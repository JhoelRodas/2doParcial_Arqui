import 'package:control_asistencia/modelo/dato/conexion.dart';
import 'package:control_asistencia/modelo/negocio/n_examen.dart';

class DExamen {
  // SIN SINGLETON: la conexión se recibe por constructor (inyección de dependencias).
  final Conexion dbHelper;

  DExamen({Conexion? conexion}) : dbHelper = conexion ?? Conexion();

  Future<List<NExamen>> listarPorMateria(int materiaId) async {
    final db = await dbHelper.database;
    final res = await db.query(
      'examenes',
      where: 'id_materia = ?',
      whereArgs: [materiaId],
      orderBy: 'fecha DESC, hora DESC',
    );
    return res.map((e) => NExamen.fromMap(e)).toList();
  }

  Future<NExamen?> obtenerPorId(int id) async {
    final db = await dbHelper.database;
    final res = await db.query('examenes', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return NExamen.fromMap(res.first);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> listarExamenesConMateria() async {
    final db = await dbHelper.database;
    return await db.rawQuery('''
      SELECT e.*, m.nombre as materia_nombre, m.codigo as materia_codigo, m.grupo as materia_grupo
      FROM examenes e
      INNER JOIN materias m ON e.id_materia = m.id
      ORDER BY e.activo DESC, e.fecha DESC
    ''');
  }

  Future<int> insertar(NExamen examen) async {
    final db = await dbHelper.database;
    return await db.insert('examenes', examen.toMap()..remove('id'));
  }

  Future<int> actualizar(NExamen examen) async {
    final db = await dbHelper.database;
    return await db.update(
      'examenes',
      examen.toMap()
        ..remove('id')
        ..remove('id_materia'),
      where: 'id = ?',
      whereArgs: [examen.id],
    );
  }

  Future<int> eliminar(int idExamen) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      await txn.delete(
        'asistencias',
        where: 'id_examen = ?',
        whereArgs: [idExamen],
      );
      return await txn.delete(
        'examenes',
        where: 'id = ?',
        whereArgs: [idExamen],
      );
    });
  }
}

