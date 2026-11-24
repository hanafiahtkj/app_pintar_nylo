import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/widgets/app/app_list_widget.dart';

class AppPage extends NyStatefulWidget {
  static RouteView path = ('/app', (_) => AppPage());

  AppPage({super.key}) : super(child: () => _AppPageState());
}

class _AppPageState extends NyPage<AppPage> {
  int? idKategori;
  String? categoryName;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String searchQuery = '';

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        _searchController.addListener(_onSearchChanged);
        final rawData = data();
        final arguments = rawData is Map ? rawData : null;
        if (arguments != null) {
          idKategori = arguments['id'] as int?;
          categoryName = arguments['name'] as String?;

          final focusSearch = arguments['focusSearch'] as bool? ?? false;
          if (focusSearch) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                FocusScope.of(context).requestFocus(_searchFocusNode);
              }
            });
          }
        }
      };

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
    });
  }

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        onPopInvokedWithResult: (didPop, _) {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor:
              isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF6F8FB),
          appBar: _buildAppBar(context),
          body: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 24.0 : 12.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (categoryName != null &&
                            categoryName!.trim().isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 4.0,
                              top: 4.0,
                              bottom: 12.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryName!,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Daftar layanan yang tersedia dalam kategori ini',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        AppListWidget(
                          idKategori: idKategori,
                          search: searchQuery,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);

    return AppBar(
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: categoryName?.isNotEmpty == true
                      ? 'Cari di $categoryName...'
                      : 'Cari layanan...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.grey.shade400
                        : const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () => _searchController.clear(),
                          icon: Icon(
                            Icons.cancel_rounded,
                            color: theme.hintColor.withValues(alpha: 0.65),
                            size: 20,
                          ),
                          tooltip: 'Hapus pencarian',
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(
                        alpha: isDark ? 0.25 : 0.14,
                      ),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(
                        alpha: isDark ? 0.25 : 0.14,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accentColor, width: 1.4),
                  ),
                  filled: true,
                  fillColor: isDark ? theme.cardColor : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
