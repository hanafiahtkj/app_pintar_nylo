import '/modules/native_service_module.dart';

/// Daftar terpusat seluruh modul layanan native yang sudah tersedia di versi
/// aplikasi ini.
///
/// Cara menambah modul native baru:
/// 1. Buat folder mandiri di `lib/modules/<nama_layanan>/` beserta kelas
///    implementasi [NativeServiceModule].
/// 2. Tambahkan instance modul ke list [nativeServiceModules] di bawah ini.
/// 3. Aktifkan `is_native = 1` di backend untuk `slug` layanan tersebut saat
///    siap rilis.
final List<NativeServiceModule> nativeServiceModules = <NativeServiceModule>[
  // Contoh:
  // CctvModule(),
];
