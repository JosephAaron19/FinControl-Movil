import '../models/attendance_state.dart';

class AttendanceRecord {
  final DateTime date;
  final DateTime? entryTime;
  final DateTime? breakStartTime;
  final DateTime? breakEndTime;
  final DateTime? exitTime;
  final AttendanceStatus status;
  final String sede;
  final double? latitude;
  final double? longitude;
  final String? incidentType;
  final String? incidentDescription;

  AttendanceRecord({
    required this.date,
    this.entryTime,
    this.breakStartTime,
    this.breakEndTime,
    this.exitTime,
    this.status = AttendanceStatus.salidaRegistrada,
    this.sede = "Sede Central - Finhold",
    this.latitude,
    this.longitude,
    this.incidentType,
    this.incidentDescription,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final entryTime = json['hora_entrada'] != null ? DateTime.parse(json['hora_entrada']).toLocal() : null;
    final breakStartTime = json['hora_inicio_break'] != null ? DateTime.parse(json['hora_inicio_break']).toLocal() : null;
    final breakEndTime = json['hora_fin_break'] != null ? DateTime.parse(json['hora_fin_break']).toLocal() : null;
    final exitTime = json['hora_salida'] != null ? DateTime.parse(json['hora_salida']).toLocal() : null;
    final String backendStatus = json['estado'] ?? 'Sin Marcar';

    return AttendanceRecord(
      date: DateTime.parse(json['fecha']),
      entryTime: entryTime,
      breakStartTime: breakStartTime,
      breakEndTime: breakEndTime,
      exitTime: exitTime,
      status: _inferStatus(backendStatus, entryTime, breakStartTime, breakEndTime, exitTime),
      sede: json['sede_nombre'] ?? "Sede Central",
      latitude: json['latitud_entrada'] != null ? double.parse(json['latitud_entrada'].toString()) : null,
      longitude: json['longitud_entrada'] != null ? double.parse(json['longitud_entrada'].toString()) : null,
    );
  }

  static AttendanceStatus _inferStatus(String backendStatus, DateTime? entry, DateTime? breakStart, DateTime? breakEnd, DateTime? exit) {
    if (exit != null) return AttendanceStatus.salidaRegistrada;
    if (breakEnd != null) return AttendanceStatus.descansoFinalizado;
    if (breakStart != null) return AttendanceStatus.enDescanso;
    
    final statusLower = backendStatus.toLowerCase();
    
    if (statusLower == 'justificado') return AttendanceStatus.justificado;
    if (statusLower == 'no_marco_entrada') return AttendanceStatus.noMarcoEntrada;
    if (statusLower == 'tardanza') return AttendanceStatus.tardanza;
    if (statusLower == 'observado') return AttendanceStatus.observado;
    
    if (entry != null) {
      return AttendanceStatus.entradaRegistrada;
    }
    
    return AttendanceStatus.sinMarcar;
  }
}
