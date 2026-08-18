import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';
import '../theme/app_theme.dart';

/// Pantalla de configuración: tema, sonido y música.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final settings = context.watch<AppSettingsProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Configuración',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _SeccionTitulo(titulo: 'Apariencia', colors: colors),
              const SizedBox(height: 12),
              _CardConfiguracion(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tema',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppTheme.seedColor,
                        selectedForegroundColor: Colors.white,
                        foregroundColor: colors.textPrimary,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode),
                          tooltip: 'Claro',
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode),
                          tooltip: 'Oscuro',
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto),
                          tooltip: 'Sistema',
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (valor) {
                        context.read<AppSettingsProvider>().cambiarTema(
                          valor.first,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SeccionTitulo(titulo: 'Sonido', colors: colors),
              const SizedBox(height: 12),
              _CardConfiguracion(
                colors: colors,
                child: Column(
                  children: [
                    _FilaSwitch(
                      icono: Icons.touch_app_outlined,
                      label: 'Efectos de sonido',
                      descripcion: 'Click al mover fichas y victoria',
                      valor: settings.sonidoActivado,
                      colors: colors,
                      onChanged: (_) {
                        context.read<AppSettingsProvider>().alternarSonido();
                      },
                    ),
                    Divider(color: colors.emptyTile, height: 24),
                    _FilaSwitch(
                      icono: Icons.music_note_outlined,
                      label: 'Música de fondo',
                      descripcion: 'Música durante el menú y el juego',
                      valor: settings.musicaActivada,
                      colors: colors,
                      onChanged: (_) {
                        context.read<AppSettingsProvider>().alternarMusica();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final AppColors colors;

  const _SeccionTitulo({required this.titulo, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _CardConfiguracion extends StatelessWidget {
  final Widget child;
  final AppColors colors;

  const _CardConfiguracion({required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FilaSwitch extends StatelessWidget {
  final IconData icono;
  final String label;
  final String descripcion;
  final bool valor;
  final AppColors colors;
  final ValueChanged<bool> onChanged;

  const _FilaSwitch({
    required this.icono,
    required this.label,
    required this.descripcion,
    required this.valor,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: AppTheme.seedColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                descripcion,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: valor,
          onChanged: onChanged,
          activeThumbColor: AppTheme.seedColor,
        ),
      ],
    );
  }
}
