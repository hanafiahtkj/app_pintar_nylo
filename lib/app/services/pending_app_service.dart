import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/layanan_app.dart';
import '/app/services/chrome_safari_browser_service.dart';
import '/app/services/native_service_registry.dart';
import '/config/app.dart';
import '/config/storage_keys.dart';

class PendingApp {
  final String? slug;
  final String? baseUrlSso;
  final String? nama;
  final bool isNative;

  PendingApp({
    this.slug,
    this.baseUrlSso,
    this.nama,
    this.isNative = false,
  });

  factory PendingApp.fromJson(Map<String, dynamic> json) {
    final rawNative = json['is_native'];
    final parsedNative = rawNative == true ||
        rawNative == 1 ||
        rawNative?.toString().trim().toLowerCase() == 'true' ||
        rawNative?.toString().trim() == '1';

    return PendingApp(
      slug: json['slug']?.toString(),
      baseUrlSso: json['base_url_sso']?.toString(),
      nama: json['nama']?.toString(),
      isNative: parsedNative,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'base_url_sso': baseUrlSso,
        'nama': nama,
        'is_native': isNative,
      };
}

class PendingAppService {
  static final PendingAppService _instance = PendingAppService._internal();
  factory PendingAppService() => _instance;
  PendingAppService._internal();

  PendingApp? pendingApp;

  Future<void> initialize() async {
    if (pendingApp != null) return;
    try {
      final raw = await StorageKeysConfig.pendingApp.read<String>();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          pendingApp = PendingApp.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {}
  }

  void set(PendingApp app) {
    pendingApp = app;
    StorageKeysConfig.pendingApp.save(jsonEncode(app.toJson()));
  }

  PendingApp? consume() {
    final app = pendingApp;
    pendingApp = null;
    StorageKeysConfig.pendingApp.deleteFromStorage();
    return app;
  }

  void showPendingAppDialogIfNeeded() {
    final pending = consume();
    if (pending == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = NyNavigator.instance.router.navigatorKey?.currentContext;
      if (context == null || !context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text('Berhasil Login'),
              ],
            ),
            content: Text(
              'Apakah Anda ingin melanjutkan membuka aplikasi "${pending.nama ?? ''}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Nanti'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;
                  final registry = NativeServiceRegistry();
                  if (pending.isNative && registry.hasModule(pending.slug)) {
                    final module = registry.findModule(pending.slug);
                    if (module != null) {
                      module.open(
                        context,
                        LayananApp(
                          slug: pending.slug,
                          nama: pending.nama,
                          is_sso: 1,
                          is_native: 1,
                        ),
                      );
                      return;
                    }
                  }
                  final chromeLauncher = ChromeSafariBrowserLauncher();
                  final url = pending.baseUrlSso ??
                      '${AppConfig.apiBaseUrl}/view/${pending.slug}';
                  if (url.isNotEmpty) {
                    chromeLauncher.openBrowser(url: url, context: context);
                  }
                },
                child: const Text('Ya, Lanjutkan'),
              ),
            ],
          );
        },
      );
    });
  }
}
