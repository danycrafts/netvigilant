import 'package:flutter/material.dart';
import 'package:netvigilant/core/theme/app_theme.dart';

enum MetricCardType {
  primary,
  secondary,
  success,
  warning,
  error,
}

class MetricCardData {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? customColor;
  final VoidCallback? onTap;

  const MetricCardData({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.customColor,
    this.onTap,
  });
}

class MetricCard extends StatelessWidget {
  final MetricCardData data;
  final MetricCardType type;

  const MetricCard({
    super.key,
    required this.data,
    this.type = MetricCardType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = _getColorScheme(theme);

    return Card(
      color: colorScheme['background'],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme['border']!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                data.icon,
                size: 24,
                color: colorScheme['icon'],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme['text'],
                      ),
                    ),
                    if (data.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        data.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme['text']?.withAlpha(180),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      data.value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme['value'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getColorScheme(ThemeData theme) {
    switch (type) {
      case MetricCardType.success:
        return {
          'background': AppColors.successGreen.withAlpha(20),
          'border': AppColors.successGreen.withAlpha(80),
          'icon': AppColors.successGreen,
          'text': theme.colorScheme.onSurface,
          'value': AppColors.successGreen,
        };
      case MetricCardType.warning:
        return {
          'background': AppColors.warningYellow.withAlpha(20),
          'border': AppColors.warningYellow.withAlpha(80),
          'icon': AppColors.warningYellow,
          'text': theme.colorScheme.onSurface,
          'value': AppColors.warningYellow,
        };
      case MetricCardType.error:
        return {
          'background': AppColors.errorRed.withAlpha(20),
          'border': AppColors.errorRed.withAlpha(80),
          'icon': AppColors.errorRed,
          'text': theme.colorScheme.onSurface,
          'value': AppColors.errorRed,
        };
      default:
        return {
          'background': data.customColor?.withAlpha(20) ?? theme.colorScheme.surfaceVariant,
          'border': data.customColor?.withAlpha(80) ?? theme.colorScheme.outline,
          'icon': data.customColor ?? theme.colorScheme.primary,
          'text': theme.colorScheme.onSurface,
          'value': data.customColor ?? theme.colorScheme.primary,
        };
    }
  }
}

class MetricRow extends StatelessWidget {
  final List<MetricCardData> metrics;

  const MetricRow({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: metrics.map((metric) {
        return MetricCard(data: metric);
      }).toList(),
    );
  }
}
