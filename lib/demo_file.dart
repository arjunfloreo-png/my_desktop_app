import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: YouTubeOnlyPlayer(),
  ));
}


class YouTubeOnlyPlayer extends StatefulWidget {
  const YouTubeOnlyPlayer({super.key});

  @override
  State<YouTubeOnlyPlayer> createState() => _YouTubeOnlyPlayerState();
}

class _YouTubeOnlyPlayerState extends State<YouTubeOnlyPlayer> {
  final _controller = WebviewController();

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// This function takes a normal YouTube link and turns it into a "Player Only" link
  String convertToEmbedUrl(String url) {
    // Standard YouTube ID is 11 characters
    final RegExp regExp = RegExp(
      r'(?:v=|/shorts/|/embed/|youtu\.be/)([a-zA-Z0-9_-]{11})',
    );
    final match = regExp.firstMatch(url);
    
    if (match != null && match.groupCount >= 1) {
      final videoId = match.group(1);
      // Adding parameters to make it even cleaner:
      // autoplay=1 (starts immediately)
      // rel=0 (don't show other channels' videos at the end)
      // modestbranding=1 (hides the YouTube logo as much as possible)
      return 'https://youtube.com';
    }
    
    // Fallback: If no ID found, play a default video so it doesn't show the home page
    return 'https://youtube.com';
  }

  Future<void> _initWebView() async {
    try {
      await _controller.initialize();
      
      // PASTE YOUR YOUTUBE LINK HERE
      const myVideoLink = 'https://youtu.be/pF--YKCCUMw?si=ggavnANkP7eh1d-R'; 
      
      final cleanUrl = convertToEmbedUrl(myVideoLink);
      await _controller.loadUrl(cleanUrl);

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Makes the player look native
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: Webview(
                _controller,
                // Allow the video to go fullscreen within the app
                permissionRequested: (url, kind, isUserInitiated) =>
                    Future.value(WebviewPermissionDecision.allow),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the app closes
    _controller.dispose();
    super.dispose();
  }
}
