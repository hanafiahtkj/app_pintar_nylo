import '/app/models/emergency_item.dart';
import 'package:nylo_framework/nylo_framework.dart';

class EmergencyCategory extends Model {
  late String categoryName;
  late List<EmergencyItem> items;

  static final StorageKey key = 'emergency_category';

  EmergencyCategory({
    this.categoryName = '',
    this.items = const [],
  }) : super(key: key);

  EmergencyCategory.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      categoryName = data['category_name'] ?? '';
      items = (data['items'] as List<dynamic>?)
              ?.map((e) => EmergencyItem.fromJson(e))
              .toList() ??
          <EmergencyItem>[];
    } else {
      categoryName = '';
      items = <EmergencyItem>[];
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'category_name': categoryName,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
