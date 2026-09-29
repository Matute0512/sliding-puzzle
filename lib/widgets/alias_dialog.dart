import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';

/// Diálogo para elegir el alias del Top 5 Global (máx. 5 letras mayúsculas).
///
/// Es un `StatefulWidget` a propósito: el `TextEditingController` tiene que
/// vivir exactamente lo que vive el `TextField`. Creándolo fuera y llamando a
/// `dispose()` después de `showDialog`, el controlador se liberaba mientras el
/// diálogo todavía estaba montado durante su animación de salida, y cualquier
/// rebuild en esa ventana —el teclado al ocultarse cambia los insets y fuerza
/// uno— reventaba con "A TextEditingController was used after being disposed".
/// Atándolo al `State`, el controlador se libera en el mismo frame en que se
/// desmonta el campo, sin ventana de riesgo y sin importar por dónde salga el
/// usuario (Publicar, "Ahora no" o el botón Atrás del sistema).
///
/// Los colores del texto van fijos (ver [KenneyInk]): el panel de Kenney es
/// claro en los dos temas, así que el texto de encima va oscuro siempre.
class AliasDialog extends StatefulWidget {
  const AliasDialog({super.key});

  /// Muestra el diálogo y devuelve el alias normalizado (recortado, en
  /// mayúsculas y de hasta 5 letras), o `null` si el usuario lo descartó o no
  /// escribió nada.
  static Future<String?> mostrar(BuildContext context) async {
    final alias = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AliasDialog(),
    );

    final normalizado = alias?.trim().toUpperCase() ?? '';
    if (normalizado.isEmpty) return null;
    return normalizado.length <= 5 ? normalizado : normalizado.substring(0, 5);
  }

  @override
  State<AliasDialog> createState() => _AliasDialogState();
}

class _AliasDialogState extends State<AliasDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _publicar() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return KenneyDialog(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      // Scrolleable: con el teclado abierto los insets recortan el alto
      // disponible del diálogo, y un Column fijo desborda en pantallas chicas.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.aliasDialogTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KenneyInk.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.aliasDialogBody,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: KenneyInk.secondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              maxLength: 5,
              inputFormatters: [LengthLimitingTextInputFormatter(5)],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: KenneyInk.primary,
              ),
              decoration: InputDecoration(
                hintText: l10n.aliasHint,
                counterText: '',
                filled: true,
                // Claro y fijo, como el resto de la superficie: el campo vive
                // sobre el sprite, no sobre el fondo del tema.
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _publicar(),
            ),
            const SizedBox(height: 20),
            KenneyButton(
              tint: AppTheme.seedColor,
              onPressed: _publicar,
              child: Text(
                l10n.publish,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.notNow,
                style: const TextStyle(color: KenneyInk.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
