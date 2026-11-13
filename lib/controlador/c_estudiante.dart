import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:control_asistencia/modelo/dato/d_estudiante.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';

class CEstudiante {
  static const String _keyRegistro = 'est_registro';
  static const String _keyNombre = 'est_apellidos_nombres';

  final DEstudiante _dEstudiante = DEstudiante();

  Future<List<NEstudiante>> listarEstudiantesPorMateria(
    int idMateria, {
    String? estado,
  }) async {
    return await _dEstudiante.listarPorMateria(idMateria, estado: estado);
  }

  Future<Map<String, int>> contarPorMateria(int idMateria) async {
    return await _dEstudiante.contarPorMateria(idMateria);
  }

  /// Solo se llama una vez en el formulario de primer ingreso.
  Future<void> guardarDatos({
    required String registro,
    required String apellidosNombres,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRegistro, registro.trim());
    await prefs.setString(_keyNombre, apellidosNombres.trim());
  }

  Future<Map<String, String>?> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final registro = prefs.getString(_keyRegistro);
    final nombre = prefs.getString(_keyNombre);
    if (registro != null && registro.isNotEmpty) {
      return {'registro': registro, 'apellidos_nombres': nombre ?? ''};
    }
    return null;
  }

  Future<void> limpiarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRegistro);
    await prefs.remove(_keyNombre);
  }

  String generarQrPayload({
    required String registro,
    required String apellidosNombres,
  }) {
    final payload = {
      'registro': registro,
      'nombre': apellidosNombres,
      'tipo': 'ASISTENCIA_EXAMEN',
    };
    return jsonEncode(payload);
  }
}
