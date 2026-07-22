import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/markdown.dart';
import '../../../core/widgets/speak_button.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/data/pdf_text.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../settings/settings_providers.dart';
import '../data/ai_cache.dart';
import '../data/ai_report.dart';
import 'listen_screen.dart';
import '../data/gemini_service.dart';
import 'doc_chat_screen.dart';

/// "Notu değiştir" geri çağırması: AI çıktısı notun içeriğiyle değiştirilir;
/// [asType] verilirse notun çalışma modu da o tipe geçer (madde/sıralı liste).
/// [keepChecked] true ise AI'a yalnız işaretsiz maddeler gönderilmiştir;
/// işaretli (tamamlanmış) maddeler değiştirilmeden korunmalı, sonuç yalnız
/// işaretsizlerin yerine geçer.
typedef ReplaceTextCallback =
    void Function(String text, {NoteType? asType, bool keepChecked});

/// Editördeki "Yapay Zeka" düğmesinin açtığı alt sayfa.
Future<void> showAiSheet(
  BuildContext context,
  Note note, {
  ValueChanged<String>? onAppendText,
  ReplaceTextCallback? onReplaceText,
  ReplaceTextCallback? onCreateNote,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => AiSheet(
    note: note,
    onAppendText: onAppendText,
    onReplaceText: onReplaceText,
    onCreateNote: onCreateNote,
  ),
);

class AiSheet extends ConsumerStatefulWidget {
  const AiSheet({
    super.key,
    required this.note,
    this.onAppendText,
    this.onReplaceText,
    this.onCreateNote,
  });

  final Note note;

  /// Sonucu (OCR, ses dökümü vb.) nota ekleyen geri çağırma.
  final ValueChanged<String>? onAppendText;

  /// Sonucu notun içeriğiyle değiştiren geri çağırma ("Geliştir" için).
  final ReplaceTextCallback? onReplaceText;

  /// Sonucu ORİJİNAL notu değiştirmeden YENİ bir notta açan geri çağırma
  /// (madde 1-2): kullanıcı hem "değiştirmeden" (orijinal kalır) hem
  /// "düzeltilmiş" (yeni notta) sürüme sahip olur. [asType] verilirse yeni
  /// not o tipte (madde/sıralı liste) oluşturulur.
  final ReplaceTextCallback? onCreateNote;

  @override
  ConsumerState<AiSheet> createState() => _AiSheetState();
}

class _AiSheetState extends ConsumerState<AiSheet> {
  bool _loading = false;
  String? _result;
  String? _error;

  /// [cacheKey] verilirse çıktı cihazda saklanır ve aynı girdi ikinci kez
  /// model çağırmaz. Anahtar içerikten türetildiği için not/PDF değişince
  /// kendiliğinden tazelenir — saat karşılaştırmasına gerek yok.
  /// Son başarısız işlemi tekrar deneyebilmek için saklanır (hata görünümünde
  /// "Tekrar dene").
  VoidCallback? _retryAction;

  Future<void> _run(
    Future<String> Function(GeminiService) action, {
    bool cacheAsSummary = false,
    String? cacheKey,
    bool improvement = false,
    NoteType? replaceAsType,
    bool keepChecked = false,
  }) async {
    _retryAction = () => _run(
      action,
      cacheAsSummary: cacheAsSummary,
      cacheKey: cacheKey,
      improvement: improvement,
      replaceAsType: replaceAsType,
      keepChecked: keepChecked,
    );
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
      _lastWasImprovement = improvement;
      _replaceAsType = replaceAsType;
      _keepChecked = keepChecked;
    });
    if (cacheKey != null) {
      final cached = await AiCache.read(cacheKey);
      if (cached != null && cached.trim().isNotEmpty) {
        if (mounted) {
          setState(() {
            _result = cached;
            _loading = false;
          });
        }
        return;
      }
    }
    try {
      final service = ref.read(geminiServiceProvider);
      // Notlar düz metin tuttuğundan AI çıktısındaki markdown işaretlerini
      // (**, *, #, `) tek noktada temizle: gösterim, kopyalama ve nota
      // ekleme/değiştirmenin tümü temiz metni kullanır.
      final text = stripMarkdown(await action(service)).trim();
      if (cacheKey != null) await AiCache.write(cacheKey, text);
      if (cacheAsSummary) {
        ref
            .read(notesRepositoryProvider)
            ?.setAiSummary(
              widget.note.id,
              AiSummary(text: text, model: 'gemini', createdAt: DateTime.now()),
            );
      }
      if (mounted) setState(() => _result = text);
    } on GeminiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.isAuthError
              ? context.l10n.aiNoApiKey
              : context.l10n.aiError(e.message),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = context.l10n.aiError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _summarizePdf(GeminiService service, Attachment pdf) async {
    final notSyncedMessage = context.l10n.attachmentNotSynced;
    final repo = ref.read(attachmentRepositoryProvider);
    final bytes = repo == null ? null : await repo.readBytes(pdf);
    if (bytes == null) {
      throw GeminiException(notSyncedMessage);
    }
    return service.summarizePdf(bytes, pdf.fileName);
  }

  static const _translateTargets = [
    'Türkçe',
    'İngilizce',
    'Almanca',
    'Fransızca',
    'İspanyolca',
    'Arapça',
    'Rusça',
  ];

  bool _lastWasImprovement = false;

  /// "Notu değiştir" uygulanınca notun geçeceği tip (madde/sıralı liste
  /// çevirileri için); null ise tip korunur.
  NoteType? _replaceAsType;

  /// Son işlemde işaretli maddeler kapsam dışı bırakıldı mı (checklist +
  /// ayar açık). Sonucu uygularken işaretliler korunmalı.
  bool _keepChecked = false;

  /// Bu not için işaretli maddeler AI kapsamı dışında mı tutulsun: ayar açık,
  /// not checklist ve en az bir işaretli VE bir işaretsiz madde varsa. (Hepsi
  /// işaretliyse dışlanacak bir şey kalmaz; hiç işaretli yoksa fark etmez.)
  bool get _skipCheckedForNote {
    if (!ref.read(aiSkipCheckedProvider)) return false;
    if (widget.note.type != NoteType.checklist) return false;
    final hasChecked = widget.note.items.any((i) => i.checked);
    final hasUnchecked = widget.note.items.any(
      (i) => !i.checked && i.text.trim().isNotEmpty,
    );
    return hasChecked && hasUnchecked;
  }

  /// Üç düzeyde "notu düzelt": kullanıcı ne kadar müdahale istediğini seçer.
  /// Üçü de içerik metnini (başlık/işaret olmadan) gönderir ve sonucu nota
  /// geri uygulanabilir kılar (improvement: true).
  static const _fixCommon =
      'Düz metin ver; başına madde imi, numara ya da onay kutusu '
      '([ ], [x]) KOYMA; hiçbir biçimlendirme işareti (yıldız, kare, '
      'alt çizgi) kullanma.';

  /// Liste notlarında (checklist/sıralı) her satır ayrı bir maddedir. Bu
  /// kısıt olmadan "dengeli/detaylı" düzeltme maddeleri tek paragrafa
  /// birleştiriyor ve sıralı liste tek maddeye çöküyordu — çıktı satır sayısı
  /// girdiyle aynı kalmalı.
  String get _listStructureConstraint =>
      widget.note.type == NoteType.text
      ? ''
      : ' ÖNEMLİ: Bu bir listedir; girdideki HER SATIR ayrı bir maddedir. '
            'Çıktı da AYNI sayıda satır içermeli — her maddeyi kendi satırında '
            'ver, satırları BİRLEŞTİRME, tek paragrafa DÖNÜŞTÜRME, madde '
            'ekleme veya çıkarma. Her satırı tek tek düzelt.';

  Future<void> _pickFixLevel() async {
    final l10n = context.l10n;
    // (etiket, açıklama, istem)
    final options = <(String, String, String)>[
      (
        l10n.fixSimple,
        l10n.fixSimpleInfo,
        'Yalnızca yazım, imla, noktalama ve büyük/küçük harf hatalarını '
            'düzelt. Cümle yapısına, kelime seçimine veya sıralamaya DOKUNMA. '
            'Her satırı olduğu gibi ayrı tut; satır/madde sayısını KORU, '
            'satırları birleştirme veya bölme. Anlamı ve içeriği KORU; yeni '
            'bilgi ekleme, madde silme. $_fixCommon',
      ),
      (
        l10n.fixBalanced,
        l10n.fixBalancedInfo,
        'Yazım, imla ve noktalama hatalarını düzelt; ayrıca bozuk veya '
            'devrik cümleleri düzgün ve akıcı hale getir, gereksiz '
            'tekrarları sadeleştir. Anlamı ve tüm bilgileri KORU; yeni bilgi '
            'ekleme. Genel yapıyı ve satır düzenini olabildiğince koru. '
            '$_fixCommon',
      ),
      (
        l10n.fixDetailed,
        l10n.fixDetailedInfo,
        'Metni baştan aşağı yeniden düzenle: yazım ve dilbilgisini düzelt, '
            'cümleleri akıcı ve profesyonel bir dille yeniden yaz, düşünceleri '
            'mantıklı bir akışa sok, gerekirse paragraflara ayır. Hiçbir '
            'bilgiyi ATLAMA veya uydurma; yalnızca var olan içeriği daha iyi '
            'ifade et. $_fixCommon',
      ),
    ];
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.fixLevelTitle),
        children: [
          for (final (label, info, prompt) in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, prompt),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                subtitle: Text(info),
              ),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    final skip = _skipCheckedForNote;
    // Liste yapısını koru: sıralı/checklist notunda maddeler tek satıra
    // çökmesin (kullanıcı: "5 madde tek numaraya dönüşüyor").
    final prompt = chosen + _listStructureConstraint;
    await _run(
      (s) => s.rewriteText(widget.note.toContentText(skipChecked: skip), prompt),
      improvement: true,
      keepChecked: skip,
    );
  }

  Future<void> _pickImprovement() async {
    final l10n = context.l10n;
    // (etiket, istem, "notu değiştir" uygulanınca geçilecek tip)
    // Yazım düzeltmesi burada YOK: sayfanın üstündeki "Notu düzelt" düğmesi
    // aynı işi yapıyordu, ikisi bir arada kafa karıştırıyordu.
    final options = <(String, String, NoteType?)>[
      (
        l10n.improveFormal,
        'Daha resmî ve profesyonel bir dille yeniden yaz',
        null,
      ),
      (l10n.improveShorten, 'Anlamı koruyarak yarı uzunluğa kısalt', null),
      (
        l10n.improveBullets,
        'Düzenli bir maddeler listesine dönüştür: her satır tek bir madde '
            'olsun, başına işaret/numara koyma',
        NoteType.checklist,
      ),
      (
        l10n.improveNumbered,
        'Sıralı bir listeye dönüştür: içeriği mantıklı bir sıraya koy, '
            'her satır tek bir adım olsun, başına numara koyma',
        NoteType.ordered,
      ),
    ];
    final chosen = await showDialog<(String, NoteType?)>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.aiImprove),
        children: [
          for (final (label, prompt, type) in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, (prompt, type)),
              child: Text(label),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    // İşaretlileri dışlama yalnız tip DEĞİŞMEDEN düzenlemede anlamlı; liste
    // tipine dönüştürmede (bullets/numbered) tüm içerik yeniden şekillenir.
    final skip = chosen.$2 == null && _skipCheckedForNote;
    // Tip korunuyorsa (Formal/Kısalt) liste yapısını da koru; tip
    // dönüştürmede (bullets/numbered) içerik zaten yeniden şekillenir.
    final prompt = chosen.$2 == null
        ? chosen.$1 + _listStructureConstraint
        : chosen.$1;
    await _run(
      // İçerik metni (başlık/işaret yok): geliştirme sonucu nota geri
      // uygulanırken başlık öğeye, `[ ]`/numara işaretleri metne sızmasın.
      (s) => s.rewriteText(
        widget.note.toContentText(skipChecked: skip),
        prompt,
      ),
      improvement: true,
      replaceAsType: chosen.$2,
      keepChecked: skip,
    );
  }

  Future<void> _pickLanguageAndTranslate() async {
    final language = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.aiTranslate),
        children: [
          for (final target in _translateTargets)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, target),
              child: Text(target),
            ),
        ],
      ),
    );
    if (language == null) return;
    // İçerik metni (başlık ve `- [x]`/numara işaretleri OLMADAN): model
    // işaretleri de "çevirmeye" çalışıp yapıya sızdırıyordu. improvement:
    // çeviri sonucu nota geri uygulanabilir ("Notu değiştir" görünür).
    final skip = _skipCheckedForNote;
    await _run(
      (s) =>
          s.translateText(widget.note.toContentText(skipChecked: skip), language),
      improvement: true,
      keepChecked: skip,
    );
  }

  Future<String> _extractImageText(
    GeminiService service,
    Attachment image,
  ) async {
    final notSyncedMessage = context.l10n.attachmentNotSynced;
    final repo = ref.read(attachmentRepositoryProvider);
    final bytes = repo == null ? null : await repo.readBytes(image);
    if (bytes == null) {
      throw GeminiException(notSyncedMessage);
    }
    return service.extractTextFromImage(bytes, image.mimeType);
  }

  Future<String> _transcribeAudio(
    GeminiService service,
    Attachment audio,
  ) async {
    final notSyncedMessage = context.l10n.attachmentNotSynced;
    final repo = ref.read(attachmentRepositoryProvider);
    final bytes = repo == null ? null : await repo.readBytes(audio);
    if (bytes == null) {
      throw GeminiException(notSyncedMessage);
    }
    return service.transcribeAudio(bytes, audio.mimeType);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pdfs = [
      for (final a in widget.note.attachments)
        if (a.kind == AttachmentKind.pdf) a,
    ];
    final images = [
      for (final a in widget.note.attachments)
        if (a.kind == AttachmentKind.image) a,
    ];
    final audios = [
      for (final a in widget.note.attachments)
        if (a.kind == AttachmentKind.audio) a,
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.aiTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(l10n.aiThinking),
                      ],
                    ),
                  )
                else if (_result != null)
                  _ResultView(
                    text: _result!,
                    onCopy: () async {
                      await Clipboard.setData(ClipboardData(text: _result!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l10n.copied)));
                      }
                    },
                    onReport: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref
                          .read(aiReportServiceProvider)
                          .report(content: _result!, source: 'ai_sheet');
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.aiReportThanks)),
                      );
                    },
                    // Önce alt sayfayı kapat, SONRA uygula: değerler önceden
                    // yakalanır. Eskiden callback önce, pop sonra çağrılıyordu;
                    // callback (editörde setState) bir istisna fırlatırsa pop'a
                    // ulaşılamıyor, alt sayfa açık kalıyor ve "Notu değiştir"
                    // tepkisiz görünüyordu. Sıra çevrildi: sayfa her hâlükârda
                    // kapanır, uygulama editörde çalışır.
                    onAppend: widget.onAppendText == null
                        ? null
                        : () {
                            final append = widget.onAppendText!;
                            final text = _result!;
                            Navigator.pop(context);
                            append(text);
                          },
                    onReplace:
                        widget.onReplaceText == null || !_lastWasImprovement
                        ? null
                        : () {
                            final replace = widget.onReplaceText!;
                            final text = _result!;
                            final type = _replaceAsType;
                            final keep = _keepChecked;
                            Navigator.pop(context);
                            replace(text, asType: type, keepChecked: keep);
                          },
                    // "Yeni not olarak aç": orijinal not değişmez, sonuç ayrı
                    // bir notta açılır. Her sonuç türünde (düzeltme/çeviri/
                    // özet/OCR) sunulur. Liste dönüşümü tipini yalnız düzeltme
                    // sonucunda taşı; diğerlerinde notun tipi editörde belirlenir.
                    onCreateNote: widget.onCreateNote == null
                        ? null
                        : () {
                            final create = widget.onCreateNote!;
                            final text = _result!;
                            final type = _lastWasImprovement
                                ? _replaceAsType
                                : null;
                            final keep = _keepChecked;
                            Navigator.pop(context);
                            create(text, asType: type, keepChecked: keep);
                          },
                  )
                else ...[
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          if (_retryAction != null)
                            TextButton.icon(
                              onPressed: _retryAction,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: Text(l10n.retry),
                            ),
                        ],
                      ),
                    ),
                  // Hızlı erişim: tek dokunuşla yazım/düzen düzeltmesi.
                  if (widget.onReplaceText != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: FilledButton.tonalIcon(
                        onPressed: widget.note.isEmpty ? null : _pickFixLevel,
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: Text(l10n.aiFixNote),
                      ),
                    ),
                  _sectionLabel(context, l10n.aiSectionNote),
                  // Notun tamamıyla (gövde + PDF/görsel ekleri) sohbet.
                  ListTile(
                    leading: const Icon(Icons.forum_outlined),
                    title: Text(l10n.noteChatTitle),
                    subtitle: Text(
                      l10n.noteChatIntro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    enabled:
                        !widget.note.isEmpty ||
                        widget.note.attachments.isNotEmpty,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DocChatScreen(note: widget.note),
                        ),
                      );
                    },
                  ),
                  // Alt yazılar iki benzer işlemin farkını söyler: özet kısa
                  // metin, analiz yapılacak/ana nokta dökümü.
                  ListTile(
                    leading: const Icon(Icons.summarize_outlined),
                    title: Text(l10n.aiSummarize),
                    subtitle: Text(l10n.aiSummarizeInfo),
                    enabled: !widget.note.isEmpty,
                    onTap: () => _run(
                      (s) => s.summarizeNote(widget.note),
                      cacheAsSummary: true,
                      cacheKey: AiCache.keyFor(
                        'note_summary',
                        widget.note.toPlainText(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: Text(l10n.aiAnalyze),
                    subtitle: Text(l10n.aiAnalyzeInfo),
                    enabled: !widget.note.isEmpty,
                    onTap: () => _run(
                      (s) => s.analyzeNote(widget.note),
                      cacheKey: AiCache.keyFor(
                        'note_analyze',
                        widget.note.toPlainText(),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(l10n.aiTranslate),
                    enabled: !widget.note.isEmpty,
                    onTap: _pickLanguageAndTranslate,
                  ),
                  if (widget.onReplaceText != null)
                    ListTile(
                      leading: const Icon(Icons.auto_fix_high_outlined),
                      title: Text(l10n.aiImprove),
                      enabled: !widget.note.isEmpty,
                      onTap: _pickImprovement,
                    ),
                  // Ekler: dosya adı satır başlığında BİR kez geçer, işlemler
                  // altında açılır. Eskiden her ek için adı tekrarlayan ayrı
                  // satırlar vardı (bir PDF = üç uzun satır).
                  if (pdfs.isNotEmpty ||
                      images.isNotEmpty ||
                      audios.isNotEmpty)
                    _sectionLabel(context, l10n.aiSectionAttachments),
                  for (final pdf in pdfs)
                    ExpansionTile(
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(
                        pdf.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.summarize_outlined),
                          title: Text(l10n.summarize),
                          onTap: () => _run(
                            (s) => _summarizePdf(s, pdf),
                            cacheKey: AiCache.keyFor('pdf_summary', pdf.id),
                          ),
                        ),
                        // Sesli dinleme: metin çıkarma ve okuma cihazda yapılır,
                        // model yalnız "podcast'e dönüştür" denirse çağrılır.
                        ListTile(
                          leading: const Icon(Icons.headphones_outlined),
                          title: Text(l10n.listen),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ListenScreen(
                                  title: pdf.fileName,
                                  loadText: () async => PdfText.cleanForSpeech(
                                    await PdfText.extract(pdf.localPath),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.question_answer_outlined),
                          title: Text(l10n.ask),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DocChatScreen(attachment: pdf),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  // Görsel ve seste tek işlem var: açılır satır gereksiz,
                  // işlem alt yazıda duruyor.
                  for (final image in images)
                    ListTile(
                      leading: const Icon(Icons.document_scanner_outlined),
                      title: Text(
                        image.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(l10n.extractText),
                      onTap: () => _run((s) => _extractImageText(s, image)),
                    ),
                  for (final audio in audios)
                    ListTile(
                      leading: const Icon(Icons.graphic_eq),
                      title: Text(
                        audio.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(l10n.transcribe),
                      onTap: () => _run((s) => _transcribeAudio(s, audio)),
                    ),
                  if (widget.note.aiSummary != null) ...[
                    const Divider(indent: 20, endIndent: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.aiSummaryTitle,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          // Sesli özet: özet zaten üretilmiş durumda,
                          // seslendirme cihazda yapılıyor — ek API çağrısı yok.
                          SpeakButton(text: widget.note.aiSummary!.text),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        widget.note.aiSummary!.text,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sayfa içi bölüm başlığı ("Bu not" / "Ekler"). Düz liste hangi işlemin
/// nota, hangisinin eke ait olduğunu göstermiyordu.
Widget _sectionLabel(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
  child: Text(
    text,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  ),
);

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.text,
    required this.onCopy,
    this.onReport,
    this.onAppend,
    this.onReplace,
    this.onCreateNote,
  });

  final String text;
  final VoidCallback onCopy;

  /// Sorunlu AI çıktısını bildirme (Play üretken AI politikası).
  final VoidCallback? onReport;
  final VoidCallback? onAppend;
  final VoidCallback? onReplace;

  /// Sonucu yeni bir notta açar (orijinal değişmeden kalır).
  final VoidCallback? onCreateNote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          // Wrap: dar ekranda butonlar taşmaz, gerekirse alt satıra sarılır
          // ("Nota ekle" ekranın dışında kalıp dokunulamıyordu).
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onReport != null)
                IconButton(
                  tooltip: context.l10n.aiReport,
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                ),
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 16),
                label: Text(context.l10n.copy),
              ),
              if (onCreateNote != null)
                FilledButton.tonalIcon(
                  onPressed: onCreateNote,
                  icon: const Icon(Icons.note_add_outlined, size: 18),
                  label: Text(context.l10n.openAsNewNote),
                ),
              if (onReplace != null)
                FilledButton.icon(
                  onPressed: onReplace,
                  icon: const Icon(Icons.published_with_changes, size: 18),
                  label: Text(context.l10n.replaceNote),
                ),
              if (onAppend != null)
                FilledButton.tonalIcon(
                  onPressed: onAppend,
                  icon: const Icon(Icons.playlist_add, size: 18),
                  label: Text(context.l10n.addToNote),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
