class NMateria {
  final int? id;
  final String codigo;
  final String nombre;
  final String grupo;
  final String? fechaActualizacion;

  NMateria({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.grupo,
    this.fechaActualizacion,
  });

  factory NMateria.fromMap(Map<String, dynamic> map) => NMateria(
    id: map['id'],
    codigo: map['codigo'],
    nombre: map['nombre'],
    grupo: map['grupo'],
    fechaActualizacion: map['fecha_actualizacion'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'codigo': codigo,
    'nombre': nombre,
    'grupo': grupo,
    'fecha_actualizacion': fechaActualizacion,
  };

  NMateria copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? grupo,
    String? fechaActualizacion,
  }) {
    return NMateria(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      grupo: grupo ?? this.grupo,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
