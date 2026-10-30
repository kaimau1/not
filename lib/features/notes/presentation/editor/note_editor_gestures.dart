part of 'note_editor_screen.dart';

/// Jestler (kullanıcı isteği 2026-10-30): maddelerin üstüne çizilen jestler
/// KİPSİZ çalışır (ikinci tur: "jestler direkt çalışmalı, aktif edilmeden;
/// ayarlardan opsiyonel" — [itemGesturesProvider]); yalnız "Buraya bağla"da
/// daire içine alarak seçim bir örtü kipidir. Tanıma ve örtü
/// `ink_gestures.dart`ta; burada jestin NOTA etkisi.
enum _GestureMode { off, embedLasso }

extension _EditorGestures on _NoteEditorScreenState {
  void _setGestureMode(_GestureMode mode) {
    if (_gestureMode == mode) return;
    if (mode != _GestureMode.off) _dismissKeyboard();
    _update(() => _gestureMode = mode);
    if (mode == _GestureMode.embedLasso) {
      _showSnack(context.l10n.embedLassoHint);
    }
  }

  /// Örtünün iki parmak kaydırması için sayfanın kaydırıcısı.
  ScrollPosition? _gestureScrollPosition() {
    final context = _pageKey.currentContext;
    if (context == null) return null;
    return Scrollable.maybeOf(context)?.position;
  }

  /// Örtüden gelen çizgi.
  void _onGestureStroke(List<Offset> points) {
    if (_gestureMode == _GestureMode.embedLasso) _lassoEmbed(points);
  }

  /// BURAYA BAĞLA — DAİRE İÇİNE AL: halkanın kutusunun düştüğü alanda
  /// (gövde ya da madde) içindeki yazı seçilir ve bekleyen ek ona bağlanır.
  void _lassoEmbed(List<Offset> points) {
    final l10n = context.l10n;
    final root = _pageKey.currentContext;
    if (root == null || _pendingEmbed == null) return;
    final box = inkBounds(points);
    final state = editableTextAt(root, box.center, slop: box.height / 2);
    final selection = state == null
        ? null
        : selectionInside(state.renderEditable, box);
    final controller = state?.widget.controller;
    if (selection == null || controller is! WrapTextController) {
      _showSnack(l10n.embedLassoMissed);
      return;
    }
    final FormatTarget target;
    if (identical(controller, _bodyController)) {
      target = FormatTarget(
        controller: _bodyController,
        focusNode: _bodyFocus,
        commit: () => _mutate(
          (n) => n.copyWith(body: _bodyController.logicalText),
          immediate: true,
        ),
      );
    } else {
      final items = _itemsEditorKey.currentState;
      final id = items?.itemIdForController(controller);
      if (items == null || id == null) {
        _showSnack(l10n.embedLassoMissed);
        return;
      }
      target = FormatTarget(
        controller: controller,
        focusNode: state!.widget.focusNode,
        commit: () => items.replaceItemText(id, controller.logicalText),
      );
    }
    _update(() => _gestureMode = _GestureMode.off);
    HapticFeedback.selectionClick();
    _finishPendingEmbed(forcedTarget: target, forcedSelection: selection);
  }

  /// MADDE JESTİ: üstünü çiz / ✓ → işaretle (ya da işareti kaldır),
  /// karala → sil, daire → yazımı düzelt. Tanınmayan çizgi SESSİZ kalır:
  /// her dokunuş/kaydırma buradan geçiyor.
  void _applyItemGesture(List<Offset> points, InkGesture gesture) {
    final l10n = context.l10n;
    final items = _itemsEditorKey.currentState;
    if (gesture == InkGesture.none || items == null) return;
    final id = items.itemIdAt(inkBounds(points).center);
    if (id == null) return;
    switch (gesture) {
      case InkGesture.strike:
      case InkGesture.check:
        HapticFeedback.selectionClick();
        items.toggleCheckedOf(id);
      case InkGesture.scribble:
        HapticFeedback.mediumImpact();
        items.removeItemOf(id);
        _showSnack(l10n.gestureItemDeleted);
      case InkGesture.circle:
        HapticFeedback.selectionClick();
        unawaited(_fixItemSpelling(id));
      case InkGesture.none:
        break;
    }
  }

  /// Daire içine alınan maddenin YAZIMINI düzeltir (AI, yalnız imla/
  /// noktalama — kelimeye dokunmaz). Biçim işaretli madde düz metne iner.
  Future<void> _fixItemSpelling(String id) async {
    final l10n = context.l10n;
    final items = _itemsEditorKey.currentState;
    final original = items?.itemTextOf(id);
    if (items == null || original == null) return;
    final plain = stripRichMarkers(original).trim();
    if (plain.isEmpty) return;
    try {
      final fixed = await _runBusy(
        l10n.gestureFixing,
        () => ref
            .read(geminiServiceProvider)
            .rewriteText(
              plain,
              'Yalnızca yazım, imla, noktalama ve büyük/küçük harf '
              'hatalarını düzelt. Kelime seçimine ve sıraya DOKUNMA. Tek '
              'satır ver; madde imi, tırnak ya da açıklama ekleme.',
            ),
      );
      if (!mounted) return;
      final line = fixed.trim().split('\n').first.trim();
      // Madde bu arada değiştiyse (yazıldı, silindi) üstüne yazılmaz.
      if (line.isEmpty || items.itemTextOf(id) != original) return;
      if (line == plain) {
        _showSnack(l10n.gestureNothingToFix);
        return;
      }
      items.replaceItemText(id, line);
      _showSnack(l10n.gestureFixed);
    } catch (e) {
      if (mounted) _showSnack(l10n.aiError('$e'));
    }
  }

  /// İÇERİK ALANINA değen her işaretçi (parmak, kalem): maddenin üstünde
  /// başlayan TEK işaretçinin yolu toplanır, kalkınca jest mi diye bakılır.
  /// Dinleyici jest yarışına GİRMEZ (ham `Listener`): kaydırma, seçim,
  /// dokunuş olduğu gibi çalışır; bunlardan biri olduysa jest sayılmaz.
  /// true: çizgi maddede başladı (kalem el yazısı tuvalini açmasın).
  bool _trackGestureDown(PointerDownEvent event) {
    _contentPointers++;
    if (_contentPointers > 1) {
      // İkinci parmak: yakınlaştırma/kaydırma — jest değil.
      _gesturePointer = null;
      return false;
    }
    if (_readOnly || _gestureMode != _GestureMode.off) return false;
    if (!ref.read(itemGesturesProvider)) return false;
    final items = _itemsEditorKey.currentState;
    if (items == null || items.isSelecting) return false;
    if (items.itemIdAt(event.position) == null) return false;
    _gesturePointer = event.pointer;
    _gesturePoints = [event.position];
    _gestureStartedAt = event.timeStamp;
    _gestureMovedAt = null;
    _gestureScrollStart = _gestureScrollPosition()?.pixels;
    _gestureSelectionStart = _formatTarget?.controller.selection;
    return true;
  }

  void _onContentPointerMove(PointerMoveEvent event) {
    if (event.pointer != _gesturePointer) return;
    _gesturePoints.add(event.position);
    if (_gestureMovedAt == null &&
        (event.position - _gesturePoints.first).distance > 6) {
      _gestureMovedAt = event.timeStamp;
    }
  }

  void _onContentPointerCancel(PointerCancelEvent event) {
    _contentPointers = math.max(0, _contentPointers - 1);
    if (event.pointer == _gesturePointer) _gesturePointer = null;
  }

  void _onContentPointerUp(PointerUpEvent event) {
    _contentPointers = math.max(0, _contentPointers - 1);
    if (event.pointer != _gesturePointer) return;
    _gesturePointer = null;
    final points = _gesturePoints;
    _gesturePoints = [];
    final gesture = classifyInkGesture(points);
    if (gesture == InkGesture.none) return;
    final started = _gestureStartedAt ?? event.timeStamp;
    final moved = _gestureMovedAt ?? event.timeStamp;
    // Uzun basış (madde menüsü, sürükle-sırala, metin seçimi) sonrası
    // sürükleme jest değil.
    if (moved - started > const Duration(milliseconds: 400)) return;
    // Hızlı fiske (sayfa çevirme, kaydırma) jest değil.
    final touch = event.kind == PointerDeviceKind.touch;
    if (touch &&
        event.timeStamp - started < const Duration(milliseconds: 120)) {
      return;
    }
    // Sayfa kaydıysa kullanıcı kaydırıyordu.
    final scroll = _gestureScrollPosition()?.pixels;
    final scrollStart = _gestureScrollStart;
    if (scroll != null &&
        scrollStart != null &&
        (scroll - scrollStart).abs() > 6) {
      return;
    }
    // Alanda seçim/imleç sürüklendiyse (tutamaç, uzun basış seçimi) jest
    // değil.
    final selection = _formatTarget?.controller.selection;
    if (selection != null &&
        selection.isValid &&
        !selection.isCollapsed &&
        selection != _gestureSelectionStart) {
      return;
    }
    // Kalemin sürüklemesi alanda imleç açmış olabilir: jestten sonra bırak.
    if (!touch) FocusManager.instance.primaryFocus?.unfocus();
    _applyItemGesture(points, gesture);
  }
}

/// "Daire çizerek bağla" kipindeyken alt şerit: ne çizileceğini söyler.
class _GestureModeBanner extends StatelessWidget {
  const _GestureModeBanner({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        child: Row(
          children: [
            Icon(Icons.gesture, size: 18, color: scheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.embedLassoHint,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSecondaryContainer),
              ),
            ),
            IconButton(
              key: const ValueKey('gesture-mode-close'),
              tooltip: l10n.close,
              icon: const Icon(Icons.close, size: 18),
              color: scheme.onSecondaryContainer,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
