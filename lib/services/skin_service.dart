import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'coins_service.dart';

/// Representa un tema visual de fichas para el tablero del puzzle.
@immutable
class TileSkin {
  final String id;
  final int precio;
  final Color colorFicha;
  final Color colorSombra;
  final Color colorAcento;

  const TileSkin({
    required this.id,
    required this.precio,
    required this.colorFicha,
    required this.colorSombra,
    required this.colorAcento,
  });

  bool get esGratis => precio == 0;
}

/// Servicio que gestiona la tienda, desbloqueo y equipamiento de temas de fichas.
class SkinService {
  static const String skinClasicaId = 'classic';
  static const String _claveSkinsDesbloqueadas = 'skins_desbloqueadas';
  static const String _claveSkinEquipada = 'skin_equipada';

  /// Catálogo oficial de skins arcade.
  /// Todos los colores fueron verificados para cumplir con contraste WCAG AA (≥ 4.5:1)
  /// sobre el texto blanco de los números de las fichas.
  static const Map<String, TileSkin> catalogo = {
    'classic': TileSkin(
      id: 'classic',
      precio: 0,
      colorFicha: Color(0xFF4361EE),
      colorSombra: Color(0xFF3146B5),
      colorAcento: Color(0xFF809BFD),
    ),
    'emerald': TileSkin(
      id: 'emerald',
      precio: 100,
      colorFicha: Color(0xFF047857),
      colorSombra: Color(0xFF064E3B),
      colorAcento: Color(0xFF34D399),
    ),
    'crimson': TileSkin(
      id: 'crimson',
      precio: 200,
      colorFicha: Color(0xFFDC2626),
      colorSombra: Color(0xFF991B1B),
      colorAcento: Color(0xFFF87171),
    ),
    'cyber': TileSkin(
      id: 'cyber',
      precio: 300,
      colorFicha: Color(0xFF7C3AED),
      colorSombra: Color(0xFF5B21B6),
      colorAcento: Color(0xFFA78BFA),
    ),
    'amber': TileSkin(
      id: 'amber',
      precio: 500,
      colorFicha: Color(0xFFB45309),
      colorSombra: Color(0xFF78350F),
      colorAcento: Color(0xFFFBBF24),
    ),
  };

  /// Lista ordenada de skins para mostrar en la tienda.
  static List<TileSkin> get skinsDisponibles => catalogo.values.toList();

  /// Notificador reactivo de la skin actualmente equipada.
  static final ValueNotifier<String> skinEquipadaListenable =
      ValueNotifier<String>(skinClasicaId);

  /// Notificador reactivo del conjunto de IDs desbloqueadas.
  static final ValueNotifier<Set<String>> skinsDesbloqueadasListenable =
      ValueNotifier<Set<String>>({skinClasicaId});

  /// Retorna la [TileSkin] actualmente activa.
  static TileSkin get skinEquipada =>
      catalogo[skinEquipadaListenable.value] ?? catalogo[skinClasicaId]!;

  /// Inicializa el servicio leyendo el estado persistido en [SharedPreferences].
  static Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();

    final listaGuardada =
        prefs.getStringList(_claveSkinsDesbloqueadas) ?? [skinClasicaId];
    final desbloqueadas = Set<String>.from(listaGuardada)..add(skinClasicaId);
    skinsDesbloqueadasListenable.value = desbloqueadas;

    final equipadaGuardada =
        prefs.getString(_claveSkinEquipada) ?? skinClasicaId;
    if (desbloqueadas.contains(equipadaGuardada) &&
        catalogo.containsKey(equipadaGuardada)) {
      skinEquipadaListenable.value = equipadaGuardada;
    } else {
      skinEquipadaListenable.value = skinClasicaId;
    }
  }

  /// Indica si la skin [id] ya fue adquirida o desbloqueada.
  static bool estaDesbloqueada(String id) =>
      skinsDesbloqueadasListenable.value.contains(id);

  /// Intenta adquirir una skin deduciendo su costo en monedas de [CoinsService].
  /// Retorna `true` si la compra fue exitosa o si ya estaba desbloqueada.
  static Future<bool> comprarSkin(String id) async {
    final skin = catalogo[id];
    if (skin == null) return false;

    if (estaDesbloqueada(id)) return true;

    final pudoPagar = await CoinsService.gastarMonedas(skin.precio);
    if (!pudoPagar) return false;

    final nuevoSet = Set<String>.from(skinsDesbloqueadasListenable.value)
      ..add(id);
    skinsDesbloqueadasListenable.value = nuevoSet;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_claveSkinsDesbloqueadas, nuevoSet.toList());

    // Al comprarla, la equipamos automáticamente por conveniencia del usuario.
    await equiparSkin(id);
    return true;
  }

  /// Equipa la skin indicada si está en la lista de desbloqueadas.
  static Future<bool> equiparSkin(String id) async {
    if (!estaDesbloqueada(id) || !catalogo.containsKey(id)) return false;

    skinEquipadaListenable.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveSkinEquipada, id);
    return true;
  }

  /// Restablece el estado en memoria para tests aislados.
  @visibleForTesting
  static void reiniciarParaTests() {
    skinEquipadaListenable.value = skinClasicaId;
    skinsDesbloqueadasListenable.value = {skinClasicaId};
  }
}
