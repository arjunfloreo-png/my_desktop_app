// import 'dart:io';

// import 'package:flutter/material.dart';

// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
// import 'package:media_kit_video/media_kit_video_controls/src/controls/material.dart';

// import 'package:webview_windows/webview_windows.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   MediaKit.ensureInitialized();

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const VideoPlayerScreen(),
//     );
//   }
// }

// class VideoPlayerScreen extends StatefulWidget {
//   const VideoPlayerScreen({super.key});

//   @override
//   State<VideoPlayerScreen> createState() =>
//       _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState
//     extends State<VideoPlayerScreen> {
//   final TextEditingController urlController =
//       TextEditingController(
//     text:
//         "https://www.youtube.com/watch?v=M7lc1UVf-VE",
//   );

//   String currentUrl =
//       "https://www.youtube.com/watch?v=M7lc1UVf-VE";

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,

//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: const Text(
//           "Universal Windows Video Player",
//         ),
//       ),

//       body: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),

//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: urlController,

//                     style: const TextStyle(
//                       color: Colors.white,
//                     ),

//                     decoration: InputDecoration(
//                       hintText:
//                           "Enter mp4 or YouTube URL",

//                       hintStyle: const TextStyle(
//                         color: Colors.white54,
//                       ),

//                       filled: true,
//                       fillColor: Colors.grey.shade900,

//                       border: OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(width: 10),

//                 ElevatedButton(
//                   onPressed: () {
//                     setState(() {
//                       currentUrl =
//                           urlController.text.trim();
//                     });
//                   },

//                   child: const Text("Play"),
//                 ),
//               ],
//             ),
//           ),

//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(12),

//               child: UniversalVideoPlayer(
//                 videoUrl: currentUrl,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class UniversalVideoPlayer extends StatelessWidget {
//   final String videoUrl;

//   const UniversalVideoPlayer({
//     super.key,
//     required this.videoUrl,
//   });

//   bool isYoutubeUrl(String url) {
//     return url.contains("youtube.com") ||
//         url.contains("youtu.be");
//   }

//   String extractYoutubeId(String url) {
//     final uri = Uri.parse(url);

//     if (uri.host.contains("youtu.be")) {
//       return uri.pathSegments.first;
//     }

//     return uri.queryParameters['v'] ?? '';
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isYoutubeUrl(videoUrl)) {
//       return YoutubeIframePlayer(
//         videoId: extractYoutubeId(videoUrl),
//       );
//     }

//     return Mp4Player(
//       videoUrl: videoUrl,
//     );
//   }
// }

// class Mp4Player extends StatefulWidget {
//   final String videoUrl;

//   const Mp4Player({
//     super.key,
//     required this.videoUrl,
//   });

//   @override
//   State<Mp4Player> createState() =>
//       _Mp4PlayerState();
// }

// class _Mp4PlayerState extends State<Mp4Player> {
//   late final Player player;

//   late final VideoController controller;

//   @override
//   void initState() {
//     super.initState();

//     player = Player();

//     controller = VideoController(player);

//     player.open(
//       Media(widget.videoUrl),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         color: Colors.black,
//       ),

//       clipBehavior: Clip.hardEdge,

//       child: Video(
//         controller: controller,
//         controls: MaterialVideoControls,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     player.dispose();

//     super.dispose();
//   }
// }

// class YoutubeIframePlayer extends StatefulWidget {
//   final String videoId;

//   const YoutubeIframePlayer({
//     super.key,
//     required this.videoId,
//   });

//   @override
//   State<YoutubeIframePlayer> createState() =>
//       _YoutubeIframePlayerState();
// }

// class _YoutubeIframePlayerState
//     extends State<YoutubeIframePlayer> {
//   final WebviewController controller =
//       WebviewController();

//   bool loading = true;

//   @override
//   void initState() {
//     super.initState();

//     initializeWebview();
//   }

//   Future<void> initializeWebview() async {
//     await controller.initialize();

//     final html = '''
// <!DOCTYPE html>

// <html>

// <head>

// <meta charset="UTF-8">

// <style>

// html, body {
//   margin: 0;
//   padding: 0;
//   width: 100%;
//   height: 100%;
//   overflow: hidden;
//   background: black;
// }

// #player {
//   width: 100vw;
//   height: 100vh;
// }

// </style>

// </head>

// <body>

// <div id="player"></div>

// <script src="https://www.youtube.com/iframe_api"></script>

// <script>

// var player;

// function onYouTubeIframeAPIReady() {

//   player = new YT.Player('player', {

//     videoId: '${widget.videoId}',

//     width: '100%',

//     height: '100%',

//     playerVars: {

//       autoplay: 1,
//       controls: 1,
//       rel: 0,
//       modestbranding: 1,
//       fs: 1

//     },

//     events: {

//       'onReady': function(event) {

//         event.target.playVideo();

//       }

//     }

//   });

// }

// function playVideo() {
//   player.playVideo();
// }

// function pauseVideo() {
//   player.pauseVideo();
// }

// function stopVideo() {
//   player.stopVideo();
// }

// </script>

// </body>

// </html>
// ''';

//     final file = File(
//       '${Directory.current.path}/youtube_player.html',
//     );

//     await file.writeAsString(html);

//     await controller.loadUrl(
//       Uri.file(file.path).toString(),
//     );

//     setState(() {
//       loading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return const Center(
//         child: CircularProgressIndicator(),
//       );
//     }

//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         color: Colors.black,
//       ),

//       clipBehavior: Clip.hardEdge,

//       child: Stack(
//         children: [
//           Webview(controller),

//           Positioned(
//             bottom: 20,
//             left: 20,

//             child: Row(
//               children: [
//                 ElevatedButton(
//                   onPressed: () async {
//                     await controller.executeScript(
//                       'playVideo();',
//                     );
//                   },

//                   child: const Text("Play"),
//                 ),

//                 const SizedBox(width: 10),

//                 ElevatedButton(
//                   onPressed: () async {
//                     await controller.executeScript(
//                       'pauseVideo();',
//                     );
//                   },

//                   child: const Text("Pause"),
//                 ),

//                 const SizedBox(width: 10),

//                 ElevatedButton(
//                   onPressed: () async {
//                     await controller.executeScript(
//                       'stopVideo();',
//                     );
//                   },

//                   child: const Text("Stop"),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     controller.dispose();

//     super.dispose();
//   }
// }