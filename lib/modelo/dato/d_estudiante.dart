import 'package:control_asistencia/modelo/dato/conexion.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';

class DEstudiante {
  // SIN SINGLETON: la conexión se recibe por constructor (inyección de dependencias).
  final Conexion dbHelper;

  DEstudiante({Conexion? conexion}) : dbHelper = conexion ?? Conexion();

  /// Usado al importar el Excel del docente.
  Future<int> upsert(NEstudiante estudiante) async {
    final db = await dbHelper.database;
    final existing = await obtenerPorRegistro(estudiante.registro);
    if (existing != null && existing.id != null) {
      await db.update(
        'estudiantes',
        estudiante.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    } else {
      return await db.insert('estudiantes', estudiante.toMap()..remove('id'));
    }
  }

  Future<NEstudiante?> obtenerPorId(int id) async {
    final db = await dbHelper.database;
    final res = await db.query('estudiantes', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return NEstudiante.fromMap(res.first);
    }
    return null;
  }

  Future<NEstudiante?> obtenerPorRegistro(String registro) async {
    final db = await dbHelper.database;
    String base = registro.trim();
    final match = RegExp(r'^(-?\d+)\.0+$').firstMatch(base);
    if (match != null) {
      base = match.group(1)!;
    }

    final res = await db.query(
      'estudiantes',
      where: 'registro = ? OR registro = ?',
      whereArgs: [base, '$base.0'],
    );
    if (res.isNotEmpty) {
      return NEstudiante.fromMap(res.first);
    }
    return null;
  }

  Future<List<NEstudiante>> listarPorMateria(
    int materiaId, {
    String? estado,
  }) async {
    final db = await dbHelper.database;
    String query = '''
      SELECT e.* FROM estudiantes e
      INNER JOIN inscripciones i ON e.id = i.id_estudiante
      WHERE i.id_materia = ?
    ''';
    List<dynamic> args = [materiaId];

    if (estado != null) {
      query += " AND COALESCE(i.estado, 'ACTIVO') = ?";
      args.add(estado);
    }

    query += ' ORDER BY e.apellidos_nombres';

    final res = await db.rawQuery(query, args);
    return res.map((m) => NEstudiante.fromMap(m)).toList();
  }

  Future<Map<String, int>> contarPorMateria(int materiaId) async {
    final db = await dbHelper.database;
    final res = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN COALESCE(estado, 'ACTIVO') = 'ACTIVO' THEN 1 ELSE 0 END) as activos,
        SUM(CASE WHEN estado = 'RETIRADO' THEN 1 ELSE 0 END) as retirados
      FROM inscripciones
      WHERE id_materia = ?
    ''',
      [materiaId],
    );

    if (res.isNotEmpty) {
      final row = res.first;
      return {
        'total': (row['total'] as num?)?.toInt() ?? 0,
        'activos': (row['activos'] as num?)?.toInt() ?? 0,
        'retirados': (row['retirados'] as num?)?.toInt() ?? 0,
      };
    }
    return {'total': 0, 'activos': 0, 'retirados': 0};
  }

  Future<List<NEstudiante>> listarTodos() async {
    final db = await dbHelper.database;
    final res = await db.query('estudiantes', orderBy: 'apellidos_nombres');
    return res.map((m) => NEstudiante.fromMap(m)).toList();
  }

  Future<void> inscribir(
    int estudianteId,
    int materiaId, {
    String estado = 'ACTIVO',
  }) async {
    if (estudianteId <= 0 || materiaId <= 0) return;
    final db = await dbHelper.database;
    final existing = await db.query(
      'inscripciones',
      where: 'id_materia = ? AND id_estudiante = ?',
      whereArgs: [materiaId, estudianteId],
    );
    if (existing.isEmpty) {
      await db.insert('inscripciones', {
        'id_materia': materiaId,
        'id_estudiante': estudianteId,
        'estado': estado,
      });
    } else {
      await db.update(
        'inscripciones',
        {'estado': estado},
        where: 'id_materia = ? AND id_estudiante = ?',
        whereArgs: [materiaId, estudianteId],
      );
    }
  }

  Future<int> desinscribirNoPresentes(
    int materiaId,
    Set<int> idsEstudiantesActivos,
  ) async {
    final db = await dbHelper.database;
    if (idsEstudiantesActivos.isEmpty) return 0;
    final placeholders = List.filled(
      idsEstudiantesActivos.length,
      '?',
    ).join(',');
    return await db.rawUpdate(
      '''
      UPDATE inscripciones
      SET estado = 'RETIRADO'
      WHERE id_materia = ?
        AND COALESCE(estado, 'ACTIVO') != 'RETIRADO'
        AND id_estudiante NOT IN ($placeholders)
    ''',
      [materiaId, ...idsEstudiantesActivos],
    );
  }
}

