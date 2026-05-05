import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'views/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: const FinaTrackApp(),
    ),
  );
}

class FinaTrackApp extends StatelessWidget {
  const FinaTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinaTrack',
      debugShowCheckedModeBanner: false,
      theme: FinaTrackTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
