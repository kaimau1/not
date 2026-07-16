import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/attachment.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return AttachmentRepository(FirebaseStorage.instance, uid);
});

class _CompressRequest {
  const _CompressRequest(this.bytes, this.maxDimension);

  final Uint8List bytes;
  final int maxDimension;
}

class _CompressResult {
  const _CompressResult(this.bytes, this.width, this.height, this.isJpg);

  final Uint8List bytes;
  final int width;
  final int height;
  final bool isJpg;
}

_CompressResult _compressImage(_CompressRequest request) {
  final decoded = img.decodeImage(request.bytes);
  if (decoded == null) {
    return _CompressResult(request.bytes, 0, 0, false);
  }
  var picture = decoded;
  final longest =
      picture.width > picture.height ? picture.width : picture.height;
  if (longest > request.maxDimension) {
    picture = img.copyResize(
      picture,
      width: picture.width >= picture.height ? request.maxDimension : null,
      height: picture.height > picture.width ? request.maxDimension : null,
      interpolation: img.Interpolation.linear,
    );
  }
  final encoded = Uint8List.fromList(img.encodeJpg(picture, quality: 85));
  // Yeniden kodlama dosyayı büyüttüyse orijinali koru.
  if (encoded.length >= request.bytes.length) {
    return _CompressResult(request.bytes, decoded.width, decoded.height, false);
  }
  return _CompressResult(encoded, picture.width, picture.height, true);
}

/// Ekleri önce cihaza kopyalar (not çevrimdışıyken bile eklenebilsin),
/// sonra Firebase Storage'a yükler. Yükleme kuyruğu [uploadPending] üzerinden
/// çalışır.
class AttachmentRepository {
  AttachmentRepository(this._storage, this.uid);

  final FirebaseStorage _storage;
  final String uid;

  static const _uuid = Uuid();

  Future<Directory> _attachmentsDir(String noteId) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'attachments', noteId));
    await dir.create(recursive: true);
    return dir;
  }

  /// Görseli küçültüp yerel kopyasını oluşturur; yükleme sonradan yapılır.
  Future<Attachment> prepareImage({
    required String noteId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final result = await compute(
      _compressImage,
      _CompressRequest(bytes, AppConstants.maxImageDimension),
    );
    if (result.bytes.length > AppConstants.maxAttachmentBytes) {
      throw const FileTooLargeException();
    }
    final id = _uuid.v4();
    final safeName = result.isJpg
        ? '${p.basenameWithoutExtension(fileName)}.jpg'
        : p.basename(fileName);
    final dir = await _attachmentsDir(noteId);
    final file = File(p.join(dir.path, '${id}_$safeName'));
    await file.writeAsBytes(result.bytes, flush: true);

    return Attachment(
      id: id,
      kind: AttachmentKind.image,
      fileName: safeName,
      mimeType: result.isJpg ? 'image/jpeg' : _mimeFromName(safeName),
      localPath: file.path,
      sizeBytes: result.bytes.length,
      width: result.width == 0 ? null : result.width,
      height: result.height == 0 ? null : result.height,
      createdAt: DateTime.now(),
    );
  }

  Future<Attachment> preparePdf({
    required String noteId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (bytes.length > AppConstants.maxAttachmentBytes) {
      throw const FileTooLargeException();
    }
    final id = _uuid.v4();
    final safeName = p.basename(fileName);
    final dir = await _attachmentsDir(noteId);
    final file = File(p.join(dir.path, '${id}_$safeName'));
    await file.writeAsBytes(bytes, flush: true);

    return Attachment(
      id: id,
      kind: AttachmentKind.pdf,
      fileName: safeName,
      mimeType: 'application/pdf',
      localPath: file.path,
      sizeBytes: bytes.length,
      createdAt: DateTime.now(),
    );
  }

  /// Ses kaydını yerel eke dönüştürür (kayıt dosyası zaten diskte).
  Future<Attachment> prepareAudio({
    required String noteId,
    required String sourcePath,
    required Duration duration,
  }) async {
    final source = File(sourcePath);
    final sizeBytes = await source.length();
    if (sizeBytes > AppConstants.maxAttachmentBytes) {
      throw const FileTooLargeException();
    }
    final id = _uuid.v4();
    final fileName = 'kayit_${duration.inSeconds}s.m4a';
    final dir = await _attachmentsDir(noteId);
    final file = await source.copy(p.join(dir.path, '${id}_$fileName'));
    await source.delete();

    return Attachment(
      id: id,
      kind: AttachmentKind.audio,
      fileName: fileName,
      mimeType: 'audio/mp4',
      localPath: file.path,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
    );
  }

  /// Yerel kopyası olup henüz yüklenmemiş eki Storage'a gönderir ve
  /// indirme adresiyle birlikte güncellenmiş metadata'yı döner.
  Future<Attachment?> upload(String noteId, Attachment attachment) async {
    if (attachment.isUploaded || attachment.localPath.isEmpty) return null;
    final file = File(attachment.localPath);
    if (!await file.exists()) return null;

    final storagePath =
        'users/$uid/notes/$noteId/${attachment.id}_${attachment.fileName}';
    final ref = _storage.ref(storagePath);
    await ref.putFile(
      file,
      SettableMetadata(contentType: attachment.mimeType),
    );
    final url = await ref.getDownloadURL();
    return attachment.copyWith(storagePath: storagePath, downloadUrl: url);
  }

  Future<void> deleteFromStorage(Attachment attachment) async {
    if (attachment.storagePath.isEmpty) return;
    try {
      await _storage.ref(attachment.storagePath).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// PDF baytlarını getirir: önce yerel kopya, yoksa Storage'dan indirir.
  Future<Uint8List?> readBytes(Attachment attachment) async {
    if (attachment.localPath.isNotEmpty) {
      final file = File(attachment.localPath);
      if (await file.exists()) return file.readAsBytes();
    }
    if (attachment.storagePath.isNotEmpty) {
      return _storage
          .ref(attachment.storagePath)
          .getData(AppConstants.maxAttachmentBytes);
    }
    return null;
  }

  static String _mimeFromName(String name) {
    final ext = p.extension(name).toLowerCase();
    return switch (ext) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}

class FileTooLargeException implements Exception {
  const FileTooLargeException();
}
