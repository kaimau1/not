# Koyu tema dökümü (DENEYIM F80.1, D24 — 2026-11-12)

Kaynak: `TOUR_DARK=1 TOUR_SIZES=telefon,matepad-yatay,masaustu` turu (önce:
`build/tour-once-koyu/`, sonra: `build/tour-koyu/`, dosya adı `<boyut>-<sahne>-koyu.png`).
Tur Adaçayı ailesiyle çizer; aileler arası fark yalnız palet ölçümüyle (madde 5) sınandı.

## Plandaki beş madde

| # | Bulgu (plan) | Durum | Kanıt / iş |
|---|---|---|---|
| 1 | İki parlak yüzey (ev + "+") | **Çözülmüş (F74.1)** — doğrulandı | `telefon-ana-koyu.png`: ev 40 dp `primaryContainer` (koyu yeşil), tek parlak yüzey "+" |
| 2 | Koyu renkli kart koyu zeminde kayboluyor | **Zaten var** — doğrulandı | `note_card.dart` kenar çizgisi renkli kartta `accent` %16 (F31.1); `telefon-ana-koyu.png` sol üst mor kartın çerçevesi seçiliyor. Kod değişmedi |
| 3 | PDF önizlemesi koyu ekranda bembeyaz | **Düzeltildi** | `documentPreviewScrim` (`note_card_media.dart`): koyuda kapak ve belge karosunun üstüne %8 siyah perde; açık belge ve görsel kartları aynı. Bekçi `test/dark_theme_polish_test.dart` |
| 4 | "Sil" dolu koyu kırmızı blok | **`DestructiveRow` çözmemişti → düzeltildi** | `errorContainer` %50 koyuda #5A1418 gibi dolu blok (`telefon-n4-menu-koyu.png`); koyuda %24 (yazı/simge `error` aynı). Bekçi aynı test |
| 5 | Kart–zemin ayrımı | **Ölçüldü, 4 aile düzeltildi** | aşağıdaki tablo; bekçi `theme_contrast_test` "koyu temada kart zeminden en az 0,04 L açık" |

## Madde 5 — kart ile zemin arasındaki OKLab L farkı (koyu)

Ölçü: OKLab L (algısal açıklık, 0–1), `AppTokens.card` − `ColorScheme.surface`. Eşik 0,04.
Düzeltme: kart tonunun her kanalı +1 (ton ve doygunluk aynı, yalnız açıklık).

| Aile | Zemin | Kart (önce) | ΔL önce | Kart (sonra) | ΔL sonra |
|---|---|---|---|---|---|
| Adaçayı (sage) | 131916 | 1C221E | **0,038** | 1D231F | 0,043 |
| Lavanta | 16151B | 1F1D26 | **0,037** | 201E27 | 0,042 |
| Krem | 1B1914 | 25221C | **0,039** | 26231D | 0,043 |
| Saman | 1A1711 | 24201A | **0,0399** | 25211B | 0,044 |
| Porselen | 14171C | 1D2126 | 0,042 | — | — |
| Kil | 1B1614 | 261F1C | 0,041 | — | — |
| Zeytin | 161813 | 1F221B | 0,041 | — | — |
| Beyaz + 5 sade klasik (ortak koyu) | 121314 | 1C1D1F | 0,044 | — | — |
| Şeftali | 1C1715 | 27201D | 0,041 | — | — |
| Nane | 111A18 | 1A2421 | 0,041 | — | — |
| Okyanus | 0D151E | 161F2A | 0,044 | — | — |
| Gül | 1E0D15 | 2A161F | 0,044 | — | — |
| Mandalina | 1E130D | 2A1D16 | 0,045 | — | — |
| Zümrüt | 0D1E17 | 162A22 | 0,048 | — | — |
| Ametist | 160D1E | 21162A | 0,044 | — | — |

Açık temada bütün aileler ≥ 0,039 (beyaz 0,033 — bembeyaz kâğıt kullanıcı isteği 2026-11-06,
değişmedi); açık temanın kuralı "kart zeminden açık" testinde ayrı.

## Turda görülen, BAŞKA paketin işi (burada yapılmadı)

- **Not alt çubuğunda "+" renkli notta kahverengi** (`matepad-yatay-n1-koyu.png`, mor not):
  kapsüllerin notun tonunu alması K-D6 / F75 — **P36**.
- Klasör şeridi çipleri ve arama hapı koyuda dengeli; değişiklik yok.
- `e-pdf-balonlu` sahnesi pdfium yokluğundan hata kutusu (tabanda da var, bilinen).

## Sonra turu

`TOUR_COMPARE=build/tour-once-koyu` farkları ve elle bakılan görüntüler
`docs/deneyim/once-sonra.md` "Koyu" bölümünde.
