import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/post.dart';
import '/app/networking/pintar_api_service.dart';
import '/app/services/service_launcher_service.dart';

class PostPage extends NyStatefulWidget {
  static RouteView path = ('/post', (_) => PostPage());

  PostPage({super.key}) : super(child: () => _PostPageState());
}

class _PostPageState extends NyPage<PostPage> {
  static const int _initialLimit = 9;
  List<Post> _allPosts = [];
  List<Post> _visiblePosts = [];
  bool _hasMorePosts = true;
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        _scrollController.addListener(_onScroll);
        _fetchPosts();
      };

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _fetchPosts() async {
    if (mounted && !_loading) {
      setState(() => _loading = true);
    }
    try {
      final result =
          await api<PintarApiService>((request) => request.getPosts());
      if (mounted) {
        setState(() {
          _allPosts = result ?? [];
          _visiblePosts = _allPosts.take(_initialLimit).toList();
          _hasMorePosts = _allPosts.length > _visiblePosts.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showToastDanger(
          title: 'Gagal Memuat',
          description: 'Tidak dapat memuat daftar berita. Silakan coba lagi.',
        );
      }
    }
  }

  void _loadMorePosts() {
    if (_hasMorePosts) {
      final nextItems =
          _allPosts.skip(_visiblePosts.length).take(_initialLimit).toList();
      setState(() {
        _visiblePosts.addAll(nextItems);
        _hasMorePosts = _allPosts.length > _visiblePosts.length;
      });
    }
  }

  int _resolveColumns(double maxWidth) {
    if (maxWidth >= 980) return 3;
    if (maxWidth >= 620) return 2;
    return 1;
  }

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text(
          'Berita',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: _buildBody(context, isDark),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final horizontalPad = isWide ? 24.0 : 16.0;

    if (_loading) {
      return Skeletonizer(
        enabled: true,
        child: _buildSkeletonGrid(context, horizontalPad, isDark),
      );
    }

    if (_visiblePosts.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return RefreshIndicator(
      onRefresh: _fetchPosts,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _resolveColumns(constraints.maxWidth);
                final gap = columns > 1 ? 16.0 : 14.0;
                final itemWidth =
                    (constraints.maxWidth - (gap * (columns - 1))) / columns;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: _visiblePosts
                          .map(
                            (post) => SizedBox(
                              width: itemWidth,
                              child: _buildListItem(context, post, isDark),
                            ),
                          )
                          .toList(),
                    ),
                    if (_hasMorePosts) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _loadMorePosts,
                          icon: const Icon(Icons.expand_more_rounded, size: 18),
                          label: const Text('Muat Lebih Banyak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? const Color(0xFF6EA8FE)
                                : const Color(0xFF1455D4),
                            side: BorderSide(
                              color: (isDark
                                      ? const Color(0xFF6EA8FE)
                                      : const Color(0xFF1455D4))
                                  .withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: mutedColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada berita tersedia',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tarik ke bawah atau tekan tombol di bawah untuk memuat ulang.',
              style: TextStyle(fontSize: 13, color: mutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetchPosts,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Muat Ulang'),
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF6EA8FE)
                    : const Color(0xFF1455D4),
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid(
    BuildContext context,
    double horizontalPad,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final surfacePlaceholder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = _resolveColumns(constraints.maxWidth);
              final gap = columns > 1 ? 16.0 : 14.0;
              final itemWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: List.generate(
                  6,
                  (_) => Container(
                    width: itemWidth,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.dividerColor
                            .withValues(alpha: isDark ? 0.22 : 0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(color: surfacePlaceholder),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Judul berita pemerintah kota Banjarmasin hari ini',
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '2 hari yang lalu',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Post post, bool isDark) {
    final theme = Theme.of(context);
    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final placeholderBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F5F9);
    final title = (post.title ?? '').trim();
    final published = (post.published ?? '').trim();

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ServiceLauncherService.openNews(context, post.url),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: post.image_url ?? '',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: placeholderBg,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: mutedColor.withValues(alpha: 0.5),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: placeholderBg,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 34,
                      color: mutedColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 42),
                      child: Text(
                        title.isNotEmpty ? title : 'Tanpa judul',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (published.isNotEmpty) ...[
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: mutedColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              published,
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Baca',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: accentBlue,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: accentBlue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
