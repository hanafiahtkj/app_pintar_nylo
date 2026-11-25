import 'dart:math' as math;
import 'package:flutter/material.dart';
import '/modules/cctv/models/cctv_camera_group.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

class CctvMapMarker extends StatelessWidget {
  final CctvCameraGroup group;
  final bool isActive;
  final bool? aliveStatus;
  final CctvTokens tokens;
  final Animation<double> rippleAnimation;
  final VoidCallback onTap;

  const CctvMapMarker({
    super.key,
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

    if (isActive) {
      return _ActiveRadarPin(
        group: group,
        isOffline: isOffline,
        tokens: tokens,
        rippleAnimation: rippleAnimation,
        onTap: onTap,
      );
    }

    final Color bg;
    final Color border;
    final Color iconColor;

    if (isOffline) {
      bg = tokens.offline;
      border = tokens.offline;
      iconColor = Colors.white;
    } else {
      bg = tokens.surfaceElevated;
      border = tokens.border;
      iconColor = tokens.textSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.videocam_rounded,
              size: 16,
              color: iconColor,
            ),
          ),
          if (group.isMultiCamera)
            Positioned(
              top: 2,
              right: 2,
              child: _CameraCountBadge(
                count: group.cameras.length,
                tokens: tokens,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveRadarPin extends StatelessWidget {
  final CctvCameraGroup group;
  final bool isOffline;
  final CctvTokens tokens;
  final Animation<double> rippleAnimation;
  final VoidCallback onTap;

  const _ActiveRadarPin({
    required this.group,
    required this.isOffline,
    required this.tokens,
    required this.rippleAnimation,
    required this.onTap,
  });

  Widget _buildSonarRing(double phase, Color accent) {
    final eased = Curves.easeOut.transform(phase);
    final scale = 0.85 + (eased * 1.85);
    final fade = (1.0 - eased).clamp(0.0, 1.0);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: fade * 0.22),
          border: Border.all(
            color: accent.withValues(alpha: fade * 0.58),
            width: 1.6,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = isOffline ? tokens.offline : tokens.primary;
    final iconColor = isOffline ? Colors.white : tokens.primaryOnFill;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: rippleAnimation,
        builder: (context, child) {
          final t = rippleAnimation.value;
          final phase1 = t;
          final phase2 = (t + 0.5) % 1.0;
          final breath = 1.0 + (math.sin(t * math.pi * 2) * 0.035);

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Staggered dual sonar waves
              _buildSonarRing(phase1, accent),
              _buildSonarRing(phase2, accent),

              // Subtle anchor dot at exact coordinate
              Positioned(
                bottom: 20,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.35),
                  ),
                ),
              ),

              // Main active pin + pointer + count badge
              Transform.scale(
                scale: breath,
                child: child,
              ),
            ],
          );
        },
        child: SizedBox(
          width: 48,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Teardrop pointer tip
              Positioned(
                bottom: 2,
                child: CustomPaint(
                  size: const Size(12, 7),
                  painter: _PinPointerPainter(
                    fillColor: Colors.white,
                    innerColor: accent,
                  ),
                ),
              ),
              // Main circular pin with thick white rim
              Positioned(
                top: 3,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.42),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.videocam_rounded,
                    size: 19,
                    color: iconColor,
                  ),
                ),
              ),
              if (group.isMultiCamera)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _CameraCountBadge(
                    count: group.cameras.length,
                    tokens: tokens,
                    backgroundColor: const Color(0xFF0F172A),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraCountBadge extends StatelessWidget {
  final int count;
  final CctvTokens tokens;
  final Color? backgroundColor;

  const _CameraCountBadge({
    required this.count,
    required this.tokens,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? tokens.primary,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            color: backgroundColor != null ? Colors.white : tokens.primaryOnFill,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _PinPointerPainter extends CustomPainter {
  final Color fillColor;
  final Color innerColor;

  const _PinPointerPainter({
    required this.fillColor,
    required this.innerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(
      outerPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    final innerPath = Path()
      ..moveTo(2.4, 0)
      ..lineTo(size.width - 2.4, 0)
      ..lineTo(size.width / 2, size.height - 2.2)
      ..close();

    canvas.drawPath(
      innerPath,
      Paint()
        ..color = innerColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _PinPointerPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.innerColor != innerColor;
  }
}
