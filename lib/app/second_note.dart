import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/settings_providers.dart';

/// **İKİ NOT YAN YANA** (K32, kullanıcı kararı K-O12 2026-11-12: "tablet
/// yatayda iki not yan yana OLSUN"). İkinci not URL'de DEĞİL: [SplitShell]'in
/// üçüncü sütunu. Derin bağlantı, geri ve web geçmişi yolu değişmez
/// (go_router'da ikinci kabuk sayfası siyah ekran kök nedeniydi).

/// Bir not bölmesinin en dar hâli (bölünmüş düzendeki notla aynı).
const double kSecondNoteMinWidth = 380;

/// İki not arasındaki ayracın genişliği (liste ayracıyla aynı).
const double kSecondNoteDivider = 24;

/// Yandaki not. Kalıcı DEĞİL: uygulama yeniden açılınca yok (en güvenli;
/// sabah bakılacak).
@immutable
class SecondNote {
  const SecondNote(this.id, {this.ownerId, this.readOnly = false});

  final String id;

  /// Paylaşılan klasördeki notun sahibi (bkz. `NoteEditorScreen.ownerId`).
  final String? ownerId;
  final bool readOnly;
}

final secondNoteProvider = NotifierProvider<SecondNoteNotifier, SecondNote?>(
  SecondNoteNotifier.new,
);

class SecondNoteNotifier extends Notifier<SecondNote?> {
  @override
  SecondNote? build() => null;

  void open(SecondNote note) => state = note;

  void close() {
    if (state != null) state = null;
  }
}

enum TwoNoteLayout {
  /// Yandaki not çizilmez (kapalı ya da sığmıyor).
  off,

  /// Yalnız iki not; liste kendiliğinden çekilir (☰ ile göz atılır).
  twoOnly,

  /// Liste + iki not (geniş pencere).
  listAndTwo,
}

/// İki not bu içerik genişliğine sığar mı (yalnız YATAY pencere; dikey
/// tablette yok — sabah bakılacak).
bool twoNotesFit({required double content, required bool landscape}) =>
    landscape && content >= 2 * kSecondNoteMinWidth + kSecondNoteDivider;

/// [content] kabuğun genişliği (ray düşülmüş), [list] liste bölmesinin dar
/// hâlinin genişliği.
TwoNoteLayout twoNoteLayoutFor({
  required double content,
  required double list,
  required bool landscape,
  required bool secondOpen,
}) {
  if (!secondOpen || !twoNotesFit(content: content, landscape: landscape)) {
    return TwoNoteLayout.off;
  }
  final all =
      list + kSecondNoteDivider + 2 * kSecondNoteMinWidth + kSecondNoteDivider;
  return content >= all ? TwoNoteLayout.listAndTwo : TwoNoteLayout.twoOnly;
}

/// Not alanında yandaki notun payı (0.3–0.7; ayraç çift tık = 0.5).
final secondNoteFractionProvider =
    NotifierProvider<SecondNoteFractionNotifier, double>(
      SecondNoteFractionNotifier.new,
    );

class SecondNoteFractionNotifier extends Notifier<double> {
  static const _key = 'second_note_fraction';

  static double _clamp(double v) => v.clamp(0.3, 0.7);

  @override
  double build() =>
      _clamp(ref.watch(sharedPreferencesProvider).getDouble(_key) ?? 0.5);

  void set(double value) {
    state = _clamp(value);
    ref.read(sharedPreferencesProvider).setDouble(_key, state);
  }
}

/// Editöre "yandaki bölmedesin" der: kendini kapatma yolu rotayı değil
/// [close]'u çağırır (`context.pop()` BİRİNCİL notu kapatırdı).
class SecondNotePane extends InheritedWidget {
  const SecondNotePane({super.key, required this.close, required super.child});

  final VoidCallback close;

  /// Bağımlılık KURMAZ (initState'te de okunur; değer bölme ömrünce sabit).
  static SecondNotePane? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SecondNotePane>();

  @override
  bool updateShouldNotify(SecondNotePane oldWidget) => false;
}
