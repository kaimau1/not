import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/presentation/folder_tile.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/core/widgets/undo_snackbar.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/auth/presentation/account_sheet.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/friends/data/friends_repository.dart';
import 'package:notlar/features/friends/domain/friend.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/notes/data/attachment_save.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_strip.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences _prefs;

/// Ek şeridi tercihleri okur (görünüm, Drive): sağlayıcı test için verilir.
Widget _scoped(Widget child) => ProviderScope(
  overrides: [sharedPreferencesProvider.overrideWithValue(_prefs)],
  child: child,
);

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('tr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

const _slide = Attachment(
  id: 's',
  kind: AttachmentKind.slide,
  fileName: 'sunum.pptx',
  mimeType: '',
);

/// 2026-10-17 (6. tur) — simge, ayarlar, farklı kaydet, sunumun gömülü/sabit
/// kipleri, tek AI arama anahtarı, gelen+paylaşılan birleşimi, ek şeridinin
/// aç/kapası, kendiliğinden kapanan bildirimler.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  group('Sunum: gömülü ve sabit kipler', () {
    test('sunum sayfaya gömülür ve sabitlenir', () {
      // Varsayılan yeri şerit (eski sunum ekleri kendiliğinden sayfaya
      // taşınmaz).
      expect(_slide.offPage, isTrue);
      expect(_slide.floatsOnPage, isFalse);
      final placed = _slide.placedOnPage(true);
      expect(placed.floatsOnPage, isTrue);
      expect(placed.offPage, isFalse);
      final pinned = _slide.copyWith(pinHeight: 220);
      expect(pinned.isPinnedTop, isTrue);
      expect(pinned.floatsOnPage, isFalse);
    });
  });

  group('Farklı kaydet', () {
    test('dosya adı ve türü', () {
      const text = Attachment(
        id: 't',
        kind: AttachmentKind.text,
        fileName: 'Toplantı',
        mimeType: '',
        text: 'merhaba',
      );
      expect(saveAsFileName(text), 'Toplantı.txt');
      expect(saveAsMimeType(text), 'text/plain');
      expect(saveAsFileName(_slide), 'sunum.pptx');
      expect(saveAsMimeType(_slide), contains('presentationml'));
      const pdf = Attachment(
        id: 'p',
        kind: AttachmentKind.pdf,
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
      );
      expect(saveAsMimeType(pdf), 'application/pdf');
    });

    testWidgets('ek şeridinin ⋯ levhasında "Farklı kaydet" var', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scoped(
          _app(
            Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: AttachmentStrip(
                  attachments: const [_slide],
                  onRemove: (_) {},
                  expanded: true,
                  onToggle: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('strip-more')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('strip-action-saveAs')), findsOneWidget);
      expect(find.text('Farklı kaydet'), findsOneWidget);
    });
  });

  group('Ek şeridi aç/kapa', () {
    testWidgets('açık şeridin başında GİZLE tutamağı', (tester) async {
      var toggles = 0;
      await tester.pumpWidget(
        _scoped(
          _app(
            Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: AttachmentStrip(
                  attachments: const [_slide],
                  onRemove: (_) {},
                  expanded: true,
                  onToggle: () => toggles++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('strip-collapse')));
      expect(toggles, 1);
    });

    testWidgets('alt çubuktaki ataç gizliyse kapalı şeridin tutamağı var', (
      tester,
    ) async {
      var toggles = 0;
      Widget strip(bool handle) => _scoped(
        _app(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AttachmentStrip(
                attachments: const [_slide],
                onRemove: (_) {},
                expanded: false,
                collapsedHandle: handle,
                onToggle: () => toggles++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(strip(false));
      expect(find.byKey(const ValueKey('strip-expand')), findsNothing);
      await tester.pumpWidget(strip(true));
      await tester.tap(find.byKey(const ValueKey('strip-expand')));
      expect(toggles, 1);
    });
  });

  group('Bildirimler kendiliğinden kapanır', () {
    testWidgets('eylemli bildirim geri sayımla kapanır, eylem çalışır', (
      tester,
    ) async {
      var undone = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  timedSnackBar(
                    content: const Text('Metin kaldırıldı'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(
                      label: 'Geri al',
                      onPressed: () => undone++,
                    ),
                  ),
                ),
                child: const Text('GÖSTER'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('GÖSTER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Metin kaldırıldı'), findsOneWidget);
      // KÖK NEDEN testi: aksiyonlu SnackBar'ın varsayılanı persist: true.
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.persist, isFalse);
      expect(find.byKey(const ValueKey('snack-countdown')), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Metin kaldırıldı'), findsNothing);

      await tester.tap(find.text('GÖSTER'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('snack-action')));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.text('Metin kaldırıldı'), findsNothing);
    });
  });

  group('Ana ekran menüsü', () {
    testWidgets('Ayarlar hızlı satırda ve GRİ', (tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: ActionMenu(
              quick: [
                MenuAction('trash', 'Çöp', Icons.delete_outline),
                MenuAction(
                  'settings',
                  'Ayarlar',
                  Icons.settings_outlined,
                  neutral: true,
                ),
              ],
              sections: [],
            ),
          ),
        ),
      );
      final scheme = Theme.of(
        tester.element(find.byType(ActionMenu)),
      ).colorScheme;
      Color circleOf(String id) {
        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byKey(ValueKey('menu-quick-$id')),
                matching: find.byType(Container),
              )
              .first,
        );
        return (box.decoration! as BoxDecoration).color!;
      }

      expect(circleOf('settings'), scheme.surfaceContainerHighest);
      expect(circleOf('trash'), scheme.primaryContainer);
    });
  });

  group('Gelen ve paylaşılanlar', () {
    testWidgets('rozet gelen + okunmamış ortak notları sayar; iki sekme', (
      tester,
    ) async {
      final inbox = [
        const InboxNote(
          id: 'i1',
          fromUid: 'ali',
          fromName: 'Ali',
          fromEmail: 'ali@x',
          title: 'Gelen not',
          body: 'merhaba',
          items: [],
          type: NoteType.text,
          tags: [],
          color: NoteColor.none,
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(_prefs),
            currentUidProvider.overrideWithValue('ben'),
            inboxNotesProvider.overrideWith((ref) => Stream.value(inbox)),
            sharedNotesWithMeProvider.overrideWith(
              (ref) => Stream.value(const <NoteShare>[]),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            incomingFriendRequestsProvider.overrideWith(
              (ref) => Stream.value(const <FriendRequest>[]),
            ),
            premiumProvider.overrideWith((ref) => Stream.value(false)),
          ],
          child: _app(
            const Scaffold(
              body: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [SharedHubChip(), AccountAvatarButton()],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 2026-10-31: kapı klasör şeridindeki kısa adlı "Gelen" çipi; rozet
      // onun üstünde, avatar artık saymaz (yalnız arkadaşlık isteği).
      expect(find.text('Gelen'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('home-account-avatar')),
          matching: find.text('1'),
        ),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('shared-hub-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Gelen ve paylaşılanlar'), findsWidgets);
      expect(find.byKey(const ValueKey('hub-tab-inbox')), findsOneWidget);
      expect(find.byKey(const ValueKey('hub-tab-shared')), findsOneWidget);
      // Gelen sekmesi açık: not listede.
      expect(find.text('Gelen not'), findsOneWidget);
    });
  });
}
