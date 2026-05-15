import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';

class ActivityFinishScreen extends StatefulWidget {
  const ActivityFinishScreen({super.key});

  @override
  State<ActivityFinishScreen> createState() => _ActivityFinishScreenState();
}

class _ActivityFinishScreenState extends State<ActivityFinishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacionController = TextEditingController();
  
  String _resultado = 'EXITOSO';
  File? _evidenceImage;
  bool _isLoading = false;

  final List<Map<String, String>> _resultados = [
    {'value': 'EXITOSO', 'label': 'Exitoso / Finalizado'},
    {'value': 'REPROGRAMADO', 'label': 'Reprogramado'},
    {'value': 'CANCELADO', 'label': 'Cancelado'},
    {'value': 'NO_ENCONTRADO', 'label': 'No se encontró al cliente'},
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _evidenceImage = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final result = await provider.finishActividadFlow(
      resultado: _resultado,
      observacion: _observacionController.text.trim(),
      evidencePath: _evidenceImage?.path,
    );

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actividad finalizada correctamente'), backgroundColor: Colors.green),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?['message'] ?? 'Error al finalizar actividad'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = Provider.of<AttendanceProvider>(context).actividadEnProceso;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Actividad'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activity != null) ...[
                    Card(
                      color: Colors.blue.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Actividad en curso:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                            const SizedBox(height: 4),
                            Text(activity['titulo'] ?? 'Sin título', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Cliente: ${activity['cliente_nombre'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  DropdownButtonFormField<String>(
                    value: _resultado,
                    decoration: const InputDecoration(
                      labelText: 'Resultado de la Actividad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.check_circle),
                    ),
                    items: _resultados.map((t) => DropdownMenuItem(
                      value: t['value'],
                      child: Text(t['label']!),
                    )).toList(),
                    onChanged: (val) => setState(() => _resultado = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _observacionController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones finales',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_alt),
                    ),
                    maxLines: 4,
                    validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text("Evidencia de Finalización (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: _evidenceImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Tomar foto de evidencia", style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_evidenceImage!, fit: BoxFit.cover),
                          ),
                    ),
                  ),
                  if (_evidenceImage != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _evidenceImage = null),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Quitar foto", style: TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('FINALIZAR ACTIVIDAD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }
}
