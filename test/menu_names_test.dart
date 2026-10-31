import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// F10.3: not ekranının ⋮ düğmesi başlıktaki "+" ile aynı adı taşıyordu
/// ("Etiket · Başlık · Alarm") — ekran okuyucu ikisini aynı okuyordu. Seçim
/// çubuklarının ⋮'i de aynı yanlış adı kullanıyordu.
void main() {
  for (final code in ['tr', 'en']) {
    test('$code: ⋮ adları "+" menüsünden ayrı', () {
      final l10n = lookupAppLocalizations(Locale(code));
      final names = {l10n.noteMetaMenu, l10n.noteMenu, l10n.moreActions};
      expect(names, hasLength(3));
    });
  }
}
