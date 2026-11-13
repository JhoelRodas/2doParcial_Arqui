import 'package:control_asistencia/controlador/command/command.dart';

/// Invoker del patrón Command: ejecuta comandos y mantiene el historial
/// para poder deshacer en orden inverso (pila LIFO).
class AsistenciaInvoker {
  static const int _maxHistorial = 20;
  final List<Command> _commandHistory = [];

  bool get puedeDeshacer => _commandHistory.isNotEmpty;

  /// Ejecuta el comando y, si tuvo éxito, lo guarda en el historial.
  Future<bool> executeCommand(Command command) async {
    final ok = await command.execute();
    if (ok) {
      _commandHistory.add(command);
      if (_commandHistory.length > _maxHistorial) {
        _commandHistory.removeAt(0);
      }
    }
    return ok;
  }

  /// Deshace el último comando ejecutado. Devuelve null si no hay nada que deshacer.
  Future<Command?> undoCommand() async {
    if (_commandHistory.isEmpty) return null;
    final command = _commandHistory.removeLast();
    await command.undo();
    return command;
  }

  void limpiar() => _commandHistory.clear();
}
