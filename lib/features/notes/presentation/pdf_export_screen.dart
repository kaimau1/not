import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/attachment_tag.dart';
import '../../../core/utils/local_file.dart';
import '../data/attachment_repository.dart';
import '../data/note_docx.dart';
import '../data/note_pdf.dart';
import '../domain/attachment.dart';
import '../../../core/utils/rich_text.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'viewers/pdf_viewer_screen.dart';

/// Notu PDF'e ya da Word'e (.docx) aktarmadan önce düzenleme ekranı.
///
/// Başlık ve içerik ayrı ayrı düzenlenebilir; içerik tek bir düz metin
/// kutusudur ve yapı satır başlarındaki işaretlerden okunur (`[x]`, `1.`,
/// `-`). Böylece kullanıcı madde ekleyip silebiliyor, işaretli/işaretsiz
/// durumu da metinle birlikte taşınıyor — ayrı bir liste düzenleyicisi
/// yazmaya gerek kalmadı. Notun görselleri (el yazısı çizimleri dahil)
/// istenirse iki biçime de gömülür.
class PdfExportScreen extends ConsumerStatefulWidget {
  const PdfExportScreen({super.key, required this.note, this.layout});

  final Note note;

  /// Notun EKRANDAKİ sayfa ölçüleri (editörden gelir): görsellerin metnin
  /// neresinde durduğunu bulmak için gerekir. Eskiden tüm görseller metnin
  /// SONUNA ekleniyordu — dışa aktarılan belge nottaki düzene benzemiyordu.
  /// null ise (paylaş menüsünden çağrı) eski davranış sürer.
  final ({double bodyTop, double pageWidth, double pageHeight})? layout;

  @override
  ConsumerState<PdfExportScreen> createState() => _PdfExportScreenState();
}

/// Dışa aktarmaya girecek TEK görselin ayarları — kullanıcı düzenleyebilir
/// (kullanıcı isteği 2026-08-09: "dışa aktarmada görsellerin yeri ve boyutu
/// da düzenlenebilmeli").
class _ImageOption {
  _ImageOption({
    required this.attachment,
    required this.line,
    required this.widthFraction,
    required this.align,
  });

  final Attachment attachment;

  /// Metnin kaçıncı satırından ÖNCE gelecek (null = en sona).
  int? line;

  /// Sayfa genişliğine oranı.
  double widthFraction;

  /// Yatay hiza — sol/sağ olanlar metnin YANINA akar (bkz. NotePdf).
  ExportAlign align;

  /// Bu görsel belgeye girsin mi?
  bool include = true;
}

class _PdfExportScreenState extends ConsumerState<PdfExportScreen> {
  /// Notun İŞARETLİ (biçim taşıyan) hâlleri. Alanlarda TEMİZ metin gösterilir
  /// ama dışa aktarmaya — kullanıcı elle değiştirmediyse — işaretli hâl gider:
  /// böylece çıktı nottaki gibi kalın/renkli/büyük çıkar.
  ///
  /// KÖK NEDEN (kullanıcı ekran görüntüsü 2026-08-08): alanlara HAM metin
  /// konuyordu ve başlık `##5:**_~ezan vakti~_**##` olarak görünüyordu.
  late final String _markedTitle = widget.note.title.trim();
  late final String _markedContent = _contentOf(widget.note);

  late final TextEditingController _title = TextEditingController(
    text: stripRichMarkers(_markedTitle),
  );
  late final TextEditingController _content = TextEditingController(
    text: stripRichMarkers(_markedContent),
  );
  bool _includeDate = true;
  bool _includeImages = true;
  bool _busy = false;

  bool get _hasImages =>
      widget.note.attachments.any((a) => a.kind == AttachmentKind.image);

  /// Dışa aktarılacak metin — biçim İŞARETLERİYLE (çözümlemeyi `NotePdf`
  /// yapıyor, bkz. `NotePdf._rich`).
  ///
  /// **KÖK NEDEN (kullanıcı bulgusu 2026-08-08: "maddeler, veriler
  /// yazılmıyor").** Metin notunun MADDELERİ buraya hiç girmiyordu: gövde
  /// alınıyor, aynı notun içindeki onay kutuları/maddeler atlanıyordu. Karışık
  /// içerik (gövde + maddeler) uygulamada olağan — `Note.toPlainText` zaten
  /// ikisini de yazıyor, burası yazmıyordu. Artık üç liste türünde de gövde ve
  /// maddeler birlikte gider.
  static String _contentOf(Note note) => switch (note.type) {
    NoteType.text => [
      if (note.body.trim().isNotEmpty) note.body.trimRight(),
      for (final item in note.items)
        if (item.text.trim().isNotEmpty)
          '[${item.checked ? 'x' : ' '}] ${item.text}',
    ].join('\n'),
    NoteType.checklist => [
      if (note.body.trim().isNotEmpty) note.body.trimRight(),
      for (final item in note.items)
        '[${item.checked ? 'x' : ' '}] ${item.text}',
    ].join('\n'),
    NoteType.ordered => [
      if (note.body.trim().isNotEmpty) note.body.trimRight(),
      for (var i = 0; i < note.items.length; i++)
        '${i + 1}. ${note.items[i].text}',
    ].join('\n'),
    // PDF notu dışa aktarılırken KAYNAK BELGE değil, kullanıcının sayfa
    // notları yazılır (belgenin kendisi zaten ek olarak duruyor ve buradaki
    // dışa aktarma metin + görsel üretiyor).
    NoteType.pdf || NoteType.slides => note.pageNotesText().trimRight(),
    // Arşiv defteri: açıklaması + metin girdileri. Ekler (görsel/belge)
    // dışa aktarmanın görsel bölümünden zaten geçiyor.
    NoteType.archive => [
      if (note.body.trim().isNotEmpty) note.body.trimRight(),
      for (final item in note.items)
        if (item.text.trim().isNotEmpty) item.text,
    ].join('\n'),
  };

  /// Dışa aktarılacak GÖVDE metni: metin içi ek etiketleri ("📎 rapor.pdf")
  /// gömülü fontun çizebileceği "[ek: rapor.pdf]" biçimine çevrilir
  /// (gerekçe: exportAttachmentTags).
  String _exportContent() => exportAttachmentTags(
    _exported(_markedContent, _content.text),
    [for (final a in widget.note.attachments) a.fileName],
  );

  /// Alandaki metin kullanıcı tarafından DEĞİŞTİRİLMEDİYSE işaretli özgün
  /// hâli döner (biçim korunur); değiştirildiyse kullanıcının yazdığı düz
  /// metin gider.
  static String _exported(String marked, String edited) =>
      stripRichMarkers(marked).trim() == edited.trim() ? marked : edited;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  /// Nota bağlı görsellerin baytlarını toplar (yerel → yoksa Storage).
  /// Erişilemeyen görsel (henüz senkronlanmamış, dosyası silinmiş) atlanır —
  /// dışa aktarma tek görsel yüzünden tümden başarısız olmasın.
  Future<List<ExportImage>> _loadImages() async {
    if (!_includeImages) return const [];
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return const [];
    final out = <ExportImage>[];
    for (final option in _options) {
      if (!option.include) continue;
      final a = option.attachment;
      try {
        final bytes = await repo.readBytes(a);
        if (bytes == null) continue;
        out.add(
          ExportImage(
            bytes: bytes,
            width: a.width ?? 0,
            height: a.height ?? 0,
            mimeType: a.mimeType,
            line: option.line,
            widthFraction: option.widthFraction,
            align: option.align,
          ),
        );
      } catch (_) {
        // Erişilemeyen görsel dışa aktarmayı düşürmez.
      }
    }
    return out;
  }

  /// Görsel ayarları — nottaki düzenden türetilir, sonra kullanıcı oynar.
  ///
  /// `didChangeDependencies`te BİR KEZ kurulur: [_lineFor] metni ölçmek için
  /// temaya (yazı stiline) ihtiyaç duyuyor, yani `initState`te hesaplanamaz;
  /// her build'de yeniden kurulsaydı da kullanıcının değişiklikleri silinirdi.
  final _options = <_ImageOption>[];
  var _optionsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_optionsReady) return;
    _optionsReady = true;
    for (final a in widget.note.attachments) {
      if (a.kind != AttachmentKind.image) continue;
      if (a.id == widget.note.backgroundImageId) continue;
      _options.add(
        _ImageOption(
          attachment: a,
          // Düzen bilgisi yoksa görsel metnin SONUNA konur; `null` yerine
          // gerçek satır sayısı yazılır ki "konum" düğmeleri ile gösterilen
          // sayı birbirini tutsun (null'da eksi düğmesi kapalıyken sayı
          // sondaki satırı gösteriyordu).
          line: _lineFor(a) ?? _lineCount,
          widthFraction: (a.displayWidth ?? 1).clamp(0.15, 1.0).toDouble(),
          align: _alignFor(a),
        ),
      );
    }
  }

  /// İçerik alanındaki satır sayısı — "konum" ayarının üst sınırı.
  int get _lineCount => _content.text.isEmpty
      ? 0
      : '\n'.allMatches(_content.text).length + 1;

  /// Görselin nottaki dikey yerini, dışa aktarılan metnin satır sırasına
  /// çevirir. Metin notunda konum BİREBİR hesaplanır: ekrandaki sütun
  /// genişliği ve yazı stiliyle dizilen metinde, görselin üst kenarının
  /// düştüğü satır bulunur. Liste notlarında satırlar ayrı alanlar olduğundan
  /// oranla (görselin sayfadaki yeri / sayfa yüksekliği) yaklaşılır.
  int? _lineFor(Attachment a) {
    final layout = widget.layout;
    if (layout == null || a.pageY == null) return null;
    final content = _content.text;
    if (content.isEmpty) return 0;
    final bandTop = a.pageY! - layout.bodyTop;
    if (bandTop <= 0) return 0;
    if (widget.note.type == NoteType.text) {
      final style = Theme.of(context).textTheme.bodyLarge;
      final painter = TextPainter(
        text: TextSpan(text: content, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: (layout.pageWidth - 32).clamp(1.0, double.infinity));
      final offset = painter
          .getPositionForOffset(Offset(0, bandTop))
          .offset
          .clamp(0, content.length);
      painter.dispose();
      return '\n'.allMatches(content.substring(0, offset)).length;
    }
    final body = (layout.pageHeight - layout.bodyTop).clamp(
      1.0,
      double.infinity,
    );
    final lineCount = '\n'.allMatches(content).length + 1;
    return ((bandTop / body) * lineCount).round().clamp(0, lineCount);
  }

  /// Nottaki yatay konumdan hiza: sol çeyrekte sola, sağ çeyrekte sağa yaslı.
  ExportAlign _alignFor(Attachment a) {
    if (widget.layout == null || a.x == null) return ExportAlign.center;
    final center = a.x! + (a.displayWidth ?? 0.5) / 2;
    if (center < 0.4) return ExportAlign.left;
    if (center > 0.6) return ExportAlign.right;
    return ExportAlign.center;
  }

  DateTime? get _date => _includeDate
      ? (widget.note.updatedAt ?? widget.note.createdAt ?? DateTime.now())
      : null;

  void _showError(Object e) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.aiError(e.toString()))),
      );
  }

  /// PDF byte'larını üretir. Diske/blob'a yazmayı çağıran taraf yapar —
  /// web ve masaüstü/mobil farklı hedeflere yazdığı için ayrıldı.
  Future<Uint8List?> _generateBytes() async {
    setState(() => _busy = true);
    try {
      return await NotePdf.build(
        title: _exported(_markedTitle, _title.text.trim()),
        content: _exportContent(),
        date: _date,
        images: await _loadImages(),
        palette: NoteColors.richPalette,
      );
    } catch (e) {
      if (mounted) _showError(e);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Word (.docx) byte'larını üretir.
  Future<Uint8List?> _generateDocxBytes() async {
    setState(() => _busy = true);
    try {
      return await NoteDocx.build(
        title: _title.text.trim(),
        content: _exportContent(),
        date: _date,
        images: await _loadImages(),
      );
    } catch (e) {
      if (mounted) _showError(e);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareWord() async {
    final bytes = await _generateDocxBytes();
    if (bytes == null || !mounted) return;
    const mimeType =
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    // Web'de `dart:io File` çalışmaz ("Unsupported operation" — kullanıcı
    // bulgusu); share_plus web'de byte'lardan doğrudan indirme/paylaşım
    // tetikleyebiliyor, geçici dosyaya hiç gerek yok.
    final file = kIsWeb
        ? XFile.fromData(
            bytes,
            name: '${NotePdf.safeFileName(_title.text)}.docx',
            mimeType: mimeType,
          )
        : XFile(await NoteDocx.writeTemp(bytes, _title.text), mimeType: mimeType);
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        subject: _title.text.trim().isEmpty
            ? context.l10n.appName
            : _title.text.trim(),
      ),
    );
  }

  Future<void> _preview() async {
    final bytes = await _generateBytes();
    if (bytes == null || !mounted) return;
    // Web'de gerçek dosya yolu yok: byte'lar blob URL'ine sarılıp mevcut
    // "Storage'dan gelen ek" yolundan (isUploaded/downloadUrl) gösteriliyor,
    // ki PdfViewerScreen değişmesin.
    final attachment = kIsWeb
        ? Attachment(
            id: 'preview',
            kind: AttachmentKind.pdf,
            fileName: NotePdf.safeFileName(_title.text),
            mimeType: 'application/pdf',
            downloadUrl: NotePdf.webBlobUrl(bytes),
          )
        : Attachment(
            id: 'preview',
            kind: AttachmentKind.pdf,
            fileName: NotePdf.safeFileName(_title.text),
            mimeType: 'application/pdf',
            localPath: await NotePdf.writeTemp(bytes, _title.text),
          );
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => PdfViewerScreen(attachment: attachment)));
  }

  Future<void> _share() async {
    final bytes = await _generateBytes();
    if (bytes == null || !mounted) return;
    final file = kIsWeb
        ? XFile.fromData(
            bytes,
            name: '${NotePdf.safeFileName(_title.text)}.pdf',
            mimeType: 'application/pdf',
          )
        : XFile(
            await NotePdf.writeTemp(bytes, _title.text),
            mimeType: 'application/pdf',
          );
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        subject: _title.text.trim().isEmpty
            ? context.l10n.appName
            : _title.text.trim(),
      ),
    );
  }

  /// Tek görselin ayar kartı: küçük önizleme + hiza + genişlik + konum.
  Widget _imageCard(AppLocalizations l10n, _ImageOption option) {
    final scheme = Theme.of(context).colorScheme;
    final a = option.attachment;
    final hasFile = a.localPath.isNotEmpty && localFileExists(a.localPath);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: hasFile
                        ? Image.file(
                            File(a.localPath),
                            fit: BoxFit.cover,
                            cacheWidth: 120,
                          )
                        : ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: const Icon(Icons.image_outlined, size: 20),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    a.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: option.include,
                  onChanged: (v) => setState(() => option.include = v),
                ),
              ],
            ),
            if (option.include) ...[
              const SizedBox(height: 4),
              SegmentedButton<ExportAlign>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
                segments: [
                  ButtonSegment(
                    value: ExportAlign.left,
                    icon: const Icon(Icons.format_align_left, size: 18),
                    label: Text(l10n.exportAlignLeft),
                  ),
                  ButtonSegment(
                    value: ExportAlign.center,
                    icon: const Icon(Icons.format_align_center, size: 18),
                    label: Text(l10n.exportAlignCenter),
                  ),
                  ButtonSegment(
                    value: ExportAlign.right,
                    icon: const Icon(Icons.format_align_right, size: 18),
                    label: Text(l10n.exportAlignRight),
                  ),
                ],
                selected: {option.align},
                onSelectionChanged: (v) =>
                    setState(() => option.align = v.first),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      l10n.exportImageWidth,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: option.widthFraction,
                      min: 0.15,
                      max: 1,
                      onChanged: (v) =>
                          setState(() => option.widthFraction = v),
                    ),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      '%${(option.widthFraction * 100).round()}',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      l10n.exportImageLine,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.decrease,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: (option.line ?? 0) <= 0
                        ? null
                        : () => setState(() => option.line = option.line! - 1),
                  ),
                  Text(
                    '${(option.line ?? _lineCount) + 1}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  IconButton(
                    tooltip: l10n.increase,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: (option.line ?? _lineCount) >= _lineCount
                        ? null
                        : () => setState(
                            () => option.line = (option.line ?? 0) + 1,
                          ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.exportImageLineOf(_lineCount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportPdf)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.pdfTitleField,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _content,
              minLines: 10,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.pdfContentField,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                helperMaxLines: 3,
                helperText: l10n.pdfMarkupHint,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.pdfIncludeDate),
              value: _includeDate,
              onChanged: (v) => setState(() => _includeDate = v),
            ),
            if (_hasImages) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.exportIncludeImages),
                value: _includeImages,
                onChanged: (v) => setState(() => _includeImages = v),
              ),
              // GÖRSEL AYARLARI: her görselin yeri, hizası ve boyutu burada
              // düzenlenir. Sol/sağ hizalı ve dar görsellerin YANINDAN metin
              // akar (bkz. NotePdf._withImages) — "orta" tam genişlik blok
              // demektir, ipucu bunu söylüyor.
              if (_includeImages && _options.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.exportImages,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.exportImagesInfo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                for (final option in _options) _imageCard(l10n, option),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _busy ? null : _preview,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(l10n.pdfPreview),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: scheme.primary,
                      ),
                      onPressed: _busy ? null : _share,
                      icon: const Icon(Icons.ios_share),
                      label: Text(l10n.share),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Word: aynı içerik .docx olarak paylaşılır (Word'de açıp
              // düzenlemeye devam etmek isteyenler için).
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _busy ? null : _shareWord,
                icon: const Icon(Icons.description_outlined),
                label: Text(l10n.exportWord),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
