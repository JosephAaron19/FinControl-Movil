import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';

class HistoryDetailScreen extends StatelessWidget {
  final AttendanceRecord record;

  const HistoryDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de Jornada"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            const Text(
              "Cronología",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTimeline(),
            if (record.incidentType != null) ...[
              const SizedBox(height: 32),
              _buildIncidentCard(),
            ],
            const SizedBox(height: 32),
            _buildLocationCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(record.date),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          record.sede,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildIncidentCard() {
    return Card(
      color: Colors.amber.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  "Incidencia: ${record.incidentType}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              record.incidentDescription ?? "",
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _TimelineItem(
          time: record.entryTime != null ? DateFormat('HH:mm').format(record.entryTime!) : "--:--",
          title: "Marcado de Entrada",
          subtitle: "Registro de inicio de jornada",
          icon: Icons.login,
          color: Colors.blue,
          isFirst: true,
        ),
        _TimelineItem(
          time: record.breakStartTime != null ? DateFormat('HH:mm').format(record.breakStartTime!) : "--:--",
          title: "Inicio de Descanso",
          subtitle: "Pausa para refrigerio",
          icon: Icons.coffee,
          color: Colors.orange,
        ),
        _TimelineItem(
          time: record.breakEndTime != null ? DateFormat('HH:mm').format(record.breakEndTime!) : "--:--",
          title: "Fin de Descanso",
          subtitle: "Retorno a labores",
          icon: Icons.play_circle,
          color: Colors.green,
        ),
        _TimelineItem(
          time: record.exitTime != null ? DateFormat('HH:mm').format(record.exitTime!) : "--:--",
          title: "Marcado de Salida",
          subtitle: "Jornada completada",
          icon: Icons.logout,
          color: Colors.red,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map_outlined, size: 20),
                SizedBox(width: 8),
                Text("Ubicación de registro", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Las marcas fueron realizadas dentro del radio permitido de la sede.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {},
              child: const Center(child: Text("VER EN MAPA")),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 20,
                color: isFirst ? Colors.transparent : Colors.grey[800],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(time, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
