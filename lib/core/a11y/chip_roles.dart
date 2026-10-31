import 'package:flutter/material.dart';

/// **ÇİP ROLLERİ** (F15.3, erişilebilirlik). Flutter çiplerin hepsini
/// "seçilebilir düğme" diye bildiriyor; web'de ve TalkBack'te bu onay kutusu
/// gibi okunuyordu ("işaretli değil") — eylem çipinde bile.
///
/// - [radioChip]: TEKLİ seçim grubundaki çip (yazı boyutu, kip, dil…) radyo
///   düğmesi gibi okunur: `inMutuallyExclusiveGroup` + işaretli/değil.
/// - [actionChip]: bir iş yapan çip (#etiket ekle, saat seç…) düz düğme;
///   "seçili değil" durumu okunmaz.
///
/// Çipin kendisi aynen çizilir; yalnız semantik düğüm değişir. Etiket çipin
/// `Text` yazısından alınır; yazı `Text` değilse çip olduğu gibi döner.
Widget radioChip(ChoiceChip chip) {
  final label = _labelOf(chip.label);
  if (label == null) return chip;
  final onSelected = chip.onSelected;
  return Semantics(
    container: true,
    inMutuallyExclusiveGroup: true,
    checked: chip.selected,
    enabled: onSelected != null,
    label: label,
    onTap: onSelected == null ? null : () => onSelected(!chip.selected),
    excludeSemantics: true,
    child: chip,
  );
}

/// Bkz. [radioChip].
Widget actionChip(ActionChip chip) {
  final label = _labelOf(chip.label);
  if (label == null) return chip;
  return Semantics(
    container: true,
    button: true,
    enabled: chip.onPressed != null,
    label: label,
    onTap: chip.onPressed,
    excludeSemantics: true,
    child: chip,
  );
}

String? _labelOf(Widget label) => label is Text ? label.data : null;
