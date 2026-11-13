import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_frame.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/router.dart';
import '../../../core/error_log.dart';
import '../../../core/friendly_error.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/gemini_service.dart';
import '../../auth/data/google_scope_auth.dart' show chooseGoogleAccount;
import '../../auth/presentation/account_required.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../calendar/presentation/event_editor.dart';
import '../../calendar/presentation/task_editor.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/note_link_ui.dart' show noteLinkLabel;
import '../../notes/presentation/note_target_picker.dart';
import '../data/gmail_api.dart';
import '../data/gmail_auth.dart';
import '../domain/gmail_note.dart';
import '../domain/gmail_smart.dart';
import '../../../core/widgets/delayed_spinner.dart';

/// **GMAIL** (F28.1; ekran BAŞTAN yazıldı 2026-11-06, kullanıcı isteği
/// "Gmail ekranının yeniden yazılması"): üstte arama + hızlı süzgeç çipleri
/// (Gelen, Okunmamış, Yıldızlı, Ekli, Bugün), liste tarih kümeleriyle
/// (Bugün / Dün / Bu hafta / Daha eski), satırda gönderen avatarı, okunmamış
/// kalın + nokta, sonda otomatik sayfa yükleme. YALNIZ OKUMA — Gmail'de
/// hiçbir şey değişmez (okundu işareti bile).
class GmailScreen extends ConsumerStatefulWidget {
  const GmailScreen({super.key});

  @override
  ConsumerState<GmailScreen> createState() => _GmailScreenState();
}

class _GmailScreenState extends ConsumerState<GmailScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _items = <GmailSummary>[];
  String? _next;
  bool _loading = false;
  bool _needsConnect = false;
  bool _loadedOnce = false;
  Object? _error;
  GmailFilter _filter = GmailFilter.inbox;

  /// Yarışan isteklerde yalnız sonuncusu listeyi yazar (süzgeç hızlı
  /// değiştirilince eski sayfa yenisinin üstüne eklenmesin).
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_loading || _next == null || _error != null) return;
    final p = _scroll.position;
    if (p.pixels > p.maxScrollExtent - 600) unawaited(_load());
  }

  Future<void> _load({bool reset = false}) async {
    final session = ref.read(gmailSessionProvider);
    if (session == null) return;
    if (_loading && !reset) return;
    final gen = ++_generation;
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
        if (mounted && gen == _generation) {
          setState(() => _needsConnect = true);
        }
        return;
      }
      final page = await session.api.list(
        query: gmailQuery(_filter, _search.text),
        pageToken: reset ? null : _next,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _needsConnect = false;
        _items.addAll(page.items);
        _next = page.next;
      });
    } on GmailApiException catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() => e.unauthorized ? _needsConnect = true : _error = e);
    } catch (e) {
      ErrorLog.record('gmail-list', e);
      if (mounted && gen == _generation) setState(() => _error = e);
    } finally {
      if (mounted && gen == _generation) {
        setState(() {
          _loading = false;
          _loadedOnce = true;
        });
      }
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

  void _setFilter(GmailFilter f) {
    if (f == _filter) return;
    setState(() => _filter = f);
    unawaited(_load(reset: true));
  }

  void _open(GmailSummary m) => unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GmailMessageScreen(id: m.id, summary: m),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final available = ref.watch(gmailAvailableProvider);
    return Scaffold(
      appBar: HomeInBar(
        appBar: AppBar(
          title: Text(l10n.gmailTitle),
          actions: [
            if (available && gmailMultiAccount)
              _AccountButton(onChanged: () => _load(reset: true)),
            if (available && !_needsConnect)
              IconButton(
                key: const ValueKey('gmail-refresh'),
                tooltip: l10n.gmailRefresh,
                onPressed: _loading ? null : () => _load(reset: true),
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
      ),
      body: !available
          ? EmptyState(
              icon: Icons.mail_lock_outlined,
              title: l10n.gmailGoogleOnly,
            )
          : _needsConnect
          ? _ConnectView(onConnect: _connect, error: _error)
          : Column(
              children: [
                _SearchHeader(
                  controller: _search,
                  filter: _filter,
                  onSubmit: () => _load(reset: true),
                  onFilter: _setFilter,
                ),
                Expanded(child: _list(context)),
              ],
            ),
    );
  }

  Widget _list(BuildContext context) {
    final l10n = context.l10n;
    if (_items.isEmpty) {
      if (_error != null) {
        return ErrorState(error: _error!, onRetry: () => _load(reset: true));
      }
      if (_loading || !_loadedOnce) return const _InboxSkeleton();
      return RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 64),
            EmptyState(
              key: const ValueKey('gmail-empty'),
              icon: Icons.inbox_outlined,
              title: _search.text.trim().isEmpty
                  ? l10n.gmailEmpty
                  : l10n.gmailNoResults,
            ),
          ],
        ),
      );
    }
    // Satırlar + tarih kümesi başlıkları tek düz listede.
    final now = DateTime.now();
    final rows = <Object>[];
    GmailDay? last;
    for (final m in _items) {
      final day = gmailDayOf(m.date, now);
      if (day != last) {
        rows.add(day);
        last = day;
      }
      rows.add(m);
    }
    final footer = _loading || _next != null || _error != null;
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        key: const ValueKey('gmail-list'),
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: rows.length + (footer ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == rows.length) {
            return _ListFooter(
              loading: _loading,
              error: _error,
              onMore: _load,
            );
          }
          final row = rows[i];
          if (row is GmailDay) return _DayHeader(day: row);
          final m = row as GmailSummary;
          return _MailRow(mail: m, onTap: () => _open(m));
        },
      ),
    );
  }
}

/// Arama kutusu + süzgeç çipleri.
class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.filter,
    required this.onSubmit,
    required this.onFilter,
  });

  final TextEditingController controller;
  final GmailFilter filter;
  final VoidCallback onSubmit;
  final ValueChanged<GmailFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(GmailFilter f) => switch (f) {
      GmailFilter.inbox => l10n.gmailFilterInbox,
      GmailFilter.unread => l10n.gmailFilterUnread,
      GmailFilter.starred => l10n.gmailFilterStarred,
      GmailFilter.attachments => l10n.gmailFilterAttachments,
      GmailFilter.today => l10n.gmailFilterToday,
    };
    IconData icon(GmailFilter f) => switch (f) {
      GmailFilter.inbox => Icons.inbox_outlined,
      GmailFilter.unread => Icons.mark_email_unread_outlined,
      GmailFilter.starred => Icons.star_outline,
      GmailFilter.attachments => Icons.attach_file,
      GmailFilter.today => Icons.today_outlined,
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => SearchBar(
              key: const ValueKey('gmail-search'),
              controller: controller,
              hintText: l10n.gmailSearchHint,
              elevation: const WidgetStatePropertyAll(0),
              leading: const Icon(Icons.search),
              textInputAction: TextInputAction.search,
              trailing: [
                if (value.text.isNotEmpty)
                  IconButton(
                    tooltip: l10n.clear,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clear();
                      onSubmit();
                    },
                  ),
              ],
              onSubmitted: (_) => onSubmit(),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final f in GmailFilter.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: FilterChip(
                    key: ValueKey('gmail-filter-${f.name}'),
                    avatar: Icon(icon(f), size: 18),
                    showCheckmark: false,
                    label: Text(label(f)),
                    selected: filter == f,
                    onSelected: (_) => onFilter(f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});
  final GmailDay day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = switch (day) {
      GmailDay.today => l10n.gmailDayToday,
      GmailDay.yesterday => l10n.gmailDayYesterday,
      GmailDay.thisWeek => l10n.gmailDayThisWeek,
      GmailDay.older => l10n.gmailDayOlder,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: SectionLabel(text),
    );
  }
}

/// Gönderen adından kararlı bir avatar rengi (temanın kap renklerinden).
Color _avatarColor(ColorScheme s, String from) {
  final palette = [
    s.primaryContainer,
    s.secondaryContainer,
    s.tertiaryContainer,
    s.surfaceContainerHighest,
  ];
  return palette[from.hashCode.abs() % palette.length];
}

Color _onAvatar(ColorScheme s, Color bg) {
  if (bg == s.primaryContainer) return s.onPrimaryContainer;
  if (bg == s.secondaryContainer) return s.onSecondaryContainer;
  if (bg == s.tertiaryContainer) return s.onTertiaryContainer;
  return s.onSurface;
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.from, this.size = 40});
  final String from;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final bg = _avatarColor(s, from);
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: bg,
        child: Text(
          senderInitial(from),
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w600,
            color: _onAvatar(s, bg),
          ),
        ),
      ),
    );
  }
}

/// Listede saat (bugün), gün + ay (bu yıl) ya da tam tarih.
String _shortDate(BuildContext context, DateTime? d) {
  if (d == null) return '';
  final locale = Localizations.localeOf(context).toLanguageTag();
  final now = DateTime.now();
  if (gmailDayOf(d, now) == GmailDay.today) {
    return DateFormat.Hm(locale).format(d);
  }
  if (d.year == now.year) return DateFormat.MMMd(locale).format(d);
  return DateFormat.yMd(locale).format(d);
}

class _MailRow extends StatelessWidget {
  const _MailRow({required this.mail, required this.onTap});
  final GmailSummary mail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final l10n = context.l10n;
    final strong = mail.unread ? AppWeight.strong : FontWeight.w500;
    final subject = mail.subject.trim().isEmpty
        ? l10n.gmailNoSubject
        : mail.subject.trim();
    final date = _shortDate(context, mail.date);
    return Semantics(
      button: true,
      label: [
        if (mail.unread) l10n.gmailFilterUnread,
        displayFrom(mail.from),
        subject,
        date,
      ].join(', '),
      excludeSemantics: true,
      // Tema belirteçleriyle kâğıt kart (TEMA_PLANI): okunmamış satırın
      // çerçevesi vurgu renginde, okunmuş sönük.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 3, 12, 3),
        child: Material(
          color: AppTokens.of(context).card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.of(context).cardRadius),
            side: BorderSide(
              color: mail.unread
                  ? s.primary.withValues(alpha: 0.45)
                  : AppTokens.of(context).hairline,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
        key: ValueKey('gmail-row-${mail.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SenderAvatar(from: mail.from),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayFrom(mail.from),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: strong,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: mail.unread ? s.primary : s.onSurfaceVariant,
                            fontWeight: mail.unread ? AppWeight.strong : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: strong,
                        color: s.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mail.snippet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: s.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (mail.hasAttachments) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: s.onSurfaceVariant,
                          ),
                        ],
                        if (mail.starred) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 16, color: s.tertiary),
                        ],
                        if (mail.unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: s.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (mail.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final t in mail.tags) _TagChip(tag: t),
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
        ),
      ),
    );
  }
}

/// Gmail kategori/önem etiketi çipi (liste satırında).
class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});
  final String tag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = Theme.of(context).colorScheme;
    final label = switch (tag) {
      'important' => l10n.gmailTagImportant,
      'promotions' => l10n.gmailTagPromotions,
      'social' => l10n.gmailTagSocial,
      'updates' => l10n.gmailTagUpdates,
      _ => l10n.gmailTagForums,
    };
    final important = tag == 'important';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: important ? s.tertiaryContainer : s.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: important ? s.onTertiaryContainer : s.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.loading,
    required this.error,
    required this.onMore,
  });

  final bool loading;
  final Object? error;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : error != null
            ? Column(
                children: [
                  Text(
                    friendlyError(l10n, error!),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: onMore,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              )
            : TextButton(onPressed: onMore, child: Text(l10n.gmailLoadMore)),
      ),
    );
  }
}

/// İlk yüklemede satır biçiminde iskelet (boş beyaz ekran yerine).
class _InboxSkeleton extends StatelessWidget {
  const _InboxSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return ListView.builder(
      key: const ValueKey('gmail-skeleton'),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 20, backgroundColor: c),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(120 + (i % 3) * 30, 12),
                  const SizedBox(height: 8),
                  bar(double.infinity, 10),
                  const SizedBox(height: 6),
                  bar(180, 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bağlan ekranı: ne yapılır, ne YAPILMAZ (yalnız okuma) ve tek düğme.
class _ConnectView extends StatelessWidget {
  const _ConnectView({required this.onConnect, this.error});
  final VoidCallback onConnect;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: s.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: s.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 44,
                  color: s.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.gmailConnectTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              point(Icons.search, l10n.gmailConnectPointRead),
              point(Icons.note_add_outlined, l10n.gmailConnectPointNote),
              point(Icons.lock_outline, l10n.gmailReadOnlyHint),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  friendlyError(l10n, error!),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: s.error),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('gmail-connect'),
                  onPressed: onConnect,
                  icon: const Icon(Icons.link),
                  label: Text(l10n.gmailConnect),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tek e-posta: üstte konu + gönderen kartı, ekler çip olarak, gövde
/// seçilebilir; altta eylem çubuğu (Nota kaydet · AI özet · Görev listesi ·
/// Görev).
class GmailMessageScreen extends ConsumerStatefulWidget {
  const GmailMessageScreen({super.key, required this.id, this.summary});
  final String id;

  /// Listeden gelen özet: gövde inerken başlık hemen görünsün.
  final GmailSummary? summary;

  @override
  ConsumerState<GmailMessageScreen> createState() => _GmailMessageScreenState();
}

enum _SaveMode { plain, summary, tasks }

class _GmailMessageScreenState extends ConsumerState<GmailMessageScreen> {
  GmailMessage? _message;
  Object? _error;
  _SaveMode? _busy;
  bool _withAttachments = true;

  /// Gövdede seçili yazı (boş = seçim yok).
  final _selected = ValueNotifier<String>('');

  /// ÇEVİRİ (kullanıcı isteği 2026-11-08: "Gmail'deki çeviri"): Gmail'in
  /// "İletiyi çevir / Orijinali göster" davranışı — çeviri bir kez yapılır,
  /// iki görünüm arasında geçilir. null = çevrilmedi.
  String? _translated;
  bool _showTranslated = false;
  bool _translating = false;

  Future<void> _toggleTranslate() async {
    final m = _message;
    if (m == null || _translating) return;
    if (_translated != null) {
      setState(() => _showTranslated = !_showTranslated);
      return;
    }
    if (!ensureAiReady(context, ref)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final language = Localizations.localeOf(context).languageCode == 'tr'
        ? 'Türkçe'
        : 'English';
    setState(() => _translating = true);
    try {
      final out = await ref
          .read(geminiServiceProvider)
          .translateText(m.body, language);
      if (!mounted) return;
      setState(() {
        _translated = out.trim();
        _showTranslated = true;
      });
    } catch (e) {
      ErrorLog.record('gmail-translate', e);
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyError(l10n, e))),
      );
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  void dispose() {
    _selected.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final session = ref.read(gmailSessionProvider);
    if (session == null) return;
    setState(() => _error = null);
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
    if (m == null || repo == null || session == null || _busy != null) return;
    if (mode != _SaveMode.plain && !ensureAiReady(context, ref)) return;
    final l10n = context.l10n;
    final router = ref.read(routerProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = mode);
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
      messenger.showMessage(l10n.gmailNoteCreated);
      unawaited(router.pushNote(noteRoutePath(id)));
    } on GeminiException catch (e) {
      messenger.showMessage(aiErrorText(l10n, e));
    } catch (e) {
      ErrorLog.record('gmail-save', e);
      messenger.showMessage(friendlyError(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = null);
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

  /// Seçili metni (ya da akıllı bağlantının satırını) "Nota ekle" ekranıyla
  /// seçilen nota — ya da yeni nota — yazar, sonra notu açar. Metne kaynak
  /// satırı (kimden, tarih, Gmail bağlantısı) eşlik eder: mail ↔ not bağı.
  Future<void> _addTextToNote(String text) async {
    final m = _message;
    final repo = ref.read(notesRepositoryProvider);
    if (m == null || repo == null || text.trim().isEmpty) return;
    final target = await showNoteTargetPicker(context, preview: text);
    if (target == null || !mounted) return;
    final l10n = context.l10n;
    final router = ref.read(routerProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final draft = noteDraftFromEmail(m, replacementBody: text.trim());
      final String id;
      final picked = target.note;
      if (picked == null) {
        id = await repo.createNote(
          NoteType.text,
          title: draft.title,
          body: draft.body,
        );
      } else {
        final note = await hydrateNote(ref, picked);
        final old = note.body.trimRight();
        await repo.updateNote(
          note.copyWith(
            body: old.isEmpty ? draft.body : '$old\n\n${draft.body}',
          ),
        );
        id = note.id;
      }
      messenger.showMessage(l10n.gmailAddedToNote);
      unawaited(router.pushNote(noteRoutePath(id)));
    } catch (e) {
      ErrorLog.record('gmail-add-to-note', e);
      messenger.showMessage(friendlyError(l10n, e));
    }
  }

  /// Bu iletiden oluşmuş notlar: gövdelerinde iletinin Gmail bağlantısı var.
  List<Note> _relatedNotes(GmailMessage m) => [
    for (final n in ref.watch(notesStreamProvider).value ?? const <Note>[])
      if (n.deletedAt == null && n.body.contains(m.webUrl)) n,
  ];

  /// AKILLI BAĞLANTILAR: gövdedeki tarih/saat → takvime ekle; gönderen →
  /// bir nota bağla; iletiden oluşmuş not → aç.
  Widget _smartLinks(BuildContext context, GmailMessage m) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dates = findSmartDates(m.body, m.date ?? DateTime.now());
    final sender = parseSender(m.from);
    final related = _relatedNotes(m);
    if (dates.isEmpty && sender == null && related.isEmpty) {
      return const SizedBox.shrink();
    }
    Widget chip(Key key, IconData icon, String label, VoidCallback onTap) =>
        ActionChip(
          key: key,
          avatar: Icon(icon, size: 18),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          onPressed: onTap,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final n in related)
            chip(
              ValueKey('gmail-related-${n.id}'),
              Icons.sticky_note_2_outlined,
              l10n.gmailSmartRelatedNote(
                noteLinkLabel(n, l10n.remindersUntitled),
              ),
              () => unawaited(
                ref.read(routerProvider).pushNote(noteRoutePath(n.id)),
              ),
            ),
          for (final d in dates)
            chip(
              ValueKey('gmail-date-${d.when.toIso8601String()}'),
              Icons.event_outlined,
              l10n.gmailSmartAddToCalendar(
                d.hasTime
                    ? DateFormat.MMMd(locale).add_Hm().format(d.when)
                    : DateFormat.MMMd(locale).format(d.when),
              ),
              () => unawaited(
                showEventEditor(
                  context,
                  day: d.when,
                  start: d.hasTime ? d.when : null,
                  initialTitle: m.subject.trim(),
                  initialDescription: m.webUrl,
                ),
              ),
            ),
          if (sender != null)
            chip(
              const ValueKey('gmail-link-person'),
              Icons.person_add_alt_outlined,
              l10n.gmailSmartLinkPerson(
                sender.name.isEmpty ? sender.email : sender.name,
              ),
              () => unawaited(
                _addTextToNote(
                  '👤 ${sender.name.isEmpty ? sender.email : '${sender.name} <${sender.email}>'}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final m = _message;
    final subject = (m?.subject ?? widget.summary?.subject ?? '').trim();
    final from = m?.from ?? widget.summary?.from ?? '';
    final date = m?.date ?? widget.summary?.date;
    return Scaffold(
      appBar: HomeInBar(
        appBar: AppBar(
          actions: [
            if (m != null && m.body.trim().isNotEmpty)
              IconButton(
                key: const ValueKey('gmail-translate'),
                tooltip: _showTranslated
                    ? l10n.gmailShowOriginal
                    : l10n.gmailTranslate,
                isSelected: _showTranslated,
                icon: _translating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate),
                onPressed: () => unawaited(_toggleTranslate()),
              ),
            if (m != null)
              IconButton(
                key: const ValueKey('gmail-open-web'),
                tooltip: l10n.gmailOpenInGmail,
                icon: const Icon(Icons.open_in_new),
                onPressed: () => unawaited(
                  launchUrl(
                    Uri.parse(m.webUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          SelectableText(
            subject.isEmpty ? l10n.gmailNoSubject : subject,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SenderAvatar(from: from, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayFrom(from),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (date != null)
                      Text(
                        DateFormat.yMMMMd(
                          Localizations.localeOf(context).toLanguageTag(),
                        ).add_Hm().format(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: s.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            ErrorState(error: _error!, onRetry: _open)
          else if (m == null)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: DelayedSpinner()),
            )
          else ...[
            if (m.attachments.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in m.attachments)
                    Chip(
                      avatar: Icon(
                        a.mimeType == 'application/pdf'
                            ? Icons.picture_as_pdf_outlined
                            : a.mimeType.startsWith('image/')
                            ? Icons.image_outlined
                            : Icons.attach_file,
                        size: 18,
                      ),
                      label: Text(
                        a.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                key: const ValueKey('gmail-with-attachments'),
                contentPadding: EdgeInsets.zero,
                value: _withAttachments,
                onChanged: (v) => setState(() => _withAttachments = v),
                title: Text(l10n.gmailWithAttachments),
              ),
              const Divider(),
            ],
            _smartLinks(context, m),
            const SizedBox(height: 8),
            // Metin seçilebilir; seçim menüsünde "Nota ekle" ile seçilen
            // kısım nota aktarılır (bkz. [showNoteTargetPicker]).
            // BAĞLANTILAR TIKLANIR (kullanıcı isteği 2026-11-08): seçim
            // [SelectionArea] ile — `Text.rich` dokunma tanıyıcıları orada
            // çalışır; seçilen yazı alttaki "Nota ekle" düğmesini açar.
            if (_showTranslated && _translated != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.translate, size: 16, color: s.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.gmailTranslated,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showTranslated = false),
                      child: Text(l10n.gmailShowOriginal),
                    ),
                  ],
                ),
              ),
            SelectionArea(
              onSelectionChanged: (c) =>
                  _selected.value = c?.plainText.trim() ?? '',
              contextMenuBuilder: (context, state) =>
                  AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: state.contextMenuAnchors,
                    buttonItems: [
                      ...state.contextMenuButtonItems,
                      if (_selected.value.isNotEmpty)
                        ContextMenuButtonItem(
                          label: l10n.gmailAddSelectionToNote,
                          onPressed: () {
                            state.hideToolbar();
                            unawaited(_addTextToNote(_selected.value));
                          },
                        ),
                    ],
                  ),
              child: Text.rich(
                TextSpan(
                  children: _showTranslated && _translated != null
                      ? [TextSpan(text: _translated)]
                      : linkifyMail(
                    m.body,
                    m.links,
                    linkStyle: TextStyle(
                      color: s.primary,
                      decoration: TextDecoration.underline,
                    ),
                    onOpen: (url) => unawaited(
                      launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
            // GÖRSELLER (2026-11-08): HTML'deki uzak görseller + resim ekleri;
            // dokununca tam ekran.
            _MailImages(message: m, api: ref.read(gmailSessionProvider)?.api),
          ],
        ],
      ),
      bottomNavigationBar: m == null
          ? null
          : ValueListenableBuilder<String>(
              valueListenable: _selected,
              builder: (context, sel, actions) => sel.isEmpty
                  ? actions!
                  // SEÇİLİ YAZIYI NOTA EKLE altta düğme (kullanıcı isteği
                  // 2026-11-08): seçim menüsünü aramaya gerek kalmasın.
                  : Material(
                      color: s.surfaceContainer,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: FilledButton.icon(
                            key: const ValueKey('gmail-add-selection'),
                            icon: const Icon(Icons.note_add_outlined),
                            label: Text(l10n.gmailAddSelectionToNote),
                            onPressed: () =>
                                unawaited(_addTextToNote(sel)),
                          ),
                        ),
                      ),
                    ),
              child: _actions(context, m),
            ),
    );
  }

  Widget _actions(BuildContext context, GmailMessage m) {
    final l10n = context.l10n;
    final s = Theme.of(context).colorScheme;
    Widget action({
      required Key key,
      required Widget icon,
      required String label,
      required VoidCallback onTap,
      _SaveMode? mode,
    }) {
      final busy = mode != null && _busy == mode;
      return Expanded(
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(AppRadius.l),
          onTap: _busy != null ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconTheme(
                          data: IconThemeData(color: s.onSurface),
                          child: icon,
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: s.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              action(
                key: const ValueKey('gmail-save'),
                icon: const Icon(Icons.note_add_outlined),
                label: l10n.gmailSaveNote,
                mode: _SaveMode.plain,
                onTap: () => _save(_SaveMode.plain),
              ),
              action(
                key: const ValueKey('gmail-ai-summary'),
                icon: const AiIcon(),
                label: l10n.gmailAiSummary,
                mode: _SaveMode.summary,
                onTap: () => _save(_SaveMode.summary),
              ),
              action(
                key: const ValueKey('gmail-ai-tasks'),
                icon: const Icon(Icons.checklist),
                label: l10n.gmailAiTasks,
                mode: _SaveMode.tasks,
                onTap: () => _save(_SaveMode.tasks),
              ),
              // E-postadan görev (TAKVIM F52.3): başlık konu, ayrıntıda
              // iletinin Gmail bağlantısı.
              action(
                key: const ValueKey('gmail-task'),
                icon: const Icon(Icons.add_task),
                label: l10n.itemMenuTask,
                onTap: () => unawaited(
                  showTaskEditor(
                    context,
                    initialTitle: m.subject.trim(),
                    initialNotes: m.webUrl,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gövdeyi bağlantılı parçalara böler: çıplak `http(s)://` adresleri ve
/// HTML'den gelen `<a>` yazıları ([links]) tıklanır olur.
///
/// ponytail: her yazının ilk geçtiği yer bağlanır (aynı yazı iki farklı
/// adrese gidiyorsa ilki kazanır).
@visibleForTesting
List<InlineSpan> linkifyMail(
  String body,
  List<({String label, String url})> links, {
  required TextStyle linkStyle,
  required void Function(String url) onOpen,
}) {
  final marks = <({int start, int end, String url})>[];
  for (final m in RegExp(r'https?://[^\s<>()"]+').allMatches(body)) {
    var end = m.end;
    while (end > m.start && '.,;:!?'.contains(body[end - 1])) {
      end--;
    }
    marks.add((start: m.start, end: end, url: body.substring(m.start, end)));
  }
  bool overlaps(int a, int b) => marks.any((k) => a < k.end && b > k.start);
  for (final l in links) {
    final i = body.indexOf(l.label);
    if (i >= 0 && !overlaps(i, i + l.label.length)) {
      marks.add((start: i, end: i + l.label.length, url: l.url));
    }
  }
  marks.sort((a, b) => a.start.compareTo(b.start));
  final spans = <InlineSpan>[];
  var at = 0;
  for (final k in marks) {
    if (k.start < at) continue;
    if (k.start > at) spans.add(TextSpan(text: body.substring(at, k.start)));
    spans.add(
      TextSpan(
        text: body.substring(k.start, k.end),
        style: linkStyle,
        recognizer: TapGestureRecognizer()..onTap = () => onOpen(k.url),
      ),
    );
    at = k.end;
  }
  if (at < body.length) spans.add(TextSpan(text: body.substring(at)));
  return spans;
}

/// ponytail: oturum boyu sınırsız; çok e-posta açılırsa LRU'ya çevir.
final _imageCache = <String, Future<Uint8List>>{};

/// E-postanın görselleri: HTML'deki uzak adresler + resim ekleri (indirilir).
class _MailImages extends StatelessWidget {
  const _MailImages({required this.message, required this.api});

  final GmailMessage message;
  final GmailApi? api;

  void _open(BuildContext context, ImageProvider image) => unawaited(
    showDialog<void>(
      context: context,
      builder: (c) => GestureDetector(
        onTap: () => Navigator.pop(c),
        child: InteractiveViewer(child: Image(image: image)),
      ),
    ),
  );

  Widget _thumb(BuildContext context, ImageProvider image) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: InkWell(
        onTap: () => _open(context, image),
        child: Image(
          image: image,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final api = this.api;
    final files = [
      if (api != null)
        for (final a in message.attachments)
          if (a.mimeType.startsWith('image/') && a.size < 8 * 1024 * 1024) a,
    ];
    if (_imageCache.length > 24) _imageCache.clear();
    if (message.imageUrls.isEmpty && files.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 160,
        child: ListView(
          key: const ValueKey('gmail-images'),
          scrollDirection: Axis.horizontal,
          children: [
            for (final f in files)
              FutureBuilder<Uint8List>(
                future: _imageCache.putIfAbsent(
                  f.attachmentId,
                  () => api!.attachment(message.id, f.attachmentId),
                ),
                builder: (context, snap) => snap.hasData
                    ? _thumb(context, MemoryImage(snap.data!))
                    : const SizedBox(
                        width: 120,
                        child: Center(child: DelayedSpinner()),
                      ),
              ),
            for (final url in message.imageUrls)
              _thumb(context, NetworkImage(url)),
          ],
        ),
      ),
    );
  }
}

/// Sağ üstte etkin hesabın baş harfi; dokununca Google'ın hesap menüsü gibi
/// levha: hesaplar (seçili ✓), "Başka hesap ekle", ek hesabı kaldır.
class _AccountButton extends ConsumerWidget {
  const _AccountButton({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final primary = ref.watch(authStateProvider).value?.email;
    final accounts = ref.watch(gmailAccountsProvider);
    final active = accounts.active ?? primary ?? '?';
    final notifier = ref.read(gmailAccountsProvider.notifier);
    void done(VoidCallback change) {
      change();
      onChanged();
    }

    Widget avatar(String email, {double r = 16}) => CircleAvatar(
      radius: r,
      child: Text(
        email.isEmpty ? '?' : email[0].toUpperCase(),
        style: TextStyle(fontSize: r),
      ),
    );

    return IconButton(
      key: const ValueKey('gmail-account'),
      tooltip: active,
      icon: avatar(active, r: 14),
      onPressed: () => unawaited(
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final email in [?primary, ...accounts.extra])
                  ListTile(
                    leading: avatar(email),
                    title: Text(email),
                    trailing: email == active
                        ? const Icon(Icons.check_rounded)
                        : email == primary
                        ? null
                        : IconButton(
                            tooltip: l10n.gmailRemoveAccount,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              Navigator.pop(sheet);
                              done(() => notifier.remove(email));
                            },
                          ),
                    onTap: () {
                      Navigator.pop(sheet);
                      if (email != active) {
                        done(() => notifier.select(email == primary ? null : email));
                      }
                    },
                  ),
                ListTile(
                  key: const ValueKey('gmail-add-account'),
                  leading: const Icon(Icons.person_add_alt_outlined),
                  title: Text(l10n.gmailAddAccount),
                  onTap: () async {
                    Navigator.pop(sheet);
                    final email = await chooseGoogleAccount();
                    if (email != null) {
                      done(() => notifier.add(email, primary: primary));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
