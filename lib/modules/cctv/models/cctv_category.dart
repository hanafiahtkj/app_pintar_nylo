import 'package:nylo_framework/nylo_framework.dart';
import 'cctv_camera.dart';

class CctvCategory extends Model {
  final String uuid;
  final String name;

  CctvCategory({
    required this.uuid,
    required this.name,
  });

  factory CctvCategory.fromJson(Map<String, dynamic> json) {
    return CctvCategory(
      uuid: json['uuid']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
    );
  }

  static List<CctvCategory> listFromResponse(dynamic raw) {
    List<dynamic> items = const [];
    if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List<dynamic>;
    } else if (raw is List) {
      items = raw;
    }

    return items
        .whereType<Map>()
        .map((e) => CctvCategory.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.uuid.isNotEmpty)
        .toList();
  }

  String get displayName => CctvCamera.formatCategoryName(name);

  @override
  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
      };
}
