# Cloud Functions — `searchUsers`

> **Otomatik dağıtım**: `main`e her push'ta `.github/workflows/build.yml`
> içindeki `deploy` işi bu fonksiyonu da yayınlamayı DENER (adım: "Cloud
> Functions'ı yayınla"). Elle `firebase deploy --only functions`
> çalıştırmana GEREK YOK — proje Blaze plana geçmişse ve
> `FIREBASE_SERVICE_ACCOUNT` gizli anahtarının rolleri yeterliyse bir
> sonraki main push'unda kendiliğinden yayınlanır. Bu adım
> `continue-on-error: true` ile işaretli: Blaze'e geçilmediyse veya rol
> eksikse KIRMIZI (başarısız) görünür ama geri kalan yayın (Firestore/
> Storage kuralları, web, Cloudflare) engellenmez. Actions sekmesinde bu
> adımın loguna bakıp neden başarısız olduğunu görebilirsin — aşağıdaki iki
> ön koşuldan biri eksik demektir:
> 1. Proje Blaze (pay-as-you-go) planda değil.
> 2. `FIREBASE_SERVICE_ACCOUNT` servis hesabının IAM rolleri Cloud
>    Functions dağıtımına yetmiyor — gerekli roller: **Cloud Functions
>    Developer**, **Service Account User**, **Cloud Build Editor**,
>    **Artifact Registry Writer** (2. nesil fonksiyonlar Cloud Run üstünde
>    çalıştığı için **Cloud Run Admin** de gerekebilir). Firestore/Storage
>    kuralları için kullanılan servis hesabının rolleri genelde bunları
>    kapsamaz, ayrıca eklemek gerekebilir (Google Cloud Console → IAM).
>
> Aşağıdaki elle-dağıtım adımları yalnız yerelde test etmek ya da CI dışı
> bir dağıtım yapmak istersen gerekli.

Tek fonksiyon: arkadaş eklemede "tüm kullanıcılar içinde ad/e-posta ile
arama" (kullanıcı isteği 2026-08-21). Neden Cloud Function gerektiği ve
gizlilik gerekçesi `firestore.rules`'taki `userSearch` koleksiyonu kuralında
ve `functions/index.js` başındaki yorumda anlatılıyor — özetle:
`userDirectory` koleksiyonu (e-postayla tam eşleşme) zaten herkese `get`
açık ama `list` KAPALI; isimle arama `list`/aralık sorgusu gerektirdiği için
aynı deseni izleyemiyoruz, o yüzden okuma Admin SDK'ya (bu fonksiyona)
taşındı ve sonuç 15 kayıtla sınırlandı.

## Kurulum (bir defalık)

```bash
npm install -g firebase-tools   # yoksa
firebase login
cd functions
npm install
```

## Yerelde test (opsiyonel, emülatörle)

```bash
cd functions
npm install
firebase emulators:start --only functions,firestore
```

## Dağıtım (GEREKLİ — bu fonksiyon deploy edilmeden arama çalışmaz)

```bash
firebase deploy --only functions
```

**Blaze (pay-as-you-go) plan gerekir** — Cloud Functions ücretsiz Spark
planında çalışmaz. Firebase konsolunda proje ayarlarından plan
yükseltilmeli (kullanım bu ölçekte pratikte ücretsiz kotanın içinde kalır,
ama plan seçimi Google tarafında zorunlu).

Aynı anda Firestore kurallarını da güncel tutmayı unutma (bu değişiklikte
`userSearch` koleksiyonu kuralı eklendi):

```bash
firebase deploy --only firestore:rules
```

## Uygulama tarafı

- `pubspec.yaml`'a `cloud_functions` paketi eklendi — `flutter pub get`
  çalıştırmayı unutma.
- Kullanıcı giriş yaptığında (`FriendsRepository.syncOwnDirectoryEntry`,
  `DashboardScreen.initState`'ten çağrılıyor) hem `userDirectory` hem
  `userSearch` dokümanı yazılıyor. **Fonksiyon deploy edilmeden önce**
  giriş yapmış kullanıcılar `userSearch`e zaten yazılmaya başlar (bu kısım
  Cloud Function'a bağlı değil, düz Firestore yazımı) — deploy'dan SONRA
  arama hemen çalışır, geriye dönük dolgu gerekmez.
