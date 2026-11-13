import 'package:control_asistencia/controlador/command/command.dart';
import 'package:control_asistencia/modelo/dato/d_asistencia.dart';
import 'package:control_asistencia/modelo/negocio/n_asistencia.dart';

/// ConcreteCommand: registra (o modifica) la asistencia de un estudiante en
/// un examen. Antes de ejecutar guarda un respaldo (backup) del estado previo
/// para poder deshacer:
///  - si no existía registro  -> undo lo elimina,
///  - si existía              -> undo restaura el estado anterior.
class RegistrarAsistenciaCommand implements Command {
  final DAsistencia _dAsistencia; // Receiver
  final NAsistencia _nueva;

  NAsistencia? _backup; // estado anterior
  int? _idAfectado;

  RegistrarAsistenciaCommand(this._dAsistencia, this._nueva);

  @override
  String get descripcion => 'Asistencia (${_nueva.estado})';

  @override
  Future<bool> execute() async {
    _backup = await _dAsistencia.obtenerAsistencia(
      _nueva.idExamen,
      _nueva.idEstudiante,
    );
    final id = await _dAsistencia.registrarAsistencia(_nueva);
    _idAfectado = id;
    return id > 0;
  }

  @override
  Future<void> undo() async {
    final backup = _backup;
    if (backup == null) {
      final id = _idAfectado;
      if (id != null && id > 0) {
        await _dAsistencia.eliminarAsistencia(id);
      }
    } else {
      await _dAsistencia.registrarAsistencia(backup);
    }
  }
}
