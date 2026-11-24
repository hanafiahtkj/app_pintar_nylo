import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class NotFoundPage extends NyStatefulWidget {
  static RouteView path = ("/not-found", (_) => NotFoundPage());

  NotFoundPage({super.key}) : super(child: () => _NotFoundPageState());
}

class _NotFoundPageState extends NyPage<NotFoundPage> {
  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 768;
    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.14);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: false,
        title: const Text(
          'Halaman Tidak Ditemukan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 20,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isWide ? 28 : 24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentBlue.withValues(alpha: isDark ? 0.18 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.explore_off_outlined,
                        size: 28,
                        color: accentBlue,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Konten Tidak Tersedia',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tautan yang Anda buka mungkin sudah dipindahkan atau alamat halaman tidak valid.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: mutedColor,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => routeToInitial(),
                        icon: const Icon(Icons.home_rounded, size: 19),
                        label: const Text(
                          'Kembali ke Beranda',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentBlue,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
