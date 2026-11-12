# Levha ve onay penceresi dökümü (DENEYIM F76.3 / F76.4, 2026-11-12)

Kural (§2.3, K-D7): başlık `SheetHeader` (56 dp, solda 16 dp, `AppText.sheetTitle` 18/24 w600,
sağda ✕), bölüm adı `SectionLabel` (`AppText.section` 14/20 w600 `primary`), **✕ olan levhada
tutamak yok**, alt güvenli alan `showAppSheet` içinde HER levhada (2026-11-06'dan beri).

## Bu pakette çevrilenler

| Levha | Önce | Sonra |
|---|---|---|
| Not ⋮ menüsü (`showActionMenuSheet`, editör) | tutamak + ✕; altta "Ekranı düzenle · Ayarlar"; Sil yarı saydam karo | tutamak yok; ⚙ açılır menü (Menüyü düzenle · Ekranı düzenle · Ayarlar, K-D10); Sil `DestructiveRow` |
| Kart ⋮ menüsü (`showNoteActionsSheet`) | tutamak + ✕ | başlık varsa tutamak yok (başlıksız notta ✕ yok → tutamak kalır) |
| Menüyü düzenle (`_MenuLayoutEditor`) | tutamak + ✕ | tutamak yok |
| AI levhası (`showAiSheet`) | tutamak + ✕; çerçeveli kartlar; bölüm adı 20 dp içeride | tutamak yok; satırlar `SheetTile.rich`; "Bu not" kutuları çerçevesiz `surfaceContainer` (2 sütun, açıklamalar aynı); bölüm adı 16 dp |
| Paylaş levhası (`showNoteShareSheet`) | tutamak + ✕; bölüm adı 12 pt `labelMedium`; kutusuz `ListTile` | tutamak yok; bölüm adı `SectionLabel`; Ayarlı PDF/Word, Balonlu PDF, Not paketi, Arkadaşa gönder, Birlikte düzenle, Klasörü paylaş → `SheetTile.rich` (misafirde kilit rozeti ›'nin solunda) |
| Dışa aktarma seçimi (`showExportChoiceSheet`) | `ListTile` | `SheetTile.rich` (✕ yok, tutamak kalır) |
| Bütün `SheetHeader`'lar (bileşenin içi, F72.5 kalanı) | 48 dp, solda 20 dp, `titleMedium` 16 pt | 56 dp, solda 16 dp, `sheetTitle` 18 pt |

## Bütün `showAppSheet` çağrıları

"Tutamak" = `showDragHandle`; "Başlık" = levhanın başlığı nasıl çiziliyor (`-` = başlık yok ya
da gövde başka sınıfta). **Kapsam içinde tutamak + ✕ birlikte kalan levha: yok** (✕ yalnız
`SheetHeader`'da var; `SheetHeader`'lı ve tutamaklı kalanlar "kapsam dışı" sütununda).

| Çağrı (`lib/`) | Tutamak | Başlık | Kapsam dışı |
|---|---|---|---|
| `core/widgets/action_menu_sheet.dart:89` | !menu.hasHeader | SheetHeader | — |
| `core/widgets/action_menu_sheet.dart:197` | false | SheetHeader | — |
| `core/widgets/color_palette.dart:45` | true | el yazısı | — |
| `features/ai/presentation/ai_sheet.dart:52` | false | SheetHeader | — |
| `features/auth/presentation/account_required.dart:21` | true | el yazısı | — |
| `features/auth/presentation/account_sheet.dart:102` | true | - | — |
| `features/calendar/presentation/calendar_screen.dart:387` | true | - | — |
| `features/calendar/presentation/calendar_screen.dart:999` | true | - | — |
| `features/calendar/presentation/event_editor.dart:62` | true | SheetHeader | takvim editörü |
| `features/calendar/presentation/event_editor.dart:269` | true | SheetHeader | takvim editörü |
| `features/calendar/presentation/google_calendar_ui.dart:24` | true | el yazısı | — |
| `features/calendar/presentation/google_calendar_ui.dart:288` | true | el yazısı | — |
| `features/calendar/presentation/note_calendar_links.dart:126` | true | el yazısı | — |
| `features/calendar/presentation/routines_screen.dart:211` | true | el yazısı | takvim (rutin) |
| `features/calendar/presentation/routines_screen.dart:274` | true | SheetHeader | takvim (rutin) |
| `features/calendar/presentation/task_editor.dart:40` | true | SheetHeader | takvim editörü |
| `features/folders/presentation/folder_chat_screen.dart:102` | true | - | — |
| `features/folders/presentation/folder_chat_screen.dart:137` | true | - | — |
| `features/folders/presentation/folder_chat_screen.dart:436` | true | - | — |
| `features/folders/presentation/folder_sheets.dart:217` | true | - | — |
| `features/folders/presentation/folder_sheets.dart:349` | true | - | — |
| `features/folders/presentation/folder_sheets.dart:404` | true | el yazısı | — |
| `features/folders/presentation/folder_sheets.dart:620` | true | - | — |
| `features/friends/presentation/friends_screen.dart:55` | true | - | — |
| `features/friends/presentation/friends_screen.dart:254` | true | el yazısı | — |
| `features/inbox/presentation/send_note_sheet.dart:39` | true | el yazısı | — |
| `features/notes/presentation/archive_insights_sheet.dart:27` | true | - | — |
| `features/notes/presentation/capture_mode_sheet.dart:86` | true | el yazısı | — |
| `features/notes/presentation/collaborators_sheet.dart:40` | true | - | — |
| `features/notes/presentation/color_picker_sheet.dart:41` | true | el yazısı | — |
| `features/notes/presentation/dashboard_background_sheet.dart:38` | true | el yazısı | — |
| `features/notes/presentation/duplicates_sheet.dart:19` | true | - | — |
| `features/notes/presentation/editor/ai_result_sheet.dart:22` | true | - | — |
| `features/notes/presentation/editor/attach_sheet.dart:21` | true | SheetHeader | Ekle levhası |
| `features/notes/presentation/editor/attachment_actions.dart:283` | true | - | — |
| `features/notes/presentation/editor/attachment_status.dart:96` | true | - | — |
| `features/notes/presentation/editor/attachment_strip.dart:800` | true | el yazısı | — |
| `features/notes/presentation/editor/audio_recorder_sheet.dart:17` | varsayılan | - | — |
| `features/notes/presentation/editor/calculator_sheet.dart:14` | true | - | — |
| `features/notes/presentation/editor/embed_sheet.dart:123` | true | el yazısı | — |
| `features/notes/presentation/editor/embed_sheet.dart:372` | true | el yazısı | — |
| `features/notes/presentation/editor/format_menu.dart:321` | true | el yazısı | biçim çubuğu |
| `features/notes/presentation/editor/in_note_find.dart:153` | true | el yazısı | — |
| `features/notes/presentation/editor/note_editor_actions.dart:555` | true | - | — |
| `features/notes/presentation/editor/note_editor_actions.dart:787` | true | - | — |
| `features/notes/presentation/editor/note_editor_ai.dart:126` | true | - | — |
| `features/notes/presentation/editor/note_editor_appearance.dart:149` | true | - | — |
| `features/notes/presentation/editor/note_editor_appearance.dart:276` | true | el yazısı | — |
| `features/notes/presentation/editor/note_editor_media_view.dart:69` | true | el yazısı | — |
| `features/notes/presentation/editor/note_editor_media_view.dart:441` | true | el yazısı | — |
| `features/notes/presentation/editor/note_history_sheet.dart:18` | true | el yazısı | — |
| `features/notes/presentation/editor/note_search_sheet.dart:47` | true | - | — |
| `features/notes/presentation/editor/pdf_page_box.dart:838` | true | - | — |
| `features/notes/presentation/editor/pdf_page_box.dart:1515` | true | el yazısı | — |
| `features/notes/presentation/file_use_sheet.dart:181` | true | - | — |
| `features/notes/presentation/filter_sheet.dart:33` | false | SheetHeader | — |
| `features/notes/presentation/filter_sheet.dart:613` | true | el yazısı | — |
| `features/notes/presentation/note_actions_sheet.dart:46` | !menu.hasHeader | SheetHeader | — |
| `features/notes/presentation/note_link_ui.dart:33` | true | el yazısı | — |
| `features/notes/presentation/note_link_ui.dart:145` | true | el yazısı | — |
| `features/notes/presentation/note_link_ui.dart:187` | true | el yazısı | — |
| `features/notes/presentation/note_stats_sheet.dart:18` | true | el yazısı | — |
| `features/notes/presentation/note_template_sheet.dart:42` | true | - | — |
| `features/notes/presentation/note_template_sheet.dart:489` | true | - | — |
| `features/notes/presentation/note_theme_sheet.dart:44` | true | SheetHeader | tema levhası |
| `features/notes/presentation/place_reminder_sheet.dart:31` | true | - | — |
| `features/notes/presentation/qr_scan_screen.dart:130` | varsayılan | el yazısı | — |
| `features/notes/presentation/reminder_sheet.dart:26` | true | - | — |
| `features/notes/presentation/reminder_sheet.dart:34` | true | - | — |
| `features/notes/presentation/share_sheet.dart:79` | false | SheetHeader | — |
| `features/notes/presentation/share_sheet.dart:611` | true | - | — |
| `features/notes/presentation/share_target_sheet.dart:106` | true | - | — |
| `features/notes/presentation/study_cards_screen.dart:176` | true | el yazısı | — |
| `features/notes/presentation/trash_analysis_sheet.dart:27` | true | - | — |
| `features/notes/presentation/trash_screen.dart:421` | true | - | — |
| `features/notes/presentation/viewers/area_actions.dart:21` | true | el yazısı | — |
| `features/notes/presentation/voice_capture_sheet.dart:122` | varsayılan | - | — |
| `features/notes/presentation/voice_capture_sheet.dart:582` | varsayılan | el yazısı | — |
| `features/settings/presentation/settings_sections/settings_ai.dart:349` | true | - | — |
| `features/settings/presentation/settings_sections/settings_appearance.dart:71` | true | - | — |
| `features/settings/presentation/settings_sections/settings_appearance.dart:555` | true | el yazısı | — |
| `features/settings/presentation/settings_sections/settings_appearance.dart:811` | true | el yazısı | — |
| `features/settings/presentation/settings_sections/settings_voice.dart:317` | true | - | — |
| `features/settings/presentation/theme_picker.dart:201` | true | el yazısı | tema levhası |

**Sabah bakılacak (F76.3 kalanı):**
- Kapsam dışı ve hâlâ tutamak + ✕ (`SheetHeader`) olanlar: Ekle levhası (`attach_sheet.dart:21`),
  tema levhası (`note_theme_sheet.dart:44`), takvim editörleri (`event_editor.dart`,
  `task_editor.dart`, `routines_screen.dart:274`), kalem tepsisi (`pen_tray.dart`,
  `showModalBottomSheet`). Sahibi olan paket `showDragHandle: false` yapmalı (K-D7).
- "el yazısı" başlıklı 34 levha (`titleMedium`/`titleLarge` ile kendi `Text`'i, ✕ yok,
  tutamaklı): K-D7'ye uyuyor ama başlık puntosu 16 (`SheetHeader` 18). `SheetHeader`'a çevirmek
  her levhaya ✕ ekler ve ~34 dosyaya (çoğu `editor/` — P20) dokunur; ayrı paket önerilir
  (P41 göçüyle birlikte).
- `SectionLabel` iç dolgusu (üst 20 / alt 8, §2.3) YAPILMADI: not menüsünde 4 bölüm × 16 dp
  levhayı yeniden uzatır (F76.1 kabulüyle çelişir). Öneri: menü ızgarasında bugünkü 10/2
  kalsın, liste ekranları için ayrı karar.
- `showModalBottomSheet`'i doğrudan çağıran 8 yer (`account_required.dart`, `tag_tap.dart`,
  `spell_settings_sheet.dart`, `pen_tray.dart`, `item_divider_style.dart`, `gmail_screen.dart`,
  `tasks_screen.dart`, `line_task_chip.dart`) ortak hareketi ve alt güvenli alanı almıyor.

## Onay pencereleri (F76.4)

- **Tema düzeyinde** (`AppTheme._base` → `dialogTheme`): bütün `AlertDialog` başlıkları
  `AppText.sheetTitle` (18/24 w600; M3 varsayılanı 24 pt `headlineSmall`), gövdesi
  `AppText.body` (14/20). `actions` M3'te zaten sağda.
- **Ortak yardımcı** `lib/core/widgets/confirm_dialog.dart` → `showConfirmDialog(...,
  destructive:)`: solda "Vazgeç" `TextButton`, sağda onay `FilledButton` (yıkıcıysa `error` /
  `onError`). Çevrilenler: klasör sil ×2 (`folder_sheets.dart` — onay `error` tonunda
  DEĞİLDİ), etiket sil (`filter_sheet.dart`), çöpü boşalt ve kalıcı sil (`trash_screen.dart` —
  kalıcı sil `error` tonunda DEĞİLDİ).
- `showDialog` toplam 57 çağrı. Yıkıcı olup `error` tonu olmayan, sabah bakılacak:
  `calendar_entry_delete.dart:35` (takvim, kapsam dışı), `friends_screen.dart:273`,
  `collaborators_sheet.dart:341`, `assistant_confirm.dart:14`, `note_history_sheet.dart:122`
  (editör). Geri kalan `AlertDialog`'lar (`TextButton` + `FilledButton`) kalıba uyuyor; özel
  `Dialog(` kullananlar (kilit, kalem, AI seçimleri, tekrar seçici) onay penceresi değil.
