import 'dart:math';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';

/// PATRÓN STRATEGY (CU-03: Generar Grupos)
///
/// Roles:
///   - Strategy          -> [OrdenStrategy]
///   - ConcreteStrategy  -> [OrdenAlfabeticoStrategy], [OrdenAleatorioStrategy]
///   - Context           -> [AsignacionGruposContext]
///   - Client            -> VMateriaDetalle (elige la estrategia y la pasa al contexto)
abstract class OrdenStrategy {
  /// Nombre que se muestra en la vista (dropdown).
  String get nombre;

  /// Devuelve una NUEVA lista ordenada según el criterio (no modifica la original).
  List<NEstudiante> ordenar(List<NEstudiante> estudiantes);
}

/// ConcreteStrategy 1: orden alfabético por "Apellidos y Nombres".
class OrdenAlfabeticoStrategy implements OrdenStrategy {
  @override
  String get nombre => 'Alfabético';

  @override
  List<NEstudiante> ordenar(List<NEstudiante> estudiantes) {
    final copia = List<NEstudiante>.from(estudiantes);
    copia.sort(
      (a, b) => a.apellidosNombres.toLowerCase().compareTo(
        b.apellidosNombres.toLowerCase(),
      ),
    );
    return copia;
  }
}

/// ConcreteStrategy 2: orden aleatorio.
class OrdenAleatorioStrategy implements OrdenStrategy {
  final Random _random;

  OrdenAleatorioStrategy([Random? random]) : _random = random ?? Random();

  @override
  String get nombre => 'Aleatorio';

  @override
  List<NEstudiante> ordenar(List<NEstudiante> estudiantes) {
    final copia = List<NEstudiante>.from(estudiantes);
    copia.shuffle(_random);
    return copia;
  }
}

/// Context: mantiene una referencia a la estrategia actual y solo se
/// comunica con ella mediante la interfaz [OrdenStrategy]. El cliente puede
/// cambiarla en tiempo de ejecución con [setStrategy].
class AsignacionGruposContext {
  OrdenStrategy _strategy;

  AsignacionGruposContext([OrdenStrategy? strategy])
    : _strategy = strategy ?? OrdenAlfabeticoStrategy();

  OrdenStrategy get strategy => _strategy;

  void setStrategy(OrdenStrategy strategy) {
    _strategy = strategy;
  }

  List<NEstudiante> ordenar(List<NEstudiante> estudiantes) {
    return _strategy.ordenar(estudiantes);
  }
}
