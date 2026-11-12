# Dokunuş tepkisi dökümü (DENEYIM F78.4, 2026-11-12)

`lib/` içinde 84 `GestureDetector`; 42'sinde `onTap` var. Sık dokunulan yüzeylerin çoğu
zaten tepkili: ana ekran kartı ve klasör karoları `PressScale`, düğmeler `IconButton` /
`InkWell`, levha karoları `SheetTile` / `ActionMenu` (mürekkep dalgası). Aşağıdaki 42
`GestureDetector(onTap:)` Material dalgası taşımaz; sınıflarına göre:

## Düzeltildi — dokunuş başka yere götürüyor, basma tepkisi yoktu → `PressScale`

| Yer | Ne yapar |
|---|---|
| `share_target_sheet.dart` `_PickableCard` | paylaşım hedefi: kartı seçer, levha kapanır |
| `note_target_picker.dart` hücre | not hedefi seçici: kartı seçer |
| `folder_chat_screen.dart` görsel balonu | görseli tam ekran açar |

## Dokunmadan bırakıldı — tepki zaten AYNI KAREDE görünen durum değişimi

| Tür | Yerler |
|---|---|
| Seç / aç-kapa (seçili hâl hemen boyanır) | `view_mode_switch.dart:312`, `pen_tray.dart:416/1003/1142/1471`, `note_theme_sheet.dart:298/383`, `image_prepare_screen.dart:195`, `customizable.dart:84`, `items_editor_row.dart:320` (seçim kipi), `bubble_dock.dart:755/805/953`, `settings_account.dart:937` |
| Oynat / duraklat, denetimleri göster | `note_video_boxes.dart:136/428/518`, `video_viewer.dart:315/361` |
| Odak verir, satır ekler, düzenlemeye geçer | `dashboard_widgets.dart:348`, `items_editor.dart:2123` ("Yeni madde"), `note_image_caption.dart:140`, `attachment_actions.dart:326` (açıklama bandı), `note_images.dart:1362` |
| Şerit / hap aç-kapa | `pdf_page_box.dart:989`, `pdf_page_column.dart:203`, `pinned_media_pane.dart:1287`, `attachment_status.dart:207`, `note_video_boxes.dart:602` |

## Kapsam dışı

| Tür | Yerler | Neden |
|---|---|---|
| Perde / boşluk (dokununca kapatır) | `app_frame.dart:449`, `quick_add_fab.dart:145`, `gmail_screen.dart:1461`, `note_images.dart:1302/1733` | basılacak görünür yüzey yok |
| Jest alanı (sürükleme, çift dokunuş, uzun bas) | `note_images.dart:1995`, `bubble_pin.dart:1013`, `slide_canvas.dart:119` | F78.4: jest alanları kapsam dışı |
| Takvim görünümleri | `calendar_views.dart:835/1069` | Ek D: ay/hafta/gün görünümleri kimsede değil (yalnız ajanda satırı P40) |

Döküm betiği: tek seferlik; yeniden üretmek için `Grep "GestureDetector\("` + `onTap:`.
Yeni dokunulabilir yüzeyde kural: Material yüzeyse `InkWell`/`IconButton`; kart gibi
özel çizimse `PressScale` ile sar (jest yarışmasına girmez, kökte `setState` yok).
