class NAsistencia {
  final int? id;
  final int idExamen;
  final int idEstudiante;
  final String fechaHora;
  final String estado; // 'PRESENTE', 'AUSENTE', 'ATRASADO'
  final bool sincronizado;

  NAsistencia({
    this.id,
    required this.idExamen,
    required this.idEstudiante,
    required this.fechaHora,
    this.estado = 'PRESENTE',
    this.sincronizado = false,
  });

  factory NAsistencia.fromMap(Map<String, dynamic> map) => NAsistencia(
        id: map['id'] is int
            ? map['id'] as int
            : int.tryParse(map['id']?.toString() ?? ''),
        idExamen: map['id_examen'] is int
            ? map['id_examen'] as int
            : (int.tryParse(map['id_examen']?.toString() ?? '') ?? 0),
        idEstudiante: map['id_estudiante'] is int
            ? map['id_estudiante'] as int
            : (int.tryParse(map['id_estudiante']?.toString() ?? '') ?? 0),
        fechaHora: map['fecha_hora']?.toString() ?? '',
        estado: map['estado']?.toString() ?? 'PRESENTE',
        sincronizado: (map['sincronizado'] ?? 0) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'id_examen': idExamen,
        'id_estudiante': idEstudiante,
        'fecha_hora': fechaHora,
        'estado': estado,
      };

  NAsistencia copyWith({
    int? id,
    int? idExamen,
    int? idEstudiante,
    String? fechaHora,
    String? estado,
    bool? sincronizado,
  }) {
    return NAsistencia(
      id: id ?? this.id,
      idExamen: idExamen ?? this.idExamen,
      idEstudiante: idEstudiante ?? this.idEstudiante,
      fechaHora: fechaHora ?? this.fechaHora,
      estado: estado ?? this.estado,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }
}
