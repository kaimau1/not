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
- [ ] F46.5 Yedek (`backup_service`): takvim/görev/gün bağı dışa+içe aktarma — geri yüklemede not kimlikleri yeniden eşlenmeli (`NoteShare.import` yeni kimlik verir). Faz 47'de ayarlarla birlikte.
- [x] F46.4 Kural testi (`rules-test`): dört koleksiyon yalnız sahibine (genel `users/{uid}/{c}/**` kuralı yetiyor, kural değişmedi).

### Faz 47 — Takvim ekranı (yerel)
- [x] F47.1 `/calendar` rota; rayda **Hatırlatıcılar'ın yerini aldı** (`AppSection.calendar`, Alt+5; `/reminders` da takvim bölümü sayılır), ana ekran ⋮ hızlı satırı "Takvim"; Hatırlatıcılar listesi takvim çubuğundaki ⏰ düğmesinden (K5 ilk adım).
- [x] F47.2 Ajanda (`_AgendaList`, seçili günden 60 gün, "Daha ileri" uzatır, seçili gün boşsa "plan yok"), boş durum, telefonda başlıktan açılır ay ızgarası.
- [~] F47.3 Ay ızgarası (`month_grid.dart`, yerel haftabaşı, nokta, yatay kaydırma) + geniş (≥ 720 dp) düzende solda sabit ızgara. **Gün/Hafta saat ızgarası AÇIK.**
- [x] F47.4 Etkinlik levhası (`event_editor.dart`): başlık, tüm gün, başlangıç/bitiş (bitiş başlangıçla kayar), tekrar (`pickReminderRepeat` — `every/until` arayüzde yok), tek hatırlatma, konum, açıklama; sil → çöp + geri al; tekrarlıda "yalnız bu / tümü" (`exdates`). Düzenleme serinin tamamına uygulanır.
- [~] F47.5 Not hatırlatıcıları ajandada ve ızgarada (tekrarlılar açılır, gizli klasör bastırılır, dokununca not). **Sürükleyerek taşıma AÇIK.**
- [x] F47.6 `ReminderService` takvim bildirimleri: `calendarAlarms` (14 gün ufuk, en çok 60), yük `cal:event:<id>` / `cal:task:<id>` (dokununca `/calendar`), ilk eşitlemede `cal:` önekli yetimler iptal, kanal `calendar`. Yalnız cihazda (web'de dinleyici yok). **Cihazda doğrulanmadı** → KALANLAR §2.
- [ ] F47.7 Ekran turu (`tool/tour`) telefon/tablet/masaüstü görüntüleri; akıcılık ölçümü (`tool/perf`).

### Faz 48 — Google Takvim (salt okuma)
- [ ] F48.1 `calendar_api.dart` (Gmail kalıbı, yalnız GET), `calendarAuthProvider`, Ayarlar → Bağlantılar'da "Google Takvim".
- [ ] F48.2 Takvim listesi + hangi takvimler gösterilsin (renkleriyle), cihazda önbellek, `syncToken`.
- [ ] F48.3 Google etkinlikleri ızgarada/ajandada (farklı kenarlık), ayrıntıda "Google Takvim'de aç".
- [ ] F48.4 Google etkinliğine not bağlama (bağ `users/{uid}/eventLinks/{googleEventId}` — Google'a yazılmaz).

### Faz 49 — Not ↔ takvim
- [ ] F49.1 Günün notu, etkinlikten toplantı notu, not ⋮ "Takvime bağla".
- [ ] F49.2 Notta bağ hapı; takvimde güne/etkinliğe atlama.
- [ ] F49.3 Ajandada "o gün yazılan notlar" (isteğe bağlı).

### Faz 50 — Görevler (yerel + Google Görevler iki yönlü)
- [ ] F50.1 Görevler sekmesi: listeler, alt görev, sıralama, tamamlananlar, son tarih + saat, hatırlatma, tekrar.
- [ ] F50.2 Görevler takvimde/ajandada (son tarih gününde, tikli).
- [ ] F50.3 Liste notunda madde → görev (K6), tamamlanma eşlemesi.
- [ ] F50.4 Google Tasks API iki yönlü senkron (`tasks` kapsamı), çakışma kuralı, testler (sahte HTTP).

### Faz 51 — Google Takvim'e yazma
- [ ] F51.1 `calendar.events` kapsamı; yeni etkinlikte "Kaydet: Bu cihaz / Google Takvim (X)" seçimi (K2).
- [ ] F51.2 Düzenleme/silme Google'a; tekrarlayan Google etkinliğinde "yalnız bu / tümü" Google'a bırakılır.
- [ ] F51.3 Hata/çevrimdışı kuyruğu (`UploadQueue` kalıbı).

### Faz 52 — Akıllı bağlar (AI + mevcut özellikler)
- [ ] F52.1 Brifing: bugünün etkinlikleri + görevleri + (Faz 53'ten sonra) rutinler.
- [ ] F52.2 Asistan/sesli komut araçları: etkinlik ekle, görev ekle, "yarın neler var?".
- [ ] F52.3 Notta tarih ifadesi önerisi; fotoğraftan etkinlik; Gmail iletisinden görev.
- [ ] F52.4 `.ics` dışa/içe aktarma (isteğe bağlı).

### Faz 53 — Rutinler (Aşama 2)
- [ ] F53.1 `Routine` modeli (ad, adımlar, tekrar, saat, renk) + `routineLogs`.
- [ ] F53.2 Rutin günün görevlerine düşer; adım tikleri; hatırlatma.
- [ ] F53.3 Seri + 30 günlük şerit; brifing ve asistan entegrasyonu.
- [ ] F53.4 Ana sayfa widget'ı "Bugün" (sıradaki etkinlik/görev/rutin).

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
| 46 Model | ✅ (F46.5 yedek açık) |
| 47 Takvim ekranı | 🟡 çekirdek bitti; gün/hafta ızgarası, sürükleme, tur açık |
| 48 Google Takvim okuma | — |
| 49 Not ↔ takvim | — |
| 50 Görevler | — |
| 51 Google'a yazma | — |
| 52 Akıllı bağlar | — |
| 53 Rutinler | — |
