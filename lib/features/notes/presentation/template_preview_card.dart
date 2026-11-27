// P63 iskelet — docs/plan_tasarim_B.md §6.2 + v2 özgün kart önizlemeleri.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/rich_text.dart';
import '../domain/note_type.dart';

/// Minyatür sayfanın bir satırının türü.
enum TemplateLineKind { heading, check, number, bullet, text, gap }

/// v2 minyatür önizleme biçimi: her liste türü kendi görsel yapısını çizer.
enum TemplatePreviewStyle {
  lines,
  shopping,
  habits,
  moving,
  packing,
  workout,
  cleaning,
  gifts,
  watchlist,
  expense,
}

/// Minyatür satır kalınlığı, satır adımı ve sayfa yüksekliği:
/// üst/alt `AppSpace.m` + 5 satır (4 aralık × 9 + 4) = 64.
const double _lineThick = 4;
const double _lineStep = 9;
const int _maxLines = 5;
const double _pageHeight =
    2 * AppSpace.m + (_maxLines - 1) * _lineStep + _lineThick;

/// Satır başı işaretinin (kutucuk, numara, nokta) kapladığı yer.
const double _markWidth = 6;

/// Favori kartın çizgisi: vurgu × bu saydamlık (bugünkü `_TemplateCard`).
const double _favoriteEdgeAlpha = 0.7;

/// Kendi şablonumda menü hedefi: alt bandın sağ 40 dp'si.
const double _menuTarget = 40;

/// Gövde satırlarının (başlık hariç) göreli uzunlukları — sayfa "yazılmış"
/// görünsün diye satır sırasıyla döner.
const List<double> _textWidths = [0.92, 0.7, 0.82, 0.6, 0.76];

final RegExp _hashHeading = RegExp(r'^#{1,6} ');
final RegExp _numbered = RegExp(r'^\d+[.)] ');

/// Şablon içeriğinden minyatürün satır türleri (en çok [max]).
///
/// Liste notunda her madde `check`/`number`; yazı notunda satır başına göre.
/// Gerçek şablon başlıkları `# ` önekiyle değil zengin işaretle yazılır
/// (`buildTemplateText` → `setLineHeading`) — ikisi de başlık sayılır.
List<TemplateLineKind> templatePreviewLines({
  required NoteType type,
  required String body,
  required List<String> items,
  int max = _maxLines,
}) {
  if (type == NoteType.checklist || type == NoteType.ordered) {
    final kind = type == NoteType.ordered
        ? TemplateLineKind.number
        : TemplateLineKind.check;
    return List.filled(items.length < max ? items.length : max, kind);
  }
  final out = <TemplateLineKind>[];
  for (final line in body.split('\n')) {
    if (out.length == max) break;
    out.add(_kindOf(line));
  }
  while (out.isNotEmpty && out.last == TemplateLineKind.gap) {
    out.removeLast();
  }
  return out;
}

TemplateLineKind _kindOf(String line) {
  if (line.trim().isEmpty) return TemplateLineKind.gap;
  if (lineHeadingAt(line, 0) != RichHeading.normal) {
    return TemplateLineKind.heading;
  }
  final plain = stripRichMarkers(line).trimLeft();
  if (plain.isEmpty) return TemplateLineKind.gap;
  if (_hashHeading.hasMatch(plain)) return TemplateLineKind.heading;
  if (plain.startsWith('☐') || plain.startsWith('☑') || plain.startsWith('☒')) {
    return TemplateLineKind.check;
  }
  if (plain.startsWith('•') ||
      plain.startsWith('- ') ||
      plain.startsWith('* ')) {
    return TemplateLineKind.bullet;
  }
  if (_numbered.hasMatch(plain)) return TemplateLineKind.number;
  return TemplateLineKind.text;
}

/// **ŞABLON KARTI = ÖZGÜN MİNYATÜR**: üstte şablonun gerçek arayüzünden esinlenen
/// minyatür çizim (`CustomPaint`, 64 dp), altta renkli simge kutusu + ad +
/// (varsa) özellik etiketi.
class TemplatePreviewCard extends StatelessWidget {
  const TemplatePreviewCard({
    super.key,
    required this.lines,
    required this.accent,
    required this.icon,
    required this.name,
    required this.onTap,
    this.previewStyle = TemplatePreviewStyle.lines,
    this.badge,
    this.favorite = false,
    this.onFavorite,
    this.favoriteKey,
    this.onMenu,
    this.onLongPress,
  });

  /// [templatePreviewLines] sonucu (çağıran şablon başına bir kez hesaplar).
  final List<TemplateLineKind> lines;
  final TemplatePreviewStyle previewStyle;
  final String? badge;
  final Color accent;
  final IconData icon;
  final String name;
  final VoidCallback onTap;

  /// Favori mi (yıldız dolu, çizgi vurgu renginde).
  final bool favorite;

  /// null = yıldız çizilmez.
  final VoidCallback? onFavorite;
  final Key? favoriteKey;

  /// Kendi şablonumda menü: alt bandın sağındaki `more_horiz` hedefi.
  final VoidCallback? onMenu;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final menu = onMenu;
    final fav = onFavorite;
    final subtitle = badge?.trim();
    final hasBadge = subtitle != null && subtitle.isNotEmpty;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
        side: BorderSide(
          color: favorite
              ? accent.withValues(alpha: _favoriteEdgeAlpha)
              : scheme.outlineVariant.withValues(alpha: AppAlpha.muted),
          width: favorite ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress ?? menu ?? fav,
        hoverColor: accent.withValues(alpha: AppAlpha.hairline),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s,
                    AppSpace.s,
                    AppSpace.s,
                    0,
                  ),
                  child: SizedBox(
                    key: const ValueKey('tpl-mini-page'),
                    height: _pageHeight,
                    child: CustomPaint(
                      painter: _MiniPagePainter(
                        lines: lines,
                        previewStyle: previewStyle,
                        accent: accent,
                        ink: scheme.onSurface,
                        paper: tokens.card,
                        edge: tokens.hairline,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.s,
                    AppSpace.s,
                    menu == null ? AppSpace.s : 0,
                    AppSpace.s,
                  ),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: AppAlpha.pressed),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.xs),
                          child: Icon(
                            icon,
                            size: AppIconSize.xs,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: AppWeight.strong,
                              ),
                            ),
                            if (hasBadge) ...[
                              const SizedBox(height: AppSpace.xxs),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.meta.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (menu != null)
                        InkWell(
                          onTap: menu,
                          child: const SizedBox(
                            width: _menuTarget,
                            height: _menuTarget,
                            child: Icon(Icons.more_horiz, size: AppIconSize.xs),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (fav != null)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: IconButton(
                  key: favoriteKey,
                  visualDensity: VisualDensity.compact,
                  iconSize: AppIconSize.s,
                  tooltip: favorite
                      ? context.l10n.templateUnfavorite
                      : context.l10n.templateFavorite,
                  color: favorite ? accent : scheme.outline,
                  icon: Icon(favorite ? Icons.star : Icons.star_outline),
                  onPressed: fav,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Minyatür sayfa: kâğıt zemin + türüne özel görsel şablon çizimi.
class _MiniPagePainter extends CustomPainter {
  _MiniPagePainter({
    required this.lines,
    required this.previewStyle,
    required this.accent,
    required this.ink,
    required this.paper,
    required this.edge,
  });

  final List<TemplateLineKind> lines;
  final TemplatePreviewStyle previewStyle;
  final Color accent;
  final Color ink;
  final Color paper;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final page = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.s),
    );
    canvas.drawRRect(page, Paint()..color = paper);
    canvas.drawRRect(
      page,
      Paint()..color = accent.withValues(alpha: AppAlpha.hairline),
    );
    canvas.drawRRect(
      page.deflate(0.5),
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke,
    );

    final body = Paint()..color = ink.withValues(alpha: AppAlpha.soft);
    final softBody = Paint()..color = ink.withValues(alpha: AppAlpha.hairline);
    final head = Paint()..color = accent.withValues(alpha: AppAlpha.strong);
    final tint = Paint()..color = accent.withValues(alpha: AppAlpha.pressed);
    final ringPaint = Paint()
      ..color = accent.withValues(alpha: AppAlpha.strong)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final boxStroke = Paint()
      ..color = body.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    switch (previewStyle) {
      case TemplatePreviewStyle.habits:
        _paintHabits(canvas, size, body, softBody, head, ringPaint);
        return;
      case TemplatePreviewStyle.shopping:
        _paintShopping(canvas, size, body, head, tint, boxStroke);
        return;
      case TemplatePreviewStyle.moving:
        _paintMoving(canvas, size, body, head, tint, softBody);
        return;
      case TemplatePreviewStyle.packing:
        _paintPacking(canvas, size, body, head, tint, boxStroke);
        return;
      case TemplatePreviewStyle.workout:
        _paintWorkout(canvas, size, body, head, tint, ringPaint);
        return;
      case TemplatePreviewStyle.cleaning:
        _paintCleaning(canvas, size, body, head, tint, boxStroke);
        return;
      case TemplatePreviewStyle.gifts:
        _paintGifts(canvas, size, body, head, tint, ringPaint);
        return;
      case TemplatePreviewStyle.watchlist:
        _paintWatchlist(canvas, size, body, head, tint, ringPaint);
        return;
      case TemplatePreviewStyle.expense:
        _paintExpense(canvas, size, body, head, tint, softBody);
        return;
      case TemplatePreviewStyle.lines:
        break;
    }

    final left = AppSpace.s;
    final right = size.width - AppSpace.s;
    final usable = right - left;
    const bar = Radius.circular(_lineThick / 2);
    for (var i = 0; i < lines.length && i < _maxLines; i++) {
      final top = AppSpace.m + i * _lineStep;
      final mid = top + _lineThick / 2;
      void line(double from, double fraction, Paint p) => canvas.drawRRect(
        RRect.fromLTRBR(
          from,
          top,
          left + usable * fraction,
          top + _lineThick,
          bar,
        ),
        p,
      );
      final textStart = left + _markWidth + AppSpace.xs;
      final w = _textWidths[i % _textWidths.length];
      switch (lines[i]) {
        case TemplateLineKind.gap:
          break;
        case TemplateLineKind.heading:
          line(left, 0.55, head);
        case TemplateLineKind.text:
          line(left, w, body);
        case TemplateLineKind.check:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(left + _markWidth / 2, mid),
              width: _markWidth - 1,
              height: _markWidth - 1,
            ),
            Paint()
              ..color = body.color
              ..style = PaintingStyle.stroke,
          );
          line(textStart, w, body);
        case TemplateLineKind.number:
          line(left, _markWidth / usable, body);
          line(textStart, w, body);
        case TemplateLineKind.bullet:
          canvas.drawCircle(
            Offset(left + _markWidth / 2, mid),
            _lineThick / 2,
            body,
          );
          line(textStart, w, body);
      }
    }
  }

  void _pill(Canvas canvas, double l, double t, double w, double h, Paint p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(l, t, w, h),
        Radius.circular(h / 2),
      ),
      p,
    );
  }

  void _paintHabits(
    Canvas canvas,
    Size size,
    Paint body,
    Paint soft,
    Paint head,
    Paint ring,
  ) {
    final l = AppSpace.s;
    final usable = size.width - l * 2;
    _pill(canvas, l, 10, usable * 0.52, 5, head);
    _pill(canvas, size.width - l - usable * 0.22, 10, usable * 0.22, 5, soft);
    // 7 gün halkası
    final r = math.min(5.2, usable / 18);
    final step = usable / 7;
    for (var i = 0; i < 7; i++) {
      final cx = l + step * (i + 0.5);
      const cy = 27.0;
      if (i < 5) {
        canvas.drawCircle(Offset(cx, cy), r, head);
      } else {
        canvas.drawCircle(Offset(cx, cy), r - 0.5, ring);
      }
    }
    // Altta 2 ilerleme satırı
    _pill(canvas, l, 40, usable * 0.78, 4, body);
    _pill(canvas, l, 49, usable * 0.58, 4, soft);
  }

  void _paintShopping(
    Canvas canvas,
    Size size,
    Paint body,
    Paint head,
    Paint tint,
    Paint stroke,
  ) {
    final l = AppSpace.s;
    final usable = size.width - l * 2;
    // Üstte 2 reyon hapı
    _pill(canvas, l, 9, usable * 0.36, 7, head);
    _pill(canvas, l + usable * 0.42, 9, usable * 0.34, 7, tint);
    // 2 sütun checklist
    final mid = size.width / 2 + 2;
    for (var col = 0; col < 2; col++) {
      final x = col == 0 ? l : mid;
      final colW = usable * 0.42;
      for (var row = 0; row < 3; row++) {
        final y = 24.0 + row * 11;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 6, 6),
            const Radius.circular(AppRadius.hair),
          ),
          row == 0 && col == 0 ? head : stroke,
        );
        _pill(canvas, x + 9, y + 1, colW * (row.isEven ? 0.78 : 0.62), 4, body);
      }
    }
  }

  void _paintMoving(
    Canvas canvas,
    Size size,
    Paint body,
    Paint head,
    Paint tint,
    Paint soft,
  ) {
    final l = AppSpace.s;
    final usable = size.width - l * 2;
    // Üstte 3 aşamalı zaman çubuğu
    for (var i = 0; i < 3; i++) {
      final w = (usable - 6) / 3;
      _pill(canvas, l + i * (w + 3), 10, w, 5, i == 0 ? head : tint);
    }
    // Altında oda & koli kartları
    for (var r = 0; r < 2; r++) {
      final y = 22.0 + r * 17;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(l, y, usable, 13),
          const Radius.circular(AppRadius.xs),
        ),
        soft,
      );
      canvas.drawCircle(Offset(l + 7, y + 6.5), 2.8, r == 0 ? head : body);
      _pill(canvas, l + 14, y + 4.5, usable * (r == 0 ? 0.56 : 0.44), 4, body);
      _pill(canvas, size.width - l - 22, y + 4, 18, 5, tint);
    }
  }

  void _paintPacking(
    Canvas canvas,
    Size size,
    Paint body,
    Paint head,
    Paint tint,
    Paint stroke,
  ) {
    final l = AppSpace.s;
    final usable = size.width - l * 2;
    // 3 çanta sekmesi (Kabin · Valiz · Üstümde)
    for (var i = 0; i < 3; i++) {
      final w = (usable - 6) / 3;
      _pill(canvas, l + i * (w + 3), 9, w, 6, i == 0 ? head : tint);
    }
    // İlerleme çubuğu
    _pill(canvas, l, 20, usable, 3.5, tint);
    _pill(canvas, l, 20, usable * 0.62, 3.5, head);
    // 3 kontrol satırı
    for (var r = 0; r < 3; r++) {
      final y = 29.0 + r * 9.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(l, y, 5.5, 5.5),
          const Radius.circular(AppRadius.hair),
        ),
        r == 0 ? head : stroke,
      );
      _pill(canvas, l + 9, y + 1, usable * (r == 1 ? 0.68 : 0.8), 4, body);
    }
  }

  void _paintWorkout(
    Canvas canvas,
    Size size,
    Paint body,
    Paint head,
    Paint tint,
    Paint ring,
  ) {
    final l = AppSpace.s;
    final usable = size.width - l * 2;
    // Üstte sayaç çubuğu
    _pill(canvas, l, 10, usable * 0.44, 6, head);
    _pill(canvas, size.width - l - usable * 0.28, 10, usable * 0.28, 6, tint);
    // Set halkaları (3 dolu, 1 boş)
    const r = 6.0;
    for (var i = 0; i < 4; i++) {
      final cx = l + 8 + i * 17.0;
      const cy = 29.0;
      if (i < 3) {
        canvas.drawCircle(Offset(cx, cy), r, head);
      } else {
        canvas.drawCircle(Offset(cx, cy), r - 0.5, ring);
      }
    }
    _pill(canvas, l, 42, usable * 0.72, 4, body);
    _pill(canvas, l, 50, usable * 0.5, 4, tint);
  }

  void _paintCleaning(
    Canvas canvas,
    Size size,
    Paint body,
    Paint head,
    Paint tint,
    Paint stroke,
  ) {
    final l = AppSpace.s;
    final usable = size.width - l * 2;
    _pill(canvas, l, 9, usable * 0.34, 7, head);
    _pill(canvas, l + usable * 0.38, 9, usable * 0.28, 7, tint);
    for (var r = 0; r < 3; r++) {
      final y = 23.0 + r * 11;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(l, y, 6, 6),
          const Radius.circular(AppRadius.hair),
        ),
        r == 0 ? head : stroke,
      );
      _pill(canvas, l + 10, y + 1, usable * (0.72 - r * 0.1), 4, body);
      _pill(canvas, size.width - l - 16, y + 0.5, 16, 5, tint);
    }
  }

  void _paintGifts(
    Canvas canvas,
    Size size,
    Paint body,
    Paint head,
    Paint tint,
    Paint ring,
  ) {
    final l = AppSpace.s;
    final usable = size.width - l * 2;
    _pill(canvas, l, 10, usable * 0.5, 6, head);
    // 3 aşama noktası: fikir → alındı → paket
    for (var r = 0; r < 3; r++) {
      final y = 23.0 + r * 11;
      _pill(canvas, l, y + 1, usable * (0.58 - r * 0.06), 4.5, body);
      for (var d = 0; d < 3; d++) {
        final cx = size.width - l - (2 - d) * 8.5 - 3;
        final cy = y + 3.2;
        if (d <= 2 - r) {
          canvas.drawCircle(Offset(cx, cy), 3, d == 0 ? head : tint);
        } else {
          canvas.drawCircle(Offset(cx, cy), 2.5, ring);
        }
      }
    }
  }

  void _paintWatchlist(
    Canvas canvas,
    Size size,
    Paint body,
    Paint head,
    Paint tint,
    Paint ring,
  ) {
    final l = AppSpace.s;
    final usable = size.width - l * 2;
    // Tür hapları
    _pill(canvas, l, 9, usable * 0.28, 6, head);
    _pill(canvas, l + usable * 0.32, 9, usable * 0.26, 6, tint);
    // 5 yıldız puanlama + satırlar (artık asla boş beyaz kutu değil!)
    for (var row = 0; row < 2; row++) {
      final y = 23.0 + row * 16;
      _pill(canvas, l, y, usable * (row == 0 ? 0.45 : 0.36), 4.5, body);
      for (var s = 0; s < 5; s++) {
        final cx = l + 4 + s * 10.0;
        final cy = y + 10.5;
        final filled = row == 0 ? s < 4 : s < 5;
        _drawStar(canvas, Offset(cx, cy), 3.8, filled ? head : ring);
      }
      _pill(canvas, size.width - l - 22, y + 2, 22, 6, tint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = (i * math.pi / 5) - math.pi / 2;
      final dist = i.isEven ? r : r * 0.46;
      final pt = Offset(
        center.dx + math.cos(rad) * dist,
        center.dy + math.sin(rad) * dist,
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintExpense(
    Canvas canvas,
    Size size,
    Paint body,
    Paint head,
    Paint tint,
    Paint soft,
  ) {
    final l = AppSpace.s;
    final usable = size.width - l * 2;
    // Toplam özet bandı
    _pill(canvas, l, 10, usable * 0.56, 6, head);
    _pill(canvas, size.width - l - 24, 10, 24, 6, tint);
    // 3 kalem + sağda tutar çubukları
    const heights = [0.76, 0.52, 0.64];
    for (var r = 0; r < 3; r++) {
      final y = 23.0 + r * 11;
      _pill(canvas, l, y + 1, usable * (0.48 - r * 0.05), 4, body);
      final bw = usable * 0.34 * heights[r];
      _pill(canvas, size.width - l - bw, y, bw, 6, r == 0 ? head : soft);
    }
  }

  @override
  bool shouldRepaint(_MiniPagePainter old) =>
      !listEquals(old.lines, lines) ||
      old.previewStyle != previewStyle ||
      old.accent != accent ||
      old.ink != ink ||
      old.paper != paper ||
      old.edge != edge;
}
