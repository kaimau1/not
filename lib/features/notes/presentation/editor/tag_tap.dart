import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';

import '../../../../core/utils/attachment_tag.dart';
import '../../../../core/utils/video_time.dart';
import 'text_wrap.dart';

/// Bir metin alanına yapılan SON dokunuşun ekran konumu.
///
/// `TextField.onTap` konum taşımaz; etikete dokunulup dokunulmadığını
/// yalnız imlecin düştüğü yerden anlamak sınırda yanılıyordu (aşağıya bak).
/// Alan bir [Listener] ile sarılır, basışın konumu burada tutulur.
class TapPointTracker {
  Offset? last;

  /// Bu dokunuş süresince odak alması engellenen alan (bkz. [wrap]).
  FocusNode? _blocked;
  Timer? _release;

  /// Uzun basış bu süreyi aşınca engel kalkar: damgaya/etikete BASILI
  /// TUTMAK onu seçip düzenlemek demektir, klavye açılabilir.
  static const _holdRelease = Duration(milliseconds: 380);

  /// [focusNode] ve [keepsKeyboardClosed] verilirse: ODAKSIZ alanda parmak
  /// bir BAĞLANTININ (video zaman damgası, gömülü ek) üstüne inince bu
  /// dokunuş alanı odaklamaz — klavye hiç açılmaz.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-16: "videoda dk üzerine tıklayınca
  /// klavye açılıyor"): damga `TextField.onTap`te işleniyordu ve o geri
  /// çağırma alanın kendi dokunuş işleminden SONRA koşar — o sırada
  /// `requestKeyboard` odağı çoktan istemiş, klavye açılmış oluyordu. Karar
  /// PARMAK İNERKEN verilir: odak düğümünün `canRequestFocus`u bu dokunuşun
  /// sonuna dek kapatılır; alan imleci yine taşır (onTap damgayı oradan
  /// okur) ama odaklanamaz. Zaten odaktaki alana (yazarken) dokunulmaz.
  Widget wrap(
    Widget child, {
    FocusNode? focusNode,
    bool Function(Offset global)? keepsKeyboardClosed,
  }) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      last = event.position;
      if (focusNode == null ||
          keepsKeyboardClosed == null ||
          event.kind == PointerDeviceKind.mouse ||
          focusNode.hasFocus ||
          !focusNode.canRequestFocus) {
        return;
      }
      if (!keepsKeyboardClosed(event.position)) return;
      _unblock();
      _blocked = focusNode..canRequestFocus = false;
      _release = Timer(_holdRelease, _unblock);
    },
    // Dokunuşun kendisi (seçim, onTap) parmak kalktığı olayın içinde işlenir;
    // engel ondan SONRA, bir sonraki turda kalkar.
    onPointerUp: (_) => _releaseSoon(),
    onPointerCancel: (_) => _releaseSoon(),
    child: child,
  );

  void _releaseSoon() {
    if (_blocked == null) return;
    _release?.cancel();
    _release = Timer(Duration.zero, _unblock);
  }

  void _unblock() {
    _release?.cancel();
    _release = null;
    final node = _blocked;
    _blocked = null;
    node?.canRequestFocus = true;
  }
}

/// [global] noktasının altında bir VİDEO ZAMAN DAMGASI ya da GÖMÜLÜ EK
/// etiketi var mı — parmak inerken (dokunuş işlenmeden önce) sorulur, bkz.
/// [TapPointTracker.wrap].
bool linkAtPoint({
  required EditableTextState? editable,
  required String displayText,
  required Offset global,
  bool timestamps = false,
  Iterable<String> tagNames = const [],
}) {
  if (editable == null) return false;
  final render = editable.renderEditable;
  if (!render.attached || !render.hasSize) return false;
  final local = render.globalToLocal(global);
  bool hits(int start, int end, double slack) {
    final boxes = render.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: end),
    );
    for (final box in boxes) {
      if (box.toRect().inflate(slack).contains(local)) return true;
    }
    return false;
  }

  final offset = render.getPositionForPoint(global).offset;
  if (timestamps) {
    final hit = videoTimestampAt(displayText, offset);
    if (hit != null && hits(hit.start, hit.end, 3)) return true;
  }
  if (tagNames.isNotEmpty) {
    for (final tag in findAttachmentTags(displayText, tagNames)) {
      if (offset < tag.start || offset > tag.end) continue;
      if (hits(tag.start, tag.end, 2)) return true;
    }
  }
  return false;
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

/// Dokunuşun düştüğü VİDEO ZAMAN DAMGASI (saniye; yoksa null).
///
/// Etiketteki kuralın aynısı: imleç damganın İÇİNDEYSE ya da sınırındayken
/// parmak damganın çizildiği kutudaysa damgaya dokunulmuştur. Damganın
/// yanına imleç koymak yazmaya devam etmektir — sayfayı sarmaz.
int? tappedVideoTimestamp({
  required String displayText,
  required TextSelection selection,
  EditableTextState? editable,
  Offset? tapGlobal,
}) {
  if (!selection.isValid || !selection.isCollapsed) return null;
  final caret = selection.baseOffset;
  final hit = videoTimestampAt(displayText, caret);
  if (hit == null) return null;
  if (caret > hit.start && caret < hit.end) return hit.seconds;
  if (editable == null || tapGlobal == null) return null;
  final render = editable.renderEditable;
  if (!render.attached || !render.hasSize) return null;
  final local = render.globalToLocal(tapGlobal);
  final boxes = render.getBoxesForSelection(
    TextSelection(baseOffset: hit.start, extentOffset: hit.end),
  );
  for (final box in boxes) {
    if (box.toRect().inflate(3).contains(local)) return hit.seconds;
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
