import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/events/notification_refresh_event.dart';
import '/app/models/notification_item.dart';
import '/app/networking/pintar_api_service.dart';
import '/app/providers/firebase_messaging_provider.dart';
import '/app/services/notification_read_service.dart';
import '/resources/pages/notification_detail_page.dart';

class NotificationPage extends NyStatefulWidget {
  static RouteView path = ('/notification', (_) => NotificationPage());

  final void Function(int total, int unread)? onCountChanged;

  NotificationPage({super.key, this.onCountChanged})
      : super(child: () => _NotificationPageState());
}

class _NotificationPageState extends NyPage<NotificationPage> {
  final GlobalKey<_NotificationListWidgetState> _listKey =
      GlobalKey<_NotificationListWidgetState>();
  int _total = 0;
  int _unread = 0;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () {
        FirebaseMessagingService().ensurePermission();
      };

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: _buildAppBar(context, theme, isDark),
      body: NotificationListWidget(
        key: _listKey,
        onCountChanged: (total, unread) {
          if (_total != total || _unread != unread) {
            setState(() {
              _total = total;
              _unread = unread;
            });
            widget.onCountChanged?.call(total, unread);
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final subtitleText = _total > 0
        ? (_unread > 0
            ? '$_unread belum dibaca dari $_total'
            : 'Semua notifikasi sudah dibaca')
        : null;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: theme.scaffoldBackgroundColor,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Notifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (subtitleText != null)
            Text(
              subtitleText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: mutedColor,
              ),
            ),
        ],
      ),
      actions: [
        if (_unread > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _listKey.currentState?.markAllAsRead(),
              icon: Icon(
                Icons.done_all_rounded,
                size: 16,
                color: accentBlue,
              ),
              label: Text(
                'Tandai dibaca',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: accentBlue,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationListWidget extends StatefulWidget {
  static String state = 'notification_list';
  final bool isScrollEnabled;
  final void Function(int total, int unread)? onCountChanged;

  const NotificationListWidget({
    super.key,
    this.isScrollEnabled = true,
    this.onCountChanged,
  });

  @override
  State<NotificationListWidget> createState() => _NotificationListWidgetState();
}

class _NotificationListWidgetState extends NyState<NotificationListWidget> {
  List<NotificationItem> _notifications = [];
  Set<int> _readIds = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  final ScrollController _scrollController = ScrollController();

  _NotificationListWidgetState() {
    stateName = NotificationListWidget.state;
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () async {
        _readIds = await NotificationReadService().getReadNotificationIds();
        if (widget.isScrollEnabled) {
          _scrollController.addListener(_onScroll);
        }
        listen<NotificationRefreshEvent>((_) {
          _loadNotifications();
        });
        _loadNotifications();
      };

  @override
  void dispose() {
    if (widget.isScrollEnabled) {
      _scrollController.removeListener(_onScroll);
    }
    _scrollController.dispose();
    super.dispose();
  }

  int get _totalCount => _notifications.length;
  int get _unreadCount => _notifications.where((n) => !_isRead(n)).length;

  bool _isRead(NotificationItem item) {
    return _readIds.contains(item.id) || item.isRead;
  }

  void _notifyCountChanged() {
    widget.onCountChanged?.call(_totalCount, _unreadCount);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    if (mounted && !_isLoading) setState(() => _isLoading = true);
    try {
      final result = await api<PintarApiService>(
        (request) => request.getNotifications(page: 1, perPage: 10),
      );
      if (mounted && result != null) {
        setState(() {
          _notifications = result.notifications;
          _currentPage = result.currentPage;
          _lastPage = result.lastPage;
          _isLoading = false;
        });
        _notifyCountChanged();
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await api<PintarApiService>(
        (request) =>
            request.getNotifications(page: _currentPage + 1, perPage: 10),
      );
      if (mounted && result != null) {
        setState(() {
          _notifications.addAll(result.notifications);
          _currentPage = result.currentPage;
          _lastPage = result.lastPage;
          _isLoadingMore = false;
        });
        _notifyCountChanged();
      } else if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _markAsRead(NotificationItem item) async {
    if (!_isRead(item)) {
      if (mounted) {
        setState(() => _readIds.add(item.id));
        _notifyCountChanged();
      }
      await NotificationReadService().markNotificationRead(item.id);
      if (widget.onCountChanged == null) {
        await event<NotificationRefreshEvent>(broadcast: true);
      }
    }
  }

  Future<void> markAllAsRead() async {
    final unreadItems = _notifications.where((n) => !_isRead(n)).toList();
    if (unreadItems.isEmpty) return;

    if (mounted) {
      setState(() {
        for (final item in unreadItems) {
          _readIds.add(item.id);
        }
      });
      _notifyCountChanged();
    }

    for (final item in unreadItems) {
      await NotificationReadService().markNotificationRead(item.id);
    }
    if (widget.onCountChanged == null) {
      await event<NotificationRefreshEvent>(broadcast: true);
    }
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
    return parsed != null ? Color(parsed) : const Color(0xFF1455D4);
  }

  @override
  Widget view(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 768;
    final horizontalPad = isWide ? 24.0 : 16.0;
    final bottomPad = isWide ? 28.0 : 96.0;

    if (_isLoading) {
      return Skeletonizer(
        enabled: true,
        child: _buildSkeletonList(context, horizontalPad, isDark),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: _buildEmptyState(context, isDark),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(horizontalPad, 10, horizontalPad, bottomPad),
        physics: widget.isScrollEnabled
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: _buildNotificationItem(
                context,
                _notifications[index],
                isDark,
              ),
            ),
          );
        },
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
              Icons.notifications_none_rounded,
              size: 48,
              color: mutedColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada notifikasi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Informasi dan pengumuman penting dari Pemerintah Kota Banjarmasin akan muncul di sini.',
              style: TextStyle(fontSize: 13, color: mutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadNotifications,
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

  Widget _buildSkeletonList(
    BuildContext context,
    double horizontalPad,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final borderColor =
        theme.dividerColor.withValues(alpha: isDark ? 0.22 : 0.14);

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(horizontalPad, 10, horizontalPad, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 22),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INFORMASI PUBLIK', style: TextStyle(fontSize: 11)),
                      SizedBox(height: 6),
                      Text(
                        'Judul notifikasi informasi layanan publik',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Deskripsi singkat mengenai pengumuman layanan publik Banjarmasin.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationItem item,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final color = _parseColor(item.color);
    final isRead = _isRead(item);
    final accentBlue =
        isDark ? const Color(0xFF6EA8FE) : const Color(0xFF1455D4);
    final mutedColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final titleColor =
        theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    final descColor =
        isDark ? Colors.grey.shade300 : const Color(0xFF475569);

    final cardBg = isRead
        ? theme.cardColor
        : Color.alphaBlend(
            accentBlue.withValues(alpha: isDark ? 0.12 : 0.045),
            theme.cardColor,
          );
    final cardBorder = isRead
        ? theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.14)
        : accentBlue.withValues(alpha: isDark ? 0.35 : 0.24);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _markAsRead(item);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificationDetailPage(item: item),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: color.withValues(alpha: isDark ? 0.2 : 0.12),
                      child: Icon(
                        item.isUrgent
                            ? Icons.campaign_rounded
                            : Icons.notifications_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                    if (!isRead)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: accentBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cardBg,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.sourceApp != null &&
                              item.sourceApp!.trim().isNotEmpty)
                            Expanded(
                              child: Text(
                                item.sourceApp!.trim().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: mutedColor,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            const Spacer(),
                          const SizedBox(width: 8),
                          Text(
                            item.time,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: mutedColor,
                              fontWeight:
                                  isRead ? FontWeight.w400 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.title.trim(),
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                          fontSize: 15,
                          color: titleColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.desc.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          color: descColor,
                          height: 1.38,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
