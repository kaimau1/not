import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/note.dart';
import 'attachment_repository.dart';
import 'notes_repository.dart';

/// Bekleyen ekleri arka planda Firebase Storage'a taşıyan kuyruk.
/// Not akışını ve bağlantı durumunu izler; yüklenmemiş yerel eki olan her
/// notu yakalayıp sırayla yükler. Dashboard açıkken kendiliğinden çalışır.
final uploadQueueProvider = Provider<UploadQueue>((ref) {
  final queue = UploadQueue(ref);
  ref.onDispose(queue.dispose);
  queue.start();
  return queue;
});

class UploadQueue {
  UploadQueue(this._ref);

  final Ref _ref;
  final Set<String> _inFlight = {};
  ProviderSubscription<AsyncValue<List<Note>>>? _notesSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void start() {
    _notesSub = _ref.listen(notesStreamProvider, (previous, next) {
      final notes = next.value;
      if (notes != null) _process(notes);
    }, fireImmediately: true);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        final notes = _ref.read(notesStreamProvider).value;
        if (notes != null) _process(notes);
      }
    });
  }

  Future<void> _process(List<Note> notes) async {
    final attachmentRepo = _ref.read(attachmentRepositoryProvider);
    final notesRepo = _ref.read(notesRepositoryProvider);
    if (attachmentRepo == null || notesRepo == null) return;

    for (final note in notes) {
      for (final attachment in note.attachments) {
        if (attachment.isUploaded || attachment.localPath.isEmpty) continue;
        final key = '${note.id}/${attachment.id}';
        if (!_inFlight.add(key)) continue;
        try {
          final uploaded = await attachmentRepo.upload(note.id, attachment);
          if (uploaded != null) {
            await notesRepo.patchAttachment(note.id, uploaded);
          }
        } catch (e) {
          // Bağlantı yoksa veya yükleme başarısızsa bir sonraki tetikte
          // yeniden denenir.
          debugPrint('Ek yüklenemedi ($key): $e');
        } finally {
          _inFlight.remove(key);
        }
      }
    }
  }

  void dispose() {
    _notesSub?.close();
    _connectivitySub?.cancel();
  }
}
