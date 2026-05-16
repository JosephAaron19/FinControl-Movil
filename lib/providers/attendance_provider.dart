import 'dart:convert';
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
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status_codes;

class AttendanceProvider with ChangeNotifier {
  WebSocketChannel? _socketChannel;
  AttendanceState _state = AttendanceState();
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  ApiService get apiService => _apiService;
  bool _isGpsEnabled = false;
  Map<String, dynamic>? _userProfile;
  List<AttendanceRecord> _history = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _puedeMarcarEntrada = false;
  bool _puedeIniciarDescanso = false;
  bool _puedeFinalizarDescanso = false;
  bool _puedeMarcarSalida = false;
  bool _puedeIniciarActividad = false;
  bool _puedeFinalizarActividad = false;
  Map<String, dynamic>? _actividadEnProceso;
  String _mensajeJornada = "";
  
  bool get puedeMarcarEntrada => _puedeMarcarEntrada;
  bool get puedeIniciarDescanso => _puedeIniciarDescanso;
  bool get puedeFinalizarDescanso => _puedeFinalizarDescanso;
  bool get puedeMarcarSalida => _puedeMarcarSalida;
  bool get puedeIniciarActividad => _puedeIniciarActividad;
  bool get puedeFinalizarActividad => _puedeFinalizarActividad;
  Map<String, dynamic>? get actividadEnProceso => _actividadEnProceso;
  String get mensajeJornada => _mensajeJornada;
  
  Timer? _syncTimer;
  String? _lastSyncTimestamp;
  
  bool get isGpsEnabled => _isGpsEnabled;
  bool get isActionLoading => _isActionLoading;
  AttendanceState get state => _state;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<AttendanceRecord> get history => _history;
  bool get isLoading => _isLoading;
  String get deviceInfo => "Flutter Device (Android/iOS)";

  String get userRole => _userProfile?['rol']?.toString().toLowerCase() ?? 'operador';
  bool get isAsesor => userRole == 'asesor';
  
  bool get isJornadaActiva {
    return _state.status != AttendanceStatus.sinMarcar && 
           _state.status != AttendanceStatus.salidaRegistrada &&
           _state.status != AttendanceStatus.noMarcoEntrada;
  }

  AttendanceProvider() {
    _initGpsListener();
    _tryReconnectSocket();
  }

  void _tryReconnectSocket() async {
    final hasToken = await _apiService.loadToken();
    if (hasToken) {
      _initWebSocket();
    }
  }

  void _initWebSocket() {
    if (_socketChannel != null) {
      _socketChannel!.sink.close();
    }

    // Construcción robusta de la URL de WebSocket usando el objeto Uri
    final baseUri = Uri.parse(ApiService.baseUrl);
    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final uri = Uri(
      scheme: wsScheme,
      host: baseUri.host,
      port: baseUri.port != 0 ? baseUri.port : null,
      path: '/ws/notifications/',
      queryParameters: {'token': _apiService.token},
    );
    
    _socketChannel = WebSocketChannel.connect(uri);

    _socketChannel!.stream.listen(
      (message) {
        print('WebSocket message received: $message');
        final data = jsonDecode(message);
        if (data['type'] == 'config_update' || data['type'] == 'attendance_update') {
          // Recargar datos si hay cambios en la configuración o asistencia
          loadInitialData();
        }
      },
      onError: (error) {
        print('Error en WebSocket: $error');
        // Reintentar después de un tiempo
        Future.delayed(const Duration(seconds: 5), _initWebSocket);
      },
      onDone: () {
        print('Conexión WebSocket cerrada');
        // Reintentar si se cerró inesperadamente
        if (_apiService.token != null) {
          Future.delayed(const Duration(seconds: 5), _initWebSocket);
        }
      },
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _socketChannel?.sink.close();
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

  Future<Map<String, dynamic>> login(String dni, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.login(dni, password, rememberMe: rememberMe);
    if (response['success'] == true) {
      await loadInitialData();
      _initWebSocket();
      _startSyncTimer();
    }
    
    _isLoading = false;
    notifyListeners();
    return response;
  }

  void logout() async {
    _syncTimer?.cancel();
    _socketChannel?.sink.close();
    _socketChannel = null;
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
    
    final jornadaStatus = await _apiService.checkJornadaStatus();
    if (jornadaStatus != null) {
      _puedeMarcarEntrada = jornadaStatus['puede_marcar_entrada'] ?? false;
      _puedeIniciarDescanso = jornadaStatus['puede_iniciar_descanso'] ?? false;
      _puedeFinalizarDescanso = jornadaStatus['puede_finalizar_descanso'] ?? false;
      _puedeMarcarSalida = jornadaStatus['puede_marcar_salida'] ?? false;
      _puedeIniciarActividad = jornadaStatus['puede_iniciar_actividad'] ?? false;
      _puedeFinalizarActividad = jornadaStatus['puede_finalizar_actividad'] ?? false;
      _actividadEnProceso = jornadaStatus['actividad_en_proceso'];
      _mensajeJornada = jornadaStatus['mensaje'] ?? "";
      
      // Actualizar el estado local basado en lo que dice el servidor
      final statusLower = (jornadaStatus['asistencia_estado'] ?? '').toString().toLowerCase();
      
      if (statusLower == 'justificado') {
        _state = _state.copyWith(status: AttendanceStatus.justificado);
      } else if (statusLower == 'no_marco_entrada') {
        _state = _state.copyWith(status: AttendanceStatus.noMarcoEntrada);
      } else if (statusLower == 'tardanza' && (_state.status == AttendanceStatus.sinMarcar || _state.status == AttendanceStatus.noMarcoEntrada)) {
        _state = _state.copyWith(status: AttendanceStatus.tardanza);
      }
    }
    
    notifyListeners();
  }

  double get targetLatitude {
    final sede = _userProfile?['sede_info'] ?? _userProfile?['sede'];
    if (sede is Map && sede['latitud'] != null) {
      return double.parse(sede['latitud'].toString());
    }
    return -12.046374;
  }

  double get targetLongitude {
    final sede = _userProfile?['sede_info'] ?? _userProfile?['sede'];
    if (sede is Map && sede['longitud'] != null) {
      return double.parse(sede['longitud'].toString());
    }
    return -77.042793;
  }

  double get allowedRadius {
    final sede = _userProfile?['sede_info'] ?? _userProfile?['sede'];
    if (sede is Map && sede['radio_metros'] != null) {
      return sede['radio_metros'].toDouble();
    }
    return 100.0;
  }

  Future<bool> markEntry({String? selfiePath}) async {
    if (_isActionLoading) return false;
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
        // Usar el estado devuelto por el servidor (Puntual, Tardanza, Observado)
        AttendanceStatus finalStatus = isObserved ? AttendanceStatus.observado : AttendanceStatus.entradaRegistrada;
        final serverStatus = result['status']?.toString().toLowerCase();
        
        if (serverStatus == 'tardanza') {
          finalStatus = AttendanceStatus.tardanza;
        } else if (serverStatus == 'observado') {
          finalStatus = AttendanceStatus.observado;
        } else if (serverStatus == 'justificado') {
          finalStatus = AttendanceStatus.justificado;
        } else if (serverStatus == 'puntual') {
          finalStatus = AttendanceStatus.entradaRegistrada;
        }

        _state = _state.copyWith(
          status: finalStatus,
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
    if (_isActionLoading) return false;
    // Permitir iniciar descanso si ya entró (Puntual, Observado o Tardanza)
    if (_state.status != AttendanceStatus.entradaRegistrada && 
        _state.status != AttendanceStatus.observado && 
        _state.status != AttendanceStatus.tardanza) return false;

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
    if (_isActionLoading) return false;
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
    if (_isActionLoading) return false;
    if (_state.status == AttendanceStatus.sinMarcar || _state.status == AttendanceStatus.salidaRegistrada) return false;

    // Bloquear salida si hay actividad en proceso (asesor)
    if (isAsesor && _actividadEnProceso != null) {
      _mensajeJornada = "Debes finalizar la actividad de campo antes de marcar salida.";
      notifyListeners();
      return false;
    }

    _isActionLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return false;

      final result = await _apiService.markAttendance(
        type: 'SALIDA',
        lat: position.latitude,
        lng: position.longitude,
        deviceInfo: deviceInfo,
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
      } else {
        // Si el backend responde error (ej. "Finaliza la actividad antes de marcar salida")
        // No actualizamos localmente y esperamos a que el usuario vea la alerta o el estado se recargue.
        await loadInitialData();
        return false;
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> startActividadFlow({
    required String type,
    required String titulo,
    required String descripcion,
    required String clienteNombre,
    String? clienteDocumento,
    String? clienteTelefono,
    String? direccionActividad,
    String? evidencePath,
  }) async {
    if (_isActionLoading) return {'success': false, 'message': 'Acción en curso'};
    _isActionLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return {'success': false, 'message': 'No se pudo obtener la ubicación GPS'};

      final result = await _apiService.startActividad(
        type: type,
        titulo: titulo,
        descripcion: descripcion,
        clienteNombre: clienteNombre,
        clienteDocumento: clienteDocumento,
        clienteTelefono: clienteTelefono,
        direccionActividad: direccionActividad,
        lat: position.latitude,
        lng: position.longitude,
        deviceInfo: deviceInfo,
        evidencePath: evidencePath,
      );

      if (result != null && result['error'] == null) {
        await loadInitialData();
        return {'success': true, 'data': result};
      } else {
        String errorMsg = result?['error']?['error'] ?? result?['error']?['detail'] ?? "Error al iniciar actividad";
        return {'success': false, 'message': errorMsg};
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> finishActividadFlow({
    required String resultado,
    String? observacion,
    String? evidencePath,
  }) async {
    if (_isActionLoading) return {'success': false, 'message': 'Acción en curso'};
    if (_actividadEnProceso == null) return {'success': false, 'message': 'No hay actividad en proceso'};

    _isActionLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return {'success': false, 'message': 'No se pudo obtener la ubicación GPS'};

      final result = await _apiService.finishActividad(
        actividadId: _actividadEnProceso!['id'],
        resultado: resultado,
        observacion: observacion,
        lat: position.latitude,
        lng: position.longitude,
        deviceInfo: deviceInfo,
        evidencePath: evidencePath,
      );

      if (result != null && result['error'] == null) {
        await loadInitialData();
        return {'success': true, 'data': result};
      } else {
        String errorMsg = result?['error']?['error'] ?? result?['error']?['detail'] ?? "Error al finalizar actividad";
        return {'success': false, 'message': errorMsg};
      }
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
