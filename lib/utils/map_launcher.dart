import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  /// Opens Google Maps searching for real, verified nearby fertilizer stores,
  /// agro centers, and PACS based on the user's real location.
  static Future<void> openGoogleMaps({
    required double userLat,
    required double userLng,
    String? storeName,
    String? storeLocation,
    String? cityName,
    double? storeLat,
    double? storeLng,
  }) async {
    String searchQuery;

    final cleanCity = cityName?.trim() ?? '';
    final cleanStore = storeName?.trim() ?? '';
    final cleanLoc = storeLocation?.trim() ?? '';

    // 1. If real city is known, search fertilizer dealers in that city
    if (cleanCity.isNotEmpty &&
        cleanCity != 'India' &&
        cleanCity != 'Tamil Nadu') {
      if (cleanStore.isNotEmpty &&
          !cleanStore.contains("Uzhavar Service Agri Center") &&
          !cleanStore.contains("Primary Agricultural Cooperative")) {
        searchQuery = "$cleanStore, $cleanCity";
      } else {
        searchQuery = "fertilizer and agro chemical store in $cleanCity";
      }
    } else if (cleanLoc.isNotEmpty &&
        !cleanLoc.toLowerCase().contains("main road") &&
        !cleanLoc.toLowerCase().contains("main bazaar") &&
        !cleanLoc.toLowerCase().contains("market bazaar")) {
      searchQuery = "fertilizer and seed store in $cleanLoc";
    } else {
      // 2. Center search near the user's live GPS coordinates
      searchQuery = "fertilizer and pesticide shop near me";
    }

    debugPrint(
        "🗺️ Launching Google Maps with query: '$searchQuery' at ($userLat, $userLng)");

    // Geo URI intent for Android Maps app
    final Uri geoIntent = Uri.parse(
      'geo:$userLat,$userLng?q=${Uri.encodeComponent(searchQuery)}',
    );

    // Universal web maps URL
    final Uri webMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(searchQuery)}',
    );

    try {
      bool launched = await launchUrl(
        geoIntent,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        launched = await launchUrl(
          webMapsUrl,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched) {
        await launchUrl(
          webMapsUrl,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      debugPrint("Map Launcher Exception: $e. Falling back to web browser.");
      try {
        await launchUrl(webMapsUrl, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }
}
