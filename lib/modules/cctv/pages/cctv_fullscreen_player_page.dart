import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '/modules/cctv/models/cctv_camera.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

class CctvFullscreenPlayerPage extends StatefulWidget {
  final VideoPlayerController controller;
  final CctvCamera camera;
  final bool? isAlive;
  final bool initialMuted;
  final ValueChanged<bool> onMuteChanged;

  const CctvFullscreenPlayerPage({
    super.key,
    required this.controller,
    required this.camera,
    required this.isAlive,
    required this.initialMuted,
    required this.onMuteChanged,
  });

  @override
  State<CctvFullscreenPlayerPage> createState() =>
      _CctvFullscreenPlayerPageState();
}

class _CctvFullscreenPlayerPageState extends State<CctvFullscreenPlayerPage>
    with SingleTickerProviderStateMixin {
  bool _showControls = true;
  late bool _isMuted;
  Timer? _hideTimer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialMuted;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    widget.controller.addListener(_onPlayerUpdate);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pulseController.dispose();
    widget.controller.removeListener(_onPlayerUpdate);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Restore default system orientations so landscape tablets aren't forced to portrait
    SystemChrome.setPreferredOrientations(const []);
    super.dispose();
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHide();
  }

  void _togglePlayPause() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
    _scheduleHide();
  }

  void _toggleMute() {
    _isMuted = !_isMuted;
    widget.controller.setVolume(_isMuted ? 0.0 : 1.0);
    widget.onMuteChanged(_isMuted);
    setState(() {});
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CctvTokens.of(context);
    final value = widget.controller.value;
    final aspectRatio =
        value.isInitialized && value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!value.hasError)
              Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(widget.controller),
                ),
              ),

            if (value.isBuffering && !value.hasError)
              Center(
                child: CircularProgressIndicator(
                  color: tokens.primary,
                  strokeWidth: 2.5,
                ),
              ),

            if (value.hasError)
              Container(
                color: const Color(0xE6090B10),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_outlined,
                          color: tokens.offline,
                          size: 32,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.camera.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Siaran terputus karena gangguan jaringan atau kamera sedang offline.',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: CctvTokens.minTouchTarget,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                            label: const Text(
                              'Kembali ke Halaman CCTV',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: tokens.primary,
                              foregroundColor: tokens.primaryOnFill,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(CctvTokens.radiusMd),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (!value.hasError)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xB3000000),
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xCC000000),
                        ],
                        stops: [0.0, 0.25, 0.72, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Keluar layar penuh',
                                  constraints: const BoxConstraints(
                                    minWidth: CctvTokens.minTouchTarget,
                                    minHeight: CctvTokens.minTouchTarget,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.camera.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (widget.camera.address.isNotEmpty)
                                        Text(
                                          widget.camera.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _StatusBadge(
                                  isAlive: widget.isAlive,
                                  pulseAnimation: _pulseController,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _togglePlayPause,
                                  icon: Icon(
                                    value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  tooltip: value.isPlaying ? 'Jeda' : 'Putar',
                                  constraints: const BoxConstraints(
                                    minWidth: CctvTokens.minTouchTarget,
                                    minHeight: CctvTokens.minTouchTarget,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _toggleMute,
                                  icon: Icon(
                                    _isMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  tooltip: _isMuted
                                      ? 'Aktifkan suara'
                                      : 'Bisukan suara',
                                  constraints: const BoxConstraints(
                                    minWidth: CctvTokens.minTouchTarget,
                                    minHeight: CctvTokens.minTouchTarget,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.fullscreen_exit_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  tooltip: 'Keluar layar penuh',
                                  constraints: const BoxConstraints(
                                    minWidth: CctvTokens.minTouchTarget,
                                    minHeight: CctvTokens.minTouchTarget,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool? isAlive;
  final Animation<double> pulseAnimation;

  const _StatusBadge({
    required this.isAlive,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final Color textColor;
    final Color borderColor;
    final String label;

    if (isAlive == true) {
      dotColor = const Color(0xFF34D399);
      textColor = const Color(0xFF6EE7B7);
      borderColor = const Color(0x6610B981);
      label = 'LIVE';
    } else if (isAlive == false) {
      dotColor = const Color(0xFFFB7185);
      textColor = const Color(0xFFFDA4AF);
      borderColor = const Color(0x66F43F5E);
      label = 'OFFLINE';
    } else {
      dotColor = const Color(0xFF94A3B8);
      textColor = const Color(0xFFE2E8F0);
      borderColor = const Color(0x26FFFFFF);
      label = 'Memeriksa';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC090B10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAlive == true)
            FadeTransition(
              opacity: Tween<double>(begin: 0.35, end: 1.0)
                  .animate(pulseAnimation),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
