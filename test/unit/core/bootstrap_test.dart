import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_desk/core/bootstrap.dart';
import 'package:lingo_desk/core/di/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bootstrap', () {
    setUp(() async {
      // Use in-memory storage and start from a clean container.
      SharedPreferences.setMockInitialValues({});
      await reset();
    });

    tearDown(() async {
      await reset();
    });

    test('initialize completes without errors', () async {
      await expectLater(Bootstrap.initialize(), completes);
    });

    test('initialize is async and completes', () async {
      // Verify that initialize is actually async
      final future = Bootstrap.initialize();
      expect(future, isA<Future<void>>());
      await future;
    });
  });
}
