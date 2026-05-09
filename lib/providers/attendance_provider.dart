import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../models/attendance_state.dart';
import '../models/attendance_record.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/tracking_service.dart';

class AttendanceProvider with ChangeNotifier {
  AttendanceState _state = AttendanceState();
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  ApiService get apiService => _apiService;
  bool _isGpsEnabled = false;
  Map<String, dynamic>? _userProfile;
  List<AttendanceRecord> _history = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  
  Timer? _syncTimer;
  String? _lastSyncTimestamp;
  
  bool get isGpsEnabled => _isGpsEnabled;
  bool get isActionLoading => _isActionLoading;
  AttendanceState get state => _state;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<AttendanceRecord> get history => _history;
  bool get isLoading => _isLoading;
  String get deviceInfo => "Flutter Device (Android/iOS)";

  AttendanceProvider() {
    _initGpsListener();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _startSyncTimer() {
    if (_syncTimer != null && _syncTimer!.isActive) return;
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_apiService.token == null) return;
      final syncData = await _apiService.checkSyncStatus(_lastSyncTimestamp);
      if (syncData != null) {
        if (syncData['has_changes'] == true) {
          _lastSyncTimestamp = syncData['timestamp'];
          await loadInitialData();
        } else {
          _lastSyncTimestamp = syncData['timestamp'];
        }
      }
    });
  }

  Future<void> checkPersistentSession() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      bool hasToken = await _apiService.loadToken();
      if (hasToken) {
        // Cargar perfil desde cache inmediatamente para no bloquear el UI
        _userProfile = await _apiService.getCachedUserProfile();
        
        // Iniciar la carga de datos de la red en segundo plano (o bloqueante pero con timeout corto)
        await loadInitialData();
        _startSyncTimer();
      } else {
        await _apiService.logout();
      }
    } else {
      // Si no marcó mantener sesión activa, forzar cierre al abrir la app
      await _apiService.logout();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> requestEnableGps() async {
    await Geolocator.openLocationSettings();
  }

  void _initGpsListener() async {
    // 1. Pedir permiso de ubicación normal (en primer plano)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 2. Si ya dio el permiso normal, pedir el permiso SIEMPRE (Segundo plano crítico)
    if (permission == LocationPermission.whileInUse) {
      // En Android 11+ esto abre la configuración para seleccionar "Permitir todo el tiempo"
      permission = await Geolocator.requestPermission();
    }

    // 3. Importar permission_handler de forma diferida para pedir ignorar optimización de batería
    try {
      await _requestBatteryAndBackgroundPermissions();
    } catch(e) {
      print("Error solicitando permisos de batería: $e");
    }

    _isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    notifyListeners();

    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      _isGpsEnabled = (status == ServiceStatus.enabled);
      notifyListeners();
    });
  }

  Future<void> _requestBatteryAndBackgroundPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Solicitar permiso de actividad en segundo plano agresiva y evadir matar la app
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<Position?> getCurrentLocation() async {
    return await _locationService.getCurrentLocation();
  }

  Future<bool> login(String dni, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.login(dni, password, rememberMe: rememberMe);
    if (success) {
      await loadInitialData();
      _startSyncTimer();
    }
    
    _isLoading = false;
    notifyListeners();
    return success;
  }

  void logout() async {
    _syncTimer?.cancel();
    _lastSyncTimestamp = null;
    await _apiService.logout();
    TrackingService.stop();
    _state = AttendanceState();
    _userProfile = null;
    _history = [];
    notifyListeners();
  }

  void resetToday() {
    _state = AttendanceState(status: AttendanceStatus.sinMarcar);
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    // Intentar obtener desde la red
    final profileData = await _apiService.getUserProfile();
    if (profileData != null) {
      _userProfile = profileData;
    } else if (_userProfile == null) {
      // Fallback a cache si la red falla y no teniamos nada
      _userProfile = await _apiService.getCachedUserProfile();
    }
    
    final historyData = await _apiService.getHistory();
    _history = historyData.map((item) => AttendanceRecord.fromJson(item)).toList();
    
    final today = DateTime.now();
    final todayRecord = _history.firstWhere(
      (r) => r.date.year == today.year && r.date.month == today.month && r.date.day == today.day,
      orElse: () => AttendanceRecord(date: today, status: AttendanceStatus.sinMarcar),
    );

    _state = AttendanceState(
      status: todayRecord.status,
      entryTime: todayRecord.entryTime,
      breakStartTime: todayRecord.breakStartTime,
      breakEndTime: todayRecord.breakEndTime,
      exitTime: todayRecord.exitTime,
      latitude: todayRecord.latitude,
      longitude: todayRecord.longitude,
    );
    
    notifyListeners();
  }

  double get targetLatitude {
    final sede = _userProfile?['sede'];
    if (sede is Map && sede['latitud'] != null) {
      return double.parse(sede['latitud'].toString());
    }
    return -12.046374;
  }

  double get targetLongitude {
    final sede = _userProfile?['sede'];
    if (sede is Map && sede['longitud'] != null) {
      return double.parse(sede['longitud'].toString());
    }
    return -77.042793;
  }

  double get allowedRadius {
    final sede = _userProfile?['sede'];
    if (sede is Map && sede['radio_metros'] != null) {
      return sede['radio_metros'].toDouble();
    }
    return 100.0;
  }

  Future<bool> markEntry({String? selfiePath}) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return false;

      double lat = position.latitude;
      double lng = position.longitude;
      final distance = _locationService.calculateDistance(lat, lng, targetLatitude, targetLongitude);
      bool isObserved = distance > allowedRadius;

      final result = await _apiService.markAttendance(
        type: 'ENTRADA',
        lat: lat,
        lng: lng,
        deviceInfo: 'Flutter Device',
      );

      if (result != null) {
        _state = _state.copyWith(
          status: isObserved ? AttendanceStatus.observado : AttendanceStatus.entradaRegistrada,
          entryTime: DateTime.now(),
          latitude: lat,
          longitude: lng,
        );
        
        // Iniciar Tracking
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('asistencia_id', result['asistencia_id']);
        await prefs.setInt('historial_jornada_id', result['historial_jornada_id']);
        
        await TrackingService.start();

        await loadInitialData();
        return true;
      }
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startBreak() async {
    if (_state.status != AttendanceStatus.entradaRegistrada && _state.status != AttendanceStatus.observado) return false;

    _isActionLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return false;

      final result = await _apiService.markAttendance(
        type: 'INICIO_BREAK',
        lat: position.latitude,
        lng: position.longitude,
        deviceInfo: 'Flutter Device',
      );

      if (result != null) {
        _state = _state.copyWith(
          status: AttendanceStatus.enDescanso,
          breakStartTime: DateTime.now(),
        );
        await loadInitialData();
        return true;
      }
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> endBreak() async {
    if (_state.status != AttendanceStatus.enDescanso) return false;

    _isActionLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return false;

      final result = await _apiService.markAttendance(
        type: 'FIN_BREAK',
        lat: position.latitude,
        lng: position.longitude,
        deviceInfo: 'Flutter Device',
      );

      if (result != null) {
        _state = _state.copyWith(
          status: AttendanceStatus.descansoFinalizado,
          breakEndTime: DateTime.now(),
        );
        await loadInitialData();
        return true;
      }
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markExit({String? selfiePath}) async {
    if (_state.status == AttendanceStatus.sinMarcar || _state.status == AttendanceStatus.salidaRegistrada) return false;

    _isActionLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return false;

      final result = await _apiService.markAttendance(
        type: 'SALIDA',
        lat: position.latitude,
        lng: position.longitude,
        deviceInfo: 'Flutter Device',
      );

      if (result != null) {
        _state = _state.copyWith(
          status: AttendanceStatus.salidaRegistrada,
          exitTime: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
        );

        if (result['detener_tracking'] == true) {
          TrackingService.stop();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('asistencia_id');
          await prefs.remove('historial_jornada_id');
        }

        await loadInitialData();
        return true;
      }
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
