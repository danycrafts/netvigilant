import 'package:flutter/material.dart';
import 'package:netvigilant/core/theme/app_theme.dart';

enum StatusType { success, warning, error, info, neutral }

class StatusIndicator extends StatelessWidget {
  final StatusType status;
  final String text;
  final bool showIcon;
  final bool isLive;

  const StatusIndicator({
    super.key,
    required this.status,
    required this.text,
    this.showIcon = true,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            if (isLive)
              _buildLiveIndicator(statusColor)
            else
              Icon(
                statusIcon,
                color: statusColor,
                size: 14,
              ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case StatusType.success:
        return AppColors.successGreen;
      case StatusType.warning:
        return AppColors.warningOrange;
      case StatusType.error:
        return AppColors.errorRed;
      case StatusType.info:
        return AppColors.infoYellow;
      case StatusType.neutral:
        return AppColors.mutedGray;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case StatusType.success:
        return Icons.check_circle;
      case StatusType.warning:
        return Icons.warning;
      case StatusType.error:
        return Icons.error;
      case StatusType.info:
        return Icons.info;
      case StatusType.neutral:
        return Icons.circle;
    }
  }
}

class LiveStatusIndicator extends StatefulWidget {
  final String text;
  final Color? color;

  const LiveStatusIndicator({
    super.key,
    required this.text,
    this.color,
  });

  @override
  State<LiveStatusIndicator> createState() => _LiveStatusIndicatorState();
}

class _LiveStatusIndicatorState extends State<LiveStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = widget.color ?? AppColors.successGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: indicatorColor.withValues(alpha: _pulseAnimation.value),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            widget.text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}