// P63 iskelet — docs/plan_tasarim_B.md §6.2
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/rich_text.dart';
import '../domain/note_type.dart';

/// Minyatür sayfanın bir satırının türü.
enum TemplateLineKind { heading, check, number, bullet, text, gap }

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

/// **ŞABLON KARTI = KÜÇÜK KÂĞIT**: üstte şablonun içeriğinden çizilen
/// minyatür sayfa (tek `CustomPaint`, metin dizimi yok), altta simge + ad.
///
/// Favori yıldızı kartın sağ üst köşesinde (bugünkü yer): 104 dp'lik telefon
/// kartında alt banda simge + ad + yıldız + 40 dp menü sığmıyor
/// (docs/plan_tasarim_B.md §7.11, sabah bakılacak).
class TemplatePreviewCard extends StatelessWidget {
  const TemplatePreviewCard({
    super.key,
    required this.lines,
    required this.accent,
    required this.icon,
    required this.name,
    required this.onTap,
    this.favorite = false,
    this.onFavorite,
    this.favoriteKey,
    this.onMenu,
    this.onLongPress,
  });

  /// [templatePreviewLines] sonucu (çağıran şablon başına bir kez hesaplar).
  final List<TemplateLineKind> lines;
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
    final menu = onMenu;
    final fav = onFavorite;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(
          color: favorite
              ? accent.withValues(alpha: _favoriteEdgeAlpha)
              : scheme.outlineVariant.withValues(alpha: AppAlpha.muted),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress ?? menu ?? fav,
        hoverColor: scheme.primary.withValues(alpha: AppAlpha.hairline),
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
                        accent: accent,
                        ink: scheme.onSurface,
                        paper: tokens.card,
                        edge: tokens.hairline,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: AppSpace.s),
                    Icon(icon, size: AppIconSize.xs, color: accent),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpace.s,
                        ),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: AppWeight.strong,
                          ),
                        ),
                      ),
                    ),
                    if (menu == null)
                      const SizedBox(width: AppSpace.s)
                    else
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

/// Minyatür sayfa: kâğıt zemin + satır iskeleti (başlık çubuğu vurguda,
/// gövde mürekkep × `AppAlpha.soft`).
class _MiniPagePainter extends CustomPainter {
  _MiniPagePainter({
    required this.lines,
    required this.accent,
    required this.ink,
    required this.paper,
    required this.edge,
  });

  final List<TemplateLineKind> lines;
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
      page.deflate(0.5),
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke,
    );
    final body = Paint()..color = ink.withValues(alpha: AppAlpha.soft);
    final head = Paint()..color = accent.withValues(alpha: AppAlpha.strong);
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

  @override
  bool shouldRepaint(_MiniPagePainter old) =>
      !listEquals(old.lines, lines) ||
      old.accent != accent ||
      old.ink != ink ||
      old.paper != paper ||
      old.edge != edge;
}
