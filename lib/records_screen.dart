import 'package:flutter/material.dart';
import 'records_service.dart';

/// Pantalla
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreen();
}

class _RecordsScreen extends State<RecordsScreen> {
  // Mapa que guarda los récords de cada dificultad
  final Map<int, Map<String, int?>> _records = {};
  bool _cargado = true;

  @override
  void initState() {
    super.initState();
    _cargarRecords();
  }

  /// Carga los récords de las 3 dificultades al iniciar la pantalla.
  Future<void> _cargarRecords() async {
    for (final size in [3, 4, 5]) {
      final tiempo = await RecordsService.obtenerMejorTiempo(size);
      final movimientos = await RecordsService.obtenerMejorMovimientos(size);
      _records[size] = {'tiempo': tiempo, 'movimientos': movimientos};
    }
    setState(() => _cargado = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('🏆 Récords', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cargado
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _TarjetaRecord(
                  dificultad: '😊 Fácil',
                  descripcion: 'Tablero 3x3',
                  color: Colors.green,
                  tiempo: _records[3]?['tiempo'],
                  movimientos: _records[3]?['movimientos'],
                ),
                const SizedBox(height: 16),
                _TarjetaRecord(
                  dificultad: '😤 Medio',
                  descripcion: 'Tablero 4x4',
                  color: Colors.orange,
                  tiempo: _records[4]?['tiempo'],
                  movimientos: _records[4]?['movimientos'],
                ),
                const SizedBox(height: 16),
                _TarjetaRecord(
                  dificultad: '💀 Difícil',
                  descripcion: 'Tablero 5x5',
                  color: Colors.red,
                  tiempo: _records[5]?['tiempo'],
                  movimientos: _records[5]?['movimientos'],
                ),
              ],
            ),
    );
  }
}

// Widget reutilizable para mostrar el récord de cada dificultad
class _TarjetaRecord extends StatelessWidget {
  final String dificultad;
  final String descripcion;
  final Color color;
  final int? tiempo;
  final int? movimientos;

  const _TarjetaRecord({
    required this.dificultad,
    required this.descripcion,
    required this.color,
    required this.tiempo,
    required this.movimientos,
  });

  @override
  Widget build(BuildContext context) {
    final sinRecord = tiempo == null && movimientos == null;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dificultad,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  descripcion,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            sinRecord
                ? const Text(
                    'Sin récord todavía — ¡jugá para establecer uno!',
                    style: TextStyle(color: Colors.grey),
                  )
                : Row(
                    children: [
                      const Icon(Icons.timer, size: 18, color: Colors.indigo),
                      const SizedBox(width: 4),
                      Text(
                        '${tiempo ?? '-'}s',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 24),
                      const Icon(
                        Icons.sports_esports,
                        size: 18,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${movimientos ?? '-'} mov',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
