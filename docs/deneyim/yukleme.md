# Yükleme hâlleri dökümü (DENEYIM F78.3, 2026-11-12)

Kural (§2.3, ilke 5): **içerik alanındaki** halka `DelayedSpinner` (300 ms altında biten
işte hiç görünmez, sonra 150 ms'de belirir). **Düğme içi** halka ve **ilerleme değeri
taşıyan** halka olduğu gibi kalır (dokunuşun karşılığı / yüzde bilgisi gecikmemeli).
Yeni içerik halkası yazarken: `const Center(child: DelayedSpinner())`.

## DelayedSpinner'a çevrilenler (içerik alanı)

| Yer | Dosya |
|---|---|
| Arşiv, Çöp listesi ilk yükleme | `archive_screen.dart`, `trash_screen.dart` |
| Arkadaşlar listesi | `friends_screen.dart` |
| Klasör sohbeti: ileti listesi, görsel yer tutucusu | `folder_chat_screen.dart` |
| Gmail: ileti gövdesi, ek küçük resmi | `gmail_screen.dart` |
| Yinelenenler levhası, sürüm geçmişi levhası, not bağlantısı listesi | `duplicates_sheet.dart`, `editor/note_history_sheet.dart`, `note_link_ui.dart` |
| Sunum: not bölmesi, görüntüleyici, gömülü kutu | `editor/slide_note_pane.dart`, `viewers/slide_viewer_screen.dart`, `editor/slide_page_box.dart` |
| Görsel görüntüleyici: indirme, işlem; video görüntüleyici: oynatıcı kurulumu | `viewers/image_viewer.dart`, `viewers/video_viewer.dart` |
| Tarama düzenleme: görsel çözülürken | `scan_edit_screen.dart` |
| Kılavuz, Gizlilik metni; ses listesi | `guide_screen.dart`, `privacy_screen.dart`, `settings_sections/settings_voice.dart` |
| Giriş: otomatik oturum açma | `login_screen.dart` |
| Sabit/gömülü PDF belge açılırken, sabit PDF/video rota geçişinde | `editor/media_loading_cover.dart` (`MediaLoadingCover`: küçük resim + %24 perde + gecikmeli halka; `pdf_page_box.dart`, `pinned_media_pane.dart`) |

## Olduğu gibi kalanlar

| Tür | Yer | Neden |
|---|---|---|
| Düğme içi (14–28 dp) | AI, Gmail, giriş, takvim, tarama, ses, ayarlar düğmeleri; `split_shell`, `app_update`, `speak_button`, `audio_card_box`, video ▶ kurulumu | dokunuşun anında karşılığı |
| İlerleme değerli | `attachment_strip.dart` ve `note_media_box.dart` (indirme yüzdesi), `dashboard_widgets.dart` (basılı tutma halkası), `ai_hub_screen.dart` (kota) | değer gösterir, bekleme halkası değil |
| İşlem perdesi | `qr_scan_screen.dart`, `viewers/area_select.dart`, `viewers/area_actions.dart` | kullanıcının başlattığı işlem; perde zaten anında gelir |
| Yazılı bekleme (halka + açıklama) | `ai_sheet.dart`, `ai_text_result.dart`, `listen_screen.dart`, `text_recognize_screen.dart`, `transcript_screen.dart`, `voice_capture_sheet.dart` | AI işi her zaman > 300 ms; yazı ile halka birlikte durur |
| Editör kökü | `editor/note_editor_screen.dart` (2 halka) | Ek D: editör yapısı P20/P36'da; P39 girmez |

## Görseller (F78.3c)

- Kart (`note_card_media.dart`) ve görüntüleyici (`image_viewer.dart`): yerel görsel
  `frameBuilder: fadeInFrame` ile 150 ms solarak gelir; bellek önbelleğinden eşzamanlı
  gelen solmaz (geri kaydırmada yanıp sönme yok). Ağ görseli zaten `fadeInDuration` 150 ms.
- Kart kapağının boyu görselden değil ekin `width/height` bilgisinden
  (`CardMediaPlan.heroHeight`) — görsel gelince kart zıplamaz. Test:
  `test/loading_states_test.dart`.
