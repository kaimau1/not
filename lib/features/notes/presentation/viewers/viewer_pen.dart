import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../editor/page_ink_layer.dart' show InkClaim;
import '../editor/stylus_toggle.dart';
import 'bubble_layer.dart';
import 'ink_layer.dart';
import 'ink_tools.dart';
import 'pen_policy.dart';

/// **TAM EKRAN GÖRÜNTÜLEYİCİDE KALEM KURALI** (OTURTMA F63.4, KALEM K3):
/// PDF / görsel / slayt tam ekranı ayrı rota olduğu için editörün yüzen
/// "kalem yazar / dokunur" düğmesi orada yoktu ve kalem ancak çizim
/// düğmesine basınca yazıyordu. Üç ekran bu karışımı kullanır:
///
/// * [penScope] — gövdeyi sarar: yüzen düğme + kalemin İLK görülüşü
///   ([InkToolMemory.stylusEver]; çizim kipi kapalıyken mürekkep katmanı
///   dokunuş almadığından burada dinlenir).
/// * [penLayer] — sayfa katmanı: çizim kipi kapalıyken [InkClaim] ile (kalem
///   yazar, parmak gezinir/yakınlaştırır); kip açıkken eskisi gibi.
/// * [syncPen] — kural ([PenPolicy], yüzey `viewer`) denetleyiciye yazılır.
mixin ViewerPen<T extends StatefulWidget> on State<T> {
  InkController get penInk;
  BubbleController get penBubbles;

  /// Çizim kipi (araç çubuğundaki kalem düğmesi).
  bool get penEditing;

  /// Belge yazılabilir mi (`onChanged != null`).
  bool get penAllowed;

  /// Tek parmağı başka bir kip bekliyor (alan seçimi): kalem kapalı.
  bool get penBlocked => false;

  /// Yüzen düğme "kalem dokunur"a geçti: açık çizim kipi kapanır.
  void penStopEditing();

  PenPolicy get penPolicy => PenPolicy.resolve(
    surface: PenSurface.viewer,
    penMode: penEditing,
    autoStylus: InkToolMemory.autoStylus,
    stylusEver: InkToolMemory.stylusEver,
    penOnly: InkToolMemory.penOnly,
  );

  /// Kip, yüzen düğme ya da balon bırakma kipi değişince çağrılır.
  void syncPen() {
    final policy = penPolicy;
    penInk.allowedKinds = policy.allowedKinds;
    // Kip kapalıyken kalemin tek tıkı alttakine (balon tutamağı) geçer.
    penInk.passStylusTaps = !penEditing;
    penInk.setEditing(
      penAllowed && !penBlocked && !penBubbles.adding && policy.layerActive,
    );
  }

  void _onAutoStylus() {
    if (!mounted) return;
    if (!InkToolMemory.autoStylus && penEditing) {
      penStopEditing();
    } else {
      setState(() {});
    }
  }

  void _onBubbleAdding() {
    if (mounted) syncPen();
  }

  /// Ekranın her kip değişimi (çizim, alan seçimi, balon) `setState`ten
  /// geçer: kural orada yeniden yazılır — ekranların kendi
  /// `setEditing(...)` çağrılarından SONRA, son söz kuralın.
  @override
  void setState(VoidCallback fn) => super.setState(() {
    fn();
    syncPen();
  });

  @override
  void initState() {
    super.initState();
    InkToolMemory.autoStylusListenable.addListener(_onAutoStylus);
    penBubbles.addingListenable.addListener(_onBubbleAdding);
    syncPen();
  }

  @override
  void dispose() {
    // Balon denetleyicisi ekranla birlikte kapanır (dinleyici onunla gider).
    InkToolMemory.autoStylusListenable.removeListener(_onAutoStylus);
    super.dispose();
  }

  /// Gövdeyi sarar: yüzen düğme + kalemin ilk görülüşü.
  // ponytail: kalem cihazda İLK kez burada görülürse düğme belirirken gövde
  // bir kez yeniden kurulur (StylusToggleOverlay şekil değiştirir) — cihaz
  // başına tek sefer; rahatsız ederse örtü hep Stack olur.
  Widget penScope({required Widget child}) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      if (InkToolMemory.stylusEver ||
          (e.kind != PointerDeviceKind.stylus &&
              e.kind != PointerDeviceKind.invertedStylus)) {
        return;
      }
      InkToolMemory.noteStylusEver();
      setState(() {});
    },
    child: StylusToggleOverlay(
      visible: penAllowed && penPolicy.showFloatingToggle,
      child: child,
    ),
  );

  /// [page] sayfasının mürekkep katmanı.
  Widget penLayer(int page) {
    final layer = InkPageLayer(controller: penInk, page: page);
    // Çizim kipinde iki parmağı InkNavLayer işler; üstlenme yutmasın.
    return penEditing ? layer : InkClaim(ink: penInk, child: layer);
  }
}
