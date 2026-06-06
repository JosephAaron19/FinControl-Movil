import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';
import 'services/tracking_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  // Inicializar Firebase y obtener Token FCM
  try {
    await Firebase.initializeApp();
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Solicitar permisos de notificación (para iOS y Android 13+)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final String? fcmToken = await messaging.getToken();
    print("=================== FCM TOKEN ===================");
    print(fcmToken ?? "No se pudo obtener el token (es null)");
    print("=================================================");
  } catch (e) {
    print("Error al inicializar Firebase / FCM: $e");
  }

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
      theme: FinControlTheme.lightTheme,
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

    if (provider.isCheckingSession && provider.userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.userProfile != null) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
