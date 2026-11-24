import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/layanan_app.dart';

/// Kontrak untuk setiap modul layanan native di bawah `lib/modules/<slug>/`.
///
/// Saat API `/api/v3/getApps` mengembalikan `is_native: 1` (atau `true`) dan
/// `slug` layanan terdaftar di [NativeServiceRegistry], aplikasi akan membuka
/// modul native ini alih-alih browser. Jika tidak, aplikasi otomatis fallback
/// ke browser (`/view/<slug>`).
abstract class NativeServiceModule {
  /// Nilai `slug` eksak dari API `/api/v3/getApps` (mis. `'cctv'`, `'parak-acil'`).
  String get slug;

  /// Mendaftarkan seluruh route Nylo milik modul ini ke [NyRouter].
  void registerRoutes(NyRouter router);

  /// Opsional: model decoders khusus milik modul ini.
  Map<Type, dynamic> get modelDecoders => const {};

  /// Opsional: API service decoders khusus milik modul ini.
  Map<Type, dynamic> get apiDecoders => const {};

  /// Opsional: controllers khusus milik modul ini.
  Map<Type, dynamic> get controllers => const {};

  /// Membuka halaman awal modul native.
  Future<void> open(BuildContext context, LayananApp app);
}
