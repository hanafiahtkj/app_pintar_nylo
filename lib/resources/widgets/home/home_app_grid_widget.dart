import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/layanan_app.dart';
import '/app/networking/pintar_api_service.dart';
import '/app/services/service_launcher_service.dart';
import '/config/app.dart';
import '/resources/pages/category_page.dart';

class HomeAppGridWidget extends StatefulWidget {
  static String state = 'home_app_grid';
  final String? search;
  final int? idKategori;

  const HomeAppGridWidget({super.key, this.search, this.idKategori});

  @override
  State<HomeAppGridWidget> createState() => _HomeAppGridWidgetState();
}

class _HomeAppGridWidgetState extends NyState<HomeAppGridWidget> {
  List<LayananApp>? _apps;
  bool _loading = true;

  _HomeAppGridWidgetState() {
    stateName = HomeAppGridWidget.state;
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        _fetchApps();
      };

  @override
  Future<void> stateUpdated(dynamic data) async {
    await _fetchApps();
  }

  Future<void> _fetchApps() async {
    if (mounted && !_loading) {
      setState(() => _loading = true);
    }
    try {
      final result = await api<PintarApiService>(
        (request) => request.getApps(
          search: widget.search,
          idKategori: widget.idKategori,
        ),
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
        showToastDanger(title: 'Error', description: e.toString());
      }
    }
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
      return const Center(
        child: Text('Tidak ada aplikasi ditemukan'),
      );
    }

    return _buildGridList(context);
  }

  int _resolveCrossAxisCount(double maxWidth) {
    if (maxWidth < 340) return 3;
    if (maxWidth < 600) return 4;
    if (maxWidth < 860) return 6;
    return 7;
  }

  Widget _buildSkeletonList(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _resolveCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount >= 6 ? crossAxisCount : 8,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 10.0,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            return Column(
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 56,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGridList(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _resolveCrossAxisCount(constraints.maxWidth);
        final totalItems = (_apps?.length ?? 0) + 1;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalItems,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 10.0,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            if (index == totalItems - 1) {
              return _buildSeeAllItem(context);
            }
            return _buildGridItem(context, index);
          },
        );
      },
    );
  }

  Widget _buildSeeAllItem(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          routeTo(CategoryPage.path);
        },
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isDark
                    ? Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.16),
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A)
                        .withValues(alpha: isDark ? 0.22 : 0.055),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.asset(
                    'assets/icons/semua_layanan.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.grid_view_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 7.0, left: 4.0, right: 4.0),
                child: Text(
                  'Semua',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, int position) {
    final app = _apps?[position];
    if (app == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => ServiceLauncherService.openLayananApp(context, app),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isDark
                    ? Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.16),
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A)
                        .withValues(alpha: isDark ? 0.22 : 0.055),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: ColorFiltered(
                    colorFilter: isDark
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          )
                        : const ColorFilter.matrix(<double>[
                            1.09, 0, 0, 0, 0,
                            0, 1.09, 0, 0, 0,
                            0, 0, 1.09, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                    child: CachedNetworkImage(
                      imageUrl: '${AppConfig.apiBaseUrl}/storage/${app.path}',
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 7.0, left: 4.0, right: 4.0),
                child: Text(
                  app.nama ?? 'Layanan',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
