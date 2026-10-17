import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/rich_text.dart';
import '../data/user_templates.dart';
import '../domain/note.dart';
import '../domain/note_templates.dart';
import '../domain/note_type.dart';
import 'template_editor_screen.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';

/// **ŞABLON GALERİSİ + ÖNİZLEME/DÜZENLEME** (bkz. [NoteTemplate]).
///
/// 2026-09-29 YENİDEN DÜZEN (kullanıcı: "listeler şablonlar olmamış, daha
/// düzgün, gelişmiş özellikler olmalı"). Eski levha dokuz kartlık düz bir
/// ızgaraydı ve karta dokunmak notu HEMEN oluşturuyordu: ne geleceği
/// görülmüyor, alışveriş listesinin beş sabit maddesi herkese aynı
/// geliyordu. Artık iki adım:
///
/// 1. **Galeri** — arama, bölüm çipleri (Listeler / Planlama / Yazı /
///    Şablonlarım), son kullanılanlar; her kartta içeriğin ilk satırları.
/// 2. **Önizleme** — başlık düzenlenir; liste şablonunda maddeler tek tek
///    seçilir/çıkarılır, yenisi yazılır, reyon reyon ÖNERİLER çip olarak
///    eklenir, liste türü (onay kutulu / numaralı) seçilir. Yazı
///    şablonunda sayfanın başlıkları önizlenir. "Oluştur" notu bu hâliyle
///    TEK yazımda doğurur.
///
/// [initial] verilirse galeri atlanır, doğrudan o şablonun önizlemesi açılır
/// ("+" menüsündeki "Alışveriş listesi" kısayolu). Vazgeçilirse null.
Future<NoteTemplateContent?> showNoteTemplateSheet(
  BuildContext context, {
  NoteTemplate? initial,
}) => showAppSheet<NoteTemplateContent>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (sheetContext) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
    ),
    child: NoteTemplateSheet(initial: initial),
  ),
);

/// Galeride seçilen şablon: hazır ya da kullanıcının kendi şablonu.
@immutable
class _Pick {
  const _Pick.builtin(NoteTemplate this.builtin) : user = null;
  const _Pick.user(UserTemplate this.user) : builtin = null;

  final NoteTemplate? builtin;
  final UserTemplate? user;

  /// Son kullanılanlar listesindeki anahtar.
  String get key => builtin != null ? 'b:${builtin!.key}' : 'u:${user!.id}';
}

/// Levhanın kendisi (testte doğrudan kurulabilsin diye açık).
class NoteTemplateSheet extends ConsumerStatefulWidget {
  const NoteTemplateSheet({super.key, this.initial});

  final NoteTemplate? initial;

  @override
  ConsumerState<NoteTemplateSheet> createState() => _NoteTemplateSheetState();
}

/// Bölüm çipi: null = tümü; [_mine] = kendi şablonlarım.
class _NoteTemplateSheetState extends ConsumerState<NoteTemplateSheet> {
  late _Pick? _picked = widget.initial == null
      ? null
      : _Pick.builtin(widget.initial!);
  TemplateCategory? _category;
  bool _mine = false;
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _create(NoteTemplateContent content) {
    final picked = _picked;
    if (picked != null) {
      ref.read(recentTemplatesProvider.notifier).remember(picked.key);
    }
    Navigator.pop(context, content);
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: picked == null
          ? KeyedSubtree(
              key: const ValueKey('gallery'),
              child: _gallery(context),
            )
          : KeyedSubtree(
              key: ValueKey(
                'compose-${picked.key}-${picked.user?.hashCode ?? 0}',
              ),
              child: _composer(context, picked),
            ),
    );
  }

  // ── 2. adım: önizleme ─────────────────────────────────────────────────

  Widget _composer(BuildContext context, _Pick pick) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final builtin = pick.builtin;
    final user = pick.user;
    final NoteTemplateContent base = builtin != null
        ? buildNoteTemplate(builtin, l10n)
        : (
            type: user!.type,
            title: user.title,
            body: user.body,
            items: user.items,
          );
    return TemplateComposer(
      base: base,
      label: builtin?.label(l10n) ?? user!.name,
      icon: builtin?.icon ?? _userIcon(user!.type),
      accent: builtin?.accent ?? scheme.primary,
      suggestions: builtin == null
          ? const []
          : templateSuggestions(builtin, l10n),
      // Kısayolla doğrudan açıldıysa "geri" levhayı kapatmaz, galeriye döner.
      onBack: () => setState(() => _picked = null),
      onCreate: _create,
      // Kendi şablonumda "Düzenle" (yerinde günceller), hazır şablonda
      // "Şablonlarıma kaydet" (biçilmiş hâli kişisel şablon olur).
      onSaveAsTemplate: (content) => user != null
          ? _editUser(user)
          : _saveBuiltinAs(content, builtin!.label(l10n)),
      saveAsEdits: user != null,
    );
  }

  /// Önizlemede biçilen hazır şablon düzenleyicide açılır; kaydedilince
  /// "Şablonlarım"a girer ve önizleme o şablona geçer.
  Future<void> _saveBuiltinAs(NoteTemplateContent content, String name) async {
    final saved = await showTemplateEditor(
      context,
      initial: UserTemplate(
        id: '',
        name: name,
        type: content.type,
        title: content.title,
        body: content.body,
        items: content.items,
      ),
    );
    if (saved == null || !mounted) return;
    ref.read(userTemplatesProvider.notifier).add(saved);
    _announce(context.l10n.templateSaved(saved.name));
    setState(() => _picked = _Pick.user(saved));
  }

  Future<void> _newTemplate() async {
    final saved = await showTemplateEditor(context);
    if (saved == null || !mounted) return;
    ref.read(userTemplatesProvider.notifier).add(saved);
    _announce(context.l10n.templateSaved(saved.name));
    setState(() {
      _mine = true;
      _category = null;
    });
  }

  Future<void> _editUser(UserTemplate template) async {
    final saved = await showTemplateEditor(context, initial: template);
    if (saved == null || !mounted) return;
    ref.read(userTemplatesProvider.notifier).update(saved);
    // Önizleme açıksa yeni içerikle yeniden kurulur.
    if (_picked?.user?.id == saved.id) {
      setState(() => _picked = _Pick.user(saved));
    }
  }

  void _announce(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── 1. adım: galeri ───────────────────────────────────────────────────

  Widget _gallery(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final userTemplates = ref.watch(userTemplatesProvider);
    final recents = ref.watch(recentTemplatesProvider);
    final q = _fold(_query.trim());

    bool matchesBuiltin(NoteTemplate t) =>
        q.isEmpty ||
        _fold(t.label(l10n)).contains(q) ||
        _fold(t.description(l10n)).contains(q);
    bool matchesUser(UserTemplate t) =>
        q.isEmpty ||
        _fold(t.name).contains(q) ||
        t.items.any((i) => _fold(i).contains(q)) ||
        _fold(stripRichMarkers(t.body)).contains(q);

    final sections = <Widget>[];
    void addSection(String? label, List<_Pick> picks) {
      if (picks.isEmpty) return;
      if (label != null) sections.add(_SectionLabel(label));
      sections.add(_grid(context, picks));
    }

    final searching = q.isNotEmpty;
    if (_mine) {
      final mine = [
        for (final t in userTemplates)
          if (matchesUser(t)) _Pick.user(t),
      ];
      if (mine.isEmpty) {
        sections.add(
          _EmptyMine(searching: searching, onCreate: _newTemplate),
        );
      } else {
        addSection(null, mine);
      }
    } else if (searching) {
      addSection(null, [
        for (final t in userTemplates)
          if (matchesUser(t)) _Pick.user(t),
        for (final t in NoteTemplate.values)
          if (matchesBuiltin(t)) _Pick.builtin(t),
      ]);
      if (sections.isEmpty) {
        sections.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                l10n.templatesNoMatch,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }
    } else {
      // Son kullanılanlar yalnız "Tümü"nde, aramasızken — hızlı dönüş.
      if (_category == null) {
        final recentPicks = <_Pick>[];
        for (final key in recents) {
          final pick = _resolve(key, userTemplates);
          if (pick != null) recentPicks.add(pick);
        }
        addSection(l10n.templatesRecent, recentPicks);
      }
      for (final c in TemplateCategory.values) {
        if (_category != null && _category != c) continue;
        addSection(_categoryLabel(c, l10n), [
          for (final t in NoteTemplate.values)
            if (t.category == c) _Pick.builtin(t),
        ]);
      }
      if (_category == null && userTemplates.isNotEmpty) {
        addSection(l10n.templatesMine, [
          for (final t in userTemplates) _Pick.user(t),
        ]);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.templatesTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('tpl-new'),
                  onPressed: _newTemplate,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.templateNew),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              l10n.templatesSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.templatesSearch,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.clearSearch,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(
                  label: l10n.templatesAll,
                  selected: _category == null && !_mine,
                  onTap: () => setState(() {
                    _category = null;
                    _mine = false;
                  }),
                ),
                for (final c in TemplateCategory.values)
                  _chip(
                    label: _categoryLabel(c, l10n),
                    selected: _category == c && !_mine,
                    onTap: () => setState(() {
                      _category = c;
                      _mine = false;
                    }),
                  ),
                _chip(
                  label: userTemplates.isEmpty
                      ? l10n.templatesMine
                      : '${l10n.templatesMine} · ${userTemplates.length}',
                  icon: Icons.bookmark_outline,
                  selected: _mine,
                  onTap: () => setState(() {
                    _mine = true;
                    _category = null;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...sections,
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, size: 16),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    ),
  );

  Widget _grid(BuildContext context, List<_Pick> picks) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 480 ? 3 : 2;
      final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final pick in picks)
            SizedBox(width: math.max(0, width), child: _card(context, pick)),
        ],
      );
    },
  );

  Widget _card(BuildContext context, _Pick pick) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final builtin = pick.builtin;
    if (builtin != null) {
      return _TemplateCard(
        icon: builtin.icon,
        accent: builtin.accent,
        label: builtin.label(l10n),
        description: builtin.description(l10n),
        onTap: () => setState(() => _picked = pick),
      );
    }
    final user = pick.user!;
    return _TemplateCard(
      icon: _userIcon(user.type),
      accent: scheme.primary,
      label: user.name.isEmpty ? l10n.remindersUntitled : user.name,
      description: _userSummary(user, l10n),
      onTap: () => setState(() => _picked = pick),
      onMenu: () => _userMenu(user),
    );
  }

  Future<void> _userMenu(UserTemplate template) async {
    final l10n = context.l10n;
    final action = await showAppSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.templateEdit),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(l10n.templateDuplicate),
              onTap: () => Navigator.pop(sheetContext, 'duplicate'),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(l10n.templateRename),
              onTap: () => Navigator.pop(sheetContext, 'rename'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(l10n.templateDelete),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final notifier = ref.read(userTemplatesProvider.notifier);
    if (action == 'edit') return _editUser(template);
    if (action == 'duplicate') {
      notifier.duplicate(template.id, newId: newUserTemplateId());
      return;
    }
    if (action == 'delete') {
      notifier.remove(template.id);
      ref.read(recentTemplatesProvider.notifier).forget('u:${template.id}');
      // Geri al: yanlışlıkla silinen şablonun içeriği bir daha yazılmaz.
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          timedSnackBar(
            content: Text(l10n.templateDeleted(template.name)),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () => notifier.add(template),
            ),
          ),
        );
      return;
    }
    final name = await promptTemplateName(context, initial: template.name);
    if (name != null) notifier.rename(template.id, name);
  }

  _Pick? _resolve(String key, List<UserTemplate> userTemplates) {
    if (key.startsWith('b:')) {
      final name = key.substring(2);
      for (final t in NoteTemplate.values) {
        if (t.key == name) return _Pick.builtin(t);
      }
      return null;
    }
    if (key.startsWith('u:')) {
      final id = key.substring(2);
      for (final t in userTemplates) {
        if (t.id == id) return _Pick.user(t);
      }
    }
    return null;
  }
}

String _categoryLabel(TemplateCategory c, AppLocalizations l10n) => switch (c) {
  TemplateCategory.lists => l10n.templatesLists,
  TemplateCategory.planning => l10n.templatesPlanning,
  TemplateCategory.writing => l10n.templatesWriting,
};

IconData _userIcon(NoteType type) => switch (type) {
  NoteType.checklist => Icons.checklist,
  NoteType.ordered => Icons.format_list_numbered,
  _ => Icons.notes,
};

/// Kendi şablonumun kart altı: ilk maddeler ya da gövdenin ilk satırı.
String _userSummary(UserTemplate t, AppLocalizations l10n) {
  if (t.items.isNotEmpty) {
    return t.items.take(4).join(' · ');
  }
  for (final line in stripRichMarkers(t.body).split('\n')) {
    if (line.trim().isNotEmpty) return line.trim();
  }
  return l10n.templatesMineInfo;
}

String _fold(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

/// **ŞABLON OLARAK KAYDET** — kart ve editör menülerinin ortak gövdesi.
/// Ad sorulur (varsayılan: notun başlığı), şablon "Şablonlarım"a girer.
Future<void> saveNoteAsTemplate(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final name = await promptTemplateName(
    context,
    initial: note.displayTitle.trim(),
  );
  if (name == null) return;
  ref
      .read(userTemplatesProvider.notifier)
      .add(
        UserTemplate.fromNote(
          note,
          id: newUserTemplateId(),
          name: name,
        ),
      );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.templateSaved(name))));
}

/// Şablon adı sorusu (kaydetme ve yeniden adlandırma). İptalde null.
Future<String?> promptTemplateName(
  BuildContext context, {
  String initial = '',
}) async {
  final l10n = context.l10n;
  final controller = TextEditingController(text: initial);
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.templateNameTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.templateNameHint),
        onSubmitted: (v) => Navigator.pop(dialogContext, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: Text(l10n.templateSave),
        ),
      ],
    ),
  );
  controller.dispose();
  final clean = name?.trim() ?? '';
  return clean.isEmpty ? null : clean;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyMine extends StatelessWidget {
  const _EmptyMine({required this.searching, required this.onCreate});

  final bool searching;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Icon(Icons.bookmark_add_outlined, size: 40, color: scheme.outline),
          const SizedBox(height: 10),
          Text(
            searching ? l10n.templatesNoMatch : l10n.templatesMineEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (!searching) ...[
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.templateNew),
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.icon,
    required this.accent,
    required this.label,
    required this.description,
    required this.onTap,
    this.onMenu,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String description;
  final VoidCallback onTap;

  /// Kendi şablonumda ⋮ (yeniden adlandır / sil); uzun basış da açar.
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenu,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (onMenu != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  tooltip: context.l10n.more,
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMenu,
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Önizlemedeki tek madde: metni ve listeye girip girmeyeceği.
class _Item {
  _Item(this.text);

  final String text;
  bool selected = true;
}

/// **ŞABLON ÖNİZLEMESİ** — not oluşmadan önce içerik burada biçilir.
///
/// Liste şablonunda (madde / sıralı):
/// * her madde bir satır; onay kutusu listeye girip girmeyeceğini söyler
///   (varsayılanlar işaretli gelir, istenmeyen tek dokunuşla çıkar);
/// * "Madde ekle" alanı — Enter her maddeyi ekler, alan açık kalır;
/// * ÖNERİLER — reyon/konu başlıklı çipler; dokunulan öneri listeye girer,
///   bir daha dokununca çıkar;
/// * liste türü: onay kutulu ↔ numaralı.
///
/// Yazı şablonunda sayfanın başlıkları olduğu gibi önizlenir.
class TemplateComposer extends StatefulWidget {
  const TemplateComposer({
    super.key,
    required this.base,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onCreate,
    this.suggestions = const [],
    this.onBack,
    this.onSaveAsTemplate,
    this.saveAsEdits = false,
  });

  final NoteTemplateContent base;
  final String label;
  final IconData icon;
  final Color accent;
  final List<TemplateSuggestionGroup> suggestions;
  final VoidCallback? onBack;
  final ValueChanged<NoteTemplateContent> onCreate;

  /// Başlıktaki yer imi düğmesi: o an biçilen içerikle çağrılır. null ise
  /// düğme yok.
  final ValueChanged<NoteTemplateContent>? onSaveAsTemplate;

  /// true: düğme "Şablonu düzenle" (kendi şablonum), false: "Şablonlarıma
  /// kaydet" (hazır şablon).
  final bool saveAsEdits;

  @override
  State<TemplateComposer> createState() => _TemplateComposerState();
}

class _TemplateComposerState extends State<TemplateComposer> {
  late final _title = TextEditingController(text: widget.base.title);
  final _add = TextEditingController();
  final _addFocus = FocusNode();
  late final List<_Item> _items = [for (final t in widget.base.items) _Item(t)];
  late NoteType _type = widget.base.type;

  bool get _isList =>
      widget.base.type == NoteType.checklist ||
      widget.base.type == NoteType.ordered;

  @override
  void dispose() {
    _title.dispose();
    _add.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  int get _selectedCount => _items.where((i) => i.selected).length;

  bool _hasItem(String text) => _items.any(
    (i) => i.selected && i.text.toLowerCase() == text.toLowerCase(),
  );

  void _toggleSuggestion(String text) {
    setState(() {
      final existing = _items.indexWhere(
        (i) => i.text.toLowerCase() == text.toLowerCase(),
      );
      if (existing < 0) {
        _items.add(_Item(text));
      } else {
        _items[existing].selected = !_items[existing].selected;
      }
    });
  }

  void _addTyped() {
    final text = _add.text.trim();
    if (text.isEmpty) return;
    setState(() {
      final existing = _items.indexWhere(
        (i) => i.text.toLowerCase() == text.toLowerCase(),
      );
      if (existing < 0) {
        _items.add(_Item(text));
      } else {
        _items[existing].selected = true;
      }
      _add.clear();
    });
    _addFocus.requestFocus();
  }

  NoteTemplateContent _composed() {
    // Yazılıp eklenmeden bırakılan madde de listeye girer.
    if (_add.text.trim().isNotEmpty) _addTyped();
    return composeTemplateContent(
      widget.base,
      title: _title.text,
      type: _type,
      items: [
        for (final i in _items)
          if (i.selected) i.text,
      ],
    );
  }

  void _submit() => widget.onCreate(_composed());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  tooltip: l10n.back,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (widget.onSaveAsTemplate != null)
                IconButton(
                  key: const ValueKey('tpl-save-as'),
                  tooltip: widget.saveAsEdits
                      ? l10n.templateEdit
                      : l10n.templateSaveAsMine,
                  icon: Icon(
                    widget.saveAsEdits
                        ? Icons.edit_outlined
                        : Icons.bookmark_add_outlined,
                  ),
                  onPressed: () => widget.onSaveAsTemplate!(_composed()),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.captureNoteTitle,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_isList)
            ..._listEditor(context, scheme)
          else
            _textPreview(context),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(
                _isList && _selectedCount > 0
                    ? l10n.templateCreateWithCount(_selectedCount)
                    : l10n.templateCreate,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _listEditor(BuildContext context, ColorScheme scheme) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: SegmentedButton<NoteType>(
          segments: [
            ButtonSegment(
              value: NoteType.checklist,
              icon: const Icon(Icons.checklist),
              label: Text(l10n.templateListChecks),
            ),
            ButtonSegment(
              value: NoteType.ordered,
              icon: const Icon(Icons.format_list_numbered),
              label: Text(l10n.templateListNumbers),
            ),
          ],
          selected: {_type},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _type = v.first),
        ),
      ),
      _SectionLabel(
        _items.isEmpty
            ? l10n.templateItems
            : '${l10n.templateItems} · $_selectedCount/${_items.length}',
      ),
      for (var i = 0; i < _items.length; i++)
        CheckboxListTile(
          key: ValueKey('tpl-item-$i-${_items[i].text}'),
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.only(left: 4),
          controlAffinity: ListTileControlAffinity.leading,
          value: _items[i].selected,
          title: Text(
            _items[i].text,
            style: _items[i].selected
                ? null
                : TextStyle(
                    color: scheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
          ),
          onChanged: (v) => setState(() => _items[i].selected = v ?? false),
        ),
      Padding(
        padding: const EdgeInsets.only(left: 4, top: 4),
        child: TextField(
          controller: _add,
          focusNode: _addFocus,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.add),
            hintText: l10n.templateAddItem,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _addTyped(),
        ),
      ),
      for (final group in widget.suggestions) ...[
        _SectionLabel(group.label),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              for (final s in group.items)
                FilterChip(
                  label: Text(s),
                  selected: _hasItem(s),
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => _toggleSuggestion(s),
                ),
            ],
          ),
        ),
      ],
      if (widget.suggestions.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            l10n.templateSuggestionsInfo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
    ];
  }

  Widget _textPreview(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = widget.base.body.split('\n');
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 0, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final raw in lines)
              () {
                final plain = stripRichMarkers(raw);
                // Şablonlarda yalnız BAŞLIK satırları işaret taşır.
                final heading = plain != raw;
                return Padding(
                  padding: EdgeInsets.only(top: heading ? 8 : 1),
                  child: Text(
                    plain.isEmpty ? ' ' : plain,
                    style: heading
                        ? theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )
                        : theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                  ),
                );
              }(),
          ],
        ),
      ),
    );
  }
}

/// Önizlemede biçilen içerik (saf, testli): başlık kırpılır, BOŞSA şablonun
/// kendi başlığı kalır; liste şablonunda tür ve seçili maddeler, yazı
/// şablonunda gövde aynen.
NoteTemplateContent composeTemplateContent(
  NoteTemplateContent base, {
  required String title,
  required NoteType type,
  required List<String> items,
}) {
  final isList =
      base.type == NoteType.checklist || base.type == NoteType.ordered;
  final cleanTitle = title.trim();
  return (
    type: isList ? type : base.type,
    title: cleanTitle.isEmpty ? base.title : cleanTitle,
    body: base.body,
    items: isList
        ? [
            for (final i in items)
              if (i.trim().isNotEmpty) i.trim(),
          ]
        : base.items,
  );
}
