# DEVIR — P08 büyük dosyalar yerelde (F65.9)

Yapılanlar (dal oto/P08-buyuk-dosya):
- `Attachment.localOnly` (model, knownKeys, copyWith, fromMap/toMap, withLayoutOf; `skipsUpload` içerir).
- `copyFileStreamed` + `isNoSpaceError` (lib/core/utils/local_file.dart).
- `AttachmentRepository.prepareLocalPdf` (akışla kopya, localOnly, önbellek kopyasını siler, `DeviceFullException`).
- `readBytes` localOnly'de `FileTooLargeException` (RAM'e alma yok).
- Editör `_addPdfFile`: boyut > maxBytes ise `_addLocalPdfFile` (şeritte "Kopyalanıyor… %", sonra bilgi snack).
- Durum: `AttachmentStatus.deviceOnly` / `otherDevice` + l10n (tr/en).
- Testler: test/large_local_pdf_test.dart, forward_compat_test, attachment_status_test (yeşil).

Kalan (madde dışı ya da cihaz): ek menüsünde yedekle⇄yalnız cihaz geçişi; OCR/metin
dizini tembelliği; gmail/share_intake/quick_add yolları hâlâ bayt tabanlı (tavanda reddeder);
tablette 1 GB kabul ölçümü (cihazda doğrulanmadı).

Test: flutter test test/large_local_pdf_test.dart test/forward_compat_test.dart test/attachment_status_test.dart --reporter failures-only
