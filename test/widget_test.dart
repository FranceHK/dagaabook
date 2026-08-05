import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dagaabook/main.dart';

void main() {
  testWidgets('DagaaBook splash screen shows app name', (WidgetTester tester) async {
    await tester.pumpWidget(const DagaaBookApp());

    expect(find.text('DagaaBook'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Let the splash screen's auto-navigation timer finish so it doesn't
    // leak into the next test.
    await tester.pumpAndSettle(const Duration(milliseconds: 1700));
  });
}
