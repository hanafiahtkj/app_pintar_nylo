import 'package:nylo_framework/nylo_framework.dart';

class LayananApp extends Model {
  int? id;
  String? slug;
  String? nama;
  int? id_kategori;
  String? keterangan;
  String? base_url;
  String? base_url_sso;
  String? path;
  String? file_name;
  int? is_sso;
  int? is_webview;
  int? is_iframe;
  int? order;
  int? status;
  int? jumlah_lihat;
  String? kategori;

  static final StorageKey key = 'layanan_app';

  LayananApp({
    this.id,
    this.slug,
    this.nama,
    this.id_kategori,
    this.keterangan,
    this.base_url,
    this.base_url_sso,
    this.path,
    this.file_name,
    this.is_sso,
    this.is_webview,
    this.is_iframe,
    this.order,
    this.status,
    this.jumlah_lihat,
    this.kategori,
  }) : super(key: key);

  LayananApp.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      id = data['id'];
      slug = data['slug'];
      nama = data['nama'];
      id_kategori = data['id_kategori'];
      keterangan = data['keterangan'];
      base_url = data['base_url'];
      base_url_sso = data['base_url_sso'];
      path = data['path'];
      file_name = data['file_name'];
      is_sso = data['is_sso'];
      is_webview = data['is_webview'];
      is_iframe = data['is_iframe'];
      order = data['order'];
      status = data['status'];
      jumlah_lihat = data['jumlah_lihat'];
      kategori = data['kategori'];
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'nama': nama,
        'id_kategori': id_kategori,
        'keterangan': keterangan,
        'base_url': base_url,
        'base_url_sso': base_url_sso,
        'path': path,
        'file_name': file_name,
        'is_sso': is_sso,
        'is_webview': is_webview,
        'is_iframe': is_iframe,
        'order': order,
        'status': status,
        'jumlah_lihat': jumlah_lihat,
        'kategori': kategori,
      };
}
