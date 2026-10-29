import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/error_log.dart';
import '../../../core/utils/youtube.dart';
import '../../ai/data/gemini_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/note.dart';
import '../domain/transcript.dart';
import 'timed_transcript.dart';

/// **VİDEO NOTU TRANSKRİPTİ** (kullanıcı isteği 2026-10-29: "Kanallarım'dan
/// full transkript de gelsin; alınan notlarda — Harita'dan gelenlerde de —
/// ±10 sn'lik transkript gelsin, AI ile analiz edilsin, gerekirse birkaç sn
/// daha alınarak cümle bütünlüğü korunsun; arka planda yapılsın").
///
/// Köprü (`HaritaNotlari.kt`) video notuna her satırda `ytTodo: true` ve
/// `ytPending` (`{s: saniye, line: satır, note: metin}`) yazar; uygulama
/// açıkken bu servis onları sessizce işler:
///  1. zamanlı transkript: Kanallarım'ın `transcript` ekiyle yolladığı tam
///     altyazı (köprü `ytTranscript` alanına yazar), yoksa notta kayıtlı
///     transkript, o da yoksa Gemini videoyu bağlantıdan cümle cümle döker,
///  2. notta yoksa TAM transkript, videonun transkript eki olarak eklenir,
///  3. her bekleyen satırın altına ±10 sn'lik parça (AI cümleleri tamamlar;
///     AI yoksa cümle sınırına göre kural tabanlı) yazılır.
/// Yazım İŞLEMDE (transaction): iki cihaz aynı anda işlese de satır bir kez
/// işlenir. Yalnız Android'de çalışır (notlar telefondaki uygulamalardan
/// gelir; web ve telefon aynı anda AI harcamasın).
final videoNoteTranscriptsProvider = Provider<void>((ref) {
  if (kIsWeb) return;
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;
  final worker = _Worker(
    FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.notesCollection),
    uid,
    ref.read(geminiServiceProvider),
  );
  final sub = worker.notes
      .where('ytTodo', isEqualTo: true)
      .snapshots()
      .listen((s) => worker.enqueue([for (final d in s.docs) d.id]));
  ref.onDispose(() {
    sub.cancel();
    worker.disposed = true;
  });
});

/// Bekleyen satırın altına yazılan parçanın biçimi: “…”.
String videoExcerptLine(String excerpt) => '“$excerpt”';

/// [body]'de [line] satırının ALTINA [excerpt] satırını koyar. Satır
/// bulunamazsa (kullanıcı değiştirdi) parça sona eklenir; aynı satırın
/// altında zaten parça varsa bir sonraki eşleşmeye geçer.
String insertVideoExcerpt(String body, String line, String excerpt) {
  final quote = videoExcerptLine(excerpt);
  final lines = body.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() != line.trim()) continue;
    final next = i + 1 < lines.length ? lines[i + 1].trimLeft() : '';
    if (next.startsWith('“')) continue;
    lines.insert(i + 1, quote);
    return lines.join('\n');
  }
  final trimmed = body.trimRight();
  return trimmed.isEmpty ? quote : '$trimmed\n$quote';
}

/// Köprünün satırın altına koyduğu ham altyazı (AI düzeltene dek görünür).
String videoRawCaptionLine(String caption) => '“…$caption…”';

/// Satırın parçasını gövdeye işler: eski biçimde satır + "Altyazı (…):"
/// bloğu [line] olarak gövdede durur, satır + parça ile değişir; yeni
/// biçimde ham altyazı satırı ([videoRawCaptionLine]) düzeltilmişiyle
/// değişir; ikisi de yoksa parça satırın altına girer.
String applyVideoExcerpt(
  String body,
  String line,
  String caption,
  String excerpt,
) {
  final block = TimedTranscript.parseCaptionBlock(line);
  if (block != null && body.contains(line)) {
    final head = block.head.isEmpty ? '' : '${block.head}\n';
    return body.replaceFirst(line, '$head${videoExcerptLine(excerpt)}');
  }
  if (caption.isNotEmpty) {
    final raw = videoRawCaptionLine(caption);
    if (body.contains(raw)) {
      return body.replaceFirst(raw, videoExcerptLine(excerpt));
    }
  }
  return insertVideoExcerpt(body, block?.head ?? line, excerpt);
}

class _Worker {
  _Worker(this.notes, this.uid, this.ai);

  final CollectionReference<Map<String, dynamic>> notes;
  final String uid;
  final GeminiService ai;
  bool disposed = false;

  final _queue = <String>{};
  final _done = <String>{};
  bool _running = false;
  final _segments = <String, List<CaptionSegment>?>{};

  void enqueue(List<String> ids) {
    // Bu oturumda denenmiş not tekrar denenmez (hata döngüsü olmasın);
    // yeni satır gelince belge değişir ve kimlik yeniden kuyruğa girer.
    for (final id in ids) {
      if (_done.add(id)) _queue.add(id);
    }
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    try {
      while (_queue.isNotEmpty && !disposed) {
        final id = _queue.first;
        _queue.remove(id);
        try {
          await _process(id);
        } catch (e, st) {
          ErrorLog.record('video notu transkripti', e, st);
        }
        _done.remove(id);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _process(String noteId) async {
    final ref = notes.doc(noteId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    final note = Note.fromDoc(snap);
    final pending = _pendingOf(data['ytPending']);
    final video = note.attachments.firstWhereOrNull(
      (a) => a.isWebVideo && youTubeVideoId(a.webUrl) != null,
    );
    final videoId = video == null ? null : youTubeVideoId(video.webUrl);
    if (video == null || videoId == null) {
      await ref.update({'ytTodo': FieldValue.delete()});
      return;
    }
    final saved = Transcripts.of(note.attachments, video);
    final needFull = saved == null;
    final bridged = data['ytTranscript'] as String?;
    if (!needFull && pending.isEmpty) {
      await ref.update({
        'ytTodo': FieldValue.delete(),
        'ytTranscript': FieldValue.delete(),
      });
      return;
    }
    // Zamanlı transkript: Kanallarım'ın yolladığı tam altyazı > notta kayıtlı
    // transkript > Gemini dökümü (uzun videoda dakikalar sürebilir). Hiçbiri
    // olmasa da Kanallarım'ın ±10 sn altyazısı AI ile düzeltilir.
    final segments = await _segmentsFor(
      videoId,
      video.webUrl,
      saved?.text,
      bridged: bridged,
    );
    final failed = segments == null || segments.isEmpty;
    final excerpts = <Object, String>{};
    final ready = <Object>{};
    for (final p in pending) {
      if (failed && p.caption.isEmpty) continue;
      final text = await _excerpt(failed ? null : segments, p);
      if (text.isNotEmpty) excerpts[p.key] = text;
      ready.add(p.key);
    }
    final full = needFull && !failed
        ? Transcripts.create(
            video,
            TimedTranscript.fullText(segments),
            fileSuffix: 'transkript',
          )
        : null;
    if (disposed) return;
    final tries = (data['ytTries'] as num? ?? 0).toInt() + (failed ? 1 : 0);
    // Döküm üç kez olmadıysa bırakılır (kota/ağ); altyazısız satırlar kalır.
    final giveUp = failed && tries >= 3;
    await notes.firestore.runTransaction((tx) async {
      final fresh = await tx.get(ref);
      final d = fresh.data();
      if (d == null) return;
      final current = Note.fromDoc(fresh);
      final stillPending = _pendingOf(d['ytPending']);
      var body = d['body'] as String? ?? '';
      final handled = <Map<String, Object?>>[];
      for (final p in stillPending) {
        if (!ready.contains(p.key) && !giveUp) continue;
        final text = excerpts[p.key];
        if (text != null) {
          body = applyVideoExcerpt(body, p.line, p.caption, text);
        }
        handled.add(p.raw);
      }
      final hasFull =
          Transcripts.of(current.attachments, video) != null || full != null;
      final addFull =
          full != null && Transcripts.of(current.attachments, video) == null;
      final left = stillPending.length - handled.length;
      final done = giveUp || (left == 0 && hasFull);
      tx.update(ref, {
        'body': body,
        if (addFull)
          'attachments': [
            for (final a in current.attachments) a.toMap(),
            full.toMap(),
          ],
        if (handled.isNotEmpty) 'ytPending': FieldValue.arrayRemove(handled),
        if (d.containsKey('ytTranscript') && (done || !failed))
          'ytTranscript': FieldValue.delete(),
        if (done) 'ytTodo': FieldValue.delete(),
        if (done || !failed)
          'ytTries': FieldValue.delete()
        else
          'ytTries': tries,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      });
    });
  }

  /// Videonun zamanlı transkripti: notta kayıtlı tam transkript (damgalı)
  /// varsa ondan, yoksa Gemini videoyu bağlantıdan cümle cümle döker.
  Future<List<CaptionSegment>?> _segmentsFor(
    String id,
    String url,
    String? saved, {
    String? bridged,
  }) async {
    if (bridged != null) {
      final parsed = TimedTranscript.parseStamped(bridged);
      if (parsed.length > 1) return _segments[id] = parsed;
    }
    final cached = _segments[id];
    if (cached != null) return cached;
    if (saved != null) {
      final parsed = TimedTranscript.parseStamped(saved);
      if (parsed.length > 1) return _segments[id] = parsed;
    }
    try {
      final text = await ai.transcribeMedia(
        mimeType: 'video/mp4',
        webUrl: url,
        video: true,
        sentenceStamps: true,
      );
      final parsed = TimedTranscript.parseStamped(text);
      if (parsed.isNotEmpty) return _segments[id] = parsed;
    } catch (e) {
      ErrorLog.record('video dökümü', e);
    }
    return null;
  }

  /// Satırın parçası. Kaynaklar: Kanallarım'ın ±10 sn altyazısı (kelimeler
  /// doğru ama cümle ortasından kesik) ve varsa tam transkriptin o çevresi
  /// (cümleyi tamamlamak için birkaç sn öte). AI ikisini birleştirir; AI
  /// yoksa transkriptten cümle sınırına göre kesilir, o da yoksa ham altyazı.
  Future<String> _excerpt(List<CaptionSegment>? segments, _Pending p) async {
    final from = p.from ?? p.at - 10;
    final to = p.to ?? p.at + 10;
    final center = (from + to) / 2;
    final radius = (to - from) / 2;
    final window = segments == null
        ? const <CaptionSegment>[]
        : TimedTranscript.window(segments, center, radius: radius);
    final fallback = window.isNotEmpty
        ? TimedTranscript.excerpt(segments!, center, radius: radius)
        : p.caption;
    if (window.isEmpty && p.caption.isEmpty) return fallback;
    try {
      final timed = window.isEmpty
          ? null
          : [
              for (final s in window)
                '[${TimedTranscript.stamp(s.start)}] ${s.text}',
            ].join('\n');
      final text = await ai.videoNoteExcerpt(
        timed: timed,
        caption: p.caption,
        fromSeconds: from,
        toSeconds: to,
        note: p.note,
      );
      // Model kaynaklardan çok daha uzun bir şey yazdıysa uydurmuştur.
      final source =
          window.fold<int>(0, (n, s) => n + s.text.length + 1) +
          p.caption.length;
      if (text.isNotEmpty && text.length <= source * 1.3 + 40) return text;
    } catch (e, st) {
      ErrorLog.record('video parçası AI', e, st);
    }
    return fallback;
  }

  static List<_Pending> _pendingOf(Object? raw) => [
    if (raw is List)
      for (final e in raw)
        if (e is Map && e['s'] is num) _Pending.from(e),
  ];
}

class _Pending {
  _Pending._(
    this.at,
    this.line,
    this.note,
    this.caption,
    this.from,
    this.to,
    this.raw,
  );

  /// Köprünün kaydı. Eski köprü (v1.1.535) Kanallarım'ın "Altyazı (a – b):"
  /// bloğunu satırın İÇİNDE bırakıyordu; blok burada da ayrılır.
  factory _Pending.from(Map<dynamic, dynamic> e) {
    final line = e['line'] as String? ?? '';
    final block = TimedTranscript.parseCaptionBlock(line);
    final note = e['note'] as String? ?? '';
    int? sec(Object? v) => v is num ? v.toInt() : null;
    return _Pending._(
      (e['s'] as num).toInt(),
      line,
      TimedTranscript.parseCaptionBlock(note)?.head ?? note,
      (e['cap'] as String?) ?? block?.text ?? '',
      sec(e['from']) ?? block?.from,
      sec(e['to']) ?? block?.to,
      Map<String, Object?>.from(e),
    );
  }

  final int at;
  final String line;
  final String note;

  /// Kanallarım'ın gönderdiği ham ±10 sn altyazı ve aralığı (yoksa boş/null).
  final String caption;
  final int? from;
  final int? to;
  final Map<String, Object?> raw;

  /// Kayıt kimliği: köprünün yazdığı an (aynı saniyede iki not da ayrılır).
  Object get key => raw['at'] ?? at;
}

extension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
