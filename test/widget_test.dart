// Smoke test: the app boots and shows its initial (loading) frame without
// throwing. We pump a single frame only — the console runs repeating timers
// and pulse animations once data loads, so pumpAndSettle would never settle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sih26_companion/main.dart';

void main() {
  testWidgets('App boots without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const CompanionApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
