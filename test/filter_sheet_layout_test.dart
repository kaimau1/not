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
}
