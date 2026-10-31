import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_similarity.dart';
import '../../notes/presentation/duplicates_sheet.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/ai_gate.dart';
import '../data/ai_history.dart';
import 'assistant_confirm.dart';
import 'chat_controller.dart';
import 'read_document.dart';
import '../../../core/friendly_error.dart';
import '../../auth/presentation/account_required.dart';

/// Tüm yapay zekâ özelliklerinin tek giriş noktası.
///
/// ESKİDEN: üç satırlık bir menüydü (Sohbet / Brifing / Belge oku) — her satır
/// başka bir ekrana atıyordu, sayfanın kendisi hiçbir iş yapmıyordu.
/// ŞİMDİ: soru buradan sorulur, puan durumu burada görünür ve öneriler
/// GERÇEK sayılardan üretilir (kaç not etiketsiz, kaç not başlıksız).
class AiHubScreen extends ConsumerStatefulWidget {
  const AiHubScreen({super.key});

  @override
  ConsumerState<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends ConsumerState<AiHubScreen> {
  final _input = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    final l10n = context.l10n;
    _input.clear();
    setState(() => _hasText = false);
    await ref
        .read(chatProvider.notifier)
        .send(
          text,
          noApiKeyText: l10n.aiNoApiKey,
          errorText: l10n.aiError,
          describeError: (e) => friendlyError(l10n, e),
          historyLabel: l10n.aiHistoryQuestion,
          confirmDelete: (title) => confirmAssistantDelete(context, title),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Kendi anahtarını girenler (BYOK) ve premium kullanıcılar dahili kapıdan
    // hiç geçmez, sayaç hiç azalmaz — çubuk onlara sürekli "30 / 30" diyordu.
    // Sınır uygulanmayan kullanıcıya puan göstergesi HİÇ gösterilmez.
    final metered = !ref.watch(aiUnlimitedProvider);
    final remaining = ref.watch(freeAiRemainingProvider);
    final limit = ref.watch(aiDailyLimitProvider);
    final chat = ref.watch(chatProvider);
    final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
    // Öneri sayıları GERÇEK sorgudan: notların kendisi sayılıyor.
    // Arşivlenmiş ve kilitli notlar sayılmaz — biri zaten görünmüyor,
    // ötekinin içeriğine bakılamaz.
    final active = [
      for (final n in notes)
        if (n.archivedAt == null && !n.locked) n,
    ];
    final untagged = active.where((n) => n.tags.isEmpty).length;
    final untitled = active.where((n) => n.title.trim().isEmpty).length;
    // Kopya sayısı metin benzerliğinden ölçülüyor (yerel, AI'sız — bkz.
    // note_similarity.dart).
    // Arka planda hesaplanır (F2.5); hesap sürerken önceki sayı görünür.
    final duplicates = duplicateCount(
      ref.watch(duplicateNotesProvider).value ?? const [],
    );
    final history = ref.watch(aiHistoryProvider);

    // **YENİDEN TASARIM** (kullanıcı isteği 2026-09-23: "yapay zeka ekranı
    // çok eski ve düzensiz kaldı, baştan tasarlanmayı hak ediyor"). Eskiden
    // 640 px'lik tek sütunda farklı biçimde kutular alt alta diziliyordu:
    // satır kartları, iki ayrı iki-sütunlu kutu grubu, bağımsız bir puan
    // çubuğu. Artık tek bir dil: üstte ekranın ne yaptığını söyleyen başlık
    // alanı (puan orada), altında asistan, sonra aynı biçimdeki araç kartları
    // — her birinin kendi renkli simgesi. Geniş ekranda asistan solda, araçlar
    // sağda.
    final chatCard = _ChatCard(
      chat: chat,
      controller: _input,
      hasText: _hasText,
      onChanged: (v) {
        final has = v.trim().isNotEmpty;
        if (has != _hasText) setState(() => _hasText = has);
      },
      onSend: _send,
      onSuggestion: _send,
      onFullScreen: () => context.push('/chat'),
    );
    // **AI İLE SESLİ NOT EN ÜSTTE** (kullanıcı isteği 2026-10-20: "AI sesli
    // notu bu AI menüsünün üzerine alalım, ana ekranda doğrudan yazma
    // olsun"). Ana ekranın mikrofonu artık hep doğrudan yazdırır; konuşup
    // notu yapay zekâya kurdurmak buradan. Dokunuş ana ekrana döner ve
    // ORTAK sesli not levhasını açar (widget/kısayolla aynı yol — bkz.
    // voiceAutostartProvider): not ana ekranın akışında, seçili klasörde
    // kurulur.
    final voiceCard = _ToolCard(
      key: const ValueKey('ai-hub-voice-note'),
      icon: Icons.mic_none_rounded,
      accent: _AiAccent.indigo,
      title: l10n.aiVoiceRowTitle,
      subtitle: l10n.aiVoiceRowInfoHub,
      showChevron: true,
      onTap: () {
        ref.read(voiceAutostartProvider.notifier).request();
        context.go('/');
      },
    );
    final tools = [
      _ToolCard(
        icon: Icons.wb_sunny_outlined,
        accent: _AiAccent.amber,
        title: l10n.briefingTitle,
        subtitle: l10n.hubBriefingInfo,
        showChevron: true,
        onTap: () => context.push('/briefing'),
      ),
      _ToolCard(
        icon: Icons.headphones_outlined,
        accent: _AiAccent.blue,
        title: l10n.readDocument,
        subtitle: l10n.hubReadInfo,
        showChevron: true,
        onTap: () => pickAndReadDocument(context),
      ),
    ];
    final tasks = [
      _ToolCard(
        icon: Icons.summarize_outlined,
        accent: _AiAccent.violet,
        title: l10n.aiTaskWeekSummary,
        subtitle: l10n.aiTaskWeekSummaryInfo,
        onTap: () => _send(l10n.aiTaskWeekSummaryInfo),
      ),
      _ToolCard(
        icon: Icons.new_label_outlined,
        accent: _AiAccent.teal,
        title: l10n.aiTaskTagUntagged,
        subtitle: l10n.aiTaskTagUntaggedInfo(untagged),
        onTap: untagged == 0 ? null : () => _send(l10n.aiTaskTagUntagged),
      ),
      _ToolCard(
        icon: Icons.title,
        accent: _AiAccent.rose,
        title: l10n.aiTaskSuggestTitles,
        subtitle: l10n.aiTaskSuggestTitlesInfo(untitled),
        onTap: untitled == 0 ? null : () => _send(l10n.aiTaskSuggestTitles),
      ),
      // Bu kutu yapay zekâya HİÇ gitmez: benzerlik yerelde ölçülür, puan
      // harcamaz. Yine de burada duruyor çünkü kullanıcı açısından aynı iş —
      // "notlarımı toparla".
      _ToolCard(
        icon: Icons.copy_all_outlined,
        accent: _AiAccent.slate,
        title: l10n.aiTaskDuplicates,
        subtitle: l10n.aiTaskDuplicatesInfo(duplicates),
        onTap: duplicates == 0 ? null : () => showDuplicatesSheet(context),
      ),
    ];
    final historySection = history.isEmpty
        ? const <Widget>[]
        : [
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _SectionLabel(l10n.aiRecentActions)),
                TextButton(
                  onPressed: ref.read(aiHistoryProvider.notifier).clear,
                  child: Text(l10n.aiHistoryClear),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _HistoryCard(entries: history),
          ];
    final footer = Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(
        l10n.aiPointsRenew,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
      ),
    );

    // Misafir, anahtarsız (F10.5): puan yerine açıklama kartı, AI araçları
    // soluk. Kopyalar (sondaki kart) AI'sız — açık kalır.
    final locked = ref.watch(aiGuestLockedProvider);
    Widget dim(Widget w) => GuestAiDim(locked: locked, child: w);
    final shownTasks = [
      for (var i = 0; i < tasks.length; i++)
        i < tasks.length - 1 ? dim(tasks[i]) : tasks[i],
    ];
    final guestCard = [
      if (locked) ...[const SizedBox(height: 12), const GuestAiCard()],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiHubTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsAi,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 920;
          // Alt dolguya sistem gezinme çubuğu EKLENİR: en alttaki satır
          // çubuğun arkasında yarım kalıyordu (2026-08-09).
          final padding = EdgeInsets.fromLTRB(
            16,
            4,
            16,
            24 + MediaQuery.viewPaddingOf(context).bottom,
          );
          final hero = _Hero(
            metered: metered && !locked,
            remaining: remaining,
            limit: limit,
            onPoints: () => context.push('/premium'),
          );
          if (!wide) {
            final columns = box.maxWidth >= 560 ? 2 : 1;
            return ListView(
              padding: padding,
              children: [
                hero,
                ...guestCard,
                const SizedBox(height: 16),
                dim(voiceCard),
                const SizedBox(height: 12),
                dim(chatCard),
                const SizedBox(height: 22),
                _SectionLabel(l10n.aiToolsSection),
                const SizedBox(height: 10),
                dim(_TileGrid(columns: columns, children: tools)),
                const SizedBox(height: 22),
                _SectionLabel(l10n.aiOnYourNotes),
                const SizedBox(height: 10),
                _TileGrid(columns: 2, children: shownTasks),
                ...historySection,
                footer,
              ],
            );
          }
          return SingleChildScrollView(
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    hero,
                    ...guestCard,
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              dim(voiceCard),
                              const SizedBox(height: 12),
                              dim(chatCard),
                              ...historySection,
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SectionLabel(l10n.aiToolsSection),
                              const SizedBox(height: 10),
                              dim(_TileGrid(columns: 1, children: tools)),
                              const SizedBox(height: 22),
                              _SectionLabel(l10n.aiOnYourNotes),
                              const SizedBox(height: 10),
                              _TileGrid(columns: 2, children: shownTasks),
                            ],
                          ),
                        ),
                      ],
                    ),
                    footer,
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

/// Ekranın vurgu renkleri: her araç kendi rengiyle tanınsın (klasörlerin
/// renkli simge kutusuyla aynı dil).
abstract final class _AiAccent {
  static const indigo = Color(0xFF4F5BD5);
  static const amber = Color(0xFFD9982B);
  static const blue = Color(0xFF4F8FD6);
  static const violet = Color(0xFF8E74D0);
  static const teal = Color(0xFF2FA392);
  static const rose = Color(0xFFD06A95);
  static const slate = Color(0xFF7D8799);
}

/// Başlık alanı: ekranın ne olduğunu söyler, günlük puan burada durur.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.metered,
    required this.remaining,
    required this.limit,
    required this.onPoints,
  });

  final bool metered;
  final int remaining;
  final int limit;
  final VoidCallback onPoints;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final points = metered
        ? _PointsPill(remaining: remaining, limit: limit, onTap: onPoints)
        : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            Color.alphaBlend(
              scheme.tertiaryContainer.withValues(alpha: dark ? 0.5 : 0.7),
              scheme.surface,
            ),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final title = Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 28,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiHubTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiHubTagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          if (points == null) return title;
          // Dar ekranda puan başlığın ALTINA iner; yan yana sıkışmasın.
          if (box.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 14), points],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 12),
              points,
            ],
          );
        },
      ),
    );
  }
}

/// Günlük puan: dairesel gösterge + "27 / 30". Dokununca Premium açılır —
/// "puan nedir, nasıl artar" sorusunun cevabı bir dokunuş uzakta.
class _PointsPill extends StatelessWidget {
  const _PointsPill({
    required this.remaining,
    required this.limit,
    required this.onTap,
  });

  final int remaining;
  final int limit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final ratio = limit <= 0 ? 0.0 : (remaining / limit).clamp(0.0, 1.0);
    return Tooltip(
      message: l10n.aiPointsToday,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 3.5,
                      backgroundColor: scheme.outlineVariant,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.aiPointsToday,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      l10n.aiPointsOf(remaining, limit),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartları [columns] sütunlu, satır içinde EŞİT yükseklikte dizer.
///
/// IntrinsicHeight ŞART: `CrossAxisAlignment.stretch` liste içinde dikey
/// alanı sınırsız bulunca release'de kutuları sonsuz yüksekliğe geriyor,
/// altındaki her şeyi erişilemez uzağa itiyordu (2026-08-09 kök nedeni).
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: 10),
                Expanded(
                  child: j < slice.length ? slice[j] : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          rows[i],
        ],
      ],
    );
  }
}

/// "SON İŞLEMLER" kartı: yapay zekânın en son yaptığı beş iş.
///
/// Yalnız işin ADI ve ne kadar önce olduğu yazar — soru metni ya da not
/// içeriği tutulmuyor (bkz. AiHistory). Amaç denetim değil, "az önce ne
/// yaptırmıştım" sorusuna cevap.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entries});

  final List<AiHistoryEntry> entries;

  /// Bugünse saat, değilse gün+ay. "3 dk önce" biçimi için dört ayrı l10n
  /// anahtarı (ve 16 çeviri) gerekirdi; `intl` zaten yerel ayara uygun saat
  /// ve tarih veriyor, kullanıcının merak ettiği sıra da böyle görünüyor.
  static String _when(DateTime at) {
    final now = DateTime.now();
    final sameDay =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return sameDay
        ? DateFormat.Hm().format(at)
        : DateFormat('d MMM').format(at);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final entry in entries.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 15,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    _when(entry.at),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Günlük puan çubuğu. Her soru bir puan düşer; kullanıcı kotayı ancak
/// istek reddedilince fark ediyordu.
///
/// Not içindeki AI levhası da aynı çubuğu gösteriyor (iki yüzey aynı dili
/// konuşsun), bu yüzden herkese açık.
class AiPointsBar extends StatelessWidget {
  const AiPointsBar({super.key, required this.remaining, required this.limit});

  final int remaining;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final ratio = limit <= 0 ? 0.0 : (remaining / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.aiPointsToday,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              l10n.aiPointsOf(remaining, limit),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation(scheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.chat,
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onSend,
    required this.onSuggestion,
    required this.onFullScreen,
  });

  final ChatState chat;
  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onFullScreen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.forum_outlined,
                  size: 19,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.aiChatWithNotes,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (chat.turns.isNotEmpty)
                TextButton(
                  onPressed: onFullScreen,
                  child: Text(l10n.aiChatFullScreen),
                ),
            ],
          ),
          if (chat.turns.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 238),
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final turn in chat.turns)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: turn.isUser
                              ? AlignmentDirectional.centerEnd
                              : AlignmentDirectional.centerStart,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.84,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: turn.isUser
                                    ? scheme.primaryContainer
                                    : scheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                turn.text,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (chat.busy)
                      Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.aiChatLooking,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasText ? scheme.primary : scheme.outlineVariant,
                width: hasText ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsetsDirectional.only(start: 16, end: 7),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: l10n.aiChatInputHint,
                      hintStyle: TextStyle(
                        fontSize: 14.5,
                        color: scheme.onSurfaceVariant,
                      ),
                      // Temanın dolgulu alan biçimi kutunun İÇİNDE ikinci bir
                      // kutu çiziyordu; çerçeve zaten dıştaki kapta.
                      filled: false,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Material(
                    color: hasText ? scheme.primary : scheme.surfaceContainer,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: chat.busy || !hasText ? null : onSend,
                      child: Icon(
                        Icons.arrow_upward,
                        size: 20,
                        color: hasText
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Öneri çipleri yalnız sohbet boşken: konuşma başlayınca yerlerini
          // yanıta bırakırlar.
          if (chat.turns.isEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (icon, text) in [
                  (Icons.shopping_cart_outlined, l10n.chatSuggestion1),
                  (Icons.work_outline, l10n.chatSuggestion2),
                  (Icons.alarm, l10n.chatSuggestion3),
                ])
                  ActionChip(
                    avatar: Icon(icon, size: 16, color: scheme.primary),
                    label: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: scheme.surface,
                    side: BorderSide(color: scheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: () => onSuggestion(text),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: scheme.outlineVariant)),
      ],
    );
  }
}

/// Araç kartı: renkli simge kutusu + başlık + açıklama. [onTap] null ise
/// yapılacak iş yok (ör. etiketsiz not kalmamış) — kart soluk ve
/// dokunulamaz durur.
class _ToolCard extends StatelessWidget {
  const _ToolCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = false,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: dark ? 0.28 : 0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 22, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showChevron)
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
