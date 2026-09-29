import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/router.dart';
import 'package:notlar/features/notes/data/share_intake.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/capture_mode_sheet.dart';
import 'package:notlar/features/notes/presentation/share_target_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// "Birlikte aç" / paylaş ile gelen içeriğin hedefi (kullanıcı isteği
/// 2026-09-29: "PDF açmak istediğimde Notlar ana sayfası açılıp ister eski
/// bir notuma ekleme istersem yeni not oluşturma seçenekleri gelsin").
void main() {
  Note note(
    String id, {
    NoteType type = NoteType.text,
    String title = '',
    String body = '',
    List<NoteItem> items = const [],
    DateTime? updatedAt,
    bool locked = false,
    DateTime? archivedAt,
  }) => Note(
    id: id,
    type: type,
    title: title,
    body: body,
    items: items,
    updatedAt: updatedAt,
    locked: locked,
    archivedAt: archivedAt,
  );

  group('yönlendirici dış adresleri sayfa saymaz', () {
    test('WhatsApp content:// adresi dış kaynak', () {
      expect(
        isExternalLocation(
          Uri.parse(
            'content://0@com.whatsapp.provider.media/item/9f3880bd-770b',
          ),
        ),
        isTrue,
      );
      expect(isExternalLocation(Uri.parse('file:///sdcard/a.pdf')), isTrue);
      expect(isExternalLocation(Uri.parse('notlar://voice')), isTrue);
    });

    test('uygulama sayfaları ve web adresleri dış kaynak DEĞİL', () {
      expect(isExternalLocation(Uri.parse('/note/abc')), isFalse);
      expect(isExternalLocation(Uri.parse('/')), isFalse);
      expect(
        isExternalLocation(Uri.parse('https://notlar.app/note/1')),
        isFalse,
      );
    });
  });

  group('hedef not listesi', () {
    final old = note('a', title: 'Eski', updatedAt: DateTime(2026, 1, 1));
    final fresh = note('b', title: 'Kasko', updatedAt: DateTime(2026, 9, 1));
    final pdf = note('c', type: NoteType.pdf, title: 'Poliçe');
    final locked = note('d', title: 'Gizli', locked: true);
    final archived = note('e', title: 'Arşiv', archivedAt: DateTime(2026));

    test('en son düzenlenen üstte; kilitli ve arşivli listelenmez', () {
      final list = shareCandidates([
        old,
        fresh,
        locked,
        archived,
      ], hasFiles: true);
      expect(list.map((n) => n.id), ['b', 'a']);
    });

    test('yalnız metin gelince belge (PDF) notu listelenmez', () {
      expect(shareCandidates([pdf, fresh], hasFiles: false).map((n) => n.id), [
        'b',
      ]);
      expect(
        shareCandidates([pdf, fresh], hasFiles: true).map((n) => n.id),
        containsAll(['b', 'c']),
      );
    });

    test('arama başlıkta ve içerikte, Türkçe büyük harfe duyarsız', () {
      final list = shareCandidates(
        [fresh, note('f', body: 'İSTANBUL poliçesi')],
        hasFiles: true,
        query: 'istanbul',
      );
      expect(list.map((n) => n.id), ['f']);
    });
  });

  group('var olan nota metin ekleme', () {
    var n = 0;
    String id() => 'x${n++}';

    test('metin notunda gövdenin sonuna paragraf', () {
      final fields = appendSharedText(
        note('t', body: 'İlk satır'),
        'https://ornek.com',
        newId: id,
      );
      expect(fields['body'], 'İlk satır\n\nhttps://ornek.com');
    });

    test('boş gövdede yalnız metin', () {
      expect(
        appendSharedText(note('t'), 'Merhaba', newId: id)['body'],
        'Merhaba',
      );
    });

    test('listede her satır yeni madde; sondaki boş madde atlanır', () {
      final list = note(
        'l',
        type: NoteType.checklist,
        items: const [
          NoteItem(id: '1', text: 'Süt'),
          NoteItem(id: '2', text: ''),
        ],
      );
      final fields = appendSharedText(list, 'Ekmek\n\nYumurta', newId: id);
      final items = [
        for (final m in fields['items']! as List) (m as Map)['text'],
      ];
      expect(items, ['Süt', 'Ekmek', 'Yumurta']);
    });

    test('boş metin hiçbir şey yazmaz', () {
      expect(appendSharedText(note('t'), '   ', newId: id), isEmpty);
    });
  });

  group('levha', () {
    Future<ShareDestination?> open(
      WidgetTester tester, {
      required List<Note> notes,
      bool askMode = false,
      Future<void> Function()? act,
    }) async {
      ShareDestination? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showShareTargetSheet(
                      context,
                      incoming: const ShareIncoming(
                        files: [(name: 'kasko.pdf', kind: AttachmentKind.pdf)],
                      ),
                      notes: notes,
                      askMode: askMode,
                    );
                  },
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await act?.call();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('gelen dosya adı ve iki seçenek görünür', (tester) async {
      await open(tester, notes: const []);
      expect(find.text('kasko.pdf'), findsOneWidget);
      expect(find.text('Yeni not'), findsOneWidget);
      expect(find.text('Var olan nota'), findsOneWidget);
    });

    testWidgets('var olan not seçilince o notun kimliği döner', (tester) async {
      final result = await open(
        tester,
        notes: [note('hedef', title: 'Araba')],
        act: () async {
          await tester.tap(find.text('Var olan nota'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Araba'));
        },
      );
      expect(result?.isExisting, isTrue);
      expect(result?.noteId, 'hedef');
    });

    testWidgets('belge paylaşımında yeni not kipi seçilir', (tester) async {
      final result = await open(
        tester,
        notes: const [],
        askMode: true,
        act: () async {
          await tester.enterText(find.byType(TextField).first, 'Kasko');
          await tester.ensureVisible(find.text('Balonlu'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Balonlu'));
        },
      );
      expect(result?.isExisting, isFalse);
      expect(result?.choice?.mode, CaptureMode.bubbles);
      expect(result?.choice?.noteTitle, 'Kasko');
    });
  });
}
