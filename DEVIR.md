# DEVIR — P09 Yazım düzeltici v2 (Faz 70)

- F70.0 (3d…, ilk commit) — kök neden: v1 `SpellMemory.suggest` → bulanık `nearest`
  ("kalen" → "kalem") her seferinde aynı adayı verir; öğrenme yalnız SON biten kelimeyi
  ve yalnız silmeyle izliyordu (`_trackEdit`/`_learnFromEdit`), tek adımda değiştirme ya da
  bir kelime sonra düzeltme `reject` çağırmıyordu; `replacedWord` bilinen "kalem"de null.
- F70.1–F70.6 (ikinci commit): `lib/core/utils/spell_engine.dart` (saf motor: decide,
  mesafe, güven eşiği `confidenceMargin`), `spell_learn.dart` v2 hafıza (fixes (to,n),
  rejected çiftler `a>b`, keep; v1 göçü `decode`), `auto_spell.dart` yalnız bağlama
  (izlenen kelimeler `_track/_settle`, Backspace geri al `_Undo`, `beginNote`),
  `spell_learned_screen.dart` (aç/kapa, yalnız kurallar, reddedilenler), l10n 3 anahtar.
  Eski `spell_learn_test.dart` silindi; `test/spell_engine_test.dart` 31 test yeşil.
- Kararlar (sabah bakılacak): "öner" (altı noktalı) YOK (en güvenli); otomatik düzeltme
  başka kelimeyle değiştirilince yazılan çift onaylı öğrenilir (öbür notlarda uygulanır);
  motorun "önceki kelime" girdisi kullanılmadı (YAGNI); `.v1` yedeği silen kod yok (bir
  sürüm sonra elle).
- Plan [x], regresyon satırı, docs/hafiza/editor.md yazıldı. Sıradaki: CI yeşil mi (gh run list -b oto/P09-yazim-v2 -L 1).
- Test: `C:/src/flutter/bin/flutter.bat test test/spell_engine_test.dart test/istekler_2026_11_08_test.dart --reporter failures-only`
