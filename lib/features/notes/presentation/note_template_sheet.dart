import '../../../core/app_icons.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/sheet_header.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/rich_text.dart';
import '../data/quick_entry_memory.dart';
import '../data/user_templates.dart';
import '../domain/note.dart';
import '../domain/note_templates.dart';
import '../domain/note_type.dart';
import 'template_editor_screen.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../../core/a11y/chip_roles.dart';
import '../../../app/theme/app_tokens.dart';
import 'quick_list_screen.dart';
import 'template_preview_card.dart';

/// Galeri ↔ önizleme geçişinde girişin yatay kayması (genişliğin oranı).
const double _enterShift = 0.03;

/// Boş hâl simgesi (bugünkü 40; minyatür kartın değil, boş galerinin).
const double _emptyIcon = 40;

Future<T?> _showTemplateSheet<T>(BuildContext context, Widget sheet) =>
    showAppSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: sheet,
      ),
    );

/// Şablon seçiminin sonucu: [open] — not oluşunca editörde açılsın mı;
/// [quick] — hızlı liste ekranından geldi (kayıt bildirimi gösterilir).
typedef TemplateOutcome = ({NoteTemplateContent content, bool open, bool quick});

/// **AKILLI LİSTE** girdisi (kullanıcı isteği 2026-11-16): tek tip liste;
/// market + bavul sözlüğü birlikte, tür yazılanlardan bulunur. Öneriler
/// alışveriş ve seyahat şablonlarının grupları; hafıza anahtarı `smart`.
QuickListArgs smartListArgs(BuildContext context) {
  final l10n = context.l10n;
  return QuickListArgs(
    kind: 'smart',
    title: l10n.smartListGeneric,
    icon: Icons.auto_awesome_outlined,
    accent: Theme.of(context).colorScheme.primary,
    groups: templateSuggestions(NoteTemplate.shopping, l10n),
    packingGroups: templateSuggestions(NoteTemplate.travel, l10n),
    smart: true,
  );
}

/// Şablon LİSTE ise hızlı liste ekranının girdisi; yazı şablonunda null.
QuickListArgs? quickListArgsFor(
  BuildContext context, {
  NoteTemplate? builtin,
  UserTemplate? user,
}) {
  final l10n = context.l10n;
  if (builtin != null) {
    final c = buildNoteTemplate(builtin, l10n);
    if (c.type != NoteType.checklist && c.type != NoteType.ordered) return null;
    return QuickListArgs(
      kind: 'b:${builtin.key}',
      title: c.title,
      icon: builtin.icon,
      accent: builtin.accent,
      type: c.type,
      seedItems: c.items,
      groups: templateSuggestions(builtin, l10n),
      grocery: builtin == NoteTemplate.shopping,
    );
  }
  if (user != null && user.isList) {
    final title = user.title.trim().isEmpty ? user.name : user.title.trim();
    return QuickListArgs(
      kind: 'u:${user.id}',
      title: title,
      icon: _userIcon(user.type),
      accent: Theme.of(context).colorScheme.primary,
      type: user.type,
      initialItems: user.items,
      grocery: looksLikeGrocery(title, user.items, l10n.localeName),
    );
  }
  return null;
}

/// **ŞABLONDAN NOT — TEK KAPI** (kullanıcı isteği 2026-11-15). Liste
/// şablonu levhadaki önizleme yerine HIZLI LİSTE sayfasında kurulur
/// ([QuickListScreen]); yazı şablonu eskisi gibi levhada önizlenir.
/// [initial]/[initialUser] liste ise galeri hiç açılmaz.
Future<TemplateOutcome?> pickTemplate(
  BuildContext context,
  WidgetRef ref, {
  NoteTemplate? initial,
  UserTemplate? initialUser,
}) async {
  var args = quickListArgsFor(context, builtin: initial, user: initialUser);
  if (args == null) {
    // TEK ÖRNEK (kullanıcı bulgusu 2026-11-15 "şablon oluştururken aşırı
    // kasıyor"): builder klavye payına bağlı, klavyenin her karesinde yeniden
    // çağrılır; levha builder DIŞINDA bir kez kurulur (S48).
    final sheet = NoteTemplateSheet(initial: initial, initialUser: initialUser);
    final picked = await _showTemplateSheet<Object>(context, sheet);
    if (picked is NoteTemplateContent) {
      return (content: picked, open: true, quick: false);
    }
    if (picked is! QuickListArgs || !context.mounted) return null;
    args = picked;
  }
  final result = await showQuickList(context, args);
  if (result == null) return null;
  ref.read(recentTemplatesProvider.notifier).remember(args.kind);
  return (content: result.content, open: result.open, quick: true);
}

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

/// **ŞABLON GALERİSİ + YAZI ŞABLONU ÖNİZLEMESİ** (bkz. [NoteTemplate]).
///
/// 1. **Galeri** — arama, bölüm çipleri (Listeler / Planlama / Yazı /
///    Şablonlarım), son kullanılanlar; her kartta içeriğin ilk satırları.
/// 2. LİSTE şablonu seçilince levha o şablonun [QuickListArgs]'ıyla kapanır
///    (hızlı liste sayfası, bkz. [pickTemplate]); YAZI şablonu
///    [TemplateComposer]'da önizlenir, "Oluştur" notu tek yazımda doğurur.
///
/// [initial]/[initialUser] verilirse galeri atlanır (yalnız yazı şablonu
/// gelir: liste şablonu [pickTemplate]'te levhasız açılır).
class NoteTemplateSheet extends ConsumerStatefulWidget {
  const NoteTemplateSheet({super.key, this.initial, this.initialUser});

  final NoteTemplate? initial;

  /// "+" menüsündeki favori KENDİ şablonum: galeri atlanır.
  final UserTemplate? initialUser;

  @override
  ConsumerState<NoteTemplateSheet> createState() => _NoteTemplateSheetState();
}

/// Bölüm çipi: null = tümü; [_mine] = kendi şablonlarım.
class _NoteTemplateSheetState extends ConsumerState<NoteTemplateSheet> {
  late _Pick? _picked = widget.initial != null
      ? _Pick.builtin(widget.initial!)
      : widget.initialUser != null
      ? _Pick.user(widget.initialUser!)
      : null;
  TemplateCategory? _category;
  bool _mine = false;
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Seçim: liste şablonu hızlı liste sayfasına gider, gerisi önizlemeye.
  void _pick(_Pick pick) {
    final args = quickListArgsFor(
      context,
      builtin: pick.builtin,
      user: pick.user,
    );
    if (args != null) {
      Navigator.pop<Object>(context, args);
      return;
    }
    setState(() => _picked = pick);
  }

  void _create(NoteTemplateContent content) {
    final picked = _picked;
    if (picked != null) {
      ref.read(recentTemplatesProvider.notifier).remember(picked.key);
    }
    Navigator.pop(context, content);
  }

  /// Minyatür satırları şablon başına BİR KEZ (S41): hazır şablonda kaynak
  /// dil kodu, kendi şablonumda şablon nesnesi — değişince yeniden hesaplanır.
  final Map<String, (Object, List<TemplateLineKind>)> _lines = {};

  List<TemplateLineKind> _linesOf(_Pick pick, AppLocalizations l10n) {
    final builtin = pick.builtin;
    final Object source = builtin != null ? l10n.localeName : pick.user!;
    final cached = _lines[pick.key];
    if (cached != null && cached.$1 == source) return cached.$2;
    final NoteTemplateContent c = builtin != null
        ? buildNoteTemplate(builtin, l10n)
        : (
            type: pick.user!.type,
            title: pick.user!.title,
            body: pick.user!.body,
            items: pick.user!.items,
            columns: 1,
          );
    final lines = templatePreviewLines(
      type: c.type,
      body: c.body,
      items: c.items,
    );
    _lines[pick.key] = (source, lines);
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    final enter = AppMotion.of(context, AppMotion.short);
    return AnimatedSwitcher(
      duration: enter,
      reverseDuration: AppMotion.exitOf(enter),
      switchInCurve: AppMotion.curveOf(context, AppMotion.enter),
      switchOutCurve: AppMotion.curveOf(context, AppMotion.exit),
      // Kayma yalnız GİRİŞTE (çıkış düz solma); yalnız boyama.
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => FractionalTranslation(
            translation: animation.status == AnimationStatus.reverse
                ? Offset.zero
                : Offset(_enterShift * (1 - animation.value), 0),
            child: child,
          ),
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
            columns: 1,
          );
    return TemplateComposer(
      base: base,
      label: builtin?.label(l10n) ?? user!.name,
      icon: builtin?.icon ?? _userIcon(user!.type),
      accent: builtin?.accent ?? scheme.primary,
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
    _pick(_Pick.user(saved));
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
      _pick(_Pick.user(saved));
    }
  }

  void _announce(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showMessage(message);
  }

  // ── 1. adım: galeri ───────────────────────────────────────────────────

  Widget _gallery(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final userTemplates = ref.watch(userTemplatesProvider);
    final recents = ref.watch(recentTemplatesProvider);
    final favorites = ref.watch(favoriteTemplatesProvider);
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
          searching
              ? _EmptyState(
                  icon: Icons.search_off_rounded,
                  text: l10n.templatesNoMatch,
                )
              : _EmptyState(
                  icon: Icons.bookmark_add_outlined,
                  text: l10n.templatesMineEmpty,
                  actionLabel: l10n.templateNew,
                  onAction: _newTemplate,
                ),
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
          _EmptyState(
            icon: Icons.search_off_rounded,
            text: l10n.templatesNoMatch,
          ),
        );
      }
    } else {
      // Favoriler ve son kullanılanlar yalnız "Tümü"nde, aramasızken —
      // hızlı dönüş. Favori olan son kullanılanlarda tekrar görünmez.
      if (_category == null) {
        final favoritePicks = <_Pick>[];
        for (final key in favorites) {
          final pick = _resolve(key, userTemplates);
          if (pick != null) favoritePicks.add(pick);
        }
        addSection(l10n.templatesFavorites, favoritePicks);
        final recentPicks = <_Pick>[];
        for (final key in recents) {
          if (favorites.contains(key)) continue;
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
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        0,
        AppSpace.l,
        AppSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpace.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.templatesTitle,
                    style: AppText.of(theme).sheetTitle,
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
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xs,
              0,
              AppSpace.xs,
              AppSpace.m,
            ),
            child: Text(l10n.templatesSubtitle, style: AppText.of(theme).meta),
          ),
          // Dolu, çerçevesiz hap arama alanı (plan §2.2).
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.templatesSearch,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: BorderSide.none,
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
          const SizedBox(height: AppSpace.m),
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
          const SizedBox(height: AppSpace.xs),
          // Bölüm değişince ızgara yalnız SOLARAK değişir (kayma yok, boy
          // tek adımda); aramada anahtar aynı → geçiş yok.
          AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.quick),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: Column(
              key: ValueKey('tpl-sections-$_category-$_mine'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: sections,
            ),
          ),
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
    padding: const EdgeInsets.only(right: AppSpace.s),
    child: radioChip(
      ChoiceChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: AppIconSize.xs),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    ),
  );

  Widget _grid(BuildContext context, List<_Pick> picks) => LayoutBuilder(
    builder: (context, constraints) {
      // KÜÇÜK KARTLAR (kullanıcı isteği 2026-11-05: "şablonların kart boyutu
      // küçültülür"): telefonda 3, genişte 4 sütun, kart dikey ve kısa.
      final columns = constraints.maxWidth > 480 ? 4 : 3;
      final width =
          (constraints.maxWidth - AppSpace.s * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpace.s,
        runSpacing: AppSpace.s,
        children: [
          // Anahtarlı: aramada sonuç daralınca kalan kart öğesiyle birlikte
          // yerinde kalır (konuma göre eşlenip yeniden kurulmaz, T7).
          for (final pick in picks)
            SizedBox(
              key: ValueKey(pick.key),
              width: math.max(0, width),
              child: _card(context, pick),
            ),
        ],
      );
    },
  );

  /// Kart önbelleği (T7, K-47/48): arama her tuşta kök `setState` ile
  /// galeriyi kurar; girdisi (şablon nesnesi, yıldız, vurgu rengi, dil)
  /// değişmeyen kart AYNI örnekle döner → yeniden kurulmaz (eskiden tuş
  /// başına ~24 kart). Tema değişimini kart kendi `Theme.of` bağımlılığıyla
  /// zaten alır; `ThemeData` kimliği her kurulumda yeni olabildiğinden anahtara
  /// yalnız kartın parametre olarak aldığı vurgu girer.
  final _cards = <String, (UserTemplate?, bool, Color, Locale, Widget)>{};

  Widget _card(BuildContext context, _Pick pick) {
    final accent = Theme.of(context).colorScheme.primary;
    final locale = Localizations.localeOf(context);
    final favorite = ref.watch(favoriteTemplatesProvider).contains(pick.key);
    final old = _cards[pick.key];
    if (old != null &&
        identical(old.$1, pick.user) &&
        old.$2 == favorite &&
        old.$3 == accent &&
        old.$4 == locale) {
      return old.$5;
    }
    final card = _buildCard(context, pick, favorite);
    _cards[pick.key] = (pick.user, favorite, accent, locale, card);
    return card;
  }

  Widget _buildCard(BuildContext context, _Pick pick, bool favorite) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final builtin = pick.builtin;
    void toggleFavorite() {
      final ok = ref.read(favoriteTemplatesProvider.notifier).toggle(pick.key);
      if (!ok) _announce(l10n.templateFavoritesFull);
    }

    final user = pick.user;
    final label = builtin != null
        ? builtin.label(l10n)
        : (user!.name.isEmpty ? l10n.remindersUntitled : user.name);
    // KÜÇÜK KÂĞIT KART (P63 PB4): minyatür içeriği gösterir; açıklama
    // ipucunda kalır (web fare üstü, uzun basış okuyucusu).
    return Tooltip(
      message: builtin != null
          ? builtin.description(l10n)
          : _userSummary(user!, l10n),
      waitDuration: AppMotion.long,
      child: TemplatePreviewCard(
        key: ValueKey('tpl-card-${pick.key}'),
        lines: _linesOf(pick, l10n),
        icon: builtin?.icon ?? _userIcon(user!.type),
        accent: builtin?.accent ?? scheme.primary,
        name: label,
        favorite: favorite,
        onFavorite: toggleFavorite,
        favoriteKey: ValueKey('tpl-fav-$label'),
        onTap: () => _pick(pick),
        onMenu: user == null ? null : () => _userMenu(user),
      ),
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
              leading: const Icon(AppIcons.copy),
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
      ref.read(favoriteTemplatesProvider.notifier).forget('u:${template.id}');
      // Geri al: yanlışlıkla silinen şablonun içeriği bir daha yazılmaz.
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showMessage(
        l10n.templateDeleted(template.name),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => notifier.add(template),
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
      .add(UserTemplate.fromNote(note, id: newUserTemplateId(), name: name));
  messenger
    ..hideCurrentSnackBar()
    ..showMessage(l10n.templateSaved(name));
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
    // Uygulamanın tek bölüm başlığı (TUTARLILIK F36.7).
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xs,
        AppSpace.l,
        AppSpace.xs,
        AppSpace.s,
      ),
      child: SectionLabel(label),
    );
  }
}

/// Galerinin TEK boş hâli (P63 PB4): boş "Şablonlarım" ve sonuçsuz arama
/// aynı kılıkta — simge, tek satır yazı, isteğe bağlı düğme.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final action = onAction;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpace.xxxl,
        horizontal: AppSpace.m,
      ),
      child: Column(
        children: [
          Icon(icon, size: _emptyIcon, color: scheme.outline),
          const SizedBox(height: AppSpace.m),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.of(theme).body
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpace.l),
            FilledButton.tonalIcon(
              onPressed: action,
              icon: const Icon(Icons.add),
              label: Text(actionLabel ?? ''),
            ),
          ],
        ],
      ),
    );
  }
}

/// **YAZI ŞABLONU ÖNİZLEMESİ** — not oluşmadan önce başlık biçilir, sayfanın
/// başlıkları olduğu gibi önizlenir. Liste şablonları hızlı liste sayfasında
/// kurulur ([QuickListScreen]; önizlemenin liste dalı 2026-11-17 T15'te
/// silindi).
class TemplateComposer extends StatefulWidget {
  const TemplateComposer({
    super.key,
    required this.base,
    required this.label,
    required this.icon,
    required this.accent,
    required this.onCreate,
    this.onBack,
    this.onSaveAsTemplate,
    this.saveAsEdits = false,
  });

  final NoteTemplateContent base;
  final String label;
  final IconData icon;
  final Color accent;
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

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  NoteTemplateContent _composed() =>
      composeTemplateContent(widget.base, title: _title.text);

  void _submit() => widget.onCreate(_composed());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = AppTokens.fromTheme(theme);
    // Gövde kayar, "Oluştur" SABİT ALT BANTTA (P63 PB4: uzun listede düğme
    // kaydırmanın altında kalıyordu). Levha zaten klavye payıyla dolgulu.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.m,
              0,
              AppSpace.l,
              AppSpace.l,
            ),
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
                      )
                    else
                      const SizedBox(width: AppSpace.xs),
                    Icon(
                      widget.icon,
                      color: widget.accent,
                      size: AppIconSize.m,
                    ),
                    const SizedBox(width: AppSpace.s),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: AppWeight.strong,
                        ),
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
                const SizedBox(height: AppSpace.s),
                // KÂĞIT: not sayfası gibi — başlık çerçevesiz, maddeler sıkı.
                // Material: madde satırlarının mürekkebi kâğıdın üstünde.
                Padding(
                  padding: const EdgeInsets.only(left: AppSpace.xs),
                  child: Material(
                    color: tokens.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.l),
                      side: BorderSide(color: tokens.hairline),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.l,
                        AppSpace.m,
                        AppSpace.l,
                        AppSpace.m,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _title,
                            textCapitalization: TextCapitalization.sentences,
                            style: theme.textTheme.titleLarge,
                            decoration: InputDecoration.collapsed(
                              hintText: l10n.captureNoteTitle,
                            ),
                          ),
                          const SizedBox(height: AppSpace.s),
                          ..._textPreview(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: tokens.hairline),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.s,
            ),
            child: FilledButton.icon(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kMinInteractiveDimension),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
              ),
              icon: const Icon(Icons.check),
              label: Text(
                l10n.templateCreate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Yazı şablonu: sayfanın başlıkları not sayfasındaki gibi.
  List<Widget> _textPreview(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return [
      for (final raw in widget.base.body.split('\n'))
        () {
          final plain = stripRichMarkers(raw);
          // Şablonlarda yalnız BAŞLIK satırları işaret taşır.
          final heading = plain != raw;
          return Padding(
            padding: EdgeInsets.only(top: heading ? AppSpace.s : AppSpace.xxs),
            child: Text(
              plain.isEmpty ? ' ' : plain,
              style: heading
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: AppWeight.strong,
                    )
                  : AppText.of(theme).body
                        .copyWith(color: scheme.onSurfaceVariant),
            ),
          );
        }(),
    ];
  }
}

/// Önizlemede biçilen içerik (saf, testli): başlık kırpılır, BOŞSA şablonun
/// kendi başlığı kalır; tür, gövde, maddeler ve sütun aynen.
NoteTemplateContent composeTemplateContent(
  NoteTemplateContent base, {
  required String title,
}) {
  final cleanTitle = title.trim();
  return (
    type: base.type,
    title: cleanTitle.isEmpty ? base.title : cleanTitle,
    body: base.body,
    items: base.items,
    columns: base.columns,
  );
}
