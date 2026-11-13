import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:control_asistencia/controlador/c_asistencia.dart';
import 'package:control_asistencia/modelo/negocio/n_asistencia.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';
import 'package:control_asistencia/controlador/c_excel.dart';
import 'package:control_asistencia/vista/docente/v_escanear_qr.dart';
import 'package:control_asistencia/vista/docente/v_modal_asistencia.dart';
import 'package:control_asistencia/controlador/c_examen.dart';
import 'package:control_asistencia/modelo/negocio/n_examen.dart';

class VExamenAsistencia extends StatefulWidget {
  final Map<String, dynamic> examenData;

  const VExamenAsistencia({super.key, required this.examenData});

  @override
  State<VExamenAsistencia> createState() => _ExamenAsistenciaScreenState();
}

class _ExamenAsistenciaScreenState extends State<VExamenAsistencia>
    {
  final CAsistencia _asistenciaController = CAsistencia();
  final CExcel _excelController = CExcel();

  List<Map<String, dynamic>> _estudiantes = [];
  Map<String, int> _estadisticas = {'total': 0, 'presentes': 0, 'atrasados': 0, 'ausentes': 0};
  bool _cargando = true;
  String _filtroEstado = 'TODOS';
  String _busqueda = '';
  late bool _activo;

  int get examenId => widget.examenData['id'];
  int get materiaId => widget.examenData['id_materia'];

  @override
  void initState() {
    super.initState();
    _activo = widget.examenData['activo'] ?? true;
    _cargarDatos();
  }

  @override
  void dispose() {
    // Desuscripción del Patrón Observer
    
    super.dispose();
  }

  // Métodos de notificación
  void onAsistenciaRegistrada(NAsistencia asistencia, NEstudiante estudiante) {
    if (mounted) {
      _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asistencia registrada: ${estudiante.nombreCompleto} (${asistencia.estado})'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void onAsistenciaRevertida(String descripcion) {
    if (mounted) {
      _cargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deshecho: $descripcion'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void onEstadisticasActualizadas(Map<String, int> estadisticas) {
    if (mounted) {
      setState(() {
        _estadisticas = estadisticas;
      });
    }
  }

  void onError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final lista = await _asistenciaController.listarEstudiantesConEstado(examenId, materiaId);
    final stats = await _asistenciaController.obtenerEstadisticas(examenId, materiaId);

    if (mounted) {
      setState(() {
        _estudiantes = lista;
        _estadisticas = stats;
        _cargando = false;
      });
    }
  }

  Future<void> _finalizarExamen() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Finalizar Examen', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de finalizar este examen? \n\n'
          'Una vez finalizado, no se podrán registrar nuevas asistencias ni modificar las existentes.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _cargando = true);
      final examen = NExamen(
        id: examenId,
        idMateria: materiaId,
        titulo: widget.examenData['titulo'] ?? '',
        fecha: widget.examenData['fecha'] ?? '',
        hora: widget.examenData['hora'] ?? '',
        aula: widget.examenData['aula'] ?? '',
        activo: false,
      );
      await CExamen().actualizarExamen(examen);
      
      setState(() {
        _activo = false;
        _cargando = false;
      });
    }
  }

  Future<void> _exportarAsistencia() async {
    setState(() => _cargando = true);
    final msj = await _excelController.exportarAsistenciaExamen(
      examenId: examenId,
      materiaId: materiaId,
      tituloExamen: widget.examenData['titulo'] ?? 'examen',
    );
    setState(() => _cargando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msj),
          backgroundColor: msj.contains('Error') ? Colors.red : Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// PATRÓN COMMAND: deshace el último comando de asistencia ejecutado.
  Future<void> _deshacerUltimo() async {
    final descripcion = await _asistenciaController.deshacerUltimaAsistencia();
    if (!mounted) return;

    if (descripcion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay acciones para deshacer')),
      );
      return;
    }
    onAsistenciaRevertida(descripcion);
  }

  List<Map<String, dynamic>> get _estudiantesFiltrados {
    return _estudiantes.where((item) {
      final estado = item['estado'] as String;
      if (estado == 'NO_ASIGNADO') return false; // Hide assigned to other groups

      final nombre = (item['apellidos_nombres'] ?? '').toString().toLowerCase();
      final registro = (item['registro'] ?? '').toString().toLowerCase();

      final coincideFiltro = _filtroEstado == 'TODOS' || estado == _filtroEstado;
      final coincideBusqueda = _busqueda.isEmpty ||
          nombre.contains(_busqueda.toLowerCase()) ||
          registro.contains(_busqueda.toLowerCase());

      return coincideFiltro && coincideBusqueda;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final examen = widget.examenData;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(
          examen['titulo'] ?? 'Control de asistencia',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // COMMAND: botón que invoca el undo del último comando.
          if (_activo)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Deshacer última asistencia',
              onPressed: _asistenciaController.puedeDeshacer ? _deshacerUltimo : null,
            ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Exportar a Excel y Compartir',
            onPressed: _exportarAsistencia,
          ),
          if (_activo)
            IconButton(
              icon: const Icon(Icons.lock),
              tooltip: 'Finalizar Examen',
              onPressed: _finalizarExamen,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : Column(
              children: [
                // Cabecera con datos del examen y estadísticas
                _buildHeaderExamen(),

                _buildFiltros(),

                Expanded(
                  child: _estudiantesFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined,
                                  size: 48, color: Colors.white24),
                              const SizedBox(height: 8),
                              Text(
                                'No se encontraron estudiantes',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF7C3AED),
                          backgroundColor: const Color(0xFF16213E),
                          onRefresh: _cargarDatos,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _estudiantesFiltrados.length,
                            itemBuilder: (context, index) {
                              final est = _estudiantesFiltrados[index];
                              return _buildStudentCard(est);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: _activo
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VEscanearQr(
                      examenData: widget.examenData,
                      cAsistencia: _asistenciaController,
                    ),
                  ),
                );
                _cargarDatos();
              },
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text(
                'ESCANEAR QR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderExamen() {
    final examen = widget.examenData;
    final total = _estadisticas['total'] ?? 0;
    final presentes = _estadisticas['presentes'] ?? 0;
    final atrasados = _estadisticas['atrasados'] ?? 0;
    final ausentes = _estadisticas['ausentes'] ?? 0;

    final porcentaje = total > 0 ? ((presentes + atrasados) / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${examen['materia_codigo']} - ${examen['materia_nombre']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  'Aula: ${examen['aula']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_activo)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.redAccent.withAlpha(80)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.redAccent),
                  SizedBox(width: 6),
                  Text(
                    'EXAMEN FINALIZADO',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Contadores rápidos
          Row(
            children: [
              Expanded(child: _buildStatChip('Total', '$total', const Color(0xFF38BDF8))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatChip('Presentes', '$presentes', const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatChip('Atrasados', '$atrasados', const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Expanded(child: _buildStatChip('Ausentes', '$ausentes', const Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso de asistencia',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                  ),
                  Text(
                    '${(porcentaje * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: porcentaje > 0.7 ? const Color(0xFF10B981) : const Color(0xFFA78BFA),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: porcentaje,
                  backgroundColor: const Color(0xFF1A1A2E),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    porcentaje > 0.7 ? const Color(0xFF10B981) : const Color(0xFF7C3AED),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (val) => setState(() => _busqueda = val),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o registro...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 20, color: Colors.white.withOpacity(0.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFF16213E),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterButton('TODOS'),
                const SizedBox(width: 8),
                _buildFilterButton('PRESENTE'),
                const SizedBox(width: 8),
                _buildFilterButton('ATRASADO'),
                const SizedBox(width: 8),
                _buildFilterButton('AUSENTE'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String estado) {
    final isSelected = _filtroEstado == estado;
    return ChoiceChip(
      label: Text(estado, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => setState(() => _filtroEstado = estado),
      selectedColor: const Color(0xFF7C3AED),
      backgroundColor: const Color(0xFF16213E),
      side: BorderSide(
        color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.12),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> est) {
    final estado = est['estado'] as String;
    final nombre = est['apellidos_nombres'] as String? ?? 'Sin Nombre';
    final fotoBase64 = est['foto'] as String? ?? '';

    Color badgeColor = const Color(0xFF94A3B8);
    IconData badgeIcon = Icons.cancel_outlined;

    if (estado == 'PRESENTE') {
      badgeColor = const Color(0xFF10B981);
      badgeIcon = Icons.check_circle;
    } else if (estado == 'ATRASADO') {
      badgeColor = const Color(0xFFF59E0B);
      badgeIcon = Icons.watch_later;
    } else if (estado == 'AUSENTE') {
      badgeColor = const Color(0xFFEF4444);
      badgeIcon = Icons.cancel_outlined;
    }

    ImageProvider? imageProvider;
    if (fotoBase64.isNotEmpty) {
      try {
        String b64 = fotoBase64;
        if (b64.contains(',')) b64 = b64.split(',')[1];
        imageProvider = MemoryImage(base64Decode(b64.replaceAll(RegExp(r'\s+'), '')));
      } catch (e) {
        // Ignorar error de decodificación
      }
    }

    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: badgeColor.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF1A1A2E),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, color: Colors.white60)
              : null,
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reg: ${est['registro']}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
            if (est['fecha_hora'] != null)
              Text(
                'Hora: ${est['fecha_hora']}',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45)),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: badgeColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, size: 14, color: badgeColor),
              const SizedBox(width: 4),
              Text(
                estado,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
        onTap: _activo ? () async {
          final rawId = est['estudiante_id'] ?? est['id'];
          final estId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

          final estudiante = NEstudiante(
            id: estId,
            registro: est['registro']?.toString() ?? '',
            apellidosNombres: est['apellidos_nombres']?.toString() ?? '',
            carrera: est['carrera']?.toString() ?? '',
            plan: est['plan']?.toString() ?? '',
            telefono: est['telefono']?.toString() ?? '',
            email: est['email']?.toString() ?? '',
            foto: est['foto']?.toString() ?? '',
          );

          NAsistencia? previa;
          if (est['asistencia_id'] != null) {
            final rawAId = est['asistencia_id'];
            final aId = rawAId is int ? rawAId : int.tryParse(rawAId.toString());
            previa = NAsistencia(
              id: aId,
              idExamen: examenId,
              idEstudiante: estId ?? 0,
              estado: est['estado']?.toString() ?? 'AUSENTE',
              fechaHora: est['fecha_hora']?.toString() ?? '',
              sincronizado: false,
            );
          }

          await mostrarModalAsistencia(
            context: context,
            estudiante: estudiante,
            examenId: examenId,
            materiaId: materiaId,
            cAsistencia: _asistenciaController,
            asistenciaPrevia: previa,
            onGuardado: (_) => _cargarDatos(),
          );

          if (mounted) {
            _cargarDatos();
          }
        } : null,
      ),
    );
  }
}
