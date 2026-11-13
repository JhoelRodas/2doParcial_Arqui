CREATE TABLE estudiantes (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    registro            TEXT NOT NULL UNIQUE,
    apellidos_nombres   TEXT NOT NULL,
    carrera             TEXT NOT NULL,
    plan                TEXT NOT NULL,
    telefono            TEXT,
    email               TEXT,
    foto                TEXT
);

CREATE TABLE materias (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo              TEXT NOT NULL,
    nombre              TEXT NOT NULL,
    grupo               TEXT NOT NULL,
    fecha_actualizacion TEXT
);

CREATE TABLE examenes (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    id_materia          INTEGER NOT NULL,
    titulo              TEXT NOT NULL,
    fecha               TEXT NOT NULL,
    hora                TEXT NOT NULL,
    aula                TEXT NOT NULL,
    activo              INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (id_materia) REFERENCES materias (id)
);

CREATE TABLE inscripciones (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    id_materia          INTEGER NOT NULL,
    id_estudiante       INTEGER NOT NULL,
    estado              TEXT NOT NULL DEFAULT 'ACTIVO',
    FOREIGN KEY (id_materia) REFERENCES materias (id),
    FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id)
);

CREATE TABLE asistencias (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    id_examen           INTEGER NOT NULL,
    id_estudiante       INTEGER NOT NULL,
    fecha_hora          TEXT NOT NULL,
    estado              TEXT NOT NULL,
    FOREIGN KEY (id_examen) REFERENCES examenes (id),
    FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id)
);
