# DEVIR — P54 Markdown (.md) desteği (dal oto/P54-markdown)

Durum: kod + testler yazıldı; cihazda doğrulanmadı.

Envanter (önce → sonra):
1. Not içi "Dosya ekle"/sürükle-bırak: .md seçilemiyordu / "desteklenmiyor" → METİN EKİ (`markdownAttachment`, rozet MD).
2. Ek görüntüleyici: yoktu (metin eki ekranı ham gösterirdi) → TranscriptScreen .md'yi `markdownReadable` ile okunur gösterir; "Tümünü nota ekle"/"Yeni not" var olan düğmeler.
3. Paylaş (SEND text/*): ham Markdown gövdeye → `markdownNoteDraft` (başlık, liste, ☐/☑). "Birlikte aç" (VIEW): filtre yoktu → manifestte text/markdown, text/x-markdown + .md/.markdown pathPattern.
4. Web: seçici süzgecinde md yoktu → `PickedFileKind.allExtensions` + `DocPicker.byExtension` md/markdown = text/markdown; sürükle-bırak aynı yoldan. Ana ekran "Dosya" .md → yeni not.

Test: test/markdown_support_test.dart (8). Yerelde security_guard_test CRLF yüzünden kırmızı (önceden var, CI Linux'ta yeşil).
Cihazda bakılacak: dosya yöneticisinden .md "Birlikte aç"ta Notlar çıkıyor mu; paylaşımda not başlığı.
Sabah bakılacak: metin eki ekranının başlığı .md'de de "Transkript" yazıyor.
