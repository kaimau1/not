import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/local_file.dart';
import '../../auth/data/google_scope_auth.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import '../domain/attachment.dart';
import '../domain/attachment_sync.dart';
import '../domain/note.dart';
import 'attachment_repository.dart';
import 'attachment_thumb.dart';
import 'drive_files_api.dart';
import 'drive_store.dart' show isGoogleUser;
import 'notes_repository.dart';

/// **YENİ EK SENKRONU BAYRAĞI** (F28.2, F19.E1): varsayılan KAPALI. Açıkken ek
/// kullanıcının Drive'ındaki görünür "Notlar" klasörüne de yüklenir; eski
/// `UploadQueue` kalkana dek yan yana çalışır, hiçbir kayıt silinmez.
final attachmentSyncV2Provider = boolPref(
  'attachment_sync_v2',
  defaultValue: false,
);

/// Ek kaydındaki Drive kimliği (yeni yapı); boş = Drive'da değil.
String attachmentDriveFileId(Attachment a) {
  final sync = a.extras['sync'];
  if (sync is! Map) return '';
  return (sync['driveFileId'] as String?) ?? '';
}

AttachState attachStateOf(Attachment a, {required bool hasLocalFile}) {
  final sync = a.extras['sync'];
  return AttachState.fromMap(
    sync is Map ? Map<String, dynamic>.from(sync) : null,
    hasLocalFile: hasLocalFile,
  );
}

/// Tek geçiş: bekleyenleri seçer, yükler, sonucu kayda yazar. Karar
/// [nextAttachState] ve [pickUploads]'ta; burası yalnız yan etki.
class AttachmentSyncEngine {
  AttachmentSyncEngine({
    required this.uploadFile,
    required this.uploadThumb,
    required this.readLocal,
    required this.saveSync,
    this.hasLocalFile,
    this.skipNote,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final Future<String> Function(Attachment a, Uint8List bytes) uploadFile;

  /// Önizleme yolu; görsel değilse ya da üretilemezse boş.
  final Future<String> Function(Attachment a, Uint8List bytes) uploadThumb;
  final Future<Uint8List?> Function(Attachment a) readLocal;
  final Future<void> Function(String noteId, String id, Map<String, dynamic> m)
  saveSync;
  final bool Function(Attachment a)? hasLocalFile;

  /// Yalnız bu cihazda kalacak not: Drive'a gitmez.
  final bool Function(Note n)? skipNote;
  final DateTime Function() _now;

  /// Başarısız denemeler bellekte: her hatada buluta yazmak gereksiz trafik.
  final _failed = <String, AttachState>{};

  // ponytail: dosya belleğe okunup tek istekte gider; büyük video için
  // Drive'ın resumable yüklemesi gerekir, D adımında UploadQueue kalkınca.
  static const maxUploadBytes = 50 * 1024 * 1024;

  bool _uploadable(Attachment a) =>
      a.kind != AttachmentKind.text && !a.isWebVideo && !a.skipsUpload;

  /// Yüklenen ek sayısını döner.
  Future<int> pass(Iterable<Note> notes) async {
    final byId = <String, ({String noteId, Attachment a})>{};
    final states = <String, AttachState>{};
    for (final n in notes) {
      if (n.deletedAt != null || (skipNote?.call(n) ?? false)) continue;
      for (final a in n.attachments) {
        if (!_uploadable(a)) continue;
        final local = hasLocalFile?.call(a) ?? localFileExists(a.localPath);
        var s = _failed[a.id] ?? attachStateOf(a, hasLocalFile: local);
        s = nextAttachState(s, const EnqueueUpload());
        byId[a.id] = (noteId: n.id, a: a);
        states[a.id] = s;
      }
    }
    var done = 0;
    while (true) {
      final picks = pickUploads(states, _now(), maxConcurrent: 1);
      if (picks.isEmpty) return done;
      final id = picks.single;
      final item = byId[id]!;
      final started = nextAttachState(states[id]!, const UploadStarted());
      try {
        final bytes = await readLocal(item.a);
        if (bytes == null) {
          states[id] = nextAttachState(started, const LocalFileLost());
          continue;
        }
        if (bytes.length > maxUploadBytes) {
          states[id] = const AttachState.local();
          continue;
        }
        final fileId = await uploadFile(item.a, bytes);
        final thumb = await uploadThumb(item.a, bytes);
        final ok = nextAttachState(
          started,
          UploadSucceeded(driveFileId: fileId, thumbPath: thumb),
        );
        await saveSync(item.noteId, id, ok.toMap());
        states[id] = ok;
        _failed.remove(id);
        done++;
      } catch (e) {
        final failed = nextAttachState(started, UploadFailed('$e', _now()));
        states[id] = failed;
        _failed[id] = failed;
      }
    }
  }
}

/// Oturumun Drive bağlantısı: bayrak açık + Google hesabı + Android/web.
/// Misafirde null: ek cihazda kalır, ana ekranın "Bağla" şeridi uyarır.
final attachmentDriveSessionProvider =
    Provider<
      ({DriveFilesApi api, DriveTokenCache tokens, GoogleScopeAuth auth})?
    >((ref) {
      if (!ref.watch(attachmentSyncV2Provider)) return null;
      if (!isGoogleUser(ref.watch(authStateProvider).value)) return null;
      if (!kIsWeb && !Platform.isAndroid) return null;
      ref.watch(currentUidProvider);
      final auth = googleScopeAuth(kDriveFileScope, 'notlar_drive_file_token');
      final tokens = DriveTokenCache(silentRefresh: auth.silent);
      final client = http.Client();
      ref.onDispose(client.close);
      return (
        api: DriveFilesApi(client: client, tokens: tokens),
        tokens: tokens,
        auth: auth,
      );
    });

/// Notlar değişince (kısa beklemeyle) ve dakikada bir geçiş. Bayrak kapalıyken
/// hiçbir şey yapmaz.
final attachmentSyncServiceProvider = Provider<void>((ref) {
  final session = ref.watch(attachmentDriveSessionProvider);
  final uid = ref.watch(currentUidProvider);
  if (session == null || uid == null) return;
  final engine = AttachmentSyncEngine(
    uploadFile: (a, bytes) => session.api.upload(
      bytes: bytes,
      fileName: a.fileName,
      mimeType: a.mimeType.isEmpty ? 'application/octet-stream' : a.mimeType,
      attachmentId: a.id,
    ),
    uploadThumb: (a, bytes) async {
      if (a.kind != AttachmentKind.image) return '';
      final thumb = await compute(makeThumbnail, bytes);
      if (thumb == null) return '';
      final path = thumbStoragePath(uid, a.id);
      await FirebaseStorage.instance
          .ref(path)
          .putData(thumb, SettableMetadata(contentType: 'image/jpeg'));
      return path;
    },
    readLocal: (a) async =>
        ref.read(attachmentRepositoryProvider)?.readLocalBytes(a),
    saveSync: (noteId, id, map) async {
      await ref
          .read(notesRepositoryProvider)
          ?.patchAttachmentSync(noteId, id, map);
    },
    skipNote: (n) => ref.read(notesRepositoryProvider)?.isLocal(n.id) ?? true,
  );
  var running = false;
  Future<void> run() async {
    if (running) return;
    running = true;
    try {
      // Jeton yoksa (izin verilmemiş) sessizce bekler: pencere açmaz.
      if (await session.tokens.get() == null) return;
      await engine.pass(ref.read(notesStreamProvider).value ?? const <Note>[]);
    } finally {
      running = false;
    }
  }

  Timer? debounce;
  ref.listen(notesStreamProvider, (_, _) {
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 5), () => unawaited(run()));
  });
  final tick = Timer.periodic(
    const Duration(minutes: 1),
    (_) => unawaited(run()),
  );
  ref.onDispose(() {
    debounce?.cancel();
    tick.cancel();
  });
});
