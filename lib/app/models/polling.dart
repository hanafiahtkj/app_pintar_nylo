import 'package:nylo_framework/nylo_framework.dart';

class Polling extends Model {
  double? sangatbaik;
  double? baik;
  double? cukup;
  double? kurang;

  static final StorageKey key = 'polling';

  Polling({this.sangatbaik, this.baik, this.cukup, this.kurang})
      : super(key: key);

  Polling.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      sangatbaik = (data['sangatbaik'] as num?)?.toDouble();
      baik = (data['baik'] as num?)?.toDouble();
      cukup = (data['cukup'] as num?)?.toDouble();
      kurang = (data['kurang'] as num?)?.toDouble();
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'sangatbaik': sangatbaik,
        'baik': baik,
        'cukup': cukup,
        'kurang': kurang,
      };
}
