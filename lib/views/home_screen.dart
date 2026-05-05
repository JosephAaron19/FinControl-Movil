import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_state.dart';
import 'incident_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinaTrack'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 28),
            onSelected: (value) {
              if (value == 'logout') {
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
            const SizedBox(height: 32),
            _buildActionButtons(context, attendanceProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, Juan Pérez',
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sede asignada:", style: TextStyle(color: Colors.grey)),
                Text("Sede Central - Finhold", style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
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

  Widget _buildActionButtons(BuildContext context, AttendanceProvider provider) {
    final status = provider.state.status;

    return Column(
      children: [
        _ActionButton(
          label: "Marcar entrada",
          icon: Icons.login,
          color: Colors.blue,
          onPressed: status == AttendanceStatus.sinMarcar
              ? () async {
                  bool success = await provider.markEntry();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("GPS Desactivado. Por favor active la ubicación."),
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
                onPressed: (status == AttendanceStatus.entradaRegistrada || status == AttendanceStatus.observado)
                    ? () async {
                        bool success = await provider.startBreak();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("GPS Desactivado. Por favor active la ubicación."),
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
                onPressed: status == AttendanceStatus.enDescanso
                    ? () async {
                        bool success = await provider.endBreak();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("GPS Desactivado. Por favor active la ubicación."),
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
          onPressed: (status == AttendanceStatus.entradaRegistrada ||
                  status == AttendanceStatus.descansoFinalizado ||
                  status == AttendanceStatus.observado)
              ? () async {
                  bool success = await provider.markExit();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("GPS Desactivado. Por favor active la ubicación."),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IncidentScreen()),
            );
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

    return Row(
      children: [
        Icon(
          Icons.gps_fixed,
          size: 14,
          color: isGpsEnabled ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          isGpsEnabled ? "GPS Activo" : "GPS Desactivado",
          style: TextStyle(
            color: isGpsEnabled ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
