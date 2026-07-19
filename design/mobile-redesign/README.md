# Not — Mobil Yeniden Tasarım (Figma)

Uygulamanın ana ekranlarının Figma'da yeniden tasarlanmış mobil (390×844) sürümleri.
Mevcut tasarım dili korunarak modernleştirildi: indigo tohum renk (`#4A5CCC`),
Inter tipografi, gölgesiz/ince kenarlıklı premium yüzeyler, 12–18px yuvarlatmalar.

> Figma dosyası (taslak): https://www.figma.com/design/u8gIfBt8HSNSCVZpzwIZ25

## Ekranlar

| # | Ekran | Kaynak | Görsel |
|---|-------|--------|--------|
| 1 | Giriş | `login_screen.dart` | `01-login.png` |
| 2 | Ana ekran (notlar) | `dashboard_screen.dart` | `02-dashboard.png` |
| 3 | Not editörü | `note_editor_screen.dart` | `03-note-editor.png` |
| 4 | Yapay zekâ asistanı | `chat_screen.dart` | `04-ai-chat.png` |
| 5 | Canlı çeviri | `translator_screen.dart` | `05-translator.png` |
| 6 | Ayarlar | `settings_screen.dart` | `06-settings.png` |

## Tasarım kararları

- **Renk & tema:** Kaynak koddaki `AppTheme.seed = #4A5CCC` ve `NoteColors`
  paleti (kırmızı/kehribar/yeşil/mavi/mor pastel not renkleri) birebir kullanıldı.
- **Ana ekran:** Arama çubuğu + semantik arama kıvılcımı, tek satır filtre çipleri,
  iki sütunlu masonry not ızgarası (sabitlenenler/diğerleri), sağ alt mikrofon + "+"
  FAB sütunu — koddaki yapıya sadık.
- **Not editörü:** Başlık + meta, gövde, madde listesi, görsel eki ve alt ekleme
  araç çubuğu; sağda "Yapay zekâ" vurgu düğmesi.
- **Asistan:** Sol (asistan) / sağ (kullanıcı) baloncuklar, araç çağrısı sonucunu
  gösteren hatırlatıcı onay çipi, mikrofon + gönder giriş çubuğu.
- **Çeviri:** Dil seçici + takas, kaynak/çeviri panelleri, canlı dinleme mikrofonu.
- **Ayarlar:** Profil/senkron kartı, tema seçici (Sistem/Açık/Koyu/Kağıt),
  gruplu satırlar ve anahtarlar.

## Revizyon (geri bildirim sonrası)

- **Logo düzeltildi:** Giriş ekranındaki yanlış "N" harfi yerine uygulamanın gerçek
  kimliğine uygun **yapışkan not** logosu (indigo squircle + beyaz not).
- **Klasik simgeler:** Emoji/yapmacık simgeler kaldırıldı; tümü uygulamanın mevcut
  Material "outlined" diline sadık **tek renk vektör** simgelerle değiştirildi
  (bkz. `00-icon-set.png`).
- **Renkler sadeleştirildi:** İndigo dolgu ağırlığı azaltıldı; beyaz/nötr yüzeyler
  öne alındı, indigo yalnızca vurgu (buton, FAB, seçili çip, küçük simge) olarak.
- **Ayarlar:** Yeni gruplu düzen ve tema seçici korundu.

## Kaynak

- `mockups.html` — 6 ekranın tamamı (tek dosya, `#login` … `#settings` hash'leriyle).
- `icons.html` — klasik simge seti.
- Render: headless Chromium ile 390×844 @2x PNG.

## Notlar

- Tipografi: Uygulama **Inter Tight** kullanıyor; mockup'lar sistem sans-serif ile
  render edildi (görsel olarak çok yakın).
- Bu klasör tasarım referansıdır; Flutter koduna henüz uygulanmadı. Figma dosyasının
  (v1) simge/logo güncellemesi, Figma Starter kotası açılınca senkronlanacak.
