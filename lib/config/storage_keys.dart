import 'package:nylo_framework/nylo_framework.dart';

final class StorageKeysConfig {
  static Future<List<StorageKey>> Function() syncedOnBoot() => () async {
        return <StorageKey>[
          auth,
          bearerToken,
          pushNotificationsEnabled,
          launchCount,
        ];
      };

  static final StorageKey auth = 'SK_USER';

  static final StorageKey bearerToken = 'authToken';

  static final StorageKey isDarkMode = 'is_dark_mode';

  static final StorageKey readNotificationIds = 'read_notification_ids';

  static final StorageKey pushNotificationsEnabled =
      'push_notifications_enabled';

  static final StorageKey appleName = 'apple_name';

  static final StorageKey launchCount = 'launch_count';

  static final StorageKey pendingApp = 'pending_sso_app';

  static final StorageKey legacyMigrationDone = 'legacy_storage_migrated_v1';
}
