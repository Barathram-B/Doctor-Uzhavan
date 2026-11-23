import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../services/cloud_ai_service.dart';
import '../services/weather_service.dart';
import '../utils/speech_helper.dart';

class ChatBotScreen extends StatefulWidget {
  final String selectedLanguage;
  const ChatBotScreen({super.key, required this.selectedLanguage});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final FlutterTts _flutterTts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();

  // Speech-To-Text instance & state
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  double _soundLevel = 0.0;
  List<stt.LocaleName> _availableLocales = [];
  String _activeSpeechLocale = '';

  // Animation controller for live recording waves visualizer
  late AnimationController _waveAnimController;

  late String _currentLanguage;
  bool _isLoading = false;
  bool _isSpeaking = false;
  int? _speakingMessageIndex;
  Uint8List? _selectedImageBytes;

  static const List<String> _supportedLanguages = [
    'English',
    'Tamil',
    'Hindi',
    'Marathi',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Bengali',
    'Gujarati',
    'Punjabi',
  ];

  final Map<String, Map<String, dynamic>> _langConfig = {
    'English': {
      'greeting':
          'Hello! I am DoctorUzhavan.AI. Ask me anything in the world about farming, crops, pest remedies, fertilizers, or soil!',
      'switched':
          'Language switched to English. You can ask or speak any farming question!',
      'inputHint': 'Ask or record any farming question...',
      'photoAttached': 'Photo attached',
      'recordingText': 'Listening in English... Speak now',
      'stopText': 'Stop',
      'sendText': 'Send',
      'listenTooltip': 'Record Voice (English)',
      'suggestions': [
        '📍 What can I plant today based on my location?',
        '🌾 Paddy stem borer remedy & chemical dose',
        '🍅 Tomato leaf curl cure',
        '🍌 Increase banana bunch size & potash',
        '🌿 Jeevamrutham organic preparation',
        '🐛 Cotton pink bollworm control',
        '💧 Drip irrigation scheduling',
        '🌶️ Prevent chilli flower drop',
        '🌱 Soil testing & pH correction',
      ],
    },
    'Tamil': {
      'greeting':
          'வணக்கம்! நான் DoctorUzhavan.AI. விவசாயம், பயிர்கள், பூச்சி, நோய், உர அளவு, அல்லது மண் மேலாண்மை பற்றியும் என்னிடம் எதையும் கேட்கலாம்!',
      'switched':
          'மொழி தமிழுக்கு மாற்றப்பட்டது. உங்கள் சந்தேகங்களை தமிழில் கேட்கவும் அல்லது பேசவும்!',
      'inputHint': 'விவசாயக் கேள்விகளை எழுத அல்லது பேசவும்...',
      'photoAttached': 'புகைப்படம் இணைக்கப்பட்டது',
      'recordingText': 'தமிழில் கேட்கிறது... பேசுங்கள்',
      'stopText': 'நிறுத்து',
      'sendText': 'அனுப்பு',
      'listenTooltip': 'குரல் மூலம் பேச (தமிழ்)',
      'suggestions': [
        '📍 இன்று என் இருப்பிடத்திற்கு என்ன பயிர் நடலாம்?',
        '🌾 நெல் குருத்துப்பூச்சி மருந்து மற்றும் அளவு',
        '🍅 தக்காளி இலை சுருட்டை நோய் சிகிச்சை',
        '🍌 வாழை தார் பெரிதாக பொட்டாஷ் உரம்',
        '🌿 ஜீவாமிர்தம் தயாரிக்கும் எளிய முறை',
        '🐛 பருத்தி காய்ப்புழு கட்டுப்பாடு',
        '💧 சொட்டு நீர் பாசன அட்டவணை',
        '🌶️ மிளகாய் பூ உதிர்வதை தடுக்கும் மருந்து',
        '🌱 மண் பரிசோதனை & காரத்தன்மை சரிசெய்ய',
      ],
    },
    'Hindi': {
      'greeting':
          'नमस्ते! मैं DoctorUzhavan.AI हूँ। दुनिया भर की किसी भी फसल, खाद, कीट, रोग, सिंचाई या मिट्टी से जुड़े कोई भी सवाल पूछें!',
      'switched':
          'भाषा हिंदी में बदल दी गई है। किसी भी फसल के बारे में कुछ भी पूछें या बोलें!',
      'inputHint': 'खेती से जुड़ा सवाल लिखें या बोलें...',
      'photoAttached': 'फोटो जोड़ा गया',
      'recordingText': 'हिंदी में सुन रहे हैं... बोलिए',
      'stopText': 'रोकें',
      'sendText': 'भेजें',
      'listenTooltip': 'आवाज़ से पूछें (हिंदी)',
      'suggestions': [
        '📍 मेरी लोकेशन के अनुसार आज क्या लगाएं?',
        '🌾 धान में तना छेदक का उपचार व दवा',
        '🍅 टमाटर पत्ता मरोड़ रोग की रोकथाम',
        '🍌 केले का घौद बढ़ाने का उपाय',
        '🌿 जीवामृत बनाने की सटीक विधि',
        '🐛 कपास में गुलाबी सुंडी नियंत्रण',
        '💧 ड्रिप सिंचाई प्रबंधन',
        '🌶️ मिर्च में फूल झड़ने से रोकें',
        '🌱 मिट्टी परीक्षण और सुधार',
      ],
    },
    'Marathi': {
      'greeting':
          'नमस्कार! मी DoctorUzhavan.AI आहे. शेती, कोणत्याही पिकाचे रोग, खते, कीड व्यवस्थापन किंवा हवामानाविषयी कोणताही प्रश्न विचारा!',
      'switched':
          'भाषा मराठीत बदलली आहे. पिकांविषयी कोणताही प्रश्न विचारा किंवा बोला!',
      'inputHint': 'शेतीविषयक प्रश्न विचारा किंवा बोला...',
      'photoAttached': 'फोटो जोडला',
      'recordingText': 'मराठीत ऐकत आहे... बोला',
      'stopText': 'थांबवा',
      'sendText': 'पाठवा',
      'listenTooltip': 'आवाजाने विचारा (मराठी)',
      'suggestions': [
        '📍 माझ्या स्थानानुसार आज कोणती लागवड करावी?',
        '🌾 भातातील खोडकिडा नियंत्रण व औषध',
        '🍅 टोमॅटो चुरडा-मुरडा रोग उपाय',
        '🍌 केळी घडाची वाढ उपाय',
        '🌿 जीवामृत तयार करण्याची कृती',
        '🐛 कापसातील बोंडअळी नियंत्रण',
        '💧 ठिबक सिंचन पद्धती',
        '🌶️ मिरची फुलगळ प्रतिबंध औषध',
        '🌱 माती परीक्षण व उपाय',
      ],
    },
    'Telugu': {
      'greeting':
          'నమస్కారం! నేను DoctorUzhavan.AI. వ్యవసాయం, పంటలు, తెగుళ్లు, ఎరువుల నిర్వహణ గురించి నన్ను ఏదైనా అడగండి!',
      'switched':
          'భాష తెలుగులోకి మార్చబడింది. మీ ప్రశ్నలను మాట్లాడండి లేదా టైప్ చేయండి!',
      'inputHint': 'వ్యవసాయ ప్రశ్నను అడగండి లేదా మాట్లాడండి...',
      'photoAttached': 'ఫోటో జతచేయబడింది',
      'recordingText': 'తెలుగులో వింటున్నాము... మాట్లాడండి',
      'stopText': 'ఆపు',
      'sendText': 'పంపు',
      'listenTooltip': 'వాయిస్ ద్వారా అడగండి (తెలుగు)',
      'suggestions': [
        '📍 నా ప్రాంతానికి ఈరోజు ఏ పంట వేయాలి?',
        '🌾 వరి కాండం తొలుచు పురుగు నివారణ',
        '🍅 టమాట ఆకు ముడత నివారణ మందు',
        '🍌 అరటి గెల బరువు పెరగడానికి ఎరువులు',
        '🌿 జీవామృతం తయారీ విధానం',
        '🐛 పత్తిలో గులాబీ రంగు పురుగు నివారణ',
        '💧 బిందు సేద్యం నిర్వహణ',
        '🌶️ మిరపలో పూత రాలకుండా నివారణ',
        '🌱 భూసార పరీక్ష & నేల యాజమాన్యం',
      ],
    },
    'Kannada': {
      'greeting':
          'ನಮಸ್ಕಾರ! ನಾನು DoctorUzhavan.AI. ಕೃಷಿ, ಬೆಳೆಗಳು, ರೋಗ, ಕೀಟನಾಶಕ ಅಥವಾ ರಸಗೊಬ್ಬರದ ಬಗ್ಗೆ ಏನನ್ನಾದರೂ ಕೇಳಿ!',
      'switched':
          'ಭಾಷೆ ಕನ್ನಡಕ್ಕೆ ಬದಲಾಗಿದೆ. ಬೆಳೆಗಳ ಬಗ್ಗೆ ಪ್ರಶ್ನೆ ಕೇಳಿ ಅಥವಾ ಮಾತನಾಡಿ!',
      'inputHint': 'ಕೃಷಿ ಪ್ರಶ್ನೆ ಕೇಳಿ ಅಥವಾ ಮಾತನಾಡಿ...',
      'photoAttached': 'ಫೋಟೋ ಲಗತ್ತಿಸಲಾಗಿದೆ',
      'recordingText': 'ಕನ್ನಡದಲ್ಲಿ ಆಲಿಸಲಾಗುತ್ತಿದೆ... ಮಾತನಾಡಿ',
      'stopText': 'ನಿಲ್ಲಿಸು',
      'sendText': 'ಕಳುಹಿಸು',
      'listenTooltip': 'ಧ್ವನಿ ಮೂಲಕ ಕೇಳಿ (ಕನ್ನಡ)',
      'suggestions': [
        '📍 ನನ್ನ ಸ್ಥಳಕ್ಕೆ ತಕ್ಕಂತೆ ಇಂದು ಯಾವ ಬೆಳೆ ಬೆಳೆಯಬಹುದು?',
        '🌾 ಭತ್ತದ ಕಾಂಡ ಕೊರೆಯುವ ಹುಳು ಹತೋಟಿ',
        '🍅 ಟೊಮೆಟೊ ಎಲೆ ಸುರುಟು ರೋಗಕ್ಕೆ ಔಷಧಿ',
        '🍌 ಬಾಳೆ ಗೊನೆ ತೂಕ ಹೆಚ್ಚಿಸಲು ಗೊಬ್ಬರ',
        '🌿 ಜೀವಾಮೃತ ತಯಾರಿಸುವ ವಿಧಾನ',
        '🐛 ಹತ್ತಿ ಕಾಯಿ ಕೊರೆಯುವ ಹುಳು ನಿಯಂತ್ರಣ',
        '💧 ಹನಿ ನೀರಾವರಿ ವೇಳಾಪಟ್ಟಿ',
        '🌶️ ಮೆಣಸಿನಕಾಯಿ ಹೂ ಉದುರುವುದನ್ನು ತಡೆಯುವುದು',
        '🌱 ಮಣ್ಣು ಪರೀಕ್ಷೆ ಮತ್ತು ಸುಧಾರಣೆ',
      ],
    },
    'Malayalam': {
      'greeting':
          'നമസ്കാരം! ഞാൻ DoctorUzhavan.AI. കൃഷി, വിളകൾ, കീടങ്ങൾ, വളം, മണ്ണ് എന്നിവയെക്കുറിച്ച് എന്തും ചോദിക്കാം!',
      'switched':
          'ഭാഷ മലയാളത്തിലേക്ക് മാറ്റി. കൃഷി ചോദ്യങ്ങൾ ചോദിക്കുകയോ സംസാരിക്കുകയോ ചെയ്യാം!',
      'inputHint': 'കൃഷി ചോദ്യങ്ങൾ ചോദിക്കുക അല്ലെങ്കിൽ സംസാരിക്കുക...',
      'photoAttached': 'ഫോട്ടോ ചേർത്തു',
      'recordingText': 'മലയാളത്തിൽ കേൾക്കുന്നു... സംസാരിക്കുക',
      'stopText': 'നിർത്തുക',
      'sendText': 'അയക്കുക',
      'listenTooltip': 'വോയ്‌സ് വഴി ചോദിക്കുക (മലയാളം)',
      'suggestions': [
        '📍 ഇന്നത്തെ കാലാവസ്ഥയ്ക്ക് അനുയോജ്യമായ വിള ഏത്?',
        '🌾 നെല്ലിലെ തണ്ടുതുരപ്പൻ പുഴു നിയന്ത്രണം',
        '🍅 തക്കാളി ഇലച്ചുരുൾ രോഗപ്രതിവിധി',
        '🍌 വാഴക്കുല വലുതാക്കാൻ പൊട്ടാഷ് പ്രയോഗം',
        '🌿 ജീവാമൃതം ഉണ്ടാക്കുന്ന വിധം',
        '🐛 പരുത്തിയിലെ പുഴുശല്യം തടയാൻ',
        '💧 തുള്ളിനന ജലസേചനം',
        '🌶️ മുളകിലെ പൂകൊഴിച്ചിൽ തടയാൻ',
        '🌱 മണ്ണുപരിശോധനയും പരിപാലനവും',
      ],
    },
    'Bengali': {
      'greeting':
          'নমস্কার! আমি DoctorUzhavan.AI। কৃষি, ফসল, কীটনাশক, রোগ ও সার ব্যবস্থাপনা সম্পর্কে যেকোনো প্রশ্ন জিজ্ঞাসা করুন!',
      'switched':
          'ভাষা বাংলায় পরিবর্তিত হয়েছে। ফসলের বিষয়ে প্রশ্ন করুন বা মুখে বলুন!',
      'inputHint': 'কৃষি প্রশ্ন লিখুন বা মুখে বলুন...',
      'photoAttached': 'ছবি সংযুক্ত করা হয়েছে',
      'recordingText': 'বাংলায় শুনছি... আপনার প্রশ্ন বলুন',
      'stopText': 'থামুন',
      'sendText': 'পাঠান',
      'listenTooltip': 'ভয়েসে জিজ্ঞাসা করুন (বাংলা)',
      'suggestions': [
        '📍 আমার অবস্থানের জন্য আজ কোন ফসল উপযুক্ত?',
        '🌾 ধানের মাজরা পোকা দমন ও ওষুধ',
        '🍅 টমেটো পাতা কোঁকড়ানো রোগ প্রতিকার',
        '🍌 কলার ছড়ি বড় করার সার',
        '🌿 জীবামৃত তৈরির নিয়ম',
        '🐛 তুলোর পোকা দমন',
        '💧 ড্রিপ সেচ পদ্ধতি',
        '🌶️ লঙ্কা ফুল ঝরে পড়া রোধ',
        '🌱 মাটি পরীক্ষা ও পরিচর্যা',
      ],
    },
    'Gujarati': {
      'greeting':
          'નમસ્તે! હું DoctorUzhavan.AI છું. ખેતી, પાક, જીવાત, રોગ, ખાતર અથવા જમીન વિશે મને કંઈપણ પૂછો!',
      'switched':
          'ભાષા ગુજરાતીમાં બદલાઈ ગઈ છે. પાક વિશે પ્રશ્ન પૂછો અથવા બોલો!',
      'inputHint': 'ખેતીનો પ્રશ્ન પૂછો અથવા બોલો...',
      'photoAttached': 'ફોટો જોડ્યો',
      'recordingText': 'ગુજરાતીમાં સાંભળી રહ્યું છે... બોલો',
      'stopText': 'રોકો',
      'sendText': 'મોકલો',
      'listenTooltip': 'અવાજ દ્વારા પૂછો (ગુજરાતી)',
      'suggestions': [
        '📍 મારા વિસ્તાર મુજબ આજે કયો પાક વાવવો?',
        '🌾 ડાંગરમાં ગાભમારાની ઈયળનું નિયંત્રણ',
        '🍅 ટામેટામાં કોકડવા રોગનો ઈલાજ',
        '🍌 કેળાની લૂમ મોટી કરવા માટે ખાતર',
        '🌿 જીવામૃત બનાવવાની પદ્ધતિ',
        '🐛 કપાસમાં ગુલાબી ઈયળ નિયંત્રણ',
        '💧 ટપક સિંચાઈ પદ્ધતિ',
        '🌶️ મરચીમાં ફૂલ ખરતા અટકાવવા',
        '🌱 જમીન ચકાસણી અને સુધારણા',
      ],
    },
    'Punjabi': {
      'greeting':
          'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ! ਮੈਂ DoctorUzhavan.AI ਹਾਂ। ਖੇਤੀਬਾੜੀ, ਫ਼ਸਲਾਂ, ਕੀੜੇ-ਮਕੌੜੇ, ਖਾਦ ਜਾਂ ਮਿੱਟੀ ਸੰਬੰਧੀ ਕੋਈ ਵੀ ਸਵਾਲ ਪੁੱਛੋ!',
      'switched':
          'ਭਾਸ਼ਾ ਪੰਜਾਬੀ ਵਿੱਚ ਬਦਲ ਗਈ ਹੈ। ਫ਼ਸਲਾਂ ਬਾਰੇ ਸਵਾਲ ਪੁੱਛੋ ਜਾਂ ਬੋਲੋ!',
      'inputHint': 'ਖੇਤੀਬਾੜੀ ਸਵਾਲ ਪੁੱਛੋ ਜਾਂ ਬੋਲੋ...',
      'photoAttached': 'ਫ਼ੋਟੋ ਜੋੜੀ ਗਈ',
      'recordingText': 'ਪੰਜਾਬੀ ਵਿੱਚ ਸੁਣ ਰਿਹਾ ਹੈ... ਬੋਲੋ',
      'stopText': 'ਰੋਕੋ',
      'sendText': 'ਭੇਜੋ',
      'listenTooltip': 'ਆਵਾਜ਼ ਨਾਲ ਪੁੱਛੋ (ਪੰਜਾਬੀ)',
      'suggestions': [
        '📍 ਮੇਰੀ ਲੋਕੇਸ਼ਨ ਮੁਤਾਬਕ ਅੱਜ ਕਿਹੜੀ ਫ਼ਸਲ ਲਗਾਈਏ?',
        '🌾 ਝੋਨੇ ਵਿੱਚ ਤਣਾ ਛੇਦਕ ਦੀ ਰੋਕਥਾਮ',
        '🍅 ਟਮਾਟਰ ਦਾ ਪੱਤਾ ਮਰੋੜ ਰੋਗ ਇਲਾਜ',
        '🍌 ਕੇਲੇ ਦਾ ਗੁੱਛਾ ਵਧਾਉਣ ਦੇ ਤਰੀਕੇ',
        '🌿 ਜੀਵਾਮ੍ਰਿਤ ਬਣਾਉਣ ਦੀ ਵਿਧੀ',
        '🐛 ਨਰਮੇ ਵਿੱਚ ਗੁਲਾਬੀ ਸੁੰਡੀ ਦੀ ਰੋਕਥਾਮ',
        '💧 ਤੁਪਕਾ ਸਿੰਚਾਈ ਪ੍ਰਬੰਧਨ',
        '🌶️ ਮਿਰਚਾਂ ਦੇ ਫੁੱਲ ਝੜਨ ਤੋਂ ਰੋਕੋ',
        '🌱 ਮਿੱਟੀ ਦੀ ਪਰਖ ਅਤੇ ਸੁਧਾਰ',
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.selectedLanguage;
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _initTts();
    _initSpeech();
    _addInitialGreeting();
    // Preload weather asynchronously in the background so it never slows down chat
    WeatherService.fetchCurrentLocationWeather();
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageIndex = null;
        });
      }
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageIndex = null;
        });
      }
    });

    _flutterTts.setErrorHandler((_) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageIndex = null;
        });
      }
    });
  }

  /// Initialize Speech-To-Text and query available system speech engines
  Future<void> _initSpeech() async {
    try {
      final available = await _speechToText.initialize(
        onError: (error) {
          debugPrint(
              "STT Error: ${error.errorMsg} (permanent: ${error.permanent})");
          if (mounted) {
            setState(() {
              _isListening = false;
              _soundLevel = 0.0;
            });
          }
        },
        onStatus: (status) {
          debugPrint("STT Status: $status");
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
                _soundLevel = 0.0;
              });
            }
          }
        },
      );

      if (available) {
        final locales = await _speechToText.locales();
        _availableLocales = locales;
        _activeSpeechLocale = SpeechHelper.resolveSttLocale(
            _currentLanguage, _availableLocales);
      }

      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });
      }
    } catch (e) {
      debugPrint("STT initialization error: $e");
    }
  }

  void _addInitialGreeting() {
    final greeting = _langConfig[_currentLanguage]?['greeting'] ??
        _langConfig['English']!['greeting'];
    _messages.add({"sender": "ai", "text": greeting, "image": null});
  }

  void _onLanguageChanged(String? newLanguage) {
    if (newLanguage == null || newLanguage == _currentLanguage) return;

    _stopSpeaking();
    _stopListening();

    setState(() {
      _currentLanguage = newLanguage;
      _activeSpeechLocale = SpeechHelper.resolveSttLocale(
          _currentLanguage, _availableLocales);
      final switchNotice = _langConfig[_currentLanguage]?['switched'] ??
          "Language switched to $_currentLanguage.";
      _messages.add({"sender": "ai", "text": switchNotice, "image": null});
    });

    _scrollToBottom();
  }

  /// Toggle Speech Recognition recording
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  /// Start recording voice in the accurately matched language
  Future<void> _startListening() async {
    // 1. Immediately stop Text-To-Speech if active so it doesn't feed audio into the mic
    await _stopSpeaking();

    // 2. Check if speech engine is initialized, try re-initializing if not
    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _currentLanguage == 'Tamil'
                    ? "மைக்ரோஃபோன் அனுமதி அல்லது பேச்சு அறிதல் சேவை கிடைக்கவில்லை. அமைப்புகளில் அனுமதியை சரிபார்க்கவும்."
                    : _currentLanguage == 'Hindi'
                        ? "माइक्रोफ़ोन या स्पीच रिकग्निशन सेवा उपलब्ध नहीं है। कृपया ऐप सेटिंग जांचें।"
                        : "Microphone or Speech Recognition service not available. Please verify microphone permissions.",
              ),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return;
      }
    }

    // 3. Resolve exact locale ID matching the active language
    final localeToUse = SpeechHelper.resolveSttLocale(
        _currentLanguage, _availableLocales);
    _activeSpeechLocale = localeToUse;

    setState(() {
      _isListening = true;
      _soundLevel = 0.0;
    });

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() {
              _soundLevel = level;
            });
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: localeToUse,
          listenMode: stt.ListenMode.dictation,
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(seconds: 40),
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint("STT Listen error: $e");
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.isNotEmpty) {
      setState(() {
        _controller.text = result.recognizedWords;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
    }
  }

  Future<void> _stopAndSend() async {
    await _stopListening();
    if (_controller.text.trim().isNotEmpty || _selectedImageBytes != null) {
      _sendMessage();
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();

      img.Image? decoded = img.decodeImage(bytes);
      if (decoded != null) {
        img.Image resized = img.copyResize(decoded, width: 800);
        bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 80));
      }

      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _sendMessage({String? predefinedText}) async {
    if (_isListening) {
      await _stopListening();
    }

    final text = predefinedText ?? _controller.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;

    final Uint8List? attachedImage = _selectedImageBytes;

    String userDisplayText = text;
    if (userDisplayText.isEmpty) {
      switch (_currentLanguage) {
        case 'Tamil':
          userDisplayText = "இணைக்கப்பட்ட படத்தை ஆய்வு செய்க...";
          break;
        case 'Hindi':
          userDisplayText = "संलग्न फोटो का विश्लेषण करें...";
          break;
        case 'Marathi':
          userDisplayText = "जोडलेल्या फोटोचे विश्लेषण करा...";
          break;
        case 'Telugu':
          userDisplayText = "జతచేసిన ఫోటోను విశ్లేషించండి...";
          break;
        case 'Kannada':
          userDisplayText = "ಲಗತ್ತಿಸಲಾದ ಫೋಟೋವನ್ನು ವಿಶ್ಲೇಷಿಸಿ...";
          break;
        case 'Malayalam':
          userDisplayText = "ചേർത്ത ചിത്രം പരിശോധിക്കുക...";
          break;
        case 'Bengali':
          userDisplayText = "সংযুক্ত ছবিটি বিশ্লেষণ করুন...";
          break;
        case 'Gujarati':
          userDisplayText = "જોડેલ ફોટોનું વિશ્લેષણ કરો...";
          break;
        case 'Punjabi':
          userDisplayText = "ਨਾਲ ਲੱਗੀ ਫ਼ੋਟੋ ਦੀ ਜਾਂਚ ਕਰੋ...";
          break;
        default:
          userDisplayText = "Analyzed attached image...";
      }
    }

    setState(() {
      _messages.add({
        "sender": "user",
        "text": userDisplayText,
        "image": attachedImage,
      });
      _isLoading = true;
      _selectedImageBytes = null;
    });

    if (predefinedText == null) {
      _controller.clear();
    }
    _scrollToBottom();

    // Non-blocking location context
    if (!WeatherService.hasCachedWeather) {
      await WeatherService.fetchCurrentLocationWeather();
    }

    final double? lat = WeatherService.cachedLat;
    final double? lng = WeatherService.cachedLng;
    final double? temp = WeatherService.cachedTemp;
    final String? locName = WeatherService.cachedLocationName;
    final bool isDefault = WeatherService.isUsingDefaultLocation;

    // Call Cloud AI Service with strict selected language & dynamic live location
    String aiResponse = await CloudAIService.askAgricultureAssistant(
      userQuery: text.isEmpty ? userDisplayText : text,
      selectedLanguage: _currentLanguage,
      locationName: locName,
      userLat: lat,
      userLng: lng,
      currentTemp: temp,
      isDefaultLocation: isDefault,
      imageBytes: attachedImage,
    );

    if (mounted) {
      final newIndex = _messages.length;
      setState(() {
        _messages.add({"sender": "ai", "text": aiResponse, "image": null});
        _isLoading = false;
      });
      _scrollToBottom();
      _speakText(aiResponse, newIndex);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _speakText(String text, int messageIndex) async {
    if (text.isEmpty) return;

    if (_isSpeaking && _speakingMessageIndex == messageIndex) {
      await _stopSpeaking();
      return;
    }

    await _stopSpeaking();

    String cleanSpokenText = SpeechHelper.cleanTextForSpeech(text);
    if (cleanSpokenText.isEmpty) return;

    String langCode = SpeechHelper.getLanguageCode(_currentLanguage);

    setState(() {
      _isSpeaking = true;
      _speakingMessageIndex = messageIndex;
    });

    try {
      await _flutterTts.setLanguage(langCode);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.44);
      await _flutterTts.speak(cleanSpokenText);
    } catch (e) {
      debugPrint("TTS Error: $e");
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingMessageIndex = null;
        });
      }
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _speakingMessageIndex = null;
      });
    }
  }

  /// Builds oscillating audio recording waves that dynamically react to speech levels
  Widget _buildRecordingWaves() {
    // 17 symmetrical waveform bars
    final waveWeights = [
      0.2, 0.35, 0.55, 0.75, 0.9, 0.6, 0.85, 1.0, 0.85, 0.6, 0.9, 0.75, 0.55, 0.35, 0.2
    ];

    return AnimatedBuilder(
      animation: _waveAnimController,
      builder: (context, child) {
        final double micNormalized = (_soundLevel.clamp(0.0, 10.0) / 10.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(waveWeights.length, (index) {
            // Dynamic sine wave offset per bar
            final double phase =
                (index * 0.45) + (_waveAnimController.value * 2 * math.pi);
            final double osc = (0.5 + 0.5 * math.sin(phase)).clamp(0.15, 1.0);

            // Compute responsive wave height
            const double baseHeight = 6.0;
            final double dynamicMax = 28.0 * waveWeights[index];
            final double waveHeight = baseHeight +
                (dynamicMax * osc * (0.35 + (micNormalized * 0.65)));

            final bool isHot = micNormalized > 0.35;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.2),
              width: 3.5,
              height: waveHeight.clamp(5.0, 36.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: isHot
                      ? [const Color(0xFF2E7D32), Colors.greenAccent.shade400]
                      : [const Color(0xFF1B5E20), const Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isHot
                    ? [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        )
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    _waveAnimController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _stopSpeaking();
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig =
        _langConfig[_currentLanguage] ?? _langConfig['English']!;
    final List<dynamic> suggestions = currentConfig['suggestions'] ?? [];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, color: Color(0xFF81C784), size: 22),
            const SizedBox(width: 6),
            const Text(
              'DoctorUzhavan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white70, width: 0.8),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          // Small compact language switch button
          Container(
            margin: const EdgeInsets.only(right: 10, top: 11, bottom: 11),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white38, width: 0.8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentLanguage,
                isDense: true,
                dropdownColor: const Color(0xFF1B5E20),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Colors.white70, size: 16),
                selectedItemBuilder: (BuildContext context) {
                  return _supportedLanguages.map<Widget>((String lang) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language,
                            color: Colors.white70, size: 13),
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
                items: _supportedLanguages.map((String lang) {
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
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                final Uint8List? imgBytes = msg["image"];
                final bool isThisSpeaking =
                    _isSpeaking && _speakingMessageIndex == index;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF2E7D32) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imgBytes != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              imgBytes,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          msg["text"] ?? "",
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () =>
                                    _speakText(msg["text"] ?? "", index),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isThisSpeaking
                                        ? const Color(0xFFFFEBEE)
                                        : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isThisSpeaking
                                            ? Icons.stop_circle_rounded
                                            : Icons.volume_up,
                                        color: isThisSpeaking
                                            ? Colors.red
                                            : const Color(0xFF2E7D32),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isThisSpeaking
                                            ? (_currentLanguage == 'Tamil'
                                                ? "நிறுத்து"
                                                : _currentLanguage == 'Hindi'
                                                    ? "रोकें"
                                                    : _currentLanguage ==
                                                            'Marathi'
                                                        ? "थांबवा"
                                                        : "Stop")
                                            : (_currentLanguage == 'Tamil'
                                                ? "கேட்க"
                                                : _currentLanguage == 'Hindi'
                                                    ? "सुनें"
                                                    : _currentLanguage ==
                                                            'Marathi'
                                                        ? "ऐका"
                                                        : "Listen"),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isThisSpeaking
                                              ? Colors.red
                                              : const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text("DoctorUzhavan-AI is Responding...",
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),

          // Attached Image Preview
          if (_selectedImageBytes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    currentConfig['photoAttached'] ?? "Photo attached",
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _selectedImageBytes = null),
                  )
                ],
              ),
            ),

          // Localized Suggestion Chips
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: const Color(0xFFF1F8E9),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestionText = suggestions[index] as String;
                return ActionChip(
                  label: Text(
                    suggestionText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFC8E6C9)),
                  onPressed: _isLoading
                      ? null
                      : () {
                          final cleanQuery = suggestionText
                              .replaceAll(
                                  RegExp(
                                      r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
                                      unicode: true),
                                  '')
                              .trim();
                          _sendMessage(
                              predefinedText: cleanQuery.isNotEmpty
                                  ? cleanQuery
                                  : suggestionText);
                        },
                );
              },
            ),
          ),

          // Active Voice Recording Indicator & Animated Recording Waves
          if (_isListening)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Pulsing red REC badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.redAccent, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "REC",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Active language label
                      Expanded(
                        child: Text(
                          "🎙️ $_currentLanguage (${SpeechHelper.getNativeLanguageName(_currentLanguage)}) • $_activeSpeechLocale",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Stop button
                      OutlinedButton.icon(
                        onPressed: _stopListening,
                        icon:
                            const Icon(Icons.stop, color: Colors.red, size: 15),
                        label: Text(
                          currentConfig['stopText'] ?? "Stop",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          side: const BorderSide(color: Colors.redAccent),
                          backgroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Send button
                      ElevatedButton.icon(
                        onPressed: _stopAndSend,
                        icon: const Icon(Icons.send,
                            color: Colors.white, size: 13),
                        label: Text(
                          currentConfig['sendText'] ?? "Send",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          backgroundColor: const Color(0xFF2E7D32),
                          elevation: 1,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ANIMATED VOICE RECORDING WAVES
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Center(
                      child: _buildRecordingWaves(),
                    ),
                  ),

                  // Real-time captured words preview
                  if (_controller.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        _controller.text,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Message Input Field & Voice Record Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_a_photo, color: Color(0xFF2E7D32)),
                  onPressed: _pickImage,
                  tooltip: "Attach Crop Photo",
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: currentConfig['inputHint'] ??
                          "Ask or record any farming question...",
                      hintStyle:
                          const TextStyle(fontSize: 14, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                // Voice Recording Microphone Button
                Tooltip(
                  message: _isListening
                      ? (currentConfig['stopText'] ?? "Stop Recording")
                      : (currentConfig['listenTooltip'] ?? "Record Voice"),
                  child: InkWell(
                    onTap: _toggleListening,
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening
                              ? Colors.redAccent
                              : const Color(0xFF2E7D32),
                          width: _isListening ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Colors.redAccent
                            : const Color(0xFF2E7D32),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
