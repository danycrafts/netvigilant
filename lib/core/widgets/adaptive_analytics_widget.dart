import 'package:flutter/material.dart';
import 'package:apptobe/core/widgets/simple_fallback_widgets.dart';
import 'package:apptobe/core/widgets/usage_analytics_widget.dart';

class AdaptiveAnalyticsWidget extends StatefulWidget {
  const AdaptiveAnalyticsWidget({super.key});

  @override
  State<AdaptiveAnalyticsWidget> createState() => _AdaptiveAnalyticsWidgetState();
}

class _AdaptiveAnalyticsWidgetState extends State<AdaptiveAnalyticsWidget> {
  bool _showComplexWidget = false;

  @override
  void initState() {
    super.initState();
    // Start with simple widget, then upgrade after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showComplexWidget = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _showComplexWidget
          ? const UsageAnalyticsWidget()
          : const SimpleAnalyticsWidget(),
    );
  }
}