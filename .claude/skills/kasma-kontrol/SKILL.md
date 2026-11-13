---
name: kasma-kontrol
description: Editöre ya da kart ızgarasına GÖRÜNÜR yeni alan, kip veya sarmalayıcı eklerken push'tan önce uygula ("editör baştan kuruluyor" kasma listesi, 8 madde).
---

# Kasma kontrol listesi — "editör baştan kuruluyor" (kullanıcı isteği 2026-11-09)

CLAUDE.md'den taşındı (2026-11-14), AYNEN. Bekçi testi `test/jank_patterns_guard_test.dart`
bu listeye atıf yapar.

Editöre/kart ızgarasına GÖRÜNÜR yeni alan, kip ya da sarmalayıcı eklerken, push'tan ÖNCE:
1. Yeni madde/not alanı → üç karşılaştırmaya da ekle: `sameItemsVisually` (note_editor_screen), `ItemsEditor._sameItems`, `text_merge._sameItem`. Eksikse Firestore yankısı her kayıtta "değişti" sayılır → editör baştan kurulur.
2. Satır önbelleği (`ItemsEditor._cachedItemRow`): satırı değiştiren alan anahtara girsin; liste düzeyi girdi `_syncRowCache` env'ine. Env'e HER BUILD'DE YENİ nesne (map, liste, kapanış) koyma — önbellek her karede boşalır.
3. Yerel UI durumu (aç/kapa, seçim, hover) için editörün KÖK `setState`'i değil, alt widget'ın kendi durumu ya da `ValueNotifier` + dar `ListenableBuilder`.
4. Sarmalayıcı (Stack, KeyedSubtree, TapRegion) eklediysen ağaç ŞEKLİ koşula göre değişmesin (koşulda `SizedBox.shrink` tut) — şekil değişince alt ağaç ve metin alanları sıfırdan kurulur.
5. Doğrula: `test/items_editor_row_cache_test.dart` kalıbıyla "girdisi değişmeyen satır `identical`" testi yaz; şüphede `tool/perf/` ile cihazda ölç. Ölçmeden "düzeldi" deme.
6. **Editör gövdesiyle aynı Column/Row'daki bir şeyin BOYUNU animasyonla değiştirme** (yükseklik, `heightFactor`, `AnimatedSize`, `AnimatedContainer` boyu): gövde her karede yeniden dizilir. Boy TEK ADIMDA değişsin, hareket yalnız boyamada (`Transform`/`FractionalTranslation`/`Opacity`). Bekçi: `keyboard_jank_guard_test.dart`.
7. Klavyeye bağlı gösterme/gizleme (`KeyboardSwitch`) alt ağacı SÖKMEZ: iki taraf da kurulu, `Offstage` ile değişir. `MediaQuery.of(context)` kök/kabuk bağlamında okunmaz — `viewInsetsOf`/`sizeOf` ya da ayrı küçük öğe.
8. `test/perf_budget_test.dart` kırmızıysa birleştirme yok (bütçeler `test/perf_budget/budgets.json`, mandal: yalnız DÜŞER; senaryolar OTURTMA Ek A).

Gerekçe (kullanıcı 2026-11-10): "son güncellemelerden sonra kasma yeniden başladı… zamanında
kontrol et" — kök neden iki gün önce eklenen, alt çubuğu gizleyen boy animasyonuydu (madde 6);
testler yeşildi, kimse ölçmemişti. Bu yüzden editör/klavye/çubuk/liste/geçiş işi `[apk]`'dan
önce ayrıca `ab-olcum` skill'iyle cihazda ölçülür.
