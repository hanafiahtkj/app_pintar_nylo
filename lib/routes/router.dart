import '/app/services/native_service_registry.dart';
import '/resources/pages/app_page.dart';
import '/resources/pages/category_page.dart';
import '/resources/pages/emergency_page.dart';
import '/resources/pages/home_page.dart';
import '/resources/pages/login_page.dart';
import '/resources/pages/lowongan_page.dart';
import '/resources/pages/not_found_page.dart';
import '/resources/pages/notification_detail_page.dart';
import '/resources/pages/notification_page.dart';
import '/resources/pages/notification_settings_page.dart';
import '/resources/pages/post_page.dart';
import '/resources/pages/profile_page.dart';
import 'package:nylo_framework/nylo_framework.dart';

NyRouter appRouter() => nyRoutes((NyRouter router) {
      router.add(HomePage.path).initialRoute();
      router.add(LoginPage.path);
      router.add(CategoryPage.path);
      router.add(AppPage.path);
      router.add(PostPage.path);
      router.add(LowonganPage.path);
      router.add(EmergencyPage.path);
      router.add(NotificationPage.path);
      router.add(NotificationDetailPage.path);
      router.add(ProfilePage.path);
      router.add(NotificationSettingsPage.path);

      // Route milik modul layanan native terdaftar di `lib/config/native_modules.dart`
      NativeServiceRegistry().registerAllRoutes(router);

      router.add(NotFoundPage.path).unknownRoute();
    });
