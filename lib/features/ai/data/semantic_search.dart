import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show ValueNotifier, kIsWeb, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/local_file.dart' show appSupportPath;
import '../../../core/utils/search_fold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/presentation/notes_providers.dart';
import '../../notes/domain/note_links.dart';
import 'assistant_service.dart' show keywordRelevant;
import 'attachment_text_index.dart';
import 'gemini_service.dart';
import 'model_catalog.dart' show ModelCooldown;

/// Hesaba bağlı (F5.5): vektör önbelleği notların içeriğinden türer; hesap
/// değişince öbür hesabınki bellekte kalmasın.
final semanticIndexProvider = Provider<SemanticIndex>((ref) {
  final index = SemanticIndex(ref, uid: ref.watch(currentUidProvider));
  ref.onDispose(index.dispose);
  return index;
});

/// Arka planda vektör eklendikçe arama sağlayıcısı kendini yeniler (eksik
/// notlar gömüldükçe sonuç zenginleşir).
void _refreshOnIndexGrowth(Ref ref, SemanticIndex index) {
  void refresh() => ref.invalidateSelf();
  index.revision.addListener(refresh);
  ref.onDispose(() {
    try {
      index.revision.removeListener(refresh);
    } catch (_) {
      // İndeks önce atıldı (hesap değişti).
    }
  });
}

/// Sorguyla anlamca en alakalı notlar (skor eşiği uygulanmış, sıralı).
final semanticSearchProvider = FutureProvider.autoDispose
    .family<List<Note>, String>((ref, query) async {
      final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
      // Gizli klasördeki notlar anlamsal aramaya da girmez (düz metin
      // aramasıyla aynı kural — bkz. filteredNotesProvider).
      final hiddenFolders = ref.watch(hiddenFoldersRevealedProvider)
          ? const <String>{}
          : ref.watch(hiddenFolderIdsProvider);
      // Kilitli notların içeriği embedding'e ve sonuçlara girmez.
      final active = [
        for (final n in notes)
          if (n.archivedAt == null &&
              !n.locked &&
              !hiddenFolders.contains(n.folderId))
            n,
      ];
      if (active.isEmpty || query.trim().isEmpty) return const [];
      // ÇÖP DE CANLI (T14, 2026-11-17): çöpteki notun vektörü ana aramada
      // silinirse çöpte anlamca arama onu yeniden gömüyordu; iki arama da
      // açıkken `revision` üzerinden birbirini tetikleyen döngü. Çöp listesi
      // henüz yoksa kalıcı silinenle çöptekini ayıramayız → bu tur budama yok.
      final trash = ref.watch(trashStreamProvider).value;
      final index = ref.read(semanticIndexProvider);
      _refreshOnIndexGrowth(ref, index);
      try {
        // Kilitli notun vektörü de bırakılır (diskte içerikten türev kalmasın).
        if (trash != null) {
          index.pruneTo({
            for (final n in [...notes, ...trash])
              if (!n.locked) n.id,
          });
        }
        return await index.search(query.trim(), active);
      } on GeminiException {
        // Embedding dahili (anahtarsız) modda desteklenmiyor; arama hata ekranına
        // düşmesin, düz metin aramasıyla devam edilsin.
        final q = foldForSearch(query.trim());
        return [
          for (final n in active)
            if (foldForSearch(n.toPlainText()).contains(q)) n,
        ];
      }
    });

/// **İlgili notlar** (F18.17): [noteId]ye anlamca yakın notlar. Anlamsal
/// indeks (kendi anahtarıyla; vektör önbellekteyse yeni çağrı yok) olmazsa
/// AI'sız kelime örtüşmesi. Kilitli, gizli klasördeki, arşivdeki ve zaten
/// bağlı notlar öneriye girmez; hedef kilitliyse öneri yok.
final relatedNotesProvider = FutureProvider.autoDispose
    .family<List<Note>, String>((ref, noteId) async {
      final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
      final target = notes.where((n) => n.id == noteId).firstOrNull;
      if (target == null || target.locked) return const [];
      final hidden = ref.watch(hiddenFoldersRevealedProvider)
          ? const <String>{}
          : ref.watch(hiddenFolderIdsProvider);
      final linked = outgoingNoteLinks(target).toSet();
      final candidates = [
        for (final n in notes)
          if (n.id != noteId &&
              !n.locked &&
              n.archivedAt == null &&
              n.deletedAt == null &&
              !hidden.contains(n.folderId) &&
              !linked.contains(n.id))
            n,
      ];
      if (candidates.isEmpty) return const [];
      try {
        final found = await ref
            .read(semanticIndexProvider)
            .related(target, candidates);
        if (found.isNotEmpty) return found;
      } catch (_) {
        // Gömme yok (dahili mod) ya da ağ: yerel yedek.
      }
      final text = '${target.title} ${target.toPlainText()}';
      return keywordRelevant(
        text.length > 400 ? text.substring(0, 400) : text,
        candidates,
        limit: 5,
      );
    });

/// Ana ekran DIŞINDAKİ arama yüzeyleri (arşiv, çöp, klasör) için anlamsal
/// aramanın aday kümesi (geliştirme raporu B4, 2026-10-20: AI anahtarı
/// arşivden çöpe ve klasöre de geldi).
enum SemanticScope { archive, trash, folder }

/// Kapsamlı anlamsal arama: [semanticSearchProvider] ile aynı indeks ve aynı
/// eşik; yalnız aday kümesi kapsamın notları. [folderId] yalnız
/// [SemanticScope.folder]da. Kilitli ve gizli klasördeki notlar girmez.
final scopedSemanticSearchProvider = FutureProvider.autoDispose
    .family<
      List<Note>,
      ({SemanticScope scope, String? folderId, String query})
    >((ref, key) async {
      final query = key.query.trim();
      final hiddenFolders = ref.watch(hiddenFoldersRevealedProvider)
          ? const <String>{}
          : ref.watch(hiddenFolderIdsProvider);
      final source = switch (key.scope) {
        SemanticScope.trash =>
          ref.watch(trashStreamProvider).value ?? const <Note>[],
        _ => ref.watch(notesStreamProvider).value ?? const <Note>[],
      };
      final candidates = [
        for (final n in source)
          if (!n.locked &&
              !hiddenFolders.contains(n.folderId) &&
              switch (key.scope) {
                SemanticScope.archive => n.archivedAt != null,
                SemanticScope.trash => n.deletedAt != null,
                SemanticScope.folder =>
                  n.folderId == key.folderId && n.archivedAt == null,
              })
            n,
      ];
      if (candidates.isEmpty || query.isEmpty) return const [];
      final index = ref.read(semanticIndexProvider);
      _refreshOnIndexGrowth(ref, index);
      try {
        return await index.search(query, candidates);
      } on GeminiException {
        final q = foldForSearch(query);
        return [
          for (final n in candidates)
            if (foldForSearch(n.toPlainText()).contains(q)) n,
        ];
      }
    });

/// Embedding indeksi: her notun vektörü içeriği değiştikçe yenilenir, arama
/// kosinüs benzerliğiyle yapılır.
///
/// **Kalıcı önbellek (2026-11-15, dal oto/arama-onbellek):** vektörler
/// eskiden yalnız bellekteydi; her açılışta ilk arama TÜM defteri yeniden
/// gömüyordu (450 not ≈ 170K belirteç > 30K TPM → 429, günlük 1K istek her
/// açılışta). Artık hesaba özgü ikili dosyada
/// (`<appSupport>/semantic_vectors_<uid>.bin`, uygulamanın özel dizini):
/// anahtar `notKimliği|model|boyut`, değer (gömülen metnin md5'i, Float32
/// vektör). İlk aramada TEMBEL yüklenir (açılışa yük yok). Yalnız metni
/// değişen/yeni not gömülür; silinen ve kilitlenen notun kaydı silinir;
/// Embedding 2 göçü bitince başka model/boyuttaki kayıtlar silinir. Web'de
/// dosya yok → yalnız bellek (sessiz). Çıkışta [deleteStore].
///
/// **Kota (100 RPM / 30K TPM / 1K RPD):** eksikler dakikalık pencerede
/// payın %80'ine sığan parçalarla gömülür ([_Pacer]); kalan pay sorgulara.
/// Eksikler tek parçaya sığıyorsa arama bekler (küçük defterde eski
/// davranış); sığmıyorsa önbellektekilerle HEMEN sonuç döner, parçalar arka
/// planda gömülür ve her parçada [revision] artar (arama sağlayıcıları
/// kendini yeniler).
///
/// **Model (K-S2):** Embedding 2 öncelikli. Ortak [ModelCooldown]
/// (GeminiService.cooldown) okunur: RPM 429'unda (1 dk soğuma) aynı modelle
/// beklenip sürülür — tek 429 artık oturumu 001'e kilitlemez; RPD dolunca
/// ya da 404/400-403/boş yanıtta Pasifik gece yarısına dek 001. Skor yalnız
/// AYNI modelin sorgu vektörüyle (iki modelin vektörleri karşılaştırılamaz).
///
/// Vektörler NORMALİZE saklanır: kosinüs benzerliği düz iç çarpıma iner;
/// sorgu vektörü sorgu metnine göre bellekte önbelleklenir.
class SemanticIndex {
  SemanticIndex(this._ref, {String? uid}) : _uid = uid {
    if (uid != null) _wiped.remove(uid);
  }

  final Ref _ref;
  final String? _uid;

  /// Testler gerçek uygulama klasörüne yazmasın diye.
  @visibleForTesting
  static String? overrideDir;

  /// Çıkışta silinen hesaplar: arka planda süren bir parça dosyayı geri
  /// yazmasın.
  static final _wiped = <String>{};

  static File? _fileFor(String uid) {
    final base = overrideDir ?? appSupportPath;
    if (kIsWeb || base == null) return null;
    return File('$base/semantic_vectors_$uid.bin');
  }

  /// Oturum kapatılınca / hesap silinince [uid]in vektör dosyası silinir.
  static Future<void> deleteStore(String? uid) async {
    if (uid == null) return;
    _wiped.add(uid);
    final file = _fileFor(uid);
    try {
      if (file != null && await file.exists()) await file.delete();
    } catch (_) {
      // Silinemedi: dosya özel dizinde, sonraki çıkışta yeniden denenir.
    }
  }

  /// `id|model|boyut` → (metin özeti, normalize vektör)
  final _vectors = <String, (String, Float32List)>{};

  /// noteId → (updatedAt, ek metni boyu, metin özeti): değişmeyen notun
  /// düz metni her aramada yeniden çıkarılıp özetlenmesin.
  final _digests = <String, (DateTime?, int, String)>{};

  /// Arka plan parçası bitip vektör eklendikçe artar.
  final revision = ValueNotifier<int>(0);

  bool _disposed = false;
  bool _dirty = false;

  /// Süren dolumu bekleyen arama yok: her parçada [revision] artar.
  bool _background = false;

  /// Dolumu bekleyen arama(lar); dolum kotada beklemeye geçince bırakılır.
  Completer<void>? _handoff;

  void _releaseWaiters() {
    _handoff?.complete();
    _handoff = null;
  }

  Future<void>? _loading;
  Future<void>? _filling;
  List<Note> _wanted = const [];
  final _pacer = _Pacer();

  static String _key(String id, String model) =>
      '$id|$model|${GeminiService.embedDim}';

  ModelCooldown get _cooldown => _ref.read(geminiServiceProvider).cooldown;

  /// Etkin gömme modeli: Embedding 2 uzun süre (RPD/404) soğumadaysa 001.
  String get _model =>
      _cooldown.remaining(GeminiService.embedModelV2) > _shortWait
      ? GeminiService.embedModelV1
      : GeminiService.embedModelV2;

  /// Bundan kısa soğuma (RPM) beklenir, uzunu model değiştirir.
  static const _shortWait = Duration(minutes: 2);

  @visibleForTesting
  String get activeModel => _model;

  void dispose() {
    _disposed = true;
    revision.dispose();
  }

  /// sorgu metni → normalize vektör (küçük, eklenme sıralı; taşınca en eski
  /// atılır — LinkedHashMap sırası eklenme sırasıdır).
  final _queryCache = <String, Float32List>{};
  static const _maxQueryCache = 32;

  /// Silinen notların vektörlerini bırakır (F7.5). Arşivli/gizli notlar
  /// canlı sayılır: yeniden gösterilince baştan vektörlenmesin.
  void pruneTo(Set<String> liveIds) {
    final before = _vectors.length;
    _vectors.removeWhere((k, _) => !liveIds.contains(k.split('|').first));
    _digests.removeWhere((id, _) => !liveIds.contains(id));
    if (_vectors.length != before) _dirty = true;
  }

  @visibleForTesting
  int get cachedVectorCount => _vectors.length;

  @visibleForTesting
  void debugPut(String id) =>
      _vectors[_key(id, GeminiService.embedModelV2)] = ('', Float32List(0));

  @visibleForTesting
  String? modelOf(String id) {
    for (final m in [_model, GeminiService.embedModelV2]) {
      if (_vectors.containsKey(_key(id, m))) return m;
    }
    return null;
  }

  /// Arka plan dolumu (testler bekleyebilsin).
  @visibleForTesting
  Future<void> get idle => _filling ?? Future.value();

  /// [target]a anlamca en yakın notlar (F18.17 "İlgili notlar"). Vektörler
  /// önbellekteyse yeni çağrı YOK; eksik/bayat olanlar üretilir.
  Future<List<Note>> related(
    Note target,
    List<Note> candidates, {
    int limit = 5,
    double threshold = 0.55,
  }) async {
    final others = [
      for (final n in candidates)
        if (n.id != target.id) n,
    ];
    await _prepare([target, ...others]);
    final model = _model;
    final t = _vectors[_key(target.id, model)];
    if (t == null || t.$2.isEmpty) return const [];
    final scored = <(Note, double)>[];
    for (final n in others) {
      final e = _vectors[_key(n.id, model)];
      if (e == null) continue;
      scored.add((n, _dot(t.$2, e.$2)));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [
      for (final (note, score) in scored.take(limit))
        if (score > threshold) note,
    ];
  }

  Future<List<Note>> search(String query, List<Note> notes) async {
    await _prepare(notes);
    final (model, queryVector) = await _queryVector(query, notes);

    final scored = <(Note, double)>[];
    for (final note in notes) {
      // Başka modelin vektörü bu sorgu vektörüyle karşılaştırılamaz.
      final entry = _vectors[_key(note.id, model)];
      if (entry == null) continue;
      scored.add((note, _dot(queryVector, entry.$2)));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [
      for (final (note, score) in scored.take(30))
        if (score > 0.35) note,
    ];
  }

  /// Önbelleği (ilk çağrıda) yükler, eksikleri gömmeye başlar; eksikler bu
  /// dakikanın payına tek parçada sığıyorsa biter, yoksa arka planda sürer.
  Future<void> _prepare(List<Note> notes) async {
    await (_loading ??= _load());
    _wanted = notes;
    final missing = _missing(notes, _model);
    if (missing.isEmpty) {
      if (_dirty) await _save();
      return;
    }
    final fits =
        _chunk(missing).length == missing.length &&
        _pacer.wait(_tokens(missing), missing.length) == Duration.zero;
    final run = _filling ??= _fillLoop().whenComplete(() {
      _filling = null;
      _background = false;
      _releaseWaiters();
    });
    if (fits) {
      // Dolum RPM'e takılıp beklemeye geçerse arama da beklemez.
      await Future.any([run, (_handoff ??= Completer<void>()).future]);
    } else {
      _background = true;
    }
  }

  /// Sorgu vektörü (etkin modelle; modele göre önbellekli). Embedding 2
  /// uzun süre düşerse (RPD/404) notlar 001 ile hazırlanır, sorgu tekrarlanır.
  Future<(String, Float32List)> _queryVector(
    String query,
    List<Note> notes,
  ) async {
    final model = _model;
    final key = '$model|$query';
    final cached = _queryCache[key];
    if (cached != null) return (model, cached);
    final Float32List v;
    try {
      v = _normalized(
        (await _ref
                .read(geminiServiceProvider)
                .embedTexts([query], model: model, query: true))
            .first,
      );
    } on GeminiException catch (e) {
      if (!_switchedModel(model, e)) rethrow;
      await _prepare(notes);
      return _queryVector(query, notes);
    }
    if (_queryCache.length >= _maxQueryCache) {
      _queryCache.remove(_queryCache.keys.first);
    }
    _queryCache[key] = v;
    return (model, v);
  }

  /// Embedding 2 hatası bugün için 001'e geçirdi mi? Erişilemezlik
  /// (404/400-403/boş yanıt) günlük soğumaya yazılır; 429'u embedTexts
  /// zaten yazdı (PerDay → gün, değilse 1 dk). Bağlantı/anahtarsız hatalar
  /// geçirmez (001 de aynı sebeple başarısız olur).
  bool _switchedModel(String model, GeminiException e) {
    if (model != GeminiService.embedModelV2) return false;
    if (const {
      GeminiErrorKind.modelNotFound,
      GeminiErrorKind.invalidKey,
      GeminiErrorKind.unavailable,
    }.contains(e.kind)) {
      _cooldown.hit(model, 404);
    }
    return _model != model;
  }

  /// [model]de vektörü olmayan ya da metni değişmiş notlar (+ metin, özet).
  List<(Note, String, String)> _missing(List<Note> notes, String model) {
    final extra = _ref.read(attachmentTextProvider);
    final out = <(Note, String, String)>[];
    for (final note in notes) {
      final extraLen = extra[note.id]?.length ?? 0;
      final memo = _digests[note.id];
      final entry = _vectors[_key(note.id, model)];
      if (memo != null &&
          memo.$1 == note.updatedAt &&
          memo.$2 == extraLen &&
          entry != null &&
          entry.$1 == memo.$3) {
        continue;
      }
      final text = _textOf(note, extra[note.id]);
      final digest = md5.convert(utf8.encode(text)).toString();
      _digests[note.id] = (note.updatedAt, extraLen, digest);
      if (entry != null && entry.$1 == digest) continue;
      out.add((note, text, digest));
    }
    return out;
  }

  static String _textOf(Note note, String? extra) {
    // Ek içeriği (PDF metni + görsel OCR) seçenek açıkken vektöre de girer:
    // "faturadaki tutarı" arayan kullanıcı notun yazısında değil EKİNDE
    // olanı arıyor (bkz. attachment_text_index.dart).
    final text = [note.toPlainText(), ?extra].join('\n');
    return text.length > 1500 ? text.substring(0, 1500) : text;
  }

  /// Kaba belirteç tahmini (Türkçe ~3 karakter/belirteç, ihtiyatlı).
  static int _tokens(List<(Note, String, String)> items) {
    var sum = 0;
    for (final i in items) {
      sum += i.$2.length ~/ 3 + 8;
    }
    return sum;
  }

  /// Bir dakikalık paya sığan baş dilim.
  static List<(Note, String, String)> _chunk(
    List<(Note, String, String)> missing,
  ) {
    var tokens = 0;
    var n = 0;
    while (n < missing.length && n < _Pacer.maxRequests) {
      final t = _tokens([missing[n]]);
      if (n > 0 && tokens + t > _Pacer.maxTokens) break;
      tokens += t;
      n++;
    }
    return missing.sublist(0, n);
  }

  /// Eksikler bitene dek parça parça gömer. RPM 429'unda soğuma kadar bekler
  /// (en çok 3 kez üst üste), RPD'de model değişir, başka hatada durur
  /// (sonraki arama yeniden başlatır).
  Future<void> _fillLoop() async {
    var failures = 0;
    while (!_disposed) {
      final model = _model;
      final missing = _missing(_wanted, model);
      if (missing.isEmpty) {
        if (model == GeminiService.embedModelV2) _dropOtherModels();
        if (_dirty) await _save();
        return;
      }
      final chunk = _chunk(missing);
      final tokens = _tokens(chunk);
      final wait = _pacer.wait(tokens, chunk.length);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      if (_disposed) return;
      try {
        _pacer.add(tokens, chunk.length);
        final vectors = await _ref.read(geminiServiceProvider).embedTexts([
          for (final c in chunk) c.$2,
        ], model: model);
        if (_disposed) return;
        for (var j = 0; j < chunk.length && j < vectors.length; j++) {
          _vectors[_key(chunk[j].$1.id, model)] = (
            chunk[j].$3,
            _normalized(vectors[j]),
          );
        }
        _dirty = true;
        failures = 0;
        // Ara kayıt: uygulama kapanırsa gömülen parça boşa gitmesin.
        if (missing.length > chunk.length) await _save();
        // Arama beklemeden döndüyse sonuç yenilensin.
        if (_background && !_disposed) revision.value++;
      } on GeminiException catch (e) {
        if (_switchedModel(model, e)) continue;
        final left = _cooldown.remaining(model);
        if (e.kind != GeminiErrorKind.rateLimited ||
            left > _shortWait ||
            ++failures > 3) {
          if (_dirty) await _save();
          return;
        }
        _background = true;
        _releaseWaiters();
        await Future<void>.delayed(
          left > Duration.zero ? left : const Duration(seconds: 20),
        );
      }
    }
  }

  /// Embedding 2 göçü bitti: başka model/boyuttaki kayıtlar silinir.
  void _dropOtherModels() {
    final suffix = '|${GeminiService.embedModelV2}|${GeminiService.embedDim}';
    final before = _vectors.length;
    _vectors.removeWhere((k, _) => !k.endsWith(suffix));
    if (_vectors.length != before) _dirty = true;
  }

  // Dosya biçimi: 'SVC1' + adet(u32) + her kayıt: anahtar(u16 boy + utf8),
  // özet(u8 boy + ascii), vektör(u16 boy + float32 LE).
  static const _magic = 0x53564331;

  Future<void> _load() async {
    final uid = _uid;
    final file = uid == null ? null : _fileFor(uid);
    if (file == null) return;
    try {
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      final data = ByteData.sublistView(bytes);
      if (data.getUint32(0) != _magic) return;
      final count = data.getUint32(4);
      var o = 8;
      final loaded = <String, (String, Float32List)>{};
      for (var i = 0; i < count; i++) {
        final kl = data.getUint16(o);
        final key = utf8.decode(bytes.sublist(o + 2, o + 2 + kl));
        o += 2 + kl;
        final hl = bytes[o];
        final digest = ascii.decode(bytes.sublist(o + 1, o + 1 + hl));
        o += 1 + hl;
        final n = data.getUint16(o);
        o += 2;
        final v = Float32List(n);
        for (var j = 0; j < n; j++) {
          v[j] = data.getFloat32(o, Endian.little);
          o += 4;
        }
        loaded[key] = (digest, v);
      }
      if (_disposed) return;
      _vectors.addAll(loaded);
    } catch (_) {
      // Bozuk/yarım dosya aramayı kilitlemesin: sıfırdan gömülür.
    }
  }

  Future<void> _save() async {
    final uid = _uid;
    final file = uid == null ? null : _fileFor(uid);
    _dirty = false;
    if (file == null || _disposed || _wiped.contains(uid)) return;
    final b = BytesBuilder(copy: false);
    b.add(
      (ByteData(8)
            ..setUint32(0, _magic)
            ..setUint32(4, _vectors.length))
          .buffer
          .asUint8List(),
    );
    for (final e in _vectors.entries) {
      final k = utf8.encode(e.key);
      final h = ascii.encode(e.value.$1);
      final v = e.value.$2;
      final rec = ByteData(2 + k.length + 1 + h.length + 2 + v.length * 4);
      var o = 0;
      rec.setUint16(o, k.length);
      o += 2;
      for (final x in k) {
        rec.setUint8(o++, x);
      }
      rec.setUint8(o++, h.length);
      for (final x in h) {
        rec.setUint8(o++, x);
      }
      rec.setUint16(o, v.length);
      o += 2;
      for (final x in v) {
        rec.setFloat32(o, x, Endian.little);
        o += 4;
      }
      b.add(rec.buffer.asUint8List());
    }
    try {
      final tmp = File('${file.path}.tmp');
      await tmp.parent.create(recursive: true);
      await tmp.writeAsBytes(b.takeBytes(), flush: true);
      if (_wiped.contains(uid)) {
        await tmp.delete();
        return;
      }
      await tmp.rename(file.path);
    } catch (_) {
      _dirty = true; // Disk dolu vb.: sonraki turda yeniden denenir.
    }
  }

  /// Birim uzunluğa ölçekler; sıfır vektör olduğu gibi kalır (skoru 0 çıkar).
  static Float32List _normalized(List<double> v) {
    final out = Float32List.fromList([for (final x in v) x]);
    var norm = 0.0;
    for (final x in out) {
      norm += x * x;
    }
    if (norm == 0) return out;
    final inv = 1 / sqrt(norm);
    for (var i = 0; i < out.length; i++) {
      out[i] *= inv;
    }
    return out;
  }

  static double _dot(Float32List a, Float32List b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }
}

/// Dakikalık sabit pencere: gömme parçaları hesap kotasının (100 RPM /
/// 30K TPM) %80'ini aşmasın; kalan pay arama sorgularına.
class _Pacer {
  static const maxRequests = 80;
  static const maxTokens = 24000;

  DateTime _start = DateTime(0);
  int _tokens = 0;
  int _requests = 0;

  void _roll() {
    final now = DateTime.now();
    if (now.difference(_start) >= const Duration(minutes: 1)) {
      _start = now;
      _tokens = 0;
      _requests = 0;
    }
  }

  /// Bu parça pencereye sığmıyorsa pencerenin bitimine kalan süre.
  Duration wait(int tokens, int requests) {
    _roll();
    if (_tokens + tokens <= maxTokens && _requests + requests <= maxRequests) {
      return Duration.zero;
    }
    return const Duration(minutes: 1) - DateTime.now().difference(_start);
  }

  void add(int tokens, int requests) {
    _roll();
    _tokens += tokens;
    _requests += requests;
  }
}
