// Pruebas unitarias de los 3 patrones de diseño del 2do parcial.
// Usan clases D falsas (en memoria), así no necesitan SQLite ni un celular.
// Ejecutar con:  flutter test

import 'dart:math';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:control_asistencia/controlador/command/asistencia_invoker.dart';
import 'package:control_asistencia/controlador/command/command.dart';
import 'package:control_asistencia/controlador/command/registrar_asistencia_command.dart';
import 'package:control_asistencia/controlador/strategy/orden_strategy.dart';
import 'package:control_asistencia/controlador/template/exportadores_concretos.dart';
import 'package:control_asistencia/modelo/dato/d_asistencia.dart';
import 'package:control_asistencia/modelo/dato/d_estudiante.dart';
import 'package:control_asistencia/modelo/dato/d_examen.dart';
import 'package:control_asistencia/modelo/negocio/n_asistencia.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';
import 'package:control_asistencia/modelo/negocio/n_examen.dart';

// ═══════════════════════════ Datos y clases falsas ═══════════════════════════

NEstudiante est(int id, String reg, String nombre) => NEstudiante(
      id: id,
      registro: reg,
      apellidosNombres: nombre,
      carrera: 'Sistemas',
      plan: '187-3',
      telefono: '',
      email: '',
    );

NAsistencia asis(int examen, int estudiante, String estado) => NAsistencia(
      idExamen: examen,
      idEstudiante: estudiante,
      fechaHora: '2026-11-13 08:00:00',
      estado: estado,
    );

/// DAsistencia en memoria: misma lógica "upsert" que la real.
class FakeDAsistencia extends DAsistencia {
  final Map<int, NAsistencia> filas = {};
  int _siguienteId = 1;
  List<Map<String, dynamic>> listaParaExportar = [];
  Map<int, List<Map<String, dynamic>>> listaPorExamen = {};

  NAsistencia? buscar(int examen, int estudiante) {
    for (final a in filas.values) {
      if (a.idExamen == examen && a.idEstudiante == estudiante) return a;
    }
    return null;
  }

  @override
  Future<int> registrarAsistencia(NAsistencia asistencia) async {
    final existente = buscar(asistencia.idExamen, asistencia.idEstudiante);
    final id = existente?.id ?? _siguienteId++;
    filas[id] = NAsistencia(
      id: id,
      idExamen: asistencia.idExamen,
      idEstudiante: asistencia.idEstudiante,
      fechaHora: asistencia.fechaHora,
      estado: asistencia.estado,
    );
    return id;
  }

  @override
  Future<NAsistencia?> obtenerAsistencia(int examenId, int estudianteId) async =>
      buscar(examenId, estudianteId);

  @override
  Future<int> eliminarAsistencia(int id) async =>
      filas.remove(id) == null ? 0 : 1;

  @override
  Future<List<Map<String, dynamic>>> listarEstudiantesConAsistencia(
    int examenId,
    int materiaId,
  ) async =>
      listaPorExamen[examenId] ?? listaParaExportar;
}

class FakeDEstudiante extends DEstudiante {
  List<NEstudiante> estudiantes = [];
  @override
  Future<List<NEstudiante>> listarPorMateria(int materiaId, {String? estado}) async =>
      estudiantes;
}

class FakeDExamen extends DExamen {
  Map<int, NExamen> examenes = {};
  @override
  Future<NExamen?> obtenerPorId(int id) async => examenes[id];
}

/// Comando falso para probar el Invoker.
class ComandoFalso implements Command {
  final bool resultado;
  int ejecutado = 0;
  int deshecho = 0;
  ComandoFalso([this.resultado = true]);
  @override
  String get descripcion => 'falso';
  @override
  Future<bool> execute() async {
    ejecutado++;
    return resultado;
  }

  @override
  Future<void> undo() async => deshecho++;
}

/// Lee una celda de la hoja como texto (fila y columna desde 0).
String celda(Sheet hoja, int fila, int col) =>
    hoja.rows[fila][col]?.value?.toString() ?? '';

// Subclases de prueba: reemplazan SOLO guardar/compartir (usan el celular)
// y registran el orden en que el método plantilla llama a cada paso.
class ExportadorExamenPrueba extends ExportadorAsistenciaExamen {
  final List<String> pasos = [];
  List<int>? bytes;
  ExportadorExamenPrueba(FakeDAsistencia d)
      : super(examenId: 1, materiaId: 1, tituloExamen: 'Parcial 1', dAsistencia: d);

  @override
  Future<String?> cargarDatos() async {
    pasos.add('cargarDatos');
    return super.cargarDatos();
  }

  @override
  void escribirEncabezado(Sheet hoja) {
    pasos.add('escribirEncabezado');
    super.escribirEncabezado(hoja);
  }

  @override
  void escribirFilas(Sheet hoja) {
    pasos.add('escribirFilas');
    super.escribirFilas(hoja);
  }

  @override
  Future<String> guardarArchivo(List<int> b) async {
    pasos.add('guardarArchivo');
    bytes = b;
    return 'ruta/prueba.xlsx';
  }

  @override
  Future<void> compartirArchivo(String ruta) async => pasos.add('compartirArchivo');
}

/// Matriz de prueba que usa el valorCelda/títulos REALES de Consolidado o Cronograma.
class MatrizPrueba extends ExportadorMatrizExamenes {
  final ExportadorMatrizExamenes real;
  List<int>? bytes;
  MatrizPrueba(this.real, FakeDAsistencia a, FakeDEstudiante e, FakeDExamen x)
      : super(
          materiaId: 1,
          materiaNombre: 'Arquitectura',
          examenIds: [10, 20],
          dAsistencia: a,
          dEstudiante: e,
          dExamen: x,
        );

  @override
  String valorCelda(String estado) => real.valorCelda(estado);
  @override
  String get tituloReporte => real.tituloReporte;
  @override
  String get nombreHoja => real.nombreHoja;
  @override
  String get prefijoArchivo => real.prefijoArchivo;
  @override
  String get textoCompartir => real.textoCompartir;
  @override
  String get mensajeExito => real.mensajeExito;
  @override
  String get prefijoError => real.prefijoError;

  @override
  Future<String> guardarArchivo(List<int> b) async {
    bytes = b;
    return 'ruta/prueba.xlsx';
  }

  @override
  Future<void> compartirArchivo(String ruta) async {}
}

// ═══════════════════════════════════ TESTS ═══════════════════════════════════

void main() {
  // ─────────────────────────── STRATEGY (CU-03) ───────────────────────────
  group('Strategy - CU-03 Generar grupos', () {
    final lista = [
      est(1, '300', 'perez lopez ana'),
      est(2, '100', 'Arce Rojas Luis'),
      est(3, '200', 'mendoza cruz Eva'),
      est(4, '400', 'Zarate Paz Ivan'),
    ];

    test('Alfabético ordena por apellidos sin importar mayúsculas (igual que el 1er parcial)', () {
      final context = AsignacionGruposContext()..setStrategy(OrdenAlfabeticoStrategy());
      final r = context.ordenar(lista).map((e) => e.apellidosNombres).toList();
      final esperado = List<NEstudiante>.from(lista)
        ..sort((a, b) => a.apellidosNombres.toLowerCase().compareTo(b.apellidosNombres.toLowerCase()));
      expect(r, esperado.map((e) => e.apellidosNombres).toList());
      expect(r.first, 'Arce Rojas Luis');
      expect(r.last, 'Zarate Paz Ivan');
    });

    test('Aleatorio mezcla, conserva todos los estudiantes y no modifica la lista original', () {
      final original = lista.map((e) => e.id).toList();
      final context = AsignacionGruposContext(OrdenAleatorioStrategy(Random(7)));
      final r = context.ordenar(lista);
      expect(r.length, lista.length);
      expect(r.map((e) => e.id).toSet(), original.toSet());
      expect(lista.map((e) => e.id).toList(), original); // la original no cambia
    });

    test('Context usa Alfabético por defecto y permite cambiar la estrategia', () {
      final context = AsignacionGruposContext();
      expect(context.strategy, isA<OrdenAlfabeticoStrategy>());
      context.setStrategy(OrdenAleatorioStrategy());
      expect(context.strategy, isA<OrdenAleatorioStrategy>());
      expect(context.strategy.nombre, 'Aleatorio');
    });

    test('Lista vacía no falla', () {
      expect(AsignacionGruposContext().ordenar([]), isEmpty);
    });
  });

  // ─────────────────────────── COMMAND (CU-04) ───────────────────────────
  group('Command - CU-04 Registrar y deshacer asistencia', () {
    test('Registrar nuevo y deshacer: el registro se elimina', () async {
      final d = FakeDAsistencia();
      final invoker = AsistenciaInvoker();
      final ok = await invoker.executeCommand(RegistrarAsistenciaCommand(d, asis(1, 5, 'PRESENTE')));
      expect(ok, isTrue);
      expect(d.buscar(1, 5)?.estado, 'PRESENTE');
      expect(invoker.puedeDeshacer, isTrue);

      final deshecho = await invoker.undoCommand();
      expect(deshecho?.descripcion, 'Asistencia (PRESENTE)');
      expect(d.buscar(1, 5), isNull);
      expect(invoker.puedeDeshacer, isFalse);
    });

    test('Cambiar un estado existente y deshacer: vuelve al estado anterior', () async {
      final d = FakeDAsistencia();
      await d.registrarAsistencia(asis(1, 5, 'ATRASADO')); // ya existía
      final invoker = AsistenciaInvoker();
      await invoker.executeCommand(RegistrarAsistenciaCommand(d, asis(1, 5, 'PRESENTE')));
      expect(d.buscar(1, 5)?.estado, 'PRESENTE');
      expect(d.filas.length, 1); // no duplica

      await invoker.undoCommand();
      expect(d.buscar(1, 5)?.estado, 'ATRASADO');
      expect(d.filas.length, 1);
    });

    test('Deshacer en orden inverso (LIFO) con varios estudiantes', () async {
      final d = FakeDAsistencia();
      final invoker = AsistenciaInvoker();
      await invoker.executeCommand(RegistrarAsistenciaCommand(d, asis(1, 1, 'PRESENTE')));
      await invoker.executeCommand(RegistrarAsistenciaCommand(d, asis(1, 2, 'AUSENTE')));
      await invoker.undoCommand();
      expect(d.buscar(1, 2), isNull);
      expect(d.buscar(1, 1), isNotNull);
      await invoker.undoCommand();
      expect(d.filas, isEmpty);
    });

    test('Sin historial, undoCommand devuelve null', () async {
      expect(await AsistenciaInvoker().undoCommand(), isNull);
    });

    test('Un comando que falla no se guarda en el historial', () async {
      final invoker = AsistenciaInvoker();
      final c = ComandoFalso(false);
      expect(await invoker.executeCommand(c), isFalse);
      expect(c.ejecutado, 1);
      expect(invoker.puedeDeshacer, isFalse);
    });

    test('El historial guarda como máximo 20 comandos', () async {
      final invoker = AsistenciaInvoker();
      final comandos = List.generate(25, (_) => ComandoFalso());
      for (final c in comandos) {
        await invoker.executeCommand(c);
      }
      var deshechos = 0;
      while (await invoker.undoCommand() != null) {
        deshechos++;
      }
      expect(deshechos, 20);
      expect(comandos.first.deshecho, 0); // los más antiguos se descartan
      expect(comandos.last.deshecho, 1);
    });

    test('limpiar() vacía el historial', () async {
      final invoker = AsistenciaInvoker();
      await invoker.executeCommand(ComandoFalso());
      invoker.limpiar();
      expect(invoker.puedeDeshacer, isFalse);
    });
  });

  // ──────────────────────── TEMPLATE METHOD (CU-05) ────────────────────────
  group('Template Method - CU-05 Exportar a Excel', () {
    test('exportar() ejecuta los pasos en el orden fijo de la plantilla', () async {
      final d = FakeDAsistencia()
        ..listaParaExportar = [
          {'registro': '100', 'apellidos_nombres': 'Arce Luis', 'estado': 'PRESENTE', 'fecha_hora': '08:01'},
        ];
      final exp = ExportadorExamenPrueba(d);
      final msj = await exp.exportar();
      expect(msj, 'Exportación completada.');
      expect(exp.pasos, [
        'cargarDatos',
        'escribirEncabezado',
        'escribirFilas',
        'guardarArchivo',
        'compartirArchivo',
      ]);
    });

    test('Asistencia de un examen: mismo Excel que el 1er parcial', () async {
      final d = FakeDAsistencia()
        ..listaParaExportar = [
          {'registro': '100', 'apellidos_nombres': 'Arce Luis', 'estado': 'PRESENTE', 'fecha_hora': '08:01'},
          {'registro': '200', 'apellidos_nombres': null, 'estado': null, 'fecha_hora': null},
        ];
      final exp = ExportadorExamenPrueba(d);
      await exp.exportar();
      final hoja = Excel.decodeBytes(exp.bytes!)['asistencia'];
      expect([for (var c = 0; c < 5; c++) celda(hoja, 0, c)],
          ['Nro', 'Registro', 'Apellidos y Nombres', 'Estado Asistencia', 'Hora Registro']);
      expect([for (var c = 0; c < 5; c++) celda(hoja, 1, c)], ['1', '100', 'Arce Luis', 'PRESENTE', '08:01']);
      expect([for (var c = 0; c < 5; c++) celda(hoja, 2, c)], ['2', '200', 'Sin Nombre', 'AUSENTE', '--']);
    });

    test('Sin estudiantes: devuelve el mensaje y no guarda ni comparte', () async {
      final exp = ExportadorExamenPrueba(FakeDAsistencia());
      expect(await exp.exportar(), 'No hay estudiantes para exportar.');
      expect(exp.pasos, ['cargarDatos']);
    });

    // Datos de 2 exámenes para Consolidado y Cronograma.
    (FakeDAsistencia, FakeDEstudiante, FakeDExamen) datosMatriz() {
      final x = FakeDExamen()
        ..examenes = {
          10: NExamen(id: 10, idMateria: 1, titulo: 'Grupo 1', fecha: '2026-11-20', hora: '08:00', aula: '236'),
          20: NExamen(id: 20, idMateria: 1, titulo: 'Grupo 2', fecha: '2026-11-21', hora: '08:00', aula: '236'),
        };
      final e = FakeDEstudiante()..estudiantes = [est(1, '100', 'Arce Luis'), est(2, '200', 'Mendoza Eva')];
      final a = FakeDAsistencia()
        ..listaPorExamen = {
          10: [
            {'estudiante_id': 1, 'estado': 'PRESENTE'},
            {'estudiante_id': 2, 'estado': 'NO_ASIGNADO'},
          ],
          20: [
            {'estudiante_id': 1, 'estado': 'NO_ASIGNADO'},
            {'estudiante_id': 2, 'estado': null}, // sin registro -> AUSENTE
          ],
        };
      return (a, e, x);
    }

    test('Consolidado: matriz con estados, NO_ASIGNADO en blanco (igual que el 1er parcial)', () async {
      final (a, e, x) = datosMatriz();
      final real = ExportadorConsolidado(materiaId: 1, materiaNombre: 'Arquitectura', examenIds: [10, 20]);
      final exp = MatrizPrueba(real, a, e, x);
      expect(await exp.exportar(), 'Exportación consolidada completada.');
      final hoja = Excel.decodeBytes(exp.bytes!)['Consolidado'];
      expect(celda(hoja, 0, 0), 'Materia:');
      expect(celda(hoja, 0, 1), 'Arquitectura');
      expect(celda(hoja, 1, 1), 'Asistencia Consolidada de Múltiples Exámenes');
      expect(celda(hoja, 4, 2), 'Apellidos y Nombres');
      expect(celda(hoja, 4, 3), 'Grupo 1\n2026-11-20');
      expect([for (var c = 0; c < 5; c++) celda(hoja, 5, c)], ['1', '100', 'Arce Luis', 'PRESENTE', '']);
      expect([for (var c = 0; c < 5; c++) celda(hoja, 6, c)], ['2', '200', 'Mendoza Eva', '', 'AUSENTE']);
    });

    test('Cronograma: marca X el día asignado y deja en blanco NO_ASIGNADO', () async {
      final (a, e, x) = datosMatriz();
      final real = ExportadorCronograma(materiaId: 1, materiaNombre: 'Arquitectura', examenIds: [10, 20]);
      final exp = MatrizPrueba(real, a, e, x);
      expect(await exp.exportar(), 'Cronograma exportado.');
      final hoja = Excel.decodeBytes(exp.bytes!)['Cronograma'];
      expect(celda(hoja, 1, 1), 'Cronograma de Exámenes por Grupos');
      expect([for (var c = 3; c < 5; c++) celda(hoja, 5, c)], ['X', '']);
      expect([for (var c = 3; c < 5; c++) celda(hoja, 6, c)], ['', 'X']);
    });

    test('Matriz sin exámenes o sin estudiantes devuelve los mensajes del 1er parcial', () async {
      final (a, e, x) = datosMatriz();
      final real = ExportadorConsolidado(materiaId: 1, materiaNombre: 'A', examenIds: [99]);
      x.examenes.clear();
      expect(await MatrizPrueba(real, a, e, x).exportar(), 'No se encontraron los exámenes seleccionados.');

      final (a2, e2, x2) = datosMatriz();
      e2.estudiantes = [];
      expect(await MatrizPrueba(real, a2, e2, x2).exportar(), 'No hay estudiantes inscritos.');
    });

    test('Si un paso falla, devuelve el prefijo de error de la subclase', () async {
      final exp = ExportadorExamenPrueba(_DAsistenciaQueFalla());
      expect(await exp.exportar(), startsWith('Error al exportar: '));
    });
  });
}

class _DAsistenciaQueFalla extends FakeDAsistencia {
  @override
  Future<List<Map<String, dynamic>>> listarEstudiantesConAsistencia(int examenId, int materiaId) =>
      throw Exception('BD no disponible');
}
