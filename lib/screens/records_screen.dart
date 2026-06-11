import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/records_service.dart';
import '../widgets/record_card.dart';

/// Pantalla que muestra los récords locales por dificultad.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final Map<int, Map<String, int?>> _records = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarRecords();
  }

  /// Carga los récords de las 3 dificultades al iniciar la pantalla
  Future<void> _cargarRecords() async {
    for (final size in [3, 4, 5]) {
      final tiempo = await RecordsService.obtenerMejorTiempo(size);
      final movimientos = await RecordsService.obtenerMejorMovimientos(size);
      _records[size] = {'tiempo': tiempo, 'movimientos': movimientos};
    }
    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Text(
          '🏆 Récords',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    RecordCard(
                      dificultad: '😊  Fácil',
                      descripcion: 'Tablero 3x3',
                      color: const Color(0xFF10B981),
                      tiempo: _records[3]?['tiempo'],
                      movimientos: _records[3]?['movimientos'],
                    ),
                    const SizedBox(height: 16),
                    RecordCard(
                      dificultad: '😤  Medio',
                      descripcion: 'Tablero 4x4',
                      color: const Color(0xFFF59E0B),
                      tiempo: _records[4]?['tiempo'],
                      movimientos: _records[4]?['movimientos'],
                    ),
                    const SizedBox(height: 16),
                    RecordCard(
                      dificultad: '💀  Difícil',
                      descripcion: 'Tablero 5x5',
                      color: const Color(0xFFEF4444),
                      tiempo: _records[5]?['tiempo'],
                      movimientos: _records[5]?['movimientos'],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
