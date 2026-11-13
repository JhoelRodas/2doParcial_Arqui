import 'package:control_asistencia/modelo/dato/conexion.dart';
import 'package:control_asistencia/modelo/negocio/n_asistencia.dart';

/// Regla: Solo ejecuta SQL. Nunca contiene lógica de negocio.
class DAsistencia {
  // SIN SINGLETON: la conexión se recibe por constructor (inyección de dependencias).
  final Conexion dbHelper;

  DAsistencia({Conexion? conexion}) : dbHelper = conexion ?? Conexion();

  Future<int> registrarAsistencia(NAsistencia asistencia) async {
    final db = await dbHelper.database;
    final map = asistencia.toMap()
      ..remove('id')
      ..remove('sincronizado');

    final existing = await obtenerAsistencia(
      asistencia.idExamen,
      asistencia.idEstudiante,
    );
    if (existing != null && existing.id != null) {
      await db.update(
        'asistencias',
        map,
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    } else {
      return await db.insert('asistencias', map);
    }
  }

  Future<NAsistencia?> obtenerAsistencia(int examenId, int estudianteId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'asistencias',
      where: 'id_examen = ? AND id_estudiante = ?',
      whereArgs: [examenId, estudianteId],
    );
    if (res.isNotEmpty) {
      return NAsistencia.fromMap(res.first);
    }
    return null;
  }

  Future<int> eliminarAsistencia(int id) async {
    final db = await dbHelper.database;
    return await db.delete('asistencias', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listarEstudiantesConAsistencia(
    int examenId,
    int materiaId,
  ) async {
    final db = await dbHelper.database;
    return await db.rawQuery(
      '''
      SELECT 
        e.id as estudiante_id,
        e.registro,
        e.apellidos_nombres,
        e.carrera,
        e.foto,
        a.id as asistencia_id,
        a.fecha_hora,
        COALESCE(a.estado, 'AUSENTE') as estado
      FROM estudiantes e
      INNER JOIN inscripciones i ON e.id = i.id_estudiante
      LEFT JOIN asistencias a ON (e.id = a.id_estudiante AND a.id_examen = ?)
      WHERE i.id_materia = ?
        AND (COALESCE(i.estado, 'ACTIVO') = 'ACTIVO' OR a.id IS NOT NULL)
      ORDER BY e.apellidos_nombres
    ''',
      [examenId, materiaId],
    );
  }

  Future<Map<String, int>> obtenerEstadisticasExamen(
    int examenId,
    int materiaId,
  ) async {
    final list = await listarEstudiantesConAsistencia(examenId, materiaId);
    int total = 0;
    int presentes = 0;
    int atrasados = 0;
    int ausentes = 0;

    for (var item in list) {
      final estado = item['estado'] as String;

      if (estado == 'NO_ASIGNADO') {
        continue;
      }

      total++;
      if (estado == 'PRESENTE') {
        presentes++;
      } else if (estado == 'ATRASADO') {
        atrasados++;
      } else {
        ausentes++;
      }
    }

    return {
      'total': total,
      'presentes': presentes,
      'atrasados': atrasados,
      'ausentes': ausentes,
    };
  }
}

