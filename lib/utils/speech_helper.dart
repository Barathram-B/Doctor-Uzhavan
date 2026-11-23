import 'package:speech_to_text/speech_to_text.dart';

class SpeechHelper {
  /// Cleans raw AI markdown text so Text-To-Speech (TTS) speaks naturally
  /// without reading out asterisks (**), hashes (###), bullet points, or symbols.
  static String cleanTextForSpeech(String rawText) {
    if (rawText.isEmpty) return "";

    String cleaned = rawText;

    // 1. Remove markdown bold/italic asterisks: ***text***, **text**, *text*
    cleaned = cleaned.replaceAll(RegExp(r'\*+'), ' ');

    // 2. Remove markdown headers: # Header, ## Subheader, ### Title
    cleaned = cleaned.replaceAll(RegExp(r'#+\s*'), ' ');

    // 3. Remove code blocks and inline backticks
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    cleaned = cleaned.replaceAll('`', ' ');

    // 4. Remove URLs
    cleaned = cleaned.replaceAll(RegExp(r'https?:\/\/\S+'), ' ');

    // 5. Remove markdown bullet points (- item, + item, * item)
    cleaned = cleaned.replaceAll(RegExp(r'^[ \t]*[-+*]\s+', multiLine: true), '');

    // 6. Remove numbered list prefixes like "1. " or "2) "
    cleaned = cleaned.replaceAll(RegExp(r'^[ \t]*\d+[\.\)]\s+', multiLine: true), '');

    // 7. Remove markdown link markup: [Text](url) -> Text
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');

    // 8. Remove troublesome brackets, symbols and underscores that TTS spells out
    cleaned = cleaned.replaceAll(RegExp(r'[_~|<>\[\]\(\)\{\}\\]'), ' ');

    // 9. Remove emojis that TTS might speak in English unexpectedly
    cleaned = cleaned.replaceAll(
      RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true),
      ' ',
    );

    // 10. Replace multiple colons, dashes or slashes with a pause comma
    cleaned = cleaned.replaceAll(RegExp(r'[:—–]+'), ', ');
    cleaned = cleaned.replaceAll(RegExp(r'-+'), ' ');

    // 11. Collapse multiple spaces and newlines into single spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Get the standard TTS language code for all supported languages
  static String getLanguageCode(String language) {
    switch (language) {
      case 'Tamil':
        return 'ta-IN';
      case 'Hindi':
        return 'hi-IN';
      case 'Marathi':
        return 'mr-IN';
      case 'Telugu':
        return 'te-IN';
      case 'Kannada':
        return 'kn-IN';
      case 'Malayalam':
        return 'ml-IN';
      case 'Bengali':
        return 'bn-IN';
      case 'Gujarati':
        return 'gu-IN';
      case 'Punjabi':
        return 'pa-IN';
      case 'English':
      default:
        return 'en-IN';
    }
  }

  /// Get native language name for UI display
  static String getNativeLanguageName(String language) {
    switch (language) {
      case 'Tamil':
        return 'தமிழ்';
      case 'Hindi':
        return 'हिन्दी';
      case 'Marathi':
        return 'मराठी';
      case 'Telugu':
        return 'తెలుగు';
      case 'Kannada':
        return 'ಕನ್ನಡ';
      case 'Malayalam':
        return 'മലയാളം';
      case 'Bengali':
        return 'বাংলা';
      case 'Gujarati':
        return 'ગુજરાતી';
      case 'Punjabi':
        return 'ਪੰਜਾਬੀ';
      case 'English':
      default:
        return 'English';
    }
  }

  /// Language code prefix for locale resolution
  static String getLocalePrefix(String language) {
    switch (language) {
      case 'Tamil':
        return 'ta';
      case 'Hindi':
        return 'hi';
      case 'Marathi':
        return 'mr';
      case 'Telugu':
        return 'te';
      case 'Kannada':
        return 'kn';
      case 'Malayalam':
        return 'ml';
      case 'Bengali':
        return 'bn';
      case 'Gujarati':
        return 'gu';
      case 'Punjabi':
        return 'pa';
      case 'English':
      default:
        return 'en';
    }
  }

  /// Accurately resolves the best available Speech-To-Text locale on the device.
  /// Matches exact regional variants (e.g. ta_IN, hi_IN) from available device engines.
  static String resolveSttLocale(String language, List<LocaleName> systemLocales) {
    final prefix = getLocalePrefix(language);

    if (systemLocales.isNotEmpty) {
      // 1. Look for precise India region match e.g. ta_IN or ta-IN
      for (final loc in systemLocales) {
        final normalized = loc.localeId.toLowerCase().replaceAll('-', '_');
        if (normalized == '${prefix}_in') {
          return loc.localeId;
        }
      }

      // 2. Look for any match starting with the prefix (e.g. ta_LK, ta)
      for (final loc in systemLocales) {
        final normalized = loc.localeId.toLowerCase().replaceAll('-', '_');
        if (normalized.startsWith('${prefix}_') || normalized == prefix) {
          return loc.localeId;
        }
      }

      // 3. For English, fallback to en_US or en_GB if en_IN not found
      if (prefix == 'en') {
        for (final loc in systemLocales) {
          final normalized = loc.localeId.toLowerCase().replaceAll('-', '_');
          if (normalized.startsWith('en')) {
            return loc.localeId;
          }
        }
      }
    }

    // Default standard codes if system locales list is empty or unpopulated
    switch (language) {
      case 'Tamil':
        return 'ta_IN';
      case 'Hindi':
        return 'hi_IN';
      case 'Marathi':
        return 'mr_IN';
      case 'Telugu':
        return 'te_IN';
      case 'Kannada':
        return 'kn_IN';
      case 'Malayalam':
        return 'ml_IN';
      case 'Bengali':
        return 'bn_IN';
      case 'Gujarati':
        return 'gu_IN';
      case 'Punjabi':
        return 'pa_IN';
      case 'English':
      default:
        return 'en_IN';
    }
  }
}
