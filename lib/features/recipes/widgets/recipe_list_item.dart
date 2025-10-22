import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'auto_selected_ribbon.dart';

/// HelloChef-style two-column recipe row: info left, image + Add button right
/// Used on wider screens for a more compact, list-style layout
class RecipeListItem extends StatelessWidget {
  final String id;
  final String title;
  final String? subtitle;
  final String? category;
  final String? imageUrl;
  final List<String> tags;
  final bool selected;
  final bool autoSelected;
  final VoidCallback onToggle;

  const RecipeListItem({
    super.key,
    required this.id,
    required this.title,
    this.subtitle,
    this.category,
    required this.imageUrl,
    required this.tags,
    required this.selected,
    this.autoSelected = false,
    required this.onToggle,
  });

  void _handleTap() {
    HapticFeedback.selectionClick();
    onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: text/meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      category!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // RIGHT: image + ribbon + Add button
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 150,
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: imageUrl != null && imageUrl!.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: imageUrl!,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                memCacheWidth: (150 *
                                        MediaQuery.of(context)
                                            .devicePixelRatio *
                                        1.5)
                                    .round(),
                                placeholder: (context, url) => Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.restaurant_menu,
                                    size: 40,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              )
                            : imageUrl != null
                                ? Image.asset(
                                    imageUrl!,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        child: Icon(
                                          Icons.restaurant_menu,
                                          size: 40,
                                          color: theme
                                              .colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.3),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.restaurant_menu,
                                      size: 40,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                      ),
                      // Auto-selected ribbon
                      if (autoSelected)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: AutoSelectedRibbon(visible: autoSelected),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 150,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface,
                    foregroundColor: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                  onPressed: _handleTap,
                  icon: Icon(
                    selected ? Icons.check : Icons.add,
                    size: 18,
                  ),
                  label: Text(
                    selected ? 'Added' : 'Add',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
