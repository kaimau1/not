import '../../../core/utils/search_fold.dart';
import 'note.dart';

/// **ÇÖP KUTUSU ANALİZİ** (kullanıcı isteği 2026-10-20: "çöp kutusuna AI
/// analiz ekle, akıllı bir analiz yapsın").
///
/// İki katman: önce CİHAZDA, anında ve ücretsiz kurallar (bu dosya — saf,
/// test edilebilir); kullanıcı isterse üstüne AI'nın içeriğe bakan derin
/// analizi (bkz. `GeminiService.analyzeTrash`). Kurallar iki yöne öneri
/// üretir: "geri yüklemeyi düşün" (içinde iş/bilgi kalmış notlar) ve "güvenle
/// silinebilir" (boş, kopya, içeriksiz). Kesin karar kullanıcının — hiçbir
/// şey kendiliğinden silinmez ya da geri yüklenmez.
enum TrashVerdict { restore, delete }

/// Öneri gerekçesi; metin arayüzde yerelleştirilir.
enum TrashReason {
  /// Boş ya da yalnız birkaç harf: kaybedilecek bir şey yok.
  empty,

  /// Aynı içerik çöpte olmayan bir notta zaten var.
  duplicateOfActive,

  /// Aynı içerik çöpte birden çok kez var: en yenisi dışındakiler.
  duplicateInTrash,

  /// İşaretlenmemiş (yapılmamış) maddeler var.
  openTasks,

  /// İleri tarihli hatırlatıcı kurulu.
  futureReminder,

  /// Şifre, IBAN, telefon gibi kaybı pahalı bilgi geçiyor.
  sensitiveInfo,

  /// Ekler (görsel, belge, ses) taşıyor.
  hasAttachments,

  /// Uzun, emek verilmiş metin.
  substantial,

  /// AI'nın kendi gerekçesi ([TrashSuggestion.note] metninde).
  ai,
}

class TrashSuggestion {
  const TrashSuggestion({
    required this.noteId,
    required this.verdict,
    required this.reason,
    this.note = '',
  });

  final String noteId;
  final TrashVerdict verdict;
  final TrashReason reason;

  /// AI gerekçesi ya da ek ayrıntı (ör. kopyanın başlığı).
  final String note;
}

/// Çöpün sayısal özeti.
class TrashStats {
  const TrashStats({
    required this.count,
    required this.attachmentCount,
    required this.soonCount,
    required this.lockedCount,
  });

  final int count;
  final int attachmentCount;

  /// 3 gün içinde kalıcı silinecekler.
  final int soonCount;

  /// İçeriği analize (AI'ya) GİRMEYEN kilitli notlar.
  final int lockedCount;
}

class TrashAnalysis {
  const TrashAnalysis({required this.stats, required this.suggestions});

  final TrashStats stats;

  /// Not başına EN FAZLA bir öneri (en güçlü gerekçe).
  final List<TrashSuggestion> suggestions;

  Iterable<TrashSuggestion> of(TrashVerdict verdict) =>
      suggestions.where((s) => s.verdict == verdict);
}

/// Kaybı pahalı bilgi kalıpları: parola/şifre sözcüğü, IBAN, kart/telefon
/// gibi uzun rakam dizileri, e-posta.
final _sensitive = RegExp(
  r'(şifre|sifre|parola|password|pin\b|iban|tr\d{2}\s?\d{4}|'
  r'\b\d{10,}\b|\b\d{3}[\s-]\d{3}[\s-]\d{2}[\s-]\d{2}\b|'
  r'[\w.+-]+@[\w-]+\.[\w.]+)',
  caseSensitive: false,
);

/// Notun içeriği (karşılaştırma için katlanmış, boşluksuz).
String _fingerprint(Note note) =>
    foldForSearch(note.toPlainText()).replaceAll(RegExp(r'\s+'), ' ').trim();

/// Çöpü cihazda inceler. [active]: çöpte OLMAYAN notlar (kopya denetimi).
/// [daysLeft]: notun kalıcı silinmesine kalan gün (null = bilinmiyor).
TrashAnalysis analyzeTrash(
  List<Note> trash, {
  required List<Note> active,
  required int? Function(Note note) daysLeft,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final activePrints = <String, Note>{
    for (final n in active)
      if (!n.locked) _fingerprint(n): n,
  }..remove('');
  // Çöpün içindeki kopyalar: aynı içerikten en yeni silineni kalır.
  final newestByPrint = <String, Note>{};
  for (final n in trash) {
    if (n.locked) continue;
    final print = _fingerprint(n);
    if (print.isEmpty) continue;
    final seen = newestByPrint[print];
    final nd = n.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final sd = seen?.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    if (seen == null || nd.isAfter(sd)) newestByPrint[print] = n;
  }

  final suggestions = <TrashSuggestion>[];
  var attachments = 0;
  var soon = 0;
  var locked = 0;
  for (final n in trash) {
    attachments += n.attachments.length;
    if ((daysLeft(n) ?? 99) <= 3) soon++;
    if (n.locked) {
      // Kilitli notun içeriğine bakılmaz.
      locked++;
      continue;
    }
    final print = _fingerprint(n);
    TrashSuggestion pick(TrashVerdict v, TrashReason r, [String note = '']) =>
        TrashSuggestion(noteId: n.id, verdict: v, reason: r, note: note);

    // SİLİNEBİLİR gerekçeler önce: boş not ya da başka yerde duran kopya
    // için "geri yükle" önermek anlamsız.
    if (print.length < 3 && n.attachments.isEmpty) {
      suggestions.add(pick(TrashVerdict.delete, TrashReason.empty));
      continue;
    }
    final twin = activePrints[print];
    if (twin != null) {
      suggestions.add(
        pick(
          TrashVerdict.delete,
          TrashReason.duplicateOfActive,
          twin.displayTitle.trim(),
        ),
      );
      continue;
    }
    if (print.isNotEmpty && newestByPrint[print]?.id != n.id) {
      suggestions.add(pick(TrashVerdict.delete, TrashReason.duplicateInTrash));
      continue;
    }
    // GERİ YÜKLE gerekçeleri, güçlüden zayıfa.
    final reminder = n.reminderAt;
    if (reminder != null && reminder.isAfter(at)) {
      suggestions.add(pick(TrashVerdict.restore, TrashReason.futureReminder));
      continue;
    }
    if (_sensitive.hasMatch(n.toPlainText())) {
      suggestions.add(pick(TrashVerdict.restore, TrashReason.sensitiveInfo));
      continue;
    }
    final open = n.items.where((i) => !i.checked && i.text.trim().isNotEmpty);
    if (open.isNotEmpty) {
      suggestions.add(
        pick(TrashVerdict.restore, TrashReason.openTasks, '${open.length}'),
      );
      continue;
    }
    if (n.attachments.isNotEmpty) {
      suggestions.add(
        pick(
          TrashVerdict.restore,
          TrashReason.hasAttachments,
          '${n.attachments.length}',
        ),
      );
      continue;
    }
    if (print.length >= 600) {
      suggestions.add(pick(TrashVerdict.restore, TrashReason.substantial));
    }
  }
  return TrashAnalysis(
    stats: TrashStats(
      count: trash.length,
      attachmentCount: attachments,
      soonCount: soon,
      lockedCount: locked,
    ),
    suggestions: suggestions,
  );
}

/// AI'ya giden özet: not başına kısa satır (kimlik yerine sıra numarası —
/// belirteç tasarrufu). Kilitli notlar GİRMEZ. [limit] not, metin 220 harfe
/// kırpılır. Dönen harita: sıra numarası → not kimliği.
({String digest, Map<String, String> ids}) trashDigest(
  List<Note> trash, {
  int limit = 60,
}) {
  final buffer = StringBuffer();
  final ids = <String, String>{};
  var index = 0;
  for (final n in trash) {
    if (n.locked) continue;
    if (index >= limit) break;
    index++;
    final key = 'n$index';
    ids[key] = n.id;
    var text = n.toPlainText().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length > 220) text = '${text.substring(0, 220)}…';
    final open = n.items.where((i) => !i.checked && i.text.trim().isNotEmpty);
    buffer.writeln(
      '[$key] ${text.isEmpty ? '(boş)' : text}'
      '${n.attachments.isEmpty ? '' : ' | ek: ${n.attachments.map((a) => a.kind.id).join(',')}'}'
      '${open.isEmpty ? '' : ' | açık madde: ${open.length}'}',
    );
  }
  return (digest: buffer.toString(), ids: ids);
}
