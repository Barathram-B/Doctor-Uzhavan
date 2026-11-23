import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../services/cloud_ai_service.dart';
import '../services/weather_service.dart';
import '../utils/map_launcher.dart';
import '../utils/speech_helper.dart';

class HarvestScanScreen extends StatefulWidget {
  final String selectedLanguage;
  const HarvestScanScreen({super.key, required this.selectedLanguage});

  @override
  State<HarvestScanScreen> createState() => _HarvestScanScreenState();
}

class _HarvestScanScreenState extends State<HarvestScanScreen> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  final FlutterTts _flutterTts = FlutterTts();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late String _currentLanguage;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  bool _isSpeaking = false;
  String? _cameraError;
  Map<String, dynamic>? _harvestResult;

  double _currentUserLat = 11.1271;
  double _currentUserLng = 78.6569;

  final Map<String, Map<String, String>> _uiTexts = {
    'English': {
      'title': 'Harvest Date Finder',
      'calculating': 'Calculating Harvest & Fertilizers...',
      'findHarvestBtn': 'Find Harvest Date',
      'stage': 'Current Stage',
      'estDate': 'Estimated Harvest Date',
      'daysRemaining': 'days remaining',
      'fertTitle': 'Recommended Stage Fertilizer',
      'dosage': 'Dosage / Amount',
      'cost': 'Estimated Cost',
      'shopTitle': 'Nearby Fertilizer Shop',
      'shopLocation': 'Location',
      'openMaps': 'Open Shop in Google Maps',
      'careTip': 'Growth & Irrigation Care Tip',
      'listen': 'Listen Voice Summary',
      'stopVoice': 'Stop Voice',
      'nonPlantTitle': 'Focus on Fruit, Flower, or Crop',
      'nonPlantMsg': 'No crop detected. Point the camera directly at the fruit, flower, or plant canopy.',
      'galleryBtn': 'Upload from Gallery',
      'cameraError': 'Camera access needed to scan live crops',
      'retryCamera': 'Grant Permission & Retry',
    },
    'Tamil': {
      'title': 'அறுவடை நாள் கணக்கீடு',
      'calculating': 'அறுவடை மற்றும் உரம் கணக்கிடப்படுகிறது...',
      'findHarvestBtn': 'அறுவடை நாளைக் கண்டறி',
      'stage': 'தற்போதைய வளர்ச்சி நிலை',
      'estDate': 'அறுவடை நாள்',
      'daysRemaining': 'நாட்கள் மீதமுள்ளன',
      'fertTitle': 'பரிந்துரைக்கப்படும் உரம்',
      'dosage': 'உர அளவு / பயன்பாடு',
      'cost': 'தோராய விலை',
      'shopTitle': 'அருகிலுள்ள உர விற்பனை நிலையம்',
      'shopLocation': 'இடம்',
      'openMaps': 'வரைபடத்தில் கடையைக் காண்க',
      'careTip': 'பயிர் பராமரிப்பு ஆலோசனை',
      'listen': 'குரல் வழியே கேட்கவும்',
      'stopVoice': 'குரலை நிறுத்தவும்',
      'nonPlantTitle': 'பழம் அல்லது பூவின் மீது கவனம் வைக்கவும்',
      'nonPlantMsg': 'பயிர் கண்டறியப்படவில்லை. கேமராவை பழம், பூ அல்லது இலைக்கு நேராகப் பிடிக்கவும்.',
      'galleryBtn': 'புகைப்படத்தை பதிவேற்றுக',
      'cameraError': 'நேரடி பயிர் ஸ்கேன் செய்ய கேமரா அனுமதி தேவை',
      'retryCamera': 'கேமராவை மீண்டும் இயக்குக',
    },
    'Hindi': {
      'title': 'कटाई तिथि खोजक',
      'calculating': 'कटाई और खाद की गणना हो रही है...',
      'findHarvestBtn': 'कटाई तिथि ज्ञात करें',
      'stage': 'वर्तमान अवस्था',
      'estDate': 'अनुमानित कटाई तिथि',
      'daysRemaining': 'दिन शेष',
      'fertTitle': 'अनुशंसित खाद एवं उर्वरक',
      'dosage': 'मात्रा एवं प्रयोग विधि',
      'cost': 'अनुमानित मूल्य',
      'shopTitle': 'नजदीकी उर्वरक केंद्र',
      'shopLocation': 'स्थान',
      'openMaps': 'गूगल मैप्स में दुकान देखें',
      'careTip': 'देखभाल एवं सिंचाई सलाह',
      'listen': 'आवाज में सुनें',
      'stopVoice': 'आवाज रोकें',
      'nonPlantTitle': 'फल, फूल या फसल पर फोकस करें',
      'nonPlantMsg': 'फसल नहीं पहचानी गई। कृपया कैमरे को सीधे पौधे के फल, फूल या पत्ती पर रखें।',
      'galleryBtn': 'गैलरी से फोटो चुनें',
      'cameraError': 'फसल स्कैन करने के लिए कैमरा अनुमति चाहिए',
      'retryCamera': 'कैமரா पुनः शुरू करें',
    },
    'Marathi': {
      'title': 'काढणी तारीख शोधक',
      'calculating': 'काढणी आणि खताची माहिती मोजत आहे...',
      'findHarvestBtn': 'काढणीची तारीख शोधा',
      'stage': 'सध्याची अवस्था',
      'estDate': 'अपेक्षित काढणी तारीख',
      'daysRemaining': 'दिवस बाकी',
      'fertTitle': 'शिफारस केलेले खत',
      'dosage': 'खताचे प्रमाण व वापर',
      'cost': 'अंदाजे किंमत',
      'shopTitle': 'जवळचे कृषी व खत सेवा केंद्र',
      'shopLocation': 'ठिकाण',
      'openMaps': 'गुगल मॅपवर दुकान पहा',
      'careTip': 'पीक निगा व पाणी सल्ला',
      'listen': 'आवाजात ऐका',
      'stopVoice': 'आवाज थांबवा',
      'nonPlantTitle': 'फळ किंवा फुलावर लक्ष केंद्रित करा',
      'nonPlantMsg': 'पीक ओळखले नाही. कृपया कॅमेरा थेट फळ, फूल किंवा पानावर धरा.',
      'galleryBtn': 'गॅलरीतून फोटो निवडा',
      'cameraError': 'पीक स्कॅन करण्यासाठी कॅमेरा परवानगी हवी',
      'retryCamera': 'कॅमेरा पुन्हा सुरू करा',
    },
  };

  // Comprehensive multi-lingual offline database covering stage-specific fertilizers, dosage amounts, costs, and shops
  final Map<int, Map<String, dynamic>> _cropHarvestDatabase = {
    0: {
      "cropName": {
        "English": "Tomato",
        "Tamil": "தக்காளி",
        "Hindi": "टमाटर",
        "Marathi": "टोमॅटो",
      },
      "stageName": {
        "English": "Flowering & Fruit Setting Stage",
        "Tamil": "பூக்கும் மற்றும் பிஞ்சு பிடிக்கும் நிலை",
        "Hindi": "फूल एवं फल लगने की अवस्था",
        "Marathi": "फुलोरा व फळधारणा अवस्था",
      },
      "daysRemaining": 35,
      "fertilizer": {
        "English": "Mono Potassium Phosphate (00:52:34) + Boron",
        "Tamil": "மோனோ பொட்டாசியம் பாஸ்பேட் (00:52:34) + போரான்",
        "Hindi": "मोनो पोटेशियम फॉस्फेट (00:52:34) + बोरॉन",
        "Marathi": "मोनो पोटॅशियम फॉस्फेट (00:52:34) + बोरॉन",
      },
      "fertilizerAmount": {
        "English": "5 grams per 1 Litre of water (Foliar spray) or 25 kg / acre",
        "Tamil": "1 லிட்டர் தண்ணீருக்கு 5 கிராம் (இலைவழி தெளிப்பு) அல்லது ஏக்கருக்கு 25 கிலோ",
        "Hindi": "5 ग्राम प्रति 1 लीटर पानी (छिड़काव) या 25 किग्रा प्रति एकड़",
        "Marathi": "5 ग्रॅम प्रति 1 लिटर पाणी (फवारणी) किंवा 25 किलो प्रति एकर",
      },
      "storePrice": "00:52:34: ₹240 / 1 kg | Boron: ₹150 / 250g",
      "storeName": "Primary Agricultural Cooperative Society (PACS)",
      "storeLocation": "Local Agricultural Market / PACS",
      "storeLat": 0.0,
      "storeLng": 0.0,
      "advice": {
        "English": "Maintain balanced drip irrigation. Avoid excess nitrogen to prevent flower drop.",
        "Tamil": "சீரான சொட்டு நீர் பாசனம் செய்யவும். பூ உதிர்வதைத் தடுக்க அதிகப்படியான தழைச்சத்தை தவிர்க்கவும்.",
        "Hindi": "संतुलित ड्रिप सिंचाई बनाए रखें। फूल गिरने से रोकने के लिए अधिक यूरिया न दें।",
        "Marathi": "ठिबक सिंचन नियमित ठेवा. फुले गळू नयेत म्हणून जास्त नत्र देणे टाळा.",
      },
      "spokenTa": {
        "English": "Your tomato crop is in flowering and fruit setting stage. Estimated harvest in 35 days. Recommended fertilizer is 00 52 34 with Boron at 5 grams per litre. Market rate is 240 rupees per kg at your nearby PACS or fertilizer store.",
        "Tamil": "உங்கள் தக்காளி பயிர் பூக்கும் மற்றும் பிஞ்சு பிடிக்கும் நிலையில் உள்ளது. அறுவடைக்கு 35 நாட்கள் ஆகும். பரிந்துரைக்கப்படும் உரம் மோனோ பொட்டாசியம் பாஸ்பேட் 00 52 34 மற்றும் போரான், ஒரு லிட்டர் தண்ணீருக்கு 5 கிராம் தெளிக்கவும். இதன் சந்தை விலை ஒரு கிலோ 240 ரூபாய், அருகிலுள்ள வேளாண் கூட்டுறவு மையம் அல்லது உரக் கடையில் கிடைக்கும்.",
        "Hindi": "आपकी टमाटर की फसल फूल और फल लगने की अवस्था में है। कटाई में 35 दिन शेष हैं। अनुशंसित खाद मोनो पोटेशियम फॉस्फेट 00 52 34 और बोरॉन है। बाजार दर 240 रुपये प्रति किलोग्राम है।",
        "Marathi": "आपले टोमॅटो पीक फुलोरा व फळधारणा अवस्थेत आहे. काढणीसाठी 35 दिवस बाकी आहेत. शिफारस केलेले खत 00 52 34 आणि बोरॉन आहे. बाजारभाव 240 रुपये प्रति किलो आहे.",
      },
    },
    1: {
      "cropName": {
        "English": "Paddy / Rice",
        "Tamil": "நெல் பயிர்",
        "Hindi": "धान की फसल",
        "Marathi": "भाताचे पीक",
      },
      "stageName": {
        "English": "Milky Grain Filling Stage",
        "Tamil": "பால் பிடிக்கும் மற்றும் மணி கட்டும் நிலை",
        "Hindi": "दुग्ध एवं दाना भराव अवस्था",
        "Marathi": "दाणे भरण्याची अवस्था",
      },
      "daysRemaining": 20,
      "fertilizer": {
        "English": "Potassium Nitrate (13:00:45) or Muriate of Potash (MOP)",
        "Tamil": "பொட்டாசியம் நைட்ரேட் (13:00:45) அல்லது பொட்டாஷ் உரம்",
        "Hindi": "पोटेशियम नाइट्रेट (13:00:45) या म्यूरेट ऑफ पोटाश",
        "Marathi": "पोटॅशियम नायट्रेट (13:00:45) किंवा पोटॅश",
      },
      "fertilizerAmount": {
        "English": "10 grams per 1 Litre water spray or 20 kg Potash per acre",
        "Tamil": "1 லிட்டர் தண்ணீருக்கு 10 கிராம் இலைவழி தெளிப்பு அல்லது ஏக்கருக்கு 20 கிலோ",
        "Hindi": "10 ग्राम प्रति लीटर पानी छिड़काव या 20 किग्रा पोटाश प्रति एकड़",
        "Marathi": "10 ग्रॅम प्रति लिटर पाणी फवारणी किंवा 20 किलो पोटॅश प्रति एकर",
      },
      "storePrice": "13:00:45: ₹210 / 1 kg | Potash: ₹34 / kg (₹1,700 / bag)",
      "storeName": "Primary Agricultural Cooperative Society (PACS)",
      "storeLocation": "Local Agro Service Depot / PACS",
      "storeLat": 0.0,
      "storeLng": 0.0,
      "advice": {
        "English": "Keep 2 cm water level in the field until 10 days before harvest, then drain.",
        "Tamil": "அறுவடைக்கு 10 நாட்களுக்கு முன்பு வரை வயலில் 2 செ.மீ தண்ணீர் நிறுத்தி வைக்கவும், பின்னர் வடிக்கவும்.",
        "Hindi": "कटाई से 10 दिन पहले तक खेत में 2 सेमी पानी रखें, फिर पानी निकाल दें।",
        "Marathi": "काढणीच्या 10 दिवस आधीपर्यंत शेतात 2 सेंमी पाणी ठेवा, नंतर पाणी काढून टाका.",
      },
      "spokenTa": {
        "English": "Your paddy crop is in grain filling stage. Expected harvest is in 20 days. Recommended fertilizer is Potassium Nitrate 13 00 45 at 10 grams per litre spray. Rate is 210 rupees per kg at nearby agro center.",
        "Tamil": "உங்கள் நெல் பயிர் பால் பிடிக்கும் மணி கட்டும் நிலையில் உள்ளது. அறுவடைக்கு 20 நாட்கள் உள்ளன. பரிந்துரைக்கப்படும் உரம் பொட்டாசியம் நைட்ரேட் 13 00 45, ஒரு லிட்டருக்கு 10 கிராம் தெளிக்கவும். இதன் சந்தை விலை 210 ரூபாய், அருகிலுள்ள வேளாண் உரக் கடையில் கிடைக்கும்.",
        "Hindi": "आपकी धान की फसल दाना भराव अवस्था में है। कटाई में 20 दिन बाकी हैं। अनुशंसित खाद पोटेशियम नाइट्रेट 13 00 45 है। बाजार दर 210 रुपये प्रति किलोग्राम है।",
        "Marathi": "आपले भात पीक दाणे भरण्याच्या अवस्थेत आहे. काढणीसाठी 20 दिवस बाकी आहेत. शिफारस केलेले खत 13 00 45 आहे. बाजारभाव 210 रुपये प्रति किलो आहे.",
      },
    },
    2: {
      "cropName": {
        "English": "Chilli / Pepper",
        "Tamil": "மிளகாய்",
        "Hindi": "मिर्च",
        "Marathi": "मिरची",
      },
      "stageName": {
        "English": "Fruit Development & Ripening",
        "Tamil": "காய் வளர்ச்சி மற்றும் பழுக்கும் நிலை",
        "Hindi": "फल विकास एवं परिपक्वता अवस्था",
        "Marathi": "फळ वाढ आणि पक्वता अवस्था",
      },
      "daysRemaining": 15,
      "fertilizer": {
        "English": "Calcium Nitrate + Micronutrient Chelate",
        "Tamil": "கால்சியம் நைட்ரேட் + நுண்ணூட்டச்சத்து கலவை",
        "Hindi": "कैल्शियम नाइट्रेट + सूक्ष्म पोषक तत्व",
        "Marathi": "कॅल्शियम नायट्रेट + सूक्ष्म अन्नद्रव्ये",
      },
      "fertilizerAmount": {
        "English": "4 grams per 1 Litre water spray or 15 kg / acre",
        "Tamil": "1 லிட்டர் தண்ணீருக்கு 4 கிராம் இலைவழி தெளிப்பு அல்லது ஏக்கருக்கு 15 கிலோ",
        "Hindi": "4 ग्राम प्रति लीटर पानी छिड़काव या 15 किग्रा प्रति एकड़",
        "Marathi": "4 ग्रॅम प्रति लिटर पाणी फवारणी किंवा 15 किलो प्रति एकर",
      },
      "storePrice": "Calcium Nitrate: ₹80 / 1 kg | Micronutrients: ₹190 / 250g",
      "storeName": "Primary Agricultural Cooperative Society (PACS)",
      "storeLocation": "Local Agro Service Depot / Market",
      "storeLat": 0.0,
      "storeLng": 0.0,
      "advice": {
        "English": "Harvest when pods attain deep bright color. Avoid overhead watering to prevent fruit rot.",
        "Tamil": "காய்கள் முழுமையான நிறம் பெற்றவுடன் அறுவடை செய்யவும். காய் அழுகல் வராமல் இருக்க இலை மீது தண்ணீர் தெளிப்பதைத் தவிர்க்கவும்.",
        "Hindi": "जब मिर्च का रंग गहरा हो जाए तब कटाई करें। फल सड़न रोकने के लिए ऊपर से पानी न डालें।",
        "Marathi": "मिरच्या पूर्ण पिकल्यावर तोडणी करा. फळ कुजणे टाळण्यासाठी पानांवर पाणी मारणे टाळा.",
      },
      "spokenTa": {
        "English": "Your chilli crop is in fruit ripening stage. Ready for harvest in 15 days. Recommended fertilizer is Calcium Nitrate with Micronutrients. Rate is 80 rupees per kg for Calcium Nitrate.",
        "Tamil": "உங்கள் மிளகாய் பயிர் பழுக்கும் நிலையில் உள்ளது. 15 நாட்களில் அறுவடை செய்யலாம். பரிந்துரைக்கப்படும் உரம் கால்சியம் நைட்ரேட் மற்றும் நுண்ணூட்டம், ஒரு லிட்டருக்கு 4 கிராம் தெளிக்கவும். கால்சியம் நைட்ரேட் விலை கிலோ 80 ரூபாய்.",
        "Hindi": "आपकी मिर्च की फसल फल परिपक्वता अवस्था में है। 15 दिनों में कटाई योग्य होगी। अनुशंसित खाद कैल्शियम नाइट्रेट है। बाजार दर 80 रुपये प्रति किलोग्राम है।",
        "Marathi": "आपली मिरची काढणीसाठी 15 दिवसांत तयार होईल. शिफारस केलेले खत कॅल्शियम नायट्रेट आहे. बाजारभाव 80 रुपये प्रति किलो आहे.",
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.selectedLanguage;
    _setupCameraModelAndNotifications();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _setupCameraModelAndNotifications() async {
    // 1. Safe non-blocking notifications initialization
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const initSettings = InitializationSettings(android: androidSettings);
      _notificationsPlugin.initialize(initSettings).catchError((_) => false);
    } catch (e) {
      debugPrint("Notifications init notice: $e");
    }

    // 2. Safe non-blocking TFLite model initialization
    try {
      _interpreter ??=
          await Interpreter.fromAsset('assets/dual_plant_model.tflite');
    } catch (e) {
      debugPrint("TFLite model init notice: $e");
    }

    // 3. Camera initialization with back camera detection and permission handling
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _cameraError = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
            _cameraError = "No camera found on this device.";
          });
        }
      }
    } catch (e) {
      debugPrint("Camera initialization exception: $e");
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraError = "Camera access required to scan live crops.";
        });
      }
    }
  }

  Future<void> _captureFromCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      XFile capturedFile = await _cameraController!.takePicture();
      Uint8List rawBytes = await capturedFile.readAsBytes();
      await _processCapturedCropImage(rawBytes);
    } catch (e) {
      debugPrint("Camera capture error: $e");
    }
  }

  Future<void> _pickCropImageFromGallery() async {
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file != null) {
        Uint8List bytes = await file.readAsBytes();
        await _processCapturedCropImage(bytes);
      }
    } catch (e) {
      debugPrint("Gallery pick error: $e");
    }
  }

  Future<void> _processCapturedCropImage(Uint8List rawBytes) async {
    _stopVoice();

    setState(() {
      _isAnalyzing = true;
      _harvestResult = null;
    });

    try {
      // 1. Fix Orientation and Compress JPEG bytes
      Uint8List processedBytes = rawBytes;
      img.Image? decodedImg = img.decodeImage(rawBytes);

      if (decodedImg != null) {
        img.Image orientedImg = img.bakeOrientation(decodedImg);
        img.Image resizedImg = img.copyResize(orientedImg, width: 1024);
        processedBytes =
            Uint8List.fromList(img.encodeJpg(resizedImg, quality: 85));
      }

      // 2. Fetch location & weather
      double temp = 28.0;
      String? locationName;
      try {
        Map<String, dynamic> weatherData =
            await WeatherService.fetchCurrentLocationWeather();
        temp = (weatherData['temp'] as num?)?.toDouble() ?? 28.0;
        _currentUserLat = (weatherData['lat'] as num?)?.toDouble() ?? 11.1271;
        _currentUserLng = (weatherData['lng'] as num?)?.toDouble() ?? 78.6569;
        locationName = weatherData['locationName'] as String?;
      } catch (e) {
        debugPrint("Location/Weather fetch fallback: $e");
      }

      // 3. Query Gemini Cloud Harvest AI directly
      try {
        debugPrint("🌐 Querying Gemini Cloud Harvest AI...");

        Map<String, dynamic>? cloudResponse =
            await CloudAIService.analyzeHarvestOnline(
          imageBytes: processedBytes,
          language: _currentLanguage,
          currentTemp: temp,
          userLat: _currentUserLat,
          userLng: _currentUserLng,
          locationName: locationName,
        );

        if (cloudResponse != null) {
          if (cloudResponse['isPlant'] == false) {
            _handleNonPlantDetected();
            return;
          }

          int daysLeft = cloudResponse['daysRemaining'] ?? 30;
          DateTime targetDate = DateTime.now().add(Duration(days: daysLeft));

          setState(() {
            _harvestResult = {
              ...cloudResponse,
              "targetDate":
                  "${targetDate.day}/${targetDate.month}/${targetDate.year}",
            };
            _isAnalyzing = false;
          });

          _scheduleHarvestNotification(
              cloudResponse['cropName'] ?? 'Crop', targetDate);
          _speakVoiceAssistant(cloudResponse['spokenTa'] ?? "");
          return;
        }
      } catch (e) {
        debugPrint("Cloud AI Harvest error: $e");
      }

      // 4. Fall back to rich local database if offline or API returns null
      debugPrint("📱 Network Offline or API Unavailable. Running Local Harvest Model...");
      _runOfflineTFLiteHarvestModel(processedBytes);
    } catch (e) {
      debugPrint("Harvest Scan Error: $e");
      setState(() => _isAnalyzing = false);
    }
  }

  void _runOfflineTFLiteHarvestModel(Uint8List imageBytes) {
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null || _interpreter == null) {
      setState(() => _isAnalyzing = false);
      return;
    }

    img.Image resizedImage =
        img.copyResize(originalImage, width: 224, height: 224);
    var input = List.generate(1 * 224 * 224 * 3, (index) => 0.0)
        .reshape([1, 224, 224, 3]);

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    var diseaseOut = List.filled(1 * 3, 0.0).reshape([1, 3]);
    var growthOut = List.filled(1 * 3, 0.0).reshape([1, 3]);
    var outputs = {0: diseaseOut, 1: growthOut};

    _interpreter!.runForMultipleInputs([input], outputs);

    List<double> probabilities = List<double>.from(growthOut[0]);
    int predictedStageIndex = 0;
    double maxConfidence = probabilities[0];

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        predictedStageIndex = i;
      }
    }

    if (maxConfidence < 0.45) {
      _handleNonPlantDetected();
      return;
    }

    Map<String, dynamic> rawEntry = _cropHarvestDatabase[predictedStageIndex] ??
        _cropHarvestDatabase[0]!;

    // Resolve multi-language fields
    String cropName = rawEntry['cropName'] is Map
        ? (rawEntry['cropName'][_currentLanguage] ??
            rawEntry['cropName']['English'])
        : rawEntry['cropName'].toString();

    String stageName = rawEntry['stageName'] is Map
        ? (rawEntry['stageName'][_currentLanguage] ??
            rawEntry['stageName']['English'])
        : rawEntry['stageName'].toString();

    String fertilizer = rawEntry['fertilizer'] is Map
        ? (rawEntry['fertilizer'][_currentLanguage] ??
            rawEntry['fertilizer']['English'])
        : rawEntry['fertilizer'].toString();

    String fertilizerAmount = rawEntry['fertilizerAmount'] is Map
        ? (rawEntry['fertilizerAmount'][_currentLanguage] ??
            rawEntry['fertilizerAmount']['English'])
        : rawEntry['fertilizerAmount'].toString();

    String advice = rawEntry['advice'] is Map
        ? (rawEntry['advice'][_currentLanguage] ??
            rawEntry['advice']['English'])
        : rawEntry['advice'].toString();

    String spokenTa = rawEntry['spokenTa'] is Map
        ? (rawEntry['spokenTa'][_currentLanguage] ??
            rawEntry['spokenTa']['English'])
        : rawEntry['spokenTa'].toString();

    int daysLeft = rawEntry['daysRemaining'] as int? ?? 25;
    DateTime targetHarvestDate = DateTime.now().add(Duration(days: daysLeft));

    final String currentCity = WeatherService.cachedCityName ?? '';
    final String displayStoreName = (currentCity.isNotEmpty &&
            currentCity != 'India' &&
            currentCity != 'Tamil Nadu')
        ? "$currentCity Primary Agricultural Cooperative Society (PACS)"
        : (rawEntry['storeName'] ??
            "Primary Agricultural Cooperative Society (PACS)");
    final String displayStoreLocation = (currentCity.isNotEmpty &&
            currentCity != 'India' &&
            currentCity != 'Tamil Nadu')
        ? "$currentCity Agricultural Market / PACS"
        : (rawEntry['storeLocation'] ?? "Local Agro Service Center");

    setState(() {
      _harvestResult = {
        "cropName": cropName,
        "stageName": stageName,
        "daysRemaining": daysLeft,
        "fertilizer": fertilizer,
        "fertilizerAmount": fertilizerAmount,
        "storePrice": rawEntry['storePrice'] ?? "₹240 / 1 kg",
        "storeName": displayStoreName,
        "storeLocation": displayStoreLocation,
        "storeLat": 0.0,
        "storeLng": 0.0,
        "advice": advice,
        "spokenTa": spokenTa,
        "targetDate":
            "${targetHarvestDate.day}/${targetHarvestDate.month}/${targetHarvestDate.year}",
      };
      _isAnalyzing = false;
    });

    _scheduleHarvestNotification(cropName, targetHarvestDate);
    _speakVoiceAssistant(spokenTa);
  }

  void _handleNonPlantDetected() {
    setState(() => _isAnalyzing = false);
    _showNonPlantDialog();
    String alertMsg = _currentLanguage == 'Tamil'
        ? "தயவுசெய்து பழம் அல்லது பூவின் மீது கேமராவை வைக்கவும்."
        : _currentLanguage == 'Hindi'
            ? "कृपया कैमरे को फल या फूल पर केंद्रित करें।"
            : _currentLanguage == 'Marathi'
                ? "कृपया कॅमेरा फळ किंवा फुलावर केंद्रित करा."
                : "Please point camera directly at fruit, flower, or crop.";
    _speakVoiceAssistant(alertMsg);
  }

  void _showNonPlantDialog() {
    final texts = _uiTexts[_currentLanguage] ?? _uiTexts['English']!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(texts['nonPlantTitle']!),
        content: Text(texts['nonPlantMsg']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF4CAF50))),
          )
        ],
      ),
    );
  }

  Future<void> _scheduleHarvestNotification(
      String cropName, DateTime harvestDate) async {
    const androidDetails = AndroidNotificationDetails(
      'harvest_channel',
      'Harvest Reminders',
      channelDescription: 'Alerts farmers when crop is ready for harvest',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      '🌾 Harvest Reminder',
      'Your $cropName crop is ready for harvest today!',
      notificationDetails,
    );
  }

  Future<void> _speakVoiceAssistant(String rawText) async {
    if (rawText.isEmpty) return;

    if (_isSpeaking) {
      await _stopVoice();
      return;
    }

    await _stopVoice();

    // Clean all asterisks, hashes, stars, emojis and symbols for natural human speech
    String cleanText = SpeechHelper.cleanTextForSpeech(rawText);
    if (cleanText.isEmpty) return;

    String langCode = SpeechHelper.getLanguageCode(_currentLanguage);

    setState(() => _isSpeaking = true);

    try {
      await _flutterTts.setLanguage(langCode);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.44);
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint("Harvest TTS Error: $e");
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stopVoice() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    if (mounted) setState(() => _isSpeaking = false);
  }

  void _onLanguageChanged(String? newLanguage) {
    if (newLanguage == null || newLanguage == _currentLanguage) return;
    _stopVoice();
    setState(() {
      _currentLanguage = newLanguage;
      _harvestResult = null; // Reset result so user can re-scan in new language
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    _stopVoice();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = _uiTexts[_currentLanguage] ?? _uiTexts['English']!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          texts['title']!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          // In-Screen Language Dropdown
          Container(
            margin: const EdgeInsets.only(right: 10, top: 11, bottom: 11),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white38, width: 0.8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentLanguage,
                isDense: true,
                dropdownColor: const Color(0xFF2E7D32),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                selectedItemBuilder: (BuildContext context) {
                  return ['English', 'Tamil', 'Hindi', 'Marathi'].map<Widget>((String lang) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          lang,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
                items: ['English', 'Tamil', 'Hindi', 'Marathi'].map((String lang) {
                  final nativeLabel = SpeechHelper.getNativeLanguageName(lang);
                  return DropdownMenuItem<String>(
                    value: lang,
                    child: Text(
                      lang == 'English' ? 'English' : '$lang ($nativeLabel)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _onLanguageChanged,
              ),
            ),
          ),
        ],
      ),
      body: !_isCameraInitialized
          ? Container(
              color: const Color(0xFFF4F9F5),
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 72,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _cameraError ?? texts['cameraError']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _setupCameraModelAndNotifications,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        texts['retryCamera']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B5E20),
                        side: const BorderSide(
                            color: Color(0xFF2E7D32), width: 1.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _pickCropImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: Text(
                        texts['galleryBtn']!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Positioned.fill(child: CameraPreview(_cameraController!)),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFF81C784), width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: "harvestGalleryBtn",
                        onPressed:
                            _isAnalyzing ? null : _pickCropImageFromGallery,
                        backgroundColor: Colors.white,
                        elevation: 4,
                        child: const Icon(
                          Icons.photo_library,
                          color: Color(0xFF2E7D32),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FloatingActionButton.extended(
                          heroTag: "harvestScanBtn",
                          onPressed:
                              _isAnalyzing ? null : _captureFromCamera,
                          backgroundColor: const Color(0xFF2E7D32),
                          elevation: 4,
                          icon: _isAnalyzing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.calendar_month,
                                  color: Colors.white),
                          label: Text(
                            _isAnalyzing
                                ? texts['calculating']!
                                : texts['findHarvestBtn']!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_harvestResult != null) _buildHarvestResultCard(texts),
              ],
            ),
    );
  }

  /// Displays all crop harvest info, growth stage, fertilizer name, dosage amount,
  /// price cost, shop name, shop location, and Map navigation cleanly in line-by-line cards
  Widget _buildHarvestResultCard(Map<String, String> texts) {
    final String cropName = _harvestResult!['cropName'] ?? "Crop";
    final String stageName = _harvestResult!['stageName'] ?? "Stage";
    final String targetDate = _harvestResult!['targetDate'] ?? "";
    final dynamic daysLeft = _harvestResult!['daysRemaining'] ?? 0;
    final String fertilizer =
        _harvestResult!['fertilizer'] ?? "Balanced NPK / Stage Booster";
    final String fertilizerAmount =
        _harvestResult!['fertilizerAmount'] ?? "5g / Litre of water (Foliar spray)";
    final String storePrice = _harvestResult!['storePrice'] ?? "₹280 / 1 kg";
    final String storeName =
        _harvestResult!['storeName'] ?? "Uzhavar Service Agri Center";
    final String storeLocation =
        _harvestResult!['storeLocation'] ?? "Main Bazaar Road";
    final double? storeLat = (_harvestResult!['storeLat'] as num?)?.toDouble();
    final double? storeLng = (_harvestResult!['storeLng'] as num?)?.toDouble();
    final String advice = _harvestResult!['advice'] ?? "";
    final String spokenTa = _harvestResult!['spokenTa'] ?? "";

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Crop Name, Stage Tag, Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cropName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${texts['stage']}: $stageName",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _stopVoice();
                      setState(() => _harvestResult = null);
                    },
                  )
                ],
              ),
              const Divider(height: 16),

              // CARD 1: Estimated Harvest Date & Days Countdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available,
                        color: Color(0xFF2E7D32), size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            texts['estDate']!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                          Text(
                            targetDate,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$daysLeft ${texts['daysRemaining']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // CARD 2: Fertilizer Name, Dosage Amount & Cost
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCEDC8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco,
                            color: Color(0xFF33691E), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          texts['fertTitle']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF33691E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fertilizer,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dosage Amount Line
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.scale,
                            size: 16, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: "${texts['dosage']}: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: fertilizerAmount),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Cost Line
                    Row(
                      children: [
                        const Icon(Icons.payments,
                            size: 16, color: Color(0xFF1B5E20)),
                        const SizedBox(width: 6),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13),
                            children: [
                              TextSpan(
                                text: "${texts['cost']}: ",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              TextSpan(
                                text: storePrice,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // CARD 3: Shop Name, Location, and Google Maps Navigation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront,
                            color: Color(0xFF1B5E20), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          texts['shopTitle']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${texts['shopLocation']}: $storeLocation",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Map Navigation Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          MapLauncher.openGoogleMaps(
                            userLat: _currentUserLat,
                            userLng: _currentUserLng,
                            storeName: storeName,
                            storeLocation: storeLocation,
                            cityName: WeatherService.cachedCityName,
                            storeLat: storeLat,
                            storeLng: storeLng,
                          );
                        },
                        icon: const Icon(Icons.map, size: 20),
                        label: Text(
                          texts['openMaps']!,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (advice.isNotEmpty) ...[
                const SizedBox(height: 10),
                // CARD 4: Growth Tip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates,
                          color: Color(0xFFF57F17), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${texts['careTip']}: $advice",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // CARD 5: Listen / Stop Voice Assistant Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSpeaking
                        ? Colors.red
                        : const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _speakVoiceAssistant(spokenTa),
                  icon: Icon(
                    _isSpeaking
                        ? Icons.stop_circle_rounded
                        : Icons.volume_up,
                    size: 22,
                  ),
                  label: Text(
                    _isSpeaking
                        ? texts['stopVoice']!
                        : "${texts['listen']!} ($_currentLanguage)",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
