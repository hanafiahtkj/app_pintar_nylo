import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:app_pintar_nylo/app/models/notification_item.dart';
import 'package:app_pintar_nylo/app/models/notification_page_response.dart';
import 'package:app_pintar_nylo/app/services/pending_app_service.dart';
import 'package:app_pintar_nylo/app/services/service_launcher_service.dart';
import 'package:app_pintar_nylo/bootstrap/env.g.dart';
import 'package:app_pintar_nylo/bootstrap/providers.dart';
import 'package:app_pintar_nylo/resources/pages/app_page.dart';
import 'package:app_pintar_nylo/resources/pages/category_page.dart';
import 'package:app_pintar_nylo/resources/pages/emergency_page.dart';
import 'package:app_pintar_nylo/resources/pages/login_page.dart';
import 'package:app_pintar_nylo/resources/pages/not_found_page.dart';
import 'package:app_pintar_nylo/resources/pages/notification_settings_page.dart';
import 'package:app_pintar_nylo/resources/pages/profile_page.dart';

void main() {
  NyTest.init();

  nySetUpAll(() async {
    NyEnvRegistry.register(getter: Env.get);
    await setupApplication(providers);
  });

  group('Defensive Model & Service Parsing', () {
    test('NotificationItem handles bool, int, string flags and non-Map aplikasi',
        () {
      final item = NotificationItem.fromJson({
        'id': '42',
        'title': 'Pengumuman',
        'desc': 'Isi ringkas',
        'is_read': 1,
        'is_urgent': 'true',
        'aplikasi': [],
      });

      expect(item.id, 42);
      expect(item.isRead, isTrue);
      expect(item.isUrgent, isTrue);
      expect(item.sourceApp, 'Informasi Publik');
    });

    test('NotificationPageResponse handles untyped Map<dynamic, dynamic> meta',
        () {
      final Map<dynamic, dynamic> raw = {
        'data': [
          {'id': 1, 'title': 'Tes', 'desc': 'Desc'}
        ],
        'meta': <dynamic, dynamic>{
          'current_page': 2,
          'last_page': 5,
          'per_page': 10,
          'total': 48,
        },
      };

      final response = NotificationPageResponse.fromJson(raw);
      expect(response.notifications.length, 1);
      expect(response.currentPage, 2);
      expect(response.lastPage, 5);
      expect(response.perPage, 10);
      expect(response.total, 48);
    });

    test('PendingApp round-trips JSON cleanly', () {
      final app = PendingApp(
        slug: 'parak-acil',
        baseUrlSso: 'https://pintar.banjarmasinkota.go.id/sso/parak-acil',
        nama: 'Parak Acil Online',
      );
      final restored = PendingApp.fromJson(app.toJson());
      expect(restored.slug, app.slug);
      expect(restored.baseUrlSso, app.baseUrlSso);
      expect(restored.nama, app.nama);
    });
  });

  nyWidgetTest(
    'CategoryPage renders without crashing when opened with no route data (AUD-01)',
    (tester) async {
      await tester.pumpNyWidgetSimple(CategoryPage());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Kategori'), findsOneWidget);
    },
  );

  nyWidgetTest(
    'AppPage renders without crashing when opened with no route data (AUD-02)',
    (tester) async {
      await tester.pumpNyWidgetSimple(AppPage());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    },
  );

  nyWidgetTest(
    'EmergencyPage and NotFoundPage render cleanly with AppBar',
    (tester) async {
      await tester.pumpNyWidgetSimple(EmergencyPage());
      await tester.pump();
      expect(find.text('Panggilan Darurat'), findsOneWidget);

      await tester.pumpNyWidgetSimple(NotFoundPage());
      await tester.pump();
      expect(find.text('Halaman Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    },
  );

  nyWidgetTest(
    'LoginPage renders constrained auth card cleanly on Mobile and Tablet viewports',
    (tester) async {
      // Mobile viewport (390x844)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpNyWidgetSimple(LoginPage());
      await tester.pump();
      expect(find.text('Masuk ke Banjarmasin Pintar'), findsOneWidget);
      expect(find.text('Masuk dengan SSO'), findsOneWidget);

      // Tablet viewport (1024x768) — verify SSO button width is constrained (<= 440)
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pump();
      final ssoButtonRect = tester.getRect(find.text('Masuk dengan SSO'));
      expect(ssoButtonRect.width, lessThanOrEqualTo(440));
    },
  );

  nyWidgetTest(
    'ProfilePage renders constrained login prompt cleanly on Mobile and Tablet viewports',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpNyWidgetSimple(ProfilePage());
      await tester.pump();
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Masuk untuk Melihat Profil'), findsOneWidget);

      tester.view.physicalSize = const Size(1024, 768);
      await tester.pump();
      final ssoRect = tester.getRect(find.text('Masuk dengan SSO'));
      expect(ssoRect.width, lessThanOrEqualTo(440));
    },
  );

  nyWidgetTest(
    'NotificationSettingsPage renders constrained settings card on Mobile and Tablet',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpNyWidgetSimple(NotificationSettingsPage());
      await tester.pump();
      expect(find.text('Pengaturan Notifikasi'), findsOneWidget);
      expect(find.text('Notifikasi Push'), findsOneWidget);

      tester.view.physicalSize = const Size(1024, 768);
      await tester.pump();
      final tileRect = tester.getRect(find.byType(SwitchListTile));
      expect(tileRect.width, lessThanOrEqualTo(760));
    },
  );

  group('ServiceLauncherService URL Guards & Encoding', () {
    test('buildLayananUrl rejects null/blank slugs and builds valid path', () {
      expect(ServiceLauncherService.buildLayananUrl(null), isNull);
      expect(ServiceLauncherService.buildLayananUrl('   '), isNull);
      expect(
        ServiceLauncherService.buildLayananUrl('cctv'),
        endsWith('/view/cctv'),
      );
    });

    test('buildNewsViewUrl encodes query params and rejects blank urls', () {
      expect(ServiceLauncherService.buildNewsViewUrl(null), isNull);
      expect(ServiceLauncherService.buildNewsViewUrl('  '), isNull);

      final built = ServiceLauncherService.buildNewsViewUrl(
        'https://berita.banjarmasinkota.go.id/detail?id=10&ref=home',
      );
      expect(built, isNotNull);
      final parsed = Uri.parse(built!);
      expect(
        parsed.queryParameters['base_url'],
        'https://berita.banjarmasinkota.go.id/detail?id=10&ref=home',
      );
    });
  });
}
