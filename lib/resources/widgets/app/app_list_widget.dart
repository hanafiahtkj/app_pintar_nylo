import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/layanan_app.dart';
import '/app/networking/pintar_api_service.dart';
import '/app/services/service_launcher_service.dart';
import '/config/app.dart';

class AppListWidget extends StatefulWidget {
  final String? search;
  final int? idKategori;

  const AppListWidget({super.key, this.search, this.idKategori});

  @override
  State<AppListWidget> createState() => _AppListWidgetState();
}

class _AppListWidgetState extends NyState<AppListWidget> {
  List<LayananApp>? _apps;
  bool _loading = true;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        _fetchApps();
      };

  @override
  void didUpdateWidget(covariant AppListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idKategori != widget.idKategori) {
      _fetchApps();
    }
  }

  Future<void> _fetchApps() async {
    if (mounted && !_loading) {
      setState(() => _loading = true);
    }
    try {
      final result = await api<PintarApiService>(
        (request) => request.getApps(idKategori: widget.idKategori),
      );
      if (mounted) {
        setState(() {
          _apps = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showToastDanger(
          title: 'Gagal Memuat',
          description: 'Tidak dapat memuat daftar layanan.',
        );
      }
    }
  }

  int _resolveColumns(double maxWidth) {
    if (maxWidth >= 980) return 3;
    if (maxWidth >= 600) return 2;
    return 1;
  }

  @override
  Widget view(BuildContext context) {
    if (_loading) {
      return Skeletonizer(
        enabled: true,
        child: _buildSkeletonList(context),
      );
    }

    if (_apps == null) {
      return _buildEmptyState(context);
    }

    final query = widget.search?.trim().toLowerCase() ?? '';
    final filteredApps = _apps!
        .where((app) =>
            (app.nama?.toLowerCase().contains(query) ?? false) ||
            (app.keterangan?.toLowerCase().contains(query) ?? false) ||
            (app.kategori?.toLowerCase().contains(query) ?? false))
        .toList();

    if (filteredApps.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildColumnList(context, filteredApps);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Layanan tidak ditemukan',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Coba ubah kata kunci pencarian Anda.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnList(BuildContext context, List<LayananApp> apps) {
    if (widget.idKategori == null) {
      return _buildCategorizedList(context, apps);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildResponsiveGrid(context, apps, constraints.maxWidth);
      },
    );
  }

  Widget _buildCategorizedList(BuildContext context, List<LayananApp> apps) {
    final Map<String, List<LayananApp>> grouped = {};
    final orderedKeys = <String>[];
    for (final app in apps) {
      final cat = app.kategori ?? 'Lainnya';
      if (!grouped.containsKey(cat)) {
        orderedKeys.add(cat);
      }
      grouped.putIfAbsent(cat, () => []).add(app);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: orderedKeys.asMap().entries.map((entry) {
            final idx = entry.key;
            final category = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: 4.0,
                    top: idx == 0 ? 4.0 : 20.0,
                    bottom: 10.0,
                  ),
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                _buildResponsiveGrid(
                  context,
                  grouped[category]!,
                  constraints.maxWidth,
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildResponsiveGrid(
    BuildContext context,
    List<LayananApp> apps,
    double maxWidth,
  ) {
    final cols = _resolveColumns(maxWidth);
    const double spacing = 12.0;
    final double itemWidth =
        cols == 1 ? maxWidth : (maxWidth - spacing * (cols - 1)) / cols;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: apps
          .map((app) => _buildListItem(context, app, itemWidth: itemWidth))
          .toList(),
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _resolveColumns(constraints.maxWidth);
        const double spacing = 12.0;
        final double itemWidth = cols == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            cols * 3,
            (index) => Container(
              width: itemWidth,
              height: 92,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    LayananApp app, {
    required double itemWidth,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: itemWidth,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? theme.dividerColor.withValues(alpha: 0.16)
                : const Color(0xFFEEF2F7),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A)
                  .withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ServiceLauncherService.openLayananApp(context, app),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: '${AppConfig.apiBaseUrl}/storage/${app.path}',
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: theme.dividerColor.withValues(alpha: 0.12),
                          child: const Icon(
                          Icons.broken_image_outlined,
                          size: 26,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        app.nama ?? 'Layanan',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.keterangan ?? 'Tidak ada deskripsi',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? Colors.grey.shade400
                              : const Color(0xFF64748B),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
