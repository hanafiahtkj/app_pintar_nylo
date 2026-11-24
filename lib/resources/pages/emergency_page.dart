import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:url_launcher/url_launcher.dart';
import '/app/models/emergency_category.dart';
import '/app/models/emergency_item.dart';
import '/app/networking/pintar_api_service.dart';

class EmergencyPage extends NyStatefulWidget {
  static RouteView path = ('/emergency', (_) => EmergencyPage());

  EmergencyPage({super.key}) : super(child: () => _EmergencyPageState());
}

class _EmergencyPageState extends NyPage<EmergencyPage> {
  List<EmergencyCategory> _categories = [];
  bool _loading = true;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        _fetchEmergencies();
      };

  Future<void> _fetchEmergencies() async {
    if (mounted && !_loading) {
      setState(() => _loading = true);
    }
    try {
      final result =
          await api<PintarApiService>((request) => request.getEmergencies());
      if (mounted) {
        setState(() {
          _categories = result ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showToastDanger(
          title: 'Gagal Memuat',
          description: 'Tidak dapat memuat nomor darurat. Silakan coba lagi.',
        );
      }
    }
  }

  void _makeCall(String number) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: number.replaceAll(' ', ''),
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat melakukan panggilan ke $number')),
      );
    }
  }

  int _resolveColumns(double maxWidth) {
    if (maxWidth >= 980) return 3;
    if (maxWidth >= 620) return 2;
    return 1;
  }

  Color _parseColor(String rawHex) {
    var cleanHex = rawHex.replaceAll('#', '').trim();
    if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
    final parsed = int.tryParse(cleanHex, radix: 16);
    return parsed != null ? Color(parsed) : const Color(0xFF9E9E9E);
  }

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final unselectedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            'Panggilan Darurat',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Skeletonizer(
          enabled: true,
          child: _buildSkeleton(),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            'Panggilan Darurat',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_disabled_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tidak ada data darurat',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _fetchEmergencies,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            'Panggilan Darurat',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TabBar(
                      dividerColor: theme.dividerColor.withValues(
                        alpha: isDark ? 0.14 : 0.08,
                      ),
                      dividerHeight: 0.7,
                      indicatorColor: accentColor,
                      labelColor: accentColor,
                      unselectedLabelColor: unselectedColor,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      indicator: UnderlineTabIndicator(
                        borderRadius: BorderRadius.circular(2),
                        borderSide: BorderSide(
                          width: 2.5,
                          color: accentColor,
                        ),
                        insets: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      tabs: _categories
                          .map((c) => Tab(child: Text(c.categoryName)))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: _categories.map((category) {
                  return _buildListView(category.items);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final contentWidth =
            (constraints.maxWidth - (isWide ? 48 : 24)).clamp(0.0, 1120.0);
        final cols = _resolveColumns(contentWidth);
        const spacing = 12.0;
        final itemWidth = cols == 1
            ? contentWidth
            : (contentWidth - spacing * (cols - 1)) / cols;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 24 : 12,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(
                  cols * 3,
                  (_) => Container(
                    width: itemWidth,
                    height: 88,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Bone.circle(size: 46),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Bone.text(words: 2),
                              const SizedBox(height: 6),
                              Bone.text(words: 3),
                            ],
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
      },
    );
  }

  Widget _buildListView(List<EmergencyItem> items) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _fetchEmergencies,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = _resolveColumns(constraints.maxWidth);
          final isWide = cols > 1;

          if (!isWide) {
            final dividerColor = theme.dividerColor.withValues(
              alpha: isDark ? 0.18 : 0.12,
            );
            return ColoredBox(
              color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.8,
                  color: dividerColor,
                ),
                itemBuilder: (context, index) {
                  return _buildMobileRow(items[index]);
                },
              ),
            );
          }

          return ColoredBox(
            color:
                isDark ? theme.scaffoldBackgroundColor : const Color(0xFFFAFBFE),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                        child: LayoutBuilder(
                          builder: (context, innerConstraints) {
                            final gridCols =
                                _resolveColumns(innerConstraints.maxWidth);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCols,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                mainAxisExtent: 112,
                              ),
                              itemBuilder: (context, index) {
                                return _buildSoftCard(items[index]);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileRow(EmergencyItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      child: InkWell(
        onTap: () => _makeCall(item.number),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 102),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: _buildItemContent(item),
          ),
        ),
      ),
    );
  }

  Widget _buildSoftCard(EmergencyItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: theme.dividerColor.withValues(alpha: 0.16))
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: isDark ? 0.22 : 0.045),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _makeCall(item.number),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: _buildItemContent(item),
          ),
        ),
      ),
    );
  }

  Widget _buildItemContent(EmergencyItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color itemColor = _parseColor(item.color);

    // ignore: non_const_argument_for_const_parameter
    final IconData itemIcon = IconData(
      // ignore: non_const_argument_for_const_parameter
      item.icon,
      // ignore: non_const_argument_for_const_parameter
      fontFamily:
          item.fontFamily.isNotEmpty ? item.fontFamily : 'MaterialIcons',
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: itemColor.withValues(alpha: 0.12),
          child: Icon(
            itemIcon,
            color: itemColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.number,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFDC2626),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.description.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    color: isDark
                        ? Colors.grey.shade400
                        : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A)
                .withValues(alpha: isDark ? 0.2 : 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.call_rounded,
            color: Color(0xFF16A34A),
            size: 20,
          ),
        ),
      ],
    );
  }
}
