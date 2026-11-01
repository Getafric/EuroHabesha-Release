import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'startup_presentation.dart';

/// Kept in MaterialApp.builder, above the existing Navigator.
class EuroHabeshaVideoIntro extends StatefulWidget {
  const EuroHabeshaVideoIntro({super.key, required this.child});
  final Widget child;
  @override
  State<EuroHabeshaVideoIntro> createState() => _EuroHabeshaVideoIntroState();
}

class _EuroHabeshaVideoIntroState extends State<EuroHabeshaVideoIntro> {
  bool _done = false;
  bool _scheduled = false;
  StartupPresentation? _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _done) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _finish();
        return;
      }
      final settings = await StartupPresentationSettings.loadForLaunch();
      if (!mounted || _done) return;
      if (!settings.enabled) {
        _finish();
      } else {
        setState(() => _settings = settings);
      }
    });
  }

  void _finish() {
    if (mounted && !_done) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    ExcludeSemantics(excluding: !_done,
      child: IgnorePointer(ignoring: !_done, child: widget.child)),
    if (!_done) Positioned.fill(child: _settings == null
      ? _IntroLoading(onSkip: _finish)
      : StartupPresentationPlayer(settings: _settings!, onFinished: _finish)),
  ]);
}

class _IntroLoading extends StatelessWidget {
  const _IntroLoading({required this.onSkip});
  final VoidCallback onSkip;
  @override
  Widget build(BuildContext context) => Material(color: const Color(0xFF061E12),
    child: Stack(children: [
      const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
      Positioned(top: 0, right: 12, child: SafeArea(child: TextButton(
        onPressed: onSkip, child: const Text('Passer'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFD700),
          minimumSize: const Size(92, 48)),
      ))),
    ]));
}

/// Shared by real launch and admin preview. No route or configuration writes.
class StartupPresentationPlayer extends StatefulWidget {
  const StartupPresentationPlayer({super.key, required this.settings,
    required this.onFinished, this.allowLocalFallback = true});
  final StartupPresentation settings;
  final VoidCallback onFinished;
  final bool allowLocalFallback;
  @override
  State<StartupPresentationPlayer> createState() => _StartupPresentationPlayerState();
}

class _StartupPresentationPlayerState extends State<StartupPresentationPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _video;
  ImageProvider? _image;
  Timer? _timer;
  Timer? _watchdog;
  final _elapsed = Stopwatch();
  bool _ready = false;
  bool _done = false;
  bool _started = false;
  bool _foreground = true;
  bool _finishing = false;
  bool _usingFallback = false;
  String? _previewError;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool fallback = false}) async {
    if (!mounted || _done) return;
    final generation = ++_generation;
    try {
      final settings = widget.settings;
      if (fallback || settings.isLocal) {
        await _loadVideo(VideoPlayerController.asset('assets/images/euro_habesha_intro.mp4',
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true)));
      } else {
        final url = await settings.downloadUrl();
        if (!mounted || _done) return;
        if (settings.mediaType == 'image') {
          final image = NetworkImage(url);
          Object? decodeError;
          await precacheImage(image, context, onError: (error, stack) {
            decodeError = error;
          }).timeout(const Duration(seconds: 5));
          if (decodeError != null) throw StateError('Image illisible.');
          if (!mounted || _done) return;
          setState(() { _image = image; _ready = true; });
          _startClock();
        } else {
          await _loadVideo(VideoPlayerController.networkUrl(Uri.parse(url),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true)));
        }
      }
    } catch (_) {
      if (generation == _generation) _onFailure();
    }
  }

  Future<void> _loadVideo(VideoPlayerController video) async {
    if (!mounted || _done) { await video.dispose(); return; }
    _video = video;
    await video.setVolume(0);
    if (!mounted || _done || _video != video) return;
    await video.initialize().timeout(const Duration(seconds: 6));
    if (!mounted || _done || _video != video) return;
    if (video.value.size.width <= 0 || video.value.size.height <= 0) {
      throw StateError('Dimensions vidéo invalides.');
    }
    await video.setLooping(false);
    if (!mounted || _done || _video != video) return;
    video.addListener(_onVideo);
    setState(() => _ready = true);
    if (_foreground) {
      _armWatchdog();
      await video.play();
    }
  }

  void _startClock() {
    if (_foreground) _elapsed.start();
    _timer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_elapsed.elapsed >= Duration(seconds: widget.settings.durationSeconds)) {
        _finish();
      }
    });
  }

  void _onVideo() {
    final value = _video?.value;
    if (!mounted || _done || _finishing || value == null) return;
    if (value.hasError) {
      _finishing = true;
      final generation = _generation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (generation != _generation || !mounted || _done) return;
        _finishing = false;
        _onFailure();
      });
      WidgetsBinding.instance.scheduleFrame();
      return;
    }
    if (value.isPlaying && !_started) {
      _started = true;
      _startClock();
    }
    if (value.isCompleted || value.duration > Duration.zero && value.position >= value.duration) {
      _finishing = true;
      final generation = _generation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (generation == _generation) _finish();
      });
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  void _onFailure() {
    if (!mounted || _done) return;
    ++_generation;
    _finishing = false;
    _release();
    if (widget.allowLocalFallback && !widget.settings.isLocal && !_usingFallback) {
      _usingFallback = true;
      _started = false;
      _elapsed.reset();
      setState(() { _ready = false; _image = null; });
      _load(fallback: true);
    } else if (!widget.allowLocalFallback) {
      setState(() {
        _previewError = 'Aperçu indisponible. Vérifiez le fichier ou la connexion.';
        _ready = false;
      });
    } else {
      _finish();
    }
  }

  void _armWatchdog() {
    _watchdog?.cancel();
    final remaining = Duration(seconds: widget.settings.durationSeconds) - _elapsed.elapsed;
    _watchdog = Timer(remaining + const Duration(seconds: 5), _finish);
  }

  Future<void> _setPlaying(bool playing) async {
    final video = _video;
    if (video == null || !_ready || _done) return;
    try {
      if (playing) { await video.play(); } else { await video.pause(); }
    } catch (_) {
      if (mounted && !_done && _video == video) _onFailure();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_done) return;
    if (_foreground) {
      if (_ready && (_image != null || _started)) _elapsed.start();
      if (_video != null && _ready) _armWatchdog();
    } else {
      _elapsed.stop();
      _watchdog?.cancel();
    }
    unawaited(_setPlaying(_foreground));
  }

  void _release() {
    _timer?.cancel(); _timer = null;
    _watchdog?.cancel();
    _elapsed.stop();
    final video = _video;
    _video = null;
    if (video != null) {
      video.removeListener(_onVideo);
      unawaited(video.dispose().catchError((Object _) {}));
    }
  }

  void _finish() {
    if (!mounted || _done) return;
    _done = true;
    ++_generation;
    _release();
    widget.onFinished();
  }

  @override
  void dispose() {
    _done = true;
    WidgetsBinding.instance.removeObserver(this);
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return Material(color: const Color(0xFF061E12), child: Stack(fit: StackFit.expand,
      children: [
        if (_previewError != null) Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Text(_previewError!, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white))))
        else if (_ready && _image != null) Image(image: _image!, fit: BoxFit.contain)
        else if (_ready && video != null) Center(child: FittedBox(fit: BoxFit.contain,
          child: SizedBox(width: video.value.size.width, height: video.value.size.height,
            child: VideoPlayer(video))))
        else const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
        Positioned(top: 0, right: 12, child: SafeArea(child: TextButton(
          onPressed: _finish, child: const Text('Passer'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFD700),
            backgroundColor: const Color(0xDD061E12), minimumSize: const Size(92, 48)),
        ))),
      ]));
  }
}
