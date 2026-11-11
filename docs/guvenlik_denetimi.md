# Güvenlik denetimi (Faz 71, 2026-11-11)

Kendi uygulamamızın savunma amaçlı denetimi. Kapsam: kurallar, CI, Android/web yüzeyi,
uygulama içi sızıntı yolları, bağımlılıklar. Yöntem: kod okuma + emülatörde kural testi +
geçmişte desen taraması. **Cihazda ve yayındaki sitede hiçbir şey denenmedi.**
Tehdit modeli: `docs/guvenlik.md`.

Özet: 1 yüksek, 5 orta, 3 düşük bulgu DÜZELTİLDİ. Açık kritik/yüksek yok. Açık kalan
ortalar KARAR ya da konsol işi (aşağıda "Kullanıcı işi").

## Bulgular

| No | Önem | Bulgu | Kanıt | Düzeltme | Durum |
|---|---|---|---|---|---|
| G-01 | **Yüksek** | E-posta dizini ele geçirme: herkes `userDirectory/{başkasının e-postası}` kaydını kendi uid'ine yazabiliyordu (var olanın üstüne de). Kurbana e-postayla gönderilen arkadaşlık isteği, ardından paylaşılan not/klasör saldırgana gidiyordu. Yorum "kimlik e-postayla eşleşir" diyordu, kural bakmıyordu. | `firestore.rules` `match /userDirectory/{email}` (eski hâli yalnız `uid == auth.uid`) | Kimlik = jetondaki doğrulanmış e-posta | Düzeltildi; test "F71.2 e-posta dizini" kırmızı → yeşil |
| G-02 | Orta | Arama dizininde başkasının e-postası/adıyla görünme | `firestore.rules` `match /userSearch/{uid}` | `email`/`emailLower` jetonla eşleşmeli | Düzeltildi + test |
| G-03 | Orta | Arkadaşlık isteği ve kabul kaydında sahte e-posta; alan boyutu sınırsız | `firestore.rules` `friendRequests`, `friends` | E-posta jetonla eşleşir, ad ≤ 200, e-posta ≤ 320 | Düzeltildi + test |
| G-04 | Orta | Paylaşılan klasörün üyesi ('read' rolü dahil) sahibin klasörünü yeniden adlandırıp gizleyebiliyordu | `firestore.rules` `match /users/{ownerUid}/folders/{folderId}` ilk `allow update` | Üye `name/icon/hidden/color/ownerId` alanlarına dokunamaz | Düzeltildi + test |
| G-05 | Düşük | Sohbet iletisinde `senderName` tavansız | `firestore.rules` `messages` | ≤ 200 | Düzeltildi + test |
| G-06 | Orta | CI: üçüncü taraf action'lar etikete bağlıydı (etiket başka koda taşınabilir; `deploy` servis hesabı, `android` imza anahtarıyla koşuyor); `GITHUB_TOKEN` varsayılan yetkide | `.github/workflows/build.yml` | 4 action commit SHA'sına sabit; üst düzey `permissions: contents: read` | Düzeltildi + bekçi. main'e özgü işler (`web`, `deploy`, `android`) dalda koşmaz — ilk main koşusunda izlenmeli |
| G-07 | Düşük | Bağlantı açıcı her şemayı başlatıyordu (`intent:`, `file:`, başka uygulamanın şeması). Bugün bulucu yalnız http/www/e-posta üretiyor; süzgeç savunma derinliği | `lib/core/utils/link_text.dart` `openLink` | Yalnız http, https, mailto (`linkUri`) | Düzeltildi + test |
| G-08 | Düşük | Web: çerçeveye alma engeli yoktu (tıklama tuzağı) | `web/_headers` | `X-Frame-Options: DENY` + `frame-ancestors 'none'` | Yazıldı; yayındaki yanıtta doğrulanmadı |
| G-26 | Orta | Kilitli notun hatırlatıcı bildirimi başlığı ve gövdenin ilk 120 karakterini kilit ekranında gösteriyordu (şerit ve Hatırlatıcılar ekranı gizliyordu, bildirim gizlemiyordu) | `lib/features/notes/data/reminder_service.dart` `_scheduleOne` | Kilitli notta "Kilitli not", gövde yok; kilit değişince yeniden planlanır | Düzeltildi + test; cihazda doğrulanmadı. Önceden planlanmış bildirimler not bir kez değişene/uygulama yeniden planlayana dek eski metinle kalabilir |
| G-09 | Orta | Firebase API anahtarı depoda ve her pakette (tasarım gereği). Koruma konsol ayarına bağlı | `lib/firebase_options.dart`, `android/app/google-services.json` | Konsolda anahtar kısıtı + App Check zorlaması | **Kullanıcı işi** |
| G-10 | Orta | `GOOGLE_DESKTOP_CLIENT_SECRET` APK'da düz metin (dart-define). Yüklü uygulama istemcisinin sırrı gizli sayılmaz; akış PKCE + state + 127.0.0.1 ile korunuyor | `.github/workflows/build.yml` "APK derle", `loopback_oauth.dart:64-157` | Belgelendi; onay ekranı kapsamları en aza indirilmeli | Kabul / **kullanıcı işi** (konsol denetimi) |
| G-11 | Orta | Yedek (`.notyedek`) şifresiz; kilitli notlar düz metin içinde | `lib/features/notes/data/backup_service.dart:413` | Uyarı ya da parola seçeneği | **KARAR — sabah bakılacak** |
| G-12 | Orta | Tam CSP yok (`script-src`, `connect-src`) | `web/_headers`, `web/index.html` | Flutter wasm + Firebase + Google girişiyle denenmeden konamaz | Açık (deneme gerek) |
| G-13 | Orta | Gelen notlar: arkadaş sınırsız sayıda not bırakabilir; `fromName`/`fromEmail` doğrulanmıyor; `items`/`tags` tavansız (belge sınırı 1 MiB) | `firestore.rules` `inboxNotes` | Hız sınırı kuralla yapılamaz (sayaç/Function ister) | Açık |
| G-14 | Düşük | E-postadan "hesap var mı + uid" öğrenilir (misafir oturum dahil) | `firestore.rules` `userDirectory` `allow get` | Misafiri dışlamak davranış değiştirir | KARAR — sabah bakılacak |
| G-15 | Düşük | Uid'i bilinen herkese istek bırakılabilir (gönderen başına 1 belge) | `firestore.rules` `friendRequests` | — | Kabul |
| G-16 | Düşük | `presence` belgesini okuma rolündeki üye de yazar, içerik tavansız; `versions` yaratma tavansız | `firestore.rules` `{sub}/{docId}` | Alan/boyut doğrulaması | Açık |
| G-17 | Düşük | Hiç paylaşılmamış klasörün kimliğini bilen biri aynı kimlikle kendi klasörünü açıp aynayı işgal edebilir (paylaşımı engeller; veri sızmaz, kimlik rastgele) | `firestore.rules` `folderShares` create | — | Kabul |
| G-18 | Düşük | Storage: içerik türü istemci beyanı (`image/.*` SVG dahil); sohbet görselini her üye siler; ortak çalışan sahibin dosyasının üstüne yazar; toplam kota sunucuda zorlanmıyor | `storage.rules` | Function + sayaç (KALANLAR'da) | Açık |
| G-19 | Düşük | CI: sır `echo '${{ secrets.X }}' > dosya` biçiminde betiğe gömülüyor (env ile verilmeli); `npx firebase-tools` sürümsüz; `functions/` kilit dosyasız (`npm install`) | `.github/workflows/build.yml` `release`, `deploy` | Yalnız main'de koşan adımlar — gözetimsiz değiştirilmedi | Açık |
| G-20 | Düşük | `notlar://new` her uygulamadan tetiklenir (boş not yaratır). `notlar://note/<id>` not kilidini atlamıyor (kodda; cihazda denenmedi) | `lib/app/router.dart:297-335` | — | Kabul / cihaz turu |
| G-21 | Düşük | İçe aktarılan arşivler bellekte açılıyor: zip bombası = bellek tükenmesi (yerel çökme). Yol geçişi tek noktada kesili | `note_package.dart:242`, `backup_ui.dart:203`, `attachment_repository.dart:298`, `MainActivity.kt` `sanitize` | Açılmış boyut/dosya sayısı tavanı | Açık |
| G-22 | Bilgi | `rules-test` `npm audit`: 29 açık (yalnız test aracı; dağıtılmıyor) | `rules-test/package-lock.json` | `firebase-tools` büyük sürüm yükseltmesi | Açık |
| G-23 | Düşük | Dizin kaydı yazımı hatayı yakalamıyor (kural reddederse yakalanmamış hata günlüğe düşer) | `dashboard_screen.dart:343` | `.catchError` | Açık (ana ekran dosyası — ölçüm kapısı) |
| G-24 | Bilgi | Kilitli notun başlığı kartta ve aramada görünür | `notes_providers.dart:1353` | — | Tasarım |
| G-25 | Bilgi | Güncelleme: adres GitHub API yanıtından, ayrıca host denetimi yok; bütünlüğü Android zorlar (aynı paket + aynı imza) | `app_update.dart:159-176`, `ApkGuncelleme.kt` | — | Kabul |

## F71.2 — Kim okur / kim yazar

| Yol | Okur | Yazar | Test |
|---|---|---|---|
| `users/{uid}` | sahip | sahip (`premiumUntil` hariç) | premiumUntil |
| `users/{uid}/{alt}/**` | sahip | sahip | kendi notu, ayar, takvim |
| `users/{to}/friendRequests/{from}` | iki taraf | gönderen yaratır (kendi e-postası); iki taraf siler | F71.2 arkadaşlık |
| `users/{o}/friends/{f}` | sahip | `f`, istek varsa yaratır; iki taraf siler | F71.2 arkadaşlık |
| `users/{o}/folders/{id}` | sahip, üyeler | sahip; davetli yalnız kendi davetini yanıtlar | F71.2 rol yükseltme |
| `users/{o}/notes/{id}` | sahip; klasör read/both; ortak çalışan | sahip; both hepsini, write yalnız kendi notunu; ortak çalışan; silme yalnız sahip | F71.2 rol matrisi, ortak not |
| `…/notes/{id}/heavy·versions·presence` | ana notla aynı | ana notla aynı; presence yalnız kendi belgesi | ortak not alt belgeleri |
| `folderShares/{id}` | sahip, üye, davetli | sahip (gerçek klasör şart); davetli kendi satırı | F71.2 sahte ayna, klasör aynası |
| `folderShares/{id}/messages` | sahip, üyeler | sahip/üye yaratır; yazar ve sahip siler | F71.2 sohbet |
| `noteShares/{sahip_not}` | sahip, ortak çalışan | sahip (gerçek not şart); ortak çalışan yalnız ayrılır | ortak not aynası |
| `users/{to}/inboxNotes` | alıcı | arkadaş yaratır | F71.2 gelen notlar |
| `userDirectory/{eposta}` | giriş yapmış herkes (tek belge) | yalnız o e-postanın sahibi | F71.2 e-posta dizini |
| `userSearch/{uid}` | kimse (yalnız Function) | sahip, kendi e-postasıyla | F1.1, F71.2 arama dizini |
| `config/*` | herkes | kimse | config |
| `rateLimits/*` | kimse | kimse | config |
| `aiQuota/{uid}` | sahip | sahip, yalnız artırır | F71.2 AI kotası |
| Storage `users/{uid}/**` | sahip; paylaşılan notta read/both + ortak çalışan | sahip (50 MB, tür listesi); write/both + ortak çalışan | Storage testleri |
| Storage `users/{uid}/thumbs/*` | sahip | sahip (40 KB, jpeg/png/webp) | önizleme |
| Storage `folderChats/{id}/*` | sahip, üyeler | sahip, üyeler (8 MB, görsel) | F71.2 Storage sohbet |

Kapsam özeti (`rules-test/kapsam.js`, 2026-11-11): 43 `allow` koşulundan 33'ü testlerde
değerlendiriliyor. Değerlendirilmeyenler çoğunlukla sahibin kendi silme/okuma yolları.

## Sızıntı yolları (F71.6) — kilitli not / gizli klasör

| Yol | Durum | Bekçi |
|---|---|---|
| Arama | gövde aranmaz, kesit yok | `security_guard_test` |
| Kart önizlemesi, açılış anlık görüntüsü | gizli | `card_preview_test`, `home_snapshot_test` |
| Widget | gizli (kilit + gizli klasör) | `today_widget_payload_test` |
| Hatırlatıcı bildirimi | **sızıyordu → düzeltildi (G-26)** | `security_guard_test` |
| Hatırlatıcı şeridi / ekranı | gizli | `security_guard_test` |
| AppFunctions (`Ajan.kt`), harita köprüsü | kilitli + gizli klasör dışarıda (`YerelNot.gorunurNotlar`) | yok (Kotlin; cihaz) |
| AI bağlamı, ilgili notlar, brifing, anlamsal arama | kilitli dışarıda | `security_guard_test`, `notes_chat_retrieval_test`, `related_notes_test` |
| Paylaşım hedefi, çalışma kartları, çöp analizi | kilitli dışarıda | ilgili testler |
| Yedek | kilitli not DAHİL, şifresiz (G-11) | — |

## Geçmiş ve bağımlılıklar (F71.3, F71.7)

- Geçmiş (elle desen taraması, bütün dallar): özel anahtar, OAuth istemci sırrı, GitHub/Google
  jetonu, servis hesabı, keystore parolası **bulunmadı**. `.jks`, `key.properties`, `env.json`
  hiç commit'lenmemiş. Tek eşleşme Firebase API anahtarı (G-09). Kalıcı tarama: CI gitleaks.
  CI ilk koşusu (791 commit): tek bulgu eski bir `DEVIR.md` satırı — yanlış alarm
  (`.gitleaksignore`). osv-scanner: `pubspec.lock` (268 paket) temiz; `rules-test`
  31 bilinen açık (G-22, uyarı vermez).
- `pull_request_target` yok; iş akışı yalnız `push` + elle tetikleme. Release yazma yetkisi
  yalnız `android` ve `release` işlerinde.
- `dart pub outdated`: 131 paketin daha yeni sürümü var (kısıtla uyumsuz). Bilinen açık
  eşlemesi yerelde yapılamadı (osv-scanner kurulu değil) → CI `guvenlik` işinin kaydı.

## İncelenmeyenler

`ErrorLog`/Crashlytics'e not içeriği düşüyor mu · `FLAG_SECURE` kapsamı · PDF/PPTX
ayrıştırıcılarının bozuk dosyaya dayanıklılığı · `functions/push.js` · Gmail gövdesinin
tamamı (görülen: düz metin + yalnız `https?://` bağlantısı) · uygulama kilidinin derin
bağlantı/bildirim açılışında cihazdaki davranışı.

## Kullanıcı işi (konsol / hesap)

1. **Firebase Console → App Check:** Firestore, Storage ve Functions için "Enforce" açık mı?
2. **Google Cloud Console → Credentials:** Firebase API anahtarları uygulamaya (Android paket
   adı + SHA-1, web için alan adı) ve yalnız gereken API'lere kısıtlı mı?
3. **OAuth onay ekranı:** masaüstü istemcisinin kapsamları yalnız kullanılanlar mı (Drive
   dosya, Gmail, Takvim/Görevler); yayın durumu ve test kullanıcıları doğru mu?
4. **GitHub → Settings → Actions → Workflow permissions:** "Read repository contents" seçili
   olsun; dal koruması (main'e zorla push yok).
5. **Firestore'da `userDirectory`:** kendi e-postanın kaydındaki `uid` senin uid'in mi (G-01
   düzeltmeden önce ele geçirilmiş olabilir; uygulama açılınca kendi kaydını yeniden yazar).
6. Kararlar: G-11 (yedek parolası/uyarı), G-14 (misafir e-posta araması).
