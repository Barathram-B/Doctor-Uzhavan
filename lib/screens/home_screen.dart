import 'package:flutter/material.dart';
import 'disease_scan_screen.dart';
import 'harvest_scan_screen.dart';
import 'chat_bot_screen.dart';
import '../utils/speech_helper.dart';
import '../services/update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _selectedLanguage = 'English';
  late AnimationController _animController;
  late Animation<double> _bounceAnimation;

  final Map<String, Map<String, String>> _localizedStrings = {
    'English': {
      'welcome': 'Welcome!',
      'instruction': 'Select an action below to scan your crop or calculate harvest time.',
      'diseaseTitle': 'Crop Health & Disease',
      'diseaseSubtitle': 'Identify leaf disease & remedy',
      'harvestTitle': 'Harvest Date Finder',
      'harvestSubtitle': 'Predict harvest & maturity date',
    },
    'Tamil': {
      'welcome': 'வணக்கம்!',
      'instruction': 'உங்கள் பயிரை ஆய்வு செய்ய அல்லது அறுவடை நேரத்தைக் கணக்கிட கீழே தேர்ந்தெடுக்கவும்.',
      'diseaseTitle': 'பயிர் நோய் அறிதல்',
      'diseaseSubtitle': 'நோய் மற்றும் மருந்துகளை அறிதல்',
      'harvestTitle': 'அறுவடை நாள் கணக்கீடு',
      'harvestSubtitle': 'அறுவடை செய்யும் நாளைக் கணித்தல்',
    },
    'Marathi': {
      'welcome': 'नमस्कार!',
      'instruction': 'तुमच्या पिकाची तपासणी करण्यासाठी किंवा काढणीची वेळ काढण्यासाठी खालील पर्याय निवडा.',
      'diseaseTitle': 'पिक आरोग्य व रोग',
      'diseaseSubtitle': 'पानावरील रोग आणि उपाय शोधा',
      'harvestTitle': 'काढणीची तारीख शोधक',
      'harvestSubtitle': 'पिकाच्या काढणीची तारीख ठरवा',
    },
    'Hindi': {
      'welcome': 'नमस्ते!',
      'instruction': 'अपनी फसल की जांच या कटाई का समय जानने के लिए नीचे एक विकल्प चुनें।',
      'diseaseTitle': 'फसल स्वास्थ्य एवं रोग',
      'diseaseSubtitle': 'पत्ती के रोग और उपाय पहचानें',
      'harvestTitle': 'कटाई की तिथि खोजक',
      'harvestSubtitle': 'फसल पकने की तिथि ज्ञात करें',
    },
    'Telugu': {
      'welcome': 'స్వాగతం!',
      'instruction': 'మీ పంటను పరీక్షించడానికి లేదా కోత సమయాన్ని లెక్కించడానికి ఎంచుకోండి.',
      'diseaseTitle': 'పంట ఆరోగ్యం & తెగుళ్లు',
      'diseaseSubtitle': 'ఆకు తెగులు & నివారణ గుర్తించండి',
      'harvestTitle': 'కోత తేదీ గుర్తింపు',
      'harvestSubtitle': 'పంట కోత తేదీని అంచనా వేయండి',
    },
    'Kannada': {
      'welcome': 'ಸುಸ್ವಾಗತ!',
      'instruction': 'ಬೆಳೆ ಪರಿಶೀಲಿಸಲು ಅಥವಾ ಕೊಯ್ಲು ಸಮಯ ಲೆಕ್ಕಾಚಾರ ಮಾಡಲು ಆಯ್ಕೆಮಾಡಿ.',
      'diseaseTitle': 'ಬೆಳೆ ಆರೋಗ್ಯ & ರೋಗ',
      'diseaseSubtitle': 'ಎಲೆ ರೋಗ ಮತ್ತು ಪರಿಹಾರ ಗುರುತಿಸಿ',
      'harvestTitle': 'ಕೊಯ್ಲು ದಿನಾಂಕ ಶೋಧಕ',
      'harvestSubtitle': 'ಬೆಳೆ ಕೊಯ್ಲು ದಿನಾಂಕ ಊಹಿಸಿ',
    },
    'Malayalam': {
      'welcome': 'സ്വാഗതം!',
      'instruction': 'വിള പരിശോധിക്കുന്നതിനും വിളവെടുപ്പ് സമയം കണക്കാക്കുന്നതിനും തിരഞ്ഞെടുക്കുക.',
      'diseaseTitle': 'വിള ആരോഗ്യവും രോഗവും',
      'diseaseSubtitle': 'ഇല രോഗവും പ്രതിവിധിയും കണ്ടെത്തുക',
      'harvestTitle': 'വിളവെടുപ്പ് തീയതി കണ്ടെത്തൽ',
      'harvestSubtitle': 'വിളവെടുപ്പ് സമയം പ്രവചിക്കുക',
    },
    'Bengali': {
      'welcome': 'স্বাগতম!',
      'instruction': 'আপনার ফসল পরীক্ষা করতে বা ফসল তোলার সময় গণনা করতে বেছে নিন।',
      'diseaseTitle': 'ফসলের স্বাস্থ্য ও রোগ',
      'diseaseSubtitle': 'পাতার রোগ ও প্রতিকার শনাক্ত করুন',
      'harvestTitle': 'ফসল কাটার তারিখ নির্ধারক',
      'harvestSubtitle': 'ফসল কাটার সময় অনুমান করুন',
    },
    'Gujarati': {
      'welcome': 'સ્વાગત છે!',
      'instruction': 'તમારા પાકની તપાસ કરવા અથવા લણણીનો સમય ગણવા માટે પસંદ કરો.',
      'diseaseTitle': 'પાક આરોગ્ય અને રોગ',
      'diseaseSubtitle': 'પાંદડાના રોગ અને ઉપાય ઓળખો',
      'harvestTitle': 'લણણી તારીખ શોધક',
      'harvestSubtitle': 'પાક લણણી સમયની ગણતરી કરો',
    },
    'Punjabi': {
      'welcome': 'ਜੀ ਆਇਆਂ ਨੂੰ!',
      'instruction': 'ਆਪਣੀ ਫ਼ਸਲ ਦੀ ਜਾਂਚ ਜਾਂ ਕਟਾਈ ਦਾ ਸਮਾਂ ਜਾਣਨ ਲਈ ਚੁਣੋ।',
      'diseaseTitle': 'ਫ਼ਸਲ ਸਿਹਤ ਅਤੇ ਬਿਮਾਰੀ',
      'diseaseSubtitle': 'ਪੱਤਿਆਂ ਦੀ ਬਿਮਾਰੀ ਅਤੇ ਉਪਾਅ ਪਛਾਣੋ',
      'harvestTitle': 'ਕਟਾਈ ਮਿਤੀ ਖੋਜਕ',
      'harvestSubtitle': 'ਫ਼ਸਲ ਕਟਾਈ ਦਾ ਅਨੁਮਾਨ ਲਗਾਓ',
    },
  };

  @override
  void initState() {
    super.initState();
    // Setup subtle jumping/bouncing animation for DoctorUzhavan.AI button
    _animController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Silently check for new app updates in the background on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(
        context,
        selectedLanguage: _selectedLanguage,
        isManualCheck: false,
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = _localizedStrings[_selectedLanguage] ?? _localizedStrings['English']!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.eco, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'DoctorUzhavan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 21),
            tooltip: "Check for Updates",
            onPressed: () {
              UpdateService.checkForUpdates(
                context,
                selectedLanguage: _selectedLanguage,
                isManualCheck: true,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 80, 150, 82),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white30, width: 0.8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isDense: true,
                  dropdownColor: const Color(0xFF2E7D32),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                  selectedItemBuilder: (BuildContext context) {
                    return [
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
                    ].map<Widget>((String lang) {
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
                  items: [
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
                  ].map((String lang) {
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
                  onChanged: (String? newLanguage) {
                    if (newLanguage != null) {
                      setState(() {
                        _selectedLanguage = newLanguage;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      // --- FLOATING BOUNCING DOCTORUZHAVAN.AI BUTTON ---
      floatingActionButton: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_bounceAnimation.value),
            child: child,
          );
        },
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatBotScreen(selectedLanguage: _selectedLanguage),
              ),
            );
          },
          backgroundColor: const Color(0xFF1B5E20),
          icon: const Icon(Icons.smart_toy, color: Colors.white, size: 26),
          label: const Text(
            "DoctorUzhavan.AI",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
      // --- FULL SCREEN BACKGROUND IMAGE DECORATION ---
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/home_bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withValues(alpha: 0.12), // Subtle dark tint for clarity
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        texts['welcome']!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        texts['instruction']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Color(0x99000000)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                _buildCircularActionButton(
                  title: texts['diseaseTitle']!,
                  subtitle: texts['diseaseSubtitle']!,
                  iconAssetPath: "assets/icons/disease_icon.png",
                  fallbackIcon: Icons.bug_report,
                  circleColor: const Color(0xFF2E7D32),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiseaseScanScreen(selectedLanguage: _selectedLanguage),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                _buildCircularActionButton(
                  title: texts['harvestTitle']!,
                  subtitle: texts['harvestSubtitle']!,
                  iconAssetPath: "assets/icons/harvest_icon.png",
                  fallbackIcon: Icons.calendar_month,
                  circleColor: const Color(0xFF4CAF50),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HarvestScanScreen(selectedLanguage: _selectedLanguage),
                      ),
                    );
                  },
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularActionButton({
    required String title,
    required String subtitle,
    required String iconAssetPath,
    required IconData fallbackIcon,
    required Color circleColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(70),
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: circleColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Image.asset(
                  iconAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(fallbackIcon, size: 50, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0x8A000000)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}