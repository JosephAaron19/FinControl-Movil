import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class TrackingService {
  static const String notificationChannelId = 'tracking_channel';
  static const int notificationId = 888;

  static Future<void> initializeService() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      print("TrackingService no soportado en esta plataforma (Windows/Web). Ignorando inicialización.");
      return;
    }

    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'FinControl Tracking',
      description: 'Canal de tracking de jornada activa.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStartBackground,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Jornada Activa',
        initialNotificationContent: 'Registrando ubicación...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStartBackground,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> start() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    await FlutterBackgroundService().startService();
  }

  static void stop() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    FlutterBackgroundService().invoke('stopService');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStartBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final ApiService apiService = ApiService();
  final Battery battery = Battery();
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  
  await apiService.loadToken();

  Timer? timer;
  int intervalSeconds = 60;

  service.on('stopService').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });

  final config = await apiService.getTrackingConfig();
  if (config != null) {
    intervalSeconds = config['intervalo_segundos'] ?? 60;
    if (config['tracking_activo'] == false) {
      service.stopSelf();
      return;
    }
  }

  Future<void> captureAndSendPoint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? asistenciaId = prefs.getInt('asistencia_id');
      final int? historialId = prefs.getInt('historial_jornada_id');

      if (asistenciaId == null) {
        flutterLocalNotificationsPlugin.show(
          889, 'Debug', 'Error: asistenciaId es null',
          const NotificationDetails(android: AndroidNotificationDetails('tracking_channel', 'Debug', importance: Importance.max)),
        );
        return;
      }

      flutterLocalNotificationsPlugin.show(
        890, 'Debug', 'Obteniendo GPS...',
        const NotificationDetails(android: AndroidNotificationDetails('tracking_channel', 'Debug', importance: Importance.max)),
      );

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final int batteryLevel = await battery.batteryLevel;
      String deviceModel = "Device";
      try {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceModel = "${androidInfo.brand} ${androidInfo.model}";
      } catch (_) {}

      flutterLocalNotificationsPlugin.show(
        891, 'Debug', 'Enviando a API...',
        const NotificationDetails(android: AndroidNotificationDetails('tracking_channel', 'Debug', importance: Importance.max)),
      );

      final success = await apiService.sendTrackingPoint(
        asistenciaId: asistenciaId,
        historialJornadaId: historialId ?? asistenciaId,
        lat: pos.latitude,
        lng: pos.longitude,
        precision: pos.accuracy,
        bateria: batteryLevel,
        deviceInfo: deviceModel,
      );

      if (!success) {
        flutterLocalNotificationsPlugin.show(
          892, 'Debug', 'Fallo al enviar a API (Server Error o Red)',
          const NotificationDetails(android: AndroidNotificationDetails('tracking_channel', 'Debug', importance: Importance.max)),
        );
        List<String> pending = prefs.getStringList('pending_points') ?? [];
        pending.add(jsonEncode({
          'asistencia': asistenciaId,
          'historial_jornada_id': historialId ?? asistenciaId,
          'latitud': pos.latitude,
          'longitud': pos.longitude,
          'precision_metros': pos.accuracy,
          'bateria_porcentaje': batteryLevel,
          'dispositivo_info': deviceModel,
          'fecha': DateTime.now().toIso8601String(),
        }));
        await prefs.setStringList('pending_points', pending);
      } else {
        flutterLocalNotificationsPlugin.show(
          893, 'Debug', '¡Punto enviado exitosamente a Django!',
          const NotificationDetails(android: AndroidNotificationDetails('tracking_channel', 'Debug', importance: Importance.max)),
        );
      }
    } catch (e) {
      flutterLocalNotificationsPlugin.show(
        894, 'Debug', 'Excepción: $e',
        const NotificationDetails(android: AndroidNotificationDetails('tracking_channel', 'Debug', importance: Importance.max)),
      );
      print("Tracking Error: $e");
    }
  }

  // Capturar el primer punto INMEDIATAMENTE
  await captureAndSendPoint();

  timer = Timer.periodic(Duration(seconds: intervalSeconds), (t) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          888,
          'Jornada Activa',
          'Capturando ubicación... (${DateTime.now().hour}:${DateTime.now().minute})',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'tracking_channel',
              'FinControl Tracking',
              ongoing: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    }
    await captureAndSendPoint();
  });
}
