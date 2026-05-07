import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'views/splash_screen.dart';
import 'services/tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TrackingService.initializeService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: const FinControlApp(),
    ),
  );
}

class FinControlApp extends StatelessWidget {
  const FinControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinControl',
      debugShowCheckedModeBanner: false,
      theme: FinControlTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
