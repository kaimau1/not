import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n_ext.dart';
import '../../settings/settings_providers.dart';

/// Ana ekranın zemin görseli: seç / görünürlük / kaldır.
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _DashboardBackgroundSheet(),
    );

class _DashboardBackgroundSheet extends ConsumerWidget {
  const _DashboardBackgroundSheet();

  Future<void> _pick(WidgetRef ref) async {
    final Uint8List bytes;
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      const group = XTypeGroup(
        label: 'Görseller',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      final file = await openFile(acceptedTypeGroups: const [group]);
      if (file == null) return;
      bytes = await file.readAsBytes();
    } else {
      // Zemin ekran boyutunda gösterilir; tam çözünürlüklü fotoğraf okumak
      // boşuna bellek (bkz. editördeki aynı tavan).
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (file == null) return;
      bytes = await file.readAsBytes();
    }
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
            const SizedBox(height: 12),
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
                  ),
                ),
              ),
            if (hasImage) const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _pick(ref),
              icon: const Icon(Icons.wallpaper),
              label: Text(
                hasImage
                    ? l10n.dashboardBackgroundChange
                    : l10n.dashboardBackgroundPick,
              ),
            ),
            if (hasImage) ...[
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
              TextButton.icon(
                onPressed: () {
                  ref.read(dashboardBackgroundProvider.notifier).setPath(null);
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.hide_image_outlined),
                label: Text(l10n.removeBackgroundImage),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
