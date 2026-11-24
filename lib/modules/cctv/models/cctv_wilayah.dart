import 'package:nylo_framework/nylo_framework.dart';

class CctvKelurahan extends Model {
  final String uuid;
  final String nama;

  CctvKelurahan({
    required this.uuid,
    required this.nama,
  });

  factory CctvKelurahan.fromJson(Map<String, dynamic> json) {
    return CctvKelurahan(
      uuid: json['uuid']?.toString().trim() ?? '',
      nama: json['nama']?.toString().trim() ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'nama': nama,
      };
}

class CctvKecamatan extends Model {
  final String uuid;
  final String namaKecamatan;
  final List<CctvKelurahan> kelurahan;

  CctvKecamatan({
    required this.uuid,
    required this.namaKecamatan,
    required this.kelurahan,
  });

  factory CctvKecamatan.fromJson(Map<String, dynamic> json) {
    final rawKel = json['kelurahan'];
    final kelList = rawKel is List
        ? rawKel
            .whereType<Map>()
            .map((e) => CctvKelurahan.fromJson(Map<String, dynamic>.from(e)))
            .where((k) => k.uuid.isNotEmpty)
            .toList()
        : <CctvKelurahan>[];

    return CctvKecamatan(
      uuid: json['uuid']?.toString().trim() ?? '',
      namaKecamatan: json['nama_kecamatan']?.toString().trim() ?? '',
      kelurahan: kelList,
    );
  }

  static List<CctvKecamatan> listFromResponse(dynamic raw) {
    List<dynamic> items = const [];
    if (raw is Map && raw['data'] is List) {
      items = raw['data'] as List<dynamic>;
    } else if (raw is List) {
      items = raw;
    }

    return items
        .whereType<Map>()
        .map((e) => CctvKecamatan.fromJson(Map<String, dynamic>.from(e)))
        .where((k) => k.uuid.isNotEmpty)
        .toList();
  }

  @override
  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'nama_kecamatan': namaKecamatan,
        'kelurahan': kelurahan.map((k) => k.toJson()).toList(),
      };
}
