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
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
      maxWidth: 800,
      maxHeight: 800,
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

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
      ),
    );
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activity != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // soft blue background
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Actividad en curso:", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1D4ED8)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            activity['titulo'] ?? 'Sin título', 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Cliente: ${activity['cliente_nombre'] ?? 'N/A'}", 
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  DropdownButtonFormField<String>(
                    value: _resultado,
                    decoration: _inputDecoration(
                      labelText: 'Resultado de la Actividad',
                      prefixIcon: Icons.check_circle_outlined,
                    ),
                    dropdownColor: Colors.white,
                    items: _resultados.map((t) => DropdownMenuItem(
                      value: t['value'],
                      child: Text(t['label']!),
                    )).toList(),
                    onChanged: (val) => setState(() => _resultado = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _observacionController,
                    decoration: _inputDecoration(
                      labelText: 'Observaciones finales',
                      prefixIcon: Icons.note_alt_outlined,
                    ),
                    maxLines: 4,
                    validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Evidencia de Finalización (Opcional)", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: _evidenceImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 8),
                              Text("Tomar foto de evidencia", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_evidenceImage!, fit: BoxFit.cover, width: double.infinity),
                          ),
                    ),
                  ),
                  if (_evidenceImage != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _evidenceImage = null),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text("Quitar foto", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF34D399),
                          Color(0xFF059669),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submit,
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            'FINALIZAR ACTIVIDAD',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }
}
