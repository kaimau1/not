# Hafıza — Arayüz, tema, ana ekran

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

## Arayüz kararları
- **Tasarım dili sözleşmesi (2026-11-12, DENEYIM_PLANI §2):** yeni arayüz yazarken ölçü ELLE yazılmaz: köşe/boşluk/punto/süre `AppRadius`/`AppSpace`/`AppText`/`AppMotion` (F72'den sonra mandal testi `design_tokens_guard_test` yeni elle değeri kırmızıya düşürür; sayım `python tool/design/token_sayim.py`). Renk rolü: `primary` = eylem/seçim/oluşturma, `secondary` (sıcak) = zaman, dikkat ve etiket (iğne, yıldız, hatırlatıcı, zamanı gelen, etiket hapı), `tertiary` = yalnız yapay zekâ, gerisi nötr. Ekran başına tek dolu birincil düğme; arayüz kromunda en kalın w600. Hedef görünüm `docs/deneyim/hedef.html`. **TUZAK (2026-11-12 kök neden):** ilk plan sürümü 16 yerde kullanıcının eski açık isteğini tersine çeviriyordu (klasör sayısı üst simge, menü 3 sütun simge, etiket renkli, takvim şeridi 10 gün, başlıktaki "+", ajandada hızlı sil…) — ekran görüntüsüne bakıp "sadeleştirme" önermek yetmez; görünüş/yer değiştirmeden ÖNCE `python tool/design/istek_tara.py <dosya>` ile o dosyadaki "kullanıcı isteği/bulgusu" yorumlarını oku. Yapılmayacaklar listesi DENEYIM_PLANI §4.
- **Tema (TEMA_PLANI, 2026-11-04):** beş aile `ThemeFamily` (Adaçayı
  varsayılan, Porselen, Kil; 2026-11-05 gece + Lavanta, Zeytin) × açık/koyu
  (Sistem ve Koyu yine Adaçayı koyusu; seçici dar ekranda 4+3), renkler `app_palette.dart`,
  şemada olmayanlar `AppTokens` (kart, kart çizgisi, gölge, köşe 16).
  "Masa ve kâğıt": açık temada kart zeminden AÇIK — `surfaceContainerLow`
  zeminden açık (levha), High/Highest koyu; renksiz not kartı
  `AppTokens.card` (eski `surfaceContainerLow` değil). Eski kırık beyaz /
  kağıt / beyaz `AppThemeChoice.fromStored`'da okunurken eşlenir, kayıt
  değişmez. Kart gölgesi bulanıksız 1 dp (GLES; bulanık gölge ölçülmeden
  açılmaz). `theme_contrast_test` her rol + not paleti kontrastını korur.
- **Hareket (TEMA Faz 34, 2026-11-05):** `AppMotion` + `kGridInset/kGridGap` `app_tokens.dart`. Tema geçişi ÖLÇÜLDÜ, kare başına 50–66 ms → `themeAnimationDuration: Duration.zero`, geri açma. Renk solması `ColorFade` (denetleyici ilk değişimde; `identity` temayı da içerir, yoksa tema değişiminde her kart animasyona girer). TUZAK: editörde üst çubuk ve Scaffold HEP saydam, sayfa rengi arkadaki `ColoredBox`ta; yeni saydam `AppBar` `systemOverlayStyle` vermezse durum simgesi beyaz kalır. ΔE ≥ 0,08 K5 paletinde tutmuyor, test bugünkü ayrımı korur (kullanıcı kararı bekliyor).
- **Beyaz açılış (2026-11-05, ÇÖZÜLMEDİ):** `NormalTheme` + v31 `windowSplashScreenBackground` `launch_bg` ama MIUI 13'te ~0,6 sn beyaz sürüyor. Tahmin MIUI sistem penceresi; ilk Flutter karesi elenmedi. Ölçüm: `screenrecord` + ffmpeg; aynı saniyede `screencap` yanıltıyor (ana ekran da aynı renk).
- **Açılış ekranı (2026-11-12, F78.1/K-D8 — cihazda DOĞRULANMADI):** `LaunchTheme` = `Theme.SplashScreen` (core-splashscreen 1.0.1; zemin `launch_bg`, simge `ic_launcher`, `postSplashScreenTheme` `NormalTheme`); `MainActivity` `FlutterUiDisplayListener` ile ilk kareye dek tutar, 3 sn emniyet. `launch_background.xml` ve v31 stilleri silindi. Beyaz kare sürüyorsa commit geri alınır.
- **Yükleme hâli kuralı (2026-11-12, F78.3):** içerik alanında `const Center(child: DelayedSpinner())` (düğme içi ve yüzdeli halka kalır; döküm `docs/deneyim/yukleme.md`). PDF belgesi açılırken `MediaLoadingCover` (küçük resim + %24 perde) — rota geçişi yer tutucusuna KONMAZ, yerel görsele solma EKLENMEZ (ikisi de denendi, kötüleşme riskiyle geri alındı). Basma tepkisi olmayan özel yüzey `PressScale` ile sarılır (`docs/deneyim/dokunus.md`). İşlemler iyimser: arayüz `batchUpdate`/`updateFields` Future'ını BEKLEMEZ (bekçi `test/optimistic_actions_test.dart`).
- **Worktree tuzağı:** yeni worktree'de `.dart_tool` yok; `dart analyze` yanıltıcı "URI yok" verir. Önce `flutter pub get`.
- **Okunurluk (2026-11-04 kök neden):** özel renk kâğıda sabit oranda
  karışıp yazı hep tema mürekkebinde kalıyordu → `NoteColors.customSurface`
  + `inkThemeFor` (zıt parlaklıktaki AYNI tema, önbellekten). Editör
  `_editorInk` / kart `_cardInk` Expando + `_themeOf` — bu dosyalarda
  ekranın kendi bağlamından `Theme.of(context)` YAZMA (dış temayı okur,
  yazı stili okunmaz kalır). Editör ağacı hep `Theme` ile sarılı (renk eşiği
  aşılınca alt ağaç yeniden kurulmasın). Renkli yazı `RichTextTheme.background`
  → `markStyle` → `readableOn` (≥ 4,5, ton korunur). Renkli kartın koyu tonu
  `NoteColors.noteInk` (hap, kutucuk, ilerleme, defter çizgisi `PaperInks`).
- **Not vurgusu — kart = açık not (TUTARLILIK F36.1, 2026-11-04):** içerik
  öğeleri (kutucuk, "Yeni madde", etiket/klasör/hatırlatıcı hapı, raptiye,
  madde ayırıcı) `NoteAccent`'ten: renkli notta `noteInk`, renksizde null →
  temanın vurgusu; kutucuk `NoteCheckColors` (işaretli soluk dolgu).
  Editör ağacı `NoteAccent` ile sarılı, değer DIŞ temadan (zıt temada zemin
  yanlış çıkar); ItemsEditor `_accent` satır önbelleği anahtarında. Krom
  (çubuk, levha, menü) temanın. Test `note_accent_consistency_test`.
- **Not her yerde aynı (TUTARLILIK Faz 37, 2026-11-05):** başlık tek stil `noteTitleStyle` (`editor/title_fit.dart`), yeni yüzey de bunu kullansın. TUZAK: `AppTheme.opposite` (zıt okunurluk) `Theme.of`tan geçmemiş HAM temadır, M3 ölçüleri (`letterSpacing`, `height`, kimi `fontSize`) onda null; ondan ölçü okuyan yer sabit yedek versin. Liste satırı artık notun rengini taşır. PDF/görsel `PdfNoteStyle.forNote` (temanın AÇIK hâlinden; renksiz not boyanmaz). Kural `note_everywhere_same_test`. TUZAK: `Flexible` + `Spacer` boşluğu oranla böler, kullanılmayan pay boş kalır (tarih ortada durur, saat yer varken kesilir): sol grup `Expanded`.
- **Başlık sığdırma ölçümü (F36.2 kök neden):** `TextField` M3'te stilini
  `bodyLarge`ın ÜSTÜNE birleştirir (harf aralığı 0,5 miras) → ölçüm
  `fieldMergedStyle(bodyLarge, stil)` ile; yoksa uzun başlık çipin altına taşar.
- **AI hata metni (F36.5, F42.3):** tek kapı `aiErrorText(l10n, e)`; `e.message` ya da `aiError(friendlyError())` YAZMA. Veri katmanı metin yazmaz: `GeminiException.of(kind)`, metin ARB'de (`localized`). `GeminiException('…')` yalnız zaten yerelleşmiş metinle (test tarar). Daire jesti AI yoksa bir kez `gestureFixNeedsAi`, sonra oturum boyu sessiz; karalama silmesi bildirimde Geri al.
- **AI durumu (F42.2, 2026-11-05):** tek kaynak `aiAvailabilityProvider`; yeni AI düğmesi `ensureAiReady(context, ref)` ile başlar, simgesi `AiIcon`. Arka plan işi çağırmaz, sessiz geçer. AI'sız yola düşen kapı (AI sesli not, anlamsal arama) kilitlenmez. Kota kilidi yalnız yenilenme saati biliniyorsa (son söz sunucu sayacında). Web'de "dahili kapalı" istekten öğrenilir (`aiBuiltInOffProvider`, 24 saat); site anahtarı yokluğu kapalı demek DEĞİL.
- **Ses simgeleri (F42.1, K7):** `AppIcons.dictation/aiVoiceNote/voiceRecord/listen/voiceCommand`, `IconData` alan satır `AppIcons.glyph` ile çizer (AI sesli not bileşik). Jest: parmak yalnız işaretler, `inkGestureAllowed` (K10). TUZAK: Bash heredoc'una yazılan Python betiğinde ters bölüler yarıya iniyor (`\\b` → backspace): betiği Write ile yaz.
- **Ek tek model (F40, 2026-11-05):** menü sırası yalnız `attachmentActionsFor`; yeni ek işi oraya + `AttachmentAction`. Görünüm geçişi menü maddesi değil anahtar (K6; "Sayfaya göm/Ek olarak taşı/Nota aktar" YOK), her geçiş `_setAttachmentView` → "A → B · Geri al". Durum tek dil `attachmentStatusOf` + rozet; ek kutusuna tıklanabilir yer tutucu koyma (yüzende dokunuş seçer, kartta notu açar; `interactive: false` + köşe rozeti). Araç satırı zemini `PdfReadStyle.barColor`. Video dönüşü oturumluk (`NoteVideoHub.rotate`). Web dosya bırakma `listenFileDrops` → `useFiles`.
- **Paylaşılan klasör = süzgeç (K8, F43.2, 2026-11-05):** `openFolder` (`folder_nav.dart`) tek kapı; `selectedSharedFolderProvider` açıkken `selectedFolderProvider` null. Izgara `sharedFolderSlivers`, kart `ownerId` taşır (seçim yok). TUZAK: ana ekranda not oluşturan yol kendi koleksiyona yazar, bu yüzden açıkken mikrofon ve "+" yerine `SharedFolderFab`; yeni kapı eklersen bak. Yana çekiş durağı `sharedFolderStopId` (`sahip/klasör`). `NoteListRow` sahibi taşımaz: paylaşılan yüzeyde liste görünümü kullanma. Ek paylaşımı tek `shareAttachmentFiles`; misafir kilidi `AccountLockBadge` (`MenuAction.badge`, ray `locked`).
- **Bölüm başlığı (F36.7):** tek `SectionLabel`, cümle düzeni (büyük harf
  yalnız rozet: BALONLU PDF, SUNUM, VİDEO, YENİ); Başlık Düzeni ad yok
  ("Çöp kutusu"). Sayı 0 → rozet çizilmez; boş klasör solması renkte
  (`Opacity` yok).
- **Ekran turu (F36.3):** `tool/tour/screen_tour_test.dart` (CI dışı) →
  `build/tour/*.png`, 4 boyut. TUZAK: testte `debugDisableShadows` → FAB/panel
  çevresinde koyu halka çizilir, GERÇEK DEĞİL.
- **Ana ekran jestleri (F39, 2026-11-05):** zoom ve yana çekiş jest boyunca YALNIZ `Transform` (`PinchColumns`, `FolderSwipe`), yerleşim bırakınca bir kez; jestte ikinci ızgara kurma. TUZAK: `Row`da `Flexible` + `Expanded` boş alanı yarı yarıya böler; `build` içinde `context.size` assert atar. Çoklu dokunuş ölçümü: `adb input` iki parmak bilmez, `InputManager.injectInputEvent` + `app_process` küçük dex (`tool/perf/Pinch.java`).
- Ana ekran tek mikrofon = doğrudan yazdır; AI sesli not Yapay zekâ
  ekranının en üstünde. "+" tek panel. Dosya akışı tek levha
  `showFileUseSheet`; HEIC → PNG.
- "Tümü" çipi kalıcı; kendi klasörüm = süzgeçli ana ekran; "Gelen" çipi ana
  ekranı süzer (`sharedHubOnHomeProvider`), "Gelen" klasörü cihaz tercihi.
  Çip sayısı listeyle AYNI süzgeç (`sharedNotesVisibleCountProvider`: çöpteki/
  silinmiş/kendi aynası sayılmaz — 2026-11-05 "boşken 1 görünüyor").
  Paylaşılanlar ayrı bölüm (`home_show_shared`, yer
  `homeSharedAtBottomProvider`).
- Süz düğmesi arama kutusunun içinde; varsayılan sıralama "Son güncellenen"
  (`migrateDefaultNoteSort`).
- Kartta görünenler `card_show_*`; kart TEK semantik düğüm, ⋮ ayrı.
- Menüler `ActionMenu`; not ⋮ ve kart ⋮ TEK katalog `noteMenuModel` (F38.1): yeni iş oraya + iki handler (`note_menu_model_test` ölü düğmeyi yakalar). Çok işlemli = levha, tek seçimli ya da ≤ 4 madde = açılır menü (F38.6). Hızlı satır en çok 5: 6'da dar ekranda ad kesilir. Alt çubuk
  sırası sabit: Biçim · Ekle · Kalem · Ara · Ekler · (☑|Seç) (F75.1, 2026-11-12: Paylaş ⋮ menüsünde; kalem = `_togglePen`, belge notunda üzerine yazma; kimlik `UiItem.barPen`; `planEditorBar` sığmayınca önce Ara'yı, en son Kalem'i düşürür — 360 dp + ekli metin notu). TUZAK: `MinTapTarget` payını ATA kutu keser — kapsülün dikey dolgusu Row'un dışında olursa (Container padding) 48 dp yalnız ekran okuyucuda kalır; Row kapsülün tam boyunda olmalı. Segment 40 dp görünür, dokunma 48 dp (`MinTapTarget(minWidth: segment + boşluk)` — yatay pay komşunun kutusuna taşmasın). Renkli notta çubuk notun tonunda (`_barInk`/`_barPage`, F75.3): yeni çubuk düğmesi rengi `_barInk ?? tema` ile alsın.
- Simgeler `lib/core/app_icons.dart` sözlüğünden (`visual_consistency_test`
  doğrudan `Icons.archive/move_to_inbox/…` kullanımını yakalar; F18.15'te
  yakaladı). Levha `SheetHeader` + `SectionLabel` (asla `toUpperCase`).
  Sabit renk yalnız `fixed_colors.dart`. Liste yüklemesi `NoteListSkeleton`
  / `ErrorState`.
- Erişilebilirlik `lib/core/a11y/` (renk adları, çip rolleri, `MinTapTarget`,
  `motionOf`). Okunan metne < 0,8 alfa verme, ≥ 12 punto. Sistem yazı
  boyutu izleme varsayılan kapalı.
- Terimler `TERIMLER.md` (`terminology_test`; Türkçe sınır için Unicode
  bakış, `\b` değil). İpuçları `TipOnce`. Hata metni `friendlyError`.
  Bildirim `messenger.showMessage` (elle SnackBar kurma; kökten
  `rootScaffoldMessengerKey`).
- Arayüz dilleri tr + en. Kılavuz `assets/guide/guide_<dil>.md`
  (`guide_screen_test` eskimiş ifade listesi).
- Kişiselleştirme `UiItem` kimlikleri kalıcı anahtar — değiştirme.
- **Tek Ekle kataloğu (F41, 2026-11-05):** "+" paneli ve Ekle levhası `addCatalog` + `AddTile`; yeni seçenek oraya yazılır (kimlikler `UiItem.quickAdd`/`attach`, değiştirme). Web dosya bırakma/yapıştırma `addFileDropHandler`: en son açılan yüzey alır (not > ana ekran). Paylaşımdan gelen ek `?place=<id>` ile ipucuyla açılır.
- Misafir: hesap isteyen giriş gizlenmez (`AccountLockBadge`); dahili AI
  misafire kapalı (`aiAvailabilityProvider`).
- "Yeni sürüm var" (F18.21, yalnız Android): `config/app.latestBuild` >
  kurulu derleme (yerel 1 sayılmaz) → sürüm başına bir kez bildirim
  (`update_notice_shown_for`) + Ayarlar → Hakkında satırı.

- **Cihaz turu kök nedenleri (2026-11-05):** `resizeToAvoidBottomInset: false` ekranda bildirim klavyenin arkasında kalır: yeni bildirim `timedSnackBar`/`showMessage` ile ya da `snackBarMarginOverKeyboard`. Tembel listede `maxScrollExtent` ilk karelerde tahmin: oranı tahmin oturana dek yeniden uygula (`_restoreScroll`). Biçimli metni `substring` ile bölme: `splitRichText` (klavye "İleri" `_enterAt`, donanım Enter `_splitMultiline`: ikisi ayrı yol). Düz madde satırında (F24.3) odak düğümünün `context`i boş: satırı bulan kod `rowContext` kullansın; testler `debugEagerItemFields` ile bunu GİZLER, yeni satır davranışını `items_editor_lazy_test`e de yaz. Aramada geri aramayı kapatır (`PopScope`). Sabit video: döndür < 430 dp ⋮ menüsünde, üstünde çubukta (telefonda çubukta ⋮ taşıyordu).
- **Cihaz turu tuzakları:** Bash heredoc'ta ters bölü bozulur, yama betiğini Write ile yaz. `adb` Enter donanım yoludur, Gboard "İleri" değil. Koordinat basarken klavyeye bak. Ekran 30 sn'de kapanır, `dump` boş döner. Telefon `taban.py` + şarjla 49 °C'ye çıkar (sayı geçersiz), önce < 37 °C bekle. "Yalnız kalem" o telefonda açık kalmıştı: adb çizgi bırakmıyordu, hata değil. MIUI otomatik başlatma izni `appops` ile verilemiyor. Dosya seçici Dosya Okuyucu'yu açar, "Diğer" sistem seçicisi. Kişisel dosyalar açmaktan kaçın (video denemesi gerçek bir videoyu açtı, görüntüler silindi; test videosu it).

- **Klasör silme kök nedeni (2026-11-06):** `folderShares` aynası silmesi klasörle AYNI batch'teydi; aynası olmayan (hiç paylaşılmamış) klasörde kural `resource.data` null'da reddediyor, batch bütünüyle geri alınıyordu (klasör yerelde kaybolup geri geliyordu). Ayna artık ayrı, en iyi çabayla silinir; kural `resource == null` silmeye izin verir. TUZAK: batch'e "var olmayabilir" belgeye silme koyma.
- **Klasör halkası (2026-11-06):** yarıçap küçültüp çipi aynı boyda bırakmak çakıştırıyordu. `radialRadiiFor` gerçek çip boyutlarıyla (TextPainter) çakışmasız oval arar; sığmazsa ızgara levha (`folder-grid-menu`). Test 13 durakta çakışma olmadığını ölçer.
- **Ayarlar kabuğu baştan (2026-11-06):** akordeon kalktı. Kök = profil + kısayollar + gruplu kategoriler (`_settingsGroups`: Hesap · Uygulama · Veri ve gizlilik; gruplanmamış yeni alan "Diğer"e düşer). Dar ekranda alan AYNI ekranda açılır (`_open`, `PopScope` geri → kök; rota değil, satırlar ebeveyn build'iyle tazelensin), ≥ 900 dp iki bölme. `?area=` doğrudan alan sayfası. Satır bileşenleri değişmedi.
- **Gmail / Kişiler baştan (2026-11-06):** Gmail süzgeç çipleri `gmailQuery` (süzgeçte `in:inbox`), tarih kümeleri `gmailDayOf`, okunmamış/yıldız `labelIds`'ten yalnız gösterim. Kişiler saf yardımcıları `friend_list.dart` (Türkçe sıra/İ-ı). Ekleme tek alan; tam e-posta yazınca doğrudan istek satırı.
- **Klasör şeridi + tema + hatırlatıcı (2026-11-06 gece):** klasör İÇİNDEYKEN (kendi/Gelen/paylaşılan) şerit gizli tercihe rağmen çizilir, başında SABİT ana sayfa düğmesi (`home-strip-go-home`); "Tümü" çipi DOKUN → `/folders`, UZUN BAS → bütün notlar (eski dokunuş) — **2026-11-10 F60.S3 TERSİNE ÇEVRİLDİ:** DOKUN = bütün notlar (`resetFilters` + `showAllNotes` true, not açıksa `goHome`), UZUN BAS = `/folders`; vurgu yalnız klasör/Gelen/paylaşılan seçili DEĞİLKEN (bekçi `folder_strip_chips_test`). TUZAK (test): yatay şeritte ekran dışındaki çip için `find.descendant`in HEM kendisine HEM `matching` bulucusuna `skipOffstage: false`. Sağdaki "Tüm klasörler" simgesi kalktı. Klasör menüsü (düğme + yukarıdan çekiş) Gelen'i şeritteki yerinde gösterir (`kSharedHubFolderId` → `showSharedHubOnHome`). Klasörler ekranı kartı 128 dp (simge adın yanında, 2 önizleme). Başlıksız `ActionMenu`'de ⚙ ilk bölüm başlığının sağında (ayrı satır yok). Tema: `theme_picker.dart` tek seçenek listesi (`themeChoiceOptions`), ana ⋮ → Tema = perdesiz alçak levha, canlı uygular, Vazgeç geri alır. 5 canlı aile Okyanus/Gül/Mandalina/Zümrüt/Ametist (renkler betikle üretildi, kontrast testli). Hatırlatıcı TEK levha `showReminderSheet` (zaman + tarih/saat + tekrar + Kaldır/Kaydet, `applyReminderChoice` kaldırmada Geri al); `pickReminderWhen` artık kullanılmıyor. `showAppSheet` HER levhaya alt `SafeArea` sarar (gezinme çubuğu altına girme kök nedeni: kenardan kenara + levhada alt dolgu yok).
- TUZAK: `dart format` `HomeInBar(appBar:`'ı alt satıra bölüyor; `rail_scope_menu_test` artık regex ile bakar.

## Kısa kurallar (sıkıştırmada tek satıra inenler)
- Görünüm levhası: temalar + "Düz renkler"; "Sade" tema ve rengi kaldırır;
  `isScrollControlled`. Not teması tek kapı üst çubuk palet.
- Sesli not kaydı notun içinde (`VoiceNoteRecorder`, hap); kaydedici
  eklentiyi tembel kurar (testte platform kanalı patlar).
- Görsel açıklaması sayfa düzeninin parçası (`_captionBand`).
- İşaretli blok 10'ar
  (`_checkedShown`, "İşaretlileri göster (N gizli)"), açılışa özgü.
- Ayar alanları `ExpandReveal` (+ `_StaggeredRows`, `_followIntoView`);
  arama + ✨ AI kipi (`matchSettings`, yalnız ayar adları).
- Paylaşım iki kavram: Birlikte düzenle / Kopya gönder. Paylaş levhası
  Dışarı gönder / Kişilerle (F43.1); web'de "Görsel" `pngPages`.
- Ana ekrana yerleştir: `NoteShortcut.pin` → `NotKisayolu.kt` →
  `notlar://note/<id>`.
- **Geniş ekran (2026-11-02):** ray 64 dp etiketsiz (adı ipucunda),
  kendiliğinden etiketli ≥ 1600; "Gelen" RAYDA YOK (`railSections`). Not
  açıkken ray ÇEKMECE (sol kenar tutamağı / kenardan çekme, Esc + geri
  kapatır) ve liste TEK SÜTUN solda: yan yana sınırı not açıkken
  `kNoteSplitBreakpoint` 640 (yoksa 840), not kipinin liste genişliği ayrı
  (`note_pane_width`). `/` rotası kararı `SplitScope`tan okur (genişlikten
  değil — liste iki kez kurulmasın). Dikey menteşe (`verticalHingeOf`) varsa
  ayraç menteşeye oturur; AppFrame menteşe koordinatını içerik alanına kaydırır.
  **Tek liste örneği (2026-11-02, kullanıcı isteği "sağda not seç alanı
  kalmasın"):** ≥ 640 dp'de liste HEP kabuğun sol panelinde; not yokken tam
  genişlik (LayoutBuilder — `MediaQuery` genişliği rayı içerir, taşar),
  `/` rotası boş döner; `NoNoteSelected` + `listPaneWidthProvider` silindi.
  Aynı State kaldığı için arama/süzgeç/kaydırma korunur; sütun sayısı
  değişince konum oranla taşınır + açılan/kapatılan notun kartı vurgusuz
  görünür alana gelir (`DashboardPaneScope.anchorNoteId`, `_revealCard`).
  **Liste gizliyken (tam ekran / odak modu) ☰**: editör AppBar `leading`,
  kalem+tam ekranda kalem tepsisinde; Esc ve geri önce tam ekrandan çıkarır,
  Ctrl+Shift+F tam ekran. Başka nota geçince tam ekran SÜRER (dispose'da
  `openEditorNoteIds` boşsa kapanır). Tarayıcı geri tuşu PopScope'a uğramaz
  (go_router popstate) — orada tam ekran önce kapanmaz.
  **Çekerek tam ekran** (2026-11-02): not açıkken ayraç en dar hâlden SOLA
  56 dp itilince ipucu "Bırak: tam ekran" (lastik daralma + titreşim),
  bırakınca `noteFullscreenProvider`; tam ekrandan sol kenardan sağa çekip çık.
  **Ekler (2026-11-02):** metin/liste notunun sayfası `kReadingWidth` 760'ta
  ortada (`_buildCanvas`; görsel x'i ve mürekkep sayfa genişliğine ORANLI →
  hepsi birlikte ölçeklenir, kaydırma tam genişlikte). Açık not listede
  çerçeveli: editör `openNoteIdsProvider` yığınına yazar, hücre `select` ile
  izler (kart önbelleği bozulmaz). Alt+↑/↓ `visibleNoteOrder` (ekranda çizilen
  sıra) ile komşu notu `pushReplacement` eder, kilitliyi atlar; Ctrl+W
  `popRoute` (PopScope'a uyar), derin bağlantıda `go('/')`. TUZAK: tarayıcı
  Ctrl+W/Ctrl+N'yi sayfaya vermez (sekmeyi kapatır) — yalnız Android/kurulu
  PWA'da çalışır. Ayraca çift tık = o kipin varsayılan genişliği.
- **Geniş ekran kapıları (F44, 2026-11-05):** yeni not kapıları rayda (K3), ana ekran FAB'ları `AppRailScope.visible` ise çizilmez; iş ana ekranda, ray ve kısayol `homeDoors` (`HomeDoors`) ile çağırır (dar↔geniş geçişinde yeni örnek önce kurulur, `dispose` yalnız kendisiyse siler). "Notlar" = `goHome` (K4). Dar web 🏠 `HomeInBar`: yeni çubuklu bölüm ekranı sarılır + `kHomeInBarLocations` (K5). Sütun `readingColumn`/`readingMargin`: sabit medyada ve belgede çubuklar bölmeyi doldurur. Dikey < 960 dp not açılınca liste çekilir (`listAutoHidesFor`, `listPeekLocationProvider`); editör `SplitScope.listHidden` okur, sağlayıcı değil. TUZAK: kökteki `AppShortcuts` metin alanının kısayollarından ÖNCE yakalar (`DefaultTextEditingShortcuts` daha yukarıda): Ctrl+A/Delete gibi metinde de anlamlı tuşu koşulsuz bağlama. TUZAK: `DashboardScreen` gizli listede hiç kurulmayabilir (`FreezeWhenHidden`): `ref` okuyan tembel alan `dispose`ta patlar, `initState`te kur. Web'de Ctrl+tekerlek ve kıstırma `PointerScaleEvent` gelir (`exp(-dy/200)`), yatay kaydırma tekerlek olayı (bırakma yok, sessizlikle biter).
- Misafir kartı "Sonra" → şerit; 5/20 notta bir kez tam kart.
- Bekleme penceresi oturum düşüren işte `DialogRoute` + `removeRoute`
  (körlemesine `pop()` alttaki sayfayı atar).
- Kart ⋮ "Görsel önizlemesini gizle" `cardMediaHidden`; hassas içerik
  gizleme `card_hide_sensitive`.
- Çöp analizi `trash_analysis.dart` + AI; çöp hatırlatması bildirim 999002.
- **Tema aileleri 7 (2026-11-06):** + `white` (klasik beyaz: gri masa, beyaz kâğıt, mavi) ve `straw` (saman kâğıdı: saman masa, krem kâğıt, sepya). Kayıt adları `white`/`straw` — eski `light`/`paper` göç eşlemesi (→ Porselen/Kil) DEĞİŞMEDİ. Seçici dar ekranda 3 × 3.
- **Dar sütun kartı + Gelen adı (2026-11-07):** ana ekran `NoteCardWidth(width: cellWidth)` verir; `noteCardSqueezeFor` 0 (≥150 dp) / 1 (3 sütun) / 2 (<112, 4 sütun): başlık 16/14,5/13, "+N madde daha" → "+N", dar kartta etiket hapı + hatırlatıcı yazısı gizli (hap sıfıra sıkışıp boş leke oluyordu), çok darda tek durum simgesi, belge kartında ad yok. Gelen = `sharedHubOnHomeProvider` (selectedFolder DEĞİL) → `appliedFilterLabels` ayrıca okur, `resetFilters` kapatır. Tur: `TOUR_COLUMNS=3|4`.
- **CI deploy:** Cloudflare Pages "Unknown internal error" (2026-11-06, koşu 748) kodla ilgisiz; sonraki main push yeniden yayınlar. Main'e APK işi sürerken push ETME: `cancel-in-progress` APK'yı iptal eder.
- **Push öncesi `flutter analyze` (tam, ~11 sn)**: CI analizi `info` düzeyinde de kırmızı (avoid_redundant_argument_values) — yalnız değişen dosyayı analiz etmek yetmedi (2026-11-06, iki kırmızı koşu). arb_case_test: özel adlar (Google Takvim) `titleCaseOk`'a.
- **Menü düzeni (2026-11-06):** `ActionMenu(menuId:)` → başlıkta ⚙ "Menüyü düzenle": sırala (sürükle), gizle (göz), hızlı satıra al (yıldız, en çok 5). Kayıt `menu_layout_v1` (`MenuLayouts`, main'de `attach`). Kimlikler: `note.card`, `note.editor`, `note.add`, `home.menu`, `home.selection`. Varsayılan hızlı satırdan çıkarılan işlem "Diğer" grubuna düşer (kaybolmaz). PopupMenuButton menüleri kapsam dışı.
- **Klasör düğmesi (2026-11-06, 5. tur):** ana ekran sol alt `FolderHoldButton` + liste TEPEDEYKEN aşağı çekiş (≥ 80 dp parmak, bırakınca; `_trackFolderPull`, gösterge `FolderPullIndicator`) — ikisi de `openFolderMenu` (tek kapı). Menü KOMPAKT: sabit 74×76 karo (renkli simge dairesi + sayı rozeti + tek satır ad), orta daire 76, oval en çok %30 uzun; sığmazsa (telefonda ~11+) aynı karolarla ızgara levha. Izgaraya `AlwaysScrollableScrollPhysics` (az notta da çekilsin). Çekiş seçim/sıralama/arama/paylaşılan klasörde kapalı (`_folderPullAllowed`). TUZAK: FAB'a `tooltip` verme.
- **Yana kaydırma akan geçiş (2026-11-06):** KÖK NEDEN "hızlı geçişte takılma": bırakınca ızgara merkeze geri sekerken yeni içerik AnimatedSwitcher'da ters yönden geliyordu (gelen liste parmağın tersine kayıyordu). `FolderSwipe.continuesInPlace(direction, oran)` true dönerse ızgara sekmez; ana ekran ayrılan görünümü bırakılan orandan aynı yöne sürdürür (`_leavingKey/_leavingFrom`, 2×medium sonra temizlenir), gelen 0,3 uzaktan girer. Takvim açan çekişte eski davranış.
- **Profil levhası (2026-11-06, baştan):** `showAccountSheet` kâğıt kartlar (AppTokens card/hairline/cardRadius): kimlik kartı + durum hapı, 2 kare kısayol (Kişiler/Premium), gruplu satırlar (Ayarlar/Hesap değiştir), en altta OutlinedButton çıkış. TUZAK: levhaya FilledButton koyma — test onay kutusunu `find.byType(FilledButton)` ile bulur.
- **Ana ekran üst çubuğu (2026-11-06):** arama hapı (50 dp, yuvarlak) hesap + ⋮'yi İÇİNE alır (`_SearchField.trailing`); AppBar `actions` boş. ⋮ → "Görünüm ve süz" = `showFilterSheet`. Takvimde dar ekranda görevler/hatırlatıcılar/rutinler/Google ⋮'te (başlık sıfıra sıkışıyordu); rutin simgesi `kRoutineIcon`.
- **Tema aileleri 10:** + `cream` (açık saman), `peach` (sıcak pastel — okuma/disleksi önerisi), `mint` (yeşil-mavi, düşük yorgunluk). TUZAK: `balloon_list_theme_fixes_test` vurgu doygunluğu > 0,2 ister.

## 2026-11-07 — Klasör şeridi sabit, sabit bölmede PDF şeridi alt satırda, izinsiz tarama
- **Klasör şeridi** yana kaydırılan ızgaranın DIŞINDA (sabit başlık, `shelfAsStrip`); ızgarada yalnız kök KARO rafı. Kök neden: şerit segmentKey'li `CustomScrollView`'in sliver'ıydı → çekişte parmakla kayıyor, geçişte solup yeniden kuruluyor, yatay konumu sıfırdan seçili çipe kayıyordu. Seçili çip artık ORTALANMAZ (`_EnsureVisible` en kısa kaydırma, +24 dp pay). Ev düğmesi ana sayfada da yerinde (dolu) — eskiden giriş/çıkışta şerit 56 dp sıçrıyordu. Bekçi: `test/folder_strip_fixed_test.dart`.

## 2026-11-07 — Tablet turu (HUAWEI MatePad 11, GMS'siz, M-Pencil) — kök nedenler
- **GMS'siz Android (Huawei/HarmonyOS; GBox uygulamaya GMS vermez):** `gmsInstalled()` (yerel `gmsInstalled`, manifestte `<queries>` gms). Yoksa giriş doğrudan tarayıcı; Drive/Gmail/Takvim jetonu `browserScopeToken` → yerel `googleScopeToken` (Firebase `startActivityForReauthenticateWithProvider`, kapsamlı). TUZAK: FlutterFire Google'da `credential.accessToken`'ı HEP null verir (GoogleAuthCredential, OAuthCredential değil) → jeton Kotlin'de Parcel'dan `ya29.` dizesi olarak çıkarılır. Jeton ~55 dk şifreli depoda (uid'e bağlı); dolunca "bağla" yeniden ister (yenileme anahtarı yok). FCM/App Check GMS'siz çalışmaz (yakalanıyor).
- Cihaz notları: MatePad 11 = 1600×2560, 400 dpi (yatay 1024×640 dp); Huawei `adb install` iki onay penceresi ister ("Devam et" → "Yükle"); `input stylus` Android 12'de kalem türü üretmez, `/dev/input` SELinux'la kapalı → gerçek kalem davranışı elle denenmeli. Avast mağaza dışı APK'yı "şüpheli" bildiriyor (sezgisel).

## 2026-11-07 — Tablet: avuç, kalem tıkı, fiziksel klavye
- Play yorum analizi ve sonraki fazlar: `docs/arsiv/planlar/YORUM_ANALIZI_PLANI.md`.

## 2026-11-08 — Kalem, satır hatırlatıcısı, bildirim düzeyi, kapanış kasması
- **Bildirim önem düzeyi = kanal** (`domain/reminder_level.dart`): Android kanalının önemi kurulduktan sonra DEĞİŞMEZ, o yüzden düzey başına ayrı kanal. '' = `high` = eski `reminders` kanalı (eski hatırlatıcılar değişmeden çalar; "Sık" etiketi). Acil = `Importance.max` + `fullScreenIntent` + alarm; `USE_FULL_SCREEN_INTENT` YALNIZ `src/kisisel` manifestinde (Play beyanı ister). `showWhenLocked` BİLEREK yok (kilitli notlar kilit ekranında açılmasın). Not alanı `reminderLevel` (gerçek alan, `toMap` koşulsuz).
- **Ana ekran şeridi + rozet** (`data/due_state.dart`, `domain/due_items.dart`): "şimdi" (`dueClockProvider`) yalnız sonraki hatırlatıcı anına kurulan tek seferlik Timer ve `AppLifecycleListener.onResume` ile ilerler. Rozet için YENİ BAĞIMLILIK YOK: başlatıcılar rozeti bildirimden çizer → sessiz düşük önemli tek özet bildirimi (`badge` kanalı, `number`, yük `due` — `note:` değil, mutabakat dokunmasın). Bedel: sayı > 0 iken perdede bir satır. Web'de şerit `tasksStreamProvider`ı da dinler (eskiden web'de görev dinleyicisi yoktu).

## 2026-11-08 — Oturum B (arama, yazı tipi, Gmail, takvim pratikliği)
- **Yazı tipi seçici = tema levhası** (`_showAppFontSheet`: perdesiz alçak levha, `_FontChoiceCard` "Aa", anında uygula, Vazgeç).
- **Not seçici** `NoteTargetPicker`/`showNoteTargetPicker` (note_target_picker.dart): yeniden kullanılabilir; Gmail "Nota ekle", takvim "Mevcut notu bağla", nottan rutin bunu kullanır.

## 2026-11-08 — Oturum D (18 maddelik ikinci tur)
- **Kare/çember karışması — kök neden:** eski tanıyıcı eksene hizalı kutuya göre ölçüyordu (yuvarlak köşeli kare elips hatasında düşük; eğik dikdörtgen hiç). `recognizeClosedShape` (ink_recognize): dışbükey zarf → en küçük döndürülmüş kutu; elips/dikdörtgen/dörtgen/üçgen ortalama uzaklık/köşegen ile yarışır (dörtgen ×1,25 ceza). En/boy ≤ 1,18 → kare/daire (`regular`), dik açılı değilse serbest dörtgen (`InkFixKind.quad`), eksene < 10° eğim düzelir. Basılı tut-şekle-dönüştür de bunu kullanır. Şekil aracına Üçgen + Tablo (3×3, tek çizgi, kenardan geçer).

## 2026-11-08 — Oturum E (15+2 maddelik üçüncü tur)
- **Seçimde geri tuşu çalışmıyordu — kök neden `BackCloses`:** Flutter rotadaki BÜTÜN PopScope'ları çağırır; KAPALI bir `BackCloses` (ör. kalem kipi kapalı) `_onPop`'ta `orElse: this` ile kendini "kapatıp" `_consumed = true` yapıyordu → ekranın kendi geri işi (`BackCloses.handling` true) hiç çalışmıyordu. Açık panel yoksa artık olay tüketilmez. Bekçi `items_selection_back_editor_test`.
- **İpuçları (TipOnce) artık ÜSTTE ve dokunuş geçirgen** (OverlayEntry, IgnorePointer; ilk dokunuşta kalkar). Eskiden alttaki SnackBar ek menüsünü/alt çubuğu örtüyordu. Kalem ipuçları: `penToggle`, `penShapeHold` (2. çizgi), `penEraserHold` (5. çizgi).
- **Ana ekran:** basılı tut = doğrudan sürükle (`_ReorderableNoteCell`, seçim kapalıyken de). Yer değişmediyse ve yol < 12 dp → eski iş (seçim), sıra KAYDEDİLMEZ (ölçüt "elle"ye dönmez). Süzgeç/klasör/aramada yalnız seçim (alt kümede sıra anlamsız).

## 2026-11-09 — Oturum F (yeni özellik denetimi)
- **Levhadan "Geri al" görünmüyordu — kök neden:** kök ScaffoldMessenger bildirimi alttaki SAYFANIN Scaffold'unda çizer; açık modal levha onu örter (takvim gün levhasında hızlı sil). `showUndoSnackBar` açılır rotadan (PopupRoute) çağrılınca kök Overlay'de kendi şeridini (`_OverlayUndo`) gösterir. Bekçi `undo_over_sheet_test`.
- **İpucu şeridi "ilk dokunuşta kalkar" değildi:** Listener yalnız kendi kutusunda isabet alır → `GestureBinding.pointerRouter.addGlobalRoute` (dokunuşu tüketmez).
- F54.2 `lastBackupProvider` (prefs `last_full_backup_at/_count`): yalnız dosya gerçekten kaydedilince (Android Kaydet onayı / paylaşım `dismissed` değil).
- **Jest dolumu (2026-11-09 isteği):** basılı tutma jestlerinde dolan halka `core/widgets/hold_progress_ring.dart` (`HoldProgressRing`: ilk %25–30 ÇİZİLMEZ — çizerken sürekli yeniden kurulan "şekle oturt" beklemesi titremesin; `HoldRingArea`: Listener, dokunuşu tüketmez). Kalem: `InkController.holdProgress` (şekle oturt + silgi önerisi, `kInkHoldDuration` 550 ms, zamanlayıcı her iptal edildiğinde `_clearHold`). Ana ekran: kart sürükleme (`kLongPressTimeout`) ve klasörler arası yana çekişte etiketin altında dolum çubuğu (`swipe-progress`, eşik `commitFraction`).

## 2026-11-09 — Oturum G (yorum analizi: çokgen, çizgi ucu, son yazı biçimi)
- **Son yazı boyutu/tipi (F56.3):** `NoteFormatMemory` (cihaz tercihi, `main.dart`'ta `attach`). Yalnız GÖVDE ve notun tamamı (seçili aralık, başlık hariç) değişince yazılır; `createNote` her yeni notu bu değerlerle doğurur; varsayılana dönünce anahtar silinir.

## 2026-11-09 — Oturum H (tablet cihaz turu dönüşü)
- **Geniş ekranda not notun yerine** (`NoteContextPush.pushNote`): `/note/*` + `splitActiveFor` → `pushReplacement`; geri = liste. Telefonda yığın kalır. Test `note_route_test`.
- **Dolum halkası** yalnız elle sıralamada (`_ReorderableNoteCell`) çiziliyordu; süzgeç/arama/sıralama/liste görünümü ve seçimdeki hedef hücrelere de eklendi.
- **Aramadan/şeritten açılınca kaydırma** açılış geçişi bitince (`_afterOpenTransition`) — eskiden geçişle aynı anda olup görünmüyordu.
- **Yan sabitleme** (`editor/pinned_side.dart`): `PinnedSideMemory` (üst/sol/sağ + oran), `PinnedMediaPane(fill:)` sütunu doldurur (çubuktan boy sürüklenmez), `PinnedSideLayout` ayraçlı Row; yalnız ≥ 840 dp. Yerleşim değişince not gövdesi ağaçta yer değiştirir (durum sıfırlanır — bilinçli).

## 2026-11-09 — Oturum J (tablet senkron + hızlı satır sadeleşmesi)
- **Tablet "missing initial state" + "headful operation"** KÖK NEDEN: GMS'siz Android'de Google girişi/kapsamı Firebase'in `firebaseapp.com/__/auth/handler` sayfasından geçiyordu; Huawei tarayıcısı Google dönüşünü başka sekmede açınca `sessionStorage` boş → giriş bitmiyor (senkron da bu yüzden yoktu), yarım akış Firebase'de "sürüyor" kaldığı için sonraki deneme "headful". Çözüm `auth/data/loopback_oauth.dart`: masaüstü OAuth (PKCE + `http://127.0.0.1:<port>` yerel sunucu, `GOOGLE_DESKTOP_CLIENT_ID/SECRET` dart-define; boşsa eski akış), yenileme anahtarı `jeton|bitişMs|uid|yenileme` (4. alan) şifreli depoda → saatlik "bağla" yok. Kapsam pencereleri `browserScopeToken`'da sırayla; Kotlin `pendingAuthResult` yarım akışı sürdürür. Konsolda masaüstü istemci kullanıcı işi (KALANLAR J0).
- **☐/☑**: paylaşım biçimi yapıştırmada (`ItemsEditor._lineMarker`, `itemsFromText`) art arda soyulur — Telegram turunda "☐ ☐" birikiyordu.
- Klasör düğmesi (sol alt) kalktı; liste ayracı 24 dp + tutamak, not açıkken sütun = genişlik/220 (1–3).


## Görünüm ve süz levhası (2026-11-10)
- Başlık "Görünüm ve süz"; TUTAMAK YOK (`showDragHandle: false`) — M3 tutamağı üstte ~48 dp ölü şerit açıyordu. Aç-kapa seçenekleri `_Option(toggle: true)` çip (✓ simgesi, `Semantics.toggled`), 48 dp anahtar satırı DEĞİL. Klasör satırı (`homeFolderStripHiddenProvider`) ve takvim şeridi (`homeCalendarStripProvider`) aç-kapası burada; ⋮ menüsünden kaldırıldı. Tür + Durum tek "Süz" kartında, satır başında küçük ad.
- TUZAK: `SegmentedButton`'a `VisualDensity.compact` verme — 40 dp'ye iner, `accessibility_test` 48 dp kuralı düşer. Görünür alana giren küçük `TextButton` (Elle sırala) `MinTapTarget` ister.
- **Alt çubuk düzeni (P57, 2026-11-13):** sıra `UiPrefs.barOrder`/`aiOrder` (boş = varsayılan, `UiPrefs.orderOf`); yeni çubuk düğmesi = `UiItem` kimliği + `barLeftDefault`'a ekle + editördeki `byId` haritası + `PersonalizeBarList.describe`. Varsayılanda görünmemesi gereken düğme `optIn`'e girer (kayıtta `+kimlik`).

- **Titreşim tek kaynak (P38, 2026-11-13):** `HapticFeedback` doğrudan çağrılmaz, `AppHaptics` (`lib/core/haptics.dart`): `tick` seçim, `thud` tamamlandı, `heavy` tutma/yıkıcı, `heaviest` yalnız çöpe bırakma. Göçte tür DEĞİŞMEZ. Mandal `design_tokens/budget.json` `haptic` (yalnız düşer; P55/P56 çitindeki 35 çağrı göçünce 0). Yıldız/iğne tepkisi `core/widgets/toggle_pop.dart` (yalnız boyama, ağaç şekli sabit).

## 2026-11-14 — P59 geniş düzen dönüşü + mini pano ölçeği
- **Kapanış geçişi:** KÖK "web/tablette nottan dönüşte animasyon yok": rota `/` olur olmaz sağ bölme 0 genişliğe iniyordu → notun çıkış geçişi görünmüyordu (c34ed0ae'nin liste solması yetmedi). `SplitShell._closing`: kapanışta düzen 300 ms "not açık" kalır, sonra TEK ADIMDA tam genişlik + `_back` solması. Bekçi `fullscreen_pull_test` + bütçe S26.
- **Mini pano:** bölmede sütun `paneColumnsFor(genişlik, paneCardScaleProvider)` = genişlik/(220×ölçek), 1–4; `PinchColumns.onCommit` bölmede `setColumns` (yarım sütun payı). Genel `gridColumnsProvider` yalnız tam genişlik ızgarası. Ölçek alt sınırı 0,5 → dar bölmede 4 sütun çıkmaz (kart ≥ 110 dp).

## 2026-11-14 — K32 iki not yan yana (tablet yatay)
- **Karar 1:** ikinci not URL'de DEĞİL — `SplitShell`'in üçüncü sütunu (`lib/app/second_note.dart`: `secondNoteProvider`, `twoNoteLayoutFor`). İç gezgin yok, `NoteEditorScreen` doğrudan gömülür; derin bağlantı/geri/web geçmişi değişmez. Yalnız yatay ∧ içerik ≥ 784 dp; üçü sığmazsa liste `autoHides` (☰ göz atma), tam ekran/göz atmada yandaki Offstage.
- **Karar 5:** geri = birincilin PopScope zinciri → birincil kapanır → yandaki de (kabuk `_closing` bitince). Yandaki editörün `PopScope.canPop` HEP true (kabuk sayfasına kayıtlı; false kalırsa çıkış kilitlenir).
- **Karar 6:** aynı not iki bölmede olmaz: `pushNote` hedef yandaysa önce kapatır + bir kare bekler; bağlamsız yollar için kabuk kuralı (birincil = yandaki → kapat).
- **TUZAK:** yandaki bölmede `context.pop()`/`Navigator.pop` BİRİNCİL notu kapatır. Editörün kendini kapattığı her yer `_closeEditor()` hunisinden geçer (silindi, bulunamadı, kalem bitti, kayıt bitince geri, `_delete`, `_toggleArchive`); yeni kapanış yolu da onu kullanır. Yandakinde tam ekran/☰/ana sayfa çizilmez, genel sağlayıcıları (`noteFullscreenProvider`, `listPeekLocationProvider`) yazmaz.
- **Kök neden (S27):** editör kökü `ref.watch(notesStreamProvider)` (geri bağlantı çipi) ile liste akışının HER yayınında kuruluyordu (telefonda da her kayıt yankısı) → `select(var mı)` + çip kendi `Consumer`ında. Kabuk klavye karelerinde yeniden kurulunca yandaki bölmeye yeni widget örneği gidiyordu → `_secondPane` örneği saklar.
- Tek mikrofon: öbür editörde dikte/kayıt sürerken mikrofon alınmaz (`_micBusyElsewhere`, `_live` kümesi).

## 2026-11-14 — Levha tutamağı, güvenli alan, öksüz grup
- **K-D7 kalktı (kullanıcı isteği):** başlıklı (✕'li) menü levhasında da TUTAMAK var (`showActionMenuSheet`, `showNoteActionsSheet`, sabit ek ⋮ `_openSheet`). Aşağı çekerek kapatma kullanıcının beklediği yol.
- **`showAppSheet` varsayılanı `useSafeArea: true`:** uzun levha durum çubuğunun altına girmiyordu ⚙/✕ çakışıyordu (KÖK: `useSafeArea:false`'ta modal levha üst dolguyu SİLER, içteki `SafeArea` işe yaramaz). Çağrılarda `useSafeArea: true` yazma (lint: gereksiz argüman).
- **Öksüz madde (hızlı satırdan düşen):** menünün TEK grubu varsa o grubun sonuna katılır; ayrı tek maddelik "Diğer" yok (ana ekran ⋮ "düzensiz" bulgusu). Çok gruplu menüde "Diğer" kalır.
- Gizli ek özeti (`CardHiddenMediaLine`): tek ekin adı ikinci satırda; yükseklik tahmini 22 → 38 (`estimateNoteHeight`).
- Başlığı üst çubukta duran notta (SABİT EKLİ metin notu da! `_barTitle`) hızlı satır hiç kurulmuyordu (KÖK: `title: _barTitle ?? _typingTitle(...)`). Şimdi `KeyboardSwitch(onlyWhileEditing:)` — yalnız gövde alanı odaktayken (`_fieldFocusedN`); çubuktaki başlık düzenlenirken başlık yerinde kalır. TUZAK: anahtarı odakla takıp sökme (ilk kurulum klavye karesine düşer, S17 79→248). `KeyboardSwitch` artık dinleyiciyi kendi tutar (VLB yok), `TickerMode` yalnız `pauseHidden: true` (hızlı satır); `_HintGlow` `TickerMode.getValuesNotifier` dinler → S17 metin ilk kare 45→37.

## Tasarım ilkeleri ve yapılmayacaklar (kalıcı; DENEYIM_PLANI §2/§4, P53 2026-11-14 buraya taşındı)

Tam plan: `docs/arsiv/planlar/DENEYIM_PLANI.md` (belirteç tabloları §2.1–2.3). Görünüş/yer değiştirmeden önce `python tool/design/istek_tara.py <dosya>`.

Beş ilke:

1. **İçerik konuşur, krom susar.** Bir ekranda en koyu/en doygun yüzey kullanıcının
   notudur. Renk yalnız DURUM ya da TEK birincil eylemdir.
2. **Ekran başına tek dolu birincil düğme** (ana ekranda "+").
3. **Aynı iş her yerde aynı kılıkta.** Başlık, bölüm adı, karo tek bileşen.
4. **Hareket yön söyler, süs değildir.** Giriş 200–300 ms, çıkış 2/3'ü; yalnız boyama.

### Yapılmayacaklar — kullanıcının eski istekleriyle çelişir (§4)


| # | Fikir | Çeliştiği istek (kod yorumu) |
|---|---|---|
| Y1 | Arama hapından ✨ ya da süz düğmesini çıkarmak / gizlemek | 2026-11-06 "boştayken AI tuşu görünmüyor" → HEP GÖRÜNÜR (`dashboard_widgets.dart:408`); 2026-11-06 "arama çubuğu profil ve 3 noktayı da kapsasın" (`:305`) |
| Y2 | Klasör çipinde sayıyı adın yanına almak | 2026-10-31 "not sayısını simgesinde üssü şeklinde yaz" + "görünür alana maksimum klasör butonu sığsın" (`folder_tile.dart:583, 594`) |
| Y3 | Ev düğmesini kaldırmak ya da "Tümü" çipiyle birleştirmek | 2026-11-06 "klasörlerde ana menüye dön düğmesi olmalı" (`dashboard_shelf.dart:184`); ayrıca ana sayfa ≠ "Tümü" (`showAllNotesProvider`) |
| Y4 | Takvim şeridini 7 güne indirmek ya da varsayılan gizlemek | 2026-11-08 "en üstte 2 satır yüksekliğinde takvim satırı; bugünden itibaren 10 gün" (`home_calendar_strip.dart:20`) |
| Y5 | Etiket hapını nötr yapmak | 2026-11-05 "etiketler çok sönük görünüyor, temaya göre renklendirilebilir" (`tag_pill.dart:3`) |
| Y6 | Not menüsünü iki sütunlu "simge + yanında yazı" satırlara çevirmek | 2026-10-20 "not menüsü üstteki 4'lü gibi simge olsun, 3 sütun olsun" — iki sütun satır ESKİ hâldi (`action_menu_sheet.dart:375`) |
| Y7 | Başlık satırındaki "+"yı çip satırına almak / boşken çip satırı açmak | 2026-08-09 "artı butonu başlık satırında olsun; etiket yoksa etiket satırı oluşmasın" (`note_editor_screen.dart:3410`) |
| Y8 | Not üst çubuğuna geri oku eklemek | 2026-11-03 sıkı üst çubuk, 2026-11-05 "üst alanda sadeleşme" (`:472, :4785`); sistem geri hareketi var |
| Y9 | Alt kapsüldeki ses düğmelerini birleştirmek / gizlemek / uzun basışa almak | 2026-09-01 "mikrofon direkt sesle yazma olsun, yanına farklı bir mikrofon" (`:2729`); 2026-10-11 tek kapsül (`:4576`); 2026-10-20 (`add_catalog.dart:41`) |
| Y10 | Sabit ek çubuğundan T / balon / görünüm anahtarı / kalemi ⋮'e indirmek | 2026-11-09 "menüye girmeden T" (`pinned_media_pane.dart:1326`), 2026-11-05 "açık metin kısmını bulamadım" (`:1413`), 2026-10-16 (`:171`), 2026-11-08 (`:1249`) → K-O6 kullanıcıda |
| Y11 | Ajandada/gün sayfasında satır sonu çöp düğmesini kaldırmak | 2026-11-08 "üzerine tıklayınca ilk açılan yerde silme de olmalı" (`calendar_entry_delete.dart:19`) |
| Y12 | Ay görünümünde gün kâğıtlarını düz ızgaraya çevirmek; çipleri tek satıra indirmek | 2026-11-07 "çok düz, günler arasında belli belirsiz çizgi var" → KÂĞIT HÜCRELER (`calendar_views.dart:322`); "gerekirse 2 satır" (`:394`) |
| Y13 | Telefonda takvim ‹ › oklarını kaldırmak | 2026-11-07 "dar ekranda da var; yalnız kaydırma bilinmiyordu" (`calendar_screen.dart:504`) |
| Y14 | Ana ekranda kaydırınca başlığın çekilmesi | 2026-11-06 ev düğmesi "kaydırılınca kaybolmasın"; 2026-11-07 şerit kök nedeni (HAFIZA "Klasör şeridi sabit") |
| Y15 | AI merkezini yeniden düzenlemek | 2026-09-23 yeniden tasarım, 2026-10-20 "AI sesli not en üstte" (`ai_hub_screen.dart:93, 113`) |
| Y16 | "+" tek dokunuşta doğrudan not; Ekle karolarını yeniden biçimlemek | 2026-10-20 "artı menüsü düzeni" tek panel tek dokunuş (`quick_add_fab.dart:367`); 2026-11-11 düzen kipi |

---

### Yapılmayacaklar (genel)

- §4'teki 16 fikir.
- Yeni özellik, yeni ekran, yeni ayar sayfası. (İzinli tek yeni tercih: `card_show_checked`.)
- Yeni paket. İzinli tek yerel bağımlılık: `core-splashscreen` (K-D8).
- Bulanıklık (`BackdropFilter` — "+" panelinden 2026-10-15'te kasma yüzünden kaldırıldı),
  bulanık gölge, gradyan zemin, ışıltı, paralaks, zıplayan eğri.
- Boy animasyonu — hiçbir yerde. Çubuk yüksekliği değişimi — hiçbir yerde.
- Not başlığı/gövdesi stilini, kalem tepsisini, biçim çubuğunu, sayfa geçiş sürelerini
  değiştirmek.
- 20 tema ailesinden birini silmek ya da renklerini "iyileştirmek" (F80.1'in ölçümlü koyu
  düzeltmeleri hariç).
- `UiItem`, `menuId`, `ValueKey` kimliklerini değiştirmek.
- `dart format lib`, tam test takımını yerelde koşmak, CI kırmızıyken birleştirmek,
  ölçmeden "akıcı" yazmak.

---
