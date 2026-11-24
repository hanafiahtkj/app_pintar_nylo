import '/app/models/lowongan.dart';
import '/bootstrap/decoders.dart';
import '/config/app.dart';
import 'package:nylo_framework/nylo_framework.dart';

class KarierApiService extends NyApiService {
  KarierApiService()
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
  String get baseUrl => AppConfig.karierApiBaseUrl;

  @override
  Map<Type, Interceptor> get interceptors => <Type, Interceptor>{
        ...super.interceptors,
      };

  Future<List<Lowongan>?> getLowongans({int page = 1}) async {
    final res = await networkResponse<List<Lowongan>>(
      request: (request) => request.get(
        '/api/lowongans',
        queryParameters: {'page': page},
      ),
    );
    if (!res.isSuccessful) {
      throw Exception(res.errorMessage ?? 'Gagal memuat lowongan');
    }
    return res.data;
  }
}
