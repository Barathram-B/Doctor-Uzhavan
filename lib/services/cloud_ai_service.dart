import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class CloudAIService {
  static const String _primaryKey = ApiConfig.geminiPrimaryKey;
  static const String _backupKey = ApiConfig.geminiBackupKey;

  // Active verified models on Google Generative Language API
  static const List<String> _models = [
    "gemini-3-flash-preview",
    "gemini-3.1-flash-lite",
    "gemini-3.5-flash-lite",
    "gemini-3.1-flash-lite-preview",
  ];

  static String? _workingModel;
  static String? _workingKey;

  /// Fast HTTP post to verified working Google Gemini models
  static Future<http.Response?> _sendGeminiRequest(
      Map<String, dynamic> body) async {
    final availableKeys = [_primaryKey, _backupKey]
        .where((k) => k.trim().isNotEmpty)
        .toList();

    if (availableKeys.isEmpty) {
      debugPrint(
          "⚠️ [CloudAIService] No Gemini API key provided. Run with --dart-define-from-file=secrets.json");
      return null;
    }

    List<String> keysToTry = _workingKey != null && availableKeys.contains(_workingKey)
        ? [
            _workingKey!,
            ...availableKeys.where((k) => k != _workingKey)
          ]
        : availableKeys;

    List<String> modelsToTry = _workingModel != null
        ? [_workingModel!, ..._models.where((m) => m != _workingModel)]
        : _models;

    for (String key in keysToTry) {
      for (String model in modelsToTry) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
          );

          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            _workingModel = model;
            _workingKey = key;
            return response;
          } else {
            debugPrint(
                "Gemini [$model] HTTP ${response.statusCode}: ${response.body}");
          }
        } catch (e) {
          debugPrint("Gemini [$model] call error: $e");
        }
      }
    }
    return null;
  }

  // =========================================================================
  // Method 1: Crop Disease Scan Analyzer
  // =========================================================================
  static Future<Map<String, dynamic>?> analyzeCropOnline({
    required Uint8List imageBytes,
    required String language,
    double userLat = 11.1271,
    double userLng = 78.6569,
    String? locationName,
  }) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final locText = locationName != null && locationName.isNotEmpty
          ? "$locationName (Lat: $userLat, Lng: $userLng)"
          : "Latitude $userLat, Longitude $userLng";

      final prompt = '''
        Analyze this agricultural leaf/plant image for disease diagnosis.
        Farmer location: $locText.
        Selected output language: $language.

        CRITICAL RATE & STORE INSTRUCTIONS:
        - "storePrice": Provide the REALISTIC, AUTHENTIC Indian retail market price (Rate in ₹ INR) corresponding specifically to the recommended chemical/medicine/fungicide product and pack size. Do NOT output a static or generic price.
          * Copper Oxychloride 50% WP (COC): ₹320 - ₹380 / 500g
          * Mancozeb 75% WP (Dithane M-45): ₹220 - ₹270 / 500g
          * Neem Oil 10000 ppm: ₹260 - ₹340 / 500ml
          * Streptocycline: ₹70 - ₹85 / 6g pouch
          * Imidacloprid 17.8% SL: ₹280 - ₹360 / 250ml
          * Carbendazim 50% WP (Bavistin): ₹180 - ₹240 / 250g
          * Hexaconazole 5% EC: ₹280 - ₹350 / 500ml
          * Trichoderma Viride / Pseudomonas Bio-fungicide: ₹90 - ₹130 / 1 kg
        - "storeName": Name a realistic local store such as "Primary Agricultural Cooperative Society (PACS) / உழவர் சேவை மையம்" or "Agro Service Center, $locText".
        - "storeLocation": Area or market in $locText (e.g. "$locText Main Road / Agri Market").
        - "storeLat": 0.0, "storeLng": 0.0 (return 0.0 so the mobile app triggers dynamic live Google Maps search).

        Respond STRICTLY in JSON format following this exact schema:
        {
          "cropName": "Crop Name in $language",
          "diseaseName": "Disease Name in $language",
          "remedyTa": "Treatment guide written in $language without markdown or asterisks",
          "fertilizer": "Recommended Fertilizer / Fungicide Name",
          "fertilizerAmount": "Dosage and application rate in $language (e.g., 2ml / Litre water or 25kg / acre)",
          "storeName": "Name of nearby Agro / Fertilizer Store or PACS",
          "storeLocation": "Area or market near $locText",
          "storePrice": "Realistic Indian Market Rate in ₹ INR with pack size",
          "storeLat": 0.0,
          "storeLng": 0.0,
          "isPlant": true
        }

        Set "isPlant": false ONLY if the image strictly depicts non-agricultural objects like shoes, cars, walls, or furniture.
      ''';

      final response = await _sendGeminiRequest({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image,
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "response_mime_type": "application/json"
        }
      });

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        dynamic parsed = jsonDecode(text.trim());
        if (parsed is List && parsed.isNotEmpty) {
          return Map<String, dynamic>.from(parsed[0]);
        }
        return Map<String, dynamic>.from(parsed);
      }
    } catch (e) {
      debugPrint("⚠️ Disease Scan Exception: $e");
    }
    return null;
  }

  // =========================================================================
  // Method 2: Harvest Date & Stage Fertilizer Analyzer
  // =========================================================================
  static Future<Map<String, dynamic>?> analyzeHarvestOnline({
    required Uint8List imageBytes,
    required String language,
    required double currentTemp,
    double userLat = 11.1271,
    double userLng = 78.6569,
    String? locationName,
  }) async {
    try {
      final base64Image = base64Encode(imageBytes);
      final locText = locationName != null && locationName.isNotEmpty
          ? "$locationName (Lat: $userLat, Lng: $userLng)"
          : "Latitude $userLat, Longitude $userLng";

      final prompt = '''
        You are an expert agronomist. Analyze this fruit, flower, leaf, or crop image to estimate harvest date and provide precise stage-specific fertilizer guidance.
        Current field temperature: $currentTemp°C.
        Farmer location: $locText.
        Target output language: $language.

        CRITICAL RATE & STORE INSTRUCTIONS:
        - "storePrice": Provide the REALISTIC, ACCURATE Indian retail market price (Rate in ₹ INR) corresponding specifically to the recommended fertilizer or booster product. Do NOT use a generic or static price like ₹280.
          * Water Soluble 19:19:19: ₹150 - ₹180 / 1 kg
          * Water Soluble 00:52:34 (MKP): ₹220 - ₹260 / 1 kg
          * Water Soluble 13:00:45 (Potassium Nitrate): ₹190 - ₹230 / 1 kg
          * Water Soluble 00:00:50 (SOP): ₹160 - ₹200 / 1 kg
          * Urea: ₹266 / 45kg bag (approx ₹6/kg)
          * DAP 18:46:0: ₹1,350 / 50kg bag
          * Muriate of Potash / MOP: ₹1,700 / 50kg bag (approx ₹34/kg)
          * Calcium Nitrate: ₹75 - ₹90 / 1 kg (or ₹1,400 / 25kg bag)
          * Boron 20%: ₹220 - ₹280 / 500g
          * Chelated Micronutrient Mixture: ₹240 - ₹320 / 500g
          * Zinc Sulphate 33%: ₹65 - ₹85 / 1 kg
        - "storeName": Suggest a realistic store such as "Primary Agricultural Cooperative Society (PACS) / உழவர் சேவை மையம்" or "Agro Service Center, $locText".
        - "storeLocation": Town or market in $locText (e.g. "$locText Market Road").
        - "storeLat": 0.0, "storeLng": 0.0 (return 0.0 so the mobile app triggers dynamic live Google Maps search).

        Respond STRICTLY in JSON format following this exact schema:
        {
          "cropName": "Crop Name in $language",
          "stageName": "Current Growth Stage in $language (e.g., Flowering / Fruit Formation / Grain Filling / Ripening)",
          "daysRemaining": 25,
          "harvestDate": "DD/MM/YYYY",
          "fertilizer": "Recommended stage-specific fertilizer / booster in $language",
          "fertilizerAmount": "Exact dosage and amount in $language (e.g., 5 grams per litre of water spray or 25 kg per acre)",
          "storePrice": "Realistic Indian Market Rate in ₹ INR with pack size",
          "storeName": "Name of nearby Agro / Fertilizer Center or PACS",
          "storeLocation": "Town or market area near $locText",
          "storeLat": 0.0,
          "storeLng": 0.0,
          "advice": "Care tip and watering advice in $language",
          "spokenTa": "Voice summary in natural $language without any markdown, asterisks (**), or symbols. Clearly tell harvest date, days remaining, stage, recommended fertilizer, dosage amount, estimated price, and nearby shop location.",
          "isPlant": true
        }

        Set "isPlant": false ONLY if the image clearly shows non-agricultural objects like shoes, clothes, vehicles, or interior walls.
      ''';

      final response = await _sendGeminiRequest({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image,
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "response_mime_type": "application/json"
        }
      });

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        dynamic parsed = jsonDecode(text.trim());
        if (parsed is List && parsed.isNotEmpty) {
          return Map<String, dynamic>.from(parsed[0]);
        }
        return Map<String, dynamic>.from(parsed);
      }
    } catch (e) {
      debugPrint("⚠️ Harvest Scan Exception: $e");
    }
    return null;
  }

  // =========================================================================
  // Method 3: DoctorUzhavan.AI Multi-Lingual Assistant
  // Real live Gemini AI intelligence answering whatever question is asked
  // =========================================================================
  static Future<String> askAgricultureAssistant({
    required String userQuery,
    required String selectedLanguage,
    String? locationName,
    double? userLat,
    double? userLng,
    double? currentTemp,
    bool isDefaultLocation = false,
    Uint8List? imageBytes,
  }) async {
    try {
      final now = DateTime.now();
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final currentMonth = monthNames[now.month - 1];
      final currentDateStr = "${now.day} $currentMonth ${now.year}";

      final effectiveLocation = (locationName != null && locationName.isNotEmpty)
          ? locationName
          : (userLat != null && userLng != null
              ? "Latitude ${userLat.toStringAsFixed(3)}, Longitude ${userLng.toStringAsFixed(3)}"
              : "Regional Agriculture Zone");

      final promptText = '''
You are "DoctorUzhavan.AI", a world-class agricultural scientist, agronomist, and farming advisor.
Provide expert, accurate, practical, and localized advice for the farmer's question: "$userQuery"

LIVE CONTEXT:
- Today's Date: $currentDateStr
- Current Month: $currentMonth
- Farmer's Actual Location: $effectiveLocation
- Coordinates: Latitude ${userLat ?? 11.1271}, Longitude ${userLng ?? 78.6569}
- Current Field Temperature: ${currentTemp != null ? '$currentTemp°C' : '28°C'}
- Live GPS Verified: ${!isDefaultLocation ? 'YES' : 'Regional Default'}
- Selected App Language: $selectedLanguage

CRITICAL LOCATION & PLANTING RULES:
1. If the farmer asks what to plant today, which crop is best for their location, or seasonal farming advice:
   - Base your recommendations specifically on their ACTUAL location: $effectiveLocation, current month ($currentMonth), and the active planting season (e.g. Rabi season, Samba / Thaladi, Navarai, Kharif, or Zaid depending on the region).
   - NEVER assume or mention an unrelated fixed location like Paramakudi unless their actual location is Paramakudi.
   - Recommend the top 3 to 4 best crops to sow or plant right now in their specific region, including recommended high-yield varieties, crop duration (in days), water requirement, and key care tips.

MANDATORY RESPONSE RULES:
1. SCRIPT & LANGUAGE: You MUST respond 100% in the selected language: $selectedLanguage.
   - If $selectedLanguage is "Tamil": Write in natural, clear Tamil script (தமிழ்).
   - If $selectedLanguage is "Hindi": Write in clear Hindi script (हिंदी).
   - If $selectedLanguage is "Marathi": Write in clear Marathi script (मराठी).
   - If $selectedLanguage is "Telugu": Write in clear Telugu script (తెలుగు).
   - If $selectedLanguage is "Kannada": Write in clear Kannada script (ಕನ್ನಡ).
   - If $selectedLanguage is "Malayalam": Write in clear Malayalam script (മലയാളം).
   - If $selectedLanguage is "Bengali": Write in clear Bengali script (বাংলা).
   - If $selectedLanguage is "Gujarati": Write in clear Gujarati script (ગુજરાતી).
   - If $selectedLanguage is "Punjabi": Write in clear Punjabi script (ਪੰਜਾਬੀ).
   - If $selectedLanguage is "English": Write in clear English.
   Translate your entire agricultural knowledge into $selectedLanguage. Never output mixed languages unless specifying technical scientific names.
2. DYNAMIC & COMPREHENSIVE: Answer any farming question across the world dynamically and thoroughly. For pest, fertilizer, or disease queries, give specific chemical and organic solutions, exact dosages (e.g. ml per litre of water or kg per acre), authentic current Indian retail market rates in ₹ INR (e.g., Urea ₹266/bag, DAP ₹1,350/bag, Potash ₹34/kg, 19:19:19 ₹160/kg, 00:52:34 ₹240/kg, Copper Oxychloride ₹340/500g, Neem Oil ₹280/500ml), and advise visiting local Primary Agricultural Cooperative Societies (PACS / உழவர் சேவை மையம்) or licensed agro dealers.
3. NATURAL VOICE FRIENDLY (NO ASTERISKS): Text-To-Speech will read your response out loud. Do NOT use markdown bold asterisks (**like this**) or bullet asterisks (*). Write clean paragraphs or numbered lists (1., 2., 3.) so TTS speaks smoothly and naturally without saying "star, star".
4. If an image is provided, inspect the crop, leaves, soil, or symptom shown in the photo in detail.
''';

      List<Map<String, dynamic>> parts = [
        {"text": promptText}
      ];

      if (imageBytes != null) {
        final base64Image = base64Encode(imageBytes);
        parts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Image,
          }
        });
      }

      final response = await _sendGeminiRequest({
        "contents": [
          {"parts": parts}
        ]
      });

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        if (text.trim().isNotEmpty) {
          return text.trim();
        }
      }

      if (selectedLanguage == 'Tamil') {
        return "மன்னிக்கவும், AI சேவையை இணைக்க முடியவில்லை. தயவுசெய்து உங்கள் இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.";
      } else if (selectedLanguage == 'Hindi') {
        return "क्षमा करें, AI सेवा से कनेक्ट नहीं हो सका। कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।";
      } else if (selectedLanguage == 'Marathi') {
        return "क्षमस्व, AI सेवेशी संपर्क होऊ शकला नाही. कृपया आपले इंटरनेट तपासून पुन्हा प्रयत्न करा.";
      } else if (selectedLanguage == 'Telugu') {
        return "క్షమించండి, AI సేవను కనెక్ట్ చేయలేకపోయాము. దయచేసి మీ ఇంటర్నెట్ కనెక్షన్‌ని తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.";
      } else if (selectedLanguage == 'Kannada') {
        return "ಕ್ಷಮಿಸಿ, AI ಸೇವೆಯನ್ನು ಸಂಪರ್ಕಿಸಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.";
      } else if (selectedLanguage == 'Malayalam') {
        return "ക്ഷമിക്കണം, AI സേവനത്തിലേക്ക് കണക്റ്റ് ചെയ്യാൻ കഴിഞ്ഞില്ല. ദയവായി നിങ്ങളുടെ ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.";
      } else if (selectedLanguage == 'Bengali') {
        return "দুঃখিত, AI সেবায় সংযোগ করা যায়নি। অনুগ্রহ করে আপনার ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।";
      } else if (selectedLanguage == 'Gujarati') {
        return "માફ કરશો, AI સેવા સાથે કનેક્ટ કરી શકાયું નથી. કૃપા કરીને તમારું ઇન્ટરનેટ કનેક્શન તપાસો અને ફરી પ્રયાસ કરો.";
      } else if (selectedLanguage == 'Punjabi') {
        return "ਮਾਫ਼ ਕਰਨਾ, AI ਸੇਵਾ ਨਾਲ ਜੁੜਿਆ ਨਹੀਂ ਜਾ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਇੰਟਰਨੈਟ ਕਨੈਕਸ਼ਨ ਜਾਂਚੋ ਅਤੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।";
      } else {
        return "Unable to connect to DoctorUzhavan.AI. Please check your internet connection and try again.";
      }
    } catch (e) {
      debugPrint("Chatbot Exception: $e");
      if (selectedLanguage == 'Tamil') {
        return "பிழை ஏற்பட்டது. தயவுசெய்து இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.";
      } else if (selectedLanguage == 'Hindi') {
        return "त्रुटि हुई। कृपया अपना इंटरनेट जांचें और पुनः प्रयास करें।";
      } else if (selectedLanguage == 'Marathi') {
        return "त्रुटी आली. कृपया इंटरनेट तपासून पुन्हा प्रयत्न करा.";
      } else if (selectedLanguage == 'Telugu') {
        return "లోపం సంభవించింది. దయచేసి మీ ఇంటర్నెట్ కనెక్షన్‌ని తనిఖీ చేయండి.";
      } else if (selectedLanguage == 'Kannada') {
        return "ದೋಷ ಸಂಭವಿಸಿದೆ. ದಯವಿಟ್ಟು ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕವನ್ನು ಪರಿಶೀಲಿಸಿ.";
      } else if (selectedLanguage == 'Malayalam') {
        return "ഒരു തകരാർ സംഭവിച്ചു. ദയവായി നിങ്ങളുടെ ഇന്റർനെറ്റ് പരിശോധിക്കുക.";
      } else {
        return "An error occurred while connecting. Please check your network and try again.";
      }
    }
  }
}
