import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/settings_providers.dart';
import '../domain/attachment.dart';
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

  /// Son başarısız deneme + deneme sayısı (ek başına): not akışı her tuş
  /// vuruşunda snapshot ürettiğinden, kalıcı olarak başarısız bir yükleme
  /// aralıksız yeniden denenip ağ/pil yakıyordu. Bekleme ÜSTEL büyür
  /// (1-2-4-… dk, tavan 6 saat): bozuk dosya/kural reddi gibi hiç
  /// düzelmeyecek bir hata sabit 1 dk'da bir Storage'a tam yükleme denemesi
  /// yapıyordu. Bağlantı gelince connectivity tetiği yine dener; kalıcı "pes
  /// et" YOK — geçici hatayı kalıcıdan istemcide ayırt edemeyiz, 6 saatlik
  /// tavan zaten zararsız.
  final Map<String, ({DateTime at, int attempts})> _lastFailure = {};
  static const _baseRetryDelay = Duration(minutes: 1);
  static const _maxRetryDelay = Duration(hours: 6);

  Duration _retryDelayFor(int attempts) {
    final scaled = _baseRetryDelay * (1 << (attempts - 1).clamp(0, 12));
    return scaled > _maxRetryDelay ? _maxRetryDelay : scaled;
  }
  ProviderSubscription<AsyncValue<List<Note>>>? _notesSub;
  ProviderSubscription<int>? _limitSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  void start() {
    _notesSub = _ref.listen(notesStreamProvider, (previous, next) {
      final notes = next.value;
      if (notes != null) _process(notes);
    }, fireImmediately: true);

    // Sınır yükseltilince bekleyen büyük ekler hemen sıraya girsin (yoksa bir
    // sonraki not değişikliğine kadar cihazda beklerlerdi).
    _limitSub = _ref.listen(syncLimitMbProvider, (previous, next) {
      final notes = _ref.read(notesStreamProvider).value;
      if (notes != null) _process(notes);
    });

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

    // Kullanıcının senkron boyut sınırı (MB, 0 = sınırsız): sınırı aşan ek
    // cihazda kalır, buluta hiç yüklenmez. Ayar değişince bir sonraki not
    // akışı/bağlantı tetiğinde yeniden değerlendirilir.
    final limitMb = _ref.read(syncLimitMbProvider);
    final limitBytes = limitMb <= 0 ? null : limitMb * 1024 * 1024;

    // Silinen notların artıkları birikmesin: harita yalnız hâlâ var olan
    // ekler için kayıt tutar.
    final liveKeys = <String>{
      for (final note in notes)
        for (final attachment in note.attachments) '${note.id}/${attachment.id}',
    };
    _lastFailure.removeWhere((key, _) => !liveKeys.contains(key));

    for (final note in notes) {
      for (final attachment in note.attachments) {
        // Görüntülü not buluta hiç gitmez (yalnızca cihazda saklanır).
        if (attachment.kind == AttachmentKind.video) continue;
        if (attachment.isUploaded || attachment.localPath.isEmpty) continue;
        if (limitBytes != null && attachment.sizeBytes > limitBytes) continue;
        final key = '${note.id}/${attachment.id}';
        final lastFailure = _lastFailure[key];
        if (lastFailure != null &&
            DateTime.now().difference(lastFailure.at) <
                _retryDelayFor(lastFailure.attempts)) {
          continue;
        }
        if (!_inFlight.add(key)) continue;
        try {
          final uploaded = await attachmentRepo.upload(note.id, attachment);
          if (uploaded != null) {
            await notesRepo.patchAttachment(note.id, uploaded);
          }
          _lastFailure.remove(key);
        } catch (e) {
          // Bağlantı yoksa veya yükleme başarısızsa bir sonraki tetikte
          // (üstel bekleme dolduysa) yeniden denenir.
          _lastFailure[key] = (
            at: DateTime.now(),
            attempts: (lastFailure?.attempts ?? 0) + 1,
          );
          debugPrint('Ek yüklenemedi ($key): $e');
        } finally {
          _inFlight.remove(key);
        }
      }
    }
  }

  void dispose() {
    _notesSub?.close();
    _limitSub?.close();
    _connectivitySub?.cancel();
  }
}
