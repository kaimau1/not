// F73.4 (K-D9): tema seçici üç grupta; hiçbir seçenek silinmez/çiftlenmez.
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/presentation/theme_picker.dart';
import 'package:notlar/features/settings/settings_providers.dart';

void main() {
  test('üç grup, her tema seçeneği tam bir kez', () {
    expect(themeChoiceGroupOrder, hasLength(3));
    final flat = [for (final g in themeChoiceGroupOrder) ...g];
    expect(flat.toSet(), AppThemeChoice.values.toSet());
    expect(flat, hasLength(AppThemeChoice.values.length));
    expect(themeChoiceGroupOrder.first.first, AppThemeChoice.system);
  });
}
