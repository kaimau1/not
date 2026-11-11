# DEVİR — oto/P17-ekler (P17: F65.4, F65.5, F65.7, F60.3)

## Yapılanlar
- F65.4 bekleyen ek bildirimi + "Şimdi dene" (c947e09b). Kanıt: `test/attachment_status_test.dart` kırmızı → yeşil.
- F65.5 PDF ilk sayfa önizlemesi buluta (0d4671f7). Kanıt: `test/pdf_cloud_thumb_test.dart` kırmızı → yeşil.
- F65.7 kısa yerleşim ipucu, 4 sn (bu commit). Kanıt: `test/view_mode_switch_test.dart` F65.7. Tür bazlı varsayılan sabah bakılacak.

## Şu an
- F60.3 "📖 s.N" satırı silinemiyor.

## Kök neden / kanıt
- F65.4: kuyruk yalnız uygulama açıkken çalışır (`upload_queue.dart` `UploadQueue`); arka plana geçiş izi yoktu. Bağlantı: `reminder_service.dart` `_armUploadNotice`/`_cancelUploadNotice`.

- F65.5: `attachment_repository.dart` `uploadToDrive` yalnız görsele önizleme üretiyordu; kart `_PdfFirstPage` dosyasızken simgeye düşüyordu.

## Denenip işe yaramayan
- (yok)

## Sıradaki
- F60.3, sonra rapor (F60.3: `WrapTextController` düzeyinde silme ÇALIŞIYOR — dokunuş yolu şüpheli).

## Açık test
- `flutter test test/attachment_status_test.dart test/pdf_cloud_thumb_test.dart test/view_mode_switch_test.dart --reporter failures-only`
