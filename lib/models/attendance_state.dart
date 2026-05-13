enum AttendanceStatus {
  sinMarcar,
  entradaRegistrada,
  enDescanso,
  descansoFinalizado,
  salidaRegistrada,
  observado,
  pendienteRevision,
  tardanza,
  noMarcoEntrada,
  justificado,
}

class AttendanceState {
  final AttendanceStatus status;
  final DateTime? entryTime;
  final DateTime? breakStartTime;
  final DateTime? breakEndTime;
  final DateTime? exitTime;
  final String? lastLocation;
  final double? latitude;
  final double? longitude;

  AttendanceState({
    this.status = AttendanceStatus.sinMarcar,
    this.entryTime,
    this.breakStartTime,
    this.breakEndTime,
    this.exitTime,
    this.lastLocation,
    this.latitude,
    this.longitude,
  });

  AttendanceState copyWith({
    AttendanceStatus? status,
    DateTime? entryTime,
    DateTime? breakStartTime,
    DateTime? breakEndTime,
    DateTime? exitTime,
    String? lastLocation,
    double? latitude,
    double? longitude,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      entryTime: entryTime ?? this.entryTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      exitTime: exitTime ?? this.exitTime,
      lastLocation: lastLocation ?? this.lastLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
