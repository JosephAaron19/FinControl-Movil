import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // URL de desarrollo local
  // static const String baseUrl = 'http://192.168.137.1:8000/api';
  // URL de producción de la API
  // static const String baseUrl = 'https://apifincontrol.finatech.com.pe/api';
  // URL de desarrollo local con IP de tu máquina
  static const String baseUrl = 'http://10.185.254.252:8001/api';

  String? _token;
  String? get token => _token;

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<bool> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('remember_me');
    await prefs.remove('cached_user_profile');
    _token = null;
  }

  Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        // El refresh token podría cambiar también según la configuración de SimpleJWT
        final newRefresh = data['refresh'] ?? refreshToken;
        await _saveTokens(_token!, newRefresh);
        return true;
      }
      return false;
    } catch (e) {
      print('Error al refrescar token: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> login(
    String dni,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'dni': dni,
              'password': password,
              'origen': 'movil',
            }),
          )
          .timeout(const Duration(seconds: 20));
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access'];
        final refreshTokenStr = data['refresh'] ?? '';
        await _saveTokens(_token!, refreshTokenStr);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', rememberMe);
        return {'success': true};
      } else {
        String message = 'Error: DNI o contraseña incorrectos';
        try {
          final data = jsonDecode(response.body);
          if (data['detail'] != null) {
            message = data['detail'];
          } else if (data['error'] != null) {
            message = data['error'];
          }
        } catch (_) {}
        return {'success': false, 'message': message};
      }
    } catch (e) {
      print('Error en login: $e');
      String errorMsg =
          'Error de conexión. Verifique que el servidor esté activo en $baseUrl';
      if (e.toString().contains('TimeoutException')) {
        errorMsg =
            'Tiempo de espera agotado. No se pudo conectar con el servidor.';
      } else if (e.toString().contains('SocketException')) {
        errorMsg =
            'No se pudo establecer conexión con el servidor. Verifique su red y la IP $baseUrl';
      }
      return {'success': false, 'message': errorMsg};
    }
  }

  Future<Map<String, dynamic>?> markAttendance({
    required String type, // 'ENTRADA', 'SALIDA', 'INICIO_BREAK', 'FIN_BREAK'
    double? lat,
    double? lng,
    String? deviceInfo,
  }) async {
    if (_token == null) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/attendance/event/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({
              'type': type.toUpperCase(),
              'latitud': lat,
              'longitud': lng,
              'device_info': deviceInfo,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error al marcar asistencia: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_token == null) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/profile/'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache the profile for offline access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_profile', jsonEncode(data));
        return data;
      }
      return null;
    } catch (e) {
      print('Error al obtener perfil: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_user_profile');
      if (cachedStr != null) {
        return jsonDecode(cachedStr);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getHistory() async {
    if (_token == null) return [];

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/attendance/history/'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error al obtener historial: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> reportIncident({
    required String type,
    required String description,
    double? lat,
    double? lng,
    String? deviceInfo,
    String? photoPath,
  }) async {
    if (_token == null)
      return {'success': false, 'message': 'No hay sesión activa'};

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/incidents/create/'),
      );

      request.headers.addAll({'Authorization': 'Bearer $_token'});

      request.fields['tipo_incidencia'] = type;
      request.fields['descripcion'] = description;
      if (lat != null) request.fields['latitud'] = lat.toString();
      if (lng != null) request.fields['longitud'] = lng.toString();
      if (deviceInfo != null) request.fields['dispositivo_info'] = deviceInfo;

      if (photoPath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_evidencia_url', photoPath),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('Incident response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      } else {
        String errorMsg = "Error al enviar la incidencia";
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['error'] ?? errorData['detail'] ?? errorMsg;
        } catch (_) {}
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      print('Error al reportar incidencia: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>?> getTrackingConfig() async {
    if (_token == null) return null;
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/configuracion-tracking/'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> sendTrackingPoint({
    required int asistenciaId,
    required int historialJornadaId,
    required double lat,
    required double lng,
    double? precision,
    int? bateria,
    String? deviceInfo,
  }) async {
    if (_token == null) {
      await loadToken(); // Intentar cargar si es null (ej. reinicio de servicio)
      if (_token == null) return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ubicacion-puntos/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({
              'asistencia': asistenciaId,
              'historial_jornada_id': historialJornadaId,
              'latitud': lat,
              'longitud': lng,
              'precision_metros': precision,
              'bateria_porcentaje': bateria,
              'dispositivo_info': deviceInfo,
              'origen': 'servicio_background',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        // Token expirado, intentar refrescar
        final refreshed = await refreshToken();
        if (refreshed) {
          // Reintentar una vez más
          return await sendTrackingPoint(
            asistenciaId: asistenciaId,
            historialJornadaId: historialJornadaId,
            lat: lat,
            lng: lng,
            precision: precision,
            bateria: bateria,
            deviceInfo: deviceInfo,
          );
        }
      }

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> checkSyncStatus(
    String? lastSyncTimestamp,
  ) async {
    if (_token == null) return null;
    try {
      Uri uri = Uri.parse('$baseUrl/sync/');
      if (lastSyncTimestamp != null) {
        uri = uri.replace(queryParameters: {'last_sync': lastSyncTimestamp});
      }
      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $_token'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error al verificar sync: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkJornadaStatus() async {
    if (_token == null) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/jornada/estado-marcacion/'),
            headers: {'Authorization': 'Bearer $_token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error al verificar estado de jornada: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> startActividad({
    required String type,
    required String titulo,
    required String descripcion,
    required String clienteNombre,
    String? clienteDocumento,
    String? clienteTelefono,
    String? direccionActividad,
    double? lat,
    double? lng,
    String? deviceInfo,
    String? evidencePath,
  }) async {
    if (_token == null) return null;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jornada-actividades/iniciar/'),
      );

      request.headers.addAll({'Authorization': 'Bearer $_token'});

      request.fields['tipo_actividad'] = type;
      request.fields['titulo'] = titulo;
      request.fields['descripcion'] = descripcion;
      request.fields['cliente_nombre'] = clienteNombre;
      if (clienteDocumento != null)
        request.fields['cliente_documento'] = clienteDocumento;
      if (clienteTelefono != null)
        request.fields['cliente_telefono'] = clienteTelefono;
      if (direccionActividad != null)
        request.fields['direccion_actividad'] = direccionActividad;
      if (lat != null) request.fields['latitud_inicio'] = lat.toString();
      if (lng != null) request.fields['longitud_inicio'] = lng.toString();
      if (deviceInfo != null) request.fields['dispositivo_inicio'] = deviceInfo;

      if (evidencePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'evidencia_inicio_url',
            evidencePath,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': jsonDecode(response.body)};
    } catch (e) {
      print('Error al iniciar actividad: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> finishActividad({
    required int actividadId,
    required String resultado,
    String? observacion,
    double? lat,
    double? lng,
    String? deviceInfo,
    String? evidencePath,
  }) async {
    if (_token == null) return null;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/jornada-actividades/finalizar/'),
      );

      request.headers.addAll({'Authorization': 'Bearer $_token'});

      request.fields['actividad_id'] = actividadId.toString();
      request.fields['resultado_actividad'] = resultado;
      if (observacion != null) request.fields['observacion'] = observacion;
      if (lat != null) request.fields['latitud_fin'] = lat.toString();
      if (lng != null) request.fields['longitud_fin'] = lng.toString();
      if (deviceInfo != null) request.fields['dispositivo_fin'] = deviceInfo;

      if (evidencePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('evidencia_fin_url', evidencePath),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': jsonDecode(response.body)};
    } catch (e) {
      print('Error al finalizar actividad: $e');
      return null;
    }
  }
}
