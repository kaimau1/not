import '../../../app/app_frame.dart';
import '../../calendar/presentation/task_editor.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router.dart';
import '../../../core/error_log.dart';
import '../../../core/friendly_error.dart';
import '../../../core/l10n_ext.dart';
import '../../ai/data/gemini_service.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note_type.dart';
import '../data/gmail_api.dart';
import '../data/gmail_auth.dart';
import '../domain/gmail_note.dart';
import '../../auth/presentation/account_required.dart';

/// **GMAIL** (F28.1): gelen kutusu + arama, e-postayı nota kaydet, AI ile
/// özet / görev listesi. YALNIZ OKUMA — Gmail'de hiçbir şey değişmez.
class GmailScreen extends ConsumerStatefulWidget {
  const GmailScreen({super.key});

  @override
  ConsumerState<GmailScreen> createState() => _GmailScreenState();
}

class _GmailScreenState extends ConsumerState<GmailScreen> {
  final _search = TextEditingController();
  final _items = <GmailSummary>[];
  String? _next;
  bool _loading = false;
  bool _needsConnect = false;
  Object? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    final session = ref.read(gmailSessionProvider);
    if (session == null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _next = null;
      }
    });
    try {
      // Jeton yoksa (hiç bağlanmamış) liste isteği atılmaz: "Bağlan" kartı.
      if (await session.tokens.get() == null) {
        if (mounted) setState(() => _needsConnect = true);
        return;
      }
      final page = await session.api.list(
        query: _query,
        pageToken: reset ? null : _next,
      );
      if (!mounted) return;
      setState(() {
        _needsConnect = false;
        _items.addAll(page.items);
        _next = page.next;
      });
    } on GmailApiException catch (e) {
      if (!mounted) return;
      setState(() => e.unauthorized ? _needsConnect = true : _error = e);
    } catch (e) {
      ErrorLog.record('gmail-list', e);
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connect() async {
    final session = ref.read(gmailSessionProvider);
    if (session == null) return;
    try {
      final r = await session.auth.connect();
      if (r == null) return;
      session.tokens.put(r.token, r.expiry);
      await _load(reset: true);
    } catch (e) {
      ErrorLog.record('gmail-connect', e);
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final available = ref.watch(gmailAvailableProvider);
    return Scaffold(
      appBar: HomeInBar(appBar: AppBar(title: Text(l10n.gmailTitle))),
      body: !available
          ? _Message(icon: Icons.mail_lock_outlined, text: l10n.gmailGoogleOnly)
          : _needsConnect
          ? _ConnectCard(onConnect: _connect)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: SearchBar(
                    controller: _search,
                    hintText: l10n.gmailSearchHint,
                    leading: const Icon(Icons.search),
                    onSubmitted: (q) {
                      _query = q;
                      unawaited(_load(reset: true));
                    },
                  ),
                ),
                if (_error != null)
                  ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(l10n.gmailError),
                    subtitle: Text(friendlyError(l10n, _error!)),
                    trailing: TextButton(
                      onPressed: () => _load(reset: _items.isEmpty),
                      child: Text(l10n.retry),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    child: _items.isEmpty && !_loading && _error == null
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              _Message(
                                icon: Icons.inbox_outlined,
                                text: l10n.gmailEmpty,
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount:
                                _items.length +
                                (_loading || _next != null ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == _items.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Center(
                                    child: _loading
                                        ? const CircularProgressIndicator()
                                        : TextButton(
                                            onPressed: _load,
                                            child: Text(l10n.gmailLoadMore),
                                          ),
                                  ),
                                );
                              }
                              final m = _items[i];
                              return ListTile(
                                title: Text(
                                  m.subject.isEmpty ? '—' : m.subject,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${m.from} · ${m.snippet}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: m.hasAttachments
                                    ? const Icon(Icons.attach_file, size: 18)
                                    : null,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        GmailMessageScreen(id: m.id),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({required this.onConnect});
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mail_outline, size: 48),
            const SizedBox(height: 12),
            Text(l10n.gmailReadOnlyHint, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.link),
              label: Text(l10n.gmailConnect),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek e-posta: gövde + "Nota kaydet" / "AI özetiyle not" / "Görev listesi".
class GmailMessageScreen extends ConsumerStatefulWidget {
  const GmailMessageScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<GmailMessageScreen> createState() => _GmailMessageScreenState();
}

enum _SaveMode { plain, summary, tasks }

class _GmailMessageScreenState extends ConsumerState<GmailMessageScreen> {
  GmailMessage? _message;
  Object? _error;
  bool _busy = false;
  bool _withAttachments = true;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final session = ref.read(gmailSessionProvider);
    if (session == null) return;
    try {
      final m = await session.api.message(widget.id);
      if (mounted) setState(() => _message = m);
    } catch (e) {
      ErrorLog.record('gmail-open', e);
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save(_SaveMode mode) async {
    final m = _message;
    final repo = ref.read(notesRepositoryProvider);
    final session = ref.read(gmailSessionProvider);
    if (m == null || repo == null || session == null || _busy) return;
    if (mode != _SaveMode.plain && !ensureAiReady(context, ref)) return;
    final l10n = context.l10n;
    final router = ref.read(routerProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      String id;
      if (mode == _SaveMode.plain) {
        final d = noteDraftFromEmail(m);
        id = await repo.createNote(NoteType.text, title: d.title, body: d.body);
      } else {
        final ai = await ref
            .read(geminiServiceProvider)
            .fromEmail(m.subject, m.body, tasks: mode == _SaveMode.tasks);
        final items = mode == _SaveMode.tasks
            ? taskItemsFromAi(ai)
            : const <String>[];
        if (items.isNotEmpty) {
          final d = noteDraftFromEmail(m, replacementBody: '');
          id = await repo.createNote(
            NoteType.checklist,
            title: d.title,
            body: d.body,
            items: items,
          );
        } else {
          final d = noteDraftFromEmail(m, replacementBody: ai);
          id = await repo.createNote(
            NoteType.text,
            title: d.title,
            body: d.body,
          );
        }
      }
      if (_withAttachments) await _attach(id, m, session.api, repo);
      messenger.showSnackBar(SnackBar(content: Text(l10n.gmailNoteCreated)));
      unawaited(router.pushNote(noteRoutePath(id)));
    } on GeminiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(aiErrorText(l10n, e))));
    } catch (e) {
      ErrorLog.record('gmail-save', e);
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(l10n, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Görsel ve PDF ekleri nota katılır (öbür türler atlanır — kaynak
  /// bağlantısı notta). Tek ek başarısızsa not yine durur.
  Future<void> _attach(
    String noteId,
    GmailMessage m,
    GmailApi api,
    NotesRepository repo,
  ) async {
    final attachRepo = ref.read(attachmentRepositoryProvider);
    if (attachRepo == null) return;
    final prepared = <Attachment>[];
    for (final a in m.attachments) {
      final image = a.mimeType.startsWith('image/');
      final pdf = a.mimeType == 'application/pdf';
      if (!image && !pdf) continue;
      try {
        final bytes = await api.attachment(m.id, a.attachmentId);
        prepared.add(
          pdf
              ? await attachRepo.preparePdf(
                  noteId: noteId,
                  bytes: bytes,
                  fileName: a.fileName,
                )
              : (await attachRepo.prepareImage(
                  noteId: noteId,
                  bytes: bytes,
                  fileName: a.fileName,
                )).copyWith(asFile: true),
        );
      } catch (e) {
        ErrorLog.record('gmail-attachment', e);
      }
    }
    if (prepared.isNotEmpty) {
      await repo
          .appendAttachments(noteId, prepared)
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final m = _message;
    return Scaffold(
      appBar: HomeInBar(appBar: AppBar(
        title: Text(
          m?.subject ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      )),
      body: _error != null
          ? _Message(
              icon: Icons.error_outline,
              text: friendlyError(l10n, _error!),
            )
          : m == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(m.from, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                SelectableText(m.body),
                if (m.attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  for (final a in m.attachments)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.attach_file),
                      title: Text(a.fileName),
                    ),
                  SwitchListTile(
                    value: _withAttachments,
                    onChanged: (v) => setState(() => _withAttachments = v),
                    title: Text(l10n.gmailWithAttachments),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
      bottomNavigationBar: m == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _busy
                    ? const LinearProgressIndicator()
                    : Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _save(_SaveMode.plain),
                            icon: const Icon(Icons.note_add_outlined),
                            label: Text(l10n.gmailSaveNote),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _save(_SaveMode.summary),
                            icon: const AiIcon(),
                            label: Text(l10n.gmailAiSummary),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _save(_SaveMode.tasks),
                            icon: const Icon(Icons.checklist),
                            label: Text(l10n.gmailAiTasks),
                          ),
                          // E-postadan görev (TAKVIM F52.3): başlık konu,
                          // ayrıntıda iletinin Gmail bağlantısı.
                          OutlinedButton.icon(
                            key: const ValueKey('gmail-task'),
                            onPressed: () => unawaited(
                              showTaskEditor(
                                context,
                                initialTitle: m.subject.trim(),
                                initialNotes: m.webUrl,
                              ),
                            ),
                            icon: const Icon(Icons.add_task),
                            label: Text(l10n.itemMenuTask),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}
