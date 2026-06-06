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

  InputDecoration _inputDecorationNoIcon({
    required String labelText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Actividad'),
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
                  DropdownButtonFormField<String>(
                    value: _tipoActividad,
                    decoration: _inputDecoration(
                      labelText: 'Tipo de Actividad',
                      prefixIcon: Icons.category_outlined,
                    ),
                    dropdownColor: Colors.white,
                    items: _tipos.map((t) => DropdownMenuItem(
                      value: t['value'],
                      child: Text(t['label']!),
                    )).toList(),
                    onChanged: (val) => setState(() => _tipoActividad = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tituloController,
                    decoration: _inputDecoration(
                      labelText: 'Título de la actividad',
                      prefixIcon: Icons.title_outlined,
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: _inputDecoration(
                      labelText: 'Descripción / Motivo',
                      prefixIcon: Icons.description_outlined,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Datos del Cliente", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clienteNombreController,
                    decoration: _inputDecoration(
                      labelText: 'Nombre del Cliente',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _clienteDocumentoController,
                          decoration: _inputDecorationNoIcon(
                            labelText: 'DNI / RUC',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _clienteTelefonoController,
                          decoration: _inputDecorationNoIcon(
                            labelText: 'Teléfono',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _direccionController,
                    decoration: _inputDecoration(
                      labelText: 'Dirección de la actividad',
                      prefixIcon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Evidencia (Opcional)", 
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
                          Color(0xFF38BDF8),
                          Color(0xFF0284C7),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withOpacity(0.2),
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
                            'INICIAR ACTIVIDAD',
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
