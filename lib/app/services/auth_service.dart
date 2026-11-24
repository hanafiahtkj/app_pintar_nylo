import '/app/events/login_success_event.dart';
import '/app/events/logout_event.dart';
import '/app/models/user.dart';
import '/app/networking/pintar_api_service.dart';
import '/app/providers/firebase_messaging_provider.dart';
import '/config/storage_keys.dart';
import 'package:nylo_framework/nylo_framework.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? currentUser;
  bool isLoggedIn = false;

  /// Loads cached auth state synchronously/locally during boot,
  /// then refreshes remote user profile asynchronously.
  Future<void> initialize() async {
    final authenticated = await Auth.isAuthenticated();
    final savedToken = await StorageKeysConfig.bearerToken.read<String>();
    isLoggedIn = authenticated || (savedToken != null && savedToken.isNotEmpty);

    if (isLoggedIn) {
      final authData = Auth.data();
      if (authData is Map && authData.isNotEmpty) {
        currentUser = User.fromJson(authData);
      }
      _refreshRemoteUser(savedToken);
    }
  }

  Future<void> _refreshRemoteUser(String? savedToken) async {
    try {
      final remoteUser =
          await api<PintarApiService>((request) => request.getUser());
      if (remoteUser != null && isLoggedIn) {
        remoteUser.token = savedToken ?? Auth.data(field: 'token');
        currentUser = remoteUser;
        await Auth.authenticate(data: remoteUser.toJson());
        await event<LoginSuccessEvent>(data: {'user': remoteUser});
      }
    } catch (_) {}
  }

  Future<User?> loginWithToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return null;

    // Verify token against /api/v3/user BEFORE persisting credentials
    final user = await api<PintarApiService>(
      (request) => request.getUser(customToken: trimmed),
    );
    if (user == null) {
      return null;
    }

    user.token = trimmed;
    currentUser = user;
    isLoggedIn = true;
    await StorageKeysConfig.bearerToken.save(trimmed, inBackpack: true);
    await Auth.authenticate(data: user.toJson());
    await FirebaseMessagingService().refreshTokenRegistration();
    await event<LoginSuccessEvent>(data: {'user': user});
    return user;
  }

  Future<User?> loginWithApple({
    required String appleId,
    required String password,
    String? name,
    String? email,
  }) async {
    final token = await api<PintarApiService>(
      (request) => request.signInWithApple(
        appleId: appleId,
        password: password,
        name: name,
        email: email,
      ),
    );
    if (token != null && token.isNotEmpty) {
      final user = await loginWithToken(token);
      if (user != null) {
        return user;
      }
      throw Exception('Gagal memverifikasi sesi pengguna');
    }
    throw Exception('Apple login gagal mendapatkan token');
  }

  Future<bool> submitPolling(int rating) async {
    final ok = await api<PintarApiService>(
          (request) => request.submitPolling(rating),
        ) ??
        false;
    if (!ok) {
      return false;
    }
    if (currentUser != null) {
      currentUser!.isPolling = rating;
      await Auth.authenticate(data: currentUser!.toJson());
    }
    return true;
  }

  Future<void> logout() async {
    isLoggedIn = false;
    currentUser = null;
    await StorageKeysConfig.bearerToken.deleteFromStorage();
    await Auth.logout();
    await event<LogoutEvent>();
  }
}
