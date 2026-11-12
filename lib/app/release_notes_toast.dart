import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/l10n_ext.dart';
import '../core/widgets/undo_snackbar.dart'
    show rootScaffoldMessengerKey, timedSnackBar;
import '../features/settings/presentation/guide_screen.dart'
    show loadGuideSource;
import '../features/settings/settings_providers.dart'
    show sharedPreferencesProvider;
import 'router.dart' show routerProvider;
import '../app/theme/app_tokens.dart';

/// **GÜNCELLEMEDEN SONRA "YENİLİKLER" TOSTU** (2026-11-10, kullanıcı: *"sürüm
/// notları sürüm bazlı, son kullanıcının anlayacağı şekilde ana ekranda tost
/// mesaj olarak gösterilsin"*).
///
/// Sürüm notları güne göre bölümlü (`## 10 Kasım 2026 {#2026-11-10}`) ve
/// aynı gün birden çok sürüm çıkıyor; bu yüzden "hangi sürüm" yerine "kullanıcı
/// hangi maddeleri görmedi" tutulur: en yeni bölümün kimliği ve o bölümde
/// gösterilmiş maddeler. Kurulu sürüm değişince yalnız GÖRÜLMEMİŞ maddeler
/// gösterilir (en çok 3, kısaltılmış); "Tümünü gör" sürüm notlarını açar.
class ReleaseNotesToast extends ConsumerStatefulWidget {
  const ReleaseNotesToast({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ReleaseNotesToast> createState() => _ReleaseNotesToastState();
}

class _ReleaseNotesToastState extends ConsumerState<ReleaseNotesToast> {
  static const _prefVersion = 'release_notes_seen_version';
  static const _prefTop = 'release_notes_seen_top';
  static const _prefBullets = 'release_notes_seen_bullets';

  @override
  void initState() {
    super.initState();
    // Açılışın ilk karelerini yormasın; güncelleme denetiminden (4 sn) önce.
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) unawaited(_run().catchError((Object _) {}));
    });
  }

  Future<void> _run() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final version = (await PackageInfo.fromPlatform()).version;
    if (!mounted || prefs.getString(_prefVersion) == version) return;
    final lang = Localizations.localeOf(context).languageCode;
    final source = await loadGuideSource(lang, base: 'release_notes');
    final result = unseenReleaseNotes(
      source,
      seenTop: prefs.getString(_prefTop),
      seenBullets: prefs.getStringList(_prefBullets) ?? const [],
    );
    await prefs.setString(_prefVersion, version);
    if (result.top != null) {
      await prefs.setString(_prefTop, result.top!);
      await prefs.setStringList(_prefBullets, result.topBullets);
    }
    if (result.unseen.isEmpty || !mounted) return;
    _show(version, result.unseen);
  }

  void _show(String version, List<String> unseen) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final l10n = context.l10n;
    final shown = unseen.take(3).map(shortReleaseNote).toList();
    final more = unseen.length - shown.length;
    messenger.showSnackBar(
      timedSnackBar(
        duration: const Duration(seconds: 12),
        content: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final color = theme.colorScheme.onInverseSurface;
            return Column(
              key: const ValueKey('release-notes-toast'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.releaseNotesToastTitle(version),
                  style: TextStyle(fontWeight: AppWeight.strong, color: color),
                ),
                const SizedBox(height: 4),
                for (final line in shown)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('• $line', style: TextStyle(color: color)),
                  ),
                if (more > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n.releaseNotesToastMore(more),
                      style: TextStyle(color: color.withValues(alpha: 0.75)),
                    ),
                  ),
              ],
            );
          },
        ),
        action: SnackBarAction(
          label: l10n.releaseNotesToastAll,
          onPressed: () => ref.read(routerProvider).push('/guide?doc=notes'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Sürüm notlarından kullanıcının henüz görmediği maddeler (yeniden eskiye).
///
/// [seenTop] null ise (ilk kez) yalnız en yeni bölüm sayılır — kullanıcıya
/// bütün geçmiş dökülmesin. `top`/`topBullets` bir sonraki sefere saklanır.
({List<String> unseen, String? top, List<String> topBullets})
unseenReleaseNotes(
  String markdown, {
  String? seenTop,
  List<String> seenBullets = const [],
}) {
  final sections = <({String id, List<String> bullets})>[];
  final head = RegExp(r'^##\s.*\{#([^}]+)\}\s*$');
  for (final raw in markdown.split('\n')) {
    final line = raw.trimRight();
    final m = head.firstMatch(line);
    if (m != null) {
      sections.add((id: m.group(1)!, bullets: <String>[]));
    } else if (sections.isNotEmpty && line.startsWith('- ')) {
      sections.last.bullets.add(line.substring(2).trim());
    }
  }
  if (sections.isEmpty) {
    return (unseen: const [], top: null, topBullets: const []);
  }
  final unseen = <String>[];
  final seen = seenBullets.toSet();
  for (final s in sections) {
    if (seenTop == null) {
      unseen.addAll(s.bullets);
      break;
    }
    // Kimlikler ISO tarih: dize karşılaştırması sıra verir.
    final cmp = s.id.compareTo(seenTop);
    if (cmp < 0) break;
    unseen.addAll(
      cmp == 0 ? s.bullets.where((b) => !seen.contains(b)) : s.bullets,
    );
  }
  return (
    unseen: unseen,
    top: sections.first.id,
    topBullets: sections.first.bullets,
  );
}

/// Tost için tek satırlık özet: kalın başlık varsa o ("**Sesle yazma:** …" →
/// "Sesle yazma"), yoksa ilk cümle; en çok ~90 karakter.
String shortReleaseNote(String bullet) {
  final bold = RegExp(r'^\*\*(.+?)\*\*').firstMatch(bullet);
  var text = bold != null
      ? bold.group(1)!.replaceAll(RegExp(r'[:：]\s*$'), '')
      : bullet.replaceAll('**', '');
  if (bold == null) {
    final dot = text.indexOf(RegExp(r'[.;:](\s|$)'));
    if (dot > 0) text = text.substring(0, dot);
  }
  text = text.trim();
  if (text.length > 90) text = '${text.substring(0, 87).trimRight()}…';
  return text;
}
