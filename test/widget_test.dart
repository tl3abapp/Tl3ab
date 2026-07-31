import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:padel_connect/main.dart';

void main() {
  testWidgets('Padel app shows sign in and create account flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PadelConnectApp());
    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsAtLeastNWidgets(1));
    expect(find.text('Create Account'), findsOneWidget);
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();
    expect(find.text('Create User'), findsOneWidget);
    expect(find.text('Password'), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
  });
}
