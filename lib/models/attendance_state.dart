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
  final String? horarioNombre;
  final String? horarioInicioEntrada;
  final String? horarioFinEntrada;
  final String? horarioInicioSalida;
  final String? horarioFinSalida;

  AttendanceState({
    this.status = AttendanceStatus.sinMarcar,
    this.entryTime,
    this.breakStartTime,
    this.breakEndTime,
    this.exitTime,
    this.lastLocation,
    this.latitude,
    this.longitude,
    this.horarioNombre,
    this.horarioInicioEntrada,
    this.horarioFinEntrada,
    this.horarioInicioSalida,
    this.horarioFinSalida,
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
    String? horarioNombre,
    String? horarioInicioEntrada,
    String? horarioFinEntrada,
    String? horarioInicioSalida,
    String? horarioFinSalida,
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
      horarioNombre: horarioNombre ?? this.horarioNombre,
      horarioInicioEntrada: horarioInicioEntrada ?? this.horarioInicioEntrada,
      horarioFinEntrada: horarioFinEntrada ?? this.horarioFinEntrada,
      horarioInicioSalida: horarioInicioSalida ?? this.horarioInicioSalida,
      horarioFinSalida: horarioFinSalida ?? this.horarioFinSalida,
    );
  }
}
