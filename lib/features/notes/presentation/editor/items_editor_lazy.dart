part of 'items_editor.dart';

/// **YALNIZ DOKUNULAN MADDE METİN ALANI (F24.3, AKICILIK K2).** 120 maddelik
/// notta 120 `TextField` (EditableText + kaydırıcı + jestler + odak düğümü):
/// açılışta ilk kare 97 ms + 27 kare 23 ms, kapanışta söküm 20-40 ms/kare
/// (telefonda ölçüldü, 2026-11-04). Madde düz `RichText` olarak çizilir; dokununca ya da odak
/// istenince gerçek alana döner ve bir daha geri dönmez (ağacın şekli sabit,
/// bkz. `_itemRow`).
///
/// Bütün odak yolları (Enter, birleştirme, biçim çubuğu, arama, dikte) zaten
/// `requestFocus` çağırıyor: bu düğüm alan henüz yoksa önce alanı kurdurur.
/// Testler (`test/flutter_test_config.dart`) satırları hep gerçek alanla kurar:
/// onlarca test maddeye doğrudan `enterText` ile yazıyor. Düz çizim yolunu
/// `items_editor_lazy_test` sınar.
@visibleForTesting
bool debugEagerItemFields = false;

class _LazyFocusNode extends FocusNode {
  VoidCallback? _needField;
  bool _pending = false;

  /// Satırın bağlamı: düz çizimde düğüm henüz alana bağlı değil, [context]
  /// boş. KÖK NEDEN (cihaz turu 2026-11-05): jest katmanı maddeyi düğümün
  /// bağlamından buluyordu; F24.3'ten beri hiç dokunulmamış maddeye çizilen
  /// jest (üstünü çiz, ✓) sessizce boşa gidiyordu.
  BuildContext? _rowContext;

  BuildContext? get rowContext => context ?? _rowContext;

  @override
  void requestFocus([FocusNode? node]) {
    final needField = _needField;
    if (node == null && context == null && needField != null) {
      _pending = true;
      needField();
      return;
    }
    super.requestFocus(node);
  }

  /// Alan kuruldu ve düğüm bağlandı: bekleyen odak isteği şimdi uygulanır.
  void _flushPending() {
    if (!_pending) return;
    _pending = false;
    super.requestFocus();
  }
}

/// Düz çizim gerçek alanın birebir aynısı olmalı (satır kırılımı, yükseklik):
/// BİRLEŞMİŞ stil + imleç payı — bkz. [windowedFieldStyle],
/// [kWindowedCaretMargin], test `items_editor_lazy_test`.
class _LazyItemField extends StatefulWidget {
  const _LazyItemField({
    required this.controller,
    required this.focusNode,
    required this.style,
    required this.strut,
    required this.verticalPad,
    required this.maxLines,
    required this.eager,
    required this.field,
    this.textAlign = TextAlign.start,
  });

  final WrapTextController controller;
  final _LazyFocusNode focusNode;
  final TextStyle style;
  final StrutStyle strut;
  final double verticalPad;
  final int? maxLines;

  /// Düz çizimin karşılayamadığı satır: hemen gerçek alan.
  final bool eager;
  final Widget field;

  /// Ara başlık hizası (bkz. [NoteItem.align]); gerçek alanla aynı olmalı,
  /// yoksa odaklanınca yazı yer değiştirir.
  final TextAlign textAlign;

  @override
  State<_LazyItemField> createState() => _LazyItemFieldState();
}

class _LazyItemFieldState extends State<_LazyItemField> {
  final _paragraph = GlobalKey();
  late bool _active;

  @override
  void initState() {
    super.initState();
    _active =
        widget.eager || widget.focusNode.hasFocus || widget.focusNode._pending;
    widget.focusNode._needField = _activate;
    widget.focusNode._rowContext = context;
    if (_active) _afterFieldBuilt();
  }

  @override
  void didUpdateWidget(covariant _LazyItemField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.focusNode, widget.focusNode)) {
      if (identical(oldWidget.focusNode._needField, _activate)) {
        oldWidget.focusNode._needField = null;
      }
      if (identical(oldWidget.focusNode._rowContext, context)) {
        oldWidget.focusNode._rowContext = null;
      }
      widget.focusNode._needField = _activate;
      widget.focusNode._rowContext = context;
    }
    if (widget.eager && !_active) {
      _active = true;
      _afterFieldBuilt();
    }
  }

  @override
  void dispose() {
    if (identical(widget.focusNode._needField, _activate)) {
      widget.focusNode._needField = null;
    }
    if (identical(widget.focusNode._rowContext, context)) {
      widget.focusNode._rowContext = null;
    }
    super.dispose();
  }

  void _activate() {
    if (!mounted) return;
    if (_active) {
      _afterFieldBuilt();
      return;
    }
    setState(() => _active = true);
    _afterFieldBuilt();
  }

  void _afterFieldBuilt([VoidCallback? then]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.focusNode._flushPending();
      then?.call();
    });
  }

  int _offsetAt(Offset global) {
    final paragraph =
        _paragraph.currentContext?.findRenderObject() as RenderParagraph?;
    if (paragraph == null) return widget.controller.text.length;
    return paragraph
        .getPositionForOffset(paragraph.globalToLocal(global))
        .offset;
  }

  void _openAt(Offset global, {bool selectWord = false}) {
    widget.controller.selection = TextSelection.collapsed(
      offset: _offsetAt(global).clamp(0, widget.controller.text.length),
    );
    widget.focusNode._pending = true;
    setState(() => _active = true);
    _afterFieldBuilt(
      selectWord
          ? () => WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) selectWordAt(editableTextBelow(context), global);
            })
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_active) return widget.field;
    final merged = windowedFieldStyle(context, widget.style);
    final oneLine = widget.maxLines == 1;
    return TextFieldTapRegion(
      child: Semantics(
        textField: true,
        multiline: !oneLine,
        onTap: () => widget.focusNode.requestFocus(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _openAt(d.globalPosition),
          onLongPressStart: (d) => _openAt(d.globalPosition, selectWord: true),
          child: Padding(
            padding: EdgeInsets.only(
              top: widget.verticalPad,
              bottom: widget.verticalPad,
              right: kWindowedCaretMargin,
            ),
            child: ListenableBuilder(
              listenable: widget.controller,
              // Ortalı/sağa hizalı başlıkta paragraf satırı doldursun:
              // RichText yazı kadar daralırsa hiza görünmez.
              builder: (context, _) => SizedBox(
                width: widget.textAlign == TextAlign.start
                    ? null
                    : double.infinity,
                child: RichText(
                key: _paragraph,
                textAlign: widget.textAlign,
                text: widget.controller.buildTextSpan(
                  context: context,
                  style: merged,
                  withComposing: false,
                ),
                strutStyle: widget.strut,
                maxLines: widget.maxLines,
                softWrap: !oneLine,
                overflow: oneLine ? TextOverflow.clip : TextOverflow.visible,
                textScaler: MediaQuery.textScalerOf(context),
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
