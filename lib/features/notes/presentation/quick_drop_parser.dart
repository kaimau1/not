part of 'quick_drop_sheet.dart';

class QuickDropRecentNotifier extends Notifier<List<String>> {
  static const _key = 'quick_drop_recent';
  static const _contextKey = 'quick_drop_context_v1';
  static const maxEntries = 6;
  static const _maxContextEntries = 40;

  @override
  List<String> build() =>
      ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];

  /// Günün 4 zaman dilimi: sabah (5–11), gündüz (12–16), akşam (17–21), gece.
  static int hourBucket(int hour) => hour >= 5 && hour < 12
      ? 0
      : hour >= 12 && hour < 17
      ? 1
      : hour >= 17 && hour < 22
      ? 2
      : 3;

  void remember(String noteId, {DateTime? at}) {
    final next = [
      noteId,
      for (final id in state)
        if (id != noteId) id,
    ].take(maxEntries).toList();
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setStringList(_key, next);
    final t = at ?? DateTime.now();
    final counts = _readContext(prefs.getString(_contextKey));
    final slot = '$noteId|${t.weekday}|${hourBucket(t.hour)}';
    counts[slot] = (counts[slot] ?? 0) + 1;
    if (counts.length > _maxContextEntries) {
      final weakest = counts.entries.reduce(
        (a, b) => a.value <= b.value ? a : b,
      );
      counts.remove(weakest.key);
    }
    prefs.setString(_contextKey, jsonEncode(counts));
  }

  /// [now] saat dilimi ve haftanın gününe göre not başına bağlam puanı (HE-5).
  Map<String, int> contextScores([DateTime? now]) {
    final t = now ?? DateTime.now();
    final counts = _readContext(
      ref.read(sharedPreferencesProvider).getString(_contextKey),
    );
    return quickDropContextScores(counts, t);
  }

  static Map<String, int> _readContext(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.value is num) '${e.key}': (e.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }
}

/// Saf bağlam puanı (HE-5): aynı gün+saat dilimi ×2, yalnız aynı saat dilimi ×1.
Map<String, int> quickDropContextScores(
  Map<String, int> slotCounts,
  DateTime now,
) {
  final day = '${now.weekday}';
  final bucket = '${QuickDropRecentNotifier.hourBucket(now.hour)}';
  final scores = <String, int>{};
  for (final e in slotCounts.entries) {
    final parts = e.key.split('|');
    if (parts.length != 3 || e.value <= 0) continue;
    final id = parts[0];
    if (parts[2] != bucket) continue;
    final weight = parts[1] == day ? 2 : 1;
    scores[id] = (scores[id] ?? 0) + e.value * weight;
  }
  return scores;
}

/// Eklenebilecek notlar: yazı ve liste notları (çöpte/arşivde/kilitli
/// olmayan; sayfalı yazı notu hariç — sayfa seçimi ister). Sıra: son
/// kullanılan hedefler, sonra iğneliler, sonra günün saatine göre sık
/// kullanılanlar (HE-5), sonra en son değişenler.
List<Note> quickDropCandidates(
  Iterable<Note> notes,
  List<String> recent, {
  Map<String, int> contextBoost = const {},
}) {
  final ok = [
    for (final n in notes)
      if (n.deletedAt == null &&
          n.archivedAt == null &&
          !n.locked &&
          (n.type == NoteType.checklist ||
              n.type == NoteType.ordered ||
              (n.type == NoteType.text && !n.paged && n.textPages.isEmpty)) &&
          n.displayTitle.trim().isNotEmpty)
        n,
  ];
  int rank(Note n) {
    final r = recent.indexOf(n.id);
    if (r >= 0) return r;
    return n.pinned ? 100 : 200;
  }

  DateTime at(Note n) =>
      n.updatedAt ?? n.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  ok.sort((a, b) {
    final c = rank(a).compareTo(rank(b));
    if (c != 0) return c;
    final ba = contextBoost[a.id] ?? 0;
    final bb = contextBoost[b.id] ?? 0;
    if (ba != bb) return bb.compareTo(ba);
    return at(b).compareTo(at(a));
  });
  return ok;
}

/// [note]a [content] eklenince yazılacak alanlar ve bildirim sayısı.
/// Liste notunda içerik maddelere ayrılır (alışveriş listesinde kelime
/// kelime, cümleli listede yalnız virgülle); yazı notunda sona satır eklenir.
/// Eklenecek bir şey yoksa `fields` boştur.
({Map<String, dynamic> fields, int added}) quickDropFields(
  Note note,
  String content, {
  required String locale,
  QuickEntryMemory memory = const QuickEntryMemory(),
  String Function()? newId,
}) {
  // Art arda söylenenler ("süt al bir de faturayı öde") ayrı madde/satır.
  final text = quickDropSeparate(content.trim());
  if (text.isEmpty) return (fields: const {}, added: 0);
  if (note.type == NoteType.text) {
    final lines = [
      for (final l in text.split(', '))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    final joined = text.contains(', ') && lines.length > 1
        ? lines.join('\n')
        : content.trim();
    final body = note.body.trimRight();
    return (
      fields: {'body': body.isEmpty ? joined : '$body\n$joined'},
      added: joined.split('\n').length,
    );
  }
  final kind = detectNoteListKind(note, locale: locale);
  final effectiveMode = note.listMode != ListMode.general
      ? note.listMode
      : listModeFromLegacyKind(smartListKindId(kind));
  final priceByKey = <String, double>{};
  final metaByKey = <String, InlineParsedItem>{};
  var parseInput = text;
  {
    final segments = text.split(',');
    final rebuilt = <String>[];
    for (final rawSeg in segments) {
      final seg = rawSeg.trim();
      if (seg.isEmpty) continue;
      final inline = InlineItemParser.parse(
        seg,
        mode: effectiveMode,
        locale: locale,
        learnedGroups: memory.itemGroups,
      );
      final baseKey = quickItemKey(inline.title);
      if (inline.price != null) {
        priceByKey[baseKey] = inline.price!;
      }
      if (inline.dueDate != null ||
          inline.priority.isSet ||
          inline.price != null ||
          inline.quantity != null ||
          inline.category.isNotEmpty) {
        metaByKey[baseKey] = inline;
      }
      if (kind == SmartListKind.shopping || kind == SmartListKind.expense) {
        final priced = extractInlinePrice(seg);
        if (priced.price != null && priced.text.isNotEmpty) {
          priceByKey[quickItemKey(priced.text)] = priced.price!;
          rebuilt.add(priced.text);
        } else {
          rebuilt.add(seg);
        }
      } else {
        rebuilt.add(inline.title);
      }
    }
    if (rebuilt.isNotEmpty) parseInput = rebuilt.join(', ');
  }
  final parsed = _parseIntoList(note, parseInput, locale, memory);
  final plan = planDropIntoList(
    [for (final i in note.items) (text: i.text, checked: i.checked)],
    parsed.items,
    addQuantities: kind != SmartListKind.generic,
  );
  final added =
      plan.texts.length + plan.uncheck.length + plan.requantify.length;
  if (added == 0) return (fields: const {}, added: 0);
  final id = newId ?? () => const Uuid().v4();
  final existing = <NoteItem>[
    for (var i = 0; i < note.items.length; i++)
      // Boş yer tutucu satır (yeni listenin tek boş maddesi) atılır.
      if (note.items[i].text.trim().isNotEmpty || note.items.length > 1)
        () {
          final nextText = plan.requantify[i];
          var updated = note.items[i].copyWith(
            text: nextText,
            checked: plan.uncheck.contains(i) ? false : null,
          );
          if (nextText != null) {
            final parsedQty = parseQuickQty(quickQtyOf(nextText));
            if (parsedQty != null && parsedQty.value > 0) {
              updated = updated.copyWith(
                quantity: parsedQty.value,
                unit: parsedQty.rawUnit,
              );
            }
          }
          return updated;
        }(),
  ];
  final fresh = <NoteItem>[
    for (final t in plan.texts)
      () {
        final key = quickItemKey(t);
        final inline = metaByKey[key] ??
            InlineItemParser.parse(
              t,
              mode: effectiveMode,
              locale: locale,
              learnedGroups: memory.itemGroups,
            );
        final parsedQty = parseQuickQty(quickQtyOf(t));
        final foundPrice = inline.price ?? priceByKey[key];
        final qty = parsedQty?.value ?? inline.quantity;
        final unit = (parsedQty?.rawUnit.isNotEmpty ?? false)
            ? parsedQty!.rawUnit
            : inline.unit;
        final cleanText =
            (kind == SmartListKind.shopping || kind == SmartListKind.expense)
                ? () {
                    final priced = extractInlinePrice(t);
                    return priced.price != null && priced.text.isNotEmpty
                        ? quickCapitalize(priced.text)
                        : t;
                  }()
                : (inline.title.isNotEmpty ? inline.title : t);
        var category = inline.category;
        if (category.isEmpty && effectiveMode == ListMode.shopping) {
          final g =
              memory.itemGroups[key] ??
              groceryLexicon(locale).groupOf(cleanText);
          category = aisleCategoryKey(g) ?? '';
        }
        return NoteItem(
          id: id(),
          text: cleanText,
          quantity: qty != null && qty > 0 ? qty : null,
          unit: qty != null && qty > 0 ? unit : '',
          price: foundPrice != null && foundPrice > 0 ? foundPrice : null,
          dueDate: inline.dueDate,
          priority: inline.priority,
          category: category,
        );
      }(),
  ];
  final items = insertItemsBySmartGroup(
    existing,
    fresh,
    kind: kind,
    locale: locale,
    learnedGroups: memory.itemGroups,
  );
  return (
    fields: {
      'items': [for (final i in items) i.toMap()],
    },
    added: added,
  );
}

QuickParse _parseIntoList(
  Note note,
  String text,
  String locale,
  QuickEntryMemory memory,
) => quickDropListParser(
  note,
  locale: locale,
  memory: memory,
).parse(text, flush: true);

/// Liste notuna eklemenin ayrıştırıcısı (alışverişe benziyorsa market
/// sözlüğü + notun kendi maddeleri + hızlı ekle hafızası). Kurulumu pahalı
/// (~2200 kelimelik sözlük): önizleme satırı hedef başına BİR kez kurar.
QuickParser quickDropListParser(
  Note note, {
  required String locale,
  QuickEntryMemory memory = const QuickEntryMemory(),
}) {
  final grocery = looksLikeGrocery(note.displayTitle, [
    for (final i in note.items) i.text,
  ], locale);
  final lex = buildQuickLexicon(
    locale: locale,
    grocery: grocery,
    learned: memory.all('drop'),
    extra: [
      for (final i in note.items)
        if (i.text.trim().isNotEmpty) quickBaseName(i.text),
    ],
  );
  return buildQuickParser(lex, memory: memory, phrasesOnly: !grocery);
}

/// HE-2 önizleme satırı (17K §4.2, "→ Market listesi · süt, ekmek (2
/// madde)"): [content] [note]a eklenince NOTA GİRECEKLER — liste notunda
/// yeni, yeniden açılan ve miktarı değişen maddeler; yazı notunda eklenecek
/// satırlar. Hiçbir şey yazmaz; [quickDropFields] ile aynı ayrıştırma.
/// Boş = eklenecek yeni bir şey yok (hepsi zaten notta).
List<String> quickDropPreview(
  Note note,
  String content, {
  required QuickParser Function() parser,
}) {
  final text = quickDropSeparate(content.trim());
  if (text.isEmpty) return const [];
  if (note.type == NoteType.text) {
    final lines = [
      for (final l in text.split(', '))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    return lines.length > 1 ? lines : [content.trim()];
  }
  final plan = planDropIntoList([
    for (final i in note.items) (text: i.text, checked: i.checked),
  ], parser().parse(text, flush: true).items);
  return [
    ...plan.texts,
    for (final i in plan.uncheck) plan.requantify[i] ?? note.items[i].text,
    for (final e in plan.requantify.entries)
      if (!plan.uncheck.contains(e.key)) e.value,
  ];
}

/// DA-14: [content] liste notuna eklenince yapılacak BULANIK yazım
/// düzeltmeleri (yazılan → düzeltilen). Tam eşleşme, harf düzleştirme ve
/// öğretilmiş düzeltme dahil değil (yalnız [QuickHow.fuzzy]).
List<({String typed, String fixed})> quickDropFixes(
  Note note,
  String content, {
  required String locale,
  QuickEntryMemory memory = const QuickEntryMemory(),
}) {
  if (note.type == NoteType.text) return const [];
  final text = quickDropSeparate(content.trim());
  if (text.isEmpty) return const [];
  return [
    for (final i in _parseIntoList(note, text, locale, memory).items)
      if (i.corrected && i.typed.isNotEmpty) (typed: i.typed, fixed: i.name),
  ];
}

/// [memory] + Decisions'ın geri çevirdiği düzeltmeler (yalnız bu ekleme;
/// kalıcı hafızaya YAZILMAZ — K5).
QuickEntryMemory quickDropVetoed(
  QuickEntryMemory memory,
  Iterable<({String typed, String fixed})> vetoed,
) => vetoed.isEmpty
    ? memory
    : QuickEntryMemory(
        kinds: memory.kinds,
        rejected: {
          ...memory.rejected,
          for (final v in vetoed)
            '${quickAscii(v.typed)}>${quickAscii(v.fixed)}',
        },
      );

/// Hızlı eklemenin GERİ ALINMASI (H10, 2026-11-17): eski kopyayı körlemesine
/// geri yazmak, ekleme ile geri al arasında nota yapılan değişikliği (başka
/// cihaz, ortak kişi, editör) siliyordu. Yalnız bu eklemenin dokunduğu şey
/// geri alınır: eklenen maddeler çıkar; değiştirdiği madde HÂLÂ yazdığı
/// hâldeyse eskisine döner. Yazı notunda eklenen son satırlar, gövde hâlâ
/// yazılanla başlıyorsa çıkarılır. Geri alınacak bir şey kalmadıysa boş.
Map<String, dynamic> quickDropUndoFields({
  required Note before,
  required Note current,
  required Map<String, dynamic> written,
}) {
  if (before.type == NoteType.text) {
    final w = written['body'];
    if (w is! String) return const {};
    final now = current.body;
    if (!now.startsWith(w)) return const {};
    return {'body': before.body + now.substring(w.length)};
  }
  final raw = written['items'];
  if (raw is! List) return const {};
  final wrote = {
    for (final m in raw)
      if (m is Map) (m['id'] as String?) ?? '': Map<String, dynamic>.from(m),
  };
  final old = {for (final i in before.items) i.id: i};
  var changed = false;
  final items = <NoteItem>[];
  for (final i in current.items) {
    final w = wrote[i.id];
    if (!old.containsKey(i.id)) {
      // Bu eklemenin maddesi (kimliği eskide yok) → çıkar.
      if (w != null) {
        changed = true;
        continue;
      }
      items.add(i);
      continue;
    }
    final o = old[i.id]!;
    if (w != null &&
        !sameFirestoreValue(o.toMap(), w) &&
        sameFirestoreValue(i.toMap(), w)) {
      changed = true;
      items.add(o);
    } else {
      items.add(i);
    }
  }
  if (!changed) return const {};
  return {
    'items': [for (final i in items) i.toMap()],
  };
}

/// **HIZLI EKLE** levhasını açar. [text]: uygulama dışından gelen metin
/// (HE-3, `notlar://ekle?metin=…`) alana yazılı gelir; eklenmez.
Future<void> showQuickDropSheet(BuildContext context, {String text = ''}) {
  // Levha yerleşimsiz (yalnız boyama katmanında) yükselir: klavye açılıp
  // kapanırken 0 kurulum, 0 yerleşim (K-67, S56).
  final sheet = text.isEmpty
      ? const QuickDropSheet()
      : QuickDropSheet(initialText: text);
  return showLiftingSheet<void>(
    context: context,
    constraints: const BoxConstraints(maxWidth: 640),
    child: sheet,
  );
}
