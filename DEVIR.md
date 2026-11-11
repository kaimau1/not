# DEVİR — P12 Güvenlik denetimi + CI kapıları (Faz 71)

Dal: `oto/P12-guvenlik` (origin/main 8e0f787a'dan).

## Yapılanlar
- F71.2 kurallar: `rules-test/rules.test.js`'e 12 yeni test (5'i eski kuralda KIRMIZI idi);
  `firestore.rules` sıkılaştırıldı (userDirectory e-posta bağı = YÜKSEK bulgu, userSearch,
  friendRequests/friends e-posta + tavan, üye klasör adını değiştiremez, senderName tavanı).
  Yerelde 26/26 yeşil.

## Şu an
- Sırada: openLink şema süzgeci + test, `web/_headers` çerçeve başlığı, CI kapıları
  (gitleaks, osv-scanner, kural kapsam özeti, `permissions:`), bekçi testleri
  (`test/security_guard_test.dart`), `docs/guvenlik.md`, `docs/guvenlik_denetimi.md`,
  `SECURITY.md`, plan `[x]`.

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
