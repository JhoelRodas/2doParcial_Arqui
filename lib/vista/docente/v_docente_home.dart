import 'package:flutter/material.dart';
import 'package:control_asistencia/modelo/negocio/n_materia.dart';
import 'package:control_asistencia/controlador/c_materia.dart';
import 'package:control_asistencia/vista/docente/v_materia_detalle.dart';
import 'dart:async';
import 'package:control_asistencia/vista/v_selector_rol.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:control_asistencia/controlador/c_excel.dart';

class VDocenteHome extends StatefulWidget {
  const VDocenteHome({super.key});

  @override
  State<VDocenteHome> createState() => _DocenteHomeScreenState();
}

class _DocenteHomeScreenState extends State<VDocenteHome> {
  final CMateria _cMateria = CMateria();
  List<NMateria> _materias = [];
  bool _cargando = true;
  StreamSubscription? _intentDataStreamSubscription;
  final CExcel _cExcel = CExcel();

  @override
  void initState() {
    super.initState();
    _cargarMaterias();
    _initIntentListener();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  void _initIntentListener() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            if (value.isNotEmpty) {
              _handleSharedFile(value.first.path);
            }
          },
          onError: (err) {
            debugPrint("getIntentDataStream error: $err");
          },
        );

    // Escuchar cuando la app estaba cerrada y se abre por el Intent
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        _handleSharedFile(value.first.path);
      }
    });
  }

  Future<void> _handleSharedFile(String filePath) async {
    // Si no es un excel, ignoramos
    if (!filePath.toLowerCase().endsWith('.xlsx') &&
        !filePath.toLowerCase().endsWith('.xls'))
      return;

    List<NMateria> materiasDisponibles = _materias;
    if (materiasDisponibles.isEmpty) {
      materiasDisponibles = await _cMateria.listarMaterias();
      if (mounted) {
        setState(() {
          _materias = materiasDisponibles;
        });
      }
    }

    if (materiasDisponibles.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No tienes materias creadas. Crea una materia primero para importar la lista.',
          ),
        ),
      );
      ReceiveSharingIntent.instance.reset();
      return;
    }

    NMateria? materiaSeleccionada;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text(
            'Importar Excel Compartido',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona la materia para importar esta lista de estudiantes:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ...materiasDisponibles.map(
                (m) => ListTile(
                  title: Text(
                    m.nombre,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    m.codigo,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  onTap: () {
                    materiaSeleccionada = m;
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );

    if (materiaSeleccionada != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Procesando archivo...')));

      final resultado = await _cExcel.importarListaExcelDesdeRuta(
        materiaSeleccionada!.id!,
        filePath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resultado)));
    }

    ReceiveSharingIntent.instance.reset();
  }

  Future<void> _cargarMaterias() async {
    setState(() => _cargando = true);
    final materias = await _cMateria.listarMaterias();
    if (mounted) {
      setState(() {
        _materias = materias;
        _cargando = false;
      });
    }
  }

  void _cerrarModoDocente() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const VSelectorRol()),
      (route) => false,
    );
  }

  Future<void> _mostrarDialogoNuevaMateria({NMateria? materiaExistente}) async {
    final formKey = GlobalKey<FormState>();
    String codigo = materiaExistente?.codigo ?? '';
    String nombre = materiaExistente?.nombre ?? '';
    String grupo = materiaExistente?.grupo ?? '';
    final bool esEdicion = materiaExistente != null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          esEdicion ? 'Editar Materia' : 'Nueva Materia',
          style: const TextStyle(color: Colors.white),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: codigo,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Sigla / Codigo',
                  labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
                  hintText: 'Ej: INF412',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onSaved: (v) => codigo = v!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: nombre,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre de la Materia',
                  labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
                  hintText: 'Ej: Arquitectura de Software',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onSaved: (v) => nombre = v!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: grupo,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Grupo',
                  labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
                  hintText: 'Ej: SC',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                onSaved: (v) => grupo = v!,
              ),
            ],
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
                  final materia = materiaExistente.copyWith(
                    codigo: codigo,
                    nombre: nombre,
                    grupo: grupo,
                  );
                  await _cMateria.actualizarMateria(materia);
                } else {
                  final materia = NMateria(
                    codigo: codigo,
                    nombre: nombre,
                    grupo: grupo,
                  );
                  await _cMateria.crearMateria(materia);
                }
                if (mounted) Navigator.pop(ctx);
                _cargarMaterias();
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoEliminarMateria(NMateria materia) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Eliminar Materia',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro que deseas eliminar la materia "${materia.nombre}"?\n\n'
          'Esta acción es irreversible y eliminará en cascada todas las inscripciones, '
          'exámenes y registros de asistencia asociados a esta materia.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _cargando = true);
      await _cMateria.eliminarMateria(materia.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materia eliminada exitosamente')),
        );
      }
      _cargarMaterias();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: const Text(
          'Mis Materias',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Salir',
            onPressed: _cerrarModoDocente,
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : _materias.isEmpty
          ? _buildEmptyState()
          : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevaMateria,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Crear Materia',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Colors.white.withAlpha(60),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes materias creadas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea una materia para luego importar\ntu lista de estudiantes de Excel.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(160)),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
      itemCount: _materias.length,
      itemBuilder: (context, index) {
        final m = _materias[index];
        return Card(
          color: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => VMateriaDetalle(materia: m)),
              ).then((_) => _cargarMaterias());
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.class_,
                      color: Color(0xFFD8B4FE),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${m.codigo} â€” Grupo ${m.grupo}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    color: const Color(0xFF1A1A2E),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Text(
                          'Editar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'editar') {
                        _mostrarDialogoNuevaMateria(materiaExistente: m);
                      } else if (value == 'eliminar') {
                        _mostrarDialogoEliminarMateria(m);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
