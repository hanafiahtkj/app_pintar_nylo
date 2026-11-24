import 'package:nylo_framework/nylo_framework.dart';
import '/config/native_modules.dart';
import '/modules/native_service_module.dart';

/// Registry terpusat yang memetakan `slug` layanan ke [NativeServiceModule].
class NativeServiceRegistry {
  static final NativeServiceRegistry _instance =
      NativeServiceRegistry._internal();

  factory NativeServiceRegistry() => _instance;

  NativeServiceRegistry._internal() {
    for (final module in nativeServiceModules) {
      registerModule(module);
    }
  }

  final Map<String, NativeServiceModule> _modules = {};

  String _normalizeSlug(String? slug) => (slug ?? '').trim().toLowerCase();

  /// Mendaftarkan modul native berdasarkan `slug`.
  void registerModule(NativeServiceModule module) {
    final key = _normalizeSlug(module.slug);
    if (key.isEmpty) return;
    _modules[key] = module;
  }

  /// Menghapus modul dari registry (berguna untuk pengujian).
  void unregisterModule(String slug) {
    _modules.remove(_normalizeSlug(slug));
  }

  /// Mengecek apakah modul native untuk [slug] tersedia pada build ini.
  bool hasModule(String? slug) {
    final key = _normalizeSlug(slug);
    if (key.isEmpty) return false;
    return _modules.containsKey(key);
  }

  /// Mengambil modul native untuk [slug], atau `null` jika belum tersedia.
  NativeServiceModule? findModule(String? slug) {
    final key = _normalizeSlug(slug);
    if (key.isEmpty) return null;
    return _modules[key];
  }

  /// Daftar seluruh modul terdaftar.
  List<NativeServiceModule> get modules => List.unmodifiable(_modules.values);

  /// Mendaftarkan seluruh route dari semua modul native ke [NyRouter].
  void registerAllRoutes(NyRouter router) {
    for (final module in _modules.values) {
      module.registerRoutes(router);
    }
  }

  /// Gabungan seluruh `modelDecoders` dari semua modul native.
  Map<Type, dynamic> get allModelDecoders {
    final combined = <Type, dynamic>{};
    for (final module in _modules.values) {
      combined.addAll(module.modelDecoders);
    }
    return combined;
  }

  /// Gabungan seluruh `apiDecoders` dari semua modul native.
  Map<Type, dynamic> get allApiDecoders {
    final combined = <Type, dynamic>{};
    for (final module in _modules.values) {
      combined.addAll(module.apiDecoders);
    }
    return combined;
  }

  /// Gabungan seluruh `controllers` dari semua modul native.
  Map<Type, dynamic> get allControllers {
    final combined = <Type, dynamic>{};
    for (final module in _modules.values) {
      combined.addAll(module.controllers);
    }
    return combined;
  }
}
