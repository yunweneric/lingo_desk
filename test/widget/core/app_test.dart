import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lingo_desk/core/app.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('LingoDeskApp Widget Tests', () {
    setUp(() async {
      await TestHelpers.setUp();
    });

    tearDown(() async {
      await TestHelpers.tearDown();
    });

    testWidgets('App renders onboarding title', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const LingoDeskApp());

      expect(find.text('Translate everything, once'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('Onboarding displays brand-aligned setup copy', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const LingoDeskApp());

      expect(find.text('Translation workspace'.toUpperCase()), findsOneWidget);
      expect(find.textContaining('home.hero.title'), findsOneWidget);
      expect(find.byType(HugeIcon), findsWidgets);
    });

    testWidgets('App uses Material 3 theme', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const LingoDeskApp());

      // Verify MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);

      // Get the MaterialApp widget to verify theme
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('App does not show debug banner', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const LingoDeskApp());

      // Get the MaterialApp widget to verify debug banner is disabled
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });
  });
}
