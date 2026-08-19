import 'dart:convert';

/// Representa una partida guardada en el historial de récords.
class RecordGame {
  final int tiempo;
  final int movimientos;

  const RecordGame({required this.tiempo, required this.movimientos});

  Map<String, dynamic> toJson() => {
    'tiempo': tiempo,
    'movimientos': movimientos,
  };

  factory RecordGame.fromJson(Map<String, dynamic> json) => RecordGame(
    tiempo: json['tiempo'] as int,
    movimientos: json['movimientos'] as int,
  );

  static String encodeList(List<RecordGame> lista) =>
      jsonEncode(lista.map((p) => p.toJson()).toList());

  static List<RecordGame> decodeList(String raw) {
    final lista = jsonDecode(raw) as List<dynamic>;
    return lista
        .map((e) => RecordGame.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
