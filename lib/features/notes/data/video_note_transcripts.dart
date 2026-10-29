import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
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
///  1. Gemini videoyu bağlantıdan cümle başına damgalı döker (notta tam
///     transkript zaten varsa o kullanılır — [TimedTranscript]),
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
        } catch (e) {
          debugPrint('video notu transkripti ($id): $e');
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
    if (!needFull && pending.isEmpty) {
      await ref.update({'ytTodo': FieldValue.delete()});
      return;
    }
    final segments = await _segmentsFor(videoId, video.webUrl, saved?.text);
    if (segments == null || segments.isEmpty) {
      // AI dökümü yok (kota/ağ): üç denemeden sonra bırak.
      final tries = (data['ytTries'] as num? ?? 0).toInt() + 1;
      await ref.update(
        tries >= 3
            ? {
                'ytTodo': FieldValue.delete(),
                'ytTries': FieldValue.delete(),
                'ytPending': FieldValue.delete(),
              }
            : {'ytTries': tries},
      );
      return;
    }
    final excerpts = <int, String>{};
    for (final p in pending) {
      final text = await _excerpt(segments, p);
      if (text.isNotEmpty) excerpts[p.at] = text;
    }
    final full = needFull
        ? Transcripts.create(
            video,
            TimedTranscript.fullText(segments),
            fileSuffix: 'transkript',
          )
        : null;
    if (disposed) return;
    await notes.firestore.runTransaction((tx) async {
      final fresh = await tx.get(ref);
      final d = fresh.data();
      if (d == null) return;
      final current = Note.fromDoc(fresh);
      final stillPending = _pendingOf(d['ytPending']);
      var body = d['body'] as String? ?? '';
      final handled = <Map<String, Object?>>[];
      for (final p in stillPending) {
        if (!pending.any((q) => q.at == p.at)) continue;
        final text = excerpts[p.at];
        if (text != null) body = insertVideoExcerpt(body, p.line, text);
        handled.add(p.raw);
      }
      final addFull =
          full != null && Transcripts.of(current.attachments, video) == null;
      final left = stillPending.length - handled.length;
      tx.update(ref, {
        'body': body,
        if (addFull)
          'attachments': [
            for (final a in current.attachments) a.toMap(),
            full.toMap(),
          ],
        if (handled.isNotEmpty) 'ytPending': FieldValue.arrayRemove(handled),
        if (left == 0) 'ytTodo': FieldValue.delete(),
        'ytTries': FieldValue.delete(),
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
    String? saved,
  ) async {
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
      debugPrint('video dökümü ($id): $e');
    }
    return null;
  }

  Future<String> _excerpt(List<CaptionSegment> segments, _Pending p) async {
    final fallback = TimedTranscript.excerpt(segments, p.at);
    final window = TimedTranscript.window(segments, p.at);
    if (window.isEmpty) return fallback;
    try {
      final timed = [
        for (final s in window) '[${TimedTranscript.stamp(s.start)}] ${s.text}',
      ].join('\n');
      final text = await ai.videoNoteExcerpt(
        timed: timed,
        atSeconds: p.at,
        note: p.note,
      );
      // Model penceredeki metinden çok daha uzun bir şey yazdıysa uydurmuştur.
      final cap = window.fold<int>(0, (n, s) => n + s.text.length + 1) * 1.3;
      if (text.isNotEmpty && text.length <= cap) return text;
    } catch (e) {
      debugPrint('video parçası AI: $e');
    }
    return fallback;
  }

  static List<_Pending> _pendingOf(Object? raw) => [
    if (raw is List)
      for (final e in raw)
        if (e is Map && e['s'] is num)
          _Pending(
            (e['s'] as num).toInt(),
            e['line'] as String? ?? '',
            e['note'] as String? ?? '',
            Map<String, Object?>.from(e),
          ),
  ];
}

class _Pending {
  const _Pending(this.at, this.line, this.note, this.raw);

  final int at;
  final String line;
  final String note;
  final Map<String, Object?> raw;
}

extension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
