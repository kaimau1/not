import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_version.dart';
import 'package:notlar/features/notes/presentation/editor/note_history_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

import 'support/editor_harness.dart' show CountingNotesRepository;

/// Sürüm okumalarını sayan depo.
class _Repo extends CountingNotesRepository {
  int reads = 0;

  @override
  Future<List<NoteVersion>> listVersions(String noteId) {
    reads++;
    return Future.value(const []);
  }
}

/// T7 / K-58 (kasma envanteri): sürüm geçmişi levhasının builder'ı
/// `repo.listVersions`'u HER çağrıda yeniden başlatıyordu; levha yeniden
/// kurulunca (ekran boyu/dönme, klavye payı) Firestore'dan 30 sürüm baştan
/// okunuyor, liste bekleme çarkına dönüyordu.
void main() {
  testWidgets('levha yeniden kurulunca sürümler yeniden okunmaz', (
    tester,
  ) async {
    final repo = _Repo();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showNoteHistorySheet(context, repo, 'n'),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(repo.reads, 1);
    // Ekran boyu değişti (dönme / pencere): levha builder'ı yeniden koşar.
    for (final h in [700.0, 650.0, 800.0]) {
      tester.view.physicalSize = Size(400, h);
      tester.view.devicePixelRatio = 1;
      await tester.pump();
    }
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    expect(repo.reads, 1, reason: 'aynı levhada tek okuma');
    expect(find.text('Sürüm geçmişi'), findsOneWidget);
  });
}
