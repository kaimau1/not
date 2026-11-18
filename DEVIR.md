# DEVIR — P76 Decisions (dal oto/P76-decisions)

Yapılanlar (her biri ayrı commit):
- DA-E1 servis + bayrak + savunmacı ayrıştırma (6bc09df4)
- DA-1 hızlı ekle hedefi (428677a5) · DA-2 etiket öner çipinde sessiz düzen (7914622e)
- DA-13 başlık doğrulama (fe3d969a) · DA-14 hızlı ekle yazım doğrulama (34d32241)
- DA-E0 altın set + puan + canlı koşucu + gerçek fikstür (75d47c9d)

Şu anki adım: bitti; main'e birleştirilmedi, push yok (kullanıcı kararı 2026-11-18).

Ölçüm (canlı, 2026-11-18 23:54, ücretsiz katman, bilgisayar):
- dropTarget 30/30, kapsam95 %100, ECE 0,066, P50/P95 306/507 ms
- noteTriage %98 (300 alt soru), ECE 0,043, 404/672 ms
- titleOk 30/30, doğru-ret %100 / yanlış-ret %0, ECE 0,058, 269/504 ms
- spellFixOk 29/30, doğru-ret %93 / yanlış-ret %0, ECE 0,152 (>0,10 → kapalı), 311/986 ms
- 429 ücretsiz katmanda ~84 ardışık çağrıda (code too_many_requests)

İşe yaramayan: ilk koşuda 429 sonrası servis 1 dk susunca titleOk tümü yanıtsız → koşucu 61 sn bekleyip yeniden dener.

Sıradaki: gölge kip (`aiDecisionsShadow`) ile gerçek kullanım uyuşması; üretken taban koşusu; DA-16 kayıt; vekil Function (DA-E3).
Test: `flutter test test/decision_*_test.dart test/quick_list_screen_test.dart test/quick_drop_test.dart test/ai_altin_decisions_set_test.dart`
Canlı: `GEMINI_API_KEY=... flutter test tool/ai_altin/decisions_kos_test.dart`
