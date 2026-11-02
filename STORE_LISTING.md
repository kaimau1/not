# STORE_LISTING — Google Play mağaza metni (F18.30)

Taslak. **Play'e çıkış kararı hâlâ yok** (YOL_HARITASI F4.10); karar gelince
bu metin Play Console'a yapıştırılır. Paket: `dev.kaimau.notlar`. Genel
(kişisel köprüsüz) AAB: Actions → Derleme → Run workflow → **play** işaretli
(F18.29), çıktı `notlar-play-aab` artifact'ı.

Sınırlar: ad ≤ 30, kısa açıklama ≤ 80, uzun açıklama ≤ 4000 karakter.

## Türkçe (tr-TR)

**Ad:** Notlar — Yapay Zekâlı Not Defteri

**Kısa açıklama:** Bulutla eşitlenen, yapay zekâlı not, liste ve hatırlatıcı uygulaması.

**Uzun açıklama:**

Notlar; yazdığın, çizdiğin, kaydettiğin her şeyi tek yerde toplar ve telefon,
tablet ile bilgisayar arasında kendiliğinden eşitler. İnternet yokken de yazarsın;
bağlantı gelince notların her cihazda hazırdır.

NOTLAR
• Metin, kontrol listesi ve sıralı liste notları; sürükle-bırak sıralama
• Fotoğraf, PDF, ses kaydı ve el çizimi ekle; görsel üstüne kalemle yaz
• Etiketler, klasörler, arşiv, 30 gün geri alınabilir çöp kutusu
• `[[` ile notları birbirine bağla; geri bağlantılar ve "İlgili notlar"
• Tekrarlayan hatırlatıcılar: her gün, hafta içi, haftalık, aylık, yıllık

YAPAY ZEKÂ
• Not özeti ve analizi, PDF ile sohbet, "Tüm notlar" sohbeti (kaynak notu gösterir)
• Sesli komutla not ve hatırlatıcı: "her pazartesi 9'da toplantı"
• Canlı konuşma çevirisi, fotoğraftan metin (OCR), anlama göre arama
• Günlük brifing ve haftalık özet
• Nottan soru-cevap kartları ve aralıklı tekrar ("Bugünün kartları")
• Dahili yapay zekâ günlük kotalıdır; istersen kendi anahtarını (Gemini, OpenAI,
  Anthropic, OpenRouter) girersin — anahtar yalnız cihazında kalır

PAYLAŞIM
• Arkadaş ekle, not gönder, ortak not ve paylaşılan klasör aç
• Ekleri istersen kendi Google Drive'ında sakla

GİZLİLİK VE GÜVENLİK
• Uygulama kilidi (cihaz kilidi, şifre ya da desen) ve not kilidi
• Tam yedek ve geri yükleme; Google Keep, Markdown ve Evernote içe aktarma
• Reklam yok; notların reklam için kullanılmaz

GEREKSİNİM
Yalnız 64 bit (arm64) Android cihazlar desteklenir. Google ile giriş önerilir;
misafir hesap yalnız o cihaza bağlıdır.

## English (en-US)

**Title:** Notes — AI Notebook

**Short description:** Cloud-synced notes, lists and reminders with built-in AI help.

**Full description:**

Notes keeps everything you write, draw and record in one place and syncs it across
your phone, tablet and computer on its own. Write offline; your notes are ready on
every device once you reconnect.

NOTES
• Text, checklist and ordered-list notes with drag-and-drop ordering
• Attach photos, PDFs, voice recordings and hand drawings; write on top of images
• Tags, folders, archive and a 30-day recoverable trash
• Link notes with `[[`; backlinks and "Related notes"
• Repeating reminders: daily, weekdays, weekly, monthly, yearly

AI
• Note summaries and analysis, chat with a PDF, chat with all your notes (shows the source note)
• Voice commands for notes and reminders: "team meeting every Monday at 9"
• Live speech translation, text from photos (OCR), search by meaning
• Daily briefing and weekly digest
• Question-and-answer cards from a note with spaced repetition ("Today's cards")
• Built-in AI has a daily quota; or enter your own key (Gemini, OpenAI, Anthropic,
  OpenRouter) — the key stays on your device

SHARING
• Add friends, send notes, create shared notes and shared folders
• Optionally keep attachments in your own Google Drive

PRIVACY AND SECURITY
• App lock (device lock, password or pattern) and per-note lock
• Full backup and restore; import from Google Keep, Markdown and Evernote
• No ads; your notes are never used for advertising

REQUIREMENTS
64-bit (arm64) Android devices only. Signing in with Google is recommended; a
guest account is tied to that one device.

## Veri güvenliği formu (taslak — `PRIVACY_POLICY.md` ile tutarlı)

Form cevapları Play Console'da kullanıcı tarafından doğrulanmalıdır.

| Soru | Cevap |
|---|---|
| Veri toplanıyor mu / paylaşılıyor mu | Toplanıyor; üçüncü taraflarla **satılmıyor**, reklam için paylaşılmıyor. Hizmet sağlayıcılar (Google Firebase / Drive / Gemini) işleyici sayılır. |
| Aktarımda şifreleme | Evet (HTTPS) |
| Silme isteği | Evet — Ayarlar → "Hesabımı ve verilerimi sil" (hesap ve tüm veriler silinir) |
| Kişisel bilgi: ad, e-posta | Toplanır (Google girişi; kimlik doğrulama + arkadaş dizini). İsteğe bağlı değil (misafir hariç) |
| Kullanıcı kimliği | Toplanır (Firebase UID) |
| Fotoğraf/video, ses, dosyalar | Kullanıcı eklediği ekler; işlevsellik için; Firebase Storage ya da kullanıcının Drive'ı |
| Uygulama içeriği (notlar) | Toplanır; işlevsellik; reklam yok |
| Konum | Toplanmaz |
| Finansal bilgi | Toplanmaz |
| Çökme günlükleri / tanılama | Toplanır (Crashlytics); uygulama işlevi/analiz |
| Cihaz kimlikleri | Bildirim jetonu (FCM); işlevsellik |
| Çocuklar | Gizlilik politikası: 13 yaş altına yönelik değil — Console'da "çocuklara yönelik değil" seçilir |

## Görseller

- Simge: `assets/icon/play_store_512.png` (512×512, hazır).
- Öne çıkan görsel 1024×500 ve ekran görüntüleri (telefon ≥ 2, en çok 8; 16:9–9:16)
  **cihazdan alınmalı** — F19.C1 duman testinde alınan ekranlar uygundur:
  ana ekran ızgarası · metin notu + biçim · liste notu · yapay zekâ sohbeti ·
  hatırlatıcılar · tablet yan yana düzen. Bulut ortamında gerçek hesapla ekran
  üretilemediği için bu adım **F19**'dadır (bkz. `KALAN_ISLER_PLANI.md` F19.D).
