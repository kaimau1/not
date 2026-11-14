# DEVIR — K32 iki not yan yana (dal oto/K32-yan-yana)

Plan: `docs/plan_K32_K34.md` §K32 (A0–A7). Telefon/adb KULLANILMADI (P60 telefonda).

## Yapılanlar
- A0 `test/second_note_test.dart` (a)–(e) + dikey: önce 4 kırmızı (b,c,d,e), şimdi 6 yeşil.
- A1 `lib/app/second_note.dart`: SecondNote, secondNoteProvider, twoNoteLayoutFor, pay tercihi, SecondNotePane.
- A2 editör kendini kapattığı 6 yer → `_closeEditor()`: silindi dalı (`note_editor_screen` ~1431),
  "not bulunamadı → Geri" (~3125), kalem bitti maybePop (~2699), kayıt bitince geri (~5037),
  `_delete` (appearance:476), `_toggleArchive` (actions:932). `goHome` düğmesi yandakinde çizilmez.
- A3 `split_shell.dart`: Row'a HEP var olan ayraç2 + yandaki bölme; liste `twoOnly`'de autoHides.
- A0 ölçüm: geri, `/`'tan itilmiş notta iç gezginden not rotasını kapatır (konum `/`); başlangıç
  konumu `/note/a` (altında `/` yok) iken geri hiçbir şey yapmıyor — gerçek uygulamada not hep
  `/` üstüne itilir, test (c) bu yolu kilitler.

## Bütçe (ikinci not YOKKEN değişmedi)
S12 {0,0,1,1} · S12b {0,0,2} · S26 {1,14}.

## Sıradaki
A4 menü "Yanda aç" + router aynı-not · A5 S27 · A6 kenar · A7 kapanış.

## Test
`flutter test test/second_note_test.dart test/fullscreen_pull_test.dart test/split_layout_rules_test.dart --reporter failures-only`
