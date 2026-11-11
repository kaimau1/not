# DEVIR — P13 Mürekkep deposu v2 (yazma bayrağı KAPALI)

Dal `oto/P13-murekkep-v2` (origin/main 1f6e6fb1'den). Paket bitti; CI bekleniyor.

## Yapılanlar
- F61.0(a) + F61.1: `lib/features/notes/domain/ink_pack.dart` (encode/decodeInkPack, Ek B), `test/ink_pack_test.dart`.
- F61.2: `simplifyStroke` + `InkController.pointerUp` (ink_layer.dart) — `test/ink_simplify_pointer_test.dart`.
- F61.3: `lib/features/notes/domain/ink_plan.dart` (InkOrder, planInkDocs, mergeInkDocs), `test/ink_plan_test.dart`.
- F61.4 (kısmen): `ink` silme listelerinde (notes_repository `_deleteCloudCopy`, account_service). KURAL YOK (yalnız sıkılaştırma sınırı).
- F61.5: okuma — notes_repository `_hydratedDoc`/`hydrate`/`needsHydrate`, `InkDocCache`/`mergeInkV2`, `InkStroke.parse`; `test/ink_v2_read_test.dart`.
- F61.6: yazılmadı (K-O2 en güvenli); bekçi testi "v2 YAZIMI KAPALI".

## Kararlar / notlar
- F61.0 (b)(c) cihazda ölçülmedi → K-O2 "En güvenli".
- Öneri (şekil/tik) sadeleşmiş çizgiden tanınıyor (kimlik tutarlılığı için) — sabah bakılacak.
- v1 notta `heavyLoaded` anlamı değişmedi (editörün `hydrating` dalı ona bağlı).

## Açık ölçüm
- Kalem kalkış yoluna dokunuldu: `python -u tool/perf/ab_kalem.py <etiket> <kart> <kalem>` A/B gerekir (taban 1f6e6fb1).
