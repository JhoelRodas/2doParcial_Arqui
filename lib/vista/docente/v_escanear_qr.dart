import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:control_asistencia/controlador/c_asistencia.dart';
import 'package:control_asistencia/modelo/negocio/n_estudiante.dart';
import 'package:control_asistencia/modelo/negocio/n_asistencia.dart';
import 'package:control_asistencia/vista/docente/v_modal_asistencia.dart';

class VEscanearQr extends StatefulWidget {
  final Map<String, dynamic> examenData;
  final CAsistencia cAsistencia;

  const VEscanearQr({
    super.key,
    required this.examenData,
    required this.cAsistencia,
  });

  @override
  State<VEscanearQr> createState() => _EscanearQrScreenState();
}

class _EscanearQrScreenState extends State<VEscanearQr> {
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isProcessing = false;

  int get examenId => widget.examenData['id'];
  int get materiaId => widget.examenData['id_materia'];

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _procesarCodigo(raw);
        break;
      }
    }
  }

  Future<void> _procesarCodigo(String rawPayload) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final result = await widget.cAsistencia.validarEstudianteQR(
        qrPayload: rawPayload,
        examenId: examenId,
        materiaId: materiaId,
      );

      if (!mounted) return;

      if (!result['valido'] || result['estudiante'] == null) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            icon: const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            title: const Text('Validación Fallida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(result['error'] ?? 'Error de validación', style: const TextStyle(color: Colors.white70)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return;
      }

      final NEstudiante estudiante = result['estudiante']!;
      final NAsistencia? previa = result['asistenciaPrevia'] as NAsistencia?;

      // 2. Mostrar directamente el modal de verificación visual reutilizable
      await mostrarModalAsistencia(
        context: context,
        estudiante: estudiante,
        examenId: examenId,
        materiaId: materiaId,
        cAsistencia: widget.cAsistencia,
        asistenciaPrevia: previa,
      );
    } catch (e) {
      debugPrint('Error procesando escaneo: $e');
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR de Examen'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Linterna',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            tooltip: 'Cambiar Cámara',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Visor de Cámara con MobileScanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Marco guía de escaneo
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2000,
                  ),
                ],
              ),
            ),
          ),

          // Instrucciones inferiores
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Apunta al código QR del estudiante para verificar su fotografía y registrar la asistencia.',
                style: TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
