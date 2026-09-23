import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/presentation/editor/drawing_screen.dart';
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

  /// Görsel yükleniyor: gönder düğmeleri kilitlenir, ikinci kez
  /// gönderilmesin.
  bool _sending = false;

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

  /// **GÖRSEL GÖNDER** (kullanıcı isteği 2026-09-04: "sohbette görsel
  /// gönderilebilir olsun … gönderilirken üzerine çizme gibi işlevler
  /// olabilsin").
  ///
  /// Akış: kaynağı seç → önizleme → istersen ÜZERİNE ÇİZ → gönder. Çizim
  /// ekranı not tarafındakinin ta kendisi ([DrawingScreen]), yalnız zemini
  /// seçilen görsel.
  Future<void> _sendImage() async {
    final l10n = context.l10n;
    final mobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.addImage),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            if (mobile)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.takePhoto),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      // Sohbet görselinin tavanı dar (bkz. `maxImageBytes`): kaynağı
      // yüklemeden önce küçültmek, "çok büyük" hatasına düşmenin en ucuz
      // yolu.
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    var bytes = await picked.readAsBytes();
    if (!mounted) return;
    final draw = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.4,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  icon: const Icon(Icons.brush_outlined, size: 18),
                  label: Text(l10n.addDrawing),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(l10n.folderChatSend),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (draw == null || !mounted) return;
    if (draw) {
      final drawn = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => DrawingScreen(
            background: bytes,
            saveLabel: l10n.folderChatSend,
          ),
        ),
      );
      if (drawn == null || !mounted) return;
      bytes = drawn;
    }
    final repo = ref.read(folderChatRepositoryProvider);
    if (repo == null) return;
    setState(() => _sending = true);
    try {
      await repo.sendImage(
        widget.folderId,
        bytes,
        text: _controller.text.trim(),
      );
      _controller.clear();
      _scrollToEnd();
    } on FolderImageTooLargeException catch (e) {
      if (mounted) _snack(l10n.attachmentTooLarge(e.maxBytes ~/ (1024 * 1024)));
    } catch (e) {
      if (mounted) _snack(l10n.genericError('$e'));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            _Composer(
              controller: _controller,
              onSend: _send,
              onImage: _sending ? null : () => unawaited(_sendImage()),
              busy: _sending,
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onImage,
    required this.busy,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  /// Görsel gönderme akışı; yükleme sürerken null (düğme kapalı).
  final VoidCallback? onImage;
  final bool busy;

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
          IconButton(
            tooltip: l10n.addImage,
            onPressed: onImage,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
          ),
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

  /// Balondaki görsel: dokununca tam ekran açılır.
  Widget _image(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _ChatImageViewer(url: message.imageUrl),
          ),
        ),
        child: CachedNetworkImage(
          imageUrl: message.imageUrl,
          fit: BoxFit.cover,
          // RAM: sohbet balonu ekranın yarısı kadar; tam çözünürlükte açılan
          // her fotoğraf (12 MP ≈ 48 MB) uzun sohbette belleği dolduruyordu.
          // Tam boyu `_ChatImageViewer` açıyor.
          memCacheWidth: 720,
          placeholder: (context, _) => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, _, _) =>
              const SizedBox(height: 80, child: Icon(Icons.broken_image)),
        ),
      ),
    ),
  );

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.hasImage)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(l10n.copy),
                onTap: () => Navigator.pop(sheetContext, 'copy'),
              ),
            if (message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: Text(l10n.copyAsText),
                onTap: () => Navigator.pop(sheetContext, 'text'),
              ),
            if (mine)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.delete),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'delete':
        await ref
            .read(folderChatRepositoryProvider)
            ?.delete(folderId, message.id, path: message.imagePath);
      case 'text':
        await Clipboard.setData(ClipboardData(text: message.text));
      case 'copy':
        try {
          final response = await http.get(Uri.parse(message.imageUrl));
          if (response.statusCode == 200) {
            await Pasteboard.writeImage(response.bodyBytes);
          }
        } catch (_) {
          // Kopyalanamadıysa sessiz kal: panoya yazamamak sohbeti bozmaz.
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // Uzun basış MENÜ açar: sil (yalnız kendi mesajım) ve — görselli
        // mesajda — KOPYALA (kullanıcı isteği 2026-09-04: "görsel …
        // kopyalanabilsin"). Eskiden uzun basış doğrudan siliyordu; görsel
        // gelince tek eylemli kestirme yetmez oldu.
        onLongPress: () => unawaited(_menu(context, ref)),
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
              if (message.hasImage) _image(context),
              if (message.text.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: message.hasImage ? 6 : 0),
                  child: Text(message.text),
                ),
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


/// Sohbet görselinin tam ekran görüntüleyicisi: yakınlaştırılabilir.
class _ChatImageViewer extends StatelessWidget {
  const _ChatImageViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.transparent),
    body: Center(
      child: InteractiveViewer(
        maxScale: 5,
        child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
      ),
    ),
  );
}
