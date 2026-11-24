import 'dart:async';
import 'package:flutter/material.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

/// Soft Sonar Pulse + Layout Skeleton loading view shown while locating the
/// nearest CCTV camera and fetching the camera list, categories, and wilayah.
class CctvLoadingView extends StatefulWidget {
  const CctvLoadingView({super.key});

  @override
  State<CctvLoadingView> createState() => _CctvLoadingViewState();
}

class _CctvLoadingViewState extends State<CctvLoadingView>
    with TickerProviderStateMixin {
  late final AnimationController _sonarController;
  late final AnimationController _shimmerController;
  Timer? _phaseTimer;
  int _messageIndex = 0;

  static const List<String> _messages = [
    'Mencari titik CCTV terdekat...',
    'Menyiapkan peta & daftar kamera...',
  ];

  @override
  void initState() {
    super.initState();
    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _phaseTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) {
        setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
      }
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _sonarController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CctvTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= CctvTokens.desktopBreakpoint;
        final isCompactMobile = width < CctvTokens.compactMobileBreakpoint;

        if (isDesktop) {
          return _buildDesktopSkeleton(tokens);
        }
        return _buildMobileSkeleton(tokens, isFullBleed: isCompactMobile);
      },
    );
  }

  Widget _buildSonarStage(
    CctvTokens tokens, {
    required bool rounded,
  }) {
    final content = AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.isDark
              ? const Color(0xFF1C1728)
              : const Color(0xFFEEF4FC),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Concentric soft sonar waves
            AnimatedBuilder(
              animation: _sonarController,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(220, 220),
                  painter: _SonarRingsPainter(
                    progress: _sonarController.value,
                    color: tokens.primary,
                  ),
                );
              },
            ),

            // Center glowing camera/location hub
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1.05).animate(
                    CurvedAnimation(
                      parent: _sonarController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: tokens.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tokens.primary.withValues(alpha: 0.32),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: tokens.primaryOnFill,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _messages[_messageIndex],
                    key: ValueKey<int>(_messageIndex),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pemantauan CCTV Kota Banjarmasin',
                  style: tokens.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (rounded) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(CctvTokens.radiusLg),
        child: content,
      );
    }

    final maxMobileHeight = MediaQuery.sizeOf(context).height * 0.34;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: maxMobileHeight.clamp(180.0, 360.0),
      ),
      child: content,
    );
  }

  Widget _buildMobileSkeleton(CctvTokens tokens, {required bool isFullBleed}) {
    return Column(
      children: [
        _buildSonarStage(tokens, rounded: false),
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: isFullBleed
                ? const EdgeInsets.only(bottom: 24)
                : const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Camera Bar Skeleton
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    borderRadius: isFullBleed
                        ? BorderRadius.zero
                        : BorderRadius.circular(CctvTokens.radiusLg),
                    border: isFullBleed
                        ? Border(bottom: BorderSide(color: tokens.border))
                        : Border.all(color: tokens.border),
                    boxShadow:
                        isFullBleed ? tokens.sectionShadow : tokens.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ShimmerBox(
                                  controller: _shimmerController,
                                  tokens: tokens,
                                  height: 16,
                                  width: 200,
                                ),
                                const SizedBox(height: 8),
                                _ShimmerBox(
                                  controller: _shimmerController,
                                  tokens: tokens,
                                  height: 12,
                                  width: 150,
                                ),
                              ],
                            ),
                          ),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 40,
                            width: 40,
                            radius: CctvTokens.radiusMd,
                          ),
                          const SizedBox(width: 6),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 40,
                            width: 40,
                            radius: CctvTokens.radiusMd,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, color: tokens.divider),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 12,
                            width: 64,
                          ),
                          const SizedBox(width: 12),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 12,
                            width: 72,
                          ),
                          const Spacer(),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 12,
                            width: 64,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isFullBleed ? 10 : 14),

                // Filter + Map Skeleton
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    borderRadius: isFullBleed
                        ? BorderRadius.zero
                        : BorderRadius.circular(CctvTokens.radiusLg),
                    border: isFullBleed
                        ? Border.symmetric(
                            horizontal: BorderSide(color: tokens.border),
                          )
                        : Border.all(color: tokens.border),
                    boxShadow:
                        isFullBleed ? tokens.sectionShadow : tokens.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pill chips skeleton
                      Row(
                        children: [
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 36,
                            width: 88,
                            radius: CctvTokens.radiusPill,
                          ),
                          const SizedBox(width: 8),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 36,
                            width: 78,
                            radius: CctvTokens.radiusPill,
                          ),
                          const SizedBox(width: 8),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 36,
                            width: 76,
                            radius: CctvTokens.radiusPill,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ShimmerBox(
                        controller: _shimmerController,
                        tokens: tokens,
                        height: 44,
                        width: double.infinity,
                        radius: CctvTokens.radiusMd,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ShimmerBox(
                              controller: _shimmerController,
                              tokens: tokens,
                              height: 44,
                              width: double.infinity,
                              radius: CctvTokens.radiusMd,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ShimmerBox(
                              controller: _shimmerController,
                              tokens: tokens,
                              height: 44,
                              width: double.infinity,
                              radius: CctvTokens.radiusMd,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ShimmerBox(
                        controller: _shimmerController,
                        tokens: tokens,
                        height: 220,
                        width: double.infinity,
                        radius: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSkeleton(CctvTokens tokens) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: CctvTokens.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: _buildSonarStage(tokens, rounded: true),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 360,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: tokens.surfaceElevated,
                        borderRadius:
                            BorderRadius.circular(CctvTokens.radiusLg),
                        border: Border.all(color: tokens.border),
                        boxShadow: tokens.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 14,
                            width: 180,
                          ),
                          const SizedBox(height: 20),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 18,
                            width: 220,
                          ),
                          const SizedBox(height: 8),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 13,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 24),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 54,
                            width: double.infinity,
                            radius: CctvTokens.radiusMd,
                          ),
                          const Spacer(),
                          _ShimmerBox(
                            controller: _shimmerController,
                            tokens: tokens,
                            height: 44,
                            width: double.infinity,
                            radius: CctvTokens.radiusMd,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(CctvTokens.radiusLg),
                  border: Border.all(color: tokens.border),
                  boxShadow: tokens.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _ShimmerBox(
                          controller: _shimmerController,
                          tokens: tokens,
                          height: 36,
                          width: 92,
                          radius: CctvTokens.radiusPill,
                        ),
                        const SizedBox(width: 8),
                        _ShimmerBox(
                          controller: _shimmerController,
                          tokens: tokens,
                          height: 36,
                          width: 86,
                          radius: CctvTokens.radiusPill,
                        ),
                        const SizedBox(width: 8),
                        _ShimmerBox(
                          controller: _shimmerController,
                          tokens: tokens,
                          height: 36,
                          width: 86,
                          radius: CctvTokens.radiusPill,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ShimmerBox(
                      controller: _shimmerController,
                      tokens: tokens,
                      height: 300,
                      width: double.infinity,
                      radius: CctvTokens.radiusMd,
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

class _SonarRingsPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _SonarRingsPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 14);
    final maxRadius = size.width * 0.48;

    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1.0;
      final radius = 26 + (maxRadius - 26) * Curves.easeOut.transform(phase);
      final opacity = (1.0 - phase) * 0.28;

      final fillPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);

      final strokePaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SonarRingsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _ShimmerBox extends StatelessWidget {
  final AnimationController controller;
  final CctvTokens tokens;
  final double height;
  final double width;
  final double radius;

  const _ShimmerBox({
    required this.controller,
    required this.tokens,
    required this.height,
    required this.width,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final base = tokens.isDark
        ? const Color(0xFF2D263C)
        : const Color(0xFFE9EFF6);
    final highlight = tokens.isDark
        ? const Color(0xFF3A324D)
        : const Color(0xFFF6F9FC);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final slide = (controller.value * 2) - 1;
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + slide, 0),
              end: Alignment(1.0 + slide, 0),
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
        );
      },
    );
  }
}
