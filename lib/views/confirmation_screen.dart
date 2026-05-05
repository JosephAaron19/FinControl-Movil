import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConfirmationScreen extends StatelessWidget {
  final String actionTitle;
  final VoidCallback onConfirm;

  const ConfirmationScreen({
    super.key,
    required this.actionTitle,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(actionTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.camera_alt, size: 100, color: Colors.blueGrey),
            const SizedBox(height: 24),
            const Text(
              "Captura de evidencia requerida",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Por favor, tómate una selfie para confirmar tu identidad y ubicación.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text("Hora actual"),
                subtitle: Text(DateFormat('HH:mm:ss').format(DateTime.now())),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.location_on),
                title: Text("Ubicación detectada"),
                subtitle: Text("Calle Las Orquídeas 456, San Isidro"),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text("TOMAR FOTO Y CONFIRMAR"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
          ],
        ),
      ),
    );
  }
}
