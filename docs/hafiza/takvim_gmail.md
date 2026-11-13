# Hafıza — Takvim, Görevler, Gmail

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

## Kısa kurallar (sıkıştırmada tek satıra inenler)
- **Gmail (F28.1, 2026-11-04):** `features/gmail/`, yalnız GET (`gmail_test` doğrular), kapsam `gmail.readonly` Drive'dan AYRI istenir. TUZAK: `http.Response.body` charset başlığı yoksa latin1 çözer → Gmail JSON'unu `utf8.decode(bodyBytes)` ile oku. Jeton önbelleği `DriveTokenCache` (adı Drive ama kapsamdan bağımsız).
- **Takvim zemini (2026-11-06):** `DashboardBackground.calendar` (`dashboard_bg_calendar`) → `CalendarBackdrop` (ayın ızgarası + günün ilk 3 kaydı, tek abonelik, IgnorePointer + RepaintBoundary) renk/desen/görselin yerini alır; `CardSeeThrough` (InheritedWidget, ızgaranın üstünde bir kez) kartta zemini %22, başlık dışı içeriği TEK `Opacity` (0,3) ile soldurur, gölgeyi kapatır. Yalnız ızgara kartı (liste satırı değil). Opacity katmanı kart başına — bu kip açıkken GLES'te kaydırma maliyeti ölçülmedi.
- **Takvimden not açma (2026-11-07):** `/calendar` SplitShell DIŞINDA — not HİÇBİR ZAMAN ham `router.push(noteRoutePath(..))` ile açılmaz (ikinci kabuk → siyah ekran; "Bu güne not" böyle bozuktu). `router.pushNote`/`context.pushNote`; sayfasız rotadan (gün sayfası `CalendarDayScreen`, `Navigator.push`) `kOutsideShellNotePrefix`. Ay hücresi çift dokunuş → gün sayfası (`WeekPage(dayCount: 1)`); veri `calendarDataProvider`.
- **Takvim tatilleri (2026-11-07):** yerleşik tablo `domain/holidays.dart` (sabit resmî + Diyanet bayram ilk günleri 2024–2032; 2028+ `estimated`). UZATMA / İDARİ İZİN / kesin tarih → `tool/tatiller.json` düzenle + main'e push: CI `deploy` `tool/set_holidays.js` ile `config/holidays`'e yazar (değişmediyse yazmaz), uygulama canlı okur (`holidayOverridesProvider`, APK gerekmez). Tatil AgendaEntry DEĞİL: `CalendarData.holidays` (`HolidayCalendar`, yıl başına önbellek); ⋮ menüsünde aç/kapa (`calendar_holidays`). Hafta başlığı dokunuşu → gün sayfası. Ay şeridi 9,5 pt, yer varsa 2 satır (`kMonthChipTwoLine`); kısa ad sığmalı ("29 Ekim Bayramı", sözcük ortadan bölünmesin).
- **Sola kaydırınca takvim (2026-11-06):** `swipeLeftCalendarProvider` (`swipe_left_calendar`, varsayılan açık) — yalnız Tümü görünümünde İLERİ yön (sola çekiş) `/calendar` açar (`swipeOpensCalendar` saf); klasör/süzgeçte durak gezer. `FolderSwipe` mod kapalıyken de bu yüzden etkin.
- **Takvim taşıma + yedek (F47.5/F46.5):** `movedToDay`/`canMoveEntry` (agenda.dart) — tekrarlı ve Google etkinliği taşınmaz. Yedek `yedek.json` `calendar` alanı (`calendar_backup.dart`, Timestamp → `{"$ts"}`), geri yüklemede not kimliği eşlemesi (atlanan not da karşılığına).
- **Google Takvim (Faz 48):** Firestore'a YAZILMAZ; önbellek SharedPreferences `gcal_cache_<uid>`; kimlik `g:<takvim>/<id>` (`fromGoogle`); bağlı notlar `eventLinks/{googleEventId}`. Testte `GoogleCalendarController.authOverride/clientOverride`. TUZAK: `googleCalendarAvailableProvider` Firebase `authStateProvider` okur — testte override yoksa denetleyici boş durum döner (sorun değil).
- **Google yazma/eşleme (F50.4/Faz 51):** Görevler `planTaskSync` saf (içerik aynıysa yazım yok — ping-pong önlemi; "değişti" = `updatedAt` > son eşleme / Google `updated` > bağdaki `updated`). Takvim yazımı ayrı kapsam `calendar.events` (`connectWrite`), iyimser + kalıcı kuyruk (`gcal_cache_<uid>` içinde `queue`), geçici kimlik `tmp-…`.
- **Takvim SAĞA kaydırınca (2026-11-06, ilk sürüm sola idi):** `swipeOpensCalendar` `direction < 0`; ayar anahtarı adı eski (`swipe_left_calendar`).
- **Google 403 ayrımı (2026-11-06):** "Google Takvim bağlanamadı" kök nedeni F19.B10 — konsolda Calendar API kapalı; 403 hep `unauthorized` sayıldığı için hata yutuluyordu. `google_api_problem.dart`: `SERVICE_DISABLED` artık yetkisiz DEĞİL, `showGoogleConnectFailure` nedeni + "Etkinleştir" (konsol adresi gövdeden). Görevler bağlanınca API kapalıysa bağlantı geri alınır.
- **Levha klavyesi (2026-11-06, yeni etkinlik kasması):** `core/widgets/sheet_keyboard.dart` — `SheetInsetPadding` (viewInsets yalnız ince dolguda) + `focusAfterRouteOpens` (autofocus yerine; klavye levha animasyonu BİTİNCE). Takvim `Scaffold(resizeToAvoidBottomInset: false)`. Yeni yazı alanlı levhada bu ikisini kullan.

## 2026-11-07 — Tablet turu (HUAWEI MatePad 11, GMS'siz, M-Pencil) — kök nedenler
- **Huawei tarayıcısı özel sekmeyi AYRI görevde açar:** Firebase dönüşü sekmeyi kapatmıyor, kullanıcı boş "about:blank"ta kalıyordu. Tarayıcı akışları `browserFlow()` / yerel `bringToFront` (`moveTaskToFront`, REORDER_TASKS; etkinlik az önce bittiği için 10 sn arka plan izni) ile uygulamayı öne alır.

## 2026-11-08 — Kalem, satır hatırlatıcısı, bildirim düzeyi, kapanış kasması
- **Satır hatırlatıcısı = `tasks` kaydı** (TAKVIM_PLANI §10); `TaskItem.level/contact/gmailLink` boşken yazılmaz. `reminderTimePrefix` artık `@visibleForTesting` değil (çip ve şerit kullanıyor).

## 2026-11-08 — Oturum B (arama, yazı tipi, Gmail, takvim pratikliği)
- **Takvim tekerlek:** `PinchZoomDetector.wheelZoom` yalnız yıl/ay görünümünde; `PointerSignalResolver` sayesinde kaydırılabilir alan tekeri önce alır. Hafta görünümünde yakınlaştırma artık gün (ajanda) açar.
- **Gmail:** `gmail_smart.dart` (tarih/saat ayıklama, gönderen); iletiden oluşan not = gövdesinde ileti `webUrl`i olan not (ilgili not çipi bununla bulur).

## 2026-11-08 — Oturum C (12 maddelik istek listesi)
- Gmail çoklu hesap yalnız Android: `AccountManager.newChooseAccountIntent` → e-posta → `googleScopeAuth(account:)`; uygulamanın giriş hesabı değişmez. Jeton anahtarı hesaba göre.

## 2026-11-08 — Oturum E (15+2 maddelik üçüncü tur)
- **Takvim zemini KALDIRILDI** (`calendar_backdrop.dart` silindi; `DashboardBackground.calendar` yok). Yerine `HomeCalendarStrip` (ana ekran tepesi, 10 gün, `homeCalendarStripProvider` varsayılan açık, `homeCalendarStripOpenProvider` daralt). Takvim aboneliği yalnız şerit AÇIKKEN (`calendarDataProvider`). Güne dokun = `showCalendarDaySheet`, basılı tut = `/calendar?day=`. `CardSeeThrough` sınıfı duruyor ama artık hiçbir yerde açılmıyor.
- **Gün levhası canlı veri** (`calendarDataProvider`; eskiden açılıştaki anlık görüntü) + satır başına çöp (`calendar_entry_delete.dart`, geri alınır; tekrarlayan = yalnız bu/hepsi; Google = onay). Ay sayfası çevirince seçim değişmez; "Yeni" seçili gün görünen ayda değilse ayın 1'i/bugün.

## 2026-11-09 — Oturum F (yeni özellik denetimi)
- Takvim şeridi 36 dp: TUZAK — şeritteki `IconButton` varsayılan 48 dp dokunma alanıyla bütün satırı 48'e çekiyordu (`tapTargetSize: shrinkWrap`). Bölüm başlığı üst 8, ayırıcı payı 4. Şerit "bugün"ü `dueClockProvider.select(dayKey)` ile öne gelişte yeniler.


## 2026-11-12 — P48 "telefonda eklediğim etkinlik tablette yok"
- KÖK NEDEN: Google Takvim bağlantısı CİHAZA özgü (`gcal_cache_<uid>` SharedPreferences, Firestore'da iz yok). Bağlı cihazda yeni etkinlik varsayılan Google'a gidiyordu (K2) → Google'ı bağlamamış cihaz görmez. "Bu cihaz" etiketi yanlıştı (Firestore etkinliği bütün cihazlarda). Varsayılan artık Firestore, etiket "Tüm cihazlar" (K2 sapması — KULLANICI ONAYLADI 2026-11-13: "etkinlik her yerde görünecek"). Google'a kaydedilmiş eski etkinlikler yalnız Google'ı bağlayan cihazda görünür.
