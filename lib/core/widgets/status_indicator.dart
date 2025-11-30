import 'package:flutter/material.dart';
import 'package:netvigilant/core/theme/app_theme.dart';

enum StatusType {
  success,
  warning,
  error,
  neutral,
}

class LiveStatusIndicator extends StatefulWidget {
  final String text;

  const LiveStatusIndicator({super.key, required this.text});

  @override
  _LiveStatusIndicatorState createState() => _LiveStatusIndicatorState();
}

class _LiveStatusIndicatorState extends State<LiveStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_animationController),
      child: StatusIndicator(
        status: StatusType.success,
        text: widget.text,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}


class StatusIndicator extends StatelessWidget {
  final StatusType status;
  final String text;

  const StatusIndicator({
    super.key,
    required this.status,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = _getColorScheme(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme['background'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme['border']!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 14,
            color: colorScheme['icon'],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme['text'],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (status) {
      case StatusType.success:
        return Icons.check_circle;
      case StatusType.warning:
        return Icons.warning;
      case StatusType.error:
        return Icons.error;
      case StatusType.neutral:
        return Icons.info;
    }
  }

  Map<String, Color> _getColorScheme(ThemeData theme) {
    switch (status) {
      case StatusType.success:
        return {
          'background': AppColors.successGreen.withAlpha(20),
          'border': AppColors.successGreen.withAlpha(80),
          'icon': AppColors.successGreen,
          'text': AppColors.successGreen,
        };
      case StatusType.warning:
        return {
          'background': AppColors.warningYellow.withAlpha(20),
          'border': AppColors.warningYellow.withAlpha(80),
          'icon': AppColors.warningYellow,
          'text': AppColors.warningYellow,
        };
      case StatusType.error:
        return {
          'background': AppColors.errorRed.withAlpha(20),
          'border': AppColors.errorRed.withAlpha(80),
          'icon': AppColors.errorRed,
          'text': AppColors.errorRed,
        };
      case StatusType.neutral:
      default:
        return {
          'background': theme.colorScheme.secondaryContainer,
          'border': theme.colorScheme.outline,
          'icon': theme.colorScheme.onSecondaryContainer,
          'text': theme.colorScheme.onSecondaryContainer,
        };
    }
  }
}
