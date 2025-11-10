// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zensta/main.dart';

void main() {
  testWidgets('App renders Setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZenstaApp()));

    expect(find.text('Setup Zensta'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
