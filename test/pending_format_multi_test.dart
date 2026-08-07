import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/presentation/editor/format_menu.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// BİÇİM ŞERİDİ KEEP GİBİ (kullanıcı ekran görüntüsüyle: "biçim alanı
/// Keep'teki gibi olmalı, basınca direkt aktifleştiği belli olmalı ve birden
/// çok açılabilmeli, açılanlarla yazmaya devam etmeli").
///
/// Keep'te B/I/U birer AÇ/KAPA düğmesi: basılınca hemen yanar, üçü aynı anda
/// açık kalabilir ve o andan sonra yazılan metin üçünü birden alır.
void main() {
  WrapTextController controllerAt(String text, int caret) =>
      WrapTextController(text: text)
        ..selection = TextSelection.collapsed(offset: caret);

  /// Kullanıcının yazması: alanın değerini IME gibi günceller.
  void type(WrapTextController controller, String typed) {
    final caret = controller.selection.baseOffset;
    controller.value = TextEditingValue(
      text: controller.text.replaceRange(caret, caret, typed),
      selection: TextSelection.collapsed(offset: caret + typed.length),
    );
  }

  test('tek biçim: basılınca bekler, işaretler koşu BİTİNCE metne girer', () {
    final c = controllerAt('', 0);
    expect(applyRichFormat(c, RichFormat.bold), isFalse);
    expect(c.hasPendingFormat, isTrue);
    // Metne HENÜZ dokunulmadı: ham işaret ekranda görünmez.
    expect(c.text, '');

    // KOŞU BOYUNCA tampona hiç dokunulmaz — boşluk da koşuyu bitirmez.
    // (Eskiden kelime sınırında sarılıyordu; Gboard boşluktan sonra kendi
    // oluşturma aralığını yeniden açtığı için o an da güvenli değildi.)
    type(c, 'merhaba');
    expect(c.logicalText, 'merhaba');
    type(c, ' ');
    expect(c.logicalText, 'merhaba ');
    // Ama EKRANDA kalın görünür: canlı önizleme aralığı koşunun tamamı.
    expect(c.pendingRange, (0, 8));
    expect(c.pendingMark.bold, isTrue);

    c.flushPendingFormat();
    expect(c.logicalText, '**merhaba **');
  });

  test('BİRDEN ÇOK biçim aynı anda beklenir ve iç içe sarılır', () {
    final c = controllerAt('', 0);
    applyRichFormat(c, RichFormat.bold);
    applyRichFormat(c, RichFormat.italic);
    applyRichFormat(c, RichFormat.underline);
    expect(c.pendingFormats.keys, [
      RichFormat.bold,
      RichFormat.italic,
      RichFormat.underline,
    ]);

    type(c, 'merhaba ');
    c.flushPendingFormat();
    // Önce basılan en DIŞTA sarar (** = kalın, _ = italik, ~ = altı çizili).
    expect(c.logicalText, '**_~merhaba ~_**');
    // Üçü de metinde etkin.
    final active = activeFormats(c.logicalText, 4, 11);
    expect(active.bold, isTrue);
    expect(active.italic, isTrue);
    expect(active.underline, isTrue);
  });

  test('aynı düğmeye yeniden basmak beklemeyi KALDIRIR (aç/kapa)', () {
    final c = controllerAt('', 0);
    applyRichFormat(c, RichFormat.bold);
    applyRichFormat(c, RichFormat.italic);
    applyRichFormat(c, RichFormat.bold);
    expect(c.pendingFormats.keys, [RichFormat.italic]);

    type(c, 'merhaba ');
    c.flushPendingFormat();
    expect(c.logicalText, '_merhaba _');
  });

  test('KOŞU ORTASINDA biçmi kapatmak: yazılan kısım kalın, gerisi düz', () {
    // Word davranışı: "kalın yaz → kalını kapat → düz devam et". Eskiden
    // kapatma yalnız beklemeyi düşürüyordu; o ana kadar yazılan metin hiç
    // işaretlenmediği için kullanıcı "kalın yazamıyorum" diyordu.
    final c = controllerAt('', 0);
    applyRichFormat(c, RichFormat.bold);
    type(c, 'kalin');
    expect(c.logicalText, 'kalin');

    applyRichFormat(c, RichFormat.bold); // kapat
    expect(c.logicalText, '**kalin**');
    expect(c.hasPendingFormat, isFalse);
    // İmleç kutunun DIŞINDA: devamı düz yazılır, kutuya sızmaz.
    expect(c.selection.baseOffset, '**kalin**'.length);

    type(c, ' duz');
    expect(c.logicalText, '**kalin** duz');
    expect(activeFormats(c.logicalText, 11, 13).bold, isFalse);
  });

  test('bekleyen biçim düğmeyi HEMEN yakar (metin daha yazılmadan)', () {
    final c = controllerAt('', 0);
    expect(activeRichFormats(c).bold, isFalse);

    applyRichFormat(c, RichFormat.bold);
    applyRichFormat(c, RichFormat.underline);
    final active = activeRichFormats(c);
    expect(active.bold, isTrue);
    expect(active.underline, isTrue);
    expect(active.italic, isFalse);
  });

  test('bekleme değişince şerit haber alır (denetleyici dinleyicisi)', () {
    final c = controllerAt('', 0);
    var notifications = 0;
    c.addListener(() => notifications++);
    applyRichFormat(c, RichFormat.bold);
    expect(notifications, greaterThan(0));
  });

  test('imleç taşınınca bekleyenler düşer', () {
    final c = controllerAt('abc', 0);
    applyRichFormat(c, RichFormat.bold);
    expect(c.hasPendingFormat, isTrue);

    // Kullanıcı imleci başka yere koydu: "buradan itibaren" niyeti bitti.
    c.selection = const TextSelection.collapsed(offset: 3);
    applyRichFormat(c, RichFormat.italic);
    expect(c.pendingFormats.keys, [RichFormat.italic]);
  });

  test('koşu boyunca tampona HİÇ dokunulmaz, sonunda TEK sarma olur', () {
    final c = controllerAt('', 0);
    applyRichFormat(c, RichFormat.bold);
    applyRichFormat(c, RichFormat.italic);
    type(c, 'mer ');
    expect(c.logicalText, 'mer ');
    type(c, 'haba');
    expect(c.logicalText, 'mer haba');
    // Koşunun tamamı ekranda biçimli görünüyor.
    expect(c.pendingRange, (0, 8));

    c.flushPendingFormat();
    expect(c.logicalText, '**_mer haba_**');
  });

  test('geri silme koşuyu KISALTIR ama biçim niyetini düşürmez', () {
    final c = controllerAt('', 0);
    applyRichFormat(c, RichFormat.bold);
    type(c, 'merhabax');
    // Son harfi sil.
    c.value = const TextEditingValue(
      text: 'merhaba',
      selection: TextSelection.collapsed(offset: 7),
    );
    expect(c.hasPendingFormat, isTrue);
    expect(c.pendingRange, (0, 7));
    c.flushPendingFormat();
    expect(c.logicalText, '**merhaba**');
  });

  test('koşunun DIŞINA dokunmak koşuyu kapatır, aradaki metni yutmaz', () {
    // KÖK NEDEN: "yazmaya devam etme" ile "başka yere dokunma" ayırt
    // edilmezse, metnin ilerisine dokunmak aradaki bütün metni koşunun içine
    // alır ve hepsi kalın olurdu.
    final c = controllerAt('sonrasi', 0);
    applyRichFormat(c, RichFormat.bold);
    type(c, 'ilk');
    expect(c.logicalText, 'ilksonrasi');
    // Kullanıcı metnin sonuna dokundu (metin değişmedi, imleç sıçradı).
    c.value = const TextEditingValue(
      text: 'ilksonrasi',
      selection: TextSelection.collapsed(offset: 10),
    );
    expect(c.hasPendingFormat, isFalse);
    // Yalnız yazılan parça sarıldı; dokunulan yere kadarki metin düz kaldı.
    expect(c.logicalText, '**ilk**sonrasi');
  });

  test('renk gibi indeksli biçimler de birlikte bekleyebilir', () {
    final c = controllerAt('', 0);
    applyRichFormat(c, RichFormat.bold);
    applyRichFormat(c, RichFormat.color, colorIndex: 2);
    type(c, 'merhaba ');
    c.flushPendingFormat();
    expect(c.logicalText, '**%%2:merhaba %%**');
    expect(activeFormats(c.logicalText, 7, 14).color, 2);
  });

  // KÖK NEDEN (kullanıcı iki ekran görüntüsüyle: "biçimli yazarken hâlâ
  // problemler mevcut"): `merhaba` yazarken ekranda `me` düz, `rh` kalın ve
  // ardından HAM `_aba_` çıkıyordu. Sarma "IME oluşturma aralığı bitti"
  // anında yapılıyordu; oysa Gboard bir kelimeyi yazarken o aralığı arada bir
  // kapatıp yeniden açıyor. Tam o anda tampona işaret sokmak klavyenin kendi
  // metin modelindeki konumları kaydırıyor, sonraki tuş işaretleri kelimenin
  // ortasına dağıtıyor ve eşi kalmayan işaret ham karakter olarak çiziliyordu.
  test('koşu boyunca tampona DOKUNULMAZ (IME bozulmasın)', () {
    final c = controllerAt('', 0);
    applyRichFormat(c, RichFormat.bold);
    for (final ch in 'merhaba dunya '.split('')) {
      type(c, ch);
      expect(
        c.logicalText.contains('*'),
        isFalse,
        reason: '"$ch" sonrası tamponda işaret belirdi',
      );
    }
    // Biçim hâlâ bekliyor: düğme yanık kalır, kaybolmaz.
    expect(c.hasPendingFormat, isTrue);
    expect(activeRichFormats(c).bold, isTrue);
  });

  test('alan odaktan çıkarken bekleyen biçim METNE YAZILIR', () {
    final c = controllerAt('', 0);
    applyRichFormat(c, RichFormat.bold);
    type(c, 'merhaba');
    expect(c.logicalText, 'merhaba');

    c.flushPendingFormat();
    expect(c.logicalText, '**merhaba**');
    expect(c.hasPendingFormat, isFalse);
  });

  test('flush yazılacak bir şey yoksa yalnız beklemeyi düşürür', () {
    final c = controllerAt('', 0);
    applyRichFormat(c, RichFormat.bold);
    c.flushPendingFormat();
    expect(c.logicalText, '');
    expect(c.hasPendingFormat, isFalse);
  });
}
