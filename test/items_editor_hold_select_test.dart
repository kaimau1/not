import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// F60.S6 — maddeye uzun basış (≈500 ms) metni seçer (bugünkü davranış);
/// parmak kalkmadan ≈ +600 ms daha basılı kalırsa metin seçimi kalkar ve
/// o madde madde seçim kipine girer.
void main() {
  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ItemsEditor(
            items: [
              for (var i = 0; i < 5; i++)
                NoteItem(id: 'i$i', text: 'Madde numara $i'),
            ],
            onChanged: (_) {},
            showCheckboxes: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ItemsEditorState editor(WidgetTester tester) =>
      tester.state<ItemsEditorState>(find.byType(ItemsEditor));

  /// Satır 1'in İLK sözcüğünün üstü (alan geniş; ortası yazının sağındaki
  /// boşluğa düşer).
  Offset textPoint(WidgetTester tester) {
    final r = tester.getRect(find.text('Madde numara 1', findRichText: true));
    return Offset(r.left + 20, r.center.dy);
  }

  /// Satır 1'in metni üzerinde basılı tutar; [hold] kadar bekleyip bırakır.
  Future<void> holdOnItem(WidgetTester tester, Duration hold) async {
    final at = textPoint(tester);
    final gesture = await tester.startGesture(at);
    // Kareleri adım adım ilerlet: uzun basış (500 ms) metin alanını
    // gerçek TextField'a çevirir, kelime seçimi kare sonrası uygulanır.
    var waited = Duration.zero;
    const step = Duration(milliseconds: 50);
    while (waited < hold) {
      await tester.pump(step);
      waited += step;
    }
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('uzun bas + bekle (1200 ms) → madde seçim kipi, o madde seçili', (
    tester,
  ) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpEditor(tester);
    await holdOnItem(tester, const Duration(milliseconds: 1200));

    expect(editor(tester).isSelecting, isTrue);
    expect(find.text('1 madde seçildi'), findsOneWidget);
    // Metin seçimi temizlendi: hiçbir alan seçili metin taşımıyor.
    for (final f in tester.widgetList<EditableText>(
      find.byType(EditableText),
    )) {
      expect(
        f.controller.selection.isCollapsed || !f.controller.selection.isValid,
        isTrue,
      );
    }
    // Uzun basışın kendi titreşimi ayrı; geçişin hafif titreşimi de geldi.
    expect(haptics, contains('HapticFeedbackType.lightImpact'));
    // Metin seçim araç çubuğu da açık kalmadı.
    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
  });

  testWidgets('düz çizilen (tembel) maddede de basılı tutma madde seçer', (
    tester,
  ) async {
    debugEagerItemFields = false;
    addTearDown(() => debugEagerItemFields = true);
    await pumpEditor(tester);
    expect(find.byType(EditableText), findsNothing);
    await holdOnItem(tester, const Duration(milliseconds: 1200));

    expect(editor(tester).isSelecting, isTrue);
    expect(find.text('1 madde seçildi'), findsOneWidget);
    for (final f in tester.widgetList<EditableText>(
      find.byType(EditableText),
    )) {
      expect(
        f.controller.selection.isCollapsed || !f.controller.selection.isValid,
        isTrue,
      );
    }
    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
  });

  testWidgets('fare ile basılı tutma madde seçimine geçmez', (tester) async {
    await pumpEditor(tester);
    final gesture = await tester.startGesture(
      textPoint(tester),
      kind: PointerDeviceKind.mouse,
    );
    for (var i = 0; i < 26; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(editor(tester).isSelecting, isFalse);
  });

  testWidgets('600 ms’de bırakınca yalnız metin seçili, seçim kipi yok', (
    tester,
  ) async {
    await pumpEditor(tester);
    await holdOnItem(tester, const Duration(milliseconds: 600));

    expect(editor(tester).isSelecting, isFalse);
    final selected = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .where(
          (f) =>
              f.controller.selection.isValid &&
              !f.controller.selection.isCollapsed,
        );
    expect(selected, isNotEmpty);
  });

  testWidgets('basılıyken kayan parmak madde seçimine geçmez', (tester) async {
    await pumpEditor(tester);
    final at = textPoint(tester);
    final gesture = await tester.startGesture(at);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    // Uzun basıştan sonra seçim tutamacı gibi sürükleme: eşiği aşar.
    await gesture.moveBy(const Offset(60, 0));
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(editor(tester).isSelecting, isFalse);
  });
}
