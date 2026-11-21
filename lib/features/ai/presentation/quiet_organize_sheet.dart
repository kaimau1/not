import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/friendly_error.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../auth/presentation/account_required.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../data/ai_history.dart';
import '../data/gemini_service.dart';
import 'ai_result_note.dart';

/// Toplu "Sessiz düzen" (A8, PLAN §1.6) kapsamı.
enum QuietOrganizeScope { titles, tags, both }

/// Başlıksız ve/veya etiketsiz notları TEK istekte toplu düzenler.
/// Kullanıcı önerileri kutucuklarla seçip tek dokunuşla uygular; tek "Geri al"
/// tüm notları eski hâline döndürür.
Future<void> showQuietOrganizeSheet(
  BuildContext context, {
  QuietOrganizeScope scope = QuietOrganizeScope.both,
}) => showAppSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _QuietOrganizeSheet(initialScope: scope),
);

class _QuietOrganizeSheet extends ConsumerStatefulWidget {
  const _QuietOrganizeSheet({required this.initialScope});

  final QuietOrganizeScope initialScope;

  @override
  ConsumerState<_QuietOrganizeSheet> createState() =>
      _QuietOrganizeSheetState();
}

class _QuietOrganizeSheetState extends ConsumerState<_QuietOrganizeSheet> {
  late QuietOrganizeScope _scope;
  bool _loading = true;
  bool _applying = false;
  String? _error;
  List<QuietOrganizeSuggestion> _suggestions = const [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _scope = widget.initialScope;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetch();
    });
  }

  Future<void> _fetch() async {
    if (!ensureAiReady(context, ref)) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    setState(() {
      _loading = true;
      _error = null;
      _suggestions = const [];
      _selected.clear();
    });
    try {
      final results = await ref
          .read(geminiServiceProvider)
          .batchQuietOrganize(
            notes,
            suggestTitles:
                _scope == QuietOrganizeScope.titles ||
                _scope == QuietOrganizeScope.both,
            suggestTags:
                _scope == QuietOrganizeScope.tags ||
                _scope == QuietOrganizeScope.both,
          );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _selected
          ..clear()
          ..addAll(results.map((r) => r.noteId));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = aiErrorText(context.l10n, e);
        _loading = false;
      });
    }
  }

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
      final nextTitle =
          (s.title != null && current.title.trim().isEmpty)
          ? s.title!
          : current.title;
      final nextTags = (s.tags.isNotEmpty && current.tags.isEmpty)
          ? s.tags
          : current.tags;
      if (nextTitle == current.title &&
          _sameTags(nextTags, current.tags)) {
        continue;
      }
      updates.add((
        before: current,
        after: current.copyWith(title: nextTitle, tags: nextTags),
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
