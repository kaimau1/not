# DEVİR — P12 Güvenlik denetimi + CI kapıları (Faz 71)

Dal: `oto/P12-guvenlik` (origin/main 8e0f787a'dan).

## Yapılanlar
- F71.2 kurallar: `rules-test/rules.test.js`'e 12 yeni test (5'i eski kuralda KIRMIZI idi);
  `firestore.rules` sıkılaştırıldı (userDirectory e-posta bağı = YÜKSEK bulgu, userSearch,
  friendRequests/friends e-posta + tavan, üye klasör adını değiştiremez, senderName tavanı).
  Yerelde 26/26 yeşil.

- F71.3/8 CI: `guvenlik` işi (gitleaks + osv-scanner, uyarı düzeyi), `rules-test/kapsam.js`
  (kural kapsam özeti, npm test sonunda), üst düzey `permissions: contents: read`,
  üçüncü taraf action'lar SHA'ya sabit, `.gitleaks.toml`.
- F71.4/5/6: `linkUri` şema süzgeci (link_text.dart), `web/_headers` çerçeve başlığı,
  kilitli notun hatırlatıcı bildirimi artık başlık/gövde göstermiyor (reminder_service.dart),
  bekçi `test/security_guard_test.dart` (13 test yeşil). Tam analyze temiz.

- Belgeler: docs/guvenlik.md, docs/guvenlik_denetimi.md (G-01…G-26), SECURITY.md; plan F71.1–8
  [x] + Durum; regresyon listesi; docs/hafiza/veri.md.
- CI ilk koşu (42967262678): guvenlik işi yeşil; osv pubspec.lock TEMİZ, rules-test 31 açık
  (test aracı → uyarıdan çıkarıldı, özet satırı); gitleaks 1 bulgu (ayrıntı görünmüyordu →
  --verbose eklendi).

## Şu an
- Sırada: yeni koşuda gitleaks bulgusunun dosya/kuralına bak; yanlış alarmsa
  .gitleaks.toml izin listesine ekle (gerçek sırsa denetime YÜKSEK olarak yaz, değeri yazma).
  Sonra test parçalarının yeşilini bekle, rapor.

## Kanıt / kök neden
- `firestore.rules` userDirectory: yorum "kimlik e-postayla eşleşir" diyordu, kural yalnız
  `uid == auth.uid` bakıyordu → herkes başkasının e-posta kaydını kendine yönlendirebiliyordu.
- Geçmiş taraması (elle, desen): özel anahtar / OAuth sırrı / jeton YOK; yalnız Firebase
  API anahtarı (`google-services.json`, `firebase_options.dart` — tasarım gereği açık).

## Komutlar
- Kural testi (yerel, Java = Android Studio JBR):
  `cd rules-test && JAVA_HOME="/c/Program Files/Android/Android Studio/jbr" PATH="$JAVA_HOME/bin:$PATH" npm test`
- `"C:/src/flutter/bin/flutter.bat" test test/security_guard_test.dart --reporter failures-only`

## İşe yaramayan
- gitleaks / osv-scanner yerelde kurulu değil → yalnız CI'da koşar.
