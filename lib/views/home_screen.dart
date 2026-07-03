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
import 'package:geolocator/geolocator.dart';

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0EA5E9),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_filled),
              ),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.history),
              ),
              label: 'Historial',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    // Recargar datos del backend al abrir la pantalla principal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<AttendanceProvider>(context, listen: false);
        provider.loadInitialData();
        _checkGpsStatus(provider);
      }
    });
  }

  void _checkGpsStatus(AttendanceProvider provider) async {
    final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isGpsEnabled && !provider.hasShownGpsWarning) {
      provider.hasShownGpsWarning = true;
      if (mounted) {
        _showGpsWarningDialog();
      }
    }
  }

  void _showGpsWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF59E0B),
            size: 48,
          ),
          title: const Text(
            "GPS Desactivado",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          content: const Text(
            "El GPS de su dispositivo se encuentra desactivado. "
            "No podrá empezar su jornada ni realizar marcaciones hasta que lo active.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Aceptar",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0F2FE), // Celeste muy suave superior
                  Color(0xFFF8FAFC), // Difumina hacia gris/azul claro
                  Color(0xFFF8FAFC),
                ],
                stops: [0.0, 0.25, 1.0],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: () async {
                  await attendanceProvider.loadInitialData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildGreeting(context),
                      const SizedBox(height: 24),
                      _buildStatusCard(context, attendanceProvider.state),
                      if (attendanceProvider.isAsesor && attendanceProvider.isJornadaActiva) ...[
                        const SizedBox(height: 24),
                        _buildActivityCard(context, attendanceProvider),
                      ],
                      const SizedBox(height: 24),
                      _buildActionButtons(context, attendanceProvider),
                    ],
                  ),
                ),
              ),
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
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Por favor, no cierre la aplicación",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 36,
                width: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.business,
                  color: Color(0xFF0EA5E9),
                  size: 36,
                ),
              ),
              const SizedBox(width: 8),
              const Row(
                children: [
                  Text(
                    'Fin',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Control',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildProfileMenu(context),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<String>(
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
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFE2E8F0),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          color: Color(0xFF1E293B),
          size: 24,
        ),
      ),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
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
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final userProfile = context.select<AttendanceProvider, Map<String, dynamic>?>(
      (p) => p.userProfile,
    );
    final String name = userProfile?['nombre_completo'] ?? 'Usuario';
    final String displayDate = DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());
    
    final String capitalizedDate = displayDate.isNotEmpty
        ? '${displayDate[0].toUpperCase()}${displayDate.substring(1)}'
        : displayDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $name',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          capitalizedDate,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
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
    IconData statusIcon = Icons.info_outline;
    Color statusIconColor = Colors.blue;

    switch (state.status) {
      case AttendanceStatus.sinMarcar:
        statusText = "Aún no marcaste entrada";
        statusIcon = Icons.error_outline;
        statusIconColor = const Color(0xFFEF4444);
        break;
      case AttendanceStatus.entradaRegistrada:
        statusText = "Jornada iniciada";
        statusIcon = Icons.info_outline;
        statusIconColor = const Color(0xFF0EA5E9);
        break;
      case AttendanceStatus.enDescanso:
        statusText = "En descanso";
        statusIcon = Icons.coffee;
        statusIconColor = const Color(0xFFF59E0B);
        break;
      case AttendanceStatus.descansoFinalizado:
        statusText = "Descanso finalizado";
        statusIcon = Icons.info_outline;
        statusIconColor = const Color(0xFF0EA5E9);
        break;
      case AttendanceStatus.salidaRegistrada:
        statusText = "Jornada finalizada";
        statusIcon = Icons.info_outline;
        statusIconColor = const Color(0xFF0EA5E9);
        break;
      case AttendanceStatus.observado:
        statusText = "Entrada Observada (Fuera de rango)";
        statusIcon = Icons.warning_amber_rounded;
        statusIconColor = const Color(0xFFF59E0B);
        break;
      case AttendanceStatus.tardanza:
        statusText = "Tardanza Detectada";
        statusIcon = Icons.warning_amber_rounded;
        statusIconColor = const Color(0xFFF59E0B);
        break;
      case AttendanceStatus.noMarcoEntrada:
        statusText = "No marcó entrada";
        statusIcon = Icons.error_outline;
        statusIconColor = const Color(0xFFEF4444);
        break;
      case AttendanceStatus.justificado:
        statusText = "Asistencia Justificada";
        statusIcon = Icons.check_circle_outline;
        statusIconColor = const Color(0xFF10B981);
        break;
      default:
        statusText = "Estado desconocido";
        statusIcon = Icons.info_outline;
        statusIconColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusIconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusIconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Color(0xFFE2E8F0)),
            _buildCardRow(
              icon: Icons.storefront_outlined,
              label: "Sede asignada:",
              valueWidget: Text(
                sede,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                ),
              ),
            ),
            if (state.horarioNombre != null) ...[
              _buildCardRow(
                icon: Icons.access_time_outlined,
                label: "Horario:",
                valueWidget: Text(
                  state.horarioNombre!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            _buildCardRow(
              icon: Icons.location_on_outlined,
              label: "Ubicación:",
              valueWidget: const _GpsStatusIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRow({
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          valueWidget,
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, AttendanceProvider provider) {
    final activity = provider.actividadEnProceso;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment, color: Color(0xFF0EA5E9), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Actividad de campo",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Color(0xFFE2E8F0)),
            if (activity != null) ...[
              Text(
                activity['titulo'] ?? 'Sin título',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    "Cliente: ${activity['cliente_nombre'] ?? 'N/A'}", 
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    "Iniciado: ${activity['hora_inicio_actividad'] != null ? DateFormat('HH:mm').format(DateTime.parse(activity['hora_inicio_actividad'])) : 'N/A'}", 
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Finaliza esta actividad para poder marcar salida.",
                        style: TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                label: "Finalizar actividad",
                icon: Icons.check_circle,
                activeColor: const Color(0xFF10B981),
                onPressed: provider.puedeFinalizarActividad 
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityFinishScreen()))
                  : null,
              ),
            ] else ...[
              const Text(
                "No hay actividad en proceso",
                style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                label: "Iniciar actividad",
                icon: Icons.add_task,
                activeColor: const Color(0xFF0EA5E9),
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
    return Column(
      children: [
        if (provider.mensajeJornada.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFBFDBFE),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline, 
                    color: Color(0xFF1D4ED8),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.mensajeJornada,
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8), 
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _ActionButton(
          label: "Marcar entrada",
          icon: Icons.login,
          gradientColors: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
          onPressed: (provider.puedeMarcarEntrada && provider.isGpsEnabled)
              ? () async {
                  bool success = await provider.markEntry();
                  if (!success && mounted) {
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
                activeColor: const Color(0xFFF59E0B),
                onPressed: (provider.puedeIniciarDescanso && provider.isGpsEnabled)
                    ? () async {
                        bool success = await provider.startBreak();
                        if (!success && mounted) {
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
                icon: Icons.play_arrow_outlined,
                activeColor: const Color(0xFF10B981),
                onPressed: (provider.puedeFinalizarDescanso && provider.isGpsEnabled)
                    ? () async {
                        bool success = await provider.endBreak();
                        if (!success && mounted) {
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
          activeColor: const Color(0xFFEF4444),
          onPressed: (provider.puedeMarcarSalida && provider.isGpsEnabled)
              ? () async {
                  bool success = await provider.markExit();
                  if (!success && mounted) {
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
          activeColor: const Color(0xFF0284C7),
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
  final Color? activeColor;
  final List<Color>? gradientColors;
  final VoidCallback? onPressed;
  final bool isSecondary;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.activeColor,
    this.gradientColors,
    this.onPressed,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    if (!isEnabled) {
      return SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isSecondary) {
      final Color color = activeColor ?? const Color(0xFF0284C7);
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: gradientColors != null
              ? LinearGradient(
                  colors: gradientColors!,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: gradientColors == null ? (activeColor ?? const Color(0xFF0284C7)) : null,
          boxShadow: [
            BoxShadow(
              color: (gradientColors != null ? gradientColors!.first : (activeColor ?? const Color(0xFF0284C7)))
                  .withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isGpsEnabled ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isGpsEnabled ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isGpsEnabled ? Icons.check_circle_outline : Icons.error_outline,
              size: 14,
              color: isGpsEnabled ? const Color(0xFF047857) : const Color(0xFFD97706),
            ),
            const SizedBox(width: 6),
            Text(
              isGpsEnabled ? "GPS Activo" : "Activar GPS aquí",
              style: TextStyle(
                color: isGpsEnabled ? const Color(0xFF047857) : const Color(0xFFD97706),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                decoration: isGpsEnabled ? TextDecoration.none : TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
