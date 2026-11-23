import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';

class UpdateInfo {
  final String version;
  final int? versionCode;
  final String title;
  final String releaseNotes;
  final String apkUrl;
  final bool isForceUpdate;

  const UpdateInfo({
    required this.version,
    this.versionCode,
    required this.title,
    required this.releaseNotes,
    required this.apkUrl,
    this.isForceUpdate = false,
  });
}

class UpdateService {
  /// Current installed application version (matches pubspec.yaml)
  static const String currentVersion = "1.0.0";
  static const int currentVersionCode = 1;

  /// GitHub Repository Configuration (can be customized in api_config.dart)
  static String githubOwner = ApiConfig.githubOwner;
  static String githubRepo = ApiConfig.githubRepo;

  // Cache to avoid repeatedly asking user in the same session
  static bool _hasPromptedThisSession = false;

  /// Checks if a newer version exists on GitHub Releases or raw version.json
  static Future<UpdateInfo?> checkLatestVersion() async {
    try {
      // 1. Primary: Try GitHub Releases API
      final releaseApiUrl = Uri.parse(
        'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest',
      );

      final response = await http
          .get(releaseApiUrl, headers: {'Accept': 'application/vnd.github.v3+json'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String tagName = (data['tag_name'] as String?) ?? '';
        final String rawVersion = tagName.replaceAll(RegExp(r'[^0-9.]'), '');

        if (isNewerVersion(rawVersion, currentVersion)) {
          // Look for .apk asset in release
          String apkUrl = '';
          if (data['assets'] is List && (data['assets'] as List).isNotEmpty) {
            for (var asset in data['assets']) {
              final name = (asset['name'] as String?)?.toLowerCase() ?? '';
              if (name.endsWith('.apk')) {
                apkUrl = (asset['browser_download_url'] as String?) ?? '';
                break;
              }
            }
          }

          if (apkUrl.isEmpty) {
            apkUrl =
                'https://github.com/$githubOwner/$githubRepo/releases/download/$tagName/doctoruzhavan.apk';
          }

          final String title =
              (data['name'] as String?)?.trim().isNotEmpty == true
                  ? data['name']
                  : "DoctorUzhavan $tagName";

          final String body = (data['body'] as String?)?.trim() ?? '';

          return UpdateInfo(
            version: rawVersion.isNotEmpty ? rawVersion : tagName,
            title: title,
            releaseNotes: body,
            apkUrl: apkUrl,
            isForceUpdate: body.toLowerCase().contains("[force_update]"),
          );
        }
      }
    } catch (e) {
      debugPrint("GitHub Releases API check error: $e");
    }

    // 2. Secondary Fallback: Try checking version.json on GitHub raw
    try {
      final rawJsonUrl = Uri.parse(
        'https://raw.githubusercontent.com/$githubOwner/$githubRepo/main/version.json',
      );

      final response =
          await http.get(rawJsonUrl).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String remoteVersion = (data['version'] as String?) ?? '';
        final int remoteCode = (data['versionCode'] as num?)?.toInt() ?? 0;

        if (remoteCode > currentVersionCode ||
            isNewerVersion(remoteVersion, currentVersion)) {
          return UpdateInfo(
            version: remoteVersion,
            versionCode: remoteCode,
            title: data['title'] ?? "DoctorUzhavan Update",
            releaseNotes: data['releaseNotes'] is Map
                ? (data['releaseNotes']['English'] ?? '')
                : (data['releaseNotes'] ?? ''),
            apkUrl: data['apkUrl'] ??
                'https://github.com/$githubOwner/$githubRepo/releases/latest/download/doctoruzhavan.apk',
            isForceUpdate: data['forceUpdate'] == true,
          );
        }
      }
    } catch (e) {
      debugPrint("Fallback version.json check error: $e");
    }

    return null;
  }

  /// Compares semantic versions (e.g. 1.0.1 > 1.0.0)
  static bool isNewerVersion(String latest, String current) {
    if (latest.isEmpty || current.isEmpty) return false;

    final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');

    final latestParts =
        cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts =
        cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (latestParts.length < 3) {
      latestParts.add(0);
    }
    while (currentParts.length < 3) {
      currentParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  /// Automatically or manually prompts the farmer to update
  static Future<void> checkForUpdates(
    BuildContext context, {
    required String selectedLanguage,
    bool isManualCheck = false,
  }) async {
    if (!isManualCheck && _hasPromptedThisSession) return;

    if (isManualCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(_getCheckMessage(selectedLanguage)),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    final updateInfo = await checkLatestVersion();

    if (!context.mounted) return;

    if (updateInfo != null) {
      _hasPromptedThisSession = true;
      showDialog(
        context: context,
        barrierDismissible: !updateInfo.isForceUpdate,
        builder: (ctx) => _buildUpdateDialog(ctx, updateInfo, selectedLanguage),
      );
    } else if (isManualCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getUpToDateMessage(selectedLanguage)),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  /// Launches the download URL directly in the Android browser / Download manager
  static Future<void> downloadAndInstallApk(String apkUrl) async {
    final uri = Uri.parse(apkUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Failed to launch APK download URL: $e");
    }
  }

  /// Builds the localized update dialog
  static Widget _buildUpdateDialog(
    BuildContext context,
    UpdateInfo info,
    String language,
  ) {
    final dialogTexts = _getLocalizedDialogTexts(language);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: Color(0xFF2E7D32),
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dialogTexts['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "v$currentVersion",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Color(0xFF2E7D32)),
                ),
                Text(
                  "v${info.version}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dialogTexts['description']!,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          if (info.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                info.releaseNotes,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  height: 1.35,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!info.isForceUpdate)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              dialogTexts['later']!,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            downloadAndInstallApk(info.apkUrl);
          },
          icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
          label: Text(
            dialogTexts['updateNow']!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  static String _getCheckMessage(String lang) {
    switch (lang) {
      case 'Tamil':
        return "புதிய பதிப்பைச் சரிபார்க்கிறது...";
      case 'Hindi':
        return "नए अपडेट की जांच की जा रही है...";
      case 'Marathi':
        return "नवीन अपडेट तपासत आहे...";
      default:
        return "Checking for updates...";
    }
  }

  static String _getUpToDateMessage(String lang) {
    switch (lang) {
      case 'Tamil':
        return "DoctorUzhavan ஏற்கனவே புதிய பதிப்பில் உள்ளது (v$currentVersion).";
      case 'Hindi':
        return "DoctorUzhavan पहले से ही नवीनतम संस्करण में है (v$currentVersion)।";
      case 'Marathi':
        return "DoctorUzhavan आधीच नवीनतम आवृत्तीवर आहे (v$currentVersion).";
      default:
        return "DoctorUzhavan is up to date (v$currentVersion).";
    }
  }

  static Map<String, String> _getLocalizedDialogTexts(String lang) {
    switch (lang) {
      case 'Tamil':
        return {
          'title': 'புதிய பதிப்பு கிடைக்கிறது!',
          'description':
              'DoctorUzhavan-ன் புதிய அம்சங்கள், பூச்சி மருந்துகள் மற்றும் மேம்பாடுகளுடன் புதிய பதிப்பு வந்துள்ளது.',
          'updateNow': 'இப்போதே புதுப்பிக்கவும்',
          'later': 'பிறகு',
        };
      case 'Hindi':
        return {
          'title': 'नया अपडेट उपलब्ध है!',
          'description':
              'DoctorUzhavan का नया संस्करण नई सुविधाओं, फसल उपचार और सुधारों के साथ उपलब्ध है।',
          'updateNow': 'अभी अपडेट करें',
          'later': 'बाद में',
        };
      case 'Marathi':
        return {
          'title': 'नवीन अपडेट उपलब्ध आहे!',
          'description':
              'DoctorUzhavan ची नवीन आवृत्ती नवीन औषधे आणि सुधारणांसह उपलब्ध आहे.',
          'updateNow': 'आता अपडेट करा',
          'later': 'नंतर',
        };
      case 'Telugu':
        return {
          'title': 'కొత్త అప్‌డేట్ అందుబాటులో ఉంది!',
          'description':
              'DoctorUzhavan కొత్త ఫీచర్లు మరియు పంట చికిత్సలతో కొత్త వెర్షన్ అందుబాటులోకి వచ్చింది.',
          'updateNow': 'ఇప్పుడే అప్‌డేట్ చేయండి',
          'later': 'తరువాత',
        };
      case 'Kannada':
        return {
          'title': 'ಹೊಸ ಆವೃತ್ತಿ ಲಭ್ಯವಿದೆ!',
          'description':
              'DoctorUzhavan ಹೊಸ ವೈಶಿಷ್ಟ್ಯಗಳು ಮತ್ತು ಬೆಳೆ ರೋಗ ಪರಿಹಾರಗಳೊಂದಿಗೆ ಲಭ್ಯವಿದೆ.',
          'updateNow': 'ಈಗಲೇ ನವೀಕರಿಸಿ',
          'later': 'ನಂತರ',
        };
      case 'Malayalam':
        return {
          'title': 'പുതിയ അപ്ഡേറ്റ് ലഭ്യമാണ്!',
          'description':
              'DoctorUzhavan പുതിയ സവിശേഷതകളോടെ ഏറ്റവും പുതിയ പതിപ്പ് ലഭ്യമാണ്.',
          'updateNow': 'ഇപ്പോൾ അപ്ഡേറ്റ് ചെയ്യുക',
          'later': 'പിന്നീട്',
        };
      case 'Bengali':
        return {
          'title': 'নতুন আপডেট উপলব্ধ!',
          'description':
              'DoctorUzhavan-এর নতুন সংস্করণ নতুন বৈশিষ্ট্য ও ফসলের চিকিৎসা সহ উপলব্ধ।',
          'updateNow': 'এখনই আপডেট করুন',
          'later': 'পরে',
        };
      case 'Gujarati':
        return {
          'title': 'નવું અપડેટ ઉપલબ્ધ છે!',
          'description':
              'DoctorUzhavan નું નવું વર્ઝન નવી સુવિધાઓ અને પાક સારવાર સાથે ઉપલબ્ધ છે.',
          'updateNow': 'હવે અપડેટ કરો',
          'later': 'પછી',
        };
      case 'Punjabi':
        return {
          'title': 'ਨਵਾਂ ਅੱਪਡੇਟ ਉਪਲਬਧ ਹੈ!',
          'description':
              'DoctorUzhavan ਦਾ ਨਵਾਂ ਵਰਜਨ ਨਵੀਆਂ ਸਹੂਲਤਾਂ ਅਤੇ ਫ਼ਸਲ ਇਲਾਜ ਨਾਲ ਉਪਲਬਧ ਹੈ।',
          'updateNow': 'ਹੁਣੇ ਅੱਪਡੇਟ ਕਰੋ',
          'later': 'ਬਾਅਦ ਵਿੱਚ',
        };
      case 'English':
      default:
        return {
          'title': 'New Update Available!',
          'description':
              'A newer version of DoctorUzhavan is available with new crop remedies, AI enhancements, and features.',
          'updateNow': 'Update Now',
          'later': 'Later',
        };
    }
  }
}
