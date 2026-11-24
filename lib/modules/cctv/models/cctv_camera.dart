import 'package:nylo_framework/nylo_framework.dart';

class CctvCamera extends Model {
  final String id;
  final String location;
  final String address;
  final String zone;
  final String? categoryUuid;
  final String? kecamatanUuid;
  final String? kecamatanNama;
  final String? kelurahanUuid;
  final String? kelurahanNama;
  final double latitude;
  final double longitude;
  final bool hasValidCoords;
  final String? videoUrl;

  CctvCamera({
    required this.id,
    required this.location,
    required this.address,
    required this.zone,
    this.categoryUuid,
    this.kecamatanUuid,
    this.kecamatanNama,
    this.kelurahanUuid,
    this.kelurahanNama,
    required this.latitude,
    required this.longitude,
    required this.hasValidCoords,
    this.videoUrl,
  });

  factory CctvCamera.fromFeature(Map<String, dynamic> feature, {int index = 0}) {
    final props = feature['properties'] is Map
        ? Map<String, dynamic>.from(feature['properties'] as Map)
        : feature;

    final lat = _parseDouble(props['latitude']);
    final lng = _parseDouble(props['longitude']);
    final validCoords =
        lat != null && lng != null && lat.isFinite && lng.isFinite && (lat != 0 || lng != 0);

    final category = props['category'] is Map
        ? Map<String, dynamic>.from(props['category'] as Map)
        : null;
    final kecamatan = props['kecamatan'] is Map
        ? Map<String, dynamic>.from(props['kecamatan'] as Map)
        : null;
    final kelurahan = props['kelurahan'] is Map
        ? Map<String, dynamic>.from(props['kelurahan'] as Map)
        : null;

    final rawUuid = _nonEmpty(props['uuid']);
    final rawName = _nonEmpty(props['name']);
    final rawAddress = props['address']?.toString().trim() ?? '';
    final rawUrl = _nonEmpty(props['url']);

    return CctvCamera(
      id: rawUuid ?? '${index + 1}',
      location: rawName ?? 'Kamera Tidak Bernama',
      address: rawAddress,
      zone: _nonEmpty(category?['name']) ?? 'Publik',
      categoryUuid: _nonEmpty(category?['uuid']),
      kecamatanUuid: _nonEmpty(kecamatan?['uuid']),
      kecamatanNama: _nonEmpty(kecamatan?['nama']),
      kelurahanUuid: _nonEmpty(kelurahan?['uuid']),
      kelurahanNama: _nonEmpty(kelurahan?['nama']),
      latitude: validCoords ? lat : 0,
      longitude: validCoords ? lng : 0,
      hasValidCoords: validCoords,
      videoUrl: rawUrl,
    );
  }

  static List<CctvCamera> listFromGeoJson(dynamic raw) {
    List<dynamic> features = const [];
    if (raw is Map) {
      final data = raw['data'];
      if (data is Map && data['features'] is List) {
        features = data['features'] as List<dynamic>;
      } else if (raw['features'] is List) {
        features = raw['features'] as List<dynamic>;
      } else if (data is List) {
        features = data;
      }
    } else if (raw is List) {
      features = raw;
    }

    final result = <CctvCamera>[];
    for (var i = 0; i < features.length; i++) {
      final item = features[i];
      if (item is Map) {
        result.add(
          CctvCamera.fromFeature(Map<String, dynamic>.from(item), index: i),
        );
      }
    }
    return result;
  }

  String get displayName => formatDisplayName(location);

  String get displayCategory => formatCategoryName(zone);

  String get wilayahLabel {
    final parts = <String>[];
    if (kelurahanNama != null && kelurahanNama!.isNotEmpty) {
      parts.add('Kel. $kelurahanNama');
    }
    if (kecamatanNama != null && kecamatanNama!.isNotEmpty) {
      parts.add('Kec. $kecamatanNama');
    }
    return parts.join(', ');
  }

  String get coordsLabel =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  String get coordKey =>
      '${latitude.toStringAsFixed(6)}_${longitude.toStringAsFixed(6)}';

  static String formatDisplayName(String? text) {
    if (text == null || text.isEmpty) return '';
    if (text == text.toLowerCase()) {
      return _toTitleCase(text);
    }
    return text;
  }

  static String formatCategoryName(String? text) {
    if (text == null || text.trim().isEmpty) return 'Publik';
    final lower = text.trim().toLowerCase();
    if (lower == 'atcs') return 'ATCS';
    return _toTitleCase(lower);
  }

  static String _toTitleCase(String input) {
    return input.replaceAllMapped(
      RegExp(r'\b\w'),
      (match) => match.group(0)!.toUpperCase(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  @override
  Map<String, dynamic> toJson() => {
        'uuid': id,
        'name': location,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'url': videoUrl,
        'category': {'uuid': categoryUuid, 'name': zone},
        'kecamatan': {'uuid': kecamatanUuid, 'nama': kecamatanNama},
        'kelurahan': {'uuid': kelurahanUuid, 'nama': kelurahanNama},
      };
}
