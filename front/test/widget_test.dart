// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front/main.dart';

void main() {
  testWidgets('Login screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen is displayed.
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('아이디'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);

    // Enter text into the text fields.
    await tester.enterText(find.byType(TextField).at(0), 'test_id');
    await tester.enterText(find.byType(TextField).at(1), 'test_password');

    // Tap the login button.
    await tester.tap(find.text('로그인'));
    await tester.pump();

    // Verify that the login request is made and the next screen is displayed.
    // (This part may require mocking the HTTP request and response)
  });
}
