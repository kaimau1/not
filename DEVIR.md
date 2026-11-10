# DEVIR — P09 Yazım düzeltici v2 (Faz 70)

- F70.0 — `test/spell_engine_test.dart` "F70.0 ısrar" iki test KIRMIZI (v1 kodu).
  Geri getiren yol: `SpellMemory.suggest` → bulanık `nearest` ("kalen" → "kalem").
  Öğrenme yalnız SON biten kelimeyi ve yalnız silmeyle izliyordu (`auto_spell.dart`
  `_trackEdit`/`_learnFromEdit`): bir kelime sonra yapılan değişiklik ya da tek adımda
  (klavye önerisi) değiştirme `reject` çağırmıyordu; `replacedWord` de bilinen "kalem"de null.
- Sıradaki: F70.1 sözleşme testleri → F70.2 `lib/core/utils/spell_engine.dart` → F70.3 bağlama.
- Test: `C:/src/flutter/bin/flutter.bat test test/spell_engine_test.dart --reporter failures-only`
