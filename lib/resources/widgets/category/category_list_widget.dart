import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/category_item.dart';
import '/app/networking/pintar_api_service.dart';
import '/config/app.dart';
import '/resources/pages/app_page.dart';

class CategoryListWidget extends StatefulWidget {
  final String? search;
  final Function(int)? onTap;

  const CategoryListWidget({super.key, this.search, this.onTap});

  @override
  State<CategoryListWidget> createState() => _CategoryListWidgetState();
}

class _CategoryListWidgetState extends NyState<CategoryListWidget> {
  List<CategoryItem>? _categories;
  bool _loading = true;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        _fetchCategories();
      };

  Future<void> _fetchCategories() async {
    if (mounted && !_loading) {
      setState(() => _loading = true);
    }
    try {
      final result =
          await api<PintarApiService>((request) => request.getCategories());
      if (mounted) {
        setState(() {
          _categories = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showToastDanger(
          title: 'Gagal Memuat',
          description: 'Tidak dapat memuat daftar kategori layanan.',
        );
      }
    }
  }

  int _resolveColumns(double maxWidth) {
    if (maxWidth < 560) return 1;
    if (maxWidth < 900) return 2;
    return 3;
  }

  @override
  Widget view(BuildContext context) {
    if (_loading) {
      return Skeletonizer(
        enabled: true,
        child: _buildSkeletonList(context),
      );
    }

    if (_categories != null) {
      final query = widget.search?.trim().toLowerCase() ?? '';
      final filteredCategories = _categories!
          .where((category) =>
              category.nama?.toLowerCase().contains(query) ?? true)
          .toList();

      if (filteredCategories.isNotEmpty) {
        return _buildGridList(context, filteredCategories);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: 44,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Kategori tidak ditemukan',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Coba gunakan kata kunci pencarian lain.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _resolveColumns(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            mainAxisExtent: 76.0,
          ),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 12,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 68,
                          height: 10,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridList(BuildContext context, List<CategoryItem> categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _resolveColumns(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            mainAxisExtent: 76.0,
          ),
          itemBuilder: (context, index) {
            return _buildGridItem(context, categories[index]);
          },
        );
      },
    );
  }

  Widget _buildGridItem(BuildContext context, CategoryItem category) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            routeTo(
              AppPage.path,
              data: {
                'id': category.id,
                'name': category.nama,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl:
                          '${AppConfig.apiBaseUrl}/api/v3/category/image/${category.id}/128/98',
                      errorWidget: (context, url, error) => Container(
                        color: theme.dividerColor.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.category_outlined,
                          size: 22,
                          color: Colors.grey,
                        ),
                      ),
                      fit: BoxFit.cover,
                      cacheKey: category.path?.replaceAll(' ', ''),
                      useOldImageOnUrlChange: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.nama ?? '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
