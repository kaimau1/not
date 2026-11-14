# Not Uygulaması — Hafıza (dizin + her oturumda geçerli kurallar)

İş başında BU dosyayı oku, sonra dokunacağın konunun dosyasını `docs/hafiza/` altından aç
(tablo aşağıda). İş sonunda kalıcı karar / kök neden / tuzak varsa İLGİLİ KONU DOSYASINA
ekle (tarihli, kısa); bu dosyaya yalnız her oturumu ilgilendiren kural girer. Sır/anahtar/
kişisel veri YAZILMAZ. **Tavan 30 KB** (`test/hafiza_size_test.dart`). Eski TAM hâl (bölünmeden
önce, 109 KB): `HAFIZA_ARSIV_3.md`; tarihçe `HAFIZA_ARSIV.md` (→ 2026-10-19),
`HAFIZA_ARSIV_2.md` (→ 2026-11-02) — üçü de dondurulmuş, `grep` ile ara. Açık iş `PLAN.md`,
kullanıcının listesi `KONTROL_LISTEM.md`, eski planlar `docs/arsiv/planlar/` (P53, 2026-11-14).

## Ortam
- Flutter **3.47.9** (CI ile aynı); Windows'ta `C:\src\flutter\bin\flutter.bat` (PATH'te değil).
- `dart format` yalnız kendi eklediğin dosyaya (`lib/l10n/generated` hariç: hep formatla).
- CI `flutter analyze` BİLGİ (info) düzeyini de hata sayar: push'tan önce tam `flutter analyze`.
- `flutter install` DERLEMEZ. Yerel APK: `--build-number` + `--dart-define-from-file=env.json` ZORUNLU.
- Tam test takımını yerelde koşma; doğrulama CI (CLAUDE.md). Bulutta SDK/APK ayrıntısı: `ortam_ci.md`.
- Graf elle (`graphify update .`), bayatlar; satır bilgisini koddan doğrula.

## Her oturumda geçerli kurallar
1. Kanıt önce: kanıtı üretmeden düzeltme yazma; üretilemiyorsa "üretilemedi" yaz, bırak.
2. Kök neden: belirtiyi değil, ortak çağrı yolunu düzelt (önce çağıranları Grep'le).
3. "Cihazda doğrulanmadı" ile "doğrulandı"yı karıştırma; telefon gerektiren ölçümü varsayma.
4. Editöre görünür yeni alan/kip/sarmalayıcı: CLAUDE.md kasma listesi + `akicilik.md`.
5. Yeni madde/not alanı: `sameItemsVisually`, `ItemsEditor._sameItems`, `text_merge._sameItem` üçüne de ekle.
6. Editör gövdesiyle aynı Column'daki şeyin boyunu animasyonla değiştirme (`keyboard_jank_guard_test`).
7. Yerel UI durumu için editör kökünde `setState` yok; `ValueNotifier` + dar `ListenableBuilder`.
8. Rota içi panel kapanışı `BackCloses` ile (LIFO); `PopScope`'u körlemesine ekleme.
9. Notu `router.push(noteRoutePath(..))` ile açma; `pushNote` kullan (ikinci kabuk = siyah ekran).
10. Geniş ekranda liste tek örnek, kabuğun sol panelinde; ikinci liste kurma (`SplitScope`).
11. Zemin RENGİ seçen her yol `theme: ''` yazar; `noteSurface` temanın tonunu verir.
12. Sesli not/kaydedici eklentisi tembel kurulur; testte platform kanalı patlar.
13. Firestore'a JS'ten gelen sayı tamsayı olabilir (`1.0` → int): okurken `num` kabul et.
14. Veri silen/taşıyan iş: önce yerel tam yedek, geri alınabilir, `rules-test` yeşil.
15. Kural değişince `cd rules-test && npm ci && npm test`; erişimi gevşetme.
16. Ek senkronu tek yol: `UploadQueue` + `DriveStore`; ek yüklemesi sayfa üstü el yazısını silmemeli.
17. `config/app` bayraklarına (`inkV2Write`, `minClient`) dokunma.
18. Gmail yalnız GET; `http.Response.body` yerine `utf8.decode(bodyBytes)` (charset yoksa latin1 çözer).
19. Google API 403 ≠ `unauthorized` hep; `SERVICE_DISABLED` ayrı gösterilir (`google_api_problem.dart`).
20. Takvim/Görevler eşlemesi içerik aynıysa yazmaz (ping-pong önlemi).
21. Bekleme penceresi oturum düşüren işte `DialogRoute` + `removeRoute`; körlemesine `pop()` yok.
22. Levha klavyesi: `SheetInsetPadding` + `focusAfterRouteOpens` (autofocus değil).
23. `MediaQuery.of(context)` kök/kabuk bağlamında okunmaz; `viewInsetsOf`/`sizeOf`.
24. Ana liste kartı önbelleği: yeni girdiyi anahtara ekle; env'e her build yeni nesne koyma.
25. `main`'e APK işi sürerken push etme (`cancel-in-progress` APK'yı iptal eder).
26. Yerel imza anahtarını commit'leme/yazdırma; ölçüm uygulaması `dev.kaimau.notlar.olcum`, varsayılan kimlikli uygulamaya veri gönderme.
27. Dar ekran kartı: `noteCardSqueezeFor`; geniş ekran kapıları `AppRailScope.visible` + `homeDoors`.
28. Sürüm notu: her `[apk]`'da `assets/guide/release_notes_tr.md` + `_en.md` günün bölümü (aynı tarih kimliği).
29. Yeni tema ailesi eklerken `balloon_list_theme_fixes_test` vurgu doygunluğu > 0,2 ister.
30. Yeni sabit/ölü görünen koda dokunmadan önce `Grep` ile çağıranı doğrula; ölü ise sil, şüphede listele.

## Konu dizini — "şuna dokunacaksan şunu oku"
| Dokunacağın şey | Dosya (`docs/hafiza/`) |
|---|---|
| Ortam, CI, deploy, Android tuzakları, test tuzakları, açık sorular | `ortam_ci.md` |
| Firestore modeli, kurallar, yedek/içe aktarma, ek senkronu | `veri.md` |
| Riverpod, kart önbelleği, kasma, açılış/geçiş performansı; hız sözleşmesi (sonda) | `akicilik.md` |
| Not editörü, klavye, hızlı satır, metin birleştirme, yazım | `editor.md` |
| Kalem, şekil tanıma, avuç reddi, sabit kalemler, ek üstü çizgi | `kalem.md` |
| PDF görüntüleyici, balonlu mod, ek modeli, taranan belge | `ekler_pdf.md` |
| Ana ekran, tema, menüler, ayarlar, geniş ekran/ray, tablet; tasarım ilkeleri + yapılmayacaklar (sonda) | `arayuz.md` |
| Web'e özgü davranış (PWA, tarayıcı kısıtları) | `web.md` |
| Takvim, Görevler, Gmail, hatırlatıcı, tatiller | `takvim_gmail.md` |
| Sesli komut, dikte, çeviri, asistan, AI özellikleri | `ai_ses.md` |

Konu sınırı bulanıksa (ör. kalem ↔ PDF) iki dosyada da `grep` yap; tarihli oturum
notları (`## 2026-11-0X — Oturum …`) konularına göre parçalanıp ilgili dosyalara dağıldı.
