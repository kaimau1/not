import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/presentation/filter_sheet.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Süz levhasının seçenekleri ÇİP gibi yan yana akmalı.
///
/// KÖK NEDEN (kullanıcı: "süz alanı kullanışlı değil"): seçenek kutusunda
/// `alignment: Alignment.center` vardı. Wrap çocuklarına gevşek kısıt verir ve
/// hizalaması olan bir kutu gevşek kısıtta eldeki en geniş ölçüyü alır — her
/// seçenek satırın tamamını kaplıyordu. Dokuz süzgeç + klasörler + etiketler +
/// beş sıralama alt alta dizilince levha ekranlarca uzuyor, aranan seçeneğe
/// ulaşmak için kaydırmak gerekiyordu.
void main() {
  testWidgets('süzgeç seçenekleri aynı satırda yan yana durur', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Firebase'e hiç gidilmesin: levha yalnız süzgeç seçeneklerini
          // çizecek, not/klasör listesi boş yeter.
          notesStreamProvider.overrideWith((ref) => Stream.value(const <Note>[])),
          foldersStreamProvider.overrideWith(
            (ref) => Stream.value(const <NoteFolder>[]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showFilterSheet(context),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    final all = tester.getRect(find.text('Tümü'));
    final text = tester.getRect(find.text('Metin'));

    // Tam genişlik kutularda ikisi ALT ALTA düşerdi; çip akışında aynı satırda
    // ve soldan sağa sıralı olurlar.
    expect(
      all.center.dy,
      closeTo(text.center.dy, 1),
      reason: '"Tümü" ile "Metin" aynı satırda olmalı',
    );
    expect(all.center.dx, lessThan(text.center.dx));
  });

  // KT-2 (keşif turu 2026-11-14; KARAR 1.0): masaüstünde (1440) levha 1240 px
  // yayılıyordu. KÖK NEDEN: levhaya yalnız maxHeight veren `constraints`
  // M3'ün varsayılan 640 dp genişlik sınırını EZİYORDU (maxWidth sonsuz).
  // Geniş ekranda levha ortada, en çok 560 dp.
  testWidgets('geniş ekranda levha ortada, en çok 560 dp (KT-2)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notesStreamProvider.overrideWith((ref) => Stream.value(const <Note>[])),
          foldersStreamProvider.overrideWith(
            (ref) => Stream.value(const <NoteFolder>[]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showFilterSheet(context),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    // BottomSheet kendisi tam genişlik; sınır içteki levha yüzeyinde.
    final sheet = tester.getRect(
      find
          .descendant(of: find.byType(BottomSheet), matching: find.byType(Material))
          .first,
    );
    expect(sheet.width, lessThanOrEqualTo(560));
    expect(sheet.center.dx, closeTo(720, 1));
  });

  // Kullanıcı bulgusu 2026-11-27: "üstteki tutamacından tutup aşağı çekip
  // kapatamıyorum, sadece geri tuşuyla kapanıyor". KÖK NEDEN: kapsül
  // kaydırma alanının İÇİNDEYDİ; sürükleme levhaya değil kaydırmaya gidiyordu.
  testWidgets('tutamaktan aşağı çekince levha kapanır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notesStreamProvider.overrideWith((ref) => Stream.value(const <Note>[])),
          foldersStreamProvider.overrideWith(
            (ref) => Stream.value(const <NoteFolder>[]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showFilterSheet(context),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('Görünüm ve süz'), findsOneWidget);
    // Öbür menüler gibi M3 tutamağı var.
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
    );
    await tester.drag(find.text('Görünüm ve süz'), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Görünüm ve süz'), findsNothing);
  });
}
