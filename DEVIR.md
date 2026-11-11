# DEVİR — oto/P17-ekler (P17: F65.4, F65.5, F65.7, F60.3)

## Yapılanlar
- F65.4 bekleyen ek bildirimi + "Şimdi dene" (c947e09b). Kanıt: `test/attachment_status_test.dart` kırmızı → yeşil.
- F65.5 PDF ilk sayfa önizlemesi buluta (0d4671f7). Kanıt: `test/pdf_cloud_thumb_test.dart` kırmızı → yeşil.
- F65.7 kısa yerleşim ipucu, 4 sn (son F65.7 commit'i). Kanıt: `test/view_mode_switch_test.dart` F65.7. Tür bazlı varsayılan sabah bakılacak.
- F60.3 PDF referansı dokunuşu klavyeyi kilitlemez (bu commit). Kanıt: `test/pdf_ref_keyboard_test.dart`.

## Şu an
- Paket bitti; CI bekleniyor.

## Kök neden / kanıt
- F65.4: kuyruk yalnız uygulama açıkken çalışır (`upload_queue.dart` `UploadQueue`); arka plana geçiş izi yoktu. Bağlantı: `reminder_service.dart` `_armUploadNotice`/`_cancelUploadNotice`.
- F65.5: `attachment_repository.dart` `uploadToDrive` yalnız görsele önizleme üretiyordu; kart `_PdfFirstPage` dosyasızken simgeye düşüyordu.
- F60.3: `tag_tap.dart` `linkAtPoint` referansı PDF yokken de bağlantı sayıyordu (klavye açılmıyor).

## Denenip işe yaramayan
- F60.3: `WrapTextController` sarma çapası şüphesi — geri silme sarma açık/kapalı çalışıyor, kök değil.

## Sıradaki
- CI yeşilse birleştirme (usta işi); cihaz doğrulaması KALANLAR'a.

## Açık test
- `flutter test test/attachment_status_test.dart test/pdf_cloud_thumb_test.dart test/view_mode_switch_test.dart test/pdf_ref_keyboard_test.dart --reporter failures-only`
