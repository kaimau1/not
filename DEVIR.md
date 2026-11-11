# DEVIR — P13 Mürekkep deposu v2 (yazma bayrağı KAPALI)

Dal `oto/P13-murekkep-v2` (origin/main 1f6e6fb1'den).

## Yapılanlar
- F61.0(a) + F61.1: `lib/features/notes/domain/ink_pack.dart` (encode/decodeInkPack, Ek B), `test/ink_pack_test.dart`.
- F61.3: `lib/features/notes/domain/ink_plan.dart` (InkOrder, planInkDocs, mergeInkDocs), `test/ink_plan_test.dart`.
- F61.4 (kısmen): `ink` silme listelerine (notes_repository `_deleteCloudCopy`, account_service); KURAL YOK (yalnız sıkılaştırma sınırı).
- F61.2: `simplifyStroke` (ink_pack.dart) + `InkController.pointerUp` (ink_layer.dart) — `test/ink_simplify_pointer_test.dart`.

## Şu an
- F61.5 okuma tarafı (`_hydratedDoc`, `hydrate`) sırada; sonra F61.6.

## Kararlar / notlar
- F61.0 (b)(c) cihazda ölçülmedi → K-O2 "En güvenli": okuma tarafı yazılır, yazma bayrağı kapalı.
- Öneri (şekil/tik) sadeleşmiş çizgiden tanınıyor (kimlik tutarlılığı için).

## Açık ölçüm
- Kalem çizim yoluna dokunuldu (pointerUp): `python tool/perf/ab_kalem.py` A/B gerekir.
