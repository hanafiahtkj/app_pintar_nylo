import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:nylo_framework/nylo_framework.dart';

typedef CheckForUpdateFn = Future<AppUpdateInfo> Function();
typedef StartFlexibleUpdateFn = Future<AppUpdateResult> Function();
typedef CompleteFlexibleUpdateFn = Future<void> Function();

/// Provider untuk mengecek dan menjalankan Android Flexible In-App Update.
class InAppUpdateProvider implements NyProvider {
  static const bool _simulateFromEnv =
      bool.fromEnvironment('SIMULATE_IN_APP_UPDATE');

  final CheckForUpdateFn? _checkForUpdateFn;
  final StartFlexibleUpdateFn? _startFlexibleUpdateFn;
  final CompleteFlexibleUpdateFn? _completeFlexibleUpdateFn;
  final bool? _isAndroidOverride;
  final bool? _simulateOverride;
  final Duration _bootDelay;

  InAppUpdateProvider({
    CheckForUpdateFn? checkForUpdateFn,
    StartFlexibleUpdateFn? startFlexibleUpdateFn,
    CompleteFlexibleUpdateFn? completeFlexibleUpdateFn,
    bool? isAndroidOverride,
    bool? simulateOverride,
    Duration bootDelay = const Duration(seconds: 1),
  })  : _checkForUpdateFn = checkForUpdateFn,
        _startFlexibleUpdateFn = startFlexibleUpdateFn,
        _completeFlexibleUpdateFn = completeFlexibleUpdateFn,
        _isAndroidOverride = isAndroidOverride,
        _simulateOverride = simulateOverride,
        _bootDelay = bootDelay;

  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  bool get _isSimulationEnabled =>
      kDebugMode && (_simulateOverride ?? _simulateFromEnv);

  @override
  Future<Nylo?> setup(Nylo nylo) async {
    return nylo;
  }

  @override
  Future<void> boot(Nylo nylo) async {
    if (!_isAndroid) return;
    _log('boot() dipanggil (simulasi: $_isSimulationEnabled)');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(_bootDelay, checkForUpdate);
    });
  }

  /// Mengecek ketersediaan update dan menjalankan alur flexible update jika tersedia.
  Future<void> checkForUpdate() async {
    if (!_isAndroid) return;

    final CheckForUpdateFn checkFn = _checkForUpdateFn ??
        (_isSimulationEnabled
            ? _simulatedCheckForUpdate
            : InAppUpdate.checkForUpdate);
    final StartFlexibleUpdateFn startFn = _startFlexibleUpdateFn ??
        (_isSimulationEnabled
            ? _simulatedStartFlexibleUpdate
            : InAppUpdate.startFlexibleUpdate);
    final CompleteFlexibleUpdateFn completeFn = _completeFlexibleUpdateFn ??
        (_isSimulationEnabled
            ? _simulatedCompleteFlexibleUpdate
            : InAppUpdate.completeFlexibleUpdate);

    try {
      _log('Memanggil checkForUpdate()...');
      final AppUpdateInfo info = await checkFn();
      _log(
        'Hasil checkForUpdate(): availability=${info.updateAvailability}, '
        'flexibleAllowed=${info.flexibleUpdateAllowed}, '
        'installStatus=${info.installStatus}, '
        'availableVersionCode=${info.availableVersionCode}',
      );

      if (info.installStatus == InstallStatus.downloaded) {
        _log(
          'Update sudah terunduh sebelumnya, memanggil completeFlexibleUpdate()...',
        );
        await completeFn();
        _log('completeFlexibleUpdate() selesai dipanggil.');
        return;
      }

      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.flexibleUpdateAllowed) {
        _log('Update tersedia! Memanggil startFlexibleUpdate()...');
        final AppUpdateResult result = await startFn();
        _log('Hasil startFlexibleUpdate(): $result');

        if (result == AppUpdateResult.success) {
          _log('Unduhan berhasil, memanggil completeFlexibleUpdate()...');
          await completeFn();
          _log('completeFlexibleUpdate() selesai dipanggil.');
        }
      } else {
        _log('Tidak ada update fleksibel yang perlu dijalankan.');
      }
    } catch (e) {
      _log('Gagal cek update: $e');
    }
  }

  Future<AppUpdateInfo> _simulatedCheckForUpdate() async {
    return AppUpdateInfo(
      updateAvailability: UpdateAvailability.updateAvailable,
      immediateUpdateAllowed: true,
      immediateAllowedPreconditions: const [],
      flexibleUpdateAllowed: true,
      flexibleAllowedPreconditions: const [],
      availableVersionCode: 999,
      installStatus: InstallStatus.unknown,
      packageName: 'com.diskominfotik.banjarmasinpintar',
      clientVersionStalenessDays: 1,
      updatePriority: 3,
    );
  }

  Future<BuildContext?> _waitForNavigatorContext() async {
    for (int i = 0; i < 30; i++) {
      final context = NyNavigator.instance.router.navigatorKey?.currentContext;
      if (context != null && context.mounted) {
        return context;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return null;
  }

  Future<AppUpdateResult> _simulatedStartFlexibleUpdate() async {
    final context = await _waitForNavigatorContext();
    if (context == null || !context.mounted) {
      _log('[SIMULATION] Navigator context tidak tersedia.');
      return AppUpdateResult.inAppUpdateFailed;
    }

    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Simulasi Update Tersedia'),
        content: const Text(
          'InAppUpdateProvider berhasil berjalan saat boot.\n\n'
          'Simulasi Play Store mendeteksi versi baru (versionCode: 999). '
          'Pilih aksi untuk menguji alur Flexible Update:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Update Sekarang'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      _log(
        '[SIMULATION] User menerima update — menyimulasikan unduhan...',
      );
      await Future.delayed(const Duration(milliseconds: 600));
      return AppUpdateResult.success;
    }

    _log('[SIMULATION] User menolak update (userDeniedUpdate).');
    return AppUpdateResult.userDeniedUpdate;
  }

  Future<void> _simulatedCompleteFlexibleUpdate() async {
    _log(
      '[SIMULATION] completeFlexibleUpdate() dipanggil — update siap di-install!',
    );
    final context = NyNavigator.instance.router.navigatorKey?.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'Simulasi In-App Update selesai: completeFlexibleUpdate() terpanggil!',
          ),
        ),
      );
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[InAppUpdateProvider] $message');
    }
  }
}
