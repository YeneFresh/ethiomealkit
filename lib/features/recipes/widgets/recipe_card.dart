import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_tokens.dart';
import 'auto_selected_ribbon.dart';

/// Single-column Instagram-style recipe card with expandable chef notes
class RecipeCard extends StatefulWidget {
  final String id;
  final String title;
  final String? imageUrl;
  final List<String> tags;
  final bool isSelected;
  final VoidCallback onTap;
  final String? chefNote;
  final int selectedCount;
  final int allowedCount;
  final bool autoSelected; // NEW: flag to show auto-selected ribbon

  const RecipeCard({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.tags,
    required this.isSelected,
    required this.onTap,
    this.chefNote,
    required this.selectedCount,
    required this.allowedCount,
    this.autoSelected = false, // NEW
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _showNote = false;

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  List<_BadgeData> _getBadges() {
    final badges = <_BadgeData>[];
    final tagSet = widget.tags.map((t) => t.toLowerCase()).toSet();

    if (tagSet.contains("chef's choice") || tagSet.contains('chef_choice')) {
      badges.add(_BadgeData(
        label: "Chef's Choice",
        color: Yf.gold600,
        icon: Icons.star,
      ));
    }
    if (tagSet.contains('express') ||
        tagSet.contains('quick') ||
        tagSet.contains('30-min')) {
      badges.add(_BadgeData(
        label: 'Express',
        color: Yf.success600,
        icon: Icons.bolt,
      ));
    }
    if (tagSet.contains('family') || tagSet.contains('family-friendly')) {
      badges.add(_BadgeData(
        label: 'Family',
        color: Color(0xFF1565C0),
        icon: Icons.people,
      ));
    }
    if (tagSet.contains('new')) {
      badges.add(_BadgeData(
        label: 'New',
        color: Color(0xFF4CAF50),
        icon: Icons.fiber_new,
      ));
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badges = _getBadges();
    final hasChefNote = widget.chefNote != null && widget.chefNote!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias, // Ensure rounded corners apply to children
      elevation: 0.8,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: widget.isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image (4:3 aspect ratio for consistent framing)
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 4 / 3, // Industry-consistent 4:3 ratio
              child: Stack(
                children: [
                  // Main image
                  if (widget.imageUrl != null)
                    FadeInImage(
                      placeholder: MemoryImage(_transparentPixel),
                      image: AssetImage(widget.imageUrl!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter, // Better framing for food
                      imageErrorBuilder: (context, error, stackTrace) {
                        return _buildImageFallback(theme);
                      },
                      fadeInDuration: const Duration(milliseconds: 200),
                    )
                  else
                    _buildImageFallback(theme),

                  // Auto-selected ribbon (top-left, above badges)
                  if (widget.autoSelected)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: AutoSelectedRibbon(visible: widget.autoSelected),
                    ),

                  // Badges overlay (top-left, below ribbon)
                  if (badges.isNotEmpty)
                    Positioned(
                      top: widget.autoSelected ? 36 : Yf.s8, // Offset if ribbon present
                      left: Yf.s8,
                      child: Wrap(
                        spacing: Yf.s8,
                        runSpacing: Yf.s8,
                        children: badges
                            .map((badge) => _BadgeChip(badge: badge))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(Yf.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),

                SizedBox(height: Yf.s12),

                // Selection button row (industry-standard pill style)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: widget.isSelected
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.5)
                                : Colors.black12,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: widget.isSelected
                              ? theme.colorScheme.primary
                              : Colors.black87,
                          backgroundColor: widget.isSelected
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.08)
                              : null,
                        ),
                        onPressed: _handleTap,
                        icon: Icon(
                          widget.isSelected ? Icons.check : Icons.add,
                          size: 18,
                        ),
                        label: Text(
                          widget.isSelected ? 'Added' : 'Add',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Chef's note button
                    if (hasChefNote)
                      TextButton.icon(
                        onPressed: () => setState(() => _showNote = !_showNote),
                        icon: Icon(
                          Icons.restaurant_menu,
                          size: 16,
                          color: Yf.brown700,
                        ),
                        label: Text(
                          _showNote ? 'Hide note' : 'Chef\'s note',
                          style: TextStyle(color: Yf.brown700, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                // Expandable chef note
                if (_showNote && hasChefNote) ...[
                  SizedBox(height: Yf.s12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Yf.s12),
                    decoration: BoxDecoration(
                      color: Yf.peach50,
                      borderRadius: Yf.borderRadius12,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Yf.gold600,
                        ),
                        SizedBox(width: Yf.s8),
                        Expanded(
                          child: Text(
                            widget.chefNote!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Yf.ink900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // 1x1 transparent pixel for placeholder
  static final _transparentPixel = Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);
}

class _BadgeData {
  final String label;
  final Color color;
  final IconData icon;

  _BadgeData({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _BadgeChip extends StatelessWidget {
  final _BadgeData badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: badge.color.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badge.icon,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            badge.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
