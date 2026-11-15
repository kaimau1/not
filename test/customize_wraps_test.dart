import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/widgets/customizable.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/attach_sheet.dart';
import 'package:notlar/features/notes/presentation/editor/editor_quick_row.dart';
import 'package:notlar/features/notes/presentation/editor/video_hub_scope.dart';
import 'package:notlar/features/notes/presentation/editor/video_transport.dart';
import 'package:notlar/core/utils/video_time.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// P63 PB7 (plan_tasarim_B §7.9): hızlı satır `quickOrder`, Ekle levhası
/// `attachOrder` sırasında; video hız/süre düzen modunda çerçeveli, normal
/// kipte gizliyse yok. Kayıt boşken varsayılan düzen (ayraçlı) aynen.
void main() {
  setUp(Personalize.debugReset);
  tearDown(Personalize.debugReset);

  Widget app(Widget body) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: Scaffold(body: body),
  );

  Widget row() => EditorQuickRow(
    onBold: () {},
    onBullet: () {},
    onCheckbox: () {},
    onHeading: () {},
    onPhoto: () {},
    onFile: () {},
    onPen: null,
    onPenSettings: null,
    onReminder: () {},
    onSpell: () {},
    onPackage: () {},
  );

  double dx(WidgetTester tester, String key) =>
      tester.getCenter(find.byKey(ValueKey('quick-row-$key'))).dx;

  testWidgets('hızlı satır kullanıcı sırasında (quickOrder)', (tester) async {
    await tester.pumpWidget(app(row()));
    // Varsayılan görünenler (sade): yazım, paket, kalın.
    expect(dx(tester, 'spell'), lessThan(dx(tester, 'bold')));
    Personalize.update((p) => p.copyWith(quickOrder: ['bold', 'spell']));
    await tester.pump();
    expect(dx(tester, 'bold'), lessThan(dx(tester, 'spell')));
    expect(dx(tester, 'spell'), lessThan(dx(tester, 'package')));
  });

  testWidgets('Ekle levhası kullanıcı sırasında (attachOrder)', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAttachSheet(context),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    double x(IconData icon) => tester.getCenter(find.byIcon(icon).last).dx;
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(
      x(Icons.photo_camera_outlined),
      lessThan(x(Icons.videocam_outlined)),
    );
    Navigator.of(tester.element(find.byIcon(Icons.videocam_outlined).last))
        .pop();
    await tester.pumpAndSettle();

    Personalize.update((p) => p.copyWith(attachOrder: ['video', 'camera']));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(
      x(Icons.videocam_outlined),
      lessThan(x(Icons.photo_camera_outlined)),
    );
  });

  testWidgets('video hızı: gizliyken yok, düzen modunda çerçeveli', (
    tester,
  ) async {
    Personalize.prefs.value = const UiPrefs(hidden: {UiItem.videoSpeed});
    final hub = NoteVideoHub();
    hub.register(_FakeSource('v'));
    const video = Attachment(
      id: 'v',
      kind: AttachmentKind.video,
      fileName: 'v.mp4',
      mimeType: 'video/mp4',
    );
    await tester.pumpWidget(
      app(
        VideoHubScope(
          hub: hub,
          child: const VideoTransportControls(video: video, showSpeed: true),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('video-speed')), findsNothing);
    Personalize.startEditing();
    await tester.pump();
    expect(find.byKey(const ValueKey('video-speed')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('video-speed')),
        matching: find.byType(CustomizeFrame),
      ),
      findsOneWidget,
    );
  });
}

class _FakeSource extends VideoTimeSource {
  _FakeSource(this.attachmentId);

  @override
  final String attachmentId;

  final _changes = ValueNotifier<int>(0);

  @override
  Listenable get changes => _changes;

  @override
  Duration? get lastPosition => const Duration(seconds: 83);

  @override
  Duration? get duration => const Duration(minutes: 4);

  @override
  Future<Duration?> position() async => lastPosition;

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> seekBy(Duration delta) async {}
}
