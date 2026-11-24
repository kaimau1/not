import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/friendly_error.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../auth/presentation/account_required.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../settings/settings_providers.dart';
import '../data/ai_gate.dart';
import '../data/ai_history.dart';
import '../data/gemini_service.dart';
import '../domain/smart_categorize.dart';
import 'ai_result_note.dart';

/// Toplu "Sessiz düzen" (A8, PLAN §1.6) kapsamı.
enum QuietOrganizeScope { titles, tags, both }

/// Başlıksız ve/veya etiketsiz notları yerelde 0 krediyle sınıflandırır ve
/// isteğe bağlı olarak düşük güvenlileri tek istekte toplu yapay zekâya sorar.
/// Kullanıcı önerileri kutucuklarla seçip tek dokunuşla uygular; tek "Geri al"
/// tüm notları eski hâline döndürür.
Future<void> showQuietOrganizeSheet(
  BuildContext context, {
  QuietOrganizeScope scope = QuietOrganizeScope.both,
  bool preferLocalFirst = false,
}) => showAppSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _QuietOrganizeSheet(
    initialScope: scope,
    preferLocalFirst: preferLocalFirst,
  ),
);

class _QuietOrganizeSheet extends ConsumerStatefulWidget {
  const _QuietOrganizeSheet({
    required this.initialScope,
    required this.preferLocalFirst,
  });

  final QuietOrganizeScope initialScope;
  final bool preferLocalFirst;

  @override
  ConsumerState<_QuietOrganizeSheet> createState() =>
      _QuietOrganizeSheetState();
}

class _QuietOrganizeSheetState extends ConsumerState<_QuietOrganizeSheet> {
  late QuietOrganizeScope _scope;
  bool _loading = true;
  bool _applying = false;
  bool _aiRefined = false;
  String? _error;
  List<QuietOrganizeSuggestion> _suggestions = const [];
  Map<String, SmartNoteClassification> _localById = const {};
  Map<String, NoteFolder> _folderByName = const {};
  final Set<String> _selected = {};

  bool get _suggestTitles =>
      _scope == QuietOrganizeScope.titles || _scope == QuietOrganizeScope.both;

  bool get _suggestTags =>
      _scope == QuietOrganizeScope.tags || _scope == QuietOrganizeScope.both;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch();
    });
  }

  Future<void> _fetch({bool forceAi = false}) async {
    for (
      var i = 0;
      i < 3 &&
          (ref.read(notesStreamProvider).isLoading ||
              ref.read(foldersStreamProvider).isLoading);
      i++
    ) {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
    }
    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    final folders =
        ref.read(foldersStreamProvider).value ?? const <NoteFolder>[];
    final folderByName = {for (final f in folders) f.name: f};
    final folderNames = folderByName.keys.toList(growable: false);
    final prefs = ref.read(sharedPreferencesProvider);
    final learn = SmartNoteLearn(prefs);
    final localList = SmartNoteCategorizer.classifyAll(
      notes,
      suggestTitles: _suggestTitles,
      suggestTags: _suggestTags,
      learn: learn,
      existingFolders: folderNames,
    );
    final localMap = {for (final c in localList) c.noteId: c};
    final localSuggestions = [
      for (final c in localList) c.toOrganizeSuggestion(),
    ];

    final availability = ref.read(aiAvailabilityProvider);
    final useLocalOnly =
        !forceAi &&
        (widget.preferLocalFirst || availability != AiAvailability.ready);

    if (useLocalOnly) {
      if (!mounted) return;
      setState(() {
        _localById = localMap;
        _folderByName = folderByName;
        _suggestions = localSuggestions;
        _selected
          ..clear()
          ..addAll(localSuggestions.map((r) => r.noteId));
        _error = null;
        _loading = false;
        _aiRefined = false;
      });
      return;
    }

    if (!ensureAiReady(context, ref)) {
      if (forceAi) return;
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    final targetNotes = forceAi
        ? [
            for (final n in notes)
              if (localMap[n.id]?.needsAiRefinement ?? false) n,
          ]
        : notes;

    if (forceAi && targetNotes.isEmpty) {
      if (mounted) setState(() => _aiRefined = true);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _localById = localMap;
      _folderByName = folderByName;
      if (!forceAi) {
        _suggestions = localSuggestions;
        _selected.clear();
      }
    });

    try {
      final results = await ref
          .read(geminiServiceProvider)
          .batchQuietOrganize(
            targetNotes,
            suggestTitles: _suggestTitles,
            suggestTags: _suggestTags,
          );
      if (!mounted) return;
      final merged = forceAi ? _mergeSuggestions(results) : results;
      setState(() {
        _suggestions = merged;
        _selected
          ..clear()
          ..addAll(merged.map((r) => r.noteId));
        _loading = false;
        _aiRefined = true;
      });
    } catch (e) {
      if (!mounted) return;
      if (!forceAi && localSuggestions.isNotEmpty) {
        setState(() {
          _suggestions = localSuggestions;
          _selected
            ..clear()
            ..addAll(localSuggestions.map((r) => r.noteId));
          _loading = false;
          _aiRefined = false;
        });
        return;
      }
      setState(() {
        _error = aiErrorText(context.l10n, e);
        _loading = false;
      });
    }
  }

  List<QuietOrganizeSuggestion> _mergeSuggestions(
    List<QuietOrganizeSuggestion> aiResults,
  ) {
    final byId = {for (final s in _suggestions) s.noteId: s};
    for (final s in aiResults) {
      byId[s.noteId] = s;
    }
    return byId.values.toList(growable: false);
  }

  Future<void> _pickCategoryFix(
    Note note,
    SmartNoteClassification current,
  ) async {
    final l10n = context.l10n;
    final picked = await showAppSheet<SmartNoteCategory>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: l10n.aiSmartFixTitle),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final cat in SmartNoteCategory.values)
                        ListTile(
                          key: ValueKey('smart-fix-cat-${cat.name}'),
                          title: Text(_categoryLabel(l10n, cat)),
                          trailing: cat == current.category
                              ? Icon(
                                  Icons.check,
                                  size: AppIconSize.m,
                                  color: Theme.of(ctx).colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(ctx, cat),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || picked == current.category || !mounted) return;

    final learn = SmartNoteLearn(ref.read(sharedPreferencesProvider));
    await learn.recordCorrection(note, current.category, picked);
    final folders = _folderByName.keys.toList(growable: false);
    final updated = SmartNoteCategorizer.overrideCategory(
      note,
      picked,
      suggestTitle: _suggestTitles,
      suggestTags: _suggestTags,
      existingFolders: folders,
    );

    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    final similar = learn.findSimilar(
      note,
      current.category,
      notes,
      currentCategoryOf: (n) =>
          _localById[n.id]?.category ?? SmartNoteCategory.personal,
    );

    var applySimilar = false;
    if (similar.isNotEmpty && mounted) {
      applySimilar =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.aiSmartSimilarConfirmTitle),
              content: Text(l10n.aiSmartSimilarConfirmBody(similar.length)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.aiQuietOrganizeApply(similar.length)),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!mounted) return;
    final nextLocal = Map<String, SmartNoteClassification>.from(_localById);
    final suggestionMap = {for (final s in _suggestions) s.noteId: s};

    void applyOverride(Note target, SmartNoteClassification next) {
      nextLocal[target.id] = next;
      suggestionMap[target.id] = next.toOrganizeSuggestion();
      _selected.add(target.id);
    }

    applyOverride(note, updated);
    if (applySimilar) {
      for (final other in similar) {
        final prevCat =
            nextLocal[other.id]?.category ?? SmartNoteCategory.personal;
        await learn.recordCorrection(other, prevCat, picked);
        applyOverride(
          other,
          SmartNoteCategorizer.overrideCategory(
            other,
            picked,
            suggestTitle: _suggestTitles,
            suggestTags: _suggestTags,
            existingFolders: folders,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _localById = nextLocal;
      _suggestions = suggestionMap.values.toList(growable: false);
    });
  }

  static String _categoryLabel(AppLocalizations l10n, SmartNoteCategory cat) =>
      switch (cat) {
        SmartNoteCategory.finance => l10n.aiCatFinance,
        SmartNoteCategory.health => l10n.aiCatHealth,
        SmartNoteCategory.education => l10n.aiCatEducation,
        SmartNoteCategory.work => l10n.aiCatWork,
        SmartNoteCategory.shopping => l10n.aiCatShopping,
        SmartNoteCategory.travel => l10n.aiCatTravel,
        SmartNoteCategory.personal => l10n.aiCatPersonal,
        SmartNoteCategory.tech => l10n.aiCatTech,
        SmartNoteCategory.recipes => l10n.aiCatRecipes,
        SmartNoteCategory.official => l10n.aiCatOfficial,
      };

  Future<void> _apply() async {
    if (_applying || _selected.isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    final byId = {for (final n in notes) n.id: n};

    final updates = <({Note before, Note after})>[];
    for (final s in _suggestions) {
      if (!_selected.contains(s.noteId)) continue;
      final current = byId[s.noteId];
      if (current == null || current.locked) continue;
      final nextTitle = (s.title != null && current.title.trim().isEmpty)
          ? s.title!
          : current.title;
      final nextTags = (s.tags.isNotEmpty && current.tags.isEmpty)
          ? s.tags
          : current.tags;
      final localFolderName = _localById[s.noteId]?.folderSuggestion;
      final matchedFolder = localFolderName == null
          ? null
          : _folderByName[localFolderName];
      final nextFolderId =
          ((current.folderId == null || current.folderId!.isEmpty) &&
              matchedFolder != null)
          ? matchedFolder.id
          : current.folderId;
      if (nextTitle == current.title &&
          _sameTags(nextTags, current.tags) &&
          nextFolderId == current.folderId) {
        continue;
      }
      updates.add((
        before: current,
        after: current.copyWith(
          title: nextTitle,
          tags: nextTags,
          folderId: nextFolderId,
        ),
      ));
    }
    if (updates.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _applying = true);
    for (final pair in updates) {
      await repo.updateNote(pair.after);
    }
    ref.read(aiHistoryProvider.notifier).record(l10n.aiQuietOrganizeTitle);
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: l10n.aiQuietOrganizeApplied(updates.length),
      undoLabel: l10n.undo,
      onUndo: () {
        for (final pair in updates) {
          repo.updateNote(pair.before);
        }
      },
    );
    Navigator.pop(context);
  }

  static bool _sameTags(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
    ref.watch(foldersStreamProvider);
    ref.listen(foldersStreamProvider, (prev, next) {
      if (next.hasValue && !_aiRefined && _localById.isNotEmpty) {
        final hasFolders = (next.value ?? const <NoteFolder>[]).isNotEmpty;
        if (hasFolders && _folderByName.isEmpty) _fetch();
      }
    });
    final byId = {for (final n in notes) n.id: n};

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.aiQuietOrganizeTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.s,
              ),
              child: Wrap(
                spacing: AppSpace.s,
                runSpacing: AppSpace.xs,
                children: [
                  for (final (s, label) in [
                    (QuietOrganizeScope.both, l10n.aiQuietOrganizeBoth),
                    (QuietOrganizeScope.tags, l10n.aiTaskTagUntagged),
                    (QuietOrganizeScope.titles, l10n.aiTaskSuggestTitles),
                  ])
                    ChoiceChip(
                      key: ValueKey('quiet-org-scope-${s.name}'),
                      label: Text(label),
                      selected: _scope == s,
                      onSelected: _loading
                          ? null
                          : (on) {
                              if (on && _scope != s) {
                                setState(() => _scope = s);
                                _fetch();
                              }
                            },
                    ),
                ],
              ),
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.all(AppSpace.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpace.m),
                    Text(l10n.aiThinking, style: text.meta),
                  ],
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: text.body.copyWith(color: scheme.error),
                    ),
                    const SizedBox(height: AppSpace.m),
                    FilledButton.tonal(
                      onPressed: _fetch,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              )
            else if (_suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpace.xxl),
                child: Text(
                  l10n.aiQuietOrganizeEmpty,
                  textAlign: TextAlign.center,
                  style: text.body.copyWith(color: scheme.onSurfaceVariant),
                ),
              )
            else ...[
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.l,
                    vertical: AppSpace.s,
                  ),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpace.s),
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];
                    final note = byId[s.noteId];
                    final local = _localById[s.noteId];
                    final checked = _selected.contains(s.noteId);
                    final preview = (note?.toPlainText() ?? '')
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim();
                    final existingTitle = (note?.title ?? '').trim();
                    return Material(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() {
                          if (checked) {
                            _selected.remove(s.noteId);
                          } else {
                            _selected.add(s.noteId);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.m),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                key: ValueKey('quiet-org-check-${s.noteId}'),
                                value: checked,
                                onChanged: (v) => setState(() {
                                  if (v ?? false) {
                                    _selected.add(s.noteId);
                                  } else {
                                    _selected.remove(s.noteId);
                                  }
                                }),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (s.title != null &&
                                        existingTitle.isEmpty)
                                      Text(
                                        s.title!,
                                        style: text.rowTitle.copyWith(
                                          color: scheme.primary,
                                        ),
                                      )
                                    else
                                      Text(
                                        existingTitle.isNotEmpty
                                            ? existingTitle
                                            : l10n.remindersUntitled,
                                        style: text.rowTitle,
                                      ),
                                    if (preview.isNotEmpty) ...[
                                      const SizedBox(height: AppSpace.xxs),
                                      Text(
                                        preview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: text.meta,
                                      ),
                                    ],
                                    if (local != null) ...[
                                      const SizedBox(height: AppSpace.xs),
                                      Wrap(
                                        spacing: AppSpace.xs,
                                        runSpacing: AppSpace.xs,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpace.s,
                                              vertical: AppSpace.xxs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: scheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.s,
                                                  ),
                                            ),
                                            child: Text(
                                              '${_categoryLabel(l10n, local.category)} · ${l10n.aiLocalBadge((local.confidence * 100).round())}',
                                              style: text.badge.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          if (local.folderSuggestion != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpace.s,
                                                    vertical: AppSpace.xxs,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: scheme.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.s,
                                                    ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.folder_outlined,
                                                    size: AppIconSize.s,
                                                    color: scheme
                                                        .onPrimaryContainer,
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpace.xxs,
                                                  ),
                                                  Text(
                                                    l10n.aiSmartFolderSuggestion(
                                                      local.folderSuggestion!,
                                                    ),
                                                    style: text.badge.copyWith(
                                                      color: scheme
                                                          .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (note != null)
                                            TextButton.icon(
                                              key: ValueKey(
                                                'quiet-org-fix-${s.noteId}',
                                              ),
                                              style: TextButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: AppSpace.s,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              onPressed: () =>
                                                  _pickCategoryFix(note, local),
                                              icon: const Icon(
                                                Icons.tune_outlined,
                                                size: AppIconSize.s,
                                              ),
                                              label: Text(
                                                l10n.aiSmartFixAction,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                    if (s.tags.isNotEmpty) ...[
                                      const SizedBox(height: AppSpace.s),
                                      Wrap(
                                        spacing: AppSpace.xs,
                                        runSpacing: AppSpace.xs,
                                        children: [
                                          for (final tag in s.tags)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpace.s,
                                                    vertical: AppSpace.xxs,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    scheme.secondaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.s,
                                                    ),
                                              ),
                                              child: Text(
                                                '#$tag',
                                                style: text.badge.copyWith(
                                                  color: scheme
                                                      .onSecondaryContainer,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (!_aiRefined &&
                  _localById.values.any((c) => c.needsAiRefinement))
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.l,
                    AppSpace.xs,
                    AppSpace.l,
                    0,
                  ),
                  child: OutlinedButton.icon(
                    key: const ValueKey('quiet-org-refine-ai'),
                    onPressed: _applying ? null : () => _fetch(forceAi: true),
                    icon: const Icon(
                      Icons.auto_awesome_outlined,
                      size: AppIconSize.s,
                    ),
                    label: Text(l10n.aiSmartRefineWithAi),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                child: AiResultNote(
                  content: _suggestions
                      .map((s) => '${s.title ?? ''} ${s.tags.join(",")}')
                      .join('\n'),
                  source: 'quiet_organize',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.xs,
                  AppSpace.l,
                  AppSpace.l,
                ),
                child: FilledButton.icon(
                  key: const ValueKey('quiet-org-apply'),
                  onPressed: _applying || _selected.isEmpty ? null : _apply,
                  icon: const Icon(Icons.check, size: AppIconSize.s),
                  label: Text(l10n.aiQuietOrganizeApply(_selected.length)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
