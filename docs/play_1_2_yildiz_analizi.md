# Google Play 1-2 Yıldız Riskleri, Politika Engelleri ve 4-5 Yıldız Planı (2026-11-26)

Bu belge, **Notlar** (`dev.kaimau.notlar`) uygulamasının Google Play yayını öncesinde 1-2 yıldız getirebilecek kritik hataları, Play Store ret nedenlerini ve düşük donanımlı cihazlardaki performans darboğazlarını tek merkezde toplamak ve Faz 1-7 düzeltme durumunu takip etmek için hazırlanmıştır.

---

## 1. Kritik 1-2 Yıldız ve Politika Ret Riskleri (Faz 1)

### 1.1 Şifreli (E2EE) Notlarda Veri Kaybı ve Bozulma [P0]
- **Boş not temizliğinin kilitli notları silmesi**: `Note.isEmpty` (`locked` ve `e2ee` alanlarını kontrol etmeden) `body`/`items` boş göründüğünde kilitli notu "boş" sayıyordu; `NotesRepository.cleanupEmptyNotes` ve `NoteEditorScreen.dispose` şifreli notu kalıcı olarak silebiliyordu.
- **Şifre/PIN/Desen değişikliğinde eski notların kaybolması**: `createNoteLock` her değişimde yeni salt üretiyor ancak mevcut kilitli notlar eski anahtarla şifreli kaldığı için şifre değiştirildikten sonra eski notlar açılamaz hâle geliyordu; "Şifremi unuttum" akışı da veri kaybı uyarısı göstermeden şifreli içeriği yetim bırakıyordu.
- **Cihaz kilidi ve biyometrik anahtar tutarsızlığı**: Varsayılan `NoteLockMethod.device` seçildiğinde `ensureDeviceKey()` çağrılmadığı için kilitlenen notlar açık metin kalabiliyordu; PIN/Parola seçili hesapta İkinci Cihaz üzerinden biyometrik açılış `ensureDeviceKey()` çağırıp yanlış rastgele anahtar üretebiliyordu.
- **Kilit açma ve kart menüsünde `'e2ee'` kalıntısı**: `Note.copyWith` ve `updateNote` kilidi açılan nottan `'e2ee'` alanını silmediği için bir sonraki senkronizasyonda şifreli eski veri geri gelebiliyordu; kart menüsündeki `updateFields({'locked': ...})` şifreleme/çözme yapmadan bayrağı değiştiriyordu.
- **`textPages` / `pageNotes` ve sürüm geçmişi sızıntısı**: Kilitli çok sayfalı notlarda `textPages` ve `pageNotes` E2EE zarfına girmiyordu; `_maybeVersion` kilitli not içeriğini sürüm alt koleksiyonuna düz metin yazabiliyordu.
- **Yedekleme, dışa aktarma, çoğaltma ve istatistik**: `backup_ui.dart` (tam JSON ve Markdown ZIP) ve `note_actions_sheet.dart`, bellek önbelleğindeki çözülmemiş kilitli notları boş `body`/`items` ile okuyabiliyordu.

### 1.2 Play Yapısı Onay Kilitlenmesi, Faturalama ve Kota Açıkları [P0]
- **`NOTLAR_PLAY=true` ile Akıllı Kararlar'ın tamamen çalışmaması**: Play yapısında `aiConsentProvider` varsayılanı `false` iken hiçbir ekranda `.accept()` çağrısı bulunmuyordu; `DecisionService` sessizce `null` dönüyordu.
- **+1.000 Karar Paketi ve Pro Kapısı tutarsızlığı**: Ücretsiz kullanıcı `ProScreen` üzerinden `+1.000` paketini görebilirken `EntitlementGate.allows(ProFeature.smartDecisions, ...)` yalnızca `tier >= lifetime` kontrolü yapıyordu; satın alma sonrası `_pausedUntil` sıfırlanmıyor, `recover()` zaman aşımı bulunmuyordu ve `buyConsumable` doğrulama akışında tüketim sonrası doğrulama riski vardı.
- **Bulut faturalama uç noktaları (`cloudflare/src/billing.ts`, `decisions.ts`)**: `decisions.ts` yalnızca string `input` kabul ederken istemci mesaj dizisi gönderiyordu; `consumeProduct` yanıt kontrolü, 4096 token sınırı ve RTDN paket iadesi düşümü eksikti.
- **BYOK ve Çapraz Uygulama Kartı**: Ücretsiz kullanıcı BYOK anahtarı kaydedip doğrulayabiliyor ama kullanımda sessizce engelleniyordu; `CrossAppPromoCard` her iki uygulama arasında "ortak kredi" vaadi verip Play'de henüz yayımlanmamış paket adına bağlanıyordu.

### 1.3 Cloudflare Uçları, Hesap Silme ve Çevrimdışı Yetki [P0]
- **`DELETE /v1/users/me` eksikliği**: Google Play hesap silme politikası için gerekli Cloudflare kullanıcı silme ucu ve istemci çağrısı eksikti.
- **`CloudflareSyncTransport` ve çevrimdışı entitlement**: `JsonHttp` istemci enjeksiyonu, App Check başlığı, doğrudan `PUT /v1/users/me` çağrısı ve `entitlementProvider` UID bazlı kalıcı önbelleği eksikti (çevrimdışı açılışta Pro rozeti düşüyordu).
- **Paylaşım sahiplik denetimi**: `cloudflare/src/sync.ts` `handleUpsertShare` içinde sahip kontrolü sıkılaştırılmalı.

### 1.4 Mağaza Metni, Gizlilik Politikası, Giriş Ekranı ve Rehber Tutarsızlıkları [P0]
- `PRIVACY_POLICY.md` ve `web/gizlilik.html`, `STORE_LISTING.md` ve uygulamayla çelişiyor: kaldırılmış Gmail/OpenAI/Anthropic/OpenRouter/Firebase AI ifadelerini taşıyor, E2EE'yi "yok" yazıyor ve Open Food Facts API ile Google Play Faturalama bilgisini atlıyor.
- Giriş ekranı (`loginFeatureAiTitle`), ayarlar arama ipucu (`settingsSearchHint`), yardım rehberleri (`guide_tr.md`, `guide_en.md`) ve `ReminderService` hâlâ kaldırılmış Özet/Brifing ekranlarına (`/briefing`) atıf yapıyor.
- Misafir (oturum açmamış) kullanıcılar için 3+ notta yerel yedekleme / bulut senkronizasyon hatırlatması görünür değil.

---

## 2. Bozuk Kullanıcı Akışları ve Özellik Hataları (Faz 2)

- **Ses/Video Transkript çıkmazı**: `Transcripts.canTranscribe` ve dosya kullanım ekranları kaldırılmış akışlara yönlendirip `UnsupportedMediaException` hatasına düşüyor.
- **İlk 60 saniye vitrini (`starter_notes.dart`)**: Başlangıç alışveriş notu reyon id'lerini metin (`'sut'`, `'manav'`, `'firin'`) olarak yazıyor, `ShopItemMeta` yalnızca sayısal `g` kabul ettiği için tüm ürünler "Diğer" reyonuna düşüyor; `'2 lt süt'` formatı `+` dokunuşunda `'2 lt süt (3 lt)'` bozulmasına yol açıyor.
- **Mağaza Modu, Fiş OCR ve Barkod**: `StoreModeScreen` paylaşımlı liste erişimi, fiş OCR kelime sınırı ve birim fiyat bölme hataları, aktif mağazaya göre filtrelenmemiş toplam/bitir/bütçe çubuğu, barkod arama yükleme göstergesi ve tek dokunuş ekleme akışı.
- **Türkçe yazım denetimi ve dikte**: `spell_underline.dart` dil sabitleri, ortak serileştirilmiş `DefaultSpellCheckService`, `auto_spell.dart` web budama/seeding ve `dictation_tidy.dart` kip/noktalama düzeltmeleri.

---

## 3. Düşük Donanımlı Cihaz Performans ve Pil Optimizasyonları (Faz 3)

- **Bellek basıncı ve `ImageCacheBudget` tersliği**: Düşük RAM'li cihazlarda (`<=4 GB`) 500 görsel önbelleği bug'ının 3 katmanlı bütçeyle (`low` / `mid` / `high`) düzeltilmesi ve `AppServices` yaşam döngüsü çakışmasının giderilmesi (`dosya okuyucu` `memory_pressure.dart` modeli).
- **Büyük görsel & PDF OOM önleme**: `image_prepare_screen.dart` boyut okumasının `ui.ImageDescriptor` ile yapılması, `area_select` / duvar kağıdı `cacheWidth` sınırları ve düşük RAM cihazlarda `PdfPageImage` DPI tavanı.
- **Pil ve Kanal Fırtınaları**: `YouTubeViewerScreen` 1 Hz JS döngüsü ve sızıntısı, `WidgetService` soğuk başlatma IPC ve deterministik hash, `ReminderService` eşzamanlı init yarışı ve gereksiz iptal döngüleri, duraklatılmayan takvim/görev zamanlayıcıları, `NotePresenceIndicator` self-echo yeniden çizimleri, `PrefsSync`/`UploadQueue` biriktirme (debounce).
- **CPU / GPU Akıcılığı (KP1–KP9)**: `FieldValue.serverTimestamp()` kaynaklı çift `EventChannel` çözmesi, K-26 `backlinksIndexProvider`, dinamik `RegExp` kaldırma ve `TrLexicon` bitmask + artımlı tarama + tek `Path` yazım alt çizgisi, `InkController` 2.4 dp widget yeniden kurma fırtınasının ve O(N²) aktif yolun düzeltilmesi, KP2 `TweenAnimationBuilder+Opacity` yerine `FadeTransition`/`ScaleTransition`, ana iş parçacığındaki senkron dosya G/Ç çağrılarının kaldırılması.

---

## 4. Temizlik, Boyut Küçültme ve Modülerlik (Faz 4-5)

- **Faz 4 (Ölü Kod ve Paket Boyutu)**: 5 kullanılmayan dosya (`speak_button.dart`, `quiet_organize_sheet.dart`, `duplicates_sheet.dart`, `ai_result_sheet.dart`, `audio_recorder_sheet.dart`), 446+ kullanılmayan ARB anahtarı, ölü `Briefing`/`AiTask`/`SemanticSearch` kalıntıları, `flutter_displaymode` kaldırma, `decodeCommonImage` yardımcısı, Gradle `resourceConfigurations = ["tr", "en"]` ve duvar kağıdı/font alt kümeleme (yalnızca RFN olmayan 4 font).
- **Faz 5 (Büyük Dosya Bölünmesi)**: 1.400 satır üzerindeki 16 dosyanın tüm statik guard testlerini koruyarak aynı dizinli `part` dosyalarına ayrılması.

---

## 5. Durum Takip Tablosu

| Faz | Kapsam | Durum | Doğrulama Notu |
| :--- | :--- | :--- | :--- |
| Faz 0 | Git senkronizasyonu (`1af0fc93`) & baseline analyze | Tamamlandı | Başlangıç taraması ve planlama |
| Faz 1 | Play ret riskleri, E2EE veri kaybı, Consent/Billing, Cloudflare, Gizlilik | Tamamlandı | `--dart-define=NOTLAR_PLAY=true` 5 dosya (`+33 ~1`), Cloudflare (`7/7`), Functions (`37/37`) |
| Faz 2 | Ses/video transkript, başlangıç notu, Mağaza Modu, yazım/dikte | Tamamlandı | Faz 2 ve tam paket içinde geçti |
| Faz 3 | RAM/GPU/Pil/CPU & düşük donanım optimizasyonları | Tamamlandı | Faz 3 perf/bütçe testleri + `editor_leak_test`/`oturum_birikim_test` (`S51` 0 sızıntı) |
| Faz 4 | Ölü kod/ARB temizliği, `decodeCommonImage`, Android/asset küçültme | Tamamlandı | 9 ölü dosya + 480 ARB (`3087 → 2607`), 8 RFN-serbest yazı tipi alt kümelendi (`1391.3 → 635.8 KB`), 17 JPG (`2340.4 → 2317.6 KB`) |
| Faz 5 | >1.400 satırlık dosyaların modüler `part` bölünmesi | Tamamlandı | `25/25` dosya bölündü (`0` üretilmemiş dosya `>1.400` satır; `note_editor_screen.dart` `6.530 → 1.224` satır), 14 bekçi testi (`+80`) geçti |
| Faz 6 | Güvenlik, Decisions D3/D5, tasarım jetonu, test borcu, belgeler ve tam yerel kapı | Tamamlandı | `>1400L`: `0`; `flutter analyze`: `0`; tam `flutter test -j 4`: `+3849 ~7` (rutin yedeği, D3 `captureRoute`, `test_borcu` 14/14 satır kapatma ve `HardKeyboard` düzeltmeleri dahil); `NOTLAR_PLAY=true`: `+33 ~1`; `cloudflare` `7/7`, `functions` `37/37`, `rules-test` `28/28` (`37/47` kapsama) |
| Faz 7 | Profil APK (`9003`) derleme ve tablet (`dev.kaimau.notlar.olcum`) ölçümü | Tamamlandı | `app-profile.apk` (`64.055.607` bayt / `61.1 MB`); `ram_taban.py` (`26.0 °C`, çıkış `0`), `ab_hepsi.py` `17/17` evre (`26.9 → 27.6 °C`, çıkış `0`) ve `taban.py` (`27.5 → 27.7 °C`, çıkış `0`) tümüyle geçti; `logcat` `0` `flutter`/istisna satırı; kilit `BOS` |
| Faz 8 | `K-47`/`K-48`/`K-51`/`K-58`/`K-68`, `1k/3k` ölçek testi, Chrome Web+CSP, `Ctrl+/` ve `9005` tablet (dikey+yatay) | Tamamlandı (`9005` tablet kilidi `BOS`) | `scale_1000_3000_test.dart` (`4/4`), `S30`/`S49`, `trash_analysis_test` + `trash_archive_bar_test` + `shortcut_table_test` (`33/33`), `NOTLAR_PLAY=true` (`+33 ~1`), `flutter analyze` `0`, Web CSP `0` hata; `9005` dikey `--kosu 3` (`26/27 ms`), `ram_taban` `YouTube` (`375/480` MB), `tur_gez dikey/yatay`, Mağaza Kipi v2, `K-21` (`120 Hz`), `32 İki not yan yana` ve `ab_hepsi --yon yatay` doğrulandı (`logcat` `0` hata; kilit `BOS`) |

---

## 6. Faz 7 Tablet Ölçüm Özeti

- **Cihaz ve sürüm (`dev.kaimau.notlar.olcum`):** Tablet `5VLBB21A27203178`, kurulan sürüm `versionName=1.2.999`, `versionCode=9003`; final ARM64 profil APK (`C:\src\flutter\bin\flutter.bat build apk --profile --target-platform android-arm64 --build-name=1.2.999 --build-number=9003`): `build/app/outputs/flutter-apk/app-profile.apk` (`64.055.607` bayt / `61.1 MB`; `9002` artımlı derlemede `78.833.243` bayt / `75.2MB` idi).
- **RAM ölçümü (`ram_taban.py --etiket optimizasyon_9003_20261127`, `26.0 °C`, çıkış `0`):**
  - `ana ekran`: PSS `345` MB / RSS `416` MB (`Java 35`, `Native 44`, `Graphics 95`, `Code 79`)
  - `editör`: PSS `356` MB / RSS `430` MB (`Java 20`, `Native 45`, `Graphics 95`, `Code 103`)
  - `PDF`: PSS `397` MB / RSS `512` MB (`Java 20`, `Native 57`, `Graphics 95`, `Code 119`)
  - `kalem`: PSS `364` MB / RSS `479` MB (`Java 21`, `Native 45`, `Graphics 95`, `Code 96`)
  - `YouTube`: denenmedi (veri setinde YouTube'lu not yok)
- **Tam akıcılık ölçümü (`ab_hepsi.py --kosu 1 --teyit 0 --altin --etiket-a opt9003_20261127 --etiket-b opt9003_20261127`, `26.9 → 27.6 °C`, çıkış `0`, `[Kitap bilet]`):**
  - `17/17` evre eksiksiz ölçüldü (`HardKeyboard` kanca temizliği + `ab_hepsi.py` `GEO_1600`/`kb_closed`/`trim_typed` düzeltmeleri sonrası `ensure_ime[0]` ilk denemede sanal klavyeyi açtı).
  - İlk kare (ortanca): **A `26` ms / B `25` ms** (`tablet_taban` altın: `~40` ms).
  - Öne çıkan evreler (A / B UI ms, LAYOUT ms): `acilis` `139.8 / 134.6` (`122.9 / 119.0`), `liste` `2436.2 / 2362.6` (`1301.0 / 1253.0`), `menu` `107.2 / 107.2` (`21.9 / 21.3`, `0` >16 ms), `arama` `87.6 / 172.4`, `klasor` `232.0 / 236.2`, `yeni_not` `301.7 / 307.1`, `not_ac` `116.0 / 110.5`, `kb` `509.1 / 494.1` (`max_ms 10.8`, `0` >16 ms — `HardKeyboard` açık/kapalı tam IME geçişi), `yaz` `652.2 / 1163.2` (`max_ms 13.0`, `0` >16 ms — tek koşulu A=B oynaklığı), `not_kapa` `179.7 / 175.0` (`LAYOUT 44.7 / 44.8`), `sabit_ac` `510.4 / 502.3`, `sabit_kay` `493.3 / 501.7` (`max_ms 4.3`, `0` >16 ms), `sabit_kb` `1293.6 / 1261.7` (`max_ms 13.1`, `0` >16 ms), `sablon` `261.5 / 268.1`, `bicim` `1439.2 / 1464.6` (`LAYOUT 45.3 / 40.8`, `0` >16 ms), `kalem` `1271.9 / 1303.8` (`0` >16 ms), `duzen` `291.1 / 296.3`. (`14/17` evre `altın içinde`; `--kosu 1` tek koşulu A=B'de `yaz`/`arama` oynaklığı ve `kb` tam IME döngüsü kare sayısı nedeniyle betik kararı `KALDI` raporlandı.)
- **Açılış, kaydırma ve yazma tabanı (`taban.py opt9003_20261127 dev.kaimau.notlar.olcum`, `27.5 → 27.7 °C`, çıkış `0`):**
  - 3 soğuk açılış `total_ms`: **`1276 / 1376 / 1367` ms** (`20 / 20 / 21` kare, `max_ms` `225.0 / 158.3 / 141.6` ms; `9002`: `1615 / 1417 / 1429` ms).
  - 12 fırlatmalı kaydırma: **`1645` kare**, `jank_pct: %2.5`, `dropped_vsyncs: 49`, `p50_ms: 8.3`, `p90_ms: 8.5`, `p99_ms: 16.8`, `max_ms: 33.4`, `eff_fps: 116.5` fps.
  - Tablet aç/kapa (`3` tekrar, telefonun `kisa metin/gorselli/uzun liste/uzun metin` etiketleri veri setinde olmadığı için atlandı): `kalem pdf` (`open_max 300.0/291.6/308.2`, `close_anim_max 108.3/125.0/125.0`), `kalem bos` (`300.0/300.2/292.0`, `133.5/116.8/124.9`), `cizgi` (`300.0/308.3/291.6`, `116.7/116.6/116.7`), `ilk kart` (`299.7/308.1/300.2`, `125.0/116.8/108.3`).
  - `atrace` yazma: `kalem bos` (`sf` `399` kare, `eff_fps 64.9`, `p90 16.7`, `max_ms 233.3`; `main` `500` patlama, `%18.8` meşgul, `p50 1.82`, `p90 10.72`, `max_ms 189.6`) ve `cizgi` (`sf` `389` kare, `eff_fps 56.3`, `p90 16.7`, `max_ms 225.2`; `main` `487` patlama, `%18.8` meşgul, `p50 2.07`, `p90 13.92`, `max_ms 171.8`).
- **Günlük ve ortak tablet kilidi:** `adb logcat -d -s flutter AndroidRuntime` çıktısında `0` `flutter` / `FATAL` / istisna satırı görüldü (yalnız `uiautomator` araç başlangıç kayıtları). Ölçüm bitiminde kilit hemen bırakıldı (`BIRAKILDI` → `cihaz-kilit.ps1 durum`: `BOS`).

## 7. Faz 8 Ölçek, Web + CSP ve Tablet `9005` Özeti (2026-11-27)
- **Performans & ölçek (`K-47`/`K-48` çöp levhasi, `K-51`, `K-58`, `K-68`, `K-63`):** `trash_analysis_sheet.dart` tembel `CustomScrollView` + `SliverList.builder` + `_SuggestionTile._wsRe`; `account_identity_card.dart` sabit `168x168` önbellek boyutu (`S30` `0/0/314`); `audio_card_box.dart` oynatıcı konum akışı önbelleği (`_TimeLabel`/`_WaveSeek`); `quick_list_screen.dart` `static final _outerParensRe` + `O(1)` `_rowKeys` kümesi (`S49` geçti) ve `test/scale_1000_3000_test.dart` (`4/4`: `1.000` ve `3.000` sentetik notta ilk kare `20` tembel `NoteCard`, fırlatmada `0` yeni kart kurulumu).
- **Web + CSP (`G-12`):** `flutter build web --release` (`main.dart.js` `11.230.199` bayt + `trash_analysis_sheet`/`Ctrl+/` güncellemesi), `web/_headers` tam CSP başlıklarıyla yerel sunucuda (`127.0.0.1:8787`) Chrome üzerinde `0` CSP/konsol hatası, IndexedDB kalıcılığı, Mağaza Kipi ve `#/delete-account` akışıyla doğrulandı; `AppShortcuts` içine `Ctrl+Shift+/` (Türkçe Q), `Ctrl+NumpadDivide` ve `Ctrl+(Shift)+?` yedekleri eklendi (`test/shortcut_table_test.dart` `4/4`).
- **Tablet `9005` (`dev.kaimau.notlar.olcum`, `5VLBB21A27203178`, dikey `64.059.187` B / yatay `64.068.856` B):**
  - **`K-21` & `K-20`:** MatePad 11 ana ekranda ve açık sanal klavye (`SwiftKey`) sırasında `120.00001 Hz (mod 2)` koruyor; HarmonyOS tablette `/system/bin/screenrecord` bulunmadığından `panel_kayit.py` (`K-20`) video ölçümü Android telefon gerektirir (`ed_9005_closed/open` alt çubuğu SwiftKey üzerinde temiz, `kb` evresinde `0 >16 ms`).
  - **Dikey `ab_hepsi.py --kosu 3 --teyit 0 --altin` (`26,0 → 27,2 °C`, 6 koşu):** İlk kare ortancası `A 26 / B 27 ms`, `not_kapa LAYOUT 48.6/43.7`, `bicim LAYOUT 39.9/37.3 (0 >16)`, `yaz`/`sabit_kay`/`sabit_kb`/`kalem` `0 >16 ms`.
  - **RAM (`ram_taban.py --youtube`, `26,9 °C`, çıkış `0`):** `ana ekran 363/468`, `editör 373/478`, `PDF 409/514`, `kalem 369/475`, `YouTube 375/480` MB PSS/RSS (geçici notlar Çöp dahil silindi, `209 | Tümü`).
  - **Yatay + `32 İki not yan yana` + `tur_gez`:** `KT-17(c)` dikey APK reddi (`çıkış 1`), `tur_gez dikey/yatay` (çıkış `0`), `KT-17(a)/(b)` (`↑` düğmesi `+` solunda), `P78(a)/(b)/(c)/(d)`, Mağaza Kipi v2, `32 İki not yan yana` (`yanda_ac_9005.png`, `☰`, `✕`) ve `ab_hepsi --yon yatay` (`A 27 / B 23 ms`, `17/17` evre) doğrulandı; dikey `9005` APK geri yüklendi, `logcat` `0` `flutter`/istisna satırı, ortak kilit `BOS`.
