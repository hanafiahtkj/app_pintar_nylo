import 'package:nylo_framework/nylo_framework.dart';

class NotificationItem extends Model {
  late int id;
  late String title;
  late String desc;
  String? body;
  late String color;
  late String createdAt;
  late String time;
  late bool isRead;
  late bool isUrgent;
  String? actionType;
  String? actionUrl;
  String? actionRoute;
  String? actionPayload;
  String? sourceApp;

  static final StorageKey key = 'notification_item';

  NotificationItem({
    this.id = 0,
    this.title = '',
    this.desc = '',
    this.body,
    this.color = '#0b51b7',
    this.createdAt = '',
    this.time = '',
    this.isRead = false,
    this.isUrgent = false,
    this.actionType,
    this.actionUrl,
    this.actionRoute,
    this.actionPayload,
    this.sourceApp,
  }) : super(key: key);

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  NotificationItem.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      id = (data['id'] is num)
          ? (data['id'] as num).toInt()
          : int.tryParse(data['id']?.toString() ?? '') ?? 0;
      title = data['title']?.toString() ?? '';
      desc = data['desc']?.toString() ?? '';
      body = data['body']?.toString();
      color = data['color']?.toString() ?? '#0b51b7';
      createdAt = data['created_at']?.toString() ?? '';
      time = data['time']?.toString() ?? '';
      isRead = _parseBool(data['is_read']);
      isUrgent = _parseBool(data['is_urgent']);
      actionType = data['action_type']?.toString();
      actionUrl = data['action_url']?.toString();
      actionRoute = data['action_route']?.toString();
      actionPayload = data['action_payload']?.toString();
      final aplikasi = data['aplikasi'];
      sourceApp = (aplikasi is Map && aplikasi['nama'] != null)
          ? aplikasi['nama'].toString()
          : 'Informasi Publik';
    } else {
      id = 0;
      title = '';
      desc = '';
      color = '#0b51b7';
      createdAt = '';
      time = '';
      isRead = false;
      isUrgent = false;
      sourceApp = 'Informasi Publik';
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'desc': desc,
        'body': body,
        'color': color,
        'created_at': createdAt,
        'time': time,
        'is_read': isRead,
        'is_urgent': isUrgent,
        'action_type': actionType,
        'action_url': actionUrl,
        'action_route': actionRoute,
        'action_payload': actionPayload,
        'aplikasi': {'nama': sourceApp},
      };
}
