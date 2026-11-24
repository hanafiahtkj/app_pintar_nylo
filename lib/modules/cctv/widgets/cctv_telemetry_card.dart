import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/modules/cctv/controllers/cctv_controller.dart';
import '/modules/cctv/models/cctv_camera.dart';
import '/modules/cctv/services/cctv_local_service.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

class CctvTelemetryCard extends StatefulWidget {
  final CctvController controller;
  final VoidCallback onRefreshStatus;
  final VoidCallback onOpenMap;

  /// When `true` (tablet landscape / desktop ≥ 1024px), renders as a full side
  /// panel with metadata always visible. When `false` (mobile), renders as a
  /// soft, compact card with expandable metadata.
  final bool isDesktopPanel;
  final bool isFullBleed;

  const CctvTelemetryCard({
    super.key,
    required this.controller,
    required this.onRefreshStatus,
    required this.onOpenMap,
    this.isDesktopPanel = false,
    this.isFullBleed = false,
  });

  @override
  State<CctvTelemetryCard> createState() => _CctvTelemetryCardState();
}

class _CctvTelemetryCardState extends State<CctvTelemetryCard> {
  bool _expanded = false;

  void _copyCoords(BuildContext context, CctvCamera camera) {
    final text =
        '${camera.latitude.toStringAsFixed(5)}, ${camera.longitude.toStringAsFixed(5)}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Koordinat $text disalin'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CctvTokens.of(context);
    final activeCam = widget.controller.activeCamera;

    if (widget.isDesktopPanel) {
      return _buildDesktopPanel(context, tokens, activeCam);
    }
    return _buildMobileCard(context, tokens, activeCam);
  }

  Widget _buildMobileCard(
    BuildContext context,
    CctvTokens tokens,
    CctvCamera? activeCam,
  ) {
    final fullBleed = widget.isFullBleed;
    final distanceLabel = widget.controller.distanceLabelFor(activeCam);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: fullBleed
            ? BorderRadius.zero
            : BorderRadius.circular(CctvTokens.radiusLg),
        border: fullBleed
            ? Border(bottom: BorderSide(color: tokens.border))
            : Border.all(color: tokens.border),
        boxShadow: fullBleed ? tokens.sectionShadow : tokens.cardShadow,
      ),
      clipBehavior: fullBleed ? Clip.none : Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeCam != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeCam.displayName.isNotEmpty
                              ? activeCam.displayName
                              : 'Lokasi Kamera',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.title,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (distanceLabel != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.primarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.near_me_rounded,
                                      size: 11,
                                      color: tokens.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      distanceLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: tokens.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                activeCam.address.isNotEmpty
                                    ? activeCam.address
                                    : activeCam.displayCategory,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tokens.caption.copyWith(
                                  fontSize: 12,
                                  color: tokens.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SoftIconAction(
                    icon: Icons.map_outlined,
                    tooltip: 'Lihat lokasi di peta',
                    color: tokens.primary,
                    background: tokens.primarySoft,
                    onTap: widget.onOpenMap,
                  ),
                  const SizedBox(width: 6),
                  _SoftIconAction(
                    icon: Icons.keyboard_arrow_down_rounded,
                    tooltip: _expanded
                        ? 'Sembunyikan detail lokasi'
                        : 'Lihat detail lokasi',
                    color: tokens.textSecondary,
                    background: tokens.surfaceSubtle,
                    rotationTurns: _expanded ? 0.5 : 0.0,
                    onTap: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ),

          if (activeCam != null)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Divider(height: 1, color: tokens.divider),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MetadataGrid(
                          camera: activeCam,
                          tokens: tokens,
                          onCopyCoords: () => _copyCoords(context, activeCam),
                        ),
                        if (activeCam.hasValidCoords) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  CctvLocalService.openInExternalMaps(
                                      activeCam),
                              icon: Icon(
                                Icons.directions_outlined,
                                size: 17,
                                color: tokens.primary,
                              ),
                              label: Text(
                                'Buka Rute di Maps',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: tokens.primary.withValues(alpha: 0.3),
                                ),
                                backgroundColor: tokens.primarySoft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    CctvTokens.radiusMd,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Divider(height: 1, color: tokens.divider),

          _OperationalStatusStrip(
            controller: widget.controller,
            tokens: tokens,
            onRefreshStatus: widget.onRefreshStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPanel(
    BuildContext context,
    CctvTokens tokens,
    CctvCamera? activeCam,
  ) {
    final distanceLabel = widget.controller.distanceLabelFor(activeCam);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(CctvTokens.radiusLg),
        border: Border.all(color: tokens.border),
        boxShadow: tokens.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tokens.surfaceSubtle.withValues(alpha: 0.65),
            child: _OperationalStatusStrip(
              controller: widget.controller,
              tokens: tokens,
              onRefreshStatus: widget.onRefreshStatus,
            ),
          ),

          Divider(height: 1, color: tokens.divider),

          if (activeCam != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Lokasi Pemantauan', style: tokens.caption),
                      if (distanceLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tokens.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me_rounded,
                                  size: 11, color: tokens.primary),
                              const SizedBox(width: 3),
                              Text(
                                distanceLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    activeCam.displayName.isNotEmpty
                        ? activeCam.displayName
                        : 'Lokasi Kamera',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.title.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeCam.address.isNotEmpty
                        ? activeCam.address
                        : 'Alamat belum tersedia',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.body,
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: tokens.divider),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: _MetadataGrid(
                camera: activeCam,
                tokens: tokens,
                onCopyCoords: () => _copyCoords(context, activeCam),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: CctvTokens.minTouchTarget,
                      child: FilledButton.icon(
                        onPressed: widget.onOpenMap,
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text(
                          'Lihat di Peta',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: tokens.primary,
                          foregroundColor: tokens.primaryOnFill,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(CctvTokens.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (activeCam.hasValidCoords) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Buka rute di Maps',
                      child: SizedBox(
                        width: CctvTokens.minTouchTarget,
                        height: CctvTokens.minTouchTarget,
                        child: Material(
                          color: tokens.primarySoft,
                          borderRadius:
                              BorderRadius.circular(CctvTokens.radiusMd),
                          child: InkWell(
                            onTap: () =>
                                CctvLocalService.openInExternalMaps(activeCam),
                            borderRadius:
                                BorderRadius.circular(CctvTokens.radiusMd),
                            child: Icon(
                              Icons.directions_outlined,
                              size: 20,
                              color: tokens.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoftIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color background;
  final double rotationTurns;
  final VoidCallback onTap;

  const _SoftIconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.background,
    this.rotationTurns = 0.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CctvTokens.radiusMd),
          child: SizedBox(
            width: 40,
            height: 40,
            child: AnimatedRotation(
              turns: rotationTurns,
              duration: const Duration(milliseconds: 180),
              child: Icon(icon, size: 20, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationalStatusStrip extends StatelessWidget {
  final CctvController controller;
  final CctvTokens tokens;
  final VoidCallback onRefreshStatus;

  const _OperationalStatusStrip({
    required this.controller,
    required this.tokens,
    required this.onRefreshStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    style: tokens.caption.copyWith(fontSize: 12),
                    children: [
                      const TextSpan(text: 'Total '),
                      TextSpan(
                        text: '${controller.cameras.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusMetric(
                  dotColor: tokens.online,
                  textColor: tokens.onlineText,
                  count: controller.onlineCount,
                  label: 'Online',
                ),
                _StatusMetric(
                  dotColor: tokens.offline,
                  textColor: tokens.offlineText,
                  count: controller.offlineCount,
                  label: 'Offline',
                ),
                if (controller.lastCheckedLabel.isNotEmpty)
                  Text(
                    controller.lastCheckedLabel,
                    style: tokens.caption.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
          if (isNarrow)
            IconButton(
              onPressed: controller.isCheckingAlive ? null : onRefreshStatus,
              tooltip: 'Cek Status',
              icon: controller.isCheckingAlive
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.primary,
                      ),
                    )
                  : Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: tokens.primary,
                    ),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            )
          else
            TextButton.icon(
              onPressed: controller.isCheckingAlive ? null : onRefreshStatus,
              icon: controller.isCheckingAlive
                  ? SizedBox(
                      width: 13,
                      height: 13,
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
                controller.isCheckingAlive ? 'Cek...' : 'Cek Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: controller.isCheckingAlive
                      ? tokens.textMuted
                      : tokens.primary,
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CctvTokens.radiusSm),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  final Color dotColor;
  final Color textColor;
  final int count;
  final String label;

  const _StatusMetric({
    required this.dotColor,
    required this.textColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 12, color: textColor),
            children: [
              TextSpan(
                text: '$count ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: label),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetadataGrid extends StatelessWidget {
  final CctvCamera camera;
  final CctvTokens tokens;
  final VoidCallback onCopyCoords;

  const _MetadataGrid({
    required this.camera,
    required this.tokens,
    required this.onCopyCoords,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetadataCell(
                label: 'Kategori',
                value: camera.displayCategory,
                tokens: tokens,
                valueColor: tokens.primary,
                bold: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: camera.hasValidCoords ? onCopyCoords : null,
                child: _MetadataCell(
                  label: 'Koordinat GPS',
                  value: camera.hasValidCoords
                      ? camera.coordsLabel
                      : 'Belum tersedia',
                  tokens: tokens,
                  valueColor: camera.hasValidCoords
                      ? tokens.textPrimary
                      : tokens.textMuted,
                  monospace: camera.hasValidCoords,
                  trailingIcon: camera.hasValidCoords ? Icons.copy_rounded : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetadataCell(
                label: 'Kecamatan',
                value: camera.kecamatanNama ?? 'Belum terpetakan',
                tokens: tokens,
                valueColor: camera.kecamatanNama != null
                    ? tokens.textPrimary
                    : tokens.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetadataCell(
                label: 'Kelurahan',
                value: camera.kelurahanNama ?? 'Belum terpetakan',
                tokens: tokens,
                valueColor: camera.kelurahanNama != null
                    ? tokens.textPrimary
                    : tokens.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetadataCell extends StatelessWidget {
  final String label;
  final String value;
  final CctvTokens tokens;
  final Color valueColor;
  final bool bold;
  final bool monospace;
  final IconData? trailingIcon;

  const _MetadataCell({
    required this.label,
    required this.value,
    required this.tokens,
    required this.valueColor,
    this.bold = false,
    this.monospace = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tokens.caption),
        const SizedBox(height: 3),
        Row(
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                  color: valueColor,
                  fontFamily: monospace ? 'monospace' : null,
                  fontFeatures: monospace
                      ? const [FontFeature.tabularFigures()]
                      : null,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, size: 13, color: tokens.textMuted),
            ],
          ],
        ),
      ],
    );
  }
}
