import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../core/theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String url;
  final bool fullscreen;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.url,
    this.fullscreen = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  String? _videoId;
  bool _invalidVideo = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    if (widget.fullscreen) {
      _setFullscreenState(true);
    }
    _videoId = YoutubePlayer.convertUrlToId(widget.url.trim());
    if (_videoId == null || _videoId!.isEmpty) {
      _invalidVideo = true;
      return;
    }
    _controller = YoutubePlayerController(
      initialVideoId: _videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        enableCaption: false,
        forceHD: false,
        hideControls: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    if (widget.fullscreen || _isFullScreen) {
      _setFullscreenState(false);
    }
    super.dispose();
  }

  void _setFullscreenState(bool enabled) {
    if (_isFullScreen == enabled) return;
    _isFullScreen = enabled;
    _setSystemUi(enabled);
    if (mounted) setState(() {});
  }

  void _setSystemUi(bool enabled) {
    _isFullScreen = enabled;
    if (enabled) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = _invalidVideo
        ? _buildError(
            'Invalid or unsupported video link. Please use a YouTube URL.',
          )
        : YoutubePlayerBuilder(
            onEnterFullScreen: () {
              if (!mounted) return;
              _setFullscreenState(true);
            },
            onExitFullScreen: () {
              if (!mounted) return;
              _setFullscreenState(false);
            },
            player: YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppColors.primary,
              onReady: () {
                if (!mounted) return;
                if (_controller!.value.hasError) {
                  setState(() {});
                }
              },
            ),
            builder: (context, builtPlayer) {
              if (_controller!.value.hasError) {
                return _buildError(
                  'This video cannot be played in the app. Please check the video URL or embedding settings.',
                );
              }
              return builtPlayer;
            },
          );

    return Scaffold(
      backgroundColor: _isFullScreen ? Colors.black : Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: _isFullScreen ? 0 : kToolbarHeight,
        backgroundColor: _isFullScreen ? Colors.black : Colors.white,
        title: _isFullScreen
            ? null
            : const Text(
                'Video Player',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
        iconTheme: _isFullScreen
            ? null
            : const IconThemeData(color: AppColors.primary),
        automaticallyImplyLeading: !_isFullScreen,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isFullScreen
            ? Center(key: const ValueKey('fullscreen'), child: player)
            : Padding(
                key: const ValueKey('normal'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    player,
                    const SizedBox(height: 12),
                    const Text(
                      'Note: Some YouTube videos may be blocked from embedded playback.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFEA580C), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
