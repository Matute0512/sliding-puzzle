import 'package:flutter/widgets.dart';

/// Locales soportados por la app, **en orden de preferencia**.
///
/// El orden importa: cuando el idioma del dispositivo no coincide con ninguno,
/// Flutter cae al primero de esta lista y la app se renderiza en ese idioma.
/// El juego nació en español, así que ese es el respaldo correcto.
///
/// No se usa `AppLocalizations.supportedLocales` a propósito: gen-l10n lo emite
/// en orden alfabético —`[en, es]`, sin importar cuál sea el template— y con esa
/// lista un usuario en portugués, francés o italiano vería inglés.
///
/// Vive en su propio archivo para que `main.dart` y los tests consuman
/// exactamente la misma lista: si cada uno declarara la suya, los tests podrían
/// pasar validando un orden que producción no usa.
const List<Locale> localesSoportados = [Locale('es'), Locale('en')];
