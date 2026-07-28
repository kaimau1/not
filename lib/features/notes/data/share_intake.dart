import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../app/router.dart';
import '../domain/attachment.dart';
import '../domain/note_type.dart';
import 'attachment_repository.dart';
import 'notes_repository.dart';

/// Paylaş menüsünden gelen içerikleri nota çevirir: başka bir uygulamada
/// Paylaşılan dosyanın hangi ek türü olduğunu söyler; `null` ise dosya değil
/// metindir ve notun gövdesine yazılır.
///
/// Karar MIME'a göre verilir, uzantıya göre DEĞİL: eklenti dosyayı cihaza
/// kopyalarken adı sağlayıcının `_display_name` sütunundan alıyor ve bu ad
/// Drive/Gmail gibi kaynaklarda uzantısız gelebiliyor. Uzantıya bakan sürüm o
/// dosyaları sessizce atlıyordu — paylaşım hiç not oluşturmuyor, yalnızca
/// uygulama açılıyordu. Uzantı yalnızca MIME boşsa yedek ölçüt.
AttachmentKind? shareAttachmentKind(SharedMediaFile f) {
  final mime = (f.mimeType ?? '').toLowerCase();
  final ext = p.extension(f.path).toLowerCase();
  if (mime == 'application/pdf' || ext == '.pdf') return AttachmentKind.pdf;
  if (mime.contains('presentationml') || ext == '.pptx') {
    return AttachmentKind.slide;
  }
  if (mime.startsWith('image/') || f.type == SharedMediaType.image) {
    return AttachmentKind.image;
  }
  return null;
}

/// "Paylaş → Notlar" denince metin/link ve .txt/.md dosyaları gövde olur,
/// görsel/PDF/sunum ek olarak yüklenir ve editör açılır. Dashboard bu
/// provider'ı ayakta tutar.
final shareIntakeProvider = Provider<void>((ref) {
  if (kIsWeb || !Platform.isAndroid) return;

  Future<void> handle(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;

    // receive_sharing_intent yalnız SEND'i değil ACTION_VIEW'ı da yakalıyor:
    // widget/kısayol "notlar://voice" ile uygulamayı açtığında bu bağlantı
    // paylaşılan bir URL sanılıp gövdesi "notlar://voice" olan çöp not
    // oluşturuluyordu. Kendi şemamız paylaşım değil, derin bağlantıdır —
    // router zaten işliyor (notlar://new kısayolları da bu yüzden korunur).
    // Dosya paylaşımı türe göre ayrılır: düz metin GÖVDEYE yazılır (ek olarak
    // eklenseydi içeriği notta görünmezdi), PDF/sunum eke gider.
    //
    final bodyParts = <String>[];
    final docs = <SharedMediaFile>[];
    for (final f in files) {
      // receive_sharing_intent yalnız SEND'i değil ACTION_VIEW'ı da yakalıyor:
      // widget/kısayol "notlar://voice" ile uygulamayı açtığında bu bağlantı
      // paylaşılan bir URL sanılıp gövdesi "notlar://voice" olan çöp not
      // oluşturuluyordu. Kendi şemamız paylaşım değil, derin bağlantıdır —
      // router zaten işliyor (notlar://new kısayolları da bu yüzden korunur).
      if (f.path.trimLeft().startsWith('notlar://')) continue;
      if (shareAttachmentKind(f) != null) {
        docs.add(f);
        continue;
      }
      // Metin girdisi iki şey olabilir: paylaşılan yazının KENDİSİ ya da bir
      // .txt dosyasının YOLU — eklenti ikisini de aynı alanda veriyor. Diskte
      // varsa içeriği okunur, yoksa metnin kendisidir.
      try {
        final file = File(f.path);
        bodyParts.add(file.existsSync() ? await file.readAsString() : f.path);
      } catch (_) {
        // Okunamayan dosya notu engellemesin.
      }
    }
    if (bodyParts.isEmpty && docs.isEmpty) return;

    final id = await repo.createNote(NoteType.text);
    final body = bodyParts.join('\n').trim();
    if (body.isNotEmpty) repo.updateFields(id, {'body': body});

    final attachRepo = ref.read(attachmentRepositoryProvider);
    if (attachRepo != null) {
      for (final file in docs) {
        try {
          final bytes = await File(file.path).readAsBytes();
          final kind = shareAttachmentKind(file)!;
          var name = p.basename(file.path);
          // Ad uzantısız geldiyse (bkz. kindOf) türün uzantısı eklenir; yoksa
          // ek uzantısız kaydedilir ve dışa aktarıldığında açılmaz.
          if (p.extension(name).isEmpty) {
            name += switch (kind) {
              AttachmentKind.pdf => '.pdf',
              AttachmentKind.slide => '.pptx',
              _ => '.jpg',
            };
          }
          final attachment = switch (kind) {
            AttachmentKind.pdf => await attachRepo.preparePdf(
              noteId: id,
              bytes: bytes,
              fileName: name,
            ),
            AttachmentKind.slide => await attachRepo.prepareSlide(
              noteId: id,
              bytes: bytes,
              fileName: name,
            ),
            _ => await attachRepo.prepareImage(
              noteId: id,
              bytes: bytes,
              fileName: name,
            ),
          };
          repo.updateFields(id, {
            'attachments': FieldValue.arrayUnion([attachment.toMap()]),
          });
        } catch (_) {
          // Tek dosya okunamazsa/çok büyükse not yine oluşsun.
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
  final sub = ReceiveSharingIntent.instance.getMediaStream().listen(
    handle,
    onError: (Object _) {},
  );
  ref.onDispose(sub.cancel);
});
