# DEVIR — oto/P64-kesif-kucukler (P64, PLAN §1.3, telefonsuz)

Durum: BİTTİ (push yok; yürütücü birleştirip tek push yapacak). Birleştirmeden önce bu dosyayı SİL.

Yapılanlar (her madde ayrı commit, önce kırmızı test → düzelt → yeşil):
- KT-5 "Sabitlemeyi kaldır" → "Sabitten çıkar" (cb776552) — test/note_menu_model_test.dart
- KT-3 dar şeritte tek harf gün adı yok + boş hâl FAB üstünde (6d51d07e) — calendar_backdrop_themes, home_gestures
- KT-9 Klasörler ortak boş hâl (17db0621) — folders_screen_test (+terminology "Burada … yok")
- KT-12 arama ipucu "Ara..." / "Search..." (b78a37f3) — menu_names_test
- KT-2 süz levhası ≤ 560 dp ortada, kSheetMaxWidth (5a484341) — filter_sheet_layout_test
- KT-10 Ayarlar "Güvenlik" bölümü (c471d0ca) — account_identity_card_test; S36 bütçe içinde
- T10 açıklama levhası denetleyicisi State'te (a53b8120) — caption_sheet_dispose_test
- KONTROL 36 alarm izni ipucu bir kez (cefb6fed) — exact_alarm_hint_test
- KONTROL 39 sabit PDF çubuğu 1,35/2,0 yazı bekçisi (be625efb) — taşma ÜRETİLEMEDİ, düzeltme yok

Zaten yapılmış (dokunulmadı): KT-7 (PA2 H1: alt yazı 2 satır, misafir notu serbest), KT-6 (F79.6 AiOfflineCard).
Yapılmadı: KT-1, KT-4 (A/B, cihaz bekliyor), KT-8 (editör → ölçüm kapısı); KT-12'nin "klasör adı 2 satır"ı
(kart boyu sabit 72/128 dp, 2 satır 1,3 yazıda taşar — sabah bakılacak).

Kök neden KT-2: maxHeight-only constraints M3 640 dp sınırını ezer (filter_sheet.dart:44); ~30 levha aynı kalıpta.
KT-10 yanlış yol: security alanı "Veri" grubunda → S36 sound toplamı 583→612; Hesap grubunda 583 (ai 203→191).

Doğrulama: `flutter analyze` temiz; perf_budget_test tam yeşil (48); ilgili testler yeşil.
