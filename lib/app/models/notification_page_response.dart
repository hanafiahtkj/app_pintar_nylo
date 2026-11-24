import '/app/models/notification_item.dart';
import 'package:nylo_framework/nylo_framework.dart';

class NotificationPageResponse extends Model {
  late List<NotificationItem> notifications;
  late int currentPage;
  late int lastPage;
  late int perPage;
  late int total;

  static final StorageKey key = 'notification_page_response';

  NotificationPageResponse({
    this.notifications = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 10,
    this.total = 0,
  }) : super(key: key);

  NotificationPageResponse.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      final rawList = data['data'] is List ? data['data'] as List : const [];
      notifications =
          rawList.map((item) => NotificationItem.fromJson(item)).toList();

      final rawMeta = data['meta'];
      final meta = rawMeta is Map
          ? Map<String, dynamic>.from(rawMeta)
          : const <String, dynamic>{};
      currentPage = (meta['current_page'] as num?)?.toInt() ?? 1;
      lastPage = (meta['last_page'] as num?)?.toInt() ?? 1;
      perPage = (meta['per_page'] as num?)?.toInt() ?? 10;
      total = (meta['total'] as num?)?.toInt() ?? 0;
    } else {
      notifications = [];
      currentPage = 1;
      lastPage = 1;
      perPage = 10;
      total = 0;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'data': notifications.map((e) => e.toJson()).toList(),
        'meta': {
          'current_page': currentPage,
          'last_page': lastPage,
          'per_page': perPage,
          'total': total,
        },
      };
}
