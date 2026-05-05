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
}
