import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/folder_chat_repository.dart';

/// **PAYLAŞILAN KLASÖRÜN SOHBETİ** (kullanıcı isteği 2026-08-18: "birde
/// birbirine mesaj gönderme alanı olabilir").
///
/// Klasör başına tek oda: konu zaten klasörün kendisi. Sahip de paylaşılan
/// kullanıcı da aynı ekranı görür; yetki (okuma/yazma) sohbeti KISITLAMAZ —
/// bkz. [FolderChatRepository].
class FolderChatScreen extends ConsumerStatefulWidget {
  const FolderChatScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  final String folderId;
  final String folderName;

  static Future<void> open(
    BuildContext context, {
    required String folderId,
    required String folderName,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          FolderChatScreen(folderId: folderId, folderName: folderName),
    ),
  );

  @override
  ConsumerState<FolderChatScreen> createState() => _FolderChatScreenState();
}

class _FolderChatScreenState extends ConsumerState<FolderChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final repo = ref.read(folderChatRepositoryProvider);
    if (repo == null) return;
    // Kutu ÖNCE boşalır: gönderim ağ turu bekliyor, kullanıcı o sırada
    // yazdığını ekranda görmeye devam ederse ikinci kez gönderiyor.
    _controller.clear();
    try {
      await repo.send(widget.folderId, text);
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      // Gönderilemeyen metin KAYBOLMASIN: kutuya geri konur.
      _controller.text = text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.genericError('$e'))));
    }
  }

  /// Yeni mesaj gelince/gönderilince listenin dibine iner. Kare sonuna
  /// ertelenir: liste henüz yeni satırı yerleştirmemiş olabiliyor.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final myUid = ref.watch(currentUidProvider);
    final messagesAsync = ref.watch(folderMessagesProvider(widget.folderId));
    // Yeni mesaj düştüğünde dibe in — kullanıcı okurken yukarı kaymış olsa
    // bile son sözü görmek ister (sohbetin beklenen davranışı).
    ref.listen(folderMessagesProvider(widget.folderId), (_, _) {
      _scrollToEnd();
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.folderChatTitle),
            Text(
              widget.folderName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: l10n.genericError('$e'),
                ),
                data: (messages) => messages.isEmpty
                    ? EmptyState(
                        icon: Icons.forum_outlined,
                        title: l10n.folderChatEmptyTitle,
                        subtitle: l10n.folderChatEmptyHint,
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => _MessageBubble(
                          message: messages[index],
                          mine: messages[index].senderId == myUid,
                          folderId: widget.folderId,
                        ),
                      ),
              ),
            ),
            _Composer(controller: _controller, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        4,
        12,
        8 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              maxLength: kFolderMessageMaxLength,
              // Sayaç yalnız tavana yaklaşınca anlamlı; her zaman görünen
              // "0/2000" kutunun altında gereksiz bir satır kaplıyordu.
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => currentLength > (maxLength ?? 0) - 200
                  ? Text('$currentLength/$maxLength')
                  : null,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              inputFormatters: [
                LengthLimitingTextInputFormatter(kFolderMessageMaxLength),
              ],
              decoration: InputDecoration(
                hintText: l10n.folderChatHint,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: l10n.folderChatSend,
            onPressed: onSend,
            icon: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.folderId,
  });

  final FolderMessage message;
  final bool mine;
  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // Silme UZUN BASIŞLA: her balonun yanında bir çöp simgesi sohbeti
        // okunmaz hâle getirirdi. Yalnız kendi mesajın (sahip başkasınınkini
        // de silebilir ama arayüz onu kendi ekranına saklamaz — kural izin
        // verir, akış sadeliği için burada yalnız kendi mesajı sunulur).
        onLongPress: mine
            ? () => ref
                  .read(folderChatRepositoryProvider)
                  ?.delete(folderId, message.id)
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kimin yazdığı yalnız KARŞI tarafta yazılır: kendi
              // mesajlarında adını tekrar okumak yer israfı.
              if (!mine && message.senderName.isNotEmpty)
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              Text(message.text),
              if (message.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    TimeOfDay.fromDateTime(
                      message.createdAt!,
                    ).format(context),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
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
