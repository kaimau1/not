# PLAN — TEK PLAN (2026-11-17; P22/P53 birleşimi + 16/17 Kasım raporları + kasma envanteri)

**Bu dosya tek plandır.** Ayrıntı kaynakları (yalnız okuma, iş buradan seçilir):
`docs/rapor_2026-11-16_beyin_firtinasi.md` (16K), `docs/rapor_2026-11-17_senkron_lite_pro_yazim.md`
(17K), `docs/perf/kasma_envanteri.md` (K-xx). Bitmiş (`[x]`) maddeler burada tutulmaz (git'te).
Kullanıcının kendi listesi: `KONTROL_LISTEM.md`. Eski planlar `docs/arsiv/planlar/`.

## 0. 17 Kasım oturumunda BİTENLER (main'e `[apk]` ile girdi; cihazda doğrulanmadı)

- KP1 levhalar (K-01…K-12): 11 levha klavye karesinde baştan kurulmuyor; S53 bütçesi (arama
  1152→294, not seçici 4758→630, AI sonuç 1512→294 kurulum); `viewInsetsOf` bekçisi.
- KP2 (K-38 ilk ikisi): "Geri al" çubuğu ve `CountdownBar` adımlı boyama (`SteppedCountdown`).
- KP3 kısmi: ana ekran aracı ön planda güncellenmez, arka plana geçerken bir kez (K-24);
  ayar eşitlemesi değişmeyen turu atlar (K-25); nabız arka planda durur (K-53: yalnız paylaşılan
  notta başladığı doğrulandı).
- Hatalar: akıllı liste market sözlüğü (17K §5.1), hızlı ekle H9 ("rapor yaz"), H10 (güncel nota
  ekle + seçici geri al).
- Senkron S2/S3 + korkuluklar: aralıksız yazımda bulut kaydı en geç 20 sn (10 idi; sessizlik 2 sn
  kaldı), `config/app` uzaktan kayıt freni `saveDelaySec`/`saveMaxWaitSec`, sürüm budama sorgusu
  her 5 sürümde bir, boşta yazma bekçisi testi (`test/idle_write_guard_test.dart`).

## 1. SIRADAKİ İŞLER (öncelik sırasıyla)

### 1.1 Senden karar bekleyenler (karar gelmeden başlamaz)
1. Model: tek uygulama + Lite/Pro katmanı (önerim) mi, iki uygulama mı? (17K §2.1)
2. Lite senkronu açık + aralıklı (önerim); cihaz sınırı 2 mi sınırsız mı? (17K §2.2)
3. Lite ekleri kullanıcının kendi Drive'ına (önerim)? (17K §1.3 S4)
4. **S1 "yalnız değişeni dinle"** ayrı faz olarak başlasın mı? (okumayı ~30 kat düşürür; en büyük
   maliyet kazancı; risk yüksek — yedek, iki cihaz testleri, geri alınabilir bayrak şartı) (17K §1.3)
5. Yıllık fiyat aralığı (maliyet hesabı netleşsin). (17K §2.3)
6. Yazım: Y-0 ölçüm seti başlasın mı; Y-4 varsayılan "Yalnız göster" mi? (17K §3)
7. Hızlı ekle HE-4 "tek giriş" ve akıllı liste AL-2 `listKind` alanı dondurmadan çıksın mı? (17K §4–5)
8. Play'e çıkış kararı ("çıkmıyoruz" sürüyor mu?), ad, hesap türü, niş, AI katmanı, fiyat (16K §9)
9. İkinci test telefonu (60/120 Hz ayrımı için) (16K §2.2, K-21)
10. Dondurma (K-O1) kalkıyor mu? (CLAUDE.md "sabah bakılacak")

### 1.2 Senin konsolda yapacakların (5–15 dk, kod yok)
- **Google Cloud bütçe uyarısı 5 / 20 / 50 $** (e-posta + telefon) — maliyet korkuluğu 1, en acil.
- **App Check zorlaması** (Play Integrity kurulu) — korkuluk 3 (KONTROL 31).
- Acil fren gerekirse: Firestore konsolunda `config/app` belgesine `saveDelaySec: 30`,
  `saveMaxWaitSec: 120` sayıları (yeni açılan editörlerde bulut kaydını seyreltir; silince
  varsayılana döner). `minClient`/`inkV2Write`'a dokunma.

### 1.3 Kod işi — zincire hazır (karar gerektirmez)
| No | İş | Kaynak | Cihaz |
|---|---|---|---|
| T1 | Cihaz ölçüm turu: panel kip k/c, 60 Hz ayrımı, RAM tabanı, ısınma, ab_hepsi kör evreleri, 1000/3000 not; 17 Kasım `[apk]`'sının A/B'si (ÖLÇÜM KAPISI bu kez yapılamadı) | K-20, K-21, K-59…K-63 | evet |
| T2 | Not akışı yankısı: sağlayıcı sayacı senaryosu + en pahalı 3 türetilmişi dilime çevir (veri göçü yok) | K-22a, K-23 | A/B |
| T3 | Yazı tipi çalışma anı indirmesi: doğrula, `allowRuntimeFetching=false` + kalın dosyaları pakete, bekçi | K-54 | hayır |
| T4 | Hızlı ekle kalanı: H1 ("süt bitti" sessizlik süresiyle), H3 (süre tutarsızlığı), H11 ("Yeni not olarak kaydet" çipi), hızlı ekle bütçe senaryosu | 17K §4.1, K-64…K-69 | A/B |
| T5 | Akıllı liste AL-1: sık kullanılanları türe böl, ipucu satırı, açılış ilk karesi bütçesi | 17K §5.2, K-41 | hayır |
| T6 | Klavye açıkken sayfa iskeleti: 17 ekranı ölç, kötülere T2 kalıbı | K-13…K-19 | gerekirse |
| T7 | Tembel liste + build'de hesap + onChanged setState (ekran başına) | K-47, K-48, K-57, K-58 | hayır |
| T8 | Editörde kalanlar (ölçüm kapılı) | K-27…K-36 | A/B |
| T9 | Kısa geçişlerdeki `TweenAnimationBuilder`'lar ve beliriş animasyonları (`PopIn`, `RevealUp`…): önce ölç, kurulum > 5 ise düzelt (bu oturumda bilerek dokunulmadı: `child` zaten yeniden kurulmuyor) | K-37, K-38 kalanı | A/B |
| T10 | Görsel açıklama levhası: kapanış animasyonunda atılmış denetleyici kullanılıyor (debug uyarısı; S53 yazılırken görüldü) | `attachment_actions.dart` `showCaptionSheet` | hayır |
| T11 | Senkron korkuluk 6: depolama tavanı sunucuda (ya da Lite'ta Storage kapalı) — 1.1/3 kararına bağlı | 17K §1.4 | hayır |

**Bilerek yapılmayanlar:** kuralda yazma hız sınırı (17K §1.4-4) — reddedilen yazım
çevrimdışı kuyrukta YEREL değişikliği geri alır, veri kaybı riski; S1 kararıyla birlikte
`rules-test` ile yeniden düşünülür. Hatırlatıcı eşitlemesine imza katmanı (K-24 ikinci yarı) —
not başına imza zaten var, kanal çağrısı yok; risk > kazanç. Geri bağlantı dizini (K-26) — seçici
ucuz, ölçülmeden dokunulmadı.

### 1.4 Büyük fazlar (karara bağlı, sırasıyla önerim)
1. **S1 yalnız değişeni dinle** (17K §1.3) → sonra S4 Lite ekleri Drive'a.
2. **Yazım denetimi v3** Y-0 → Y-1 → Y-2 → Y-3 → Y-4 → Y-5 → Y-6 (17K §3.3).
3. **Hızlı ekle** HE-2 önizleme satırı → HE-3 uygulamayı açmadan ekle → HE-4 tek giriş → HE-5 (17K §4.2).
4. **Akıllı liste** AL-2 → AL-6 (17K §5.2).
5. **Lite/Pro + Play yolu** (karar 1.1/1, 1.1/8 sonrası): engeller E1–E12, evreler 2–6 (16K §4, §8).
6. Güven/büyüme: parolalı yedek + uçtan uca şifreli kilitli not, ilk 60 saniye, rızalı kullanım
   ölçümü, kolay dışa aktarma, uygulama içi hız günlüğü (17K §6).

## 2. Önceki açık işler (P22 listesi, aynen)

### (A) Kullanıcının yapacakları → `KONTROL_LISTEM.md`

- Cihaz turu: telefon / tablet / web (KONTROL 1–23) — F69.1, F63.7, F67.8, F19.C1, F19.C2, F19.C4–C6, YORUM F55.5, KALANLAR §2 (C–L, P22, P45)
- Yeni cihaza geçiş + tam yedek geri yükleme (KONTROL 1) — F69.2, F19.A4, YORUM F54.4
- Liste maddesi "Boş madde"ye dönüyor, kanıt bekliyor (KONTROL 2) — KALANLAR veri kaybı 2026-11-01, cihaz turu A4
- Hatırlatıcı güvenilirliği cihazda (KONTROL 4) — F69.3, YORUM F56.2
- Konsol: AI bütçe/kota (24) F19.A1 · sunucu yedeği (25) F19.A5 · Calendar/Tasks API (26) F19.B10 · masaüstü OAuth (27) KALANLAR J0 · Crashlytics (28) F19.B4, YOL_HARITASI · Drive API + Functions (29) F19.B2, F19.B3 · minClient (30) F19.B1, F61.7 · App Check (31) F19.A2, F19.D2
- Test misafir hesabını sil — F19.C7
- PPTX portu için depo izni — F19.B8, F18.20
- Hız ölçüm tabanı yenilensin mi (KONTROL 40) — HIZ F81.2, F81.4 (P43/P55/P59/P20 sabah bakılacakları)
- Kararlar (KONTROL 32–39) — K-O12/F67.6, K-O3/F61.7, K-O4/F62.6, F63.6, K-O8/F65.3, F69.3 ipucu, F66.5, HIZ F83.3

### (B) Bekletilenler / park

- Mürekkep v2 YAZMA + tembel göç + kurallar — K-O2/K-O3 kapısı (F61.0 (b)(c) cihaz ölçümü yok) — F61.0, F61.4, F61.6, F61.7, F61.8
- Kalem raster karoları + görüntüye fırınlama — F62.0 cihaz ölçümü kapısı — F62.0, F62.3, F62.4
- Kalem gecikmesi ölçümü (240 fps) — cihaz — F62.6 (ölçüm), YORUM F54.1
- Açılış süresi kalanı (motor + Activity) — kod işi yok — F68.5
- Vulkan'lı cihazda ölçüm — cihaz yok — AKICILIK F27.3, F19.F4
- Kart dizini + gövde ayrı belge (senkron yükü) — KARAR B, veri göçü güvenlik şartlı — AKICILIK F22.4, YORUM F54.3
- Play'e çıkış (Billing, OAuth yayına, gizlilik, konum beyanı, mağaza) — karar "çıkmıyoruz" — F18.27, F18.28, F19.D1–D7, YOL_HARITASI F4.10
- Taşınan düğme ipucu, uygulama içi sürüm notu — tek kullanıcı, ertelendi — YORUM F57.1, F57.2
- Önce/sonra görsel karşılaştırma dosyası — DENEYIM F80.5
- Kare ölçümü CI işi (emülatör, sonuçsuz kaldı) — F19.B6, KULLANICI_DENEYIMI F17.1, HIZ F83.3
- Bilinen sınırlar: web geri tuşu tam ekran, debug `RenderFollowerLayer` uyarısı, düz metinde görev çipi yok, madde jest katmanında şekil önerisi yok, görev kişi alanı serbest metin — KALANLAR §3, Yarım kalan

### (C) Açık kod işi

- [x] **İki not yan yana (tablet yatay)** — opus — K-O12 kararı VERİLDİ (2026-11-12) — F67.6 — 2026-11-14 kod bitti (K32, dal oto/K32-yan-yana); tablette doğrulama KONTROL_LISTEM 32
- [x] **Parmağa ayrı araç** — YAZILDI 2026-11-14 (K34, dal `oto/K34-parmak-araci`): Kaydırır/Çizer/Siler, Siler = geçici silgi yolu, avuç/iki parmak geri alma, 22 dp yarıçap süzgeci; tablette doğrulanmadı → KONTROL 41 — F63.6, YORUM F55.1
- ~~**Kalem ucu tahmini**~~ — kullanıcı kararıyla çıkarıldı (2026-11-14: "yalnız parmak aracı olsun") — F62.6
- **Dolma kalem** — YAZILDI (`InkPen.fountain`, F62.5; `test/ink_paint_v2_test.dart`), cihazda denenmedi — YORUM F55.4
- **Büyük PDF (500 MB–1 GB)** — KOD YAZILDI (P08, 2026-11-11: akışla kopya, `localOnly`, rozet; `test/large_local_pdf_test.dart`); yalnız tablette 1 GB doğrulaması kaldı → KONTROL 20 — F65.9
- **Web'de ek görünmüyor / paylaşılan notta ek** — kullanıcıdan hata metni gerek — F65.6
- **Editör bölge çıkarma + `_mutate` kök setState** — P20 kısmi (bölge çıkarılmadı; M6 `_sameVisual` silinmedi, daraldı; M7 kural CLAUDE.md'ye yazılsın mı; Seç kipi/tablette satır 23 kalıyor; ekran okuyucu taşı eylemleri yalnız tutamaçlı kipte) — sabah bakılacak — F64.3, F64.4
- **Kasma kökten artığı** — P55 [apk] ile bitti (2026-11-14); yalnız plan arşivindeki `[ ]` işaretleri bayat, cihazda his kontrolü KONTROL 3 — HIZ F84.1, F84.2, F68.3
- **Kaydırma kabulü** — P43/P46 ölçtü (%2,3–3,3); resmî kabul yazılmadı — F68.4, AKICILIK Faz 21
- **Pano gövdesini böl (ölçüm kapılı)** — boşa kurulum düzeltildi (kısmen), kalanı ölçüm kapılı — F68.2
- **Takvim haftalık ızgarada sürükle, görev elle sırala** — ay görünümünde sürükleme VAR (`_MonthCell` DragTarget), `WeekPage`'de yok — TAKVIM (ayrı faz)
- **Uçtan uca akış testleri** — widget düzeyinde YAPILDI (F18.8: `user_flows_test`, `media_bubbles_share_test`, `backup_service_test`); açık kalan: `integration_test/` emülatör akışları + web ağır işler (F17.3) — F17.2, F17.3
- **PPTX düzenleme portu** — depo izni sonrası — F18.20
- **Şablon önizlemesinin liste dalını kaldır** — liste şablonları `QuickListScreen`e taşındı (2026-11-15); `TemplateComposer` liste dalı + `showNoteTemplateSheet` üretimde çağrılmıyor, `note_templates_test` / `template_sheet_layout_test` / bütçe S48 / ekran turu ona bağlı → birlikte taşınıp silinecek; ayrıca hızlı liste + hızlı ekle cihazda A/B ölçülmedi (KONTROL "Telefonda bak") — `docs/hafiza/editor.md` sonu
