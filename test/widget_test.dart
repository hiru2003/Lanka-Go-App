import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_go/main.dart';

void main() {
  testWidgets('App launches and shows login screen title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LankaGoApp());

    // Verify that the App Title 'Lanka Go' is present.
    expect(find.text('Lanka Go'), findsOneWidget);

    // Verify that the splash login title 'Sign In' and the button are present.
    expect(find.text('Sign In'), findsNWidgets(2));

    // Verify that a scan button is rendered.
    expect(find.byType(GestureDetector), findsWidgets);
  });
}
