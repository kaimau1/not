// AI-S0 (PLAN §1.6): altın seti CANLI koşar ve puanlar.
//
// Kullanım (anahtar yalnız ortam değişkeninden; yoksa koşu atlanır):
//   GEMINI_API_KEY=... flutter test tool/ai_altin/altin_kos_test.dart
// Seçenekler (ortam değişkeni):
//   ALTIN_YETENEK=A7,A8   yalnız bu yetenekler
//   ALTIN_ONCEKI=build/ai_altin/<önceki>.json   yetenek başına önce/sonra farkı
// Sonuç: build/ai_altin/sonuc_<zaman>.json + konsolda yetenek tablosu.
//
// Dahili (Firebase AI Logic) yol kullanılmaz — koşu kullanıcının kendi
// anahtarıyla doğrudan Gemini'ye gider; model seçimi uygulamadaki zincirle
// aynıdır (`GeminiService` varsayılanları).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/ai/data/assistant_service.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'altin_puan.dart';

class _EnvKeyStore extends ApiKeyStore {
  const _EnvKeyStore(this.key);

  final String key;

  @override
  Future<String?> read(AiProvider provider) async =>
      provider == AiProvider.gemini ? key : null;
}

Note _note(Object? v, [String id = 'n1']) {
  if (v is String) return Note(id: id, type: NoteType.text, body: v);
  final m = (v as Map).cast<String, dynamic>();
  return Note(
    id: (m['id'] as String?) ?? id,
    type: NoteType.text,
    title: (m['baslik'] as String?) ?? '',
    body: (m['metin'] as String?) ?? '',
    tags: [...?(m['etiketler'] as List?)?.cast<String>()],
  );
}

/// Araç çağrılarını kaydeder, uygulama gibi "tamam" döner (hiçbir şey yazılmaz).
class _Araclar {
  final calls = <(String, Map<String, dynamic>)>[];

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> args,
  ) async {
    calls.add((name, args));
    return {'ok': true, 'id': 'altin-${calls.length}'};
  }
}

Future<AltinCikti> _kos(
  GeminiService ai,
  AssistantService assistant,
  AltinOrnek o,
) async {
  final g = o.girdi;
  final araclar = _Araclar();
  String s(String k) => g[k] as String;
  switch (o.islev) {
    case 'assistantChat':
      final notes = [
        for (final (i, n) in (g['notlar'] as List).indexed) _note(n, 'n$i'),
      ];
      final text = await ai.assistantChat(
        notesContext: assistant.buildNotesContext(notes, relevant: notes),
        history: [ChatTurn(isUser: true, text: s('soru'))],
        onToolCall: araclar.call,
      );
      return AltinCikti(text, araclar: araclar.calls);
    case 'chatAboutNote':
      return AltinCikti(
        await ai.chatAboutNote(
          note: _note(g['not']),
          attachments: const [],
          history: [ChatTurn(isUser: true, text: s('soru'))],
        ),
      );
    case 'askAboutNoteText':
      return AltinCikti(await ai.askAboutNoteText(_note(g['not']), s('soru')));
    case 'transcriptSummary':
      // Bugünkü akış: döküm nota girer, özet [summarizeNote] ile alınır.
      // AI-S3 tek akışı (özet + yapılacaklar + hatırlatıcı) gelince burası
      // o işleve bağlanır; set aynı kalır (önce/sonra).
      return AltinCikti(await ai.summarizeNote(_note(s('dokum'))));
    case 'assistantVoiceNote':
      final notes = [
        for (final (i, n) in ((g['notlar'] as List?) ?? const []).indexed)
          _note(n, 'n$i'),
      ];
      final text = await ai.assistantVoiceNote(
        notesContext: assistant.buildNotesContext(notes, relevant: notes),
        transcript: s('cumle'),
        onToolCall: araclar.call,
      );
      return AltinCikti(text, araclar: araclar.calls);
    case 'summarizeDocumentText':
      return AltinCikti(
        await ai.summarizeDocumentText(s('belge'), s('dosyaAdi')),
      );
    case 'askDocument':
      // PDF baytı yerine belge metni (A4 metin yolu); sayfa kaynakları AI-S6.
      return AltinCikti(
        await ai.askAboutNoteText(_note(s('belge')), s('soru')),
      );
    case 'structureOcr':
      // A5 hedefi: cihazda OCR, AI yalnız yapılandırır. Bugün bu adımın ayrı
      // işlevi yok — yeniden yazma yönergesiyle vekil (AI-S7'de değişir).
      return AltinCikti(
        await ai.rewriteText(
          s('ocr'),
          'OCR kırıklarını düzelt; kısa bir başlık ve madde madde yapılı not '
          'yap; bilgi ekleme',
        ),
      );
    case 'rewriteText':
      return AltinCikti(await ai.rewriteText(s('metin'), s('talimat')));
    case 'translateText':
      return AltinCikti(await ai.translateText(s('metin'), s('hedefDil')));
    case 'summarizeNote':
      return AltinCikti(await ai.summarizeNote(_note(g['not'])));
    case 'generateTitle':
      return AltinCikti(await ai.generateTitle(_note(g['not'])));
    case 'suggestTags':
      final tags = await ai.suggestTags(_note(g['not']));
      return AltinCikti(tags.join(', '), dizi: tags);
    case 'generateStudyCards':
      final cards = await ai.generateStudyCards(_note(g['not']));
      return AltinCikti(
        [for (final c in cards) 'S: ${c.q}\nC: ${c.a}'].join('\n\n'),
        dizi: [for (final c in cards) '${c.q} ${c.a}'],
      );
    case 'composeBriefing':
      return AltinCikti(await ai.composeBriefing(s('veri')));
  }
  throw StateError('bilinmeyen işlev: ${o.islev}');
}

void main() {
  final key = Platform.environment['GEMINI_API_KEY']?.trim() ?? '';
  test(
    'altın set canlı koşu',
    skip: key.isEmpty ? 'GEMINI_API_KEY yok — koşu atlandı' : false,
    timeout: const Timeout(Duration(minutes: 60)),
    () async {
      final only = (Platform.environment['ALTIN_YETENEK'] ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final assistant = container.read(assistantServiceProvider);
      final ai = GeminiService(_EnvKeyStore(key));
      final rapor = <String, dynamic>{
        'zaman': DateTime.now().toIso8601String(),
        'yetenekler': <String, dynamic>{},
      };
      for (final set in altinSetleriOku()) {
        if (only.isNotEmpty && !only.contains(set.yetenek)) continue;
        final ornekler = <Map<String, dynamic>>[];
        var toplam = 0.0;
        for (final o in set.ornekler) {
          AltinCikti? cikti;
          String? hata;
          try {
            cikti = await _kos(ai, assistant, o);
          } catch (e) {
            hata = '$e';
          }
          final sonuc = cikti == null
              ? const <AltinSonuc>[]
              : altinPuanla(o, cikti);
          final puan = altinOrnekPuani(sonuc);
          toplam += puan;
          ornekler.add({
            'id': o.id,
            'puan': puan,
            'hata': ?hata,
            'cikti': cikti?.metin,
            if (cikti != null && cikti.araclar.isNotEmpty)
              'araclar': [
                for (final (ad, args) in cikti.araclar)
                  {'ad': ad, 'args': args},
              ],
            'kalan': [
              for (final r in sonuc)
                if (!r.gecti) '${r.olcut} (${r.ayrinti})',
            ],
          });
        }
        final ort = set.ornekler.isEmpty ? 0 : toplam / set.ornekler.length;
        (rapor['yetenekler'] as Map)[set.yetenek] = {
          'ad': set.ad,
          'puan': ort,
          'ornekler': ornekler,
        };
        // ignore: avoid_print
        print(
          '${set.yetenek.padRight(5)} ${set.ad.padRight(28)} '
          '${(ort * 100).toStringAsFixed(1)}',
        );
      }
      final onceki = Platform.environment['ALTIN_ONCEKI'];
      if (onceki != null && File(onceki).existsSync()) {
        final eski =
            (jsonDecode(File(onceki).readAsStringSync()) as Map)['yetenekler']
                as Map;
        for (final MapEntry(:key, :value)
            in (rapor['yetenekler'] as Map).entries) {
          final once = (eski[key] as Map?)?['puan'] as num?;
          if (once == null) continue;
          final fark = ((value as Map)['puan'] as num) - once;
          // ignore: avoid_print
          print(
            '$key önce ${(once * 100).toStringAsFixed(1)} → fark '
            '${fark >= 0 ? '+' : ''}${(fark * 100).toStringAsFixed(1)}',
          );
        }
      }
      final dir = Directory('build/ai_altin')..createSync(recursive: true);
      final stamp = DateTime.now().toIso8601String().replaceAll(
        RegExp('[:.]'),
        '-',
      );
      final out = File('${dir.path}/sonuc_$stamp.json')
        ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rapor));
      // ignore: avoid_print
      print('rapor: ${out.path}');
    },
  );
}
