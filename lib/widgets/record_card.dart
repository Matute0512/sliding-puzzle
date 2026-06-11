import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tarjeta reutilizable para mostrar el récord de cada dificultad.
class RecordCard extends StatelessWidget {
  final String dificultad;
  final String descripcion;
  final Color color;
  final int? tiempo;
  final int? movimientos;

  const RecordCard({
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          sinRecord
              ? Text(
                  'Sin récord todavía - ¡jugá para establecer uno!',
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

/// Item individual dentro de la tarjeta récord
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
