import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/attachment_tag.dart';
import '../../../../core/utils/spell_engine.dart';
import '../../../../core/utils/spell_learn.dart';
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
/// * **CİHAZ DENETÇİSİ (2026-11-25, kullanıcı: "altı çizilmeli Word'deki
///   gibi"):** yerleşik motor yalnız ÖNERİ bulabildiği kelimenin altını
///   çiziyordu; sözlüğü küçük olduğundan "petnr", "nabr", "nasılsn" gibi
///   açık yanlışların çoğunda öneri yok → çizgi de yoktu (KÖK NEDEN). Öneri
///   bulunamayan bilinmeyen kelimeler Android'in yazım denetçisine (Gboard)
///   TOPLU sorulur ([_judge], [_pumpNative]); yanlış derse altı çizilir,
///   önerileri menüye gelir. Kişisel sözlük/sık kelime/“sözlüğe ekle” hep
///   önce gelir (sorulmaz). Web'de ve denetçisiz cihazda eski davranış.
class SpellMarks extends ChangeNotifier {
  SpellMarks._(this.controller) : _text = controller.text {
    controller.addListener(_onText);
    AutoSpell.mode.addListener(_restart);
    AutoSpell.revision.addListener(_restart);
    AutoSpell.checkDone.addListener(notifyListeners);
    _nativeTick.addListener(_onNative);
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
    AutoSpell.checkDone.removeListener(notifyListeners);
    _nativeTick.removeListener(_onNative);
    _timer?.cancel();
    _disposed = true;
    dispose();
  }

  List<SpellMark> _marks = const [];
  List<SpellMark> get marks => muted ? const [] : _marks;

  /// Alan işaretli bir maddeyse (sahibi her kurulumda yazar): ayar
  /// [AutoSpell.checkDone] kapalıyken çizgi ve öneri menüsü yok.
  bool done = false;
  void setDone(bool v) {
    if (v == done) return;
    done = v;
    notifyListeners();
  }

  bool get muted => done && !AutoSpell.checkDone.value;

  String _text;

  /// Son yazımın imleci: o an yazılan kelimenin çizgisi gizlenir.
  int editAt = -1;
  Timer? _timer;

  /// [offset] (ekran metni) altı çizili bir kelimenin içinde mi.
  SpellMark? at(int offset) {
    for (final k in marks) {
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

  /// Cihaz denetçisinden yanıt geldi: yazım sürmüyorsa yeniden denetle
  /// (yazım sürüyorsa duraklamadaki denetim zaten gelecek).
  void _onNative() {
    if (_timer?.isActive ?? false) return;
    _schedule(Duration.zero);
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
          _words[t.word] = _judge(t.word, memory);
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
    _pumpNative();
    if (_marks.isEmpty && out.isEmpty) return;
    _marks = out;
    notifyListeners();
  }

  // ---- Cihaz yazım denetçisi (Android: Gboard) ---------------------------

  /// Testte cihaz denetçisinin yerine geçer (null = platform).
  @visibleForTesting
  static Future<List<SuggestionSpan>?> Function(String text)? nativeCheck;

  /// Kelime → cihazın önerileri (null = cihaz doğru buldu). Hafızadan
  /// bağımsız: [AutoSpell.revision]'da boşalmaz.
  static final Map<String, List<String>?> _native = {};
  static final Set<String> _nativeQueue = {};

  /// Yanıtı beklenen kelimeler (önbellek o arada boşalırsa yeniden
  /// sıraya girmesin).
  static final Set<String> _nativeAsking = {};
  static final _nativeTick = ValueNotifier<int>(0);
  static bool _nativeBusy = false;
  static int _nativeFails = 0;
  static const _nativeBatch = 40;
  static final _service = DefaultSpellCheckService();

  /// Flutter'ın kendi yazım denetimiyle aynı kapı: Android'de Gboard'un
  /// denetçisi açıksa (`nativeSpellCheckServiceDefined`; yoksa oturum
  /// açılamaz). Art arda hatada oturum boyu kapanır.
  static bool get _nativeOn =>
      _nativeFails < 5 &&
      (nativeCheck != null ||
          (!kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android &&
              WidgetsBinding
                  .instance
                  .platformDispatcher
                  .nativeSpellCheckServiceDefined));

  /// Kelimenin işareti: önce yerleşik motor; önerisi yoksa ve kelime
  /// bilinmiyorsa cihaz denetçisinin yanıtı (henüz yoksa sıraya girer,
  /// yanıt gelince yeniden denetlenir).
  static ({List<String> list, bool hint})? _judge(String w, SpellMemory m) {
    final s = SpellEngine.suggestions(w, m);
    if (s != null ||
        w.length < 3 ||
        isCjk(w) ||
        m.keep.contains(w) ||
        m.known(w) ||
        !_nativeOn) {
      return s;
    }
    if (!_native.containsKey(w)) {
      if (!_nativeAsking.contains(w)) _nativeQueue.add(w);
      return null;
    }
    final list = _native[w];
    if (list == null) return null;
    return (
      list: [
        for (final x in list)
          if (!m.isRejected(w, x)) x,
      ].take(4).toList(),
      hint: false,
    );
  }

  /// Sıradaki kelimeleri tek istekte (boşlukla dizilmiş) sorar; denetçi
  /// aynı anda tek istek kabul eder.
  static void _pumpNative() {
    if (_nativeBusy || _nativeQueue.isEmpty || !_nativeOn) return;
    final batch = _nativeQueue.take(_nativeBatch).toList();
    _nativeQueue.removeAll(batch);
    _nativeAsking.addAll(batch);
    _nativeBusy = true;
    unawaited(_askNative(batch));
  }

  static Future<List<SuggestionSpan>?> _platformCheck(String text) =>
      _service.fetchSpellCheckSuggestions(const Locale('tr', 'TR'), text);

  static Future<void> _askNative(List<String> batch) async {
    final starts = <int>[];
    final text = StringBuffer();
    for (final w in batch) {
      if (text.isNotEmpty) text.write(' ');
      starts.add(text.length);
      text.write(w);
    }
    List<SuggestionSpan>? spans;
    try {
      spans = await (nativeCheck ?? _platformCheck)(text.toString());
    } catch (_) {
      spans = null;
    }
    _nativeBusy = false;
    _nativeAsking.removeAll(batch);
    if (spans == null) {
      // Meşgul (yazım düzeltmenin sorusu sürüyor) ya da hata: kelimeler
      // sıraya döner, sonraki denetimde yeniden sorulur.
      _nativeFails++;
      _nativeQueue.addAll(batch);
      return;
    }
    _nativeFails = 0;
    if (_native.length > 20000) _native.clear();
    final flagged = <String>[];
    for (var i = 0; i < batch.length; i++) {
      final w = batch[i];
      final start = starts[i];
      final span = spans
          .where(
            (s) => s.range.start == start && s.range.end == start + w.length,
          )
          .firstOrNull;
      final list = span == null
          ? null
          : <String>{
              for (final x in span.suggestions)
                if (x.trim().isNotEmpty && trLower(x) != w) trLower(x),
            }.toList();
      // Yalnız büyük harf istiyorsa ("ahmet" → "Ahmet": özel ad, cümle
      // başı) yanlış sayılmaz.
      final caseOnly =
          span != null && span.suggestions.any((x) => trLower(x) == w);
      if (list == null || caseOnly) {
        _native[w] = null;
        continue;
      }
      _native[w] = list;
      flagged.add(w);
    }
    if (flagged.isNotEmpty) {
      // Önbellekte "işaretsiz" duruyorlardı: yeniden karar verilsin.
      for (final w in flagged) {
        _words.remove(w);
      }
      _paras.clear();
      _nativeTick.value++;
    }
    _pumpNative();
  }

  /// Testler arası durağan önbellekleri boşaltır.
  @visibleForTesting
  static void debugReset() {
    _words.clear();
    _paras.clear();
    _native.clear();
    _nativeQueue.clear();
    _nativeAsking.clear();
    _nativeBusy = false;
    _nativeFails = 0;
    nativeCheck = null;
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
  void replace(String to, {bool learn = true}) {
    if (learn) AutoSpell.recordSuggestionPick(typed, to);
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
  // ELLE DÜZELT (kullanıcı 2026-11-24 + 2026-11-25: "Elle düzeltilen yazımlar
  // öğrenilmeli"): öneri yanlış ya da yoksa doğrusu yazılır ve varsayılan
  // olarak öğrenme hafızasına kaydedilir (hem `yazılan → doğru` hem sözlük).
  Future<void> manual() async {
    final host = state.context;
    final res = await showDialog<({String text, bool learn})>(
      context: host,
      builder: (ctx) => _ManualFixDialog(initial: typed),
    );
    if (res == null || !state.mounted) return;
    final now = state.textEditingValue.text;
    final w = res.text.trim();
    if (w.isEmpty || w == typed || mark.end > now.length) return;
    if (now.substring(mark.start, mark.end) != typed) return;
    if (res.learn) {
      AutoSpell.learnManualFix(typed, w);
    }
    state.userUpdateTextEditingValue(
      TextEditingValue(
        text: now.replaceRange(mark.start, mark.end, w),
        selection: TextSelection.collapsed(offset: mark.start + w.length),
      ),
      SelectionChangedCause.toolbar,
    );
  }

  return NoteSelectionToolbar.spell(
    editableState: state,
    word: typed,
    isHint: mark.hint,
    suggestions: [for (final s in options) item(s, () => replace(s))],
    actions: [
      item(l10n.spellManualFix, () => unawaited(manual())),
      item(l10n.spellAddToDictionary, () => AutoSpell.addToDictionary(typed)),
      if (first != null)
        item(l10n.spellAlwaysFix(first), () {
          AutoSpell.alwaysFix(typed, first);
          replace(first, learn: false);
        }),
      item(
        l10n.spellKeepInNote,
        () => AutoSpell.keepInNote(typed, mark.hint ? null : first),
      ),
    ],
  );
}

class _ManualFixDialog extends StatefulWidget {
  const _ManualFixDialog({required this.initial});
  final String initial;

  @override
  State<_ManualFixDialog> createState() => _ManualFixDialogState();
}

class _ManualFixDialogState extends State<_ManualFixDialog> {
  late final _c = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );
  late bool _learn = AutoSpell.learning.value;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final text = AppText.of(theme);

    void done() {
      final value = _c.text.trim();
      if (value.isEmpty) return;
      Navigator.pop(context, (text: value, learn: _learn));
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: tokens.hairline),
      ),
      backgroundColor: scheme.surfaceContainerLowest,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSpace.xxl + AppSpace.xs,
                    height: AppSpace.xxl + AppSpace.xs,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                    child: Icon(
                      Icons.spellcheck_rounded,
                      size: AppIconSize.m,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.spellManualFix,
                          style: text.rowTitle.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer.withValues(
                              alpha: AppAlpha.soft,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            widget.initial,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.badge.copyWith(
                              color: scheme.error,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: scheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.l),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _c,
                builder: (context, value, _) {
                  final trimmed = value.text.trim();
                  final changed = trimmed.isNotEmpty && trimmed != widget.initial;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const ValueKey('spell-manual-field'),
                        controller: _c,
                        autofocus: true,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: l10n.spellManualHint,
                          filled: true,
                          fillColor: scheme.surfaceContainerLow,
                          prefixIcon: Icon(
                            Icons.edit_outlined,
                            size: AppIconSize.s,
                            color: scheme.primary,
                          ),
                          suffixIcon: value.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: AppIconSize.s,
                                  ),
                                  onPressed: _c.clear,
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            borderSide: BorderSide(color: tokens.hairline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            borderSide: BorderSide(color: tokens.hairline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.m),
                            borderSide: BorderSide(
                              color: scheme.primary,
                              width: AppSpace.xxs,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => done(),
                      ),
                      const SizedBox(height: AppSpace.m),
                      Material(
                        color: _learn
                            ? scheme.primaryContainer.withValues(
                                alpha: AppAlpha.soft,
                              )
                            : scheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          side: BorderSide(
                            color: _learn
                                ? tokens.resolvedAccentBorder(scheme)
                                : tokens.hairline,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const ValueKey('spell-manual-learn-toggle'),
                          onTap: () => setState(() => _learn = !_learn),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.m,
                              vertical: AppSpace.s,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _learn
                                      ? Icons.auto_fix_high_rounded
                                      : Icons.auto_fix_off_outlined,
                                  size: AppIconSize.s,
                                  color: _learn
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppSpace.s),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.spellManualLearn,
                                        style: text.label.copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: AppWeight.strong,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpace.xxs),
                                      Text(
                                        changed
                                            ? '${widget.initial} → $trimmed'
                                            : l10n.spellManualLearnHint,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.meta.copyWith(
                                          color: changed && _learn
                                              ? scheme.primary
                                              : scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _learn,
                                  onChanged: (v) => setState(() => _learn = v),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpace.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s),
                  FilledButton(
                    key: const ValueKey('spell-manual-ok'),
                    onPressed: done,
                    child: Text(
                      MaterialLocalizations.of(context).okButtonLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
