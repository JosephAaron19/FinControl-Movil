import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_state.dart';
import '../models/attendance_record.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class AttendanceProvider with ChangeNotifier {
  AttendanceState _state = AttendanceState();
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  bool _isGpsEnabled = false;
  
  bool get isGpsEnabled => _isGpsEnabled;

  AttendanceProvider() {
    _initGpsListener();
  }

  void _initGpsListener() async {
    // Verificar estado inicial
    _isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    notifyListeners();

    // Escuchar cambios en tiempo real
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      _isGpsEnabled = (status == ServiceStatus.enabled);
      notifyListeners();
    });
  }

  final List<AttendanceRecord> _history = [
    AttendanceRecord(
      date: DateTime.now().subtract(const Duration(days: 1)),
      entryTime: DateTime.now().subtract(const Duration(days: 1, hours: 9)),
      exitTime: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      status: AttendanceStatus.salidaRegistrada,
    ),
    AttendanceRecord(
      date: DateTime.now().subtract(const Duration(days: 2)),
      entryTime: DateTime.now().subtract(const Duration(days: 2, hours: 8, minutes: 30)),
      exitTime: DateTime.now().subtract(const Duration(days: 2, hours: 0, minutes: 45)),
      status: AttendanceStatus.observado,
      incidentType: "Estoy fuera de zona",
      incidentDescription: "Me enviaron a realizar una entrega en una sede externa no registrada.",
    ),
  ];

  List<AttendanceRecord> get history => _history;

  // Coordenadas de ejemplo (Sede Finhold)
  static const double targetLatitude = -12.046374;
  static const double targetLongitude = -77.042793;
  static const double allowedRadius = 100.0; // metros

  AttendanceState get state => _state;

  Future<bool> markEntry({String? selfiePath}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final position = await _locationService.getCurrentLocation();
    if (position == null) return false;

    final distance = _locationService.calculateDistance(
      position.latitude,
      position.longitude,
      targetLatitude,
      targetLongitude,
    );

    bool isObserved = distance > allowedRadius;

    final result = await _apiService.markAttendance(
      type: 'entrada',
      lat: position.latitude,
      lng: position.longitude,
      deviceInfo: 'Flutter Device',
    );

    if (result != null) {
      _state = _state.copyWith(
        status: isObserved ? AttendanceStatus.observado : AttendanceStatus.entradaRegistrada,
        entryTime: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> startBreak() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    if (_state.status != AttendanceStatus.entradaRegistrada && _state.status != AttendanceStatus.observado) return false;

    final result = await _apiService.markAttendance(
      type: 'inicio_break',
    );

    if (result != null) {
      _state = _state.copyWith(
        status: AttendanceStatus.enDescanso,
        breakStartTime: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> endBreak() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    if (_state.status != AttendanceStatus.enDescanso) return false;

    final result = await _apiService.markAttendance(
      type: 'fin_break',
    );

    if (result != null) {
      _state = _state.copyWith(
        status: AttendanceStatus.descansoFinalizado,
        breakEndTime: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> markExit({String? selfiePath}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    if (_state.status == AttendanceStatus.sinMarcar || _state.status == AttendanceStatus.salidaRegistrada) return false;

    final position = await _locationService.getCurrentLocation();
    if (position == null) return false;

    final result = await _apiService.markAttendance(
      type: 'salida',
      lat: position.latitude,
      lng: position.longitude,
    );

    if (result != null) {
      _state = _state.copyWith(
        status: AttendanceStatus.salidaRegistrada,
        exitTime: DateTime.now(),
        latitude: position.latitude,
        longitude: position.longitude,
      );
      notifyListeners();
      return true;
    }
    return false;
  }
}
