import 'package:nylo_framework/nylo_framework.dart';

class Lowongan extends Model {
  String? slug;
  String? url;
  String? judul;
  String? lokasi;
  String? gaji_minimum;
  String? gaji_maksimum;
  String? nama_perusahaan;
  String? logo_perusahaan;
  String? tanggal_posting;

  static final StorageKey key = 'lowongan';

  Lowongan({
    this.slug,
    this.url,
    this.judul,
    this.lokasi,
    this.gaji_minimum,
    this.gaji_maksimum,
    this.nama_perusahaan,
    this.logo_perusahaan,
    this.tanggal_posting,
  }) : super(key: key);

  Lowongan.fromJson(dynamic data) : super(key: key) {
    if (data is Map) {
      slug = data['slug'];
      url = data['url'];
      judul = data['judul'];
      lokasi = data['lokasi'];
      gaji_minimum = data['gaji_minimum']?.toString();
      gaji_maksimum = data['gaji_maksimum']?.toString();
      nama_perusahaan = data['nama_perusahaan'];
      logo_perusahaan = data['logo_perusahaan'];
      tanggal_posting = data['tanggal_posting'];
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'slug': slug,
        'url': url,
        'judul': judul,
        'lokasi': lokasi,
        'gaji_minimum': gaji_minimum,
        'gaji_maksimum': gaji_maksimum,
        'nama_perusahaan': nama_perusahaan,
        'logo_perusahaan': logo_perusahaan,
        'tanggal_posting': tanggal_posting,
      };
}
