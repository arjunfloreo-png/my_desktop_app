import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
//import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'dart:io';

import 'features/session/screens/role_selection_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('args: $args');
  if (runWebViewTitleBarWidget(args)) {
    return;
  }

  MediaKit.ensureInitialized();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RoleSelectionScreen(),
    ),
  );
}


//youtbe player 

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as shelf_io;
// import 'package:webview_windows/webview_windows.dart';

// HttpServer? _localServer;

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Universal Windows Video Player',
//       theme: ThemeData.dark(),
//       home: const VideoPlayerScreen(),
//     );
//   }
// }

// class VideoPlayerScreen extends StatefulWidget {
//   const VideoPlayerScreen({super.key});

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   final WebviewController controller = WebviewController();
//   final String youtubeUrl =
//       'https://youtu.be/WN18kGdPHzk?si=CXq1V6lQ3MMdf1-B';
//   bool isReady = false;

//   @override
//   void initState() {
//     super.initState();
//     initPlayer();
//   }

//   String extractYoutubeId(String url) {
//     final uri = Uri.parse(url);
//     if (uri.host.contains('youtu.be')) {
//       return uri.pathSegments.first;
//     }
//     return uri.queryParameters['v'] ?? '';
//   }

//   Future<void> initPlayer() async {
//     await controller.initialize();

//     await controller.setUserAgent(
//       'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
//       'AppleWebKit/537.36 (KHTML, like Gecko) '
//       'Chrome/120.0.0.0 Safari/537.36',
//     );

//     final videoId = extractYoutubeId(youtubeUrl);

//     final dir = await getTemporaryDirectory();
//     final htmlFile = File('${dir.path}\\player.html');

//     await htmlFile.writeAsString('''
// <!DOCTYPE html>
// <html>
// <head>
// <meta name="viewport" content="width=device-width, initial-scale=1.0">
// <style>
//   * { margin: 0; padding: 0; }
//   html, body {
//     width: 100%; height: 100%;
//     background: #000;
//     overflow: hidden;
//   }
//   #player { width: 100vw; height: 100vh; }

//   /* ✅ Hide YouTube overlay elements */
//   .ytp-share-button,
//   .ytp-share-button-visible,
//   .ytp-endscreen-content,
//   .ytp-pause-overlay,
//   .ytp-watermark,
//   .ytp-youtube-button,
//   .ytp-show-cards-title,
//   .ytp-cards-teaser,
//   .ytp-ce-element,
//   .ytp-cards-button { 
//     display: none !important; 
//   }
// </style>
// </head>
// <body>
// <div id="player"></div>
// <script src="https://www.youtube.com/iframe_api"></script>
// <script>
//   var player;
//   function onYouTubeIframeAPIReady() {
//     player = new YT.Player('player', {
//       width: '100%',
//       height: '100%',
//       videoId: '$videoId',
//       playerVars: {
//         autoplay: 1,
//         controls: 0,
//         rel: 0,
//         modestbranding: 1,
//         enablejsapi: 1,
//         origin: 'http://localhost:8080',
//         showinfo: 0,
//         iv_load_policy: 3,
//         fs: 0,
//         disablekb: 1,
//       },
//       events: {
//         onReady: function(e) { e.target.playVideo(); }
//       }
//     });
//   }
//   function playVideo()  { if (player) player.playVideo(); }
//   function pauseVideo() { if (player) player.pauseVideo(); }
//   function stopVideo()  { if (player) player.stopVideo(); }
// </script>
// </body>
// </html>
// ''');

//     // ✅ Start local HTTP server
//     _localServer = await shelf_io.serve(
//       (Request request) async {
//         final filePath = '${dir.path}\\${request.url.path}';
//         final file = File(filePath);
//         if (await file.exists()) {
//           return Response.ok(
//             await file.readAsBytes(),
//             headers: {'Content-Type': 'text/html'},
//           );
//         }
//         return Response.notFound('Not found');
//       },
//       'localhost',
//       8080,
//     );

//     await controller.loadUrl('http://localhost:8080/player.html');

//     setState(() => isReady = true);
//   }

//   Future<void> playVideo() async =>
//       await controller.executeScript('playVideo();');

//   Future<void> pauseVideo() async =>
//       await controller.executeScript('pauseVideo();');

//   Future<void> stopVideo() async =>
//       await controller.executeScript('stopVideo();');

//   @override
//   void dispose() {
//     _localServer?.close(force: true);
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Container(
//                 margin: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: Colors.white24),
//                 ),
//                 clipBehavior: Clip.antiAlias,
//                 child: isReady
//                     ? Webview(controller)
//                     : const Center(
//                         child: CircularProgressIndicator(),
//                       ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.only(bottom: 24),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _ControlButton(
//                     icon: Icons.play_arrow,
//                     label: 'Play',
//                     color: Colors.green,
//                     onPressed: playVideo,
//                   ),
//                   const SizedBox(width: 20),
//                   _ControlButton(
//                     icon: Icons.pause,
//                     label: 'Pause',
//                     color: Colors.orange,
//                     onPressed: pauseVideo,
//                   ),
//                   const SizedBox(width: 20),
//                   _ControlButton(
//                     icon: Icons.stop,
//                     label: 'Stop',
//                     color: Colors.red,
//                     onPressed: stopVideo,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ControlButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onPressed;

//   const _ControlButton({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onPressed,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton.icon(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color.withOpacity(0.15),
//         foregroundColor: color,
//         side: BorderSide(color: color.withOpacity(0.6)),
//         padding: const EdgeInsets.symmetric(
//           horizontal: 20,
//           vertical: 12,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//       onPressed: onPressed,
//       icon: Icon(icon),
//       label: Text(label),
//     );
//   }
// }