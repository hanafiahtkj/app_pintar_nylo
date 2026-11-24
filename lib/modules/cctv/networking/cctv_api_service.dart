import 'package:nylo_framework/nylo_framework.dart';
import '/bootstrap/decoders.dart';
import '/config/app.dart';
import '/modules/cctv/models/cctv_camera.dart';
import '/modules/cctv/models/cctv_category.dart';
import '/modules/cctv/models/cctv_wilayah.dart';

class CctvApiService extends NyApiService {
  CctvApiService()
      : super(
          decoders: modelDecoders,
          useNetworkLogger: false,
          baseOptions: (BaseOptions baseOptions) {
            return baseOptions
              ..connectTimeout = const Duration(seconds: 20)
              ..receiveTimeout = const Duration(seconds: 20);
          },
        );

  @override
  String get baseUrl => AppConfig.cctvApiBaseUrl.replaceAll(RegExp(r'/+$'), '');

  @override
  Future<RequestHeaders> setAuthHeaders(RequestHeaders headers) async {
    final token = AppConfig.cctvApiToken.trim();
    if (token.isNotEmpty) {
      headers.addBearerToken(token);
    }
    return headers;
  }

  Future<List<CctvCamera>> getCameras({bool forceRefresh = false}) async {
    final res = await networkResponse<List<CctvCamera>>(
      request: (request) => request.get('/api/v2/cctv'),
      cacheKey: forceRefresh ? null : 'cctv_list_v2',
      cacheDuration: const Duration(hours: 1),
      cachePolicy:
          forceRefresh ? CachePolicy.networkOnly : CachePolicy.networkFirst,
    );
    if (!res.isSuccessful && res.data == null) {
      throw Exception(res.errorMessage ?? 'Gagal memuat daftar kamera CCTV');
    }
    return res.data ?? <CctvCamera>[];
  }

  Future<List<CctvCategory>> getCategories({bool forceRefresh = false}) async {
    final res = await networkResponse<List<CctvCategory>>(
      request: (request) => request.get('/api/v1/category'),
      cacheKey: forceRefresh ? null : 'cctv_categories_v1',
      cacheDuration: const Duration(hours: 2),
      cachePolicy:
          forceRefresh ? CachePolicy.networkOnly : CachePolicy.networkFirst,
    );
    if (!res.isSuccessful && res.data == null) {
      throw Exception(res.errorMessage ?? 'Gagal memuat kategori CCTV');
    }
    return res.data ?? <CctvCategory>[];
  }

  Future<List<CctvKecamatan>> getWilayah({bool forceRefresh = false}) async {
    final res = await networkResponse<List<CctvKecamatan>>(
      request: (request) => request.get('/api/v2/get_kecamatan_kelurahan'),
      cacheKey: forceRefresh ? null : 'cctv_wilayah_v2',
      cacheDuration: const Duration(hours: 2),
      cachePolicy:
          forceRefresh ? CachePolicy.networkOnly : CachePolicy.networkFirst,
    );
    if (!res.isSuccessful && res.data == null) {
      throw Exception(
        res.errorMessage ?? 'Gagal memuat data kecamatan & kelurahan CCTV',
      );
    }
    return res.data ?? <CctvKecamatan>[];
  }

  /// Probes each camera's HLS `.m3u8` URL directly using bounded concurrency,
  /// checking whether the manifest responds with HTTP 200 and `#EXTM3U`.
  Future<Map<String, bool>> probeHlsStreams(
    List<CctvCamera> cameras, {
    int concurrency = 6,
    bool Function()? isCancelled,
    void Function(String cameraId, bool isOnline)? onProgress,
  }) async {
    final status = <String, bool>{};
    if (cameras.isEmpty) return status;

    final origin = baseUrl;
    final probeDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 6),
        followRedirects: true,
        responseType: ResponseType.plain,
        validateStatus: (code) => code != null && code < 500,
        headers: {
          'Accept':
              'application/vnd.apple.mpegurl, application/x-mpegURL, text/plain, */*',
          'Origin': origin,
          'Referer': '$origin/',
        },
      ),
    );

    var cursor = 0;

    Future<void> worker() async {
      while (cursor < cameras.length) {
        if (isCancelled?.call() == true) return;
        final cam = cameras[cursor++];
        final isOnline = await _probeSingleStream(probeDio, cam.videoUrl);
        if (isCancelled?.call() == true) return;
        status[cam.id] = isOnline;
        onProgress?.call(cam.id, isOnline);
      }
    }

    try {
      final workerCount =
          cameras.length < concurrency ? cameras.length : concurrency;
      await Future.wait(List.generate(workerCount, (_) => worker()));
    } finally {
      probeDio.close(force: true);
    }

    return status;
  }

  Future<bool> _probeSingleStream(Dio dio, String? url) async {
    if (url == null || !RegExp(r'^https?://', caseSensitive: false).hasMatch(url)) {
      return false;
    }
    try {
      final response = await dio.get<String>(url);
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        return false;
      }
      final body = response.data ?? '';
      return body.contains('#EXTM3U');
    } catch (_) {
      return false;
    }
  }
}
