import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_desk/core/theme/lingo_desk_theme.dart';
import 'package:lingo_desk/features/app_management/domain/entities/app.dart';
import 'package:lingo_desk/features/app_management/domain/entities/app_overview.dart';
import 'package:lingo_desk/features/app_management/presentation/bloc/app_management_state.dart';
import 'package:lingo_desk/features/app_management/presentation/widgets/apps_table.dart';
import 'package:lingo_desk/features/translation_editor/domain/entities/translation_entry.dart';
import 'package:lingo_desk/features/translation_editor/presentation/bloc/translation_editor_state.dart';
import 'package:lingo_desk/features/translation_editor/presentation/widgets/translation_table.dart';

final _app = App(
  id: 'a',
  name: 'assets',
  sourceLanguage: 'en',
  targetLanguages: const ['fr', 'es', 'it', 'pt', 'uk', 'ar', 'ko'],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Widget _wrap(Widget child, double width, {double height = 760}) {
  return MaterialApp(
    theme: LingoDeskTheme.dark(),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

void main() {
  for (final width in [620.0, 780.0, 980.0, 1176.0, 1280.0, 1800.0]) {
    testWidgets('apps table at $width', (tester) async {
      tester.view.physicalSize = Size(width + 40, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: AppsTable(
              state: AppManagementLoaded(
                overviews: [
                  AppOverview(
                    app: _app,
                    keyCount: 1606,
                    missingCount: 9000,
                    missingByLanguage: const {'fr': 0, 'es': 12, 'it': 900},
                    lastActivity: DateTime(2026, 8, 18),
                  ),
                ],
              ),
            ),
          ),
          width,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'collapsed @$width');

      final chevron = find.byTooltip('Show all languages');
      if (chevron.evaluate().isNotEmpty) {
        await tester.tap(chevron.first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'expanded @$width');
      }
    });

    testWidgets('translation table at $width', (tester) async {
      tester.view.physicalSize = Size(width + 40, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          TranslationTableWidget(
            state: TranslationEditorLoaded(
              app: _app,
              entries: [
                for (var i = 0; i < 6; i++)
                  TranslationEntry(
                    key: 'admins.categories.add.field_$i',
                    values: const {'en': 'Hello there', 'fr': 'Bonjour'},
                  ),
              ],
            ),
          ),
          width,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'collapsed @$width');

      final expanders = find.byWidgetPredicate(
        (w) => w is Tooltip && (w.message ?? '').contains('more language'),
      );
      if (expanders.evaluate().isNotEmpty) {
        await tester.tap(expanders.first, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'expanded @$width');
      }
    });
  }
}
