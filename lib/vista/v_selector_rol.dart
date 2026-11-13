import 'package:flutter/material.dart';
import 'package:control_asistencia/controlador/c_estudiante.dart';
import 'package:control_asistencia/vista/estudiante/v_registro_estudiante.dart';
import 'package:control_asistencia/vista/estudiante/v_estudiante_qr.dart';
import 'package:control_asistencia/vista/docente/v_docente_home.dart';


class VSelectorRol extends StatefulWidget {
  const VSelectorRol({super.key});

  @override
  State<VSelectorRol> createState() => _SelectorRolScreenState();
}

class _SelectorRolScreenState extends State<VSelectorRol> {
  bool _verificando = true;

  @override
  void initState() {
    super.initState();
    _verificarEstudianteExistente();
  }


  Future<void> _verificarEstudianteExistente() async {
    final controller = CEstudiante();
    final datos = await controller.cargarDatos();
    if (!mounted) return;

    if (datos != null) {
      // Ya tiene datos â†’ ir directo al QR
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VEstudianteQr(
            registro: datos['registro']!,
            apellidosNombres: datos['apellidos_nombres']!,
          ),
        ),
      );
    } else {
      setState(() => _verificando = false);
    }
  }

  void _irAEstudiante() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VRegistroEstudiante()),
    );
  }

  void _irADocente() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VDocenteHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_verificando) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withAlpha(80),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Control de Asistencia',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¿Quién eres?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              _buildRolCard(
                title: 'Soy Docente',
                subtitle:
                    'Escanear QRs, gestionar materias y exportar asistencia',
                icon: Icons.school_outlined,
                gradient: const [Color(0xFF0F3460), Color(0xFF16213E)],
                borderColor: const Color(0xFF4F46E5),
                onTap: _irADocente,
              ),

              const SizedBox(height: 16),

              _buildRolCard(
                title: 'Soy Estudiante',
                subtitle:
                    'Ver mi código QR para registrar asistencia en exámenes',
                icon: Icons.badge_outlined,
                gradient: const [Color(0xFF3D1560), Color(0xFF1A1A2E)],
                borderColor: const Color(0xFF7C3AED),
                onTap: _irAEstudiante,
              ),

              const Spacer(),

              // Leyenda offline
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 14, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text(
                      '100% sin internet dentro del aula',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor.withAlpha(120), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: borderColor.withAlpha(40),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: borderColor.withAlpha(40),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(160),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withAlpha(120),
            ),
          ],
        ),
      ),
    );
  }
}
