# Kasma envanteri — 17 Kasım 2026

Uygulamadaki bilinen, kanıtlanmış ve şüpheli bütün kasma kaynaklarının TEK listesi. Amaç: bir alt
model (işçi) bu dosyadan bir kayıt alıp başka belge okumadan kanıtı üretebilsin, düzeltebilsin,
doğrulayabilsin. **Bu dosya yalnız belgedir; kod değişmedi.**

- Satır numaraları `f9d0b5a8` (main, 2026-11-16) içindir. Satır kaymışsa her kayıttaki **Bul**
  desenini `Grep` ile ara.
- Eski bulguların ayrıntısı `docs/hafiza/akicilik.md` ve `docs/perf/kullanici_video_2026-11-15.md`
  içinde; burada yalnız AÇIK kalanlar var.

## 0. Kapsam ve dürüstlük

**Tarananlar (bu oturum):** `lib/` altında üretilmiş çeviri dışındaki 549 Dart dosyası
(205.289 satır), 22 kalıp sınıfı için baştan sona tarandı (desenler Ek C'de). Ayrıca
`akicilik.md`, `editor.md`, `kullanici_video_2026-11-15.md`, `KONTROL_LISTEM.md`, `PLAN.md` ve
16 Kasım raporundaki açık kasma maddeleri buraya taşındı.

**Yapılamayanlar:**

- **Hiçbir şey çalıştırılmadı.** Bu bilgisayarda Flutter SDK yok (`C:\src\flutter` bulunamadı),
  test ya da ölçüm koşulamadı. "Ölçüldü" yazan sayılar eski oturumlardan alıntıdır; kaynağı
  yanında yazar.
- **Statik tarama şunları bulamaz:** raster iş parçacığı yükü, GC duraklaması, gölgelendirici
  derlemesi, ısınma/termal kısma, klavye sürecinin (IME) kendi gecikmesi, sistemin ekranı 60 Hz'e
  indirmesi. Bunlar için cihaz ölçümü şart (§G).
- "Eksiksiz" iddiası şudur: **kodda görülebilen kalıpların tamamı listelendi.** Çalışma anında
  ortaya çıkan bir kasma bu listede olmayabilir; §G onu yakalayacak ölçüm işlerini tanımlar.

**Kanıt düzeyi (her kayıtta yazar):**

| Etiket | Anlamı |
|---|---|
| `CİHAZ` | Telefonda ölçüldü ya da kullanıcı videosunda kare kare görüldü |
| `TEST` | Cihazsız bütçe testinde sayıldı (kurulum/dizilme sayısı) |
| `KOD` | Kalıp koddan okundu; aynı kalıbın başka yerde kasma yaptığı ölçülmüş, bu yerde ölçülmedi |
| `ADAY` | Statik şüphe. **Önce ölç; ölçüm temizse kaydı "temiz" diye kapat, düzeltme yazma** |

**Öncelik:** `P0` kullanıcının şikâyetiyle örtüşüyor ve kalıp kanıtlı · `P1` kanıtlı kalıp, sık
kullanılan yüzey · `P2` seyrek yüzey ya da küçük kazanç · `P3` aday, ölçülmeden dokunulmaz.

## 1. İşçi için kullanım (kısa)

1. `isci` skill'ini uygula. Editöre/kart ızgarasına dokunuyorsan `kasma-kontrol`, cihaz ölçümü
   varsa `ab-olcum`.
2. Sıra değişmez: **kanıt (kırmızı ya da taban sayı) → düzeltme → aynı kanıt yeşil/düşük.**
   Kanıt üretilemiyorsa düzeltme yazma; kayda "üretilemedi: ne denendi" yaz.
3. Her kayıt AYRI commit. Bütçe mandalları (`test/perf_budget/budgets.json`) yalnız düşer.
4. Dokunduğun yüzeyin bütçe senaryosu yoksa önce onu yaz (HIZ SÖZLEŞMESİ).
5. Görünüş değişmez. Bu envanterdeki düzeltmelerin hiçbiri tasarım değişikliği istemez; istiyorsa
   dur, kayda "tasarım kararı gerekir" yaz.
6. Flutter: `"C:/src/flutter/bin/flutter.bat"` (PATH'te değil). Tek test:
   `flutter test test/<dosya>_test.dart --reporter failures-only`. Push'tan önce tam
   `flutter analyze`.

## 2. Düzeltme kalıpları (kayıtlar bunlara atıf yapar)

| No | Kalıp | Hazır örnek (kopyala) |
|---|---|---|
| T1 | **Levha klavye payı.** Levha içeriği `builder` DIŞINDA bir kez kurulur; klavye boşluğunu yalnız ince bir sarmalayıcı okur. İçerik State'i kendi `build`'inde `MediaQuery.viewInsetsOf` OKUMAZ | `SheetInsetPadding` (`lib/core/widgets/sheet_keyboard.dart:8`); kullanım `quick_drop_sheet.dart:156`; S52'de düzeltilen dört levha (`capture_mode_sheet.dart:97` çevresi) |
| T2 | **Sayfa klavyesi.** `KeyboardInsetScope` + `Scaffold(resizeToAvoidBottomInset: false)` + `KeyboardSnap`; alttaki şerit `KeyboardSlide`. Kapsamın altında `viewInsetsOf` değil `KeyboardInset.liveOf/openOf` | `QuickListScreen` (S49: 438/168 → 341/99); `keyboard_snap.dart` |
| T3 | **Yerel durum dar dinlenir.** Kök `setState` yerine `ValueNotifier` + dar `ValueListenableBuilder`/`ListenableBuilder` | `_dirtyN` (`template_editor_screen.dart`), `_bodyTopN`, `_undoN` |
| T4 | **Boy animasyonu yok.** Boy tek adımda değişir; hareket yalnız boyamada (`Transform`, `FractionalTranslation`, `RevealUp`) | Biçim paneli (S9 34 → 2), `_MonthPanel` |
| T5 | **Saydamlık.** `TweenAnimationBuilder` + `Opacity` yerine `FadeTransition` (denetleyiciyle) ya da boya alfası; sürekli süren geri sayım `CustomPaint(repaint:)` ile | `SteppedCountdown` (`app_notice.dart:575` çevresi), `_FadeSnapshotPainter` |
| T6 | **Örnek önbelleği.** Girdisi değişmeyen satır/çip AYNI widget örneğini döner | `_rowCache` (`quick_list_screen.dart:469`), `_memo` (şablon), `_slotCache` |
| T7 | **Akış yankısı.** Tam listeyi izleme; `select` ile dilim, `StableBox` ile "içerik aynıysa aynı örnek", ağır türetme `runHeavy` | `_cardEnvProvider`, `_folderNotesBox` (`notes_providers.dart:1173`) |
| T8 | **Platform kanalı sıcak yolda yok.** Ön planda yazarken/menü açılırken kanal çağrısı yapma; `paused`'a ertele, birleştir, "değişmediyse çağırma" | `prefs_sync.dart:268` (yalnız değişince yaz), `reminder_service.dart:524` (yaşam döngüsü) |
| T9 | **Build'de saf hesap yok.** Sıralama/süzme/RegExp sonucu State'te tutulur, girdi değişince yenilenir | `CardPreview.of` (Expando) |
| T10 | **Tembel liste.** Öğe sayısı sınırsızsa `ListView.builder`/sliver; `shrinkWrap` yok | ana ekran ızgarası |

## 3. Özet — paketler ve öncelik

Kayıtlar dokuz pakette toplandı. Paket = bir alt ajana verilecek iş. Kuyruk'a kopyalanacak hazır
satırlar Ek A'da (ben `OTOMASYON.md`'ye EKLEMEDİM; zincir kendiliğinden başlamasın diye karar
kullanıcıda).

| Paket | İçerik | Kayıt | Öncelik | Model | Cihaz |
|---|---|---|---|---|---|
| KP1 | Klavye açıkken levhalar + bekçi testi | K-01…K-12 | P0 | sonnet | A/B (kb) |
| KP2 | Süren geri sayım ve beliriş animasyonları | K-37, K-38 | P1 | sonnet | A/B (menu, yaz) |
| KP3 | Yazarken çalışan arka plan işleri | K-24, K-25, K-26 | P1 | opus | A/B (yaz, kb) |
| KP4 | Klavye açıkken sayfa iskeleti | K-13…K-19 | P1→P2 | önce sonnet (ölçüm), sonra opus | gerekirse |
| KP5 | Not akışı yankısı (not sayısıyla büyüyen yük) | K-22, K-23 | P1 | opus (veri göçü kısmı ayrı karar) | A/B + 1000 not |
| KP6 | Tembel liste ve build'de hesap | K-47, K-48, K-57, K-58 | P2 | sonnet (ekran başına mekanik) | hayır |
| KP7 | Cihaz ölçüm turu ve ölçüm aracı açıkları | K-20, K-21, K-59…K-63 | P0 (bilgi) | sonnet + telefon | evet |
| KP8 | Editörde kalanlar | K-27…K-36 | P2 | opus, ölçüm kapılı | A/B |
| KP9 | Yazı tipi çalışma anı indirmesi | K-54 | P1 | sonnet | hayır |

Önerilen sıra: **KP1 → KP7 → KP2 → KP3 → KP9 → KP5 → KP4 → KP6 → KP8.** KP7 erken, çünkü
klavye/panel şikâyetinin (K-20) kod işi mi sistem davranışı mı olduğunu o ayıracak.

Pakete girmeyenler: K-39…K-46 (önce profil; kod işi ölçümden sonra tanımlanır), K-49…K-53, K-55,
K-56 (`P3` adaylar; KP7 ölçümü bir yüzeyi işaret ederse o zaman açılır) ve K-64…K-69 (hızlı ekle /
akıllı liste; 17 Kasım raporundaki HE-1 ve AL-1 paketleriyle birlikte yapılır).

---

## A. Klavye açıkken levha baştan kuruluyor (KP1)

**Kullanıcı belirtisi:** "Klavye açıkken menüde, panelde sürekli kasma."
**Kök neden (hepsinde aynı):** levhanın State'i kendi `build`'inde
`MediaQuery.viewInsetsOf(context)` okuyor. Klavye animasyonunun her karesinde (≈ 15–30 kare)
levhanın TAMAMI yeniden kurulup diziliyor. Aynı kalıp S48'de 14.124 → 396 kurulum, S52'de dört
levhada 690–1296 → 342–354 kurulum olarak ölçülüp düzeltildi (`akicilik.md`, S48 ve S52 satırları).
**Düzeltme:** T1. **Kanıt düzeni:** `test/levha_klavye_test.dart` (S52) — levhayı aç, 6 klavye
karesi ver (`tester.view.viewInsets`), kurulum ve dizilme say. Her kayıt için bu dosyaya bir satır
eklenir; önce bugünkü sayı (taban) yazılır, düzeltmeden sonra düşmesi beklenir.

| Kayıt | Yer | Kanıt | Ö | Ek yük ve not |
|---|---|---|---|---|
| K-01 | `lib/features/ai/presentation/ai_sheet.dart:575` | KOD | P0 | AI levhası; `build` başında ek listeleri de her karede süzülüyor (`videos`, `slides`, satır 562–572). İçinde `IntrinsicHeight` (:1124) var |
| K-02 | `lib/features/notes/presentation/editor/note_search_sheet.dart:257` | KOD | P0 | **En ağırı:** aynı `build`'de arama yeniden hesaplanıyor (`_textHits(query)` + `_attachmentHits(query)`, satır 246–248). Ayrıca `onChanged` → `setState` (:269) tuş başına tüm levhayı kurar. Düzeltme: T1 + sonuç listesini State'te tut (T9), yalnız sorgu değişince hesapla |
| K-03 | `lib/features/notes/presentation/editor/calculator_sheet.dart:106` | KOD | P1 | `onChanged` → `setState` (:116) |
| K-04 | `lib/features/notes/presentation/voice_capture_sheet.dart:795` | KOD | P1 | 18 `setState`'li büyük durum; okuma `_body` içinde. İçeriği bölmeden T1 uygulanamaz: alt boşluğu (`bottomGap`) ayrı küçük widget'a taşı |
| K-05 | `lib/features/settings/presentation/settings_sections/settings_ai.dart:528` | KOD | P2 | `shrinkWrap` liste (:567), `onChanged` → `setState` (:544, :560) |
| K-06 | `lib/features/settings/presentation/settings_sections/settings_appearance.dart:119` | KOD | P2 | Dil listesi her kurulumda süzülüyor (`widget.languages.entries.where(_matches).toList()`, :116); tembel olmayan `ListView` (:138) |
| K-07 | `lib/features/friends/presentation/friends_screen.dart:610` | KOD | P2 | `build`'de `ref.watch(friendsStreamProvider)` + küme kurulumu; `ListView` (:651) |
| K-08 | `lib/features/notes/presentation/note_link_ui.dart:69` | KOD | P1 | `build`'de BÜTÜN notlar `foldForSearch` ile süzülüyor (:63–66) → yük not sayısıyla büyür; `shrinkWrap` (:94); `onChanged` → `setState` (:89) |
| K-09 | `lib/features/notes/presentation/editor/ai_result_sheet.dart:100` | KOD | P1 | Uzun AI metni içeren alan her karede diziliyor |
| K-10 | `lib/features/folders/presentation/folder_chat_screen.dart:327` | KOD | P2 | Yalnız yazma çubuğu kuruluyor (küçük); asıl yük ekranın `Scaffold`'ı (bkz. K-15) |
| K-11 | `lib/features/notes/presentation/editor/attachment_actions.dart:292` | KOD | P3 | Tek `TextField`; S52'de bilerek bırakıldı. Bekçi testi (K-12) için izin listesine yazılır ya da T1 uygulanır |

**K-12 — Bekçi testi (P0, bu paketin son işi).** `test/jank_patterns_guard_test.dart`'a yeni grup:
`lib/` altında `MediaQuery.viewInsetsOf(` geçen dosyalar bir izin listesinde olmalı. Bugünkü tam
liste (37 satır, Ek C-1). Düzeltmelerden sonra kalması beklenenler: `sheet_keyboard.dart`,
`keyboard_snap.dart`, `app_notice.dart:452` (görünen karta indirildi, PA5), `app.dart:281`
(dokunuşta bir kez), `dashboard_screen.dart:1801` (K-56), ve S52'de düzeltilen beş levhanın
`sheetContext` okumaları. Yeni dosya eklenirse test kırmızı olur. "Bozma denemesi" testi de yazılır
(dosyadaki öbür gruplar gibi).

**Paket kabul ölçütü:** her levhada 6 klavye karesinde kurulum sayısı ≤ 400 ve satır/öğe kurulumu
0; `flutter analyze` temiz; cihazda `ab_hepsi.py --altin` `kb` evresi kötüleşmedi. Cihazda levha
evresi olmadığı için "cihazda ölçülmedi" notu `KONTROL_LISTEM.md`'ye yazılır.

---

## B. Klavye açıkken sayfanın iskeleti her karede kısalıyor (KP4)

**Kök neden:** `Scaffold` varsayılan olarak gövdeyi klavye kadar kısaltır
(`resizeToAvoidBottomInset: true`); klavyenin her karesinde gövdenin tamamı yeniden dizilir.
Editörde (F60.S5: ilk kare 320 → 45 kurulum) ve hızlı listede (S49) ölçülüp T2 ile düzeltildi.
**Tarama sonucu:** `Scaffold` içeren 51 dosyanın 17'sinde metin alanı var ve
`resizeToAvoidBottomInset` hiç geçmiyor. **Hepsi `ADAY`:** önce ölç.

**Ölçüm tarifi (ekran başına, cihazsız):** ekranı kur, metin alanına odaklan, 6 klavye karesi ver;
`debugOnRebuildDirtyWidget` ile kurulum, `debugPrintLayouts`/dizilme sayacı ile dizilme say
(`perf_budget_test.dart` `_frames` düzeneği). Kare başına dizilme > 30 ise T2 uygula; değilse
kaydı "temiz" kapat.

| Kayıt | Dosya | Ö | Not |
|---|---|---|---|
| K-13 | `lib/features/ai/presentation/ai_chat_screen.dart` | P1 | Uzun sohbet + tembel olmayan `ListView` (:394, :700) → klavye karesinde TÜM mesajlar dizilir (K-47 ile birlikte) |
| K-14 | `lib/features/settings/presentation/settings_screen.dart` | P1 | Ayarlar araması (`onChanged` → `setState` :1193, `build`'de `foldForSearch` :211) |
| K-15 | `lib/features/folders/presentation/folder_chat_screen.dart` | P1 | Sohbet listesi + K-10 |
| K-16 | `lib/features/calendar/presentation/tasks_screen.dart`, `routines_screen.dart` | P2 | Görev/rutin ekleme satırı; `ListView` (:298, :329; :67) |
| K-17 | `lib/features/notes/presentation/template_editor_screen.dart` | P2 | S48'de tuş yolu düzeltildi (1840 → 191); klavye KARESİ ayrıca ölçülmedi. `shrinkWrap` (:411) |
| K-18 | `lib/features/gmail/presentation/gmail_screen.dart` (2 Scaffold) | P2 | Kişisel derlemeye özgü |
| K-19 | `friends_screen.dart`, `ai_hub_screen.dart`, `bubbles_overview.dart`, `note_package.dart`, `pdf_notes_overview.dart`, `spell_learned_screen.dart`, `pdf_export_screen.dart`, `viewers/area_actions.dart`, `viewers/transcript_screen.dart`, `settings/presentation/guide_screen.dart` | P3 | Seyrek ekranlar; toplu ölçüm, yalnız kötü çıkan düzeltilir |

---

## C. Alt panel klavyeyle birlikte "zıplıyor" (KP7'nin ana konusu)

**K-20 — Panel 60 Hz, klavye 120 Hz (`CİHAZ`, P0).** Kullanıcının telefonunda (Xiaomi, Android 16,
120/144 Hz) kapanışların %43 → %72 → %83'ünde panel klavyeden ≥ 40 px kopuyor; klavye her 8,3
ms'de, panel her ikinci karede güncelleniyor (`kullanici_video_2026-11-15.md` §1). Uygulama kareleri
o anda ağır değil (8–17 ms): sorun kare ritmi, kurulum değil.
**Durum:** kip `k` (yerel öngörü, `KlavyeOngoru.kt`) ve kip `c` yazıldı, **cihazda doğrulanmadı**
(`KONTROL_LISTEM.md` "Alt panel kip k").
**Yapılacak (kod yok, ölçüm):** `tool/perf/panel_kayit.py` ile kip `k` ve `c` 10'ar aç/kapa;
çıktıdaki geri sıçrama / takılma / ort-maks sapma `docs/perf/`'e yazılır. Kip `k` kötüyse
varsayılan `c` yapılır (`--dart-define=ALT_PANEL_KIP=c`).

**K-21 — Ekran klavye açıkken 60 Hz'e mi düşüyor? (`ADAY`, P0).** HyperOS'un bazı uygulamaları
klavye açıkken 60 Hz'e sabitlediği bilinir; bu cihazda doğrulanmadı.
**Ölçüm:** klavye açıkken `adb shell dumpsys display | grep -i refresh` ve
`adb logcat -s NotlarEkran` (etkin / istenen / modlar). Aynı ölçüm bir Samsung ya da Pixel'de de
yapılmadan K-20 için yeni kod yazılmaz.

---

## D. Yazarken ve kayıt sırasında işlemci yükü (KP3, KP5)

**K-22 — Her Firestore olayı not sayısıyla doğrusal (`CİHAZ`, P1).** 414 notta olay başına ~1,2 MB
ve 21–27 ms Dart işi (`akicilik.md:78`); 120 Hz'de kare bütçesi 8,3 ms → her otomatik kayıt 2–3
kare düşürebilir. Kök: ana dinleyici bütün notları tam gövdeleriyle dinliyor
(`notes_repository.dart:298`).
**Düzeltme (iki kademe):** (a) kendi yazdığın kaydın yankısında türetilmiş sağlayıcıları tetikleme
(K-23); (b) kalıcı: kart dizini + gövde ayrı belge (PLAN (B), F22.4) — veri göçü, kullanıcı kararı
ve yedek şartı var. Bu iş senkron maliyetini de düşürür (bkz. 17 Kasım raporu §1).
**Kanıt:** `tool/perf/prof_save.py`; ayrıca 1000 ve 3000 notlu sentetik hesap (K-63).

**K-23 — Bütün not listesini izleyen türetilmişler (`KOD`, P1).** `notesStreamProvider` her
otomatik kayıtta (yazarken 2 sn'de bir) yayın yapar; aşağıdakilerin hepsi O(n) yeniden çalışır.
Riverpod görünmeyen ekranın aboneliğini duraklatır, o yüzden **hangilerinin editör açıkken
gerçekten çalıştığı ölçülmeli**: `ProviderObserver` ile "tek otomatik kayıt yankısında yeniden
hesaplanan sağlayıcılar" sayan bir bütçe senaryosu (S51'in düzeneği `oturum_birikim_test.dart`).

| Tür | Yerler |
|---|---|
| Sağlayıcı (tam liste) | `notes_providers.dart:293, 345, 895, 1124, 1151, 1211` · `due_state.dart:68` · `upload_queue.dart:204` · `semantic_search.dart:49, 90, 144` · `attachment_text_index.dart:85` · `folder_order.dart:129` · `notes_repository.dart:134` (depolama sayacı: tüm ekleri toplar) · `calendar_screen.dart:46` |
| Widget `build`'inde tam liste | `ai_hub_screen.dart:76` · `ai_chat_screen.dart:626` · `calendar_screen.dart:1222` · `google_calendar_ui.dart:246` · `gmail_screen.dart:998` · `guest_backup_card.dart:61` · `note_target_picker.dart:50` · `reminders_screen.dart:125, 137` · `study_cards_screen.dart:57` |
| Editör | `note_editor_screen.dart:3617–3624` (bkz. K-26) |

Düzeltme: T7. Öncelik sırası ölçüme göre; tahminim en pahalılar `upload_queue.dart:204` (her not ×
her ek) ve `notes_providers.dart` altılısı.

**K-24 — Oturum boyu dinleyiciler yazma duraklamasında kanal çağrısı yapıyor (`KOD`, P1).**
Flutter 3.47 Android'de Dart arayüz işi ana iş parçacığında koşar; her platform kanalı çağrısı
kareyi bekletir (`akicilik.md:27–29`).

| Yer | Her not yayınında ne oluyor |
|---|---|
| `widget_service.dart:49` → `_update` (:118–162) | 2 sn gecikmeyle 3 `saveWidgetData` + 2 `updateWidget` = **5 kanal çağrısı**. Otomatik kayıt da 2 sn: kullanıcı yazmayı bıraktığı ya da menüye uzandığı ana denk gelir |
| `reminder_service.dart:485` | 3 sn sonra `_syncReminders`: tüm notları gezer, bildirim eklentisine iptal/planlama çağrıları yapar |
| `upload_queue.dart:376` | Bekleyen yükleme taraması |
| `place_reminders.dart:168` | Konum hatırlatıcı eşitlemesi (kanal) |
| `notes_repository.dart:86–99` | Her yayında `expiredNotes` O(n) (ucuz ama sıcak yolda) |
| `assistant_service.dart:207`, `dashboard_screen.dart:1390` | Hafif; ölçümde bak |

**Düzeltme (T8):** (1) Ana ekran araçlarını ön plandayken hiç güncelleme; `AppLifecycleState.paused`
anında bir kez yaz (kullanıcı aracı zaten uygulamadan çıkınca görür; "aynı yük ise yazma" denetimi
duruyor). Tema değişimi bugünkü gibi anında kalabilir. (2) Hatırlatıcı eşitlemesini yalnız
hatırlatıcıyı etkileyen alanların imzası değişince çalıştır (not başına `id + reminderAt +
reminderRepeat + başlık + arşiv/silinme` özeti; liste için tek birleşik özet).
**Kanıt:** debug/profilde `ext.notlar.channels` sayacı (`akicilik.md:72–73`): "editörde 20 sn yazı
+ 5 sn bekle" senaryosunda kanal çağrısı sayısı önce/sonra. Hedef: yazma sırasında araç ve
hatırlatıcı kaynaklı çağrı 0.
**Dikkat:** hatırlatıcı güvenilirliği kullanıcının açık maddesi (`KONTROL_LISTEM` 4). İmza
karşılaştırması yanlış yazılırsa hatırlatıcı kaçar → `test/` altında "hatırlatıcı alanı değişince
eşitleme çalışır, gövde değişince çalışmaz" testi şart.

**K-25 — Ayar eşitlemesi 20 sn'de bir uyanıyor (`ADAY`, P2).** `prefs_sync.dart:221`: her turda
bütün yerel tercihler okunur, kayıtlı anlık görüntü `jsonDecode` edilir, plan çıkarılır (:241–279).
Değişiklik yokken de çalışır. Düzeltme: tercih yazan ortak yola "kirli" işareti koy, zamanlayıcıyı
kaldır; eşitleme yalnız kirliyken, `paused`'ta ve `resumed`'da. Bulut yazımını da azaltır.
**Kanıt:** 60 sn boşta bekleme senaryosunda `_run` çağrı sayısı (bugün 3, hedef 0).

**K-26 — Editör her not yayınında geri bağlantıları yeniden tarıyor (`KOD`, P1).**
`note_editor_screen.dart:3617–3624`: `select` içinde `backlinksTo` bütün notları dolaşıyor, hemen
altında tam liste ayrıca izleniyor. Kendi otomatik kaydın da yayın olduğu için yazarken 2 sn'de bir
çalışır. Düzeltme: geri bağlantı dizini ayrı sağlayıcı (not kimliği → bağlayanlar), yalnız
`tagLinks`'i değişen not girer/çıkar; editör yalnız kendi kimliğinin dilimini izler.
**Kanıt:** K-23'teki sayaç senaryosu.

---

## E. Editörde kalanlar (KP8) — hepsi ölçüm kapılı

| Kayıt | Sorun | Kanıt | Yer / kaynak | Öneri |
|---|---|---|---|---|
| K-27 | Tuş başına ~106 kurulum / ~76 dizilme; ilk odakta ~210 `Focus` kurulumu; Gboard geri sil ~25 `InkResponse` kurduruyor | TEST (S50) | `akicilik.md:155` "Kalan (çerçeve)"; `items_editor.dart:1964` (`shrinkWrap` kök nedeni) | Satırlardaki `InkResponse`'ları `GestureDetector` + `Semantics` yap (kalıp `editor.md:207`); `shrinkWrap`'i kaldırmak ayrı, büyük iş |
| K-28 | Tek uzun paragrafta `findLinks` + `_scanPlainness` her dizilimde tüm paragrafı tarıyor (not açmada LAYOUT'un %24'ü) | CİHAZ (P55) | `akicilik.md:126`; `text_wrap_controller.dart:747–770` | Önbelleği paragraf içi dilime böl ya da metin değişmediyse sonucu sakla |
| K-29 | Uzun listede açılıştan 500 ms sonra kare başına ≈ 480 kurulum (`_growBudget`); erken dokunuş klavye açılışına denk gelir | TEST | `akicilik.md:101` | Büyümeyi klavye/odak hareketi bitene kadar beklet (`_keyboardMoving` kalıbı) |
| K-30 | Üst çubuğun `LayoutBuilder`'ı altındaki her `setState` çubuğu dizime işaretliyor | TEST | `akicilik.md:101` | Çubuğu sabit örnek yap; altındaki durumları T3'e taşı |
| K-31 | Seç kipinde ve tutamaçlı kipte (tablet/web) madde işaretlemek 23 satırı kuruyor | TEST (S3/S4) | `akicilik.md:129, 137` | `SliverReorderableList` çatallaması gerekir → kullanıcı kararı |
| K-32 | Sabit ekli notta klavye geçiş karesi ~200 kurulum: `PinnedMediaPane` yeni örnekle kuruluyor | TEST (S17) | `akicilik.md:118` | Medya alt ağacını önbelleğe al (T6) |
| K-33 | Çizgi tepsisinin `AnimatedSize`'ı gövdeyi 14 karede diziyor | TEST (S44) | `format_bar.dart:634`; `editor.md:187` | T4 |
| K-34 | Çizgi seçimi başına 1 kök kurulumu (`setDividerOf` → `_update`) | TEST (S44) | `editor.md:187` | T3 (`NoteSlice`) |
| K-35 | Ses kaydı hapının `AnimatedSize`'ı; testte kayıt eklentisi olmadığı için kanıt üretilemedi | ADAY | `note_editor_screen.dart:4417` | Eklentiyi sahteleyen test kapısı yaz (`DeviceSpeech.debugAvailable` kalıbı), sonra ölç |
| K-36 | Biçim paneli gövde boy karesi 2 (0 için panel içeriğin üstünde yüzmeli) | TEST (S9) | `akicilik.md:137` | Tasarım kararı gerekir → dokunma |

---

## F. Açılış, menü, geçiş, bildirim (KP2 ve ölçüm kapılılar)

**K-37 — Beliriş animasyonları alt ağacı her karede kuruyor (`KOD`, P1).** Kalıp:
`TweenAnimationBuilder` → `builder` içinde `Opacity(opacity: t, child: child)`. `Opacity` ara
değerlerde ek katman (saveLayer) açar; ağır kareye denk gelince yarım açılma görünür (ses kartında
ölçüldü: 20 karenin 13'ünde kart eksik, `akicilik.md:152`).

| Yer | Kullanım |
|---|---|
| `lib/core/widgets/pop_in.dart:46–51` | `PopIn(` 6 yerde |
| `lib/core/widgets/scale_settle.dart:99–103` | `ScaleSettle(` 3 yerde |
| `lib/core/widgets/customize_board.dart:211–215` | düzen panosu |
| `lib/features/notes/presentation/quick_add_fab.dart:360–364` | "+" düğmesi |
| `lib/features/notes/presentation/editor/note_image_caption.dart:153–158` | görsel açıklaması |

Düzeltme: T5 — tek `AnimationController`, `FadeTransition` + `ScaleTransition`; denetleyici
State'te bir kez. Animasyonları kaldır erişilebilirlik ayarı (`AppMotion.of`) korunur.
**Kanıt:** widget testi: animasyon boyunca çocuğun `build` sayısı 1 (bugün kare sayısı kadar değil,
ama `Opacity` render nesnesi her karede boyanır; `debugNeedsPaint` ile katman sayımı).

**K-38 — Saniyelerce süren `TweenAnimationBuilder` geri sayımları (`KOD`, P1).** "Bildirim varken
yazarken kasma" bulgusunun kökü buydu ve `app_notice.dart`'ta `SteppedCountdown` ile düzeltildi
(`editor.md:208`). Aynı kalıp şuralarda duruyor:

| Yer | Etki |
|---|---|
| `lib/core/widgets/undo_snackbar.dart:197` | "Geri al" çubuğu (28 çağrı yeri). Süre boyunca **her karede** `FractionallySizedBox(widthFactor)` → çubuğun dizilimi yenilenir |
| `lib/core/widgets/countdown_bar.dart:21` | `CountdownBar(` 2 yerde; her karede `ClipRRect` + `LinearProgressIndicator` kurulur |
| `lib/core/widgets/hold_progress_ring.dart:40` | basılı tutma halkası (kısa) |
| `lib/features/notes/presentation/editor/note_editor_parts.dart:407` (+ `Opacity` :435) | yazarken gizlenen çubuk |
| `format_bar.dart:1071, 1125` · `items_editor_row.dart:452` · `pdf_page_column.dart:200` · `view_mode_switch.dart:323` · `split_shell.dart:533` · `ai_hub_screen.dart:494, 680` · `keyboard_snap.dart:1102` | kısa geçişler; ölç, kare başına kurulum > 5 ise düzelt |

Düzeltme: ilk ikisi `SteppedCountdown` ile değiştirilir (aynı görünüm, saniyede 8 adım, yalnız
boyama). **Kanıt:** widget testi — geri sayım sürerken 10 kare boyunca kurulum 0, dizilme 0.

**Ölçüm kapılı, önce profil (kod yazmadan):**

| Kayıt | Sorun | Kanıt | Kaynak | İlk adım |
|---|---|---|---|---|
| K-39 | Menü (kart ⋮, "+") açılışında en kötü kare 40,9 ms | CİHAZ (altın taban) | `altin_taban.json`, S37 | `vmsvc.py` ile menü evresinde hangi widget pahalı; `ActionMenu` her bölümü `LayoutBuilder` + `Wrap` ile kuruyor |
| K-40 | "+" paneli `SingleChildScrollView(reverse: true)`: bütün gruplar açılışta kurulu | ADAY | `action_menu_sheet.dart` | Açılış karesi kurulum sayısı (bütçe S37'ye "+" paneli satırı) |
| K-41 | Şablon/Akıllı liste dokunuşundan sonra 247 ms donma (k1 60,25 s) | CİHAZ (video) | `kullanici_video` §3 | S49'a "açılış ilk karesi" ölçümü ekle; eski şablon levhasında ilk kare ~2400 kurulum, 74 çip idi |
| K-42 | Soğuk açılışta ilk veri karesi 160–228 ms (kart metin dizimi) | CİHAZ (P55) | `akicilik.md:126` | `prof_cold.py`; S24 ilk kare 927 kurulum |
| K-43 | Ana ekran: bölüm geçişinde en ağır kare 2282 kurulum; pay genişleyince tek karede 413–668; kaydırmada karelerin %2,3–3,3'ü > 16 ms; aramada harf başına 24 kart | TEST + CİHAZ | `akicilik.md:111, 115, 134` | Resmî kabul yazılmamış (PLAN (C) "Kaydırma kabulü") |
| K-44 | Not açmada en uzun kare 61 ms (LAYOUT 58,7) | CİHAZ (P55) | `akicilik.md:126` | K-28 ile birlikte |
| K-45 | Ana ekran sekme/filtre geçişinde 85–86 ms kare | CİHAZ (video) | `kullanici_video` §3 | `ab_hepsi.py` `klasor` evresi + S23 |
| K-46 | Not kapanış karesi 523 kurulum | TEST (S19) | `akicilik.md:115` | `vmsvc.py` |

---

## G. Statik taramadan çıkan diğer kayıtlar (KP6, KP9)

**K-47 — Tembel olmayan listeler (`KOD`/`ADAY`, P2).** `ListView(children: …)` bütün öğeleri hemen
kurar. Öğe sayısı SINIRSIZ olanlar önce:

| Öncelik | Yerler |
|---|---|
| P1 (sınırsız) | `ai_chat_screen.dart:394, 700` (mesajlar) · `gmail_screen.dart:213, 328, 1118, 1498` · `tasks_screen.dart:298, 329` · `spell_learned_screen.dart:65` (600 düzeltmeye kadar; `build`'de 2 sıralama :57) · `trash_analysis_sheet.dart:224` · `note_link_ui.dart:94` (tüm notlar) |
| P2 (onlarca öğe) | `settings_appearance.dart:138, 881` · `friends_screen.dart:651` · `note_search_sheet.dart:319` · `study_cards_screen.dart:193` · `note_history_sheet.dart:68` (30 sürüm) · `filter_sheet.dart:267` · `archive_insights_sheet.dart:196` · `bubble_dock.dart:742, 795, 948` · `pdf_page_box.dart:1546` · `calendar_screen.dart:1272` |
| P3 (kısa, sabit) | `ai_hub_screen.dart:274` · `ai_text_result.dart:69` · `routines_screen.dart:67` · `dashboard_shelf.dart:234` · `embed_sheet.dart:165` · `note_editor_actions.dart:595` · `quick_row_editor.dart:197` · `note_theme_sheet.dart:190` · `pdf_export_screen.dart:520` · `scan_review_screen.dart:476` · `template_editor_screen.dart:210` · `area_actions.dart:156` · `customize_hub.dart:182` · `personalize_screen.dart:59` · `premium_screen.dart:43` · `privacy_screen.dart:29` · `settings_screen.dart:845` · `settings_ai.dart:566` · `settings_area.dart:583` |

`items_editor.dart:2317, 2351` bilinçli (S50 `_slotCache`); dokunma. Düzeltme: T10.
`shrinkWrap: true` olan 13 yer Ek C-4'te.

**K-48 — `build` içinde sıralama/süzme/RegExp (`KOD`, P2).** Her kurulumda yeniden çalışır;
klavye karesinde kurulan levhalarda (bölüm A) yük katlanır.
`calendar_screen.dart:1400` · `note_calendar_links.dart:142` · `tasks_screen.dart:180` ·
`folders_screen.dart:320` · `attach_sheet.dart:66` · `spell_learned_screen.dart:57` ·
`note_link_ui.dart:61` · `note_target_picker.dart:46` · `trash_screen.dart:127` ·
`guide_screen.dart:257` · `settings_screen.dart:211` · `quick_list_screen.dart:519` (RegExp) ·
`trash_analysis_sheet.dart:471` (RegExp) · `privacy_screen.dart:15` (RegExp). Düzeltme: T9.

**K-49 — `IntrinsicHeight` / `IntrinsicWidth` (`ADAY`, P3).** Alt ağacı iki kez dizer.
`app_frame.dart:619` · `ai_sheet.dart:1124` · `account_sheet.dart:161` · `ai_hub_screen.dart:552`
· `settings_area.dart:1074` · `calendar_screen.dart:1546` · `dashboard_widgets.dart:1485` ·
`view_mode_switch.dart:220`. Yalnız liste içinde tekrar edenler önemli: önce
`settings_area.dart:1074` ve `dashboard_widgets.dart:1485`'e bak.

**K-50 — Ek katman açan boyama (`ADAY`, P3).** `ShaderMask`: `share_sheet.dart:539`,
`trash_screen.dart:626` (liste içindeyse öğe başına katman). Sabit `Opacity` (0 < x < 1):
`ai_sheet.dart:1045, 1074` · `ai_hub_screen.dart:973` · `account_required.dart:300` ·
`calendar_views.dart:309, 475` · `dashboard_widgets.dart:291, 1209` ·
`dashboard_background_sheet.dart:183` · `drag_trash_target.dart:290` ·
`note_editor_appearance.dart:237` · `share_sheet.dart:409` · `note_images.dart:670, 1978` ·
`pinned_media_pane.dart:1197` · `note_editor_parts.dart:435`. Düzeltme: mümkünse rengin alfası
(metin/simge) ya da görselde `color` + `colorBlendMode`/`opacity:` parametresi. Kaydırılan liste
içindekiler önce: `calendar_views.dart:475`, `dashboard_widgets.dart:1209`.

**K-51 — Tam boy görsel çözme (`KOD`, P3).** Büyük dosyaların çoğu `cacheWidth` ile doğru çözülüyor
(tarandı). Kalanlar: `viewers/area_actions.dart:67, 163` (`Image.memory(png)` tam boy) ve
`account_identity_card.dart:121` (profil fotoğrafı, küçük). Düzeltme: `decodeWidthBucket`.

**K-52 — Ana iş parçacığında eşzamanlı dosya okuma (`ADAY`, P2).**
`local_notes_store.dart` (`existsSync` + `readAsStringSync`: yerel notlar açılışta) ·
`attachment_text_index.dart` (`readAsBytesSync`) · `image_prepare_screen.dart`,
`scan/scan_enhance.dart` (`readAsBytesSync`/`writeAsBytesSync`; `runHeavy` içinde mi, kontrol et) ·
`antalia_engine.dart` (`readAsStringSync`). Dosya büyükse kare düşürür. Düzeltme: `runHeavy`
içinde ya da eşzamansız okuma. **Önce** çağrının ana iş parçacığında olduğunu doğrula.

**K-53 — Sürekli çalışan animasyon ve zamanlayıcılar (`ADAY`, P2; pil + kare).**
`.repeat(`: `skeleton.dart:30` · `dashboard_widgets.dart:696` (odak nabzı; durma koşulu :684–688) ·
`bubble_pin.dart:639` · `listening_visuals.dart:80` · `voice_note_recorder.dart:362, 369`.
`Timer.periodic`: `prefs_sync.dart:221` (20 sn, K-25) · `note_presence.dart:72` (25 sn; her
vuruşta `setState` :74 ve Firestore yazımı) · `tasks_screen.dart:45`, `calendar_screen.dart:147`
(Google eşitleme) · `youtube_viewer.dart:348` (1 sn) · `app_update.dart` (30 dk).
**Doğrulanacak:** `NotePresenceIndicator` paylaşılMAYAN notta nabız başlatıyor mu
(`note_presence.dart:115–125` `shared` hesabı var; `_start` yalnız `shared` iken mi çağrılıyor).
Başlatıyorsa tek kişilik notta 25 sn'de bir boşa yazma + kurulum → hem kasma hem maliyet.

**K-54 — Kalın yazı tipi çalışma anında internetten iniyor olabilir (`KOD` + çıkarım, P1, KP9).**
Pakette 34 Google yazı tipi dosyası var: aile başına yalnız Regular + Medium
(`assets/google_fonts/`, kalın/yarı kalın 0 dosya). `GoogleFonts.config.allowRuntimeFetching` kodda
hiç ayarlanmıyor (varsayılan açık). Kodda 47 dosyada 80 yerde `FontWeight.w600–w900` kullanılıyor.
Not yazı tipi bir Google ailesiyse (ör. Lora) ve metin kalınsa paket o ağırlığı bulamaz →
**ağdan indirir** → gelince motor "yazı tipleri değişti" der, ekrandaki BÜTÜN metin yeniden dizilir
(aynı kök neden `note_fonts.dart:156–160`'ta belgelenmiş). Çevrimdışıyken sahte kalın çizilir.
Uygulamanın kendi yazı tipi (PT Sans: Regular/Bold/Italic pakette) etkilenmez.
**Doğrulama:** `main`'de geçici `GoogleFonts.config.allowRuntimeFetching = false`; Lora seçili,
kalın metinli notu aç; günlükte "font not found … runtime fetching disabled" çıkıyorsa doğrudur.
**Düzeltme (birini seç, kullanıcı kararı gerekmez):** (a) çalışma anı indirmeyi kapat + 19 ailenin
Bold dosyasını pakete ekle (~+2,5 MB); (b) değişken yazı tipi dosyaları (aile başına tek dosya, tüm
ağırlıklar). (a) daha az riskli. Bekçi: `allowRuntimeFetching == false` ve "katalogdaki her aile
için w700 dosyası var" testi.

**K-55 — Kabukta `MediaQuery.of` (`ADAY`, P3).** `app.dart:97` (yazı ölçeği sarmalayıcısı),
`app_frame.dart:352` (geniş ekran çerçevesi), `note_open_route.dart:486, 497`,
`customizable.dart:393`, `freeze_when_hidden.dart:132`, `bubble_pin.dart:111`. Hepsi MediaQuery'yi
kopyalayıp yeniden veren sarmalayıcı; mandalda (`jank_patterns_guard_test.dart` `_mediaQueryLatch`).
Klavye karesinde kendileri kurulur ve yeni veri nesnesi yayar. Tablette klavye karesi başına
kurulum say; `app_frame.dart:352` altındaki `LayoutBuilder` her karede çalışıyorsa veriyi
`size`/`displayFeatures` dışında değişmeyecek biçimde böl.

**K-56 — Ana ekran arama çubuğu klavye karesinde kuruluyor (`KOD`, P3).**
`dashboard_screen.dart:1801`: okuma bilerek yalnız `AppBar`'a daraltılmış (eskiden panonun tamamı
15–30 kez kuruluyordu). Kalan: `AppBar` kare başına 1 kurulum. Bekçide izinli.

**K-57 — `onChanged` → `setState`: tuş başına bütün form kuruluyor (`KOD`, P2).** 46 yer (Ek C-5).
Önemliler: `note_search_sheet.dart:269` (K-02) · `calculator_sheet.dart:116` ·
`settings_ai.dart:278, 544, 560` · `settings_appearance.dart:129` · `note_link_ui.dart:89` ·
`settings_screen.dart:1193` · `guide_screen.dart:300` · `gmail_screen.dart:1191` ·
`event_editor.dart:513` · `task_editor.dart:350, 357, 400` · `share_target_sheet.dart:223, 322`.
Düzeltme: T3 (alan kendi `ValueNotifier`'ını günceller; yalnız sonuca bağlı parça dinler).

**K-58 — Kurulumda yeniden oluşturulan Future/Stream (`KOD`, P3).**
`note_history_sheet.dart:28`: `repo.listVersions(noteId)` levha `builder`'ında çağrılıyor →
levha her yeniden kurulduğunda (ekran dönmesi vb.) Firestore'dan 30 sürüm yeniden okunur (kasma +
okuma maliyeti). `audio_card_box.dart:372, 438`: `createPositionStream()` her kurulumda yeni akış.
`privacy_screen.dart:20`: her kurulumda dosya okuma. Düzeltme: Future/Stream State'te bir kez.

---

## H. Hızlı ekle ve hızlı/akıllı liste yüzeyleri (ölçülmedi)

| Kayıt | Sorun | Kanıt | Yer | Yapılacak |
|---|---|---|---|---|
| K-64 | Hızlı ekle için bütçe senaryosu yok; cihazda hiç ölçülmedi | — | `quick_drop_sheet.dart` | `perf_budget_test`'e senaryo: ⚡ → levha açık → 6 klavye karesi → 3 harf → Ekle (kurulum/dizilme). `ab_hepsi.py`'ye `hizli_ekle` evresi |
| K-65 | Açılışta klavye ve mikrofon aynı anda açılıyor olabilir (ikisi de kanal çağrısı) | ADAY | varsayılanlar `quick_entry_memory.dart:159–163`; `quick_drop_sheet.dart:241` | Sıra: levha animasyonu bitsin → ya klavye ya mikrofon. Önce aynı karede mi, ölç |
| K-66 | Aday notlar `initState`'te süzülüp sıralanıyor (not sayısıyla büyür) | KOD | `quick_drop_sheet.dart:236`, `quickDropCandidates` :53–78 | İlk karede son 6 hedef; kalan bir kare sonra |
| K-67 | `SheetInsetPadding` alt payı her klavye karesinde yeniliyor (içerik kurulmuyor, dizilim yenileniyor) | ADAY | `quick_drop_sheet.dart:156` | T2'deki tek adımda oturma kalıbı; önce S-senaryosuyla dizilme say |
| K-68 | Hızlı listede çip başına `has()` tüm satırları tarıyor; `build`'de `RegExp` | ADAY | `quick_list_screen.dart:519` çevresi | Küme (Set) + sabit RegExp |
| K-69 | AI yedeğinde 5 sn'ye kadar sessiz bekleme ("dondu" hissi; kasma değil) | KOD | `quick_drop_sheet.dart:341` | 300 ms sonra ince ilerleme + "Ben seçeyim" |

---

## İ. Cihazda ölçülecekler ve ölçüm aracı açıkları (KP7)

Bunlar kod işi değil; yapılmadan yukarıdaki `ADAY` kayıtlarının çoğu kapatılamaz.

| Kayıt | İş | Çıktı |
|---|---|---|
| K-59 | **RAM tabanı yok.** `adb shell dumpsys meminfo dev.kaimau.notlar.olcum` beş durumda: boşta ana ekran, editör, PDF, kalem, YouTube | `docs/perf/ram_taban.md` tablo. Şüpheliler: WebView, pdfium sayfa önbelleği, 50 MB görsel önbelleği (`image_cache_budget.dart`), ONNX oturumu |
| K-60 | **Isınma etkisi.** Kapanış zikzağının sıklığı videolar arasında artıyor (%43 → %72 → %83) | Aynı notta soğuk (< 34 °C) ve 10 dk kullanım sonrası `panel_kayit.py`; fark varsa termal kısma |
| K-61 | **Ölçüm aracı kör noktaları.** `ab_hepsi.py`'de `liste` evresi kare yakalamıyor, `acilis` 2 kare görüyor, `sablon`/`bicim`/`kalem`/`duzen` evreleri hiç koşmadı (`OTOMASYON.md` toplu-2 notu) | Evreler çalışır hâle gelir; ölçülemeyen yüzey = görünmeyen kasma. Ayarlar, hesap levhası, hızlı ekle, akıllı liste için evre yok |
| K-62 | **Gerçek kullanım verisi yok.** Yalnız profil/beta derlemesinde `FrameTiming` ile ekran başına p50/p90/p99 ve "16 ms üstü kare %" toplayan sayaç + Ayarlar → Hakkında'da gizli "Hız günlüğü" | Kullanıcı "şurada kastı" dediğinde bakılacak sayı. Yayın derlemesinde kapalı |
| K-63 | **Büyük hesapla ölçüm yok.** Bütün ölçümler ~400 notla | `make_dataset.py` ile 1000 ve 3000 notlu sentetik hesap; `ab_hepsi.py` + `prof_save.py`. K-22/K-23'ün gerçek boyutu burada çıkar |
| K-20, K-21 | Bölüm C | — |

---

## Kapanışlar (2026-11-17, dal ccr-e44d1883-4uhqkg; cihaz: ölçülmedi)
- K-01…K-11 — KAPANDI: `SheetInsetPadding`; S53 arama 1152/210 → 294/84, seçici 4758/270 → 630/150,
  AI sonuç 1512/249 → 294/153 (`levha_klavye_2_test`); diğer levhalar mekanik aynı düzeltme, ayrıca
  ölçülmedi. K-12 — KAPANDI: `jank_patterns_guard_test` K-12 grubu.
- K-38 — KISMEN: `undo_snackbar`, `countdown_bar` → `SteppedCountdown`; kısa geçişler açık (PLAN T9).
- K-37 — AÇIK: bilerek dokunulmadı (`child` yeniden kurulmuyor; ölçmeden kazanç belirsiz).
- K-24 — KISMEN: araç güncellemesi ön planda yok. Hatırlatıcı: not başına imza zaten var, kanal
  çağrısı yok → dokunulmadı.
- K-25 — KAPANDI (zamanlayıcı kaldı, değişmeyen tur hemen döner). K-53 — TEMİZ (nabız yalnız
  paylaşılan notta) + arka planda durma eklendi. K-26 — AÇIK (ucuz, ölçülmedi).

## Ek A — Kuyruk'a hazır paket satırları (kopyala; ben eklemedim)

```
| KP1 | Klavye açıkken levhalar: 11 levhada T1 + viewInsets bekçisi | sonnet | docs/perf/kasma_envanteri.md §A (K-01…K-12) | A/B (kb) | evet | bekliyor |
| KP7 | Cihaz ölçüm turu: panel kipi k/c, 60 Hz ayrımı, RAM tabanı, ısınma, ab_hepsi kör evreleri, 1000/3000 not | sonnet + telefon | kasma_envanteri §C, §İ (K-20, K-21, K-59…K-63) | evet | hayır | bekliyor |
| KP2 | Geri sayım ve beliriş animasyonları (SteppedCountdown, FadeTransition) | sonnet | kasma_envanteri §F (K-37, K-38) | A/B (menu, yaz) | evet | bekliyor |
| KP3 | Yazarken arka plan işleri: araç güncellemesi paused'a, hatırlatıcı imzası, ayar eşitleme zamanlayıcısı, geri bağlantı dizini | opus | kasma_envanteri §D (K-24, K-25, K-26) | A/B (yaz, kb) | evet | bekliyor |
| KP9 | Yazı tipi çalışma anı indirmesi: doğrula, kapat, kalınları pakete koy, bekçi | sonnet | kasma_envanteri §G K-54 | hayır | evet | bekliyor |
| KP5 | Not akışı yankısı: sağlayıcı sayacı senaryosu + en pahalı 3 türetilmişi dilime çevir (veri göçü YOK) | opus | kasma_envanteri §D (K-22a, K-23) | A/B + 1000 not | evet | bekliyor |
| KP4 | Klavye açıkken sayfa iskeleti: 17 ekranı ölç, kötü çıkanlara T2 | sonnet (ölçüm) → opus | kasma_envanteri §B (K-13…K-19) | gerekirse | evet | bekliyor |
| KP6 | Tembel liste + build'de hesap + onChanged setState (ekran başına) | sonnet | kasma_envanteri §G (K-47, K-48, K-57, K-58) | hayır | evet | bekliyor |
| KP8 | Editörde kalanlar (ölçüm kapılı) | opus | kasma_envanteri §E (K-27…K-36) | A/B | evet | bekliyor |
```

## Ek B — Kayıt kapatma biçimi

İşçi bir kaydı bitirince bu dosyada kaydın satırına şunu ekler (silmez):
`— KAPANDI <tarih> <dal> <commit>: önce <sayı> → sonra <sayı> (<test adı>); cihaz: <ölçüldü /
ölçülmedi>`. `ADAY` temiz çıktıysa: `— TEMİZ <tarih>: <ölçüm ve sayı>`.

## Ek C — Ham tarama listeleri (f9d0b5a8)

Betik: `lib/` altındaki her `.dart` dosyası (üretilmiş çeviri hariç), yorum satırları ayıklanarak.

**C-1. `viewInsetsOf(` / `.viewInsets` / `MediaQuery.of(` — 37 satır**
`app/note_open_route.dart:486, 497` · `app/app_frame.dart:352` · `app/app.dart:97, 281` ·
`folders/…/folder_chat_screen.dart:327` · `settings/…/settings_ai.dart:528` ·
`settings/…/settings_appearance.dart:119` · `ai/…/ai_sheet.dart:575` ·
`core/widgets/app_notice.dart:452` · `core/widgets/keyboard_snap.dart:121, 122, 154, 222, 228, 445, 964`
· `core/widgets/customizable.dart:393` · `core/widgets/freeze_when_hidden.dart:132` ·
`notes/…/capture_mode_sheet.dart:97` · `core/widgets/sheet_keyboard.dart:15` ·
`core/widgets/undo_snackbar.dart:45` · `friends/…/friends_screen.dart:610` ·
`notes/…/file_use_sheet.dart:202` · `notes/…/dashboard_screen.dart:1801` ·
`notes/…/editor/attachment_actions.dart:292` · `notes/…/editor/ai_result_sheet.dart:100` ·
`notes/…/note_link_ui.dart:69` · `notes/…/editor/calculator_sheet.dart:106` ·
`notes/…/note_template_sheet.dart:71` · `notes/…/place_reminder_sheet.dart:41` ·
`notes/…/share_target_sheet.dart:127` · `notes/…/editor/note_editor_screen.dart:1631, 2302` ·
`notes/…/voice_capture_sheet.dart:795` · `notes/…/viewers/bubble_dock.dart:1213` ·
`notes/…/viewers/bubble_reveal.dart:146` · `notes/…/editor/note_search_sheet.dart:257` ·
`notes/…/viewers/bubble_pin.dart:111`

**C-2. Boy animasyonu (`AnimatedSize`, `AnimatedContainer`, `AnimatedSwitcher`, `SizeTransition`,
…) — 44 satır.** Editör gövdesiyle aynı sütunda olanlar kasma listesi md. 6'ya girer:
`format_bar.dart:634` (K-33) · `note_editor_screen.dart:4417` (K-35) ·
`items_editor_row.dart:175` · `items_editor_widgets.dart:551` (`_DividerReveal`, ölçüldü: temiz).
Diğerleri (ölç, boy değiştiriyorsa T4): `split_shell.dart:716, 841` · `app_notice.dart:226` ·
`theme_picker.dart:383` · `guide_screen.dart:421` · `settings_screen.dart:951, 972, 1160` ·
`settings_appearance.dart:662` · `settings_area.dart:254` · `expand_reveal.dart:103` ·
`color_dot.dart:51` · `tasks_screen.dart:252` · `calendar_screen.dart:555, 770` ·
`dashboard_widgets.dart:20, 229, 578, 1211` · `note_theme_sheet.dart:306, 385` ·
`note_template_sheet.dart:271, 589` · `dashboard_screen.dart:1982` · `divider_kind_picker.dart:72`
· `filter_sheet.dart:151` · `share_target_sheet.dart:229` · `share_sheet.dart:527` ·
`voice_capture_sheet.dart:766` · `audio_card_box.dart:292, 312` · `notebook_paper.dart:726` ·
`note_editor_media_view.dart:1127` · `pen_tray.dart:737, 1327, 1795` ·
`stylus_toggle.dart:64, 154` · `view_mode_switch.dart:225`

**C-3. `TweenAnimationBuilder` / `Opacity(` / katman açanlar** — K-37, K-38, K-50'de sayıldı
(57 satır; tam liste için desen:
`\bOpacity\(|TweenAnimationBuilder|BackdropFilter\(|ShaderMask\(|IntrinsicHeight\(|IntrinsicWidth\(`).
`BackdropFilter`, `ImageFiltered`, `ColorFiltered`, `UniqueKey()` ve "her kurulumda `GlobalKey()`"
**0 sonuç**.

**C-4. `shrinkWrap: true` — 13 yer.** `settings_voice.dart:667` · `calendar_screen.dart:1273` ·
`settings_appearance.dart:882` · `settings_ai.dart:567` · `embed_sheet.dart:166` ·
`study_cards_screen.dart:194` · `template_editor_screen.dart:411` ·
`note_editor_actions.dart:596` · `note_editor_screen.dart:4064, 4128` · `note_link_ui.dart:94` ·
`note_history_sheet.dart:69` · `pdf_page_box.dart:1547`

**C-5. `onChanged` → `setState` — 46 yer.** `color_palette.dart:156, 165, 175` ·
`ai_hub_screen.dart:106` · `event_editor.dart:513` · `routines_screen.dart:453` ·
`task_editor.dart:350, 357, 400` · `folder_sheets.dart:153` · `gmail_screen.dart:1191` ·
`dashboard_widgets.dart:836` · `bubbles_overview.dart:177` · `calculator_sheet.dart:116` ·
`format_bar.dart:563` · `note_editor_parts.dart:92` · `note_search_sheet.dart:269` ·
`pdf_page_box.dart:1611` · `item_divider_style.dart:300` · `note_link_ui.dart:89` ·
`note_template_sheet.dart:548, 1238` · `pdf_export_screen.dart:405, 434, 450, 551, 558` ·
`place_reminder_sheet.dart:330` · `reminder_repeat_ui.dart:82` · `reminder_sheet.dart:335` ·
`share_target_sheet.dart:223, 322` · `ink_layer.dart:2518, 2979` · `guide_screen.dart:300` ·
`settings_screen.dart:1193` · `settings_ai.dart:278, 544, 560` · `settings_appearance.dart:129` ·
`settings_switches.dart:139` · `settings_voice.dart:55, 107, 172` · `settings_writing.dart:236`

**C-6. `setState` yoğunluğu (ilk 12).** `items_editor.dart` 27 · `note_images.dart` 26 ·
`pdf_select_layer.dart` 25 · `scan_review_screen.dart` 21 · `pdf_page_box.dart` 19 ·
`gmail_screen.dart` 19 · `voice_capture_sheet.dart` 18 · `note_editor_screen.dart` 17 ·
`calendar_screen.dart` 16 · `listen_screen.dart` 16 · `pinned_media_pane.dart` 15 ·
`settings_voice.dart` 14

**C-7. Platform kanalı çağıran dosyalar (`invokeMethod`).** `permissions_service.dart` 7 ·
`place_reminders.dart` 4 · `app_update.dart` 4 · `video_frame.dart` 3 · `device_speech.dart` 3 ·
`pip.dart` 3 · `display_rate.dart` 3 · `google_scope_auth.dart` 2 · `hard_keyboard.dart` 2 ·
`gms.dart` 2 · tekil: `backup_ui`, `app_lock`, `note_editor_screen`, `note_shortcut`,
`document_scan`, `attachment_save`, `keyboard_snap`, `image_cache_budget`, `doc_picker`. Eklenti
üzerinden gidenler ayrıca: `home_widget` (K-24), bildirim eklentisi, `shared_preferences` yazımları.

**C-8. Temiz çıkanlar (yeniden arama).** Elle `Hero(` yok (test yasaklıyor) · `family` sağlayıcıların
hepsi `autoDispose` (tek istisna `providerApiKeyProvider`, anahtarı sınırlı enum) ·
`shouldRepaint => true` yalnız `lock/pattern_pad.dart:136` (kilit ekranı, küçük) ·
`Image.file/network` çağrılarının `cacheWidth`'i var (K-51 dışında) · `localFileExists` önbellekli.
