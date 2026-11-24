import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
  /// the player stops its active stream so two streams do not decode and
  /// compete for bandwidth/CPU simultaneously.
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
  /// Single warm libmpv Player + VideoController shared across CCTV route
  /// transitions (CCTV -> Back -> CCTV and Fullscreen Map) to prevent Android
  /// MediaCodec / VideoOutputManager dispose-recreate deadlocks and make
  /// reopening CCTV instantaneous.
  static Player? _sharedPlayer;
  static VideoController? _sharedVideoController;
  static Future<Player>? _sharedInitFuture;
  static _CctvPlayerStageState? _activeOwner;

  Player? _player;
  VideoController? _videoController;
  final List<StreamSubscription<dynamic>> _playerSubs = [];

  _StreamState _streamState = _StreamState.idle;
  String? _errorMsg;
  bool _isMuted = true;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _awaitingOpen = false;
  bool _hasVideoFrame = false;
  bool _readyReported = false;
  Duration? _initialPosAfterOpen;
  bool _showControls = false;
  bool _pausedByUser = false;
  bool _inFullscreen = false;
  int _loadEpoch = 0;
  String? _activeLoadCameraId;
  Timer? _hideControlsTimer;
  Timer? _loadTimeoutTimer;

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
      _loadTimeoutTimer?.cancel();
      _hideControlsTimer?.cancel();
      _activeLoadCameraId = null;
      _hasVideoFrame = false;
      _readyReported = false;
      _isPlaying = false;
      _isBuffering = false;
      _streamState = _StreamState.idle;
      _errorMsg = null;
      _showControls = false;
      if (_activeOwner == this) {
        _activeOwner = null;
        final player = _sharedPlayer;
        if (player != null) {
          unawaited(player.pause());
          unawaited(player.open(const Playlist([]), play: false));
        }
      }
      return;
    }

    if (widget.isActive && !oldWidget.isActive) {
      if (widget.camera != null) {
        unawaited(_loadCamera(widget.camera!));
      } else {
        unawaited(_player?.pause());
      unawaited(_player?.open(const Playlist([]), play: false));
      }
      return;
    }

    if (!widget.isActive) return;

    if (widget.camera?.id != oldWidget.camera?.id ||
        widget.camera?.videoUrl != oldWidget.camera?.videoUrl) {
      if (widget.camera != null) {
        unawaited(_loadCamera(widget.camera!));
      } else {
        _loadEpoch++;
        _loadTimeoutTimer?.cancel();
        unawaited(_player?.pause());
      unawaited(_player?.open(const Playlist([]), play: false));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final player = _player;
    if (player == null || !widget.isActive) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        unawaited(player.pause());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_pausedByUser && _streamState == _StreamState.playing) {
        unawaited(player.play());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    _pulseController.dispose();
    _loadEpoch++;
    for (final sub in _playerSubs) {
      unawaited(sub.cancel());
    }
    _playerSubs.clear();
    final isOwner = _activeOwner == this;
    if (isOwner) {
      _activeOwner = null;
    }
    _player = null;
    _videoController = null;
    if (isOwner) {
      final player = _sharedPlayer;
      if (player != null) {
        // Pause & clear media immediately without tearing down native libmpv/MediaCodec
        unawaited(player.pause());
        unawaited(player.open(const Playlist([]), play: false));
      }
    }
    super.dispose();
  }

  static bool _isFatalStreamError(String rawError) {
    final lower = rawError.toLowerCase();
    // Ignore transient libmpv / mediacodec_embed surface-attach & live-seek warnings
    if (lower.contains('seek') ||
        lower.contains('could not open codec') ||
        lower.contains('audio') ||
        lower.contains('vo')) {
      return false;
    }
    return lower.contains('404') ||
        lower.contains('403') ||
        lower.contains('401') ||
        lower.contains('500') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('connection refused') ||
        lower.contains('name or service not known') ||
        lower.contains('no address associated') ||
        lower.contains('timed out') ||
        lower.contains('failed to open');
  }

  static Future<Player> _getOrCreateSharedPlayer() {
    final existing = _sharedPlayer;
    if (existing != null && _sharedVideoController != null) {
      return Future<Player>.value(existing);
    }
    final inFlight = _sharedInitFuture;
    if (inFlight != null) return inFlight;

    final future = () async {
      final player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 4 * 1024 * 1024,
          protocolWhitelist: [
            'http',
            'https',
            'tcp',
            'tls',
            'crypto',
            'hls',
            'file',
            'data',
          ],
        ),
      );

      final platform = player.platform;
      if (platform is NativePlayer) {
        await platform.setProperty('cache', 'yes');
        await platform.setProperty('demuxer-readahead-secs', '1');
        await platform.setProperty('cache-secs', '2');
        await platform.setProperty('network-timeout', '10');
        await platform.setProperty('hls-bitrate', 'max');
        await platform.setProperty('demuxer-lavf-o', 'live_start_index=-1');
      }

      final videoController = VideoController(
        player,
        configuration: !kIsWeb && Platform.isAndroid
            ? const VideoControllerConfiguration(
                vo: 'mediacodec_embed',
                hwdec: 'mediacodec',
              )
            : const VideoControllerConfiguration(),
      );

      _sharedPlayer = player;
      _sharedVideoController = videoController;
      return player;
    }();

    _sharedInitFuture = future;
    future.whenComplete(() {
      if (_sharedInitFuture == future) {
        _sharedInitFuture = null;
      }
    });
    return future;
  }

  Future<Player> _ensurePlayer() async {
    _activeOwner = this;
    final existing = _player;
    if (existing != null && _videoController != null) return existing;

    final player = await _getOrCreateSharedPlayer();
    if (!mounted) return player;

    _player = player;
    _videoController = _sharedVideoController;
    if (mounted) {
      setState(() {});
    }

    if (_playerSubs.isEmpty) {
      _playerSubs.add(
        player.stream.playing.listen((playing) {
          if (!mounted || !widget.isActive || _activeOwner != this) return;
          if (_isPlaying == playing) return;
          _isPlaying = playing;
          _checkStreamReady();
          if (!_inFullscreen) setState(() {});
        }),
      );

      _playerSubs.add(
        player.stream.buffering.listen((buffering) {
          if (!mounted || !widget.isActive || _activeOwner != this) return;
          if (_isBuffering == buffering) return;
          _isBuffering = buffering;
          _checkStreamReady();
          if (!_inFullscreen) setState(() {});
        }),
      );

      _playerSubs.add(
        player.stream.position.listen((position) {
          if (!mounted || !widget.isActive || _activeOwner != this) return;
          if (_awaitingOpen || _readyReported) return;
          if (_initialPosAfterOpen == null) {
            _initialPosAfterOpen = position;
            return;
          }
          if (position != _initialPosAfterOpen &&
              position > Duration.zero &&
              (player.state.width ?? 0) > 0) {
            _hasVideoFrame = true;
            _checkStreamReady();
          }
        }),
      );

      _playerSubs.add(
        player.stream.error.listen((error) {
          if (!mounted || !widget.isActive || _activeOwner != this || error.isEmpty) {
            return;
          }
          // Ignore non-fatal warnings once already actively playing with frames
          if (_streamState == _StreamState.playing && _isPlaying && !_isBuffering) {
            return;
          }
          // Only abort immediately on genuine fatal network/HTTP errors;
          // transient libmpv/mediacodec_embed warnings during surface attach
          // should not kill a healthy stream (timeout handles truly dead streams).
          if (!_isFatalStreamError(error)) return;
          _handleLoadFailure(
            _loadEpoch,
            'Siaran terputus karena gangguan jaringan atau kamera sedang offline.',
          );
        }),
      );
    }

    return player;
  }

  void _checkStreamReady() {
    if (_readyReported || _awaitingOpen || _streamState != _StreamState.loading) {
      return;
    }
    final camId = _activeLoadCameraId;
    if (camId == null) return;

    // Ready once the new stream has decoded frames and is actively playing
    if (_hasVideoFrame && _isPlaying && !_isBuffering) {
      _readyReported = true;
      _loadTimeoutTimer?.cancel();
      setState(() {
        _streamState = _StreamState.playing;
        _errorMsg = null;
        _showControls = true;
      });
      _scheduleHideControls(duration: const Duration(milliseconds: 2500));
      widget.onStreamReady(camId);
    }
  }

  void _handleLoadFailure(int epoch, String message) {
    if (!mounted || epoch != _loadEpoch) return;
    _loadTimeoutTimer?.cancel();
    if (_streamState == _StreamState.error) return;

    final advanced = widget.onStreamError();
    if (advanced) return;

    setState(() {
      _streamState = _StreamState.error;
      _errorMsg = message;
    });
  }

  Future<void> _loadCamera(CctvCamera camera) async {
    final epoch = ++_loadEpoch;
    _pausedByUser = false;
    _awaitingOpen = true;
    _hasVideoFrame = false;
    _readyReported = false;
    _initialPosAfterOpen = null;
    _isBuffering = true;
    _activeLoadCameraId = camera.id;
    _hideControlsTimer?.cancel();
    _loadTimeoutTimer?.cancel();

    final url = camera.videoUrl?.trim();
    if (url == null || url.isEmpty) {
      unawaited(_player?.pause());
      unawaited(_player?.open(const Playlist([]), play: false));
      await Future<void>.microtask(() {});
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

    _loadTimeoutTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted || epoch != _loadEpoch || _readyReported) return;
      unawaited(_player?.pause());
      unawaited(_player?.open(const Playlist([]), play: false));
      _handleLoadFailure(
        epoch,
        'Siaran gagal dimuat karena gangguan jaringan atau kamera sedang offline.',
      );
    });

    try {
      final player = await _ensurePlayer();
      if (!mounted || epoch != _loadEpoch) return;

      final origin = AppConfig.cctvApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      await player.setVolume(_isMuted ? 0.0 : 100.0);
      if (!mounted || epoch != _loadEpoch) return;

      // Reuse the single libmpv player instance directly without destroying it
      await player.open(
        Media(
          url,
          httpHeaders: {
            'Origin': origin,
            'Referer': '$origin/',
          },
        ),
        play: true,
      );
      if (!mounted || epoch != _loadEpoch) return;
      _awaitingOpen = false;
      _initialPosAfterOpen = player.state.position;
      if ((player.state.width ?? 0) > 0 &&
          player.state.playing &&
          !player.state.buffering) {
        _hasVideoFrame = true;
        _isPlaying = true;
        _isBuffering = false;
        _checkStreamReady();
      }
    } catch (_) {
      _handleLoadFailure(
        epoch,
        'Siaran gagal dimuat karena gangguan jaringan atau kamera sedang offline.',
      );
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
    final player = _player;
    if (player == null) return;
    if (_isPlaying) {
      _pausedByUser = true;
      unawaited(player.pause());
    } else {
      _pausedByUser = false;
      unawaited(player.play());
    }
    _scheduleHideControls();
  }

  void _toggleMute() {
    final player = _player;
    _isMuted = !_isMuted;
    if (player != null) {
      unawaited(player.setVolume(_isMuted ? 0.0 : 100.0));
    }
    setState(() {});
    _scheduleHideControls();
  }

  Future<void> _openFullscreen() async {
    final player = _player;
    final videoController = _videoController;
    final cam = widget.camera;
    if (player == null || videoController == null || cam == null) {
      return;
    }
    _inFullscreen = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CctvFullscreenPlayerPage(
          player: player,
          videoController: videoController,
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
    final videoController = _videoController;
    final camName = widget.camera?.displayName ?? '';
    final showBuffering =
        _streamState == _StreamState.playing && _isBuffering && !_pausedByUser;

    final playerContent = AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),

            if (videoController != null &&
                _streamState != _StreamState.error &&
                _streamState != _StreamState.idle)
              Video(
                controller: videoController,
                controls: NoVideoControls,
                fill: Colors.black,
                fit: BoxFit.contain,
              ),

            // Loading / Buffering overlay with active camera name
            if (_streamState == _StreamState.loading || showBuffering)
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
            if (videoController != null && _streamState == _StreamState.playing)
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
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            tooltip: _isPlaying ? 'Jeda' : 'Putar',
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
