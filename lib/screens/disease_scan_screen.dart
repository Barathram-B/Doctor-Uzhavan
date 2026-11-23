import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../services/cloud_ai_service.dart';
import '../services/weather_service.dart';
import '../utils/map_launcher.dart';
import '../utils/speech_helper.dart';

class DiseaseScanScreen extends StatefulWidget {
  final String selectedLanguage;
  const DiseaseScanScreen({super.key, required this.selectedLanguage});

  @override
  State<DiseaseScanScreen> createState() => _DiseaseScanScreenState();
}

class _DiseaseScanScreenState extends State<DiseaseScanScreen> {
  CameraController? _cameraController;
  Interpreter? _interpreter;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  String? _cameraError;
  Map<String, dynamic>? _scanResult;

  final Map<int, Map<String, dynamic>> _offlineRemedyDatabase = {
    0: {
      "cropName": "Tomato / தக்காளி",
      "diseaseName": "Healthy Leaf / ஆரோக்கியமான இலை",
      "remedyTa": "No disease detected. Continue normal irrigation.",
      "fertilizer": "Organic Vermicompost / மண்புழு உரம்",
      "storeName": "Primary Agricultural Cooperative Society (PACS)",
      "storeLocation": "Local Agricultural Cooperative Center / PACS",
      "storePrice": "₹120 / 10 kg bag",
      "storeLat": 0.0,
      "storeLng": 0.0,
    },
    1: {
      "cropName": "Tomato / தக்காளி",
      "diseaseName": "Leaf Blight / இலைப்புள்ளி நோய்",
      "remedyTa":
          "Spray Copper Oxychloride 50% WP (2.5g/Litre) or Neem Oil 10000 ppm (3ml/Litre).",
      "fertilizer": "Copper Oxychloride 50% WP (COC)",
      "storeName": "Primary Agricultural Cooperative Society (PACS)",
      "storeLocation": "Local Agro Chemical & Fertilizer Depot",
      "storePrice": "₹340 / 500g (Neem Oil: ₹280 / 500ml)",
      "storeLat": 0.0,
      "storeLng": 0.0,
    },
    2: {
      "cropName": "Paddy / நெல்",
      "diseaseName": "Bacterial Blight / பாக்டீரியா நோய்",
      "remedyTa":
          "Apply Streptocycline (6g/acre) mixed with Copper Oxychloride (500g/acre).",
      "fertilizer": "Streptocycline + Copper Oxychloride",
      "storeName": "Primary Agricultural Cooperative Society (PACS)",
      "storeLocation": "Local Agro Chemical & Fertilizer Depot",
      "storePrice": "₹75 / 6g pouch + ₹340 / 500g COC",
      "storeLat": 0.0,
      "storeLng": 0.0,
    }
  };

  @override
  void initState() {
    super.initState();
    _setupCameraAndModel();
  }

  Future<void> _setupCameraAndModel() async {
    // 1. Initialize TFLite model safely in isolation
    try {
      _interpreter ??=
          await Interpreter.fromAsset('assets/dual_plant_model.tflite');
    } catch (e) {
      debugPrint("TFLite model init notice: $e");
    }

    // 2. Initialize Camera safely with permission handling
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
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
      debugPrint("Camera init error: $e");
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraError = "Camera access required to scan crops.";
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
      await _processDiseaseImageBytes(rawBytes);
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
        await _processDiseaseImageBytes(bytes);
      }
    } catch (e) {
      debugPrint("Gallery pick error: $e");
    }
  }

  Future<void> _processDiseaseImageBytes(Uint8List rawBytes) async {
    setState(() {
      _isAnalyzing = true;
      _scanResult = null;
    });

    try {
      Uint8List processedBytes = rawBytes;
      img.Image? decodedImg = img.decodeImage(rawBytes);

      if (decodedImg != null) {
        img.Image orientedImg = img.bakeOrientation(decodedImg);
        img.Image resizedImg = img.copyResize(orientedImg, width: 1024);
        processedBytes =
            Uint8List.fromList(img.encodeJpg(resizedImg, quality: 85));
      }

      Map<String, dynamic> weatherData =
          await WeatherService.fetchCurrentLocationWeather();

      try {
        debugPrint("🌐 Querying Gemini Disease Cloud AI...");
        Map<String, dynamic>? cloudResponse =
            await CloudAIService.analyzeCropOnline(
          imageBytes: processedBytes,
          language: widget.selectedLanguage,
          userLat: weatherData['lat'] ?? 11.1271,
          userLng: weatherData['lng'] ?? 78.6569,
          locationName: weatherData['locationName'] as String?,
        );

        if (cloudResponse != null) {
          if (cloudResponse['isPlant'] == false) {
            _handleNonPlantDetected();
            return;
          }

          setState(() {
            _scanResult = cloudResponse;
            _isAnalyzing = false;
          });

          _speakVoiceAssistant(cloudResponse['remedyTa'] ?? "");
          return;
        }
      } catch (e) {
        debugPrint("Cloud AI Disease Scan exception: $e");
      }

      // Fall back to local model if offline or API fails
      _runOfflineTFLiteModel(processedBytes);
    } catch (e) {
      debugPrint("Analysis Error: $e");
      setState(() => _isAnalyzing = false);
    }
  }

  void _runOfflineTFLiteModel(Uint8List imageBytes) {
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

    List<double> probabilities = List<double>.from(diseaseOut[0]);
    int predictedIndex = 0;
    double maxConfidence = probabilities[0];

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxConfidence) {
        maxConfidence = probabilities[i];
        predictedIndex = i;
      }
    }

    if (maxConfidence < 0.45) {
      _handleNonPlantDetected();
      return;
    }

    Map<String, dynamic> rawResult =
        _offlineRemedyDatabase[predictedIndex] ?? _offlineRemedyDatabase[0]!;

    final String currentCity = WeatherService.cachedCityName ?? '';
    final String displayStoreName = (currentCity.isNotEmpty &&
            currentCity != 'India' &&
            currentCity != 'Tamil Nadu')
        ? "$currentCity Primary Agricultural Cooperative Society (PACS)"
        : (rawResult['storeName'] ??
            "Primary Agricultural Cooperative Society (PACS)");
    final String displayStoreLocation = (currentCity.isNotEmpty &&
            currentCity != 'India' &&
            currentCity != 'Tamil Nadu')
        ? "$currentCity Agricultural Market / Main Road"
        : (rawResult['storeLocation'] ??
            "Local Agro Chemical & Fertilizer Depot");

    Map<String, dynamic> result = {
      ...rawResult,
      "storeName": displayStoreName,
      "storeLocation": displayStoreLocation,
      "storeLat": 0.0,
      "storeLng": 0.0,
    };

    setState(() {
      _scanResult = result;
      _isAnalyzing = false;
    });

    _speakVoiceAssistant(result['remedyTa']);
  }

  void _handleNonPlantDetected() {
    setState(() => _isAnalyzing = false);
    _showNonPlantDialog();
    _speakVoiceAssistant("Please point the camera directly at a plant leaf.");
  }

  void _showNonPlantDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Focus Camera on Plant"),
        content: const Text(
            "No plant recognized. Align your camera closely on an infected leaf."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFF2E7D32))),
          )
        ],
      ),
    );
  }

  Future<void> _speakVoiceAssistant(String text) async {
    if (text.isEmpty) return;
    String cleanText = SpeechHelper.cleanTextForSpeech(text);
    if (cleanText.isEmpty) return;

    String langCode = SpeechHelper.getLanguageCode(widget.selectedLanguage);
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.42);
    await _flutterTts.speak(cleanText);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Crop (${widget.selectedLanguage})'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
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
                      _cameraError ?? "Initializing camera...",
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
                      onPressed: _setupCameraAndModel,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "Grant Permission & Retry",
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                      label: const Text(
                        "Upload from Gallery",
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                        heroTag: "diseaseGalleryBtn",
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
                          heroTag: "diseaseScanBtn",
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
                              : const Icon(Icons.camera_alt,
                                  color: Colors.white),
                          label: Text(
                            _isAnalyzing ? "Analyzing..." : "Scan Leaf",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_scanResult != null) _buildResultBottomSheet(),
              ],
            ),
    );
  }

  Widget _buildResultBottomSheet() {
  String storeName = _scanResult!['storeName'] ?? "Fertilizer Shop";
  String fertilizer = _scanResult!['fertilizer'] ?? "Recommended Fertilizer";
  String price = _scanResult!['storePrice'] ?? "N/A";

  return Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _scanResult!['cropName'] ?? "Crop",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _scanResult = null),
              )
            ],
          ),
          Text(
            _scanResult!['diseaseName'] ?? "Diagnosis",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC62828),
            ),
          ),
          const Divider(height: 20),
          Text(
            _scanResult!['remedyTa'] ?? "",
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fertilizer: $fertilizer",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "Shop: $storeName",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                Text(
                  "Est. Price: $price",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      // Fetch user live coordinates to search nearby stores accurately
                      Map<String, dynamic> weatherData =
                          await WeatherService.fetchCurrentLocationWeather();
                      double userLat = (weatherData['lat'] as num?)?.toDouble() ?? 11.1271;
                      double userLng = (weatherData['lng'] as num?)?.toDouble() ?? 78.6569;

                      double? storeLat = (_scanResult!['storeLat'] as num?)?.toDouble();
                      double? storeLng = (_scanResult!['storeLng'] as num?)?.toDouble();
                      String? storeLoc = _scanResult!['storeLocation'] as String?;

                      MapLauncher.openGoogleMaps(
                        userLat: userLat,
                        userLng: userLng,
                        storeName: storeName,
                        storeLocation: storeLoc,
                        cityName: weatherData['cityName'] as String?,
                        storeLat: storeLat,
                        storeLng: storeLng,
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: Text("Open Maps for $storeName"),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  _speakVoiceAssistant(_scanResult!['remedyTa'] ?? ""),
              icon: const Icon(Icons.volume_up),
              label: const Text("Listen Voice Summary"),
            ),
          )
        ],
      ),
    ),
  );
}
}
