import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/constants.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/markdown.dart';
import '../../../../core/utils/note_guard.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../ai/data/ai_gate.dart';
import '../../../ai/data/gemini_service.dart';
import '../../../ai/presentation/ai_sheet.dart';
import '../../../ai/presentation/listen_screen.dart';
import '../../../folders/data/folders_repository.dart';
import '../../../folders/domain/note_folder.dart';
import '../../../folders/presentation/folder_sheets.dart';
import '../../../settings/data/permissions_service.dart';
import '../../../settings/settings_providers.dart';
import '../../data/attachment_repository.dart';
import '../../data/device_speech.dart';
import '../../data/notes_repository.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../../domain/note_item.dart';
import '../../domain/note_type.dart';
import '../color_picker_sheet.dart';
import '../notes_providers.dart';
import '../pdf_export_screen.dart';
import '../qr_scan_screen.dart';
import 'ai_result_sheet.dart';
import 'attachment_strip.dart';
import 'audio_recorder_sheet.dart';
import 'calculator_sheet.dart';
import 'dictation_sheet.dart';
import 'drawing_screen.dart';
import 'items_editor.dart';
import 'note_images.dart';
import 'text_wrap.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Bir liste satırının başındaki işaretleri ayıklar: madde imi (-, •, *),
/// numara (1. / 1)) ve onay kutusu ([ ], [x]). Onay kutusu doluysa
/// [checked] true döner. AI çıktısı / yapıştırılan metin nota geri
/// uygulanırken bu işaretlerin öğe metnine sızmasını engeller (madde 1:
/// "notların başına çift parantez ve çarpılı durum ekliyor").
({String text, bool checked}) _parseListLine(String line) {
  var s = line.trim();
  s = s.replaceFirst(RegExp(r'^[-•*]\s+'), '');
  s = s.replaceFirst(RegExp(r'^\d+[.)]\s+'), '');
  var checked = false;
  final box = RegExp(r'^\[\s*([xX])?\s*\]\s*').firstMatch(s);
  if (box != null) {
    checked = box.group(1) != null;
    s = s.substring(box.end);
  }
  return (text: s.trim(), checked: checked);
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.noteId,
    this.startDrawing = false,
    this.startVoiceCapture = false,
    this.startVideo = false,
    this.startPhoto = false,
  });

  final String noteId;

  /// El yazısı modu: editör açılır açılmaz çizim tuvali gösterilir,
  /// kaydedilen çizim nota görsel eki olarak girer.
  final bool startDrawing;

  /// Keep tarzı sesli not modu: editör açılır açılmaz ses kaydı + canlı
  /// döküm başlar; bitişte ses m4a eki olur, döküm notta kalır.
  final bool startVoiceCapture;

  /// (+) menüsündeki "Görüntülü not": açılışta kamera başlatılır.
  final bool startVideo;

  /// (+) menüsündeki "Foto çek not al": açılışta fotoğraf makinesi açılır,
  /// çekilen kare nota gömülür ve kullanıcı doğrudan yazmaya başlar.
  final bool startPhoto;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  Note? _note;
  final _titleController = TextEditingController();

  /// Gövde: kayan görsellerin etrafından akan metin için özel denetleyici.
  /// `.text` çapa karakterleri içerebilir — nota giden gövde her zaman
  /// `.logicalText` üzerinden okunur (bkz. text_wrap.dart).
  final _bodyController = WrapTextController();
  final _bodyFocus = FocusNode();

  /// KÖK NEDEN (ölçüldü): `dispose()` içinde `ref` kullanmak bu Riverpod
  /// sürümünde "Using ref when a widget is about to or has been unmounted is
  /// unsafe" hatası atar — atılan istisna yüzünden editörden ÇIKARKEN çalışan
  /// her şey sessizce ölüyordu: boş notun silinmesi, otomatik etiket/başlık,
  /// sürmekte olan sesli notun kaydı. Bu yüzden gereken bağımlılıklar her
  /// build'de alanlara alınır; `dispose` yalnız bu alanları kullanır.
  NotesRepository? _notesRepo;
  GeminiService? _gemini;
  bool _autoTagEnabled = true;
  bool _autoTitleEnabled = true;

  /// Süren AI işinin adı (null = çalışan yok). Uzun AI işleri (OCR, videodan
  /// not) tek bir SnackBar gösterip sessizleşiyordu: kullanıcı çalışıp
  /// çalışmadığını anlamıyor, dakikalar sonra gelen hatayı da bağlayamıyordu.
  /// Bu alan, editörün altındaki şeritte iş bitene kadar duran canlı bir
  /// gösterge sürer ve aynı işin ikinci kez başlatılmasını engeller.
  String? _aiTask;

  /// Uzun süren AI işlerinin TEK giriş noktası: göstergeyi açar/kapatır,
  /// hataları tek biçimde bildirir. Yeni bir AI özelliği eklenirken
  /// göstergeyi ayrıca düşünmek gerekmesin diye burada toplandı.
  Future<void> _runAi(String label, Future<void> Function() body) async {
    if (_aiTask != null) return;
    setState(() => _aiTask = label);
    try {
      await body();
    } on GeminiException catch (e) {
      if (mounted) {
        _showSnack(
          e.isAuthError ? context.l10n.aiNoApiKey : context.l10n.aiError(e.message),
        );
      }
    } catch (e) {
      if (mounted) _showSnack(context.l10n.aiError('$e'));
    } finally {
      if (mounted) setState(() => _aiTask = null);
    }
  }

  /// (+) menüsünden gelen ve not yüklenmeden çalıştırılamayan açılış
  /// niyetleri; not gelir gelmez bir kez çalıştırılır.
  bool _pendingDraw = false;
  bool _pendingVoice = false;
  bool _pendingVideo = false;
  bool _pendingPhoto = false;

  void _runPendingIntents() {
    if (!mounted || _note == null) return;
    if (_pendingDraw) {
      _pendingDraw = false;
      _addDrawing();
    }
    if (_pendingVoice) {
      _pendingVoice = false;
      _startVoiceCapture();
    }
    if (_pendingVideo) {
      _pendingVideo = false;
      _addVideo();
    }
    if (_pendingPhoto) {
      _pendingPhoto = false;
      _takePhoto();
    }
  }

  void _cacheDeps() {
    _notesRepo = ref.read(notesRepositoryProvider);
    _gemini = ref.read(geminiServiceProvider);
    _autoTagEnabled = ref.read(autoTagProvider);
    _autoTitleEnabled = ref.read(autoTitleProvider);
  }

  /// Gövde metninin sayfa tepesinden uzaklığı (başlık + çip satırının altı).
  /// Görseller bunun üzerine çıkamaz; sarma hesabı da buna göre yapılır.
  double _bodyTop = 0;
  final _bodyTopKey = GlobalKey();

  /// Gövde metninin sayfa kenarlarından boşluğu.
  static const double _kGutter = 16;

  /// Başlık bloğunun yüksekliğini ölçüp [_bodyTop]'u tazeler. Yükseklik
  /// yalnız başlık/çipler değişince oynar (sarma onu etkilemez), bu yüzden
  /// ölçüm yakınsar ve tek setState'te durur.
  void _measureBodyTop() {
    final box = _bodyTopKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final h = box.size.height;
    if ((h - _bodyTop).abs() < 0.5) return;
    setState(() => _bodyTop = h);
  }

  /// Tuvaldeki görsellerin sayfa uzayındaki bantları. Gövde metni ve liste
  /// maddeleri bunları [WrapFieldMeasure] ile kendi uzaylarına çevirip
  /// etrafından akar.
  List<FloatBox> _floats = const [];

  /// Sayfa içeriğinin kökü — alanların konumu buna göre ölçülür.
  final _pageKey = GlobalKey();
  RenderBox? _pageBox() {
    final box = _pageKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  void _applyFloats(List<FloatBox> floats) {
    if (sameFloatList(_floats, floats)) return;
    setState(() => _floats = floats);
  }

  /// Metin alanını sarma ölçümüne bağlar (görsel yoksa maliyetsiz geçer).
  Widget _wrapped(WrapTextController controller, Widget field) {
    final style = Theme.of(context).textTheme.bodyLarge;
    if (style == null) return field;
    return WrapFieldMeasure(
      controller: controller,
      style: style,
      floats: _floats,
      pageBox: _pageBox,
      child: field,
    );
  }
  final _debouncer = Debouncer();
  ProviderSubscription<AsyncValue<Note?>>? _sub;
  bool _deleted = false;

  /// Doğrudan (alt sayfasız) dikte durumu.
  StreamSubscription<({String? text, double? level})>? _speechSub;
  bool _dictating = false;

  @override
  void initState() {
    super.initState();
    // İlk açılış kasması (madde 3): editör başlangıçta _note null olduğu için
    // bir kare boyunca CircularProgressIndicator gösterip ardından tüm editörü
    // kuruyordu; bu geçiş, sayfa animasyonuyla aynı anda büyük bir yerleşim
    // sıçraması yaratıyordu. Not zaten dashboard akışında yüklü olduğundan
    // (kullanıcı oradan geldi) onu SENKRON okuyup ilk kareyi dolu kur —
    // spinner→editör takası ve onunla gelen kasma ortadan kalkar.
    final cached = _cachedNote();
    if (cached != null) {
      _note = cached;
      _titleController.text = cached.title;
      _bodyController.text = cached.body;
    }
    // KÖK NEDEN: (+) menüsünden gelen "Sesli not"/"El yazısı" niyetleri ilk
    // karede çalıştırılıyordu; yeni oluşturulan not dashboard önbelleğinde
    // henüz olmadığından `_note` null oluyor ve iki akış da SESSİZCE geri
    // dönüyordu (kayıt hiç başlamıyordu). Niyet artık beklemede tutulur ve
    // not eline geçtiği anda çalıştırılır.
    _pendingDraw = widget.startDrawing;
    _pendingVoice = widget.startVoiceCapture;
    _pendingVideo = widget.startVideo;
    _pendingPhoto = widget.startPhoto;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPendingIntents());
    _sub = ref.listenManual(noteStreamProvider(widget.noteId), (
      previous,
      next,
    ) {
      final incoming = next.value;
      if (incoming == null) return;
      if (_note == null) {
        setState(() {
          _note = incoming;
          _titleController.text = incoming.title;
          _bodyController.text = incoming.body;
        });
        // Not eline geçti: bekleyen sesli not/çizim niyeti şimdi çalışır.
        _runPendingIntents();
      } else {
        // Editör açıkken yerel metin esastır; yalnızca arka planda değişen
        // alanları (ek yüklemeleri, AI özeti) benimse.
        setState(() {
          _note = _note!.copyWith(
            attachments: incoming.attachments,
            aiSummary: incoming.aiSummary,
          );
        });
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _debouncer.flush();
    final note = _note;
    if (!_deleted && note != null && note.isEmpty) {
      // İçi boş kalan not çıkarken sessizce silinir.
      _notesRepo?.hardDelete(note.id);
    } else if (!_deleted && note != null) {
      if (note.tags.isEmpty) _autoTagInBackground(note);
      if (note.title.trim().isEmpty) _autoTitleInBackground(note);
    }
    _speechSub?.cancel();
    _debouncer.dispose();
    _sub?.close();
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  /// Dashboard akışında zaten yüklü olan notu senkron döndürür (varsa).
  /// İlk kareyi dolu kurup açılış kasmasını önlemek için kullanılır.
  Note? _cachedNote() {
    final notes = ref.read(notesStreamProvider).value;
    if (notes == null) return null;
    for (final n in notes) {
      if (n.id == widget.noteId) return n;
    }
    return null;
  }

  void _mutate(Note Function(Note) transform, {bool immediate = false}) {
    final note = _note;
    if (note == null) return;
    // Tek boğaz noktası: sarma çapaları düzenleme tamponunda yaşar, nota
    // asla yazılmaz. Gövde hangi yoldan gelirse gelsin burada temizlenir —
    // her çağrı yerine ayrı koruma koymak yerine tek yerde.
    setState(() {
      final next = transform(note);
      final clean = stripWrapAnchors(next.body);
      _note = clean == next.body ? next : next.copyWith(body: clean);
    });
    void save() {
      final current = _note;
      if (current != null && !_deleted) {
        ref.read(notesRepositoryProvider)?.updateNote(current);
      }
    }

    if (immediate) {
      _debouncer.cancel();
      save();
    } else {
      _debouncer(save);
    }
  }

  // ---- Ekler ----------------------------------------------------------

  /// "Dosya çok büyük" mesajı — sınır premium'a göre (50 MB) / ücretsiz (10 MB).
  String _tooLargeMessage() {
    final premium = ref.read(premiumProvider).value ?? false;
    final limitMb =
        (premium
            ? AppConstants.maxPremiumAttachmentBytes
            : AppConstants.maxFreeAttachmentBytes) ~/
        (1024 * 1024);
    return context.l10n.attachmentTooLarge(limitMb);
  }

  /// Yeni görselin sayfadaki başlangıç yeri ve boyu. Konum/boyut verilmezse
  /// tuval onu sol üste, sayfanın YARISI genişliğinde koyuyordu — yani doğrudan
  /// yazılmakta olan metnin üzerine. Bunun yerine küçük (%32) başlar ve
  /// sayfadaki mevcut içeriğin (son görselin ya da metnin) ALTINA yerleşir.
  Attachment _placeNewImage(Attachment image, Note note) {
    const width = 0.32;
    var top = _bodyTop + 24;
    for (final a in note.attachments) {
      if (a.kind != AttachmentKind.image) continue;
      final aspect = (a.width != null && a.height != null && a.height! > 0)
          ? a.width! / a.height!
          : 1.0;
      final pageWidth = _pageBox()?.size.width ?? 0;
      final bottom = (a.pageY ?? 0) + (pageWidth * (a.displayWidth ?? 0.5)) / aspect;
      if (bottom + 16 > top) top = bottom + 16;
    }
    // Sayfanın altına taşmasın: içerik yüksekliğini aşarsa oraya sabitlenir.
    final pageHeight = _pageBox()?.size.height;
    if (pageHeight != null && top > pageHeight) top = pageHeight;
    return image.copyWith(x: 0.06, pageY: top, displayWidth: width);
  }

  Future<void> _addImageBytes(Uint8List bytes, String fileName) async {
    final tooLargeMessage = _tooLargeMessage();
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      final attachment = await repo.prepareImage(
        noteId: widget.noteId,
        bytes: bytes,
        fileName: fileName,
      );
      _mutate(
        (n) => n.copyWith(
          attachments: [...n.attachments, _placeNewImage(attachment, n)],
        ),
        immediate: true,
      );
    } on FileTooLargeException {
      _showSnack(tooLargeMessage);
    } catch (e) {
      // Yalnız FileTooLargeException yakalanıyordu; başka her hata (web'de
      // dosya sistemi yok, disk dolu, izin reddi) yukarı kaçıp await'i
      // tamamlanmadan bırakıyordu → ekran donmuş görünüyor, mesaj çıkmıyordu.
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _pickImage() async {
    if (_isDesktop) {
      const group = XTypeGroup(
        label: 'Görseller',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      );
      final file = await openFile(acceptedTypeGroups: const [group]);
      if (file == null) return;
      await _addImageBytes(await file.readAsBytes(), file.name);
    } else {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      await _addImageBytes(await file.readAsBytes(), file.name);
    }
  }

  /// "Foto çek not al": kamerayla fotoğraf çekip nota gömer. Çekilen fotoğraf
  /// sıradan bir görsel ektir — sayfada sürüklenir, boyutlandırılır, üzerine
  /// yazılır ve "Metni al" ile OCR edilebilir.
  Future<void> _takePhoto() async {
    final l10n = context.l10n;
    // Manifest'te CAMERA bildirildiği için Android çekim niyetini izin
    // olmadan REDDEDER (bkz. _addVideo).
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) _showSnack(l10n.permCameraInfo);
      return;
    }
    if (!mounted) return;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera);
      if (picked == null) return;
      await _addImageBytes(await picked.readAsBytes(), picked.name);
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
  }

  /// QR/barkod okur (kameradan ya da galerideki bir fotoğraftan) ve okunan
  /// metni notun içine ekler.
  Future<void> _scanQr() async {
    final l10n = context.l10n;
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) _showSnack(l10n.permCameraInfo);
      return;
    }
    if (!mounted) return;
    final code = await openQrScanner(context);
    if (code == null || !mounted) return;
    _appendPlainText(code);
  }

  Future<void> _pickPdf() async {
    const group = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    // PDF sıkıştırılamaz (görsel ve ses küçültülüyor, bu küçültülemiyor) —
    // büyük dosya Firebase Storage kotasına doğrudan gider. Engellemek yerine
    // boyutu söyleyip kullanıcıya soruyoruz.
    if (bytes.length > AppConstants.largeAttachmentWarnBytes && mounted) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.largeAttachmentTitle),
          content: Text(context.l10n.largeAttachmentBody(mb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!mounted) return;
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      final attachment = await repo.preparePdf(
        noteId: widget.noteId,
        bytes: bytes,
        fileName: file.name,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException {
      if (mounted) _showSnack(_tooLargeMessage());
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _pickSlide() async {
    const group = XTypeGroup(
      label: 'Sunum',
      extensions: ['pptx'],
      // Android dosya seçici uzantı yerine MIME'a bakar; yalnız `extensions`
      // verilirse PowerPoint dosyaları soluk (seçilemez) görünür.
      mimeTypes: [
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      ],
    );
    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    // Sunum sıkıştırılamaz; PDF gibi büyük dosya doğrudan Storage kotasına
    // gider. Engellemek yerine boyutu söyleyip kullanıcıya soruyoruz.
    if (bytes.length > AppConstants.largeAttachmentWarnBytes && mounted) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.largeAttachmentTitle),
          content: Text(context.l10n.largeAttachmentBody(mb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!mounted) return;
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      final attachment = await repo.prepareSlide(
        noteId: widget.noteId,
        bytes: bytes,
        fileName: file.name,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException {
      if (mounted) _showSnack(_tooLargeMessage());
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _pasteImage() async {
    final bytes = await Pasteboard.image;
    if (bytes == null) {
      if (mounted) _showSnack(context.l10n.clipboardEmpty);
      return;
    }
    await _addImageBytes(bytes, 'pano.png');
  }

  Future<void> _recordAudio() async {
    final result = await showAudioRecorderSheet(context);
    if (result == null) return;
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      final attachment = await repo.prepareAudio(
        noteId: widget.noteId,
        sourcePath: result.path,
        duration: result.duration,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException {
      if (mounted) _showSnack(_tooLargeMessage());
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _addDrawing() async {
    final bytes = await Navigator.of(
      context,
    ).push<Uint8List>(MaterialPageRoute(builder: (_) => const DrawingScreen()));
    if (bytes == null) return;
    await _addImageBytes(bytes, 'cizim.png');
  }

  void _removeAttachment(Attachment attachment) {
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id != attachment.id) a,
        ],
      ),
      immediate: true,
    );
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo != null) {
      repo.deleteFromStorage(attachment).ignore();
    }
    if (attachment.localPath.isNotEmpty) {
      File(attachment.localPath).delete().ignore();
    }
  }

  /// Bir eki (görsel) yeni değerleriyle (genişlik/hiza) değiştirir — kullanıcı
  /// görseli notta elle boyutlandırıp hizalayınca çağrılır.
  void _updateAttachment(Attachment updated) {
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == updated.id) updated else a,
        ],
      ),
      immediate: true,
    );
  }

  /// Alt bardaki bir düğme (görünüm/renk, ek, hesap makinesi) alt sayfa/menü
  /// açmadan önce klavyeyi kesin kapatır. Klavye elle kapatılmış olsa bile bir
  /// metin alanı odakta kalabiliyor; alt sayfa kapanınca odak geri gelip
  /// klavye kendiliğinden açılıyordu (madde 10). Odağı düşürüp sonraki karede
  /// tekrar düşürerek bu geri açılmayı engelliyoruz.
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Future<void> _showAttachMenu() async {
    _dismissKeyboard();
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.addImage),
              onTap: () => Navigator.pop(sheetContext, 'image'),
            ),
            // Kamerayla anında fotoğraf: masaüstünde/web'de çekim yolu yok.
            if (!kIsWeb && !_isDesktop)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.takePhoto),
                onTap: () => Navigator.pop(sheetContext, 'camera'),
              ),
            if (qrScanSupported)
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(l10n.qrScanTitle),
                subtitle: Text(l10n.qrScanSubtitle),
                onTap: () => Navigator.pop(sheetContext, 'qr'),
              ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.addPdf),
              onTap: () => Navigator.pop(sheetContext, 'pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.slideshow_outlined),
              title: Text(l10n.addSlide),
              onTap: () => Navigator.pop(sheetContext, 'slide'),
            ),
            ListTile(
              leading: const Icon(Icons.brush_outlined),
              title: Text(l10n.addDrawing),
              onTap: () => Navigator.pop(sheetContext, 'drawing'),
            ),
            // Tarayıcıda gizli: `record` web'de dosya yolu değil blob adresi
            // döndürüyor, ek akışı ise yol bekliyor (bkz. prepareAudio).
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.mic_none),
                title: Text(l10n.recordAudio),
                onTap: () => Navigator.pop(sheetContext, 'audio'),
              ),
            // Görüntülü not da cihaz dosyası ister; web'de kapalı.
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: Text(l10n.newVideoNote),
                subtitle: Text(l10n.videoLocalOnly),
                onTap: () => Navigator.pop(sheetContext, 'video'),
              ),
            if (_isDesktop)
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: Text(l10n.pasteImage),
                onTap: () => Navigator.pop(sheetContext, 'paste'),
              ),
          ],
          ),
        ),
      ),
    );
    switch (action) {
      case 'image':
        await _pickImage();
      case 'camera':
        await _takePhoto();
      case 'qr':
        await _scanQr();
      case 'pdf':
        await _pickPdf();
      case 'slide':
        await _pickSlide();
      case 'drawing':
        await _addDrawing();
      case 'audio':
        await _recordAudio();
      case 'video':
        await _addVideo();
      case 'paste':
        await _pasteImage();
    }
  }

  // ---- Diğer eylemler -------------------------------------------------

  Future<void> _pickReminder() async {
    final note = _note;
    if (note == null) return;
    final now = DateTime.now();
    final initial = note.reminderAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final reminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _mutate((n) => n.copyWith(reminderAt: reminder), immediate: true);
  }

  void _clearReminder() =>
      _mutate((n) => n.copyWith(clearReminderAt: true), immediate: true);

  /// Ayarlarda açıksa, editör kapanırken etiketsiz notu arka planda
  /// AI ile etiketler.
  void _autoTagInBackground(Note note) {
    if (note.toPlainText().length < 20) return;
    if (!_autoTagEnabled) return;
    final service = _gemini;
    final repo = _notesRepo;
    if (repo == null || service == null) return;
    Future(() async {
      try {
        final tags = await service.suggestTags(note);
        if (tags.isNotEmpty) repo.updateFields(note.id, {'tags': tags});
      } catch (_) {
        // Anahtar yoksa veya istek başarısızsa sessizce geç.
      }
    });
  }

  /// Editör kapanırken başlıksız kalan nota arka planda AI başlık yazar
  /// (Ayarlar > Yapay Zeka > "Kapatırken başlık öner", varsayılan açık).
  /// "Başlık öner" çipiyle aynı üreticiyi kullanır; akışı kesmez.
  void _autoTitleInBackground(Note note) {
    if (note.isEmpty || !_autoTitleEnabled) return;
    final service = _gemini;
    final repo = _notesRepo;
    if (repo == null || service == null) return;
    Future(() async {
      try {
        final title = await service.generateTitle(note);
        if (title.isNotEmpty) repo.updateFields(note.id, {'title': title});
      } catch (_) {
        // Kota/anahtar hatasında sessizce geç — başlıksız kalması sorun değil.
      }
    });
  }

  bool _titleGenerating = false;

  /// "Başlık öner" çipi: nota AI ile kısa bir başlık üretir ve doğrudan
  /// başlık alanına yazar (etiket önerisi gibi bağımsız, isteğe bağlı buton;
  /// eski "kapanırken otomatik başlık" genel ayarının yerini aldı).
  Future<void> _suggestTitle() async {
    final note = _note;
    if (note == null || note.isEmpty || _titleGenerating) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _titleGenerating = true);
    try {
      final title = await ref.read(geminiServiceProvider).generateTitle(note);
      if (!mounted || title.isEmpty) return;
      _titleController.text = title;
      _mutate((n) => n.copyWith(title: title), immediate: true);
    } on GeminiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _titleGenerating = false);
    }
  }

  /// AI'dan etiket önerisi al ve seçtir.
  Future<void> _suggestTags() async {
    final note = _note;
    if (note == null || note.isEmpty) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    // Etiket önerisi de görünür olsun: eskiden istek boyunca hiçbir belirti
    // yoktu, kullanıcı düğmeye ikinci kez basıyordu.
    List<String> suggestions = const [];
    var failed = false;
    await _runAi(l10n.aiThinking, () async {
      try {
        suggestions = await ref.read(geminiServiceProvider).suggestTags(note);
      } on GeminiException catch (e) {
        failed = true;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message),
            ),
          ),
        );
      }
    });
    if (failed || !mounted) return;
    suggestions = [
      for (final tag in suggestions)
        if (!note.tags.contains(tag)) tag,
    ];
    if (suggestions.isEmpty || !mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Wrap(
            spacing: 8,
            children: [
              for (final tag in suggestions)
                ActionChip(
                  label: Text('#$tag'),
                  onPressed: () => Navigator.pop(sheetContext, tag),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      _mutate(
        (n) => n.copyWith(tags: {...n.tags, selected}.toList()),
        immediate: true,
      );
    }
  }

  String _cleanTag(String raw) =>
      raw.trim().replaceAll('#', '').replaceAll(' ', '-').toLowerCase();

  void _applyTag(String cleaned) {
    if (cleaned.isEmpty) return;
    _mutate(
      (n) => n.copyWith(tags: {...n.tags, cleaned}.toList()),
      immediate: true,
    );
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final l10n = context.l10n;
    // Daha önce kullanılmış, bu notta OLMAYAN etiketler diyalogda çip olarak
    // sunulur — kullanıcı yeniden yazmak yerine dokunup ekler.
    final note = _note;
    final existing = [
      for (final t in ref.read(allTagsProvider))
        if (note == null || !note.tags.contains(t)) t,
    ];
    final tag = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addTag),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.tagHint),
              onSubmitted: (value) => Navigator.pop(dialogContext, value),
            ),
            if (existing.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.existingTagsLabel,
                style: Theme.of(dialogContext).textTheme.labelMedium?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // Çok etiket varsa diyalog taşmasın: sınırlı yükseklikte kaydırılır.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final t in existing)
                        ActionChip(
                          label: Text('#$t'),
                          onPressed: () {
                            // Çipe dokununca doğrudan eklenir (metin kutusuna
                            // yazmaya gerek yok), diyalog kapanır.
                            Navigator.pop(dialogContext);
                            _applyTag(t);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    controller.dispose();
    if (tag != null) _applyTag(_cleanTag(tag));
  }

  void _removeTag(String tag) => _mutate(
    (n) => n.copyWith(
      tags: [
        for (final t in n.tags)
          if (t != tag) t,
      ],
    ),
    immediate: true,
  );

  /// Notu bir klasöre taşır (ya da klasörden çıkarır).
  Future<void> _pickFolder() async {
    final note = _note;
    if (note == null) return;
    final picked = await showFolderPickSheet(
      context,
      ref,
      currentFolderId: note.folderId,
    );
    if (picked == null) return;
    _mutate(
      (n) => picked.isEmpty
          ? n.copyWith(clearFolderId: true)
          : n.copyWith(folderId: picked),
      immediate: true,
    );
  }

  Future<void> _share() async {
    final note = _note;
    if (note == null) return;
    final text = note.toPlainText();
    if (text.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: note.title.trim().isEmpty ? 'Not' : note.title.trim(),
      ),
    );
  }

  /// Notu cihazın TTS'iyle sesli okur (model çağrısı yok). Kilitli notta
  /// ayrıca doğrulama yok — editör zaten açılırken doğruluyor.
  Future<void> _listen() async {
    final note = _note;
    if (note == null) return;
    final title = note.title.trim();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenScreen(
          title: title.isEmpty ? context.l10n.appName : title,
          // toPlainText değil: başlık ve `- [x]` işaretleri okunmasın.
          loadText: () async => note.toContentText(),
        ),
      ),
    );
  }

  /// Not kilidi: kilitlemek serbest, kilidi kaldırmak kimlik doğrulaması
  /// ister (kart zaten açarken doğruluyor ama menüden de korunmalı).
  Future<void> _toggleLock() async {
    final note = _note;
    if (note == null) return;
    if (note.locked) {
      final ok = await authenticateForNote(context.l10n.unlockAuthReason);
      if (!ok) return;
    }
    _mutate((n) => n.copyWith(locked: !n.locked), immediate: true);
  }

  void _toggleArchive() {
    final note = _note;
    if (note == null) return;
    final archived = note.archivedAt != null;
    _mutate(
      (n) => archived
          ? n.copyWith(clearArchivedAt: true)
          : n.copyWith(archivedAt: DateTime.now()),
      immediate: true,
    );
    if (!archived) Navigator.of(context).pop();
  }

  /// AI çıktısıyla notun içeriğini değiştirir ("Geliştir" sonuçları için).
  /// [asType] verilirse not o çalışma moduna da geçirilir: "maddelere çevir"
  /// sonucu yalnızca metni değil notun tipini de checklist/sıralı yapar.
  void _replaceText(String raw, {NoteType? asType, bool keepChecked = false}) {
    final note = _note;
    // Model istenmese de ** / * / # üretebiliyor; not düz metin tuttuğundan
    // temizle.
    final text = stripMarkdown(raw);
    if (note == null || text.trim().isEmpty) return;
    // Değişiklik öncesi anlık görüntü: "Geri al" bununla eski hâle döner.
    final before = note;
    final targetType = asType ?? note.type;
    // İşaretli maddeler AI'a hiç gönderilmemişti (ayar açık): sonuç yalnız
    // işaretsizlerin yerine geçer, işaretli (tamamlanmış) maddeler metni ve
    // işaretiyle AYNEN korunur — sonlarına eklenir (uygulamanın "işaretliler
    // altta" düzeni). Kullanıcının "işaretlilere karışma" isteği.
    if (keepChecked && targetType == NoteType.checklist) {
      const uuid = Uuid();
      final newUnchecked = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty)
            NoteItem(id: uuid.v4(), text: _parseListLine(line).text),
      ];
      final preservedChecked = [
        for (final item in note.items)
          if (item.checked) item,
      ];
      _mutate(
        (n) => n.copyWith(items: [...newUnchecked, ...preservedChecked]),
        immediate: true,
      );
      _offerReplaceUndo(before);
      return;
    }
    if (targetType == NoteType.text) {
      _bodyController.text = text.trim();
      _mutate(
        (n) => n.copyWith(type: targetType, body: text.trim()),
        immediate: true,
      );
    } else {
      const uuid = Uuid();
      final parsed = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty) _parseListLine(line),
      ];
      // Tip korunuyor ve öğe sayısı birebir aynıysa (düzeltme sırayı bozmaz)
      // mevcut kimlikler ve işaretli/işaretsiz durum korunur — kullanıcının
      // işaretlediği maddeler düzeltme sonrası işaretli kalır.
      final keepState =
          targetType == note.type && parsed.length == note.items.length;
      // Sayı/sıra değişse de (kısaltma, yeniden sıralama) işaret durumu
      // kaybolmasın: eski öğelerin normalize metni → işaret eşlemesi kurulur,
      // yeni satır eskisiyle (yazım düzeltilmiş de olsa birebir eşleşen)
      // bulunursa işareti devralır.
      String norm(String s) => s.trim().toLowerCase();
      final oldChecked = {
        for (final item in note.items) norm(item.text): item.checked,
      };
      _mutate(
        (n) => n.copyWith(
          type: targetType,
          // Tip değişiyorsa eski gövde temizlenir; içerik artık öğelerde.
          body: targetType == note.type ? null : '',
          items: [
            for (var i = 0; i < parsed.length; i++)
              NoteItem(
                id: keepState ? n.items[i].id : uuid.v4(),
                text: parsed[i].text,
                // Sıralı listede işaret anlamsız; checklist'te korunur/okunur.
                checked: targetType != NoteType.checklist
                    ? false
                    : keepState
                    ? n.items[i].checked
                    : (oldChecked[norm(parsed[i].text)] ?? parsed[i].checked),
              ),
          ],
        ),
        immediate: true,
      );
      if (targetType != note.type) _bodyController.clear();
    }
    _offerReplaceUndo(before);
  }

  /// "Notu değiştir" sonrası geri alma: eski not anlık görüntüsüne (metin,
  /// öğeler, tip, başlık) tek dokunuşla döner.
  void _offerReplaceUndo(Note before) {
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: context.l10n.noteUpdatedUndo,
      undoLabel: context.l10n.undo,
      onUndo: () {
        _titleController.text = before.title;
        _bodyController.text = before.body;
        setState(() => _note = before);
        ref.read(notesRepositoryProvider)?.updateNote(before);
      },
    );
  }

  /// AI çıktısını ORİJİNAL notu değiştirmeden YENİ bir notta açar (madde 1-2).
  /// Böylece kullanıcıda hem "değiştirmeden" orijinal hem de "düzeltilmiş"
  /// sürüm ayrı notlar olarak kalır. Başlık ve klasör yeni nota taşınır;
  /// [asType] verilirse (liste dönüşümü) yeni not o tipte oluşturulur.
  Future<void> _createNoteFromText(
    String raw, {
    NoteType? asType,
    bool keepChecked = false,
  }) async {
    final note = _note;
    final text = stripMarkdown(raw);
    if (note == null || text.trim().isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final type = asType ?? note.type;
    final id = await repo.createNote(type);
    final fields = <String, dynamic>{};
    if (note.title.trim().isNotEmpty) fields['title'] = note.title;
    if (note.folderId != null) fields['folderId'] = note.folderId;
    if (type == NoteType.text) {
      fields['body'] = text.trim();
      // Karışık not (metin + checklist): AI yalnız gövdeyi düzeltti; maddeler
      // yeni notta da olduğu gibi korunur (düz metne dönüşmez).
      final items = [
        for (final i in note.items)
          if (i.text.trim().isNotEmpty) i,
      ];
      if (items.isNotEmpty) {
        fields['items'] = [for (final i in items) i.toMap()];
      }
    } else {
      const uuid = Uuid();
      final items = <NoteItem>[];
      for (final line in text.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parsed = _parseListLine(line);
        items.add(
          NoteItem(
            id: uuid.v4(),
            text: parsed.text,
            checked: type == NoteType.checklist ? parsed.checked : false,
          ),
        );
      }
      // İşaretliler kapsam dışıydı: korunan (tamamlanmış) maddeler yeni notta
      // da işaretli olarak sona eklenir (işaretsiz düzeltilmişlerin ardına).
      if (keepChecked && type == NoteType.checklist) {
        for (final item in note.items) {
          if (item.checked) {
            items.add(NoteItem(id: uuid.v4(), text: item.text, checked: true));
          }
        }
      }
      fields['items'] = [for (final it in items) it.toMap()];
      // createNote liste tipini bir boş öğeyle tohumlar; gövde artık öğelerde.
      fields['body'] = '';
    }
    repo.updateFields(id, fields);
    if (mounted) context.push('/note/$id');
  }

  /// AI çıktısını (OCR/döküm) notun gövdesine ya da liste öğelerine ekler.
  /// Markdown işaretleri temizlenir — model istenmese de **kalın**/# üretiyor.
  void _appendText(String raw) => _appendPlainText(stripMarkdown(raw));

  /// Metni OLDUĞU GİBİ (Markdown temizliği yapmadan) nota ekler. QR içeriği
  /// gibi makine verisinde temizlik zararlı: `#` ile başlayan bir satır ya da
  /// `*` taşıyan bir adres bozulurdu.
  void _appendPlainText(String text) {
    final note = _note;
    if (note == null || text.trim().isEmpty) return;
    if (note.type == NoteType.text) {
      final combined = note.body.trim().isEmpty
          ? text.trim()
          : '${note.body}\n\n${text.trim()}';
      _bodyController.text = combined;
      _mutate((n) => n.copyWith(body: combined), immediate: true);
    } else {
      const uuid = Uuid();
      final lines = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty) _parseListLine(line).text,
      ];
      _mutate((n) {
        // Listede sonda hep boş bir "yeni öğe" satırı bekler. Yeni maddeler
        // onun ARKASINA eklenince o boş satır ortada kalıyordu; eklemeden
        // önce sondaki boşlar atılır. Dikte ve AI ekleme aynı yoldan
        // geçtiğinden ikisi de düzelir.
        final kept = [...n.items];
        while (kept.isNotEmpty && kept.last.text.trim().isEmpty) {
          kept.removeLast();
        }
        return n.copyWith(
          items: [
            ...kept,
            for (final line in lines) NoteItem(id: uuid.v4(), text: line),
          ],
        );
      }, immediate: true);
    }
  }

  /// Resmin araç çubuğundaki "Metni al" düğmesi: görseldeki metni çıkarır
  /// (OCR) ve nota ekler (madde 3). AI sayfasına girmeden doğrudan resimden
  /// erişilir; sonuç [_appendText] ile gövdeye/öğelere eklenir.
  Future<void> _ocrImage(Attachment image) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    final bytes = await repo.readBytes(image);
    if (!mounted) return;
    if (bytes == null) {
      _showSnack(l10n.attachmentNotSynced);
      return;
    }
    await _runAi(l10n.aiThinking, () async {
      final service = ref.read(geminiServiceProvider);
      final text = stripMarkdown(
        await service.extractTextFromImage(bytes, image.mimeType),
      ).trim();
      if (!mounted || text.isEmpty) return;
      _appendText(text);
    });
  }

  /// Görüntülü not: kamerayla video çeker ve nota ek yapar. Video buluta
  /// GİTMEZ, yalnızca cihazda kalır (kullanıcı isteği). Süre sınırı, videonun
  /// AI'a satır içi gönderilebilmesi için gerekir — uzun kayıt modelin boyut
  /// sınırına takılır.
  static const _maxVideoSeconds = 60;

  Future<void> _addVideo() async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    // Manifest'te CAMERA bildirildiği için Android çekim niyetini izin
    // olmadan REDDEDER (image_picker'ın kendisi istemez). İlk açılış
    // tanıtımını atlayan kullanıcıda burada sorulur.
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) _showSnack(l10n.permCameraInfo);
      return;
    }
    if (!mounted) return;
    try {
      final picked = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: _maxVideoSeconds),
      );
      if (picked == null || !mounted) return;
      final attachment = await repo.prepareVideo(
        noteId: widget.noteId,
        sourcePath: picked.path,
        duration: Duration.zero,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
      if (mounted) _showSnack(l10n.videoLocalOnly);
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
  }

  /// Videodan (görüntü + ses) detaylı not çıkarır ve gövdeye ekler.
  Future<void> _videoToNote(Attachment video) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    final bytes = await repo.readBytes(video);
    if (!mounted) return;
    if (bytes == null) {
      _showSnack(l10n.attachmentNotSynced);
      return;
    }
    // Satır içi gönderim sınırı: büyük video istekte reddediliyor ve hata
    // dakikalar sonra geliyordu. Sınır ÖNCEDEN, anlaşılır biçimde söylenir.
    const maxInlineBytes = 15 * 1024 * 1024;
    if (bytes.length > maxInlineBytes) {
      _showSnack(l10n.videoTooBigForAi(bytes.length ~/ (1024 * 1024)));
      return;
    }
    await _runAi(l10n.videoToNoteRunning, () async {
      final text = stripMarkdown(
        await ref
            .read(geminiServiceProvider)
            .noteFromVideo(bytes, video.mimeType),
      ).trim();
      if (!mounted || text.isEmpty) return;
      // Sonuç doğrudan nota YAZILMAZ: önce geniş inceleme sayfasında görülür,
      // istenirse biçimi (düz metin/madde/sıralı) değiştirilip nota eklenir
      // ya da yeni not olarak açılır.
      await showAiResultSheet(
        context,
        title: l10n.videoToNote,
        text: text,
        onInsert: _appendText,
        onCreateNote: (t, {NoteType? asType}) =>
            _createNoteFromText(t, asType: asType),
      );
    });
  }

  /// Palet düğmesi: zemin rengi ve renkli çerçeve seçimi. İkisi ayrı alanlar —
  /// renkli zeminli bir nota farklı renkte çerçeve verilebilir (madde 4).
  Future<void> _showColorSheet() async {
    final note = _note;
    if (note == null) return;
    _dismissKeyboard();
    final l10n = context.l10n;
    final target = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _colorLeading(note.color, frame: false),
              title: Text(l10n.backgroundColor),
              onTap: () => Navigator.pop(sheetContext, 'bg'),
            ),
            ListTile(
              leading: _colorLeading(note.frameColor, frame: true),
              title: Text(l10n.frameColor),
              onTap: () => Navigator.pop(sheetContext, 'frame'),
            ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    final frame = target == 'frame';
    final picked = await showNoteColorPicker(
      context,
      frame: frame,
      current: frame ? note.frameColor : note.color,
    );
    if (picked == null || !mounted) return;
    _mutate(
      (n) => frame ? n.copyWith(frameColor: picked) : n.copyWith(color: picked),
      immediate: true,
    );
  }

  Widget _colorLeading(NoteColor color, {required bool frame}) {
    final swatch = NoteColors.swatch(color);
    return Container(
      width: 28,
      height: 28,
      decoration: frame && color != NoteColor.none
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: swatch, width: 4),
            )
          : BoxDecoration(color: swatch, shape: BoxShape.circle),
      child: color == NoteColor.none
          ? const Icon(Icons.format_color_reset_outlined, size: 16)
          : null,
    );
  }

  void _delete() {
    final repo = ref.read(notesRepositoryProvider);
    final note = _note;
    if (repo == null || note == null) return;
    _deleted = true;
    repo.softDelete(note.id);
    Navigator.of(context).pop();
  }

  /// Notun içeriğini (gövde + liste öğeleri) onay alarak temizler;
  /// başlık, etiketler ve ekler yerinde kalır.
  Future<void> _clearContent() async {
    final note = _note;
    if (note == null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearNote),
        content: Text(l10n.clearNoteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clearNote),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    _bodyController.clear();
    _mutate((n) => n.copyWith(body: '', items: const []), immediate: true);
  }

  /// Sesli yazdırma. Cihazın yerleşik tanıması varsa düğme DOĞRUDAN dikteyi
  /// başlatır (alt sayfa açılmaz): konuşma anında nota akar, düğmeye tekrar
  /// basınca durur. Yerleşik tanıma yoksa (Windows) eski alt sayfa açılır.
  Future<void> _dictate() async {
    final note = _note;
    if (note == null) return;
    if (_dictating) {
      await _stopInlineDictation();
      return;
    }
    if (await DeviceSpeech.isAvailable()) {
      // İzin YOKKEN SpeechRecognizer sormadan hata verir; önce iste.
      if (!await DeviceSpeech.ensureMicPermission()) {
        if (mounted) _showSnack(context.l10n.micPermissionDenied);
        return;
      }
      await _startInlineDictation(note);
      return;
    }
    // Yerleşik tanıma yok: eski alt sayfa yolu.
    if (!mounted) return;
    if (note.type == NoteType.text) {
      final base = _bodyController.logicalText;
      final baseWithSep = base.trim().isEmpty ? '' : '${base.trimRight()}\n';
      void writeLive(String full) => _writeDictated(baseWithSep, full);
      final text = await showDictationSheet(context, onPartial: writeLive);
      if (text != null && text.trim().isNotEmpty) writeLive(text.trim());
      return;
    }
    final text = await showDictationSheet(context);
    if (text == null || text.trim().isEmpty) return;
    _appendText(text);
  }

  /// Dikte metnini gövdeye yazar: taban (mevcut gövde + ayraç) sabit kalır,
  /// üstüne o ana kadarki tam döküm gelir.
  void _writeDictated(String base, String full) {
    // Dikte parçaları artık satır sonuyla ayrılıyor (liste notunda her
    // duraklama ayrı madde olsun diye). Metin notunda paragraf bölünmesin:
    // ayraçlar boşluğa çevrilir. Taban metnin kendi satırları korunur.
    final combined = base + full.replaceAll('\n', ' ');
    _bodyController.value = TextEditingValue(
      text: combined,
      selection: TextSelection.collapsed(offset: combined.length),
    );
    _mutate((n) => n.copyWith(body: combined), immediate: true);
  }

  Future<void> _startInlineDictation(Note note) async {
    final base = _bodyController.logicalText;
    final baseWithSep = base.trim().isEmpty ? '' : '${base.trimRight()}\n';
    _dictationItemIds.clear();
    setState(() => _dictating = true);
    _speechSub = DeviceSpeech.listen().listen(
      (event) {
        final text = event.text;
        if (text == null) return;
        // Metin notunda anlık gövdeye; liste tiplerinde her duraklama
        // (satır sonu) anında ayrı madde olarak eklenir — eskiden döküm
        // yalnız "Bitir"de tek öğe olarak düşüyordu.
        if (note.type == NoteType.text) {
          _writeDictated(baseWithSep, text);
        } else {
          _syncDictatedItems(text);
        }
      },
      onError: (Object e) {
        _stopInlineDictation();
        // Cihaz tanıma hatası — AI ile ilgisi yok; "yapay zeka isteği
        // başarısız" gibi yanıltıcı bir mesaj gösterme.
        if (mounted) _showSnack(context.l10n.speechRecognitionFailed);
      },
    );
  }

  /// Bu dikte oturumunun eklediği öğelerin kimlikleri: her olayda dökümün
  /// tamamı yeniden gelir; önceki dikte öğeleri yenileriyle değiştirilir,
  /// kullanıcının elle yazdığı öğelere dokunulmaz.
  final List<String> _dictationItemIds = [];

  void _syncDictatedItems(String full) {
    const uuid = Uuid();
    final lines = [
      for (final line in full.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    _mutate((n) {
      // Sondaki boş "yeni öğe" satırları ve önceki dikte öğeleri çıkarılır.
      final kept = [
        for (final item in n.items)
          if (!_dictationItemIds.contains(item.id)) item,
      ];
      while (kept.isNotEmpty && kept.last.text.trim().isEmpty) {
        kept.removeLast();
      }
      _dictationItemIds
        ..clear()
        ..addAll([for (final _ in lines) uuid.v4()]);
      return n.copyWith(
        items: [
          ...kept,
          for (var i = 0; i < lines.length; i++)
            NoteItem(id: _dictationItemIds[i], text: lines[i]),
        ],
      );
    }, immediate: true);
  }

  /// Keep tarzı sesli not: Google'ın sesli giriş ekranı açılır; dönüşte
  /// metin nota yazılır, Google'ın KENDİ kaydettiği ses de ek olur.
  /// (+) menüsündeki "Sesli not"tan `?voice=1` ile gelir.
  ///
  /// KÖK NEDEN (eski tasarım niye söküldü): canlı dikte + kendi m4a kaydımız
  /// aynı anda çalışamıyor — Android'de tek mikrofonu SON açan istemci alır
  /// ve tanıyıcı mikrofonu asenkron açtığından hep o kazanır; kayıt dosyası
  /// sessiz çıkıyordu (9.4 sn kayıtta 0.14 sn ses — logcat ile ölçüldü).
  /// Keep'in kendisi de bu yüzden Google ekranını kullanır: tek mikrofon
  /// istemcisi Google'dır, metni de kaydettiği sesi de o döndürür.
  Future<void> _startVoiceCapture() async {
    final note = _note;
    if (note == null) return;
    final res = await DeviceSpeech.voiceInputWithAudio();
    if (res == null) return; // İptal ya da sesli giriş ekranı yok.
    final text = res.text.trim();
    if (text.isNotEmpty) {
      // Dikteyle aynı yazım kuralı: metin notunda gövdenin sonuna eklenir,
      // liste notunda yeni madde olur.
      if (note.type == NoteType.text) {
        final base = _bodyController.logicalText;
        final sep = base.trim().isEmpty ? '' : '${base.trimRight()}\n';
        _writeDictated(sep, text);
      } else {
        _mutate(
          (n) => n.copyWith(
            items: [...n.items, NoteItem(id: const Uuid().v4(), text: text)],
          ),
          immediate: true,
        );
      }
    }
    final audioPath = res.audioPath;
    if (audioPath == null) return; // GET_AUDIO vermezse yalnız metin kalır.
    try {
      final repo = ref.read(attachmentRepositoryProvider);
      if (repo == null) return;
      final attachment = await repo.prepareAudio(
        noteId: widget.noteId,
        sourcePath: audioPath,
        // Google süreyi bildirmez; AMR-NB ~12.2 kbps ≈ 1.6 KB/sn olduğundan
        // dosya boyutundan kestirilir. ponytail: kaba tahmin — oynatıcı
        // gerçek süreyi dosyadan zaten okur, bu yalnız etikette görünür.
        duration: Duration(
          seconds: (File(audioPath).lengthSync() / 1600).round(),
        ),
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException {
      if (mounted) _showSnack(_tooLargeMessage());
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _stopInlineDictation() async {
    await DeviceSpeech.stop();
    // Son sonucun gelmesi için kısa bekleme (tanıyıcı stop sonrası yazar).
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _speechSub?.cancel();
    _speechSub = null;
    if (!mounted) return;
    setState(() => _dictating = false);
    // Liste tiplerinde öğeler dikte sırasında anlık eklendi (_syncDictatedItems);
    // burada yalnız oturum durumu temizlenir — sonraki dikte bu öğeleri
    // "kendi öğesi" sanıp değiştirmesin.
    _dictationItemIds.clear();
  }

  /// Dahili hesap makinesi: sonucu metin notunda imlecin bulunduğu yere,
  /// listelerde yeni öğe olarak ekler.
  Future<void> _openCalculator() async {
    // Gövde odağını bırak: alt sayfa kapanınca klavye kendiliğinden geri
    // açılmasın (odaklı alan kalırsa Flutter klavyeyi yeniden gösterir).
    _dismissKeyboard();
    final result = await showCalculatorSheet(context);
    // Sonuç metne/öğeye programatik eklenir; kullanıcı yazmıyordu, klavye
    // kapalı kalsın (sonuç eklendikten sonra alan odaklanmaz).
    _dismissKeyboard();
    if (result == null || result.isEmpty) return;
    final note = _note;
    if (note == null) return;
    if (note.type == NoteType.text) {
      final body = _bodyController.text;
      final selection = _bodyController.selection;
      final start = selection.isValid ? selection.start : body.length;
      final end = selection.isValid ? selection.end : body.length;
      final updated = body.replaceRange(start, end, result);
      _bodyController.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start + result.length),
      );
      _mutate((n) => n.copyWith(body: updated), immediate: true);
    } else {
      // _appendText liste öğelerinde satır başındaki rakamları madde
      // numarası sanıp kırpar; sonuç sayı içerdiğinden öğe doğrudan eklenir.
      const uuid = Uuid();
      _mutate(
        (n) => n.copyWith(
          items: [
            ...n.items,
            NoteItem(id: uuid.v4(), text: result),
          ],
        ),
        immediate: true,
      );
    }
  }

  /// Metin notuna boş bir checklist maddesi ekler (karışık içerik). İlk madde
  /// eklenince gövde otomatik ItemsEditor'a geçer; sonrakiler onun "Yeni öğe"
  /// düğmesinden eklenir. Tüm maddeler silinince gövde saf metne döner.
  void _addChecklistItem() {
    const uuid = Uuid();
    _mutate(
      (n) => n.copyWith(
        items: [
          ...n.items,
          NoteItem(id: uuid.v4(), text: ''),
        ],
      ),
      immediate: true,
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Arayüz ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // dispose'un kullanacağı bağımlılıklar her karede tazelenir (bkz. yukarı).
    _cacheDeps();
    final l10n = context.l10n;
    final note = _note;

    if (note == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pending =
        ref.watch(pendingWritesProvider(widget.noteId)).value ?? false;
    final background = NoteColors.surface(context, note.color);

    final titleField = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _titleController,
        onChanged: (value) => _mutate((n) => n.copyWith(title: value)),
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        maxLines: null,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: l10n.titleHint,
          filled: false,
          border: InputBorder.none,
        ),
      ),
    );

    // Notun bağlı olduğu klasör (varsa) çipte gösterilir.
    final folders =
        ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[];
    NoteFolder? noteFolder;
    if (note.folderId != null) {
      for (final f in folders) {
        if (f.id == note.folderId) {
          noteFolder = f;
          break;
        }
      }
    }

    // Etiket/öneri EYLEMLERİ tek bir menüde toplanır: hatırlatıcı, klasör ve
    // etiket çipleriyle birlikte tek satırda kalır (madde 7). Menüden kullanıcı
    // hangi ekleme/öneri işlemini uygulayacağını seçer — çipler satırı taşırıp
    // dikeyde yer kaplamaz. Uzun etiket dizileri yatayda kaydırılır.
    final actionEntries = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: 'add-tag',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.new_label_outlined),
          title: Text(l10n.addTag),
        ),
      ),
      if (!note.isEmpty)
        PopupMenuItem(
          value: 'suggest-tags',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome),
            title: Text(l10n.suggestTags),
          ),
        ),
      if (!note.isEmpty && note.title.trim().isEmpty)
        PopupMenuItem(
          value: 'suggest-title',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.title),
            title: Text(l10n.suggestTitle),
          ),
        ),
      if (note.reminderAt == null)
        PopupMenuItem(
          value: 'add-reminder',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alarm_add_outlined),
            title: Text(l10n.addReminder),
          ),
        ),
    ];

    final actionsMenu = PopupMenuButton<String>(
      tooltip: l10n.noteMetaMenu,
      onSelected: (action) {
        switch (action) {
          case 'add-tag':
            _addTag();
          case 'suggest-tags':
            _suggestTags();
          case 'suggest-title':
            _suggestTitle();
          case 'add-reminder':
            _pickReminder();
        }
      },
      itemBuilder: (context) => actionEntries,
      child: Chip(
        avatar: _titleGenerating
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome, size: 16),
        label: Text(l10n.noteMetaMenu),
      ),
    );

    final metaChildren = <Widget>[
      if (note.reminderAt != null)
        InputChip(
          avatar: const Icon(Icons.alarm, size: 16),
          label: Text(DateFormat('d MMM HH:mm', 'tr').format(note.reminderAt!)),
          onPressed: _pickReminder,
          onDeleted: _clearReminder,
        ),
      // Klasör çipi: doluysa klasör adı+simge, boşsa "Klasör" ekleme.
      ActionChip(
        avatar: Icon(
          noteFolder?.iconData ?? Icons.create_new_folder_outlined,
          size: 16,
        ),
        label: Text(noteFolder?.name ?? l10n.folder),
        onPressed: _pickFolder,
      ),
      for (final tag in note.tags)
        InputChip(label: Text('#$tag'), onDeleted: () => _removeTag(tag)),
      actionsMenu,
    ];

    final metaChips = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < metaChildren.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              metaChildren[i],
            ],
          ],
        ),
      ),
    );

    final imageAttachments = [
      for (final a in note.attachments)
        if (a.kind == AttachmentKind.image) a,
    ];

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleField,
        metaChips,
        // Son güncelleme zamanı — kullanıcı en son ne zaman dokunduğunu görür.
        if (note.updatedAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              l10n.editedAt(
                DateFormat('d MMM y HH:mm', 'tr').format(note.updatedAt!),
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );

    // Gövde metin alanı: saf metin modunda ve karışık (metin+madde) modda
    // aynı controller/focus'u paylaşır. Madde varken kısalır (2 satır tabanı).
    final bodyField = TextField(
      controller: _bodyController,
      focusNode: _bodyFocus,
      // Sarma planı bu stille hesaplanır; TextField'ın örtük varsayılanına
      // bırakılırsa ölçüm ile çizim ayrışır ve satırlar yanlış kırılır.
      style: Theme.of(context).textTheme.bodyLarge,
      onChanged: (value) =>
          _mutate((n) => n.copyWith(body: _bodyController.logicalText)),
      maxLines: null,
      minLines: note.items.isEmpty ? 8 : 2,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: l10n.bodyHint,
        filled: false,
        border: InputBorder.none,
      ),
    );

    // Başlık + çipler: yüksekliği görsellerin üst sınırıdır.
    final keyedHeader = KeyedSubtree(key: _bodyTopKey, child: header);

    // Sayfa içeriği not tipine göre değişir; SARAN KATMAN hepsinde aynıdır:
    // görseller (el yazısı çizimleri dahil) tüm sayfanın üzerinde serbest
    // katmanda yüzer, metnin sağına/soluna sürüklenir ve metin etrafından akar.
    final Widget pageContent;
    if (note.type == NoteType.text && note.items.isEmpty) {
      pageContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          keyedHeader,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _kGutter),
            child: _wrapped(_bodyController, bodyField),
          ),
        ],
      );
    } else if (note.type == NoteType.text) {
      // Karışık içerik: serbest metin + checklist maddeleri. Gövde metni, madde
      // editörünün (ItemsEditor) header'ında durur; tüm ekle/işaretle/sırala/
      // sil mantığı olduğu gibi yeniden kullanılır. Madde kalmayınca (hepsi
      // silinince) note.items boşalır ve editör kendiliğinden saf metne döner.
      pageContent = ItemsEditor(
        key: ValueKey('mixed-${note.id}'),
        items: note.items,
        showCheckboxes: true,
        expandItems: ref.watch(expandListItemsProvider),
        onChanged: (items) => _mutate((n) => n.copyWith(items: items)),
        floats: _floats,
        pageBox: _pageBox,
        shrinkWrap: true,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            keyedHeader,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _kGutter),
              child: _wrapped(_bodyController, bodyField),
            ),
          ],
        ),
      );
    } else {
      pageContent = ItemsEditor(
        key: ValueKey('items-${note.id}'),
        items: note.items,
        showCheckboxes: note.type == NoteType.checklist,
        expandItems: ref.watch(expandListItemsProvider),
        onChanged: (items) => _mutate((n) => n.copyWith(items: items)),
        floats: _floats,
        pageBox: _pageBox,
        shrinkWrap: true,
        header: keyedHeader,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBodyTop());
    final hasBodyField = note.type == NoteType.text;
    // Gövde BOŞKEN "Not..." ipucu satırı görsellere kapalı bant sayılır.
    //
    // KÖK NEDEN: görseller sayfanın üzerinde serbest katmanda yüzüyor ve
    // metnin ÜSTÜne çiziliyor. Yazılı metin görselin etrafından aktığı için
    // (bkz. text_wrap.dart) sorun çıkmıyor, ama ipucu metni akmaz — sabit
    // yerinde durur. Nota resim eklenip başa sürüklenince ipucu resmin altında
    // kalıyor ve boş notta yazı alanının nerede olduğuna dair HİÇBİR iz
    // kalmıyordu ("nereye yazacağım?"). Bir satırlık pay ayrılınca görsel bu
    // bandın altına iner (üst sınır [NotePageCanvas.topLimit] ile zorlanır) ve
    // ipucu her zaman görünür kalır.
    final bodyFontSize = MediaQuery.textScalerOf(
      context,
    ).scale(Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16);
    // Bir satır (satır aralığı ~1.45) + TextField'ın çerçevesiz dikey dolgusu.
    final hintReserve = hasBodyField && note.body.trim().isEmpty
        ? bodyFontSize * 1.45 + 32
        : 0.0;
    final body = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 96),
        child: NotePageCanvas(
          minHeight: constraints.maxHeight,
          images: imageAttachments,
          onRemove: _removeAttachment,
          onChanged: _updateAttachment,
          onExtractText: _ocrImage,
          topLimit: _bodyTop + hintReserve,
          onFloats: _applyFloats,
          // Boş alana dokunmak gövdeye odaklanır — yazmaya başlamak için
          // aşağıya dokunmak yeterli. Listede gövde alanı yok.
          onTapEmpty: hasBodyField
              ? () {
                  if (!_bodyFocus.hasFocus) _bodyFocus.requestFocus();
                }
              : null,
          child: KeyedSubtree(key: _pageKey, child: pageContent),
        ),
      ),
    );

    return CallbackShortcuts(
      bindings: {
        if (_isDesktop)
          const SingleActivator(
            LogicalKeyboardKey.keyV,
            control: true,
            shift: true,
          ): _pasteImage,
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: pending ? l10n.syncPending : l10n.synced,
                child: Icon(
                  pending
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant
                      .withValues(alpha: pending ? 0.9 : 0.5),
                ),
              ),
            ),
            IconButton(
              tooltip: note.starred ? l10n.unstar : l10n.star,
              icon: Icon(
                note.starred ? Icons.star : Icons.star_outline,
                color: note.starred ? Colors.amber.shade600 : null,
              ),
              onPressed: () => _mutate(
                (n) => n.copyWith(starred: !n.starred),
                immediate: true,
              ),
            ),
            IconButton(
              tooltip: note.pinned ? l10n.unpin : l10n.pin,
              icon: Icon(
                note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              onPressed: () => _mutate(
                (n) => n.copyWith(pinned: !n.pinned),
                immediate: true,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'share':
                    _share();
                  case 'pdf':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PdfExportScreen(
                          note: note,
                          // Sayfa ölçüleri: görseller dışa aktarmada da
                          // nottaki yerlerinde çıksın.
                          layout: () {
                            final box = _pageBox();
                            if (box == null) return null;
                            return (
                              bodyTop: _bodyTop,
                              pageWidth: box.size.width,
                              pageHeight: box.size.height,
                            );
                          }(),
                        ),
                      ),
                    );
                  case 'listen':
                    _listen();
                  case 'lock':
                    _toggleLock();
                  case 'archive':
                    _toggleArchive();
                  case 'clear':
                    _clearContent();
                  case 'settings':
                    context.push('/settings');
                  case 'delete':
                    _delete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.share_outlined),
                    title: Text(l10n.share),
                  ),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: Text(l10n.exportPdf),
                  ),
                ),
                PopupMenuItem(
                  value: 'listen',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.headphones_outlined),
                    title: Text(l10n.listenToNote),
                  ),
                ),
                PopupMenuItem(
                  value: 'lock',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      note.locked
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline,
                    ),
                    title: Text(note.locked ? l10n.unlockNote : l10n.lockNote),
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      note.archivedAt != null
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    title: Text(
                      note.archivedAt != null ? l10n.unarchive : l10n.archive,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.backspace_outlined),
                    title: Text(l10n.clearNote),
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(l10n.settings),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline),
                    title: Text(l10n.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Renkli çerçeve: seçiliyse editör içeriğini saran ince renkli kenarlık.
        body: SafeArea(
          child: note.frameColor == NoteColor.none
              ? body
              : Container(
                  margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: NoteColors.swatch(note.frameColor),
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: body,
                  ),
                ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Görsel olmayan ekler (PDF/sunum/ses/video) SAYFANIN DİBİNDE,
            // kapanabilir bir şeritte. Görseller her not tipinde TAM SAYFA
            // serbest katmanda kalır (NotePageCanvas — yukarıda).
            AttachmentStrip(
              attachments: [
                for (final a in note.attachments)
                  if (a.kind != AttachmentKind.image) a,
              ],
              onRemove: _removeAttachment,
              onChanged: _updateAttachment,
              onVideoToNote: _videoToNote,
              expanded: ref.watch(attachmentsExpandedProvider),
              onToggle: () =>
                  ref.read(attachmentsExpandedProvider.notifier).toggle(),
            ),
            // Dikte açıkken kaçırılamayacak bir şerit: tek başına kırmızı
            // ikon yeterince belirgin değildi, mikrofon farkına varılmadan
            // açık kalabiliyordu.
            if (_aiTask != null) _AiBanner(label: _aiTask!),
            if (_dictating) _DictationBanner(onStop: _dictate),
            BottomAppBar(
              color: background,
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.color,
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: _showColorSheet,
                  ),
                  IconButton(
                    tooltip: l10n.addAttachment,
                    icon: const Icon(Icons.attach_file),
                    onPressed: _showAttachMenu,
                  ),
                  IconButton(
                    tooltip: l10n.calculatorTitle,
                    icon: const Icon(Icons.calculate_outlined),
                    onPressed: _openCalculator,
                  ),
                  // Karışık içerik: metin notunun altına checklist maddesi
                  // ekler. Yalnızca metin notunda anlamlı (liste notu zaten
                  // maddeden oluşur).
                  if (note.type == NoteType.text)
                    IconButton(
                      tooltip: l10n.newItemHint,
                      icon: const Icon(Icons.checklist),
                      onPressed: _addChecklistItem,
                    ),
                  const Spacer(),
                  // Mikrofon başparmak bölgesinde, AI'ın yanında ve dolgulu:
                  // yardımcı ikonların arasında kaybolmaz. Ses kaydı eki artık
                  // ataş menüsünde; bu düğme konuşmayı anlık yazıya döker.
                  // Dikte düğmesi: doğrudan başlatır/durdurur, büyük ve dolgulu.
                  // Dinlerken renk değişir ki kaydın sürdüğü açıkça görülsün.
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: _dictating
                        ? IconButton.filled(
                            tooltip: l10n.stopAndSave,
                            iconSize: 28,
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onError,
                            ),
                            icon: const Icon(Icons.stop),
                            onPressed: _dictate,
                          )
                        : IconButton.filledTonal(
                            tooltip: l10n.liveDictation,
                            iconSize: 28,
                            icon: const Icon(Icons.mic_none),
                            onPressed: _dictate,
                          ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.tonalIcon(
                    onPressed: () => showAiSheet(
                      context,
                      note,
                      onAppendText: _appendText,
                      onReplaceText: _replaceText,
                      onCreateNote: _createNoteFromText,
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(l10n.aiTitle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dikte sürerken alt çubuğun üstünde duran uyarı şeridi. Amacı tek:
/// mikrofonun açık olduğu gözden kaçmasın.
/// Süren AI işini gösteren şerit: iş bitene kadar ekranda durur. Tek bir
/// SnackBar yeterli değildi — kayboluyor, kullanıcı "çalışıyor mu, dondu mu"
/// bilemiyordu.
class _AiBanner extends StatelessWidget {
  const _AiBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: scheme.secondaryContainer,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
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

class _DictationBanner extends StatelessWidget {
  const _DictationBanner({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: InkWell(
        onTap: onStop,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.mic, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.dictationListening,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                context.l10n.stopAndSave,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
