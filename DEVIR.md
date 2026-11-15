# DEVIR — oto/birikme-sizinti (kullandıkça artan kasma, 1.2.80)

Yapılanlar:
- Kanıt: `test/oturum_birikim_test.dart` (S51, budgets.json) — gerçek kabuk + kök sarmalayıcılar, 2 liste + 2 metin notu × 20 tur aç/dokun/klavye/geri.
- Kök neden: `lib/features/calendar/presentation/note_calendar_links.dart` `noteCalendarLinksProvider` düz `Provider.family` → açılan her not için kalıcı örnek (4 not → 4). `autoDispose` → 0.
- Docs: akicilik.md, regresyon_listesi.md, KONTROL_LISTEM "Telefonda bak", sürüm notu (tr/en 15 Kasım).

Ölçüm (önce → sonra, tur 1/4/17/20):
- kapali_nota_bagli_saglayici 4 → 0
- klavye turu kurulum/dizilme/boyama: liste 615/173/1612 (tur 1 = 17), metin 637/176/2142 (tur 4 = 20) — önce de sonra da sabit
- canlı nesne 111, toplanmayan (GC sonrası) sabit, sağlayıcı 117 sabit, abone 0, ticker 0, rota 1/1, genel dinleyici aynı

İşe yaramayan: `formattedRetainingPath` (--enable-vmservice) yol hep kendi isteğinden geçiyor; tek forceGC yetmiyor (sayı oturana dek tekrar).

Kalan: cihaz — taze ↔ 30 gir-çık sonrası `tool/perf/ab_klavye.py` + `adb shell dumpsys meminfo dev.kaimau.notlar.olcum`; termal kısma şüphesi.

Test: `flutter test test/oturum_birikim_test.dart --reporter failures-only`
