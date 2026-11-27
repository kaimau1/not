# STORE_LISTING — Google Play mağaza metni (Faz 6 güncel)

Paket: `dev.kaimau.notlar`. Genel (kişisel köprüsüz) AAB: Actions → Derleme →
Run workflow → **play** işaretli, çıktı `notlar-play-aab` artifact'ı.

Sınırlar: ad ≤ 30, kısa açıklama ≤ 80, uzun açıklama ≤ 4000 karakter.

## Türkçe (tr-TR)

**Ad:** Notlar — Akıllı Defter & Liste

**Kısa açıklama:** Reklamsız, aboneliksiz akıllı defter, market listesi ve PDF kalemi.

**Uzun açıklama:**

Reklamsız, aboneliksiz akıllı defter ve market listesi — Türkçe sesle ekle, reyon ve bütçeni yönet, PDF üstüne kalemle yaz. Telefon, tablet ve web arasında hızla eşitlenir; çevrimdışıyken de kesintisiz çalışır.

NOTLAR VE DEFTER
• Metin, kontrol listesi, sıralı liste, tablo ve çok sayfalı defter
• Fotoğraf, PDF, ses kaydı ve el çizimi ekle; PDF ve görsel üstüne kalemle doğrudan not al
• Türkçe ek çözücülü çevrimdışı yazım denetimi v3 ve öğrenen kişisel sözlük
• Klasörler, etiketler, takvim/hatırlatıcılar, arşiv ve 30 gün geri alınabilir çöp kutusu
• `[[` ile notları birbirine bağla; geri bağlantılar ve "İlgili notlar"

GERÇEKTEN AKILLI ALIŞVERİŞ LİSTESİ
• Tek elle Mağaza Kipi: renkli/simgeli 13 reyon, hızlı atlama çipleri, ekranı açık tut
• Çoklu market profili (BİM, Migros, Pazar vb.), özel reyon sırası, canlı sepet ve bütçe çubuğu
• Barkod okuma, fiş OCR ile fiyat güncelleme, "Bitmek Üzere" önerileri ve 18 hazır Türk mutfağı tarifi
• Aile/arkadaşlarla ortak alışveriş listesi ve tek dokunuş "Marketteyim" bildirimi

LİTE (ÜCRETSİZ) VE TEK SEFERLİK TAM SÜRÜM (50 TL)
• Reklam YOK, abonelik tuzağı YOK.
• Ücretsiz Lite: sınırsız not/klasör/cihaz, tüm cihaz içi akıllı araçlar (yazım v3, dikte, OCR, barkod, Mağaza Kipi), aralıklı bulut metin senkronu, kendi Google Drive'ında ek saklama.
• Tek Seferlik Tam Sürüm (50 TL — ömür boyu): anında bulut senkronu, 750 Akıllı Karar hakkı (bilinmeyen ürün reyonu, hızlı ekle hedefi, sessiz düzen), ileri alışveriş bütçe/fiyat hafızası, tüm temalar/zeminler/yazı tipleri, uçtan uca şifreli (AES-256) kilitli notlar ve parolalı tam yedek.
• İsteğe bağlı: akıllı karar hakkı bitince +1.000 Akıllı Karar paketi (30 TL, tek seferlik tüketilebilir) veya kendi Gemini anahtarınla sınırsız kullanım.

GİZLİLİK VE GÜVENLİK
• Uçtan uca AES-256-GCM şifreli kilitli notlar ve uygulama kilidi (parmak izi, şifre ya da desen)
• Parolalı `.notyedek` ve Markdown `.zip` dışa aktarma; Google Keep, Markdown ve Evernote içe aktarma
• Reklam yok; notların reklam için kullanılmaz

GEREKSİNİM
Yalnız 64 bit (arm64) Android cihazlar desteklenir. Google ile giriş önerilir; misafir hesap yalnız o cihaza bağlıdır.

## English (en-US)

**Title:** Notes — Smart Notebook & List

**Short description:** Ad-free, no-subscription notebook, smart grocery list and PDF pen.

**Full description:**

Ad-free, subscription-free smart notebook and grocery list — add items by voice, manage store aisles and budgets, and write directly over PDFs with your pen. Syncs smoothly across phone, tablet and web, and works offline anytime.

NOTES & NOTEBOOK
• Text, checklists, ordered lists, tables and multi-page notebooks
• Attach photos, PDFs, voice memos and drawings; annotate PDFs and images with a stylus
• Offline spell-check with personal typo learning
• Folders, tags, calendar/reminders, archive and a 30-day recoverable trash
• Link notes with `[[`; backlinks and related notes

TRULY SMART SHOPPING LIST
• One-hand Store Mode: color-coded aisles, quick-jump chips, keep-screen-on
• Multi-store profiles, custom aisle order, live cart total and budget bar
• Barcode scanning, receipt OCR price updates, running-low reminders and recipe packs
• Shared family shopping lists with one-tap "At the store" notification

LITE (FREE) & ONE-TIME FULL VERSION
• Zero ads, zero subscriptions.
• Free Lite: unlimited notes/folders/devices, all on-device smart tools (spell check, dictation, OCR, barcode, Store Mode), periodic cloud text sync, personal Google Drive attachments.
• One-Time Full Version (lifetime): instant cloud sync, 750 Smart Decisions credits, price memory & store comparison, all themes/wallpapers/fonts, end-to-end AES-256 encrypted locked notes and password-protected backups.
• Optional consumable +1,000 Smart Decisions top-up pack (or bring your own Gemini key).

PRIVACY AND SECURITY
• Client-side AES-256-GCM encrypted locked notes and app lock (biometric, password or pattern)
• Full backup/restore and Markdown export; import from Google Keep, Markdown and Evernote
• No ads; your notes are never used for advertising

REQUIREMENTS
64-bit (arm64) Android devices only. Signing in with Google is recommended; guest accounts remain on that device.

## Veri güvenliği formu (taslak — `PRIVACY_POLICY.md` ile tutarlı)

Form cevapları Play Console'da kullanıcı tarafından doğrulanmalıdır.

| Soru | Cevap |
|---|---|
| Veri toplanıyor mu / paylaşılıyor mu | Toplanıyor; üçüncü taraflarla **satılmıyor**, reklam için paylaşılmıyor. Hizmet sağlayıcılar (Google Firebase Auth/Firestore/Storage/Functions/App Check/FCM, Google Drive, Google Gemini Decisions API, Google Play Billing, Open Food Facts API ve etkinse Cloudflare Workers/D1/R2) işleyici sayılır. |
| Aktarımda şifreleme | Evet (HTTPS / TLS) + kilitli notlarda istemci tarafı AES-256-GCM E2EE |
| Silme isteği | Evet — Ayarlar → "Hesabımı ve verilerimi sil" ve web `hesap-silme.html` (hesap ve tüm veriler silinir) |
| Kişisel bilgi: ad, e-posta | Toplanır (Google girişi; kimlik doğrulama + arkadaş dizini). İsteğe bağlı değil (misafir hariç) |
| Kullanıcı kimliği | Toplanır (Firebase UID) |
| **Finansal bilgi: Satın alma geçmişi** | **Toplanır (Google Play satın alma belirteci özeti — ömür boyu hak ve ek karar paketi doğrulaması için; kart bilgisi toplanmaz).** |
| Fotoğraf/video, ses, dosyalar | Kullanıcı eklediği ekler; işlevsellik için; kullanıcının kendi Google Drive'ı ile Storage / Cloudflare R2 (ortak notlar) |
| Uygulama içeriği (notlar) | Toplanır; işlevsellik; reklam yok |
| Konum | Play derlemesinde toplanmaz |
| Çökme günlükleri / tanılama | Toplanır (Crashlytics); uygulama işlevi/analiz (isteğe bağlı kapatılabilir) |
| Cihaz kimlikleri | Bildirim jetonu (FCM); işlevsellik |
| Çocuklar | Gizlilik politikası: 13 yaş altına yönelik değil — Console'da "çocuklara yönelik değil" seçilir |

## Görseller

- Simge: `assets/icon/play_store_512.png` (512×512, hazır).
- Öne çıkan görsel 1024×500 ve ekran görüntüleri (telefon ≥ 2, en çok 8; 16:9–9:16)
  gerçek cihaz turunda (Faz 5) alınır: ana ekran zemini · takvim zemini ·
  Mağaza Kipi v2 · metin/liste + yazım menüsü · PDF kalem · tablet bölünmüş düzen.
