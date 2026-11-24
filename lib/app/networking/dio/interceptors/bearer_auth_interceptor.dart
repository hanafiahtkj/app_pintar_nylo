import '/app/services/auth_service.dart';
import 'package:nylo_framework/nylo_framework.dart';

class BearerAuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && AuthService().isLoggedIn) {
      await AuthService().logout();
    }
    handler.next(err);
  }
}
