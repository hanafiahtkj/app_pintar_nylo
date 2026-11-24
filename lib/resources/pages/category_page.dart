import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/widgets/app/app_list_widget.dart';
import '/resources/widgets/category/category_list_widget.dart';

class CategoryPage extends NyStatefulWidget {
  static RouteView path = ('/category', (_) => CategoryPage());

  CategoryPage({super.key}) : super(child: () => _CategoryPageState());
}

class _CategoryPageState extends NyPage<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? searchQuery;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        _searchController.addListener(_onSearchChanged);
        final rawData = data();
        final arguments = rawData is Map ? rawData : null;
        if (arguments != null) {
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
    final accentColor =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final unselectedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    return DefaultTabController(
      length: 2,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: PopScope(
          onPopInvokedWithResult: (didPop, _) {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            appBar: _buildAppBar(context, accentColor: accentColor),
            body: Column(
              children: [
                Container(
                  color: theme.scaffoldBackgroundColor,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: TabBar(
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
                          dividerColor: theme.dividerColor.withValues(
                            alpha: isDark ? 0.14 : 0.08,
                          ),
                          dividerHeight: 0.7,
                          tabs: const [
                            Tab(child: Text('Semua')),
                            Tab(child: Text('Kategori')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: theme.scaffoldBackgroundColor,
                    child: TabBarView(
                      children: [
                        _KeepAliveTab(
                          child: _buildTabContent(
                            'pelayanan_publik_tab',
                            AppListWidget(idKategori: null, search: searchQuery),
                          ),
                        ),
                        _KeepAliveTab(
                          child: _buildTabContent(
                            'kategori_tab',
                            CategoryListWidget(search: searchQuery),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String key, Widget child) {
    return SafeArea(
      top: false,
      bottom: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final isWide = constraints.maxWidth >= 768;
          return CustomScrollView(
            key: PageStorageKey<String>(key),
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
                      child: child,
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: isDark
                    ? Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A)
                        .withValues(alpha: isDark ? 0.22 : 0.065),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari layanan di sini...',
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
                  suffixIcon: searchQuery != null && searchQuery!.isNotEmpty
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
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: accentColor.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  filled: false,
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

class _KeepAliveTab extends StatefulWidget {
  final Widget child;

  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
