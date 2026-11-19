import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_actions_sheet.dart';
import 'package:notlar/features/notes/presentation/quick_add_actions.dart';
import 'package:notlar/features/notes/presentation/quick_add_fab.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Not işlem menüsü (⋮ / uzun basış) iki sütunlu, "+" paneli üç sütunlu
/// ızgaradır. Bu testler yerleşimi doğrular: Flutter testlerinde taşma
/// (overflow) hata attığından, sığmayan bir ızgara testi kırar.
void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget host(Widget child) => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  testWidgets('not işlem menüsü iki sütunlu ızgara olarak açılır', (
    tester,
  ) async {
    const note = Note(id: 'n1', type: NoteType.text, title: 'Kitaplık planı');
    await tester.pumpWidget(
      host(
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showNoteActionsSheet(context, ref, note),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    // Başlık + tüm işlemler görünür (eskiden "Sil" kaydırma gerektiriyordu).
    expect(find.text('Kitaplık planı'), findsOneWidget);
    // Kopyala/Arkadaşa gönder/Dışa aktar Paylaş levhasında (2026-10-17).
    expect(find.text('Arkadaşa gönder'), findsNothing);
    for (final label in ['Sabitle', 'Paylaş', 'Yıldızla', 'Seç', 'Sil']) {
      expect(find.text(label), findsOneWidget, reason: '$label görünmeli');
    }
    // Gruplar katlanır çekmece (2026-11-16): Kopyala kapalı, dokununca açılır.
    expect(find.text('Notu çoğalt'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('menu-fold-head-Kopyala')));
    await tester.pumpAndSettle();
    expect(find.text('Notu çoğalt'), findsOneWidget);

    // Hızlı satır ÖNEM SIRASIYLA (kullanıcı isteği 2026-11-16): Sabitle ·
    // Zemin rengi · Çerçeve · Paylaş · Klasöre taşı, AYNI satırda.
    final pin = tester.getRect(find.text('Sabitle'));
    final color = tester.getRect(find.text('Zemin rengi'));
    final share = tester.getRect(find.text('Paylaş'));
    // Üst kenar: uzun ad iki satıra inebilir.
    expect(pin.top, closeTo(color.top, 1));
    expect(pin.top, closeTo(share.top, 1));
    expect(pin.center.dx, lessThan(color.center.dx));
    expect(color.center.dx, lessThan(share.center.dx));

    // "Sil" tek başına, alt satırda ve tam genişlikte.
    expect(tester.getRect(find.text('Sil')).center.dy, greaterThan(pin.top));
  });

  testWidgets(
    '"+" paneli tek panel: Metin/Liste altta, seçenekler tek dokunuş',
    (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(host(_FabHost(calls)));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final fab = tester.getRect(find.byType(FloatingActionButton).last);
      final text = tester.getRect(find.text('Metin notu'));
      final list = tester.getRect(find.text('Liste'));
      // Birincil üçlü yan yana ve PANELİN EN ÜSTÜNDE (kullanıcı isteği
      // 2026-11-19: "alttaki metin liste maddeyi üste taşı").
      expect(text.center.dy, closeTo(list.center.dy, 1));
      expect(text.center.dx, lessThan(list.center.dx));
      expect(text.bottom, lessThan(fab.top));
      // Ana ekranda sesli not menüde yok (tek mikrofon, F3.1).
      expect(find.text('AI sesli not'), findsNothing);
      // Gruplar başlıklı; başparmaktan yukarı: Kamera, Şablon. Kalem ve Dosya
      // karoları varsayılan gizli (kullanıcı isteği 2026-11-16) — bölümleri
      // boş kalınca hiç çizilmez. Sıralı liste birincil satırda.
      expect(find.byKey(const ValueKey('quick-section-pen')), findsNothing);
      expect(find.byKey(const ValueKey('quick-section-files')), findsNothing);
      final camera = tester.getRect(
        find.byKey(const ValueKey('quick-section-camera')),
      );
      final template = tester.getRect(
        find.byKey(const ValueKey('quick-section-template')),
      );
      expect(text.center.dy, lessThan(template.center.dy));
      expect(template.center.dy, lessThan(camera.center.dy));
      expect(
        tester.getRect(find.text('Sıralı liste')).center.dy,
        closeTo(text.center.dy, 1),
      );
      // Seçenekler PANELDE — kapı levhası yok, tek dokunuşla çalışır.
      expect(find.text('Akıllı liste'), findsOneWidget);
      expect(find.text('Dosya ekle'), findsNothing);
      expect(find.text('YouTube videosu'), findsNothing);

      await tester.tap(find.text('Akıllı liste'));
      await tester.pumpAndSettle();
      expect(find.text('Metin notu'), findsNothing, reason: 'panel kapanır');
      expect(calls, ['smartlist']);

      // Metin notu tek dokunuş.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Metin notu'));
      await tester.pumpAndSettle();
      expect(calls, ['smartlist', 'text']);
    },
  );
}

class _FabHost extends ConsumerStatefulWidget {
  const _FabHost(this.calls);

  final List<String> calls;

  @override
  ConsumerState<_FabHost> createState() => _FabHostState();
}

class _FabHostState extends ConsumerState<_FabHost>
    with QuickAddActions<_FabHost> {
  final _link = LayerLink();

  @override
  String? get quickAddFolderId => null;

  @override
  Future<void> openNewNote(
    String id, {
    String query = '',
    NoteType? type,
  }) async {}

  @override
  Future<void> createNote(NoteType type) async => widget.calls.add(type.name);

  @override
  Future<void> createSmartList() async => widget.calls.add('smartlist');

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(
      alignment: Alignment.bottomRight,
      child: CompositedTransformTarget(
        link: _link,
        child: QuickAddFab(anchor: _link, actions: () => this),
      ),
    ),
  );
}
