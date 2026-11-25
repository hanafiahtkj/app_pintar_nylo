import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/modules/cctv/controllers/cctv_controller.dart';
import '/modules/cctv/models/cctv_camera_group.dart';
import '/modules/cctv/services/cctv_local_service.dart';
import '/modules/cctv/widgets/cctv_map_marker.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

class CctvMapView extends StatefulWidget {
  final CctvController controller;
  final MapController mapController;
  final ValueChanged<CctvCameraGroup> onGroupTap;
  final bool isDesktopSplitPane;
  final bool isFullBleed;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onRefreshStatus;

  const CctvMapView({
    super.key,
    required this.controller,
    required this.mapController,
    required this.onGroupTap,
    this.isDesktopSplitPane = false,
    this.isFullBleed = false,
    this.onToggleFullscreen,
    this.onRefreshStatus,
  });

  @override
  State<CctvMapView> createState() => _CctvMapViewState();
}

class _CctvMapViewState extends State<CctvMapView>
    with SingleTickerProviderStateMixin {
  late bool _showListPanel;
  bool _mapReady = false;
  bool _didInitialFocus = false;
  int _lastFocusVersion = -1;

  late final AnimationController _rippleController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  NetworkTileProvider? _tileProvider;

  NetworkTileProvider get _osmTileProvider =>
      _tileProvider ??= NetworkTileProvider(
        headers: {
          'User-Agent':
              'BanjarmasinPintar/3.0.9 (com.diskominfotik.banjarmasinpintar)',
          'Referer': 'https://pintar.banjarmasinkota.go.id/',
        },
      );

  @override
  void initState() {
    super.initState();
    _showListPanel = true;
    _lastFocusVersion = widget.controller.mapFocusVersion;
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant CctvMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ctrl = widget.controller;
    if (_mapReady && ctrl.mapFocusVersion != _lastFocusVersion) {
      _lastFocusVersion = ctrl.mapFocusVersion;
      _didInitialFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitFilteredCameras();
      });
    } else if (_mapReady &&
        !_didInitialFocus &&
        ctrl.selectedKecamatan == null &&
        ctrl.selectedKelurahan == null &&
        ctrl.activeCamera != null &&
        ctrl.activeCamera!.hasValidCoords) {
      _didInitialFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recenterMap();
      });
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _fitFilteredCameras() {
    final ctrl = widget.controller;
    if (ctrl.selectedKecamatan == null && ctrl.selectedKelurahan == null) {
      widget.mapController.move(
        const LatLng(CctvController.defaultLat, CctvController.defaultLng),
        CctvController.defaultZoom,
      );
      return;
    }

    final mapped = ctrl.mappedCameras;
    if (mapped.isEmpty) return;

    if (mapped.length == 1) {
      widget.mapController.move(
        LatLng(mapped.first.latitude, mapped.first.longitude),
        15.0,
      );
      return;
    }

    final points =
        mapped.map((c) => LatLng(c.latitude, c.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(points);
    widget.mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(42),
        maxZoom: 16,
      ),
    );
  }

  LatLng _initialCenter() {
    final active = widget.controller.activeCamera;
    if (active != null && active.hasValidCoords) {
      return LatLng(active.latitude, active.longitude);
    }
    return const LatLng(CctvController.defaultLat, CctvController.defaultLng);
  }

  double _initialZoom() {
    final active = widget.controller.activeCamera;
    if (active != null && active.hasValidCoords) {
      return 15.5;
    }
    return CctvController.defaultZoom;
  }

  void _recenterMap() {
    if (!_mapReady) return;
    final active = widget.controller.activeCamera;
    if (active != null && active.hasValidCoords) {
      widget.mapController.move(
        LatLng(active.latitude, active.longitude),
        15.5,
      );
    } else {
      widget.mapController.move(
        const LatLng(CctvController.defaultLat, CctvController.defaultLng),
        CctvController.defaultZoom,
      );
    }
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final cam = widget.mapController.camera;
    final nextZoom = (cam.zoom + delta).clamp(10.0, 18.0);
    widget.mapController.move(cam.center, nextZoom);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final tokens = CctvTokens.of(context);
    final mapGroups = ctrl.mapGroups;
    final listGroups = ctrl.allGroups;

    final desktopMapHeight = 520.0;
    final controlsBottomOffset = widget.isDesktopSplitPane ? 24.0 : 108.0;
    final osmBottomOffset = widget.isDesktopSplitPane ? 8.0 : 102.0;

    final mapCanvas = LayoutBuilder(
      builder: (context, constraints) {
        final isCompactMap = constraints.maxWidth < 360;
        final resolvedHeight = widget.isDesktopSplitPane
            ? desktopMapHeight
            : (constraints.maxHeight.isFinite ? constraints.maxHeight : 380.0);

        return SizedBox(
          height: resolvedHeight,
          width: double.infinity,
          child: Stack(
            children: [
              FlutterMap(
                mapController: widget.mapController,
                options: MapOptions(
                  initialCenter: _initialCenter(),
                  initialZoom: _initialZoom(),
                  minZoom: 10,
                  maxZoom: 18,
                  onMapReady: () {
                    _mapReady = true;
                    if (ctrl.selectedKecamatan != null ||
                        ctrl.selectedKelurahan != null) {
                      _didInitialFocus = true;
                      _fitFilteredCameras();
                    } else if (ctrl.activeCamera != null &&
                        ctrl.activeCamera!.hasValidCoords) {
                      _didInitialFocus = true;
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.diskominfotik.banjarmasinpintar',
                    tileProvider: _osmTileProvider,
                    evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
                    panBuffer: 1,
                    tileDisplay: const TileDisplay.fadeIn(
                      duration: Duration(milliseconds: 120),
                    ),
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      for (final group in [
                        ...mapGroups.where(
                          (g) => !g.containsCamera(ctrl.activeCamera?.id),
                        ),
                        ...mapGroups.where(
                          (g) => g.containsCamera(ctrl.activeCamera?.id),
                        ),
                      ])
                        () {
                          final isActive =
                              group.containsCamera(ctrl.activeCamera?.id);
                          return Marker(
                            point: LatLng(group.latitude, group.longitude),
                            width: isActive ? 96 : 46,
                            height: isActive ? 96 : 46,
                            alignment: Alignment.center,
                            child: CctvMapMarker(
                              group: group,
                              isActive: isActive,
                              aliveStatus: group.aliveStatus(ctrl.aliveStatus),
                              tokens: tokens,
                              rippleAnimation: _rippleController,
                              onTap: () {
                                widget.mapController.move(
                                  LatLng(group.latitude, group.longitude),
                                  widget.mapController.camera.zoom < 15
                                      ? 15.5
                                      : widget.mapController.camera.zoom,
                                );
                                widget.onGroupTap(group);
                              },
                            ),
                          );
                        }(),
                    ],
                  ),
                ],
              ),

              // Top-right soft floating pill (Fullscreen)
              if (widget.onToggleFullscreen != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _MapActionPill(
                    icon: Icons.fullscreen_rounded,
                    label: isCompactMap ? '' : 'Layar Penuh',
                    active: false,
                    tokens: tokens,
                    onTap: widget.onToggleFullscreen!,
                  ),
                ),

              // Bottom-right thumb-friendly Zoom & Recenter controls
              Positioned(
                right: 12,
                bottom: controlsBottomOffset,
                child: Column(
                  children: [
                    _MapSquareButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Pusatkan peta',
                      tokens: tokens,
                      onTap: _recenterMap,
                    ),
                    const SizedBox(height: 8),
                    _MapSquareButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Perbesar peta',
                      tokens: tokens,
                      onTap: () => _zoomBy(1),
                    ),
                    const SizedBox(height: 6),
                    _MapSquareButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Perkecil peta',
                      tokens: tokens,
                      onTap: () => _zoomBy(-1),
                    ),
                  ],
                ),
              ),

              // OSM Attribution badge
              Positioned(
                left: 10,
                bottom: osmBottomOffset,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '© OpenStreetMap',
                    style: TextStyle(fontSize: 10, color: Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.isDesktopSplitPane) {
      final listPanel = _MapCameraListPanel(
        groups: listGroups,
        controller: ctrl,
        tokens: tokens,
        height: desktopMapHeight,
        onClose: () => setState(() => _showListPanel = false),
        onSelectGroup: (group) {
          if (group.hasValidCoords && _mapReady) {
            widget.mapController.move(
              LatLng(group.latitude, group.longitude),
              16,
            );
          }
          widget.onGroupTap(group);
        },
      );

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showListPanel)
            Container(
              width: 320,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: tokens.divider)),
              ),
              child: listPanel,
            ),
          Expanded(child: mapCanvas),
        ],
      );
    }

    // Mobile / Tablet portrait: full-height map + unified Google Maps-style sheet
    return LayoutBuilder(
      builder: (context, constraints) {
        final availHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : 380.0;
        final collapsedSize = (92.0 / availHeight).clamp(0.18, 0.42);
        const maxSize = 0.94;
        final midSize = collapsedSize < 0.50 ? 0.58 : null;

        final activeCam = ctrl.activeCamera;
        final activeDistance = ctrl.distanceLabelFor(activeCam);
        final activeStatus = ctrl.statusOf(activeCam?.id);
        final activeDotColor = activeStatus == true
            ? tokens.online
            : activeStatus == false
                ? tokens.offline
                : tokens.textMuted;

        void toggleSheet(ScrollController scrollController) {
          if (!_sheetController.isAttached) return;
          final isExpanded = _sheetController.size > collapsedSize + 0.08;
          if (scrollController.hasClients && scrollController.offset > 0) {
            scrollController.jumpTo(0);
          }
          _sheetController.animateTo(
            isExpanded ? collapsedSize : (midSize ?? maxSize),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            mapCanvas,
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: collapsedSize,
              minChildSize: collapsedSize,
              maxChildSize: maxSize,
              snap: true,
              snapSizes: [
                collapsedSize,
                if (midSize != null) midSize,
                maxSize,
              ],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: tokens.border),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A)
                            .withValues(alpha: tokens.isDark ? 0.36 : 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      // Pinned Active Camera Header (always visible, tap/drag to toggle)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedSheetHeaderDelegate(
                          height: 88,
                          backgroundColor: tokens.surfaceElevated,
                          child: GestureDetector(
                            onTap: () => toggleSheet(scrollController),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: tokens.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      14,
                                      8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: activeDotColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Expanded(
                                                    child: Text(
                                                      activeCam?.displayName ??
                                                          'Pemantauan CCTV',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          tokens.title.copyWith(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  if (activeDistance !=
                                                      null) ...[
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            tokens.primarySoft,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .near_me_rounded,
                                                            size: 10.5,
                                                            color:
                                                                tokens.primary,
                                                          ),
                                                          const SizedBox(
                                                            width: 3,
                                                          ),
                                                          Text(
                                                            activeDistance,
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: tokens
                                                                  .primary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                  Expanded(
                                                    child: Text(
                                                      (activeCam?.address ?? '')
                                                              .isNotEmpty
                                                          ? activeCam!.address
                                                          : (activeCam
                                                                  ?.displayCategory ??
                                                              'Tarik ke atas untuk daftar kamera'),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: tokens.caption,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tokens.surfaceSubtle,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${listGroups.length}',
                                                style: tokens.caption.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: tokens.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Icon(
                                                Icons.keyboard_arrow_up_rounded,
                                                size: 18,
                                                color: tokens.textMuted,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Divider(height: 1, color: tokens.divider),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Expanded Status Summary & Quick Actions
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Total ${ctrl.cameras.length}',
                                    style: tokens.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6.5,
                                        height: 6.5,
                                        decoration: BoxDecoration(
                                          color: tokens.online,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${ctrl.onlineCount} Online',
                                        style: tokens.caption.copyWith(
                                          color: tokens.onlineText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6.5,
                                        height: 6.5,
                                        decoration: BoxDecoration(
                                          color: tokens.offline,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${ctrl.offlineCount} Offline',
                                        style: tokens.caption.copyWith(
                                          color: tokens.offlineText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (activeCam != null &&
                                      activeCam.hasValidCoords)
                                    IconButton(
                                      onPressed: () =>
                                          CctvLocalService.openInExternalMaps(
                                        activeCam,
                                      ),
                                      icon: Icon(
                                        Icons.directions_outlined,
                                        size: 18,
                                        color: tokens.primary,
                                      ),
                                      tooltip: 'Buka di Google/Apple Maps',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  if (widget.onRefreshStatus != null)
                                    TextButton.icon(
                                      onPressed: ctrl.isCheckingAlive
                                          ? null
                                          : widget.onRefreshStatus,
                                      icon: ctrl.isCheckingAlive
                                          ? SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: tokens.primary,
                                              ),
                                            )
                                          : Icon(
                                              Icons.sync_rounded,
                                              size: 15,
                                              color: tokens.primary,
                                            ),
                                      label: Text(
                                        ctrl.isCheckingAlive
                                            ? 'Cek...'
                                            : 'Cek Status',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: tokens.primary,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Divider(height: 1, color: tokens.divider),
                      ),

                      if (listGroups.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 28,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_off_outlined,
                                  size: 26,
                                  color: tokens.textMuted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tidak ada kamera ditemukan',
                                  style: tokens.label.copyWith(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ubah kata kunci atau filter wilayah di atas.',
                                  style: tokens.caption,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 24),
                          sliver: SliverList.separated(
                            itemCount: listGroups.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final group = listGroups[index];
                              return _MapCameraListPanel.buildGroupTile(
                                group: group,
                                controller: ctrl,
                                tokens: tokens,
                                onSelectGroup: (picked) {
                                  if (picked.hasValidCoords && _mapReady) {
                                    widget.mapController.move(
                                      LatLng(
                                        picked.latitude,
                                        picked.longitude,
                                      ),
                                      16,
                                    );
                                  }
                                  widget.onGroupTap(picked);
                                  if (scrollController.hasClients &&
                                      scrollController.offset > 0) {
                                    scrollController.jumpTo(0);
                                  }
                                  if (_sheetController.isAttached) {
                                    _sheetController.animateTo(
                                      collapsedSize,
                                      duration:
                                          const Duration(milliseconds: 240),
                                      curve: Curves.easeOutCubic,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PinnedSheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Color backgroundColor;
  final Widget child;

  const _PinnedSheetHeaderDelegate({
    required this.height,
    required this.backgroundColor,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedSheetHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.child != child;
  }
}

class _MapCameraListPanel extends StatelessWidget {
  final List<CctvCameraGroup> groups;
  final CctvController controller;
  final CctvTokens tokens;
  final double? height;
  final VoidCallback onClose;
  final ValueChanged<CctvCameraGroup> onSelectGroup;

  const _MapCameraListPanel({
    required this.groups,
    required this.controller,
    required this.tokens,
    required this.height,
    required this.onClose,
    required this.onSelectGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: tokens.surfaceElevated,
      child: Column(
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Icon(
                  Icons.videocam_outlined,
                  size: 16,
                  color: tokens.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Daftar Kamera',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              tokens.label.copyWith(color: tokens.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: tokens.surfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${groups.length}',
                          style: tokens.caption
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: tokens.textMuted,
                  ),
                  tooltip: 'Tutup daftar kamera',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.divider),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_off_outlined,
                    size: 26,
                    color: tokens.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada kamera ditemukan',
                    style: tokens.label.copyWith(color: tokens.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ubah kata kunci atau filter wilayah di atas.',
                    style: tokens.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (height != null)
            Expanded(
              child: _buildListView(scrollable: true),
            )
          else
            _buildListView(scrollable: false),
        ],
      ),
    );
  }

  Widget _buildListView({required bool scrollable}) {
    return ListView.separated(
      shrinkWrap: !scrollable,
      physics: scrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) => buildGroupTile(
        group: groups[index],
        controller: controller,
        tokens: tokens,
        onSelectGroup: onSelectGroup,
      ),
    );
  }

  static Widget buildGroupTile({
    required CctvCameraGroup group,
    required CctvController controller,
    required CctvTokens tokens,
    required ValueChanged<CctvCameraGroup> onSelectGroup,
  }) {
        final primary = group.primaryCamera;
        final isActive = group.containsCamera(controller.activeCamera?.id);
        final status = group.aliveStatus(controller.aliveStatus);
        final distanceLabel = controller.distanceLabelFor(primary);

        final dotColor = status == true
            ? tokens.online
            : status == false
                ? tokens.offline
                : tokens.textMuted;

        return Material(
          color: isActive ? tokens.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
          child: InkWell(
            onTap: () => onSelectGroup(group),
            borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primary.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? tokens.primary
                                : tokens.textPrimary,
                          ),
                        ),
                        if (primary.wilayahLabel.isNotEmpty)
                          Text(
                            primary.wilayahLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: tokens.primary,
                            ),
                          ),
                        Text(
                          primary.address.isNotEmpty
                              ? primary.address
                              : primary.displayCategory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (distanceLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        distanceLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (group.isMultiCamera)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        borderRadius: BorderRadius.circular(
                          CctvTokens.radiusPill,
                        ),
                      ),
                      child: Text(
                        '${group.cameras.length}',
                        style: TextStyle(
                          color: tokens.primaryOnFill,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (!group.hasValidCoords)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.warningSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Non-GPS',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: tokens.warningText,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: tokens.textMuted,
                    ),
                ],
              ),
            ),
          ),
        );
  }
}

class _MapSquareButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final CctvTokens tokens;
  final VoidCallback onTap;

  const _MapSquareButton({
    required this.icon,
    required this.tooltip,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceElevated.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
          boxShadow: tokens.floatingShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 19, color: tokens.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final CctvTokens tokens;
  final VoidCallback onTap;

  const _MapActionPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? tokens.primary
        : tokens.surfaceElevated.withValues(alpha: 0.96);
    final fg = active ? tokens.primaryOnFill : tokens.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CctvTokens.radiusPill),
        boxShadow: tokens.floatingShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CctvTokens.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CctvTokens.radiusPill),
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 12 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: fg),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
