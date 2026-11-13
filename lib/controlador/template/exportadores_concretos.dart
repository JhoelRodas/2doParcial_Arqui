import 'package:excel/excel.dart';
import 'package:control_asistencia/controlador/template/exportador_excel.dart';
import 'package:control_asistencia/modelo/dato/d_asistencia.dart';
import 'package:control_asistencia/modelo/dato/d_estudiante.dart';
import 'package:control_asistencia/modelo/dato/d_examen.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';
import 'package:control_asistencia/modelo/negocio/n_examen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Subclase 1: asistencia de UN examen (lista simple)
// ═══════════════════════════════════════════════════════════════════════════
class ExportadorAsistenciaExamen extends ExportadorExcel {
  final DAsistencia _dAsistencia;
  final int examenId;
  final int materiaId;
  final String tituloExamen;

  List<Map<String, dynamic>> _lista = [];

  ExportadorAsistenciaExamen({
    required this.examenId,
    required this.materiaId,
    required this.tituloExamen,
    DAsistencia? dAsistencia,
  }) : _dAsistencia = dAsistencia ?? DAsistencia();

  @override
  String get nombreHoja => 'asistencia';
  @override
  String get prefijoArchivo => 'Asistencia';
  @override
  String get nombreParaArchivo => tituloExamen;
  @override
  String get textoCompartir => 'Reporte de Asistencia: $tituloExamen';
  @override
  String get mensajeExito => 'Exportación completada.';
  @override
  String get prefijoError => 'Error al exportar';

  // Paso variable: datos de UN examen.
  @override
  Future<String?> cargarDatos() async {
    _lista = await _dAsistencia.listarEstudiantesConAsistencia(
      examenId,
      materiaId,
    );
    if (_lista.isEmpty) return 'No hay estudiantes para exportar.';
    return null;
  }

  @override
  void escribirEncabezado(Sheet hoja) {
    hoja.appendRow([
      TextCellValue('Nro'),
      TextCellValue('Registro'),
      TextCellValue('Apellidos y Nombres'),
      TextCellValue('Estado Asistencia'),
      TextCellValue('Hora Registro'),
    ]);
  }

  @override
  void escribirFilas(Sheet hoja) {
    for (int i = 0; i < _lista.length; i++) {
      final est = _lista[i];
      hoja.appendRow([
        IntCellValue(i + 1),
        TextCellValue((est['registro'] ?? '').toString()),
        TextCellValue((est['apellidos_nombres'] ?? 'Sin Nombre').toString()),
        TextCellValue((est['estado'] ?? 'AUSENTE').toString()),
        TextCellValue((est['fecha_hora'] ?? '--').toString()),
      ]);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Clase intermedia: matriz estudiantes x exámenes (Consolidado y Cronograma
// comparten carga de datos, encabezado y filas; solo cambia el valor de celda)
// ═══════════════════════════════════════════════════════════════════════════
abstract class ExportadorMatrizExamenes extends ExportadorExcel {
  final DAsistencia _dAsistencia;
  final DEstudiante _dEstudiante;
  final DExamen _dExamen;

  final int materiaId;
  final String materiaNombre;
  final List<int> examenIds;

  List<NExamen> _examenes = [];
  List<NEstudiante> _estudiantes = [];
  final Map<int, Map<int, String>> _asistencias = {};

  ExportadorMatrizExamenes({
    required this.materiaId,
    required this.materiaNombre,
    required this.examenIds,
    DAsistencia? dAsistencia,
    DEstudiante? dEstudiante,
    DExamen? dExamen,
  }) : _dAsistencia = dAsistencia ?? DAsistencia(),
       _dEstudiante = dEstudiante ?? DEstudiante(),
       _dExamen = dExamen ?? DExamen();

  /// Subtítulo del reporte (fila 2 del Excel).
  String get tituloReporte;

  /// Paso variable: qué se escribe en la celda según el estado de asistencia.
  String valorCelda(String estado);

  @override
  String get nombreParaArchivo => materiaNombre;

  @override
  Future<String?> cargarDatos() async {
    _examenes = [];
    for (final id in examenIds) {
      final ex = await _dExamen.obtenerPorId(id);
      if (ex != null) _examenes.add(ex);
    }
    if (_examenes.isEmpty) {
      return 'No se encontraron los exámenes seleccionados.';
    }

    _estudiantes = await _dEstudiante.listarPorMateria(
      materiaId,
      estado: 'ACTIVO',
    );
    if (_estudiantes.isEmpty) return 'No hay estudiantes inscritos.';

    _asistencias.clear();
    for (final ex in _examenes) {
      final listaExamen = await _dAsistencia.listarEstudiantesConAsistencia(
        ex.id!,
        materiaId,
      );
      for (final item in listaExamen) {
        final estId = item['estudiante_id'] as int;
        final estado = (item['estado'] ?? 'AUSENTE').toString();
        _asistencias.putIfAbsent(estId, () => {})[ex.id!] = estado;
      }
    }
    return null;
  }

  @override
  void escribirEncabezado(Sheet hoja) {
    hoja.cell(CellIndex.indexByString("A1")).value = TextCellValue('Materia:');
    hoja.cell(CellIndex.indexByString("B1")).value = TextCellValue(
      materiaNombre,
    );
    hoja.cell(CellIndex.indexByString("A2")).value = TextCellValue('Reporte:');
    hoja.cell(CellIndex.indexByString("B2")).value = TextCellValue(
      tituloReporte,
    );

    final headers = [
      TextCellValue('Nro'),
      TextCellValue('Registro'),
      TextCellValue('Apellidos y Nombres'),
    ];
    for (final ex in _examenes) {
      headers.add(TextCellValue('${ex.titulo}\n${ex.fecha}'));
    }
    hoja.insertRowIterables(headers, 4);
  }

  @override
  void escribirFilas(Sheet hoja) {
    for (int i = 0; i < _estudiantes.length; i++) {
      final est = _estudiantes[i];
      final rowValues = <CellValue>[
        IntCellValue(i + 1),
        TextCellValue(est.registro),
        TextCellValue(est.nombreCompleto),
      ];

      for (final ex in _examenes) {
        final estadoReal = _asistencias[est.id]?[ex.id!] ?? 'AUSENTE';
        rowValues.add(TextCellValue(valorCelda(estadoReal)));
      }
      hoja.insertRowIterables(rowValues, 5 + i);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Subclase 2: consolidado de asistencia de varios exámenes
// ═══════════════════════════════════════════════════════════════════════════
class ExportadorConsolidado extends ExportadorMatrizExamenes {
  ExportadorConsolidado({
    required super.materiaId,
    required super.materiaNombre,
    required super.examenIds,
  });

  @override
  String get nombreHoja => 'Consolidado';
  @override
  String get prefijoArchivo => 'Consolidado';
  @override
  String get tituloReporte => 'Asistencia Consolidada de Múltiples Exámenes';
  @override
  String get textoCompartir => 'Consolidado de Asistencias: $materiaNombre';
  @override
  String get mensajeExito => 'Exportación consolidada completada.';
  @override
  String get prefijoError => 'Error al exportar consolidado';

  // Paso variable: el consolidado muestra el estado de asistencia.
  @override
  String valorCelda(String estado) => estado == 'NO_ASIGNADO' ? '' : estado;
}

// ═══════════════════════════════════════════════════════════════════════════
// Subclase 3: cronograma de grupos (marca con 'X' el día que le toca)
// ═══════════════════════════════════════════════════════════════════════════
class ExportadorCronograma extends ExportadorMatrizExamenes {
  ExportadorCronograma({
    required super.materiaId,
    required super.materiaNombre,
    required super.examenIds,
  });

  @override
  String get nombreHoja => 'Cronograma';
  @override
  String get prefijoArchivo => 'Cronograma';
  @override
  String get tituloReporte => 'Cronograma de Exámenes por Grupos';
  @override
  String get textoCompartir => 'Cronograma de Exámenes: $materiaNombre';
  @override
  String get mensajeExito => 'Cronograma exportado.';
  @override
  String get prefijoError => 'Error al exportar cronograma';

  // Paso variable: el cronograma solo marca con 'X' el día que le toca.
  @override
  String valorCelda(String estado) => estado == 'NO_ASIGNADO' ? '' : 'X';
}
