import 'package:flutter/material.dart';
import '../apis/reward_api.dart';
import '../models/reward_box_model.dart';
import '../provider/reward_provider.dart';

class RewardDrawer extends StatefulWidget {
  final RewardProvider rewardProvider;

  const RewardDrawer({super.key, required this.rewardProvider});

  @override
  State<RewardDrawer> createState() => _RewardDrawerState();
}

class _RewardDrawerState extends State<RewardDrawer> {
  int _charVisible  = 6;
  int _badgeVisible = 6;
  static const int _step = 6;
  String? _selectedCharacterName;

  @override
  Widget build(BuildContext context) {
    print('loading=${widget.rewardProvider.isLoading} '
      'error=${widget.rewardProvider.fetchError} '
      'chars=${widget.rewardProvider.apiCharacters.length} '
      'reactions=${widget.rewardProvider.reactions.length}');
    // Loading / error states
    if (widget.rewardProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00bd74)),
      );
    }
    if (widget.rewardProvider.fetchError != null) {
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
                  backgroundColor: const Color(0xFF00bd74)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
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
            )
          ],
        ),
        child: Column(
          children: [
            _header(),
            _columnHeadings(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _characterColumn()),
                  Container(width: 1, color: const Color(0xFFE0E0E0)),
                  Expanded(child: _badgeColumn()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top header ────────────────────────────────────────────────────────────

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
            '🏅  REWARD BOX',
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

  // ── Column headings ───────────────────────────────────────────────────────

  Widget _columnHeadings() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _sectionHeading(
              emoji: '🧑',
              label: 'Characters',
              bgColor: const Color(0xFFE8F5E9),
              textColor: const Color(0xFF2E7D32),
            ),
          ),
          Container(width: 1, color: const Color(0xFFE0E0E0)),
          Expanded(
            child: _sectionHeading(
              emoji: '🎖️',
              label: 'Reward Badges',
              bgColor: const Color(0xFFE0F2F1),
              textColor: const Color(0xFF00796B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading({
    required String emoji,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      color: bgColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LEFT: character column ────────────────────────────────────────────────

  Widget _characterColumn() {
    final all     = widget.rewardProvider.apiCharacters;
    final shown   = all.take(_charVisible).toList();
    final hasMore = _charVisible < all.length;
    final canLess = _charVisible > _step;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      children: [
        ...shown.map(_characterTile),
        if (hasMore || canLess)
          _loadControl(
            hasMore: hasMore,
            canLess: canLess,
            onMore: () => setState(() => _charVisible += _step),
            onLess: () => setState(() =>
                _charVisible = (_charVisible - _step).clamp(_step, all.length)),
          ),
      ],
    );
  }

  Widget _characterTile(CharacterItem c) {
    final isSelected = _selectedCharacterName == c.name;
    const accent = Color(0xFF00bd74);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCharacterName = c.name);
        widget.rewardProvider.selectCharacterFromApi(c);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withOpacity(0.4)
              : accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : accent.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 8)]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.3),
                border: isSelected
                    ? Border.all(color: accent, width: 2)
                    : null,
              ),
              child: ClipOval(
                child: Image.network(
                  RewardApi.fullUrl(c.imagePath),
                  fit: BoxFit.cover,
                  headers: const {'ngrok-skip-browser-warning': 'true'},
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: accent),
                          ),
                        ),
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 28, color: accent),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              c.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── RIGHT: reaction/badge column ──────────────────────────────────────────

  Widget _badgeColumn() {
    final all     = widget.rewardProvider.reactions;
    final shown   = all.take(_badgeVisible).toList();
    final hasMore = _badgeVisible < all.length;
    final canLess = _badgeVisible > _step;

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: shown.map(_reactionTile).toList(),
        ),
        if (hasMore || canLess)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _loadControl(
              hasMore: hasMore,
              canLess: canLess,
              onMore: () => setState(() => _badgeVisible += _step),
              onLess: () => setState(() => _badgeVisible =
                  (_badgeVisible - _step).clamp(_step, all.length)),
            ),
          ),
      ],
    );
  }

  Widget _reactionTile(ReactionItem r) {
    return GestureDetector(
      onTap: () => widget.rewardProvider.launchReaction(r),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF00796B),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              RewardApi.fullUrl(r.gifPath),
              width: 38,
              height: 38,
              headers: const {'ngrok-skip-browser-warning': 'true'},
              errorBuilder: (_, __, ___) => const Icon(
                Icons.emoji_emotions,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              r.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Load control ──────────────────────────────────────────────────────────

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
          if (hasMore) _pill(icon: Icons.expand_more, label: 'More', onTap: onMore),
          if (hasMore && canLess) const SizedBox(width: 6),
          if (canLess) _pill(icon: Icons.expand_less, label: 'Less', onTap: onLess),
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
            color: Colors.black87, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
