import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lingo_desk/core/di/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InjectionContainer', () {
    setUp(() async {
      // Use in-memory storage and reset GetIt before each test
      SharedPreferences.setMockInitialValues({});
      await reset();
    });

    tearDown(() async {
      // Clean up after each test
      await reset();
    });

    test('init completes without errors', () async {
      await expectLater(init(), completes);
    });

    test('reset clears all registered dependencies', () async {
      // Register a test dependency
      getIt.registerLazySingleton<String>(() => 'test');

      // Verify it's registered
      expect(getIt<String>(), equals('test'));

      // Reset
      await reset();

      // Verify it's no longer registered
      expect(() => getIt<String>(), throwsA(isA<StateError>()));
    });

    test('getIt instance is accessible', () {
      // Verify getIt instance exists
      expect(getIt, isNotNull);
      expect(getIt, isA<GetIt>());
    });
  });
}
