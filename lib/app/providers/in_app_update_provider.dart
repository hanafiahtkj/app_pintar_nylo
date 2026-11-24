import 'dart:io';
import 'package:in_app_update/in_app_update.dart';
import 'package:nylo_framework/nylo_framework.dart';

class InAppUpdateProvider implements NyProvider {
  @override
  Future<Nylo?> setup(Nylo nylo) async {
    return nylo;
  }

  @override
  Future<void> boot(Nylo nylo) async {
    if (!Platform.isAndroid) return;
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (_) {}
  }
}
