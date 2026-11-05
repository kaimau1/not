import '../domain/attachment.dart';
import '../domain/note.dart';

/// **EK KAYITLARI SIFIRLAMA (F28.2-C).** Hiçbir yerden OTOMATİK çağrılmaz:
/// `dataMigrationsProvider`'a bağlı değildir, arayüzü yoktur. Gerçek hesapta
/// açılması kullanıcı onayı bekliyor (F19.E1). Drive dosyalarına dokunmaz.

/// Sürüm: bu değeri tamamlamış hesap yeniden işlenmez.
const kAttachSchema = 2;

class AttachmentResetAborted implements Exception {
  AttachmentResetAborted(this.reason);
  final String reason;
  @override
  String toString() => 'AttachmentResetAborted($reason)';
}

/// Notun eski depo işaretçileri temizlenmiş ek listesi; değişecek bir şey
/// yoksa null (idempotent). Kayıt SİLİNMEZ: başka cihazdaki yerel kopya yine
/// yeni kuyruğa girebilsin, hiçbir yerde olmayan ek "dosya yok" görünsün.
/// Yeni yapının `sync` alanı (`extras`) ve düzen alanları korunur.
List<Attachment>? resetAttachmentPointers(Note note) {
  if (!note.attachments.any(
    (a) =>
        a.storagePath.isNotEmpty ||
        a.downloadUrl.isNotEmpty ||
        a.driveId.isNotEmpty,
  )) {
    return null;
  }
  return [
    for (final a in note.attachments)
      a.copyWith(storagePath: '', downloadUrl: '', driveId: ''),
  ];
}

/// Çalıştırıcı. Sıra bağlayıcı: önce yedek (başarısızsa HİÇBİR şey yazılmaz),
/// sonra kayıtlar, sonra eski Storage dosyaları, en son sürüm işareti. Yarıda
/// kesilirse yeniden çalıştırılır; işlenmiş not atlanır. Yan etkiler dışarıdan
/// verilir ki sıra emülatörsüz sınansın.
///
/// [isTestAccount] false ise durur: kullanıcının onayı olmadan gerçek hesapta
/// çalışamaz.
Future<int> runAttachmentReset({
  required bool isTestAccount,
  required int? completedSchema,
  required Future<bool> Function() backup,
  required List<Note> notes,
  required Future<void> Function(String noteId, List<Attachment> a) writeNote,
  required Future<void> Function() deleteOldStorage,
  required Future<void> Function(int schema) markDone,
}) async {
  if (!isTestAccount) throw AttachmentResetAborted('test hesabı değil');
  if (completedSchema != null && completedSchema >= kAttachSchema) return 0;
  final bool saved;
  try {
    saved = await backup();
  } catch (e) {
    throw AttachmentResetAborted('yedek alınamadı: $e');
  }
  if (!saved) throw AttachmentResetAborted('yedek alınamadı');
  var changed = 0;
  for (final n in notes) {
    final next = resetAttachmentPointers(n);
    if (next == null) continue;
    await writeNote(n.id, next);
    changed++;
  }
  await deleteOldStorage();
  await markDone(kAttachSchema);
  return changed;
}
