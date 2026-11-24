import 'package:nylo_framework/nylo_framework.dart';

class CategoryItem extends Model {
  int? id;
  String? slug;
  String? nama;
  String? keterangan;
  String? path;
  String? file_name;
  int? urut;

  static final StorageKey key = 'category_item';

  CategoryItem({
    this.id,
    this.slug,
    this.nama,
    this.keterangan,
    this.path,
    this.file_name,
    this.urut,
  }) : super(key: key);

  CategoryItem.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      id = data['id'];
      slug = data['slug'];
      nama = data['nama'];
      keterangan = data['keterangan'];
      path = data['path'];
      file_name = data['file_name'];
      urut = data['urut'];
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'nama': nama,
        'keterangan': keterangan,
        'path': path,
        'file_name': file_name,
        'urut': urut,
      };
}
