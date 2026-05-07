import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_record.dart';
import '../models/attendance_state.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<AttendanceProvider>(context).history;

    return Scaffold(
      appBar: AppBar(title: const Text("Mi Actividad")),
      body: history.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[index];
                return _HistoryCard(record: record);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No hay registros aún",
            style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Tus marcaciones aparecerán aquí",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AttendanceRecord record;

  const _HistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final bool isObserved = record.status == AttendanceStatus.observado;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryDetailScreen(record: record),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildDateSection(context),
                const VerticalDivider(width: 32, indent: 4, endIndent: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              record.sede,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          _buildStatusBadge(isObserved),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTimeRow(Icons.login, "Entrada", record.entryTime, Colors.green),
                      if (record.breakStartTime != null)
                        _buildTimeRow(Icons.coffee, "Break", record.breakStartTime, Colors.orange),
                      _buildTimeRow(Icons.logout, "Salida", record.exitTime, Colors.red),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(IconData icon, String label, DateTime? time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Text(
            time != null ? DateFormat('hh:mm a').format(time) : "--:--",
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('dd').format(record.date),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            DateFormat('MMM').format(record.date).toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isObserved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isObserved ? Colors.amber.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isObserved ? Colors.amber : Colors.green, width: 1),
      ),
      child: Text(
        isObserved ? "OBSERVADO" : "VÁLIDO",
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isObserved ? Colors.amber[800] : Colors.green[800],
        ),
      ),
    );
  }
}
