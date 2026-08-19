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
      await tester.pumpWidget(TestHelpers.localized(const LingoDeskApp()));
      // The localization scope loads its JSON before the first real
      // frame, so the app is not on screen until it settles.
      await tester.pumpAndSettle();

      expect(
        find.text('Translate every locale from one clean desk'),
        findsOneWidget,
      );
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('Onboarding displays brand-aligned setup copy', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(TestHelpers.localized(const LingoDeskApp()));
      // The localization scope loads its JSON before the first real
      // frame, so the app is not on screen until it settles.
      await tester.pumpAndSettle();

      expect(find.text('Translation workspace'.toUpperCase()), findsOneWidget);
      expect(find.textContaining('home.hero.title'), findsWidgets);
      expect(find.byType(HugeIcon), findsWidgets);
    });

    testWidgets('App uses Material 3 theme', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(TestHelpers.localized(const LingoDeskApp()));
      // The localization scope loads its JSON before the first real
      // frame, so the app is not on screen until it settles.
      await tester.pumpAndSettle();

      // Verify MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);

      // Get the MaterialApp widget to verify theme
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('App does not show debug banner', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(TestHelpers.localized(const LingoDeskApp()));
      // The localization scope loads its JSON before the first real
      // frame, so the app is not on screen until it settles.
      await tester.pumpAndSettle();

      // Get the MaterialApp widget to verify debug banner is disabled
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });
  });
}
