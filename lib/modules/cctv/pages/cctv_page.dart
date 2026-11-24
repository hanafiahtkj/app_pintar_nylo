import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/layanan_app.dart';
import '/modules/cctv/controllers/cctv_controller.dart';
import '/modules/cctv/models/cctv_camera_group.dart';
import '/modules/cctv/pages/cctv_fullscreen_map_page.dart';
import '/modules/cctv/widgets/cctv_filter_bar.dart';
import '/modules/cctv/widgets/cctv_group_picker_sheet.dart';
import '/modules/cctv/widgets/cctv_loading_view.dart';
import '/modules/cctv/widgets/cctv_map_view.dart';
import '/modules/cctv/widgets/cctv_player_stage.dart';
import '/modules/cctv/widgets/cctv_telemetry_card.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

class CctvPage extends NyStatefulWidget {
  static RouteView path = ('/modules/cctv', (_) => CctvPage());

  final CctvController? cctvController;

  CctvPage({super.key, this.cctvController})
      : super(child: () => _CctvPageState());
}

class _CctvPageState extends NyPage<CctvPage> with WidgetsBindingObserver {
  LayananApp? _app;
  late final CctvController _controller;
  late final bool _ownsController;
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _distributionSectionKey = GlobalKey();
  bool _isFullscreenMapOpen = false;
  bool _isSearching = false;

  @override
  LoadingStyle get loadingStyle => LoadingStyle.none();

  @override
  void initState() {
    _ownsController = widget.cctvController == null;
    _controller = widget.cctvController ?? CctvController();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  get init => () {
        final raw = data();
        if (raw is LayananApp) {
          _app = raw;
        }
        if (_ownsController) {
          unawaited(_controller.loadInitialData());
        }
      };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _controller.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  int _activeFilterCount() {
    var count = 0;
    if (_controller.selectedCategory != null) count++;
    if (_controller.selectedKecamatan != null) count++;
    if (_controller.selectedKelurahan != null) count++;
    if (_controller.onlineOnly) count++;
    return count;
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    setState(() => _isSearching = false);
  }

  Future<void> _handleGroupTap(CctvCameraGroup group) async {
    if (group.cameras.length == 1) {
      _controller.selectCamera(group.cameras.first);
      return;
    }

    final picked = await showCctvGroupPickerSheet(
      context: context,
      cameras: group.cameras,
      activeCameraId: _controller.activeCamera?.id,
      aliveStatus: _controller.aliveStatus,
    );

    if (picked != null && mounted) {
      _controller.selectCamera(picked);
    }
  }

  void _openMapForActiveCamera() {
    final cam = _controller.activeCamera;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (cam != null && cam.hasValidCoords) {
        try {
          _mapController.move(LatLng(cam.latitude, cam.longitude), 16);
        } catch (_) {
          // Map controller may not be attached yet; ignore safely.
        }
      }
      final ctx = _distributionSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _openFullscreenMap() async {
    setState(() => _isFullscreenMapOpen = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CctvFullscreenMapPage(controller: _controller),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isFullscreenMapOpen = false);
      }
    }
  }

  @override
  Widget view(BuildContext context) {
    final tokens = CctvTokens.of(context);
    final title = (_app?.nama ?? '').trim().isNotEmpty
        ? _app!.nama!.trim()
        : 'Pemantauan CCTV';

    return Scaffold(
      backgroundColor: tokens.pageBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: _isSearching
            ? IconButton(
                onPressed: _closeSearch,
                icon: Icon(Icons.arrow_back_rounded, color: tokens.textPrimary),
                tooltip: 'Tutup pencarian',
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _controller.setSearchQuery,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 14, color: tokens.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari kamera, alamat, wilayah...',
                  hintStyle: TextStyle(fontSize: 13.5, color: tokens.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                ),
              )
            : Text(
                title,
                style: tokens.heading,
              ),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final filterCount = _activeFilterCount();
              final hasCameras = _controller.cameras.isNotEmpty;

              if (_isSearching) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.searchQuery.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _controller.setSearchQuery('');
                        },
                        icon: Icon(Icons.close_rounded, color: tokens.textMuted),
                        tooltip: 'Hapus pencarian',
                      ),
                    if (hasCameras)
                      _AppBarFilterButton(
                        count: filterCount,
                        tokens: tokens,
                        onTap: () => showCctvFilterSheet(
                          context: context,
                          controller: _controller,
                        ),
                      ),
                  ],
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasCameras) ...[
                    IconButton(
                      onPressed: _openSearch,
                      icon: Icon(
                        Icons.search_rounded,
                        color: _controller.searchQuery.isNotEmpty
                            ? tokens.primary
                            : tokens.textPrimary,
                      ),
                      tooltip: 'Cari kamera CCTV',
                    ),
                    _AppBarFilterButton(
                      count: filterCount,
                      tokens: tokens,
                      onTap: () => showCctvFilterSheet(
                        context: context,
                        controller: _controller,
                      ),
                    ),
                  ],
                  IconButton(
                    onPressed: _controller.isLoadingInitial
                        ? null
                        : () => _controller.loadInitialData(forceRefresh: true),
                    icon: Icon(Icons.refresh_rounded, color: tokens.textPrimary),
                    tooltip: 'Muat ulang daftar kamera',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoadingInitial && _controller.cameras.isEmpty) {
            return const CctvLoadingView();
          }

          if (_controller.initialError != null && _controller.cameras.isEmpty) {
            return _buildInitialError(tokens);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              if (width >= CctvTokens.desktopBreakpoint) {
                return _buildDesktopLayout(tokens);
              }
              final isCompactMobile =
                  width < CctvTokens.compactMobileBreakpoint;
              return _buildMobileLayout(tokens, isFullBleed: isCompactMobile);
            },
          );
        },
      ),
    );
  }

  Widget _buildInitialError(CctvTokens tokens) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: tokens.offline,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal Memuat Data CCTV',
                style: tokens.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _controller.initialError!,
                style: tokens.body.copyWith(color: tokens.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: CctvTokens.minTouchTarget,
                child: FilledButton.icon(
                  onPressed: () =>
                      _controller.loadInitialData(forceRefresh: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor: tokens.primaryOnFill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
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

  Widget _buildMobileLayout(CctvTokens tokens, {required bool isFullBleed}) {
    return Column(
      children: [
        // Sticky 16:9 Video Player pinned at top
        if (_controller.activeCamera != null)
          CctvPlayerStage(
            camera: _controller.activeCamera,
            isAlive: _controller.statusOf(_controller.activeCamera?.id),
            onStreamReady: _controller.markCameraLive,
            onStreamError: _controller.handleStreamError,
            isDesktopStage: false,
            isActive: !_isFullscreenMapOpen,
          ),

        // Compact Telemetry Bar directly beneath video
        CctvTelemetryCard(
          controller: _controller,
          onRefreshStatus: () => _controller.checkAlive(forceRefresh: true),
          onOpenMap: _openMapForActiveCamera,
          isDesktopPanel: false,
          isFullBleed: isFullBleed,
        ),

        // Full-height Map + Google Maps-style Draggable Camera List Sheet
        Expanded(
          child: CctvMapView(
            controller: _controller,
            mapController: _mapController,
            isDesktopSplitPane: false,
            isFullBleed: isFullBleed,
            onGroupTap: _handleGroupTap,
            onToggleFullscreen: _openFullscreenMap,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(CctvTokens tokens) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: CctvTokens.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_controller.activeCamera != null) ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 8,
                        child: CctvPlayerStage(
                          camera: _controller.activeCamera,
                          isAlive:
                              _controller.statusOf(_controller.activeCamera?.id),
                          onStreamReady: _controller.markCameraLive,
                          onStreamError: _controller.handleStreamError,
                          isDesktopStage: true,
                          isActive: !_isFullscreenMapOpen,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 4,
                        child: CctvTelemetryCard(
                          controller: _controller,
                          onRefreshStatus: () =>
                              _controller.checkAlive(forceRefresh: true),
                          onOpenMap: _openMapForActiveCamera,
                          isDesktopPanel: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _buildDistributionSection(tokens, isDesktopSplitPane: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionSection(
    CctvTokens tokens, {
    required bool isDesktopSplitPane,
    bool isFullBleed = false,
  }) {
    return Container(
      key: _distributionSectionKey,
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: isFullBleed
            ? BorderRadius.zero
            : BorderRadius.circular(CctvTokens.radiusLg),
        border: isFullBleed
            ? Border(
                bottom: BorderSide(color: tokens.border),
              )
            : Border.all(color: tokens.border),
        boxShadow: isFullBleed ? tokens.sectionShadow : tokens.cardShadow,
      ),
      clipBehavior: isFullBleed ? Clip.none : Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Desktop keeps inline FilterBar; Mobile uses AppBar Search + Filter sheet.
          if (isDesktopSplitPane) ...[
            CctvFilterBar(controller: _controller),
            Divider(height: 1, color: tokens.divider),
          ],

          // Interactive Map + Camera List (auto-visible by default)
          CctvMapView(
            controller: _controller,
            mapController: _mapController,
            isDesktopSplitPane: isDesktopSplitPane,
            isFullBleed: isFullBleed,
            onGroupTap: _handleGroupTap,
            onToggleFullscreen: _openFullscreenMap,
          ),
        ],
      ),
    );
  }
}


class _AppBarFilterButton extends StatelessWidget {
  final int count;
  final CctvTokens tokens;
  final VoidCallback onTap;

  const _AppBarFilterButton({
    required this.count,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = count > 0;

    return IconButton(
      onPressed: onTap,
      tooltip: 'Filter CCTV',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.tune_rounded,
            color: isActive ? tokens.primary : tokens.textPrimary,
          ),
          if (isActive)
            Positioned(
              top: -4,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.surface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: tokens.primaryOnFill,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
