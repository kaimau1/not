# Hafıza — Akıcılık (Riverpod/performans, kasma)

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

## Riverpod / performans
- Riverpod 3 görünmeyen ekranın ve DİNLENMEYEN sağlayıcının aboneliğini
  DURAKLATIR: oturum boyu servisler `lib/app/app_services.dart`ta; testte
  sağlayıcıyı okumadan önce `container.listen`. Tek nota/klasöre bağlı akış
  `.autoDispose.family`; autoDispose'u `ref.read` ile okuma.
- Notifier örneği yeniden kurulumda korunur. Hesaba bağlı bellek önbelleği
  `currentUidProvider`ı izlesin (F5.5).
- Kart küçük resmi bütçesi 64 adet / 6 MB; PDF sayfası çizen her yol
  `data/pdf/pdf_page_render.dart`. Tam boy `Image.file/memory` KULLANMA →
  `boundedImage` / `cacheWidth: decodeWidthBucket`.
- Ağır iş `runHeavy` (`core/utils/run_heavy.dart`) — `Isolate.run` doğrudan
  yazılmaz (web'de yok); kapanış statik yardımcıda. Web'de
  `getTemporaryDirectory` yok → `XFile.fromData`.
- `localFileExists` "yok"u 2 sn önbellekler → dosya yazan `forgetLocalFile`.
- `ConsumerState.dispose` içinde `ref` yok. Türetilmiş sağlayıcı içerik
  aynıysa önceki örneği döner (`StableBox`). Toplu işlem tek `WriteBatch`
  (450'lik). Animasyonda `FrameLoop`.
- **Uzun liste (F24.3, 2026-11-04):** madde düz `RichText` (`items_editor_lazy.dart`), dokununca/`requestFocus`la gerçek alan. Odak için `_LazyFocusNode` (yeni odak yolu da `requestFocus` kullansın). Düz çizim gerçek alanla birebir: `windowedFieldStyle` + 3 dp imleç payı. Düz çizimin bilmediği görünüm/dokunuş ekleyen satır `_needsRealField`e. Testler `debugEagerItemFields` ile gerçek alan kurar. Kademeli: ilk 16, 500 ms sonra kare başına 2 (100 düz satır bile tek karede 163 ms). Ölçüm tuzağı: SF'deki açılış "680 ms" donma değil bekleme boşluğuydu.
- **Akıcılık ölçümü (2026-11-03, `AKICILIK_PLANI.md`, araçlar `tool/perf/`):**
  Flutter 3.47 Android'de Dart UI = ana iş parçacığı (birleşik, KAPATILAMAZ:
  `DisableMergedPlatformUIThread` motorda yasak) → her platform kanalı
  çağrısının Java tarafı kareyi bekletir. Adreno ≤ 650 → Impeller OpenGLES
  (motor kara listesi). Release'te Skia A/B `am start … --ez enable-impeller
  false` ile; kaydırmada fark yok (sorun Dart). Release'te Dart zaman çizelgesi
  yok; profilde CPU örnekleyici `setFlag profiler true` ister. Test telefonunda
  yan yana "Notlar Ölçüm" (`dev.kaimau.notlar.olcum`, 244 not) kurulu.
  Varsayılan kimlikle `flutter run/drive` o telefonda ASLA (kaldır-kur → veri gider).
- **Kart önizlemesi DİLİM (F21, 2026-11-03):** kart notun yalnız baştaki
  dilimini işler (`card_preview.dart`: `previewSlice` 5 satır / 300 kod
  birimi, grafem sınırında; madde 120). `maxLines` şekillendirmeyi KISMAZ —
  kartta TAM metni maske/biçim/`Text`ten geçiren kod yazma. Örtme dilimden
  64 karakter taşar (kesimde bölünen numara açık kalmasın). `CardPreview.of`
  not ÖRNEĞİ başına (Expando): dilim + TAM metinde parola taraması bir kez.
  Aramada eşleşme görünen başta değilse kesit (`searchExcerpt`; gövde+konum
  süzgecin önbelleğinden, `bodySearchMatch`). Kart TEK abonelik:
  `_cardEnvProvider` + `select` (kayıt `==`) — yeni kart ayarı oraya, karta
  ayrı `ref.watch` koyma; ana ekran halesi de oradan (`NoteCard.frame`,
  hücrede `Consumer` yok). Dilimi 600→300 indirmek LAYOUT'u değiştirmedi:
  kalan kaydırma takılması 33 ms'lik tek vsync, ana + raster BİRLİKTE (K7).
- **Ölçülen kök nedenler (2026-11-03):** kart önizlemesi (F21'de çözüldü,
  yukarıda); tek `TextField` tuş başına
  O(n) (35 KB'ta 90–110 ms); FlutterFire her olayda TÜM koleksiyonu ana iş
  parçacığında kodluyor + `serverTimestamp` kayıt başına 2 olay (27–56 ms
  blok); HeroController her geçişte tüm ağacı geziyor (elle Hero yok, yalnız
  FAB `heroTag`ları). Zamanlama/parça
  hileleri (ilk N madde, kare başına K) belirti yaması — önce kök neden.
- **AKICILIK bulut turu (2026-11-04, cihazda ölçülmedi):** editör kaydı
  2 sn / en geç 10 sn (`kEditorSaveDelay/MaxWait`), otomatik kayıt
  `updateNote(clientTime: true)` (istemci saati → kayıt başına 2. olay yok),
  kapanış/`paused`ta bir kez sunucu damgası; not kapanırken zamanlayıcı
  `Debouncer.pause` (rota kalkınca yazar). Hero: `HeroControllerScope.none`
  go_router'da İŞLEMEZ (her gezginin kendi HeroController'ı) → sayfalar
  `withoutHeroWalk` (`HeroMode(false)`); `lib`te elle `Hero(` yasak (test).
  Arama vurgusu `SearchHighlight` boya katmanı (span değil): kart önbelleği
  anahtarı "arama var mı", canlı sorgu `_liveQuery` — vurgu metne span olarak
  geri KONMAZ (sorgu başına kart kurulumu/şekillendirme, 139 ms).
- **AKICILIK 2. tur (2026-11-04, cihazda ölçülmedi):** editörün not akışı +
  senkron göstergesi TEK yerel dinleyici (`_DocHub`, Firestore örneği başına;
  not akışı metadata-only olayı `deepDataEquals` ile eler) — yeni tek-belge
  dinleyicisi açma, `_sharedDoc`u kullan. Not geçişinde `Opacity` YOK
  (görüntü boya alfası, `_FadeSnapshotPainter`). Açık not sıralamada
  TUTULUR (`sortHeldNoteIdsProvider`), kapanış başında bırakılır. Açılışta
  servisler kare başına bir (`AppServices` kademeleri; kilit/derin bağlantı/
  paylaş ilk karede) — yeni servis kademeye eklenir. Segment geçişinde
  ayrılan ızgara `SnapshotWhenLeaving`. Kanal sayacı: debug/profil
  `ext.notlar.channels` (`VM.channels()`). F24.2 saf pencere modeli
  `text_window.dart` (bağlı değil). Bulutta YAPILMAYANLAR + gerekçe:
  F23.5, F24.3, F25.2, F22.4 → KALAN_ISLER F19.F1–F3.
- **Pencereli yazma (F24.2, 2026-11-04, telefonda LAYOUT p90 122→12 ms):** `editor/windowed_body.dart`. MODEL HEP `_bodyController`; alan `_bodyField` (yazarken `BodyWindow.win`). Yalnız odaklıyken, ilk tuştan sonra, ≥ 6000 krk; ek etiketi (📎), yüzen görsel, not içi arama, bekleyen biçim, sayfalı/mürekkepli not → tek alan (`_windowAllowed`). `displayText` veren yerde `_bodyField.text` kullan. TUZAK: alan State'i `_bodyFieldKey` ile taşınır (yoksa klavye kapanır); parça `RenderEditable` genişliği için sağdan 3 dp pay + birleşmiş giriş stili ister (yoksa satır zıplar, test sabitler); alt parça kimliği SONDAN uzaklık (baştan olsa yazınca bütün alt parçalar yeniden yerleşir, yeri de bayatlar); klavyeden gelen eski pencere durumu `_isStale` ile yazılmaz (paragraf çoğalırdı). Gerçek klavye önerisi/dikte denenmedi (KALANLAR #47).
- **Anında içerik (F25.2, 2026-11-04):** `home_snapshot.dart`, arka plana geçişte ilk 30 kartın KISALTILMIŞ kopyası tercihte; yalnız dashboard `loading` dalında, `SliverIgnorePointer` ile çizilir. TUZAK: depo akışına ya da editöre SOKMA (kısaltılmış not tam notun üstüne yazılır; eksik liste hatırlatıcıları "silinmiş" sanır). Kilitli/parola notu içeriği yazılmaz; sabitliler önce girer (yoksa liste gelince zıplar). Tercih anahtarı `home_snapshot`, hesap çıkışında silinmez (uid eşleşmezse okunmaz).
- **Metin eşiği (F24.1, ölçüldü):** tek alanda LAYOUT ~5 ms/KB → pencere eşiği 2500, pencere 1500; 4–6 KB tahmini yanlıştı. Firestore olayı not sayısıyla doğrusal: 200 not 593 KB / 11 ms Dart, 414 not ~1,2 MB / 21–27 ms (F22.4'ün gerekçesi). Açılışta ana iş parçacığına düşen saf hesap arıyorsan `prof_cold.py` (boş çöpte parmak izi böyle bulundu).
- **Ölçüm tuzakları (2026-11-04):** kapanış "99 ms donma" yanılgıydı (AKICILIK Ek B notu). Uzun ölçüm + şarj telefonu 52 °C'ye çıkardı, MIUI "Aşırı ısınıyor" verdi: sayılar geçersiz; `dumpsys battery | grep temperature` ile bak (derleme arasında `KEYCODE_SLEEP`). Telefon yan dönebilir: release uygulaması döner (senaryo koordinatları bozulur, `dumpsys input | grep SurfaceOrientation`), profil derlemesi dikey kilitli. Veri setini ikinci kez içe aktarmak kopya sayılır; `OLCUM_SEED` ile başka set. Ölçüm uygulamasında (`.olcum`) artık 414 not var, stres notları dipte: arama ile bul. Soğuk açılış profili: `am start … --ez start-paused true`, sonra profiler + `resume`.
- **Klavye turu ölçümü (F38.7, 2026-11-05):** `tool/perf/klavye.py`: birikim yok, kare başına ana ≤ 15 ms, raster ≤ 10 ms; yalnız `Scaffold` kabuğu kurulur. Kapanış sonu 33 ms ×4–5 uygulama işi değil (tahmin: sistem). SF aralığında ~500 ms imleç yanıp sönmesi, ilk aralık boşta bekleme: takılma sayma. `note_screen_chrome_test` 20 turu sabitler. TUZAK: Bash aracında tırnak içeren heredoc ve `rtk grep` + glob takılabiliyor: uzun betiği Write ile dosyaya yaz.
- **Klavye/kapanış kasması (2026-11-03)**: madde büyümesi klavye oynarken
  320 ms bekler (`_keyboardMoving`); örtülü pano `FreezeWhenHidden` ile
  donar (MediaQuery geçirmez); yetişme `noteRouteClosing` bitince +120 ms.
  Cihazsız tanı: `tester.view.viewInsets` kare kare + `debugOnRebuildDirtyWidget`.
  TUZAK: debug'da `MediaQuery` bildirimi pahalı, release'te değil.
- Ana ekran ızgarası deterministik sütun ataması (`balancedColumnAssignment`).
  Kesme noktası geçişinde `DashboardScreen` başka yerde yeniden kurulur →
  kaydırma `DashboardScrollMemory`de ORANLA taşınır (F18.11).

- Levha kapandıktan sonra sağlayıcı okunacaksa levhanın `ref`i DEĞİL, açan
  ekranın `ProviderScope.containerOf`u (2026-11-03: hesap levhasında "Oturumu
  kapat/Hesap değiştir" bu yüzden sessizce çalışmıyordu).

## 2026-11-08 — Kalem, satır hatırlatıcısı, bildirim düzeyi, kapanış kasması
- **Not kapanış kasması — kök neden:** sıralama tutması (`sortHeldNoteIds`) kapanışın İLK karesinde bırakılıyordu → abonelikler sürerken zaten yeniden hesaplanan `filteredNotesProvider` ikinci kez hesaplanıp pano ekranı kuruluyordu; pano o sırada `FreezeWhenHidden` ile donuk olduğundan görünür faydası yoktu. Bırakma `dispose`ta; kapanıştaki tarih önerisi ayrıştırması +700 ms. Cihazda ölçülmedi (KALANLAR §2 A12).

- **Bütçe testleri (F59, 2026-11-11):** `test/perf_budget_test.dart` S1–S16 (S10 `note_package_open_test`); bütçe = bugünkü ölçüm, `budgets.json`'da `bugun`/`hedef`/`neden`, yalnız DÜŞER. Düzenek: `_count` (tür başına kurulum), `_LiveRepo` (gerçek depo + sahte Firestore: kendi yankısı), `_pumpHome` (bölünmüş kabuk). Tuzaklar: levha/panel için `pump()` + `pump(400ms)` (tek `pump(500ms)` animasyonu başlatmaz); `CountingNotesRepository` `isOwnEcho` bilmez (yankı testi `_LiveRepo` ister). Açık bulgular: 30 maddeli notta ilk klavye açılışında `ItemsEditor` kare başına kuruluyor (S8); **yedek/not paketi `Note.pageInk` taşımıyor** (`encodeNoteJson`). Kalem A/B: `tool/perf/ab_kalem.py` (dolu sayfa `hazirla 1500` ile cihazda üretilir).

- **Klavye açılış titremesi (F60.S5, 2026-11-11):** kök — editör `Scaffold`'ı `MediaQuery`'ye bağlı, klavyenin HER karesinde iskeletini kurup diziyordu; hızlı satır ilk klavye karesinde sıfırdan kuruluyordu; `PinnedMediaPane` evreyi `setState` ile alıyordu. Çözüm `KeyboardInsetScope` (`core/widgets/keyboard_snap.dart`): Scaffold'ın üstünde, alt ağaca KARARLI MediaQuery. **Kural:** kapsamın altında klavyeyi izleyen yeni widget `MediaQuery.viewInsetsOf` DEĞİL `KeyboardInset.liveOf/openOf` okur (yoksa oturana dek 0 görür). S17: ilk kare 320 → 45 kurulum, hareket 87–96 → 54. Açık: `ItemsEditor._growBudget` uzun listede açılıştan 500 ms sonra kare başına ≈480 kurulum (erken dokunuşta klavye açılışına denk gelir); üst çubuk `LayoutBuilder`'ı altındaki her `setState` çubuğu dizime işaretler.
- **F68.1 önizleme tutma (2026-11-12):** `heldNotePreviewProvider` = not kimliği → değişiklik ÖNCESİ örnek; yalnız `filteredNotesProvider` okur (depo/editör/hatırlatıcı `notesStreamProvider`'da güncel kalır). Örnek `touch` ANINDA alınır — sağlayıcı tembel hesaplandığı için "ilk hesapta gördüğünü tut" kayıt yankısıyla aynı tura düşüp YENİ örneği tutuyordu (test bunu yakaladı). `_mutate(immediate: true)` (yıldız/sabitle/renk) tutmayı bırakır. Bütçe S12 iki pencereli: yazarken+kayıt 0/0, durunca 1/1.
- **Ölçüm tuzağı (S12):** düzenekte `updatedAt`'siz notlar ilk kayıtta "Bugün" bölümüne taşınır → bölümler yeniden dizilir, bütün kartlar yeniden MOUNT olur ("13 kart" buydu, kart önbelleği kaçağı değil). Gerçekte de eski bir notu ilk düzenlemede bir kez olur; artık yazma durunca.
- **`DashboardPaneScope.anchorNoteId` bildirim sebebi DEĞİL (F68.2, S12b):** çapa yalnız sütun kipi değişirken okunur; bildirirse nottan nota geçişte bütün pano kurulur.
- **`ab_hepsi.py` ilk tam koşu (P43, 2026-11-13):** altın taban `docs/perf/altin_taban.json` (9c837495). Aynı APK A=A'da evre gürültüsü ±%15 (`yaz` LAYOUT 262–302, `menu` 44–75) → "B ortancası > A en kötüsü + %10" kuralı 13 evrede yanlış alarm verir (kabul KALDI); AC şarjda her koşu telefonu 40 °C'ye ısıtır, betik 37'nin hemen altında başlar → serin altın tabana karşı +%20–40 kayma. Açılışta UI ms anlamsız (2 kare) → karar `ilk_kare_ms` (378–413 ms). Koşu başına ~6 dk + soğuma ~10 dk (tam koşu ~70 dk).
- **2. tur (2026-11-13 sabah):** eşik %20 + < 34 °C başlangıç ile A=A A/B kararı 2/2 GEÇTİ (en büyük kayma `menu` UI +%11, `yaz` LAYOUT +%9). < 34 °C'de koşu ~5 dk + soğuma ~3 dk (6 koşu ~45 dk). Altın taban 6 koşu A=A ortancası; yine de `yaz` LAYOUT oturumdan oturuma 302→377 oynuyor → altına karşı %15 tek başına yanlış alarm verebilir. Geçişte `mCurrentFocus=null` normal — ready() bekler.
