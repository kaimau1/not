# PLAN — açık işlerin tek listesi (P22/P53, 2026-11-14)

Bitmiş (`[x]`) maddeler burada YOK; geçmiş eski plan dosyalarında ve git'te. Her satırın sonunda
eski kimlik durur. Kullanıcının kendi listesi: `KONTROL_LISTEM.md`.

> **Geçiş notu (2026-11-14):** P43, P55, P59, P20 hâlâ açık ve eski planlara (OTURTMA/HIZ/DENEYIM)
> adla atıf yapıyor; bu yüzden eski plan dosyaları henüz `docs/arsiv/planlar/`'a TAŞINMADI (P53
> adım 3–6 ertelendi, sabah bakılacak). O paketler bitene dek ayrıntı eski dosyalarda, bu dosya özet.

## (A) Kullanıcının yapacakları → `KONTROL_LISTEM.md`

- Cihaz turu: telefon / tablet / web (KONTROL 1–23) — F69.1, F63.7, F67.8, F19.C1, F19.C2, F19.C4–C6, YORUM F55.5, KALANLAR §2 (C–L, P22, P45)
- Yeni cihaza geçiş + tam yedek geri yükleme (KONTROL 1) — F69.2, F19.A4, YORUM F54.4
- Liste maddesi "Boş madde"ye dönüyor, kanıt bekliyor (KONTROL 2) — KALANLAR veri kaybı 2026-11-01, cihaz turu A4
- Hatırlatıcı güvenilirliği cihazda (KONTROL 4) — F69.3, YORUM F56.2
- Konsol: AI bütçe/kota (24) F19.A1 · sunucu yedeği (25) F19.A5 · Calendar/Tasks API (26) F19.B10 · masaüstü OAuth (27) KALANLAR J0 · Crashlytics (28) F19.B4, YOL_HARITASI · Drive API + Functions (29) F19.B2, F19.B3 · minClient (30) F19.B1, F61.7 · App Check (31) F19.A2, F19.D2
- Test misafir hesabını sil — F19.C7
- PPTX portu için depo izni — F19.B8, F18.20
- Kararlar (KONTROL 32–39) — K-O12/F67.6, K-O3/F61.7, K-O4/F62.6, F63.6, K-O8/F65.3, F69.3 ipucu, F66.5, HIZ F83.3

## (B) Bekletilenler / park

- Mürekkep v2 YAZMA + tembel göç + kurallar — K-O2/K-O3 kapısı (F61.0 (b)(c) cihaz ölçümü yok) — F61.0, F61.4, F61.6, F61.7, F61.8
- Kalem raster karoları + görüntüye fırınlama — F62.0 cihaz ölçümü kapısı — F62.0, F62.3, F62.4
- Kalem gecikmesi ölçümü (240 fps) — cihaz — F62.6 (ölçüm), YORUM F54.1
- Açılış süresi kalanı (motor + Activity) — kod işi yok — F68.5
- Vulkan'lı cihazda ölçüm — cihaz yok — AKICILIK F27.3, F19.F4
- Kart dizini + gövde ayrı belge (senkron yükü) — KARAR B, veri göçü güvenlik şartlı — AKICILIK F22.4, YORUM F54.3
- Play'e çıkış (Billing, OAuth yayına, gizlilik, konum beyanı, mağaza) — karar "çıkmıyoruz" — F18.27, F18.28, F19.D1–D7, YOL_HARITASI F4.10
- Taşınan düğme ipucu, uygulama içi sürüm notu — tek kullanıcı, ertelendi — YORUM F57.1, F57.2
- Önce/sonra görsel karşılaştırma dosyası — DENEYIM F80.5
- Kare ölçümü CI işi (emülatör, sonuçsuz kaldı) — F19.B6, KULLANICI_DENEYIMI F17.1, HIZ F83.3
- Bilinen sınırlar: web geri tuşu tam ekran, debug `RenderFollowerLayer` uyarısı, düz metinde görev çipi yok, madde jest katmanında şekil önerisi yok, görev kişi alanı serbest metin — KALANLAR §3, Yarım kalan

## (C) Açık kod işi

- **İki not yan yana (tablet yatay)** — opus — K-O12 kararı VERİLDİ (2026-11-12) — F67.6
- **Parmağa ayrı araç** — fable (kalem) — karar VERİLDİ (2026-11-12), tablette doğrulanır — F63.6, YORUM F55.1
- **Kalem ucu tahmini** — fable — K-O4 VERİLDİ; 1 karelik doğrusal tahmin, yalnız boyanır — F62.6
- **Dolma kalem uç inceltme tabanı** — fable — YORUM F55.4
- **Büyük PDF (500 MB–1 GB) yerelde açılsın** — opus — F65.9
- **Web'de ek görünmüyor / paylaşılan notta ek** — kullanıcıdan hata metni gerek — F65.6
- **Editör bölge çıkarma + `_mutate` kök setState** — P20 kısmi; sabah bakılacak — F64.3, F64.4
- **Pano gövdesini böl (ölçüm kapılı)** — F68.2
- **Kasma kökten (not aç/kapa, klavye, alt panel)** — P55 sürüyor — HIZ F84.1–F84.3, F60.S2, F60.5, F68.3
- **Kaydırma kabulü** — P43 — F68.4, AKICILIK Faz 21
- **Hız: otomatik karar, altın taban** — P43 — HIZ F81.2, F81.4
- **Takvim haftalık ızgarada sürükle, görev elle sırala** — TAKVIM (ayrı faz)
- **Uçtan uca akış testleri, web ağır işler** — KULLANICI_DENEYIMI F17.2, F17.3
- **PPTX düzenleme portu** — depo izni sonrası — F18.20
- **Kapanış toparlaması (P53 adım 3–6)** — eski planları arşive taşı, OTOMASYON Kuyruk sıkıştır, CLAUDE.md "Yol haritası" tek satır + F58.1 dondurma + F58.4 oturum disiplini, HAFIZA bayat adlar — açık P'ler bitince — F58.1, F58.4, F69.5
