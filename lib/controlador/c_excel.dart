import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';
import 'package:control_asistencia/modelo/dato/d_estudiante.dart';
import 'package:control_asistencia/modelo/dato/d_materia.dart';
import 'package:control_asistencia/controlador/template/exportadores_concretos.dart';

/// Controlador encargado de procesar la importación de listas desde Excel.
class CExcel {
  final DEstudiante _dEstudiante = DEstudiante();
  final DMateria _dMateria = DMateria();

  /// Extrae el texto limpio de un CellValue de Excel, resolviendo tipos numéricos
  /// como DoubleCellValue (evita .0 al final) o IntCellValue.
  String _extraerTextoCelda(CellValue? cellValue) {
    if (cellValue == null) return '';
    if (cellValue is TextCellValue) {
      String s = (cellValue.value.text ?? cellValue.value.toString()).trim();
      final match = RegExp(r'^(-?\d+)\.0+$').firstMatch(s);
      if (match != null) s = match.group(1)!;
      return s;
    }
    if (cellValue is IntCellValue) {
      return cellValue.value.toString().trim();
    }
    if (cellValue is DoubleCellValue) {
      final d = cellValue.value;
      if (d == d.roundToDouble()) {
        return d.toInt().toString();
      }
      return d.toString().trim();
    }
    if (cellValue is DateCellValue) {
      return '${cellValue.year}-${cellValue.month.toString().padLeft(2, '0')}-${cellValue.day.toString().padLeft(2, '0')}';
    }
    if (cellValue is BoolCellValue) {
      return cellValue.value ? 'true' : 'false';
    }
    if (cellValue is FormulaCellValue) {
      return cellValue.formula.trim();
    }

    String s = cellValue.toString().trim();
    final match = RegExp(r'^(-?\d+)\.0+$').firstMatch(s);
    if (match != null) {
      s = match.group(1)!;
    }
    return s;
  }

  String _getColText(List<Data?> row, int colIndex) {
    if (colIndex < 0 || colIndex >= row.length) return '';
    return _extraerTextoCelda(row[colIndex]?.value);
  }

  /// Procesa los bytes de un archivo Excel, detectando dinámicamente columnas
  Future<String> _procesarExcelBytes(
    List<int> bytes,
    int idMateria, {
    bool esCompartido = false,
  }) async {
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.keys.isEmpty) {
      return 'El archivo Excel está vacío.';
    }

    // Tomar la primera hoja con datos
    Sheet? table;
    for (final name in excel.tables.keys) {
      final s = excel.tables[name];
      if (s != null && s.rows.isNotEmpty) {
        table = s;
        break;
      }
    }

    if (table == null || table.rows.isEmpty) {
      return 'La hoja de cálculo está vacía.';
    }

    // 1. Detección Inteligente de Cabeceras y Mapeo de Columnas
    int headerRowIdx = -1;
    int colRegistro = 1; // Por defecto columna B (Registro) si existe Nro en A
    int colNombres = 2;
    int colCarrera = 3;
    int colPlan = 4;
    int colTelefono = 5;
    int colEmail = 6;
    int colFoto = -1;

    for (int r = 0; r < table.rows.length && r < 10; r++) {
      final row = table.rows[r];
      if (row.isEmpty) continue;

      int? foundReg;
      int? foundNom;

      for (int c = 0; c < row.length; c++) {
        final rawText = _extraerTextoCelda(row[c]?.value);
        final cellText = rawText.toLowerCase().trim();

        if (cellText.isEmpty || cellText.length > 35) continue;

        if (cellText == 'registro' ||
            cellText.startsWith('reg') ||
            cellText.contains('código') ||
            cellText.contains('codigo') ||
            cellText.contains('carnet') ||
            cellText.contains('matricula')) {
          foundReg = c;
        } else if (cellText.contains('nombre') ||
            cellText.contains('apellido') ||
            cellText.contains('alumno')) {
          foundNom = c;
        }
      }

      if (foundReg != null) {
        headerRowIdx = r;
        colRegistro = foundReg;
        if (foundNom != null) colNombres = foundNom;

        for (int c = 0; c < row.length; c++) {
          if (c == colRegistro || c == colNombres) continue;
          final cellText = _extraerTextoCelda(
            row[c]?.value,
          ).toLowerCase().trim();
          if (cellText.contains('carrera') || cellText.contains('programa')) {
            colCarrera = c;
          } else if (cellText.contains('plan')) {
            colPlan = c;
          } else if (cellText.contains('tel') ||
              cellText.contains('cel') ||
              cellText.contains('movil') ||
              cellText.contains('fono')) {
            colTelefono = c;
          } else if (cellText.contains('email') ||
              cellText.contains('correo') ||
              cellText.contains('mail')) {
            colEmail = c;
          } else if (cellText.contains('foto') ||
              cellText.contains('imagen') ||
              cellText.contains('base64')) {
            colFoto = c;
          }
        }
        break;
      }
    }

    final startRow = (headerRowIdx >= 0) ? headerRowIdx + 1 : 1;
    int countNuevos = 0;
    int countActualizados = 0;
    final Set<int> idsEnExcel = {};

    for (int i = startRow; i < table.rows.length; i++) {
      final row = table.rows[i];
      if (row.isEmpty) continue;

      final registroStr = _getColText(row, colRegistro);
      if (registroStr.isEmpty) continue;

      // Descartar si coincide con encabezados repetidos
      final regLower = registroStr.toLowerCase();
      if (regLower == 'registro' ||
          regLower == 'nro' ||
          regLower == 'no.' ||
          regLower == '#' ||
          regLower == 'carnet') {
        continue;
      }

      final nombres = _getColText(row, colNombres);
      final nombresFinal = nombres.isNotEmpty ? nombres : 'Sin Nombre';
      final carrera = _getColText(row, colCarrera);
      final plan = _getColText(row, colPlan);
      final telefono = _getColText(row, colTelefono);
      final email = _getColText(row, colEmail);
      final fotoBase64 = _getColText(row, colFoto);

      final estudiante = NEstudiante(
        registro: registroStr,
        apellidosNombres: nombresFinal,
        carrera: carrera,
        plan: plan,
        telefono: telefono,
        email: email,
        foto: fotoBase64,
      );

      final existing = await _dEstudiante.obtenerPorRegistro(registroStr);
      final estudianteId = await _dEstudiante.upsert(
        existing != null ? estudiante.copyWith(id: existing.id) : estudiante,
      );

      await _dEstudiante.inscribir(estudianteId, idMateria, estado: 'ACTIVO');
      idsEnExcel.add(estudianteId);

      if (existing == null) {
        countNuevos++;
      } else {
        countActualizados++;
      }
    }

    // Gestionar retiros: marcar como RETIRADO a quienes ya no están en este Excel
    int countRetirados = 0;
    if (idsEnExcel.isNotEmpty) {
      countRetirados = await _dEstudiante.desinscribirNoPresentes(
        idMateria,
        idsEnExcel,
      );
    }

    final nowIso = DateTime.now().toIso8601String();
    await _dMateria.actualizarFechaImportacion(idMateria, nowIso);

    final origen = esCompartido ? ' desde archivo externo' : '';
    String resumen =
        'Importación exitosa$origen: $countNuevos nuevos, $countActualizados actualizados';
    if (countRetirados > 0) {
      resumen += ' ($countRetirados marcados como retirados)';
    }
    return '$resumen.';
  }

  /// Permite al docente elegir un archivo .xlsx y lo procesa.
  /// Retorna un mensaje indicando el resultado.
  Future<String> importarListaExcel(int idMateria) async {
    try {
      // 1. Seleccionar archivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.single.path == null) {
        return 'Importación cancelada.';
      }

      final file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      return await _procesarExcelBytes(bytes, idMateria);
    } catch (e) {
      return 'Error al importar: ${e.toString()}';
    }
  }

  /// Importa una lista desde una ruta local específica (Deep Link / Compartir)
  Future<String> importarListaExcelDesdeRuta(
    int idMateria,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return 'El archivo compartido no existe o no se puede leer.';
      }

      var bytes = file.readAsBytesSync();
      return await _procesarExcelBytes(bytes, idMateria, esCompartido: true);
    } catch (e) {
      return 'Error al procesar el archivo externo: ${e.toString()}';
    }
  }

  /// CU-05: exportaciones a Excel. Cada una es una subclase del patrón
  /// Template Method ([ExportadorExcel]); este controlador solo elige cuál usar.
  // TEMPLATE METHOD: el controlador (Client) crea la subclase y llama a exportar().
  Future<String> exportarAsistenciaExamen({
    required int examenId,
    required int materiaId,
    required String tituloExamen,
  }) {
    return ExportadorAsistenciaExamen(
      examenId: examenId,
      materiaId: materiaId,
      tituloExamen: tituloExamen,
    ).exportar();
  }

  Future<String> exportarAsistenciaMultiple({
    required int materiaId,
    required String materiaNombre,
    required List<int> examenIds,
  }) {
    return ExportadorConsolidado(
      materiaId: materiaId,
      materiaNombre: materiaNombre,
      examenIds: examenIds,
    ).exportar();
  }

  Future<String> exportarCronogramaGrupos({
    required int materiaId,
    required String materiaNombre,
    required List<int> examenIds,
  }) {
    return ExportadorCronograma(
      materiaId: materiaId,
      materiaNombre: materiaNombre,
      examenIds: examenIds,
    ).exportar();
  }
}
