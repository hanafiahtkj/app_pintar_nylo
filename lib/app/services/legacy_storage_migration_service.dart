import '/config/storage_keys.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time migration from legacy SharedPreferences (`app_pintar_flutter`)
/// into Nylo v7 secure storage (`NyStorage` / `Auth`).
class LegacyStorageMigrationService {
  static Future<void> migrateIfNeeded() async {
    try {
      final alreadyMigrated =
          await StorageKeysConfig.legacyMigrationDone.read<bool>() ?? false;
      if (alreadyMigrated) return;

      final prefs = await SharedPreferences.getInstance();

      // 1. Auth token
      final legacyToken = prefs.getString('authToken');
      final currentToken = await StorageKeysConfig.bearerToken.read<String>();
      if ((currentToken == null || currentToken.isEmpty) &&
          legacyToken != null &&
          legacyToken.isNotEmpty) {
        await StorageKeysConfig.bearerToken
            .save(legacyToken, inBackpack: true);
        await Auth.authenticate(data: {'token': legacyToken});
      }

      // 2. Apple Sign-In cached name (Apple only sends name on first login)
      final legacyAppleName = prefs.getString('apple_name');
      final currentAppleName = await StorageKeysConfig.appleName.read<String>();
      if ((currentAppleName == null || currentAppleName.isEmpty) &&
          legacyAppleName != null &&
          legacyAppleName.isNotEmpty) {
        await StorageKeysConfig.appleName.save(legacyAppleName);
      }

      // 3. Read notification IDs
      final legacyReadIds = prefs.getStringList('read_notification_ids');
      final currentReadIds =
          await StorageKeysConfig.readNotificationIds.read<List>();
      if ((currentReadIds == null || currentReadIds.isEmpty) &&
          legacyReadIds != null &&
          legacyReadIds.isNotEmpty) {
        await StorageKeysConfig.readNotificationIds.save(legacyReadIds);
      }

      // 4. Push notification toggle preference
      if (prefs.containsKey('push_notifications_enabled')) {
        final legacyPush = prefs.getBool('push_notifications_enabled') ?? true;
        await StorageKeysConfig.pushNotificationsEnabled.save(legacyPush);
      }

      // 5. Dark mode preference
      if (prefs.containsKey('is_dark_mode')) {
        final legacyDark = prefs.getBool('is_dark_mode') ?? false;
        await StorageKeysConfig.isDarkMode.save(legacyDark, inBackpack: true);
      }

      // 6. App launch count (iOS In-App Review threshold)
      if (prefs.containsKey('launch_count')) {
        final legacyLaunchCount = prefs.getInt('launch_count') ?? 0;
        await StorageKeysConfig.launchCount.save(legacyLaunchCount);
      }

      await StorageKeysConfig.legacyMigrationDone.save(true);
    } catch (_) {
      // Never block app boot if migration fails (e.g., in unit tests)
    }
  }
}
