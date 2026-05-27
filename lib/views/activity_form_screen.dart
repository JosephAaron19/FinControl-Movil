import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';

class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({super.key});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _clienteNombreController = TextEditingController();
  final _clienteDocumentoController = TextEditingController();
  final _clienteTelefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  
  String _tipoActividad = 'VISITA';
  File? _evidenceImage;
  bool _isLoading = false;

  final List<Map<String, String>> _tipos = [
    {'value': 'VISITA', 'label': 'Visita a cliente'},
    {'value': 'SUPERVISION', 'label': 'Supervisión'},
    {'value': 'COBRANZA', 'label': 'Cobranza'},
    {'value': 'ENTREGA', 'label': 'Entrega'},
    {'value': 'OTRO', 'label': 'Otro'},
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1920,
      maxHeight: 1080,
    );
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
    final result = await provider.startActividadFlow(
      type: _tipoActividad,
      titulo: _tituloController.text.trim(),
      descripcion: _descripcionController.text.trim(),
      clienteNombre: _clienteNombreController.text.trim(),
      clienteDocumento: _clienteDocumentoController.text.trim(),
      clienteTelefono: _clienteTelefonoController.text.trim(),
      direccionActividad: _direccionController.text.trim(),
      evidencePath: _evidenceImage?.path,
    );

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actividad iniciada correctamente'), backgroundColor: Colors.green),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?['message'] ?? 'Error al iniciar actividad'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Actividad'),
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
                  DropdownButtonFormField<String>(
                    value: _tipoActividad,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Actividad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _tipos.map((t) => DropdownMenuItem(
                      value: t['value'],
                      child: Text(t['label']!),
                    )).toList(),
                    onChanged: (val) => setState(() => _tipoActividad = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título de la actividad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción / Motivo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  const Text("Datos del Cliente", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clienteNombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cliente',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _clienteDocumentoController,
                          decoration: const InputDecoration(
                            labelText: 'DNI / RUC',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _clienteTelefonoController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de la actividad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Evidencia (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('INICIAR ACTIVIDAD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }
}
