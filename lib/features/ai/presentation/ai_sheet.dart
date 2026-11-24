import '../../../core/app_icons.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_tile.dart';
import '../../../app/theme/app_tokens.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/markdown.dart';
import '../../../core/widgets/undo_snackbar.dart';
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
import 'ai_hub_screen.dart' show AiPointsBar;
import 'ai_result_note.dart';
import 'listen_screen.dart';
import '../data/gemini_service.dart';
import 'ai_chat_screen.dart';
import 'quiet_organize_sheet.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/friendly_error.dart';
import '../../auth/presentation/account_required.dart';
import '../../../core/widgets/sheet_keyboard.dart';

/// "Notu değiştir" geri çağırması: AI çıktısı notun içeriğiyle değiştirilir;
/// [asType] verilirse notun çalışma modu da o tipe geçer (madde/sıralı liste).
/// [keepChecked] true ise AI'a yalnız işaretsiz maddeler gönderilmiştir;
/// işaretli (tamamlanmış) maddeler değiştirilmeden korunmalı, sonuç yalnız
/// işaretsizlerin yerine geçer.
typedef ReplaceTextCallback = void Function(
  String text, {
  NoteType? asType,
  bool keepChecked,
});

/// Editördeki "Yapay Zeka" düğmesinin açtığı alt sayfa.
Future<void> showAiSheet(
  BuildContext context,
  Note note, {
  ValueChanged<String>? onAppendText,
  ReplaceTextCallback? onReplaceText,
  ReplaceTextCallback? onCreateNote,
  ValueChanged<Attachment>? onTranscribe,
  VoidCallback? onVoiceNote,
}) => showAppSheet<void>(
  context: context,
  isScrollControlled: true,
  // SheetHeader'da ✕ var → tutamak yok (DENEYIM K-D7).
  showDragHandle: false,
  builder: (_) => AiSheet(
    note: note,
    onAppendText: onAppendText,
    onReplaceText: onReplaceText,
    onCreateNote: onCreateNote,
    onTranscribe: onTranscribe,
    onVoiceNote: onVoiceNote,
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
    this.onVoiceNote,
  });

  final Note note;

  /// "AI ile sesli not": yapay zekâ dinleme levhasını açar (sonuç nota
  /// eklenir). Levhanın EN ÜST satırı — kullanıcı isteği 2026-10-20: "AI
  /// sesli notu AI menüsünün üzerine alalım"; editörün alt çubuğunda artık
  /// yalnız doğrudan yazdırma mikrofonu var.
  final VoidCallback? onVoiceNote;

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

  /// A7 özet uzunluk anahtarı: null = not özeti değil, false = kısa, true = ayrıntılı.
  bool? _summaryDetailed;

  /// A6 önce/sonra karşılaştırma için orijinal metin.
  String? _beforeText;

  /// A5 fotoğraftan yapılı notun önerilen başlığı (varsa önizleme üstünde).
  String? _resultHeader;

  /// [cacheKey] verilirse çıktı cihazda saklanır ve aynı girdi ikinci kez
  /// model çağırmaz. Anahtar içerikten türetildiği için not/PDF değişince
  /// kendiliğinden tazelenir — saat karşılaştırmasına gerek yok.
  /// Son başarısız işlemi tekrar deneyebilmek için saklanır (hata görünümünde
  /// "Tekrar dene").
  VoidCallback? _retryAction;

  Future<void> _runNoteSummary({required bool detailed}) => _run(
    (s) => s.summarizeNote(widget.note, detailed: detailed),
    cacheAsSummary: !detailed,
    cacheKey: AiCache.keyFor(
      detailed ? 'note_summary_detailed' : 'note_summary',
      widget.note.toPlainText(),
    ),
    summaryDetailed: detailed,
  );

  Future<void> _run(
    Future<String> Function(GeminiService) action, {
    bool cacheAsSummary = false,
    String? cacheKey,
    bool improvement = false,
    NoteType? replaceAsType,
    bool keepChecked = false,
    bool? summaryDetailed,
    String? beforeText,
    String? resultHeader,
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
      summaryDetailed: summaryDetailed,
      beforeText: beforeText,
      resultHeader: resultHeader,
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
      _summaryDetailed = summaryDetailed;
      _beforeText = beforeText;
      _resultHeader = resultHeader;
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
        setState(() => _error = aiErrorText(context.l10n, e));
      }
    } catch (e) {
      if (mounted) setState(() => _error = aiErrorText(context.l10n, e));
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
    return service.summarizeDocumentText(
      text,
      slide.fileName,
      detailed: detailed,
    );
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
  String _contentForTextOp({
    required bool skipChecked,
    required bool converting,
  }) {
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
  String get _listStructureConstraint => widget.note.type == NoteType.text
      ? ''
      : ' ÖNEMLİ: Bu bir listedir; girdideki HER SATIR ayrı bir maddedir. '
            'Çıktı da AYNI sayıda satır içermeli — her maddeyi kendi satırında '
            'ver, satırları BİRLEŞTİRME, tek paragrafa DÖNÜŞTÜRME, madde '
            'ekleme veya çıkarma. Her satırı tek tek düzelt.';

  /// **YAZIYI İYİLEŞTİR** (PLAN §1.6 A6): düzeltme, yeniden yazma,
  /// kısalt/uzat, resmî/samimi ton, liste dönüştürme ve çeviri tek menüde;
  /// yazım v3 anlık altı çizgiyle çakışmadan not düzeyinde çalışır ve sonuçta
  /// önce/sonra karşılaştırmalı önizleme sunar.
  Future<void> _pickWriteImprove() async {
    final l10n = context.l10n;
    final canReplace = widget.onReplaceText != null;
    final chosen = await showDialog<_WriteChoice>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.aiWriteImprove),
        children: [
          if (canReplace) ...[
            _dialogGroupTitle(dialogContext, l10n.aiWriteGroupFix),
            _writeOption(
              dialogContext,
              key: const ValueKey('ai-write-fix-simple'),
              icon: Icons.spellcheck,
              label: l10n.fixSimple,
              info: l10n.fixSimpleInfo,
              choice: _WriteChoice.rewrite(
                'Yalnızca yazım, imla, noktalama ve büyük/küçük harf hatalarını '
                'düzelt. Cümle yapısına, kelime seçimine veya sıralamaya DOKUNMA. '
                'Her satırı olduğu gibi ayrı tut; satır/madde sayısını KORU, '
                'satırları birleştirme veya bölme. Anlamı ve içeriği KORU; yeni '
                'bilgi ekleme, madde silme. $_fixCommon',
              ),
            ),
            _writeOption(
              dialogContext,
              key: const ValueKey('ai-write-fix-balanced'),
              icon: Icons.auto_fix_high,
              label: l10n.fixBalanced,
              info: l10n.fixBalancedInfo,
              choice: _WriteChoice.rewrite(
                'Yazım, imla ve noktalama hatalarını düzelt; ayrıca bozuk veya '
                'devrik cümleleri düzgün ve akıcı hale getir, gereksiz '
                'tekrarları sadeleştir. Anlamı ve tüm bilgileri KORU; yeni bilgi '
                'ekleme. Genel yapıyı ve satır düzenini olabildiğince koru. '
                '$_fixCommon',
              ),
            ),
            _writeOption(
              dialogContext,
              key: const ValueKey('ai-write-fix-detailed'),
              icon: Icons.edit_note,
              label: l10n.fixDetailed,
              info: l10n.fixDetailedInfo,
              choice: _WriteChoice.rewrite(
                'Metni baştan aşağı yeniden düzenle: yazım ve dilbilgisini düzelt, '
                'cümleleri akıcı ve profesyonel bir dille yeniden yaz, düşünceleri '
                'mantıklı bir akışa sok, gerekirse paragraflara ayır. Hiçbir '
                'bilgiyi ATLAMA veya uydurma; yalnızca var olan içeriği daha iyi '
                'ifade et. $_fixCommon',
              ),
            ),
            _dialogGroupTitle(dialogContext, l10n.aiWriteGroupTone),
            _writeOption(
              dialogContext,
              key: const ValueKey('ai-write-shorten'),
              icon: Icons.compress,
              label: l10n.improveShorten,
              choice: _WriteChoice.rewrite(
                'Anlamı koruyarak yarı uzunluğa kısalt. $_fixCommon',
              ),
            ),
            _writeOption(
              dialogContext,
              key: const ValueKey('ai-write-expand'),
              icon: Icons.expand,
              label: l10n.improveExpand,
              choice: _WriteChoice.rewrite(
                'Mevcut fikirleri ve olguları koruyarak daha açıklayıcı, '
                'ayrıntılı ve akıcı biçimde genişlet; uydurma bilgi ekleme. '
                '$_fixCommon',
              ),
            ),
            _writeOption(
              dialogContext,
              key: const ValueKey('ai-write-formal'),
              icon: Icons.business_center_outlined,
              label: l10n.improveFormal,
              choice: _WriteChoice.rewrite(
                'Daha resmî ve profesyonel bir dille yeniden yaz. $_fixCommon',
              ),
            ),
            _writeOption(
              dialogContext,
              key: const ValueKey('ai-write-casual'),
              icon: Icons.sentiment_satisfied_outlined,
              label: l10n.improveCasual,
              choice: _WriteChoice.rewrite(
                'Daha samimi, doğal ve günlük bir dille yeniden yaz. '
                '$_fixCommon',
              ),
            ),
            _dialogGroupTitle(dialogContext, l10n.aiWriteGroupFormat),
            _writeOption(
              dialogContext,
              key: const ValueKey('ai-write-bullets'),
              icon: Icons.checklist,
              label: l10n.improveBullets,
              choice: const _WriteChoice.rewrite(
                'Düzenli bir maddeler listesine dönüştür: her satır tek bir madde '
                'olsun, başına işaret/numara koyma',
                asType: NoteType.checklist,
              ),
            ),
            _writeOption(
              dialogContext,
              key: const ValueKey('ai-write-numbered'),
              icon: Icons.format_list_numbered,
              label: l10n.improveNumbered,
              choice: const _WriteChoice.rewrite(
                'Sıralı bir listeye dönüştür: içeriği mantıklı bir sıraya koy, '
                'her satır tek bir adım olsun, başına numara koyma',
                asType: NoteType.ordered,
              ),
            ),
          ],
          _dialogGroupTitle(dialogContext, l10n.aiTranslate),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.xs,
              AppSpace.xl,
              AppSpace.s,
            ),
            child: Wrap(
              spacing: AppSpace.s,
              runSpacing: AppSpace.xs,
              children: [
                for (final target in _translateTargets)
                  ActionChip(
                    key: ValueKey('ai-translate-$target'),
                    label: Text(target),
                    onPressed: () => Navigator.pop(
                      dialogContext,
                      _WriteChoice.translate(target),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen == null) return;
    if (chosen.language != null) {
      final skip = _skipCheckedForNote;
      final before = _contentForTextOp(skipChecked: skip, converting: false);
      await _run(
        (s) => s.translateText(before, chosen.language!),
        improvement: true,
        keepChecked: skip,
        beforeText: before,
      );
      return;
    }
    final converting = chosen.asType != null;
    final skip = !converting && _skipCheckedForNote;
    final before = _contentForTextOp(skipChecked: skip, converting: converting);
    final prompt = converting
        ? chosen.instruction!
        : chosen.instruction! + _listStructureConstraint;
    await _run(
      (s) => s.rewriteText(before, prompt),
      improvement: true,
      replaceAsType: chosen.asType,
      keepChecked: skip,
      beforeText: before,
    );
  }

  Widget _dialogGroupTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.m,
        AppSpace.xl,
        AppSpace.xs,
      ),
      child: Text(
        text,
        style: AppText.of(theme).meta.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: AppWeight.strong,
        ),
      ),
    );
  }

  SimpleDialogOption _writeOption(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    String? info,
    required _WriteChoice choice,
  }) => SimpleDialogOption(
    key: key,
    onPressed: () => Navigator.pop(context, choice),
    child: ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: AppIconSize.m),
      title: Text(label),
      subtitle: info == null ? null : Text(info),
    ),
  );

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
        ..showMessage(notSynced);
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

  /// **FOTOĞRAFTAN YAPILI NOT** (PLAN §1.6 A5): önce cihaz içi ücretsiz OCR
  /// (`ScanOcr.recognizeImageText`) metni çıkarır; metin yeterliyse görsel
  /// baytı yüklenmeden yalnız metin AI'ya gidip başlık + maddelere ayrılır.
  /// Cihaz içi OCR desteklenmiyorsa ya da boş dönerse görsel yedeği çalışır.
  Future<void> _runStructuredImage(Attachment image) async {
    final notSyncedMessage = context.l10n.attachmentNotSynced;
    final repo = ref.read(attachmentRepositoryProvider);
    String ocrText = '';
    if (ScanOcr.supported) {
      final path =
          image.localPath.isNotEmpty && localFileExists(image.localPath)
          ? image.localPath
          : await recognizableImagePath(image, repo);
      if (path != null) {
        try {
          ocrText = (await ScanOcr.recognizeImageText(path)).trim();
        } catch (_) {
          ocrText = '';
        }
      }
    }
    StructuredOcrNote? structured;
    await _run((service) async {
      var source = ocrText;
      if (source.length < 8) {
        final bytes = repo == null ? null : await repo.readBytes(image);
        if (bytes == null) {
          if (source.isEmpty) throw GeminiException(notSyncedMessage);
        } else {
          source = (await service.extractTextFromImage(
            bytes,
            image.mimeType,
          )).trim();
        }
      }
      final parsed = await service.structureOcrText(source);
      structured = parsed;
      return parsed.toFormattedText();
    });
    if (mounted && structured != null && _result != null) {
      setState(() {
        _replaceAsType = structured!.suggestedType == NoteType.text
            ? null
            : structured!.suggestedType;
        _resultHeader = structured!.title.trim().isEmpty
            ? null
            : structured!.title.trim();
      });
    }
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
    final offline = ref.watch(isOfflineProvider);
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
      child: SheetInsetPadding(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetHeader(title: l10n.aiTitle),
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
                    beforeText: _beforeText,
                    resultTitle: _resultHeader,
                    summaryDetailed: _summaryDetailed,
                    onSummaryDetailChanged: _summaryDetailed == null
                        ? null
                        : (detailed) => _runNoteSummary(detailed: detailed),
                    onCopy: () async {
                      await Clipboard.setData(ClipboardData(text: _result!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showMessage(l10n.copied);
                      }
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
                    // bir notta açılır. A6 liste dönüşümü ve A5 fotoğraftan
                    // yapılı notta önerilen tip (checklist/ordered) taşınır.
                    onCreateNote: widget.onCreateNote == null
                        ? null
                        : () {
                            final create = widget.onCreateNote!;
                            final text = _result!;
                            final type = _replaceAsType;
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
                  // Misafir, anahtarsız (F10.5): puan yerine açıklama kartı,
                  // araçlar soluk ve dokunulamaz.
                  // F79.6 (4): çevrimdışıyken düğmeler etkin görünüyor, hata
                  // ancak dokununca geliyordu — önce söyle, araçları soldur.
                  if (offline)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpace.l,
                        AppSpace.xs,
                        AppSpace.l,
                        AppSpace.m,
                      ),
                      child: AiOfflineCard(),
                    )
                  else if (ref.watch(aiAvailabilityProvider) !=
                      AiAvailability.ready)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpace.l,
                        AppSpace.xs,
                        AppSpace.l,
                        AppSpace.m,
                      ),
                      child: AiStatusCard(),
                    )
                  else if (!ref.watch(aiUnlimitedProvider))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.l,
                        AppSpace.xs,
                        AppSpace.l,
                        AppSpace.m,
                      ),
                      child: AiPointsBar(
                        remaining: ref.watch(freeAiRemainingProvider),
                        limit: ref.watch(aiDailyLimitProvider),
                      ),
                    ),
                  AiStatusDim(
                    locked:
                        offline ||
                        ref.watch(aiAvailabilityProvider) !=
                            AiAvailability.ready,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ÜÇ BÖLÜM (PLAN §1.6 AI-S2, 2026-11-18): Yaz · Sor ·
                        // Dönüştür. Bölüm fiile göre — kullanıcı "ne yapmak
                        // istiyorum"dan bakar, eki/notu değil. Sesli not Yaz'ın
                        // en üstünde kalır (kullanıcı isteği 2026-10-20).
                        _sectionLabel(context, l10n.aiSectionWrite),
                        if (widget.onVoiceNote != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpace.l,
                              0,
                              AppSpace.l,
                              AppSpace.s,
                            ),
                            child: _AiRow(
                              key: const ValueKey('ai-sheet-voice-note'),
                              icon: AppIcons.aiVoiceNote,
                              title: l10n.aiVoiceRowTitle,
                              subtitle: l10n.aiVoiceRowInfoEditor,
                              onTap: () {
                                final open = widget.onVoiceNote!;
                                Navigator.pop(context);
                                open();
                              },
                            ),
                          ),
                        // Yaz (PLAN §1.6 A6): düzelt · yeniden yaz · kısalt/uzat ·
                        // resmî/samimi · biçim · çevir — tek menü.
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.l,
                          ),
                          child: _AiRow(
                            key: const ValueKey('ai-sheet-write-improve'),
                            icon: Icons.auto_fix_high,
                            title: l10n.aiWriteImprove,
                            subtitle: l10n.aiWriteImproveInfo,
                            onTap: widget.note.isEmpty
                                ? null
                                : _pickWriteImprove,
                          ),
                        ),
                        // Sor (A1 notlarına sor, A4 belgeye sor).
                        _sectionLabel(context, l10n.aiSectionAsk),
                        // TEK SOHBET (F3.3): not, belgesi ya da tüm notlar;
                        // soru-cevap ya da beyin fırtınası — kapsam/kip ekranda.
                        // "Analiz et" (analyzeNote) AI-S1 kararıyla kalktı
                        // (2026-11-17): ana nokta/yapılacak soruları burada.
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.l,
                          ),
                          child: _AiRow(
                            key: const ValueKey('ai-sheet-chat'),
                            icon: Icons.forum_outlined,
                            title: l10n.aiChatRowTitle,
                            subtitle: l10n.aiChatRowInfo,
                            onTap: () {
                              Navigator.pop(context);
                              AiChatScreen.open(
                                context,
                                note: widget.note,
                                onAddToNote: widget.onAppendText,
                              );
                            },
                          ),
                        ),
                        for (final pdf in pdfs)
                          ListTile(
                            leading: const Icon(Icons.question_answer_outlined),
                            title: Text(
                              pdf.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(l10n.ask),
                            onTap: () {
                              Navigator.pop(context);
                              AiChatScreen.open(
                                context,
                                note: widget.note,
                                document: pdf,
                                scope: ChatScope.document,
                              );
                            },
                          ),
                        // Dönüştür (A7 özet, A2 kayıttan not, A5 fotoğraftan not,
                        // belge özeti/dinleme). Ekler: dosya adı satır başlığında
                        // BİR kez geçer, işlemler altında açılır.
                        _sectionLabel(context, l10n.aiSectionTransform),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.l,
                          ),
                          child: _AiRow(
                            key: const ValueKey('ai-sheet-summarize'),
                            icon: Icons.summarize_outlined,
                            title: l10n.aiSummarize,
                            subtitle: l10n.aiSummarizeInfo,
                            onTap: widget.note.isEmpty
                                ? null
                                : () => _runNoteSummary(detailed: false),
                          ),
                        ),
                        const SizedBox(height: AppSpace.s),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.l,
                          ),
                          child: _AiRow(
                            key: const ValueKey('ai-sheet-smart-categorize'),
                            icon: Icons.auto_awesome_mosaic_outlined,
                            title: l10n.aiSmartCategorizeAction,
                            subtitle: l10n.aiSmartCategorizeInfo,
                            onTap: () {
                              final nav = Navigator.of(context);
                              final host = nav.context;
                              nav.pop();
                              showQuietOrganizeSheet(
                                host,
                                preferLocalFirst: true,
                              );
                            },
                          ),
                        ),
                        if (pdfs.isNotEmpty ||
                            slides.isNotEmpty ||
                            images.isNotEmpty ||
                            audios.isNotEmpty ||
                            videos.isNotEmpty)
                          _sectionLabel(context, l10n.aiAttachmentsSection),
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
                                    (s) => _summarizePdf(
                                      s,
                                      pdf,
                                      detailed: detailed,
                                    ),
                                    cacheKey: AiCache.keyFor(
                                      detailed
                                          ? 'pdf_summary_detailed'
                                          : 'pdf_summary',
                                      pdf.id,
                                    ),
                                  );
                                },
                              ),
                              // Sesli dinleme: metin çıkarma ve okuma cihazda yapılır,
                              // model yalnız "podcast'e dönüştür" denirse çağrılır.
                              ListTile(
                                leading: const Icon(AppIcons.listen),
                                title: Text(l10n.listen),
                                onTap: () {
                                  final repo = ref.read(
                                    attachmentRepositoryProvider,
                                  );
                                  Navigator.pop(context);
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ListenScreen(
                                        title: pdf.fileName,
                                        allowCache: !widget.note.locked,
                                        loadText: () async {
                                          if (localFileExists(pdf.localPath)) {
                                            return PdfText.cleanForSpeech(
                                              await PdfText.extract(
                                                pdf.localPath,
                                              ),
                                            );
                                          }
                                          final bytes = await repo?.readBytes(
                                            pdf,
                                          );
                                          if (bytes == null) return '';
                                          return PdfText.cleanForSpeech(
                                            await PdfText.extractFromBytes(
                                              bytes,
                                            ),
                                          );
                                        },
                                      ),
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
                                    (s) => _summarizeSlide(
                                      s,
                                      slide,
                                      detailed: detailed,
                                    ),
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
                                leading: const Icon(AppIcons.listen),
                                title: Text(l10n.listen),
                                onTap: () {
                                  final repo = ref.read(
                                    attachmentRepositoryProvider,
                                  );
                                  Navigator.pop(context);
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ListenScreen(
                                        title: slide.fileName,
                                        allowCache: !widget.note.locked,
                                        loadText: () async {
                                          if (localFileExists(
                                            slide.localPath,
                                          )) {
                                            return DocText.extract(
                                              slide.localPath,
                                            );
                                          }
                                          final bytes = await repo?.readBytes(
                                            slide,
                                          );
                                          if (bytes == null) return '';
                                          return DocText.extractFromBytes(
                                            'pptx',
                                            bytes,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        // GÖRSELDE METİN + YAPILI NOT (PLAN §1.6 A5): ücretsiz cihaz
                        // içi "Metni tanı" ve önce cihaz içi OCR + ardından yalnız
                        // yapılandırma için AI kullanan "Yapılı nota dönüştür".
                        for (final image in images)
                          ExpansionTile(
                            key: ValueKey('ai-image-tile-${image.id}'),
                            leading: const Icon(
                              Icons.document_scanner_outlined,
                            ),
                            title: Text(
                              image.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            children: [
                              ListTile(
                                leading: const Icon(Icons.text_fields),
                                title: Text(l10n.extractText),
                                onTap: () => ScanOcr.supported
                                    ? _recognizeImageText(image)
                                    : _run((s) => _extractImageText(s, image)),
                              ),
                              ListTile(
                                key: ValueKey(
                                  'ai-photo-structured-${image.id}',
                                ),
                                leading: const Icon(
                                  Icons.auto_awesome_outlined,
                                ),
                                title: Text(l10n.aiPhotoToStructuredNote),
                                subtitle: Text(
                                  l10n.aiPhotoToStructuredNoteInfo,
                                ),
                                onTap: () => _runStructuredImage(image),
                              ),
                            ],
                          ),
                        for (final audio in audios)
                          ListTile(
                            leading: const Icon(AppIcons.voiceRecord),
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
                          const Divider(
                            indent: AppSpace.xl,
                            endIndent: AppSpace.xl,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpace.xl,
                              AppSpace.xs,
                              AppSpace.s,
                              AppSpace.xs,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.aiSummaryTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                ),
                                // Sesli özet: özet zaten üretilmiş durumda,
                                // seslendirme cihazda yapılıyor — ek API çağrısı yok.
                                SpeakButton(text: widget.note.aiSummary!.text),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpace.xl,
                              0,
                              AppSpace.xl,
                              AppSpace.s,
                            ),
                            child: Text(
                              widget.note.aiSummary!.text,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.l),
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
    super.key,
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

  // ORTAK ZENGİN KARO (DENEYIM F76.2): çerçeveli kart yerine
  // `SheetTile.rich` — zeminli, çerçevesiz; Paylaş levhasıyla aynı kılık.
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? AppAlpha.disabled : 1,
    child: SheetTile.rich(
      icon: icon,
      label: title,
      description: subtitle,
      onTap: onTap,
    ),
  );
}

/// Sayfa içi bölüm başlığı ("Bu not" / "Ekler"). Düz liste hangi işlemin
/// nota, hangisinin eke ait olduğunu göstermiyordu.
// Uygulamanın tek bölüm başlığı (TUTARLILIK F36.7).
Widget _sectionLabel(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.fromLTRB(
    AppSpace.l,
    AppSpace.m,
    AppSpace.l,
    AppSpace.xs,
  ),
  child: SectionLabel(text),
);

class _WriteChoice {
  const _WriteChoice.rewrite(this.instruction, {this.asType}) : language = null;

  const _WriteChoice.translate(this.language)
    : instruction = null,
      asType = null;

  final String? instruction;
  final NoteType? asType;
  final String? language;
}

class _ResultView extends StatefulWidget {
  const _ResultView({
    required this.text,
    required this.onCopy,
    this.beforeText,
    this.resultTitle,
    this.summaryDetailed,
    this.onSummaryDetailChanged,
    this.onAppend,
    this.onReplace,
    this.onCreateNote,
  });

  final String text;
  final String? beforeText;
  final String? resultTitle;
  final VoidCallback onCopy;
  final bool? summaryDetailed;
  final ValueChanged<bool>? onSummaryDetailChanged;
  final VoidCallback? onAppend;
  final VoidCallback? onReplace;

  /// Sonucu yeni bir notta açar (orijinal değişmeden kalır).
  final VoidCallback? onCreateNote;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  bool _compare = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final before = widget.beforeText?.trim();
    final canCompare =
        before != null && before.isNotEmpty && before != widget.text.trim();
    final header = widget.resultTitle?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.summaryDetailed != null &&
              widget.onSummaryDetailChanged != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.m),
              child: Wrap(
                spacing: AppSpace.s,
                runSpacing: AppSpace.xs,
                children: [
                  ChoiceChip(
                    key: const ValueKey('ai-summary-short'),
                    label: Text(l10n.summaryShort),
                    selected: !widget.summaryDetailed!,
                    onSelected: (selected) {
                      if (selected && widget.summaryDetailed!) {
                        widget.onSummaryDetailChanged!(false);
                      }
                    },
                  ),
                  ChoiceChip(
                    key: const ValueKey('ai-summary-detailed'),
                    label: Text(l10n.summaryDetailed),
                    selected: widget.summaryDetailed!,
                    onSelected: (selected) {
                      if (selected && !widget.summaryDetailed!) {
                        widget.onSummaryDetailChanged!(true);
                      }
                    },
                  ),
                ],
              ),
            ),
          if (canCompare)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.m),
              child: Wrap(
                spacing: AppSpace.s,
                runSpacing: AppSpace.xs,
                children: [
                  ChoiceChip(
                    key: const ValueKey('ai-preview-after-only'),
                    label: Text(l10n.aiPreviewAfter),
                    selected: !_compare,
                    onSelected: (s) {
                      if (s && _compare) setState(() => _compare = false);
                    },
                  ),
                  ChoiceChip(
                    key: const ValueKey('ai-preview-compare'),
                    label: Text(l10n.aiPreviewCompare),
                    selected: _compare,
                    onSelected: (s) {
                      if (s && !_compare) setState(() => _compare = true);
                    },
                  ),
                ],
              ),
            ),
          if (header != null && header.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s),
              child: Text(
                header,
                key: const ValueKey('ai-structured-title'),
                style: AppText.of(theme).rowTitle,
              ),
            ),
          if (_compare && canCompare) ...[
            Container(
              key: const ValueKey('ai-preview-before-box'),
              padding: const EdgeInsets.all(AppSpace.m),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiPreviewBefore,
                    style: AppText.of(theme).badge
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    before,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpace.l),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.m),
              border: _compare && canCompare
                  ? Border.all(
                      color: scheme.primary.withValues(alpha: AppAlpha.muted),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_compare && canCompare) ...[
                  Text(
                    l10n.aiPreviewAfter,
                    style: AppText.of(theme).badge
                        .copyWith(color: scheme.primary),
                  ),
                  const SizedBox(height: AppSpace.xs),
                ],
                SelectableText(widget.text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          // PL3 (b): "AI yanılabilir" + "Bildir" (kişisel veri gitmez).
          AiResultNote(content: widget.text, source: 'ai_sheet'),
          // Wrap: dar ekranda butonlar taşmaz, gerekirse alt satıra sarılır
          // ("Nota ekle" ekranın dışında kalıp dokunulamıyordu).
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpace.s,
            runSpacing: AppSpace.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: widget.onCopy,
                icon: const Icon(AppIcons.copy, size: AppIconSize.xs),
                label: Text(l10n.copy),
              ),
              if (widget.onCreateNote != null)
                FilledButton.tonalIcon(
                  onPressed: widget.onCreateNote,
                  icon: const Icon(
                    Icons.note_add_outlined,
                    size: AppIconSize.s,
                  ),
                  label: Text(l10n.openAsNewNote),
                ),
              if (widget.onReplace != null)
                FilledButton.icon(
                  onPressed: widget.onReplace,
                  icon: const Icon(
                    Icons.published_with_changes,
                    size: AppIconSize.s,
                  ),
                  label: Text(l10n.replaceNote),
                ),
              if (widget.onAppend != null)
                FilledButton.tonalIcon(
                  onPressed: widget.onAppend,
                  icon: const Icon(Icons.playlist_add, size: AppIconSize.s),
                  label: Text(l10n.addToNote),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
