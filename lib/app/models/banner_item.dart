import 'package:nylo_framework/nylo_framework.dart';

class BannerItem extends Model {
  int? id;
  String? title;
  String? image;
  String? link;
  int? order;
  String? platform;
  int? isActive;

  static final StorageKey key = 'banner_item';

  BannerItem({
    this.id,
    this.title,
    this.image,
    this.link,
    this.order,
    this.platform,
    this.isActive,
  }) : super(key: key);

  BannerItem.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      id = data['id'];
      title = data['title'];
      image = data['image'];
      link = data['link'];
      order = data['order'];
      platform = data['platform'];
      isActive = data['is_active'];
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image': image,
        'link': link,
        'order': order,
        'platform': platform,
        'is_active': isActive,
      };
}
