import 'dart:async';

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
  Player? _hoverPlayer;
  VideoController? _hoverController;
  OverlayEntry? _overlayEntry;

  /// URL currently being async-loaded — lets us cancel stale loads
  /// when the mouse moves to a different item before loading finishes.
  String? _loadingUrl;

  /// 300 ms debounce so we don't fire previews on quick mouse passes.
  Timer? _hoverDebounce;

  // ────────────────────────────────────────────
  void _closeLibrary() {
    widget.videoProvider.toggleLibrary();
    widget.onClose();
  }

  // ── Single entry point for all hover-enters ──
  void _onHoverEnter(VideoItem video, Offset position, Size itemSize) {
    // Always cancel the pending debounce and nuke the current overlay
    // so only ONE overlay can ever exist at a time.
    _hoverDebounce?.cancel();
    _removeOverlay();

    _hoverDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (video.isExternal) {
        _showExternalInfoOverlay(video);
      } else {
        _showMp4PreviewOverlay(video);
      }
    });
  }

  void _onHoverExit() {
    _hoverDebounce?.cancel();
    _removeOverlay();
  }

  // ── MP4 preview (media_kit) ──────────────────
  Future<void> _showMp4PreviewOverlay(VideoItem video) async {
  final targetUrl = video.url;
  _loadingUrl = targetUrl;

  final player = Player();
  final controller = VideoController(player);

  // IMPORTANT:
  // Assign first before async work.
  _hoverPlayer = player;
  _hoverController = controller;

  // Insert overlay BEFORE opening media.
  _insertOverlay(
    child: HoverPreviewPopup(
      controller: controller,
      title: video.title,
    ),
    width: 280,
    height: 180,
  );

  try {
    await player.setVolume(0);

    // Small delay helps texture initialization on Flutter desktop/web.
    await Future.delayed(const Duration(milliseconds: 80));

    await player.open(
      Media(targetUrl),
      play: true,
    );

    await player.setPlaylistMode(PlaylistMode.loop);

    // stale hover protection
    if (!mounted || _loadingUrl != targetUrl) {
      await player.dispose();
    }
  } catch (e) {
    debugPrint('Preview failed: $e');
    _removeOverlay();
  }
}

  

  // ── External link info card ──────────────────
   // ── External / YouTube preview ──────────────────
void _showExternalInfoOverlay(VideoItem video) {
  if (!mounted) return;

  final url = video.url.toLowerCase();

  // Detect YouTube links
  final isYoutube =
      url.contains('youtube.com') ||
      url.contains('youtu.be');

  if (isYoutube) {
    // Show mini YouTube preview
    _insertOverlay(
      child: _YoutubePreviewCard(video: video),
      width: 280,
      height: 180,
    );
  } else {
    // Fallback normal external card
    _insertOverlay(
      child: _ExternalLinkCard(video: video),
      width: 280,
      height: 130,
    );
  }
}

  // ── Shared overlay inserter ──────────────────
  void _insertOverlay({
    required Widget child,
    required double width,
    required double height,
  }) {
    // Hard guarantee: remove any existing overlay before inserting
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (!mounted) return;

    final screenSize = MediaQuery.of(context).size;
    final double left = (screenSize.width / 2) - (width / 2);
    final double top = (screenSize.height / 2) - (height / 2);

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        width: width,
        child: Material(color: Colors.transparent, child: child),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // ── Tear down overlay + player ───────────────
  void _removeOverlay() {
    _loadingUrl = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _hoverPlayer?.dispose();
    _hoverPlayer = null;
    _hoverController = null;
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
    _hoverDebounce?.cancel();
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Filtered topics ──────────────────────────
  List<MainTopic> get _filteredTopics {
    final source = widget.videoProvider.topics;
    if (_searchQuery.isEmpty) return source;

    final query = _searchQuery.toLowerCase();
    final List<MainTopic> result = [];

    for (final mainTopic in source) {
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
                  const Icon(
                    Icons.video_library_outlined,
                    size: 18,
                    color: Color(0xFF00796B),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Select Video',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  _LegendBadge(isExternal: false),
                  const SizedBox(width: 6),
                  _LegendBadge(isExternal: true),
                  const SizedBox(width: 12),
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

            // ── List ─────────────────────────────────
            Expanded(
              child: widget.videoProvider.isLoadingTopics
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00796B),
                      ),
                    )
                  : widget.videoProvider.topicsError != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wifi_off_outlined,
                                size: 40,
                                color: Color(0xFFB2DFDB),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.videoProvider.topicsError!,
                                style: const TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: widget.videoProvider.fetchTopics,
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(color: Color(0xFF00796B)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _filteredTopics.isEmpty
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
                                final isMainExpanded =
                                    _expandedMainTopics.contains(mainTopic.title);

                                return Column(
                                  children: [
                                    // ── MainTopic Row ──────────
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        isMainExpanded
                                            ? _expandedMainTopics
                                                .remove(mainTopic.title)
                                            : _expandedMainTopics
                                                .add(mainTopic.title);
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
                                          borderRadius:
                                              BorderRadius.circular(12),
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

                                    // ── SubTopics ──────────────
                                    if (isMainExpanded)
                                      ...mainTopic.subTopics.map((subTopic) {
                                        final subKey =
                                            '${mainTopic.title}_${subTopic.title}';
                                        final isSubExpanded =
                                            _expandedSubTopics.contains(subKey);

                                        final mp4Count = subTopic.videos
                                            .where((v) => v.isMp4)
                                            .length;
                                        final linkCount = subTopic.videos
                                            .where((v) => v.isExternal)
                                            .length;

                                        return Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () => setState(() {
                                                isSubExpanded
                                                    ? _expandedSubTopics
                                                        .remove(subKey)
                                                    : _expandedSubTopics
                                                        .add(subKey);
                                              }),
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  left: 28,
                                                  right: 12,
                                                  top: 4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFE0F2F1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: const Color(
                                                        0xFF80CBC4),
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
                                                          color:
                                                              Color(0xFF004D40),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    if (mp4Count > 0)
                                                      _SubtopicCount(
                                                        count: mp4Count,
                                                        isExternal: false,
                                                      ),
                                                    if (mp4Count > 0 &&
                                                        linkCount > 0)
                                                      const SizedBox(width: 4),
                                                    if (linkCount > 0)
                                                      _SubtopicCount(
                                                        count: linkCount,
                                                        isExternal: true,
                                                      ),
                                                    const SizedBox(width: 6),
                                                    Icon(
                                                      isSubExpanded
                                                          ? Icons
                                                              .keyboard_arrow_up
                                                          : Icons
                                                              .keyboard_arrow_down,
                                                      color: const Color(
                                                          0xFF00796B),
                                                      size: 18,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // ── Video Items ──────
                                            if (isSubExpanded)
                                              ...subTopic.videos.map((video) {
                                                return VideoHoverItem(
                                                  video: video,
                                                  onTap: () {
                                                    _onHoverExit();
                                                    widget.videoProvider
                                                        .selectVideo(video);
                                                    _closeLibrary();
                                                  },
                                                  onHoverEnter: (pos, size) =>
                                                      _onHoverEnter(
                                                          video, pos, size),
                                                  onHoverExit: _onHoverExit,
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

// ─────────────────────────────────────────────────────────────
// EXTERNAL LINK INFO CARD
// Shown on hover for link-type items instead of a video preview.
// ─────────────────────────────────────────────────────────────
class _ExternalLinkCard extends StatefulWidget {
  final VideoItem video;
  const _ExternalLinkCard({required this.video});

  @override
  State<_ExternalLinkCard> createState() => _ExternalLinkCardState();
}

class _ExternalLinkCardState extends State<_ExternalLinkCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2920),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFB74D).withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: icon + labels ─────────────
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFB74D).withOpacity(0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.open_in_new_rounded,
                      color: Color(0xFFFFB74D),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXTERNAL LINK',
                        style: TextStyle(
                          color: Color(0xFFFFB74D),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Opens in browser · No preview',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 10),

              // ── Video title ────────────────────────
              Text(
                widget.video.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // ── URL chip ───────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  widget.video.url,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUBTOPIC COUNT BADGE
// ─────────────────────────────────────────────────────────────
class _SubtopicCount extends StatelessWidget {
  final int count;
  final bool isExternal;

  const _SubtopicCount({required this.count, required this.isExternal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isExternal
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isExternal
              ? const Color(0xFFFFB74D)
              : const Color(0xFF81C784),
        ),
      ),
      child: Text(
        '$count ${isExternal ? 'link${count > 1 ? 's' : ''}' : 'mp4${count > 1 ? 's' : ''}'}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isExternal
              ? const Color(0xFFE65100)
              : const Color(0xFF2E7D32),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER LEGEND BADGE
// ─────────────────────────────────────────────────────────────
class _LegendBadge extends StatelessWidget {
  final bool isExternal;
  const _LegendBadge({required this.isExternal});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isExternal
                ? const Color(0xFFFFB74D)
                : const Color(0xFF81C784),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isExternal ? 'Link' : 'MP4',
          style: TextStyle(
            fontSize: 11,
            color: isExternal
                ? const Color(0xFFE65100)
                : const Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────
// YOUTUBE / EXTERNAL MINI PREVIEW
// ─────────────────────────────────────────────
class _YoutubePreviewCard extends StatefulWidget {
  final VideoItem video;

  const _YoutubePreviewCard({
    required this.video,
  });

  @override
  State<_YoutubePreviewCard> createState() =>
      _YoutubePreviewCardState();
}

class _YoutubePreviewCardState
    extends State<_YoutubePreviewCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  late final Animation<double> _fade;

  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _ac = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 220,
      ),
    );

    _fade = CurvedAnimation(
      parent: _ac,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ac,
        curve: Curves.easeOut,
      ),
    );

    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // EXTRACT YOUTUBE THUMBNAIL
  // ─────────────────────────────────────────
  String _thumbnail(String url) {
    try {
      final uri = Uri.parse(url);

      String? id;

      if (uri.host.contains('youtu.be')) {
        id = uri.pathSegments.first;
      } else {
        id = uri.queryParameters['v'];
      }

      if (id == null || id.isEmpty) {
        return '';
      }

      return 'https://img.youtube.com/vi/$id/0.jpg';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = _thumbnail(widget.video.url);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: 280,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [

              // ─────────────────────────────
              // THUMBNAIL
              // ─────────────────────────────
              if (thumb.isNotEmpty)
                Image.network(
                  thumb,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: Colors.black87,
                ),

              // ─────────────────────────────
              // DARK OVERLAY
              // ─────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),

              // ─────────────────────────────
              // PLAY ICON
              // ─────────────────────────────
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.92),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),

              // ─────────────────────────────
              // YOUTUBE BADGE
              // ─────────────────────────────
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'YOUTUBE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─────────────────────────────
              // TITLE
              // ─────────────────────────────
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  widget.video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

