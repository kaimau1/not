# DEVIR — oto/pano-tik-levha

Yapılanlar:
- İŞ 2 (300dd4f4): capture_mode / file_use / place_reminder / share_target levhalarında içerik
  builder dışında bir kez kuruluyor (S48 kalıbı). S52 `test/levha_klavye_test.dart`, 6 inset karesi
  kurulum/dizilme: kip 780/228→354/156, dosya 870/282→342/210, konum 690/270→354/198,
  paylaş 1296/426→354/222. Hafıza akicilik.md.
- İŞ 1: ana ekran kartı kutucukları salt görünüm. `note_card.dart` toggleCardItem +
  _CardItemRow/_NotePreview onToggle silindi; kutucuk dokunuşu kartın InkWell'ine → not açılır.
  Bekçi `test/card_checked_item_test.dart` (iki kutu: yazım 0, editör rotası açılır);
  optimistic_actions_test'teki "kartta madde işaretle" testi kalktı. Sürüm notu 16 Kasım.
- istek_tara note_card.dart: kart işaretleme için alıntılı kullanıcı isteği yok; eski D6
  plan önerisiydi (KULLANICI_DENEYIMI_PLANI B2, TUTARLILIK_PLANI B11).

Şu an: CI bekleniyor. main'e birleştirme YOK (yürütücü).
Test: flutter test test/levha_klavye_test.dart test/card_checked_item_test.dart
Cihazda ölçülmedi (telefon yok).
