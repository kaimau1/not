# DEVİR — oto/P17-ekler (P17: F65.4, F65.5, F65.7, F60.3)

## Yapılanlar
- F65.4 bekleyen ek bildirimi + "Şimdi dene" (c947e09b). Kanıt: `test/attachment_status_test.dart` kırmızı → yeşil.
- F65.5 PDF ilk sayfa önizlemesi buluta (bu commit). Kanıt: `test/pdf_cloud_thumb_test.dart` kırmızı → yeşil.

## Şu an
- F65.7 ek ekleme sonrası kısa ipucu.

## Kök neden / kanıt
- F65.4: kuyruk yalnız uygulama açıkken çalışır (`upload_queue.dart` `UploadQueue`); arka plana geçiş izi yoktu. Bağlantı: `reminder_service.dart` `_armUploadNotice`/`_cancelUploadNotice`.

- F65.5: `attachment_repository.dart` `uploadToDrive` yalnız görsele önizleme üretiyordu; kart `_PdfFirstPage` dosyasızken simgeye düşüyordu.

## Denenip işe yaramayan
- (yok)

## Sıradaki
- F65.7 → F60.3 (F60.3: `WrapTextController` düzeyinde silme ÇALIŞIYOR — dokunuş yolu şüpheli).

## Açık test
- `flutter test test/attachment_status_test.dart test/pdf_cloud_thumb_test.dart --reporter failures-only`
