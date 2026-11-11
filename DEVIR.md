# DEVIR — P11b (pageInk yedek/paket)
- Kök neden: `lib/features/notes/data/note_package.dart` `encodeNoteJson` (s.59) `Note.pageInk` yazmıyordu, `decodeNoteJson` okumuyordu; ayrıca `note_share.dart` `NoteShare.import` (s.~196) `Note(...)` kurarken `pageInk`'i geçirmiyordu → tam yedek + not paketi sayfa üstü el yazısını düşürüyordu.
- Ek üstü mürekkep (`Attachment.ink`) zaten taşınıyordu (`_encodeAttachment`), başka InkStroke alanı yok.
- Düzeltme: encode `pageInk` (boşsa yazılmaz), decode (yoksa boş → eski dosyalar açılır), import `pageInk: source.pageInk`.
- Testler: `test/note_package_test.dart` (gidiş-dönüş + eski paket), `test/backup_service_test.dart` (yedek→geri yükleme pageInk) — önce kırmızı, sonra yeşil.
- Komut: `flutter test test/note_package_test.dart test/backup_service_test.dart --reporter failures-only`
- Sıradaki: CI yeşil → yürütücü birleştirir (DEVIR.md silinir).
