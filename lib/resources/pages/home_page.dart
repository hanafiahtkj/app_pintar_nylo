import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '/app/controllers/home_controller.dart';
import '/app/events/login_success_event.dart';
import '/app/events/logout_event.dart';
import '/app/events/notification_refresh_event.dart';
import '/app/models/banner_item.dart';
import '/app/models/notification_item.dart';
import '/app/models/polling.dart';
import '/app/models/urgent_notification.dart';
import '/app/networking/pintar_api_service.dart';
import '/app/services/auth_service.dart';
import '/app/services/chrome_safari_browser_service.dart';
import '/app/services/notification_read_service.dart';
import '/config/app.dart';
import '/config/storage_keys.dart';
import '/resources/pages/category_page.dart';
import '/resources/pages/emergency_page.dart';
import '/resources/pages/login_page.dart';
import '/resources/pages/lowongan_page.dart';
import '/resources/pages/notification_detail_page.dart';
import '/resources/pages/notification_page.dart';
import '/resources/pages/post_page.dart';
import '/resources/widgets/home/home_app_grid_widget.dart';
import '/resources/widgets/home/home_lowongan_list_widget.dart';
import '/resources/widgets/home/home_post_list_widget.dart';
import '/resources/widgets/profile/profile_body_widget.dart';

class HomePage extends NyStatefulWidget<HomeController> {
  static RouteView path = ('/home', (_) => HomePage());

  HomePage({super.key}) : super(child: () => _HomePageState());
}

class _HomePageState extends NyPage<HomePage> {
  final InAppReview _inAppReview = InAppReview.instance;

  int _page = 0;
  int _notificationUnread = 0;
  int _launchCount = 0;
  static const int _minLaunchesForReview = 3;
  String _appVersion = '';
  bool _pendingProfile = false;
  bool _appleLoginActive = false;
  int _currentBannerIndex = 0;
  bool _hasVisitedNotification = false;
  bool _hasVisitedProfile = false;

  String? _hotline;
  Polling? _polling;
  List<BannerItem> _banners = [];
  List<UrgentNotification> _urgentNotifications = [];

  @override
  bool get stateManaged => true;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  get init => () async {
    listen<NotificationRefreshEvent>((_) {
      _loadNotificationUnreadCount();
    });

    listen<LoginSuccessEvent>((_) {
      if (mounted) {
        setState(() {
          if (_pendingProfile) {
            _pendingProfile = false;
            _hasVisitedProfile = true;
            _page = 3;
          }
        });
      }
    });

    listen<LogoutEvent>((_) {
      if (mounted) {
        setState(() {});
      }
    });

    _loadAppVersion();
    _loadNotificationUnreadCount();
    _loadAppleLoginStatus();
    _trackLaunchCount();
    _loadHomeData();
  };

  Future<void> _loadHomeData() async {
    Future<void> fetchHotline() async {
      try {
        final res = await api<PintarApiService>((r) => r.getHotline());
        if (mounted) setState(() => _hotline = res?.text);
      } catch (_) {}
    }

    Future<void> fetchPolling() async {
      try {
        final res = await api<PintarApiService>((r) => r.getPolling());
        if (mounted) setState(() => _polling = res);
      } catch (_) {}
    }

    Future<void> fetchBanners() async {
      try {
        final res = await api<PintarApiService>((r) => r.getBanners());
        if (mounted && res != null) setState(() => _banners = res);
      } catch (_) {}
    }

    Future<void> fetchUrgent() async {
      try {
        final res = await api<PintarApiService>(
          (r) => r.getUrgentNotifications(),
        );
        if (mounted && res != null) setState(() => _urgentNotifications = res);
      } catch (_) {}
    }

    await Future.wait([
      fetchHotline(),
      fetchPolling(),
      fetchBanners(),
      fetchUrgent(),
    ]);
  }

  Future<void> _loadNotificationUnreadCount() async {
    try {
      final readIds = await NotificationReadService().getReadNotificationIds();
      final result = await api<PintarApiService>(
        (r) => r.getNotifications(page: 1, perPage: 10),
      );
      if (result != null && mounted) {
        final unread = result.notifications
            .where((n) => !readIds.contains(n.id) && !n.isRead)
            .length;
        setState(() => _notificationUnread = unread);
      }
    } catch (_) {}
  }

  Future<void> _trackLaunchCount() async {
    final current =
        await StorageKeysConfig.launchCount.read<int>(defaultValue: 0) ?? 0;
    _launchCount = current + 1;
    await StorageKeysConfig.launchCount.save(_launchCount, inBackpack: true);
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _loadAppleLoginStatus() async {
    try {
      final active = await api<PintarApiService>(
        (r) => r.getAppleLoginStatus(),
      );
      if (mounted) setState(() => _appleLoginActive = active ?? false);
    } catch (_) {
      if (mounted) setState(() => _appleLoginActive = Platform.isIOS);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && mounted) {
      if (Platform.isIOS && _launchCount < _minLaunchesForReview) {
        return;
      }

      if (AuthService().isLoggedIn &&
          AuthService().currentUser?.isPolling == 0) {
        _showRatingDialog(context);
      } else {
        _triggerInAppReviewNative();
      }
    }
  }

  Future<void> _refreshPage() async {
    if (mounted) {
      setState(() {
        _page = 0;
      });
    }
    updateState(HomeAppGridWidget.state);
    await Future.wait([_loadHomeData(), _loadNotificationUnreadCount()]);
  }

  Future<void> _triggerInAppReviewNative() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (_) {}
  }

  Future<void> _triggerInAppReviewWithExit() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (_) {
    } finally {
      await SystemNavigator.pop();
    }
  }

  void _showRatingDialog(
    BuildContext context, {
    bool isFromBackButton = false,
  }) {
    int selectedRating = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Beri Penilaian',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bagaimana pengalaman Anda menggunakan aplikasi ini?',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    RadioGroup<int>(
                      groupValue: selectedRating,
                      onChanged: (int? value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRating = value;
                          });
                        }
                      },
                      child: const Column(
                        children: [
                          ListTile(
                            title: Text('Sangat Baik'),
                            dense: true,
                            leading: Radio<int>(
                              value: 1,
                              activeColor: Colors.green,
                            ),
                          ),
                          ListTile(
                            title: Text('Baik'),
                            dense: true,
                            leading: Radio<int>(
                              value: 2,
                              activeColor: Colors.blue,
                            ),
                          ),
                          ListTile(
                            title: Text('Cukup'),
                            dense: true,
                            leading: Radio<int>(
                              value: 3,
                              activeColor: Colors.orange,
                            ),
                          ),
                          ListTile(
                            title: Text('Kurang'),
                            dense: true,
                            leading: Radio<int>(
                              value: 4,
                              activeColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isFromBackButton && !Platform.isIOS) {
                  SystemNavigator.pop();
                }
              },
              child: const Text('Nanti saja'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pageContext = this.context;
                final ok = await AuthService().submitPolling(selectedRating);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                if (ok && pageContext.mounted) {
                  _showThankYouDialog(pageContext);
                  Future.delayed(const Duration(milliseconds: 800), () {
                    _triggerInAppReviewNative();
                  });
                } else if (pageContext.mounted) {
                  showToastDanger(
                    title: 'Gagal',
                    description: 'Gagal mengirim penilaian. Silakan coba lagi.',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kirim Nilai'),
            ),
          ],
        );
      },
    );
  }

  void _showThankYouDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (
            BuildContext buildContext,
            Animation animation,
            Animation secondaryAnimation,
          ) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Material(
                  color: Colors.transparent,
                  child: _ThankYouDialogContent(),
                ),
              ),
            );
          },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.5,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeInOut)),
          child: child,
        );
      },
    );
  }

  @override
  Widget view(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        if (Platform.isIOS && _launchCount < _minLaunchesForReview) {
          await SystemNavigator.pop();
          return;
        }

        if (AuthService().isLoggedIn &&
            AuthService().currentUser?.isPolling == 0) {
          _showRatingDialog(context, isFromBackButton: true);
          return;
        }

        _triggerInAppReviewWithExit();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 768;
          final bool isDesktop = constraints.maxWidth >= 1100;

          if (isWide) {
            return Scaffold(
              body: Row(
                children: [
                  _buildSideNav(isExtended: isDesktop),
                  Expanded(child: _buildPageContent(isWide: true)),
                ],
              ),
            );
          }

          return Scaffold(
            body: _buildPageContent(isWide: false),
            bottomNavigationBar: _buildBottomNav(),
          );
        },
      ),
    );
  }

  void _selectPage(int page) {
    if (page == 2) {
      _hasVisitedNotification = true;
    } else if (page == 3) {
      if (AuthService().isLoggedIn) {
        _hasVisitedProfile = true;
      } else if (_appleLoginActive && Platform.isIOS) {
        _pendingProfile = true;
        routeTo(LoginPage.path);
        return;
      } else {
        _pendingProfile = true;
        _login();
        return;
      }
    }
    setState(() => _page = page);
  }

  int get _stackIndex {
    if (_page == 2) return 1;
    if (_page == 3) return 2;
    return 0;
  }

  Widget _buildPageContent({required bool isWide}) {
    return IndexedStack(
      index: _stackIndex,
      children: [
        RefreshIndicator(
          onRefresh: _refreshPage,
          child: _buildBody(isWide: isWide),
        ),
        _hasVisitedNotification
            ? NotificationPage(
                onCountChanged: (total, unread) {
                  if (mounted) setState(() => _notificationUnread = unread);
                },
              )
            : const SizedBox.shrink(),
        _hasVisitedProfile
            ? ProfileBodyWidget(
                initialHotline: _hotline,
                onLogout: () => setState(() => _page = 0),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildSideNav({required bool isExtended}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark
        ? const Color(0xFF6EA8FE)
        : const Color(0xFF1455D4);
    final inactiveColor = isDark
        ? Colors.grey.shade200
        : const Color(0xFF334155);
    final borderColor = theme.dividerColor.withValues(
      alpha: isDark ? 0.12 : 0.07,
    );

    return Container(
      width: isExtended ? 228 : 88,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(right: BorderSide(color: borderColor, width: 0.7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: isDark ? 0.14 : 0.025),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExtended ? 14 : 10,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: isExtended
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isExtended ? 8 : 0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: isExtended
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: theme.dividerColor.withValues(
                            alpha: isDark ? 0.14 : 0.08,
                          ),
                        ),
                      ),
                      child: Image.asset(
                        'assets/app_icon/icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (isExtended) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Banjarmasin\nPintar',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSideNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Beranda',
                isActive: _page == 0,
                isExtended: isExtended,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _selectPage(0),
              ),
              const SizedBox(height: 6),
              _buildSideNavItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                label: 'Layanan',
                isActive: false,
                isExtended: isExtended,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => routeTo(CategoryPage.path),
              ),
              const SizedBox(height: 6),
              _buildSideNavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                label: 'Notifikasi',
                isActive: _page == 2,
                isExtended: isExtended,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                badge: _notificationUnread,
                onTap: () => _selectPage(2),
              ),
              const SizedBox(height: 6),
              _buildSideNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                isActive: _page == 3,
                isExtended: isExtended,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _selectPage(3),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => routeTo(EmergencyPage.path),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isExtended ? 14 : 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.call_rounded, size: 20),
                      if (isExtended) ...[
                        const SizedBox(width: 8),
                        const Text(
                          'Darurat',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required bool isExtended,
    required Color activeColor,
    required Color inactiveColor,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isActive
          ? activeColor.withValues(alpha: 0.11)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: isExtended ? 12 : 0),
          child: Row(
            mainAxisAlignment: isExtended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? activeColor : inactiveColor,
                    size: 23,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -8,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            badge > 99 ? '99+' : '$badge',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (isExtended) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navBg = theme.cardColor;

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNavItem(
                      Icons.home_outlined,
                      Icons.home,
                      'Beranda',
                      0,
                      onTap: () => _selectPage(0),
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      Icons.grid_view_outlined,
                      Icons.grid_view_rounded,
                      'Layanan',
                      1,
                      onTap: () => routeTo(CategoryPage.path),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => routeTo(EmergencyPage.path),
                      behavior: HitTestBehavior.opaque,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Darurat',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD32F2F),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      Icons.notifications_outlined,
                      Icons.notifications,
                      'Notifikasi',
                      2,
                      badge: _notificationUnread,
                      onTap: () => _selectPage(2),
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      Icons.person_outline,
                      Icons.person,
                      'Profil',
                      3,
                      onTap: () => _selectPage(3),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -30,
                child: GestureDetector(
                  onTap: () => routeTo(EmergencyPage.path),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      border: Border.all(color: navBg, width: 4),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD32F2F,
                          ).withValues(alpha: 0.32),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int page, {
    int badge = 0,
    VoidCallback? onTap,
  }) {
    final isActive = _page == page;

    const activeColor = Color(0xFF1455D4);
    const inactiveColor = Color(0xFF9EADBD);

    return GestureDetector(
      onTap: onTap ?? (() => setState(() => _page = page)),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey<bool>(isActive),
                  color: isActive ? activeColor : inactiveColor,
                  size: isActive ? 28 : 24,
                ),
              ),
              if (badge > 0)
                Positioned(
                  right: -10,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSlider({required bool isWide}) {
    final browserLauncher = ChromeSafariBrowserLauncher();

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final double viewportFraction;
        final double bannerHeight;
        final bool enlargeCenter;

        if (availableWidth >= 960) {
          viewportFraction = 0.48;
          bannerHeight = 190.0;
          enlargeCenter = false;
        } else if (availableWidth >= 600) {
          viewportFraction = 0.62;
          bannerHeight = 180.0;
          enlargeCenter = false;
        } else {
          viewportFraction = 0.92;
          bannerHeight = (availableWidth * 0.36).clamp(132.0, 168.0);
          enlargeCenter = true;
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final activeDotColor = isDark
            ? const Color(0xFF6EA8FE)
            : const Color(0xFF1455D4);

        return Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: bannerHeight,
                autoPlay: _banners.length > 1,
                autoPlayInterval: const Duration(seconds: 10),
                autoPlayCurve: Curves.fastOutSlowIn,
                enlargeCenterPage: enlargeCenter,
                enlargeFactor: 0.16,
                viewportFraction: viewportFraction,
                padEnds: !isWide,
                onPageChanged: (index, _) {
                  if (mounted && _currentBannerIndex != index) {
                    setState(() => _currentBannerIndex = index);
                  }
                },
              ),
              items: _banners.map((banner) {
                return Builder(
                  builder: (BuildContext context) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 8.0 : 4.0,
                        vertical: 4.0,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            final url = banner.link;
                            if (url != null && url.isNotEmpty) {
                              browserLauncher.openBrowser(
                                url: url,
                                context: context,
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.25 : 0.08,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: banner.image ?? '',
                                fit: BoxFit.cover,
                                placeholder: (context, _) => Container(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.12),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.16),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            if (_banners.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (i) {
                  final active = i == _currentBannerIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? activeDotColor
                          : Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _wrapConstrained(Widget child, {required bool isWide}) {
    if (!isWide) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBody({required bool isWide}) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              Positioned.fill(bottom: 82, child: _buildBackgroundImage()),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 1120 : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32.0 : 16.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopSection(isWide: isWide),
                        const SizedBox(height: 22),
                        _buildSearchAndMainServices(isWide: isWide),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: _wrapConstrained(
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: _buildBannerSlider(isWide: isWide),
            ),
            isWide: isWide,
          ),
        ),
        SliverToBoxAdapter(
          child: _wrapConstrained(
            _buildSectionHeader(
              'Layanan Publik',
              // subtitle: 'Silakan pilih layanan yang Anda butuhkan',
              onSeeAll: () => routeTo(CategoryPage.path),
            ),
            isWide: isWide,
          ),
        ),
        SliverToBoxAdapter(
          child: _wrapConstrained(
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: HomeAppGridWidget(idKategori: 93),
            ),
            isWide: isWide,
          ),
        ),
        SliverToBoxAdapter(
          child: _wrapConstrained(
            _buildSectionNotifikasiPenting(),
            isWide: isWide,
          ),
        ),
        SliverToBoxAdapter(
          child: _wrapConstrained(
            _buildSectionHeader(
              'Lowongan Terbaru',
              onSeeAll: () => routeTo(LowonganPage.path),
            ),
            isWide: isWide,
          ),
        ),
        SliverToBoxAdapter(
          child: _wrapConstrained(
            const HomeLowonganListWidget(isScrollEnabled: false),
            isWide: isWide,
          ),
        ),
        SliverToBoxAdapter(
          child: _wrapConstrained(
            _buildSectionHeader(
              'Berita Terbaru',
              onSeeAll: () => routeTo(PostPage.path),
            ),
            isWide: isWide,
          ),
        ),
        SliverToBoxAdapter(
          child: _wrapConstrained(
            const HomePostListWidget(isScrollEnabled: false),
            isWide: isWide,
          ),
        ),
        SliverToBoxAdapter(
          child: _wrapConstrained(
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: _buildSurveyResults(isWide: isWide),
            ),
            isWide: isWide,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: isWide ? 36 : 56)),
      ],
    );
  }

  Widget _buildSurveyResults({required bool isWide}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = [
      ('Sangat Baik', _polling?.sangatbaik, const Color(0xFF16A34A)),
      ('Baik', _polling?.baik, const Color(0xFF0284C7)),
      ('Cukup', _polling?.cukup, const Color(0xFFD97706)),
      ('Kurang', _polling?.kurang, const Color(0xFFDC2626)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hasil Survey Kepuasan Masyarakat',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (isWide)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSurveyItem(
                        items[0].$1,
                        items[0].$2,
                        items[0].$3,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildSurveyItem(
                        items[1].$1,
                        items[1].$2,
                        items[1].$3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildSurveyItem(
                        items[2].$1,
                        items[2].$2,
                        items[2].$3,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildSurveyItem(
                        items[3].$1,
                        items[3].$2,
                        items[3].$3,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _buildSurveyItem(items[i].$1, items[i].$2, items[i].$3),
                  if (i < items.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSurveyItem(String label, double? percentage, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clamped = (percentage ?? 0.0).clamp(0.0, 1.0);
    final percentText = '${(clamped * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              percentText,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            width: double.infinity,
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFE9EEF5),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: clamped,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BG.png'),
            alignment: Alignment.bottomRight,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection({required bool isWide}) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topInset + (isWide ? 16 : 24)),
        Text(
          'Selamat datang,',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Aplikasi Banjarmasin Pintar',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isWide ? 24 : 20,
          ),
        ),
        const SizedBox(height: 14),
        _buildLoginOrLogoutButton(),
      ],
    );
  }

  Widget _buildLoginOrLogoutButton() {
    if (AuthService().isLoggedIn) {
      final user = AuthService().currentUser;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user?.name ?? 'Unknown',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user?.nationalIdNumber ?? 'Unknown',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      return const SizedBox(height: 41);
    }
  }

  void _login() {
    final browserLauncher = ChromeSafariBrowserLauncher();

    browserLauncher.onBrowserClosed = () {
      if (!AuthService().isLoggedIn) {
        _pendingProfile = false;
      }
    };

    browserLauncher.openBrowser(url: AppConfig.ssoRegisUrl, context: context);
  }

  Widget _buildSearchAndMainServices({required bool isWide}) {
    final browserLauncher = ChromeSafariBrowserLauncher();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 8.0),
            child: Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              elevation: isDark ? 0 : 2,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  routeTo(CategoryPage.path, data: {'focusSearch': true});
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(
                        alpha: isDark ? 0.25 : 0.12,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: isDark
                            ? Colors.grey.shade400
                            : const Color(0xFF64748B),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Telusuri layanan...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF64748B),
                            fontSize: 14.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 520 : double.infinity),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 0 : 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMainServiceItem(
                  icon: Icons.call_rounded,
                  label: 'Darurat',
                  color: const Color(0xFFDC2626),
                  onTap: () => routeTo(EmergencyPage.path),
                ),
                _buildMainServiceItem(
                  icon: Icons.campaign_rounded,
                  label: 'Lapor',
                  color: const Color(0xFF1455D4),
                  onTap: () {
                    if (Platform.isIOS) {
                      _launchUrl(AppConfig.laporIosUrl);
                    } else if (Platform.isAndroid) {
                      browserLauncher.openBrowser(
                        url: AppConfig.laporAndroidUrl,
                        context: context,
                      );
                    }
                  },
                ),
                _buildMainServiceItem(
                  icon: Icons.newspaper_rounded,
                  label: 'Berita',
                  color: const Color(0xFF0F766E),
                  onTap: () => routeTo(PostPage.path),
                ),
                _buildMainServiceItem(
                  icon: Icons.headset_mic_rounded,
                  label: 'Bantuan',
                  color: const Color(0xFFD97706),
                  onTap: () => _showInfoDialog(context),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMainServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required Function() onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(icon, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          'Bantuan',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aplikasi Banjarmasin Pintar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi $_appVersion',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Untuk pertanyaan atau kendala layanan, silakan hubungi hotline resmi kami.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _openWhatsApp,
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                      label: const Text(
                        'Hubungi via WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openWhatsApp() async {
    if (_hotline == null || _hotline!.isEmpty) {
      final res = await api<PintarApiService>((r) => r.getHotline());
      if (mounted) _hotline = res?.text;
    }
    if (_hotline == null || _hotline!.isEmpty) return;

    final Uri whatsappUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: _hotline,
      queryParameters: {'text': ''},
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    }
  }

  Widget _buildSectionHeader(
    String title, {
    String? subtitle,
    VoidCallback? onSeeAll,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actionColor = isDark
        ? const Color(0xFF6EA8FE)
        : const Color(0xFF1455D4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 22.0, 12.0, 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    foregroundColor: actionColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: const Size(44, 36),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: actionColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: actionColor,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionNotifikasiPenting() {
    final items = _urgentNotifications;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Notifikasi Penting',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;

              if (isWide) {
                final cols = items.length == 1
                    ? 1
                    : (constraints.maxWidth >= 980 && items.length >= 3
                          ? 3
                          : 2);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 142,
                    ),
                    itemBuilder: (context, index) =>
                        _buildUrgentNotificationCard(context, items[index]),
                  ),
                );
              }

              final cardWidth = (constraints.maxWidth * 0.82).clamp(
                272.0,
                320.0,
              );
              return SizedBox(
                height: 148,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: cardWidth,
                    child: _buildUrgentNotificationCard(context, items[index]),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentNotificationCard(
    BuildContext context,
    UrgentNotification item,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    var hex = item.color.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
    final Color accentColor = parsed != null
        ? Color(parsed)
        : const Color(0xFF1455D4);

    final hsl = HSLColor.fromColor(accentColor);
    final Color readableAccent = isDark
        ? hsl.withLightness(hsl.lightness.clamp(0.62, 0.78)).toColor()
        : hsl.withLightness(hsl.lightness.clamp(0.28, 0.42)).toColor();

    final Color surfaceColor = Color.alphaBlend(
      accentColor.withValues(alpha: isDark ? 0.14 : 0.055),
      isDark ? theme.cardColor : Colors.white,
    );
    final Color mutedColor = isDark
        ? Colors.grey.shade400
        : const Color(0xFF64748B);
    final Color descColor = isDark
        ? Colors.grey.shade300
        : const Color(0xFF475569);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: accentColor.withValues(alpha: 0.24))
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF0F172A,
            ).withValues(alpha: isDark ? 0.2 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
              NotificationDetailPage.path,
              data: NotificationItem(
                id: item.id ?? 0,
                title: item.title,
                desc: item.desc,
                color: item.color,
                createdAt: '',
                time: item.time,
                isRead: false,
                isUrgent: true,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.campaign_rounded,
                            size: 13,
                            color: readableAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pengumuman',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: readableAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title.trim(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.28,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    item.desc.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: descColor,
                      height: 1.38,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }
}

class _ThankYouDialogContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Terima Kasih!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Terima kasih telah memberikan penilaian Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 20),
          if (!Platform.isIOS)
            ElevatedButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tutup Aplikasi'),
            ),
        ],
      ),
    );
  }
}
