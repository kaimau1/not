import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/utils/attachment_tag.dart';
import 'spell_underline.dart';
import 'tag_tap.dart';

/// Bir ek etiketinin editörde nasıl görüneceği: ekin TÜRÜNÜN simgesi ve
/// rengi (PDF, görsel, video, YouTube…).
@immutable
class TagLook {
  const TagLook(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is TagLook && other.icon == icon && other.color == color;

  @override
  int get hashCode => Object.hash(icon, color);
}

/// Metne gömülü ek etiketlerini ("📎 kelime") editörde ÇİP olarak çizer:
/// kelimenin çevresinde türün renginde yuvarlak bir çerçeve, atacın yerinde
/// türün simgesini taşıyan dolu bir rozet.
///
/// KULLANICI İSTEĞİ (2026-10-15): "ek gömmenin tüm akışı ve görüntüsü
/// yenilenmeli". Eski görünümde renkli ataç emojisi kırmızı yazının önünde
/// duruyor, PDF mi video mu gömüldüğü ancak dokununca anlaşılıyordu.
///
/// **NEDEN METNE DOKUNULMADAN üstten çiziliyor:** etiketin metni ("📎 ad")
/// ham metinle birebir aynı kalmalı (bkz. attachment_tag.dart — imleç,
/// seçim, kopyalama, dışa aktarma hep buna dayanıyor). Atacı bir widget'la
/// değiştirmek konumları kaydırır; kalınlık/punto değiştirmek satır
/// genişliğini değiştirip sarma ölçümünü bozar. Bu yüzden metin yalnız
/// RENK alır (ataç saydam, ad türün renginde — bkz. `linkSpans`
/// `tagChipColors`) ve çip ile rozet alanın ÜSTÜNE, `RenderEditable`'ın
/// kendi kutularından (`getBoxesForSelection`) çizilir.
///
/// Dokunuşu YUTMAZ (`foregroundPainter` isabet denetimine katılmaz). Yalnız
/// denetleyici değişince (yazı, seçim) yeniden çizilir; imleç yanıp
/// sönmesi alanın kendi `RepaintBoundary`'si içinde kalır.
///
/// Aynı katmanın ALTINDA (`painter`) yazım v3 Y-4 altı çizili denetimin
/// dalgalı çizgisi ([SpellMarks]): yeni sarmalayıcı yok, ağaç şekli aynı.
class AttachmentTagChips extends StatefulWidget {
  const AttachmentTagChips({
    super.key,
    required this.controller,
    required this.looks,
    required this.child,
  });

  final TextEditingController controller;

  /// Etiket adı → görünüm. Boşsa hiçbir şey çizilmez (ama ağaç AYNI kalır:
  /// ilk gömmede alanın yeniden kurulup klavyenin düşmemesi için).
  final Map<String, TagLook> looks;

  final Widget child;

  @override
  State<AttachmentTagChips> createState() => _AttachmentTagChipsState();
}

class _AttachmentTagChipsState extends State<AttachmentTagChips> {
  EditableTextState? _editable;
  late SpellMarks _spell = SpellMarks.acquire(widget.controller);

  @override
  void didUpdateWidget(AttachmentTagChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.controller, widget.controller)) return;
    _spell.release();
    _spell = SpellMarks.acquire(widget.controller);
  }

  /// Rozet simgeleri (simge × boy × renk başına bir kez dizilir).
  final _icons = <(int, int, int), TextPainter>{};

  EditableTextState? get _field {
    final cached = _editable;
    if (cached != null && cached.mounted) return cached;
    return _editable = editableTextBelow(context);
  }

  TextPainter _icon(IconData icon, double size, Color color) {
    final key = (icon.codePoint, (size * 2).round(), color.toARGB32());
    return _icons[key] ??= (TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          height: 1,
          color: color,
        ),
      ),
    )..layout());
  }

  @override
  void dispose() {
    _spell.release();
    for (final painter in _icons.values) {
      painter.dispose();
    }
    super.dispose();
  }

  // RepaintBoundary: boyayıcı denetleyicinin HER bildiriminde (her tuş,
  // her imleç hareketi) yeniden çiziyor. Sınır olmadan bu, en yakın üst
  // sınıra — sayfanın kaydırma görünümüne — kadar BÜTÜN sayfayı yeniden
  // boyatıyordu. Ağaç şekli hep aynı (bkz. [looks]).
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SpellPainter(
          this,
          widget.controller,
          _spell,
          scheme.error.withValues(alpha: AppAlpha.strong),
          scheme.onSurfaceVariant.withValues(alpha: AppAlpha.muted),
        ),
        foregroundPainter: widget.looks.isEmpty
            ? null
            : _TagChipPainter(this, widget.controller, widget.looks),
        child: widget.child,
      ),
    );
  }
}

/// Altı çizili yazım denetimi (Y-4): yanlış = dalgalı, bağlama bağlı ipucu
/// = soluk noktalı. O an yazılan kelime (IME oluşturma aralığı ya da imleç
/// tam sonunda, son yazım orada) çizilmez.
class _SpellPainter extends CustomPainter {
  _SpellPainter(this.state, this.controller, this.spell, this.color, this.hint)
    : super(repaint: Listenable.merge([controller, spell]));

  final _AttachmentTagChipsState state;
  final TextEditingController controller;
  final SpellMarks spell;
  final Color color;
  final Color hint;

  @override
  void paint(Canvas canvas, Size size) {
    final marks = spell.marks;
    if (marks.isEmpty) return;
    final field = state._field;
    final self = state.context.findRenderObject();
    if (field == null || self is! RenderBox || !self.attached) return;
    // Okuma kipinde çizgi yok (menü de açılmaz).
    if (field.widget.readOnly) return;
    final render = field.renderEditable;
    if (!render.attached || !render.hasSize) return;
    final value = controller.value;
    final sel = value.selection;
    final caret = sel.isValid && sel.isCollapsed ? sel.baseOffset : -2;
    final comp = value.composing;
    final transform = render.getTransformTo(self);
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color;
    final dots = Paint()
      ..strokeWidth = 1.4
      ..color = hint;
    canvas
      ..save()
      ..clipRect(
        MatrixUtils.transformRect(
          transform,
          Offset.zero & render.size,
        ).inflate(3),
      );
    var drawn = 0;
    for (final k in marks) {
      if (k.end > value.text.length) continue;
      if (k.end == caret && k.end == spell.editAt) continue;
      if (comp.isValid &&
          !comp.isCollapsed &&
          comp.start < k.end &&
          k.start < comp.end) {
        continue;
      }
      if (++drawn > SpellMarks.maxPainted) break;
      final boxes = render.getBoxesForSelection(
        TextSelection(baseOffset: k.start, extentOffset: k.end),
      );
      for (final box in boxes) {
        final r = MatrixUtils.transformRect(transform, box.toRect());
        final y = r.bottom - 1.5;
        if (k.hint) {
          for (var x = r.left; x < r.right; x += 3) {
            canvas.drawLine(Offset(x, y), Offset(x + 1.2, y), dots);
          }
          continue;
        }
        final path = Path()..moveTo(r.left, y);
        var up = true;
        for (var x = r.left + 2; x < r.right + 2; x += 2) {
          path.lineTo(math.min(x, r.right), up ? y - 1.2 : y + 0.6);
          up = !up;
        }
        canvas.drawPath(path, wave);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpellPainter old) =>
      !identical(old.spell, spell) ||
      !identical(old.controller, controller) ||
      old.color != color ||
      old.hint != hint;
}

class _TagChipPainter extends CustomPainter {
  _TagChipPainter(this.state, this.controller, this.looks)
    : super(repaint: controller);

  final _AttachmentTagChipsState state;
  final TextEditingController controller;
  final Map<String, TagLook> looks;

  @override
  void paint(Canvas canvas, Size size) {
    final text = controller.text;
    if (!text.contains(kAttachmentTagPrefix)) return;
    final tags = findAttachmentTags(text, looks.keys);
    if (tags.isEmpty) return;
    final field = state._field;
    final self = state.context.findRenderObject();
    if (field == null || self is! RenderBox || !self.attached) return;
    final render = field.renderEditable;
    if (!render.attached || !render.hasSize) return;
    final transform = render.getTransformTo(self);
    Rect toLocal(TextBox box) =>
        MatrixUtils.transformRect(transform, box.toRect());

    canvas
      ..save()
      // Kaydırılan (tek satırlık) alanda görünmeyen etiket dışarı taşmasın.
      ..clipRect(
        MatrixUtils.transformRect(
          transform,
          Offset.zero & render.size,
        ).inflate(3),
      );
    for (final tag in tags) {
      final look = looks[tag.fileName];
      if (look == null) continue;
      final boxes = render.getBoxesForSelection(
        TextSelection(baseOffset: tag.start, extentOffset: tag.end),
      );
      if (boxes.isEmpty) continue;
      // Satır başına TEK çip: bir satırdaki kutular (harf grupları)
      // birleştirilir; satır kırılan etiket iki çip olur.
      final lines = <Rect>[];
      for (final box in boxes) {
        final r = toLocal(box);
        if (lines.isNotEmpty &&
            (lines.last.top - r.top).abs() < 1 &&
            (lines.last.bottom - r.bottom).abs() < 1) {
          lines.last = lines.last.expandToInclude(r);
        } else {
          lines.add(r);
        }
      }
      final fill = Paint()..color = look.color.withValues(alpha: 0.10);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = look.color.withValues(alpha: 0.5);
      for (final r in lines) {
        final chip = Rect.fromLTRB(
          r.left - 2,
          r.top + 1,
          r.right + 3,
          r.bottom - 1,
        );
        final rr = RRect.fromRectAndRadius(
          chip,
          Radius.circular(math.min(chip.height / 2, 9)),
        );
        canvas
          ..drawRRect(rr, fill)
          ..drawRRect(rr, stroke);
      }
      // ROZET atacın yerinde: dolu, türün renginde, içinde beyaz simge.
      // Opak olduğu için ataç (yazı tipi saydamlığı desteklemese bile)
      // altında kalır.
      final clip = render.getBoxesForSelection(
        TextSelection(baseOffset: tag.start, extentOffset: tag.start + 2),
      );
      if (clip.isEmpty) continue;
      final e = toLocal(clip.first);
      final d = (e.height * 0.8).clamp(10.0, 30.0);
      final badge = Rect.fromCenter(
        center: e.center,
        width: math.max(d, e.width - 1),
        height: d,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(badge, Radius.circular(d * 0.32)),
        Paint()..color = look.color,
      );
      final icon = state._icon(look.icon, d * 0.7, Colors.white);
      icon.paint(
        canvas,
        badge.center - Offset(icon.width / 2, icon.height / 2),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TagChipPainter old) =>
      !identical(old.controller, controller) || !mapEquals(old.looks, looks);
}
