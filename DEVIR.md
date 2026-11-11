# DEVIR — oto/P32-pano-isaret
- P32 = F60.S14: ana ekran (dashboard) kart önizlemesinde işaretli madde kutusu geri almıyor.
- Değişen: lib/features/notes/presentation/note_card.dart (satır kutusu + toggleCardItem),
  test/card_checked_item_test.dart, OTURTMA_PLANI.md (F60.S14 [x]), docs/regresyon_listesi.md.
- Test: kırmızı (geri alıyordu) -> yeşil. Tam flutter analyze koşuldu.
- Sabah bakılacak: kartta işaret geri alma isteniyorsa ayrı yol (uzun basma).
