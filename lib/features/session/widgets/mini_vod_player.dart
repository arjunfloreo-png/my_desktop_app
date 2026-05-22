import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/mini_video_charater_reaction_model.dart';
import '../models/mini_vod.dart';
import '../provider/reward_provider.dart';

/// Mini VOD player widget with MediaKit
class MiniVodPlayer extends StatefulWidget {
  final MiniVod vod;
  final RewardProvider rewardProvider;
  final VoidCallback? onClose;

  const MiniVodPlayer({
    super.key,
    required this.vod,
    required this.rewardProvider,
    this.onClose,
  });

  @override
  State<MiniVodPlayer> createState() => _MiniVodPlayerState();
}

class _MiniVodPlayerState extends State<MiniVodPlayer> {
  late final Player _player;
  late final VideoController _videoController;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _player = Player();
      _videoController = VideoController(_player);

      await _player.open(
        Media(
          widget.vod.videoUrl,
          httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
        ),
      );

      _player.play();

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = 'Failed to load video: $e');
      debugPrint('VOD player error: $e');
    }
  }

  void _togglePlayPause() {
    if (_player.state.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _seekTo(Duration position) {
    _player.seek(position);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _errorWidget();
    }

    if (!_isInitialized) {
      return _loadingWidget();
    }

    return Column(
      children: [
        _header(),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Video(controller: _videoController),
                  StreamBuilder(
                    stream: _player.stream.playing,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      if (!isPlaying) {
                        return Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00bd74),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.expand();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        _progressBar(),
        _controls(),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF00796B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vod.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (widget.vod.category != null)
                  Text(
                    widget.vod.category!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.onClose != null)
            GestureDetector(
              onTap: widget.onClose,
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: StreamBuilder<Duration>(
        stream: _player.stream.position,
        builder: (context, posSnapshot) {
          return StreamBuilder<Duration>(
            stream: _player.stream.duration,
            builder: (context, durSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              final duration = durSnapshot.data ?? Duration.zero;
              final progress = duration.inMilliseconds > 0
                  ? (position.inMilliseconds / duration.inMilliseconds)
                      .clamp(0.0, 1.0)
                  : 0.0;

              return Column(
                children: [
                  GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final newPos = position +
                          Duration(
                            milliseconds: (details.delta.dx * 100).toInt(),
                          );
                      _seekTo(newPos);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                            elevation: 0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: (val) {
                            final pos = Duration(
                              milliseconds:
                                  (val * duration.inMilliseconds).toInt(),
                            );
                            _seekTo(pos);
                          },
                          activeColor: const Color(0xFF00bd74),
                          inactiveColor: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(
            icon: Icons.replay_10,
            label: '-10s',
            onTap: () {
              _player.seek(_player.state.position - const Duration(seconds: 10));
            },
          ),
          const SizedBox(width: 16),
          StreamBuilder<bool>(
            stream: _player.stream.playing,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              return _controlButton(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                label: isPlaying ? 'Pause' : 'Play',
                onTap: _togglePlayPause,
                isPrimary: true,
              );
            },
          ),
          const SizedBox(width: 16),
          _controlButton(
            icon: Icons.forward_10,
            label: '+10s',
            onTap: () {
              _player.seek(_player.state.position + const Duration(seconds: 10));
            },
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF00bd74) : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.grey[400],
              size: 18,
            ),
            if (!isPrimary) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _loadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFF00bd74),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading ${widget.vod.name}...',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _errorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isInitialized = false;
                _error = null;
              });
              _initializePlayer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00bd74),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = (d.inSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
