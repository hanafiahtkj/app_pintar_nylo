import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:app_pintar_nylo/bootstrap/providers.dart';
import 'package:app_pintar_nylo/bootstrap/env.g.dart';
import 'package:app_pintar_nylo/resources/pages/home_page.dart';

void main() {
  NyTest.init();

  nySetUpAll(() async {
    NyEnvRegistry.register(getter: Env.get);
    await setupApplication(providers);
  });

  nyGroup('Widget Tests', () {
    nyWidgetTest('can render HomePage widget', (tester) async {
      await tester.pumpNyWidgetSimple(HomePage());
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  nyGroup('Route Assertions', () {
    nyTest('can check if routes exist', () async {
      expectRoutesExist([
        '/home',
        '/login',
        '/category',
        '/app',
        '/post',
        '/lowongan',
        '/emergency',
        '/notification',
        '/notification-detail',
        '/profile',
        '/notification-settings',
      ]);
    });
  });
}
