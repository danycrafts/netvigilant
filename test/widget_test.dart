// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apptobe/main.dart';

void main() {
  testWidgets('App compiles and builds without errors', (WidgetTester tester) async {
    // Just test that the app builds without throwing an exception
    // This will catch the SharedPreferences error we're trying to fix
    await tester.pumpWidget(const AppToBe());
    await tester.pump();

    // If we get here, the app built successfully (SharedPreferences fallback worked)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
