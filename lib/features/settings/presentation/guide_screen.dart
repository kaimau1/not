import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/search_fold.dart';
import '../../../core/l10n_ext.dart';

/// KULLANIM KILAVUZU (kullanıcı isteği 2026-10-11: "tüm özellikleri anlatan,
/// gösteren bir kullanım kılavuzu").
///
/// KARAR — içerik dil başına bir METİN dosyasında
/// (`assets/guide/guide_<dil>.md`), l10n anahtarlarında DEĞİL: kılavuz yüzlerce cümle; her biri ayrı
/// anahtar olsaydı ARB'ler şişer, cümleler bağlamından kopuk çevrilirdi.
/// Dosyası olmayan dil İngilizceye düşer (Türkçe ve İngilizce tam).
///
/// Biçim: `## Başlık {#kimlik}` bölüm açar; `### ` alt başlık, `- ` madde,
/// `1. ` adım, `**kalın**`. Kimlik bölümün simgesini ve "Ekranı aç"
/// düğmesinin gideceği yeri seçer (bkz. [guideSectionMeta]) — metin
/// çevrilirken kimlik aynen kalır.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key, this.initialSection});

  /// Doğrudan açılacak bölüm (ör. `/guide?section=pages`).
  final String? initialSection;

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

/// Kılavuzun bir bölümü.
class GuideSection {
  const GuideSection({
    required this.id,
    required this.title,
    required this.blocks,
  });

  final String id;
  final String title;
  final List<GuideBlock> blocks;

  /// Aramada eşleşme için bölümün bütün metni (küçük harf).
  String get searchText =>
      foldForSearch('$title\n${blocks.map((b) => b.text).join('\n')}');
}

enum GuideBlockKind { paragraph, subheading, bullet, step }

class GuideBlock {
  const GuideBlock(this.kind, this.text, {this.number = 0});

  final GuideBlockKind kind;
  final String text;

  /// Adım numarası ([GuideBlockKind.step]).
  final int number;
}

/// Ayrıştırılmış kılavuz: giriş paragrafları + bölümler.
class ParsedGuide {
  const ParsedGuide({required this.intro, required this.sections});

  final List<GuideBlock> intro;
  final List<GuideSection> sections;
}

final _sectionHeader = RegExp(r'^##\s+(.+?)\s*\{#([a-z0-9_-]+)\}\s*$');
final _stepLine = RegExp(r'^(\d+)\.\s+(.*)$');

/// Kılavuz metnini bölümlere ayırır (saf — testlerde doğrudan sınanır).
ParsedGuide parseGuide(String source) {
  final intro = <GuideBlock>[];
  final sections = <GuideSection>[];
  String? id;
  String? title;
  var blocks = <GuideBlock>[];

  void close() {
    final sectionId = id;
    final sectionTitle = title;
    if (sectionId != null && sectionTitle != null) {
      sections.add(
        GuideSection(id: sectionId, title: sectionTitle, blocks: blocks),
      );
    }
  }

  for (final raw in source.split('\n')) {
    final line = raw.trimRight();
    if (line.trim().isEmpty) continue;
    // Belge başlığı (# ) ekranın kendi başlığında; metinde tekrarlanmaz.
    if (line.startsWith('# ')) continue;
    final header = _sectionHeader.firstMatch(line);
    if (header != null) {
      close();
      title = header.group(1)!.trim();
      id = header.group(2)!;
      blocks = <GuideBlock>[];
      continue;
    }
    final GuideBlock block;
    if (line.startsWith('### ')) {
      block = GuideBlock(GuideBlockKind.subheading, line.substring(4).trim());
    } else if (line.startsWith('- ')) {
      block = GuideBlock(GuideBlockKind.bullet, line.substring(2).trim());
    } else if (_stepLine.hasMatch(line)) {
      final m = _stepLine.firstMatch(line)!;
      block = GuideBlock(
        GuideBlockKind.step,
        m.group(2)!.trim(),
        number: int.parse(m.group(1)!),
      );
    } else {
      block = GuideBlock(GuideBlockKind.paragraph, line.trim());
    }
    (id == null ? intro : blocks).add(block);
  }
  close();
  return ParsedGuide(intro: intro, sections: sections);
}

/// `**kalın**` işaretlerini çizime çevirir.
List<TextSpan> guideInlineSpans(String text, TextStyle? bold) {
  final spans = <TextSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*');
  var cursor = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start)));
    }
    spans.add(TextSpan(text: m.group(1), style: bold));
    cursor = m.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return spans;
}

/// Bölüm kimliği → simge ve (varsa) "Ekranı aç" ile gidilecek rota.
({IconData icon, String? route}) guideSectionMeta(String id) => switch (id) {
  'start' => (icon: Icons.rocket_launch_outlined, route: null),
  'home' => (icon: Icons.home_outlined, route: null),
  'create' => (icon: Icons.add_circle_outline, route: null),
  'editor' => (icon: Icons.edit_note, route: null),
  'pages' => (icon: Icons.auto_stories_outlined, route: null),
  'media' => (icon: Icons.image_outlined, route: null),
  'video' => (icon: Icons.smart_display_outlined, route: null),
  'pin' => (icon: Icons.vertical_align_top, route: null),
  'gestures' => (icon: Icons.gesture, route: null),
  'embed' => (icon: Icons.attach_file, route: null),
  'documents' => (icon: Icons.picture_as_pdf_outlined, route: null),
  'scan' => (icon: Icons.document_scanner_outlined, route: null),
  'voice' => (icon: Icons.mic_none, route: null),
  'transcript' => (icon: Icons.subtitles_outlined, route: null),
  'ai' => (icon: Icons.auto_awesome_outlined, route: '/ai'),
  'organize' => (icon: Icons.folder_outlined, route: '/folders'),
  'reminders' => (icon: Icons.alarm_outlined, route: '/reminders'),
  'share' => (icon: Icons.share_outlined, route: '/inbox'),
  'widgets' => (icon: Icons.widgets_outlined, route: null),
  'settings' => (icon: Icons.settings_outlined, route: '/settings'),
  'tips' => (icon: Icons.lightbulb_outline, route: null),
  _ => (icon: Icons.article_outlined, route: null),
};

/// Dilin kılavuz dosyası; yoksa İngilizce.
Future<String> loadGuideSource(String languageCode) async {
  // `cache: false`: kılavuz nadiren açılır, metni bellekte tutmaya değmez.
  try {
    return await rootBundle.loadString(
      'assets/guide/guide_$languageCode.md',
      cache: false,
    );
  } catch (_) {
    return rootBundle.loadString('assets/guide/guide_en.md', cache: false);
  }
}

class _GuideScreenState extends State<GuideScreen> {
  Future<ParsedGuide>? _guide;
  String? _lang;
  final _search = TextEditingController();
  String _query = '';

  /// Açık bölümler (aramada eşleşenler ayrıca açık çizilir).
  final _expanded = <String>{};
  final _keys = <String, GlobalKey>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (lang != _lang) {
      _lang = lang;
      _guide = loadGuideSource(lang).then(parseGuide);
      final initial = widget.initialSection;
      if (initial != null) {
        _expanded.add(initial);
        _guide!.then((_) => _scrollTo(initial));
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  void _scrollTo(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[id]?.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _jump(String id) {
    setState(() {
      _expanded.add(id);
      _query = '';
      _search.clear();
    });
    _scrollTo(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guideTitle)),
      body: FutureBuilder<ParsedGuide>(
        future: _guide,
        builder: (context, snapshot) {
          final guide = snapshot.data;
          if (guide == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final query = foldForSearch(_query.trim());
          final visible = [
            for (final s in guide.sections)
              if (query.isEmpty || s.searchText.contains(query)) s,
          ];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              // ListView DEĞİL: tembel liste ekran dışındaki bölümleri hiç
              // kurmuyor, "İçindekiler"den atlama ([_scrollTo]) hedefini
              // bulamıyordu. On dokuz kart — hepsini kurmak ucuz.
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  14,
                  8,
                  14,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const ValueKey('guide-search'),
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.guideSearchHint,
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: l10n.clearSearch,
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() {
                                  _query = '';
                                  _search.clear();
                                }),
                              ),
                      ),
                    ),
                    if (query.isEmpty) ...[
                      const SizedBox(height: 12),
                      for (final b in guide.intro) _GuideBlockView(block: b),
                      const SizedBox(height: 8),
                      Text(
                        l10n.guideContents,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in guide.sections)
                            ActionChip(
                              key: ValueKey('guide-chip-${s.id}'),
                              avatar: Icon(
                                guideSectionMeta(s.id).icon,
                                size: 18,
                              ),
                              label: Text(s.title),
                              onPressed: () => _jump(s.id),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.guideNoResults(_query.trim()),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    for (final s in visible)
                      _SectionCard(
                        key: _keyFor(s.id),
                        section: s,
                        expanded: query.isNotEmpty || _expanded.contains(s.id),
                        onToggle: () => setState(() {
                          if (!_expanded.remove(s.id)) _expanded.add(s.id);
                        }),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    super.key,
    required this.section,
    required this.expanded,
    required this.onToggle,
  });

  final GuideSection section;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final meta = guideSectionMeta(section.id);
    final route = meta.route;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('guide-section-${section.id}'),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      meta.icon,
                      size: 20,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final b in section.blocks)
                          _GuideBlockView(block: b),
                        if (route != null)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: FilledButton.tonalIcon(
                                key: ValueKey('guide-open-${section.id}'),
                                onPressed: () => context.push(route),
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: Text(context.l10n.guideOpenScreen),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuideBlockView extends StatelessWidget {
  const _GuideBlockView({required this.block});

  final GuideBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.textTheme.bodyMedium?.copyWith(height: 1.45);
    final bold = base?.copyWith(fontWeight: FontWeight.w700);
    final text = Text.rich(
      TextSpan(style: base, children: guideInlineSpans(block.text, bold)),
    );
    switch (block.kind) {
      case GuideBlockKind.subheading:
        return Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(block.text, style: theme.textTheme.titleSmall),
        );
      case GuideBlockKind.paragraph:
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: text);
      case GuideBlockKind.bullet:
        return Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: text),
            ],
          ),
        );
      case GuideBlockKind.step:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${block.number}',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: text),
            ],
          ),
        );
    }
  }
}
