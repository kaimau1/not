# DEVIR — P30 / F60.S12 çöp kutusu (oto/P30-cop-kutusu)

## Yapılanlar
- (a) KÖK: `lib/features/notes/presentation/dashboard_widgets.dart` `_ReorderableNoteCell` — önizleme sırası kartı başka satır/sütuna taşıyınca sürüklenen hücre yeniden kurulur; Flutter `Draggable.onDragEnd`'i yalnız `mounted` iken verir (drag_target.dart ~536) → kabul edilen bırakmada (çöp/başka kart) `_dragNoteId` temizlenmiyor, çöp simgesi ekranda kalıyordu. Düzeltme: `onDragCompleted` + `onDraggableCanceled` (mounted'a bakmaz, birbirini dışlar).
- (b) `drag_trash_target.dart`: dolum beklemesi kalktı; bölgeye girip bırakmak yeter (bölge Padding ile geniş). Küresel işaretçi yolu (`pointerRouter.addGlobalRoute`) parmak→hedef vektörünü `DragTrashTarget.pull`'a yazar; hedef yakınlıkla kırmızılaşır, `TrashPullFeedback` sürüklenen kartı küçültür/döndürür/hedefe çeker.
- (c) Bırakınca 350 ms kara delik (CustomPaint'te dönen kâğıt merkeze) + olağan silme yolu + geri al. Hepsi boyamada.
- Metin: "Çöpe atmak için buraya bırak" / "Drop here to delete".

## Test
`flutter test test/drag_trash_target_test.dart --reporter failures-only` → 4/4 (yeni "başka kartın üstünden geçip…" düzeltmeden önce KIRMIZI idi). perf_budget + home_gestures yeşil; `flutter analyze` temiz.

## Sıradaki
Cihazda A/B (ana ekran listesi, sürükleme) yürütücüde; sürüm notu maddeleri raporda.
