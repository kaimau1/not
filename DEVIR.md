# DEVIR — K34 parmağa ayrı araç (tahmin kullanıcı kararıyla çıkarıldı, 2026-11-14)

- Yapılan: B0+B4 model + testler (`test/ink_finger_tool_test.dart`, 12 test).
  `InkToolMemory.fingerErases` (pref `ink_finger_eraser`), `FingerTool` türetilmiş;
  `InkController.setFingerTool`, parmak `_tempEraser` (pointerDown, kement/tutamak sonrası),
  ikinci parmak/`beginNav` geri alma (`_undoFingerErase`), `touchRadius` > 22 dp avuç süzgeci.
- B5 arayüz: `InkFingerToolPicker` (ink_layer; InkSettingsSheet + Ayarlar → Kalem), tepsi/çizim menüsü/hap "Parmak siliyor" metni, ARB 6 anahtar. Kasma 8 madde: uymayan yok (yerel State, sarmalayıcı yok), perf_budget yeşil.
- B6 kapanış yazıldı: Kuyruk K34 satırı, PLAN.md (C), plan §K34 işaretleri, KONTROL_LISTEM 34 + 41 (Tablette bak), docs/hafiza/kalem.md, regresyon F63.6, sürüm notu 14 Kasım TR+EN.
- Sıradaki: CI yeşil → yürütücü telefon A/B (ab_kalem + ab_hepsi --altin), DEVIR silinir.
- Atlanan: B1–B3 (tahmin) ve S28 — kullanıcı kararı.
- Test: `flutter test test/ink_finger_tool_test.dart test/ink_stylus_tools_test.dart --reporter failures-only`
