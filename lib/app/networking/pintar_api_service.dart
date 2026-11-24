import 'dart:io';
import '/app/models/banner_item.dart';
import '/app/models/category_item.dart';
import '/app/models/emergency_category.dart';
import '/app/models/hotline.dart';
import '/app/models/layanan_app.dart';
import '/app/models/notification_page_response.dart';
import '/app/models/polling.dart';
import '/app/models/post.dart';
import '/app/models/urgent_notification.dart';
import '/app/models/user.dart';
import '/app/networking/dio/interceptors/bearer_auth_interceptor.dart';
import '/bootstrap/decoders.dart';
import '/config/app.dart';
import '/config/storage_keys.dart';
import 'package:nylo_framework/nylo_framework.dart';

class PintarApiService extends NyApiService {
  PintarApiService()
      : super(
          decoders: modelDecoders,
          useNetworkLogger: false,
          baseOptions: (BaseOptions baseOptions) {
            return baseOptions
              ..connectTimeout = const Duration(seconds: 30)
              ..receiveTimeout = const Duration(seconds: 15);
          },
        );

  @override
  String get baseUrl => AppConfig.apiBaseUrl;

  @override
  Map<Type, Interceptor> get interceptors => <Type, Interceptor>{
        ...super.interceptors,
        BearerAuthInterceptor: BearerAuthInterceptor(),
      };

  @override
  Future<RequestHeaders> setAuthHeaders(RequestHeaders headers) async {
    String? token = Auth.data(field: 'token') ??
        await StorageKeysConfig.bearerToken.read<String>();
    if (token != null && token.isNotEmpty) {
      headers.addBearerToken(token);
    }
    return headers;
  }

  Future<List<LayananApp>?> getApps({String? search, int? idKategori}) async {
    final res = await networkResponse<List<LayananApp>>(
      request: (request) => request.get(
        '/api/v3/getApps',
        queryParameters: {
          'search': search,
          'id_kategori': idKategori,
        },
      ),
    );
    if (!res.isSuccessful) {
      throw Exception(res.errorMessage ?? 'Gagal memuat daftar layanan');
    }
    return res.data;
  }

  Future<List<CategoryItem>?> getCategories() async {
    final res = await networkResponse<List<CategoryItem>>(
      request: (request) => request.get('/api/v3/getCategories'),
    );
    if (!res.isSuccessful) {
      throw Exception(res.errorMessage ?? 'Gagal memuat kategori');
    }
    return res.data;
  }

  Future<List<BannerItem>?> getBanners() async {
    return await network<List<BannerItem>>(
      request: (request) => request.get('/api/v3/getBanners'),
    );
  }

  Future<Hotline?> getHotline() async {
    return await network<Hotline>(
      request: (request) => request.get('/api/v3/getHotline'),
    );
  }

  Future<Polling?> getPolling() async {
    return await network<Polling>(
      request: (request) => request.get('/api/v3/polling/getData'),
    );
  }

  Future<bool> submitPolling(int? polling) async {
    final res = await networkResponse<dynamic>(
      request: (request) => request.post(
        '/api/v3/polling',
        data: {'polling': polling},
      ),
    );
    return res.isSuccessful;
  }

  Future<List<Post>?> getPosts({int page = 1}) async {
    final res = await networkResponse<List<Post>>(
      request: (request) => request.get(
        '/api/v3/getBerita',
        queryParameters: {'page': page},
      ),
      cacheKey: 'berita_page_$page',
      cacheDuration: const Duration(hours: 6),
      cachePolicy: CachePolicy.networkFirst,
    );
    if (!res.isSuccessful && res.data == null) {
      throw Exception(res.errorMessage ?? 'Gagal memuat berita');
    }
    return res.data;
  }

  Future<List<EmergencyCategory>?> getEmergencies() async {
    final res = await networkResponse<List<EmergencyCategory>>(
      request: (request) => request.get('/api/v3/getEmergency'),
    );
    if (!res.isSuccessful) {
      throw Exception(res.errorMessage ?? 'Gagal memuat nomor darurat');
    }
    return res.data;
  }

  Future<List<UrgentNotification>?> getUrgentNotifications() async {
    return await network<List<UrgentNotification>>(
      request: (request) => request.get('/api/v3/urgent-notifications'),
    );
  }

  Future<NotificationPageResponse?> getNotifications({
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await networkResponse<NotificationPageResponse>(
      request: (request) => request.get(
        '/api/v3/notifications',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      ),
    );
    if (!res.isSuccessful) {
      throw Exception(res.errorMessage ?? 'Gagal memuat notifikasi');
    }
    return res.data;
  }

  Future<void> registerDeviceToken(String token) async {
    await networkResponse<dynamic>(
      request: (request) => request.post(
        '/api/v3/device-token',
        data: {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      ),
    );
  }

  Future<User?> getUser({String? customToken}) async {
    final res = await networkResponse<User>(
      request: (request) => request.get('/api/v3/user'),
      headers: customToken != null && customToken.isNotEmpty
          ? {'Authorization': 'Bearer $customToken'}
          : null,
      shouldSetAuthHeaders: customToken == null,
    );
    if (!res.isSuccessful) return null;
    return res.data;
  }

  Future<String?> signInWithApple({
    required String appleId,
    required String password,
    String? name,
    String? email,
  }) async {
    final res = await networkResponse<dynamic>(
      request: (request) => request.post(
        '/api/v3/signInWithApple',
        data: {
          'apple_id': appleId,
          'password': password,
          'name': name,
          'email': email,
        },
      ),
    );
    if (res.isSuccessful && res.rawData is Map) {
      return res.rawData['token']?.toString();
    }
    return null;
  }

  Future<bool> getAppleLoginStatus() async {
    final res = await networkResponse<dynamic>(
      request: (request) => request.get('/api/v3/apple-login-status'),
    );
    if (!res.isSuccessful) {
      throw Exception(res.errorMessage ?? 'Gagal memeriksa status Apple login');
    }
    if (res.rawData is Map) {
      return res.rawData['active'] == true;
    }
    return false;
  }
}
