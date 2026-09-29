import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_settings_provider.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';
import 'image_puzzle_test_screen.dart';

/// Pantalla de configuración: tema, sonido y música.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final settings = context.watch<AppSettingsProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
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
              _SeccionTitulo(titulo: l10n.appearance, colors: colors),
              const SizedBox(height: 12),
              _CardConfiguracion(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.theme,
                      style: const TextStyle(
                        fontSize: 14,
                        color: KenneyInk.secondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // width: double.infinity + expandedInsets hacen que el
                    // control ocupe todo el ancho de la card y reparta los
                    // 3 segmentos de forma pareja y centrada.
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        expandedInsets: EdgeInsets.zero,
                        // El checkmark de selección roba ancho horizontal y
                        // hace que 'Sistema' se corte en pantallas angostas.
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          selectedBackgroundColor: AppTheme.seedColor,
                          selectedForegroundColor: Colors.white,
                          foregroundColor: KenneyInk.primary,
                        ),
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(Icons.light_mode),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(l10n.themeLight, maxLines: 1),
                            ),
                            tooltip: l10n.themeLight,
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.dark_mode),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(l10n.themeDark, maxLines: 1),
                            ),
                            tooltip: l10n.themeDark,
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: const Icon(Icons.brightness_auto),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(l10n.themeSystem, maxLines: 1),
                            ),
                            tooltip: l10n.themeSystem,
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (valor) {
                          context.read<AppSettingsProvider>().cambiarTema(
                            valor.first,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SeccionTitulo(titulo: l10n.sound, colors: colors),
              const SizedBox(height: 12),
              _CardConfiguracion(
                child: Column(
                  children: [
                    _FilaSwitch(
                      icono: Icons.touch_app_outlined,
                      label: l10n.soundEffects,
                      descripcion: l10n.soundEffectsDesc,
                      valor: settings.sonidoActivado,
                      onChanged: (_) {
                        context.read<AppSettingsProvider>().alternarSonido();
                      },
                    ),
                    const Divider(color: KenneyInk.line, height: 24),
                    _FilaSwitch(
                      icono: Icons.music_note_outlined,
                      label: l10n.backgroundMusic,
                      descripcion: l10n.backgroundMusicDesc,
                      valor: settings.musicaActivada,
                      onChanged: (_) {
                        context.read<AppSettingsProvider>().alternarMusica();
                      },
                    ),
                  ],
                ),
              ),
              // ⚠️ TEMPORAL: acceso a la pantalla de prueba del puzzle con
              // imagen. Se borra junto con `image_puzzle_test_screen.dart`.
              // `kDebugMode` garantiza que no llegue a un build de release, así
              // que no hace falta traducir estos textos.
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                _SeccionTitulo(titulo: 'DEBUG', colors: colors),
                const SizedBox(height: 12),
                _CardConfiguracion(
                  // El Material propio sigue siendo obligatorio: la superficie
                  // es un `DecoratedBox` con un sprite de fondo, y un ListTile
                  // ahí adentro dispara una assertion ("background color or ink
                  // splashes may be invisible") porque pintaría sus efectos en
                  // el Material del Scaffold, por debajo de la tarjeta.
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.image_outlined,
                        color: AppTheme.seedColor,
                      ),
                      title: const Text(
                        'Puzzle con imagen',
                        style: TextStyle(color: KenneyInk.primary),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ImagePuzzleTestScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Tarjeta de configuración. La superficie es un panel 9-slice de Kenney, que
/// es claro en los dos temas: por eso los textos que van adentro usan
/// [KenneyInk] y no `AppColors` (ver [KenneyInk]).
class _CardConfiguracion extends StatelessWidget {
  final Widget child;

  const _CardConfiguracion({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: KenneySurface(
        slice: KenneySlices.flatPanel,
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _FilaSwitch extends StatelessWidget {
  final IconData icono;
  final String label;
  final String descripcion;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _FilaSwitch({
    required this.icono,
    required this.label,
    required this.descripcion,
    required this.valor,
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: KenneyInk.primary,
                ),
              ),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 12,
                  color: KenneyInk.secondary,
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
