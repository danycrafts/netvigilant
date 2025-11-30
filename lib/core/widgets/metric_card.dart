import 'package:flutter/material.dart';
import 'package:netvigilant/core/theme/app_theme.dart';

enum MetricCardType { primary, secondary, warning, error, success }

class MetricCardData {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? customColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const MetricCardData({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.customColor,
    this.trailing,
    this.onTap,
  });
}

class MetricCard extends StatelessWidget {
  final MetricCardData data;
  final MetricCardType type;
  final bool isCompact;

  const MetricCard({
    super.key,
    required this.data,
    this.type = MetricCardType.primary,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconBaseColor = _getIconBaseColor(theme); // Get base color from theme or custom
    final backgroundOpacity = isCompact ? 0.05 : 0.08;

    return Card(
      elevation: isCompact ? 0 : 1, // Reduce elevation for compact cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05), // Subtle border
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final bool useSmallText = cardWidth < 180 || isCompact;

            return Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (data.icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, // Make icon background circular
                            color: iconBaseColor.withValues(alpha: backgroundOpacity),
                          ),
                          child: Icon(
                            data.icon!,
                            color: iconBaseColor,
                            size: useSmallText ? 18 : 24, // Responsive icon size
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.title,
                              style: (useSmallText ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.value,
                              style: (useSmallText ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)?.copyWith(
                                color: iconBaseColor,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (data.trailing != null) data.trailing!,
                    ],
                  ),
                  if (data.subtitle != null && !isCompact) ...[
                    const SizedBox(height: 8),
                    Text(
                      data.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getIconBaseColor(ThemeData theme) {
    if (data.customColor != null) return data.customColor!;

    switch (type) {
      case MetricCardType.primary:
        return theme.colorScheme.primary; // Use theme primary
      case MetricCardType.secondary:
        return theme.colorScheme.secondary; // Use theme secondary
      case MetricCardType.warning:
        return AppColors.warningOrange;
      case MetricCardType.error:
        return AppColors.errorRed;
      case MetricCardType.success:
        return AppColors.successGreen;
    }
  }
}

class MetricRow extends StatelessWidget {
  final List<MetricCardData> metrics;
  final bool isCompact;

  const MetricRow({
    super.key,
    required this.metrics,
    this.isCompact = false, // Changed default to false for less compact by default
  });

  @override
  Widget build(BuildContext context) {
    // Using Wrap for better responsiveness, allowing items to flow to the next line
    return Wrap(
      spacing: 12, // Horizontal spacing between cards
      runSpacing: 12, // Vertical spacing between lines of cards
      alignment: WrapAlignment.start, // Align cards to the start
      children: metrics.map((metric) {
        return SizedBox( // Use SizedBox with width for consistent sizing, or Flexible if a row is preferred.
          width: isCompact ? 160 : (MediaQuery.of(context).size.width / 2) - 24, // Example width: half screen minus padding
          child: MetricCard(
            data: metric,
            isCompact: isCompact,
          ),
        );
      }).toList(),
    );
  }
}