import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class YoutubePlayerView extends StatefulWidget {
  final String url;
  const YoutubePlayerView({super.key, required this.url});

  @override
  State<YoutubePlayerView> createState() => _YoutubePlayerViewState();
}

class _YoutubePlayerViewState extends State<YoutubePlayerView> {
  bool _loading = true;
  bool _error = false;
  Webview? _webview; // ← changed from WebviewWindow? to Webview?

  String? _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    return uri.queryParameters['v'];
  }

  Future<String> _getWebViewPath() async {
    final document = await getApplicationDocumentsDirectory();
    return p.join(document.path, 'floreo_webview');
  }

  @override
  void initState() {
    super.initState();
    _openYoutube();
  }

  Future<void> _openYoutube() async {
    final videoId = _extractVideoId(widget.url);

    if (videoId == null) {
      setState(() { _loading = false; _error = true; });
      return;
    }

    try {
      final isAvailable = await WebviewWindow.isWebviewAvailable();
      if (!isAvailable) {
        setState(() { _loading = false; _error = true; });
        return;
      }

      _webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          title: 'YouTube',
          windowWidth: 1280,
          windowHeight: 720,
          titleBarTopPadding: Platform.isMacOS ? 20 : 0,
          userDataFolderWindows: await _getWebViewPath(),
        ),
      );

      _webview!
        // ← removed setApplicationNameForUserAgent (not available in this version)
        ..launch('https://www.youtube.com/embed/$videoId?autoplay=1')
        ..onClose.whenComplete(() {
          if (mounted) setState(() => _loading = false);
        });

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('WebView error: $e');
      setState(() { _loading = false; _error = true; });
    }
  }

  @override
  void dispose() {
    _webview?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Color(0xFF00bd74))
            : _error
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not open YouTube.\nWebView2 may not be installed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { _loading = true; _error = false; });
                          _openYoutube();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00bd74),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_outline,
                          color: Color(0xFF00bd74), size: 48),
                      SizedBox(height: 12),
                      Text(
                        '▶ YouTube playing in window',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
      ),
    );
  }
}