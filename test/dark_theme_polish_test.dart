import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/core/widgets/sheet_tile.dart';
import 'package:notlar/features/notes/presentation/note_card_media.dart';

/// DENEYIM F80.1 (koyu tema döküm: `docs/deneyim/koyu.md`).
void main() {
  test('belge önizlemesi: koyuda %8 siyah perde, açıkta perde yok', () {
    expect(
      documentPreviewScrim(Brightness.dark),
      Colors.black.withValues(alpha: AppAlpha.hairline),
    );
    expect(documentPreviewScrim(Brightness.light).a, 0);
  });

  for (final b in Brightness.values) {
    testWidgets('Sil satırı ($b): koyuda dolu blok değil', (tester) async {
      final theme = AppTheme.of(ThemeFamily.sage, b);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: DestructiveRow(
              icon: Icons.delete,
              label: 'Sil',
              onTap: () {},
            ),
          ),
        ),
      );
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(DestructiveRow),
              matching: find.byType(Material),
            )
            .first,
      );
      final expected = b == Brightness.dark ? AppAlpha.soft : 0.5;
      expect(material.color!.a, closeTo(expected, 0.01));
    });
  }
}
