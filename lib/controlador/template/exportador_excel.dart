import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// PATRÓN TEMPLATE METHOD (CU-05: Exportar Resultados)
///
/// Clase abstracta que define el ESQUELETO fijo de toda exportación a Excel
/// en [exportar] (el método plantilla):
///
///   1. cargarDatos()          -> paso variable (cada subclase)
///   2. crear libro y hoja     -> paso común
///   3. escribirEncabezado()   -> paso variable
///   4. escribirFilas()        -> paso variable
///   5. excel.save()           -> paso común
///   6. guardarArchivo()       -> paso común
///   7. compartirArchivo()     -> paso común
///
/// Las subclases solo implementan los pasos variables; el orden del
/// algoritmo no se puede alterar desde ellas.
abstract class ExportadorExcel {
  // ───────────────────────── MÉTODO PLANTILLA ─────────────────────────
  Future<String> exportar() async {
    try {
      // 1) PASO VARIABLE (lo implementa cada subclase)
      final errorPrevio = await cargarDatos();
      if (errorPrevio != null) return errorPrevio;

      // 2) PASO COMÚN
      final excel = Excel.createExcel();
      final Sheet hoja = excel[nombreHoja];
      excel.setDefaultSheet(nombreHoja);

      // 3) y 4) PASOS VARIABLES
      escribirEncabezado(hoja);
      escribirFilas(hoja);

      final fileBytes = excel.save();
      if (fileBytes == null) return 'Error al generar bytes del Excel.';

      // 5) y 6) PASOS COMUNES (iguales para todas las exportaciones)
      final ruta = await guardarArchivo(fileBytes);
      await compartirArchivo(ruta);

      return mensajeExito;
    } catch (e) {
      return '$prefijoError: $e';
    }
  }

  // ─────────────── Pasos variables (obligatorios en subclases) ──────────────

  /// Carga los datos necesarios. Devuelve un mensaje de error si no se puede
  /// exportar (p. ej. "No hay estudiantes"), o null si todo está bien.
  Future<String?> cargarDatos();

  void escribirEncabezado(Sheet hoja);

  void escribirFilas(Sheet hoja);

  // ─────────────── Datos que personalizan cada exportación ──────────────────
  String get nombreHoja;
  String get prefijoArchivo;
  String get nombreParaArchivo;
  String get textoCompartir;
  String get mensajeExito;
  String get prefijoError;

  // ───────────────────── Pasos comunes (ya implementados) ───────────────────

  Future<String> guardarArchivo(List<int> bytes) async {
    final directory = await getTemporaryDirectory();
    final sanitizedTitle = nombreParaArchivo.replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '_',
    );
    final filePath = '${directory.path}/${prefijoArchivo}_$sanitizedTitle.xlsx';
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  Future<void> compartirArchivo(String ruta) async {
    await Share.shareXFiles([XFile(ruta)], text: textoCompartir);
  }
}
