part of 'note_editor_screen.dart';

/// Jest kipi (kullanıcı isteği 2026-10-30): maddelerin üstüne çizilen
/// jestler ve "Buraya bağla"da daire içine alarak seçim. Tanıma ve örtü
/// `ink_gestures.dart`ta; burada jestin NOTA etkisi.
enum _GestureMode { off, items, embedLasso }

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
    if (_gestureMode == _GestureMode.embedLasso) {
      _lassoEmbed(points);
    } else {
      _applyItemGesture(points, fromStylus: false);
    }
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
  /// karala → sil, daire → yazımı düzelt. Kalemle maddeye çizilen çizgi de
  /// buradan geçer ([fromStylus]: tanınmayan çizgi sessiz kalır — kalem
  /// imleç koymak için de değer).
  void _applyItemGesture(List<Offset> points, {required bool fromStylus}) {
    final l10n = context.l10n;
    final gesture = classifyInkGesture(points);
    final items = _itemsEditorKey.currentState;
    if (gesture == InkGesture.none || items == null) {
      if (!fromStylus) _showSnack(l10n.gestureUnknown);
      return;
    }
    final id = items.itemIdAt(inkBounds(points).center);
    if (id == null) {
      if (!fromStylus) _showSnack(l10n.gestureNoItem);
      return;
    }
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

  /// KALEMLE MADDEYE çizgi (jest kipi kapalıyken de): içerik alanının
  /// dinleyicisi kalemin maddeye değdiğini görünce noktaları toplar.
  bool _startStylusGesture(PointerDownEvent event) {
    final items = _itemsEditorKey.currentState;
    if (items == null || items.itemIdAt(event.position) == null) return false;
    _stylusPointer = event.pointer;
    _stylusPoints = [event.position];
    return true;
  }

  void _onContentPointerMove(PointerMoveEvent event) {
    if (event.pointer != _stylusPointer) return;
    _stylusPoints.add(event.position);
  }

  void _onContentPointerUp(PointerUpEvent event) {
    if (event.pointer != _stylusPointer) return;
    final points = _stylusPoints;
    _stylusPointer = null;
    _stylusPoints = [];
    if (classifyInkGesture(points) == InkGesture.none) return;
    // Kalemin sürüklemesi alanda seçim açmış olabilir: jestten sonra bırak.
    FocusManager.instance.primaryFocus?.unfocus();
    _applyItemGesture(points, fromStylus: true);
  }
}

/// Jest kipindeyken alt şerit: ne çizileceğini söyler, kapatır.
class _GestureModeBanner extends StatelessWidget {
  const _GestureModeBanner({required this.lasso, required this.onClose});

  /// "Buraya bağla" kipi (daire çiz) mi, madde jestleri mi.
  final bool lasso;
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
                lasso ? l10n.embedLassoHint : l10n.gestureModeHint,
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
