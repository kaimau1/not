# TAKVİM PLANI — Faz 46–53 (takvim, görevler, Google bağlantısı, rutinler)

Kaynak: 2026-11-06 kullanıcı isteği:

> *"Takvim ve görevler özelliği. Google Workspace'te olan, ona çok benzer olacak.
> Google Workspace'teki verileri de bir API ile çekebiliriz, orayla bağlantılı
> olabiliriz. Takvimde hatırlatıcı, o güne not bağlama, notları takvime bağlama
> gibi detaylar. Bir diğer isteğim rutin belirleyebilmek — bu ikinci aşama
> olabilir. İyi mi olur, kötü mü olur, uygulama için fazla mı olur; tüm
> detaylarıyla önce planlayalım."*

Numara `TUTARLILIK_PLANI.md` (Faz 36–45) sonrasından başlar. **Durum: kararlar
VERİLDİ — K1–K10 hepsi önerilen (kullanıcı, 2026-11-06: "önerilerin güzel,
yapalım").** Sıra K10: 46 → 47 → 50 → 48 → 49 → 50.4 → 51 → 52 → 53.

## Bu dosya nasıl kullanılır

"Faz 4X'i yap" → yalnız o faz; maddedeki **KARAR** açıksa önce sor (gece
görevinde en güvenli seçenek + "sabah bakılacak"). Bitince madde `[x]`, Durum
tablosu, HAFIZA, commit/push, CI yeşil. Akıcılık bütçesi (AKICILIK Faz 21/23)
ve tema belirteçleri (TEMA_PLANI) bağlayıcı: takvim ekranı ana ekranın açılışını
YAVAŞLATMAZ (tembel yükleme, ayrı rota).

---

## 1. Değerlendirme — iyi mi, kötü mü, fazla mı?

### Kısa cevap
**İyi olur — ama "Google Takvim'in kopyası" olarak değil, "notların zaman
ekseni" olarak.** Uygulama zaten zamana bağlı çok şey biliyor (hatırlatıcılar,
tekrarlı hatırlatıcılar, günlük brifing, aralıklı tekrar kartları, liste
notları); bunların hepsi dağınık ekranlarda. Takvim onları TEK yerde toplar.
Tam bir takvim istemcisi yazmak ise (davetler, katılımcılar, toplantı odası,
saat dilimleri arası planlama, paylaşılan takvimler) bu uygulama için **fazla**:
Google Takvim bunu zaten iyi yapıyor, biz kötü bir kopyasını yapmış oluruz.

### Neden iyi
| Gerekçe | Kanıt (kod) |
|---|---|
| Altyapının yarısı hazır | `reminder_service.dart` (626 satır: planlı bildirim, 7 çalma önceden, ertele/tamam), `reminder_repeat.dart` (`daily`, `weekdays`, `weekly:1,3`, `monthly:31`, `yearly:2-29`) |
| Google bağlantı şablonu hazır | `google_scope_auth.dart` (kapsam başına jeton, Android sessiz + web açılır pencere), `ScopeTokenCache`, Gmail'in yalnız-GET istemcisi `gmail_api.dart` — Takvim/Görevler istemcisi aynı kalıpla ~300 satır |
| Dağınık ekranlar birleşir | `/reminders` (503 satır), `/briefing`, `/cards` ayrı ayrı; takvimin "Ajanda" görünümü üçünün doğal evi |
| Brifing ve asistan güçlenir | `briefing_screen.dart` bugün yalnız not hatırlatıcılarını okuyor; "bugünün etkinlikleri + görevleri" çok daha faydalı. Asistan zaten `reminderAt`/`reminderRepeat` aracı taşıyor → "yarın 15'te diş hekimi" etkinliğe dönüşebilir |
| Kural/silme hazır | `firestore.rules:100` `users/{uid}/{collection}/**` sahibine açık → yeni koleksiyon kural değişikliği istemez (yalnız `account_service.dart:39` silme listesine + yedeğe eklenmeli) |

### Riskler (dürüst liste)
| Risk | Ağırlık | Önlem |
|---|---|---|
| **Kapsam şişmesi** — uygulama zaten çok büyük (not, AI, Gmail, Drive, kartlar, sesli…) | 🔴 | Faz sınırları sıkı; davet/katılımcı/oda/paylaşılan takvim YOK (§2 "Yapılmayacaklar") |
| **İki yönlü Google senkronu zor** — tekrarlayan etkinlik istisnaları (RRULE + EXDATE + taşınmış tekil), çakışma, silinmiş kayıt, `syncToken` süresi dolması (410) | 🔴 | Önce SALT OKUMA (Faz 48), yazma sonra ve dar (Faz 51); tekrar istisnalarını Google'a bırak (K3) |
| **Üçüncü bir paralel sistem** — not hatırlatıcısı + görev + rutin aynı şeyi üç farklı yoldan yapar, kullanıcı şaşırır | 🟡 | Tek zaman modeli: hatırlatıcı = notun zamanı, görev = yapılacak şey, etkinlik = zaman aralığı; ajandada üçü tek liste (§3) |
| **Google OAuth doğrulaması** — `calendar.*` ve `tasks` kapsamları Google'ın "hassas" (sensitive) sınıfında; Play'de herkese açık sürümde onay ekranı doğrulaması ister (gizlilik politikası + tanıtım videosu; `gmail.readonly` gibi "kısıtlı" değil, güvenlik denetimi istemez) | 🟡 | Kişisel APK'da test kullanıcısı yeter; mağaza yayını öncesi doğrulama başvurusu (Faz 19 tarzı kullanıcı işi) |
| **Web'de bildirim yok** — `reminder_service.dart:315` web'de çalışmaz | 🟡 | Web'de takvim görüntüleme/düzenleme tam; hatırlatma telefondan (Google'a yazılan etkinlikte Google'ın kendi bildirimi de çalar) |
| **Akıcılık** — ay görünümü + çok sayıda kayıt ana akışı yavaşlatabilir | 🟡 | Ayrı rota, tarih aralığına göre sorgu (tüm koleksiyon değil), Google verisi bellekte + günlük önbellek |
| **Saat dilimi / yaz saati** | 🟢 | `timezone` + `flutter_timezone` zaten var; tüm gün etkinliği `YYYY-MM-DD` dizesi (saat değil) |

### Sonuç
Yapılmaya değer. **Ölçü:** "Google Takvim'deki her şey" değil; **görevler (Google
Görevler'e çok benzer, iki yönlü)** + **kendi etkinliklerin ve Google
etkinliklerinin tek takvimde görünmesi** + **notlarla bağ**. Rutin ikinci aşama
ve AYRI bir "alışkanlık takipçisi" olarak değil, tekrarlayan görevin üstüne ince
bir katman olarak (§6).

---

## 2. Kapsam

### Yapılacaklar (Aşama 1 — Takvim + Görevler)
1. **Takvim ekranı** `/calendar`: Ay · Hafta · Gün · **Ajanda** (liste) görünümü.
2. **Etkinlik**: başlık, tüm gün / saat aralığı, tekrar, konum (düz metin), açıklama,
   renk, hatırlatma(lar), bağlı notlar.
3. **Görev** (Google Görevler benzeri): başlık, ayrıntı, son tarih (+ isteğe bağlı
   saat), tamamlandı, **listeler** ("Görevlerim", "İş"…), alt görev (1 seviye),
   sıralama, yıldız, bağlı not.
4. **Not ↔ takvim bağı** (§4): notu güne/etkinliğe/göreve bağlama, günün notu,
   etkinlikten "toplantı notu aç", notta "bağlı olduğu gün/etkinlik" hapı.
5. **Hatırlatma**: etkinlik ve görev için mevcut `ReminderService` üstünden
   (ayrı bildirim motoru YOK).
6. **Google bağlantısı** (Ayarlar → Bağlantılar, Gmail/Drive'ın yanında):
   Takvim etkinliklerini göster (salt okuma) → sonra yazma; Google Görevler iki yönlü.
7. **Mevcut parçaların birleşmesi**: not hatırlatıcıları takvimde görünür;
   brifing etkinlik+görev okur; asistan/sesli komut etkinlik/görev ekler.

### Yapılmayacaklar (bilinçli)
- Davet, katılımcı, yanıt (Evet/Hayır/Belki), Meet bağlantısı oluşturma, toplantı odası.
- Paylaşılan takvim / başkasının takvimine yazma (arkadaşlara klasör paylaşımı
  zaten var; takvim paylaşımı ayrı bir dünya).
- Birden çok saat diliminde planlama, çalışma saatleri, "boş zaman bul".
- Outlook/iCloud/CalDAV (ileride `.ics` içe/dışa aktarma yeterli olabilir — Faz 53).

---

## 3. Veri modeli (öneri)

Üç zaman türü, net ayrım:

| Tür | Anlamı | Nerede durur |
|---|---|---|
| **Not hatırlatıcısı** | "Bu notu bana şu an hatırlat" | BUGÜNKÜ gibi `Note.reminderAt` / `reminderRepeat` — DEĞİŞMEZ |
| **Görev** | "Yapılacak bir şey" (tik atılır) | yeni `users/{uid}/tasks/{id}` |
| **Etkinlik** | "Bir zaman aralığı" (tik atılmaz) | yeni `users/{uid}/events/{id}` |

### `CalendarEvent` (`users/{uid}/events/{id}`)
```
title, description, location
start / end          → Timestamp (saatli)  |  startDay / endDay 'YYYY-MM-DD' (tüm gün)
allDay: bool
tz: 'Europe/Istanbul' (oluşturulduğu dilim)
repeat: ''|RRULE alt kümesi (K4)
reminders: [dakika önce, …]      (ör. [10, 1440])
color, noteIds: [..]             (bağlı notlar, en çok ~10)
source: 'local' | 'google'
google: {calendarId, eventId, etag}   (yalnız Google'a yazılmışsa)
createdAt, updatedAt, deletedAt (çöp kutusu mantığı notlarla aynı)
extras (tanınmayan alan koruması — F1.5 kuralı)
```
Sorgu: `startKey` (ilk gün `YYYY-MM-DD`) üstünde aralık sorgusu + tekrarlayanlar
ayrı küçük sorgu (`repeat != ''`) — ay görünümü tüm koleksiyonu dinlemez.

### `TaskItem` (`users/{uid}/tasks/{id}`) — Google Tasks alanlarıyla birebir
```
title, notes, listId, parentId (alt görev), position (sıra dizesi)
due: 'YYYY-MM-DD' + dueTime?: 'HH:mm' (Google Tasks saat TUTMAZ — saat yalnız bizde)
completed: bool, completedAt, starred
repeat (K4), reminder (dakika önce / saat)
noteId (bağlı not), sourceNoteItem: {noteId, itemId}? (maddeden üretildiyse)
google: {taskListId, taskId, etag, updated}
createdAt, updatedAt, deletedAt, extras
```
Listeler: `users/{uid}/taskLists/{id}` (`title`, `google.taskListId`).

### Not tarafı (F46'da değişti: `Note`'a alan EKLENMEDİ)
Gün bağı `users/{uid}/dayLinks/{YYYY-MM-DD}` → `noteIds` (gün başına bir belge).
Etkinlik/görev bağı KAYIT tarafında (`noteIds`, `noteId`). Takvim verisi küçük
olduğu için dört koleksiyon tek dinleyiciyle belleğe alınır; notun "hangi güne/
etkinliğe bağlı" sorusu bellekte çözülür — dizin gerekmez. Gerekçe: not belgesi
büyük ve sık yazılıyor (`notes_repository`, ağır belge, sürümler); bağ için notu
yeniden yazmak senkron trafiğini artırırdı (AKICILIK Faz 22) ve `Note` modeline
dokunmak forward-compat/yedek/paket yollarını da etkilerdi.

---

## 4. Not ↔ Takvim bağı (benim önerdiğim ayrıntılar)

| Akış | Nasıl | Öncelik |
|---|---|---|
| **Günün notu** | Takvimde gün başlığında "Bu güne not" → `day` alanlı yeni not (başlık: "6 Kasım Perşembe"); varsa açar | Faz 49 |
| **Etkinlikten toplantı notu** | Etkinlik ayrıntısında "Not aç" → başlığı etkinlik adı, gövdesinde saat/konum/açıklama, `noteIds`'e eklenir | Faz 49 |
| **Notu takvime bağla** | Not ⋮ → "Takvime bağla": güne / var olan etkinliğe / yeni etkinlik | Faz 49 |
| **Notta bağ hapı** | Not başlığının altında küçük hap: "📅 6 Kas · Proje toplantısı" → takvimde o güne gider | Faz 49 |
| **Maddeyi göreve çevir** | Liste notunda madde ⋮ → "Görev yap" (son tarihle); görev tamamlanınca madde de işaretlenir (iki yönlü) | Faz 50 (K6) |
| **Görevden not** | Görevin "ayrıntı" alanı kısa metin; uzun iş için "Nota bağla/aç" | Faz 50 |
| **Not hatırlatıcıları takvimde** | `reminderAt`'li notlar takvimde ayrı simgeyle görünür (tekrarlılar da açılır) — taşımak/sürüklemek hatırlatıcıyı değiştirir | Faz 47 |
| **Gün özeti** | Ajandada her günün altında: o gün oluşturulan/düzenlenen notlar (isteğe bağlı açılır) | Faz 49 |
| **Metinden tarih yakala** | Not yazarken "yarın 15:00" gibi ifadede hafif öneri: "Takvime ekle?" (`spoken_datetime.dart` zaten var) | Faz 52 |
| **Fotoğraftan etkinlik** | Davetiye/afiş fotoğrafı → OCR + AI → etkinlik taslağı | Faz 52 |
| **E-postadan görev** | Gmail ekranında ileti ⋮ → "Görev yap" (Google'daki gibi; bağlantı geri iletiye) | Faz 52 |

---

## 5. Google bağlantısı

- **Kapsamlar** (Gmail gibi AYRI, kullanıcı ayrı onaylar, `googleScopeAuth`):
  - Salt okuma: `calendar.readonly` (veya daha dar `calendar.events.readonly` + `calendar.calendarlist.readonly`).
  - Yazma: `calendar.events` (yalnız etkinlik; takvim oluşturma/silme yok).
  - Görevler: `tasks` (okuma+yazma; ayrı bir salt okuma aşaması gereksiz — API küçük).
- **Senkron yöntemi**:
  - Takvim: ilk çekiş görünür aralık ±60 gün (`timeMin/timeMax`, `singleEvents=true`
    → tekrarlar Google'da açılmış gelir; RRULE çözmek bize düşmez), sonra
    `syncToken` ile artımlı; 410 gelirse tam çekiş. Veri **Firestore'a yazılmaz**,
    cihazda önbellek (K2) — Google zaten kaynak, kopyası senkron sorunu doğurur.
  - Görevler: `updatedMin` ile artımlı iki yönlü; çakışmada `updated` daha yeni
    olan kazanır; silme `deleted=true`. Google Tasks kopyası Firestore'da TUTULUR
    (web + telefon aynı görsün, çevrimdışı çalışsın) — K1.
- **Arka plan**: Android'de WorkManager yok (eklenmeli mi? K8). Öneri: uygulama
  açılınca + takvim ekranına girince + 15 dk'da bir ekran açıkken çek; Cloud
  Function ile sunucu senkronu YOK (kullanıcının Google jetonu sunucuda saklanmaz
  — gizlilik ve basitlik).
- **Web**: jeton ~55 dk + açılır pencere (Drive/Gmail'deki bilinen durum); takvim
  ekranında "Google'ı yenile" şeridi.
- **Misafir hesap**: Google bölümü gizli; yerel takvim + görevler tam çalışır.
- **OAuth onay ekranı**: Cloud konsolunda kapsamlar eklenmeli (kullanıcı işi →
  KALANLAR §2); mağaza yayını öncesi hassas kapsam doğrulaması.

---

## 6. Rutinler (Aşama 2) — değerlendirme ve öneri

**İstek:** rutin belirleyebilmek. Üç olası anlam var; hangisi kastedildiği K9:

| Seçenek | Ne | Artı | Eksi |
|---|---|---|---|
| **A. Alışkanlık takipçisi** | "Her gün 2 L su", "Haftada 3 spor" — işaretle, seri (🔥 12 gün), aylık ısı haritası | Motive edici, görsel | Yeni ekran + istatistik; uygulamadan bağımsız bir "uygulama içinde uygulama" |
| **B. Rutin = görev şablonu** | "Sabah rutini": 07:00'de 5 adımlı kontrol listesi her gün kendini yeniler; tamamlanma geçmişi tutulur | Görev altyapısını kullanır, az kod | Seri/istatistik basit |
| **C. Zaman blokları** | Takvimde tekrarlayan blok ("Her hafta içi 09–12 Derin çalışma") | Takvimin kendisi zaten yapar (tekrarlı etkinlik) | Yeni bir şey değil |

**Öneri: B + A'nın hafif hâli.** Rutin = adları ve adımları olan, tekrarlayan bir
görev şablonu: zamanı gelince günün görev listesine (ve ajandaya) düşer,
hatırlatır, adımları tik atılır; tamamlanma günü `routineLogs` alt koleksiyonuna
yazılır → seri sayısı ve basit 30 günlük şerit. Ayrı karmaşık istatistik ekranı
yok. Brifing "bugünün rutinleri" der; asistan "sabah rutinimi kur" diyebilir.
Faz 53'te.

---

## 7. Arayüz (taslak)

- **Giriş noktası**: telefonda ana ekran menüsü + alt çubukta/çekmecede "Takvim";
  geniş ekranda rayda simge (K3 kapıları gibi, `homeDoors`). Ana sayfa widget'ı
  ("Bugün": sıradaki 3 kayıt) Faz 53.
- **Görünümler**: telefonda varsayılan **Ajanda** (en kullanışlı küçük ekran
  görünümü) + üstte açılır ay şeridi (haftayı kaydır, ayı aç); Gün/Hafta saat
  ızgarası; tablet/web'de yan yana: solda ay, sağda gün/hafta.
- **Görevler sekmesi**: Google Görevler gibi liste; listeler arası yatay kaydırma
  (ana ekrandaki klasör kaydırması kalıbı), tamamlananlar katlanır.
- **Hızlı ekleme**: "+" → Etkinlik / Görev / (Rutin); doğal dil satırı: "Cuma
  14:00 dişçi 1 saat" (yerel ayrıştırıcı, AI isteğe bağlı).
- **Hatırlatıcılar ekranı** (`/reminders`): ajandanın süzgeçli hâline dönüşür
  (K5) — iki ayrı liste kalmaz.
- **Paket**: hazır takvim paketi (`table_calendar`) yalnız ay ızgarası verir, gün/
  hafta saat ızgarası yok; tema belirteçlerine uydurmak zor. Öneri: **kendi
  çizimimiz** (ay ızgarası + saat ızgarası `CustomPainter`/Sliver) — K7.

---

## 8. Fazlar

### Faz 46 — Temel model ve depo (görünmez)
- [x] F46.1 `features/calendar/domain`: `CalendarEvent` (saatli `start/end` zaman damgası, tüm gün `startDay/endDay` dizesi, bitiş HARİÇ), `TaskItem`, `TaskList`, `GoogleLink`, `day_key.dart`; `extras` koruması; `test/calendar_model_test.dart`. Not tarafı `dayLinks` (yukarıda §3).
- [x] F46.2 `Recurrence` (`recurrence.dart`): `<reminderRepeat>;every=N;until=GÜN;count=N`, `between()` / `nextAfter()`, `exdates`; tekrarlı görevi tamamlama `completeTask` (geçmiş kopyası + sonraki oluşa ilerleme, gecikmişi bugüne atlatır).
- [x] F46.3 `CalendarRepository` (etkinlik/görev/liste/gün bağı CRUD + akış sağlayıcıları, yangın-ve-unut yazım), `account_service` silme listesi.
- [x] F46.5 Yedek (`backup_service`): takvim/görev/gün bağı dışa+içe aktarma — geri yüklemede not kimlikleri yeniden eşlenmeli (`NoteShare.import` yeni kimlik verir). Faz 47'de ayarlarla birlikte. **Yapıldı (2026-11-06):** `calendar_backup.dart` — `yedek.json` `calendar` alanı (Timestamp → `{"$ts": ISO}`), geri yüklemede eski → yeni not kimliği eşlemesi (atlanan not da karşılığına), eşlenemeyen bağ düşer, aynı kimlikli kayıt atlanır. Misafir → Google taşıması (`prepareMigration`) takvimi TAŞIMAZ (sabah bakılacak). `test/calendar_move_backup_test.dart`.
- [x] F46.4 Kural testi (`rules-test`): dört koleksiyon yalnız sahibine (genel `users/{uid}/{c}/**` kuralı yetiyor, kural değişmedi).

### Faz 47 — Takvim ekranı (yerel)
- [x] F47.1 `/calendar` rota; rayda **Hatırlatıcılar'ın yerini aldı** (`AppSection.calendar`, Alt+5; `/reminders` da takvim bölümü sayılır), ana ekran ⋮ hızlı satırı "Takvim"; Hatırlatıcılar listesi takvim çubuğundaki ⏰ düğmesinden (K5 ilk adım).
- [x] F47.2 Ajanda (`_AgendaList`, seçili günden 60 gün, "Daha ileri" uzatır, seçili gün boşsa "plan yok"), boş durum, telefonda başlıktan açılır ay ızgarası.
- [x] F47.3 **Görünümler (kullanıcı isteği 2026-11-06: "ay, hafta, yıl görünümü hoş olmalı, geçişler rahat; 2 parmak zoom ile geçiş, neresi zoom yapılırsa o hafta/ay açılmalı")**: `calendar_views.dart` — YIL (12 küçük ay, dolu gün vurgulu; hatırlatıcılar sayılmaz), AY (ekranı dolduran 6 hafta, hücrede sığdığı kadar şerit + "+n", güne dokun → gün levhası, uzun bas → yeni etkinlik), HAFTA (tüm gün şeridi + 24 saat ızgara, çakışanlar yan yana `layoutTimedBlocks`, kırmızı "şimdi" çizgisi, boş saate dokun → o saate etkinlik), AJANDA (önceki ekran). Dönemler arası yatay kaydırma (`PageView`), genişte ‹ › okları. **İki parmak** (`pinch_zoom.dart`, hareket yarışmasına girmeyen `Listener`): yakınlaştır yıl → ay → hafta, uzaklaştır tersi; hedef parmakların altındaki ay karosu / hafta satırı (`ZoomTargets`); geçiş o noktadan büyüyerek (`AnimatedSwitcher` + ölçek/solma, "hareketi azalt"a uyar), eşiğe dek canlı ölçek (yalnız `Transform` yeniden çizilir). Web: Ctrl+tekerlek ve dokunmatik yüzey kıstırması aynı eşik. Seçilen görünüm hatırlanır, ilk açılışta bir kez ipucu. Görsel tur: `flutter test tool/tour/calendar_tour_test.dart`. Gün görünümü YOK (hafta ızgarası + gün levhası yetiyor).
- [x] F47.4 Etkinlik levhası (`event_editor.dart`): başlık, tüm gün, başlangıç/bitiş (bitiş başlangıçla kayar), tekrar (`pickReminderRepeat` — `every/until` arayüzde yok), tek hatırlatma, konum, açıklama; sil → çöp + geri al; tekrarlıda "yalnız bu / tümü" (`exdates`). Düzenleme serinin tamamına uygulanır.
- [x] F47.5 Not hatırlatıcıları ajandada ve ızgarada (tekrarlılar açılır, gizli klasör bastırılır, dokununca not). **Sürükleyerek taşıma (2026-11-06):** AY görünümünde şeride basılı tut → başka güne bırak (`movedToDay`/`canMoveEntry`, saat korunur, "Geri al"); tekrarlı ETKİNLİK taşınmaz (serinin tamamı kayardı), tekrarlı hatırlatıcı/görevde serinin başı kayar. Haftanın saat ızgarasında saat değiştirerek sürükleme YOK. Cihazda doğrulanmadı → KALANLAR §2 #99.
- [x] F47.6 `ReminderService` takvim bildirimleri: `calendarAlarms` (14 gün ufuk, en çok 60), yük `cal:event:<id>` / `cal:task:<id>` (dokununca `/calendar`), ilk eşitlemede `cal:` önekli yetimler iptal, kanal `calendar`. Yalnız cihazda (web'de dinleyici yok). **Cihazda doğrulanmadı** → KALANLAR §2.
- [x] F47.7 Ekran turu `tool/tour/calendar_tour_test.dart` (telefon/tablet × 4 görünüm, koyu `TOUR_DARK=1`) ✓. Akıcılık ölçümü (`tool/perf`, telefonda kıstırma/kaydırma) telefon gerektirir → yazıldı, cihazda ölçülmedi; KALANLAR §2 #87.

### Faz 48 — Google Takvim (salt okuma)
- [x] F48.1 `google_calendar_api.dart` (Gmail kalıbı, yalnız GET, UTF-8), kapsam `calendar.readonly` ayrı (`googleScopeAuth`, web jetonu sekmede `notlar_gcal_token`). Bağlantı yeri: Ayarlar'da "Bağlantılar" bölümü YOK — takvim çubuğundaki ☁ düğmesi (`showGoogleCalendarSheet`: bağla / takvimler / yenile / kaldır); ayarlara taşımak sabah bakılacak. Konsol: **F19.B10**.
- [x] F48.2 `google_calendar_sync.dart` (`GoogleCalendarController`): takvim listesi + seçim (varsayılan Google'daki "göster"; `shown` kümesi), renk `backgroundColor`; cihazda önbellek (`gcal_cache_<uid>`, SharedPreferences) — açılışta ağsız; ilk çekiş ±60 gün `singleEvents`, sonra takvim başına `syncToken` artımlı, 410 → tam; takvim ekranına girişte + açıkken 15 dk'da bir (K8). Firestore'a yazılmaz.
- [x] F48.3 Google etkinlikleri (`g:<takvim>/<id>`, `CalendarEvent.fromGoogle`) ay/hafta/ajanda/yıl + takvim zemininde; ayda çerçeveli şerit, ajandada ☁; sürüklenmez/düzenlenmez; dokununca salt okunur levha (`showGoogleEventSheet`) + "Google Takvim'de aç" (`htmlLink`).
- [x] F48.4 `eventLinks` (`linkNoteToGoogleEvent`, hesap silme listesinde); levhada "Toplantı notu" (`openMeetingNote`: başlık + zaman/konum/açıklama, bağlanır, açılır) ve "Bağlı notlar" (bağı kaldır). Testler `google_calendar_test` (yalnız GET, artımlı/410, önbellek, gizli takvim). Gerçek Google'a karşı denenmedi → KALANLAR §2 #101.

### Faz 49 — Not ↔ takvim
- [x] F49.1 Gün levhasında "Bu güne not" (başlık `dayNoteTitle` "6 Kasım Cuma"; güne bağlı aynı başlıklı not varsa açar, yoksa oluşturup `dayLinks`e bağlar); etkinlik düzenleyicide "Toplantı notu" + "Bağlı notlar" (yerel ve Google, `openMeetingNote`); not ⋮ (kart + editör, `note_menu_model` Düzenle grubu) → "Takvime bağla" levhası: güne (tarih seçici) / yaklaşan etkinliğe (yerel + Google) / yeni etkinlik (`showEventEditor(linkNoteId, initialTitle)`), mevcut bağlar kaldırılabilir.
- [x] F49.2 `NoteCalendarPills` başlık/çip satırının altında (bağ yoksa yer kaplamaz; en çok 4): "6 Kas · Toplantı" → `/calendar?day=YYYY-MM-DD` (CalendarScreen `initialDay`). Bağlar not belgesinde değil, ters hesap `calendarLinksForNote` (`noteCalendarLinksProvider`, yalnız açık not).
- [x] F49.3 Gün levhasında güne bağlı notlar + açılır "O gün yazılan notlar (n)" (`updatedAt` o gün; ajanda listesine girmedi — gün levhası yeterli, kalabalık yapmasın). Testler `note_calendar_links_test`. Cihazda doğrulanmadı → KALANLAR §2 #102.

### Faz 49b — Not ↔ takvim pratikliği (2026-11-08, oturum B)
- [x] F49b.1 **Mevcut notu bağla**: gün levhasında, yerel etkinlik düzenleyicisinde ve Google etkinlik levhasında "Mevcut notu bağla" → yeniden kullanılabilir not seçici (`note_target_picker.dart`: üstte boş yeni not, altında tüm notların küçültülmüş kartları). `linkExistingNote` (google_calendar_ui.dart).
- [x] F49b.2 **Etkinlikten nota tek dokunuş**: ajandada bağlı-not simgesi tek bağlı notta doğrudan o notu açar (birden çoksa etkinlik levhası).
- [x] F49b.3 **Hafta → gün**: kıstırma / Ctrl+tekerlek yakınlaştırınca hafta görünümü imlecin altındaki günün ajandasını açar; düz fare tekerleği yıl ↔ ay arasında geçiş yapar (hafta/günde tekerlek kayar — çakışma kararı).
- [ ] Haftanın saat ızgarasında sürükleyerek saat değiştirme, görevlerde elle sürükle-sırala: yapılmadı (cihazda doğrulama gerektirir; ayrı faz).
- [x] F53b **Nottan rutin**: Rutinler → ✓ düğmesi → not seç → maddeler/satırlar adım olur, düzenleyicide açılır (`routine_from_note.dart`). Rutin modeline ve `tasks`a alan EKLENMEDİ.

### Faz 50 — Görevler (yerel + Google Görevler iki yönlü)
- [x] F50.1 Görevler ekranı `/tasks` (takvim çubuğunda ✓; rayda Takvim bölümü): liste çipleri + yeni liste / yeniden adlandır / sil, alt görev (tek seviye, girintili), sıralama `compareTasks`, katlanır tamamlananlar + temizle, son tarih + saat, "zamanı gelince hatırlat", tekrar (tamamlayınca ilerler), yıldız. Elle sürükleyerek sıralama AÇIK.
- [x] F50.2 Görevler takvimde/ajandada (son tarih gününde, tikli; dokununca görev levhası; ızgarada nokta).
- [x] F50.3 Madde menüsünde (basılı tut) "Görev yap" → görev levhası maddenin metniyle (`noteId`/`noteItemId`); tamamlanma iki yönlü (`task_note_sync.dart`): görev tiklenince madde (görevler ekranı + ajanda), madde tiklenince görev (kart + editör `onItemChecked`). Tekrarlı görev eşlenmez (tamamlanınca ilerler). Testler `task_note_sync_test`.
- [x] F50.4 `google_tasks_api.dart` (kapsam `tasks`, ayrı), saf plan `task_sync_plan.dart` (`planTaskSync`: eşsiz → karşıya aç; yalnız bir taraf değiştiyse o yöne; ikisi de değiştiyse `updated` yeni olan; silme iki yöne; Google'da silinmiş ama yerelde sonradan düzenlenmiş → yeniden açılır; içerik aynıysa yazım YOK — ping-pong yok). Saat/tekrar/yıldız/not bağı yalnız yerelde, korunur. `GoogleTasksController`: listeler eşlenir (varsayılan ↔ Google'daki ilk liste, eşsizler iki yönde açılır), alt görev üstüyle; görevler ekranında ☁ (bağla / şimdi eşle / kaldır), görevler + takvim ekranına girişte ve açıkken 15 dk'da bir. Silinmişler dahil okuma `fetchAllTasks`. Testler `google_tasks_test` (plan + sahte Google/Firestore uçtan uca). Gerçek hesapta denenmedi → F19.B10, KALANLAR §2 #103.

### Faz 51 — Google Takvim'e yazma
- [x] F51.1 `calendar.events` AYRI kapsam, ilk Google kaydında istenir (`connectWrite`; okuma kapsamı genişlemez). Yeni etkinlikte "Bu cihaz | Google Takvim" (Google bağlıysa varsayılan Google — K2; nottan bağlanırken bu cihaz, bağ yerel etkinliğe). Birincil takvime yazılır (`writeTarget`). Tekrar `rruleOf` ile RRULE (günlük/hafta içi/haftalık günler/aylık/yıllık + INTERVAL/COUNT/UNTIL), hatırlatma `popup` override.
- [x] F51.2 Google etkinlik levhasında "Düzenle" → aynı düzenleyici, kaydet PATCH; sil onaylı (geri alınamaz) DELETE. Tekrarlı serinin oluşu (`recurringEventId`) burada düzenlenmez → "Google Takvim'de aç" (K3).
- [x] F51.3 Kuyruk denetleyicide (`_queue`, önbellek JSON'unda kalıcı): yazım İYİMSER (takvimde hemen; yeni etkinlik geçici `tmp-` kimlikle), sırayla gönderilir; ağ/5xx/429/401'de durur, sonraki tazelemede yeniden; kalıcı 4xx düşer + hata. Geçici kimliğe sonradan yazılan düzenleme/silme gerçek kimliğe çevrilir. Levhada "n değişiklik bekliyor". Testler `google_calendar_test` (RRULE, gövde, kuyruk). Gerçek hesapta denenmedi → F19.B10 (+ `calendar.events` kapsamı), KALANLAR §2 #104.

### Faz 52 — Akıllı bağlar (AI + mevcut özellikler)
- [x] F52.1 Brifinge "TAKVİM VE GÖREVLER" bölümü (`calendarBriefingLines`: bugün/yarın etkinlik + görev saat sırasıyla, gecikmiş açık görevler; Google etkinlikleri önbellekten), istem etkinlik/görev/gecikme der. Rutinler Faz 53'te eklenir.
- [x] F52.2 Asistana üç araç (REST ve Firebase AI istemcisinde aynı sözleşme, açıklamalar ortak sabit): `create_event` (ISO başlangıç/bitiş, tüm gün, konum, dakika önce hatırlatma), `create_task` (gün + saat), `list_agenda` (gün + kaç gün → etkinlik/görev/hatırlatıcı; kilitli not girmez). Takvim araçları not deposu olmadan çalışır. Testler `calendar_ai_test`.
- [x] F52.3 (a) Notta tarih: yazarken HİÇBİR ŞEY çalışmaz (akıcılık); az önce düzenlenmiş, hatırlatıcısız notu kapatınca son 5 dolu satırda zaman ifadesi varsa tek bildirim "Notta … geçiyor · Takvime ekle" → etkinlik levhası (not bağlı, başlık notun). Aynı (not, zaman) oturumda bir kez (`noteDateSuggestion`, yerel `parseSpokenDateTimeNow`). (b) Metin tanıma ekranında "Takvime etkinlik olarak ekle" (`eventDraftFromText`: ilk satır başlık, kalanı açıklama, zaman yerel ayrıştırıcıdan — AI yok). (c) Gmail iletisinde "Görev yap" (başlık konu, ayrıntı ileti bağlantısı).
- [x] F52.4 `ics.dart` (RFC 5545 gündelik alt küme: saatli/tüm gün, konum, açıklama kaçışlı, satır katlama, basit RRULE ↔ tekrar; TZID yerel sayılır) + takvim ⋮ → dışa aktar (paylaş) / içe aktar (aynı UID ya da başlık+başlangıç atlanır). Google etkinlikleri dışa gitmez. Testler `ics_test`.

### Faz 53 — Rutinler (Aşama 2)
- [x] F53.1 `routine.dart`: `Routine` (ad, adımlar, tekrar — `Recurrence`, varsayılan günlük, çıpa `startDay`; saat, renk, hatırlat) `users/{uid}/routines`; `RoutineLog` `routineLogs/{rutin}_{gün}` (tiklenen adımlar + tamam). Hesap silme listesinde.
- [x] F53.2 Ajandada `RoutineEntry` (ay/hafta/ajanda/gün levhası/zemin; sürüklenmez); dokununca gün levhası: adımlar tiklenir (adımsızsa tek "Tamamlandı"). Hatırlatma `calendarAlarms(routines)` → `cal:routine:` (her oluş, rutinin saatinde). Görev listesine ayrı kopya YAZILMAZ (çift kayıt olmasın) — ajanda ve rutin kartı yeter.
- [x] F53.3 `/routines` (takvim çubuğunda 🧘): kart başına 🔥 seri (`routineStreak`: bugün yapılmadıysa dünden), son 30 gün şeridi (`routineStrip`), "Bugünü işaretle". Brifing (bugünün rutinleri) ve asistan `list_agenda` rutinleri de getirir. Testler `routine_test`.
- [x] F53.4 Var olan "Bugün" widget'ı (`todayWidgetPayload`) artık 7 günlük etkinlik (📅), görev (☐) ve rutinleri (🔁) de taşır; takvim akışları değişince güncellenir. Yeni Android widget'ı YAZILMADI (mevcut olan genişletildi). Cihazda doğrulanmadı → KALANLAR §2 #106.

---

## 9. Kararlar (VERİLDİ 2026-11-06 — hepsi önerilen (a))

- **K1 — Görevlerin kaynağı.** (a) **Önerilen:** görevler Firestore'da (misafir de
  kullanır, web+telefon aynı), Google bağlıysa Google Görevler ile iki yönlü
  eşlenir. (b) Görevler yalnız Google Görevler'de (Google'sız görev yok).
- **K2 — Etkinliklerin kaynağı.** (a) **Önerilen:** kendi etkinliklerin Firestore'da;
  Google etkinlikleri yalnız gösterilir (Faz 48), Faz 51'den sonra yeni etkinlikte
  "nereye kaydedilsin" seçilir (varsayılan: Google bağlıysa Google). (b) Google
  bağlıysa bütün etkinlikler doğrudan Google'a, yerel etkinlik yalnız misafirde.
  (c) Google'ı hiç yazma, yalnız oku.
- **K3 — Google tekrar istisnaları.** **Önerilen:** Google etkinliklerinde tekrarı
  Google çözer (`singleEvents`); bizim yerel tekrarımız basit kalır (istisna yok,
  "yalnız bu"yu silmek = o tarihi `exdates`e eklemek).
- **K4 — Tekrar biçimi.** (a) **Önerilen:** mevcut `reminderRepeat` dizesini
  genişlet (`interval`, bitiş tarihi/sayısı ekle) — tek ayrıştırıcı. (b) Tam RRULE.
- **K5 — Hatırlatıcılar ekranı.** (a) **Önerilen:** ajandanın "yalnız hatırlatıcılar"
  süzgecine dönüşür, menüdeki kapı takvime gider. (b) İkisi ayrı kalır.
- **K6 — Liste maddesi ↔ görev.** (a) **Önerilen:** maddeden görev üretilir ve
  tamamlanma iki yönlü eşlenir. (b) Bağ yok, yalnız kopya. (c) Hiç yapma.
- **K7 — Takvim çizimi.** (a) **Önerilen:** kendi çizimimiz (tema + akıcılık
  denetimi bizde). (b) `table_calendar` (ay) + kendi gün/hafta.
- **K8 — Arka plan senkronu.** (a) **Önerilen:** yalnız uygulama açıkken
  (açılış/ekrana giriş/15 dk); bildirimler zaten yerel. (b) `workmanager` paketi
  ile periyodik arka plan çekişi (pil + karmaşıklık).
- **K9 — Rutin ne demek?** (a) **Önerilen:** görev şablonu + hafif seri (§6 B+A).
  (b) Tam alışkanlık takipçisi. (c) Yalnız takvimde tekrarlayan blok.
- **K10 — Sıra.** **Önerilen:** 46 → 47 → 50 (görevler, yerel) → 48 → 49 → 50.4 →
  51 → 52 → 53. Gerekçe: Google'sız da işe yarayan çekirdek önce; Google görev
  senkronu takvim yazmasından daha kolay ve daha faydalı.

## Durum

| Faz | Durum |
|---|---|
| 46 Model | ✅ |
| 47 Takvim ekranı | ✅ 2026-11-06 (sürükleyerek taşıma ayda; telefonda akıcılık ölçümü KALANLAR §2 #87) — ek: ana ekranda sola kaydırınca takvim, takvim zemini |
| 48 Google Takvim okuma | ✅ 2026-11-06 (gerçek hesapta denenmedi: F19.B10 + KALANLAR §2 #101) |
| 49 Not ↔ takvim | ✅ 2026-11-06 (cihazda doğrulanmadı, KALANLAR §2 #102) |
| 50 Görevler | ✅ 2026-11-06 (Google Görevler gerçek hesapta denenmedi: F19.B10, KALANLAR §2 #103; elle sürükleyerek sıralama yok) |
| 51 Google'a yazma | ✅ 2026-11-06 (gerçek hesapta denenmedi: F19.B10, KALANLAR §2 #104) |
| 52 Akıllı bağlar | ✅ 2026-11-06 (cihazda doğrulanmadı, KALANLAR §2 #105) |
| 53 Rutinler | ✅ 2026-11-06 (cihazda doğrulanmadı, KALANLAR §2 #106) |
| 49b/53b Pratiklik | ✅ 2026-11-08 (mevcut notu bağla, tek dokunuşla nota, hafta→gün, nottan rutin; cihazda doğrulanmadı, KALANLAR §2 B-maddeleri) |
