import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'records_service.dart';

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
                    _TarjetaRecord(
                      dificultad: '😊  Fácil',
                      descripcion: 'Tablero 3x3',
                      color: const Color(0xFF10B981),
                      tiempo: _records[3]?['tiempo'],
                      movimientos: _records[3]?['movimientos'],
                    ),
                    const SizedBox(height: 16),
                    _TarjetaRecord(
                      dificultad: '😤  Medio',
                      descripcion: 'Tablero 4x4',
                      color: const Color(0xFFF59E0B),
                      tiempo: _records[4]?['tiempo'],
                      movimientos: _records[4]?['movimientos'],
                    ),
                    const SizedBox(height: 16),
                    _TarjetaRecord(
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la tarjeta
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                dificultad,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                descripcion,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Contenido
          sinRecord
              ? Text(
                  'Sin récord todavía — ¡jugá para establecer uno!',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                )
              : Row(
                  children: [
                    _ItemRecord(
                      icono: Icons.timer,
                      label: 'Mejor tiempo',
                      valor: '${tiempo ?? '-'}s',
                    ),
                    const SizedBox(width: 24),
                    _ItemRecord(
                      icono: Icons.sports_esports,
                      label: 'Menos movimientos',
                      valor: '${movimientos ?? '-'}',
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _ItemRecord extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _ItemRecord({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 16, color: const Color(0xFF4361EE)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
