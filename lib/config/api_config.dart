/// Centralized API configuration for DoctorUzhavan.
/// 
/// Keys are safely read from environment variables injected at build/run time.
/// This ensures your real API keys are NEVER committed to GitHub or public repositories.
///
/// To run or build with your keys:
///   flutter run --dart-define-from-file=secrets.json
///   flutter build apk --release --dart-define-from-file=secrets.json
///
/// (Or simply use VS Code's Run / Debug, which is preconfigured in .vscode/launch.json)
class ApiConfig {
  /// Primary Google Gemini API Key
  static const String geminiPrimaryKey = String.fromEnvironment(
    'GEMINI_PRIMARY_KEY',
    defaultValue: '',
  );

  /// Backup Google Gemini API Key (for high-availability failover)
  static const String geminiBackupKey = String.fromEnvironment(
    'GEMINI_BACKUP_KEY',
    defaultValue: '',
  );

  /// OpenWeatherMap API Key
  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: '',
  );

  /// GitHub Repository Owner for in-app automatic updates
  static const String githubOwner = String.fromEnvironment(
    'GITHUB_OWNER',
    defaultValue: 'Barathram-B',
  );

  /// GitHub Repository Name for in-app automatic updates
  static const String githubRepo = String.fromEnvironment(
    'GITHUB_REPO',
    defaultValue: 'Doctor-Uzhavan',
  );
}
