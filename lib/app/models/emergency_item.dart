import 'package:nylo_framework/nylo_framework.dart';

class EmergencyItem extends Model {
  late String name;
  late String number;
  late int icon;
  late String fontFamily;
  late String color;
  late String description;

  static final StorageKey key = 'emergency_item';

  EmergencyItem({
    this.name = '',
    this.number = '',
    this.icon = 0,
    this.fontFamily = 'MaterialIcons',
    this.color = '#9E9E9E',
    this.description = '',
  }) : super(key: key);

  EmergencyItem.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      name = data['name'] ?? '';
      number = data['number'] ?? '';
      icon = (data['icon'] as num?)?.toInt() ?? 0;
      fontFamily = data['font_family'] ?? 'MaterialIcons';
      color = data['color'] ?? '#9E9E9E';
      description = data['description'] ?? '';
    } else {
      name = '';
      number = '';
      icon = 0;
      fontFamily = 'MaterialIcons';
      color = '#9E9E9E';
      description = '';
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
        'icon': icon,
        'font_family': fontFamily,
        'color': color,
        'description': description,
      };
}
