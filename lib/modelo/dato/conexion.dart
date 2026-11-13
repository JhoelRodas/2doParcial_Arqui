import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Conexión a la base de datos local SQLite (clase normal, SIN Singleton).
/// Cada capa Dato la recibe por constructor (inyección de dependencias).
/// sqflite reutiliza internamente el mismo handle para la misma ruta.
class Conexion {
  Database? _database;

  Conexion();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('NAsistencia.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const textUniqueType = 'TEXT NOT NULL UNIQUE';
    const intType = 'INTEGER NOT NULL';

    // La foto se almacena como Base64 (o vacío si no viene en el Excel).
    await db.execute('''
CREATE TABLE estudiantes (
  id $idType,
  registro $textUniqueType,
  apellidos_nombres $textType,
  carrera $textType,
  plan $textType,
  telefono $textNullable,
  email $textNullable,
  foto $textNullable
)
''');

    await db.execute('''
CREATE TABLE materias (
  id $idType,
  codigo $textType,
  nombre $textType,
  grupo $textType,
  fecha_actualizacion $textNullable
)
''');

    await db.execute('''
CREATE TABLE examenes (
  id $idType,
  id_materia $intType,
  titulo $textType,
  fecha $textType,
  hora $textType,
  aula $textType,
  activo INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (id_materia) REFERENCES materias (id)
)
''');

    await db.execute('''
CREATE TABLE inscripciones (
  id $idType,
  id_materia $intType,
  id_estudiante $intType,
  estado TEXT NOT NULL DEFAULT 'ACTIVO',
  FOREIGN KEY (id_materia) REFERENCES materias (id),
  FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id)
)
''');

    await db.execute('''
CREATE TABLE asistencias (
  id $idType,
  id_examen $intType,
  id_estudiante $intType,
  fecha_hora $textType,
  estado $textType,
  FOREIGN KEY (id_examen) REFERENCES examenes (id),
  FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id)
)
''');
  }

  /// Migración: actualiza tablas preservando datos existentes.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE materias ADD COLUMN fecha_actualizacion TEXT');
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE inscripciones ADD COLUMN estado TEXT NOT NULL DEFAULT 'ACTIVO'");
      } catch (_) {}
    }
  }

  Future close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}



