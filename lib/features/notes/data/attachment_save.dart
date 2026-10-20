import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/web_blob.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../domain/attachment.dart';
import 'attachment_repository.dart';

/// Ekin dosya adı — metin ekinin (transkript) uzantısı yoksa `.txt`.
String saveAsFileName(Attachment a) {
  var name = a.fileName.trim();
  if (name.isEmpty) name = 'ek';
  if (a.kind == AttachmentKind.text && !name.toLowerCase().endsWith('.txt')) {
    name = '$name.txt';
  }
  return name;
}

/// Ekin MIME türü (kayıtta yoksa uzantıdan / türden tahmin).
String saveAsMimeType(Attachment a) {
  if (a.mimeType.isNotEmpty) return a.mimeType;
  return switch (a.kind) {
    AttachmentKind.pdf => 'application/pdf',
    AttachmentKind.slide =>
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    AttachmentKind.text => 'text/plain',
    AttachmentKind.image => 'image/*',
    AttachmentKind.video => 'video/*',
    AttachmentKind.audio => 'audio/*',
    AttachmentKind.unknown => 'application/octet-stream',
  };
}

/// **EKİ FARKLI KAYDET** (kullanıcı isteği 2026-10-17: "eki farklı kaydet
/// butonu koy").
///
/// Ek, kullanıcının SEÇTİĞİ yere ve adla bir dosya olarak yazılır:
///  * Android — sistemin "kaydet" penceresi (`ACTION_CREATE_DOCUMENT`):
///    İndirilenler, cihaz klasörleri, Drive… (MainActivity → `saveDocument`);
///  * diğer platformlar — kayıt yeri seçici (`file_selector`);
///  * Web — tarayıcının indirmesi.
///
/// Sonuç bildirimle söylenir (kaydedildi / iptal sessiz / hata).
abstract final class AttachmentSaveAs {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  static Future<void> run(
    BuildContext context,
    WidgetRef ref,
    Attachment attachment,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final repo = ref.read(attachmentRepositoryProvider);
    final name = saveAsFileName(attachment);
    final mime = saveAsMimeType(attachment);
    try {
      final bool? saved;
      if (kIsWeb) {
        final bytes = await _bytes(repo, attachment);
        if (bytes == null) throw StateError('no-bytes');
        downloadBytes(bytes, mime, name);
        saved = true;
      } else if (Platform.isAndroid) {
        final path = await _localPath(repo, attachment);
        if (path == null) throw StateError('no-bytes');
        saved = await _channel.invokeMethod<bool>('saveDocument', {
          'path': path,
          'name': name,
          'mimeType': mime,
        });
      } else {
        final location = await getSaveLocation(suggestedName: name);
        if (location == null) {
          saved = false;
        } else {
          final bytes = await _bytes(repo, attachment);
          if (bytes == null) throw StateError('no-bytes');
          await File(location.path).writeAsBytes(bytes, flush: true);
          saved = true;
        }
      }
      if (saved ?? false) {
        messenger
          ?..hideCurrentSnackBar()
          ..showMessage(l10n.attachmentSavedAs(name));
      }
    } catch (e) {
      messenger
        ?..hideCurrentSnackBar()
        ..showMessage(l10n.attachmentSaveAsFailed);
    }
  }

  static Future<Uint8List?> _bytes(AttachmentRepository? repo, Attachment a) {
    if (!kIsWeb && localFileExists(a.localPath)) {
      return File(a.localPath).readAsBytes();
    }
    return repo?.readBytes(a) ?? Future.value();
  }

  /// Dosyanın bu cihazdaki yolu; yoksa (buluttaki ek, metin eki) geçici bir
  /// kopyası yazılır.
  static Future<String?> _localPath(
    AttachmentRepository? repo,
    Attachment a,
  ) async {
    if (a.kind != AttachmentKind.text && localFileExists(a.localPath)) {
      return a.localPath;
    }
    final bytes = await repo?.readBytes(a);
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}kaydet_'
      '${DateTime.now().microsecondsSinceEpoch}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
