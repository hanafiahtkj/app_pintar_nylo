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
  int? is_native;
  int? requires_employee_id;
  int? order;
  int? status;
  int? jumlah_lihat;
  String? kategori;

  static final StorageKey key = 'layanan_app';

  bool get isNative => is_native == 1;
  bool get isSso => is_sso == 1;
  bool get requiresEmployeeId => requires_employee_id == 1;

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
    this.is_native,
    this.requires_employee_id,
    this.order,
    this.status,
    this.jumlah_lihat,
    this.kategori,
  }) : super(key: key);

  static int? _parseFlag(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 1 : 0;
    if (value is int) return value;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == '1' || normalized == 'true') return 1;
    if (normalized == '0' || normalized == 'false') return 0;
    return int.tryParse(normalized);
  }

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
      is_sso = _parseFlag(data['is_sso']);
      is_webview = _parseFlag(data['is_webview']);
      is_iframe = _parseFlag(data['is_iframe']);
      is_native = _parseFlag(data['is_native']);
      requires_employee_id = _parseFlag(data['requires_employee_id']);
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
        'is_native': is_native,
        'requires_employee_id': requires_employee_id,
        'order': order,
        'status': status,
        'jumlah_lihat': jumlah_lihat,
        'kategori': kategori,
      };
}
