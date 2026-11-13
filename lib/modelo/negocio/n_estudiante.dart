class NEstudiante {
  final int? id;
  final String registro;
  final String apellidosNombres;
  final String carrera;
  final String plan;
  final String telefono;
  final String email;
  final String foto; // Base64 o vacío

  NEstudiante({
    this.id,
    required this.registro,
    required this.apellidosNombres,
    required this.carrera,
    required this.plan,
    required this.telefono,
    required this.email,
    this.foto = '',
  });

  String get nombreCompleto => apellidosNombres;

  factory NEstudiante.fromMap(Map<String, dynamic> json) => NEstudiante(
    id: json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? ''),
    registro: json['registro']?.toString().trim() ?? '',
    apellidosNombres: json['apellidos_nombres']?.toString().trim() ?? '',
    carrera: json['carrera']?.toString().trim() ?? '',
    plan: json['plan']?.toString().trim() ?? '',
    telefono: json['telefono']?.toString().trim() ?? '',
    email: json['email']?.toString().trim() ?? '',
    foto: json['foto']?.toString().trim() ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'registro': registro,
    'apellidos_nombres': apellidosNombres,
    'carrera': carrera,
    'plan': plan,
    'telefono': telefono,
    'email': email,
    'foto': foto,
  };

  NEstudiante copyWith({
    int? id,
    String? registro,
    String? apellidosNombres,
    String? carrera,
    String? plan,
    String? telefono,
    String? email,
    String? foto,
  }) => NEstudiante(
    id: id ?? this.id,
    registro: registro ?? this.registro,
    apellidosNombres: apellidosNombres ?? this.apellidosNombres,
    carrera: carrera ?? this.carrera,
    plan: plan ?? this.plan,
    telefono: telefono ?? this.telefono,
    email: email ?? this.email,
    foto: foto ?? this.foto,
  );
}
