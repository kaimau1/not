import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../data/ai_gate.dart';
import 'chat_controller.dart';
import 'read_document.dart';

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
        .send(text, noApiKeyText: l10n.aiNoApiKey, errorText: l10n.aiError);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Kendi anahtarını girenler (BYOK) ve premium kullanıcılar dahili kapıdan
    // hiç geçmez, sayaç hiç azalmaz — çubuk onlara sürekli "30 / 30" diyordu.
    // Sınır uygulanmayan kullanıcıya puan çubuğu HİÇ gösterilmez (Ayarlar
    // zaten durumu ayrı ayrı yazıyor, bkz. _BuiltInAiStatus).
    final metered = !ref.watch(aiUnlimitedProvider);
    final remaining = ref.watch(freeAiRemainingProvider);
    final limit = ref.watch(aiDailyLimitProvider);
    final chat = ref.watch(chatProvider);
    final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
    // Öneri sayıları GERÇEK sorgudan: prototipteki sabit "6 not" yerine
    // notların kendisi sayılıyor. Arşivlenmiş ve kilitli notlar sayılmaz —
    // biri zaten görünmüyor, ötekinin içeriğine bakılamaz.
    final active = [
      for (final n in notes)
        if (n.archivedAt == null && !n.locked) n,
    ];
    final untagged = active.where((n) => n.tags.isEmpty).length;
    final untitled = active.where((n) => n.title.trim().isEmpty).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.aiHubTitle,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: l10n.settingsAi,
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              if (metered) AiPointsBar(remaining: remaining, limit: limit),
              const SizedBox(height: 16),
              _ChatCard(
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
              ),
              const SizedBox(height: 12),
              _HubRow(
                icon: Icons.wb_sunny_outlined,
                title: l10n.briefingTitle,
                subtitle: l10n.hubBriefingInfo,
                onTap: () => context.push('/briefing'),
              ),
              const SizedBox(height: 16),
              _SectionLabel(l10n.aiOnYourNotes),
              const SizedBox(height: 8),
              // Tasarımda dört kutu var; "Kopyaları temizle" YOK çünkü benzer
              // not bulmak için bir benzerlik ölçümü gerekiyor ve uygulamada
              // öyle bir şey yok. Uydurma bir sayı göstermektense kutuyu hiç
              // koymadım.
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TaskTile(
                      icon: Icons.summarize_outlined,
                      title: l10n.aiTaskWeekSummary,
                      info: l10n.aiTaskWeekSummaryInfo,
                      onTap: () => _send(l10n.aiTaskWeekSummaryInfo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TaskTile(
                      icon: Icons.new_label_outlined,
                      title: l10n.aiTaskTagUntagged,
                      info: l10n.aiTaskTagUntaggedInfo(untagged),
                      onTap: untagged == 0
                          ? null
                          : () => _send(l10n.aiTaskTagUntagged),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _TaskTile(
                icon: Icons.title,
                title: l10n.aiTaskSuggestTitles,
                info: l10n.aiTaskSuggestTitlesInfo(untitled),
                onTap: untitled == 0
                    ? null
                    : () => _send(l10n.aiTaskSuggestTitles),
              ),
              const SizedBox(height: 16),
              _HubRow(
                icon: Icons.headphones_outlined,
                title: l10n.readDocument,
                subtitle: l10n.hubReadInfo,
                onTap: () => pickAndReadDocument(context),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.aiPointsRenew,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_outlined, size: 19, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.aiChatWithNotes,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
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
                              maxWidth:
                                  MediaQuery.sizeOf(context).width * 0.84,
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
          const SizedBox(height: 8),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            padding: const EdgeInsetsDirectional.only(start: 12, end: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: l10n.aiChatInputHint,
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: scheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Material(
                    color: hasText ? scheme.primary : scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(9),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: chat.busy || !hasText ? null : onSend,
                      child: Icon(
                        Icons.arrow_upward,
                        size: 18,
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in [
                  l10n.chatSuggestion1,
                  l10n.chatSuggestion2,
                  l10n.chatSuggestion3,
                ])
                  ActionChip(
                    label: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: scheme.secondaryContainer,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    onPressed: () => onSuggestion(s),
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
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// "Notların üzerinde" kutusu. [onTap] null ise iş yapacak bir şey yok
/// (ör. etiketsiz not kalmamış) — kutu soluk ve dokunulamaz durur.
class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.icon,
    required this.title,
    required this.info,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String info;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
