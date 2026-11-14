# DEVIR — oto/ice-aktarma-kaybi
- Yapılan: içe aktarmada sessiz not kaybı düzeltildi (`NoteShare.import` tek yazım).
- Kök neden: `cloud_firestore` 7.1.0 Android `FlutterFirebaseFirestorePlugin.java:649`
  her `set`'i `cachedThreadPool`ta ayrı iş parçacığında çalıştırır → sıra garantisi yok.
  `note_share.dart` eskiden `createNote` (beklenmeyen, boş, birleştirmesiz set) + `updateNote`;
  boş yazım geç düşünce içerik silinir → `cleanupEmptyNotes` 2 dk sonra siler (240→173).
- Düzeltme: `NotesRepository.newNoteId()` + tek `updateNote` (`createdBy` extras'ta).
- Kanıt: `test/import_service_test.dart` "geç düşen ilk yazım" — önce kırmızı ('' ≠ 'Kalıcı'), sonra yeşil.
- "Hepsi Bugün'de" hata değil: `dateBuckets` `updatedAt`'e göre.
- İşe yaramayan/elenen: kural reddi (sahip her şeyi yazar), uid değişimi, Cloud Function, özet kümesi.
- Cihazda doğrulanmadı: KONTROL_LISTEM 42.
- Açık: `createNote`+hemen `updateNote` yapan diğer çağıranlar aynı riski taşır (gmail_screen:975, assistant_service:298, note_editor_actions:1083...).
- Test: `flutter test test/import_service_test.dart test/backup_service_test.dart test/share_intake_test.dart --reporter failures-only`
