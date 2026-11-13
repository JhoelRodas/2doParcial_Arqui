import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';
import 'package:control_asistencia/modelo/negocio/n_asistencia.dart';
import 'package:control_asistencia/controlador/c_asistencia.dart';

Future<void> mostrarModalAsistencia({
  required BuildContext context,
  required NEstudiante estudiante,
  required int examenId,
  required int materiaId,
  required CAsistencia cAsistencia,
  NAsistencia? asistenciaPrevia,
  void Function(String nuevoEstado)? onGuardado,
}) async {
  ImageProvider? obtenerImageProvider(String foto) {
    if (foto.isEmpty) return null;
    if (foto.startsWith('http://') || foto.startsWith('https://')) {
      return NetworkImage(foto);
    }
    try {
      String b64 = foto;
      if (b64.contains(',')) b64 = b64.split(',')[1];
      return MemoryImage(base64Decode(b64.replaceAll(RegExp(r'\s+'), '')));
    } catch (_) {
      return null;
    }
  }

  final estadoActual = asistenciaPrevia?.estado.toUpperCase();
  final yaRegistrado =
      asistenciaPrevia != null &&
      estadoActual != null &&
      estadoActual.isNotEmpty;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      Future<void> ejecutarGuardado(String nuevoEstado) async {
        Navigator.pop(ctx);

        final ok = await cAsistencia.registrarAsistencia(
          estudiante: estudiante,
          examenId: examenId,
          materiaId: materiaId,
          estado: nuevoEstado,
        );

        if (!context.mounted) return;

        if (ok) {
          Color bg = Colors.green.shade700;
          IconData icon = Icons.check_circle;
          if (nuevoEstado == 'ATRASADO') {
            bg = Colors.amber.shade900;
            icon = Icons.access_time;
          } else if (nuevoEstado == 'AUSENTE') {
            bg = Colors.red.shade700;
            icon = Icons.cancel;
          }

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Asistencia Registrada! ($nuevoEstado)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          estudiante.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: bg,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );

          if (onGuardado != null) {
            onGuardado(nuevoEstado);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error al registrar la asistencia en la base de datos.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      final imgProvider = obtenerImageProvider(estudiante.foto);

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'VERIFICACION DE IDENTIDAD',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFFA78BFA),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 14),

            if (yaRegistrado) ...[
              Builder(
                builder: (_) {
                  Color bgBadge = const Color(0xFF10B981).withOpacity(0.15);
                  Color borderBadge = const Color(0xFF10B981).withOpacity(0.4);
                  Color textBadge = const Color(0xFF34D399);
                  IconData iconBadge = Icons.check_circle;
                  String textoEstado = estadoActual;

                  if (estadoActual == 'ATRASADO') {
                    bgBadge = const Color(0xFFF59E0B).withOpacity(0.15);
                    borderBadge = const Color(0xFFF59E0B).withOpacity(0.4);
                    textBadge = const Color(0xFFFBBF24);
                    iconBadge = Icons.watch_later;
                    textoEstado = 'ATRASO';
                  } else if (estadoActual == 'AUSENTE') {
                    bgBadge = const Color(0xFFEF4444).withOpacity(0.15);
                    borderBadge = const Color(0xFFEF4444).withOpacity(0.4);
                    textBadge = const Color(0xFFF87171);
                    iconBadge = Icons.cancel_outlined;
                    textoEstado = 'NO LLEGO“';
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: bgBadge,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderBadge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconBadge, size: 18, color: textBadge),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YA REGISTRADO: $textoEstado',
                              style: TextStyle(
                                color: textBadge,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (asistenciaPrevia.fechaHora.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                asistenciaPrevia.fechaHora,
                                style: TextStyle(
                                  color: textBadge.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Text(
                  'PENDIENTE DE REGISTRO',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Fotografía / Avatar Grande
            Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7C3AED), width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1A1A2E),
                backgroundImage: imgProvider,
                child: imgProvider == null
                    ? const Icon(
                        Icons.person,
                        size: 68,
                        color: Color(0xFFA78BFA),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 14),

            // Nombre Completo
            Text(
              estudiante.nombreCompleto,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    'Registro: ${estudiante.registro}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA78BFA),
                      fontSize: 12,
                    ),
                  ),
                ),
                if (estudiante.carrera.isNotEmpty ||
                    estudiante.plan.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      estudiante.carrera.isNotEmpty
                          ? 'Plan: ${estudiante.carrera}'
                          : 'Plan: ${estudiante.plan}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              yaRegistrado
                  ? 'Toca un botón si deseas cambiar su estado:'
                  : 'Verifica la fotografía y selecciona el estado:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // Botones Dinámicos según estado actual
            _buildBotonesEstado(
              estadoActual: estadoActual,
              onSeleccionar: ejecutarGuardado,
            ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CERRAR',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildBotonesEstado({
  required String? estadoActual,
  required void Function(String) onSeleccionar,
}) {
  final esPresente = estadoActual == 'PRESENTE';
  final esAtrasado = estadoActual == 'ATRASADO';
  final sinRegistro = estadoActual == null || estadoActual.isEmpty;

  final btnPresente = Expanded(
    child: ElevatedButton.icon(
      onPressed: () => onSeleccionar('PRESENTE'),
      icon: const Icon(Icons.check_circle, size: 18),
      label: const Text(
        'PRESENTE',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  final btnAtraso = Expanded(
    child: ElevatedButton.icon(
      onPressed: () => onSeleccionar('ATRASADO'),
      icon: const Icon(Icons.access_time, size: 18),
      label: const Text(
        'ATRASO',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  final btnNoLlego = Expanded(
    child: ElevatedButton.icon(
      onPressed: () => onSeleccionar('AUSENTE'),
      icon: const Icon(Icons.cancel_outlined, size: 18),
      label: const Text(
        'NO LLEGÃ“',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  // Caso 1: Sin registro previo -> Muestra los 3 botones
  if (sinRegistro) {
    return Column(
      children: [
        Row(children: [btnPresente, const SizedBox(width: 10), btnAtraso]),
        const SizedBox(height: 10),
        Row(children: [btnNoLlego]),
      ],
    );
  }

  // Caso 2: Está como PRESENTE -> Oculta PRESENTE, muestra ATRASO y NO LLEGÃ“
  if (esPresente) {
    return Row(children: [btnAtraso, const SizedBox(width: 10), btnNoLlego]);
  }

  // Caso 3: Está como ATRASADO -> Oculta ATRASO, muestra PRESENTE y NO LLEGÃ“
  if (esAtrasado) {
    return Row(children: [btnPresente, const SizedBox(width: 10), btnNoLlego]);
  }

  // Caso 4: Está como AUSENTE -> Oculta NO LLEGÃ“, muestra PRESENTE y ATRASO
  return Row(children: [btnPresente, const SizedBox(width: 10), btnAtraso]);
}
