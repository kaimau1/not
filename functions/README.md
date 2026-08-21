# Cloud Functions — `searchUsers`

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
