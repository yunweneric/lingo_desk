// TEMPORARY visual harness - deleted after review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_desk/core/theme/lingo_desk_theme.dart';
import 'package:lingo_desk/features/translation_editor/presentation/widgets/translation_cell_field.dart';

void main() {
  testWidgets('cell alignment', (tester) async {
    tester.view.physicalSize = const Size(560, 260);
    // Zoom in: the defect is a few pixels of vertical offset.
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LingoDeskTheme.light(),
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Guide rules at the exact top/bottom of each 36px box make
                // any off-centre baseline obvious.
                for (final missing in [false, true]) ...[
                  Container(
                    color: const Color(0x11FF0000),
                    child: TranslationCellField(
                      value: missing ? '' : 'Description',
                      highlightMissing: missing,
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Container(
                  color: const Color(0x11FF0000),
                  child: TranslationCellField(
                    key: const Key('focus-me'),
                    value: 'Description',
                    highlightMissing: false,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('focus-me')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('__preview__/cell.png'),
    );
  });
}
