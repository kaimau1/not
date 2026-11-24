import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/attachment_tag.dart';
import '../../../../core/utils/spell_engine.dart';
import 'auto_spell.dart';
import 'selection_toolbar.dart';
import 'text_wrap.dart' show WrapTextController;

/// Altı çizili kelime: aralık denetleyicinin EKRAN metninde (sarma çapalı).
/// [hint]: bağlama bağlı öneri ("bende" → "ben de") — yanlış olmayabilir,
/// soluk çizilir.
typedef SpellMark = ({int start, int end, String word, bool hint});

/// **YAZIM v3 Y-4 — ALTI ÇİZİLİ DENETİM** (17K §3.3). Bir metin alanının
/// işaretleri; çizgi `AttachmentTagChips`'in boyama katmanında çizilir
/// (aramadaki `SearchHighlight` kalıbı): metin span'ine KONMAZ — span her
/// tuşta bütün metni yeniden biçimlendirirdi. Flutter'ın
/// `SpellCheckConfiguration`'ı kullanılmaz (her değişiklikte bütün metin
/// platform kanalından geçer, kare bekler).
///
/// * Denetim her tuşta DEĞİL: yazım [pause] kadar durunca. Arada işaretler
///   yalnız kaydırılır (değişikliğe değen düşer) — çizgi yazının altında
///   kaymasın.
/// * Artımlı: paragraf (satır) metni → işaretler, kelime → öneriler
///   önbellekte (bütün alanlar ortak); değişen paragraf yeniden denetlenir.
///   Bilinmeyen kelime pahalı (bulanık arama ~0,2 ms+): tarama 4 ms'lik
///   dilimlere bölünür, aralarda kare çizilir (not açılışındaki tam tarama
///   da böyle); her dilim baştan başlar, biten kelimeler önbellekten gelir. ponytail: `runHeavy` (izole) yerine dilim — web'de izole yok,
///   `SpellMemory`'yi izoleye kopyalamak da ana iş parçacığında; uzun
///   notta yetmezse izole taraması sabah bakılacak.
/// * Hafıza ya da "bu notta dokunma" değişince ([AutoSpell.revision])
///   önbellek boşalır, alan yeniden denetlenir.
class SpellMarks extends ChangeNotifier {
  SpellMarks._(this.controller) : _text = controller.text {
    controller.addListener(_onText);
    AutoSpell.mode.addListener(_restart);
    AutoSpell.revision.addListener(_restart);
    _schedule(Duration.zero);
  }

  final TextEditingController controller;

  /// Yazım duraklaması: bu kadar tuşa basılmazsa denetlenir (bir orta
  /// geçiş süresi, 300 ms).
  static const pause = AppMotion.medium;
  static const _sliceUs = 4000;

  /// Çizilen en çok işaret (her biri bir `getBoxesForSelection`; boyama
  /// her tuşta). ponytail: tavan, görünür alana göre süzme gerekirse sonra.
  static const maxPainted = 100;

  static final _registry = Expando<SpellMarks>();
  static final Map<String, ({List<String> list, bool hint})?> _words = {};
  static final Map<String, List<SpellMark>> _paras = {};
  static int _cacheRev = -1;

  /// Alanın işaretleri (alan kuruluyken; yoksa null).
  static SpellMarks? of(TextEditingController c) => _registry[c];

  /// Alanı kuran widget çağırır; [release] ile bırakır.
  static SpellMarks acquire(TextEditingController c) {
    final m = _registry[c] ??= SpellMarks._(c);
    m._users++;
    return m;
  }

  int _users = 0;
  bool _disposed = false;

  void release() {
    if (--_users > 0) return;
    _registry[controller] = null;
    controller.removeListener(_onText);
    AutoSpell.mode.removeListener(_restart);
    AutoSpell.revision.removeListener(_restart);
    _timer?.cancel();
    _disposed = true;
    dispose();
  }

  List<SpellMark> _marks = const [];
  List<SpellMark> get marks => _marks;

  String _text;

  /// Son yazımın imleci: o an yazılan kelimenin çizgisi gizlenir.
  int editAt = -1;
  Timer? _timer;

  /// [offset] (ekran metni) altı çizili bir kelimenin içinde mi.
  SpellMark? at(int offset) {
    for (final k in _marks) {
      if (offset >= k.start && offset <= k.end) return k;
    }
    return null;
  }

  /// Öneriler (küçük harf; önbellek o arada boşaldıysa yeniden).
  static List<String> suggestionsFor(String word) =>
      (_words[word] ?? SpellEngine.suggestions(word, AutoSpell.memory))?.list ??
      const [];

  void _schedule(Duration d) {
    _timer?.cancel();
    _timer = Timer(d, _scan);
  }

  void _restart() {
    if (AutoSpell.mode.value == SpellMode.off && _marks.isNotEmpty) {
      _marks = const [];
      notifyListeners();
    }
    _schedule(Duration.zero);
  }

  void _onText() {
    final t = controller.text;
    if (t == _text) return;
    final old = _text;
    _text = t;
    final sel = controller.selection;
    editAt = sel.isValid && sel.isCollapsed ? sel.baseOffset : -1;
    if (_marks.isNotEmpty) {
      // Değişen aralık: ortak önek/sonek dışı. Önündeki işaret yerinde,
      // arkasındaki kayar; değen ya da yazıyla bitişen (kelime uzadı)
      // düşer, duraklamada yeniden denetlenir.
      var p = 0;
      final n = old.length < t.length ? old.length : t.length;
      while (p < n && old.codeUnitAt(p) == t.codeUnitAt(p)) {
        p++;
      }
      var s = 0;
      while (s < n - p &&
          old.codeUnitAt(old.length - 1 - s) ==
              t.codeUnitAt(t.length - 1 - s)) {
        s++;
      }
      final oldEnd = old.length - s;
      final delta = t.length - old.length;
      bool apart(int i) => i < 0 || i >= t.length || !_letter.hasMatch(t[i]);
      _marks = [
        for (final k in _marks)
          if (k.end <= p && apart(k.end))
            k
          else if (k.start >= oldEnd && apart(k.start + delta - 1))
            (
              start: k.start + delta,
              end: k.end + delta,
              word: k.word,
              hint: k.hint,
            ),
      ];
    }
    _schedule(pause);
  }

  static final _letter = RegExp(r'\p{L}', unicode: true);

  void _scan() {
    if (_disposed || AutoSpell.mode.value == SpellMode.off) return;
    if (_cacheRev != AutoSpell.revision.value) {
      _cacheRev = AutoSpell.revision.value;
      _words.clear();
      _paras.clear();
    }
    final text = controller.text;
    final memory = AutoSpell.memory;
    final keep = AutoSpell.noteKeep;
    final c = controller;
    final names = c is WrapTextController
        ? c.attachmentNames
        : const <String>[];
    final out = <SpellMark>[];
    final watch = Stopwatch()..start();
    var base = 0;
    for (final para in text.split('\n')) {
      var marks = _paras[para];
      if (marks == null) {
        final tokens = SpellEngine.tokens(para);
        for (final t in tokens) {
          if (_words.containsKey(t.word)) continue;
          if (watch.elapsedMicroseconds > _sliceUs) {
            // Dilim doldu: kare çizilsin; kalan sonraki turda (yapılan
            // kelimeler önbellekte). Kendi zamanlayıcımız: alan kapanınca
            // iptal edilir.
            _schedule(Duration.zero);
            return;
          }
          if (_words.length > 20000) _words.clear();
          _words[t.word] = SpellEngine.suggestions(t.word, memory);
        }
        marks = [
          for (final t in tokens)
            if (_words[t.word] case final s? when !keep.contains(t.word))
              (start: t.start, end: t.end, word: t.word, hint: s.hint),
        ];
        if (_paras.length > 3000) _paras.clear();
        _paras[para] = marks;
      }
      // Ek etiketinin adı ("📎 fatura") kelime değil (önbellekte değil:
      // ad listesi alana göre).
      final tags = para.contains(kAttachmentTagPrefix)
          ? findAttachmentTags(para, names)
          : const <({int start, int end, String fileName})>[];
      for (final k in marks) {
        if (tags.any((t) => t.start < k.end && k.start < t.end)) continue;
        out.add((
          start: k.start + base,
          end: k.end + base,
          word: k.word,
          hint: k.hint,
        ));
      }
      base += para.length + 1;
    }
    if (_marks.isEmpty && out.isEmpty) return;
    _marks = out;
    notifyListeners();
  }
}

/// Alana dokunulduktan sonra: imleç altı çizili bir kelimedeyse menüsünü
/// açar (bkz. [spellContextMenu]). Açtıysa true.
bool showSpellMenuAfterTap(EditableTextState? editable) {
  if (editable == null || editable.widget.readOnly) return false;
  final sel = editable.textEditingValue.selection;
  final marks = SpellMarks.of(editable.widget.controller);
  if (marks == null || !sel.isValid || !sel.isCollapsed) return false;
  if (marks.at(sel.baseOffset) == null) return false;
  // Dokunuş alanı yeni odaklamış olabilir: seçim katmanı bir kare sonra.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (editable.mounted) editable.showToolbar();
  });
  return true;
}

/// Seçim menüsü kurucusunun başında: imleç altı çizili bir kelimedeyse
/// yalnız yazım menüsü — öneriler · Sözlüğe ekle · Hep böyle düzelt · Bu
/// notta dokunma. Değilse null (olağan menü).
Widget? spellContextMenu(BuildContext context, EditableTextState state) {
  final sel = state.textEditingValue.selection;
  if (state.widget.readOnly || !sel.isValid || !sel.isCollapsed) return null;
  final mark = SpellMarks.of(state.widget.controller)?.at(sel.baseOffset);
  if (mark == null) return null;
  final l10n = context.l10n;
  final text = state.textEditingValue.text;
  if (mark.end > text.length) return null;
  final typed = text.substring(mark.start, mark.end);
  final options = [
    for (final s in SpellMarks.suggestionsFor(mark.word).take(3))
      SpellEngine.matchCase(typed, s),
  ];
  void replace(String to) {
    final next = text.replaceRange(mark.start, mark.end, to);
    state.userUpdateTextEditingValue(
      TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: mark.start + to.length),
      ),
      SelectionChangedCause.toolbar,
    );
  }

  ContextMenuButtonItem item(String label, VoidCallback run) =>
      ContextMenuButtonItem(
        label: label,
        onPressed: () {
          state.hideToolbar();
          run();
        },
      );
  final first = options.isEmpty ? null : options.first;
  return NoteSelectionToolbar.spell(
    editableState: state,
    suggestions: [for (final s in options) item(s, () => replace(s))],
    actions: [
      item(l10n.spellAddToDictionary, () => AutoSpell.addToDictionary(typed)),
      if (first != null)
        item(l10n.spellAlwaysFix(first), () {
          AutoSpell.alwaysFix(typed, first);
          replace(first);
        }),
      item(
        l10n.spellKeepInNote,
        () => AutoSpell.keepInNote(typed, mark.hint ? null : first),
      ),
    ],
  );
}
