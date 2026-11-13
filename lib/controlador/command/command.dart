/// PATRÓN COMMAND (CU-04: Controlar Asistencia)
///
/// Roles:
///   - Command          -> [Command]
///   - ConcreteCommand  -> RegistrarAsistenciaCommand
///   - Invoker          -> AsistenciaInvoker
///   - Receiver         -> DAsistencia (capa Dato)
///   - Client           -> CAsistencia
///
/// Encapsula una acción sobre la asistencia como un objeto que sabe
/// ejecutarse ([execute]) y deshacerse ([undo]).
abstract class Command {
  /// Texto corto para mostrar al usuario (p. ej. en el aviso de "deshecho").
  String get descripcion;

  /// Ejecuta la acción. Devuelve true si se aplicó correctamente.
  Future<bool> execute();

  /// Revierte lo que hizo [execute].
  Future<void> undo();
}
