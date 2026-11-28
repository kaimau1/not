import 'package:flutter/foundation.dart';

import '../data/quick_entry_memory.dart';
import 'inline_item_parser.dart';
import 'list_mode.dart';
import 'note.dart';
import 'note_type.dart';
import 'quick_drop.dart';
import 'quick_entry.dart';
import 'smart_list.dart';

/// Hedef tahmininin gerekçesi.
enum SmartRouteReason {
  explicitTitle,
  lexicalMatch,
  modeMatch,
  contextBoost,
  quickInboxFallback,
}

/// Tek bir cümle/parçanın akıllı hedef yönlendirme sonucu.
@immutable
class SmartTargetRoute {
  const SmartTargetRoute({
    required this.noteId,
    required this.isQuickInbox,
    required this.content,
    required this.confidence,
    this.ties = const [],
    this.command = false,
    this.reason = SmartRouteReason.quickInboxFallback,
  });

  /// Hedef not kimliği; [isQuickInbox] true veya [ties] doluysa null olabilir.
  final String? noteId;

  /// Güven skoru eşiğin altında kaldığı için "Hızlı Not" gelen kutusuna mı düştü?
  final bool isQuickInbox;

  /// Hedef adı / gereksiz komut ayıklandıktan sonraki temiz içerik.
  final String content;

  /// Güven puanı (`0.0` – `1.0`). `>= kAutoRouteThreshold` otomatik hedef seçer.
  final double confidence;

  /// Başa baş kalan not kimlikleri.
  final List<String> ties;

  /// Kullanıcı açık komut ("… ekle", "ad: …") verdi mi?
  final bool command;

  final SmartRouteReason reason;
}

/// Çoklu niyet bölünmesinden çıkan tek bir hedef dilimi.
@immutable
class MultiIntentSegment {
  const MultiIntentSegment({
    required this.noteId,
    required this.isQuickInbox,
    required this.content,
    required this.confidence,
  });

  final String? noteId;
  final bool isQuickInbox;
  final String content;
  final double confidence;

  String get targetKey => isQuickInbox ? '\u0000quick_inbox' : (noteId ?? '');

  @override
  bool operator ==(Object other) =>
      other is MultiIntentSegment &&
      other.noteId == noteId &&
      other.isQuickInbox == isQuickInbox &&
      other.content == content;

  @override
  int get hashCode => Object.hash(noteId, isQuickInbox, content);
}

/// Güven skorlu hedef yönlendirici (0 kredi, tamamen cihazda).
///
/// * Güven >= [autoThreshold] (0.72) → hedef not otomatik seçilir.
/// * Güven < [autoThreshold] → son açık kalan alakasız nota atmak yerine
///   otomatik `"Hızlı Not"` klasörüne (`isQuickInbox: true`) yönlendirilir.
class SmartTargetRouter {
  SmartTargetRouter._();

  static const double autoThreshold = 0.72;
  static const double minLeadMargin = 0.08;

  static final _wordSplitRe = RegExp(r'[^a-z0-9]+');
  static final _trailingBuyRe = RegExp(
    r'\s+(?:al|alinacak|alınacak|lazim|lazım|getir|buy|get)\s*$',
    caseSensitive: false,
  );

  static const _shoppingCues = {
    'al',
    'alinacak',
    'alınacak',
    'market',
    'manav',
    'bakkal',
    'pazar',
    'kasap',
    'buy',
    'grocery',
  };

  static const _routineCues = {
    'rutin',
    'aliskanlik',
    'her',
    'gunluk',
    'sabah',
    'aksam',
    'ic',
    'yuruyus',
    'kosu',
    'meditasyon',
    'vitamin',
    'esne',
    'esneme',
    'egzersiz',
    'spor',
    'fircala',
    'kitap',
    'oku',
    'daily',
    'habit',
    'routine',
    'water',
    'walk',
    'workout',
    'stretch',
    'meditate',
  };

  static const _routinePhrases = [
    'su ic',
    'su iç',
    'kitap oku',
    'ilac ic',
    'ilaç iç',
    'spor yap',
    'yuruyus yap',
    'yürüyüş yap',
    'dis fircala',
    'diş fırçala',
    'her gun',
    'her gün',
    'her sabah',
    'her aksam',
    'her akşam',
    'drink water',
    'read book',
    'take vitamin',
  ];

  static const _projectCues = {
    'proje',
    'gorev',
    'dosya',
    'dosyasini',
    'dosyayi',
    'kontrol',
    'rapor',
    'sunum',
    'toplanti',
    'mail',
    'eposta',
    'fatura',
    'ode',
    'gonder',
    'hazirla',
    'bitir',
    'tamamla',
    'guncelle',
    'incele',
    'tasarim',
    'kod',
    'test',
    'yayin',
    'deploy',
    'bug',
    'hata',
    'project',
    'task',
    'file',
    'check',
    'review',
    'report',
    'send',
    'finish',
    'meeting',
    'invoice',
    'pay',
    'update',
  };

  /// [rawText] için en iyi hedef notu veya `"Hızlı Not"` yedek hedefini hesaplar.
  static SmartTargetRoute route(
    String rawText,
    List<Note> candidates, {
    required String locale,
    Map<String, int> contextBoost = const {},
    DateTime? now,
  }) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return const SmartTargetRoute(
        noteId: null,
        isQuickInbox: true,
        content: '',
        confidence: 0,
      );
    }

    final pool = [
      for (final n in candidates)
        if (!n.locked && n.deletedAt == null && n.archivedAt == null) n,
    ];
    final nonInboxPool = [
      for (final n in pool)
        if (!n.isQuickInbox) n,
    ];
    final titles = [for (final n in pool) n.displayTitle];

    // 1) Açık başlık / komut eşleşmesi ("market: süt", "süt markete ekle").
    final explicit = parseDropTarget(trimmed, titles);
    if (explicit.index != null) {
      final hitNote = pool[explicit.index!];
      return SmartTargetRoute(
        noteId: hitNote.id,
        isQuickInbox: hitNote.isQuickInbox,
        content: explicit.content,
        confidence: 0.96,
        command: explicit.command,
        reason: SmartRouteReason.explicitTitle,
      );
    }
    if (explicit.ties.isNotEmpty) {
      return SmartTargetRoute(
        noteId: null,
        isQuickInbox: false,
        content: explicit.content,
        confidence: 0.55,
        ties: [for (final i in explicit.ties) pool[i].id],
        command: explicit.command,
        reason: SmartRouteReason.explicitTitle,
      );
    }

    final body = explicit.content.trim().isEmpty
        ? trimmed
        : explicit.content.trim();
    if (nonInboxPool.isEmpty) {
      return SmartTargetRoute(
        noteId: null,
        isQuickInbox: true,
        content: body,
        confidence: 0,
        command: explicit.command,
      );
    }

    // Inline ayrıştırma ile tarih/öncelik/miktar/fiyat sinyallerini temizle.
    final parsedInline = InlineItemParser.parse(
      body,
      mode: ListMode.shopping,
      locale: locale,
      now: now,
    );
    final strippedBuy = _stripTrailingBuy(parsedInline.title);
    final lowerAscii = quickAscii(body);
    final words = _wordsOf(lowerAscii);
    final cleanWords = _wordsOf(quickAscii(strippedBuy));

    // A) Alışveriş sinyali
    final gLex = groceryLexicon(locale);
    final groceryHits = _countLexiconHits(gLex, strippedBuy, cleanWords);
    final hasShoppingCue = words.any(_shoppingCues.contains);
    final hasProjectCue = words.any(_projectCues.contains);
    final hasRoutinePhrase = _routinePhrases.any(
      (p) => lowerAscii.contains(quickAscii(p)),
    );
    final routineCueCount = words.where(_routineCues.contains).length;

    double shoppingSignal = 0;
    if (groceryHits >= 2) {
      shoppingSignal = 0.90;
    } else if (groceryHits == 1 && hasShoppingCue && !hasProjectCue) {
      shoppingSignal = 0.86;
    } else if (groceryHits == 1 &&
        !hasProjectCue &&
        !hasRoutinePhrase &&
        cleanWords.length <= 3) {
      shoppingSignal = 0.78;
    }

    // B) Rutin sinyali
    double routineSignal = 0;
    if (hasRoutinePhrase) {
      routineSignal = 0.82;
    } else if (routineCueCount >= 2 && !hasProjectCue) {
      routineSignal = 0.78;
    }

    // C) Proje / görev sinyali
    double projectSignal = 0;
    final projectHitCount = words.where(_projectCues.contains).length;
    if (projectHitCount >= 2) {
      projectSignal = 0.82;
    } else if (projectHitCount == 1 && words.length >= 2) {
      projectSignal = 0.74;
    }

    // D) Her aday notu puanla.
    final referenceNow = now ?? DateTime.now();
    final scored =
        <
          ({Note note, double score, SmartRouteReason reason, String content})
        >[];

    for (final note in nonInboxPool) {
      var score = 0.0;
      var reason = SmartRouteReason.modeMatch;
      var candidateContent = body;

      final noteMode = note.listMode != ListMode.general
          ? note.listMode
          : listModeFromLegacyKind(note.listKind);
      final profile = _profileOf(note, locale);
      final noteKind = profile.kind;
      final isShoppingNote =
          note.type != NoteType.text &&
          (noteMode == ListMode.shopping ||
              noteKind == SmartListKind.shopping ||
              profile.grocery);
      final isRoutineNote =
          note.type != NoteType.text &&
          (noteMode == ListMode.routine || noteKind == SmartListKind.habits);
      final isProjectNote =
          note.type != NoteType.text && noteMode == ListMode.project;

      // 1) Kip / alan sinyali
      if (isShoppingNote && shoppingSignal > score) {
        score = shoppingSignal;
        reason = SmartRouteReason.lexicalMatch;
        if (hasShoppingCue &&
            strippedBuy != parsedInline.title &&
            gLex.groupOf(strippedBuy) >= 0) {
          // "süt al" → Alışveriş listesine temiz "Süt" olarak girsin.
          final cleanedBody = body.replaceFirst(_trailingBuyRe, '').trim();
          if (cleanedBody.isNotEmpty) candidateContent = cleanedBody;
        }
      }
      if (isRoutineNote && routineSignal > score) {
        score = routineSignal;
        reason = SmartRouteReason.modeMatch;
      }
      if (isProjectNote && projectSignal > score) {
        score = projectSignal;
        reason = SmartRouteReason.modeMatch;
      }

      // 2) Diğer akıllı tür sözlükleri (bavul, eczane, hırdavat, kamp...)
      if (note.type != NoteType.text &&
          noteKind != SmartListKind.generic &&
          noteKind != SmartListKind.shopping &&
          noteKind != SmartListKind.habits) {
        final lex = lexiconForSmartKind(noteKind, locale);
        final hits = _countLexiconHits(lex, body, words);
        if (hits >= 2 && 0.88 > score) {
          score = 0.88;
          reason = SmartRouteReason.lexicalMatch;
        } else if (hits == 1 && words.length <= 3 && 0.78 > score) {
          score = 0.78;
          reason = SmartRouteReason.lexicalMatch;
        }
      }

      // 3) Başlık kök örtüşmesi ("proje dosyasını kontrol et" ↔ "Proje Görevleri")
      final titleOverlap = _titleStemOverlap(words, note.displayTitle);
      if (titleOverlap > 0) {
        final boosted = (score > 0 ? score + 0.14 : 0.62 + titleOverlap * 0.22)
            .clamp(0.0, 0.94);
        if (boosted > score) {
          score = boosted;
          reason = SmartRouteReason.lexicalMatch;
        }
      }

      // 4) Mevcut maddelerle birebir/kök örtüşme (özellikle rutin ve şablonlarda)
      if (note.type != NoteType.text && note.items.isNotEmpty) {
        final itemMatch = _existingItemOverlap(lowerAscii, words, profile);
        if (itemMatch) {
          score = (score + 0.26).clamp(0.76, 0.93);
          reason = SmartRouteReason.lexicalMatch;
        }
      }

      // 5) Bağlam zaman dilimi ve geçmiş kullanım artısı (yalnız anlamlı adaylarda)
      if (score >= 0.50) {
        if (_matchesTimeSlot(note.contextTimeSlot, referenceNow)) {
          score = (score + 0.05).clamp(0.0, 0.95);
        }
        if ((contextBoost[note.id] ?? 0) > 0) {
          score = (score + 0.04).clamp(0.0, 0.95);
        }
        if (note.pinned) {
          score = (score + 0.02).clamp(0.0, 0.95);
        }
      }

      if (score > 0) {
        scored.add((
          note: note,
          score: score,
          reason: reason,
          content: candidateContent,
        ));
      }
    }

    if (scored.isEmpty) {
      return SmartTargetRoute(
        noteId: null,
        isQuickInbox: true,
        content: body,
        confidence: 0,
        command: explicit.command,
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final best = scored.first;
    final runnerUp = scored.length > 1 ? scored[1] : null;

    if (best.score >= autoThreshold) {
      if (runnerUp != null &&
          (best.score - runnerUp.score) < minLeadMargin &&
          runnerUp.score >= autoThreshold) {
        // Aynı kipte iki aday varsa (ör. iki alışveriş listesi) en yüksek
        // puanlı / son kullanılan zaten başta; sadece farklı alanlarda eşitlik
        // varsa kullanıcının seçmesini kolaylaştırmak için tie bildir.
        final sameMode = best.note.listMode == runnerUp.note.listMode;
        if (!sameMode) {
          return SmartTargetRoute(
            noteId: null,
            isQuickInbox: false,
            content: body,
            confidence: best.score,
            ties: [best.note.id, runnerUp.note.id],
            command: explicit.command,
            reason: best.reason,
          );
        }
      }
      return SmartTargetRoute(
        noteId: best.note.id,
        isQuickInbox: false,
        content: best.content,
        confidence: best.score,
        command: explicit.command,
        reason: best.reason,
      );
    }

    // Güven skoru düşük (< 0.72) → son açık kalan alakasız nota değil "Hızlı Not"a.
    return SmartTargetRoute(
      noteId: null,
      isQuickInbox: true,
      content: body,
      confidence: best.score,
      command: explicit.command,
    );
  }

  static String _stripTrailingBuy(String text) =>
      text.replaceFirst(_trailingBuyRe, '').trim();

  static List<String> _wordsOf(String ascii) => [
    for (final w in ascii.split(_wordSplitRe))
      if (w.length >= 2) w,
  ];

  static int _countLexiconHits(
    QuickLexicon lex,
    String phrase,
    List<String> words,
  ) {
    if (lex.isEmpty) return 0;
    if (lex.exact(quickBaseName(phrase)) != null) return 1;
    var hits = 0;
    final seen = <String>{};
    // İki kelimelik öbekleri de dene ("diş macunu", "beyaz peynir").
    for (var i = 0; i + 1 < words.length; i++) {
      final pair = '${words[i]} ${words[i + 1]}';
      if (lex.exact(pair) != null && seen.add(pair)) {
        hits++;
      }
    }
    for (final w in words) {
      if (w.length < 3 || _shoppingCues.contains(w)) continue;
      if (lex.exact(w) != null && seen.add(w)) {
        hits++;
      }
    }
    return hits;
  }

  static double _titleStemOverlap(List<String> inputWords, String title) {
    final titleWords = [
      for (final w in _wordsOf(quickAscii(title)))
        if (w.length >= 4 && !_genericTitleWords.contains(w)) quickStem(w),
    ];
    if (titleWords.isEmpty || inputWords.isEmpty) return 0;
    var matches = 0;
    for (final tw in titleWords) {
      for (final iw in inputWords) {
        if (iw.length < 4) continue;
        if (iw == tw || quickStem(iw) == tw) {
          matches++;
          break;
        }
      }
    }
    if (matches == 0) return 0;
    return (matches / titleWords.length).clamp(0.0, 1.0);
  }

  static const _genericTitleWords = {
    'liste',
    'listesi',
    'listem',
    'not',
    'notlar',
    'notum',
    'list',
    'note',
    'notes',
    'gunluk',
    'haftalik',
    'yeni',
  };

  static bool _existingItemOverlap(
    String lowerAscii,
    List<String> words,
    _NoteRouteProfile profile,
  ) {
    if (words.isEmpty) return false;
    for (var k = 0; k < profile.itemKeys.length; k++) {
      final text = profile.itemKeys[k];
      if (lowerAscii == text) return true;
      final itemWords = profile.itemWords[k];
      if (itemWords.isEmpty) continue;
      // Madde girdinin en az YARISINI kapsamalı ve TAM KELİME olarak geçmeli
      // (kullanıcı bulgusu 2026-11-28: "yeni bir alışveriş listesi oluştur…"
      // ve "oraya da elma armut peynir ekmek" 411 maddelik "Notlar"a gitti —
      // eski kural girdinin içinde herhangi bir maddenin metni ALT DİZGE
      // olarak geçerse tek başına 0,76 veriyordu; çok maddeli notta neredeyse
      // her cümle bir maddeye "uyuyordu").
      if (itemWords.length * 2 < words.length) continue;
      if (_containsRun(words, itemWords)) return true;
      if (itemWords.length >= 2 && itemWords.every((w) => words.contains(w))) {
        return true;
      }
    }
    return false;
  }

  /// [run] kelimeleri [words] içinde ARDIŞIK geçiyor mu.
  static bool _containsRun(List<String> words, List<String> run) {
    for (var i = 0; i + run.length <= words.length; i++) {
      var ok = true;
      for (var j = 0; j < run.length; j++) {
        if (words[i + j] != run[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  /// Not başına pahalı özellikler (tür tespiti 400 maddede ~190 ms) bir kez
  /// hesaplanır. [Note] değişmez: not değişince yeni nesne gelir ve önbellek
  /// kendiliğinden tazelenir. Kök neden: hızlı ekle her harfte / her dikte
  /// kısmi sonucunda bütün adayları baştan tarıyordu (harf başına saniyeler,
  /// kullanıcı 2026-11-28 "aşırı donuyor, çöküyor").
  static final _profiles = Expando<_NoteRouteProfile>('smartRouteProfile');

  static _NoteRouteProfile _profileOf(Note note, String locale) {
    final cached = _profiles[note];
    if (cached != null && cached.locale == locale) return cached;
    final keys = <String>[];
    final wordsList = <List<String>>[];
    for (final item in note.items) {
      final text = quickAscii(quickBaseName(item.text));
      if (text.length < 3) continue;
      keys.add(text);
      wordsList.add(_wordsOf(text));
    }
    final profile = _NoteRouteProfile(
      locale: locale,
      kind: _routeKindOf(note, locale),
      grocery:
          note.type != NoteType.text &&
          looksLikeGrocery(note.displayTitle, [
            for (final i in note.items) i.text,
          ], locale),
      itemKeys: keys,
      itemWords: wordsList,
    );
    _profiles[note] = profile;
    return profile;
  }

  /// Notun yönlendirmedeki türü. Tür yalnız MADDELERDEN çıktıysa
  /// ([detectSmartKindFromItems] tek market maddesinde bile "alışveriş"
  /// der) maddelerin en az %40'ı o türün sözlüğünde olmalı: 411 maddelik bir
  /// fikir notunda tek "ekmek" maddesi onu alışveriş listesi yapmasın
  /// (kullanıcı bulgusu 2026-11-28).
  static SmartListKind _routeKindOf(Note note, String locale) {
    final kind = detectNoteListKind(note, locale: locale);
    if (kind == SmartListKind.generic ||
        smartListKindFromId(note.listKind) != SmartListKind.generic ||
        smartKindFromPhrase(note.displayTitle) != null) {
      return kind;
    }
    final lex = kind == SmartListKind.shopping
        ? groceryLexicon(locale)
        : lexiconForSmartKind(kind, locale);
    var total = 0;
    var hits = 0;
    for (final i in note.items) {
      if (i.header || i.text.trim().isEmpty) continue;
      total++;
      if (lex.groupOf(i.text) >= 0) hits++;
    }
    return hits * 5 >= total * 2 ? kind : SmartListKind.generic;
  }

  static bool _matchesTimeSlot(ContextTimeSlot slot, DateTime now) =>
      switch (slot) {
        ContextTimeSlot.any => false,
        ContextTimeSlot.morning => now.hour >= 5 && now.hour < 12,
        ContextTimeSlot.evening => now.hour >= 17 && now.hour <= 23,
        ContextTimeSlot.weekend =>
          now.weekday == DateTime.saturday || now.weekday == DateTime.sunday,
      };
}

/// Tek nefeste söylenen veya yazılan çoklu niyetli cümleleri
/// (ör. `"süt al, yarın su iç, proje dosyasını kontrol et"`) ayrı hedef
/// dilimlerine böler.
///
/// Aynı hedefe giden tüm maddeler (`"süt, ekmek, yumurta"`) bölünmez, boş
/// liste döner (normal tek-hedef akışı çalışır).
class MultiIntentSplitter {
  MultiIntentSplitter._();

  static final _clauseSplitRe = RegExp(r'\s*[,;\n]+\s*');
  static final _veSplitRe = RegExp(r'\s+(?:ve|and)\s+', caseSensitive: false);

  static List<MultiIntentSegment> split(
    String rawText,
    List<Note> candidates, {
    required String locale,
    Map<String, int> contextBoost = const {},
    DateTime? now,
  }) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return const [];

    // 1) Önce açık çoklu hedefler ("süt markete, fatura yapılacaklara").
    final pool = [
      for (final n in candidates)
        if (!n.locked && n.deletedAt == null && n.archivedAt == null) n,
    ];
    final titles = [for (final n in pool) n.displayTitle];
    final explicitMulti = parseMultiDropTargets(trimmed, titles);
    if (explicitMulti.length >= 2) {
      return [
        for (final m in explicitMulti)
          MultiIntentSegment(
            noteId: pool[m.index].id,
            isQuickInbox: pool[m.index].isQuickInbox,
            content: m.content,
            confidence: 0.96,
          ),
      ];
    }

    // 2) Doğal dil parçalarına ayır (virgül, noktalı virgül, satır sonu, "bir de", "ayrıca").
    final separated = quickDropSeparate(trimmed);
    var clauses = [
      for (final c in separated.split(_clauseSplitRe))
        if (c.trim().isNotEmpty) c.trim(),
    ];

    // Virgül yoksa ama iki ayrı niyet " ve " / " and " ile bağlandıysa dene.
    if (clauses.length == 1 && _veSplitRe.hasMatch(separated)) {
      final veParts = [
        for (final c in separated.split(_veSplitRe))
          if (c.trim().isNotEmpty) c.trim(),
      ];
      if (veParts.length == 2) {
        clauses = veParts;
      }
    }

    if (clauses.length < 2) return const [];

    final routed = <SmartTargetRoute>[];
    for (final clause in clauses) {
      final r = SmartTargetRouter.route(
        clause,
        pool,
        locale: locale,
        contextBoost: contextBoost,
        now: now,
      );
      if (r.content.trim().isEmpty) continue;
      routed.add(r);
    }
    if (routed.length < 2) return const [];

    // Aynı hedefe düşen dilimleri sırayı koruyarak grupla.
    final order = <String>[];
    final grouped = <String, List<SmartTargetRoute>>{};
    for (final r in routed) {
      final key = r.isQuickInbox ? '\u0000quick_inbox' : (r.noteId ?? '');
      if (key.isEmpty) continue;
      if (!grouped.containsKey(key)) order.add(key);
      (grouped[key] ??= []).add(r);
    }

    // En az 2 FARKLI hedef olmalı ve en az 2 dilim yüksek güvenli (veya en az
    // biri gerçek bir hedefe yüksek güvenli + diğeri farklı bir gerçek hedefe
    // yüksek güvenli) olmalı ki yanlış bölme olmasın.
    final confidentDistinctNotes = [
      for (final key in order)
        if (key != '\u0000quick_inbox' &&
            grouped[key]!.any(
              (r) => r.confidence >= SmartTargetRouter.autoThreshold,
            ))
          key,
    ];
    if (order.length < 2 || confidentDistinctNotes.isEmpty) {
      return const [];
    }
    // 1 gerçek hedef + 1 düşük güvenli parça yalnız gerçek hedef güçlü (≥ 0.80)
    // VE diğer parça en az 2 kelimelik ayrı bir cümleyse çoklu bölünür;
    // aksi hâlde ("süt, özel marka peynir") tek alışveriş listesine gider!
    if (confidentDistinctNotes.length < 2) {
      final inboxRoutes = grouped['\u0000quick_inbox'] ?? const [];
      final hasSubstantialOther = inboxRoutes.any(
        (r) => r.content.split(RegExp(r'\s+')).length >= 3,
      );
      final topStrong = grouped[confidentDistinctNotes.first]!.any(
        (r) => r.confidence >= 0.82,
      );
      if (!hasSubstantialOther || !topStrong) return const [];
    }

    return [
      for (final key in order)
        () {
          final list = grouped[key]!;
          final first = list.first;
          final bestConf = list
              .map((e) => e.confidence)
              .reduce((a, b) => a > b ? a : b);
          return MultiIntentSegment(
            noteId: first.isQuickInbox ? null : first.noteId,
            isQuickInbox: first.isQuickInbox,
            content: [for (final e in list) e.content].join(', '),
            confidence: bestConf,
          );
        }(),
    ];
  }
}

class _NoteRouteProfile {
  const _NoteRouteProfile({
    required this.locale,
    required this.kind,
    required this.grocery,
    required this.itemKeys,
    required this.itemWords,
  });

  final String locale;
  final SmartListKind kind;
  final bool grocery;
  final List<String> itemKeys;
  final List<List<String>> itemWords;
}
