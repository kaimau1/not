import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n_ext.dart';
import '../../settings/settings_providers.dart';
import 'dashboard_pattern.dart';
import '../../../core/widgets/app_sheet.dart';

/// Ana ekranın zemini: **renk · desen · görsel** — seç / görünürlük / kaldır.
///
/// **RENK VE DESEN** (kullanıcı isteği: "ana ekran zemini kısmına renk ve
/// model seçenekleri"): levha yalnız galeriden fotoğraf seçtiriyordu. Fotoğraf
/// koymak istemeyen kullanıcının ana ekranı kişiselleştirmek için hiçbir yolu
/// yoktu. Desenler ÇİZİLİYOR (bkz. [DashboardPatternLayer]) — tema renklerini
/// kullandıkları için açık/koyu/kâğıt temada da doğru görünürler ve APK'yı
/// büyütmezler.
///
/// **AYARLARDAN BURAYA TAŞINDI** (kullanıcı isteği 2026-08-16: "ana ekran
/// zemini seçeneğini ayarlardan 3 noktaya taşı"). Gerekçe ayarın kendisinde:
/// zemin yalnız ANA EKRANI ilgilendiriyor ve sonucu ancak ana ekranda
/// görülüyor — Ayarlar → Görünüm'e gidip seçmek, çıkıp bakmak, beğenmeyip
/// geri girmek demekti. Artık zeminin göründüğü ekranın kendi menüsünde ve
/// levha açıkken saydamlık kaydırıcısı zemine CANLI yansıyor.
///
/// Görsel uygulamanın kendi klasörüne KOPYALANIR: galeriden seçilen yol
/// geçici olabiliyor (Android paylaşım önbelleği), kopyalanmazsa zemin bir
/// süre sonra kendiliğinden kayboluyordu.
Future<void> showDashboardBackgroundSheet(BuildContext context) =>
    showAppSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _DashboardBackgroundSheet(),
    );

class _DashboardBackgroundSheet extends ConsumerWidget {
  const _DashboardBackgroundSheet();

  Future<void> _pick(WidgetRef ref, String imagesLabel) async {
    final Uint8List bytes;
    if (kIsWeb) return;
    // Zemin ekran boyutunda gösterilir; tam çözünürlüklü fotoğraf okumak
    // boşuna bellek (bkz. editördeki aynı tavan).
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (file == null) return;
    bytes = await file.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    // Dosya adı her seferinde değişir: aynı yol yeniden yazılsa Flutter'ın
    // görsel önbelleği eski kareyi göstermeye devam ederdi.
    final target = File('${dir.path}/dashboard_bg_${const Uuid().v4()}.img');
    await target.writeAsBytes(bytes);
    final previous = ref.read(dashboardBackgroundProvider).path;
    ref.read(dashboardBackgroundProvider.notifier).setPath(target.path);
    if (previous != null && previous != target.path) {
      unawaited(File(previous).delete().catchError((_) => File(previous)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final background = ref.watch(dashboardBackgroundProvider);
    final hasImage =
        background.path != null && File(background.path!).existsSync();
    return SafeArea(
      // Kardeş levhalarla aynı kural: içerik ekranı aşarsa kaydırılabilsin,
      // son seçenek sistem gezinme çubuğunun altında kalmasın.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dashboardBackground, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.dashboardBackgroundInfo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // ZEMİN RENGİ. İlk daire "renk yok" (temanın kendi yüzeyi).
            Text(
              l10n.dashboardBackgroundColor,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ColorDot(
                  color: null,
                  selected: background.color == null,
                  onTap: () => ref
                      .read(dashboardBackgroundProvider.notifier)
                      .setColor(null),
                ),
                for (final argb in _kBackgroundColors)
                  _ColorDot(
                    color: Color(argb),
                    selected: background.color == argb,
                    onTap: () => ref
                        .read(dashboardBackgroundProvider.notifier)
                        .setColor(argb),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // DESEN. Her çip kendi desenini küçük bir kutuda ÇİZER: adından
            // ne olduğunu tahmin etmek yerine görülerek seçilir.
            Text(
              l10n.dashboardBackgroundPattern,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final pattern in DashboardPattern.values)
                  _PatternChip(
                    pattern: pattern,
                    label: _patternLabel(context, pattern),
                    selected: background.pattern == pattern,
                    onTap: () => ref
                        .read(dashboardBackgroundProvider.notifier)
                        .setPattern(pattern),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dashboardBackgroundImageSection,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            // Seçili zeminin küçük bir önizlemesi: levha açıkken hangi
            // görselin kullanıldığı görünsün.
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Opacity(
                  opacity: background.opacity.clamp(0.05, 1),
                  child: Image.file(
                    File(background.path!),
                    key: ValueKey(background.path),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Önizleme 120 px yüksekliğinde: tam boy çözmeye gerek yok.
                    cacheWidth: 900,
                  ),
                ),
              ),
            if (hasImage) const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _pick(ref, context.l10n.exportImages),
              icon: const Icon(Icons.wallpaper),
              label: Text(
                hasImage
                    ? l10n.dashboardBackgroundChange
                    : l10n.dashboardBackgroundPick,
              ),
            ),
            // Görünürlük kaydırıcısı DESEN için de geçerli: desen varken
            // görsel olmasa da ayarlanabilmeli.
            if (hasImage || background.pattern != DashboardPattern.none) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.opacity, size: 18),
                  Expanded(
                    child: Slider(
                      value: background.opacity.clamp(0.05, 1),
                      min: 0.05,
                      max: 1,
                      onChanged: (value) => ref
                          .read(dashboardBackgroundProvider.notifier)
                          .setOpacity(value),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '%${(background.opacity * 100).round()}',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ],
            if (hasImage)
              TextButton.icon(
                onPressed: () {
                  ref.read(dashboardBackgroundProvider.notifier).setPath(null);
                },
                icon: const Icon(Icons.hide_image_outlined),
                label: Text(l10n.removeBackgroundImage),
              ),
            // Üç ayarı birden varsayılana döndürür: tek tek geri almak
            // (renk yok + desen düz + görseli kaldır) üç ayrı adımdı.
            if (hasImage ||
                background.color != null ||
                background.pattern != DashboardPattern.none)
              TextButton.icon(
                onPressed: () =>
                    ref.read(dashboardBackgroundProvider.notifier).reset(),
                icon: const Icon(Icons.restart_alt),
                label: Text(l10n.dashboardBackgroundReset),
              ),
          ],
        ),
      ),
    );
  }
}

/// Zemin rengi seçenekleri. Nötr ve düşük doygunlukta tonlar: kart ızgarası
/// ve metin her tema ile okunur kalmalı (parlak renkler kartların kendi
/// renkleriyle çarpışıyordu).
const _kBackgroundColors = <int>[
  0xFFF5F1E8, // kâğıt
  0xFFEAF1F8, // buz mavisi
  0xFFEDF5EC, // adaçayı
  0xFFF7EEF3, // gül
  0xFFF6F1E1, // kum
  0xFFECECEF, // gri
  0xFF2A2E35, // gece
  0xFF1F2A2E, // koyu deniz
  0xFF2E2632, // koyu erik
  0xFF14171A, // is
];

String _patternLabel(BuildContext context, DashboardPattern pattern) {
  final l10n = context.l10n;
  return switch (pattern) {
    DashboardPattern.none => l10n.patternNone,
    DashboardPattern.dots => l10n.patternDots,
    DashboardPattern.grid => l10n.patternGrid,
    DashboardPattern.lines => l10n.patternLines,
    DashboardPattern.diagonal => l10n.patternDiagonal,
    DashboardPattern.graph => l10n.patternGraph,
  };
}

/// Tek bir renk dairesi. [color] null ise "renk yok" (temanın yüzeyi).
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color ?? scheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: color == null
            ? Icon(Icons.format_color_reset, size: 16, color: scheme.outline)
            : null,
      ),
    );
  }
}

/// Deseni küçük bir kutuda ÇİZEN seçim çipi.
class _PatternChip extends StatelessWidget {
  const _PatternChip({
    required this.pattern,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final DashboardPattern pattern;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 44,
                width: double.infinity,
                child: ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  // Önizlemede desen tam görünürlükte ve küçük aralıkla:
                  // 44 dp'lik kutuda 28 dp'lik aralık tek çizgi gösterirdi.
                  child: DashboardPatternLayer(
                    pattern: pattern,
                    opacity: 1,
                    cell: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
