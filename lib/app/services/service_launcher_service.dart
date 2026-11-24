import 'package:flutter/material.dart';
import '/app/models/layanan_app.dart';
import '/app/services/auth_service.dart';
import '/app/services/chrome_safari_browser_service.dart';
import '/app/services/pending_app_service.dart';
import '/config/app.dart';

class ServiceLauncherService {
  ServiceLauncherService._();

  static String? buildLayananUrl(String? rawSlug) {
    final slug = (rawSlug ?? '').trim();
    if (slug.isEmpty) return null;
    return '${AppConfig.apiBaseUrl}/view/$slug';
  }

  static String? buildNewsViewUrl(String? rawPostUrl) {
    final trimmed = (rawPostUrl ?? '').trim();
    if (trimmed.isEmpty) return null;
    final encoded = Uri.encodeQueryComponent(trimmed);
    return '${AppConfig.apiBaseUrl}/view/news?base_url=$encoded';
  }

  static Future<void> openLayananApp(
    BuildContext context,
    LayananApp app,
  ) async {
    final slug = (app.slug ?? '').trim();
    final url = buildLayananUrl(slug);
    if (url == null) {
      _showUnavailableMessage(context, 'Tautan layanan tidak tersedia saat ini.');
      return;
    }

    final browserLauncher = ChromeSafariBrowserLauncher();
    final isSso = app.is_sso == 1;

    if (isSso && !AuthService().isLoggedIn) {
      PendingAppService().set(
        PendingApp(
          slug: slug,
          baseUrlSso: url,
          nama: app.nama,
        ),
      );
      await browserLauncher.openBrowser(
        url: AppConfig.ssoRegisUrl,
        context: context,
      );
      return;
    }

    await browserLauncher.openBrowser(
      url: url,
      context: context,
    );
  }

  static Future<void> openNews(
    BuildContext context,
    String? rawPostUrl,
  ) async {
    final url = buildNewsViewUrl(rawPostUrl);
    if (url == null) {
      _showUnavailableMessage(context, 'Tautan berita tidak tersedia saat ini.');
      return;
    }

    await ChromeSafariBrowserLauncher().openBrowser(
      url: url,
      context: context,
    );
  }

  static void _showUnavailableMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
