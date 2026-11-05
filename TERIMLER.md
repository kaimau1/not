# TERİMLER — tek ad, tek anlam (F14.1, 2026-10-31)

Arayüz metni yazarken bu tablo geçerli. `test/terminology_test.dart`
`app_tr.arb`'yi yasaklı yazımlara karşı tarar.

| Kavram | Kullan | Kullanma |
|---|---|---|
| AI | **Yapay zekâ** (cümle düzeni, şapkalı); kısa yerde **AI** (≥ 60 karakterlik cümlede AI yok; "AI sesli not" terimin adı) | Yapay Zeka, yapay zeka, Yapay Zekâ |
| Liste satırı | **madde** ("Yeni madde", "+3 madde daha") | öğe |
| Arayüz parçası | **düğme**, **alan** | öğe |
| Hitap | **sen** ("dokun", "seç", "yazabilirsin") | siz, "dokunun", "seçin", "Lütfen" |
| Belge notunun iki görünümü | **Balonlu** (belge notun kendisi olur) · **Klasik** (belge ek olur) | "Belge gibi not al", "Nota ek olarak ekle" |
| Konuşmayı yazıya dök (canlı) | **Dikte** | Sesle yazdır, Sesli yazdır |
| Konuş → AI notu kursun | **AI sesli not** | Sesli not (tek başına) |
| Sesi dosya olarak sakla | **Ses kaydı** | — |
| Notu sesle oku | **Sesli dinle** | Sesli oku |
| Metni panoya al | **Kopyala** | — |
| Aynı notun yeni bir kopyası | **Çoğalt** | Kopyala |
| Arkadaşın gelen kutusuna kopya | **Gönder** / "Arkadaşa gönder" | Kopya gönder |
| Ekleri bir deftere taşı | **Deftere topla** · **defter** | Arşiv defteri, Arşiv defterine kopyala |
| Sıralama | **Son güncellenen** | Son düzenlenen |
| Gelen kopyalar + ortak notlar | **Gelen** (şerit çipi) · ekran: "Gelen ve paylaşılanlar"; liste etiketleri ve ana ekran bölümü **Gelen** / **Paylaşılan** | Benimle paylaşılanlar |
| Paylaş levhası bölümleri | **Dışarı gönder** (her uygulamaya) · **Kişilerle** (Arkadaşa gönder, Birlikte düzenle) | Notlar kullanıcısına |

## Simgeler — tek simge, tek anlam (F16.1, 2026-10-31)

Kaynak: `lib/core/app_icons.dart` (`AppIcons`). Tabloda olan bir iş için
`Icons.*` doğrudan yazılmaz; `test/visual_consistency_test.dart` tarar.

| Anlam | Simge (`AppIcons.`) | Material | Bu simge başka iş için kullanılmaz |
|---|---|---|---|
| Arşiv / arşivle / arşivden çıkar | `archive` · `unarchive` | archive_outlined · unarchive_outlined | Defter, Not paketi, Gelen |
| Gelen ve paylaşılanlar | `inbox` | mail_outline (zarf) | — (eski move_to_inbox arşive benziyordu) |
| Defter (sayfalı görünüm, defter kâğıdı) | `notebook` | menu_book_outlined | Kılavuz |
| Kullanım kılavuzu | `guide` | help_outline | — |
| Not paketi (.notlar) | `notePackage` | folder_zip_outlined | — |
| Kopyala (pano) | `copy` | content_copy_outlined | Çoğalt |
| Çoğalt | `duplicate` | library_add_outlined | Kopyala |
| Görünüm (tema) | `appearance` | palette_outlined | renk seçimi |
| Renk seçimi (zemin, sayfa, özel renk, renge göre) | `color` | format_color_fill | Görünüm |
| Klasöre taşı | `moveToFolder` | drive_file_move_outline | Klasörler bölümü (folder) |
| Ara / Notta ara | `search` | search | — (derin arama manage_search ayrı iş) |
| Tam ekran | `fullscreen` | fullscreen | — |
| Çöpten geri yükle | `restore` | restore_from_trash_outlined | — |
| Dikte (AI'sız; ana ekran mikrofonu rozetsiz) | `dictation` | mic | AI sesli not |
| AI sesli not (✨ mikrofon, `AppIcons.glyph` çizer) | `aiVoiceNote` | mic_none_rounded + auto_awesome | Dikte |
| Ses kaydı, ses eki | `voiceRecord` | graphic_eq | — |
| Sesli dinle | `listen` | headphones_outlined | — |
| Sesli komut (sohbet) | `voiceCommand` | settings_voice_outlined | — |
| Kişiler | `friends` | people_outline | Paylaşılan |
| Ortak not, paylaşılan klasör (kart, editör, şerit, etiket) | `shared` | people_alt_outlined | Kişiler |

Levhalar: başlık solda + ✕ sağda (`SheetHeader`); bölüm başlığı cümle
düzeninde (`SectionLabel`, BÜYÜK HARF yok). Sabit renkler
`lib/app/theme/fixed_colors.dart`.
