# DEVIR — K34 parmağa ayrı araç (tahmin kullanıcı kararıyla çıkarıldı, 2026-11-14)

- Yapılan: B0+B4 model + testler (`test/ink_finger_tool_test.dart`, 12 test).
  `InkToolMemory.fingerErases` (pref `ink_finger_eraser`), `FingerTool` türetilmiş;
  `InkController.setFingerTool`, parmak `_tempEraser` (pointerDown, kement/tutamak sonrası),
  ikinci parmak/`beginNav` geri alma (`_undoFingerErase`), `touchRadius` > 22 dp avuç süzgeci.
- Şu an: B5 arayüz (InkSettingsSheet + settings_writing üçlü seçim, tepsi/çizim/hap metni).
- Atlanan: B1–B3 (tahmin) ve S28 — kullanıcı kararı.
- Test: `flutter test test/ink_finger_tool_test.dart test/ink_stylus_tools_test.dart --reporter failures-only`
