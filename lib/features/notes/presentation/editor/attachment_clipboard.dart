import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/friendly_error.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../data/attachment_repository.dart';
import '../../data/note_quick_export.dart';
import '../../domain/attachment.dart';

/// Uygulama içi EK panosu: "Kopyala" ile alınan ek burada bekler, başka bir
/// notun (+) menüsündeki "Kopyalanan eki yapıştır" ile oraya kopyalanır.
///
/// Neden ayrı bir pano: sistem panosu yalnız görsel BAYTLARINI taşıyabiliyor
/// (PDF/sunum/ses için karşılığı yok, masaüstünde görsel yazımı da yok) ve
/// taşıdığında bile ekin çizimi, boyutu, "şeritte mi sayfada mı" bilgisi
/// kayboluyor. Uygulama içinde ekin KENDİSİ taşınır; sistem panosuna yazma
/// buna ek olarak, mümkün olan platformlarda yapılır (bkz. not editörü).
///
/// Pano yalnız bellekte durur: uygulama kapanınca boşalır. Kaynak dosya
/// silinirse yapıştırma "dosya bulunamadı" ile biter — kalıcı bir kopya
/// tutmak, kullanıcı hiç yapıştırmadığında yer israfı olurdu.
///
/// **ÇOKLU** (kullanıcı isteği 2026-08-09: "görsellerde çoklu seçim ve
/// kopyalama"): pano tek yuvalıydı, sayfadan iki görsel seçip kopyalamak
/// mümkün değildi. Artık sıralı bir liste tutar; tek ek kopyalamak da aynı
/// yoldan geçer (tek elemanlı liste).
final attachmentClipboardProvider =
    NotifierProvider<AttachmentClipboard, List<Attachment>>(
      AttachmentClipboard.new,
    );

class AttachmentClipboard extends Notifier<List<Attachment>> {
  @override
  List<Attachment> build() => const [];

  void copy(Attachment attachment) => state = [attachment];

  void copyAll(List<Attachment> attachments) =>
      state = List.unmodifiable(attachments);

  void clear() => state = const [];
}

/// **EKİ KOPYALA** düğmesi — tam ekran görüntüleyicilerin (görsel, PDF,
/// sunum, video) üst çubuğunda (kullanıcı isteği 2026-10-23: "ek
/// görüntülendiğinde seçeneklerinde eki kopyala seçeneği olmalı"). Eskiden
/// kopyalama yalnız not ekranındaki ek menüsündeydi; eki açan kullanıcı
/// kopyalamak için geri çıkmak zorundaydı.
///
/// Not ekranındaki kopyalamayla aynı sonuç: ek uygulama içi panoya girer
/// (başka notun "+" menüsünden yapıştırılır); YouTube ekinin bağlantısı,
/// görselin baytları (cihazdaysa ya da indirilebiliyorsa) sistem panosuna da
/// yazılır.
class CopyAttachmentButton extends ConsumerStatefulWidget {
  const CopyAttachmentButton({super.key, required this.attachment});

  final Attachment attachment;

  @override
  ConsumerState<CopyAttachmentButton> createState() =>
      _CopyAttachmentButtonState();
}

class _CopyAttachmentButtonState extends ConsumerState<CopyAttachmentButton> {
  bool _busy = false;

  Future<Uint8List?> _imageBytes(Attachment a) async {
    if (!kIsWeb && localFileExists(a.localPath)) {
      return File(a.localPath).readAsBytes();
    }
    if (a.isUploaded) {
      final response = await http.get(Uri.parse(a.downloadUrl));
      if (response.statusCode == 200) return response.bodyBytes;
    }
    return null;
  }

  Future<void> _copy() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final a = widget.attachment;
    ref.read(attachmentClipboardProvider.notifier).copy(a);
    if (a.isWebVideo) {
      await Clipboard.setData(ClipboardData(text: a.webUrl));
      messenger.showMessage(l10n.videoLinkCopied);
      return;
    }
    if (a.kind == AttachmentKind.image) {
      setState(() => _busy = true);
      try {
        final bytes = await _imageBytes(a);
        if (bytes != null) await Pasteboard.writeImage(bytes);
      } catch (_) {
        // Sistem panosuna yazmak her platformda mümkün değil; uygulama içi
        // kopya yine de alındı (not ekranındaki kopyalamayla aynı karar).
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
    messenger.showMessage(l10n.attachmentCopiedPasteHint);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('viewer-copy-attachment'),
      tooltip: context.l10n.copyAttachment,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.copy_all_outlined),
      onPressed: _busy ? null : _copy,
    );
  }
}

/// Tam ekran görüntüleyicilerin ORTAK çubuğu: **Paylaş · Eki kopyala**
/// (F13.5, 2026-10-31). Görsel, PDF, sunum, video ve YouTube aynı iki
/// düğmeyle, aynı sırayla başlar; türe özgü araçlar (kırp/döndür, alan seç,
/// balon listesi, tam ekran/PiP) onların ARDINDA ya da ⋮'te. Eskiden
/// paylaşım yalnız transkript ekranında vardı — açtığın eki göndermek için
/// nota dönüp paylaş levhasından "Ekler"i seçmek gerekiyordu.
class ViewerCommonActions extends StatelessWidget {
  const ViewerCommonActions({super.key, required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ShareAttachmentButton(attachment: attachment),
      CopyAttachmentButton(attachment: attachment),
    ],
  );
}

/// Ekin KENDİSİNİ (dosya; YouTube'da bağlantı) sistem paylaşımıyla gönderir.
class ShareAttachmentButton extends ConsumerStatefulWidget {
  const ShareAttachmentButton({super.key, required this.attachment});

  final Attachment attachment;

  @override
  ConsumerState<ShareAttachmentButton> createState() =>
      _ShareAttachmentButtonState();
}

class _ShareAttachmentButtonState extends ConsumerState<ShareAttachmentButton> {
  bool _busy = false;

  Future<void> _share() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final a = widget.attachment;
    if (a.isWebVideo) {
      await SharePlus.instance.share(
        ShareParams(text: a.webUrl, subject: a.fileName),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final files = await NoteQuickExport.filesOf([
        a,
      ], attachments: ref.read(attachmentRepositoryProvider));
      if (files.isEmpty) {
        messenger.showMessage(l10n.shareAttachmentFilesNone);
        return;
      }
      await SharePlus.instance.share(
        ShareParams(files: files, subject: a.fileName),
      );
    } catch (e) {
      messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('viewer-share-attachment'),
    tooltip: context.l10n.share,
    icon: _busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.share_outlined),
    onPressed: _busy ? null : _share,
  );
}
