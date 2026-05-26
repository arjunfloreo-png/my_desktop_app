import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/mini_video_charater_reaction_model.dart';
import '../models/mini_vod.dart';
import '../provider/reward_provider.dart';
import 'hover_preview_widget.dart';

class RewardDrawer extends StatefulWidget {
  final RewardProvider rewardProvider;

  const RewardDrawer({super.key, required this.rewardProvider});

  @override
  State<RewardDrawer> createState() => _RewardDrawerState();
}

class _RewardDrawerState extends State<RewardDrawer>
    with SingleTickerProviderStateMixin {
  int _charVisible = 6;
  int _badgeVisible = 6;
  static const int _step = 6;
  String? _selectedVodId;
  String? _hoveredVodId;

  late final ScrollController _charScrollCtrl;
  late final ScrollController _badgeScrollCtrl;
  late final AnimationController _tabCtrl;
  late final Animation<Color?> _tabColorAnim;

  int _activeTab = 0; // 0 = characters, 1 = reactions

  @override
  void initState() {
    super.initState();
    _charScrollCtrl = ScrollController();
    _badgeScrollCtrl = ScrollController();

    _tabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tabColorAnim = ColorTween(
      begin: const Color(0xFF2E7D32),
      end: const Color(0xFF00796B),
    ).animate(_tabCtrl);

    _charScrollCtrl.addListener(_onCharacterScroll);
    _badgeScrollCtrl.addListener(_onReactionScroll);
  }

  void _onCharacterScroll() {
    if (_charScrollCtrl.position.pixels >
        _charScrollCtrl.position.maxScrollExtent * 0.7) {
      widget.rewardProvider.prefetchMore(_charVisible, _step);
    }
  }

  void _onReactionScroll() {
    if (_badgeScrollCtrl.position.pixels >
        _badgeScrollCtrl.position.maxScrollExtent * 0.7) {
      widget.rewardProvider.prefetchMore(
        widget.rewardProvider.characterVods.length + _badgeVisible,
        _step,
      );
    }
  }

  @override
  void dispose() {
    _charScrollCtrl.dispose();
    _badgeScrollCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int tab) {
    setState(() => _activeTab = tab);
    if (tab == 0) {
      _tabCtrl.reverse();
    } else {
      _tabCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rewardProvider.isLoading) {
      return _loadingState();
    }

    if (widget.rewardProvider.fetchError != null) {
      return _errorState();
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.3,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xff00bd74), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _header(),
            _tabBar(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: _activeTab == 0 ? _characterVodGrid() : _reactionVodGrid(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF00796B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '🎬 MINI VOD KIT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.rewardProvider.toggleDrawer,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────

  Widget _tabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          _tabButton(
            label: '🎬 Gifs',
            isActive: _activeTab == 0,
            onTap: () => _switchTab(0),
          ),
          const SizedBox(width: 6),
          _tabButton(
            label: '⚡ Player',
            isActive: _activeTab == 1,
            onTap: () => _switchTab(1),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00bd74) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  // ── Character VOD Grid ────────────────────────────────────────────────

  Widget _characterVodGrid() {
    final all = widget.rewardProvider.characterVods;
    if (all.isEmpty) {
      return Center(
        child: Text(
          'No character VODs loaded',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      );
    }

    return ListView(
      controller: _charScrollCtrl,
      padding: const EdgeInsets.all(10),
      children: [
        GridView.builder(
          itemCount: all.length,
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
         itemBuilder: (context, index) {
  final vod = all[index];
  print('Building tile for ${vod.thumbnailUrl}');
  return Column(
    children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: vod.character != null
              ? CachedNetworkImage(
                  imageUrl: vod.thumbnailUrl,
                  fit: BoxFit.cover,
                  httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00bd74),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child:
                        const Icon(Icons.person, color: Color(0xFF00bd74)),
                  ),
                )
              : Container(color: Colors.grey[800]),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        vod.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    ],
  );
},
        ),
        //   GridView.count(
        //     crossAxisCount: 2,
        //     crossAxisSpacing: 8,
        //     mainAxisSpacing: 8,
        //     shrinkWrap: true,
        //     physics: const NeverScrollableScrollPhysics(),
        //     children: [
        //       Text(
        //         'Character VODs are short clips (usually 5-15 seconds) that show a character performing a specific reaction or action. Click on any tile to play the VOD in the player tab.',
        //         style: TextStyle(color: Colors.grey[700], fontSize: 11),

        //       ),
        //     ]
        //  //   all.map(_vodTile).toList(),
        //   ),
      ],
    );
  }

  // ── Reaction VOD Grid ─────────────────────────────────────────────────

  Widget _reactionVodGrid() {
    final all = widget.rewardProvider.reactionVods;
    final selectedVod = widget.rewardProvider.selectedReactionVod;

    if (all.isEmpty) {
      return Center(
        child: Text(
          'No reaction VODs loaded',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      );
    }

    final shown = all.take(_badgeVisible).toList();
    final hasMore = _badgeVisible < all.length;
    final canLess = _badgeVisible > _step;

    return ListView(
      controller: _badgeScrollCtrl,
      padding: const EdgeInsets.all(10),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: shown.map(_vodTile).toList(),
        ),
        if (hasMore || canLess)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _loadControl(
              hasMore: hasMore,
              canLess: canLess,
              onMore: () => setState(() => _badgeVisible += _step),
              onLess: () => setState(
                () => _badgeVisible = (_badgeVisible - _step).clamp(
                  _step,
                  all.length,
                ),
              ),
            ),
          ),
        if (selectedVod != null) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          _reactionPlayerArea(selectedVod),
        ],
      ],
    );
  }

  Widget _reactionPlayerArea(MiniVod vod) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Playing: ${vod.name}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00bd74), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: HoverVideoPreview(videoUrl: vod.videoUrl),
          ),
        ),
      ],
    );
  }

  // ── VOD Tile ──────────────────────────────────────────────────────────

  Widget _vodTile(MiniVod vod) {
    final isSelected = _selectedVodId == vod.id;
    final isHovered = _hoveredVodId == vod.id;

    const accent = Color(0xFF00bd74);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hoveredVodId = vod.id);
      },
      onExit: (_) {
        setState(() => _hoveredVodId = null);
      },
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedVodId = vod.id);
          widget.rewardProvider.selectVod(vod);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accent : accent.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 10)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                /// AUTO PLAY VIDEO ON HOVER
                if (isHovered)
                  HoverVideoPreview(videoUrl: vod.videoUrl)
                else
                  _cachedThumbnail(vod.thumbnailUrl),

                /// Duration badge
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDuration(vod.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                /// Play overlay
                if (!isHovered && !isSelected)
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                /// Selected overlay
                if (isSelected)
                  Container(
                    color: accent.withOpacity(0.2),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: accent,
                        size: 36,
                      ),
                    ),
                  ),

                /// Name label
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                    child: Text(
                      vod.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cachedThumbnail(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
      placeholder: (context, url) => Container(
        color: Colors.grey[800],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00bd74),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[800],
        child: const Icon(Icons.play_circle_outline, color: Color(0xFF00bd74)),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = (d.inSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Load control ──────────────────────────────────────────────────────

  Widget _loadControl({
    required bool hasMore,
    required bool canLess,
    required VoidCallback onMore,
    required VoidCallback onLess,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasMore)
            _pill(icon: Icons.expand_more, label: 'More', onTap: onMore),
          if (hasMore && canLess) const SizedBox(width: 6),
          if (canLess)
            _pill(icon: Icons.expand_less, label: 'Less', onTap: onLess),
        ],
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() {
    return Center(
      child: CircularProgressIndicator(color: const Color(0xFF00bd74)),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(
            widget.rewardProvider.fetchError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: widget.rewardProvider.loadRewardBox,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00bd74),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
