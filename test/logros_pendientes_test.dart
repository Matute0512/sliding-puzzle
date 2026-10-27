import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/logros_pendientes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LogrosPendientes', () {
    test('encolar agrega IDs sin duplicados e ignora vacíos', () async {
      await LogrosPendientes.encolar('A');
      await LogrosPendientes.encolar('B');
      await LogrosPendientes.encolar('A');
      await LogrosPendientes.encolar('   ');
      await LogrosPendientes.encolar('');

      expect(await LogrosPendientes.leer(), ['A', 'B']);
    });

    test('la cola persiste en SharedPreferences', () async {
      await LogrosPendientes.encolar('A');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(LogrosPendientes.clave), ['A']);
    });

    test('sincronizar quita solo los logros enviados con éxito', () async {
      await LogrosPendientes.encolar('OK1');
      await LogrosPendientes.encolar('FALLA');
      await LogrosPendientes.encolar('OK2');

      final enviados = await LogrosPendientes.sincronizar((id) async {
        if (id == 'FALLA') throw Exception('sin red');
      });

      expect(enviados, 2);
      expect(await LogrosPendientes.leer(), ['FALLA']);
    });

    test('sincronizar con cola vacía no llama al envío', () async {
      var llamadas = 0;
      final enviados = await LogrosPendientes.sincronizar((_) async => llamadas++);

      expect(enviados, 0);
      expect(llamadas, 0);
    });

    test('conserva logros encolados durante el envío', () async {
      await LogrosPendientes.encolar('A');

      await LogrosPendientes.sincronizar((id) async {
        await LogrosPendientes.encolar('NUEVO');
      });

      expect(await LogrosPendientes.leer(), ['NUEVO']);
    });
  });
}

