import 'package:flutter/material.dart';

import 'package:sliding_puzzle/l10n/app_localizations.dart';
import 'package:sliding_puzzle/l10n/supported_locales.dart';
import 'package:sliding_puzzle/theme/app_theme.dart';

/// Monta [home] dentro de un `MaterialApp` con la localización real de la app.
///
/// Los widgets leen sus textos con `AppLocalizations.of(context)`, que busca un
/// `Localizations` ascendente. Sin los delegados esa búsqueda devuelve `null` y
/// el `!` de cada widget revienta con una excepción de dependencia nula, así que
/// todo test que monte UI de la app tiene que pasar por acá.
///
/// Fija `es` por defecto a propósito: el binding de tests resuelve el locale de
/// plataforma como `en_US` y, con el respaldo en español, la app se renderizaría
/// en ese idioma. Forzarlo mantiene las aserciones sobre el texto real de
/// producción (el idioma original del juego) y hace los tests independientes del
/// idioma de la máquina. Pasar [locale] para cubrir el otro idioma.
///
/// Usa [localesSoportados] —la misma lista que `main.dart`— para que un test de
/// respaldo valide el orden que producción realmente usa.
Widget appLocalizada({
  required Widget home,
  Locale locale = const Locale('es'),
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return MaterialApp(
    locale: locale,
    navigatorKey: navigatorKey,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: localesSoportados,
    theme: AppTheme.light,
    home: home,
  );
}
