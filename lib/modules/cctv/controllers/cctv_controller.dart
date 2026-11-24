import 'dart:async';
import 'package:flutter/foundation.dart';
import '/modules/cctv/models/cctv_camera.dart';
import '/modules/cctv/models/cctv_camera_group.dart';
import '/modules/cctv/models/cctv_category.dart';
import '/modules/cctv/models/cctv_wilayah.dart';
import '/modules/cctv/networking/cctv_api_service.dart';

class CctvKecamatanOption {
  final CctvKecamatan kecamatan;
  final int count;

  const CctvKecamatanOption({
    required this.kecamatan,
    required this.count,
  });
}

class CctvKelurahanOption {
  final CctvKelurahan kelurahan;
  final int count;

  const CctvKelurahanOption({
    required this.kelurahan,
    required this.count,
  });
}

class CctvController extends ChangeNotifier {
  static const String unassignedWilayahValue = '__unassigned__';
  static const int maxAutoScanAttempts = 5;
  static const Duration statusPollInterval = Duration(minutes: 3);
  static const double defaultLat = -3.316694;
  static const double defaultLng = 114.590111;
  static const double defaultZoom = 13.0;

  CctvApiService? _apiService;

  CctvController({CctvApiService? apiService}) : _apiService = apiService;

  CctvApiService get _api => _apiService ??= CctvApiService();

  List<CctvCamera> _cameras = const [];
  List<CctvCategory> _categories = const [];
  List<CctvKecamatan> _wilayahList = const [];
  final Map<String, bool> _aliveStatus = <String, bool>{};

  bool _isLoadingInitial = false;
  String? _initialError;
  bool _isCheckingAlive = false;
  DateTime? _lastCheckedAt;

  CctvCamera? _activeCamera;
  String? _playingLiveCameraId;
  String? _selectedCategory;
  String? _selectedKecamatan;
  String? _selectedKelurahan;
  String _searchQuery = '';

  bool _isAutoScanning = true;
  int _autoScanAttempts = 0;
  int _probeEpoch = 0;
  bool _disposed = false;
  Timer? _statusPollTimer;

  /// Incremented whenever wilayah filters change so the map can fit bounds.
  int _mapFocusVersion = 0;

  List<CctvCamera> get cameras => _cameras;
  List<CctvCategory> get categories => _categories;
  List<CctvKecamatan> get wilayahList => _wilayahList;
  Map<String, bool> get aliveStatus => Map.unmodifiable(_aliveStatus);

  bool get isLoadingInitial => _isLoadingInitial;
  String? get initialError => _initialError;
  bool get isCheckingAlive => _isCheckingAlive;
  DateTime? get lastCheckedAt => _lastCheckedAt;

  CctvCamera? get activeCamera => _activeCamera;
  String? get selectedCategory => _selectedCategory;
  String? get selectedKecamatan => _selectedKecamatan;
  String? get selectedKelurahan => _selectedKelurahan;
  String get searchQuery => _searchQuery;
  int get mapFocusVersion => _mapFocusVersion;

  bool? statusOf(String? cameraId) {
    if (cameraId == null) return null;
    return _aliveStatus[cameraId];
  }

  int get onlineCount =>
      _cameras.where((cam) => _aliveStatus[cam.id] == true).length;

  int get offlineCount =>
      _cameras.where((cam) => _aliveStatus[cam.id] == false).length;

  String get lastCheckedLabel {
    final dt = _lastCheckedAt;
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  bool _matchesWilayahFilter(CctvCamera cam) {
    if (_selectedKecamatan == unassignedWilayahValue) {
      return cam.kecamatanUuid == null || cam.kecamatanUuid!.isEmpty;
    }
    if (_selectedKecamatan != null && cam.kecamatanUuid != _selectedKecamatan) {
      return false;
    }
    if (_selectedKelurahan != null && cam.kelurahanUuid != _selectedKelurahan) {
      return false;
    }
    return true;
  }

  bool _matchesSearchQuery(CctvCamera cam, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    return cam.location.toLowerCase().contains(normalizedQuery) ||
        cam.address.toLowerCase().contains(normalizedQuery) ||
        cam.zone.toLowerCase().contains(normalizedQuery) ||
        (cam.kecamatanNama?.toLowerCase().contains(normalizedQuery) ?? false) ||
        (cam.kelurahanNama?.toLowerCase().contains(normalizedQuery) ?? false);
  }

  List<CctvCamera> get wilayahFilteredList =>
      _cameras.where(_matchesWilayahFilter).toList();

  List<CctvCamera> get categoryFilteredList {
    if (_selectedCategory == null) return _cameras;
    return _cameras.where((c) => c.categoryUuid == _selectedCategory).toList();
  }

  int countForCategory(String categoryUuid) =>
      wilayahFilteredList.where((c) => c.categoryUuid == categoryUuid).length;

  List<CctvKecamatanOption> get kecamatanOptions {
    final counts = <String, int>{};
    for (final cam in categoryFilteredList) {
      final kecId = cam.kecamatanUuid;
      if (kecId != null && kecId.isNotEmpty) {
        counts[kecId] = (counts[kecId] ?? 0) + 1;
      }
    }
    return _wilayahList
        .map((kec) => CctvKecamatanOption(
              kecamatan: kec,
              count: counts[kec.uuid] ?? 0,
            ))
        .toList();
  }

  int get unassignedWilayahCount => categoryFilteredList
      .where((c) => c.kecamatanUuid == null || c.kecamatanUuid!.isEmpty)
      .length;

  bool get canSelectKelurahan =>
      _selectedKecamatan != null &&
      _selectedKecamatan != unassignedWilayahValue;

  List<CctvKelurahanOption> get kelurahanOptions {
    if (!canSelectKelurahan) return const [];
    final activeKec = _wilayahList
        .where((k) => k.uuid == _selectedKecamatan)
        .firstOrNull;
    if (activeKec == null) return const [];

    final counts = <String, int>{};
    for (final cam in categoryFilteredList) {
      if (cam.kecamatanUuid == activeKec.uuid &&
          cam.kelurahanUuid != null &&
          cam.kelurahanUuid!.isNotEmpty) {
        counts[cam.kelurahanUuid!] = (counts[cam.kelurahanUuid!] ?? 0) + 1;
      }
    }

    return activeKec.kelurahan
        .map((kel) => CctvKelurahanOption(
              kelurahan: kel,
              count: counts[kel.uuid] ?? 0,
            ))
        .toList();
  }

  String get selectedKecamatanLabel {
    if (_selectedKecamatan == null) return '';
    if (_selectedKecamatan == unassignedWilayahValue) {
      return 'Belum Terpetakan';
    }
    final found = _wilayahList
        .where((k) => k.uuid == _selectedKecamatan)
        .firstOrNull;
    return found != null ? 'Kec. ${found.namaKecamatan}' : '';
  }

  String get selectedKelurahanLabel {
    if (_selectedKelurahan == null) return '';
    final found = kelurahanOptions
        .where((k) => k.kelurahan.uuid == _selectedKelurahan)
        .firstOrNull;
    return found != null ? 'Kel. ${found.kelurahan.nama}' : '';
  }

  List<CctvCamera> get filteredCameras {
    final q = _searchQuery.trim().toLowerCase();
    return _cameras.where((cam) {
      if (_selectedCategory != null && cam.categoryUuid != _selectedCategory) {
        return false;
      }
      if (!_matchesWilayahFilter(cam)) return false;
      if (!_matchesSearchQuery(cam, q)) return false;
      return true;
    }).toList();
  }

  bool get hasActiveFilters =>
      _selectedCategory != null ||
      _selectedKecamatan != null ||
      _selectedKelurahan != null ||
      _searchQuery.trim().isNotEmpty;

  List<CctvCamera> get mappedCameras =>
      filteredCameras.where((c) => c.hasValidCoords).toList();

  List<CctvCameraGroup> get mapGroups {
    final groups = <String, List<CctvCamera>>{};
    for (final cam in mappedCameras) {
      groups.putIfAbsent(cam.coordKey, () => <CctvCamera>[]).add(cam);
    }
    return groups.entries
        .map((entry) => CctvCameraGroup(
              key: entry.key,
              latitude: entry.value.first.latitude,
              longitude: entry.value.first.longitude,
              hasValidCoords: true,
              cameras: entry.value,
            ))
        .toList();
  }

  /// All filtered cameras grouped by coordinates (including Non-GPS cameras so
  /// they remain selectable in the camera list).
  List<CctvCameraGroup> get allGroups {
    final groups = <String, List<CctvCamera>>{};
    for (final cam in filteredCameras) {
      final key = cam.hasValidCoords ? cam.coordKey : 'unmapped_${cam.id}';
      groups.putIfAbsent(key, () => <CctvCamera>[]).add(cam);
    }
    return groups.entries
        .map((entry) => CctvCameraGroup(
              key: entry.key,
              latitude: entry.value.first.latitude,
              longitude: entry.value.first.longitude,
              hasValidCoords: entry.value.first.hasValidCoords,
              cameras: entry.value,
            ))
        .toList();
  }

  /// Hydrates data directly (useful for testing).
  void hydrate({
    required List<CctvCamera> cameras,
    List<CctvCategory> categories = const [],
    List<CctvKecamatan> wilayah = const [],
    Map<String, bool>? aliveStatus,
  }) {
    _cameras = cameras;
    _categories = categories;
    _wilayahList = wilayah;
    if (aliveStatus != null) {
      _aliveStatus
        ..clear()
        ..addAll(aliveStatus);
    }
    if (_cameras.isNotEmpty && _activeCamera == null) {
      _activeCamera = _cameras.first;
    }
    _notify();
  }

  Future<void> loadInitialData({bool forceRefresh = false}) async {
    _isLoadingInitial = true;
    _initialError = null;
    _notify();

    try {
      final results = await Future.wait([
        _api.getCameras(forceRefresh: forceRefresh),
        _api.getCategories(forceRefresh: forceRefresh),
        _api.getWilayah(forceRefresh: forceRefresh),
      ]);

      if (_disposed) return;

      _cameras = results[0] as List<CctvCamera>;
      _categories = results[1] as List<CctvCategory>;
      _wilayahList = results[2] as List<CctvKecamatan>;

      if (_cameras.isNotEmpty && _activeCamera == null) {
        _isAutoScanning = true;
        _autoScanAttempts = 0;
        _activeCamera = _cameras.first;
      }

      _isLoadingInitial = false;
      _notify();

      _startStatusPolling();
      unawaited(checkAlive(forceRefresh: forceRefresh));
    } catch (e) {
      if (_disposed) return;
      _isLoadingInitial = false;
      _initialError = e.toString().replaceFirst('Exception: ', '');
      _notify();
    }
  }

  Future<void> checkAlive({bool forceRefresh = false}) async {
    if (_cameras.isEmpty) return;
    if (_isCheckingAlive && !forceRefresh) return;

    final currentEpoch = ++_probeEpoch;
    _isCheckingAlive = true;
    _notify();

    try {
      await _api.probeHlsStreams(
        _cameras,
        isCancelled: () => _disposed || currentEpoch != _probeEpoch,
        onProgress: (cameraId, isOnline) {
          if (_disposed || currentEpoch != _probeEpoch) return;
          // Do not overwrite a camera that is actively playing in the player
          if (!isOnline && cameraId == _playingLiveCameraId) return;
          _aliveStatus[cameraId] = isOnline;
          _notify();
        },
      );
      if (_disposed || currentEpoch != _probeEpoch) return;
      _lastCheckedAt = DateTime.now();
    } finally {
      if (!_disposed && currentEpoch == _probeEpoch) {
        _isCheckingAlive = false;
        _notify();
      }
    }
  }

  void selectCategory(String? categoryUuid) {
    if (_selectedCategory == categoryUuid) return;
    _selectedCategory = categoryUuid;
    _notify();
  }

  void selectKecamatan(String? kecamatanUuid) {
    if (_selectedKecamatan == kecamatanUuid) return;
    _selectedKecamatan = kecamatanUuid;

    if (kecamatanUuid == null || kecamatanUuid == unassignedWilayahValue) {
      _selectedKelurahan = null;
    } else {
      final activeKec = _wilayahList
          .where((k) => k.uuid == kecamatanUuid)
          .firstOrNull;
      final isStillValid = activeKec?.kelurahan
              .any((kel) => kel.uuid == _selectedKelurahan) ??
          false;
      if (!isStillValid) {
        _selectedKelurahan = null;
      }
    }

    _mapFocusVersion++;
    _notify();
  }

  void selectKelurahan(String? kelurahanUuid) {
    if (_selectedKelurahan == kelurahanUuid) return;
    _selectedKelurahan = kelurahanUuid;
    _mapFocusVersion++;
    _notify();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _notify();
  }

  void resetFilters() {
    _selectedCategory = null;
    _selectedKecamatan = null;
    _selectedKelurahan = null;
    _searchQuery = '';
    _mapFocusVersion++;
    _notify();
  }

  void selectCamera(CctvCamera camera, {bool fromAutoScan = false}) {
    if (!fromAutoScan) {
      _isAutoScanning = false;
    }
    if (_activeCamera?.id != camera.id) {
      _playingLiveCameraId = null;
    }
    _activeCamera = camera;
    _notify();
  }

  void markCameraLive(String cameraId) {
    _isAutoScanning = false;
    _playingLiveCameraId = cameraId;
    if (_aliveStatus[cameraId] != true) {
      _aliveStatus[cameraId] = true;
      _notify();
    }
  }

  /// Called when the active HLS stream fails to load.
  /// Returns `true` if auto-scan advanced to the next camera; `false` if the
  /// player should display its error overlay.
  bool handleStreamError() {
    if (!_isAutoScanning || _autoScanAttempts >= maxAutoScanAttempts) {
      _isAutoScanning = false;
      return false;
    }

    final list = filteredCameras;
    final currentIdx = list.indexWhere((c) => c.id == _activeCamera?.id);
    if (currentIdx != -1 && currentIdx < list.length - 1) {
      _autoScanAttempts++;
      _activeCamera = list[currentIdx + 1];
      _notify();
      return true;
    }

    _isAutoScanning = false;
    return false;
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(statusPollInterval, (_) {
      if (!_disposed) {
        unawaited(checkAlive());
      }
    });
  }

  void onAppPaused() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
  }

  void onAppResumed() {
    if (_disposed || _cameras.isEmpty) return;
    _startStatusPolling();
    final last = _lastCheckedAt;
    if (last == null ||
        DateTime.now().difference(last) >= statusPollInterval) {
      unawaited(checkAlive());
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _probeEpoch++;
    _statusPollTimer?.cancel();
    super.dispose();
  }
}
