import 'package:flutter/widgets.dart';

import '../../../../core/utils/attachment_tag.dart';
import 'text_wrap.dart';

/// Bir metin alanına yapılan SON dokunuşun ekran konumu.
///
/// `TextField.onTap` konum taşımaz; etikete dokunulup dokunulmadığını
/// yalnız imlecin düştüğü yerden anlamak sınırda yanılıyordu (aşağıya bak).
/// Alan bir [Listener] ile sarılır, basışın konumu burada tutulur.
class TapPointTracker {
  Offset? last;

  Widget wrap(Widget child) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) => last = event.position,
    child: child,
  );
}

/// [context]in altındaki İLK düzenlenebilir alanın durumu (yoksa null).
/// Alanın kendi `Builder`ı içinden çağrılır ki başka bir alan bulunmasın.
EditableTextState? editableTextBelow(BuildContext context) {
  EditableTextState? found;
  void visit(Element element) {
    if (found != null) return;
    if (element is StatefulElement && element.state is EditableTextState) {
      found = element.state as EditableTextState;
      return;
    }
    element.visitChildren(visit);
  }

  if (context is Element) context.visitChildren(visit);
  return found;
}

/// Dokunuşun düştüğü EK ETİKETİ (yoksa null).
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-15, ekran görüntüsü: gömülü
/// "📎 düzeltilmeli" kelimesine dokununca önizleme yerine "Yapıştır / Tümünü
/// seç / Tüm notu kopyala" menüsü): dokunuş yalnız imlecin konumuyla
/// değerlendiriliyordu ve imleç etiketin SINIRINDA ise sayılmıyordu (yanına
/// imleç koymak yazmaya devam etmektir — kural doğru). Ama son harfin sağ
/// yarısına dokunmak da imleci SINIRA koyar: kullanıcı kelimenin TAM
/// üstüne dokunduğu hâlde önizleme açılmıyordu.
///
/// Artık sınırda DOKUNUŞUN KONUMUNA bakılır: parmak etiketin çizildiği
/// kutulardan birinin içindeyse etikete dokunulmuştur; etiketin yanındaki
/// boşluğa/sonraki kelimeye dokunmak eskisi gibi yazmaya devam eder.
///
/// [logicalText]/[logicalCaret] sarma çapalarından arındırılmış metin ve
/// imleç; [displayText] alanın gerçek (çapalı) metni — kutular onun
/// konumlarıyla ölçülür.
({int start, int end, String fileName})? tappedAttachmentTag({
  required String logicalText,
  required int logicalCaret,
  required String displayText,
  required TextSelection selection,
  required Iterable<String> names,
  EditableTextState? editable,
  Offset? tapGlobal,
}) {
  if (!selection.isValid || !selection.isCollapsed) return null;
  final inside = attachmentTagInside(logicalText, logicalCaret, names);
  if (inside != null) return inside;
  if (editable == null || tapGlobal == null) return null;
  final caret = selection.baseOffset;
  for (final tag in findAttachmentTags(displayText, names)) {
    if (caret != tag.start && caret != tag.end) continue;
    final render = editable.renderEditable;
    if (!render.attached || !render.hasSize) return null;
    final local = render.globalToLocal(tapGlobal);
    final boxes = render.getBoxesForSelection(
      TextSelection(baseOffset: tag.start, extentOffset: tag.end),
    );
    for (final box in boxes) {
      if (box.toRect().inflate(2).contains(local)) {
        return (
          start: wrapToLogicalOffset(displayText, tag.start),
          end: wrapToLogicalOffset(displayText, tag.end),
          fileName: tag.fileName,
        );
      }
    }
    return null;
  }
  return null;
}

/// Seçim menüsünün SIRASI — gövde, başlık ve madde satırları için tek kural.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-15: "metin seçim mantığı ve kalitesi
/// düzeltilmeli"): menü iki ayrı yerde kuruluyordu ve ikisi farklıydı.
/// Gövdede "Seçili yazıya ek göm", etiket önizlemesi ve "Bağlantıyı aç"
/// vardı; madde satırında yoktu (yalnız Biçim ve Tüm notu kopyala). Gövdede
/// de uzun bir "Seçili yazıya ek göm" listenin BAŞINA ekleniyor, Android'in
/// dar çubuğunda Kopyala/Yapıştır taşma menüsüne (⋮) itiliyordu; Biçim ise
/// platformun "Paylaş"ından sonra, hep ⋮'nin içinde kalıyordu.
///
/// Sıra: bağlama özgü TEK birincil iş (bağlantıyı aç / buraya bağla /
/// önizle) → Kes · Kopyala · Yapıştır (platformun kendi sırası) → bizim
/// işlerimiz (Biçim, Ek göm…) → Tümünü seç → platformun ek işleri (Paylaş,
/// Web'de ara…) → en sonda [trailing] (Tüm notu kopyala).
List<ContextMenuButtonItem> arrangeSelectionMenu({
  required List<ContextMenuButtonItem> platform,
  List<ContextMenuButtonItem> leading = const [],
  List<ContextMenuButtonItem> afterClipboard = const [],
  List<ContextMenuButtonItem> trailing = const [],
}) {
  const clipboard = {
    ContextMenuButtonType.cut,
    ContextMenuButtonType.copy,
    ContextMenuButtonType.paste,
  };
  return [
    ...leading,
    for (final item in platform)
      if (clipboard.contains(item.type)) item,
    ...afterClipboard,
    for (final item in platform)
      if (item.type == ContextMenuButtonType.selectAll) item,
    for (final item in platform)
      if (!clipboard.contains(item.type) &&
          item.type != ContextMenuButtonType.selectAll)
        item,
    ...trailing,
  ];
}
