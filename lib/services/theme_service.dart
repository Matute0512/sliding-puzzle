import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda y recupera la preferecia del tema (claro,oscuro,sistema).
class ThemeService {
  static const String _clave = 'theme_mode';

  static Future<ThemeMode> cargarThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString(_clave);

    switch (valor) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> guardarThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, mode.name);
  }
}
