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

## 2026-11-13 — P46: cihazsız bekçi bulguları (S9, S18, S21–S23, S25)
- **Arama, ilk harf iki dalga (S21 114 → 56):** kart önbelleği anahtarı ANLIK sorgu, hücre sarmalayıcısı GECİKTİRİLMİŞ `searchActive` idi → kartlar önce tuşta, sonra gecikme dolup sarmalayıcı türü değişince yeniden kuruluyordu. Kural: kartın yapısını ve sarmalayıcısını değiştiren durum AYNI kaynaktan gelsin (`_cachedCard(searching: searchActive)`). Kalan 56 = 1600 px paydaki canlı kartlar (yerinde güncellenir). YANLIŞ YOL: ızgaraya `ValueKey(searchActive)` — taze `SliverList` kaydırılmış konumda 0'dan o konuma dek bütün kartları kurar.
- **Sayfalı görünümde `onPageChanged` → `setState` (S22 979 → 509):** `itemBuilder` her kurulumda yeni kapanışlı sayfa widget'ı verince canlı sayfalar baştan kurulur. Girdisi değişmeyen sayfa aynı ÖRNEK dönsün (`CalendarScreen._weekPage`; anahtar: veri kimliği, bugün, hafta başı, dakika).
- **Yeni bölümün ızgarası (S23 en ağır kare 2941 → 2361):** gelen ızgara ilk karede 1600 px kaydırma payını da kuruyordu; geçiş boyunca 250 px (`_holdNarrowCache`), 500 ms sonra boşta genişler. Payı değiştirmek için araya dinleyen widget KOYMA (S24 ilk kare mandalı +1 olur): `_GridScrollView` kendi öğesiyle dinler, `buildViewport`'ta payı seçer; sliver'lar aynı örnek kaldığı için kart kurulmaz.
- **Biçim paneli ↔ alt çubuk (S9 `govde_boy_karesi` 34 → 2, jank mandalı 4 → 2):** iki `AnimatedSize` gövdeyi 260 ms her karede diziyordu (kasma listesi md. 6). Boy tek adım; panel içeriği ve dönen çubuk `RevealUp` ile yalnız boyamada. Çubuk notun ilk açılışında oynamaz (`_barSwapped`). Ses hapı `AnimatedSize`ı duruyor (testte kayıt eklentisi yok, kanıt üretilemedi).
- **Not açılışında ikinci kare (S18 788 → 285):** `_measureBodyTop` ilk kareden sonra kök `setState` yapıyordu; değeri yalnız `NotePageCanvas.topLimit` okuyor → `_bodyTopN` + tuvalin çevresinde dar `ValueListenableBuilder`. Kural: kare-sonu ölçümünü kök `setState`'e yazma.
- **Ölçüm tuzağı:** `_frames`'in ilk karesi eylemin kendi pump'larını da içerir (fling'in sürükleme kareleri) — "tek karede 978/2941" gerçek tek kare değil, eylem + ilk kare toplamı. Yerelde `folder_strip_fixed_test` 2. testi CRLF yüzünden kırmızı (Windows checkout), CI'da yeşil.
- **P55'e devreden cihaz maddeleri (P46'da başlanmadı):** F84.1 en kötü 3 evre (`vmsvc.py`; ipucu: S23'te kalan 9 kart pay genişleyince tek karede 413–668 kurulum, S24 kartlara dek 4019, S19 kapanış karesi 523, liste kaydırma %2,3–3,3 kare > 16 ms); F84.2 yazmada en uzun kare 29 → 42 ms (`prof_type.py`; S1/S2 cihazsız temiz → kurulum değil Dart bloğu aranmalı); F84.3 soğuk açılış (`prof_cold.py`, S24 ilk kare 930); F60.5 (`prof_type.py` iki sürüm); F60.S2 birikim (cihazsız üretilemedi, `editor_leak_test` yeşil; cihazda taze açılış ile 30 gir-çık sonrası `ab_klavye.py`); F68.3 gerçek hesapta `prof_save.py` (≤ 12 ms → kapat). P46 commit'leri cihazda ölçülmedi: önce `ab_hepsi.py --altin` (taban 519672b7), KALDI veren evrenin commit'i tek başına geri alınır. Açık cihazsız: ses hapı `AnimatedSize`, S21 kalan 56 kart, S2 mandalı 5/15 (ölçüm 1/1).
