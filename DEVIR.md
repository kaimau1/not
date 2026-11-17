# DEVIR — P67 S1 "yalnız değişeni dinle" (dal oto/P67-s1-degiseni-dinle)

Yapılanlar:
1. 7a5cb00e Eşitleme damgası `syncAt` (sunucu saati) HER not yazımında: `Note.toMap`, depodaki
   10 yazım, klasör silme, video transkript işçisi, Kotlin köprüsü. Bekçi `notes_sync_stamp_test`.
2. b434c13b `NotesDeltaFeed` (`lib/features/notes/data/notes_delta_sync.dart`): önbellek
   dinleyicisi + `syncAt > imleç−10dk` besleyicisi + `count()` ağı; geri dönüşler bugünkü yola.
   Bayrak `config/app.syncDeltaListen` → prefs `sync_delta_listen` (sonraki açılış); yerel geri
   alma prefs `sync_delta_off`. Varsayılan KAPALI; kapalıyken `watchNotes()` eskisi.
3. Belgeler: `docs/hafiza/veri.md` (S1 bölümü), `docs/regresyon_listesi.md`.

Okuma (300 not soğuk açılış, sahte DB): önce 300 → sonra 0/5/50 değişiklikte 2/6/51.
rules-test: koşuldu, yeşil (kural değişmedi). Kotlin derlenmedi (Android SDK yok) → CI APK işi.

Kalan / cihaz bekliyor: iki cihaz testi (veri.md listesi); `ListenSource.cache` davranışı cihazda.
Bayrak Firestore'da AÇILMADI; açmadan önce `minClient` damgalı sürüme.
Test: `flutter test test/notes_sync_stamp_test.dart test/notes_delta_sync_test.dart --reporter failures-only`
