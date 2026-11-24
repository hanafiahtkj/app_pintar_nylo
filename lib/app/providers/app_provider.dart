import 'package:flutter/services.dart';
import '/app/services/auth_service.dart';
import '/app/services/legacy_storage_migration_service.dart';
import '/app/services/notification_read_service.dart';
import '/app/services/pending_app_service.dart';
import '/config/storage_keys.dart';
import '/config/toast_notification.dart';
import '/bootstrap/decoders.dart';
import '/config/design.dart';
import '/bootstrap/theme.dart';
import '/config/localization.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/bootstrap/seeders.dart';
import '/bootstrap/playbooks.dart';

class AppProvider implements NyProvider {
  @override
  setup(Nylo nylo) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    await nylo.configure(
      localization: NyLocalizationConfig(
        languageCode: LocalizationConfig.languageCode,
        localeType: LocalizationConfig.localeType,
        assetsDirectory: LocalizationConfig.assetsDirectory,
      ),
      loader: DesignConfig.loader,
      logo: DesignConfig.logo,
      formFieldStyle: DesignConfig.formFieldStyle,
      themes: appThemes,
      initialThemeId: 'light_theme',
      toastNotifications: ToastNotificationConfig.styles,
      modelDecoders: modelDecoders,
      controllers: controllers,
      apiDecoders: apiDecoders,
      authKey: StorageKeysConfig.auth,
      syncKeys: StorageKeysConfig.syncedOnBoot,
      monitorAppUsage: false,
      showDateTimeInLogs: false,
      broadcastEvents: true,
      useErrorStack: getEnv('APP_DEBUG', defaultValue: false) == true,
      seeders: seeders,
      playbooks: playbooks,
    );

    return nylo;
  }

  @override
  boot(Nylo nylo) async {
    await LegacyStorageMigrationService.migrateIfNeeded();
    await PendingAppService().initialize();
    await NotificationReadService().getReadNotificationIds();
    await AuthService().initialize();
  }
}
