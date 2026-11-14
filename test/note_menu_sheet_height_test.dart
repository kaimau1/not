import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/l10n_ext.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_menu_model.dart';

/// **NOT MENÜSÜ ÖLÜ ALANI** (DENEYIM F76.1, D11): tutamak + ✕ birlikteydi,
/// altta "Ekranı düzenle · Ayarlar" satırı vardı. Kabul: 412×915'te levha
/// 2026-11-12 öncesinden (774 dp bu testte, 775 dp `telefon-n4-menu.png`) ≥ 100 dp kısa;
/// 360×640'ta "Sil"e ≤ 120 dp kaydırmayla ulaşılır.
void main() {
  Future<(double sheet, double scrollToDelete)> measure(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showActionMenuSheet(
                context,
                noteMenuModel(
                  context.l10n,
                  const Note(
                    id: 'n4',
                    type: NoteType.text,
                    title: 'Toplantı notları',
                  ),
                  surface: NoteMenuSurface.editor,
                  // Not ekranında üst/alt çubukta duranlar (tur sahnesi gibi).
                  visibleElsewhere: const {'pin', 'share', 'search'},
                ),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    final sheet = tester.getRect(find.byType(BottomSheet));
    final delete = tester.getRect(
      find.byKey(const ValueKey('menu-tile-delete')),
    );
    final overflow = delete.bottom - size.height;
    return (sheet.height, overflow < 0 ? 0.0 : overflow);
  }

  // Tutamak geri geldi (kullanıcı isteği 2026-11-14: "tutup aşağı
  // çekemiyorum"): tavan 674 + 48 dp tutamak alanı.
  testWidgets('412×915: levha ≤ 722 dp (tutamaklı), alt satır yok', (
    tester,
  ) async {
    final (h, _) = await measure(tester, const Size(412, 915));
    // ignore: avoid_print
    print('F76.1 levha yüksekliği 412×915: ${h.toStringAsFixed(0)} dp');
    expect(h, lessThanOrEqualTo(722));
    expect(find.byKey(const ValueKey('menu-footer-settings')), findsNothing);
  });

  testWidgets('360×640: "Sil"e ≤ 120 dp kaydırma', (tester) async {
    final (_, scroll) = await measure(tester, const Size(360, 640));
    // ignore: avoid_print
    print('F76.1 Sil için kaydırma 360×640: ${scroll.toStringAsFixed(0)} dp');
    expect(scroll, lessThanOrEqualTo(120));
  });
}
