import 'package:control_asistencia/modelo/dato/conexion.dart';
import 'package:control_asistencia/modelo/negocio/n_materia.dart';

class DMateria {
  // SIN SINGLETON: la conexión se recibe por constructor (inyección de dependencias).
  final Conexion dbHelper;

  DMateria({Conexion? conexion}) : dbHelper = conexion ?? Conexion();

  Future<List<NMateria>> listarTodas() async {
    final db = await dbHelper.database;
    final res = await db.query('materias', orderBy: 'nombre ASC');
    return res.map((m) => NMateria.fromMap(m)).toList();
  }

  Future<NMateria?> obtenerPorId(int id) async {
    final db = await dbHelper.database;
    final res = await db.query('materias', where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) {
      return NMateria.fromMap(res.first);
    }
    return null;
  }

  Future<int> insertar(NMateria materia) async {
    final db = await dbHelper.database;
    return await db.insert('materias', materia.toMap()..remove('id'));
  }

  Future<int> actualizarFechaImportacion(int idMateria, String fechaIso) async {
    final db = await dbHelper.database;
    return await db.update(
      'materias',
      {'fecha_actualizacion': fechaIso},
      where: 'id = ?',
      whereArgs: [idMateria],
    );
  }

  Future<int> actualizar(NMateria materia) async {
    final db = await dbHelper.database;
    return await db.update(
      'materias',
      materia.toMap()
        ..remove('id')
        ..remove('fecha_actualizacion'),
      where: 'id = ?',
      whereArgs: [materia.id],
    );
  }

  Future<int> eliminar(int idMateria) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      final examenes = await txn.query(
        'examenes',
        where: 'id_materia = ?',
        whereArgs: [idMateria],
      );
      for (var examen in examenes) {
        await txn.delete(
          'asistencias',
          where: 'id_examen = ?',
          whereArgs: [examen['id']],
        );
      }
      await txn.delete(
        'examenes',
        where: 'id_materia = ?',
        whereArgs: [idMateria],
      );
      await txn.delete(
        'inscripciones',
        where: 'id_materia = ?',
        whereArgs: [idMateria],
      );
      return await txn.delete(
        'materias',
        where: 'id = ?',
        whereArgs: [idMateria],
      );
    });
  }
}

