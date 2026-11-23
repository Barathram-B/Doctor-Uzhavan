# 🌱 DoctorUzhavan (DoctorUzhavan.AI)

**Smart Hybrid Agriculture Assistant for Farmers**

DoctorUzhavan is an intelligent, multi-lingual agricultural companion designed to empower farmers with real-time AI guidance, crop disease detection, voice-driven interaction, and harvest date forecasting across India and globally.

---

## 🚀 Key Features

* **🌾 Multi-Lingual AI Agriculture Scientist (DoctorUzhavan.AI)**
  - Powered by Google Gemini AI with agricultural knowledge, authentic fertilizer dosages, chemical/organic remedies, and localized retail market rates in ₹ INR.
  - Contextual awareness: Considers the farmer's live GPS coordinates, local weather, current month, and active regional planting seasons.

* **🎙️ Accurate Voice Recording & Speech Capture (10 Languages)**
  - Interactive tap-to-talk voice recording with live acoustic waveform visualizer bars that surge dynamically with speech volume.
  - Precision regional speech recognition tuned for:
    - **Tamil (தமிழ்)** - `ta-IN`
    - **Hindi (हिन्दी)** - `hi-IN`
    - **Marathi (मराठी)** - `mr-IN`
    - **Telugu (తెలుగు)** - `te-IN`
    - **Kannada (ಕನ್ನಡ)** - `kn-IN`
    - **Malayalam (മലയാളം)** - `ml-IN`
    - **Bengali (বাংলা)** - `bn-IN`
    - **Gujarati (ગુજરાતી)** - `gu-IN`
    - **Punjabi (ਪੰਜਾਬੀ)** - `pa-IN`
    - **Indian English** - `en-IN`
  - Real-time Text-To-Speech (TTS) natural audio readout without markdown symbols or asterisks.

* **🔍 Crop Health & Disease Scanner**
  - Instant leaf disease recognition with offline machine learning models (TFLite) + Online Cloud AI analysis.
  - Clear diagnosis, causes, organic remedy, chemical treatment with exact dosages, and nearby agro store directions.

* **📅 Harvest Date Finder & Ripening Prediction**
  - Predicts remaining days to harvest and maturity stages for major crops.
  - Recommends pre-harvest care, potash fertilization, and yield optimization tips.

* **🔄 Automatic In-App Updates**
  - Seamlessly checks GitHub Releases for new APK versions on startup.
  - Farmers are prompted with localized update notes and a one-tap direct update installation.

---

## 🛠️ Getting Started & Configuration

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.0.0)
- Android SDK & Java JDK 17+

### 2. Configure API Keys
To protect your secret keys, they are never committed to version control.

1. Copy the example template to create your local `secrets.json`:
   ```bash
   cp secrets.example.json secrets.json
   ```
2. Open `secrets.json` and insert your API keys:
   ```json
   {
     "GEMINI_PRIMARY_KEY": "YOUR_GEMINI_API_KEY",
     "GEMINI_BACKUP_KEY": "YOUR_BACKUP_GEMINI_KEY",
     "WEATHER_API_KEY": "YOUR_OPENWEATHERMAP_API_KEY"
   }
   ```
   *(Get Gemini keys at [Google AI Studio](https://aistudio.google.com/) and Weather keys at [OpenWeatherMap](https://openweathermap.org/api)).*

### 3. Run the App

* **In VS Code**: Simply press **F5** (Pre-configured in `.vscode/launch.json`).
* **From Terminal**:
  ```bash
  flutter run --dart-define-from-file=secrets.json
  ```

### 4. Build Release APK
```bash
flutter build apk --release --dart-define-from-file=secrets.json
```
The compiled APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📄 License
This project is developed for educational and agricultural empowerment purposes.
