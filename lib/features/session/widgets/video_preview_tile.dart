// // FIXED video_preview_tile.dart
// // THIS VERSION AUTOPLAYS PROPERLY

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';

// import '../../../services/thumbnail_cache_service.dart';


// class VideoPreviewTile extends StatefulWidget {

//   final String videoUrl;
//   final String title;
//   final bool circle;
//   final VoidCallback? onTap;

//   const VideoPreviewTile({
//     super.key,
//     required this.videoUrl,
//     required this.title,
//     this.circle = false,
//     this.onTap,
//   });

//   @override
//   State<VideoPreviewTile> createState() =>
//       _VideoPreviewTileState();
// }

// class _VideoPreviewTileState
//     extends State<VideoPreviewTile> {

//   late final Player _player;

//   late final VideoController _controller;

//   bool _initialized = false;

//   bool _hovered = false;

//   @override
//   void initState() {
//     super.initState();

//     _player = Player();

//     _controller =
//         VideoController(_player);

//     _initPlayer();
//   }

//   Future<void> _initPlayer() async {

//     try {

//       await _player.open(
//         Media(widget.videoUrl),
//         play: false,
//       );

//       await _player.setVolume(0);

//       await _player.setPlaylistMode(
//         PlaylistMode.loop,
//       );

//       if (mounted) {
//         setState(() {
//           _initialized = true;
//         });
//       }

//     } catch (e) {
//       debugPrint(
//         'VIDEO INIT ERROR: $e',
//       );
//     }
//   }

//   Future<void> _play() async {

//     if (!_initialized) return;

//     try {

//       await _player.play();

//     } catch (e) {
//       debugPrint(
//         'VIDEO PLAY ERROR: $e',
//       );
//     }
//   }

//   Future<void> _pause() async {

//     if (!_initialized) return;

//     try {

//       await _player.pause();

//       await _player.seek(
//         Duration.zero,
//       );

//     } catch (e) {
//       debugPrint(
//         'VIDEO PAUSE ERROR: $e',
//       );
//     }
//   }

//   @override
//   void dispose() {

//     _player.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {

//     final radius = widget.circle
//         ? BorderRadius.circular(999)
//         : BorderRadius.circular(16);

//     return MouseRegion(

//       onEnter: (_) async {

//         _hovered = true;

//         await _play();
//       },

//       onExit: (_) async {

//         _hovered = false;

//         await _pause();
//       },

//       child: GestureDetector(

//         onTap: widget.onTap,

//         child: Column(
//           children: [

//             Expanded(
//               child: ClipRRect(

//                 borderRadius: radius,

//                 child: Stack(
//                   fit: StackFit.expand,

//                   children: [

//                     // THUMBNAIL
//                     FutureBuilder<String?>(
//                       future:
//                           ThumbnailCacheService
//                               .getThumbnail(
//                         widget.videoUrl,
//                       ),

//                       builder:
//                           (context, snapshot) {

//                         if (!snapshot.hasData) {

//                           return Container(
//                             color: Colors.black12,
//                           );
//                         }

//                         return Image.file(
//                           File(snapshot.data!),
//                           fit: BoxFit.cover,
//                         );
//                       },
//                     ),

//                     // VIDEO
//                     if (_initialized)
//                       AnimatedOpacity(

//                         opacity:
//                             _hovered ? 1 : 0,

//                         duration:
//                             const Duration(
//                           milliseconds: 200,
//                         ),

//                         child: Video(
//                           controller:
//                               _controller,

//                           fit: BoxFit.cover,

//                           controls:
//                               NoVideoControls,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 5),

//             Text(
//               widget.title,

//               maxLines: 1,

//               overflow:
//                   TextOverflow.ellipsis,

//               style: const TextStyle(
//                 fontSize: 10,
//                 fontWeight:
//                     FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }