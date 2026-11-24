import 'cctv_camera.dart';

class CctvCameraGroup {
  final String key;
  final double latitude;
  final double longitude;
  final bool hasValidCoords;
  final List<CctvCamera> cameras;

  const CctvCameraGroup({
    required this.key,
    required this.latitude,
    required this.longitude,
    required this.hasValidCoords,
    required this.cameras,
  });

  CctvCamera get primaryCamera => cameras.first;

  bool get isMultiCamera => cameras.length > 1;

  bool containsCamera(String? cameraId) {
    if (cameraId == null) return false;
    return cameras.any((c) => c.id == cameraId);
  }

  /// Returns `true` if any camera in the group is online, `false` if none are
  /// online and at least one is offline, or `null` if status is still unknown.
  bool? aliveStatus(Map<String, bool> statusMap) {
    bool hasOffline = false;
    for (final cam in cameras) {
      final s = statusMap[cam.id];
      if (s == true) return true;
      if (s == false) hasOffline = true;
    }
    return hasOffline ? false : null;
  }
}
