import 'package:nylo_framework/nylo_framework.dart';

class Hotline extends Model {
  String? text;

  static final StorageKey key = 'hotline';

  Hotline({this.text}) : super(key: key);

  Hotline.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      text = data['text'];
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'text': text,
      };
}
