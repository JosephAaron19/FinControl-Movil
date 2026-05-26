import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fincontrol/main.dart';
import 'package:fincontrol/providers/attendance_provider.dart';
import 'package:fincontrol/views/login_screen.dart';

void main() {
  testWidgets('FinControl App initial load test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ],
        child: const FinControlApp(),
      ),
    );

    // Verify that the Login Screen is loaded.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
