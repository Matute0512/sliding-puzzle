import 'package:flutter/material.dart';

/// Botón reutilizable para cada nivel de dificultad.
class DifficultyButton extends StatelessWidget {
  final String label;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  const DifficultyButton({
    super.key,
    required this.label,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
        onPressed: onTap,
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(descripcion, style: const TextStyle(fontFamily: 'Poppins',fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
