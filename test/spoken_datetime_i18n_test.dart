import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spoken_datetime.dart';

/// 2026-08-06'da eklenen 12 dilin sınavı (tr/en/de/es zaten
/// `spoken_datetime_test.dart`ta). Her dil için iki kritik nokta:
/// (1) "yarın saat N" çözülüyor mu, (2) "öbür gün" ifadesi İÇİNDE "yarın"
/// kelimesi geçse bile +2 gün veriyor mu.
void main() {
  // Pazar, 26 Temmuz 2026, saat 22:15.
  final now = DateTime(2026, 7, 26, 22, 15);

  DateTime? parse(String text, String code) =>
      parseSpokenDateTime(text, languageCode: code, now: now);

  final tomorrowNine = DateTime(2026, 7, 27, 9);
  final dayAfterNine = DateTime(2026, 7, 28, 9);

  // (dil, "yarın saat 9", "öbür gün saat 9")
  const cases = <(String, String, String)>[
    ('fr', 'demain à 9h réunion', 'après-demain à 9h'),
    ('it', 'domani alle 9 riunione', 'dopodomani alle 9'),
    ('pt', 'amanhã às 9 reunião', 'depois de amanhã às 9'),
    ('nl', 'morgen om 9 vergadering', 'overmorgen om 9'),
    ('pl', 'jutro o 9 spotkanie', 'pojutrze o 9'),
    ('ru', 'завтра в 9 встреча', 'послезавтра в 9'),
    ('id', 'besok jam 9 rapat', 'lusa jam 9'),
    ('hi', 'कल 9 बजे बैठक', 'परसों 9 बजे'),
    ('ja', '明日9時に会議', '明後日9時に会議'),
    ('ko', '내일 9시 회의', '모레 9시 회의'),
    ('zh', '明天9点开会', '后天9点开会'),
    ('ar', 'غدا الساعة 9 اجتماع', 'بعد غد الساعة 9'),
  ];

  for (final (code, tomorrow, dayAfter) in cases) {
    test('$code: yarın saat 9', () {
      expect(parse(tomorrow, code), tomorrowNine);
    });

    test('$code: öbür gün saat 9', () {
      expect(parse(dayAfter, code), dayAfterNine);
    });
  }

  test('yeni dillerin hepsi destekleniyor', () {
    for (final (code, _, _) in cases) {
      expect(spokenDateTimeSupported(code), isTrue, reason: code);
    }
    // Bölge varyantı da taban koda düşer.
    expect(spokenDateTimeSupported('pt-BR'), isTrue);
    expect(spokenDateTimeSupported('zh-Hans'), isTrue);
  });

  test('zamansız cümlede hatırlatıcı UYDURULMAZ', () {
    expect(parse('会議があります', 'ja'), isNull);
    expect(parse('у меня встреча', 'ru'), isNull);
    expect(parse('j ai une réunion', 'fr'), isNull);
  });

  test('günün bölümü saati kaydırır', () {
    // Fransızca "demain soir 7" → 19:00 (soir öğleden sonra bölümü).
    expect(parse('demain soir à 7', 'fr'), DateTime(2026, 7, 27, 19));
    // Rusça "завтра вечером в 7" → 19:00.
    expect(parse('завтра вечером в 7', 'ru'), DateTime(2026, 7, 27, 19));
  });

  test('kelime sınırı: uzun kelimenin içindeki gün adı sayılmaz', () {
    // "завтракать" (kahvaltı etmek) içinde "завтра" var; Kiril harf sayıldığı
    // için sınırdan geçemez ve hatırlatıcı uydurulmaz.
    expect(parse('я люблю завтракать', 'ru'), isNull);
  });
}
