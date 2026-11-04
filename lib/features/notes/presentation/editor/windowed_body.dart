import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'text_window.dart';
import 'text_wrap.dart';

/// **UZUN NOTTA PENCERELİ YAZMA** (F24.2, telefonda ölçüldü 2026-11-04: 35 KB
/// notta tuş başına LAYOUT 122 ms, klavye kanalında tuş başına 40 KB).
///
/// Tek `TextField` tuş başına bütün metni yerleştirir (O(n), motorun içinde).
/// Yazarken alan yalnız imlecin çevresindeki paragrafları taşır ([win]); üstü
/// ve altı değişmeyen `RichText` parçalarıdır (tuşta yeniden yerleşmez).
///
/// **MODEL HEP [full]:** 130 yerden okunan `_bodyController` tam metni ve
/// seçimi taşımayı sürdürür; kayıt, biçim, dikte, arama, geri alma ona bakar.
/// Pencere ondan türer, iki yön de burada eşlenir.
///
/// Yalnız yazarken: okurken (odak yokken) editör eski yoldadır — bağlantı, ek
/// etiketi, seçim aynen. Olağan dışı her durumda ([exit]) tek alana dönülür:
/// tam metin hazır olduğu için dönüş veri açısından bedelsizdir.
class BodyWindow extends ChangeNotifier {
  BodyWindow(this.full) {
    win.addListener(_onWindowEdit);
    full.addListener(_onFullChange);
  }

  /// Sessizken yeniden pencereleme gecikmesi: klavyenin yoldaki durumu eski
  /// pencere metnini taşır (bkz. [_isStale]); yazarken pencere oynatılmaz.
  static const _quiet = Duration(milliseconds: 500);

  /// İmleç pencere kenarına bu kadar yaklaşırsa beklemeden kaydırılır.
  static const _edge = 24;

  final WrapTextController full;
  final win = WrapTextController();

  TextWindow? _window;
  bool _syncing = false;
  Timer? _quietTimer;

  /// Son yeniden pencerelemeden önceki pencere metni + geçerlilik süresi.
  String? _staleText;
  DateTime _staleUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// Üst/alt parçalar (bkz. [_tilesBefore]) — yalnız pencere kayınca değişir.
  List<BodyTile> _before = const [];
  List<BodyTile> _after = const [];

  bool get active => _window != null;
  TextWindow? get window => _window;
  List<BodyTile> get before => _before;
  List<BodyTile> get after => _after;

  /// [kWindowedThreshold] üstünde tek alandan pencereye geçer.
  void enter() {
    if (active || full.text.length < kWindowedThreshold) return;
    final selection = full.selection;
    if (!selection.isValid || !selection.isCollapsed) return;
    _place(windowAround(full.text, selection.extentOffset));
    notifyListeners();
  }

  /// Tek alana döner. Tam metin zaten güncel; yalnız bayrak iner.
  void exit({bool notify = true}) {
    if (!active) return;
    _quietTimer?.cancel();
    _window = null;
    _before = _after = const [];
    _staleText = null;
    if (notify) notifyListeners();
  }

  /// [offset] (tam metin) görünür alana alınır, imleç oraya konur.
  void moveCaretTo(int offset) {
    full.selection = TextSelection.collapsed(offset: offset);
  }

  void _place(TextWindow next) {
    final text = full.text;
    final previous = _window;
    if (previous != null) {
      _staleText = win.text;
      _staleUntil = DateTime.now().add(const Duration(seconds: 1));
    }
    _window = next;
    _before = _tilesBefore(text, next.start);
    _after = _tilesAfter(text, next.end);
    win.copyLooksFrom(full);
    _syncing = true;
    final v = full.value;
    win.mirrorValue(
      TextEditingValue(
        text: next.slice(text),
        selection: v.selection.isValid
            ? v.selection.copyWith(
                baseOffset: next.toWindow(v.selection.baseOffset),
                extentOffset: next.toWindow(v.selection.extentOffset),
              )
            : v.selection,
        composing: v.composing.isValid
            ? TextRange(
                start: next.toWindow(v.composing.start),
                end: next.toWindow(v.composing.end),
              )
            : TextRange.empty,
      ),
    );
    _syncing = false;
  }

  /// Alan → model: pencere metni tam metne yazılır.
  void _onWindowEdit() {
    final w = _window;
    if (_syncing || w == null) return;
    final v = win.value;
    if (_isStale(v.text)) {
      // Klavyeden, kaymadan ÖNCEKİ pencereye ait bir durum geldi: tam metne
      // yazılsa paragraflar çoğalır/kaybolur. Yok sayılır, alan güncellenir.
      _place(w);
      return;
    }
    final fullText = full.text;
    final selection = v.selection;
    // "Tümünü seç" pencereyi değil notu kastediyor.
    if (!selection.isCollapsed &&
        selection.start == 0 &&
        selection.end == v.text.length &&
        (w.start > 0 || w.end < fullText.length)) {
      _syncing = true;
      full.selection = TextSelection(
        baseOffset: 0,
        extentOffset: fullText.length,
      );
      _syncing = false;
      exit();
      return;
    }
    final next = spliceWindow(fullText, w, v.text);
    _window = next.window;
    _syncing = true;
    full.mirrorValue(
      TextEditingValue(
        text: next.text,
        selection: selection.isValid
            ? selection.copyWith(
                baseOffset: w.toFull(selection.baseOffset),
                extentOffset: w.toFull(selection.extentOffset),
              )
            : selection,
        composing: v.composing.isValid
            ? TextRange(
                start: w.toFull(v.composing.start),
                end: w.toFull(v.composing.end),
              )
            : TextRange.empty,
      ),
    );
    _syncing = false;
    _scheduleRewindow();
  }

  /// Model → alan: dışarıdan yazım (biçim, dikte, geri alma, başka cihaz).
  void _onFullChange() {
    if (_syncing || !active) return;
    final selection = full.selection;
    final caret = selection.isValid ? selection.extentOffset : _window!.start;
    final next = windowAround(full.text, caret);
    if (!selection.isCollapsed &&
        (selection.start < next.start || selection.end > next.end)) {
      exit();
      return;
    }
    if (full.text.length < kWindowedThreshold ~/ 2) {
      exit();
      return;
    }
    _place(next);
    notifyListeners();
  }

  void _scheduleRewindow() {
    final w = _window!;
    final selection = full.selection;
    if (!selection.isValid || !selection.isCollapsed) return;
    final caret = selection.extentOffset;
    final text = full.text;
    final tooLong = w.length > kWindowMaxChars * 2;
    if (!tooLong && !needsRewindow(text, w, caret)) return;
    final atEdge =
        (w.start > 0 && caret - w.start < _edge) ||
        (w.end < text.length && w.end - caret < _edge);
    _quietTimer?.cancel();
    if (atEdge) {
      _rewindow();
    } else {
      _quietTimer = Timer(_quiet, _rewindow);
    }
  }

  void _rewindow() {
    final w = _window;
    if (w == null) return;
    final selection = full.selection;
    if (!selection.isValid || !selection.isCollapsed) return;
    final next = windowAround(full.text, selection.extentOffset);
    if (next == w) return;
    _place(next);
    notifyListeners();
  }

  /// [incoming], kaymadan önceki pencerenin devamı mı (şimdikinin değil)?
  bool _isStale(String incoming) {
    final stale = _staleText;
    if (stale == null) return false;
    if (DateTime.now().isAfter(_staleUntil)) {
      _staleText = null;
      return false;
    }
    return _shares(incoming, stale) &&
        !_shares(incoming, _window!.slice(full.text));
  }

  static bool _shares(String a, String b) {
    final limit = math.min(a.length, b.length);
    var head = 0;
    while (head < limit && a.codeUnitAt(head) == b.codeUnitAt(head)) {
      head++;
    }
    var tail = 0;
    while (tail < limit - head &&
        a.codeUnitAt(a.length - 1 - tail) ==
            b.codeUnitAt(b.length - 1 - tail)) {
      tail++;
    }
    // En çok küçük bir düzenleme kadar fark: otomatik düzeltme bir sözcük.
    return head + tail >= math.max(a.length, b.length) - 64;
  }

  @override
  void dispose() {
    _quietTimer?.cancel();
    win.removeListener(_onWindowEdit);
    full.removeListener(_onFullChange);
    win.dispose();
    super.dispose();
  }
}

/// Pencere dışındaki bir parça: tam metindeki yeri + metni.
@immutable
class BodyTile {
  const BodyTile(this.anchor, this.text, {this.fromEnd = false});

  /// Baştan uzaklık; alt parçada ([fromEnd]) SONDAN uzaklık: pencerede yazınca
  /// alt parçanın baştan yeri kayar, sondan yeri kaymaz. Kimlik sabit kalmazsa
  /// her pencere kaymasında bütün alt parçalar yeniden yerleşirdi (200 ms).
  final int anchor;
  final bool fromEnd;
  final String text;

  /// Tam metindeki başlangıcı.
  int startIn(int fullLength) => fromEnd ? fullLength - anchor : anchor;

  @override
  bool operator ==(Object other) =>
      other is BodyTile &&
      other.anchor == anchor &&
      other.fromEnd == fromEnd &&
      other.text == text;

  @override
  int get hashCode => Object.hash(anchor, fromEnd, text);
}

/// Parça başına hedef uzunluk: pencere kayınca yalnız sınırdaki parça yeniden
/// yerleşir; 30 KB tek `RichText` olsaydı her kaymada 100 ms.
const _tileChars = 1500;

/// `[0, end)` (son `\n` hariç, o satır kırılımını parça sınırı yapar) baştan
/// parçalanır: kayınca baştaki parçalar AYNI kalır.
List<BodyTile> _tilesBefore(String text, int end) {
  if (end <= 0) return const [];
  final last = end - 1;
  final tiles = <BodyTile>[];
  var start = 0;
  while (true) {
    final target = start + _tileChars;
    if (target >= last) break;
    final cut = text.indexOf('\n', target);
    if (cut < 0 || cut >= last) break;
    tiles.add(BodyTile(start, text.substring(start, cut)));
    start = cut + 1;
  }
  tiles.add(BodyTile(start, text.substring(start, last)));
  return tiles;
}

/// `(start, sonu]` (ilk `\n` hariç) sondan parçalanır: alt parçalar sabit kalır.
List<BodyTile> _tilesAfter(String text, int start) {
  if (start >= text.length) return const [];
  final first = start + 1;
  final tiles = <BodyTile>[];
  var end = text.length;
  while (true) {
    final target = end - _tileChars;
    if (target <= first) break;
    final cut = text.lastIndexOf('\n', target);
    if (cut < first) break;
    tiles.add(
      BodyTile(
        text.length - (cut + 1),
        text.substring(cut + 1, end),
        fromEnd: true,
      ),
    );
    end = cut;
  }
  tiles.add(
    BodyTile(text.length - first, text.substring(first, end), fromEnd: true),
  );
  return tiles.reversed.toList(growable: false);
}

/// Yerleşimi `TextField`inkiyle bire bir aynı çizilen tek parça. Dokunuş
/// tam metin ofsetine çevrilip yukarı verilir.
class BodyTileView extends StatefulWidget {
  const BodyTileView({
    super.key,
    required this.tile,
    required this.fullLength,
    required this.span,
    required this.strut,
    required this.caretMargin,
    required this.onTap,
    required this.onLongPress,
  });

  final BodyTile tile;

  /// Tam metnin O ANKİ uzunluğu (bkz. [BodyTile.startIn]).
  final int Function() fullLength;
  final InlineSpan span;
  final StrutStyle strut;

  /// `RenderEditable` satır genişliğinden imleç payını düşer; parça da aynı
  /// genişlikte kırmazsa pencere kayınca satırlar zıplar.
  final double caretMargin;
  final void Function(int offset, Offset global) onTap;
  final void Function(int offset, Offset global) onLongPress;

  @override
  State<BodyTileView> createState() => _BodyTileViewState();
}

class _BodyTileViewState extends State<BodyTileView> {
  final _key = GlobalKey();

  int _offsetAt(Offset global) {
    final paragraph =
        _key.currentContext!.findRenderObject()! as RenderParagraph;
    final local = paragraph.globalToLocal(global);
    return widget.tile.startIn(widget.fullLength()) +
        paragraph.getPositionForOffset(local).offset;
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) =>
          widget.onTap(_offsetAt(d.globalPosition), d.globalPosition),
      onLongPressStart: (d) =>
          widget.onLongPress(_offsetAt(d.globalPosition), d.globalPosition),
      child: MouseRegion(
        cursor: SystemMouseCursors.text,
        child: Padding(
          padding: EdgeInsets.only(right: widget.caretMargin),
          child: RichText(
            key: _key,
            text: widget.span,
            strutStyle: widget.strut,
            textScaler: MediaQuery.textScalerOf(context),
          ),
        ),
      ),
    ),
  );
}

/// Üst parçalar + alan + alt parçalar. Parça widget'ları [_tiles] önbelleğinden
/// AYNI örnek döner: tuşta hiçbiri yeniden kurulmaz/yerleşmez.
class WindowedBodyField extends StatefulWidget {
  const WindowedBodyField({
    super.key,
    required this.window,
    required this.style,
    required this.strut,
    required this.linkColor,
    required this.topPadding,
    required this.field,
    required this.onTileTap,
    required this.onTileLongPress,
  });

  final BodyWindow window;

  /// `TextField`in BİRLEŞMİŞ yazı stili (bkz. [windowedFieldStyle]).
  final TextStyle style;
  final StrutStyle strut;
  final Color linkColor;

  /// Alanın üst/alt iç dolgusu: parça varken alan yerine parçanın ucunda.
  final double topPadding;

  /// `(üst dolgu var mı, alt dolgu var mı)` ile alanı kurar.
  final Widget Function(bool top, bool bottom) field;
  final void Function(int offset, Offset global) onTileTap;
  final void Function(int offset, Offset global) onTileLongPress;

  @override
  State<WindowedBodyField> createState() => _WindowedBodyFieldState();
}

class _WindowedBodyFieldState extends State<WindowedBodyField> {
  Map<BodyTile, Widget> _tiles = const {};
  Object? _env;

  List<Widget> _resolve(List<BodyTile> list, Map<BodyTile, Widget> next) => [
    for (final tile in list)
      next[tile] ??=
          _tiles[tile] ??
          BodyTileView(
            key: ValueKey(tile),
            tile: tile,
            fullLength: () => widget.window.full.text.length,
            span: widget.window.full.tileSpan(
              tile.text,
              widget.style,
              widget.linkColor,
            ),
            strut: widget.strut,
            caretMargin: kWindowedCaretMargin,
            onTap: widget.onTileTap,
            onLongPress: widget.onTileLongPress,
          ),
  ];

  @override
  Widget build(BuildContext context) {
    final env = (
      widget.style,
      widget.linkColor,
      widget.strut,
      MediaQuery.textScalerOf(context),
    );
    if (env != _env) {
      _tiles = const {};
      _env = env;
    }
    final next = <BodyTile, Widget>{};
    final before = _resolve(widget.window.before, next);
    final after = _resolve(widget.window.after, next);
    _tiles = next;
    return TextFieldTapRegion(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (before.isNotEmpty) SizedBox(height: widget.topPadding),
          ...before,
          widget.field(before.isEmpty, after.isEmpty),
          ...after,
          if (after.isNotEmpty) SizedBox(height: widget.topPadding),
        ],
      ),
    );
  }
}

/// `RenderEditable`in satır genişliğinden düştüğü pay: imleç 2 + boşluk 1
/// (`TextField.cursorWidth` varsayılanı, `_kCaretGap`). Test sabitler.
const kWindowedCaretMargin = 3.0;

/// `TextField` stili temanın giriş stiliyle birleştirir; parçalar da aynısını
/// kullanmazsa harf aralığı/kalınlık farkıyla satırlar başka yerden kırılır.
TextStyle windowedFieldStyle(BuildContext context, TextStyle style) =>
    (Theme.of(context).textTheme.bodyLarge ?? const TextStyle()).merge(style);

/// Parçaya uzun basınca: pencere oraya kaydıktan sonra alanda sözcük seçilir.
void selectWordAt(EditableTextState? editable, Offset global) {
  if (editable == null) return;
  editable.renderEditable.selectWordsInRange(
    from: global,
    cause: SelectionChangedCause.longPress,
  );
  editable.showToolbar();
}
