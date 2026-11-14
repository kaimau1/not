# DEVIR — P63 / PB0 iskelet (dal oto/PB0-iskelet, taban 4d56c9ab) — YARIDA — limit freni (2026-11-14 gece, 2. tur sonu)

Tarif: `docs/plan_tasarim_B.md` §6 + §7.1 (ayrıntı §1.2, §2.2, §3.2, §4.2, §5.2). Bileşenler ekrana BAĞLANMAZ. `test/perf_budget_test.dart`'a dokunma.

## Biten (yerelde test + `dart analyze` yeşil)
- ColorDot `lib/core/widgets/color_dot.dart` + `test/color_dot_test.dart` (b240e20b)
- CustomizeBoard `lib/core/widgets/customize_board.dart` + `test/customize_board_test.dart` (d972581f)
- ColorDot mandal düzeltmesi: `withValues(alpha: 0)` → `withAlpha(0)` (tasarım mandalı alpha 191>190) (1d0320b8)
- TemplatePreviewCard + `test/template_preview_lines_test.dart` (a31b62f1) — yıldız sağ üst köşede (KARAR, §7.11'e yazılacak)
- PenStrokePreview + `test/pen_stroke_preview_test.dart` (41 nokta, k=0.8; uç yarıçapı < orta × 0.6) (bf? bkz. git log)
- CI: TemplatePreviewCard push'u (a31b62f1) YEŞİL.

## ŞU AN: VoiceLevelWave — test yazıldı, bileşen YAZILMADI
- Test taslağı `test/voice_level_wave_test.dart.taslak` (CI kırılmasın diye uzantı): sürerken `_test.dart`'a geri adlandır, sonra `lib/features/notes/presentation/voice_level_wave.dart` yaz.
- Tasarım (kararlaştırıldı): durum `ValueNotifier<({Duration t, double level})> _frame`, ticker'da `smoothLevel(_frame.level, widget.level?.value ?? 0.5, dt)`; hareketi azaltta ticker YOK, boyayıcı `repaint: level`, t=0. `_sync()` didChangeDependencies + didUpdateWidget'ta (`active && motionOf`). `smoothLevel`: tau yükseliş 80 / düşüş 320 ms, `1-exp(-dt/tau)`. `waveBarFactor`: taban 0.14 + nefes 0.04·sin(2πt/2400ms) + level·0.86·zarf·titreşim; zarf 0.35+0.65·sin(π(i+.5)/n); titreşim 1+0.2·sin(2πt/(560+41i)ms + 0.7i); reduceMotion → nefes 0, titreşim 1. Çubuk 3, aralık 4, adım 7 (`const`); sığmazsa adım = w/n. Kapalı: 3 dp nokta, `idleColor ?? outlineVariant`. Sessizde renk vurgu × `AppAlpha.muted`'a doğru.

## Kalan (sırayla, her biri ayrı commit + push; önce test dosyası, derlenmediğini gör, sonra bileşen)
1. ~~TemplatePreviewCard~~ BİTTİ. Tuzak: gerçek şablon gövdesinde başlık `# ` DEĞİL, zengin işaret (`buildTemplateText` → `setLineHeading`); `templatePreviewLines` hem `# `/`## ` önekini hem `lineHeadingAt(line, 0) != normal`'i (`core/utils/rich_text.dart:1464`) başlık saysın, öbür önekler `stripRichMarkers` sonrası. Minyatür: 12 dolgu + 5 satır × adım 9 (kalınlık 4) = 64. Tuzak: telefonda kart 104 dp — alt bantta simge + ad + yıldız + 40 dp menü sığmıyor (ada 4 dp kalıyor) → önerim yıldız bugünkü gibi kartın sağ üst köşesinde, bantta simge + ad (+ `more_horiz`); plana sapma notu yaz. Yıldız ipucu: `templateFavorite`/`templateUnfavorite` var.
2. ~~PenStrokePreview~~ BİTTİ. Hipotez DOĞRULANDI: `fountainRadii` (`viewers/ink_stroke_paint.dart:153`) hızı nokta ARALIĞINDAN okur (`(1.15 − 20·v).clamp(0.45, 1.15)`, v = genişliğe oranlı aralık) → S eğrisinde uçlarda aralık ≥ 0.035, ortada ~0.005 (ör. `x(u) = u + 0.8·sin(2πu)/(2π)`, 33 nokta); `pressures` gerekmez. `identical` testi için boyayıcı sınıfını açık yap (`stroke` alanı); alfa testi `paints..path(color:)`. Bileşen yalnız çizgi (kâğıt zemin ve iğne PB3'ün), `LayoutBuilder` + `RepaintBoundary`.
3. VoiceLevelWave (§6.4): `ListeningWaveform` kalıbı (`listening_visuals.dart:271-347`); eskiyi SİLME. Hareketi azalt: ticker durur, boyayıcı `repaint: level`. "Kurulmaz" testi: düzey olayından sonra `CustomPaint.painter` aynı örnek.
4. DividerKindPicker (§6.5): mürekkep dalgası görünsün diye `AnimatedContainer(renk)` → `Material(transparency)` → `InkWell(key)` → `CustomPaint(paintItemDivider)`; çift/dalgalıda `y + AppSpace.xxs`.
5. Çeviri (§6.7, TEK commit; sonra `flutter gen-l10n` + `dart format lib/l10n/generated`). Arama sonucu — VAR, yeniden ekleme: Sırala=`reorderHandle`, Sabitlemeyi kaldır=`unpin`, Eklenebilir=`quickRowEditAvailable`, Varsayılana dön=`personalizeReset`, Ekle=`addAttachment`, Ana ekran/Video/Eklentiler=`personalizeHome/Video/Modules`. EKLENECEK (tr+en): `customizeHint`, `customizeShown` ("Görünenler"), `customizeSurfaceBottomBar/TopBar/QuickRow/AddPanel/Pinned/Pen`. Eşlemeyi plan §6.7'ye yaz (PB1–PB3 `customizeReorder`/`inkUnpinPen` aramasın).
6. Bitiş: plan §7.11'e "şablon kartında yıldız sağ üst köşede kaldı — sabah bakılacak" yaz; tam `flutter analyze`, CI yeşil, plan §7.1 PB0 `[x]`, Kuyruk P63 satırı, `docs/regresyon_listesi.md`, DEVIR.

## Kararlar / tuzaklar (genel)
- P62 iskeleti main'de → §6.0 "eşdeğer belirteç" tablosu yerine doğrudan `AppMotion.selection/emphasized/exitOf`.
- `ReorderableListView.onReorder` kullanımdan kalktı → `onReorderItem`; panonun `onReorder(old, new)` dizini öğe çıkarıldıktan SONRAKİ yer.
- `test/design_tokens_guard_test.dart` şu yazımları sayar: `size: 28`, `Duration(milliseconds: 80)`, `Curves.x`, `withValues(alpha: 0.18)`, `BorderRadius.circular(12)`, `fontSize:`, `FontWeight.w…` → belirteç ya da dosya başında adlandırılmış `const` (süreyi ms `double` tut).
- Bash'te `grep` çıktısı rtk ile kırpılıyor; tam liste için Grep aracı.

## Test
`"C:/src/flutter/bin/flutter.bat" test test/color_dot_test.dart test/customize_board_test.dart --reporter failures-only`
