import 'package:app_pintar_nylo/app/providers/in_app_update_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';

AppUpdateInfo _buildUpdateInfo({
  required UpdateAvailability availability,
  bool flexibleAllowed = true,
  InstallStatus installStatus = InstallStatus.unknown,
}) {
  return AppUpdateInfo(
    updateAvailability: availability,
    immediateUpdateAllowed: true,
    immediateAllowedPreconditions: const [],
    flexibleUpdateAllowed: flexibleAllowed,
    flexibleAllowedPreconditions: const [],
    availableVersionCode: 999,
    installStatus: installStatus,
    packageName: 'com.diskominfotik.banjarmasinpintar',
    clientVersionStalenessDays: 1,
    updatePriority: 3,
  );
}

void main() {
  group('InAppUpdateProvider', () {
    test('runs check -> start -> complete when update available and accepted',
        () async {
      final calls = <String>[];
      final provider = InAppUpdateProvider(
        isAndroidOverride: true,
        checkForUpdateFn: () async {
          calls.add('check');
          return _buildUpdateInfo(
            availability: UpdateAvailability.updateAvailable,
            flexibleAllowed: true,
          );
        },
        startFlexibleUpdateFn: () async {
          calls.add('start');
          return AppUpdateResult.success;
        },
        completeFlexibleUpdateFn: () async {
          calls.add('complete');
        },
      );

      await provider.checkForUpdate();
      expect(calls, ['check', 'start', 'complete']);
    });

    test('stops after start when user denies flexible update', () async {
      final calls = <String>[];
      final provider = InAppUpdateProvider(
        isAndroidOverride: true,
        checkForUpdateFn: () async {
          calls.add('check');
          return _buildUpdateInfo(
            availability: UpdateAvailability.updateAvailable,
            flexibleAllowed: true,
          );
        },
        startFlexibleUpdateFn: () async {
          calls.add('start');
          return AppUpdateResult.userDeniedUpdate;
        },
        completeFlexibleUpdateFn: () async {
          calls.add('complete');
        },
      );

      await provider.checkForUpdate();
      expect(calls, ['check', 'start']);
    });

    test('does not start when flexible update is not allowed', () async {
      final calls = <String>[];
      final provider = InAppUpdateProvider(
        isAndroidOverride: true,
        checkForUpdateFn: () async {
          calls.add('check');
          return _buildUpdateInfo(
            availability: UpdateAvailability.updateAvailable,
            flexibleAllowed: false,
          );
        },
        startFlexibleUpdateFn: () async {
          calls.add('start');
          return AppUpdateResult.success;
        },
        completeFlexibleUpdateFn: () async {
          calls.add('complete');
        },
      );

      await provider.checkForUpdate();
      expect(calls, ['check']);
    });

    test('does not start when update is not available', () async {
      final calls = <String>[];
      final provider = InAppUpdateProvider(
        isAndroidOverride: true,
        checkForUpdateFn: () async {
          calls.add('check');
          return _buildUpdateInfo(
            availability: UpdateAvailability.updateNotAvailable,
          );
        },
        startFlexibleUpdateFn: () async {
          calls.add('start');
          return AppUpdateResult.success;
        },
        completeFlexibleUpdateFn: () async {
          calls.add('complete');
        },
      );

      await provider.checkForUpdate();
      expect(calls, ['check']);
    });

    test('completes immediately when installStatus is already downloaded',
        () async {
      final calls = <String>[];
      final provider = InAppUpdateProvider(
        isAndroidOverride: true,
        checkForUpdateFn: () async {
          calls.add('check');
          return _buildUpdateInfo(
            availability: UpdateAvailability.developerTriggeredUpdateInProgress,
            installStatus: InstallStatus.downloaded,
          );
        },
        startFlexibleUpdateFn: () async {
          calls.add('start');
          return AppUpdateResult.success;
        },
        completeFlexibleUpdateFn: () async {
          calls.add('complete');
        },
      );

      await provider.checkForUpdate();
      expect(calls, ['check', 'complete']);
    });

    test('skips checkForUpdate on non-Android platforms', () async {
      final calls = <String>[];
      final provider = InAppUpdateProvider(
        isAndroidOverride: false,
        checkForUpdateFn: () async {
          calls.add('check');
          return _buildUpdateInfo(
            availability: UpdateAvailability.updateAvailable,
          );
        },
      );

      await provider.checkForUpdate();
      expect(calls, isEmpty);
    });

    test('catches exceptions thrown during checkForUpdate safely', () async {
      final provider = InAppUpdateProvider(
        isAndroidOverride: true,
        checkForUpdateFn: () async {
          throw Exception('Play Store unavailable');
        },
      );

      await expectLater(provider.checkForUpdate(), completes);
    });
  });
}
