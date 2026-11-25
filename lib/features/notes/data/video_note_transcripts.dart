import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/error_log.dart';
import '../../../core/utils/youtube.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/note.dart';
import '../domain/transcript.dart';
import 'timed_transcript.dart';

/// **VİDEO NOTU TRANSKRİPTİ** (yerel altyazı / Kanallarım köprüsü).
///
/// Köprü (`HaritaNotlari.kt`) video notuna her satırda `ytTodo: true` ve
/// `ytPending` yazar; uygulama açıkken bu servis köprüden gelen zamanlı
/// transkripti ve cümle kesitlerini yerelde işler.
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

/// [body]'de [line] satırının ALTINA [excerpt] satırını koyar.
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

/// Köprünün satırın altına koyduğu ham altyazı.
String videoRawCaptionLine(String caption) => '“…$caption…”';

/// Satırın parçasını gövdeye işler.
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
  _Worker(this.notes, this.uid);

  final CollectionReference<Map<String, dynamic>> notes;
  final String uid;
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
      await ref.update({
        'ytTodo': FieldValue.delete(),
        kSyncAtField: FieldValue.serverTimestamp(),
      });
      return;
    }
    final saved = Transcripts.of(note.attachments, video);
    final needFull = saved == null;
    final bridged = data['ytTranscript'] as String?;
    if (!needFull && pending.isEmpty) {
      await ref.update({
        'ytTodo': FieldValue.delete(),
        'ytTranscript': FieldValue.delete(),
        kSyncAtField: FieldValue.serverTimestamp(),
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
          'attachments': current.attachmentsField([
            ...current.attachments,
            full,
          ]),
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
        kSyncAtField: FieldValue.serverTimestamp(),
      });
    });
  }

  /// Videonun zamanlı transkripti: köprüden gelen tam altyazı veya notta
  /// kayıtlı damgalı transkript.
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
    return null;
  }

  /// Satırın parçası: transkriptten cümle sınırına göre kesilir, yoksa ham altyazı.
  Future<String> _excerpt(List<CaptionSegment>? segments, _Pending p) async {
    final from = p.from ?? p.at - 10;
    final to = p.to ?? p.at + 10;
    final center = (from + to) / 2;
    final radius = (to - from) / 2;
    final window = segments == null
        ? const <CaptionSegment>[]
        : TimedTranscript.window(segments, center, radius: radius);
    return window.isNotEmpty
        ? TimedTranscript.excerpt(segments!, center, radius: radius)
        : p.caption;
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
