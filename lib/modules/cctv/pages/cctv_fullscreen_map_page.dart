import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/modules/cctv/controllers/cctv_controller.dart';
import '/modules/cctv/models/cctv_camera.dart';
import '/modules/cctv/models/cctv_camera_group.dart';
import '/modules/cctv/services/cctv_local_service.dart';
import '/modules/cctv/widgets/cctv_group_picker_sheet.dart';
import '/modules/cctv/widgets/cctv_player_stage.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

class CctvFullscreenMapPage extends StatefulWidget {
  final CctvController controller;

  const CctvFullscreenMapPage({
    super.key,
    required this.controller,
  });

  @override
  State<CctvFullscreenMapPage> createState() => _CctvFullscreenMapPageState();
}

class _CctvFullscreenMapPageState extends State<CctvFullscreenMapPage>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _rippleController;
  CctvCamera? _previewCamera;
  bool _isInlinePlaying = false;
  bool _showDesktopList = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _previewCamera = widget.controller.activeCamera;
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _mapController.dispose();
    super.dispose();
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
      return 15.0;
    }
    return CctvController.defaultZoom;
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final cam = _mapController.camera;
    _mapController.move(cam.center, (cam.zoom + delta).clamp(10.0, 18.0));
  }

  void _recenter() {
    if (!_mapReady) return;
    final target = _previewCamera ?? widget.controller.activeCamera;
    if (target != null && target.hasValidCoords) {
      _mapController.move(LatLng(target.latitude, target.longitude), 15.5);
    } else {
      _mapController.move(
        const LatLng(CctvController.defaultLat, CctvController.defaultLng),
        CctvController.defaultZoom,
      );
    }
  }

  Future<void> _handleGroupTap(CctvCameraGroup group) async {
    if (_mapReady && group.hasValidCoords) {
      _mapController.move(
        LatLng(group.latitude, group.longitude),
        _mapController.camera.zoom < 15 ? 15.5 : _mapController.camera.zoom,
      );
    }

    if (group.cameras.length == 1) {
      final cam = group.cameras.first;
      setState(() => _previewCamera = cam);
      if (_isInlinePlaying) {
        widget.controller.selectCamera(cam);
      }
      return;
    }

    final picked = await showCctvGroupPickerSheet(
      context: context,
      cameras: group.cameras,
      activeCameraId: _previewCamera?.id ?? widget.controller.activeCamera?.id,
      aliveStatus: widget.controller.aliveStatus,
    );

    if (picked != null && mounted) {
      widget.controller.selectCamera(picked);
      setState(() {
        _previewCamera = picked;
        _isInlinePlaying = true;
      });
    }
  }

  void _playInline(CctvCamera camera) {
    widget.controller.selectCamera(camera);
    setState(() {
      _previewCamera = camera;
      _isInlinePlaying = true;
    });
  }

  void _openInMainPage(CctvCamera camera) {
    widget.controller.selectCamera(camera);
    Navigator.of(context).pop();
  }

  Future<void> _openMobileListSheet() async {
    final groups = widget.controller.allGroups;
    final tokens = CctvTokens.of(context);

    final pickedGroup = await showModalBottomSheet<CctvCameraGroup>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Daftar Kamera (${groups.length})',
                        style: tokens.heading,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.divider),
              Expanded(
                child: _buildPointListView(
                  groups: groups,
                  tokens: tokens,
                  scrollController: scrollController,
                  onTap: (group) => Navigator.of(ctx).pop(group),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (pickedGroup != null && mounted) {
      await _handleGroupTap(pickedGroup);
    }
  }

  Widget _buildPointListView({
    required List<CctvCameraGroup> groups,
    required CctvTokens tokens,
    ScrollController? scrollController,
    required ValueChanged<CctvCameraGroup> onTap,
  }) {
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_outlined,
                  size: 28, color: tokens.textMuted),
              const SizedBox(height: 8),
              Text(
                'Tidak ada kamera ditemukan',
                style: tokens.label.copyWith(color: tokens.textPrimary),
              ),
            ],
          ),
        ),
      );
    }

    final highlightedId =
        _previewCamera?.id ?? widget.controller.activeCamera?.id;

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(10),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final group = groups[index];
        final primary = group.primaryCamera;
        final isSelected = group.containsCamera(highlightedId);
        final status = group.aliveStatus(widget.controller.aliveStatus);
        final dotColor = status == true
            ? tokens.online
            : status == false
                ? tokens.offline
                : tokens.textMuted;

        return Material(
          color: isSelected ? tokens.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
          child: InkWell(
            onTap: () => onTap(group),
            borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                            color: isSelected
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
                  if (group.isMultiCamera)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        borderRadius:
                            BorderRadius.circular(CctvTokens.radiusPill),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CctvTokens.of(context);

    return Scaffold(
      backgroundColor: tokens.pageBg,
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final mapGroups = widget.controller.mapGroups;
          final allGroups = widget.controller.allGroups;
          final highlightedId =
              _previewCamera?.id ?? widget.controller.activeCamera?.id;

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isCompact = width < 360;
              final isDesktop = width >= CctvTokens.desktopBreakpoint;

              final previewCard = _previewCamera == null
                  ? null
                  : _CameraPreviewCard(
                      camera: _previewCamera!,
                      status: widget.controller.statusOf(_previewCamera!.id),
                      isFavorite:
                          widget.controller.isFavorite(_previewCamera!.id),
                      distanceLabel:
                          widget.controller.distanceLabelFor(_previewCamera!),
                      isInlinePlaying: _isInlinePlaying,
                      tokens: tokens,
                      onClose: () => setState(() {
                        _isInlinePlaying = false;
                        _previewCamera = null;
                      }),
                      onToggleFavorite: () =>
                          widget.controller.toggleFavorite(_previewCamera!.id),
                      onStopInline: () =>
                          setState(() => _isInlinePlaying = false),
                      onPlayInline: () => _playInline(_previewCamera!),
                      onOpenMainPage: () => _openInMainPage(_previewCamera!),
                      onStreamReady: widget.controller.markCameraLive,
                    );

              final mapStack = Stack(
                fit: StackFit.expand,
                children: [
                  // Edge-to-edge map canvas
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter(),
                      initialZoom: _initialZoom(),
                      minZoom: 10,
                      maxZoom: 18,
                      onMapReady: () => _mapReady = true,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.diskominfotik.banjarmasinpintar',
                        tileProvider: NetworkTileProvider(
                          headers: {
                            'User-Agent':
                                'BanjarmasinPintar/3.0.9 (com.diskominfotik.banjarmasinpintar)',
                            'Referer': 'https://pintar.banjarmasinkota.go.id/',
                          },
                        ),
                        maxZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          for (final group in mapGroups)
                            Marker(
                              point: LatLng(group.latitude, group.longitude),
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              child: _FullscreenMarker(
                                group: group,
                                isActive: group.containsCamera(highlightedId),
                                aliveStatus: group
                                    .aliveStatus(widget.controller.aliveStatus),
                                tokens: tokens,
                                rippleAnimation: _rippleController,
                                onTap: () => _handleGroupTap(group),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // SafeArea HUD overlay
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Floating Top Bar
                          Row(
                            children: [
                              _HudIconButton(
                                icon: Icons.arrow_back_rounded,
                                tooltip: 'Kembali',
                                tokens: tokens,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    height: CctvTokens.minTouchTarget,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: tokens.surfaceElevated
                                          .withValues(alpha: 0.96),
                                      borderRadius: BorderRadius.circular(
                                          CctvTokens.radiusPill),
                                      boxShadow: tokens.floatingShadow,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.map_outlined,
                                          size: 16,
                                          color: tokens.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Peta CCTV · ${mapGroups.length} titik',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: tokens.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _HudPillButton(
                                icon: Icons.format_list_bulleted_rounded,
                                label: isCompact ? '' : 'Daftar',
                                active: isDesktop && _showDesktopList,
                                tokens: tokens,
                                onTap: () {
                                  if (isDesktop) {
                                    setState(() =>
                                        _showDesktopList = !_showDesktopList);
                                  } else {
                                    _openMobileListSheet();
                                  }
                                },
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Bottom Controls + Preview/Inline Player Card
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (previewCard != null && isDesktop)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: _isInlinePlaying ? 460 : 400,
                                  ),
                                  child: previewCard,
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '© OpenStreetMap',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _HudIconButton(
                                    icon: Icons.my_location_rounded,
                                    tooltip: 'Pusatkan peta',
                                    tokens: tokens,
                                    onTap: _recenter,
                                  ),
                                  const SizedBox(height: 8),
                                  _HudIconButton(
                                    icon: Icons.add_rounded,
                                    tooltip: 'Perbesar peta',
                                    tokens: tokens,
                                    onTap: () => _zoomBy(1),
                                  ),
                                  const SizedBox(height: 6),
                                  _HudIconButton(
                                    icon: Icons.remove_rounded,
                                    tooltip: 'Perkecil peta',
                                    tokens: tokens,
                                    onTap: () => _zoomBy(-1),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          if (previewCard != null && !isDesktop) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 480),
                                child: previewCard,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );

              if (isDesktop && _showDesktopList) {
                return Row(
                  children: [
                    Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        border: Border(right: BorderSide(color: tokens.border)),
                      ),
                      child: SafeArea(
                        right: false,
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Daftar Kamera (${allGroups.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tokens.title,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(
                                        () => _showDesktopList = false),
                                    icon: const Icon(Icons.close_rounded),
                                    tooltip: 'Tutup daftar',
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: tokens.divider),
                            Expanded(
                              child: _buildPointListView(
                                groups: allGroups,
                                tokens: tokens,
                                onTap: _handleGroupTap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(child: mapStack),
                  ],
                );
              }

              return mapStack;
            },
          );
        },
      ),
    );
  }
}

class _CameraPreviewCard extends StatelessWidget {
  final CctvCamera camera;
  final bool? status;
  final bool isFavorite;
  final String? distanceLabel;
  final bool isInlinePlaying;
  final CctvTokens tokens;
  final VoidCallback onClose;
  final VoidCallback onToggleFavorite;
  final VoidCallback onStopInline;
  final VoidCallback onPlayInline;
  final VoidCallback onOpenMainPage;
  final ValueChanged<String> onStreamReady;

  const _CameraPreviewCard({
    required this.camera,
    required this.status,
    required this.isFavorite,
    required this.distanceLabel,
    required this.isInlinePlaying,
    required this.tokens,
    required this.onClose,
    required this.onToggleFavorite,
    required this.onStopInline,
    required this.onPlayInline,
    required this.onOpenMainPage,
    required this.onStreamReady,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusBg;
    final Color statusFg;
    final Color dotColor;
    final String statusLabel;

    if (status == true) {
      statusBg = tokens.onlineSoft;
      statusFg = tokens.onlineText;
      dotColor = tokens.online;
      statusLabel = 'Online';
    } else if (status == false) {
      statusBg = tokens.offlineSoft;
      statusFg = tokens.offlineText;
      dotColor = tokens.offline;
      statusLabel = 'Offline';
    } else {
      statusBg = tokens.surfaceSubtle;
      statusFg = tokens.textMuted;
      dotColor = tokens.textMuted;
      statusLabel = 'Memeriksa';
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(CctvTokens.radiusLg),
        border: Border.all(color: tokens.border),
        boxShadow: tokens.floatingShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inline Live Video Player directly inside Fullscreen Map!
          if (isInlinePlaying)
            CctvPlayerStage(
              camera: camera,
              isAlive: status,
              onStreamReady: onStreamReady,
              onStreamError: () => false,
              isDesktopStage: true,
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              camera.displayCategory,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tokens.primary,
                              ),
                            ),
                          ),
                          if (distanceLabel != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· $distanceLabel',
                              style: tokens.caption.copyWith(fontSize: 11.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onToggleFavorite,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 19,
                          color: isFavorite
                              ? const Color(0xFFF59E0B)
                              : tokens.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: tokens.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  camera.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.title,
                ),
                if (camera.wilayahLabel.isNotEmpty ||
                    camera.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    camera.address.isNotEmpty
                        ? camera.address
                        : camera.wilayahLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.caption.copyWith(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: CctvTokens.minTouchTarget,
                        child: isInlinePlaying
                            ? OutlinedButton.icon(
                                onPressed: onStopInline,
                                icon: const Icon(Icons.stop_circle_outlined,
                                    size: 18),
                                label: const Text(
                                  'Tutup Video',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: tokens.textPrimary,
                                  side: BorderSide(color: tokens.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      CctvTokens.radiusMd,
                                    ),
                                  ),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: onPlayInline,
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 20),
                                label: const Text(
                                  'Putar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: tokens.primary,
                                  foregroundColor: tokens.primaryOnFill,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      CctvTokens.radiusMd,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (camera.hasValidCoords) ...[
                      Tooltip(
                        message: 'Buka rute di Maps',
                        child: SizedBox(
                          width: CctvTokens.minTouchTarget,
                          height: CctvTokens.minTouchTarget,
                          child: Material(
                            color: tokens.surfaceSubtle,
                            borderRadius:
                                BorderRadius.circular(CctvTokens.radiusMd),
                            child: InkWell(
                              onTap: () =>
                                  CctvLocalService.openInExternalMaps(camera),
                              borderRadius:
                                  BorderRadius.circular(CctvTokens.radiusMd),
                              child: Icon(
                                Icons.directions_outlined,
                                size: 19,
                                color: tokens.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    SizedBox(
                      height: CctvTokens.minTouchTarget,
                      child: TextButton.icon(
                        onPressed: onOpenMainPage,
                        icon: Icon(
                          Icons.open_in_new_rounded,
                          size: 17,
                          color: tokens.primary,
                        ),
                        label: Text(
                          'Detail',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: tokens.primarySoft,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(CctvTokens.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final CctvTokens tokens;
  final VoidCallback onTap;

  const _HudIconButton({
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
              width: CctvTokens.minTouchTarget,
              height: CctvTokens.minTouchTarget,
              child: Icon(icon, size: 20, color: tokens.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _HudPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final CctvTokens tokens;
  final VoidCallback onTap;

  const _HudPillButton({
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
            height: CctvTokens.minTouchTarget,
            padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 12 : 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: fg),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
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

class _FullscreenMarker extends StatelessWidget {
  final CctvCameraGroup group;
  final bool isActive;
  final bool? aliveStatus;
  final CctvTokens tokens;
  final Animation<double> rippleAnimation;
  final VoidCallback onTap;

  const _FullscreenMarker({
    required this.group,
    required this.isActive,
    required this.aliveStatus,
    required this.tokens,
    required this.rippleAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = aliveStatus == false;
    final Color bg;
    final Color border;
    final Color iconColor;

    if (isOffline) {
      bg = tokens.offline;
      border = tokens.offline;
      iconColor = Colors.white;
    } else if (isActive) {
      bg = tokens.primary;
      border = tokens.primary;
      iconColor = tokens.primaryOnFill;
    } else {
      bg = tokens.surfaceElevated;
      border = tokens.border;
      iconColor = tokens.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isActive)
            AnimatedBuilder(
              animation: rippleAnimation,
              builder: (context, _) {
                final t = rippleAnimation.value;
                return Transform.scale(
                  scale: 0.8 + (t * 0.85),
                  child: Opacity(
                    opacity: (1.0 - t) * 0.45,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isOffline ? tokens.offline : tokens.primary,
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                );
              },
            ),
          AnimatedScale(
            scale: isActive ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.videocam_rounded, size: 16, color: iconColor),
            ),
          ),
          if (group.isMultiCamera)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: tokens.primary,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
                child: Center(
                  child: Text(
                    '${group.cameras.length}',
                    style: TextStyle(
                      color: tokens.primaryOnFill,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
