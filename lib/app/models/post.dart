import 'package:nylo_framework/nylo_framework.dart';

class Post extends Model {
  String? id;
  String? title;
  String? image_url;
  String? url;
  String? published;

  static final StorageKey key = 'post';

  Post({
    this.id,
    this.title,
    this.image_url,
    this.url,
    this.published,
  }) : super(key: key);

  Post.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      id = data['id']?.toString();
      title = data['title'];
      image_url = data['image_url'];
      url = data['url'];
      published = data['published'];
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image_url': image_url,
        'url': url,
        'published': published,
      };
}
