import 'package:flutter/material.dart';
import 'package:apptobe/core/widgets/simple_fallback_widgets.dart';
import 'package:apptobe/core/widgets/quick_apps_widget.dart';

class AdaptiveQuickAppsWidget extends StatefulWidget {
  const AdaptiveQuickAppsWidget({super.key});

  @override
  State<AdaptiveQuickAppsWidget> createState() => _AdaptiveQuickAppsWidgetState();
}

class _AdaptiveQuickAppsWidgetState extends State<AdaptiveQuickAppsWidget> {
  bool _showComplexWidget = false;

  @override
  void initState() {
    super.initState();
    // Start with simple widget, then upgrade after a delay
    Future.delayed(const Duration(seconds: 2), () {
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
          ? const QuickAppsWidget()
          : const SimpleQuickAppsWidget(),
    );
  }
}