import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:padel_connect/main.dart';

void main() {
  final sizes = <Size>[
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(360, 800),
  ];

  for (final size in sizes) {
    testWidgets('release smoke layout ${size.width}x${size.height}', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const PadelConnectApp());
      await tester.pump(const Duration(milliseconds: 2800));
      await tester.pumpAndSettle();
      _expectNoFlutterExceptions(tester);

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();
      _expectNoFlutterExceptions(tester);

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      _expectNoFlutterExceptions(tester);
    });
  }
}

void _expectNoFlutterExceptions(WidgetTester tester) {
  final exception = tester.takeException();
  expect(exception, isNull);
}
