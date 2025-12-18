import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_desk/core/bootstrap.dart';

void main() {
  group('Bootstrap', () {
    test('initialize completes without errors', () async {
      // This test verifies that bootstrap initialization doesn't throw
      expect(() => Bootstrap.initialize(), returnsNormally);
    });

    test('initialize is async and completes', () async {
      // Verify that initialize is actually async
      final future = Bootstrap.initialize();
      expect(future, isA<Future<void>>());
      await future;
    });
  });
}
