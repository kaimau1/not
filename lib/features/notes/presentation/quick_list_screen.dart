import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/keyboard_snap.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/notes_repository.dart';
import '../data/quick_entry_memory.dart';
import '../domain/note.dart';
import '../domain/note_templates.dart';
import '../domain/note_type.dart';
import '../domain/quick_entry.dart';
import '../domain/smart_list.dart';
import 'quick_entry_bar.dart';

/// Hızlı liste ekranının girdisi: hangi şablon, hangi öneriler.
@immutable
class QuickListArgs {
  const QuickListArgs({
    required this.kind,
    required this.title,
    required this.icon,
    required this.accent,
    this.type = NoteType.checklist,
    this.seedItems = const [],
    this.initialItems = const [],
    this.groups = const [],
    this.grocery = false,
    this.smart = false,
    this.packingGroups = const [],
  });

  /// Hafıza anahtarı (`b:shopping`, `u:<kimlik>`): sık eklenenler buna göre.
  final String kind;
  final String title;
  final IconData icon;
  final Color accent;
  final NoteType type;

  /// Hazır şablonun varsayılan maddeleri — listeye GİRMEZ (kullanıcı isteği
  /// 2026-11-15: "üstteki hazır işaretliler boş gelecek"), kullanıcının henüz
  /// geçmişi yokken "Sık eklediklerin"in tohumudur.
  final List<String> seedItems;

  /// Kendi şablonumun maddeleri: liste bunlarla dolu açılır.
  final List<String> initialItems;

  final List<TemplateSuggestionGroup> groups;

  /// Market sözlüğü ve reyon sırası kullanılsın mı.
  final bool grocery;

  /// **AKILLI LİSTE** (bkz. `smart_list.dart`): market + bavul sözlüğü
  /// birlikte; tür maddelerden ya da "bavul listesi" gibi bir öbekten
  /// bulunur, başlık/öneriler/sıra türe göre değişir. [groups] alışverişin,
  /// [packingGroups] bavulun öneri grupları.
  final bool smart;

  final List<TemplateSuggestionGroup> packingGroups;
}

@immutable
class QuickListResult {
  const QuickListResult(
    this.content, {
    this.open = false,
    this.items = const [],
  });

  final NoteTemplateContent content;

  /// Not oluşunca editörde açılsın mı ("Notta aç").
  final bool open;

  final List<QuickItem> items;
}

/// Ekranı açar; vazgeçilirse ya da liste boşsa null döner.
Future<QuickListResult?> showQuickList(
  BuildContext context,
  QuickListArgs args,
) => Navigator.of(context, rootNavigator: true).push<QuickListResult>(
  MaterialPageRoute(builder: (_) => QuickListScreen(args: args)),
);

/// **GEÇEN SEFERDEN KALANLAR**: aynı başlıklı en yeni listenin
/// İŞARETLENMEMİŞ maddeleri (çöpteki/arşivdeki notlar sayılmaz).
List<String> quickLeftovers(Iterable<Note> notes, String title) {
  // "Yapılacaklar · 15 Kasım" → "Yapılacaklar": tarihli başlıkta dünkü
  // liste de eşleşsin.
  final want = quickAscii(title.split(' · ').first);
  if (want.isEmpty) return const [];
  return quickLeftoversWhere(
    notes,
    (n) => quickAscii(n.displayTitle).startsWith(want),
  );
}

/// Akıllı listenin hafıza anahtarı TÜRE göre (AL-1, 2026-11-17): market ve
/// bavul "Sık eklediklerin"i tek anahtarda karışıyordu. Düz liste [base]
/// anahtarında kalır (eski kayıtlar da orada).
String smartMemoryKind(String base, SmartListKind kind) => switch (kind) {
  SmartListKind.shopping => '$base:market',
  SmartListKind.packing => '$base:bavul',
  SmartListKind.generic => base,
};

/// Listelerin sırayla karışımı (her listeden birer), yinelenen atlanır.
List<String> quickInterleave(List<List<String>> lists, {int count = 16}) {
  final out = <String>[];
  final seen = <String>{};
  for (var i = 0; out.length < count; i++) {
    var any = false;
    for (final l in lists) {
      if (i >= l.length) continue;
      any = true;
      if (seen.add(quickItemKey(l[i])) && out.length < count) out.add(l[i]);
    }
    if (!any) break;
  }
  return out;
}

/// [match]e uyan en yeni listenin işaretlenmemiş maddeleri.
List<String> quickLeftoversWhere(
  Iterable<Note> notes,
  bool Function(Note) match,
) {
  Note? latest;
  for (final n in notes) {
    if (n.deletedAt != null || n.archivedAt != null) continue;
    if (n.type != NoteType.checklist && n.type != NoteType.ordered) continue;
    if (!match(n)) continue;
    final at = n.updatedAt ?? n.createdAt;
    final best = latest?.updatedAt ?? latest?.createdAt;
    if (latest == null || (at != null && (best == null || at.isAfter(best)))) {
      latest = n;
    }
  }
  if (latest == null) return const [];
  final seen = <String>{};
  return [
    for (final i in latest.items)
      if (!i.checked &&
          !i.header &&
          i.text.trim().isNotEmpty &&
          seen.add(quickItemKey(i.text)))
        i.text.trim(),
  ].take(30).toList();
}

class _Row {
  _Row(this.id, this.item);

  final int id;
  QuickItem item;

  /// Sütun değiştirse de (iki sütunda yarı sınırı kayar) aynı öğe kalır:
  /// giriş animasyonu yeniden oynamaz.
  final key = GlobalKey();
}

typedef _Tab = ({String label, IconData? icon, List<String> items, bool all});

/// **HIZLI LİSTE** (kullanıcı isteği 2026-11-15: "çok düz; direkt bir not
/// sayfası açılsın, 2 sütun varsayılan, seçenekler daha kompakt ve akıllı,
/// kişi tık tık tık hemen listesini oluştursun, sesle de; üst satıra yan yana
/// yazar, o yazarken aşağıda canlı listeye eklenir").
///
/// Liste şablonu artık levhadaki önizleme yerine BU sayfada kurulur: üstte
/// hızlı giriş satırı ([QuickEntryBar]), ortada notun kendisi gibi görünen
/// canlı liste, altta kompakt öneri şeridi (sık eklenenler + reyonlar).
/// "Bitti" (ya da geri) listeyi nota çevirir; hiçbir şey eklenmediyse not
/// oluşmaz.
///
/// AKICILIK: yerel durum `ValueNotifier` + dar dinleyici; yazarken yalnız
/// giriş satırı kurulur, madde eklenince yalnız YENİ satır (değişmeyen satır
/// aynı örnek — `_rowCache`). Boy animasyonu yok: yeni satır yerinde belirir
/// (solma + ölçek, yalnız boyama).
class QuickListScreen extends ConsumerStatefulWidget {
  const QuickListScreen({super.key, required this.args});

  final QuickListArgs args;

  @override
  ConsumerState<QuickListScreen> createState() => _QuickListScreenState();
}

class _QuickListScreenState extends ConsumerState<QuickListScreen>
    with SingleTickerProviderStateMixin {
  late final _title = TextEditingController(text: widget.args.title);
  final _focus = FocusNode();
  final _entry = GlobalKey<QuickEntryBarState>();
  final _scroll = ScrollController();

  final _rows = <_Row>[];
  int _seq = 0;
  int? _lastId;

  /// Liste değişti (satır eklendi/çıktı/güncellendi).
  final _rev = ValueNotifier<int>(0);
  late final ValueNotifier<bool> _twoColumns;
  late final ValueNotifier<bool> _aisle;
  final _tab = ValueNotifier<int>(0);

  /// Vurgulanacak satır (zaten listede olan madde yeniden yazıldı): (kimlik,
  /// sayaç) — sayaç aynı satırın art arda vurgusunu da duyurur.
  final _pulse = ValueNotifier<(int, int)>((-1, 0));

  QuickLexicon? _lexicon;
  QuickParser? _parser;
  bool _done = false;

  /// "Sık eklediklerin" ve "Geçen seferden kalanlar" TÜR başına bir kez
  /// (akıllı listede tür değişince şerit o türünkini gösterir; AL-1).
  final _frequentBy = <SmartListKind, List<String>>{};
  final _leftoversBy = <SmartListKind, List<String>>{};

  /// Düz listede tür hep [SmartListKind.generic]: tek anahtar.
  SmartListKind get _memoKind =>
      widget.args.smart ? _kind.value : SmartListKind.generic;

  List<String> _frequentFor(SmartListKind kind) =>
      _frequentBy[kind] ??= _computeFrequent(kind);

  List<String> _computeFrequent(SmartListKind kind) {
    final memory = ref.read(quickEntryMemoryProvider);
    final base = widget.args.kind;
    if (!widget.args.smart) {
      final top = memory.top(base, count: 16);
      // Önce kullanıcının sık eklediği, boş kalan yer şablonun tohumu.
      final have = {for (final t in top) quickItemKey(t)};
      return [
        ...top,
        for (final s in widget.args.seedItems)
          if (have.add(quickItemKey(s))) s,
      ].take(16).toList();
    }
    // Türe bölünmeden önceki ortak kayıt ([base]) türüne süzülerek katılır.
    List<String> legacy(int Function(QuickItem) groupOf) => [
      for (final t in memory.top(base, count: 32))
        if (groupOf(QuickItem(name: t)) >= 0) t,
    ];
    final market = memory.top(smartMemoryKind(base, SmartListKind.shopping));
    final bavul = memory.top(smartMemoryKind(base, SmartListKind.packing));
    return switch (kind) {
      SmartListKind.shopping => quickInterleave([
        market,
        legacy(_groceryGroupOf),
      ]),
      SmartListKind.packing => quickInterleave([
        bavul,
        legacy(_packingGroupOf),
      ]),
      SmartListKind.generic => quickInterleave([
        market,
        bavul,
        memory.top(base, count: 16),
      ]),
    };
  }

  List<String> _leftoversFor(SmartListKind kind) =>
      _leftoversBy[kind] ??= _computeLeftovers(kind);

  /// Düz listede aynı başlıklı en yeni liste; akıllı listede başlığa değil
  /// TÜRE göre (AL-1): maddeleri aynı türe çıkan en yeni liste — başlığı
  /// elle "Antalya" yapılmış bavul listesi de bulunur.
  List<String> _computeLeftovers(SmartListKind kind) {
    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    if (!widget.args.smart) return quickLeftovers(notes, widget.args.title);
    if (kind == SmartListKind.generic) return const [];
    bool known(QuickLexicon? lex, String text) =>
        (lex?.groupOf(quickBaseName(text)) ?? -1) >= 0;
    return quickLeftoversWhere(
      notes,
      (n) =>
          smartKindOf([
            for (final i in n.items)
              if (!i.header && i.text.trim().isNotEmpty)
                (
                  grocery: known(_grocery, i.text),
                  packing: known(_packing, i.text),
                ),
          ]) ==
          kind,
    );
  }

  /// Kapanış: giriş satırı ve öneri şeridi solar, liste (not) kalır.
  late final AnimationController _closing = AnimationController(vsync: this);

  bool get _hasAisles => widget.args.grocery || widget.args.smart;

  // ── Akıllı liste ──────────────────────────────────────────────────────
  /// Bulunan tür (akıllı değilse hep düz).
  final _kind = ValueNotifier<SmartListKind>(SmartListKind.generic);

  /// "bavul listesi" gibi öbekle söylenen tür: maddelerden önce gelir.
  SmartListKind? _kindSaid;
  QuickLexicon? _packing;
  QuickLexicon? _grocery;

  /// Son kendiliğinden konan başlık: kullanıcı başlığı elle değiştirdiyse
  /// tür değişse de dokunulmaz.
  late String _autoTitle = widget.args.title;

  int _packingGroupOf(QuickItem i) => _packing?.groupOf(i.name) ?? -1;
  int _groceryGroupOf(QuickItem i) => _grocery?.groupOf(i.name) ?? -1;

  void _updateKind() {
    if (!widget.args.smart) return;
    final kind =
        _kindSaid ??
        smartKindOf([
          for (final r in _rows)
            (
              grocery: _groceryGroupOf(r.item) >= 0,
              packing: _packingGroupOf(r.item) >= 0,
            ),
        ]);
    if (kind == _kind.value) return;
    _kind.value = kind;
    _tab.value = 0;
    final l10n = context.l10n;
    final title = switch (kind) {
      SmartListKind.shopping => l10n.tplShoppingName,
      SmartListKind.packing => l10n.smartListPacking,
      SmartListKind.generic => l10n.smartListGeneric,
    };
    if (_title.text.trim() == _autoTitle.trim()) _title.text = title;
    _autoTitle = title;
    // Sıra türe bağlı (bavulda bakım grubu, markette kişisel bakım reyonu).
    _rev.value++;
  }

  @override
  void initState() {
    super.initState();
    _twoColumns = ValueNotifier(ref.read(quickListTwoColumnsProvider));
    _aisle = ValueNotifier(ref.read(quickListAisleSortProvider));
    for (final t in widget.args.initialItems) {
      if (t.trim().isEmpty) continue;
      _rows.add(_Row(_seq++, QuickItem(name: t.trim(), how: QuickHow.exact)));
    }
    focusAfterRouteOpens(this, _focus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parser != null) return;
    final memory = ref.read(quickEntryMemoryProvider);
    final lex = buildQuickLexicon(
      locale: context.l10n.localeName,
      // Akıllı liste market sözlüğünü de ayrıştırıcıya katar (hata
      // 2026-11-17: `smartListArgs` grocery vermiyordu; "süt yumurta ekmek"
      // üç yerine TEK madde oluyordu, yakın eşleşme düzeltmesi çalışmıyordu).
      grocery: widget.args.grocery || widget.args.smart,
      groups: widget.args.groups,
      learned: [
        ...memory.all(widget.args.kind),
        if (widget.args.smart)
          for (final k in [SmartListKind.shopping, SmartListKind.packing])
            ...memory.all(smartMemoryKind(widget.args.kind, k)),
      ],
      extra: [...widget.args.seedItems, ...widget.args.initialItems],
    );
    if (widget.args.smart) {
      // Market önce eklendi: iki sözlükte de olan madde (şampuan) market
      // reyonunu taşır; bavul sırası ayrı sözlükten okunur.
      for (final (text, group) in packingEntries(context.l10n.localeName)) {
        lex.add(text, group: group);
      }
      lex.addAll([for (final g in widget.args.packingGroups) ...g.items]);
      _packing = packingLexicon(context.l10n.localeName);
      _grocery = groceryLexicon(context.l10n.localeName);
    }
    _lexicon = lex;
    _parser = buildQuickParser(lex, memory: memory);
    for (final r in _rows) {
      final g = lex.groupOf(r.item.name);
      if (g >= 0) {
        r.item = QuickItem(name: r.item.name, group: g, how: QuickHow.exact);
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    _scroll.dispose();
    _rev.dispose();
    _twoColumns.dispose();
    _aisle.dispose();
    _tab.dispose();
    _kind.dispose();
    _pulse.dispose();
    _closing.dispose();
    super.dispose();
  }

  // ── Liste işlemleri ───────────────────────────────────────────────────

  _Row? _find(String text) {
    final key = quickItemKey(text);
    for (final r in _rows) {
      if (quickItemKey(r.item.text) == key) return r;
    }
    return null;
  }

  void _add(List<QuickItem> items) {
    _Row? touched;
    var said = false;
    for (final item in items) {
      // "Bavul listesi", "alışveriş listesi": madde değil, listenin türü.
      if (widget.args.smart) {
        final k = smartKindFromPhrase(item.name);
        if (k != null) {
          _kindSaid = k;
          said = true;
          continue;
        }
      }
      final existing = _find(item.text);
      if (existing != null) {
        // Zaten listede: yenisi eklenmez, miktar geldiyse güncellenir.
        if (item.qty.isNotEmpty && item.qty != existing.item.qty) {
          existing.item = existing.item.withQty(item.qty);
        }
        _pulse.value = (existing.id, _pulse.value.$2 + 1);
        touched = existing;
        continue;
      }
      final row = _Row(_seq++, item);
      _rows.add(row);
      _lastId = row.id;
      touched = row;
    }
    if (said) _updateKind();
    if (touched == null) return;
    _rev.value++;
    _updateKind();
    _reveal(touched);
  }

  void _attachQty(String qty) {
    final id = _lastId;
    if (id == null) return;
    for (final r in _rows) {
      if (r.id != id) continue;
      r.item = r.item.withQty(qty);
      _pulse.value = (r.id, _pulse.value.$2 + 1);
      _rev.value++;
      return;
    }
  }

  void _remove(_Row row) {
    _rows.remove(row);
    _rowCache.remove(row.id);
    _rev.value++;
    _updateKind();
  }

  /// Otomatik düzeltmeyi geri alır: madde yazıldığı gibi kalır ve bu
  /// düzeltme bir daha uygulanmaz.
  void _revert(_Row row) {
    final item = row.item;
    if (!item.corrected || item.typed.isEmpty) return;
    ref.read(quickEntryMemoryProvider.notifier).reject(item.typed, item.name);
    row.item = QuickItem(
      name: quickCapitalize(item.typed),
      qty: item.qty,
      typed: item.typed,
    );
    _rev.value++;
    ScaffoldMessenger.of(context)
        .showMessage(context.l10n.quickListRestored(item.typed));
  }

  void _addChip(String text) {
    final e = _lexicon?.exact(text);
    _add([
      QuickItem(
        name: text,
        group: e?.group ?? -1,
        how: QuickHow.exact,
        typed: text,
      ),
    ]);
  }

  /// Yeni/dokunulan satır görünür alana kayar (yumuşak; yalnız kaydırma).
  void _reveal(_Row row) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = row.key.currentContext;
      if (ctx == null || !mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: AppMotion.of(context, AppMotion.short),
          curve: AppMotion.curveOf(context, AppMotion.standard),
        ),
      );
    });
  }

  List<_Row> _ordered() {
    if (!_hasAisles || !_aisle.value) return _rows;
    if (!widget.args.smart) {
      return quickSortByGroup(_rows, (r) => r.item.group);
    }
    final kind = _kind.value;
    return quickSortByGroup(
      _rows,
      (r) => smartRank(
        kind,
        grocery: _groceryGroupOf(r.item),
        packing: _packingGroupOf(r.item),
      ),
    );
  }

  // ── Bitiş ─────────────────────────────────────────────────────────────

  Future<void> _finish({bool open = false, bool discard = false}) async {
    if (_done) return;
    _entry.currentState?.flush();
    if (discard || _rows.isEmpty) {
      _done = true;
      Navigator.of(context).pop();
      return;
    }
    _done = true;
    final ordered = _ordered();
    final items = [for (final r in ordered) r.item];
    final title = _title.text.trim().isEmpty
        ? widget.args.title
        : _title.text.trim();
    ref.read(quickEntryMemoryProvider.notifier).record(
      smartMemoryKind(widget.args.kind, _memoKind),
      [for (final i in items) i.name],
    );
    teachSpellFromQuickItems(items);
    final result = QuickListResult(
      (
        type: widget.args.type,
        title: title,
        body: '',
        items: [for (final i in items) i.text],
        columns: _twoColumns.value ? 2 : 1,
      ),
      open: open,
      items: items,
    );
    // NOTA DÖNÜŞÜM: giriş satırı ve öneriler solar, liste yerinde kalır —
    // sonra sayfa kapanır. Yalnız boyama.
    FocusManager.instance.primaryFocus?.unfocus();
    _closing.duration = AppMotion.of(context, AppMotion.short);
    await _closing.forward();
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  // ── Kurulum ───────────────────────────────────────────────────────────

  final Map<int, (QuickItem, Widget)> _rowCache = {};

  Widget _rowFor(_Row row) {
    final hit = _rowCache[row.id];
    if (hit != null && identical(hit.$1, row.item)) return hit.$2;
    final w = _QuickRow(
      key: row.key,
      id: row.id,
      item: row.item,
      pulse: _pulse,
      onRemove: () => _remove(row),
      onRevert: () => _revert(row),
    );
    _rowCache[row.id] = (row.item, w);
    return w;
  }

  List<_Tab> _tabs(AppLocalizations l10n, [SmartListKind? kind]) {
    final k = widget.args.smart ? (kind ?? _kind.value) : SmartListKind.generic;
    final frequent = _frequentFor(k);
    final leftovers = _leftoversFor(k);
    return [
      if (frequent.isNotEmpty)
        (
          label: l10n.quickListFrequent,
          icon: Icons.star_outline,
          items: frequent,
          all: false,
        ),
      if (leftovers.isNotEmpty)
        (
          label: l10n.quickListLeftovers,
          icon: Icons.history,
          items: leftovers,
          all: true,
        ),
      for (final g in _groupsFor(kind))
        (label: g.label, icon: null, items: g.items, all: false),
    ];
  }

  /// Öneri grupları: akıllı listede türe göre (düz listede ikisi de).
  List<TemplateSuggestionGroup> _groupsFor(SmartListKind? kind) {
    if (!widget.args.smart) return widget.args.groups;
    return switch (kind ?? _kind.value) {
      SmartListKind.shopping => widget.args.groups,
      SmartListKind.packing => widget.args.packingGroups,
      SmartListKind.generic => [
        ...widget.args.groups,
        ...widget.args.packingGroups,
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final tabs = _tabs(l10n);
    final fade = ReverseAnimation(_closing);
    // Gövdenin parçaları BİR KEZ kurulur: klavye oturunca [KeyboardSnap]
    // yalnız dolguyu yeniler, aynı örnekler yeniden kurulmaz.
    final entry = FadeTransition(
      opacity: fade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.m,
          AppSpace.xs,
          AppSpace.m,
          0,
        ),
        child: _parser == null
            ? const SizedBox.shrink()
            : QuickEntryBar(
                key: _entry,
                parser: _parser!,
                focusNode: _focus,
                onItems: _add,
                onTrailingQty: _attachQty,
                // "Bitti" / "bu kadar" söylenince dinleme biter ve liste
                // nota çevrilir (Bitti düğmesiyle aynı yol).
                onDoneWord: () => unawaited(_finish()),
              ),
      ),
    );
    final list = ListenableBuilder(
      listenable: Listenable.merge([_rev, _twoColumns, _aisle]),
      builder: (context, _) {
        final rows = _ordered();
        if (rows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: Text(
                // Akıllı listede türün söylenebildiği de anlatılır (AL-1).
                widget.args.smart ? l10n.smartListHint : l10n.quickListEmpty,
                textAlign: TextAlign.center,
                style: text.body.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          );
        }
        // İKİ SÜTUN notla AYNI düzen (ItemsEditor): ilk yarı
        // solda, ikinci yarı sağda.
        final two = _twoColumns.value;
        final half = two ? (rows.length + 1) ~/ 2 : rows.length;
        return SingleChildScrollView(
          key: const ValueKey('quick-list-scroll'),
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s,
            0,
            AppSpace.s,
            AppSpace.l,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (var i = 0; i < half; i++) _rowFor(rows[i])],
                ),
              ),
              if (two)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = half; i < rows.length; i++) _rowFor(rows[i]),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
    // Şerit yoksa da kayar kutu durur: gezinme çubuğu payını o veriyor,
    // ağacın şekli de değişmiyor.
    Widget chipPanel(List<_Tab> tabs) => tabs.isEmpty
        ? const SizedBox.shrink()
        : FadeTransition(
            opacity: fade,
            child: _ChipPanel(
              key: ValueKey('quick-chips-${tabs.length}'),
              tabs: tabs,
              tab: _tab,
              rev: _rev,
              has: (t) => _find(t) != null,
              onAdd: _addChip,
              onAddAll: (items) => _add([
                for (final t in items)
                  QuickItem(
                    name: quickBaseName(t),
                    qty: t == quickBaseName(t)
                        ? ''
                        : t
                              .substring(quickBaseName(t).length)
                              .trim()
                              .replaceAll(RegExp(r'^\(|\)$'), ''),
                    group: _lexicon?.groupOf(t) ?? -1,
                    how: QuickHow.exact,
                    typed: t,
                  ),
              ]),
            ),
          );
    // Akıllı listede öneriler TÜRLE değişir: yalnız şerit dinler.
    final chips = widget.args.smart
        ? ValueListenableBuilder<SmartListKind>(
            valueListenable: _kind,
            builder: (context, kind, _) => chipPanel(_tabs(l10n, kind)),
          )
        : chipPanel(tabs);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_finish());
      },
      // KLAVYE KASMASI (kullanıcı bulgusu 2026-11-16: "şablon eklenirken,
      // yazarken, madde eklenirken alttaki hazır maddeler klavye açılıp
      // kapanırken kasıyor"). KÖK NEDEN editördekiyle aynı (F60.S5): Scaffold
      // gövdeyi klavyenin HER karesinde kısaltıyordu — iskelet, liste ve öneri
      // şeridi kare kare kurulup diziliyordu (S49: 6 karede 420 kurulum, 168
      // dizilim). Artık editörün kanalı: Scaffold kararlı MediaQuery görür,
      // gövde klavye durunca TEK seferde oturur, öneri şeridi klavyeyi yalnız
      // boyamada ([KeyboardSlide]) izler.
      child: KeyboardInsetScope(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            leading: IconButton(
              tooltip: l10n.back,
              icon: const Icon(Icons.arrow_back),
              onPressed: _finish,
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                if (widget.args.smart)
                  ValueListenableBuilder<SmartListKind>(
                    valueListenable: _kind,
                    builder: (context, kind, _) => Icon(
                      switch (kind) {
                        SmartListKind.shopping => Icons.shopping_cart_outlined,
                        SmartListKind.packing => Icons.luggage_outlined,
                        SmartListKind.generic => widget.args.icon,
                      },
                      color: widget.args.accent,
                      size: AppIconSize.m,
                    ),
                  )
                else
                  Icon(
                    widget.args.icon,
                    color: widget.args.accent,
                    size: AppIconSize.m,
                  ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: TextField(
                    key: const ValueKey('quick-list-title'),
                    controller: _title,
                    style: text.screenTitle,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: l10n.titleHint,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder<bool>(
                valueListenable: _twoColumns,
                builder: (context, two, _) => IconButton(
                  key: const ValueKey('quick-list-columns'),
                  tooltip: two ? l10n.listOneColumn : l10n.listTwoColumns,
                  icon: Icon(
                    two
                        ? Icons.view_agenda_outlined
                        : Icons.view_column_outlined,
                  ),
                  onPressed: () {
                    _twoColumns.value = !two;
                    ref.read(quickListTwoColumnsProvider.notifier).set(!two);
                  },
                ),
              ),
              PopupMenuButton<String>(
                key: const ValueKey('quick-list-menu'),
                onSelected: (v) {
                  switch (v) {
                    case 'aisle':
                      _aisle.value = !_aisle.value;
                      ref
                          .read(quickListAisleSortProvider.notifier)
                          .set(_aisle.value);
                    case 'open':
                      unawaited(_finish(open: true));
                    case 'discard':
                      unawaited(_finish(discard: true));
                  }
                },
                itemBuilder: (context) => [
                  if (_hasAisles)
                    CheckedPopupMenuItem(
                      value: 'aisle',
                      checked: _aisle.value,
                      child: Text(l10n.quickListAisleSort),
                    ),
                  PopupMenuItem(
                    value: 'open',
                    child: Text(l10n.quickListOpenInNote),
                  ),
                  PopupMenuItem(
                    value: 'discard',
                    child: Text(l10n.quickListDiscard),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpace.s),
                child: FilledButton(
                  key: const ValueKey('quick-list-done'),
                  onPressed: _finish,
                  child: Text(l10n.quickListDone),
                ),
              ),
            ],
          ),
          // Alt güvenli alan payını [KeyboardSlide] veriyor (gezinme çubuğu,
          // klavye açıkken 0): burada uygulanırsa iki kez sayılırdı.
          body: SafeArea(
            top: false,
            bottom: false,
            child: KeyboardSnap(
              builder: (context, inset) => Padding(
                padding: EdgeInsets.only(bottom: inset),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        entry,
                        Expanded(child: list),
                        KeyboardSlide(inset: inset, child: chips),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Listenin bir satırı: boş kutu + metin + çıkar. Yeni satır yerinde belirir
/// (solma + ölçek); zaten listede olan madde yeniden yazılınca kısa bir
/// vurguyla parlar. İkisi de yalnız boyama.
class _QuickRow extends StatefulWidget {
  const _QuickRow({
    super.key,
    required this.id,
    required this.item,
    required this.pulse,
    required this.onRemove,
    required this.onRevert,
  });

  final int id;
  final QuickItem item;
  final ValueListenable<(int, int)> pulse;
  final VoidCallback onRemove;
  final VoidCallback onRevert;

  @override
  State<_QuickRow> createState() => _QuickRowState();
}

class _QuickRowState extends State<_QuickRow> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this);
  late final AnimationController _tint = AnimationController(vsync: this);

  /// Eğri BİR KEZ kurulur (her build'de yenisi dinleyici sızdırırdı).
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.pulse.addListener(_onPulse);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _enter.duration = AppMotion.of(context, AppMotion.short);
    _tint.duration = AppMotion.of(context, AppMotion.medium);
    _curve = CurvedAnimation(
      parent: _enter,
      curve: AppMotion.curveOf(context, AppMotion.enter),
    );
    _scale = Tween<double>(begin: 0.94, end: 1).animate(_curve);
    unawaited(_enter.forward());
  }

  @override
  void didUpdateWidget(_QuickRow old) {
    super.didUpdateWidget(old);
    if (!identical(old.pulse, widget.pulse)) {
      old.pulse.removeListener(_onPulse);
      widget.pulse.addListener(_onPulse);
    }
  }

  void _onPulse() {
    if (widget.pulse.value.$1 != widget.id) return;
    unawaited(_tint.forward(from: 0).then((_) => _tint.reverse()));
  }

  @override
  void dispose() {
    widget.pulse.removeListener(_onPulse);
    if (_started) _curve.dispose();
    _enter.dispose();
    _tint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final item = widget.item;
    final row = Row(
      children: [
        const SizedBox(width: AppSpace.s),
        Icon(
          Icons.check_box_outline_blank,
          size: AppIconSize.m,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpace.s),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
            child: Text(
              item.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.rowTitle,
            ),
          ),
        ),
        if (item.corrected)
          Tooltip(
            message: l10n.quickListCorrected(item.typed),
            child: InkResponse(
              key: ValueKey('quick-row-revert-${widget.id}'),
              onTap: widget.onRevert,
              radius: AppSpace.xl,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xs),
                child: Icon(
                  Icons.auto_fix_high_outlined,
                  size: AppIconSize.xs,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        InkResponse(
          key: ValueKey('quick-row-remove-${widget.id}'),
          onTap: widget.onRemove,
          radius: AppSpace.xl,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s),
            child: Tooltip(
              message: l10n.quickListRemove,
              child: Icon(
                Icons.close,
                size: AppIconSize.xs,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
    return FadeTransition(
      opacity: _curve,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _tint,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(
                alpha: AppAlpha.pressed * _tint.value,
              ),
              borderRadius: BorderRadius.circular(AppRadius.s),
            ),
            child: child,
          ),
          child: row,
        ),
      ),
    );
  }
}

/// **KOMPAKT ÖNERİ ŞERİDİ**: üstte sekmeler (sık eklenenler, geçen seferden
/// kalanlar, reyonlar), altta seçili sekmenin HENÜZ LİSTEDE OLMAYAN maddeleri
/// — iki yatay satır, boyu sabit. Dokunulan çip listeye girer ve şeritten
/// düşer.
class _ChipPanel extends StatelessWidget {
  const _ChipPanel({
    super.key,
    required this.tabs,
    required this.tab,
    required this.rev,
    required this.has,
    required this.onAdd,
    required this.onAddAll,
  });

  final List<_Tab> tabs;
  final ValueNotifier<int> tab;
  final ValueListenable<int> rev;
  final bool Function(String text) has;
  final ValueChanged<String> onAdd;
  final ValueChanged<List<String>> onAddAll;

  static const _rowHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _rowHeight,
            child: ValueListenableBuilder<int>(
              valueListenable: tab,
              builder: (context, selected, _) => ListView.separated(
                key: const ValueKey('quick-list-tabs'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
                itemBuilder: (context, i) {
                  final t = tabs[i];
                  final on = i == selected;
                  return Center(
                    child: InkWell(
                      key: ValueKey('quick-tab-$i'),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () => tab.value = i,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.s,
                          vertical: AppSpace.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (t.icon != null) ...[
                              Icon(
                                t.icon,
                                size: AppIconSize.xs,
                                color: on
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpace.xs),
                            ],
                            Text(
                              t.label,
                              style: (on ? text.section : text.label).copyWith(
                                color: on
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: _rowHeight,
            child: ListenableBuilder(
              listenable: Listenable.merge([tab, rev]),
              builder: (context, _) {
                final t = tabs[tab.value.clamp(0, tabs.length - 1)];
                final left = [
                  for (final s in t.items)
                    if (!has(s)) s,
                ];
                if (left.isEmpty) {
                  return Center(
                    child: Icon(
                      Icons.check,
                      size: AppIconSize.s,
                      color: scheme.onSurfaceVariant,
                    ),
                  );
                }
                final lead = t.all && left.length > 1 ? 1 : 0;
                return ListView.separated(
                  key: ValueKey('quick-list-chips-${tab.value}'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
                  itemCount: left.length + lead,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s),
                  itemBuilder: (context, i) {
                    if (i < lead) {
                      return Center(
                        child: ActionChip(
                          key: const ValueKey('quick-chip-all'),
                          avatar: const Icon(Icons.playlist_add),
                          label: Text(l10n.quickListAddAll),
                          onPressed: () => onAddAll(left),
                        ),
                      );
                    }
                    final s = left[i - lead];
                    return Center(
                      child: ActionChip(
                        key: ValueKey('quick-chip-$s'),
                        label: Text(s),
                        onPressed: () => onAdd(s),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
