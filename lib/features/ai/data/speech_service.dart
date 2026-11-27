import 'dart:async';
import 'dart:io' show Directory;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/speech_output.dart';

/// **TEK SESLENDİRME KAPISI** (F3.9): uygulamadaki her "sesli oku" bunu
/// çağırır. Motor cihazın yerleşik TTS'idir (Android'de Google sesleri;
/// Türkçe, İngilizce, Arapça, Endonezce ve Malayca'nın hepsi var).
///
/// ANTALIA KALKTI (kullanıcı kararı 2026-11-27: "Antalya modelini
/// beğenmiyorum, kaldıralım; Android sesleri iyi zaten"). Yalnız Türkçe
/// okuyordu, ~50 MB model indirtiyordu ve ONNX kitaplığı APK'yı ~28 MB
/// büyütüyordu. Kokoro gibi açık modeller değerlendirildi: hedef beş dilden
/// yalnız İngilizceyi okuyor — eklenmedi.
final speechProvider = NotifierProvider<SpeechService, SpeechOutputState>(
  SpeechService.new,
);

class SpeechService extends Notifier<SpeechOutputState> {
  @override
  SpeechOutputState build() {
    ref.listen(speechOutputProvider, (_, next) => state = next);
    return const SpeechOutputState();
  }

  SpeechOutputController get _device => ref.read(speechOutputProvider.notifier);

  /// [text]'i okur; zaten okuyorsa önce durdurur.
  Future<void> speak(String text, {String? languageCode}) async {
    await stop();
    await _device.speak(text, languageCode: languageCode);
  }

  Future<void> pause() => _device.pause();

  Future<void> resume() => _device.resume();

  /// Ayarlardaki DENEME okuması: önce susturur, sonra [sample]'ı okur.
  Future<void> preview(String sample, {String? languageCode}) async {
    await stop();
    await _device.speak(sample, languageCode: languageCode);
  }

  /// Okumayı durdurur.
  Future<void> stop() async {
    await _device.stop();
    state = const SpeechOutputState();
  }
}

/// Eski sürümün indirdiği Antalia modelini (~50 MB) siler. Açılışta bir kez,
/// arka planda; klasör yoksa hiçbir şey yapmaz.
Future<void> removeLegacyVoiceModel() async {
  if (kIsWeb) return;
  try {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/antalia_mini');
    if (await dir.exists()) await dir.delete(recursive: true);
  } catch (e) {
    debugPrint('Eski ses modeli silinemedi: $e');
  }
}
