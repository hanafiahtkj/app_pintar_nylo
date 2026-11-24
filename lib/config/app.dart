import 'package:nylo_framework/nylo_framework.dart';

final class AppConfig {
  static final String appName =
      getEnv('APP_NAME', defaultValue: 'Aplikasi Banjarmasin Pintar');

  static final String version = getEnv('APP_VERSION', defaultValue: '3.0.9');

  static final String appUrl =
      getEnv('APP_URL', defaultValue: 'https://pintar.banjarmasinkota.go.id');

  static final String environment =
      getEnv('APP_ENV', defaultValue: 'production');

  static final String apiBaseUrl = getEnv('API_BASE_URL',
      defaultValue: 'https://pintar.banjarmasinkota.go.id');

  static final String karierApiBaseUrl = getEnv('KARIER_API_BASE_URL',
      defaultValue: 'https://karier.banjarmasinkota.go.id');

  static final String ssoRegisUrl = getEnv('SSO_REGIS_URL',
      defaultValue: 'https://pintar.banjarmasinkota.go.id/regis');

  static final String laporAndroidUrl = getEnv('LAPOR_ANDROID_URL',
      defaultValue:
          'https://www.lapor.go.id/instansi/pemerintah-kota-banjarmasin');

  static final String laporIosUrl = getEnv('LAPOR_IOS_URL',
      defaultValue: 'https://apps.apple.com/id/app/sp4n-lapor/id1486554343');

  static final String assetPath = getEnv('ASSET_PATH', defaultValue: 'assets');

  static final bool showSplashScreen =
      getEnv('SHOW_SPLASH_SCREEN', defaultValue: false);
}
