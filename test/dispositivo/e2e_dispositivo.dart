// PRUEBA DE PUNTA A PUNTA EN EL CELULAR (con la base SQLite real del teléfono).
// No forma parte de la app. Se ejecuta con:
//   flutter run -t test/dispositivo/e2e_dispositivo.dart
// Crea datos de prueba, recorre CU-03 (Strategy), CU-04 (Command) y
// CU-05 (Template Method) con los controladores y clases D reales, y al final
// borra SOLO los registros que creó (materia "E2E Arquitectura", sus
// estudiantes 22100000x, exámenes y asistencias). No toca otros datos.

import 'dart:io';
import 'dart:math';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:control_asistencia/controlador/c_asistencia.dart';
import 'package:control_asistencia/controlador/c_estudiante.dart';
import 'package:control_asistencia/controlador/c_examen.dart';
import 'package:control_asistencia/controlador/strategy/orden_strategy.dart';
import 'package:control_asistencia/controlador/template/exportadores_concretos.dart';
import 'package:control_asistencia/modelo/dato/conexion.dart';
import 'package:control_asistencia/modelo/dato/d_asistencia.dart';
import 'package:control_asistencia/modelo/dato/d_estudiante.dart';
import 'package:control_asistencia/modelo/dato/d_materia.dart';
import 'package:control_asistencia/modelo/negocio/n_asistencia.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';
import 'package:control_asistencia/modelo/negocio/n_examen.dart';
import 'package:control_asistencia/modelo/negocio/n_materia.dart';

final List<String> resultados = [];
int ok = 0, fallos = 0;

void check(String nombre, bool condicion, [Object? detalle]) {
  final linea = '${condicion ? 'OK  ' : 'FALLA'} $nombre${condicion || detalle == null ? '' : '  -> $detalle'}';
  condicion ? ok++ : fallos++;
  resultados.add(linea);
  debugPrint('E2E: $linea');
}

// Exportadores reales pero SIN abrir el menú de compartir (guardan el archivo de verdad).
class ExpExamenSinCompartir extends ExportadorAsistenciaExamen {
  String? ruta;
  ExpExamenSinCompartir({required super.examenId, required super.materiaId, required super.tituloExamen});
  @override
  Future<void> compartirArchivo(String r) async => ruta = r;
}

class ExpConsolidadoSinCompartir extends ExportadorConsolidado {
  String? ruta;
  ExpConsolidadoSinCompartir({required super.materiaId, required super.materiaNombre, required super.examenIds});
  @override
  Future<void> compartirArchivo(String r) async => ruta = r;
}

class ExpCronogramaSinCompartir extends ExportadorCronograma {
  String? ruta;
  ExpCronogramaSinCompartir({required super.materiaId, required super.materiaNombre, required super.examenIds});
  @override
  Future<void> compartirArchivo(String r) async => ruta = r;
}

Future<Sheet> leerHoja(String? ruta, String hoja) async =>
    Excel.decodeBytes(await File(ruta!).readAsBytes())[hoja];

String celda(Sheet h, int f, int c) => h.rows[f][c]?.value?.toString() ?? '';

/// Misma lógica que VMateriaDetalle._generarYGuardarGrupos (CU-03), usando
/// el patrón Strategy y los controladores reales.
Future<List<int>> generarGrupos(int materiaId, String orden, int porGrupo, String titulo) async {
  final cEst = CEstudiante();
  final cEx = CExamen();
  final dAs = DAsistencia();
  final activos = await cEst.listarEstudiantesPorMateria(materiaId, estado: 'ACTIVO');

  final gruposContext = AsignacionGruposContext();
  gruposContext.setStrategy(orden == 'Aleatorio' ? OrdenAleatorioStrategy() : OrdenAlfabeticoStrategy());
  final estudiantes = gruposContext.ordenar(activos);

  final grupos = (estudiantes.length / porGrupo).ceil();
  final ids = <int>[];
  for (int i = 0; i < grupos; i++) {
    final asignados = estudiantes.sublist(i * porGrupo, min((i + 1) * porGrupo, estudiantes.length)).map((e) => e.id).toSet();
    final exId = await cEx.crearExamen(NExamen(
      idMateria: materiaId,
      titulo: '$titulo - Grupo ${i + 1}',
      fecha: DateFormat('yyyy-MM-dd').format(DateTime(2026, 11, 20).add(Duration(days: i))),
      hora: '10:00:00',
      aula: '236',
    ));
    ids.add(exId);
    creadosExamenes.add(exId);
    for (final e in estudiantes) {
      if (!asignados.contains(e.id)) {
        await dAs.registrarAsistencia(NAsistencia(idExamen: exId, idEstudiante: e.id!, estado: 'NO_ASIGNADO', fechaHora: ''));
      }
    }
  }
  return ids;
}

Future<void> ejecutarPruebas() async {
  final dAs = DAsistencia();
  final dEst = DEstudiante();

  // ───────────── Datos de prueba ─────────────
  final materiaId = await DMateria().insertar(NMateria(codigo: 'INF552', nombre: 'E2E Arquitectura', grupo: 'SA'));
  creadaMateriaId = materiaId;
  final nombres = ['Zarate Paz Ivan', 'arce rojas luis', 'Mendoza Cruz Eva', 'Perez Lopez Ana', 'Borda Vaca Juan'];
  final ids = <String, int>{};
  for (var i = 0; i < nombres.length; i++) {
    final reg = '22100000${i + 1}';
    final id = await dEst.upsert(NEstudiante(registro: reg, apellidosNombres: nombres[i], carrera: 'Sistemas', plan: '187-3', telefono: '', email: ''));
    await dEst.inscribir(id, materiaId);
    ids[nombres[i]] = id;
    creadosEstudiantes.add(id);
  }
  // Un estudiante retirado (no debe entrar a los grupos)
  final retId = await dEst.upsert(NEstudiante(registro: '221000009', apellidosNombres: 'Aaa Retirado Pepe', carrera: 'Sistemas', plan: '187-3', telefono: '', email: ''));
  await dEst.inscribir(retId, materiaId, estado: 'RETIRADO');
  creadosEstudiantes.add(retId);
  check('Datos: materia y 6 estudiantes creados en SQLite', materiaId > 0 && ids.length == 5);

  // ───────────── CU-03 STRATEGY ─────────────
  final examenes = await generarGrupos(materiaId, 'Alfabetico', 2, 'Parcial');
  check('CU-03 Strategy Alfabético: 5 activos / 2 por grupo = 3 exámenes', examenes.length == 3, examenes.length);

  Future<List<String>> asignadosDe(int exId) async => (await dAs.listarEstudiantesConAsistencia(exId, materiaId))
      .where((m) => m['estado'] != 'NO_ASIGNADO')
      .map((m) => m['apellidos_nombres'].toString())
      .toList();
  final g1 = await asignadosDe(examenes[0]);
  final g2 = await asignadosDe(examenes[1]);
  final g3 = await asignadosDe(examenes[2]);
  check('CU-03 Grupo 1 = Arce, Borda (orden alfabético, sin mayúsculas)', g1.length == 2 && g1.contains('arce rojas luis') && g1.contains('Borda Vaca Juan'), g1);
  check('CU-03 Grupo 2 = Mendoza, Perez', g2.length == 2 && g2.contains('Mendoza Cruz Eva') && g2.contains('Perez Lopez Ana'), g2);
  check('CU-03 Grupo 3 = Zarate', g3.length == 1 && g3.first == 'Zarate Paz Ivan', g3);
  check('CU-03 El RETIRADO no entra a ningún grupo', ![...g1, ...g2, ...g3].contains('Aaa Retirado Pepe'));

  final aleatorio = await generarGrupos(materiaId, 'Aleatorio', 2, 'Recuperatorio');
  final todos = <String>[];
  for (final e in aleatorio) {
    todos.addAll(await asignadosDe(e));
  }
  check('CU-03 Strategy Aleatorio: 3 exámenes y cada activo en exactamente 1 grupo',
      aleatorio.length == 3 && todos.length == 5 && todos.toSet().length == 5, todos);

  // ───────────── CU-04 COMMAND (con CAsistencia real) ─────────────
  final cAs = CAsistencia();
  final ex1 = examenes[0];
  final arce = (await dEst.obtenerPorRegistro('221000002'))!;
  final mendoza = (await dEst.obtenerPorRegistro('221000003'))!;

  final v1 = await cAs.validarEstudianteQR(qrPayload: '221000002', examenId: ex1, materiaId: materiaId);
  check('CU-04 QR válido para estudiante del grupo 1', v1['valido'] == true, v1['error']);
  final v2 = await cAs.validarEstudianteQR(qrPayload: '221000003', examenId: ex1, materiaId: materiaId);
  check('CU-04 QR rechazado: estudiante de otro grupo (NO_ASIGNADO)', v2['valido'] == false && v2['error'].toString().contains('otro día'), v2);
  final v3 = await cAs.validarEstudianteQR(qrPayload: '221000009', examenId: ex1, materiaId: materiaId);
  check('CU-04 QR rechazado: RETIRADO', v3['valido'] == false && v3['error'].toString().contains('RETIRADO'), v3);
  final v4 = await cAs.validarEstudianteQR(qrPayload: '999', examenId: ex1, materiaId: materiaId);
  check('CU-04 QR rechazado: no existe en BD', v4['valido'] == false, v4);

  check('CU-04 Al inicio no hay nada que deshacer', cAs.puedeDeshacer == false);
  final r1 = await cAs.registrarAsistencia(estudiante: arce, examenId: ex1, materiaId: materiaId, estado: 'PRESENTE');
  check('CU-04 Registrar PRESENTE (execute)', r1 && (await dAs.obtenerAsistencia(ex1, arce.id!))?.estado == 'PRESENTE');
  await cAs.registrarAsistencia(estudiante: arce, examenId: ex1, materiaId: materiaId, estado: 'ATRASADO');
  check('CU-04 Cambiar a ATRASADO (actualiza, no duplica)', (await dAs.obtenerAsistencia(ex1, arce.id!))?.estado == 'ATRASADO');
  check('CU-04 Ahora se puede deshacer', cAs.puedeDeshacer == true);

  final d1 = await cAs.deshacerUltimaAsistencia();
  check('CU-04 Deshacer 1: vuelve a PRESENTE', d1 == 'Asistencia (ATRASADO)' && (await dAs.obtenerAsistencia(ex1, arce.id!))?.estado == 'PRESENTE', d1);
  final d2 = await cAs.deshacerUltimaAsistencia();
  check('CU-04 Deshacer 2: se elimina el registro (vuelve a AUSENTE en la lista)',
      d2 == 'Asistencia (PRESENTE)' && await dAs.obtenerAsistencia(ex1, arce.id!) == null, d2);
  check('CU-04 Historial vacío y deshacer devuelve null', cAs.puedeDeshacer == false && await cAs.deshacerUltimaAsistencia() == null);

  // Registro manual de alguien de otro grupo y deshacer: debe volver a NO_ASIGNADO
  await cAs.registrarAsistencia(estudiante: mendoza, examenId: ex1, materiaId: materiaId, estado: 'PRESENTE');
  await cAs.deshacerUltimaAsistencia();
  check('CU-04 Deshacer registro manual de otro grupo: vuelve a NO_ASIGNADO',
      (await dAs.obtenerAsistencia(ex1, mendoza.id!))?.estado == 'NO_ASIGNADO');

  // Datos finales para exportar
  await cAs.registrarAsistencia(estudiante: arce, examenId: ex1, materiaId: materiaId, estado: 'PRESENTE');
  final borda = (await dEst.obtenerPorRegistro('221000005'))!;
  await cAs.registrarAsistencia(estudiante: borda, examenId: ex1, materiaId: materiaId, estado: 'ATRASADO');

  // ───────────── CU-05 TEMPLATE METHOD ─────────────
  final e1 = ExpExamenSinCompartir(examenId: ex1, materiaId: materiaId, tituloExamen: 'Parcial - Grupo 1');
  final m1 = await e1.exportar();
  check('CU-05 Asistencia de examen: mensaje de éxito', m1 == 'Exportación completada.', m1);
  final h1 = await leerHoja(e1.ruta, 'asistencia');
  check('CU-05 Archivo guardado en el celular', e1.ruta != null && File(e1.ruta!).existsSync(), e1.ruta);
  check('CU-05 Encabezado del Excel de asistencia', celda(h1, 0, 2) == 'Apellidos y Nombres' && celda(h1, 0, 3) == 'Estado Asistencia');
  final filasArce = h1.rows.where((r) => r.length > 2 && r[2]?.value?.toString() == 'arce rojas luis').toList();
  check('CU-05 Fila de Arce con PRESENTE', filasArce.length == 1 && filasArce.first[3]?.value?.toString() == 'PRESENTE');

  final e2 = ExpConsolidadoSinCompartir(materiaId: materiaId, materiaNombre: 'E2E Arquitectura', examenIds: examenes);
  final m2 = await e2.exportar();
  check('CU-05 Consolidado: mensaje de éxito', m2 == 'Exportación consolidada completada.', m2);
  final h2 = await leerHoja(e2.ruta, 'Consolidado');
  check('CU-05 Consolidado: título y materia', celda(h2, 0, 1) == 'E2E Arquitectura' && celda(h2, 1, 1).startsWith('Asistencia Consolidada'));
  check('CU-05 Consolidado: 3 columnas de exámenes', h2.rows[4].length >= 6 && celda(h2, 4, 3).contains('Parcial - Grupo 1'));
  // fila 5 = primer estudiante activo en orden alfabético de listarPorMateria
  final filaArce = h2.rows.firstWhere((r) => r.length > 2 && r[2]?.value?.toString() == 'arce rojas luis');
  check('CU-05 Consolidado: Arce = PRESENTE en G1, vacío en G2 y G3 (NO_ASIGNADO)',
      filaArce[3]?.value?.toString() == 'PRESENTE' && (filaArce[4]?.value?.toString() ?? '') == '' && (filaArce[5]?.value?.toString() ?? '') == '',
      filaArce.map((c) => c?.value).toList());

  final e3 = ExpCronogramaSinCompartir(materiaId: materiaId, materiaNombre: 'E2E Arquitectura', examenIds: examenes);
  final m3 = await e3.exportar();
  check('CU-05 Cronograma: mensaje de éxito', m3 == 'Cronograma exportado.', m3);
  final h3 = await leerHoja(e3.ruta, 'Cronograma');
  final filaZ = h3.rows.firstWhere((r) => r.length > 2 && r[2]?.value?.toString() == 'Zarate Paz Ivan');
  check('CU-05 Cronograma: Zarate con X solo en el día 3',
      (filaZ[3]?.value?.toString() ?? '') == '' && (filaZ[4]?.value?.toString() ?? '') == '' && filaZ[5]?.value?.toString() == 'X',
      filaZ.map((c) => c?.value).toList());
  final filaR = h3.rows.where((r) => r.length > 2 && r[2]?.value?.toString() == 'Aaa Retirado Pepe');
  check('CU-05 Cronograma: el RETIRADO no aparece', filaR.isEmpty);

  // Limpiar archivos exportados de prueba
  for (final r in [e1.ruta, e2.ruta, e3.ruta]) {
    if (r != null && File(r).existsSync()) File(r).deleteSync();
  }
}

// IDs creados por la prueba: al final se borran SOLO estos registros.
int? creadaMateriaId;
final List<int> creadosEstudiantes = [];
final List<int> creadosExamenes = [];

Future<void> limpiarDatosDePrueba() async {
  final db = await Conexion().database;
  String lista(List<int> ids) => ids.join(',');
  if (creadosExamenes.isNotEmpty) {
    await db.delete('asistencias', where: 'id_examen IN (${lista(creadosExamenes)})');
    await db.delete('examenes', where: 'id IN (${lista(creadosExamenes)})');
  }
  if (creadaMateriaId != null) {
    await db.delete('inscripciones', where: 'id_materia = ?', whereArgs: [creadaMateriaId]);
    await db.delete('materias', where: 'id = ?', whereArgs: [creadaMateriaId]);
  }
  if (creadosEstudiantes.isNotEmpty) {
    await db.delete('estudiantes', where: 'id IN (${lista(creadosEstudiantes)}) AND registro LIKE ?', whereArgs: ['22100000%']);
  }
  resultados.add('Datos de prueba eliminados (solo los creados por esta prueba).');
  debugPrint('E2E: Datos de prueba eliminados.');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ejecutarPruebas();
  } catch (e, st) {
    check('Excepción inesperada', false, '$e\n$st');
  }
  try {
    await limpiarDatosDePrueba();
  } catch (e) {
    debugPrint('E2E: No se pudo limpiar la base: $e');
  }
  debugPrint('E2E: RESUMEN $ok OK, $fallos FALLAS');
  debugPrint('E2E: FIN');
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('E2E: $ok OK, $fallos FALLAS')),
      body: ListView(children: [for (final r in resultados) ListTile(dense: true, title: Text(r))]),
    ),
  ));
}
