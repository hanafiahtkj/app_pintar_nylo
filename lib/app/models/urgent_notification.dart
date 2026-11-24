import 'package:nylo_framework/nylo_framework.dart';

class UrgentNotification extends Model {
  int? id;
  late String color;
  late String title;
  late String desc;
  late String time;

  static final StorageKey key = 'urgent_notification';

  UrgentNotification({
    this.id,
    this.color = '#9E9E9E',
    this.title = '',
    this.desc = '',
    this.time = '',
  }) : super(key: key);

  UrgentNotification.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      id = data['id'];
      color = data['color'] ?? '#9E9E9E';
      title = data['title'] ?? '';
      desc = data['desc'] ?? '';
      time = data['time'] ?? '';
    } else {
      color = '#9E9E9E';
      title = '';
      desc = '';
      time = '';
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color,
        'title': title,
        'desc': desc,
        'time': time,
      };
}
