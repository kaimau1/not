/// **EK SENKRONU — YENİ DURUM MAKİNESİ** (F28.2-A, 2026-11-04).
///
/// KARAR (kullanıcı, 2026-11-03): ek senkronu baştan yazılır. Asıl dosya
/// kullanıcının KENDİ Google Drive'ında (`drive.file`, görünür "Notlar"
/// klasörü), Firebase Storage'ta yalnız küçük önizleme (≤ [kThumbMaxBytes]).
///
/// Bu dosya SAF Dart: ağ, Firebase, Flutter yok. Her ekin senkron durumu
/// tek bir değer ([AttachState]), geçişler tek fonksiyon ([nextAttachState]).
/// Kalıcılık ek kaydındaki alanlardır ([AttachState.toMap] /
/// [AttachState.fromMap]) — ayrı yerel tablo tutulmaz. Eski `UploadQueue`
/// yerine geçecek `AttachmentSyncService` (B/D adımları) yalnız bu
/// fonksiyonu çağırır; kararı kendisi vermez.
///
/// Durumlar:
/// ```
/// local ──enqueue──▶ queued ──start──▶ uploading ──ok──▶ synced
///   ▲                  ▲                  │                 │
///   │ (misafir)        └──retryDue/Now── failed ◀──error───┘ │
///   │                                                        │
///   └────────────── başka cihaz: remote ──downloaded──▶ synced
/// ```
/// `missing`: dosya hiçbir yerde yok (yerel kopya gitti, Drive kimliği yok)
/// — kullanıcının kabul ettiği kayıp (KARAR 1); kart "dosya yok" gösterir.
library;

/// Storage'taki önizlemenin bayt tavanı (kural da aynı sınırı uygular —
/// `storage.rules` → `users/{uid}/thumbs/`).
const kThumbMaxBytes = 40 * 1024;

/// Kullanıcı başına önizleme sayısı tavanı (≈ 5000 × 40 KB ≈ 200 MB üst
/// sınır). Storage kuralları toplam sayamaz; istemci zorlar, aşınca yeni
/// eklerin önizlemesi yüklenmez (dosya yine Drive'a gider).
const kMaxThumbsPerUser = 5000;

/// Önizlemenin Storage yolu. Tek kaynak: kural testi ve servis aynı yolu
/// kullanır.
String thumbStoragePath(String uid, String attachmentId) =>
    'users/$uid/thumbs/$attachmentId.jpg';

/// Kullanıcının Drive'ında eklerin durduğu görünür klasörün adı.
const kDriveFolderName = 'Notlar';

/// Yeniden deneme beklemesinin tabanı ve tavanı (eski kuyrukla aynı:
/// 1 dk, 2 dk, 4 dk … en çok 6 saat).
const kSyncRetryBase = Duration(minutes: 1);
const kSyncRetryMax = Duration(hours: 6);

/// [attempts]. başarısızlıktan sonra beklenecek süre (üstel, tavanlı).
Duration syncRetryDelay(int attempts) {
  final n = attempts < 1 ? 1 : attempts;
  final shift = (n - 1).clamp(0, 12);
  final scaled = kSyncRetryBase * (1 << shift);
  return scaled > kSyncRetryMax ? kSyncRetryMax : scaled;
}

enum AttachPhase { local, queued, uploading, synced, remote, failed, missing }

/// Bir ekin senkron durumu. Değişmez; geçiş [nextAttachState] ile.
class AttachState {
  const AttachState._(
    this.phase, {
    this.driveFileId = '',
    this.thumbPath = '',
    this.attempts = 0,
    this.nextRetryAt,
    this.lastError = '',
  });

  /// Yalnız bu cihazda (misafir, ya da henüz kuyruğa girmemiş).
  const AttachState.local() : this._(AttachPhase.local);

  final AttachPhase phase;

  /// Drive'daki dosya kimliği (synced/remote'ta dolu).
  final String driveFileId;

  /// Storage önizleme yolu; boş = önizleme yok (tavan aşıldı ya da tür
  /// önizlenemiyor — kart simge gösterir).
  final String thumbPath;

  /// Ardışık başarısız deneme sayısı (yalnız failed'da > 0).
  final int attempts;

  /// failed: en erken yeniden deneme anı.
  final DateTime? nextRetryAt;

  /// failed: son hatanın kısa metni (kullanıcıya gösterilmez, günlük için).
  final String lastError;

  /// Dosya buluta ulaştı mı (başka cihazlar indirebilir).
  bool get isInCloud =>
      phase == AttachPhase.synced || phase == AttachPhase.remote;

  /// Servisin bu ekle şimdi ilgilenmesi gerekiyor mu.
  bool wantsUpload(DateTime now) =>
      phase == AttachPhase.queued ||
      (phase == AttachPhase.failed &&
          (nextRetryAt == null || !now.isBefore(nextRetryAt!)));

  // ── Kalıcılık ─────────────────────────────────────────────────────────
  // Ek kaydına `sync` alt haritası olarak yazılır. `uploading` kalıcı
  // değildir: uygulama yükleme ortasında kapanırsa açılışta `queued` olarak
  // okunur (yarım yükleme yeniden başlar — Drive yüklemesi idempotent değil
  // ama yarım dosya kimlik döndürmediği için çift kayıt oluşmaz).

  Map<String, dynamic> toMap() => {
    'phase': (phase == AttachPhase.uploading ? AttachPhase.queued : phase).name,
    if (driveFileId.isNotEmpty) 'driveFileId': driveFileId,
    if (thumbPath.isNotEmpty) 'thumbPath': thumbPath,
    if (attempts > 0) 'attempts': attempts,
    if (nextRetryAt != null)
      'nextRetryAt': nextRetryAt!.toUtc().millisecondsSinceEpoch,
    if (lastError.isNotEmpty) 'lastError': lastError,
  };

  /// Kayıttan okur. [hasLocalFile]: bu cihazda dosyanın kopyası var mı —
  /// aynı kayıt bir cihazda `synced`, öbüründe `remote` okunur.
  factory AttachState.fromMap(
    Map<String, dynamic>? m, {
    required bool hasLocalFile,
  }) {
    if (m == null) {
      return hasLocalFile
          ? const AttachState.local()
          : const AttachState._(AttachPhase.missing);
    }
    final phase = AttachPhase.values.firstWhere(
      (p) => p.name == m['phase'],
      orElse: () => AttachPhase.local,
    );
    final driveFileId = (m['driveFileId'] as String?) ?? '';
    final thumbPath = (m['thumbPath'] as String?) ?? '';
    final retryMs = m['nextRetryAt'];
    final base = AttachState._(
      phase == AttachPhase.uploading ? AttachPhase.queued : phase,
      driveFileId: driveFileId,
      thumbPath: thumbPath,
      attempts: (m['attempts'] as num?)?.toInt() ?? 0,
      nextRetryAt: retryMs is num
          ? DateTime.fromMillisecondsSinceEpoch(retryMs.toInt(), isUtc: true)
          : null,
      lastError: (m['lastError'] as String?) ?? '',
    );
    // Cihaza göre düzelt: buluttaysa, yerel kopya var/yok → synced/remote.
    if (driveFileId.isNotEmpty) {
      return base._with(
        phase: hasLocalFile ? AttachPhase.synced : AttachPhase.remote,
        attempts: 0,
        clearRetry: true,
        lastError: '',
      );
    }
    // Bulutta değil ve bu cihazda da yok: ya başka cihazda bekliyor
    // (yükleyecek olan o) ya da kayıp. Bu cihaz için ikisi de "dosya yok".
    if (!hasLocalFile) return base._with(phase: AttachPhase.missing);
    return base;
  }

  AttachState _with({
    AttachPhase? phase,
    String? driveFileId,
    String? thumbPath,
    int? attempts,
    DateTime? nextRetryAt,
    bool clearRetry = false,
    String? lastError,
  }) => AttachState._(
    phase ?? this.phase,
    driveFileId: driveFileId ?? this.driveFileId,
    thumbPath: thumbPath ?? this.thumbPath,
    attempts: attempts ?? this.attempts,
    nextRetryAt: clearRetry ? null : (nextRetryAt ?? this.nextRetryAt),
    lastError: lastError ?? this.lastError,
  );

  @override
  bool operator ==(Object other) =>
      other is AttachState &&
      other.phase == phase &&
      other.driveFileId == driveFileId &&
      other.thumbPath == thumbPath &&
      other.attempts == attempts &&
      other.nextRetryAt == nextRetryAt &&
      other.lastError == lastError;

  @override
  int get hashCode => Object.hash(
    phase,
    driveFileId,
    thumbPath,
    attempts,
    nextRetryAt,
    lastError,
  );

  @override
  String toString() =>
      'AttachState(${phase.name}'
      '${driveFileId.isEmpty ? '' : ', drive=$driveFileId'}'
      '${attempts == 0 ? '' : ', attempts=$attempts'})';
}

/// Durum makinesine gelen olaylar.
sealed class AttachEvent {
  const AttachEvent();
}

/// Ek buluta gönderilsin (Google hesabı bağlı, not yalnız-bu-cihaz değil).
class EnqueueUpload extends AttachEvent {
  const EnqueueUpload();
}

/// Servis yüklemeye başladı.
class UploadStarted extends AttachEvent {
  const UploadStarted();
}

/// Yükleme bitti: Drive kimliği (+ varsa önizleme yolu).
class UploadSucceeded extends AttachEvent {
  const UploadSucceeded({required this.driveFileId, this.thumbPath = ''});
  final String driveFileId;
  final String thumbPath;
}

/// Yükleme başarısız; [now] üstel beklemenin başlangıcı.
class UploadFailed extends AttachEvent {
  const UploadFailed(this.error, this.now);
  final String error;
  final DateTime now;
}

/// Kullanıcı "şimdi yeniden dene" dedi (beklemeyi atlar).
class RetryNow extends AttachEvent {
  const RetryNow();
}

/// Bu cihaz dosyayı Drive'dan indirdi.
class Downloaded extends AttachEvent {
  const Downloaded();
}

/// Bu cihazdaki yerel kopya silindi/bulunamadı.
class LocalFileLost extends AttachEvent {
  const LocalFileLost();
}

/// Hesaptan çıkıldı / misafire dönüldü: bekleyen yüklemeler durur.
class AccountUnlinked extends AttachEvent {
  const AccountUnlinked();
}

/// Tek geçiş fonksiyonu. Geçersiz olay durumu DEĞİŞTİRMEZ (aynı nesne
/// döner) — servis "bir şey değişti mi" sorusunu `identical` ile sorar.
AttachState nextAttachState(AttachState s, AttachEvent e) {
  switch (e) {
    case EnqueueUpload():
      if (s.phase == AttachPhase.local) {
        return s._with(phase: AttachPhase.queued);
      }
      return s;
    case UploadStarted():
      if (s.phase == AttachPhase.queued || s.phase == AttachPhase.failed) {
        return s._with(phase: AttachPhase.uploading);
      }
      return s;
    case UploadSucceeded(:final driveFileId, :final thumbPath):
      if (s.phase != AttachPhase.uploading || driveFileId.isEmpty) return s;
      return AttachState._(
        AttachPhase.synced,
        driveFileId: driveFileId,
        thumbPath: thumbPath,
      );
    case UploadFailed(:final error, :final now):
      if (s.phase != AttachPhase.uploading) return s;
      final attempts = s.attempts + 1;
      return s._with(
        phase: AttachPhase.failed,
        attempts: attempts,
        nextRetryAt: now.add(syncRetryDelay(attempts)),
        lastError: error.length > 200 ? error.substring(0, 200) : error,
      );
    case RetryNow():
      if (s.phase != AttachPhase.failed) return s;
      return s._with(phase: AttachPhase.queued, clearRetry: true);
    case Downloaded():
      if (s.phase != AttachPhase.remote) return s;
      return s._with(phase: AttachPhase.synced);
    case LocalFileLost():
      return switch (s.phase) {
        AttachPhase.synced => s._with(phase: AttachPhase.remote),
        AttachPhase.local ||
        AttachPhase.queued ||
        AttachPhase.uploading ||
        AttachPhase.failed => AttachState._(AttachPhase.missing),
        AttachPhase.remote || AttachPhase.missing => s,
      };
    case AccountUnlinked():
      return switch (s.phase) {
        AttachPhase.queued ||
        AttachPhase.uploading ||
        AttachPhase.failed => const AttachState.local(),
        _ => s,
      };
  }
}

/// Bekleyenlerden şimdi yüklenecekleri seçer: önce hiç denenmemiş
/// (`queued`), sonra vakti gelmiş `failed` (az denenen önce); aynı anda en
/// çok [maxConcurrent] (zaten `uploading` olanlar sayılır).
List<String> pickUploads(
  Map<String, AttachState> states,
  DateTime now, {
  int maxConcurrent = 2,
}) {
  final busy = states.values
      .where((s) => s.phase == AttachPhase.uploading)
      .length;
  final free = maxConcurrent - busy;
  if (free <= 0) return const [];
  final candidates =
      states.entries.where((e) => e.value.wantsUpload(now)).toList()
        ..sort((a, b) {
          final byAttempts = a.value.attempts.compareTo(b.value.attempts);
          return byAttempts != 0 ? byAttempts : a.key.compareTo(b.key);
        });
  return [for (final e in candidates.take(free)) e.key];
}
