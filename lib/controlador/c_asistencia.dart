import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:control_asistencia/controlador/command/asistencia_invoker.dart';
import 'package:control_asistencia/controlador/command/registrar_asistencia_command.dart';
import 'package:control_asistencia/modelo/negocio/n_asistencia.dart';
import 'package:control_asistencia/modelo/dato/d_asistencia.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';
import 'package:control_asistencia/modelo/dato/d_estudiante.dart';

class CAsistencia {
  final DAsistencia _asistenciaModel = DAsistencia();
  final DEstudiante _estudianteModel = DEstudiante();
  // COMMAND: el Invoker ejecuta los comandos y guarda el historial para deshacer.
  final AsistenciaInvoker _invoker = AsistenciaInvoker();

  Future<Map<String, dynamic>> validarEstudianteQR({
    required String qrPayload,
    required int examenId,
    required int materiaId,
  }) async {
    try {
      String registro = qrPayload;

      if (qrPayload.trim().startsWith('{')) {
        try {
          final Map<String, dynamic> data = jsonDecode(qrPayload);
          registro = data['registro']?.toString() ?? '';
        } catch (_) {}
      } else if (qrPayload.contains('|')) {
        // Formato legado
        registro = qrPayload.split('|')[0];
      }

      registro = registro.trim();
      final mMatch = RegExp(r'^(-?\d+)\.0+$').firstMatch(registro);
      if (mMatch != null) {
        registro = mMatch.group(1)!;
      }

      if (registro.isEmpty) {
        return {'valido': false, 'error': 'Formato QR inválido o vacío'};
      }

      final estudiante = await _estudianteModel.obtenerPorRegistro(registro);
      if (estudiante == null) {
        return {'valido': false, 'error': 'Estudiante no encontrado en la base de datos'};
      }

      final todosInscritos = await _estudianteModel.listarPorMateria(materiaId);
      final pertenece = todosInscritos.any((e) {
        String reg = e.registro.trim();
        final m = RegExp(r'^(-?\d+)\.0+$').firstMatch(reg);
        if (m != null) reg = m.group(1)!;
        return reg == registro;
      });
      
      if (!pertenece) {
        return {'valido': false, 'error': 'El estudiante no pertenece a esta materia'};
      }

      final activos = await _estudianteModel.listarPorMateria(materiaId, estado: 'ACTIVO');
      final esActivo = activos.any((e) {
        String reg = e.registro.trim();
        final m = RegExp(r'^(-?\d+)\.0+$').firstMatch(reg);
        if (m != null) reg = m.group(1)!;
        return reg == registro;
      });

      if (!esActivo) {
        return {
          'valido': false,
          'error': 'El estudiante figura como RETIRADO en esta materia.',
        };
      }

      final asistenciaPrevia = await _asistenciaModel.obtenerAsistencia(examenId, estudiante.id!);

      if (asistenciaPrevia != null && asistenciaPrevia.estado == 'NO_ASIGNADO') {
        return {
          'valido': false, 
          'error': 'El estudiante está asignado para otro día/grupo.\nSi debe dar el examen hoy, regístrelo manualmente desde la lista.',
        };
      }

      return {
        'valido': true,
        'estudiante': estudiante,
        'yaRegistrado': asistenciaPrevia != null,
        'asistenciaPrevia': asistenciaPrevia,
      };
    } catch (e) {
      return {'valido': false, 'error': 'Error procesando QR: $e'};
    }
  }

  Future<bool> registrarAsistencia({
    required NEstudiante estudiante,
    required int examenId,
    required int materiaId,
    String estado = 'PRESENTE',
  }) async {
    try {
      final now = DateTime.now();
      final fechaHora = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      final nuevaAsistencia = NAsistencia(
        idExamen: examenId,
        idEstudiante: estudiante.id!,
        fechaHora: fechaHora,
        estado: estado,
        sincronizado: false,
      );

      // PATRÓN COMMAND: la acción se encapsula en un Command y la ejecuta el Invoker.
      final command = RegistrarAsistenciaCommand(
        _asistenciaModel,
        nuevaAsistencia,
      );
      return await _invoker.executeCommand(command);
    } catch (e) {
      return false;
    }
  }

  /// Indica si hay una acción de asistencia que se pueda deshacer.
  bool get puedeDeshacer => _invoker.puedeDeshacer;

  /// Deshace la última asistencia registrada. Devuelve su descripción
  /// o null si no había nada que deshacer.
  Future<String?> deshacerUltimaAsistencia() async {
    try {
      final command = await _invoker.undoCommand();
      return command?.descripcion;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listarEstudiantesConEstado(
      int examenId, int materiaId) async {
    return await _asistenciaModel.listarEstudiantesConAsistencia(examenId, materiaId);
  }

  /// 4. Obtener estadísticas del examen
  Future<Map<String, int>> obtenerEstadisticas(int examenId, int materiaId) async {
    return await _asistenciaModel.obtenerEstadisticasExamen(examenId, materiaId);
  }
}
