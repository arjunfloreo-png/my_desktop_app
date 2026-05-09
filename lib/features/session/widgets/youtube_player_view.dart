import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:webview_windows/webview_windows.dart';

import '../provider/video_provider.dart';

class YoutubePlayerView extends StatefulWidget {
  final String url;
  final VideoProvider videoProvider;

  const YoutubePlayerView({
    super.key,
    required this.url,
    required this.videoProvider,
  });

  @override
  State<YoutubePlayerView> createState() =>
      _YoutubePlayerViewState();
}

class _YoutubePlayerViewState
    extends State<YoutubePlayerView> {
  final WebviewController _controller =
      WebviewController();

  HttpServer? _localServer;

  bool _isReady = false;

  String? _error;

  bool _disposed = false;

  static const List<int> _ports = [
    8080,
    8081,
    8082,
  ];

  @override
  void initState() {
    super.initState();

    _initPlayer();
  }

  // ─────────────────────────────────────────────
  // EXTRACT VIDEO ID
  // ─────────────────────────────────────────────
  String _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);

      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.first;
      }

      return uri.queryParameters['v'] ?? '';
    } catch (_) {
      return '';
    }
  }

  // ─────────────────────────────────────────────
  // BUILD HTML
  // ─────────────────────────────────────────────
  String _buildHtml(String videoId) => '''
<!DOCTYPE html>

<html>

<head>

<meta charset="utf-8">

<style>

html, body {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: black;
}

#player {
  position: fixed;
  inset: 0;
  width: 100vw !important;
  height: 100vh !important;
}

iframe {
  width: 100% !important;
  height: 100% !important;
  border: none;
}

</style>

</head>

<body>

<div id="player"></div>

<script src="https://www.youtube.com/iframe_api"></script>

<script>

var player;

function onYouTubeIframeAPIReady() {

  player = new YT.Player('player', {

    height: window.innerHeight,
    width: window.innerWidth,

    videoId: '$videoId',

    playerVars: {
      autoplay: 1,
      controls: 0,
      rel: 0,
      modestbranding: 1,
      fs: 0,
      playsinline: 1,
      enablejsapi: 1,
    },

    events: {

      onReady: function(e) {

        e.target.mute();

        setTimeout(() => {
          e.target.playVideo();
        }, 300);

      },

      onStateChange: function(e) {

        // PLAYING
        if (e.data === 1) {

          window.chrome.webview.postMessage(
            JSON.stringify({
              type: 'playing'
            })
          );

        }

        // PAUSED
        if (e.data === 2) {

          window.chrome.webview.postMessage(
            JSON.stringify({
              type: 'paused'
            })
          );

        }

      }

    }

  });

  // RESPONSIVE RESIZE
  window.addEventListener('resize', () => {

    if(player){

      player.setSize(
        window.innerWidth,
        window.innerHeight
      );

    }

  });

  // SEND PROGRESS
  setInterval(() => {

    if(player){

      window.chrome.webview.postMessage(
        JSON.stringify({
          type:'progress',
          position:player.getCurrentTime(),
          duration:player.getDuration()
        })
      );

    }

  }, 500);

}

// ─────────────────────────────────────────────
// EXTERNAL CONTROLS
// ─────────────────────────────────────────────

function playVideo(){

  if(player){
    player.playVideo();
  }

}

function pauseVideo(){

  if(player){
    player.pauseVideo();
  }

}

function stopVideo(){

  if(player){
    player.stopVideo();
  }

}

function seekTo(seconds){

  if(player){
    player.seekTo(seconds, true);
  }

}

</script>

</body>

</html>
''';

  // ─────────────────────────────────────────────
  // START LOCAL SERVER
  // ─────────────────────────────────────────────
  Future<int> _startServer(File htmlFile) async {
    for (final port in _ports) {
      try {
        final server = await shelf_io.serve(
          (Request request) async {
            return Response.ok(
              await htmlFile.readAsBytes(),
              headers: {
                'Content-Type':
                    'text/html; charset=utf-8',
              },
            );
          },
          'localhost',
          port,
        );

        _localServer = server;

        return port;
      } catch (_) {}
    }

    throw Exception('No port available');
  }

  // ─────────────────────────────────────────────
  // INIT PLAYER
  // ─────────────────────────────────────────────
  Future<void> _initPlayer() async {
    try {
      final videoId =
          _extractVideoId(widget.url);

      final dir =
          await getTemporaryDirectory();

      final htmlFile = File(
        '${dir.path}/yt_player.html',
      );

      await htmlFile.writeAsString(
        _buildHtml(videoId),
      );

      final port =
          await _startServer(htmlFile);

      await _controller.initialize();

      _controller.webMessage.listen((msg) {

        if (_disposed) return;

        final data =
            jsonDecode(msg.toString());

        switch (data['type']) {

          case 'playing':

            widget.videoProvider
                .setExternalPlayingState(true);

            break;

          case 'paused':

            widget.videoProvider
                .setExternalPlayingState(false);

            break;

          case 'progress':

            widget.videoProvider.position =
                Duration(
              seconds:
                  (data['position'] ?? 0)
                      .toInt(),
            );

            widget.videoProvider.duration =
                Duration(
              seconds:
                  (data['duration'] ?? 0)
                      .toInt(),
            );

            widget.videoProvider
                .notifyListeners();

            break;
        }
      });

      await _controller.loadUrl(
        'http://localhost:$port',
      );

      // REGISTER CONTROLS
      widget.videoProvider.externalPlay =
          play;

      widget.videoProvider.externalPause =
          pause;

      widget.videoProvider.externalStop =
          stop;

      widget.videoProvider.externalSeek =
          seekTo;

      if (!_disposed) {
        setState(() {
          _isReady = true;
        });
      }

    } catch (e) {

      if (!_disposed) {
        setState(() {
          _error = e.toString();
        });
      }

    }
  }

  // ─────────────────────────────────────────────
  // PLAYER CONTROLS
  // ─────────────────────────────────────────────
  Future<void> play() async {
    await _controller.executeScript(
      'playVideo();',
    );
  }

  Future<void> pause() async {
    await _controller.executeScript(
      'pauseVideo();',
    );
  }

  Future<void> stop() async {
    await _controller.executeScript(
      'stopVideo();',
    );
  }

  Future<void> seekTo(
    Duration position,
  ) async {
    await _controller.executeScript(
      'seekTo(${position.inSeconds});',
    );
  }

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────
  @override
  void dispose() {

    _disposed = true;

    widget.videoProvider.externalPlay =
        null;

    widget.videoProvider.externalPause =
        null;

    widget.videoProvider.externalStop =
        null;

    widget.videoProvider.externalSeek =
        null;

    _localServer?.close(force: true);

    _controller.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    if (_error != null) {
      return Center(
        child: Text(_error!),
      );
    }

    if (!_isReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SizedBox.expand(
      child: Webview(
        _controller,
        permissionRequested:
            (_, __, ___) =>
                WebviewPermissionDecision.allow,
      ),
    );
  }
}