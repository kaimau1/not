import '../../../app/app_frame.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/delayed_spinner.dart';

/// Gizlilik metninin bir bloğu: başlık (`level` 1/2), madde (`level` = girinti
/// kademesi, `bullet` = `-` maddesi) ya da paragraf (`level` 0).
typedef PrivacyBlock = ({String kind, int level, String text});

final _privacyItemRe = RegExp(r'^(\s*)(-|\d+\.)\s+');
final _privacyHeadingRe = RegExp(r'^(#{1,2})\s+(.*)$');

/// `PRIVACY_POLICY.md`'yi okunur bloklara böler (KW-7): sert satır sonları
/// birleşir (dar ekranda yarım satır kalmaz), `#`/`##` başlık, `1.` ve `-`
/// maddeler ayrı blok. Yalnız bu dosyanın kullandığı Markdown — web sayfaları
/// aynı kaynaktan `tool/gizlilik_sayfalari.dart` ile üretilir.
List<PrivacyBlock> privacyBlocks(String md) {
  final blocks = <PrivacyBlock>[];
  String? kind;
  var level = 0;
  final buf = <String>[];
  void flush() {
    if (kind != null && buf.isNotEmpty) {
      blocks.add((kind: kind!, level: level, text: buf.join(' ')));
    }
    kind = null;
    buf.clear();
  }

  for (final raw in md.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) {
      flush();
      continue;
    }
    final h = _privacyHeadingRe.firstMatch(line);
    if (h != null) {
      flush();
      blocks.add((kind: 'heading', level: h[1]!.length, text: h[2]!.trim()));
      continue;
    }
    final m = _privacyItemRe.firstMatch(line);
    if (m != null) {
      flush();
      kind = m[2] == '-' ? 'bullet' : 'item';
      level = m[1]!.isEmpty ? 1 : 2;
      buf.add(m[2] == '-' ? line.substring(m.end) : line.trimLeft());
      continue;
    }
    kind ??= 'paragraph';
    if (kind == 'paragraph') level = 0;
    buf.add(line.trim());
  }
  flush();
  return blocks;
}

/// Gizlilik Politikası — depo kökündeki PRIVACY_POLICY.md dosyasını gösterir
/// (tek kaynak: aynı metin hem uygulamada hem depoda durur; web'deki
/// `gizlilik.html` ve `hesap-silme.html` ondan üretilir —
/// `tool/gizlilik_sayfalari.dart`, PL4). Play'in Veri Güvenliği formu ve
/// KVKK bilgilendirmesi bu metne dayanır.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  // Dosya ve ayrıştırılmış bloklar state ömrü boyunca bir kez yüklenir (K-58/K-48).
  late final Future<List<PrivacyBlock>> _blocksFuture = rootBundle
      .loadString('PRIVACY_POLICY.md')
      .then(privacyBlocks);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: HomeInBar(appBar: AppBar(title: Text(l10n.privacyPolicyTitle))),
      body: FutureBuilder<List<PrivacyBlock>>(
        future: _blocksFuture,
        builder: (context, snapshot) {
          final blocks = snapshot.data;
          if (blocks == null) {
            return const Center(child: DelayedSpinner());
          }
          final style = AppText.of(Theme.of(context));
          return SelectionArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: blocks.length,
                  itemBuilder: (context, index) {
                    final b = blocks[index];
                    return switch (b.kind) {
                      'heading' => Padding(
                        padding: EdgeInsets.only(
                          top: b.level == 1 ? 0 : AppSpace.xl,
                          bottom: AppSpace.s,
                        ),
                        child: Text(
                          b.text,
                          style: b.level == 1
                              ? style.screenTitle
                              : style.sheetTitle,
                        ),
                      ),
                      'bullet' || 'item' => Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: AppSpace.l * (b.level - 1),
                          bottom: AppSpace.s,
                        ),
                        child: Text(
                          b.kind == 'bullet' ? '•  ${b.text}' : b.text,
                          style: style.body,
                        ),
                      ),
                      _ => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.m),
                        child: Text(b.text, style: style.body),
                      ),
                    };
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
