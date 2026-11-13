import 'package:control_asistencia/modelo/dato/d_materia.dart';
import 'package:control_asistencia/modelo/negocio/n_materia.dart';

class CMateria {
  final DMateria _dMateria = DMateria();

  Future<List<NMateria>> listarMaterias() async {
    return await _dMateria.listarTodas();
  }

  Future<NMateria?> obtenerMateria(int id) async {
    return await _dMateria.obtenerPorId(id);
  }

  Future<int> crearMateria(NMateria materia) async {
    return await _dMateria.insertar(materia);
  }

  Future<int> actualizarMateria(NMateria materia) async {
    return await _dMateria.actualizar(materia);
  }

  Future<int> eliminarMateria(int idMateria) async {
    return await _dMateria.eliminar(idMateria);
  }

  Future<int> actualizarFechaImportacion(int idMateria, String fechaIso) async {
    return await _dMateria.actualizarFechaImportacion(idMateria, fechaIso);
  }
}
