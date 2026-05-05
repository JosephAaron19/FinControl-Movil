import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 10.0.2.2 es la IP para acceder a localhost desde el emulador de Android
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  String? _token;

  Future<bool> login(String dni, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'dni': dni,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> markAttendance({
    required String type, // 'entrada', 'salida', 'inicio_break', 'fin_break'
    double? lat,
    double? lng,
    String? deviceInfo,
  }) async {
    if (_token == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/asistencias/marcar/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'tipo': type,
          'latitud': lat,
          'longitud': lng,
          'dispositivo_info': deviceInfo,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error al marcar asistencia: $e');
      return null;
    }
  }

  Future<List<dynamic>> getHistory() async {
    if (_token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/asistencias/historial/'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error al obtener historial: $e');
      return [];
    }
  }
}
