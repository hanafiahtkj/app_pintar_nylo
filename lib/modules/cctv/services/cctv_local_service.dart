import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '/modules/cctv/models/cctv_camera.dart';

class CctvCoordinates {
  final double latitude;
  final double longitude;

  const CctvCoordinates({
    required this.latitude,
    required this.longitude,
  });
}

class CctvLocalService {
  static const String _favoritesKey = 'cctv_favorite_ids_v1';
  static const String _recentsKey = 'cctv_recent_ids_v1';
  static const int maxRecents = 5;

  Future<Set<String>> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_favoritesKey) ?? const <String>[];
      return list.where((e) => e.trim().isNotEmpty).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> saveFavorites(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, ids.toList());
    } catch (_) {
      // Ignore storage failures gracefully.
    }
  }

  Future<List<String>> loadRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentsKey) ?? const <String>[];
      return list.where((e) => e.trim().isNotEmpty).take(maxRecents).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> saveRecents(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentsKey, ids.take(maxRecents).toList());
    } catch (_) {
      // Ignore storage failures gracefully.
    }
  }

  /// Attempts to retrieve the user's current location with a bounded timeout.
  /// Returns `null` safely if location services are disabled, permission is
  /// denied, or a timeout occurs (so the app seamlessly falls back).
  Future<CctvCoordinates?> getCurrentLocation({
    bool requestPermission = true,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(timeout);
        return CctvCoordinates(
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return CctvCoordinates(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
          );
        }
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Calculates Haversine great-circle distance in meters between two points.
  static double distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double deg) => deg * (math.pi / 180.0);

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000.0;
    return km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(1)} km';
  }

  /// Opens the camera coordinates in Google Maps (Android/Web) or Apple Maps (iOS).
  static Future<bool> openInExternalMaps(CctvCamera camera) async {
    if (!camera.hasValidCoords) return false;
    final lat = camera.latitude.toStringAsFixed(6);
    final lng = camera.longitude.toStringAsFixed(6);
    final label = Uri.encodeComponent(camera.displayName);

    final Uri uri;
    if (!kIsWeb && Platform.isIOS) {
      uri = Uri.parse('https://maps.apple.com/?q=$label&ll=$lat,$lng');
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    }

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
