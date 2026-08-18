import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_desk/core/theme/lingo_desk_theme.dart';
import 'package:lingo_desk/core/widgets/lingo_desk_checkbox.dart';

void main() {
  testWidgets('checkbox and tile toggle and render in both themes', (
    tester,
  ) async {
    for (final theme in [LingoDeskTheme.dark(), LingoDeskTheme.light()]) {
      var boxValue = false;
      var tileValue = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    LingoDeskCheckbox(
                      value: boxValue,
                      semanticLabel: 'Include French',
                      onChanged: (v) => setState(() => boxValue = v),
                    ),
                    const LingoDeskCheckbox(value: true, onChanged: null),
                    const LingoDeskCheckbox(
                      value: false,
                      onChanged: null,
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(
                      width: 420,
                      child: LingoDeskCheckboxTile(
                        value: tileValue,
                        leading: '🇫🇷',
                        title: 'French',
                        description: 'translations/fr-FR.json',
                        trailing: const Text('12 missing'),
                        onChanged: (v) => setState(() => tileValue = v),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(LingoDeskCheckbox).first);
      await tester.pumpAndSettle();
      expect(boxValue, isTrue);

      await tester.tap(find.text('translations/fr-FR.json'));
      await tester.pumpAndSettle();
      expect(tileValue, isFalse, reason: 'tapping the row toggles it');

      await tester.tap(
        find.byType(LingoDeskCheckbox).last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(tileValue, isTrue, reason: 'the box inside the row toggles too');

      expect(tester.takeException(), isNull);
    }
  });
}
