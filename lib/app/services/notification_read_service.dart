import '/config/storage_keys.dart';
import 'package:nylo_framework/nylo_framework.dart';

class NotificationReadService {
  static final NotificationReadService _instance =
      NotificationReadService._internal();
  factory NotificationReadService() => _instance;
  NotificationReadService._internal();

  Set<int> _cachedIds = <int>{};
  bool _loaded = false;

  Future<Set<int>> getReadNotificationIds() async {
    if (_loaded) return Set<int>.from(_cachedIds);
    final list = await NyStorage.readCollection<String>(
      StorageKeysConfig.readNotificationIds,
    );
    _cachedIds = list.map(int.tryParse).whereType<int>().toSet();
    _loaded = true;
    return Set<int>.from(_cachedIds);
  }

  Set<int> get readNotificationIdsSync => Set<int>.from(_cachedIds);

  Future<void> markNotificationRead(int id) async {
    await getReadNotificationIds();
    _cachedIds.add(id);
    await NyStorage.saveCollection<String>(
      StorageKeysConfig.readNotificationIds,
      _cachedIds.map((e) => e.toString()).toList(),
    );
  }
}
