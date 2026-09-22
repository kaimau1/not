import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// LİSTE MADDESİ İŞARETLEME GEÇİŞİ (kullanıcı isteği 2026-09-22: "liste
/// maddeleri tıklanma geçiş animasyonu"). İşaretlenen madde eski yerinde
/// KATLANIR, yeni yerinde AÇILARAK belirir — bir anda ışınlanmaz.
Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

double _sizeOf(WidgetTester tester, String text) {
  final transition = tester.widget<SizeTransition>(
    find
        .ancestor(
          of: find.text(text, findRichText: true),
          matching: find.byType(SizeTransition),
        )
        .first,
  );
  return transition.sizeFactor.value;
}

void main() {
  testWidgets('işaretlenen madde yerinde katlanır, yeni yerinde açılır', (
    tester,
  ) async {
    List<NoteItem>? latest;
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: [
            NoteItem(id: 'a', text: 'Süt'),
            NoteItem(id: 'b', text: 'Ekmek'),
          ],
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_sizeOf(tester, 'Süt'), 1);

    await tester.tap(find.byType(Checkbox).first);
    // İlk anlarda satır yerinde durur (işaret/çizgi görülsün)...
    await tester.pump(const Duration(milliseconds: 60));
    expect(_sizeOf(tester, 'Süt'), 1);
    // ...sonra katlanmaya başlar.
    await tester.pump(const Duration(milliseconds: 250));
    expect(_sizeOf(tester, 'Süt'), lessThan(1));
    expect(_sizeOf(tester, 'Süt'), greaterThan(0));

    // Katlanma biter, madde işaretlilerin arasına taşınır ve AÇILMAYA başlar.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_sizeOf(tester, 'Süt'), lessThan(1));

    await tester.pumpAndSettle();
    expect(_sizeOf(tester, 'Süt'), 1);
    expect(latest!.map((i) => i.text).toList(), ['Ekmek', 'Süt']);
    expect(latest!.last.checked, isTrue);
  });

  test('ortak not aynasının kimliği sahibe önekli, harita alanları tam', () {
    const share = NoteShare(
      ownerId: 'sahip',
      noteId: 'not1',
      ownerName: 'Ayşe',
      sharedWith: ['u1', 'u2'],
      names: {'u1': 'Ali', 'u2': 'Can'},
    );
    // Kural `split('_')[0]` ile sahibi okur (bkz. firestore.rules).
    expect(share.id, 'sahip_not1');
    expect(share.id.split('_').first, share.ownerId);
    expect(share.toMap().keys.toSet(), {
      'ownerId',
      'noteId',
      'ownerName',
      'sharedWith',
      'names',
    });
  });
}
