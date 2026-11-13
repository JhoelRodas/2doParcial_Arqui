class NExamen {
  final int? id;
  final int idMateria;
  final String titulo;
  final String fecha;
  final String hora;
  final String aula;
  final bool activo;

  NExamen({
    this.id,
    required this.idMateria,
    required this.titulo,
    required this.fecha,
    required this.hora,
    required this.aula,
    this.activo = true,
  });

  factory NExamen.fromMap(Map<String, dynamic> map) => NExamen(
        id: map['id'],
        idMateria: map['id_materia'],
        titulo: map['titulo'],
        fecha: map['fecha'],
        hora: map['hora'],
        aula: map['aula'],
        activo: (map['activo'] ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'id_materia': idMateria,
        'titulo': titulo,
        'fecha': fecha,
        'hora': hora,
        'aula': aula,
        'activo': activo ? 1 : 0,
      };
}
