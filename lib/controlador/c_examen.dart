import 'package:control_asistencia/modelo/dato/d_examen.dart';
import 'package:control_asistencia/modelo/negocio/n_examen.dart';

class CExamen {
  final DExamen _dExamen = DExamen();

  Future<List<NExamen>> listarExamenesPorMateria(int idMateria) async {
    return await _dExamen.listarPorMateria(idMateria);
  }

  Future<NExamen?> obtenerExamen(int id) async {
    return await _dExamen.obtenerPorId(id);
  }

  Future<int> crearExamen(NExamen examen) async {
    return await _dExamen.insertar(examen);
  }

  Future<int> actualizarExamen(NExamen examen) async {
    return await _dExamen.actualizar(examen);
  }

  Future<int> eliminarExamen(int idExamen) async {
    return await _dExamen.eliminar(idExamen);
  }
}
