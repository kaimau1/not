import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sağdan sola diller (Arapça, Farsça, İbranice, Urduca) eklendiğinde
/// yerleşimin aynalanması gerekiyor. Flutter yönü yerel ayardan çıkarıyor
/// ama bunu YALNIZCA yönlü tiplerde uyguluyor: `EdgeInsets.only(left:)`
/// RTL'de de soldadır.
///
/// Bu test, yönlü olması gereken dosyalara fiziksel bir yerleşim geri
/// sızmasın diye var. RTL'de bozulan bir yerleşim ancak o dile geçilip
/// ekrana bakılınca fark edilir — kod incelemesinde kolayca kaçar.
void main() {
  /// Yerleşimi kullanıcıya görünen ve AYNALANMASI gereken dosyalar.
  /// Buradaki liste bilerek dar: tuval geometrisi (note_images, slide_canvas,
  /// image_crop, items_editor'ün sarma dolgusu) FİZİKSEL kalmalı — ölçülen
  /// x koordinatlarından hesaplanıyor, yönlüye çevrilirse metin görselin
  /// bulunmadığı tarafa kaçar.
  const mirrored = [
    'lib/features/notes/presentation/note_card.dart',
    'lib/features/notes/presentation/dashboard_chips.dart',
    'lib/features/ai/presentation/chat_screen.dart',
    'lib/features/ai/presentation/doc_chat_screen.dart',
    'lib/core/widgets/undo_snackbar.dart',
  ];

  /// Yalnız `EdgeInsets.only(left:/right:)` yakalanır.
  ///
  /// `fromLTRB` BİLEREK dışarıda: bu kod tabanındaki kullanımların hemen
  /// hepsi simetrik (`fromLTRB(20, 0, 20, 8)`) ve simetrik yatay dolgunun
  /// yönü yoktur — hepsini `fromSTEB`e çevirmek anlamsız gürültü olurdu.
  /// ASİMETRİK bir `fromLTRB` (ör. sağda ⋮ düğmesine yer bırakan) yönlü
  /// olmalı; onlar elle çevrildi ve bu testin kapsamı dışında kalıyor.
  final physicalPadding = RegExp(
    r'EdgeInsets\.only\([^)]*\b(left|right)\s*:',
  );
  final physicalAlignment = RegExp(
    r'\bAlignment\.(center|top|bottom)(Left|Right)\b',
  );
  final physicalPositioned = RegExp(r'Positioned\(\s*(//[^\n]*\n\s*)*'
      r'(top|bottom)?\s*:?[^)]*\b(left|right)\s*:');

  for (final path in mirrored) {
    test('$path yönlü yerleşim kullanıyor', () {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path bulunamadı');
      final source = file.readAsStringSync();

      expect(
        physicalPadding.hasMatch(source),
        isFalse,
        reason:
            '$path içinde fiziksel yatay dolgu var. '
            'EdgeInsetsDirectional.only(start:/end:) kullan.',
      );
      expect(
        physicalAlignment.hasMatch(source),
        isFalse,
        reason:
            '$path içinde fiziksel hizalama var. '
            'AlignmentDirectional.centerStart/centerEnd kullan.',
      );
      expect(
        physicalPositioned.hasMatch(source),
        isFalse,
        reason:
            '$path içinde fiziksel Positioned var. '
            'PositionedDirectional(start:/end:) kullan.',
      );
    });
  }
}
