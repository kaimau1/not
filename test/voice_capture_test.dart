import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/voice_capture_sheet.dart';

/// Sesli yakalama levhası metin + SEÇİLEN EYLEM döndürür; nota ne gireceğine
/// bu eşleme karar verir. Kritik olan ayrım: hangi eylem yapay zekâ çağırır,
/// hangisi çağırmaz — yanlış tarafa düşen bir eylem ya boşuna puan harcar ya
/// da kullanıcının istediği dönüşümü sessizce atlar.
void main() {
  test('insert ve asList yapay zekâ çağırmaz', () {
    expect(voiceCaptureInstruction(VoiceCaptureAction.insert), isNull);
    expect(voiceCaptureInstruction(VoiceCaptureAction.asList), isNull);
  });

  test('özetle / böl / düzelt ayrı yönergeler üretir', () {
    final instructions = [
      voiceCaptureInstruction(VoiceCaptureAction.summarize),
      voiceCaptureInstruction(VoiceCaptureAction.toItems),
      voiceCaptureInstruction(VoiceCaptureAction.fix),
    ];
    expect(instructions.every((i) => i != null && i.trim().isNotEmpty), isTrue);
    // Üçü birbirinden farklı olmalı: kopyala-yapıştır hatası aynı yönergeyi
    // iki çipe bağlarsa kullanıcı farkı ancak çıktıda anlar.
    expect(instructions.toSet().length, 3);
  });

  test('her eylem eşlemede karşılanır', () {
    for (final action in VoiceCaptureAction.values) {
      expect(() => voiceCaptureInstruction(action), returnsNormally);
    }
  });
}
