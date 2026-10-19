import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/markdown.dart';
import 'speak_button.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/doc_text.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/data/pdf_text.dart';
import '../../notes/data/scan/scan_ocr.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/viewers/text_recognize_screen.dart';
import '../../settings/settings_providers.dart';
import '../data/ai_cache.dart';
import '../data/ai_gate.dart';
import '../data/ai_history.dart';
import '../data/ai_report.dart';
import 'ai_hub_screen.dart' show AiPointsBar;
import 'listen_screen.dart';
import '../data/gemini_service.dart';
import 'brainstorm_screen.dart';
import 'doc_chat_screen.dart';
import '../../../core/widgets/app_sheet.dart';

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
  ValueChanged<Attachment>? onTranscribe,
}) => showAppSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => AiSheet(
    note: note,
    onAppendText: onAppendText,
    onReplaceText: onReplaceText,
    onCreateNote: onCreateNote,
    onTranscribe: onTranscribe,
  ),
);

class AiSheet extends ConsumerStatefulWidget {
  const AiSheet({
    super.key,
    required this.note,
    this.onAppendText,
    this.onReplaceText,
    this.onCreateNote,
    this.onTranscribe,
  });

  final Note note;

  /// Ses/videonun TRANSKRİPT ekranını açar (bkz. `TranscriptScreen`) —
  /// verilmişse ses satırı sonucu levhada göstermek yerine oraya gider:
  /// döküm nota metin eki olarak kalır, seçilerek eklenir.
  final ValueChanged<Attachment>? onTranscribe;

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
    // KİLİTLİ notun içeriğinden türeyen çıktı diske yazılmaz: ai_cache düz
    // metin dosyalarıdır, kilidin sakladığı içerik oradan okunabilirdi.
    // Tek kapı burada — çağrı yerlerine bırakılsaydı biri unutulurdu.
    if (widget.note.locked) cacheKey = null;
    _retryAction = () => _run(
      action,
      cacheAsSummary: cacheAsSummary,
      cacheKey: cacheKey,
      improvement: improvement,
      replaceAsType: replaceAsType,
      keepChecked: keepChecked,
    );
    // Geçmiş etiketi HER asenkron adımdan önce okunur: sonrasında levha
    // kapanmış (context ağaçtan kalkmış) olabilir.
    final historyLabel = context.l10n.aiHistoryNoteAction;
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
      // Başarılı iş "SON İŞLEMLER"e girer; not içeriği değil yalnız işin adı.
      ref.read(aiHistoryProvider.notifier).record(historyLabel);
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

  Future<String> _summarizePdf(
    GeminiService service,
    Attachment pdf, {
    required bool detailed,
  }) async {
    final notSyncedMessage = context.l10n.attachmentNotSynced;
    final repo = ref.read(attachmentRepositoryProvider);
    final bytes = repo == null ? null : await repo.readBytes(pdf);
    if (bytes == null) {
      throw GeminiException(notSyncedMessage);
    }
    return service.summarizePdf(bytes, pdf.fileName, detailed: detailed);
  }

  Future<String> _summarizeSlide(
    GeminiService service,
    Attachment slide, {
    required bool detailed,
  }) async {
    final notSyncedMessage = context.l10n.attachmentNotSynced;
    final repo = ref.read(attachmentRepositoryProvider);
    final bytes = repo == null ? null : await repo.readBytes(slide);
    if (bytes == null) {
      throw GeminiException(notSyncedMessage);
    }
    final text = await DocText.extractFromBytes('pptx', bytes);
    return service.summarizeDocumentText(text, slide.fileName, detailed: detailed);
  }

  /// Özet ayrıntı düzeyini sorar: kısa mı, kaynağa bakmayı gereksiz kılan
  /// detaylı mı. null = kullanıcı vazgeçti.
  Future<bool?> _pickSummaryDetail() {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.summaryDetailTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.short_text),
              title: Text(l10n.summaryShort),
              subtitle: Text(l10n.summaryShortInfo),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.subject),
              title: Text(l10n.summaryDetailed),
              subtitle: Text(l10n.summaryDetailedInfo),
            ),
          ),
        ],
      ),
    );
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

  /// Karışık not (metin tipi + checklist maddeleri): düzeltme/geliştirme/çeviri
  /// gibi TİPİ KORUYAN işlemlerde yalnız gövde metni AI'a gider; maddeler olduğu
  /// gibi kalır. Aksi hâlde gövde + maddeler tek metne birleşip sonuç gövdeye
  /// yazılıyor, maddeler düz metne dönüşüyordu (kullanıcı: "madde karışık notu
  /// düzeltince maddeler düz metine dönüşüyor"). Tipi DEĞİŞTİREN dönüşümlerde
  /// (maddeye/sıralıya çevir) tüm içerik bilerek birleştirilir.
  String _contentForTextOp({required bool skipChecked, required bool converting}) {
    final note = widget.note;
    final mixed =
        note.type == NoteType.text &&
        note.items.any((i) => i.text.trim().isNotEmpty);
    if (mixed && !converting) return note.body.trim();
    return note.toContentText(skipChecked: skipChecked);
  }

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
    // "Notu düzelt" tipi korur: karışık notta yalnız gövde düzeltilir, maddeler
    // korunur (bkz. _contentForTextOp).
    await _run(
      (s) => s.rewriteText(
        _contentForTextOp(skipChecked: skip, converting: false),
        prompt,
      ),
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
    final converting = chosen.$2 != null;
    await _run(
      // İçerik metni (başlık/işaret yok): geliştirme sonucu nota geri
      // uygulanırken başlık öğeye, `[ ]`/numara işaretleri metne sızmasın.
      // Tipi koruyan geliştirmede (Resmî/Kısalt) karışık notun maddeleri
      // korunur; liste tipine dönüştürmede tüm içerik birleştirilir.
      (s) => s.rewriteText(
        _contentForTextOp(skipChecked: skip, converting: converting),
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
    // Çeviri tipi korur: karışık notta yalnız gövde çevrilir, maddeler korunur.
    await _run(
      (s) => s.translateText(
        _contentForTextOp(skipChecked: skip, converting: false),
        language,
      ),
      improvement: true,
      keepChecked: skip,
    );
  }

  /// Ortak tanıma ekranını açar; "Nota ekle" denirse metin notun gövdesine
  /// eklenir. Levha önce kapanır — ekran tam sayfa açılıyor.
  Future<void> _recognizeImageText(Attachment image) async {
    final append = widget.onAppendText;
    final messenger = ScaffoldMessenger.of(context);
    final notSynced = context.l10n.attachmentNotSynced;
    final navigator = Navigator.of(context);
    final path = await recognizableImagePath(
      image,
      ref.read(attachmentRepositoryProvider),
    );
    if (!mounted) return;
    if (path == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(notSynced)));
      return;
    }
    navigator.pop();
    final text = await navigator.push<String>(
      MaterialPageRoute<String>(
        builder: (_) => TextRecognizeScreen(
          imagePath: path,
          imageWidth: image.width ?? 0,
          imageHeight: image.height ?? 0,
          title: image.fileName,
          canInsert: append != null,
        ),
      ),
    );
    if (text != null && text.trim().isNotEmpty) append?.call(text.trim());
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
    // Video dökümü yalnız transkript ekranından (levhada sonucu gösteren
    // eski yol yok).
    final videos = [
      if (widget.onTranscribe != null)
        for (final a in widget.note.attachments)
          if (a.kind == AttachmentKind.video) a,
    ];
    final slides = [
      for (final a in widget.note.attachments)
        if (a.kind == AttachmentKind.slide) a,
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
                  // GÖRÜNÜM ana ekrandaki Yapay Zeka sayfasıyla AYNI dili
                  // konuşur (kullanıcı: "not içindeki ai alanı da yenilenmeli,
                  // ana sayfadaki genel ai alanı gibi olabilir"): üstte günlük
                  // puan çubuğu, altında asistan kartı, sonra iki sütunlu iş
                  // kutuları. Eskiden burası düz bir ListTile listesiydi ve
                  // hangi işin ne yaptığı ancak alt yazıyı okuyunca anlaşılıyordu.
                  // Sınırsız kullanıcıda (BYOK/premium) çubuk gizlenir: sayaç
                  // hiç azalmadığı için sürekli dolu görünüyor ve yanlış
                  // bilgi veriyordu (bkz. ai_hub_screen.dart).
                  if (!ref.watch(aiUnlimitedProvider))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: AiPointsBar(
                        remaining: ref.watch(freeAiRemainingProvider),
                        limit: ref.watch(aiDailyLimitProvider),
                      ),
                    ),
                  // Notun tamamıyla (gövde + PDF/görsel ekleri) sohbet.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _AiRow(
                      icon: Icons.forum_outlined,
                      title: l10n.noteChatTitle,
                      subtitle: l10n.noteChatIntro,
                      onTap:
                          widget.note.isEmpty &&
                              widget.note.attachments.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      DocChatScreen(note: widget.note),
                                ),
                              );
                            },
                    ),
                  ),
                  // **AI İLE BERABER DÜŞÜN** (kullanıcı isteği 2026-08-18):
                  // sohbetten bilerek AYRI bir satır — o soru-cevap, bu
                  // GENERATİF bir beyin fırtınası (bkz. brainstorm_screen.dart).
                  // Boş notta da anlamlı: AI başlıktan yola çıkıp ana hat
                  // önerir, o yüzden `note.isEmpty` burada engel değil.
                  if (widget.onAppendText != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _AiRow(
                        icon: Icons.lightbulb_outline,
                        title: l10n.brainstormTitle,
                        subtitle: l10n.brainstormRowInfo,
                        onTap: () {
                          Navigator.pop(context);
                          BrainstormScreen.open(
                            context,
                            widget.note,
                            onAddToNote: widget.onAppendText,
                          );
                        },
                      ),
                    ),
                  _sectionLabel(context, l10n.aiSectionNote),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _AiTileGrid(
                      tiles: [
                        // Hızlı erişim: tek dokunuşla yazım/düzen düzeltmesi.
                        if (widget.onReplaceText != null)
                          (
                            Icons.auto_fix_high,
                            l10n.aiFixNote,
                            l10n.aiFixNoteInfo,
                            widget.note.isEmpty ? null : _pickFixLevel,
                          ),
                        // Alt yazılar iki benzer işlemin farkını söyler: özet
                        // kısa metin, analiz yapılacak/ana nokta dökümü.
                        (
                          Icons.summarize_outlined,
                          l10n.aiSummarize,
                          l10n.aiSummarizeInfo,
                          widget.note.isEmpty
                              ? null
                              : () => _run(
                                  (s) => s.summarizeNote(widget.note),
                                  cacheAsSummary: true,
                                  cacheKey: AiCache.keyFor(
                                    'note_summary',
                                    widget.note.toPlainText(),
                                  ),
                                ),
                        ),
                        (
                          Icons.insights_outlined,
                          l10n.aiAnalyze,
                          l10n.aiAnalyzeInfo,
                          widget.note.isEmpty
                              ? null
                              : () => _run(
                                  (s) => s.analyzeNote(widget.note),
                                  cacheKey: AiCache.keyFor(
                                    'note_analyze',
                                    widget.note.toPlainText(),
                                  ),
                                ),
                        ),
                        (
                          Icons.translate,
                          l10n.aiTranslate,
                          l10n.aiTranslateInfo,
                          widget.note.isEmpty ? null : _pickLanguageAndTranslate,
                        ),
                        if (widget.onReplaceText != null)
                          (
                            Icons.auto_awesome_outlined,
                            l10n.aiImprove,
                            l10n.aiImproveInfo,
                            widget.note.isEmpty ? null : _pickImprovement,
                          ),
                      ],
                    ),
                  ),
                  // Ekler: dosya adı satır başlığında BİR kez geçer, işlemler
                  // altında açılır. Eskiden her ek için adı tekrarlayan ayrı
                  // satırlar vardı (bir PDF = üç uzun satır).
                  if (pdfs.isNotEmpty ||
                      slides.isNotEmpty ||
                      images.isNotEmpty ||
                      audios.isNotEmpty ||
                      videos.isNotEmpty)
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
                          onTap: () async {
                            final detailed = await _pickSummaryDetail();
                            if (detailed == null) return;
                            await _run(
                              (s) => _summarizePdf(s, pdf, detailed: detailed),
                              cacheKey: AiCache.keyFor(
                                detailed ? 'pdf_summary_detailed' : 'pdf_summary',
                                pdf.id,
                              ),
                            );
                          },
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
                                  allowCache: !widget.note.locked,
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
                  // Sunum ekleri: PDF gibi özetlenir (kısa/detaylı) ve sesli
                  // dinlenir. Metin cihazda PPTX'ten çıkarılıp modele gider.
                  for (final slide in slides)
                    ExpansionTile(
                      leading: const Icon(Icons.slideshow_outlined),
                      title: Text(
                        slide.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.summarize_outlined),
                          title: Text(l10n.summarize),
                          onTap: () async {
                            final detailed = await _pickSummaryDetail();
                            if (detailed == null) return;
                            await _run(
                              (s) =>
                                  _summarizeSlide(s, slide, detailed: detailed),
                              cacheKey: AiCache.keyFor(
                                detailed
                                    ? 'slide_summary_detailed'
                                    : 'slide_summary',
                                slide.id,
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.headphones_outlined),
                          title: Text(l10n.listen),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ListenScreen(
                                  title: slide.fileName,
                                  allowCache: !widget.note.locked,
                                  loadText: () async =>
                                      DocText.extract(slide.localPath),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  // Görsel ve seste tek işlem var: açılır satır gereksiz,
                  // işlem alt yazıda duruyor.
                  // GÖRSELDE METİN: cihaz içi tanıma varsa ortak "Metni Tanı"
                  // ekranı açılır (bkz. text_recognize_screen.dart) —
                  // uygulamada metin tanımanın TEK bir görünümü olsun
                  // (kullanıcı isteği 2026-08-09). ML Kit yoksa (masaüstü)
                  // eski model yolu sürer.
                  for (final image in images)
                    ListTile(
                      leading: const Icon(Icons.document_scanner_outlined),
                      title: Text(
                        image.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(l10n.extractText),
                      onTap: () => ScanOcr.supported
                          ? _recognizeImageText(image)
                          : _run((s) => _extractImageText(s, image)),
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
                      onTap: () {
                        final open = widget.onTranscribe;
                        if (open == null) {
                          _run((s) => _transcribeAudio(s, audio));
                          return;
                        }
                        Navigator.pop(context);
                        open(audio);
                      },
                    ),
                  for (final video in videos)
                    ListTile(
                      leading: const Icon(Icons.subtitles_outlined),
                      title: Text(
                        video.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(l10n.transcribe),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onTranscribe!(video);
                      },
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

/// Levhanın tam genişlikli satırı (asistan girişi). Yapay Zeka sayfasındaki
/// `_HubRow` ile aynı görünüm — iki yüzey aynı dili konuşsun.
class _AiRow extends StatelessWidget {
  const _AiRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// null: yapacak iş yok (boş not) — satır soluk ve dokunulamaz.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
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
      ),
    );
  }
}

/// İki sütunlu iş kutuları (özetle / analiz / çevir…). Yapay Zeka sayfasındaki
/// `_TaskTile` ızgarasının aynısı; işlem null ise kutu soluk ve dokunulamaz.
class _AiTileGrid extends StatelessWidget {
  const _AiTileGrid({required this.tiles});

  /// (simge, başlık, açıklama, işlem) — işlem null ise devre dışı.
  final List<(IconData, String, String, VoidCallback?)> tiles;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Levha yatayda 16+16 dolgulu; iki sütun, arada 8 px.
    final width = ((MediaQuery.sizeOf(context).width - 32 - 8) / 2).clamp(
      120.0,
      300.0,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (icon, title, info, onTap) in tiles)
          SizedBox(
            width: width,
            child: Opacity(
              opacity: onTap == null ? 0.5 : 1,
              child: Material(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 96),
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
                            height: 1.35,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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
