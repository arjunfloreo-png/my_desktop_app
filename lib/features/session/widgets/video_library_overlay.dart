import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/video_item.dart';
import '../provider/video_provider.dart';
import 'hover_preview_popup.dart';
import 'video_hover_item.dart';

class VideoLibraryOverlay extends StatefulWidget {
  final VideoProvider videoProvider;
  final VoidCallback onClose;

  const VideoLibraryOverlay({
    super.key,
    required this.videoProvider,
    required this.onClose,
  });

  @override
  State<VideoLibraryOverlay> createState() => _VideoLibraryOverlayState();
}

class _VideoLibraryOverlayState extends State<VideoLibraryOverlay> {

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  final Set<String> _expandedMainTopics = {};
  final Set<String> _expandedSubTopics = {};

  // ── Hover preview state ──────────────────────
  Player? _hoverPlayer; // It is the engine that : loads videos,plays videos,pauses videos and 
  VideoController? _hoverController; // The controller connects the player to the UI widget.
  String? _hoverVideoUrl;
  bool _isPreviewReady = false;
  OverlayEntry? _overlayEntry; // overlays FLOAT ABOVE everything

  void _closeLibrary() {
    widget.videoProvider.toggleLibrary();
    widget.onClose();
  }

  // ── Start hover preview ──────────────────────
  Future<void> _showHoverPreview(
    VideoItem video,
    Offset position,
    Size itemSize,
  ) async {
    //Remove old preview = Create new preview

    _removeOverlay(); //remove existing preview

    _hoverVideoUrl = video.url;
    _isPreviewReady = false;
     // Create New Player
    _hoverPlayer = Player(); //creates a temporary mini player
    //Create Controller
    _hoverController = VideoController(_hoverPlayer!);

    await _hoverPlayer!.setVolume(0);
    await _hoverPlayer!.open(Media(video.url), play: true);
    await _hoverPlayer!.setPlaylistMode(PlaylistMode.loop);

    if (!mounted) return;

    _isPreviewReady = true;

    final screenSize = MediaQuery.of(context).size;
    const previewWidth = 480.0;
    const previewHeight = 300.0;

    // ── Perfectly centered on screen ────────────
    final double left = (screenSize.width / 2) - (previewWidth / 2);
    final double top = (screenSize.height / 2) - (previewHeight / 2);

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: HoverPreviewPopup(
            controller: _hoverController!,
            title: video.title,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // ── Remove hover preview ─────────────────────
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _hoverPlayer?.dispose();
    _hoverPlayer = null;
    _hoverController = null;
    _hoverVideoUrl = null;
    _isPreviewReady = false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<MainTopic> get _filteredTopics {
    if (_searchQuery.isEmpty) return allTopics;

    final query = _searchQuery.toLowerCase();
    List<MainTopic> result = [];

    for (final mainTopic in allTopics) {
      final matchingSubTopics = <SubTopic>[];

      for (final subTopic in mainTopic.subTopics) {
        final matchingVideos = subTopic.videos
            .where((v) => v.title.toLowerCase().contains(query))
            .toList();

        if (subTopic.title.toLowerCase().contains(query)) {
          matchingSubTopics.add(subTopic);
        } else if (matchingVideos.isNotEmpty) {
          matchingSubTopics.add(
            SubTopic(title: subTopic.title, videos: matchingVideos),
          );
        }
      }

      if (mainTopic.title.toLowerCase().contains(query)) {
        result.add(mainTopic);
      } else if (matchingSubTopics.isNotEmpty) {
        result.add(
          MainTopic(title: mainTopic.title, subTopics: matchingSubTopics),
        );
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 60,
      right: 60,
      top: 80,
      bottom: 120,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20),
          ],
        ),
        child: Column(
          children: [
            // ── Header ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Select Video',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _closeLibrary,
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),

            // ── Search ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  filled: true,
                  fillColor: const Color(0xFFE8F5F0),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF00796B),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          }),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF9E9E9E),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // ── Expandable List ───────────────────────
            Expanded(
              child: _filteredTopics.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 40,
                            color: Color(0xFFB2DFDB),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No videos found',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredTopics.length,
                      itemBuilder: (_, mainIndex) {
                        final mainTopic = _filteredTopics[mainIndex];
                        final isMainExpanded = _expandedMainTopics.contains(
                          mainTopic.title,
                        );

                        return Column(
                          children: [
                            // ── MainTopic Row ─────────────
                            GestureDetector(
                              onTap: () => setState(() {
                                if (isMainExpanded) {
                                  _expandedMainTopics.remove(mainTopic.title);
                                } else {
                                  _expandedMainTopics.add(mainTopic.title);
                                }
                              }),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00796B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.folder_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        mainTopic.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isMainExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── SubTopics ─────────────────
                            if (isMainExpanded)
                              ...mainTopic.subTopics.map((subTopic) {
                                final subKey =
                                    '${mainTopic.title}_${subTopic.title}';
                                final isSubExpanded = _expandedSubTopics
                                    .contains(subKey);

                                return Column(
                                  children: [
                                    // SubTopic Row
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        if (isSubExpanded) {
                                          _expandedSubTopics.remove(subKey);
                                        } else {
                                          _expandedSubTopics.add(subKey);
                                        }
                                      }),
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          left: 28,
                                          right: 12,
                                          top: 4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2F1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF80CBC4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.folder_open_outlined,
                                              color: Color(0xFF00796B),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                subTopic.title,
                                                style: const TextStyle(
                                                  color: Color(0xFF004D40),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${subTopic.videos.length} video${subTopic.videos.length > 1 ? 's' : ''}',
                                              style: const TextStyle(
                                                color: Color(0xFF80CBC4),
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              isSubExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: const Color(0xFF00796B),
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // ── Video Items with Hover Preview ──
                                    if (isSubExpanded)
                                      ...subTopic.videos.map((video) {
                                        return VideoHoverItem(
                                          video: video,
                                          onTap: () {
                                            _removeOverlay();
                                            widget.videoProvider.selectVideo(
                                              video,
                                            );
                                            _closeLibrary();
                                          },
                                          onHoverEnter: (position, size) {
                                            _showHoverPreview(
                                              video,
                                              position,
                                              size,
                                            );
                                          },
                                          onHoverExit: _removeOverlay,
                                        );
                                      }),
                                  ],
                                );
                              }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


