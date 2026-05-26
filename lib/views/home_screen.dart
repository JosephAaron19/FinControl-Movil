import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_state.dart';
import 'incident_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'activity_form_screen.dart';
import 'activity_finish_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('FinControl'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle, size: 28),
                onSelected: (value) {
                  if (value == 'logout') {
                    Provider.of<AttendanceProvider>(context, listen: false).logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text('Mi Perfil'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(context),
                const SizedBox(height: 24),
                _buildStatusCard(context, attendanceProvider.state),
                if (attendanceProvider.isAsesor && attendanceProvider.isJornadaActiva) ...[
                  const SizedBox(height: 24),
                  _buildActivityCard(context, attendanceProvider),
                ],
                const SizedBox(height: 32),
                _buildActionButtons(context, attendanceProvider),
              ],
            ),
          ),
        ),
        if (attendanceProvider.isActionLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        "Capturando georeferencia...",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Por favor, no cierre la aplicación",
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final userProfile = context.select<AttendanceProvider, Map<String, dynamic>?>(
      (p) => p.userProfile,
    );
    final String name = userProfile?['nombre_completo'] ?? 'Usuario';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $name',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          DateFormat('EEEE, d MMMM').format(DateTime.now()),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, AttendanceState state) {
    final userProfile = context.select<AttendanceProvider, Map<String, dynamic>?>(
      (p) => p.userProfile,
    );
    final sedeInfo = userProfile?['sede_info'];
    final String sede = (sedeInfo is Map) 
        ? (sedeInfo['nombre'] ?? 'Sede no asignada') 
        : 'Sede no asignada';

    String statusText = "";
    Color statusColor = Colors.grey;

    switch (state.status) {
      case AttendanceStatus.sinMarcar:
        statusText = "Aún no marcaste entrada";
        statusColor = Colors.grey;
        break;
      case AttendanceStatus.entradaRegistrada:
        statusText = "Jornada iniciada";
        statusColor = Colors.green;
        break;
      case AttendanceStatus.enDescanso:
        statusText = "En descanso";
        statusColor = Colors.orange;
        break;
      case AttendanceStatus.descansoFinalizado:
        statusText = "Descanso finalizado";
        statusColor = Colors.blue;
        break;
      case AttendanceStatus.salidaRegistrada:
        statusText = "Jornada finalizada";
        statusColor = Colors.red;
        break;
      case AttendanceStatus.observado:
        statusText = "Entrada Observada (Fuera de rango)";
        statusColor = Colors.amber;
        break;
      case AttendanceStatus.tardanza:
        statusText = "Tardanza Detectada";
        statusColor = Colors.deepOrange;
        break;
      case AttendanceStatus.noMarcoEntrada:
        statusText = "No marcó entrada";
        statusColor = Colors.red;
        break;
      case AttendanceStatus.justificado:
        statusText = "Asistencia Justificada";
        statusColor = Colors.teal;
        break;
      default:
        statusText = "Estado desconocido";
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sede asignada:", style: TextStyle(color: Colors.grey)),
                Text(sede, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            if (state.horarioNombre != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Horario:", style: TextStyle(color: Colors.grey)),
                  Text(
                    "${state.horarioNombre} (${state.horarioInicioEntrada ?? ''} - ${state.horarioFinSalida ?? ''})",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Ubicación:", style: TextStyle(color: Colors.grey)),
                _GpsStatusIndicator(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, AttendanceProvider provider) {
    final activity = provider.actividadEnProceso;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  "Actividad de campo",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 32),
            if (activity != null) ...[
              Text(
                activity['titulo'] ?? 'Sin título',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("Cliente: ${activity['cliente_nombre'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("Iniciado: ${activity['hora_inicio_actividad'] != null ? DateFormat('HH:mm').format(DateTime.parse(activity['hora_inicio_actividad'])) : 'N/A'}", style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Finaliza esta actividad para poder marcar salida.",
                        style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                label: "Finalizar actividad",
                icon: Icons.check_circle,
                color: Colors.green,
                onPressed: provider.puedeFinalizarActividad 
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityFinishScreen()))
                  : null,
              ),
            ] else ...[
              const Text(
                "No hay actividad en proceso",
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                label: "Iniciar actividad",
                icon: Icons.add_task,
                color: Colors.blue,
                onPressed: provider.puedeIniciarActividad
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityFormScreen()))
                  : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AttendanceProvider provider) {
    final status = provider.state.status;

    return Column(
      children: [
        if (provider.mensajeJornada.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (status == AttendanceStatus.sinMarcar && !provider.puedeMarcarEntrada) 
                    ? Colors.red.withOpacity(0.1) 
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (status == AttendanceStatus.sinMarcar && !provider.puedeMarcarEntrada) 
                      ? Colors.red.withOpacity(0.5) 
                      : Colors.blue.withOpacity(0.5)
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (status == AttendanceStatus.sinMarcar && !provider.puedeMarcarEntrada) 
                        ? Icons.warning_amber_rounded 
                        : Icons.info_outline, 
                    color: (status == AttendanceStatus.sinMarcar && !provider.puedeMarcarEntrada) 
                        ? Colors.red 
                        : Colors.blue
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.mensajeJornada,
                      style: TextStyle(
                        color: (status == AttendanceStatus.sinMarcar && !provider.puedeMarcarEntrada) 
                            ? Colors.red 
                            : Colors.blue[300], 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        _ActionButton(
          label: "Marcar entrada",
          icon: Icons.login,
          color: Colors.blue,
          onPressed: (provider.puedeMarcarEntrada && provider.isGpsEnabled)
              ? () async {
                  bool success = await provider.markEntry();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Error al marcar. Verifique su GPS."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: "Iniciar descanso",
                icon: Icons.coffee,
                color: Colors.orange,
                onPressed: (provider.puedeIniciarDescanso && provider.isGpsEnabled)
                    ? () async {
                        bool success = await provider.startBreak();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Error al marcar. Verifique su GPS."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: "Fin descanso",
                icon: Icons.play_circle,
                color: Colors.green,
                onPressed: (provider.puedeFinalizarDescanso && provider.isGpsEnabled)
                    ? () async {
                        bool success = await provider.endBreak();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Error al marcar. Verifique su GPS."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: "Marcar salida",
          icon: Icons.logout,
          color: Colors.red,
          onPressed: (provider.puedeMarcarSalida && provider.isGpsEnabled)
              ? () async {
                  bool success = await provider.markExit();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.mensajeJornada.isNotEmpty 
                          ? provider.mensajeJornada 
                          : "Error al marcar. Verifique su GPS."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              : null,
        ),
        const SizedBox(height: 24),
        _ActionButton(
          label: "Reportar incidencia",
          icon: Icons.warning_amber_rounded,
          color: Colors.amber,
          isSecondary: true,
          onPressed: () {
            if (provider.isJornadaActiva) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IncidentScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No puede enviar su reporte porque no está en una jornada activa."),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isSecondary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : (onPressed == null ? Colors.grey[800] : color),
          foregroundColor: Colors.white,
          side: isSecondary ? BorderSide(color: color) : null,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

class _GpsStatusIndicator extends StatelessWidget {
  const _GpsStatusIndicator();

  @override
  Widget build(BuildContext context) {
    final isGpsEnabled = context.watch<AttendanceProvider>().isGpsEnabled;

    return InkWell(
      onTap: isGpsEnabled ? null : () => context.read<AttendanceProvider>().requestEnableGps(),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isGpsEnabled ? Icons.check_circle_outline : Icons.error_outline,
              size: 16,
              color: isGpsEnabled ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              isGpsEnabled ? "GPS Activo" : "Activar ubicación aquí",
              style: TextStyle(
                color: isGpsEnabled ? Colors.grey[400] : Colors.orange,
                fontSize: 13,
                fontWeight: isGpsEnabled ? FontWeight.normal : FontWeight.bold,
                decoration: isGpsEnabled ? TextDecoration.none : TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
