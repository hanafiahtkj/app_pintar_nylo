import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '/config/app.dart';
import '/modules/cctv/models/cctv_camera.dart';
import '/modules/cctv/pages/cctv_fullscreen_player_page.dart';
import '/modules/cctv/widgets/cctv_theme_tokens.dart';

enum _StreamState { idle, loading, playing, error }

class CctvPlayerStage extends StatefulWidget {
  final CctvCamera? camera;
  final bool? isAlive;
  final ValueChanged<String> onStreamReady;
  final bool Function() onStreamError;

  /// When `true` (tablet landscape / desktop), the player uses its natural 16:9
  /// aspect ratio with rounded corners instead of clamping mobile height.
  final bool isDesktopStage;

  /// When `false` (e.g. another route with its own inline player is on top),
  /// the player releases its active [VideoPlayerController] so two streams do
  /// not decode and compete for bandwidth/CPU simultaneously.
  final bool isActive;

  const CctvPlayerStage({
    super.key,
    required this.camera,
    required this.isAlive,
    required this.onStreamReady,
    required this.onStreamError,
    this.isDesktopStage = false,
    this.isActive = true,
  });

  @override
  State<CctvPlayerStage> createState() => _CctvPlayerStageState();
}

class _CctvPlayerStageState extends State<CctvPlayerStage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  _StreamState _streamState = _StreamState.idle;
  String? _errorMsg;
  bool _isMuted = true;
  bool _showControls = false;
  bool _pausedByUser = false;
  bool _inFullscreen = false;
  int _loadEpoch = 0;
  Timer? _hideControlsTimer;
  bool _lastIsBuffering = false;
  bool _lastIsPlaying = false;
  bool _lastIsInitialized = false;
  double _lastAspectRatio = 0;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    if (widget.isActive && widget.camera != null) {
      unawaited(_loadCamera(widget.camera!));
    }
  }

  @override
  void didUpdateWidget(covariant CctvPlayerStage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.isActive && oldWidget.isActive) {
      _loadEpoch++;
      _hideControlsTimer?.cancel();
      _streamState = _StreamState.idle;
      _errorMsg = null;
      _showControls = false;
      unawaited(_disposeController());
      return;
    }

    if (widget.isActive && !oldWidget.isActive) {
      if (widget.camera != null) {
        unawaited(_loadCamera(widget.camera!));
      } else {
        unawaited(_disposeController());
      }
      return;
    }

    if (!widget.isActive) return;

    if (widget.camera?.id != oldWidget.camera?.id ||
        widget.camera?.videoUrl != oldWidget.camera?.videoUrl) {
      if (widget.camera != null) {
        unawaited(_loadCamera(widget.camera!));
      } else {
        unawaited(_disposeController());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_pausedByUser && _streamState == _StreamState.playing) {
        controller.play();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _pulseController.dispose();
    _loadEpoch++;
    final controller = _videoController;
    _videoController = null;
    controller?.removeListener(_onVideoUpdate);
    controller?.dispose();
    super.dispose();
  }

  Future<void> _disposeController() async {
    final old = _videoController;
    _videoController = null;
    if (old != null) {
      old.removeListener(_onVideoUpdate);
      await old.dispose();
    }
  }

  Future<void> _loadCamera(CctvCamera camera) async {
    final epoch = ++_loadEpoch;
    _pausedByUser = false;
    _hideControlsTimer?.cancel();

    final url = camera.videoUrl?.trim();
    if (url == null || url.isEmpty) {
      await _disposeController();
      if (!mounted || epoch != _loadEpoch) return;
      final advanced = widget.onStreamError();
      if (advanced) return;
      setState(() {
        _streamState = _StreamState.error;
        _errorMsg = 'URL siaran kamera belum tersedia.';
      });
      return;
    }

    setState(() {
      _streamState = _StreamState.loading;
      _errorMsg = null;
      _showControls = false;
    });

    await _disposeController();
    if (!mounted || epoch != _loadEpoch) return;

    final origin = AppConfig.cctvApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final isHls = url.toLowerCase().contains('.m3u8');
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      formatHint: isHls ? VideoFormat.hls : null,
      httpHeaders: {
        'Origin': origin,
        'Referer': '$origin/',
      },
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    try {
      await controller.initialize().timeout(const Duration(seconds: 12));
      if (!mounted || epoch != _loadEpoch) {
        await controller.dispose();
        return;
      }

      await controller.setVolume(_isMuted ? 0.0 : 1.0);
      _lastIsBuffering = controller.value.isBuffering;
      _lastIsPlaying = controller.value.isPlaying;
      _lastIsInitialized = controller.value.isInitialized;
      _lastAspectRatio = controller.value.aspectRatio;
      controller.addListener(_onVideoUpdate);
      _videoController = controller;
      await controller.play();

      if (!mounted || epoch != _loadEpoch) return;
      setState(() {
        _streamState = _StreamState.playing;
        _errorMsg = null;
        // Briefly reveal controls so users discover mute & fullscreen actions
        _showControls = true;
      });
      _scheduleHideControls(duration: const Duration(milliseconds: 2500));
      widget.onStreamReady(camera.id);
    } catch (_) {
      await controller.dispose();
      if (!mounted || epoch != _loadEpoch) return;

      final advanced = widget.onStreamError();
      if (advanced) return;

      setState(() {
        _streamState = _StreamState.error;
        _errorMsg =
            'Siaran gagal dimuat karena gangguan jaringan atau kamera sedang offline.';
      });
    }
  }

  void _onVideoUpdate() {
    final controller = _videoController;
    if (!mounted || controller == null) return;

    if (controller.value.hasError && _streamState != _StreamState.error) {
      final advanced = widget.onStreamError();
      if (advanced) return;
      setState(() {
        _streamState = _StreamState.error;
        _errorMsg =
            'Siaran terputus karena gangguan jaringan atau kamera sedang offline.';
      });
      return;
    }
    if (!_inFullscreen) {
      final val = controller.value;
      if (val.isBuffering != _lastIsBuffering ||
          val.isPlaying != _lastIsPlaying ||
          val.isInitialized != _lastIsInitialized ||
          val.aspectRatio != _lastAspectRatio) {
        _lastIsBuffering = val.isBuffering;
        _lastIsPlaying = val.isPlaying;
        _lastIsInitialized = val.isInitialized;
        _lastAspectRatio = val.aspectRatio;
        setState(() {});
      }
    }
  }

  void _retryStream() {
    final cam = widget.camera;
    if (cam == null) return;
    unawaited(_loadCamera(cam));
  }

  void _toggleControls() {
    if (_streamState != _StreamState.playing) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _scheduleHideControls({Duration duration = const Duration(seconds: 3)}) {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(duration, () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      _pausedByUser = true;
      controller.pause();
    } else {
      _pausedByUser = false;
      controller.play();
    }
    _scheduleHideControls();
  }

  void _toggleMute() {
    final controller = _videoController;
    _isMuted = !_isMuted;
    controller?.setVolume(_isMuted ? 0.0 : 1.0);
    setState(() {});
    _scheduleHideControls();
  }

  Future<void> _openFullscreen() async {
    final controller = _videoController;
    final cam = widget.camera;
    if (controller == null || !controller.value.isInitialized || cam == null) {
      return;
    }
    _inFullscreen = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CctvFullscreenPlayerPage(
          controller: controller,
          camera: cam,
          isAlive: widget.isAlive,
          initialMuted: _isMuted,
          onMuteChanged: (muted) {
            if (mounted) {
              setState(() => _isMuted = muted);
            }
          },
        ),
      ),
    );
    _inFullscreen = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CctvTokens.of(context);
    final controller = _videoController;
    final isInitialized = controller != null && controller.value.isInitialized;
    final isBuffering = isInitialized && controller.value.isBuffering;
    final camName = widget.camera?.displayName ?? '';

    final playerContent = AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),

            if (isInitialized && _streamState == _StreamState.playing)
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio > 0
                      ? controller.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(controller),
                ),
              ),

            // Loading / Buffering overlay with active camera name
            if (_streamState == _StreamState.loading || isBuffering)
              Container(
                color: _streamState == _StreamState.loading
                    ? const Color(0xBF090B10)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: tokens.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (camName.isNotEmpty)
                        Text(
                          camName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 2),
                      const Text(
                        'Memuat siaran langsung...',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Error Overlay
            if (_streamState == _StreamState.error)
              Container(
                color: const Color(0xE6090B10),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam_off_outlined,
                          color: tokens.offline,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          camName.isNotEmpty
                              ? camName
                              : 'Siaran Tidak Dapat Diputar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _errorMsg ?? '',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: FilledButton.icon(
                            onPressed: _retryStream,
                            icon: const Icon(Icons.refresh_rounded, size: 17),
                            label: const Text(
                              'Coba Muat Ulang',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: tokens.primary,
                              foregroundColor: tokens.primaryOnFill,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  CctvTokens.radiusSm,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Top-right LIVE / OFFLINE status badge
            Positioned(
              top: 10,
              right: 10,
              child: _LiveStatusBadge(
                isAlive: widget.isAlive,
                pulseAnimation: _pulseController,
              ),
            ),

            // Bottom playback controls overlay
            if (isInitialized && _streamState == _StreamState.playing)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _togglePlayPause,
                            icon: Icon(
                              controller.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            tooltip: controller.value.isPlaying
                                ? 'Jeda'
                                : 'Putar',
                          ),
                          IconButton(
                            onPressed: _toggleMute,
                            icon: Icon(
                              _isMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: _isMuted ? 'Aktifkan suara' : 'Bisukan',
                          ),
                          IconButton(
                            onPressed: _retryStream,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'Muat ulang siaran',
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _openFullscreen,
                            icon: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            tooltip: 'Layar penuh',
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

    if (widget.isDesktopStage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(CctvTokens.radiusLg),
        child: Container(
          color: Colors.black,
          child: playerContent,
        ),
      );
    }

    // Mobile / Tablet portrait: natural 16:9 bounded only on very tall/short screens
    final maxMobileHeight = MediaQuery.sizeOf(context).height * 0.34;
    return Container(
      width: double.infinity,
      color: Colors.black,
      constraints: BoxConstraints(
        maxHeight: maxMobileHeight.clamp(180.0, 360.0),
      ),
      child: playerContent,
    );
  }
}

class _LiveStatusBadge extends StatelessWidget {
  final bool? isAlive;
  final Animation<double> pulseAnimation;

  const _LiveStatusBadge({
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
