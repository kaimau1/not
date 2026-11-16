# DEVIR — oto/odak-sablon (yeni nota odak: şablon/hızlı liste)
- Hata (v1.2.84): şablondan hızlı liste → "Bitti" → ana ekranda kart odaklanmıyor.
- Kök neden: vurgu yalnız editör kapanışında (note_editor_screen dispose); `createFromTemplate`
  (quick_add_actions.dart) open:false dalında not editörsüz doğuyor → tetik yok.
- Düzeltme: `FocusedNoteNotifier.focusCreated(id)` (notes_providers.dart) — lastCreatedId'yi
  tüketir + AppMotion.long sonra focusBrief; editör dispose ve hızlı liste dalı bunu çağırır
  (tek tetik: ikinci çağrı false).
- Rota tabanlı (didPopNext) yol seçilmedi: hızlı listede not POP'tan SONRA doğuyor, didPopNext
  anında lastCreatedId henüz yok; ayrıca RouteObserver altyapısı yok.
- Test: flutter test test/new_note_focus_test.dart (5 yeşil; tearDown DashboardScrollMemory.clear).
- Sıradaki: CI yeşil → yürütücü birleştirir (main'e işçi birleştirmez).
