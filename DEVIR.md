# DEVIR — P67 S1 "yalnız değişeni dinle" (dal oto/P67-s1-degiseni-dinle)

Yapılanlar:
1. Eşitleme damgası `syncAt` (sunucu saati) HER not yazımında: `Note.toMap`, depodaki 10 yazım,
   klasör silme (folderId=null), video transkript işçisi, Kotlin köprüsü (YerelNot.belge,
   HaritaNotlari 2 güncelleme). Bekçi `test/notes_sync_stamp_test.dart`.

Şu anki adım: delta akışı (bayrak `config/app.syncDeltaListen`, varsayılan kapalı).
Sıradaki: `lib/features/notes/data/notes_delta_sync.dart` + bayrak + testler + okuma hesabı.
Test: `flutter test test/notes_sync_stamp_test.dart --reporter failures-only`
