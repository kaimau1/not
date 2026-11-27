import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/search_fold.dart';
import '../../notes/domain/note.dart';

/// Tek bir not için önerilen başlık/etiket paketi (yerel + Decisions).
class QuietOrganizeSuggestion {
  const QuietOrganizeSuggestion({
    required this.noteId,
    this.title,
    this.tags = const [],
    this.folderId,
  });

  final String noteId;
  final String? title;
  final List<String> tags;
  final String? folderId;
}

/// Türkçe harf/aksan duyarsız katlama (`İ/I/ı/Ş/ş/Ğ/ğ/Ü/ü/Ö/ö/Ç/ç` -> ASCII).
String foldTurkish(String input) => foldForSearch(input);

enum SmartNoteCategory {
  finance,
  health,
  education,
  work,
  shopping,
  travel,
  personal,
  tech,
  recipes,
  official;

  static SmartNoteCategory? byName(String? name) {
    for (final c in values) {
      if (c.name == name) return c;
    }
    return null;
  }
}

class SmartNoteClassification {
  const SmartNoteClassification({
    required this.noteId,
    required this.category,
    required this.folderSuggestion,
    required this.tags,
    required this.suggestedTitle,
    required this.confidence,
    required this.localOnly,
    required this.matchedRule,
  });

  final String noteId;
  final SmartNoteCategory category;
  final String? folderSuggestion;
  final List<String> tags;
  final String? suggestedTitle;
  final double confidence;
  final bool localOnly;
  final String matchedRule;

  bool get needsAiRefinement => confidence < 0.65;

  QuietOrganizeSuggestion toOrganizeSuggestion() => QuietOrganizeSuggestion(
    noteId: noteId,
    title: suggestedTitle,
    tags: tags,
  );
}

class _LearnedExample {
  const _LearnedExample({
    required this.fromCategory,
    required this.toCategory,
    required this.tokens,
  });

  final String fromCategory;
  final String toCategory;
  final List<String> tokens;

  Map<String, Object?> toJson() => {
    'f': fromCategory,
    't': toCategory,
    'x': tokens,
  };

  static _LearnedExample? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final f = raw['f'];
    final t = raw['t'];
    final x = raw['x'];
    if (f is! String || t is! String || x is! List) return null;
    return _LearnedExample(
      fromCategory: f,
      toCategory: t,
      tokens: [
        for (final v in x)
          if (v is String) v,
      ],
    );
  }
}

/// Cihaz içi düzeltme hafızası: kullanıcı bir notun kategorisini düzeltince
/// aynı ham içerik değil yalnız normalleştirilmiş kelime belirteçleri saklanır.
class SmartNoteLearn {
  SmartNoteLearn([this._prefs]);

  static const String prefsKey = 'smart_note_learn_v1';
  static const int _maxExamples = 250;
  static const double _minVoteScore = 0.72;
  static const double _minSimilarScore = 0.34;

  final SharedPreferences? _prefs;
  final List<_LearnedExample> _items = [];
  bool _loaded = false;

  void ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    final raw = _prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final entry in decoded) {
        final item = _LearnedExample.fromJson(entry);
        if (item != null) _items.add(item);
      }
    } catch (_) {
      // Bozuk kayıt yok sayılır.
    }
  }

  static List<String> extractTokens(Note note) {
    final text = foldTurkish('${note.title} ${note.toPlainText()}');
    final tokens = <String>{};
    for (final match in RegExp(r'[a-z0-9]{3,24}').allMatches(text)) {
      final tok = match.group(0)!;
      if (_stopWords.contains(tok)) continue;
      tokens.add(tok);
      if (tokens.length >= 24) break;
    }
    return tokens.toList(growable: false);
  }

  static const _stopWords = {
    'bir',
    'veya',
    'icin',
    'ile',
    'gibi',
    'daha',
    'olan',
    'olarak',
    'ama',
    'fakat',
    'the',
    'and',
    'for',
    'with',
    'this',
    'that',
  };

  static double jaccardSimilarity(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final setA = a.toSet();
    final setB = b.toSet();
    final inter = setA.intersection(setB).length;
    if (inter == 0) return 0;
    return inter / (setA.length + setB.length - inter);
  }

  Future<void> recordCorrection(
    Note note,
    SmartNoteCategory fromCategory,
    SmartNoteCategory toCategory,
  ) async {
    ensureLoaded();
    final tokens = extractTokens(note);
    if (tokens.isEmpty) return;
    _items.add(
      _LearnedExample(
        fromCategory: fromCategory.name,
        toCategory: toCategory.name,
        tokens: tokens,
      ),
    );
    if (_items.length > _maxExamples) {
      _items.removeRange(0, _items.length - _maxExamples);
    }
    await _prefs?.setString(
      prefsKey,
      jsonEncode([for (final item in _items) item.toJson()]),
    );
  }

  SmartNoteCategory adjust(Note note, SmartNoteCategory proposed) {
    ensureLoaded();
    if (_items.isEmpty) return proposed;
    final tokens = extractTokens(note);
    if (tokens.isEmpty) return proposed;

    final votes = <String, double>{};
    for (final ex in _items) {
      if (ex.fromCategory != proposed.name) continue;
      final sim = jaccardSimilarity(tokens, ex.tokens);
      if (sim < _minSimilarScore) continue;
      votes[ex.toCategory] = (votes[ex.toCategory] ?? 0) + sim * 1.6;
    }
    if (votes.isEmpty) return proposed;
    var bestCat = proposed.name;
    var bestScore = _minVoteScore;
    for (final e in votes.entries) {
      if (e.value >= bestScore) {
        bestScore = e.value;
        bestCat = e.key;
      }
    }
    return SmartNoteCategory.byName(bestCat) ?? proposed;
  }

  List<Note> findSimilar(
    Note anchor,
    SmartNoteCategory fromCategory,
    List<Note> candidates, {
    required SmartNoteCategory Function(Note) currentCategoryOf,
  }) {
    final anchorTokens = extractTokens(anchor);
    if (anchorTokens.isEmpty) return const [];
    final out = <Note>[];
    for (final candidate in candidates) {
      if (candidate.id == anchor.id || candidate.locked) continue;
      if (currentCategoryOf(candidate) != fromCategory) continue;
      final sim = jaccardSimilarity(anchorTokens, extractTokens(candidate));
      if (sim >= _minSimilarScore) out.add(candidate);
    }
    return out;
  }
}

/// Sıfır kredili yerel akıllı sınıflandırma motoru.
abstract final class SmartNoteCategorizer {
  static const Map<SmartNoteCategory, List<String>> _keywords = {
    SmartNoteCategory.finance: [
      'fatura',
      'odeme',
      'iban',
      'dekont',
      'banka',
      'kredi',
      'taksit',
      'maaş',
      'maas',
      'vergi',
      'butce',
      'hesap ozeti',
      'invoice',
      'receipt',
      'payment',
      'salary',
    ],
    SmartNoteCategory.health: [
      'doktor',
      'randevu',
      'recete',
      'ilac',
      'tahlil',
      'hastane',
      'eczane',
      'kan testi',
      'enabiz',
      'poliklinik',
      'asi',
      'doctor',
      'hospital',
      'medicine',
    ],
    SmartNoteCategory.education: [
      'ders',
      'sinav',
      'vize',
      'final',
      'odev',
      'universite',
      'okul',
      'notlarim',
      'konu ozeti',
      'tez',
      'makale',
      'lecture',
      'exam',
      'homework',
      'study',
    ],
    SmartNoteCategory.work: [
      'toplanti',
      'proje',
      'sunum',
      'musteri',
      'rapor',
      'sprint',
      'gorev',
      'teslim',
      'sirket',
      'sozlesme',
      'teklif',
      'meeting',
      'project',
      'deadline',
      'report',
    ],
    SmartNoteCategory.shopping: [
      'alisveris',
      'market',
      'siparis',
      'sepet',
      'ekmek',
      'sut',
      'yumurta',
      'meyve',
      'sebze',
      'indirim',
      'kargo',
      'magaza',
      'shopping',
      'grocery',
    ],
    SmartNoteCategory.travel: [
      'ucus',
      'bilet',
      'otel',
      'rezervasyon',
      'bavul',
      'pasaport',
      'vize',
      'tatil',
      'rota',
      'tren',
      'otobus',
      'havalimani',
      'flight',
      'hotel',
      'ticket',
    ],
    SmartNoteCategory.tech: [
      'flutter',
      'dart',
      'python',
      'api',
      'sunucu',
      'server',
      'kod',
      'hata',
      'bug',
      'git',
      'github',
      'sifre',
      'parola',
      'wifi',
      'deploy',
    ],
    SmartNoteCategory.recipes: [
      'tarif',
      'malzeme',
      'pisir',
      'firin',
      'corba',
      'kek',
      'yemek',
      'kasik',
      'bardak',
      'tencere',
      'sos',
      'recipe',
      'bake',
      'cook',
    ],
    SmartNoteCategory.official: [
      'edevlet',
      'e-devlet',
      'noter',
      'dilekce',
      'mahkeme',
      'tapu',
      'kimlik',
      'ikametgah',
      'sabika',
      'sgk',
      'nufus',
      'resmi',
      'belediye',
    ],
  };

  static const Map<SmartNoteCategory, List<String>> _defaultTags = {
    SmartNoteCategory.finance: ['finans', 'odeme'],
    SmartNoteCategory.health: ['saglik'],
    SmartNoteCategory.education: ['egitim', 'ders'],
    SmartNoteCategory.work: ['is', 'toplanti'],
    SmartNoteCategory.shopping: ['alisveris'],
    SmartNoteCategory.travel: ['seyahat'],
    SmartNoteCategory.personal: ['kisisel'],
    SmartNoteCategory.tech: ['teknoloji'],
    SmartNoteCategory.recipes: ['tarif'],
    SmartNoteCategory.official: ['resmi'],
  };

  static SmartNoteClassification classify(
    Note note, {
    SmartNoteLearn? learn,
    List<String> existingFolders = const [],
  }) {
    final text = foldTurkish(
      '${note.title}\n${note.toPlainText()}\n${note.tags.join(' ')}',
    );
    var bestCat = SmartNoteCategory.personal;
    var bestHits = 0;
    var bestRule = 'default_personal';

    for (final entry in _keywords.entries) {
      var hits = 0;
      String? hitWord;
      for (final kw in entry.value) {
        final foldedKw = foldTurkish(kw);
        if (text.contains(foldedKw)) {
          hits++;
          hitWord ??= foldedKw;
        }
      }
      if (hits > bestHits) {
        bestHits = hits;
        bestCat = entry.key;
        bestRule = 'kw_${entry.key.name}_$hitWord';
      }
    }

    var confidence = switch (bestHits) {
      0 => 0.42,
      1 => 0.72,
      2 => 0.86,
      _ => math.min(0.96, 0.86 + (bestHits - 2) * 0.03),
    };

    if (learn != null) {
      final adjusted = learn.adjust(note, bestCat);
      if (adjusted != bestCat) {
        bestCat = adjusted;
        bestRule = 'learned_${adjusted.name}';
        confidence = math.max(confidence, 0.90);
      }
    }

    final tags = note.tags.isEmpty
        ? _defaultTags[bestCat] ?? const ['genel']
        : const <String>[];
    final folderSuggestion = _matchExistingFolder(bestCat, existingFolders);
    final suggestedTitle = note.title.trim().isEmpty
        ? _deriveTitle(note)
        : null;

    return SmartNoteClassification(
      noteId: note.id,
      category: bestCat,
      folderSuggestion: folderSuggestion,
      tags: tags,
      suggestedTitle: suggestedTitle,
      confidence: confidence,
      localOnly: true,
      matchedRule: bestRule,
    );
  }

  static String? _matchExistingFolder(
    SmartNoteCategory cat,
    List<String> existingFolders,
  ) {
    if (existingFolders.isEmpty) return null;
    final hints = _defaultTags[cat] ?? const [];
    for (final folder in existingFolders) {
      final f = foldTurkish(folder.trim());
      if (f.isEmpty) continue;
      if (f.contains(cat.name) || hints.any(f.contains)) {
        return folder;
      }
    }
    return null;
  }

  static String? _deriveTitle(Note note) {
    final raw = note.toPlainText().trim();
    if (raw.isEmpty) return null;
    final firstLine = raw
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^[-*•\[\]xX\s]+'), '').trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) return null;
    final words = firstLine.split(RegExp(r'\s+')).take(5).toList();
    final joined = words.join(' ');
    return joined.length > 42 ? '${joined.substring(0, 42).trim()}…' : joined;
  }

  static List<SmartNoteClassification> classifyAll(
    List<Note> notes, {
    bool suggestTitles = true,
    bool suggestTags = true,
    SmartNoteLearn? learn,
    List<String> existingFolders = const [],
  }) {
    final out = <SmartNoteClassification>[];
    for (final n in notes) {
      if (n.archivedAt != null || n.deletedAt != null || n.locked) continue;
      final needTitle = suggestTitles && n.title.trim().isEmpty;
      final needTags = suggestTags && n.tags.isEmpty;
      if (!needTitle && !needTags) continue;
      if (n.toPlainText().trim().isEmpty) continue;
      final c = classify(n, learn: learn, existingFolders: existingFolders);
      out.add(
        SmartNoteClassification(
          noteId: c.noteId,
          category: c.category,
          folderSuggestion: c.folderSuggestion,
          tags: needTags ? c.tags : const [],
          suggestedTitle: needTitle ? c.suggestedTitle : null,
          confidence: c.confidence,
          localOnly: c.localOnly,
          matchedRule: c.matchedRule,
        ),
      );
    }
    return out;
  }

  /// Kullanıcı [picked] kategorisini elle seçtiğinde öneriyi günceller.
  static SmartNoteClassification overrideCategory(
    Note note,
    SmartNoteCategory picked, {
    bool suggestTitle = true,
    bool suggestTags = true,
    List<String> existingFolders = const [],
  }) {
    final needTitle = suggestTitle && note.title.trim().isEmpty;
    final needTags = suggestTags && note.tags.isEmpty;
    return SmartNoteClassification(
      noteId: note.id,
      category: picked,
      folderSuggestion: _matchExistingFolder(picked, existingFolders),
      tags: needTags ? (_defaultTags[picked] ?? const ['genel']) : const [],
      suggestedTitle: needTitle ? _deriveTitle(note) : null,
      confidence: 0.95,
      localOnly: true,
      matchedRule: 'manual_${picked.name}',
    );
  }
}

bool needsAiRefinement(SmartNoteClassification c) => c.needsAiRefinement;
