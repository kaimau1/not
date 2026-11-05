import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_status.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// F40.4: tek ek durum dili.
void main() {
  const a = Attachment(
    id: 'a',
    kind: AttachmentKind.image,
    fileName: 'a.jpg',
    mimeType: 'image/jpeg',
  );

  AttachmentStatus of(
    Attachment x, {
    bool local = false,
    bool foreign = false,
    bool web = false,
    bool up = false,
    int fails = 0,
    int limit = 0,
    bool textOnly = false,
  }) => attachmentStatusOf(
    x,
    hasLocal: local,
    foreign: foreign,
    web: web,
    uploading: up,
    failedAttempts: fails,
    limitMb: limit,
    textOnly: textOnly,
  );

  test('cihazda var, bulutta yok', () {
    expect(of(a, local: true), AttachmentStatus.queued);
    expect(of(a, local: true, up: true), AttachmentStatus.uploading);
    expect(of(a, local: true, fails: 3), AttachmentStatus.failed);
    expect(of(a, local: true, textOnly: true), AttachmentStatus.none);
    final big = a.copyWith(sizeBytes: 3 * 1024 * 1024);
    expect(
      of(big, local: true, limit: 2, fails: 9),
      AttachmentStatus.overLimit,
    );
    const video = Attachment(id: 'v', kind: AttachmentKind.video, fileName: 'v.mp4', mimeType: 'video/mp4');
    expect(of(video, local: true), AttachmentStatus.none);
  });

  test('cihazda yok', () {
    expect(of(a), AttachmentStatus.notSynced);
    expect(of(a, foreign: true), AttachmentStatus.waitingOwner);
    expect(of(a, web: true), AttachmentStatus.onPhone);
    expect(of(a.copyWith(driveId: 'd')), AttachmentStatus.none);
    expect(of(a.copyWith(downloadUrl: 'https://x')), AttachmentStatus.none);
  });

  testWidgets('rozete dokununca açıklama levhası + yeniden dene', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: Center(
            child: AttachmentStatusBadge(
              status: AttachmentStatus.failed,
              onRetry: () => retried = true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('attachment-status-failed')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('attachment-status-sheet')),
      findsOneWidget,
    );
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(retried, isTrue);
  });
}
