import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:control_asistencia/controlador/c_excel.dart';
import 'package:control_asistencia/modelo/negocio/n_materia.dart';
import 'package:control_asistencia/modelo/negocio/n_examen.dart';
import 'package:control_asistencia/controlador/c_examen.dart';
import 'package:control_asistencia/controlador/c_materia.dart';
import 'package:control_asistencia/controlador/c_estudiante.dart';
import 'package:control_asistencia/controlador/strategy/orden_strategy.dart';
import 'package:control_asistencia/modelo/dato/d_asistencia.dart';
import 'package:control_asistencia/vista/docente/v_examen_asistencia.dart';
import 'package:control_asistencia/modelo/negocio/n_asistencia.dart';
import 'package:control_asistencia/modelo/dato/d_asistencia.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class VMateriaDetalle extends StatefulWidget {
  final NMateria materia;

  const VMateriaDetalle({super.key, required this.materia});

  @override
  State<VMateriaDetalle> createState() => _MateriaDetalleScreenState();
}

class _MateriaDetalleScreenState extends State<VMateriaDetalle> {
  final CExamen _cExamen = CExamen();
  final CMateria _cMateria = CMateria();
  final CEstudiante _cEstudiante = CEstudiante();
  final DAsistencia _dAsistencia = DAsistencia();
  final CExcel _excelController = CExcel();

  List<NExamen> _examenes = [];
  bool _cargando = true;
  bool _importando = false;
  bool _modoSeleccion = false;
  final Set<int> _examenesSeleccionados = {};

  int _activos = 0;
  int _retirados = 0;
  String? _fechaActualizacion;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    final materiaActual = await _cMateria.obtenerMateria(widget.materia.id!);
    final counts = await _cEstudiante.contarPorMateria(widget.materia.id!);
    final examenes = await _cExamen.listarExamenesPorMateria(widget.materia.id!);

    if (mounted) {
      setState(() {
        _fechaActualizacion =
            materiaActual?.fechaActualizacion ??
            widget.materia.fechaActualizacion;
        _activos = counts['activos'] ?? 0;
        _retirados = counts['retirados'] ?? 0;
        _examenes = examenes;
        _cargando = false;
      });
    }
  }

  Future<void> _importarExcel() async {
    setState(() => _importando = true);
    final msj = await _excelController.importarListaExcel(widget.materia.id!);
    await _cargarDatos();
    setState(() => _importando = false);

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

  String _formatearFechaActualizacion(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return 'Sin importación previa';
    }
    try {
      final fecha = DateTime.parse(isoString);
      return 'Ãšltima act.: ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}';
    } catch (_) {
      return 'Ãšltima act.: $isoString';
    }
  }

  ImageProvider? _obtenerImageProvider(String? foto) {
    if (foto == null || foto.trim().isEmpty) return null;
    try {
      String cleanBase64 = foto.trim();
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      return MemoryImage(base64Decode(cleanBase64));
    } catch (_) {
      return null;
    }
  }

  void _mostrarModalListaEstudiantes() async {
    final estudiantes = await _cEstudiante.listarEstudiantesPorMateria(widget.materia.id!);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String filtro = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtrados = estudiantes.where((e) {
              final matchText =
                  e.nombreCompleto.toLowerCase().contains(
                    filtro.toLowerCase(),
                  ) ||
                  e.registro.contains(filtro);
              return matchText;
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estudiantes Inscritos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_activos activos â€¢ $_retirados retirados',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: TextField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        onChanged: (val) =>
                            setModalState(() => filtro = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Buscar por registro o nombre...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1A1A2E),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Expanded(
                      child: filtrados.isEmpty
                          ? Center(
                              child: Text(
                                'No se encontraron estudiantes',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(120),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filtrados.length,
                              itemBuilder: (context, index) {
                                final est = filtrados[index];
                                final imgProvider = _obtenerImageProvider(
                                  est.foto,
                                );

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(
                                      0xFF7C3AED,
                                    ).withAlpha(40),
                                    backgroundImage: imgProvider,
                                    child: imgProvider == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Color(0xFFD8B4FE),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    est.nombreCompleto,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'REG: ${est.registro}${est.carrera.isNotEmpty ? ' â€¢ ${est.carrera}' : ''}',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(140),
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoNuevoExamen({NExamen? examenExistente}) async {
    final formKey = GlobalKey<FormState>();
    String titulo = examenExistente?.titulo ?? '';
    String aula = examenExistente?.aula ?? '';
    DateTime fechaSeleccionada = examenExistente != null 
        ? DateTime.parse(examenExistente.fecha) 
        : DateTime.now();
    TimeOfDay horaSeleccionada = examenExistente != null
        ? TimeOfDay(
            hour: int.parse(examenExistente.hora.split(':')[0]), 
            minute: int.parse(examenExistente.hora.split(':')[1])
          )
        : TimeOfDay.now();
    final bool esEdicion = examenExistente != null;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              title: Text(
                esEdicion ? 'Editar Examen' : 'Programar Examen',
                style: const TextStyle(color: Colors.white),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: titulo,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Título del Examen',
                          labelStyle: TextStyle(
                            color: Colors.white.withAlpha(150),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        onSaved: (v) => titulo = v!,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: aula,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Aula',
                          labelStyle: TextStyle(
                            color: Colors.white.withAlpha(150),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white38),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        onSaved: (v) => aula = v!,
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(fechaSeleccionada)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null)
                            setStateDialog(() => fechaSeleccionada = date);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Hora: ${horaSeleccionada.format(context)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                        ),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: horaSeleccionada,
                          );
                          if (time != null)
                            setStateDialog(() => horaSeleccionada = time);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      if (esEdicion) {
                        final examen = NExamen(
                          id: examenExistente.id,
                          idMateria: widget.materia.id!,
                          titulo: titulo,
                          fecha: DateFormat('yyyy-MM-dd').format(fechaSeleccionada),
                          hora: '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}:00',
                          aula: aula,
                          activo: examenExistente.activo,
                        );
                        await _cExamen.actualizarExamen(examen);
                      } else {
                        final examen = NExamen(
                          idMateria: widget.materia.id!,
                          titulo: titulo,
                          fecha: DateFormat('yyyy-MM-dd').format(fechaSeleccionada),
                          hora: '${horaSeleccionada.hour.toString().padLeft(2, '0')}:${horaSeleccionada.minute.toString().padLeft(2, '0')}:00',
                          aula: aula,
                          activo: true,
                        );
                        await _cExamen.crearExamen(examen);
                      }
                      if (mounted) Navigator.pop(ctx);
                      _cargarDatos();
                    }
                  },
                  child: const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarDialogoEliminarExamen(NExamen examen) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Eliminar Examen', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro que deseas eliminar el examen "${examen.titulo}"?\n\n'
          'Esta acción es irreversible y eliminará todos los registros de asistencia '
          'tomados durante este examen.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _cargando = true);
      await _cExamen.eliminarExamen(examen.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Examen eliminado exitosamente')),
        );
      }
      _cargarDatos();
    }
  }

  Future<void> _mostrarDialogoGenerarGrupos() async {
    final formKey = GlobalKey<FormState>();
    String tituloBase = '1er Parcial';
    String aulaBase = '';
    int cantidadPorGrupo = 40;
    String orden = 'Alfabético';
    DateTime fechaInicio = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              title: const Text('Generar Grupos Automáticos', style: TextStyle(color: Colors.white)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: tituloBase,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Título Base (Ej. "1er Parcial")',
                          labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        onSaved: (v) => tituloBase = v!,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: aulaBase,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Aula',
                          labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        onSaved: (v) => aulaBase = v!,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: cantidadPorGrupo.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Estudiantes por día/grupo',
                          labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Requerido';
                          if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Inválido';
                          return null;
                        },
                        onSaved: (v) => cantidadPorGrupo = int.parse(v!),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: orden,
                        dropdownColor: const Color(0xFF1A1A2E),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Criterio de asignación',
                          labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Alfabético', child: Text('Orden Alfabético')),
                          DropdownMenuItem(value: 'Aleatorio', child: Text('Orden Aleatorio')),
                        ],
                        onChanged: (v) => setStateDialog(() => orden = v!),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Fecha Inicio: ${DateFormat('dd/MM/yyyy').format(fechaInicio)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: fechaInicio,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) setStateDialog(() => fechaInicio = date);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(ctx);
                      await _generarYGuardarGrupos(tituloBase, aulaBase, cantidadPorGrupo, orden, fechaInicio);
                    }
                  },
                  child: const Text('Generar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generarYGuardarGrupos(String tituloBase, String aulaBase, int cantidadPorGrupo, String orden, DateTime fechaInicio) async {
    setState(() => _cargando = true);
    try {
      final estudiantesActivos = await _cEstudiante.listarEstudiantesPorMateria(widget.materia.id!, estado: 'ACTIVO');
      if (estudiantesActivos.isEmpty) throw Exception('No hay estudiantes activos para asignar.');

      // PATRÓN STRATEGY: el cliente elige la estrategia concreta y el contexto la ejecuta.
      // (se llama gruposContext para no tapar el "context" de Flutter)
      final gruposContext = AsignacionGruposContext();
      if (orden == 'Aleatorio') {
        gruposContext.setStrategy(OrdenAleatorioStrategy());
      } else {
        gruposContext.setStrategy(OrdenAlfabeticoStrategy());
      }
      // El Context delega el orden en la Strategy elegida arriba.
      final estudiantes = gruposContext.ordenar(estudiantesActivos);

      final int total = estudiantes.length;
      final int grupos = (total / cantidadPorGrupo).ceil();
      final List<int> examenesGeneradosIds = [];

      for (int i = 0; i < grupos; i++) {
        final start = i * cantidadPorGrupo;
        final end = min(start + cantidadPorGrupo, total);
        final asignados = estudiantes.sublist(start, end).map((e) => e.id).toSet();
        
        final date = fechaInicio.add(Duration(days: i));
        final examen = NExamen(
          idMateria: widget.materia.id!,
          titulo: '$tituloBase - Grupo ${i + 1}',
          fecha: DateFormat('yyyy-MM-dd').format(date),
          hora: '10:00:00', // Default hour
          aula: aulaBase,
          activo: true,
        );
        final examenId = await _cExamen.crearExamen(examen);
        examenesGeneradosIds.add(examenId);

        // Insert NO_ASIGNADO for students not in this group
        for (final est in estudiantes) {
          if (!asignados.contains(est.id)) {
            final asistencia = NAsistencia(
              idExamen: examenId,
              idEstudiante: est.id!,
              estado: 'NO_ASIGNADO',
              fechaHora: '',
              sincronizado: false,
            );
            await _dAsistencia.registrarAsistencia(asistencia);
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$grupos grupos generados correctamente')),
        );
      }

      if (mounted && examenesGeneradosIds.isNotEmpty) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: const Text('Exportar Cronograma', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Los grupos se han generado. ¿Deseas exportar y compartir ahora un Excel con el cronograma para enviarlo a los estudiantes?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No, gracias', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Exportar Cronograma', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          setState(() => _cargando = true);
          final msj = await _excelController.exportarCronogramaGrupos(
            materiaId: widget.materia.id!,
            materiaNombre: widget.materia.nombre,
            examenIds: examenesGeneradosIds,
          );
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _cargarDatos();
    }
  }

  Future<void> _exportarMultiplesExamenes() async {
    if (_examenesSeleccionados.isEmpty) return;
    
    setState(() => _cargando = true);
    final msj = await _excelController.exportarAsistenciaMultiple(
      materiaId: widget.materia.id!,
      materiaNombre: widget.materia.nombre,
      examenIds: _examenesSeleccionados.toList(),
    );
    setState(() {
      _cargando = false;
      _modoSeleccion = false;
      _examenesSeleccionados.clear();
    });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: Text(
          _modoSeleccion 
              ? '${_examenesSeleccionados.length} seleccionados' 
              : widget.materia.nombre,
          style: const TextStyle(fontSize: 18),
        ),
        elevation: 0,
        leading: _modoSeleccion 
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _modoSeleccion = false;
                  _examenesSeleccionados.clear();
                }),
              )
            : null,
        actions: [
          if (_modoSeleccion && _examenesSeleccionados.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar Seleccionados',
              onPressed: _exportarMultiplesExamenes,
            )
          else if (!_modoSeleccion)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Exportar Multiples Exámenes',
              onPressed: () => setState(() => _modoSeleccion = true),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.table_chart,
                        color: Colors.greenAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$_activos Estudiantes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_retirados > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.redAccent.withAlpha(80),
                                    ),
                                  ),
                                  child: Text(
                                    '$_retirados retirados',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatearFechaActualizacion(_fechaActualizacion),
                            style: TextStyle(
                              color: Colors.white.withAlpha(150),
                              fontSize: 12,
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: _importando ? null : _importarExcel,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: _importando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file, size: 16),
                            label: Text(
                              _activos > 0 ? 'ACTUALIZAR' : 'IMPORTAR',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (_activos > 0 || _retirados > 0) ...[
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _mostrarModalListaEstudiantes,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 16,
                                color: Colors.white.withAlpha(180),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ver lista de inscritos',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exámenes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _mostrarDialogoGenerarGrupos,
                      icon: const Icon(Icons.group_add, color: Colors.amberAccent, size: 18),
                      label: const Text('Grupos', style: TextStyle(color: Colors.amberAccent)),
                    ),
                    TextButton.icon(
                      onPressed: _mostrarDialogoNuevoExamen,
                      icon: const Icon(Icons.add, color: Color(0xFFD8B4FE), size: 18),
                      label: const Text('Nuevo', style: TextStyle(color: Color(0xFFD8B4FE))),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  )
                : _examenes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.white.withAlpha(80),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay exámenes programados',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _examenes.length,
                    itemBuilder: (context, index) {
                      final ex = _examenes[index];
                      final examenData = {
                        'id': ex.id,
                        'id_materia': ex.idMateria,
                        'titulo': ex.titulo,
                        'fecha': ex.fecha,
                        'hora': ex.hora,
                        'aula': ex.aula,
                        'activo': ex.activo,
                        'materia_codigo': widget.materia.codigo,
                        'materia_nombre': widget.materia.nombre,
                        'materia_grupo': widget.materia.grupo,
                      };

                      return Card(
                        color: const Color(0xFF16213E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: ex.activo
                                ? const Color(0xFF7C3AED).withAlpha(80)
                                : Colors.white.withAlpha(20),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onLongPress: () {
                            setState(() {
                              _modoSeleccion = true;
                              _examenesSeleccionados.add(ex.id!);
                            });
                          },
                          onTap: () {
                            if (_modoSeleccion) {
                              setState(() {
                                if (_examenesSeleccionados.contains(ex.id!)) {
                                  _examenesSeleccionados.remove(ex.id!);
                                  if (_examenesSeleccionados.isEmpty) _modoSeleccion = false;
                                } else {
                                  _examenesSeleccionados.add(ex.id!);
                                }
                              });
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VExamenAsistencia(examenData: examenData),
                                ),
                              ).then((_) => _cargarDatos());
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                if (_modoSeleccion)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      _examenesSeleccionados.contains(ex.id) 
                                          ? Icons.check_circle 
                                          : Icons.radio_button_unchecked,
                                      color: _examenesSeleccionados.contains(ex.id) 
                                          ? Colors.greenAccent 
                                          : Colors.white54,
                                    ),
                                  ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: ex.activo
                                        ? const Color(0xFF7C3AED).withAlpha(40)
                                        : Colors.grey.withAlpha(40),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    ex.activo
                                        ? Icons.event_available
                                        : Icons.event_busy,
                                    color: ex.activo
                                        ? const Color(0xFFD8B4FE)
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ex.titulo,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${ex.fecha} - ${ex.hora} | Aula: ${ex.aula}',
                                        style: TextStyle(
                                          color: Colors.white.withAlpha(150),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_modoSeleccion)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                                    color: const Color(0xFF1A1A2E),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'editar',
                                        child: Text('Editar', style: TextStyle(color: Colors.white)),
                                      ),
                                      const PopupMenuItem(
                                        value: 'eliminar',
                                        child: Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'editar') {
                                        _mostrarDialogoNuevoExamen(examenExistente: ex);
                                      } else if (value == 'eliminar') {
                                        _mostrarDialogoEliminarExamen(ex);
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
