import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'antalia_audio.dart';
import 'antalia_text.dart';

/// **Antalia-2 Mini**: cihazda çalışan Türkçe seslendirme modeli
/// (`cloud0day3/antalia-mini`, PatientDesk AI, Apache-2.0 — 7,62M parametre,
/// 48 kHz, tek sentetik erkek sesi; gerçek bir kişinin sesi değildir).
///
/// Model uygulamaya GÖMÜLMEZ: ilk kullanımda ~50 MB (üç ONNX + dört yabancı
/// kelime sözlüğü) `fr0stb1rd/antalia-mini-web-onnx` deposundan indirilir —
/// PyTorch ağırlıklarının tarayıcı için ONNX'e çevrilmiş hâli; aynı dosyalar
/// o projenin canlı sitesinde de kullanılıyor. APK'yı her kullanıcı için
/// 50 MB şişirmek yerine yalnız isteyen indirir; sonrası tamamen çevrimdışı.
///
/// Hat (app.js `synthPieces` ile aynı): metin → [AntaliaText] → `text_stage`
/// (harf gizli durumu + süre) → kare yayma ([AntaliaDsp]) → `sound_stage`
/// (8 adım DiT akış eşleme → mel) → `decoder` (Vocos + iSTFT → 48 kHz) →
/// kırpma + ton.
///
/// YALNIZ Android: eklentinin web tarafı int64 tensör almıyor (kimlikler
/// int64). Web'de motor kullanılamaz görünür ve okuma cihaz sesine düşer.
class AntaliaModelFiles {
  AntaliaModelFiles._();

  static const repo = 'fr0stb1rd/antalia-mini-web-onnx';
  static const baseUrl = 'https://huggingface.co/$repo/resolve/main';
  static const models = ['text_stage.onnx', 'sound_stage.onnx', 'decoder.onnx'];
  static const dicts = [
    'foreign_dict.json',
    'foreign_parts.json',
    'known_words.json',
    'english_i.json',
  ];
  static const all = [...models, ...dicts];

  /// Bütün dosyalar inince yazılan işaret: yarım kalan indirme "kurulu"
  /// sanılmasın.
  static const _marker = '.complete';

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<Directory> dir() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/antalia_mini');
  }

  static Future<bool> installed() async {
    if (!supported) return false;
    final d = await dir();
    if (!File('${d.path}/$_marker').existsSync()) return false;
    return all.every((f) {
      final file = File('${d.path}/$f');
      return file.existsSync() && file.lengthSync() > 0;
    });
  }

  /// Dosyaları indirir. [onProgress] (inen, toplam bayt) ile çağrılır;
  /// toplam bilinmiyorsa 0. Her dosya önce `.part`a yazılır, boyutu
  /// doğrulanınca yerine taşınır — kesilen indirme bozuk model bırakmaz.
  static Future<void> download({
    required void Function(int received, int total) onProgress,
    bool Function()? cancelled,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final d = await dir();
      await d.create(recursive: true);
      final marker = File('${d.path}/$_marker');
      if (marker.existsSync()) marker.deleteSync();

      // Toplam boyut önceden: ilerleme çubuğu dosya sayısıyla değil baytla
      // ilerlesin (sözlükler KB, modeller onlarca MB).
      var total = 0;
      for (final f in all) {
        final head = await c.head(Uri.parse('$baseUrl/$f'));
        final len = int.tryParse(head.headers['content-length'] ?? '');
        if (head.statusCode != 200 || len == null) {
          total = 0;
          break;
        }
        total += len;
      }

      var received = 0;
      for (final f in all) {
        if (cancelled?.call() ?? false) throw const AntaliaCancelled();
        final response = await c.send(
          http.Request('GET', Uri.parse('$baseUrl/$f')),
        );
        if (response.statusCode != 200) {
          throw HttpException('$f: HTTP ${response.statusCode}');
        }
        final part = File('${d.path}/$f.part');
        final sink = part.openWrite();
        var got = 0;
        try {
          await for (final chunk in response.stream) {
            if (cancelled?.call() ?? false) throw const AntaliaCancelled();
            sink.add(chunk);
            got += chunk.length;
            onProgress(received + got, total);
          }
        } finally {
          await sink.close();
        }
        final expected = response.contentLength;
        if (got == 0 || (expected != null && expected != got)) {
          part.deleteSync();
          throw HttpException('$f: eksik indirildi ($got/$expected)');
        }
        await part.rename('${d.path}/$f');
        received += got;
      }
      await marker.writeAsString('1');
    } finally {
      if (client == null) c.close();
    }
  }

  static Future<void> delete() async {
    final d = await dir();
    if (d.existsSync()) await d.delete(recursive: true);
  }
}

/// Ayarlar → Lisanslar sayfasına Antalia'nın Apache-2.0 bildirimi (NOTICE)
/// eklenir: metin normalleştiricisi ve ses son-işlemesi o kodun portu,
/// model ağırlıkları da aynı lisansla indiriliyor.
void registerAntaliaLicense() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Antalia-2 Mini', 'antalia-mini-web'],
      'Antalia-2 Mini — Copyright 2026 PatientDesk AI\n'
      'Model weights, text normaliser and audio post-processing are licensed '
      'under the Apache License, Version 2.0 '
      '(https://www.apache.org/licenses/LICENSE-2.0). The Dart port of the '
      'normaliser and the ONNX pipeline follow fr0stb1rd/antalia-mini-web '
      '(Apache-2.0).\n\n'
      'The normaliser dictionaries derive from the CMU Pronouncing Dictionary '
      '(Copyright Carnegie Mellon University, BSD 2-Clause). The model was '
      'trained on synthetic speech generated with VoxCPM2 (OpenBMB, '
      'Apache-2.0). The voice is synthetic and is not the voice of a real '
      'person; audio made with it must not be used to impersonate anyone.',
    );
  });
}

class AntaliaCancelled implements Exception {
  const AntaliaCancelled();
}

/// Yüklü ONNX oturumları ve sentez. Oturumlar ilk okumada açılır;
/// [release] ile kapatılır (okuma bitince bir süre sonra — ~50 MB RAM).
class AntaliaEngine {
  OrtSession? _text, _sound, _decoder;
  Future<void>? _loading;

  bool get loaded => _decoder != null;

  Future<void> load() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    if (loaded) return;
    final d = await AntaliaModelFiles.dir();
    // Sözlükler (~2,6 MB JSON) ayrı isolate'te çözülür: ana iş parçacığında
    // çözmek arayüzü bir an dondururdu.
    final data = await compute(_readDicts, d.path);
    AntaliaText.setData(
      foreign: data.$1,
      parts: data.$2,
      known: data.$3,
      englishI: data.$4,
    );
    final ort = OnnxRuntime();
    final options = OrtSessionOptions(intraOpNumThreads: 4);
    final sessions = <OrtSession>[];
    try {
      for (final f in AntaliaModelFiles.models) {
        sessions.add(await ort.createSession('${d.path}/$f', options: options));
      }
    } catch (_) {
      for (final s in sessions) {
        await s.close();
      }
      rethrow;
    }
    _text = sessions[0];
    _sound = sessions[1];
    _decoder = sessions[2];
  }

  static (Map<String, String>, Map<String, String>, List<String>, List<String>)
  _readDicts(String dir) {
    Object? read(String name) =>
        jsonDecode(File('$dir/$name').readAsStringSync());
    return (
      (read('foreign_dict.json')! as Map).cast<String, String>(),
      (read('foreign_parts.json')! as Map).cast<String, String>(),
      (read('known_words.json')! as List).cast<String>(),
      (read('english_i.json')! as List).cast<String>(),
    );
  }

  Future<void> release() async {
    final sessions = [_text, _sound, _decoder];
    _text = _sound = _decoder = null;
    for (final s in sessions) {
      await s?.close();
    }
  }

  /// Ham metin parçasını seslendirir: tonlu, 48 kHz örnekler.
  ///
  /// Metin önce normalleştirilir, sonra modelin kaldırdığı boylara bölünür
  /// (ilk parça kısa — ilk ses çabuk gelsin). Parçalar arasına cümle/virgül
  /// sessizliği konur; [last] değilse SONA da konur (sıradaki parça
  /// ardından çalınacak). [tone] okuma boyunca aynı nesnedir: filtre durumu
  /// taşınır, parça sınırında tık olmaz. [seedBase] gürültü tohumunu
  /// parçaya göre ayırır.
  Future<Float32List> synthesize(
    String raw, {
    required AntaliaTone tone,
    required bool last,
    required int seedBase,
    bool Function()? cancelled,
    double speed = AntaliaDsp.defaultSpeed,
  }) async {
    await load();
    final clean = AntaliaText.toModelText(raw);
    final pieces = [
      for (final p in AntaliaText.splitModelText(clean))
        ...AntaliaText.capLength(p),
    ];
    final out = BytesBuilder(copy: false);
    for (var k = 0; k < pieces.length; k++) {
      if (cancelled?.call() ?? false) return Float32List(0);
      var wav = await _piece(
        pieces[k],
        seed: AntaliaDsp.pieceSeed(0, seedBase + k),
        speed: speed,
      );
      if (k < pieces.length - 1 || !last) {
        wav = AntaliaDsp.withPause(wav, AntaliaDsp.pauseSec(pieces[k]));
      }
      out.add(tone.process(wav).buffer.asUint8List());
    }
    final bytes = out.takeBytes();
    return bytes.buffer.asFloat32List(
      bytes.offsetInBytes,
      bytes.lengthInBytes ~/ 4,
    );
  }

  Future<Float32List> _piece(
    String part, {
    required int seed,
    required double speed,
  }) async {
    final text = _text, sound = _sound, decoder = _decoder;
    if (text == null || sound == null || decoder == null) {
      throw StateError('Antalia modeli yüklü değil');
    }
    final enc = AntaliaDsp.encodePiece(part);
    final length = enc.ids.length;
    final values = <OrtValue>[];
    Future<OrtValue> val(Object data, List<int> shape) async {
      final v = await OrtValue.fromList(data, shape);
      values.add(v);
      return v;
    }

    try {
      // 1. Metin aşaması: harf gizli durumu [1, L, d] + log süre [1, L].
      final tOut = await text.run({
        'ids': await val(Int64List.fromList(enc.ids), [1, length]),
        'mask': await val(List<bool>.filled(length, true), [1, length]),
      });
      values.addAll(tOut.values);
      final hValue = tOut['h']!;
      final dText = hValue.shape[2];
      final h = await _floats(hValue);
      final logd = await _floats(tOut['logd']!);

      AntaliaDsp.stretchGeminates(enc.ids, logd);
      final dur = AntaliaDsp.durations(logd, speed);
      final melLen = AntaliaDsp.melLength(dur);
      final cond = AntaliaDsp.expand(h, dur, dText, melLen);
      final noise = AntaliaDsp.noise(
        melLen ~/ AntaliaDsp.stack * AntaliaDsp.noiseDim,
        seed,
      );

      // 2. Ses aşaması: 8 adım akış eşleme → mel [1, 128, T].
      final sOut = await sound.run({
        'cond': await val(cond, [1, melLen, dText]),
        'fmask': await val(List<bool>.filled(melLen, true), [1, melLen]),
        'noise': await val(noise, [
          1,
          melLen ~/ AntaliaDsp.stack,
          AntaliaDsp.noiseDim,
        ]),
      });
      values.addAll(sOut.values);

      // 3. Ses çözücü: mel → 48 kHz dalga. Mel çıkışı doğrudan girdi olur
      // (Dart'a indirip geri göndermeye gerek yok).
      final dOut = await decoder.run({'mel': sOut['mel']!});
      values.addAll(dOut.values);
      final wav = await _floats(dOut['audio']!);

      return AntaliaDsp.trim(
        wav,
        dur,
        preTokens: enc.preTokens,
        sufTokens: enc.sufTokens,
        hasPrefix: enc.hasPrefix,
      );
    } finally {
      for (final v in values) {
        unawaited(v.dispose().catchError((Object _) {}));
      }
    }
  }

  static Future<Float32List> _floats(OrtValue value) async {
    final list = await value.asFlattenedList();
    if (list is Float32List) return Float32List.fromList(list);
    return Float32List.fromList([for (final x in list) (x as num).toDouble()]);
  }
}

final antaliaEngineProvider = Provider<AntaliaEngine>((ref) {
  final engine = AntaliaEngine();
  ref.onDispose(() => unawaited(engine.release()));
  return engine;
});

/// Model kurulum durumu (Ayarlar → Ses'teki indirme satırı okur).
enum AntaliaInstall { unsupported, checking, missing, downloading, ready }

@immutable
class AntaliaModelState {
  const AntaliaModelState(
    this.status, {
    this.received = 0,
    this.total = 0,
    this.error,
  });

  final AntaliaInstall status;
  final int received;
  final int total;

  /// Son indirme hatası (ağ, depolama); yeni denemede temizlenir.
  final String? error;

  double? get progress => total > 0 ? (received / total).clamp(0.0, 1.0) : null;
  bool get ready => status == AntaliaInstall.ready;
}

final antaliaModelProvider =
    NotifierProvider<AntaliaModelController, AntaliaModelState>(
      AntaliaModelController.new,
    );

class AntaliaModelController extends Notifier<AntaliaModelState> {
  bool _cancel = false;
  Future<void>? _checking;

  @override
  AntaliaModelState build() {
    if (!AntaliaModelFiles.supported) {
      return const AntaliaModelState(AntaliaInstall.unsupported);
    }
    _checking = _check();
    return const AntaliaModelState(AntaliaInstall.checking);
  }

  /// Açılıştaki dosya denetiminin bitmesi. Okuma bunu bekler: yoksa
  /// uygulama açıldıktan hemen sonraki ilk "dinle" model kuruluyken
  /// "kurulu değil" görüp cihaz sesiyle okurdu.
  Future<void> get checked => _checking ?? Future.value();

  Future<void> _check() async {
    final ok = await AntaliaModelFiles.installed();
    if (state.status == AntaliaInstall.checking) {
      state = AntaliaModelState(
        ok ? AntaliaInstall.ready : AntaliaInstall.missing,
      );
    }
  }

  Future<void> download() async {
    if (state.status != AntaliaInstall.missing) return;
    _cancel = false;
    state = const AntaliaModelState(AntaliaInstall.downloading);
    try {
      await AntaliaModelFiles.download(
        cancelled: () => _cancel,
        onProgress: (received, total) {
          state = AntaliaModelState(
            AntaliaInstall.downloading,
            received: received,
            total: total,
          );
        },
      );
      state = const AntaliaModelState(AntaliaInstall.ready);
    } on AntaliaCancelled {
      state = const AntaliaModelState(AntaliaInstall.missing);
    } catch (e) {
      state = AntaliaModelState(AntaliaInstall.missing, error: '$e');
    }
  }

  void cancel() => _cancel = true;

  Future<void> delete() async {
    await ref.read(antaliaEngineProvider).release();
    await AntaliaModelFiles.delete();
    state = const AntaliaModelState(AntaliaInstall.missing);
  }
}
