import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ana ekran kartlarında satır içi biçim (Ayarlar → Görünüm → "Kartlarda
/// biçimli metin").
///
/// KULLANICI İSTEĞİ (2026-08-07): "dashboardta notların renklendirme altını
/// çizme vs görülebilir olsun ama bu ayar olarak ayarlarda bulunsun".
/// Kart önizlemesi eskiden biçimi [stripRichMarkers] ile söküyordu; artık
/// ayar AÇIKken biçim çiziliyor, KAPALIYKEN eski düz görünüm geri geliyor.
/// Her iki durumda da ham işaret (`**`, `%%2:`) EKRANDA GÖRÜNMEMELİ.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final note = Note(
    id: 'n1',
    type: NoteType.text,
    title: 'Başlık',
    body: 'düz **kalın** ve ~altı~ ve %%3:renkli%% metin',
    updatedAt: DateTime(2026, 8, 7),
  );

  Future<void> pumpCard(WidgetTester tester, {required bool rich}) async {
    await prefs.setBool('card_rich_preview', rich);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: SizedBox(width: 300, child: NoteCard(note: note)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Kartta çizilen bütün metin parçaları: (metin, stil).
  List<(String, TextStyle?)> spans(WidgetTester tester) {
    final out = <(String, TextStyle?)>[];
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final span = text.textSpan;
      if (span == null) {
        if (text.data != null) out.add((text.data!, text.style));
        continue;
      }
      span.visitChildren((child) {
        if (child is TextSpan && (child.text ?? '').isNotEmpty) {
          out.add((child.text!, child.style));
        }
        return true;
      });
    }
    return out;
  }

  testWidgets('ayar AÇIK: biçim çizilir, işaret görünmez', (tester) async {
    await pumpCard(tester, rich: true);
    final drawn = spans(tester);

    final bold = drawn.where((s) => s.$1 == 'kalın');
    expect(bold, isNotEmpty, reason: 'kalın parça ayrı bir span olmalı');
    expect(bold.first.$2?.fontWeight, FontWeight.w700);

    final underline = drawn.where((s) => s.$1 == 'altı');
    expect(underline, isNotEmpty);
    expect(underline.first.$2?.decoration, TextDecoration.underline);

    final colored = drawn.where((s) => s.$1 == 'renkli');
    expect(colored, isNotEmpty);
    // Palet 3 = yeşil; gövdenin kendi rengi değil, o renk uygulanmalı.
    expect(colored.first.$2?.color, isNot(isNull));

    // İşaretler METİNDE durur ama GÖRÜNMEZ çizilir (saydam + ~0 punto).
    for (final s in drawn.where(
      (s) => s.$1.contains('**') || s.$1.contains('%%'),
    )) {
      expect(s.$2?.color?.a, 0, reason: 'işaret saydam çizilmeli: ${s.$1}');
    }
  });

  testWidgets('ayar KAPALI: düz metin, ham işaret yok', (tester) async {
    await pumpCard(tester, rich: false);
    final drawn = spans(tester);
    final joined = drawn.map((s) => s.$1).join();

    expect(joined, contains('düz kalın ve altı ve renkli metin'));
    expect(joined, isNot(contains('**')));
    expect(joined, isNot(contains('%%')));
    // Biçim çizilmediği için kalın bir parça da olmamalı.
    expect(
      drawn.where(
        (s) => s.$2?.fontWeight == FontWeight.w700 && s.$1 != 'Başlık',
      ),
      isEmpty,
    );
  });
}
