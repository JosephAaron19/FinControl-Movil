import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'services/tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TrackingService.initializeService();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AttendanceProvider())],
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
      home: const RootGate(),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().checkPersistentSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    if (provider.isLoading && provider.userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.userProfile != null) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
