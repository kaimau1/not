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
| Sabit/gömülü PDF belgesi açılırken (rota geçişi BİTTİKTEN sonra) | `editor/media_loading_cover.dart` (`MediaLoadingCover`: küçük resim + %24 perde + gecikmeli halka; `pdf_page_box.dart` `_document(null)`) |

## Olduğu gibi kalanlar

| Tür | Yer | Neden |
|---|---|---|
| Düğme içi (14–28 dp) | AI, Gmail, giriş, takvim, tarama, ses, ayarlar düğmeleri; `split_shell`, `app_update`, `speak_button`, `audio_card_box`, video ▶ kurulumu | dokunuşun anında karşılığı |
| İlerleme değerli | `attachment_strip.dart` ve `note_media_box.dart` (indirme yüzdesi), `dashboard_widgets.dart` (basılı tutma halkası), `ai_hub_screen.dart` (kota) | değer gösterir, bekleme halkası değil |
| İşlem perdesi | `qr_scan_screen.dart`, `viewers/area_select.dart`, `viewers/area_actions.dart` | kullanıcının başlattığı işlem; perde zaten anında gelir |
| Yazılı bekleme (halka + açıklama) | `ai_sheet.dart`, `ai_text_result.dart`, `listen_screen.dart`, `text_recognize_screen.dart`, `transcript_screen.dart`, `voice_capture_sheet.dart` | AI işi her zaman > 300 ms; yazı ile halka birlikte durur |
| Editör kökü | `editor/note_editor_screen.dart` (2 halka) | Ek D: editör yapısı P20/P36'da; P39 girmez |

## Görseller (F78.3c)

- Görüntüleyicide ağ görseli: `fadeInDuration` 500 → 150 ms (350 ms erken tam görünür).
- Kart kapağının boyu görselden değil ekin `width/height` bilgisinden
  (`CardMediaPlan.heroHeight`) — görsel gelince kart zıplamaz; kartta ağ görseli zaten
  150 ms soluyor. Test: `test/loading_states_test.dart`.

## Yapılmadı — iyileşme kanıtlanamadı (2026-11-12 kuralı: kötüleşme kabul edilmez)

- **Yerel görsele solma** (kart + görüntüleyici): bugün ilk karede TAM görünür; solma tam
  görünürlüğü 150 ms geciktirir ve listede kaydırırken kart başına saydamlık katmanı ekler.
- **Rota geçişi sırasında küçük resim** (sabit bölmenin `AfterRouteTransition` yer tutucusu):
  yer tutucu bilerek tek `ColoredBox` (2026-10-20 "notu açarken ufak donma" kök nedeni);
  küçük resim geçiş karelerine görsel çözme + 8 widget ekler. Sabit videoda da aynı.
