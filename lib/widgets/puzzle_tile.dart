import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ficha individual del tablero del puzzle
class PuzzleTile extends StatelessWidget {
  final int numero;
  final int size;
  final VoidCallback onTap;

  const PuzzleTile({
    super.key,
    required this.numero,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final esVacio = numero == 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: esVacio ? const Color(0xFFE2E8F0) : const Color(0xFF4361EE),
          borderRadius: BorderRadius.circular(16),
          boxShadow: esVacio
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0xFF3146B5),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: esVacio
              ? null
              : Text(
                  '$numero',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: size == 3
                        ? 28
                        : size == 4
                        ? 22
                        : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
