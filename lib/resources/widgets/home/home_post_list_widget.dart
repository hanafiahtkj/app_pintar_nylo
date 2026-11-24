import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/post.dart';
import '/app/networking/pintar_api_service.dart';
import '/app/services/service_launcher_service.dart';

class HomePostListWidget extends StatefulWidget {
  final bool isScrollEnabled;

  const HomePostListWidget({super.key, this.isScrollEnabled = true});

  @override
  State<HomePostListWidget> createState() => _HomePostListWidgetState();
}

class _HomePostListWidgetState extends NyState<HomePostListWidget> {
  static const int _initialLimit = 6;
  List<Post> _allPosts = [];
  List<Post> _visiblePosts = [];
  bool _hasMorePosts = true;
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        if (widget.isScrollEnabled) {
          _scrollController.addListener(_onScroll);
        }
        _fetchPosts();
      };

  @override
  void dispose() {
    if (widget.isScrollEnabled) {
      _scrollController.removeListener(_onScroll);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
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
        showToastDanger(title: 'Error', description: e.toString());
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

  @override
  Widget view(BuildContext context) {
    if (_loading) {
      return Skeletonizer(
        enabled: _loading,
        child: _buildSkeletonList(),
      );
    }

    return _visiblePosts.isNotEmpty
        ? _buildHorizontalPostList(context)
        : const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Belum ada berita tersedia'),
            ),
          );
  }

  Widget _buildSkeletonList() {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) => Container(
          width: 280,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalPostList(BuildContext context) {
    int itemCount = _visiblePosts.length;
    if (_hasMorePosts && widget.isScrollEnabled) {
      itemCount++;
    }

    return SizedBox(
      height: 255,
      child: ListView.builder(
        controller: widget.isScrollEnabled ? _scrollController : null,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == _visiblePosts.length) {
            return const SizedBox(
              width: 80,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildListItem(context, _visiblePosts[index]);
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Post post) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardWidth = (MediaQuery.sizeOf(context).width * 0.78).clamp(240.0, 280.0);

    return GestureDetector(
      onTap: () => ServiceLauncherService.openNews(context, post.url),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
                child: CachedNetworkImage(
                  imageUrl: post.image_url ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      post.title ?? 'No title',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.published ?? '',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
