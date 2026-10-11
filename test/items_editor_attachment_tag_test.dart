import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// **MADDE SATIRINDAKİ EK ETİKETİ** (kullanıcı bulgusu 2026-09-01, ekran
/// görüntüsüyle: "ek bağlama … ataç işareti geliyor ama tamamen işlevsiz,
/// yazıya bağlanmıyor, altı çizilmesi gerekiyor, basınca bir şey olmuyor").
///
/// KÖK NEDEN: etiketi kırmızı + altı çizili çizen ve dokunuşu eke bağlayan yol
/// yalnız GÖVDE alanında kuruluydu. Editör `_bodyController.attachmentNames`i
/// besliyor, madde satırlarının denetleyicilerine hiçbir şey vermiyordu — bir
/// LİSTE notunda "Buraya bağla" düz yazı bırakıyordu.
void main() {
  Future<WrapTextController> pumpRow(
    WidgetTester tester, {
    required List<String> names,
    void Function(String)? onTag,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ItemsEditor(
            items: const [NoteItem(id: 'a', text: '📎 rapor.pdf')],
            onChanged: (_) {},
            showCheckboxes: true,
            attachmentNames: names,
            onAttachmentTag: onTag,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(find.byType(EditableText).first);
    return field.controller as WrapTextController;
  }

  testWidgets('ek adları madde denetleyicisine kadar iner', (tester) async {
    final controller = await pumpRow(tester, names: ['rapor.pdf']);
    expect(controller.attachmentNames, ['rapor.pdf']);
  });

  testWidgets('etiket ayrı bir span olarak çizilir (kırmızı + altı çizili)', (
    tester,
  ) async {
    final controller = await pumpRow(tester, names: ['rapor.pdf']);
    final span = controller.buildTextSpan(
      context: tester.element(find.byType(EditableText).first),
      withComposing: false,
    );
    // Metnin TAMAMI etiket olduğunda span tek parçadır (çocuk listesi yok);
    // etiketin ortasında düz yazı varsa çocuklara bölünür. İki hâli de aynı
    // sınavdan geçsin diye ağaç düzleştirilir.
    final underlined = <String>[];
    void walk(InlineSpan node) {
      if (node is TextSpan) {
        if (node.text != null &&
            node.style?.decoration == TextDecoration.underline) {
          underlined.add(node.text!);
        }
        for (final child in node.children ?? const <InlineSpan>[]) {
          walk(child);
        }
      }
    }

    walk(span);
    expect(underlined, contains('📎 rapor.pdf'));
  });

  testWidgets('etikete dokunmak eki bildirir', (tester) async {
    String? opened;
    await pumpRow(
      tester,
      names: ['rapor.pdf'],
      onTag: (name) => opened = name,
    );
    // Dokunuş etiketin YAZISINA düşmeli (2026-10-11 gömme yeniden tasarımı:
    // etiketin bittiği yerin sağına dokunmak imleci etiketin DIŞINA koyar —
    // orası yazmaya devam etmektir, önizleme açmaz).
    final field = tester.getRect(find.byType(EditableText).first);
    await tester.tapAt(Offset(field.left + 40, field.center.dy));
    await tester.pumpAndSettle();
    expect(opened, 'rapor.pdf');
  });

  testWidgets('etiketin SAĞINA dokunmak önizleme açmaz', (tester) async {
    String? opened;
    await pumpRow(
      tester,
      names: ['rapor.pdf'],
      onTag: (name) => opened = name,
    );
    final field = tester.getRect(find.byType(EditableText).first);
    await tester.tapAt(Offset(field.right - 4, field.center.dy));
    await tester.pumpAndSettle();
    expect(opened, isNull);
  });

  testWidgets('adı bilinmeyen ataç düz yazıdır, dokunuş bir şey yapmaz', (
    tester,
  ) async {
    String? opened;
    await pumpRow(tester, names: const [], onTag: (name) => opened = name);
    await tester.tap(find.byType(EditableText).first);
    await tester.pumpAndSettle();
    expect(opened, isNull);
  });
}
