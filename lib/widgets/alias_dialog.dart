import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

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
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.aliasDialogTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      // Scrolleable: con el teclado abierto los insets recortan el alto
      // disponible del diálogo, y un Column fijo desborda en pantallas chicas.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.aliasDialogBody,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
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
              ),
              decoration: InputDecoration(
                hintText: l10n.aliasHint,
                counterText: '',
                filled: true,
                fillColor: colors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _publicar(),
            ),
          ],
        ),
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.seedColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _publicar,
                child: Text(
                  l10n.publish,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.notNow,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
