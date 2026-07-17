import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../app/router.dart';
import '../domain/note_type.dart';
import 'attachment_repository.dart';
import 'notes_repository.dart';

/// Paylaş menüsünden gelen içerikleri nota çevirir: başka bir uygulamada
/// "Paylaş → Notlar" denince metin/link gövde olur, görseller ek olarak
/// yüklenir ve editör açılır. Dashboard bu provider'ı ayakta tutar.
final shareIntakeProvider = Provider<void>((ref) {
  if (kIsWeb || !Platform.isAndroid) return;

  Future<void> handle(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;

    final texts = [
      for (final f in files)
        if (f.type == SharedMediaType.text || f.type == SharedMediaType.url)
          f.path,
    ];
    final images = [
      for (final f in files)
        if (f.type == SharedMediaType.image) f,
    ];
    if (texts.isEmpty && images.isEmpty) return;

    final id = await repo.createNote(NoteType.text);
    final body = texts.join('\n').trim();
    if (body.isNotEmpty) repo.updateFields(id, {'body': body});

    final attachRepo = ref.read(attachmentRepositoryProvider);
    if (attachRepo != null) {
      for (final image in images) {
        try {
          final bytes = await File(image.path).readAsBytes();
          final attachment = await attachRepo.prepareImage(
            noteId: id,
            bytes: bytes,
            fileName: p.basename(image.path),
          );
          repo.updateFields(id, {
            'attachments': FieldValue.arrayUnion([attachment.toMap()]),
          });
        } catch (_) {
          // Tek görsel okunamazsa not yine oluşsun.
        }
      }
    }

    // Aynı içerik uygulama tekrar öne gelince yeniden işlenmesin.
    ReceiveSharingIntent.instance.reset();
    try {
      ref.read(routerProvider).push('/note/$id');
    } catch (_) {}
  }

  // Uygulama paylaşımla soğuk başlatıldıysa ilk içerik; açıkken gelenler
  // için akış dinlenir.
  ReceiveSharingIntent.instance
      .getInitialMedia()
      .then(handle)
      .catchError((Object _) {});
  final sub = ReceiveSharingIntent.instance
      .getMediaStream()
      .listen(handle, onError: (Object _) {});
  ref.onDispose(sub.cancel);
});
