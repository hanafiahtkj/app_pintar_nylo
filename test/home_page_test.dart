import 'package:flutter_test/flutter_test.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:app_pintar_nylo/resources/pages/home_page.dart';
import 'package:app_pintar_nylo/bootstrap/providers.dart';
import 'package:app_pintar_nylo/bootstrap/env.g.dart';

void main() {
  NyTest.init();

  nySetUpAll(() async {
    NyEnvRegistry.register(getter: Env.get);
    await setupApplication(providers);
  });

  nyGroup('HomePage', () {
    nyWidgetTest('displays welcome header text', (tester) async {
      await tester.pumpNyWidgetSimple(HomePage());

      expect(find.text('Selamat datang,'), findsOneWidget);
      expect(find.text('Aplikasi Banjarmasin Pintar'), findsOneWidget);
    });
  });
}
