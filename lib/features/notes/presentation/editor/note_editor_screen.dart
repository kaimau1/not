import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
// `AppExitResponse` (didRequestAppExit'in dönüş tipi) dart:ui'de yaşıyor;
// material/services onu yeniden dışa AKTARMIYOR. `show` ile alınır ki
// dart:ui'nin Color/TextStyle gibi tipleri material'ınkilerle çakışmasın.
import 'dart:ui' show AppExitResponse;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// RenderEditable material.dart üzerinden gelmiyor; imlecin sayfa üzerindeki
// yerini ölçmek için doğrudan gerekiyor (bkz. _caretPageTop).
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/router.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../../app/theme/note_colors.dart';
import '../../../../core/constants.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/doc_picker.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/utils/attachment_tag.dart';
import '../../../../core/utils/link_text.dart';
import '../../../../core/utils/markdown.dart';
import '../../../../core/utils/note_fonts.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/note_guard.dart';
import '../../../../core/utils/sentence_select.dart';
import '../../../../core/widgets/keyboard_snap.dart';
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
import '../../data/document_scan.dart';
import '../../data/note_speech.dart';
import '../../data/note_share.dart';
import '../../data/note_shares_repository.dart';
import '../../data/notes_repository.dart';
import '../../data/pdf_edit.dart';
import '../../data/scan/scan_ocr.dart';
import '../../data/scan/scan_title.dart';
import '../../data/user_templates.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../../domain/list_convert.dart';
import '../../domain/note_item.dart';
import '../../domain/note_type.dart';
import '../../domain/page_notes.dart';
import '../collaborators_sheet.dart';
import '../color_picker_sheet.dart';
import '../note_stats_sheet.dart';
import '../note_template_sheet.dart';
import '../notes_providers.dart';
import '../pdf_export_screen.dart';
import '../qr_scan_screen.dart';
import '../scan_review_screen.dart';
import '../share_sheet.dart';
import '../voice_capture_sheet.dart';
import 'ai_result_sheet.dart';
import 'attach_sheet.dart';
import 'attachment_clipboard.dart';
import 'attachment_strip.dart';
import 'audio_recorder_sheet.dart';
import 'calculator_sheet.dart';
import '../../data/place_reminders.dart';
import '../place_reminder_sheet.dart';
import 'drawing_screen.dart';
import 'editor_bar_layout.dart';
import 'format_bar.dart';
import 'format_menu.dart';
import 'image_layout.dart';
import 'items_editor.dart';
import 'note_images.dart';
import '../archive_note_screen.dart';
import 'note_menu_sheet.dart';
import 'in_note_find.dart';
import 'note_search_sheet.dart';
import 'text_search.dart';
import '../../domain/note_share_text.dart';
import '../local_only_action.dart';
import 'note_undo.dart';
import 'pdf_note_pane.dart';
import 'pdf_pages_screen.dart';
import 'slide_note_pane.dart';
import '../viewers/image_crop.dart';
import '../viewers/image_viewer.dart';
import '../viewers/pdf_viewer_screen.dart';
import '../viewers/slide_viewer_screen.dart';
import '../viewers/video_viewer.dart';
import '../viewers/text_recognize_screen.dart';
import 'text_wrap.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// İki madde listesi EKRANDA aynı mı? Yalnız madde METNİ değiştiyse aynı
/// sayılır: o metni satırın kendi denetleyicisi zaten çiziyor.
///
/// KÖK NEDEN (yazarken kasma) — editörün saf-yazım kısayolu ([_sameVisual])
/// eskiden madde listelerini `identical` ile karşılaştırıyordu. Bir maddeye
/// yazmak `ItemsEditor` üzerinden HER TUŞTA yeni bir liste nesnesi üretir,
/// dolayısıyla `identical` hep false çıkıyor ve kısayol yalnız gövde/başlık
/// alanında işliyordu: LİSTE notunda her harf, editörün 3700 satırlık
/// build'ini (sayfa tuvali, çipler, ek şeridi, bütün satırlar) yeniden
/// kuruyordu.
///
/// Metin dışındaki her fark (sayı, sıra, kimlik, işaret) görünürdür. Metnin
/// DOLULUĞU da öyle: `Note.isEmpty` menü girdilerini ve ipucunu etkiliyor.
@visibleForTesting
bool sameItemsVisually(List<NoteItem> a, List<NoteItem> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.id != y.id ||
        x.checked != y.checked ||
        // Yıldız satırda bir simge çiziyor: değişimi "görünmez" sayılırsa
        // yalnız `ItemsEditor`ın kendi setState'i onu gösterir, kart
        // önizlemesi ve dışa aktarma bayat kalırdı.
        x.starred != y.starred ||
        isBlankText(x.text) != isBlankText(y.text)) {
      return false;
    }
  }
  return true;
}

/// İki not EKRANDA aynı mı çizilir?
///
/// KÖK NEDEN (kasma — "yeni öğe eklemesem bile kasma devam ediyor"):
/// Firestore'un gecikme telafisi, editörün KENDİ kaydını da anında bir anlık
/// görüntü olarak geri gönderir. Akış dinleyicisi bunu koşulsuz `setState`
/// ile karşılıyordu, yani yazarken (debounce 0,5 sn / en geç 3 sn) düzenli
/// aralıklarla editörün tamamı — sayfa tuvali, sarma ölçümü, bütün madde
/// satırları — boşuna yeniden kuruluyordu. Yankıda çizimi değiştiren hiçbir
/// şey olmadığı için bu karşılaştırma o build'i tümden atlar.
///
/// Metnin KENDİSİ bilerek dışarıda: onu satırların/alanların kendi
/// denetleyicileri çiziyor (bkz. [sameItemsVisually]). Eklerde de yalnız
/// YERLEŞİMİ ve durumu etkileyen alanlar bakılır.
@visibleForTesting
/// TAHSİSSİZ "boş mu" denetimi.
///
/// KÖK NEDEN (GC baskısı): `text.trim().isEmpty` her çağrıda yeni bir dizgi
/// ayırıyor. Bu denetim HER TUŞ VURUŞUNDA madde sayısı kadar koşuyordu; 50
/// maddelik bir notta tuş başına 100 gereksiz dizgi. Tek başına takılma
/// yaratmaz, ama kare bütçesini diğer maliyetlerle birlikte aşırıyordu.
bool isBlankText(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    // Boşluk, sekme, satır sonu ve NBSP — `trim()`in kırptığı yaygın küme.
    if (c != 0x20 && c != 0x09 && c != 0x0A && c != 0x0D && c != 0xA0) {
      return false;
    }
  }
  return true;
}

bool sameRenderedNote(Note a, Note b) {
  if (identical(a, b)) return true;
  if (!sameItemsVisually(a.items, b.items)) return false;
  if (a.type != b.type ||
      a.color != b.color ||
      a.frameColor != b.frameColor ||
      a.pinned != b.pinned ||
      a.starred != b.starred ||
      a.locked != b.locked ||
      a.folderId != b.folderId ||
      a.fontFamily != b.fontFamily ||
      a.fontScale != b.fontScale ||
      a.textOpacity != b.textOpacity ||
      a.titleFontFamily != b.titleFontFamily ||
      a.titleFontScale != b.titleFontScale ||
      a.titleTextOpacity != b.titleTextOpacity ||
      a.backgroundImageId != b.backgroundImageId ||
      a.backgroundOpacity != b.backgroundOpacity ||
      a.orderIndex != b.orderIndex ||
      a.deletedAt != b.deletedAt ||
      a.archivedAt != b.archivedAt ||
      a.reminderAt != b.reminderAt ||
      a.updatedAt != b.updatedAt ||
      a.aiSummary != b.aiSummary ||
      a.title != b.title ||
      // Gövdenin DOLULUĞU tuval ipucunu ve gövde alanının varlığını belirler.
      isBlankText(a.body) != isBlankText(b.body)) {
    return false;
  }
  if (a.tags.length != b.tags.length) return false;
  for (var i = 0; i < a.tags.length; i++) {
    if (a.tags[i] != b.tags[i]) return false;
  }
  // Sayfa notları çizimi ETKİLER (PDF notunun alt bölmesi ve kart önizlemesi).
  // Metnin kendisi burada karşılaştırılır — gövdeden farklı olarak sayfa notu
  // alanı sayfa değişiminde yeniden doldurulduğu için "denetleyici zaten
  // ekranda" muafiyeti geçerli değil.
  if (a.pageNotes.length != b.pageNotes.length) return false;
  for (final entry in a.pageNotes.entries) {
    if (b.pageNotes[entry.key] != entry.value) return false;
  }
  if (a.attachments.length != b.attachments.length) return false;
  for (var i = 0; i < a.attachments.length; i++) {
    final x = a.attachments[i];
    final y = b.attachments[i];
    if (x.id != y.id ||
        x.kind != y.kind ||
        x.floatsOnPage != y.floatsOnPage ||
        // Sayfaya gömülü PDF'in GÖRÜNEN durumu: sayfa numarası, görüntü
        // döndürmesi ve yer imleri kutuyu değiştirir (bkz. PdfPageBox).
        x.pdfPage != y.pdfPage ||
        x.pdfTurns != y.pdfTurns ||
        !_sameInts(x.pdfMarks, y.pdfMarks) ||
        x.x != y.x ||
        x.pageY != y.pageY ||
        x.y != y.y ||
        x.displayWidth != y.displayWidth ||
        x.width != y.width ||
        x.height != y.height ||
        x.downloadUrl != y.downloadUrl ||
        x.fileName != y.fileName ||
        !identical(x.ink, y.ink)) {
      return false;
    }
  }
  return true;
}

/// İki sayı listesi aynı mı (yer imleri gibi kısa listeler için).
bool _sameInts(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

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
    this.ownerId,
    this.readOnly = false,
    this.startDrawing = false,
    this.startVoiceCapture = false,
    this.startDictation = false,
    this.startVideo = false,
    this.startPhoto = false,
    this.startScan = false,
    this.startPdf = false,
    this.startSlides = false,
  });

  final String noteId;

  /// Notun SAHİBİ, kendimden farklıysa (PAYLAŞILAN klasördeki not). null =
  /// benim notum.
  ///
  /// KÖK NEDEN (paylaşılan klasördeki not açılmıyordu): editör tüm okuma ve
  /// yazımlarını `notesRepositoryProvider` üzerinden, yani GİRİŞ YAPMIŞ
  /// kullanıcının koleksiyonundan yapıyordu. Paylaşılan bir not sahibinin
  /// koleksiyonunda yaşadığından editör onu bulamıyor, yazımlar da benim
  /// koleksiyonuma aynı kimlikle HAYALET bir not olarak düşüyordu. Sahip
  /// rotanın `?owner=` parametresiyle taşınır (bkz. `noteRoutePath`).
  ///
  /// **SINIR — EKLERİN yönetimi paylaşılmaz.** Görüntüleme çalışır (kartlar
  /// ve görüntüleyiciler `downloadUrl` jetonunu kullanıyor, o da Storage
  /// kurallarından bağımsız), ama ek EKLEME/SİLME hep GİRİŞ YAPMIŞ
  /// kullanıcının kendi Storage yolunda olur: dosyalar `users/{uid}/...`
  /// altında ve Storage kuralları Firestore'daki klasör paylaşımını göremez
  /// (bkz. storage.rules). Pratikte: ortak klasörler metin ve listeler için
  /// tasarlandı; ekler karşı taraftan silinemez.
  final String? ownerId;

  /// **SALT OKUNUR** — paylaşılan klasörde yalnız OKUMA yetkisi verilmiş
  /// kullanıcı (bkz. `FolderRole`). Yazımlar sunucuda ZATEN reddedilirdi;
  /// bayrak olmadan kullanıcı yazdığını ekranda görür, çıkışta sessizce
  /// kaybederdi. Bayrak hem alanları kilitler hem depoyu boşa alır — hiçbir
  /// yazım denenmez.
  final bool readOnly;

  /// El yazısı modu: editör açılır açılmaz çizim tuvali gösterilir,
  /// kaydedilen çizim nota görsel eki olarak girer.
  final bool startDrawing;

  /// Keep tarzı sesli not modu: editör açılır açılmaz ses kaydı + canlı
  /// döküm başlar; bitişte ses m4a eki olur, döküm notta kalır.
  final bool startVoiceCapture;

  /// `?dictate=1` — CANLI DİKTE ile açılır: not açılır açılmaz mikrofon
  /// dinlemeye başlar ve konuşulan söz imlece yazılır (bkz.
  /// [_toggleDictation]). Ana ekrandaki sade mikrofonun yolu budur.
  final bool startDictation;

  /// (+) menüsündeki "Görüntülü not": açılışta kamera başlatılır.
  final bool startVideo;

  /// (+) menüsündeki "Foto çek not al": açılışta fotoğraf makinesi açılır,
  /// çekilen kare nota gömülür ve kullanıcı doğrudan yazmaya başlar.
  final bool startPhoto;

  /// (+) menüsündeki "Belge tara not al": açılışta belge tarayıcı başlar,
  /// düzeltilmiş sayfalar nota girer ve istenirse yazıları tanınır.
  final bool startScan;

  /// (+) menüsündeki "PDF ekle not al": açılışta dosya seçici açılır, seçilen
  /// PDF notun içine gömülür ve iki bölmeli sayfa-notu ekranı kurulur. Seçim
  /// iptal edilirse boş not çıkışta kendiliğinden silinir.
  final bool startPdf;

  /// (+) menüsündeki "Sunum ekle not al": PDF yolunun slayt eşi.
  final bool startSlides;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Note? _note;

  /// Ataç rozetinin "yeni ek geldi" yanıp sönmesi (bkz.
  /// [_attachmentsToggle]). Değer 0 → 1 → 0 gider; iki tur döner.
  late final AnimationController _attachPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// En son çizilen ek sayısı — artışı yakalamak için (silme yanıp sönmez).
  int? _lastAttachmentCount;

  /// Ek sayısı arttıysa rozeti iki kez yakar.
  void _pulseAttachBadge(int count) {
    final previous = _lastAttachmentCount;
    _lastAttachmentCount = count;
    // İlk çizim referans alınır: notu AÇMAK yanıp sönmeyi tetiklemesin.
    if (previous == null || count <= previous) return;
    // Sistemde "hareketi azalt" açıksa animasyon yok.
    if (MediaQuery.disableAnimationsOf(context)) return;
    _attachPulse
      ..reset()
      ..repeat(reverse: true, count: 4);
  }

  /// LİSTE notunda serbest metin alanı açık mı? (Kullanıcı isteği: "liste
  /// notlarına metin notu ekleme seçeneği lazım.") Notun gövdesi doluysa alan
  /// zaten görünür; bu bayrak, gövde BOŞKEN alanı açık tutar.
  bool _listBodyOpen = false;

  /// Not makul bir sürede gelmedi (bkz. initState'teki koruma).
  bool _loadFailed = false;
  Timer? _loadGuard;

  /// Başlık da biçimlendirilebilir (kullanıcı: "sadece başlığın boyutunu
  /// ayarlayamıyorum, tüm sayfa büyüyor"): seçili başlık metnine boyut,
  /// şeffaflık, kalın... uygulanabilsin diye gövdeyle AYNI denetleyiciyi
  /// kullanır. Sarma çapası yok (başlıkta yüzen görsel olmaz), yalnız biçim
  /// işaretlerinin görünmez çizimi ve imleç düzeltmesi için gerekli.
  final _titleController = WrapTextController();
  final _titleFocus = FocusNode();

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
  AttachmentRepository? _attachmentRepo;
  GeminiService? _gemini;
  bool _autoTagEnabled = true;
  bool _autoTitleEnabled = true;

  /// Süren AI işinin adı (null = çalışan yok). Uzun AI işleri (OCR, videodan
  /// not) tek bir SnackBar gösterip sessizleşiyordu: kullanıcı çalışıp
  /// çalışmadığını anlamıyor, dakikalar sonra gelen hatayı da bağlayamıyordu.
  /// Bu alan, editörün altındaki şeritte iş bitene kadar duran canlı bir
  /// gösterge sürer ve aynı işin ikinci kez başlatılmasını engeller.
  String? _aiTask;

  /// Süren DOSYA işinin adı (kopyalama, yapıştırma, ek hazırlama). AI'dan
  /// ayrı bir alan: ikisi aynı anda koşabilir ve biri ötekini susturmamalı.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-08-10: "görüntü kopyalanırken veya
  /// başka bir şey yüklenirken sessizlik var, yüklenme dönencesi lazım"):
  /// pano işleri ancak BİTİNCE bir SnackBar gösteriyordu. Büyük bir görselin
  /// baytlarını okumak (bulut kopyasında: indirmek) saniyeler sürebiliyor ve o
  /// süre boyunca ekranda hiçbir iz yoktu — kullanıcı düğmeye basmadığını
  /// sanıp tekrar basıyordu.
  String? _busyTask;

  /// Uzun süren DOSYA işlerinin ortak sarmalayıcısı: şeritteki göstergeyi
  /// açar/kapatır. AI'nın [_runAi]'ı ile aynı desen; hata yönetimi çağırana
  /// bırakılır (her işin kendi anlamlı mesajı var).
  Future<T> _runBusy<T>(String label, Future<T> Function() body) async {
    setState(() => _busyTask = label);
    try {
      return await body();
    } finally {
      if (mounted) setState(() => _busyTask = null);
    }
  }

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
          e.isAuthError
              ? context.l10n.aiNoApiKey
              : context.l10n.aiError(e.message),
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
  bool _pendingDictation = false;
  bool _pendingVideo = false;
  bool _pendingPhoto = false;
  bool _pendingScan = false;
  bool _pendingPdf = false;
  bool _pendingSlides = false;

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
    if (_pendingDictation) {
      _pendingDictation = false;
      // Gövde odaklanır ki imleç görünür bir yerde olsun; dikte de oraya
      // yazsın (odaksız alanda hedef bulunamazdı).
      _bodyFocus.requestFocus();
      unawaited(_toggleDictation());
    }
    if (_pendingVideo) {
      _pendingVideo = false;
      _addVideo();
    }
    if (_pendingPhoto) {
      _pendingPhoto = false;
      _takePhoto();
    }
    if (_pendingScan) {
      _pendingScan = false;
      _scanDocument();
    }
    if (_pendingPdf) {
      _pendingPdf = false;
      _pickPdf();
    }
    if (_pendingSlides) {
      _pendingSlides = false;
      _pickSlide();
    }
  }

  void _cacheDeps() {
    // Paylaşılan not SAHİBİNİN koleksiyonuna yazılır (bkz.
    // [NoteEditorScreen.ownerId]); kendi notlarımda eski yol aynen sürer.
    final owner = widget.ownerId;
    _notesRepo = widget.readOnly
        ? null
        : owner == null
        ? ref.read(notesRepositoryProvider)
        : NotesRepository(
            FirebaseFirestore.instance,
            owner,
            editorUid: ref.read(currentUidProvider),
          );
    // Paylaşılan notun ekleri SAHİBİNİN Storage yoluna yüklenir (bkz.
    // AttachmentRepository.forOwner — ortak nottaki görsel kök nedeni).
    final attachments = ref.read(attachmentRepositoryProvider);
    _attachmentRepo = owner == null
        ? attachments
        : attachments?.forOwner(owner);
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

  /// Gövde alanının İÇ DOLGUSU (üst = alt). Üç yerde birden geçerlidir:
  /// alanın `contentPadding`i, sarma ölçümünün metin başlangıcı
  /// ([WrapFieldMeasure.textTop]) ve tuval ipucunun ilk satırı
  /// ([NotePageCanvas.textTop]). Tek kaynaktan beslenmezse ipucu, imleç ve
  /// sarma üç ayrı çizgiye oturur.
  ///
  /// Değer, çerçevesiz ve dolgusuz bir `InputDecoration`ın Flutter'daki
  /// varsayılanıdır (dikeyde 8 dp): görünüm birebir korunsun, ama artık
  /// TAHMİN edilmesin. İpucu eskiden 16 dp ile konumlanıyordu — yani metnin
  /// ilk satırının 8 dp altına.
  static const double _kBodyTextTop = 8;

  /// Alt çubuk araç düğmelerinin (Biçim / Ekle / Seç / Ekler) kare kenarı.
  ///
  /// KULLANICI İSTEĞİ 2026-08-30 ("ekle, biçim, seç'i Keep tarzında sadece
  /// simgeler hâline getir"): segmentler etiketliydi ve dar ekranda etiketin
  /// düşüp düşmeyeceğine ÖLÇÜLEREK karar veriliyordu — yani çubuk cihaza göre
  /// başka görünüyordu. Artık her yerde yalnız simge: satır ferahladı, karar
  /// ve ölçüm kodu da gereksiz kaldı.
  static const double _kToolSegment = kEditorBarSegment;

  /// Başlık üstündeki meta çiplerinin (klasör/etiket/hatırlatıcı/"+") ortak
  /// sıkıştırma ayarları: satır üst bar ile başlık arasındaki dar banda
  /// sığmalı. `shrinkWrap` dokunma hedefini 48 dp'ye YUVARLAMAZ — o yuvarlama
  /// çipin görünen yüksekliğini değiştirmese de satıra 10+ dp ekliyordu.
  static const _kChipDensity = VisualDensity(horizontal: -3, vertical: -3);
  static const _kChipPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 2);

  /// Silme (×) ikonunun kutusu: varsayılanı çipi gereğinden geniş yapıyor.
  static const _kChipDeleteBox = BoxConstraints(maxWidth: 20, maxHeight: 20);

  /// Başlık bloğunun yüksekliğini ölçüp [_bodyTop]'u tazeler. Yükseklik
  /// yalnız başlık/çipler değişince oynar (sarma onu etkilemez), bu yüzden
  /// ölçüm yakınsar ve tek setState'te durur.
  /// Bu kare için başlık ölçümü zaten sıraya girdi mi. Editörün build'i bir
  /// karede birden çok kez koşabiliyor (klavye açılışı, odak, tema); her
  /// kuruluşta ayrı bir kare-sonu geri çağrısı biriktirmenin anlamı yok,
  /// hepsi aynı yüksekliği ölçer.
  bool _bodyTopScheduled = false;

  void _scheduleBodyTopMeasure() {
    if (_bodyTopScheduled) return;
    _bodyTopScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bodyTopScheduled = false;
      if (mounted) _measureBodyTop();
    });
  }

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
    // Ölçüm, çizimle AYNI stili kullanmalı (notun yazı tipi/boyutu dahil);
    // ayrışırsa satırlar farklı kırılır ve imleç kayar.
    final style = _noteTextStyle();
    if (style == null) return field;
    return WrapFieldMeasure(
      controller: controller,
      style: style,
      floats: _floats,
      pageBox: _pageBox,
      // Bantlar alanın KUTUSUNA göre ölçülüyor, plan ise METİN uzayında
      // çalışıyor: aradaki iç dolgu düşülmezse metin görselin altına bir
      // dolgu boyu FAZLA iniyor (bkz. WrapFieldMeasure.textTop).
      textTop: _kBodyTextTop,
      child: field,
    );
  }

  // ---- Biçim çubuğu ---------------------------------------------------

  /// Biçim çubuğu açık mı (alt çubuktaki "Aa" düğmesi açıp kapatır).
  bool _formatBarOpen = false;

  /// Çubuğun yazacağı alan: en son odaklanan metin alanı (gövde ya da bir
  /// liste maddesi). Çubuğun kendisi odak İSTEMEDİĞİ için bu değer düğmeye
  /// basıldığında hâlâ geçerlidir (bkz. FormatBar).
  FormatTarget? _formatTarget;

  /// Çubuğun hedefi BAŞLIK mı? Başlığın kendi yazı tipi/boyutu/opaklığı var
  /// (bkz. Note.titleFontScale): çubuk hangi alan odaktaysa ONA yazar, yoksa
  /// başlığı büyütmek gövdeyi de büyütüyordu.
  bool get _titleIsTarget => _formatTarget?.controller == _titleController;

  /// Silinen madde satırının denetleyicisi hedefteyse hedef bırakılır —
  /// biçim çubuğu dispose edilmiş denetleyiciye yazmasın.
  /// Alan odaktan çıkarken bekleyen biçmi metne yazar ve sonucu nota işler.
  ///
  /// Bekleyen biçim tampona koşu boyunca DOKUNMAZ (IME yarışının kök nedeni,
  /// bkz. `WrapTextController._wrapRun`); işaretler ancak burada girdiği için
  /// yazımın nota işlenmesi de burada zorlanır.
  void _flushPending(WrapTextController controller) {
    if (!controller.hasPendingFormat) return;
    controller.flushPendingFormat();
    if (!mounted) return;
    if (controller == _titleController) {
      _mutate(
        (n) => n.copyWith(title: _titleController.logicalText),
        immediate: true,
      );
    } else if (controller == _bodyController) {
      _mutate(
        (n) => n.copyWith(body: _bodyController.logicalText),
        immediate: true,
      );
    }
  }

  void _clearFormatTargetFor(WrapTextController controller) {
    // Alan yok oluyor: hem dinleyicisi hem de ondan hatırlanan seçim düşer,
    // yoksa [_finishPendingEmbed] ölü bir denetleyiciye yazmayı denerdi.
    controller.removeListener(_rememberTargetSelection);
    if (_lastSelectionTarget?.controller == controller) {
      _lastSelectionTarget = null;
      _lastSelection = null;
    }
    if (_formatTarget?.controller != controller) return;
    _formatTarget = null;
    if (!_formatBarOpen) return;
    // KÖK NEDEN (çökme): bu kapanış alanın `dispose`undan geliyor ve bir
    // widget BUILD FAZINDA da unmount edilebiliyor (belge/tip değişince
    // pano anahtarı değişir). `mounted` yalnız "dispose edildi mi"yi
    // korur, "build içindeyiz"i korumaz — `setState() called during build`
    // istisnası buradan çıkar. Çizim tazelemesi bir kareye ertelenir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _formatBarOpen) setState(() {});
    });
  }

  void _setFormatTarget(
    WrapTextController controller,
    FocusNode focusNode,
    VoidCallback commit,
  ) {
    final changed = _formatTarget?.controller != controller;
    if (changed) {
      // SON DOLU SEÇİM dinleyicisi hep ETKİN alanda durur (bkz.
      // [_lastSelection]): madde satırına geçen kullanıcı orada seçtiği
      // yazıya da ek bağlayabilsin. Önce kaldır-sonra ekle: aynı dinleyici
      // iki kez kayıtlı kalmasın (gövde initState'te de kaydediliyor).
      _formatTarget?.controller.removeListener(_rememberTargetSelection);
      controller
        ..removeListener(_rememberTargetSelection)
        ..addListener(_rememberTargetSelection);
    }
    _formatTarget = FormatTarget(
      controller: controller,
      focusNode: focusNode,
      commit: commit,
    );
    // Alan yeni odaklandı: imleci klavyenin üstüne al. Bu kapanış gövde,
    // başlık ve madde satırlarının HEPSİNDEN geçtiği için tek yer yeter.
    _revealCaretSoon();
    // Çubuk AÇIKKEN hedef değişmesi çizimi etkiler: aktif biçim vurgusu yeni
    // alanın imlecinden hesaplanmalı. Kapalıyken çizim değişmediği için
    // gereksiz yere setState çağırmıyoruz (odak her satırda değişiyor).
    if (changed && _formatBarOpen && mounted) setState(() {});
  }

  /// Çubuktaki biçim düğmesi: seçime uygula, seçim yoksa imlece kutu aç.
  void _applyFormat(RichFormat format, {int? colorIndex}) =>
      _runOnTarget((c) => applyRichFormat(c, format, colorIndex: colorIndex));

  /// Seçimdeki tüm biçimleri siler.
  void _clearFormat() => _runOnTarget(clearRichFormat);

  /// Renk/vurgu paletindeki "Kaldır": yalnız o biçmi düşürür (bkz.
  /// [removeRichFormat] — geri dönüşün keşfedilebilir tek yolu).
  void _removeFormat(RichFormat format) =>
      _runOnTarget((c) => removeRichFormat(c, format));

  /// Biçim çubuğunun hedefinde SEÇİLİ metin var mı?
  bool _hasSelection() {
    final selection = _formatTarget?.controller.selection;
    return selection != null && selection.isValid && !selection.isCollapsed;
  }

  /// Boyut/şeffaflık kaydırıcısı bırakıldı: SEÇİM VARSA yalnız ona (satır içi
  /// kademe olarak), yoksa TÜM NOTA uygulanır. Kullanıcı isteği birebir buydu.
  ///
  /// Kaydırıcı sürekli, kademeler ayrık: en yakın kademeye yuvarlanır.
  /// Kademe notun kendi değeriyle aynıysa işaret hiç yazılmaz (metin yine
  /// notu izler) — gereksiz işaret metni kirletmesin.
  void _applyStepOrNote(
    RichFormat format,
    List<double> steps,
    int defaultIndex,
    double value,
    Note Function(Note note) noteWide,
  ) {
    final target = _formatTarget;
    if (target != null && _hasSelection()) {
      final index = richStepIndex(steps, value);
      if (applyRichStep(
        target.controller,
        format,
        index == defaultIndex ? null : index,
      )) {
        target.commit();
        if (!target.focusNode.hasFocus) target.focusNode.requestFocus();
      }
      return;
    }
    _mutate(noteWide, immediate: true);
  }

  void _runOnTarget(bool Function(WrapTextController controller) action) {
    final target = _formatTarget;
    if (target == null) return;
    if (!action(target.controller)) return;
    target.commit();
    // Odak (ve klavye) alana geri verilir: biçim uygulanan metin seçili
    // kaldığı için kullanıcı üstüne ikinci bir biçim koyabilir ya da yazmaya
    // devam edebilir. Çubuğun kendisi odak istemez (bkz. FormatBar).
    if (!target.focusNode.hasFocus) target.focusNode.requestFocus();
  }

  /// Notun kendi yazı tipi/boyutu uygulanmış gövde stili (ölçüm ve çizim
  /// ortak kaynağı).
  TextStyle? _noteTextStyle() {
    final base = Theme.of(context).textTheme.bodyLarge;
    final note = _note;
    if (base == null || note == null) return base;
    return applyNoteFont(
      base.copyWith(fontSize: (base.fontSize ?? 16) * note.fontScale),
      note.fontFamily,
    );
  }

  final _debouncer = Debouncer();
  ProviderSubscription<AsyncValue<Note?>>? _sub;
  bool _deleted = false;

  /// Bu oturumda çalışma sayacı işlendi mi (bkz. [noteActivityProvider]).
  bool _workCounted = false;

  /// Madde editörünün durumu: başlıktaki klavye "İleri" tuşu liste notunda
  /// ilk maddeye odaklanabilsin diye GlobalKey. Karışık ve saf liste dalları
  /// aynı anahtarı kullanır — tip değişiminde (metin+madde ↔ liste) State
  /// korunur; madde listesi zaten didUpdateWidget'ta senkronlanıyor.
  final _itemsEditorKey = GlobalKey<ItemsEditorState>();

  /// Başlıkta klavyenin "İleri" tuşu: odak çip satırına değil İÇERİĞE geçer
  /// (gövde; gövde alanı yoksa ilk madde). Varsayılan `nextFocus` odağı metin
  /// dışına taşıyıp klavyeyi kapatıyordu.
  void _focusAfterTitle() {
    final note = _note;
    if (note == null) return;
    final hasBody =
        note.type == NoteType.text ||
        note.body.trim().isNotEmpty ||
        _listBodyOpen;
    if (hasBody) {
      _bodyFocus.requestFocus();
    } else {
      _itemsEditorKey.currentState?.focusFirstItem();
    }
  }

  @override
  void initState() {
    super.initState();
    // Uygulama arka plana alınırken/kapatılırken bekleyen kaydı zorlamak için
    // (bkz. [_saveNow] — "kapatınca not kayboluyor" kök nedeni).
    WidgetsBinding.instance.addObserver(this);
    // Arka plandaki boş not temizliği bu notu ATLASIN (bkz. cleanupEmptyNotes):
    // kullanıcı yazmaya yeni başladığında doküman kısa bir süre boş görünür.
    openEditorNoteIds.add(widget.noteId);
    // Notu AÇMAK da bir çalışma izidir ("en çok çalışılan" sıralaması). İlk
    // kareden sonra: initState içinde sağlayıcı yazmak build'in ortasına
    // düşer ve Riverpod bunu hata sayar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(noteActivityProvider.notifier).touch(widget.noteId);
    });
    // dispose'da `ref` kullanılamadığından (bkz. yukarıdaki KÖK NEDEN notu)
    // depo/ayar bağımlılıkları ilk build'den ÖNCE de elde olmalı: yaşam
    // döngüsü kaydı ilk kare çizilmeden gelebilir.
    _cacheDeps();
    // İlk açılış kasması (madde 3): editör başlangıçta _note null olduğu için
    // bir kare boyunca CircularProgressIndicator gösterip ardından tüm editörü
    // kuruyordu; bu geçiş, sayfa animasyonuyla aynı anda büyük bir yerleşim
    // sıçraması yaratıyordu. Not zaten dashboard akışında yüklü olduğundan
    // (kullanıcı oradan geldi) onu SENKRON okuyup ilk kareyi dolu kur —
    // spinner→editör takası ve onunla gelen kasma ortadan kalkar.
    // Uzun basışla seçilen kelime, içinde bulunduğu CÜMLEYE genişletilir —
    // notta seçim neredeyse hep bir cümleyi taşımak/silmek için yapılıyor.
    attachSentenceSelection(_bodyController);
    attachSentenceSelection(_titleController);
    // Etkin alandaki SON DOLU seçimi sakla (bkz. [_lastSelection]). Gövde
    // açılışta zaten varsayılan hedef; madde satırları odaklanınca
    // [_setFormatTarget] dinleyiciyi oraya taşır.
    _bodyController.addListener(_rememberTargetSelection);
    // Biçim çubuğu son odaklanan alana yazar; gövde odağı burada bildirilir
    // (maddeler ItemsEditor'dan bildirir).
    _titleFocus.addListener(() {
      if (!_titleFocus.hasFocus) {
        // KÖK NEDEN ("kalın butonuna basıp kalın yazamıyorum"): bekleyen biçim
        // koşu bitince metne yazılır ve koşuyu bitiren en yaygın olay ODAK
        // KAYBIDIR. Bu kapanış yalnız liste satırlarında (ItemsEditor) vardı;
        // gövde ve başlıkta "kalın"a basıp yazan, sonra başka yere dokunan
        // kullanıcının biçmi SESSİZCE kayboluyordu.
        _flushPending(_titleController);
        return;
      }
      _setFormatTarget(
        _titleController,
        _titleFocus,
        () => _mutate(
          (n) => n.copyWith(title: _titleController.logicalText),
          immediate: true,
        ),
      );
    });
    _bodyFocus.addListener(() {
      if (!_bodyFocus.hasFocus) {
        _flushPending(_bodyController);
        return;
      }
      _setFormatTarget(
        _bodyController,
        _bodyFocus,
        () => _mutate(
          (n) => n.copyWith(body: _bodyController.logicalText),
          immediate: true,
        ),
      );
    });
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
    // Not hiç gelmezse (silinmiş ya da yanlış id ile açılmış bir rota)
    // ekranda sonsuza kadar dönen bir halka kalmasın: v1.0.181'de bozuk bir
    // rota yüzünden bütün "yeni not" modları bu ekranda takılı kaldı ve
    // kullanıcıya hiçbir şey söylenmiyordu.
    _loadGuard = Timer(const Duration(seconds: 6), () {
      if (mounted && _note == null) setState(() => _loadFailed = true);
    });
    _pendingDraw = widget.startDrawing;
    _pendingVoice = widget.startVoiceCapture;
    _pendingDictation = widget.startDictation;
    _pendingVideo = widget.startVideo;
    _pendingPhoto = widget.startPhoto;
    _pendingScan = widget.startScan;
    _pendingPdf = widget.startPdf;
    _pendingSlides = widget.startSlides;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPendingIntents());
    final owner = widget.ownerId;
    _sub = ref.listenManual(owner == null
        ? noteStreamProvider(widget.noteId)
        : ownedNoteStreamProvider((ownerId: owner, noteId: widget.noteId)), (
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
        // Not BAŞKA yerden çöpe atıldı (geniş ekranda soldaki kartın menüsü
        // ya da ikinci cihaz). Editör tam dokümanı `deletedAt: null` ile
        // yazdığından, kalan tek harflik bir yazım bile notu çöpten sessizce
        // DİRİLTİYORDU. Kayıt durdurulur ve editör kapatılır — kart menüsünün
        // "Geri al" snackbar'ı zaten ekranda.
        // `!_deleted` ŞART: editörün KENDİ silmesi de (softDelete + pop)
        // gecikme telafisiyle buraya bir snapshot düşürür; bayrak olmadan
        // dal ikinci kez tetiklenir ve context.pop() yığının tepesindeki
        // ALTTAKİ rotayı (örn. Arşiv ekranını) düşürürdü.
        if (incoming.deletedAt != null &&
            _note!.deletedAt == null &&
            !_deleted) {
          _deleted = true;
          _debouncer.cancel();
          if (mounted && context.canPop()) context.pop();
          return;
        }
        if (_deleted) return;
        // Editör açıkken YAZILAN alanlar (başlık/gövde/maddeler) yerel esastır;
        // gerisi uzaktan benimsenir:
        //  - ekler: yükleme/AI alanları düzen korunarak birleştirilir,
        //  - meta (sabit/yıldız/kilit/arşiv/klasör/etiket/renk/hatırlatıcı):
        //    karttan ya da ikinci cihazdan yapılan değişiklik, editörün
        //    tam-doküman kaydıyla sessizce GERİ ALINMASIN. Yereldeki meta
        //    değişikliği kaybolmaz: Firestore gecikme telafisi yerel yazımı
        //    akışa anında yansıtır, bayat snapshot gelmez.
        final localTitle = _titleController.logicalText;
        final localBody = _bodyController.logicalText;
        // Kullanıcı bu oturumda HİÇ yazmadıysa içerik de benimsenir: notu
        // yalnızca açıp bakan tarafta ikinci cihazın düzenlemesi canlı akar
        // ve bayat taban tam-doküman kaydıyla onu ezemez.
        final pristine =
            !_undoStack.canUndo &&
            !_debouncer.hasPending &&
            localTitle == _note!.title &&
            localBody == _note!.body;
        // KÖK NEDEN (kasma): burada KOŞULSUZ `setState` vardı. Firestore
        // gecikme telafisi yüzünden editörün KENDİ kaydı da anında bir
        // anlık görüntü olarak geri düşer; yani yazarken (debounce 0,5 sn,
        // en geç 3 sn) düzenli aralıklarla 4000 satırlık editör build'i —
        // sayfa tuvali, sarma ölçümü, bütün madde satırları — boşuna
        // yeniden koşuyordu. Oysa o yankıda çizimi değiştiren HİÇBİR ŞEY
        // yok: alanlar zaten yerelden geldiği gibi. Artık yeni not nesnesi
        // kurulur, çizimi etkileyen bir fark yoksa `setState` ATLANIR
        // (denetleyiciler ve `_note` yine güncel kalır).
        final previous = _note!;
        Note merged;
        {
          merged = previous.copyWith(
            attachments: mergeAttachmentLayout(
              local: _note!.attachments,
              incoming: incoming.attachments,
            ),
            aiSummary: incoming.aiSummary,
            pinned: incoming.pinned,
            starred: incoming.starred,
            locked: incoming.locked,
            tags: incoming.tags,
            color: incoming.color,
            frameColor: incoming.frameColor,
            folderId: incoming.folderId,
            clearFolderId: incoming.folderId == null,
            archivedAt: incoming.archivedAt,
            clearArchivedAt: incoming.archivedAt == null,
            reminderAt: incoming.reminderAt,
            clearReminderAt: incoming.reminderAt == null,
            // Sıra ve görünüm ayarları da uzaktan benimsenir: geniş ekranda
            // solda sürükle-sırala yapıldığında editörün tam-doküman kaydı
            // orderIndex'i geri almasın.
            orderIndex: incoming.orderIndex,
            fontFamily: incoming.fontFamily,
            clearFontFamily: incoming.fontFamily == null,
            fontScale: incoming.fontScale,
            textOpacity: incoming.textOpacity,
            titleFontFamily: incoming.titleFontFamily,
            clearTitleFontFamily: incoming.titleFontFamily == null,
            titleFontScale: incoming.titleFontScale,
            titleTextOpacity: incoming.titleTextOpacity,
            backgroundImageId: incoming.backgroundImageId,
            clearBackgroundImage: incoming.backgroundImageId == null,
            backgroundOpacity: incoming.backgroundOpacity,
          );
          if (pristine) {
            merged = merged.copyWith(
              title: incoming.title,
              body: incoming.body,
              items: incoming.items,
              // Sayfa notları da içerik: bu oturumda hiç yazılmadıysa ikinci
              // cihazın yazdığı sayfa notu canlı görünür. Yazılmışsa YEREL
              // esastır (pristine false) — yankı gelen bayat harita, henüz
              // kaydedilmemiş tuş vuruşlarını geri almasın.
              pageNotes: incoming.pageNotes,
            );
            if (incoming.title != localTitle) {
              _titleController.text = incoming.title;
            }
            if (incoming.body != localBody) {
              _bodyController.text = incoming.body;
            }
          }
        }
        _note = merged;
        if (!sameRenderedNote(previous, merged)) setState(() {});
      }
    }, fireImmediately: true);
  }

  /// Bekleyen kaydı ERTELEMEDEN yazar; metin alanlarındaki en güncel içerik
  /// nota işlenir.
  ///
  /// KÖK NEDEN ("not düzenlerken dashboard'a dönmeden uygulamayı tamamen
  /// kapatınca not bazen kaydolmuyor, kayboluyor"): kayıt yalnız iki yerde
  /// kesinleşiyordu — debounce zamanlayıcısı dolduğunda ve `dispose()`
  /// içindeki flush'ta. Uygulama görev listesinden kapatıldığında (ya da
  /// sistem onu öldürdüğünde) rota pop EDİLMEZ, dolayısıyla `dispose()` hiç
  /// çalışmaz ve o an bekleyen yazım onunla birlikte kaybolur. Yeni açılmış
  /// bir notta bu, notun Firestore'da BOŞ kalması demektir; boş notlar arka
  /// planda temizlendiği için not tümüyle yok olur — "kayboluyor" şikâyeti
  /// tam olarak budur. Bu yüzden kayıt artık her çıkış kapısında zorlanır:
  /// arka plana alma (`inactive`/`paused`/`hidden`/`detached`) ve masaüstünde
  /// pencere kapatma isteği (`didRequestAppExit`).
  Future<void>? _saveNow() {
    final note = _note;
    if (note == null || _deleted) return null;
    // Denetleyicilerdeki metin nota işlenir: son tuş vuruşunun `onChanged`'i
    // gelmemiş olabilir. Gövde/başlık için tek gerçek kaynak denetleyicidir —
    // nota dışarıdan yazan her yol (dikte, AI, yapıştırma) denetleyiciyi de
    // günceller, o yüzden burada geri alma riski yok.
    // Bekleyen biçim koşusu de burada kesinleşir: işaretler tampona ancak koşu
    // bitince giriyor, uygulama arka plana alınıp öldürülürse koşu hiç
    // bitmeyecekti ve kullanıcının "kalın" yazdığı satır düz kaydedilirdi.
    _titleController.flushPendingFormat();
    _bodyController.flushPendingFormat();
    // Odaktaki alan madde satırı ya da sayfa notu olabilir; biçim çubuğunun
    // hedefi tam olarak o alandır. Yoksa "kalın"a basıp bir madde satırına
    // yazan ve uygulamayı görev listesinden kapatan kullanıcı biçmi
    // kaybediyordu (gövde/başlık için kapatılan deliğin aynısı).
    final target = _formatTarget;
    if (target != null && target.controller.hasPendingFormat) {
      target.controller.flushPendingFormat();
      target.commit();
    }
    final title = _titleController.logicalText;
    final body = _bodyController.logicalText;
    final drifted = title != note.title || body != note.body;
    // Yazılacak yeni bir şey yoksa hiç dokunma: `inactive` evresi (bildirim
    // perdesi, kamera/galeri açılışı, izin diyaloğu) sık gelir ve her
    // seferinde boş yere `updatedAt` tazelemek notu listede öne fırlatırdı.
    if (!drifted && !_debouncer.hasPending) return null;
    final current = drifted ? note.copyWith(title: title, body: body) : note;
    _note = current;
    // setState YOK: denetleyiciler bu metni zaten gösteriyor, yeniden çizime
    // gerek yok — üstelik `detached` evresinde setState çağırmak güvensiz.
    _debouncer.cancel();
    return _notesRepo?.updateNote(current);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // `resumed` dışındaki her evre bir "çıkış" olabilir: Android'de görev
    // listesi açılınca `inactive`, arka plana geçince `hidden`/`paused`,
    // öldürülmeden hemen önce `detached` gelir. Kayıt hepsinde zorlanır —
    // fazladan yazımın maliyeti yok (Firestore merge, aynı içerik).
    if (state != AppLifecycleState.resumed) _saveNow();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    // Masaüstü (Windows): pencere kapatma düğmesi. `detached` burada
    // güvenilir gelmediğinden kapanışa izin vermeden önce kaydedilir.
    // Yazım kısa bir süre BEKLENİR: `unawaited` bırakılsaydı süreç, Firestore
    // yerel kalıcılığı diske inmeden ölebilir ve son 3 sn'lik yazım
    // kaybolabilirdi. Zaman aşımı şart — future SUNUCU onayında tamamlanır,
    // çevrimdışıyken sonsuza dek bekler; 2 sn yerel commit için yeterli.
    final write = _saveNow();
    if (write != null) {
      // Hata da yutulur: yazım 2 sn içinde reddedilirse (permission-denied)
      // istisna buradan fırlayıp kapanış yanıtını asla döndürmezdi.
      await write
          .timeout(const Duration(seconds: 2), onTimeout: () {})
          .catchError((_) {});
    }
    return super.didRequestAppExit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    openEditorNoteIds.remove(widget.noteId);
    // Dikte açıkken editörden çıkılabiliyor: mikrofon ekranla birlikte
    // kapanmazsa arka planda dinlemeye devam ederdi.
    if (_dictationSub != null) {
      _dictationSub!.cancel();
      _dictationSub = null;
      unawaited(DeviceSpeech.stop());
    }
    // Yalnız `_debouncer.flush()` DEĞİL: denetleyici metni nottan sapmış ama
    // bekleyen debounce yoksa (IME'nin odak düşerken onChanged üretmeden
    // commit ettiği otomatik düzeltme, alan içi Ctrl+Z) flush hiçbir şey
    // yazmazdı — _saveNow aynı drift ağını çıkış yolunda da kurar.
    _saveNow();
    // Silinen eklerin baytları burada gider: "Geri al" ile geri gelenler
    // dosyalarını korur (bkz. _flushAttachmentDeletes).
    _flushAttachmentDeletes();
    final note = _note;
    if (!_deleted && note != null && note.isEmpty) {
      // İçi boş kalan not çıkarken sessizce silinir.
      _notesRepo?.hardDelete(note.id);
    } else if (!_deleted && note != null) {
      // İçerik denetimi isEmpty'den AYRI: yalnız hatırlatıcısı olan metinsiz
      // not artık "boş" sayılmıyor (silinmesin diye) ama AI'ya gönderilecek
      // içeriği de yok — boş içerikle model çağırmak puan yakar ve
      // halüsinasyon başlık üretebilirdi.
      final hasContent =
          note.body.trim().isNotEmpty ||
          note.items.any((i) => i.text.trim().isNotEmpty) ||
          note.attachments.isNotEmpty;
      if (hasContent) {
        if (note.tags.isEmpty) _autoTagInBackground(note);
        if (note.title.trim().isEmpty) _autoTitleInBackground(note);
      }
    }
    _loadGuard?.cancel();
    _debouncer.dispose();
    _sub?.close();
    _titleController.dispose();
    _titleFocus.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
    _pageScroll.dispose();
    _findController.dispose();
    _findFocus.dispose();
    _attachPulse.dispose();
    super.dispose();
  }

  /// Dashboard akışında zaten yüklü olan notu senkron döndürür (varsa).
  /// İlk kareyi dolu kurup açılış kasmasını önlemek için kullanılır.
  Note? _cachedNote() {
    // Paylaşılan not BENİM akışımda yok (sahibinin koleksiyonunda yaşıyor);
    // önbelleğe bakmak en iyi ihtimalle boşuna, en kötüsünde yanlış notu
    // gösterir.
    if (widget.ownerId != null) return null;
    final notes = ref.read(notesStreamProvider).value;
    if (notes == null) return null;
    for (final n in notes) {
      if (n.id == widget.noteId) return n;
    }
    return null;
  }

  // ---- Geri alma ------------------------------------------------------

  /// Değişiklikten ÖNCEKİ not anlık görüntüleri (bkz. note_undo.dart).
  final _undoStack = NoteUndoStack();

  /// Geri alma uygulanırken true: geri alınan durum yeniden yığına girmesin.
  bool _restoring = false;

  bool get _canUndo => _undoStack.canUndo;
  bool get _canRedo => _undoStack.canRedo;

  /// Son değişikliği geri alır (araç çubuğundaki düğme ve Ctrl+Z).
  void _undo() {
    final note = _note;
    if (note == null) return;
    final previous = _undoStack.undo(note);
    if (previous == null) return;
    _restoring = true;
    // Metin alanları nottan beslenmiyor (kendi denetleyicileri var); geri
    // alınan gövde/başlık elle yazılmazsa ekranda eski metin kalırdı.
    _titleController.text = previous.title;
    _bodyController.text = previous.body;
    _mutate((_) => previous, immediate: true);
    _restoring = false;
    _showSnack(context.l10n.undone);
  }

  /// Geri alınan değişikliği yineler (düğme + Ctrl+Y / Ctrl+Shift+Z).
  void _redo() {
    final note = _note;
    if (note == null) return;
    if (note.type.isPageNoteType) FocusManager.instance.primaryFocus?.unfocus();
    final next = _undoStack.redoStep(note);
    if (next == null) return;
    _restoring = true;
    _titleController.text = next.title;
    _bodyController.text = next.body;
    _mutate((_) => next, immediate: true);
    _restoring = false;
  }

  /// Metin DIŞINDA görünür hiçbir şey değişmedi mi? (saf yazım tespiti)
  static bool _sameVisual(Note a, Note b) =>
      sameItemsVisually(a.items, b.items) &&
      identical(a.attachments, b.attachments) &&
      identical(a.tags, b.tags) &&
      identical(a.aiSummary, b.aiSummary) &&
      a.type == b.type &&
      a.color == b.color &&
      a.frameColor == b.frameColor &&
      a.pinned == b.pinned &&
      a.starred == b.starred &&
      a.locked == b.locked &&
      a.folderId == b.folderId &&
      a.fontFamily == b.fontFamily &&
      a.fontScale == b.fontScale &&
      a.textOpacity == b.textOpacity &&
      a.titleFontFamily == b.titleFontFamily &&
      a.titleFontScale == b.titleFontScale &&
      a.titleTextOpacity == b.titleTextOpacity &&
      a.backgroundImageId == b.backgroundImageId &&
      a.backgroundOpacity == b.backgroundOpacity &&
      // KÖK NEDEN (kullanıcı 2026-08-16: "tek sütun 2 sütun çalışıyor ancak
      // anlık canlı bazen görülmüyor, bir çıkış yapınca oluyor"): sütun
      // sayısı burada KARŞILAŞTIRILMIYORDU. Değişim "saf yazım" sayılıp
      // `setState` atlanıyor, yeni düzen ancak başka bir sebeple gelen
      // yeniden çizimde (ör. editörden çıkıp girmek) görünüyordu.
      a.listColumns == b.listColumns &&
      a.archivePages.length == b.archivePages.length &&
      a.orderIndex == b.orderIndex &&
      a.deletedAt == b.deletedAt &&
      a.archivedAt == b.archivedAt &&
      a.reminderAt == b.reminderAt &&
      // Tuval ipucu ve gövde alanı gövdenin BOŞLUĞUNA bakıyor; doluluk
      // değişiyorsa çizim de değişmeli.
      isBlankText(a.body) == isBlankText(b.body);

  void _mutate(Note Function(Note) transform, {bool immediate = false}) {
    final note = _note;
    if (note == null) return;
    final wasUndo = _undoStack.canUndo;
    final wasRedo = _undoStack.canRedo;
    // Tek boğaz noktası: sarma çapaları düzenleme tamponunda yaşar, nota
    // asla yazılmaz. Gövde hangi yoldan gelirse gelsin burada temizlenir —
    // her çağrı yerine ayrı koruma koymak yerine tek yerde.
    final transformed = transform(note);
    final clean = stripWrapAnchors(transformed.body);
    final next = clean == transformed.body
        ? transformed
        : transformed.copyWith(body: clean);
    if (!_restoring) {
      _undoStack.push(note, next, now: DateTime.now());
    }
    // SAF YAZIM (yalnız başlık/gövde metni değişti, geri al düğmesinin durumu
    // dahil görünür hiçbir parça etkilenmedi): 3700 satırlık build'i her tuş
    // vuruşunda çalıştırmak "klavye açılırken kasıyor" şikayetinin başrolüydü
    // — denetleyici metni zaten ekranda, ekran geneli setState atlanır.
    final pureTyping =
        _sameVisual(note, next) &&
        _undoStack.canUndo == wasUndo &&
        _undoStack.canRedo == wasRedo;
    if (pureTyping) {
      _note = next;
    } else {
      setState(() => _note = next);
    }
    // Arama açıkken metin değiştiyse eşleşme konumları kaydı: vurgular bir
    // sonraki karede yeniden hesaplanır.
    if (_findOpen) _queueFindRefresh();
    // KÖK NEDEN (bekleyen son kayıt yutuluyordu): bu kapanış `ref.read` ile
    // depoyu okuyordu, oysa `dispose()` içindeki `_debouncer.flush()` de aynı
    // kapanışı çalıştırır — ve `dispose` sırasında `ref` kullanmak istisna
    // atar (bkz. sınıfın başındaki not). Yani editörden çıkarken bekleyen
    // yazım kaydedilmediği gibi, atılan istisna dispose'un GERİ KALANINI da
    // (ek silme flush'ı, boş not temizliği, otomatik başlık) iptal ediyordu.
    // Depo artık her build'de tazelenen alandan okunur.
    // "En çok çalışılan" sıralamasının ölçüsü (bkz. noteActivityProvider):
    // oturumda İLK gerçek değişiklikte bir puan. Her tuş vuruşunda saymak
    // sayacı yazma hızına bağlardı — uzun bir nota bir cümle eklemek, kısa
    // bir notu baştan yazmaktan daha çok "çalışma" sayılmamalı.
    if (!_workCounted) {
      _workCounted = true;
      ref.read(noteActivityProvider.notifier).touch(widget.noteId);
    }

    void save() {
      final current = _note;
      if (current != null && !_deleted) {
        _notesRepo?.updateNote(current);
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

  /// Ek sınırı mesajı. İki ayrı sınır var ve ikisi de aynı istisna ağacından
  /// geliyor: TEK dosya boyutu (premium 50 MB / ücretsiz 10 MB) ve TOPLAM
  /// depolama tavanı ([StorageFullException]). [error] verilmezse dosya
  /// boyutu mesajı döner.
  String _tooLargeMessage([FileTooLargeException? error]) {
    if (error is StorageFullException) {
      return context.l10n.storageFull(formatBytes(error.quotaBytes));
    }
    final premium = ref.read(premiumProvider).value ?? false;
    final limitMb =
        (premium
            ? AppConstants.maxPremiumAttachmentBytes
            : AppConstants.maxFreeAttachmentBytes) ~/
        (1024 * 1024);
    return context.l10n.attachmentTooLarge(limitMb);
  }

  /// Görsel eklenmeden hemen önce ölçülen imleç yüksekliği (sayfa uzayı, dp).
  ///
  /// Ölçüm görsel gelince YAPILAMAZ: (+) menüsü açılırken klavye kapatılır ve
  /// odak düşer, galeri/kamera ise ekranı tümüyle terk eder. Bu yüzden değer
  /// menü açılmadan, klavyeden yapıştırılmadan ya da kısayol basılmadan ÖNCE
  /// alınıp burada saklanır. null = ölçülemedi (yığma yerleşimine düşülür).
  double? _caretPageY;

  /// Sayfa tuvalinin kaydırma denetleyicisi. Yeni görselin GÖRÜNEN alana
  /// düşmesi için gerekiyor (bkz. [_placeNewImage]).
  final _pageScroll = ScrollController();

  // ---- Not içi CANLI arama (bkz. NoteFindBar) ------------------------------

  /// Arama çubuğu alt çubuğun yerinde açık mı.
  bool _findOpen = false;
  final _findController = TextEditingController();
  final _findFocus = FocusNode();

  /// Bulunan eşleşmeler, sayfadaki sırayla (başlık, gövde, maddeler).
  List<_FindHit> _findHits = const [];

  /// Odaktaki eşleşme (-1 = yok).
  int _findIndex = -1;

  /// Vurgusu olan denetleyiciler — kapanışta/yeni aramada temizlenir.
  final Set<WrapTextController> _findPainted = {};
  bool _findRefreshQueued = false;

  /// Odaktaki metin alanındaki imlecin SAYFA (tuval) uzayındaki üst kenarı.
  double? _caretPageTop() {
    final page = _pageBox();
    final focused = FocusManager.instance.primaryFocus?.context;
    if (page == null || focused == null) return null;
    final editable = _findEditable(focused.findRenderObject());
    if (editable == null || !editable.attached || !editable.hasSize) {
      return null;
    }
    // Odak başka bir katmanda olabilir (alt sayfa, tam ekran görüntüleyici);
    // o zaman ölçüm sayfa uzayına çevrilemez.
    if (!_isDescendantOf(editable, page)) return null;
    final offset = editable.selection?.baseOffset ?? -1;
    final caret = offset < 0
        ? Rect.zero
        : editable.getLocalRectForCaret(TextPosition(offset: offset));
    return editable.localToGlobal(Offset(0, caret.top), ancestor: page).dy;
  }

  static RenderEditable? _findEditable(RenderObject? node) {
    if (node == null) return null;
    if (node is RenderEditable) return node;
    RenderEditable? found;
    node.visitChildren((child) => found ??= _findEditable(child));
    return found;
  }

  static bool _isDescendantOf(RenderObject node, RenderObject ancestor) {
    for (var p = node.parent; p != null; p = p.parent) {
      if (identical(p, ancestor)) return true;
    }
    return false;
  }

  /// İmlecin yerini görsel eklenmeden önce saklar (bkz. [_caretPageY]).
  void _rememberCaret() {
    final top = _caretPageTop();
    if (top != null) _caretPageY = top;
  }

  /// Yeni görselin sayfadaki başlangıç yeri ve boyu.
  ///
  /// Görsel YAZILAN SATIRA girer: eskiden sayfanın en üstüne ya da son görselin
  /// altına konuyordu, yani kullanıcı görseli her seferinde metnin yanına elle
  /// sürüklemek zorundaydı. İmleç ölçülemediyse (menüden gelmeyen akışlar, boş
  /// not) eski davranışa — mevcut içeriğin altına — düşülür. Boyut küçük (%32)
  /// başlar; tam genişlik metni tümüyle aşağı iterdi.
  Attachment _placeNewImage(Attachment image, Note note) {
    // PDF kutusu GENİŞ başlar: 0,32 genişlikte bir sayfada yazı okunmuyor,
    // kullanıcı her belgeyi elle büyütmek zorunda kalıyordu. Görselde 0,32
    // kalıyor — satıra üç görsel sığsın (bkz. packSlot).
    final width = image.kind == AttachmentKind.pdf ? 0.6 : 0.32;
    final pageWidth = _pageBox()?.size.width ?? 0;
    // SAYFA HENÜZ ÖLÇÜLMEDİ: dp hesabı yapılamaz, konum YAZILMAZ. Tuval
    // genişliği bildiği ilk karede görseli boş bir yere kendisi oturtur
    // (bkz. [packSlot]).
    //
    // KÖK NEDEN (kullanıcı 2026-09-05: "birden fazla görsel eklendiğinde üst
    // üste başlıyor"): burada eski görsellerin ALTI `pageWidth * displayWidth
    // / oran` ile ölçülüyordu. Ölçüm yokken `pageWidth` 0 olduğu için her
    // görselin "altı" kendi tepesine eşitleniyor, yeni görsel bir öncekinin
    // 16 dp altına — yani pratikte ÜSTÜNE — düşüyordu. Paylaşımdan gelen ve
    // çoklu seçimle eklenen görseller tam bu yoldan geçiyor.
    if (pageWidth <= 0) return image.copyWith(displayWidth: width);

    Rect boxOf(Attachment a) {
      final aspect = (a.width != null && a.height != null && a.height! > 0)
          ? a.width! / a.height!
          : 1.0;
      final w = pageWidth * (a.displayWidth ?? 0.5);
      return Rect.fromLTWH(
        (a.x ?? 0.06) * pageWidth,
        a.pageY ?? (a.y != null ? a.y! * kLegacyCanvasHeight : 0),
        w,
        w / aspect,
      );
    }

    // İmleç yoksa GÖRÜNEN alanın tepesi (kullanıcı isteği 2026-08-09: "görsel
    // eklendiğinde direk ekrana"). Eskiden ölçüm olmayan yollarda görsel var
    // olan bütün eklerin ALTINA yığılıyordu — uzun bir notta bu, ekranın
    // metrelerce aşağısı demekti: görsel eklenince ekranda hiçbir şey
    // değişmiyor, kullanıcı "eklenmedi" sanıyordu.
    final visibleTop = _pageScroll.hasClients ? _pageScroll.offset + 24 : null;
    final anchor = _caretPageY ?? visibleTop ?? (_bodyTop + 24);
    final aspect = (image.width != null &&
            image.height != null &&
            image.height! > 0)
        ? image.width! / image.height!
        : 1.0;
    final w = pageWidth * width;
    // Yeni görsel önce SATIRDA yan yana yer arar (0,32 genişlikle satıra üç
    // görsel sığar), yer kalmayınca alta iner — hiçbirinin üstüne binmez.
    final slot = packSlot(
      occupied: [
        for (final a in note.attachments)
          // Konumu yazılmamış ekler tuvalde zaten otomatik yerleşiyor;
          // onların dp kutusu burada bilinemez.
          if (a.floatsOnPage && (a.pageY != null || a.y != null)) boxOf(a),
      ],
      columnWidth: pageWidth,
      width: w,
      height: w / aspect,
      anchorTop: anchor,
      topLimit: _bodyTop,
    );
    var top = slot.top;
    // Sayfanın altına taşmasın: içerik yüksekliğini aşarsa oraya sabitlenir.
    final pageHeight = _pageBox()?.size.height;
    if (pageHeight != null && top > pageHeight) top = pageHeight;
    return image.copyWith(
      x: slot.left / pageWidth,
      pageY: top,
      displayWidth: width,
    );
  }

  /// [asFile] true ise görsel sayfaya yerleşmez, alt şeritte dosya eki olur.
  Future<void> _addImageBytes(
    Uint8List bytes,
    String fileName, {
    bool asFile = false,
  }) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      // Sıkıştırma + diske yazma büyük fotoğrafta saniyeler sürüyor ve o süre
      // boyunca ekranda hiçbir iz yoktu (bkz. [_busyTask]).
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () => repo.prepareImage(
          noteId: widget.noteId,
          bytes: bytes,
          fileName: fileName,
        ),
      );
      if (!mounted) return;
      _mutate(
        (n) => n.copyWith(
          attachments: [
            ...n.attachments,
            if (asFile)
              attachment.copyWith(asFile: true)
            else
              _placeNewImage(attachment, n),
          ],
        ),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      // Yalnız FileTooLargeException yakalanıyordu; başka her hata (web'de
      // dosya sistemi yok, disk dolu, izin reddi) yukarı kaçıp await'i
      // tamamlanmadan bırakıyordu → ekran donmuş görünüyor, mesaj çıkmıyordu.
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  /// [asFile] true ise seçilen görsel sayfaya değil ek şeridine girer.
  ///
  /// **ÇOKLU SEÇİM** (kullanıcı isteği 2026-08-09: "aynı anda birden fazla ek
  /// yüklenebilsin"): seçici tek dosyayla sınırlıydı; beş fotoğraf eklemek
  /// için "Ekle → Görsel" yolunu beş kez yürümek gerekiyordu. Seçilenler
  /// SIRAYLA eklenir (paralel değil): her ek notu yazıyor ve sayfadaki yerini
  /// bir öncekine göre hesaplıyor (bkz. [_placeNewImage]) — aynı anda
  /// koşsalardı hepsi aynı noktaya biner, üstelik büyük görsellerin
  /// sıkıştırması aynı anda belleğe yığılırdı.
  Future<void> _pickImage({bool asFile = false}) async {
    if (_isDesktop) {
      final group = XTypeGroup(
        label: context.l10n.exportImages,
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      );
      final files = await openFiles(acceptedTypeGroups: [group]);
      for (final file in files) {
        if (!mounted) return;
        await _addImageBytes(
          await file.readAsBytes(),
          file.name,
          asFile: asFile,
        );
      }
    } else {
      // Boyut tavanı platform tarafında uygulanır: 48 MP'lik bir fotoğrafın
      // ~20 MB'ı ana izoleye okunup sıkıştırma izolesine kopyalanıyordu;
      // ek zaten 1600 px'e küçültülüyor (bkz. _compressImage), kalite kaybı yok.
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 2400,
        maxHeight: 2400,
      );
      for (final file in files) {
        if (!mounted) return;
        await _addImageBytes(
          await file.readAsBytes(),
          file.name,
          asFile: asFile,
        );
      }
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
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (picked == null) return;
      await _addImageBytes(await picked.readAsBytes(), picked.name);
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
  }

  /// "Belge tara": kamerayla (masaüstünde seçilen fotoğraflardan) belge
  /// tarar. Sayfalar önce İNCELEME ekranından geçer (köşe düzeltme, filtre,
  /// döndürme — dosya-okuyucu projesinden taşınan boru hattı) ve sonuç ya
  /// **tek aranabilir PDF eki** ya da düzeltilmiş görsel ekleri olur.
  ///
  /// Görsel yolunda tarama bitince "yazılar da tanınsın mı?" sorulur; evet
  /// denirse sayfalar OCR'lanıp metin notun gövdesine yazılır. Soru sessizce
  /// atlanmıyor: OCR sayfa başına birkaç saniye sürüyor ve AI kotasından
  /// yiyor. (PDF yolunda soruya gerek yok: metin katmanı cihazda, ücretsiz.)
  Future<void> _scanDocument() async {
    final l10n = context.l10n;
    List<String>? pages;
    var autoCrop = false;
    if (DocumentScan.supported) {
      // Manifest'te CAMERA bildirildiği için Android çekim niyetini izin
      // olmadan REDDEDER (bkz. _takePhoto).
      final perms = ref.read(permissionsServiceProvider);
      if (!await perms.cameraGranted() && !await perms.requestCamera()) {
        if (mounted) _showSnack(l10n.permCameraInfo);
        return;
      }
      if (!mounted) return;
      try {
        pages = await DocumentScan.scanPages();
      } catch (e) {
        if (mounted) _showSnack(l10n.scanFailed('$e'));
        return;
      }
    } else if (_isDesktop) {
      // Masaüstünde ML Kit yok ama tarama artık VAR: seçilen fotoğraflar
      // kenar bulma + perspektif düzeltme + netleştirme borusundan geçer.
      final group = XTypeGroup(
        label: context.l10n.exportImages,
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      final files = await openFiles(acceptedTypeGroups: [group]);
      if (files.isEmpty) return;
      pages = [for (final f in files) f.path];
      autoCrop = true;
    } else {
      _showSnack(l10n.scanUnsupported);
      return;
    }
    if (pages == null || pages.isEmpty || !mounted) return;

    final result = await ScanReviewScreen.open(
      context,
      pages,
      autoCrop: autoCrop,
    );
    if (result == null || !mounted) return;

    final pdfBytes = result.pdfBytes;
    if (pdfBytes != null) {
      final repo = ref.read(attachmentRepositoryProvider);
      if (repo == null) return;
      try {
        final attachment = await repo.preparePdf(
          noteId: widget.noteId,
          bytes: pdfBytes,
          fileName: scanFileName(result.title, DateTime.now()),
        );
        _mutate(
          (n) => n.copyWith(attachments: [...n.attachments, attachment]),
          immediate: true,
        );
        if (mounted) _showSnack(l10n.scanPdfAdded);
      } on FileTooLargeException catch (e) {
        if (mounted) _showSnack(_tooLargeMessage(e));
      } catch (e) {
        if (mounted) _showSnack(l10n.attachmentFailed('$e'));
      }
      return;
    }

    // Görsel yolu: sayfa baytları bir kez okunur — hem eke hem (istenirse)
    // OCR'a aynı baytlar gider, dosya iki kez okunmaz.
    final pageBytes = <Uint8List>[];
    for (final path in result.imagePaths ?? const <String>[]) {
      final bytes = await DocumentScan.readPage(path);
      if (bytes != null) pageBytes.add(bytes);
    }
    if (pageBytes.isEmpty) {
      if (mounted) _showSnack(l10n.scanFailed('—'));
      return;
    }
    for (var i = 0; i < pageBytes.length; i++) {
      if (!mounted) return;
      await _addImageBytes(pageBytes[i], 'tarama-${i + 1}.jpg');
    }
    if (!mounted) return;
    _showSnack(l10n.scanPagesAdded(pageBytes.length));

    final wantsText = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.scanTextTitle),
        content: Text(l10n.scanTextBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.scanImageOnly),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.scanRecognizeText),
          ),
        ],
      ),
    );
    if (wantsText != true || !mounted) return;
    await _runAi(l10n.scanRecognizing, () async {
      final service = ref.read(geminiServiceProvider);
      for (final bytes in pageBytes) {
        final text = stripMarkdown(
          await service.extractTextFromImage(bytes, 'image/jpeg'),
        ).trim();
        if (!mounted) return;
        if (text.isNotEmpty) _appendText(text);
      }
    });
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

  /// Gövdedeki seçimin/imlecin üzerinde durduğu bağlantı (yoksa null).
  /// Alanın metni sarma çapaları içerdiğinden konum önce mantıksal metne
  /// çevrilir — çapalar sayılmasa adres sınırları kayardı.
  String? _selectedLink() {
    final selection = _bodyController.selection;
    if (!selection.isValid) return null;
    return linkAt(
      _bodyController.logicalText,
      wrapToLogicalOffset(_bodyController.text, selection.baseOffset),
    );
  }

  /// Gövdedeki imlecin üzerinde durduğu EK ETİKETİ (yoksa null).
  /// Bağlantı aramanın ([_selectedLink]) ek karşılığı; konum aynı gerekçeyle
  /// önce mantıksal metne çevrilir.
  Attachment? _selectedAttachmentTag() {
    final note = _note;
    final selection = _bodyController.selection;
    if (note == null || !selection.isValid) return null;
    final name = attachmentTagAt(
      _bodyController.logicalText,
      wrapToLogicalOffset(_bodyController.text, selection.baseOffset),
      [for (final a in note.attachments) a.fileName],
    );
    if (name == null) return null;
    return _attachmentForTag(note, name);
  }

  /// Etiket metninden eke: önce SEÇİLİ METİNDEN kurulan bağlar
  /// ([Note.tagLinks]), sonra dosya adıyla eşleşme. Sıra önemli — kullanıcı
  /// bir etikete dosya adının kendisini yazmışsa bağ yine de önce gelir.
  static Attachment? _attachmentForTag(Note note, String label) {
    for (final link in note.tagLinks) {
      if (link.label != label) continue;
      for (final a in note.attachments) {
        if (a.id == link.attachmentId) return a;
      }
    }
    for (final a in note.attachments) {
      if (a.fileName == label) return a;
    }
    return null;
  }

  /// Metne gömülü ek etiketini AÇAR.
  ///
  /// [editing] false ise ÖNİZLEME: görsel/belge salt okunur açılır (çizim,
  /// kırpma, döndürme düğmeleri çizilmez). true ise DÜZENLEME: aynı ekranlar
  /// düzenleme geri çağrılarıyla açılır. Kullanıcının istediği ayrım tam
  /// olarak bu — "tıklayınca önizlemesi açılır, bir butonla da düzenleme".
  void _openAttachmentTag(Attachment attachment, {required bool editing}) {
    if (!localFileExists(attachment.localPath) && !attachment.isUploaded) {
      _showSnack(context.l10n.attachmentNotSynced);
      return;
    }
    if (attachment.kind == AttachmentKind.image) {
      openImageViewer(
        context,
        attachment,
        editing ? _updateAttachment : (_) {},
        onCrop: editing ? _cropImage : null,
        onRotate: editing ? _rotateImage : null,
        // Nottaki BÜTÜN görseller (sayfadakiler + şerittekiler) galeri olur:
        // tam ekranda yana kaydırarak hepsinde gezilir.
        gallery: [
          for (final a in (_note?.attachments ?? const <Attachment>[]))
            if (a.kind == AttachmentKind.image) a,
        ],
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (attachment.kind) {
          AttachmentKind.pdf => PdfViewerScreen(
            attachment: attachment,
            onChanged: editing ? _updateAttachment : null,
          ),
          AttachmentKind.slide => SlideViewerScreen(
            attachment: attachment,
            onChanged: editing ? _updateAttachment : null,
          ),
          AttachmentKind.video => VideoViewerScreen(attachment: attachment),
          // Ses ekinin görüntüleyicisi yok; şeritteki oynatıcıdan çalınır.
          AttachmentKind.audio => ImageViewerScreen(attachment: attachment),
          AttachmentKind.image => ImageViewerScreen(attachment: attachment),
        },
      ),
    );
  }

  /// Ada göre eki bulup ÖNİZLEMEDE açar (madde satırından gelen dokunuş).
  /// Ad hem bağ etiketi hem dosya adı olabilir — çözüm [_attachmentForTag]'te.
  void _openTagByName(String name) {
    final note = _note;
    if (note == null) return;
    final attachment = _attachmentForTag(note, name);
    if (attachment != null) _openAttachmentTag(attachment, editing: false);
  }

  /// "+ Ekle" levhasından gelen ek gömme akışı.
  ///
  /// Seçim VARSA o yazıya bağlanır; yoksa imlecin olduğu yere dosya adıyla
  /// bir etiket yazılır. İki durumda da önce hangi ekin gömüleceği sorulur —
  /// kullanıcı levhaya "gömmek" için geldiği için akış hep bir sonuç üretir.
  Future<void> _embedAttachmentFlow() async {
    final note = _note;
    if (note == null) return;
    if (note.attachments.isEmpty) {
      _showSnack(context.l10n.attachmentTagNoAttachment);
      return;
    }
    final chosen = await _pickAttachmentToEmbed(note);
    if (chosen == null || !mounted) return;

    // Levha açılırken alınan anlık görüntü: klavye kapanınca seçim daralmış
    // olabilir (bkz. [_showAttachMenu]).
    final snapshot = _selectionSnapshot;
    final logical = _bodyController.logicalText;
    if (snapshot != null && snapshot.isValid && !snapshot.isCollapsed) {
      final start = wrapToLogicalOffset(
        _bodyController.text,
        snapshot.start,
      ).clamp(0, logical.length);
      final end = wrapToLogicalOffset(
        _bodyController.text,
        snapshot.end,
      ).clamp(start, logical.length);
      final label = logical.substring(start, end).trim();
      if (label.isNotEmpty) {
        _applyEmbed(label: label, attachment: chosen, start: start, end: end);
        return;
      }
    }
    // Seçim YOK: dosya adını imlece yazmak yerine bağlama kipine geç —
    // kullanıcı yazıyı sonra seçsin (istenen "ters" yön).
    _startPendingEmbed(chosen);
  }

  /// Gömülecek eki seçtiren levha.
  Future<Attachment?> _pickAttachmentToEmbed(Note note) =>
      showModalBottomSheet<Attachment>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final a in note.attachments)
                ListTile(
                  leading: Icon(switch (a.kind) {
                    AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
                    AttachmentKind.slide => Icons.slideshow_outlined,
                    AttachmentKind.video => Icons.videocam_outlined,
                    AttachmentKind.audio => Icons.audiotrack_outlined,
                    AttachmentKind.image => Icons.image_outlined,
                  }),
                  title: Text(
                    a.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(sheetContext, a),
                ),
            ],
          ),
        ),
      );

  /// Seçili aralığı etikete çevirir ve bağı nota yazar.
  ///
  /// [target] verilirse etiket O ALANA yazılır (madde satırı, başlık); alanın
  /// metni nota kendi `commit`'iyle geçer. Verilmezse gövdeye yazılır ve metin
  /// ile bağ TEK yazımda kaydedilir.
  void _applyEmbed({
    required String label,
    required Attachment attachment,
    required int start,
    required int end,
    FormatTarget? target,
  }) {
    final controller = target?.controller ?? _bodyController;
    final logical = controller.logicalText;
    // Metne yalnız ATAÇ eklenir; seçilen yazı olduğu gibi kalır.
    final tagged = '$kAttachmentTagPrefix$label';
    final text = logical.replaceRange(start, end, tagged);
    controller.setLogical(text, start + tagged.length);
    // Aynı etiket ikinci kez bağlanırsa eskisi değişir, çoğalmaz.
    List<NoteTagLink> links(Note note) => [
      for (final l in note.tagLinks)
        if (l.label != label) l,
      NoteTagLink(label: label, attachmentId: attachment.id),
    ];
    if (identical(controller, _bodyController)) {
      _mutate(
        (n) => n.copyWith(body: text, tagLinks: links(n)),
        immediate: true,
      );
    } else {
      // Alanın kendi kaydı önce koşar (madde metnini nota yazan tek yol o),
      // bağ ondan sonra eklenir.
      target!.commit();
      _mutate((n) => n.copyWith(tagLinks: links(n)), immediate: true);
    }
    _showSnack(context.l10n.attachmentTagInserted);
  }

  /// BAĞLAMA KİPİ: seçilmiş ama henüz bir yazıya bağlanmamış ek.
  ///
  /// Kullanıcı isteği 2026-08-16: "ek gömmede ters olarak da çalışmalı, yani
  /// önce eki seçip sonra metni seçme de olmalı". İlk sürüm yalnız tek yönü
  /// destekliyordu (önce yazıyı seç, sonra eki). İki yön de meşru: elinde
  /// dosya varken nereye koyacağına sonra karar vermek de olağan.
  ///
  /// Kip açıkken alt çubukta bir şerit durur ("… bağlanacak yazıyı seç") ve
  /// hem o şeritteki düğme hem de metin seçim menüsü bağlamayı bitirir.
  Attachment? _pendingEmbed;

  /// Etkin metin alanında en son yapılmış DOLU (boş olmayan) seçim ve o
  /// seçimin ait olduğu alan.
  ///
  /// **KÖK NEDEN (kullanıcı bulgusu 2026-08-18: "buraya bağla çalışmıyor,
  /// basıyorum bağlanmıyor").** `_finishPendingEmbed` seçimi doğrudan
  /// `_bodyController.selection`'dan okuyordu; oysa şeritteki düğmeye dokunmak
  /// gövde alanının DIŞINA dokunmaktır: `EditableText` odağı düşürüp seçimi
  /// imlece ÇÖKERTİYOR (`isCollapsed`). Bağlama sessizce iptal ediliyor,
  /// kullanıcıya yeniden "yazıyı seç" diyen aynı bildirim çıkıyordu — dışarıdan
  /// "hiçbir şey olmuyor" gibi görünen tam olarak buydu.
  ///
  /// **İKİNCİ TUR (kullanıcı bulgusu: "buraya bağla çalışmıyor HÂLÂ; basınca
  /// hiçbir şey olmuyor, 'bağla' yazısı kalmaya devam ediyor").** İlk çözüm
  /// ([TextFieldTapRegion] + yedek seçim) tek bir alanı, GÖVDEYİ varsayıyordu
  /// ve yedeğe düşemediği her durumda düğme SESSİZCE geri dönüyordu — kip
  /// açık kalıyor, kullanıcı aynı düğmeye tekrar tekrar basıyordu. Üç kapı
  /// birden kapatıldı:
  /// 1. Seçim artık **etkin alandan** hatırlanıyor (gövde, başlık ya da bir
  ///    MADDE satırı — bkz. [_setFormatTarget]); liste notunda da bağlanır.
  /// 2. Şeride PARMAK DEĞDİĞİ AN seçim yedekleniyor
  ///    ([_PendingEmbedBanner.onPointerDown]) — odak/seçim düşse bile bir kare
  ///    önce elimizde.
  /// 3. Seçim hiçbir yoldan bulunamazsa düğme artık SESSİZ KALMIYOR: etiket
  ///    imlecin yerine (yoksa metnin sonuna) dosya adıyla yazılır — yani
  ///    "Metne ekle"nin ilk günkü davranışı. Basmak HER ZAMAN bir sonuç üretir
  ///    ve kip kapanır.
  TextSelection? _lastSelection;
  FormatTarget? _lastSelectionTarget;

  void _rememberTargetSelection() {
    final target = _formatTarget;
    if (target == null) return;
    final selection = target.controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      _lastSelection = selection;
      _lastSelectionTarget = target;
    }
  }

  /// Bağlama kipini başlatır (ek seçildi, yazı bekleniyor).
  void _startPendingEmbed(Attachment attachment) {
    setState(() => _pendingEmbed = attachment);
    _showSnack(context.l10n.attachmentTagPickText);
  }

  /// Bağlama kipini o anki SEÇİMLE bitirir.
  ///
  /// Seçim üç kaynaktan sırayla aranır ve hiçbiri tutmazsa BİLE bir sonuç
  /// üretilir (bkz. [_lastSelection] — "basıyorum hiçbir şey olmuyor" kök
  /// nedeni):
  /// 1. **Etkin alanın canlı seçimi** — şerit [TextFieldTapRegion] içinde
  ///    olduğu için dokunmak odağı düşürmez, seçim çoğu zaman burada durur.
  /// 2. **Hatırlanan son dolu seçim** — odak yine de düştüyse (donanım
  ///    klavyesi, sistem geri jesti, alanın yeniden kurulması) yedek devreye
  ///    girer; hangi alandan geldiği de saklandığı için madde satırları da
  ///    çalışır.
  /// 3. **İmleç** — seçim yoksa etiket imlecin yerine dosya adıyla yazılır.
  ///
  /// Her üç yolda da kip KAPANIR: şeritte asılı kalan bir "bağla" yazısı,
  /// kullanıcının gördüğü asıl hataydı.
  void _finishPendingEmbed() {
    final attachment = _pendingEmbed;
    if (attachment == null) return;
    var target = _formatTarget;
    var selection = target?.controller.selection;
    final liveIsUsable =
        selection != null && selection.isValid && !selection.isCollapsed;
    if (!liveIsUsable) {
      target = _lastSelectionTarget;
      selection = _lastSelection;
    }
    final controller = target?.controller;
    var label = '';
    var start = 0;
    var end = 0;
    if (controller != null &&
        selection != null &&
        selection.isValid &&
        !selection.isCollapsed) {
      final logical = controller.logicalText;
      start = wrapToLogicalOffset(
        controller.text,
        selection.start,
      ).clamp(0, logical.length);
      end = wrapToLogicalOffset(
        controller.text,
        selection.end,
      ).clamp(start, logical.length);
      label = logical.substring(start, end).trim();
    }
    setState(() => _pendingEmbed = null);
    // Bağlandı: yedek seçim tüketildi, ikinci bir "Buraya bağla" aynı yazıyı
    // yeniden bağlamasın.
    _lastSelection = null;
    _lastSelectionTarget = null;
    if (label.isEmpty) {
      _insertTagAtCaret(attachment);
      return;
    }
    _applyEmbed(
      label: label,
      attachment: attachment,
      start: start,
      end: end,
      target: target,
    );
  }

  /// Seçim bulunamadığında bağlama kipinin ÇIKIŞI: etiket gövdedeki imlecin
  /// yerine (imleç de yoksa metnin sonuna) dosya adıyla yazılır.
  ///
  /// Bu, "Metne ekle"nin ilk günkü davranışı — yani kullanıcının bildiği bir
  /// sonuç. Sessizce hiçbir şey yapmamaktan her koşulda iyidir.
  void _insertTagAtCaret(Attachment attachment) {
    final logical = _bodyController.logicalText;
    final live = _bodyController.selection;
    final caret = live.isValid
        ? wrapToLogicalOffset(
            _bodyController.text,
            live.baseOffset,
          ).clamp(0, logical.length)
        : logical.length;
    _applyEmbed(
      label: attachment.fileName,
      attachment: attachment,
      start: caret,
      end: caret,
    );
  }

  /// Levha açılırken alınan seçim anlık görüntüsü (bkz. [_showAttachMenu]).
  TextSelection? _selectionSnapshot;

  /// SEÇİLİ METNE bir ek gömer (kullanıcı isteği 2026-08-16: "o yazıya PDF
  /// gömülür, o yazının altı çizilir kırmızı vurgulanır, tıklayınca PDF
  /// önizlemede açılır").
  ///
  /// Seçilen kelimenin başına ataç konur ve metnin kendisi etiket olur;
  /// hangi eke gittiği nota [Note.tagLinks] olarak yazılır. Metne gizli
  /// kimlik GÖMÜLMEZ — gerekçesi orada.
  Future<void> _embedIntoSelection(EditableTextState state) async {
    final note = _note;
    if (note == null) return;
    final selection = _bodyController.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final logical = _bodyController.logicalText;
    final start = wrapToLogicalOffset(
      _bodyController.text,
      selection.start,
    ).clamp(0, logical.length);
    final end = wrapToLogicalOffset(
      _bodyController.text,
      selection.end,
    ).clamp(start, logical.length);
    final label = logical.substring(start, end).trim();
    if (label.isEmpty) return;

    // Hangi ek gömülecek: notun EK ŞERİDİNDEKİ dosyalar. Ek yoksa önce
    // eklenmeli — buradan dosya seçtirip yüklemek, kullanıcının "hangi
    // notta ne var" beklentisini bozardı.
    final candidates = note.attachments;
    if (candidates.isEmpty) {
      _showSnack(context.l10n.attachmentTagNoAttachment);
      return;
    }
    final chosen = await showModalBottomSheet<Attachment>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final a in candidates)
              ListTile(
                leading: Icon(switch (a.kind) {
                  AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
                  AttachmentKind.slide => Icons.slideshow_outlined,
                  AttachmentKind.video => Icons.videocam_outlined,
                  AttachmentKind.audio => Icons.audiotrack_outlined,
                  AttachmentKind.image => Icons.image_outlined,
                }),
                title: Text(
                  a.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(sheetContext, a),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    _applyEmbed(label: label, attachment: chosen, start: start, end: end);
  }

  /// Gövde metninin seçim menüsü: imleç bir bağlantının üzerindeyse listenin
  /// başına "Bağlantıyı aç" eklenir, kalan seçenekler (kes/kopyala/yapıştır)
  /// platformun kendi listesinden gelir.
  Widget _bodyContextMenu(BuildContext menuContext, EditableTextState state) {
    // Kes/Kopyala temiz-metin sürümleriyle değiştirilir: varsayılanları
    // panoya biçim işaretlerini (`**`, `%%1:`) ve görünmez sarma çapalarını
    // HAM olarak yazıyordu — dışarı yapıştıran kullanıcı çöp görüyordu.
    final items = cleanClipboardMenuItems(state);
    // Biçim: seçili metne kalın/italik/altı çizili/renk uygular. Giriş noktası
    // SEÇİM çubuğu — biçim zaten "şu metne" uygulanır; ayrı bir düğme olsaydı
    // önce seçimi hatırlaması gerekirdi (klavye kapanınca seçim düşüyor).
    if (!state.textEditingValue.selection.isCollapsed) {
      items.add(
        ContextMenuButtonItem(
          label: context.l10n.formatMenu,
          onPressed: () {
            state.hideToolbar();
            showFormatSheet(
              context,
              controller: _bodyController,
              onApplied: () => _mutate(
                (n) => n.copyWith(body: _bodyController.logicalText),
                immediate: true,
              ),
            );
          },
        ),
      );
    }
    // EK ETİKETİ (kullanıcı isteği 2026-08-16): imleç "📎 rapor.pdf"in
    // üzerindeyse önizleme ve düzenleme buradan açılır.
    // BAĞLAMA KİPİ açıksa ilk madde odur: kullanıcı yazıyı yeni seçti,
    // yapacağı tek iş bağlamak.
    if (_pendingEmbed != null &&
        !state.textEditingValue.selection.isCollapsed) {
      items.insert(
        0,
        ContextMenuButtonItem(
          label: context.l10n.attachmentTagLinkHere,
          onPressed: () {
            state.hideToolbar();
            _finishPendingEmbed();
          },
        ),
      );
    }
    // SEÇİLİ YAZIYA EK GÖM: seçim varsa ve o seçim zaten bir etiket değilse.
    if (!state.textEditingValue.selection.isCollapsed &&
        _selectedAttachmentTag() == null) {
      items.insert(
        0,
        ContextMenuButtonItem(
          label: context.l10n.attachmentTagEmbed,
          onPressed: () {
            state.hideToolbar();
            unawaited(_embedIntoSelection(state));
          },
        ),
      );
    }
    final tagged = _selectedAttachmentTag();
    if (tagged != null) {
      items.insertAll(0, [
        ContextMenuButtonItem(
          label: context.l10n.attachmentTagPreview,
          onPressed: () {
            state.hideToolbar();
            _openAttachmentTag(tagged, editing: false);
          },
        ),
        ContextMenuButtonItem(
          label: context.l10n.attachmentTagEdit,
          onPressed: () {
            state.hideToolbar();
            _openAttachmentTag(tagged, editing: true);
          },
        ),
      ]);
    }
    final url = _selectedLink();
    if (url != null) {
      items.insert(
        0,
        ContextMenuButtonItem(
          label: context.l10n.openLink,
          onPressed: () {
            state.hideToolbar();
            openLink(url).then((opened) {
              if (!opened && mounted) _showSnack(context.l10n.linkOpenFailed);
            });
          },
        ),
      );
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  /// **ÇOKLU SEÇİM** (kullanıcı isteği 2026-08-09: "aynı anda birden fazla ek
  /// yüklenebilsin"): seçilen belgeler sırayla eklenir; biri hata verse
  /// (tavanı aşan dosya, okunamayan içerik) kalanlar yine girer.
  Future<void> _pickPdf() async {
    const group = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
    );
    for (final file in await DocPicker.pickMany(group)) {
      if (!mounted) return;
      await _addPdfFile(file);
    }
  }

  Future<void> _addPdfFile(XFile file) async {
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
      // Başka bir Not kullanıcısının gönderdiği "balonlu PDF" ise damga
      // katmanı sökülür ve balonlar/çizimler DÜZENLENEBİLİR olarak geri
      // yüklenir (bkz. PdfEdit.readSharedPdf). Sıradan PDF'te null döner.
      final restored = await PdfEdit.readSharedPdfInBackground(bytes);
      final attachment = await repo.preparePdf(
        noteId: widget.noteId,
        bytes: restored == null ? bytes : restored['bytes'] as Uint8List,
        fileName: _documentFileName(file.name, '.pdf'),
      );
      final stored = restored == null
          ? attachment
          : attachment.copyWith(
              bubbles: [
                for (final e in (restored['b'] as List?) ?? const [])
                  PageBubble.fromMap(Map<String, dynamic>.from(e as Map)),
              ],
              ink: [
                for (final e in (restored['i'] as List?) ?? const [])
                  InkStroke.fromMap(Map<String, dynamic>.from(e as Map)),
              ],
            );
      _mutate(
        (n) => n.copyWith(
          attachments: [...n.attachments, _placePdf(stored, n)],
        ),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  /// Balonlu (belge) notta duran belgenin dosya adı: **notun başlığı**;
  /// başlık boşsa dosyanın KENDİ adı + "notlar" (bkz. [documentBaseName]).
  ///
  /// Klasik metin notunda ek sıradan bir dosyadır ve adı DEĞİŞTİRİLMEZ —
  /// kullanıcı oraya bilinen adıyla bir dosya koydu, yeniden adlandırmak
  /// onu kaybettirirdi.
  String _documentFileName(String originalName, String extension) {
    final note = _note;
    if (note == null ||
        (note.type != NoteType.pdf && note.type != NoteType.slides)) {
      return originalName;
    }
    final base = documentBaseName(
      noteTitle: note.displayTitle,
      originalName: originalName,
      notesSuffix: context.l10n.docNameNotesSuffix,
    );
    return '$base$extension';
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
    final file = await DocPicker.pickOne(group);
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
        fileName: _documentFileName(file.name, '.pptx'),
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _pasteImage() async {
    // Kısayolla yapıştırırken odak metin alanındadır: görsel imlecin satırına
    // girsin diye ölçüm baytlar gelmeden önce alınır.
    _rememberCaret();
    final bytes = await Pasteboard.image;
    if (bytes == null) {
      if (mounted) _showSnack(context.l10n.clipboardEmpty);
      return;
    }
    await _addImageBytes(bytes, 'pano.png');
  }

  /// Klavyeden gelen görsel: Gboard'ın pano çubuğu ve "Yapıştır" düğmesi
  /// görseli düz metin yapıştırmadan AYRI bir yolla (Android `commitContent`)
  /// gönderir ve yalnızca alan desteklediğini bildirirse gönderir. Bu yüzden
  /// yapılandırma hem gövdeye hem liste öğelerine verilir; olmadığında klavye
  /// görseli hiç iletmez ve yapıştır düğmesi sessizce hiçbir şey yapmaz.
  // GETTER DEĞİL alan: her okumada yeni nesne üretmek `ItemsEditor`ı ve
  // `EditableText`i "widget değişti" saydırıp gereksiz `didUpdateWidget`
  // zincirleri tetikliyordu. Kapanış State'e bağlı, ömrü boyunca sabit.
  late final ContentInsertionConfiguration _keyboardImagePaste =
      ContentInsertionConfiguration(
        allowedMimeTypes: const [
          'image/png',
          'image/jpeg',
          'image/gif',
          'image/webp',
        ],
        onContentInserted: (content) {
          final data = content.data;
          if (data == null) return;
          // Klavyeden gelen görsel yazılan satıra girer: odak hâlâ alanda
          // olduğundan imleç burada ölçülebiliyor.
          _rememberCaret();
          unawaited(
            _addImageBytes(data, 'pano.${content.mimeType.split('/').last}'),
          );
        },
      );

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
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
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

  /// Nottan çıkarılan ama BAYTLARI henüz silinmemiş ekler.
  ///
  /// Dosya eskiden ek nottan çıkarılır çıkarılmaz siliniyordu; "Geri al" ile
  /// geri gelen ek bu yüzden boş bir yer tutucu olurdu. Silme editörden
  /// çıkarken yapılır: o an nota geri dönmemiş olanlar gerçekten gider.
  final _pendingAttachmentDeletes = <Attachment>[];

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
    _pendingAttachmentDeletes.add(attachment);
  }

  /// Editör kapanırken: nota geri dönmemiş eklerin baytlarını siler.
  void _flushAttachmentDeletes() {
    final note = _note;
    for (final attachment in _pendingAttachmentDeletes) {
      final restored =
          note != null && note.attachments.any((a) => a.id == attachment.id);
      if (restored) continue;
      _attachmentRepo?.deleteFromStorage(attachment).ignore();
      if (attachment.localPath.isNotEmpty) {
        File(attachment.localPath).delete().ignore();
        forgetLocalFile(attachment.localPath);
      }
    }
    _pendingAttachmentDeletes.clear();
  }

  /// Eki kopyalar: uygulama içi ek panosuna alır ve mümkünse sistem panosuna
  /// da yazar (görsel baytları Android/iOS/web'de, dosya yolu masaüstünde).
  ///
  /// Uygulama içi pano şart: sistem panosunun PDF/sunum/ses için karşılığı yok
  /// ve görselde bile ekin çizimi ile boyutu taşınmaz (bkz.
  /// attachment_clipboard.dart).
  Future<void> _copyAttachment(Attachment attachment) =>
      _copyAttachments([attachment]);

  /// Bir ya da daha çok eki panoya alır (kullanıcı isteği 2026-08-09:
  /// "görsellerde çoklu seçim ve kopyalama").
  ///
  /// Uygulama içi pano hepsini taşır; SİSTEM panosu ise tek görsel taşıyabilir
  /// (masaüstünde dosya listesi mümkün). Çoklu seçimde bu yüzden sisteme
  /// yalnız ilk görsel yazılır — uygulama içi yapıştırma hepsini getirir.
  Future<void> _copyAttachments(List<Attachment> attachments) async {
    if (attachments.isEmpty) return;
    final l10n = context.l10n;
    ref.read(attachmentClipboardProvider.notifier).copyAll(attachments);
    final repo = ref.read(attachmentRepositoryProvider);
    final attachment = attachments.first;
    try {
      // Baytları okumak (bulut kopyasında: indirmek) uzun sürebilir; şeritte
      // canlı gösterge dursun (bkz. [_busyTask]).
      await _runBusy(l10n.attachmentCopying, () async {
        if (attachment.kind == AttachmentKind.image) {
          final bytes = await repo?.readBytes(attachment);
          if (bytes != null) await Pasteboard.writeImage(bytes);
        } else if (_isDesktop) {
          final paths = [
            for (final a in attachments)
              if (a.localPath.isNotEmpty) a.localPath,
          ];
          if (paths.isNotEmpty) await Pasteboard.writeFiles(paths);
        }
      });
    } catch (_) {
      // Sistem panosuna yazmak her platformda mümkün değil (ör. masaüstünde
      // görsel yazımı yok). Uygulama içi kopya yine de alındı; kullanıcıya
      // hata göstermek yanıltıcı olurdu.
    }
    if (mounted) _showSnack(l10n.attachmentCopied);
  }

  /// Panodaki eki bu nota kopyalar (baytlar yeniden yazılır, yeni kimlik alır).
  Future<void> _pasteAttachment() async {
    final sources = ref.read(attachmentClipboardProvider);
    final repo = ref.read(attachmentRepositoryProvider);
    if (sources.isEmpty || repo == null) return;
    try {
      // Baytların yeniden yazılması saniyeler sürebilir: gösterge şeritte
      // dursun, kullanıcı düğmenin çalıştığını görsün (bkz. [_busyTask]).
      await _runBusy(context.l10n.attachmentUploading, () async {
        // SIRAYLA: her kopya sayfadaki yerini bir öncekine göre hesaplıyor
        // (bkz. [_placeNewImage]); aynı anda koşsalardı üst üste binerlerdi.
        for (final source in sources) {
          final copy = await repo.duplicate(
            noteId: widget.noteId,
            source: source,
          );
          if (!mounted) return;
          _mutate(
            (n) => n.copyWith(
              attachments: [
                ...n.attachments,
                if (copy.floatsOnPage) _placeNewImage(copy, n) else copy,
              ],
            ),
            immediate: true,
          );
        }
      });
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } on AttachmentMissingException {
      if (mounted) _showSnack(context.l10n.attachmentNotSynced);
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  /// Görseli sayfa ile ek şeridi arasında taşır (madde: "resimleri ek olarak
  /// yükleme seçeneği"). Sayfaya dönerken imlecin satırına yerleşir.
  void _setImageAsFile(Attachment image, bool asFile) {
    final note = _note;
    if (note == null) return;
    // PDF'in sayfada olup olmadığını `asFile` DEĞİL `onPage` söyler: eski
    // PDF eklerinin hepsinde `asFile: false` yazılı, anlamını değiştirmek
    // onları bir anda sayfanın ortasına taşırdı (bkz. Attachment.onPage).
    final moved = image.kind == AttachmentKind.pdf
        ? image.copyWith(onPage: !asFile)
        : image.copyWith(asFile: asFile);
    _updateAttachment(asFile ? moved : _placeNewImage(moved, note));
  }

  /// Yeni eklenen PDF'in yeri: klasik metin notunda SAYFAYA yerleşir (görsel
  /// gibi — kullanıcı isteği 2026-09-06), belge notunda ise notun kendi
  /// belgesidir ve şeritte/bölmede kalır.
  Attachment _placePdf(Attachment pdf, Note note) {
    if (note.type.isPageNoteType) return pdf;
    return _placeNewImage(pdf.copyWith(onPage: true), note);
  }

  /// Bir eki (görsel) yeni değerleriyle (genişlik/hiza) değiştirir — kullanıcı
  /// görseli notta elle boyutlandırıp hizalayınca çağrılır.
  /// Birden çok eki TEK yazımda günceller (tuvalde "satıra sığdır" ve
  /// "boyutları eşitle"): altı görseli tek tek yazmak altı kayıt ve altı
  /// geri-al adımı üretiyordu.
  void _updateAttachments(List<Attachment> updated) {
    if (updated.isEmpty) return;
    final byId = {for (final a in updated) a.id: a};
    _mutate(
      (n) => n.copyWith(
        attachments: [for (final a in n.attachments) byId[a.id] ?? a],
      ),
      immediate: true,
    );
  }

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

  /// Görseli KALICI olarak kırpar (tam ekrandaki kırpma ekranından gelir).
  /// [frac] görsel oranında (0–1) seçilen alan.
  Future<void> _cropImage(Attachment image, Rect frac) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      final cropped = await repo.cropImage(
        noteId: widget.noteId,
        attachment: image,
        left: frac.left,
        top: frac.top,
        right: frac.right,
        bottom: frac.bottom,
      );
      // Dosya AYNI yola yeniden yazıldı; Flutter'ın görsel önbelleği yolu
      // anahtar olarak kullandığından temizlenmezse eski (kırpılmamış) hâl
      // gösterilmeye devam ederdi. Tek tek atmak yetmiyor: not tuvali
      // `cacheWidth` ile sardığından anahtar `ResizeImage`, `FileImage` değil.
      // ponytail: kırpma seyrek bir işlem, önbelleği tümden atmak yeterince
      // ucuz — anahtar eşlemesini elle kurmak buna değmez.
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      _updateAttachment(cropped);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } on AttachmentMissingException {
      if (mounted) _showSnack(context.l10n.cropFailed);
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  /// Görseli KALICI olarak 90°'nin katıyla döndürür (tam ekrandaki döndür
  /// düğmesinden gelir). [quarterTurns] pozitif = saat yönü.
  ///
  /// Kırpmayla ([_cropImage]) aynı gerekçeler: aynı yola yeniden yazılan
  /// dosya için görsel önbelleği temizlenir, yoksa eski (dönmemiş) hâl
  /// gösterilmeye devam eder.
  /// Döndürülen eki geri döndürür ki tam ekran görüntüleyici KAPANMADAN
  /// kendini tazeleyebilsin (kullanıcı bulgusu 2026-08-16: "her döndürme
  /// işleminden sonra düzenleme ekranı kapanıyor"). Hata durumunda null.
  Future<Attachment?> _rotateImage(Attachment image, int quarterTurns) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return null;
    try {
      final turned = await repo.rotateImage(
        noteId: widget.noteId,
        attachment: image,
        quarterTurns: quarterTurns,
      );
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      _updateAttachment(turned);
      return turned;
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } on AttachmentMissingException {
      if (mounted) _showSnack(context.l10n.rotateFailed);
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
    return null;
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

  /// Klavyenin en son ÖLÇÜLEN yüksekliği. Klavye kapalıyken de saklanır:
  /// odak alındığı anda klavye daha açılmamış olur ama nereye kaydıracağımızı
  /// bilmek için yüksekliğini bilmek gerekir (bkz. [_revealCaret]).
  double _keyboardMemory = _kKeyboardGuess;

  /// Klavye boşluğunun YERLEŞİME GİRMİŞ hâli ([KeyboardSnap] gövdeye bunu
  /// veriyor). Sıfırsa klavye ya kapalı ya da hareket hâlinde: o durumda
  /// klavyenin kapladığı yer sayfanın yerleşiminde HENÜZ yoktur.
  double _keyboardInset = 0;

  /// İlk açılışta klavye hiç ölçülmemiş olur; Android'de tipik yükseklik.
  /// Tahmin tutmazsa oturma anındaki ikinci geçiş düzeltir.
  static const double _kKeyboardGuess = 300;

  /// Odaklı alanın İMLECİNİ klavyenin üstüne kaydırır.
  ///
  /// KÖK NEDEN — 1: **ALANIN TAMAMI DEĞİL, İMLEÇ** (kullanıcı bulgusu
  /// 2026-08-30: "uzun notlarda bir yere yazmak istediğimde klavye açılıp
  /// oraya odaklama hem geç kalıyor hem de güzel değil"). Burada eskiden
  /// `Scrollable.ensureVisible` ile ALANIN kendisi görünür kılınıyordu. Gövde
  /// TEK bir dev `TextField`tir: uzun bir notta o kutu ekrandan metrelerce
  /// uzundur ve `keepVisibleAtEnd` onun ALT KENARINI hizalar — kullanıcı
  /// notun ortasına dokunuyor, ekran notun SONUNA atlıyordu.
  ///
  /// KÖK NEDEN — 2: **GEÇ KALIYOR**. Kaydırma yalnız [KeyboardSnap] boşluğu
  /// oturttuğunda (klavye animasyonu + 140 ms) yapılıyordu. Artık odak
  /// alındığı ANDA, klavyenin bilinen yüksekliği ([_keyboardMemory])
  /// düşülerek kaydırılıyor; oturma anındaki ikinci geçiş yalnız tahmin
  /// tutmadıysa iş yapar.
  ///
  /// [hidden] sayfanın yerleşiminde HENÜZ olmayan, ama ekranı örtecek olan
  /// yükseklik (açılmakta olan klavye).
  void _revealCaret({double hidden = 0}) {
    if (!_pageScroll.hasClients) return;
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null || !focused.mounted) return;
    final editable = _findEditable(focused.findRenderObject());
    final position = _pageScroll.position;
    final viewport = position.context.notificationContext?.findRenderObject();
    if (editable == null ||
        !editable.attached ||
        !editable.hasSize ||
        viewport is! RenderBox ||
        !viewport.hasSize ||
        !_isDescendantOf(editable, viewport)) {
      // Ölçemedik (odak başka bir katmanda, alan henüz yerleşmemiş): eski
      // davranışa düş — hiç kaydırmamaktan iyidir.
      if (focused.mounted) {
        Scrollable.ensureVisible(
          focused,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
      return;
    }
    final offset = editable.selection?.extentOffset ?? -1;
    final caret = offset < 0
        ? (Offset.zero & Size(1, editable.preferredLineHeight))
        : editable.getLocalRectForCaret(TextPosition(offset: offset));
    final top = editable.localToGlobal(caret.topLeft, ancestor: viewport).dy;
    final bottom = top + math.max(caret.height, editable.preferredLineHeight);
    // İmleç kenara yapışmasın: bir-iki satırlık nefes payı.
    const margin = 28.0;
    final visibleBottom = viewport.size.height - hidden;
    var delta = 0.0;
    if (bottom + margin > visibleBottom) {
      delta = bottom + margin - visibleBottom;
    } else if (top - margin < 0) {
      delta = top - margin;
    }
    if (delta.abs() < 1) return;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < 1) return;
    position.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  /// Bir alan ODAK ALDIĞI anda imleci görünür kılar — klavyenin açılmasını
  /// beklemeden (bkz. [_revealCaret] kök neden 2). Kaydırma bir kare
  /// ertelenir: odak olayı yerleşimden önce gelebiliyor.
  void _revealCaretSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Klavye yerleşime girmişse (oturmuş) ekranı örten fazladan bir şey
      // yok; girmemişse açılacak klavyenin yüksekliği düşülür.
      _revealCaret(hidden: _keyboardInset > 0 ? 0 : _keyboardMemory);
    });
  }

  /// Sayfa tuvalinin alt sınırı: gövde alanının GÖRÜLEN EN BÜYÜK yüksekliği.
  ///
  /// KÖK NEDEN (2026-08-08 kullanıcı bulgusu: "klavye açılırken titreme kasma
  /// oluyor"): burada eskiden `constraints.maxHeight + viewInsets.bottom`
  /// yazıyordu. Değer doğruydu ama `viewInsetsOf` bir BAĞIMLILIK kurar —
  /// klavye animasyonunun HER karesinde (≈15 kare) sayfa tuvali, yüzen görsel
  /// bantları ve satır ölçümleriyle birlikte yeniden kuruluyordu. Titreme
  /// buydu.
  ///
  /// Şimdi MediaQuery'ye hiç dokunulmuyor: klavye kapalıyken ölçülen en büyük
  /// yükseklik saklanıyor ve taban o. Genişlik değişirse (yönelim, pencere)
  /// taban sıfırlanıp yeniden ölçülür. Alt sınır zaten bir MİNİMUM — fazlası
  /// görünmez, eksiği tuvali sıçratır.
  double _stableCanvasHeight(BoxConstraints constraints) {
    if (constraints.maxWidth != _canvasBaseWidth) {
      _canvasBaseWidth = constraints.maxWidth;
      _canvasBaseHeight = 0;
    }
    if (constraints.maxHeight.isFinite &&
        constraints.maxHeight > _canvasBaseHeight) {
      _canvasBaseHeight = constraints.maxHeight;
    }
    return _canvasBaseHeight;
  }

  double _canvasBaseWidth = 0;
  double _canvasBaseHeight = 0;

  /// O anki build'de kurulmuş tuval ağacı ve kurulduğu taban yükseklik.
  ///
  /// Klavye animasyonu boyunca gövdenin kısıtı her karede değişiyor ve
  /// `LayoutBuilder` yeniden koşuyor; taban yükseklik aynı kaldığı sürece
  /// BİREBİR AYNI widget örneği döndürülür ve Flutter alt ağacı hiç kurmaz.
  /// Her editör build'inde temizlenir — bayat ağaç bir kare bile yaşamaz.
  Widget? _canvasCache;
  double _canvasCacheHeight = -1;

  /// Serbest görsel tuvali + sayfa içeriği. [_canvasCache] ile birlikte
  /// çalışır; ayrı bir yöntem olması yalnız `build`i okunur tutmak için.
  Widget _buildCanvas({
    required double minHeight,
    required List<Attachment> imageAttachments,
    required double hintLineHeight,
    required TextStyle hintStyle,
    required bool useCanvasHint,
    required bool hasBodyField,
    required Widget pageContent,
    required AppLocalizations l10n,
  }) => SingleChildScrollView(
    controller: _pageScroll,
    padding: const EdgeInsets.only(bottom: 96),
    child: NotePageCanvas(
      // KLAVYEDEN BAĞIMSIZ taban — bkz. [_stableCanvasHeight].
      minHeight: minHeight,
      images: imageAttachments,
      onRemove: _removeAttachment,
      onChanged: _updateAttachment,
      onChangedMany: _updateAttachments,
      onCrop: _cropImage,
      onRotate: _rotateImage,
      onExtractText: _ocrImage,
      onCopy: _copyAttachment,
      onCopyMany: _copyAttachments,
      onDetach: (a) => _setImageAsFile(a, true),
      onVideoToNote: _videoToNote,
      topLimit: _bodyTop,
      // İpucu, gövde alanının İLK METİN SATIRINA hizalanır (dikeyde iç dolgu,
      // yatayda kenar boşluğu): imleçle aynı çizgide dursun.
      textTop: _kBodyTextTop,
      textLeft: _kGutter,
      hintLineHeight: hintLineHeight,
      hint: useCanvasHint
          // DOLGU YOK: ipucunun yeri tuvalde, metnin ilk satırının tam
          // çizgisinde hesaplanıyor (bkz. NotePageCanvas.textTop/textLeft).
          // Buraya konan her pay o hesabı kaydırır — eskiden üstte 16 dp
          // vardı ve ipucu metnin bir tık altında duruyordu.
          //
          // İpucu, gövdenin KENDİ stiliyle çizilir (yazı tipi, punto, satır
          // aralığı): tema stiliyle çizilirse notun büyütülmüş yazısında
          // ipucu ile imleç ayrı satırlara düşer.
          ? Text(
              l10n.bodyHint,
              style: hintStyle.copyWith(color: Theme.of(context).hintColor),
            )
          : null,
      onFloats: _applyFloats,
      // Boş alana dokunmak gövdeye odaklanır — yazmaya başlamak için aşağıya
      // dokunmak yeterli. Listede gövde alanı yok.
      onTapEmpty: hasBodyField
          ? () {
              if (!_bodyFocus.hasFocus) _bodyFocus.requestFocus();
            }
          : null,
      child: KeyedSubtree(key: _pageKey, child: pageContent),
    ),
  );

  /// Belge notunda bir BALONA yazılıyor: editörün alt çubuğu gizlenir.
  bool _immersiveBubble = false;

  /// PDF/sunum sayfasının ÜZERİNE yazma kipi (alt çubuktaki kalem düğmesi).
  /// Tam ekrana geçmeden bölmede çizim yapılır; kip açıkken tek parmak çizer,
  /// iki parmak gezinir (kullanıcı isteği 2026-08-08).
  bool _penMode = false;

  void _setImmersiveBubble(bool value) {
    if (_immersiveBubble == value || !mounted) return;
    setState(() => _immersiveBubble = value);
  }

  /// "Ekle" levhası: TEK sayfa, iki sütunlu ızgara (bkz. attach_sheet.dart).
  /// Eski iki katmanlı yapı (küçük açılır menü + ayrı "tüm ekler" levhası)
  /// kaldırıldı; her seçenek tek dokunuşla görünür.
  Future<void> _showAttachMenu() async {
    // İmleç ölçümü klavye kapatılmadan ÖNCE alınır: eklenecek görsel yazılan
    // satıra gitsin (odak düşünce ölçüm imkânsız).
    _rememberCaret();
    // SEÇİM DE anlık görüntüye alınır: levha açılırken klavye kapatılıyor ve
    // odak düşünce seçim daralabiliyor ("Yazıya ek göm" seçili yazıyı
    // kullanır — bkz. [_embedAttachmentFlow]).
    _selectionSnapshot = _bodyController.selection;
    _dismissKeyboard();
    final copied = ref.read(attachmentClipboardProvider);
    final action = await showAttachSheet(
      context,
      isDesktop: _isDesktop,
      pageNote: _note?.type.isPageNoteType ?? false,
      // "Yazıya ek göm" yalnız eki OLAN notta anlamlı.
      canEmbed:
          !(_note?.type.isPageNoteType ?? false) &&
          (_note?.attachments.isNotEmpty ?? false),
      // Birden çok ek kopyalandıysa ad yerine sayı yazılır.
      copiedAttachmentName: copied.isEmpty
          ? null
          : copied.length == 1
          ? copied.first.fileName
          : context.l10n.attachmentsCopiedCount(copied.length),
    );
    if (!mounted) return;
    switch (action) {
      // Karışık içerik: her not tipinde HEM serbest metin HEM madde listesi
      // eklenebilir (bkz. attach_sheet.dart — eskiden tipe göre yalnız biri
      // gösteriliyordu ve kullanıcı "liste ekle seçeneği yok" diyordu).
      case 'embed-attachment':
        await _embedAttachmentFlow();
      case 'list-item':
        _addChecklistItem();
      case 'text-block':
        // Metin notunda gövde ZATEN görünür; yalnız odaklanmak yeter.
        // Liste notunda gövde alanı gizliyse önce açılır.
        if (!_listBodyOpen) setState(() => _listBodyOpen = true);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _bodyFocus.requestFocus(),
        );
      case 'image':
        await _pickImage();
      case 'image-file':
        await _pickImage(asFile: true);
      case 'paste-attachment':
        await _pasteAttachment();
      case 'camera':
        await _takePhoto();
      case 'scan':
        await _scanDocument();
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
      // 'color' BURADAN KALKTI: sayfa görünümü artık biçim şeridinde
      // (bkz. attach_sheet.dart'taki gerekçe ve [_showColorSheet]).
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
    // Bugünün geçmiş bir saati: bildirim hiç planlanmaz (reminder_service
    // yalnız geleceği kurar) — sessizce kurmuş gibi görünmek yerine uyar.
    if (!reminder.isAfter(DateTime.now())) {
      if (mounted) _showSnack(context.l10n.reminderInPast);
      return;
    }
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

  /// Paylaş levhası: düz metin / not paketi (`.notpaket`) / balonlu PDF.
  ///
  /// Eskiden menüdeki "Paylaş" doğrudan düz metni gönderiyordu; PDF notunun
  /// düz metni çoğu zaman boş olduğu için düğme sessizce hiçbir şey yapmıyor,
  /// belgenin üzerindeki balonlar da hiçbir yoldan karşı tarafa gitmiyordu
  /// (kullanıcı bulgusu 2026-08-08). Bekleyen yazım önce kesinleşir: paylaşılan
  /// paket/PDF son hâli taşımalı.
  Future<void> _share() async {
    final note = _note;
    if (note == null) return;
    _flushPending(_titleController);
    _flushPending(_bodyController);
    if (!mounted) return;
    final current = _note ?? note;
    await showNoteShareSheet(
      context,
      ref,
      current,
      ownerId: widget.ownerId,
      // PDF/Word satırı editörün sayfa ölçüleriyle açılsın (görseller
      // nottaki yerlerinde çıksın — bkz. [_openNotesExport]).
      onExport: () => _openNotesExport(current),
    );
  }

  /// Notun metnini PAYLAŞIM biçimiyle panoya kopyalar (bkz. [noteShareText]):
  /// ⋮ menüsündeki "Kopyala". Seçip kopyalamaya gerek kalmadan tüm not.
  Future<void> _copyNoteText() async {
    final note = _note;
    if (note == null) return;
    _flushPending(_titleController);
    _flushPending(_bodyController);
    final text = noteShareText(
      _note ?? note,
      pageLabel: context.l10n.pageLabel,
    );
    if (text.trim().isEmpty) {
      _showSnack(context.l10n.shareAsTextEmpty);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showSnack(context.l10n.copied);
  }

  /// Üst bardaki ⋮ — iki sütunlu levha (bkz. note_menu_sheet.dart).
  Future<void> _openNoteMenu() async {
    final note = _note;
    if (note == null) return;
    // Levha metin alanı taşımıyor; klavye açık kalırsa levhanın yarısını
    // örter (alt bardaki diğer levhalarla aynı kural).
    _dismissKeyboard();
    final action = await showNoteEditorMenu(
      context,
      pinned: note.pinned,
      starred: note.starred,
      locked: note.locked,
      archived: note.archivedAt != null,
      isList: note.type == NoteType.checklist || note.type == NoteType.ordered,
      twoColumns: note.listColumns == 2,
      hasFloatingImages: note.attachments.any((a) => a.floatsOnPage),
      hasAttachments: note.attachments.isNotEmpty,
      canTemplate: canSaveAsTemplate(note),
      // Yalnız KENDİ notum (başkasının notu yerel yapılamaz) ve özellik
      // destekleniyorsa (web'de yok).
      localOnly: widget.ownerId == null && localOnlySupported(ref)
          ? ref.read(notesRepositoryProvider)?.isLocal(note.id) ?? false
          : null,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'pin':
        _mutate((n) => n.copyWith(pinned: !n.pinned), immediate: true);
      case 'star':
        _mutate((n) => n.copyWith(starred: !n.starred), immediate: true);
      case 'search':
        await _openNoteSearch();
      case 'stats':
        // Bekleyen yazım önce diske insin: sayaç yazılan son cümleyi de
        // saysın (aramada da aynı sıra).
        _flushPending(_bodyController);
        if (mounted) await showNoteStatsSheet(context, _note ?? note);
      case 'saveTemplate':
        // Son yazılan satır da şablona girsin.
        _flushPending(_titleController);
        _flushPending(_bodyController);
        if (mounted) await saveNoteAsTemplate(context, ref, _note ?? note);
      case 'share':
        await _share();
      case 'copyText':
        await _copyNoteText();
      case 'localOnly':
        // Son yazım önce nota insin: yerel kopya en güncel hâli taşısın.
        _flushPending(_titleController);
        _flushPending(_bodyController);
        if (!mounted) return;
        final changed = await toggleNoteLocalOnly(context, ref, _note ?? note);
        if (changed != null && mounted) setState(() {});
      case 'export':
        await _export();
      case 'listen':
        await _listen();
      case 'lock':
        await _toggleLock();
      case 'archive':
        _toggleArchive();
      case 'clear':
        await _clearContent();
      case 'toText':
        _convertToText();
      case 'toList':
        _convertToList();
      case 'sortItems':
        await _sortItems();
      case 'imagesToFiles':
        _allImagesToFiles();
      case 'toArchive':
        await _copyToArchive();
      case 'columns':
        _mutate(
          (n) => n.copyWith(listColumns: n.listColumns == 2 ? 1 : 2),
          immediate: true,
        );
      case 'settings':
        if (mounted) context.push('/settings');
      case 'delete':
        _delete();
    }
  }

  /// Notun eklerini bir ARŞİV DEFTERİNE fiziksel kopya olarak taşır.
  ///
  /// Hangi deftere gideceği sorulur; hiç defter yoksa kullanıcı önce bir
  /// tane oluşturmalı (defteri buradan sessizce yaratmak, kullanıcının
  /// haberi olmayan bir not üretirdi).
  Future<void> _copyToArchive() async {
    final note = _note;
    final notes = ref.read(notesRepositoryProvider);
    final attachments = ref.read(attachmentRepositoryProvider);
    if (note == null || notes == null || attachments == null) return;
    if (note.attachments.isEmpty) {
      _showSnack(context.l10n.archiveNothingToCopy);
      return;
    }
    final notebooks = [
      for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
        if (n.type == NoteType.archive && n.deletedAt == null) n,
    ];
    if (notebooks.isEmpty) {
      _showSnack(context.l10n.archiveNoNotebook);
      return;
    }
    final chosen = await showModalBottomSheet<Note>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final notebook in notebooks)
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(
                  notebook.displayTitle.trim().isEmpty
                      ? sheetContext.l10n.archiveNotebook
                      : notebook.displayTitle,
                ),
                onTap: () => Navigator.pop(sheetContext, notebook),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    _showSnack(context.l10n.generating);
    final count = await copyAttachmentsToArchive(
      source: note,
      archive: chosen,
      attachments: attachments,
      notes: notes,
    );
    if (!mounted) return;
    _showSnack(context.l10n.archiveCopied(count));
  }

  /// Sayfada YÜZEN bütün görselleri ek şeridine indirir (tek işlemde).
  ///
  /// Görselin kendi menüsündeki "Ek yap" ([_setImageAsFile]) aynı işi tek
  /// görsel için yapıyor; buradaki toplu sürüm kullanıcı isteği 2026-08-16
  /// ("metin içi görselleri eke dönüştürme butonu"). Tek `_mutate` çağrısı:
  /// görsel başına ayrı yazım hem Firestore'a on ayrı güncelleme gönderir
  /// hem de geri alma yığınını on adımla doldururdu.
  void _allImagesToFiles() {
    final note = _note;
    if (note == null) return;
    final count = note.attachments.where((a) => a.floatsOnPage).length;
    if (count == 0) return;
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.floatsOnPage)
              // PDF'in yerini `onPage` söylüyor (bkz. [_setImageAsFile]);
              // ona `asFile` yazmak kutuyu sayfada bırakırdı.
              a.kind == AttachmentKind.pdf
                  ? a.copyWith(onPage: false)
                  : a.copyWith(asFile: true)
            else
              a,
        ],
      ),
      immediate: true,
    );
    _showSnack(context.l10n.imagesToAttachmentsDone(count));
  }

  /// Liste notunu DÜZ METİN notuna çevirir — model çağırmadan.
  ///
  /// Maddeler gövdenin SONUNA eklenir (gövdede zaten bir açıklama olabilir)
  /// ve liste boşaltılır. Geri alınabilir: "- [x] süt" biçimindeki satırlar
  /// [itemsFromText] tarafından okunuyor, yani "metne çevir → listeye çevir"
  /// hem maddeleri hem işaretleri geri getirir.
  void _convertToText() {
    final note = _note;
    if (note == null || note.items.isEmpty) return;
    _flushPending(_bodyController);
    final converted = textFromItems(
      note.items,
      numbered: note.type == NoteType.ordered,
    );
    // `logicalText` — HAM `text` DEĞİL. KÖK NEDEN (kullanıcı 2026-08-16,
    // ekran görüntüsü): denetleyicinin metni görünmez SARMA ÇAPALARI (￼) ve
    // kelime birleştiricileri (⁠) taşıyor; ham metin gövdeye yazılınca o
    // karakterler nota kalıcı olarak girdi. Listeye geri dönüştürürken de
    // satır "￼- [x] ..." diye başladığı için madde işareti kalıbı eşleşmedi
    // ve maddelerde "OBJ- [x] ..." diye ham metin göründü.
    final existing = _bodyController.logicalText.trim();
    final body = existing.isEmpty ? converted : '$existing\n$converted';
    // `text =` değil `setLogical`: sarma planı yeni gövdeye göre yeniden
    // kurulsun, yoksa eski çapalar imleci kaydırır.
    _bodyController.setLogical(body, body.length);
    _mutate(
      (n) => n.copyWith(type: NoteType.text, body: body, items: const []),
      immediate: true,
    );
    _showSnack(context.l10n.convertedToText);
  }

  /// Düz metin notunu LİSTE notuna çevirir — model çağırmadan.
  /// Her boş olmayan satır bir madde olur, gövde boşalır.
  void _convertToList() {
    final note = _note;
    if (note == null) return;
    _flushPending(_bodyController);
    // Yine `logicalText` (bkz. [_convertToText]'teki kök neden).
    final items = itemsFromText(
      _bodyController.logicalText,
      newId: () => const Uuid().v4(),
    );
    if (items.isEmpty) {
      _showSnack(context.l10n.convertToListEmpty);
      return;
    }
    _bodyController.setLogical('', 0);
    _mutate(
      (n) => n.copyWith(
        type: NoteType.checklist,
        body: '',
        // Metin notunda zaten madde varsa (karışık içerik) onlar korunur ve
        // yeni maddeler ARKALARINA eklenir — dönüşüm hiçbir şey silmemeli.
        items: [...n.items, ...items],
      ),
      immediate: true,
    );
    _showSnack(context.l10n.convertedToList);
  }

  /// Maddeleri seçilen ölçüte göre sıralar (yerel, geri alınabilir bir
  /// düzenleme olarak kaydedilir).
  Future<void> _sortItems() async {
    final note = _note;
    if (note == null || note.items.isEmpty) return;
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<ItemSort>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (sort, label, icon) in <(ItemSort, String, IconData)>[
              (ItemSort.starredFirst, l10n.sortStarredFirst, Icons.star),
              (
                ItemSort.uncheckedFirst,
                l10n.sortUncheckedFirst,
                Icons.check_box_outline_blank,
              ),
              (
                ItemSort.alphabetical,
                l10n.sortAlphabetical,
                Icons.sort_by_alpha,
              ),
              (
                ItemSort.alphabeticalDesc,
                l10n.sortAlphabeticalDesc,
                Icons.sort_by_alpha,
              ),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.pop(sheetContext, sort),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    _mutate(
      (n) => n.copyWith(items: sortItems(n.items, choice)),
      immediate: true,
    );
  }

  /// **Dışa aktarma** — eski "PDF olarak dışa aktar" maddesinin yerini alır.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "PDF olarak dışa aktar eskide
  /// kaldı"): madde her not tipinde tek bir ekrana, `PdfExportScreen`e
  /// gidiyordu. O ekran BELGE (balonlu) notunda yalnız sayfa notlarının
  /// METNİNİ yazıyor; belgenin kendisini, üzerindeki balonları, vurguları ve
  /// el yazısını hiç almıyordu. Yani PDF notunu "PDF olarak dışa aktar"mak
  /// çoğu zaman boş ya da yarım bir dosya üretiyordu — oysa balonları belgeye
  /// basan yol (bkz. NoteShare.shareAnnotatedPdfs) ZATEN vardı, sadece
  /// Paylaş levhasının içine gömülüydü.
  ///
  /// Artık: notta balonlu/çizimli bir belge varsa hangi çıktının istendiği
  /// SORULUR; yoksa doğrudan metin/görsel dışa aktarma ekranı açılır.
  Future<void> _export() async {
    final note = _note;
    if (note == null) return;
    // Bekleyen yazım önce kesinleşsin: çıktı son hâli taşımalı.
    _flushPending(_titleController);
    _flushPending(_bodyController);
    if (!mounted) return;
    final current = _note ?? note;

    if (countStampablePdfs(current) == 0) {
      _openNotesExport(current);
      return;
    }
    final choice = await showExportChoiceSheet(context);
    if (choice == null || !mounted) return;
    if (choice == 'notes') {
      _openNotesExport(current);
      return;
    }
    await runNoteShare(context, ref, current, 'pdf');
  }

  /// Not metnini (+ görselleri) PDF/Word'e aktarma ekranı.
  void _openNotesExport(Note current) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfExportScreen(
          note: current,
          // Sayfa ölçüleri: görseller dışa aktarmada da nottaki yerlerinde
          // çıksın.
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
  }

  /// Notu sesli okur. Kilitli notta ayrıca doğrulama yok — editör zaten
  /// açılırken doğruluyor.
  ///
  /// **BELGE notunda notun kendi metni yetmez** (kullanıcı bulgusu
  /// 2026-08-08: "PDF sesli oku çalışmıyor"): PDF/sunum notunun düz metni
  /// SAYFA NOTLARIDIR ve çoğu notta boştur — okuma ekranı "okunabilir metin
  /// çıkmadı" diyip duruyordu. Artık belgenin KENDİ metni de okunuyor; sayfa
  /// notları varsa önce onlar gider (kullanıcının kendi yazdığı önce).
  Future<void> _listen() async {
    final note = _note;
    if (note == null) return;
    final title = note.title.trim();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenScreen(
          title: title.isEmpty ? context.l10n.appName : title,
          // Kilitli notun podcast metni de diske yazılmasın.
          allowCache: !note.locked,
          // toPlainText değil: başlık ve `- [x]` işaretleri okunmasın.
          loadText: () =>
              noteSpeechText(note, ref.read(attachmentRepositoryProvider)),
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
    // Snackbar KÖK messenger'da yaşar ve editör kapandıktan sonra da 4 sn
    // ekranda kalır: depo şimdiden yakalanır ki geri alma editörsüz de
    // çalışsın; unmount SONRASI dokunuşta denetleyici/ref/setState'e
    // dokunulmaz (dispose edilmiş controller'a yazmak çökertiyordu).
    // AÇIK OLAN notun deposu (`_notesRepo`): paylaşılan bir notta geri alma
    // sahibin koleksiyonuna yazmalı, benimkine değil.
    final repo = _notesRepo;
    showUndoSnackBar(
      context,
      message: context.l10n.noteUpdatedUndo,
      undoLabel: context.l10n.undo,
      onUndo: () {
        repo?.updateNote(before);
        if (!mounted) return;
        _titleController.text = before.title;
        _bodyController.text = before.body;
        setState(() => _note = before);
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
    if (mounted) context.push(noteRoutePath(id));
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
  /// **Metni tanı** — görseldeki yazıyı ortak tanıma ekranında açar.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "not içi metni tanı dendiğinde
  /// direkt tüm metni nota kopyalıyor, böyle olmaz — yine metni tanı ekranı
  /// gelmeli"): bu yol modele gidip dönen metni SORMADAN notun gövdesine
  /// ekliyordu. Kullanıcı yalnız bir telefon numarası isterken notun altına
  /// sayfanın tamamı düşüyor, üstelik her seferinde AI puanı yanıyordu.
  /// Artık [TextRecognizeScreen] açılır: metin cihazda tanınır, kullanıcı
  /// harf harf seçer ve kopyalar ya da "Nota ekle" der.
  ///
  /// ML Kit'in olmadığı yerde (masaüstü) eski model yolu KORUNUR — özellik
  /// büsbütün kaybolmasın.
  Future<void> _ocrImage(Attachment image) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    if (ScanOcr.supported) {
      final path = await recognizableImagePath(image, repo);
      if (!mounted) return;
      if (path == null) {
        _showSnack(l10n.attachmentNotSynced);
        return;
      }
      final inserted = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => TextRecognizeScreen(
            imagePath: path,
            imageWidth: image.width ?? 0,
            imageHeight: image.height ?? 0,
            title: image.fileName,
            canInsert: true,
          ),
        ),
      );
      if (!mounted || inserted == null || inserted.trim().isEmpty) return;
      _appendText(inserted.trim());
      return;
    }
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
      // Video da görsel gibi SAYFAYA yerleşir (imlecin satırına) ve olduğu
      // yerde oynatılır; "Ek olarak taşı" ile şeride alınabilir.
      _mutate(
        (n) => n.copyWith(
          attachments: [...n.attachments, _placeNewImage(attachment, n)],
        ),
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
  // Yazı tipi ve boyutu artık BİÇİM ÇUBUĞUNDA (alt çubuktaki "Aa"): palet
  // sayfasının içine gömülüyken bulunamıyordu ve boyut ancak hazır adımlardan
  // seçilebiliyordu. Çubukta yazı tipi tek dokunuş, boyut ise sürüklendikçe
  // canlı değişiyor (bkz. format_bar.dart).

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
            // Zemin görseli renk seçiminin yanında: ikisi de "notun zemini".
            ListTile(
              leading: const Icon(Icons.wallpaper),
              title: Text(l10n.noteBackgroundImage),
              onTap: () => Navigator.pop(sheetContext, 'image'),
            ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    if (target == 'image') {
      await _showBackgroundSheet();
      return;
    }
    final frame = target == 'frame';
    // Editörde şerit CANLI çalışır: dokunulan renk anında sayfaya uygulanır
    // ve şerit açık kalır (Keep davranışı). Kart menüsü/toplu işlem eski
    // "seç ve kapan" yolunu kullanmaya devam ediyor — orada önizlenecek bir
    // sayfa yok.
    await showNoteColorPicker(
      context,
      frame: frame,
      current: frame ? note.frameColor : note.color,
      onChanged: (picked) {
        if (!mounted) return;
        _mutate(
          (n) => frame
              ? n.copyWith(frameColor: picked)
              : n.copyWith(color: picked),
          immediate: true,
        );
      },
    );
  }

  /// Notun ZEMİN görselini içeriğin ARKASINA serer.
  ///
  /// Görsel görünüm alanına sabitlenir (sayfa kaydırılırken kaymaz): duvar
  /// kâğıdı gibi durur, metin üstünde okunur kalsın diye opaklığı nottan
  /// gelir ve zeminin üstüne notun kendi rengiyle bir örtü çekilir.
  Widget _withBackground(Note note, Attachment? image, Widget child) {
    if (image == null) return child;
    final provider = _backgroundProvider(image);
    if (provider == null) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: note.backgroundOpacity.clamp(0.05, 1),
            child: Image(image: provider, fit: BoxFit.cover),
          ),
        ),
        child,
      ],
    );
  }

  ImageProvider? _backgroundProvider(Attachment image) {
    // Önbellekli varlık denetimi + ekran genişliğine sınırlı decode: zemin
    // 1600 px'e kadar saklanıyor, tam boy bitmap'i bellekte tutmak boşuna.
    final targetWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    if (localFileExists(image.localPath)) {
      return ResizeImage(FileImage(File(image.localPath)), width: targetWidth);
    }
    if (image.downloadUrl.isNotEmpty) {
      return ResizeImage(
        CachedNetworkImageProvider(image.downloadUrl),
        width: targetWidth,
      );
    }
    return null;
  }

  /// Zemin görseli sayfası: seç / değiştir / kırp / görünürlük / kaldır.
  ///
  /// Kullanıcı isteği: "not zeminini seçilen bir fotoğraf yapma seçeneği
  /// olsun; koyarken kesme, üzerine yazı yazma, şeffaflığını değiştirme
  /// olsun ve sonradan da ayarlanabilsin."
  Future<void> _showBackgroundSheet() async {
    final note = _note;
    if (note == null) return;
    _dismissKeyboard();
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final current = _note;
          if (current == null) return const SizedBox.shrink();
          final image = current.backgroundImageId == null
              ? null
              : current.attachments
                    .where((a) => a.id == current.backgroundImageId)
                    .firstOrNull;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noteBackgroundImage,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: _backgroundProvider(image) == null
                            ? const SizedBox.shrink()
                            : Image(
                                image: _backgroundProvider(image)!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.opacity,
                          size: 18,
                          color: Theme.of(
                            sheetContext,
                          ).colorScheme.onSurfaceVariant,
                        ),
                        Expanded(
                          child: Slider(
                            value: current.backgroundOpacity.clamp(0.05, 1),
                            min: 0.05,
                            max: 1,
                            onChanged: (value) {
                              _mutate(
                                (n) => n.copyWith(backgroundOpacity: value),
                              );
                              setSheetState(() {});
                            },
                            onChangeEnd: (value) => _mutate(
                              (n) => n.copyWith(backgroundOpacity: value),
                              immediate: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '%${(current.backgroundOpacity * 100).round()}',
                            textAlign: TextAlign.end,
                            style: Theme.of(sheetContext).textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.crop),
                      title: Text(l10n.crop),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _cropBackground(image);
                      },
                    ),
                  ],
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.image_outlined),
                    title: Text(
                      image == null
                          ? l10n.chooseBackgroundImage
                          : l10n.changeBackgroundImage,
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _pickBackgroundImage();
                    },
                  ),
                  if (image != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.hide_image_outlined),
                      title: Text(l10n.removeBackgroundImage),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _removeBackgroundImage(image);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Zemin için görsel seçer: seçim → KIRPMA → ek olarak kaydet.
  Future<void> _pickBackgroundImage() async {
    final Uint8List bytes;
    final String name;
    if (_isDesktop) {
      final group = XTypeGroup(
        label: context.l10n.exportImages,
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      final file = await openFile(acceptedTypeGroups: [group]);
      if (file == null) return;
      bytes = await file.readAsBytes();
      name = file.name;
    } else {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (file == null) return;
      bytes = await file.readAsBytes();
      name = file.name;
    }
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      final attachment = await repo.prepareImage(
        noteId: widget.noteId,
        bytes: bytes,
        fileName: name,
      );
      final previous = _note?.backgroundImageId;
      _mutate(
        (n) => n.copyWith(
          attachments: [
            for (final a in n.attachments)
              if (a.id != previous) a,
            attachment,
          ],
          backgroundImageId: attachment.id,
        ),
        immediate: true,
      );
      if (!mounted) return;
      // Yerleştirirken kırpma: kullanıcı hangi bölgenin zemin olacağını seçer.
      await _cropBackground(attachment);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _cropBackground(Attachment image) async {
    final provider = _backgroundProvider(image);
    if (provider == null) return;
    final aspect =
        (image.width ?? 1) /
        ((image.height ?? 1) == 0 ? 1 : (image.height ?? 1));
    final rect = await Navigator.of(context).push<Rect>(
      MaterialPageRoute(
        builder: (_) =>
            ImageCropScreen(image: provider, aspect: aspect <= 0 ? 1 : aspect),
      ),
    );
    if (rect == null || !mounted) return;
    await _cropImage(image, rect);
  }

  void _removeBackgroundImage(Attachment image) {
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id != image.id) a,
        ],
        clearBackgroundImage: true,
      ),
      immediate: true,
    );
    // Baytlar HEMEN silinmez: normal ek silmeyle aynı erteleme (bkz.
    // _pendingAttachmentDeletes). Anında silinince "Geri al" bozuk
    // (senkronsuz) bir kayda dönüyordu.
    _pendingAttachmentDeletes.add(image);
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
    // Açık olan notun deposu: paylaşılan notu çöpe atmak sahibin
    // koleksiyonundaki dokümanı işaretler (bkz. [NoteEditorScreen.ownerId]).
    final repo = _notesRepo;
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
  /// Alt bardaki üç araç segmentinden biri.
  Widget _toolSegment({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Material(
        color: active ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: _kToolSegment,
            width: _kToolSegment,
            child: Icon(
              icon,
              size: 21,
              color: active ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  /// Alt çubuğun "Ekle" segmenti: TEK levhayı açar (attach_sheet.dart).
  ///
  /// Eski hâli iki katmanlıydı — küçük bir açılır menü (madde/görsel/PDF/renk)
  /// ve onun içinden açılan ikinci bir "tüm ekler" levhası. Aynı seçenek iki
  /// yerde duruyor, "Ekle" adı üç kez geçiyordu. Artık tek dokunuş, tek sayfa.
  /// Ek şeridini açıp kapatan düğme (sayı rozetli). Şeridin kendi başlık
  /// satırı kaldırıldı: kapalıyken artık HİÇ yer kaplamıyor.
  ///
  /// **Yeni ek geldiğinde YANIP SÖNER** (kullanıcı isteği 2026-08-09: "ek
  /// eklendiğinde alttaki ataç kısmı renklenmeli ve hafif yanıp sönmeli"):
  /// şerit kapalıyken (varsayılan) ek eklemek ekranda hiçbir iz bırakmıyordu —
  /// dosya gerçekten girdi mi, kullanıcı ancak ataca basıp bakınca
  /// anlıyordu. Sayı artınca düğme iki kez vurgu rengine yanar
  /// (bkz. [_attachPulse]).
  Widget _attachmentsToggle(AppLocalizations l10n, int count) {
    final scheme = Theme.of(context).colorScheme;
    final open = ref.watch(attachmentsExpandedProvider);
    return Tooltip(
      message: open ? l10n.hideAttachments : l10n.showAttachments,
      child: AnimatedBuilder(
        animation: _attachPulse,
        builder: (context, child) {
          // 0 → 1 → 0 iki kez: yanıp sönme. Renk ve metin rengi birlikte
          // döner ki rozet okunur kalsın.
          final t = _attachPulse.value;
          final glow = Color.lerp(
            open ? scheme.secondaryContainer : Colors.transparent,
            scheme.primary,
            t,
          )!;
          final ink = Color.lerp(scheme.onSurface, scheme.onPrimary, t)!;
          return Material(
            color: glow,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () =>
                  ref.read(attachmentsExpandedProvider.notifier).toggle(),
              child: Container(
                height: _kToolSegment,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file, size: 19, color: ink),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// PDF/sunum sayfasının ÜZERİNE yazma kalemi. Açıkken bölmede tek parmak
  /// çizer, iki parmak gezinir; renk/kalınlık/silgi/ok çubuğu bölmenin
  /// altında belirir (bkz. PdfNotePane.penMode).
  Widget _penToolButton(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: _penMode ? l10n.annotateDone : l10n.annotate,
      child: SizedBox(
        height: 44,
        width: 46,
        child: Material(
          color: _penMode ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => setState(() => _penMode = !_penMode),
            child: Icon(
              _penMode ? Icons.edit : Icons.edit_outlined,
              size: 20,
              color: _penMode ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// Alt çubuğun sağındaki MİKROFON düğmesi (iki tane: AI ve düz dikte).
  ///
  /// [badge] verilirse simgenin sağ üstüne küçük bir parıltı konur — iki
  /// mikrofonu tek bakışta ayıran işaret budur. [active] dikte AÇIKKEN
  /// düğmeyi vurgu rengine boyar: mikrofonun açık kaldığı fark edilmiyordu.
  Widget _voiceButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    IconData? badge,
    bool active = false,
    double size = 48,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final background = active ? scheme.primary : scheme.primaryContainer;
    final ink = active ? scheme.onPrimary : scheme.onPrimaryContainer;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(14),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 24, color: ink),
                if (badge != null)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Icon(badge, size: 11, color: ink),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Alt çubuktaki büyüteç ve ⋮ → "Notta ara": CANLI arama çubuğunu açar
  /// (kullanıcı isteği 2026-09-26: "sayfada canlı aranmalı, ayrı bir alanda
  /// değil; altta çıksın").
  Future<void> _openNoteSearch() async {
    if (_note == null) return;
    // Bekleyen biçim metne insin: aranan kelime az önce yazıldıysa tampon
    // son hâlini taşısın.
    _flushPending(_bodyController);
    if (!mounted) return;
    setState(() {
      _findOpen = true;
      _formatBarOpen = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_findOpen) return;
      _findFocus.requestFocus();
      if (_findController.text.trim().isNotEmpty) _runFind();
    });
  }

  void _closeFind() {
    for (final c in _findPainted) {
      c.clearSearchHighlights();
    }
    _findPainted.clear();
    _findController.clear();
    if (_findFocus.hasFocus) _findFocus.unfocus();
    setState(() {
      _findOpen = false;
      _findHits = const [];
      _findIndex = -1;
    });
  }

  void _queueFindRefresh() {
    if (_findRefreshQueued) return;
    _findRefreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findRefreshQueued = false;
      if (mounted && _findOpen) _runFind(keepIndex: true, reveal: false);
    });
  }

  /// Sayfadaki alanlarda arar, vurgular ve (istenirse) odaktaki eşleşmeye
  /// kaydırır. Alanların TAMPONU taranır (bkz. TextSearchIndex): vurgu ve
  /// kaydırma aynı konumlarla çalışır.
  void _runFind({bool keepIndex = false, bool reveal = true}) {
    final l10n = context.l10n;
    final query = _findController.text.trim();
    final previous = keepIndex && _findIndex >= 0 && _findIndex < _findHits.length
        ? _findHits[_findIndex]
        : null;
    final hits = <_FindHit>[];
    void scan(
      WrapTextController controller,
      FocusNode focus,
      String where,
      IconData icon,
    ) {
      if (query.isEmpty) return;
      final index = TextSearchIndex(controller.text);
      for (final match in index.find(query)) {
        hits.add(
          _FindHit(
            controller: controller,
            focus: focus,
            where: where,
            icon: icon,
            match: match,
            index: index,
          ),
        );
      }
    }

    scan(_titleController, _titleFocus, l10n.noteTitleLabel, Icons.title);
    final note = _note;
    if (note != null && !note.type.isPageNoteType) {
      scan(_bodyController, _bodyFocus, l10n.noteBodyLabel, Icons.notes_outlined);
    }
    final items = _itemsEditorKey.currentState?.searchFields() ?? const [];
    for (var i = 0; i < items.length; i++) {
      scan(
        items[i].controller,
        items[i].focus,
        '${l10n.itemLabel} ${i + 1}',
        Icons.check_box_outlined,
      );
    }
    var index = hits.isEmpty ? -1 : 0;
    if (previous != null) {
      // Düzenleme sonrası tazeleme: odak AYNI alanda, aynı ya da ilk
      // sonraki eşleşmede kalsın — imleç yazarken başa fırlamasın.
      final same = hits.indexWhere(
        (h) =>
            h.controller == previous.controller &&
            h.match.start >= previous.match.start,
      );
      if (same >= 0) index = same;
    }
    setState(() {
      _findHits = hits;
      _findIndex = index;
    });
    _paintFind();
    if (reveal) _revealFindHit();
  }

  /// Vurguları denetleyicilere dağıtır (odaktaki eşleşme koyu).
  void _paintFind() {
    final byController = <WrapTextController, List<(int, int)>>{};
    final currentIn = <WrapTextController, int>{};
    for (var i = 0; i < _findHits.length; i++) {
      final hit = _findHits[i];
      final list = byController.putIfAbsent(hit.controller, () => []);
      if (i == _findIndex) currentIn[hit.controller] = list.length;
      list.add((hit.match.start, hit.match.end));
    }
    for (final c in _findPainted.difference(byController.keys.toSet())) {
      c.clearSearchHighlights();
    }
    _findPainted
      ..clear()
      ..addAll(byController.keys);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hitColor = dark
        ? const Color(0x80C28B00)
        : const Color(0x66FFD54F);
    final currentColor = dark
        ? const Color(0xFFE65100)
        : const Color(0xFFFFA726);
    for (final entry in byController.entries) {
      entry.key.setSearchHighlights(
        entry.value,
        current: currentIn[entry.key] ?? -1,
        hitColor: hitColor,
        currentColor: currentColor,
      );
    }
  }

  void _stepFind(int delta) {
    final count = _findHits.length;
    if (count == 0) return;
    var next = (_findIndex + delta) % count;
    if (next < 0) next += count;
    setState(() => _findIndex = next);
    _paintFind();
    _revealFindHit();
  }

  /// Odaktaki eşleşmeyi sayfanın üst üçte birine kaydırır; zaten rahat
  /// görünüyorsa kıpırdatmaz.
  void _revealFindHit() {
    if (_findIndex < 0 || _findIndex >= _findHits.length) return;
    final hit = _findHits[_findIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fieldContext = hit.focus.context;
      if (fieldContext == null || !fieldContext.mounted) return;
      final editable = _findEditable(fieldContext.findRenderObject());
      if (editable == null ||
          !editable.attached ||
          !editable.hasSize ||
          !_pageScroll.hasClients) {
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.3,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      final position = _pageScroll.position;
      final viewport = position.context.notificationContext
          ?.findRenderObject();
      if (viewport is! RenderBox ||
          !viewport.hasSize ||
          !_isDescendantOf(editable, viewport)) {
        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.3,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      final length = editable.text?.toPlainText().length ?? 0;
      final start = hit.match.start.clamp(0, length);
      final end = hit.match.end.clamp(start, length);
      final boxes = editable.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      final rect = boxes.isEmpty
          ? editable.getLocalRectForCaret(TextPosition(offset: start))
          : boxes.first.toRect();
      final top = editable
          .localToGlobal(rect.topLeft, ancestor: viewport)
          .dy;
      final height = viewport.size.height;
      if (top >= height * 0.12 && top + rect.height <= height * 0.8) return;
      final target = (position.pixels + top - height * 0.3).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((target - position.pixels).abs() < 1) return;
      position.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Eşleşmeleri yarım pencerede listeler (bkz. showFindHitsSheet).
  Future<void> _openFindList() async {
    final note = _note;
    if (note == null) return;
    final query = _findController.text.trim();
    final views = <FindHitView>[
      for (final h in _findHits)
        () {
          final s = h.index.snippet(h.match, query.length);
          return (
            where: h.where,
            icon: h.icon,
            lead: s.lead,
            hit: s.hit,
            tail: s.tail,
          );
        }(),
    ];
    _dismissKeyboard();
    final picked = await showFindHitsSheet(
      context,
      hits: views,
      current: _findIndex,
      canDeepSearch: true,
    );
    if (picked == null || !mounted) return;
    if (picked == kFindDeepSearch) {
      await showNoteSearchSheet(
        context,
        ref,
        _note ?? note,
        initialQuery: query,
      );
      return;
    }
    if (picked < 0 || picked >= _findHits.length) return;
    setState(() => _findIndex = picked);
    _paintFind();
    _revealFindHit();
  }

  Widget _addToolButton(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: l10n.addAttachment,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _showAttachMenu,
          child: SizedBox(
            height: _kToolSegment,
            width: _kToolSegment,
            child: Icon(Icons.add, size: 21, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }

  /// Metni İMLECİN OLDUĞU YERE ekler; imleç bilinmiyorsa notun sonuna.
  ///
  /// KULLANICI BULGUSU 2026-08-30: "not içerisindeki sesli yazma butonu nota
  /// ekle dendiğinde imlecin olduğu yere eklemiyor, en başa metin notu olarak
  /// ekliyor." [_appendPlainText] metni gövdenin SONUNA, boş satır bırakarak
  /// yığıyordu — kullanıcı cümlenin ortasında konuşup devam edemiyordu.
  ///
  /// Hedef alan en son ODAKLANAN alandır ([_formatTarget]); levha açılırken
  /// odak düştüğü için canlı odağa bakmak yetmez. Başlık hedefse metin yine
  /// gövdeye gider (dikte başlığa yazılmaz).
  void _insertTextAtCaret(String raw) {
    final text = stripMarkdown(raw).trim();
    if (text.isEmpty) return;
    final note = _note;
    if (note == null) return;
    final target = _formatTarget?.controller;
    // Liste maddesinde yazılıyorsa metin O SATIRA girer (satırın notu
    // güncellemesi de editörün kendi yolundan geçsin).
    if (target != null &&
        target != _bodyController &&
        target != _titleController &&
        (_itemsEditorKey.currentState?.insertTextAtCaret(target, text) ??
            false)) {
      return;
    }
    // Gövde alanı yoksa (saf liste notu) ya da imleç hiç konmamışsa eski
    // davranış: metin nota eklenir.
    final hasBody = note.type == NoteType.text || note.body.trim().isNotEmpty;
    final selection = _bodyController.selection;
    if (!hasBody || !selection.isValid) {
      _appendPlainText(text);
      return;
    }
    final logical = _bodyController.logicalText;
    final result = insertAtCaret(
      logical,
      wrapToLogicalOffset(_bodyController.text, selection.baseOffset),
      text,
    );
    if (result.text == logical) return;
    _bodyController.setLogical(result.text, result.caret);
    _mutate((n) => n.copyWith(body: result.text), immediate: true);
  }

  // ————————————————————————————————————————————————————————————————
  // CANLI DİKTE — "sesle yazma"
  //
  // Kullanıcı isteği 2026-09-01: "mikrofon işareti direk sesle yazma olsun,
  // hemen yanına da AI anımsatacak farklı bir mikrofon butonu koyalım, bu da
  // şuanki durum olsun; sesle yazma çok pratik ve doğru olmalı, kişinin
  // imlecinin olduğu yere yazmalı."
  //
  // Alt çubuktaki İKİ mikrofon tam olarak bu ayrım:
  //  * `mic` (sade)      → BURASI: klavye gibi davranır, konuşulan söz
  //    imlecin olduğu yere anında yazılır, levha açılmaz, yapay zekâ
  //    çağrılmaz, kota harcanmaz.
  //  * `mic + parıltı`   → [_captureVoice]: eski davranış. Metin önce
  //    levhada gözden geçirilir, istenirse özetlenir/maddelere bölünür.
  //
  // **Neden "sil ve yeniden yaz"**: tanıyıcı her olayda o ana kadarki TAM
  // metni gönderir (bkz. DeviceSpeech.listen) ve söylenen bir kelimeyi
  // sonradan DÜZELTEBİLİR ("bir" → "birkaç"). Gelen parçayı imlece eklemek
  // metni ikizler; bu yüzden dikte boyunca yazdığımız aralık ([_dictationAt],
  // [_dictationLength]) hatırlanır ve her olayda o aralık yenisiyle
  // DEĞİŞTİRİLİR. Kullanıcının dikte sırasında elle yazdığı harfler aralığın
  // dışında kaldığı için korunur.
  StreamSubscription<({String? text, double? level})>? _dictationSub;

  /// Diktenin yazdığı alan (gövde, başlık ya da bir madde satırı) ve o
  /// alandaki yazma aralığı. Hedef, dikte BAŞLARKEN en son odaklanmış olan
  /// alandır ([_formatTarget]) — imleç oradadır.
  FormatTarget? _dictationTarget;
  int _dictationAt = 0;
  int _dictationLength = 0;

  /// Dikte boyunca ALANA YAZILMIŞ metin. Tanıyıcının yeni gönderdiği metin
  /// bununla birleştirilir (bkz. [dictationMerge]): yazılan cümle geriye
  /// gitmesin, satırı bölünmesin.
  String _dictationShown = '';

  bool get _dictating => _dictationSub != null;

  /// Sade mikrofon: dikteyi başlatır, açıksa bitirir.
  Future<void> _toggleDictation() async {
    if (_dictating) {
      await _stopDictation();
      return;
    }
    final l10n = context.l10n;
    // Yerleşik tanıma yoksa (Windows) canlı yazma mümkün değil: kullanıcı
    // düğmeye basınca hiçbir şey olmasın diye ses levhasına düşülür —
    // orada konuşma kaydedilip topluca yazıya dökülür.
    if (!await DeviceSpeech.isAvailable()) {
      if (mounted) await _captureVoice();
      return;
    }
    if (!await DeviceSpeech.ensureMicPermission()) {
      if (mounted) _showSnack(l10n.micPermissionDenied);
      return;
    }
    if (!mounted) return;

    // Hedef alan + imleç konumu ŞİMDİ dondurulur. Alan odaklı değilse
    // (kullanıcı nota hiç dokunmadan mikrofona bastı) gövdenin sonuna
    // yazılır ve odak gövdeye verilir — imleç gözle görülür bir yerde olsun.
    var target = _formatTarget;
    if (target == null) {
      _bodyFocus.requestFocus();
      target = _formatTarget;
    }
    final controller = target?.controller ?? _bodyController;
    final selection = controller.selection;
    _dictationTarget = target;
    _dictationAt = selection.isValid
        ? wrapToLogicalOffset(controller.text, selection.baseOffset)
        : controller.logicalText.length;
    _dictationLength = 0;
    _dictationShown = '';

    final sub = DeviceSpeech.listen().listen(
      (event) {
        final text = event.text;
        if (text == null || !mounted) return;
        _writeDictationAtCaret(text);
      },
      onError: (Object e) {
        // Yerli taraf oturumu kendi kapattıysa (arka plana düşme, uzun
        // sessizlik) bu bir hata değil, bitiştir: yazılan metin zaten notta.
        if (e is PlatformException &&
            (e.code == 'speech_background' || e.code == 'speech_idle')) {
          unawaited(_stopDictation());
          return;
        }
        unawaited(_stopDictation());
        if (mounted) {
          _showSnack(e is PlatformException ? (e.message ?? e.code) : '$e');
        }
      },
      onDone: () => unawaited(_stopDictation()),
    );
    if (!mounted) {
      await sub.cancel();
      return;
    }
    setState(() => _dictationSub = sub);
  }

  /// Dikteyi bitirir: akış kapatılır, şerit iner, metin olduğu gibi kalır.
  Future<void> _stopDictation() async {
    final sub = _dictationSub;
    if (sub == null) return;
    _dictationSub = null;
    _dictationTarget = null;
    _dictationLength = 0;
    _dictationShown = '';
    await sub.cancel();
    await DeviceSpeech.stop();
    // Son sözler beklemede kalmasın: yazım sırasında kayıt gecikmeliydi
    // (yukarıya bak), dikte biterken bir kez kesinleştirilir. `_saveNow`
    // denetleyici ile not arasındaki farkı yazan hazır yol.
    _saveNow();
    if (mounted) setState(() {});
  }

  /// Tanınan TAM metni hedef alandaki dikte aralığına yazar.
  ///
  /// Aralığın iki yanına, ancak GEREKİYORSA, birer boşluk konur — cümlenin
  /// ortasına konuşan kullanıcının sözü kelimeye yapışmasın ([insertAtCaret]
  /// ile aynı kural). İmleç her zaman yazılan sözün SONUNDA kalır.
  void _writeDictationAtCaret(String spoken) {
    if (spoken.trim().isEmpty) return;
    final target = _dictationTarget;
    final controller = target?.controller ?? _bodyController;
    final logical = controller.logicalText;
    // Gelen metin ÖNCE yazılanla birleştirilir: satır sonları boşluğa iner ve
    // kısalan (geri giden) sonuç yok sayılır — kullanıcı yazdığı cümlenin
    // bölünüp yeniden birleştiğini görmesin (bkz. [dictationMerge]).
    final merged = dictationMerge(_dictationShown, spoken);
    if (merged == _dictationShown) return;
    _dictationShown = merged;
    // Yazma kuralının kendisi saf bir işlevde (sınanabilsin diye).
    final result = dictationReplace(
      logical,
      _dictationAt,
      _dictationLength,
      merged,
    );
    final text = result.text;
    if (text == logical) return;
    _dictationLength = result.length;
    controller.setLogical(text, result.caret);
    // **KAYIT YAZMAKLA AYNI YOLDAN, GECİKMELİ.** Tanıyıcı saniyede birkaç kez
    // olay gönderiyor; alanın kendi `commit`i (gövde/başlık) `immediate: true`
    // ile yazdığından her olay ayrı bir Firestore yazımı olurdu — konuşurken
    // ağı ve kotayı boşuna yakan, üstelik kasan bir yol. Klavyeden yazarken
    // izlenen yol da bu değil: `TextField.onChanged` gecikmeli `_mutate`
    // çağırıyor. Madde satırı ise zaten kendi gecikmeli yolundan geçer
    // (ItemsEditor.onChanged), o yüzden orada alanın `commit`i kullanılır.
    if (identical(controller, _bodyController)) {
      _mutate((n) => n.copyWith(body: text));
    } else if (identical(controller, _titleController)) {
      _mutate((n) => n.copyWith(title: text));
    } else {
      target?.commit();
    }
  }

  /// Sesle yakalama: ortak levhayı açar, dönen metni seçilen eyleme göre işler.
  ///
  /// ESKİDEN dikte doğrudan gövdeye canlı yazıyordu; kullanıcı yanlış tanınan
  /// bir cümleyi ancak nottan silerek düzeltebiliyordu. Artık metin önce
  /// levhada gözden geçiriliyor, nota yalnız onaylanan hâli giriyor.
  ///
  /// Dönen metin İMLECİN yerine girer (bkz. [_insertTextAtCaret]).
  Future<void> _captureVoice() async {
    final result = await showVoiceCaptureSheet(
      context,
      target: VoiceCaptureTarget.editor,
    );
    if (result == null || !mounted) return;

    // Dökümü yapılamamış konuşma (anahtar yok / kota / ağ): kayıt nota SES EKİ
    // olarak girer — yapay zekâ çalışmasa da konuşma kaybolmaz.
    final audioPath = result.audioPath;
    if (audioPath != null) {
      await _attachVoiceAudio(audioPath, result.audioDuration);
      if (!mounted) return;
      if (result.text.trim().isNotEmpty) _insertTextAtCaret(result.text);
      return;
    }

    final instruction = voiceCaptureInstruction(result.action);
    if (instruction == null) {
      _insertTextAtCaret(result.text);
      return;
    }

    final l10n = context.l10n;
    setState(() => _aiTask = l10n.aiThinking);
    try {
      final text = await ref
          .read(geminiServiceProvider)
          .rewriteText(result.text, instruction);
      if (!mounted) return;
      _insertTextAtCaret(text.trim().isEmpty ? result.text : text.trim());
    } on GeminiException catch (e) {
      if (mounted) _showSnack(e.isAuthError ? l10n.aiNoApiKey : e.message);
    } catch (e) {
      if (mounted) _showSnack(l10n.aiError(e.toString()));
    } finally {
      if (mounted) setState(() => _aiTask = null);
    }
  }

  /// Sesli yakalama levhasından dönen (dökümü yapılamamış) kaydı nota ek olarak
  /// bağlar. Yol levhadan devralınır: burada kullanılmazsa dosya silinir.
  Future<void> _attachVoiceAudio(String path, Duration duration) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) {
      File(path).delete().ignore();
      return;
    }
    try {
      final attachment = await repo.prepareAudio(
        noteId: widget.noteId,
        sourcePath: path,
        duration: duration,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException catch (e) {
      File(path).delete().ignore();
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      File(path).delete().ignore();
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
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

  // Satır satır CANLI dikte (gövdeye anında yazan `_startInlineDictation` ve
  // liste notunda her duraklamayı madde yapan `_syncDictatedItems`) kaldırıldı:
  // yerini sesli yakalama levhası aldı (bkz. `_captureVoice`). Yanlış tanınan
  // cümle artık nota girmeden levhada düzeltiliyor. `_writeDictated` duruyor —
  // Keep tarzı sesli notu (`_startVoiceCapture`) o kullanıyor.

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
            items: [
              ...n.items,
              NoteItem(id: const Uuid().v4(), text: text),
            ],
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
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
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

  /// PDF sayfa yöneticisi: sil / döndür / sırala.
  ///
  /// Düzenleme yeni bir PDF BAYTI üretir (bkz. `data/pdf_edit.dart`); dosya
  /// aynı ek kimliğiyle yeniden yazılır ve `Attachment.pageIds` yeni düzene
  /// göre güncellenir — sayfa notları böylece sayfalarıyla BİRLİKTE taşınır.
  Future<void> _editPdfPages(Attachment doc, int pageCount) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPagesScreen(
            attachment: doc,
            pageCount: pageCount,
            onApply: (order, rotations) =>
                _applyPdfEdits(doc, pageCount, order, rotations),
            onBurnInk: () => _burnPdfInk(doc),
          ),
        ),
      );

  Future<void> _applyPdfEdits(
    Attachment doc,
    int pageCount,
    List<int> order,
    Map<int, int> rotations,
  ) => _runPdfEdit(doc, (bytes) async {
    var out = bytes;
    // ÖNCE döndürme: indeksler ESKİ düzene göre verildi, sıralama sonrası
    // uygulanırsa yanlış sayfalar döner.
    final byTurns = <int, List<int>>{};
    rotations.forEach((page, turns) {
      if (turns % 4 != 0) (byTurns[turns % 4] ??= []).add(page);
    });
    for (final entry in byTurns.entries) {
      out = await PdfEdit.rotatePagesInBackground(
        out,
        pageIndexes: entry.value,
        quarterTurns: entry.key,
      );
    }
    // SİLME ile SIRALAMA ayrı yollar: silme YERİNDE çalışır ve belgenin kendi
    // annotation'larını korur, sıralama ise sayfaları kopyaladığı için onları
    // kaybeder. Sıra değişmediyse ucuz ve kayıpsız olanı seçilir.
    final identityOrder = [for (var i = 0; i < pageCount; i++) i];
    // BOŞ SAYFA eklenmişse "yalnız silindi" kısayolu geçersizdir: yeni sayfa
    // ancak sıralama yolundan (yeniden kurma) doğar.
    final hasBlank = order.contains(PdfEdit.blankPage);
    final onlyDeleted =
        !hasBlank &&
        order.length < pageCount &&
        [for (final i in order) i].toString() ==
            [
              for (final i in identityOrder)
                if (order.contains(i)) i,
            ].toString();
    if (hasBlank || order.length != pageCount || !onlyDeleted) {
      if (onlyDeleted) {
        out = await PdfEdit.deletePagesInBackground(out, [
          for (final i in identityOrder)
            if (!order.contains(i)) i,
        ]);
      } else {
        out = await PdfEdit.reorderPagesInBackground(out, order);
      }
    }
    // Sayfa kimlikleri: önce SOMUTLAŞTIRILIR (bugüne kadar boş tutuluyordu),
    // sonra yeni düzene göre yeniden dizilir. Notların anahtarlarına
    // dokunulmaz — bu yüzden 3. sayfanın notu, o sayfa nereye giderse oraya
    // gider ve silinen sayfanın notu kayıtta kalır.
    // Boş sayfaya KENDİ kimliği verilir (uuid): kimliksiz bırakılsaydı
    // ondan sonraki sayfaların notları bir kayardı.
    final ids = reorderPageIds(
      materializePageIds(doc, pageCount),
      order,
      blankId: (_) => const Uuid().v4(),
    );
    return (bytes: out, pageIds: ids);
  });

  /// El yazısını belgenin İÇİNE gömer: paylaşılan PDF'te de görünsün.
  ///
  /// Gömme sonrası ekin `ink` alanı BOŞALTILIR — yoksa çizim hem belgede hem
  /// katmanda olur ve üst üste iki kez görünürdü.
  Future<void> _burnPdfInk(Attachment doc) => _runPdfEdit(
    doc,
    (bytes) async {
      final out = await PdfEdit.burnInkInBackground(bytes, doc.ink);
      return (bytes: out, pageIds: null);
    },
    clearInk: true,
    successMessage: true,
  );

  /// PDF düzenleme yollarının ortak gövdesi: baytları oku, işle, dosyayı
  /// yeniden yaz, eki güncelle.
  Future<void> _runPdfEdit(
    Attachment doc,
    Future<({Uint8List bytes, List<String>? pageIds})> Function(Uint8List)
    work, {
    bool clearInk = false,
    bool successMessage = false,
  }) async {
    final repo = _attachmentRepo;
    if (repo == null) return;
    try {
      final bytes = await repo.readBytes(doc);
      if (bytes == null) {
        if (mounted) _showSnack(context.l10n.attachmentNotSynced);
        return;
      }
      final result = await work(bytes);
      final stored = await repo.replaceDocumentBytes(
        noteId: widget.noteId,
        attachment: clearInk ? doc.copyWith(ink: const []) : doc,
        bytes: result.bytes,
        pageIds: result.pageIds,
      );
      if (!mounted) return;
      // Dosya AYNI yola yeniden yazıldı; pdfrx'in ve Flutter'ın önbellekleri
      // yolu anahtar olarak kullandığından temizlenmezse eski belge
      // gösterilmeye devam ederdi (kırpma yolundaki aynı gerekçe).
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      _updateAttachment(stored);
      if (successMessage) _showSnack(context.l10n.pdfInkBurned);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.pdfEditFailed('$e'));
    }
  }

  /// Belge notunun (PDF / sunum) gövdesi: başlık + iki bölmeli sayfa/not
  /// ekranı.
  ///
  /// Belge notun İÇİNDE yaşar (görseller gibi), sayfa geçişi notun içinde
  /// yapılır — ek şeridine gidip tam ekran açmak gerekmez. Not tipi belge olup
  /// da belgesi olmayan tek durum, dosya seçicinin iptal edilmesidir; o zaman
  /// da ekran kilitlenmez, "seç" düğmesi durur (not zaten boşsa çıkışta
  /// kendiliğinden silinir).
  Widget _pageNoteBody(
    Note note,
    Widget header,
    RichTextTheme richTheme,
    TextStyle textStyle,
  ) {
    final isSlides = note.type == NoteType.slides;
    final wanted = isSlides ? AttachmentKind.slide : AttachmentKind.pdf;
    Attachment? document;
    for (final a in note.attachments) {
      if (a.kind == wanted) {
        document = a;
        break;
      }
    }
    if (document == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSlides
                        ? Icons.slideshow_outlined
                        : Icons.picture_as_pdf_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSlides
                        ? context.l10n.slidesNoDocument
                        : context.l10n.pdfNoDocument,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: isSlides ? _pickSlide : _pickPdf,
                    child: Text(
                      isSlides
                          ? context.l10n.slidesChooseDocument
                          : context.l10n.pdfChooseDocument,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    final doc = document;
    // Anahtar EK KİMLİĞİ: belge değiştirilirse pano durumu (sayfa numarası,
    // alandaki metin) sıfırdan kurulmalı, yoksa eski belgenin 7. sayfasının
    // notu yeni belgenin 7. sayfasına yazılırdı.
    //
    // `noteOf`: anlık görüntü değil CANLI okuyucu — sayfa notuna yazmak "saf
    // yazım" sayıldığı için ekran geneli setState atlanır ve buraya geçirilen
    // bir `Note` bayat kalırdı (bkz. PageNotePane.noteOf).
    final pane = isSlides
        ? SlideNotePane(
            key: ValueKey('slide-pane-${doc.id}'),
            noteOf: () => _note ?? note,
            attachment: doc,
            textStyle: textStyle,
            richTheme: richTheme,
            onPageNoteChanged: (page, text) =>
                _mutate((n) => n.withPageNote(doc, page, text)),
            onAttachmentChanged: _updateAttachment,
            onFieldFocused: _setFormatTarget,
            onFieldDisposed: _clearFormatTargetFor,
            onImmersiveChanged: _setImmersiveBubble,
            penMode: _penMode,
            onPenModeChanged: (value) => setState(() => _penMode = value),
          )
        : PdfNotePane(
            key: ValueKey('pdf-pane-${doc.id}'),
            noteOf: () => _note ?? note,
            onEditPages: (pageCount) => _editPdfPages(doc, pageCount),
            attachment: doc,
            textStyle: textStyle,
            richTheme: richTheme,
            onPageNoteChanged: (page, text) =>
                _mutate((n) => n.withPageNote(doc, page, text)),
            onAttachmentChanged: _updateAttachment,
            onFieldFocused: _setFormatTarget,
            onFieldDisposed: _clearFormatTargetFor,
            onImmersiveChanged: _setImmersiveBubble,
            penMode: _penMode,
            onPenModeChanged: (value) => setState(() => _penMode = value),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balona yazılırken not başlığı da gizlenir: klavye ekranın yarısını
        // alıyor, o alan belgeye ve balon kartına lazım (kullanıcı isteği
        // 2026-08-08 — ekran görüntüsünde işaretlenen bölge).
        if (!_immersiveBubble) header,
        Expanded(child: pane),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // dispose'un kullanacağı bağımlılıklar her karede tazelenir (bkz. yukarı).
    _cacheDeps();
    // Tuval önbelleği YALNIZ bu build içindeki `LayoutBuilder` tekrarları
    // içindir (klavye animasyonunun kareleri). Editör yeniden kurulduğunda
    // bayat kalmasın diye burada, her şeyden önce düşürülür.
    _canvasCache = null;
    final l10n = context.l10n;
    final note = _note;
    // Alt çubuğun iki yeni düğmesi için: sayfada YÜZMEYEN ekler (şerit) ve
    // notun belge notu olup olmadığı (kalem düğmesi yalnız orada anlamlı).
    final fileAttachments = [
      for (final a in (note?.attachments ?? const <Attachment>[]))
        if (!a.floatsOnPage) a,
    ];
    final isDocumentNote =
        note != null &&
        (note.type == NoteType.pdf || note.type == NoteType.slides);
    // Ataç rozeti: sayı ARTTIYSA yanıp söner (bkz. [_pulseAttachBadge]).
    // Build sırasında animasyon başlatmak güvenli değil — bir kareye
    // ertelenir.
    if (note != null) {
      final count = fileAttachments.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pulseAttachBadge(count);
      });
    }

    if (note == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _loadFailed
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.note_alt_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noteNotFound,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () => context.pop(),
                        child: Text(l10n.back),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    final background = NoteColors.surface(context, note.color);
    // Satır içi biçimlendirmenin çizim ayarları: gövde ve maddeler AYNI
    // paleti kullanır (metindeki 1..5 indeksi her ikisinde aynı rengi verir).
    final richTheme = RichTextTheme(
      palette: NoteColors.richPalette,
      markerColor: Theme.of(
        context,
      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
    );
    _bodyController.richTheme = richTheme;
    _titleController.richTheme = richTheme;
    // Metne gömülü ek etiketleri (bkz. attachment_tag.dart) buradan
    // beslenir: ek silinip eklendikçe etiketin kırmızı çizilip çizilmeyeceği
    // değişir. Yalnız GÖVDE — başlığa ek etiketi konmaz.
    // Etiket adları: hem SEÇİLİ METİNDEN kurulan bağlar (kullanıcı isteği
    // 2026-08-16 — "o yazıya PDF gömülür") hem de dosya adıyla eklenen
    // etiketler. İkisi de aynı çizim yolundan geçer.
    _bodyController.attachmentNames = [
      for (final link in note.tagLinks)
        if (link.label.isNotEmpty) link.label,
      for (final a in note.attachments) a.fileName,
    ];
    // Notun kendi yazı tipi/boyutu: gövde ve maddeler `fontFamily`/`fontScale`
    // çiftinden, BAŞLIK ise kendi `titleFontFamily`/`titleFontScale`
    // değerlerinden beslenir — biçim çubuğu odaktaki alana yazar.
    final theme = Theme.of(context);
    final bodyBase = theme.textTheme.bodyLarge ?? const TextStyle();
    // Renk BURADA somutlaşır: satır içi opaklık (`&&k:...&&`) ancak var olan
    // bir rengin alfasını düşürebilir; stil rengi null bırakılırsa seçime
    // uygulanan şeffaflık hiç görünmezdi.
    final noteBodyStyle = applyNoteOpacity(
      applyNoteFont(
        bodyBase.copyWith(
          fontSize: (bodyBase.fontSize ?? 16) * note.fontScale,
          color: bodyBase.color ?? theme.colorScheme.onSurface,
        ),
        note.fontFamily,
      ),
      note.textOpacity,
      theme.colorScheme.onSurface,
    );

    // Üstündeki çip satırına yapışık: aradaki 8 dp, çipler başlığın ALTINDAYKEN
    // üst barla başlığı ayırmak içindi; artık o işi çip satırı görüyor.
    final titleField = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 4, 0),
      child: TextField(
        controller: _titleController,
        focusNode: _titleFocus,
        readOnly: widget.readOnly,
        onChanged: (_) =>
            _mutate((n) => n.copyWith(title: _titleController.logicalText)),
        style: applyNoteOpacity(
          applyNoteFont(
            (Theme.of(context).textTheme.headlineSmall ?? const TextStyle())
                .copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize:
                      (Theme.of(context).textTheme.headlineSmall?.fontSize ??
                          24) *
                      note.titleFontScale,
                  color:
                      Theme.of(context).textTheme.headlineSmall?.color ??
                      theme.colorScheme.onSurface,
                ),
            note.titleFontFamily,
          ),
          note.titleTextOpacity,
          theme.colorScheme.onSurface,
        ),
        // TEK SATIR (kullanıcı isteği 2026-08-08: "başlık tek satırdan
        // taşmasın"): uzun başlık alanın içinde yatay kayar, sayfa düzenini
        // aşağı itmez.
        maxLines: 1,
        textInputAction: TextInputAction.next,
        // Varsayılan `next` odak sırasındaki bir SONRAKİ öğeye gider — metin
        // olmayan bir öğeye düşerse klavye kapanıyordu. "İleri" doğrudan
        // gövdeye (liste notunda ilk maddeye) atlar.
        onEditingComplete: _focusAfterTitle,
        // Başlık da biçimlendirilebiliyor: Kes/Kopyala temiz-metin sürümü
        // (gövdeyle aynı gerekçe).
        contextMenuBuilder: (menuContext, state) =>
            AdaptiveTextSelectionToolbar.buttonItems(
              anchors: state.contextMenuAnchors,
              buttonItems: cleanClipboardMenuItems(state),
            ),
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

    // Başlık altındaki çip satırı: EKLEME eylemlerinin tümü tek bir "+"
    // menüsünde, satırda ise yalnız GERÇEKTEN VAR OLANLAR (hatırlatıcı,
    // klasör, etiketler) durur.
    //
    // Eskiden "Hatırlat" ve "Klasör" boşken bile birer çip kaplıyor, yanlarına
    // "Etiket · Başlık · Alarm" adlı geniş bir çip daha giriyordu; üç ekleme
    // düğmesi satırı doldurduğu için asıl bilgi (etiketler) ekrandan taşıyordu
    // (ekran görüntüsündeki dağınıklık). Artık satır boş notta tek bir "+"
    // düğmesinden ibaret, doldukça büyür.
    final actionEntries = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: 'reminder',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.alarm_add_outlined),
          title: Text(l10n.addReminder),
        ),
      ),
      if (PlaceReminderService.supported)
        PopupMenuItem(
          value: 'place-reminder',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add_location_alt_outlined),
            title: Text(l10n.placeReminder),
          ),
        ),
      PopupMenuItem(
        value: 'folder',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            noteFolder?.iconData ?? Icons.create_new_folder_outlined,
          ),
          title: Text(l10n.folder),
        ),
      ),
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
    ];

    // Tek "+" düğmesi: ekleme/öneri eylemlerinin tamamı burada.
    final actionsMenu = PopupMenuButton<String>(
      tooltip: l10n.noteMetaMenu,
      onSelected: (action) {
        switch (action) {
          case 'reminder':
            _pickReminder();
          case 'place-reminder':
            unawaited(showPlaceReminderSheet(context, ref, note));
          case 'folder':
            _pickFolder();
          case 'add-tag':
            _addTag();
          case 'suggest-tags':
            _suggestTags();
          case 'suggest-title':
            _suggestTitle();
        }
      },
      itemBuilder: (context) => actionEntries,
      child: Chip(
        avatar: _titleGenerating
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add, size: 16),
        // Etiketsiz, dar bir düğme: satırda yer kaplamasın.
        label: const SizedBox.shrink(),
        labelPadding: EdgeInsets.zero,
        padding: _kChipPadding,
        visualDensity: _kChipDensity,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    // Çip yazısı: gövdeyle aynı aileden ama küçük — satır üst bar ile başlık
    // arasındaki dar banda sığmalı (bkz. [metaChips]).
    final chipLabelStyle = theme.textTheme.labelMedium?.copyWith(
      fontSize: 12.5,
    );

    final metaChildren = <Widget>[
      // Yalnız KURULU hatırlatıcı çipte görünür; kurmak "+" menüsünden.
      if (note.reminderAt != null)
        InputChip(
          avatar: const Icon(Icons.alarm, size: 14),
          // Dar alanda çip etiketleri KISALTILIR (`...`): sığmayan bir metin
          // `Chip` içinde taşma hatası verir.
          label: Text(
            DateFormat('d MMM HH:mm').format(note.reminderAt!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          labelStyle: chipLabelStyle,
          padding: _kChipPadding,
          visualDensity: _kChipDensity,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          deleteIconBoxConstraints: _kChipDeleteBox,
          onPressed: _pickReminder,
          onDeleted: _clearReminder,
        ),
      // Klasör çipi yalnız notun klasörü VARSA; seçmek "+" menüsünden.
      if (noteFolder != null)
        InputChip(
          avatar: Icon(noteFolder.iconData, size: 14),
          label: Text(
            noteFolder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          labelStyle: chipLabelStyle,
          padding: _kChipPadding,
          visualDensity: _kChipDensity,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          deleteIconBoxConstraints: _kChipDeleteBox,
          onPressed: _pickFolder,
          onDeleted: () =>
              _mutate((n) => n.copyWith(clearFolderId: true), immediate: true),
        ),
      for (final tag in note.tags)
        InputChip(
          label: Text('#$tag', maxLines: 1, overflow: TextOverflow.ellipsis),
          labelStyle: chipLabelStyle,
          padding: _kChipPadding,
          visualDensity: _kChipDensity,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          deleteIconBoxConstraints: _kChipDeleteBox,
          onDeleted: () => _removeTag(tag),
        ),
    ];

    // **Çip alanı yeniden yazıldı** (kullanıcı bulgusu 2026-08-09: "etiket ve
    // klasör kısmı güzel değil, düzenlenmeli — yazılar kesiliyor, hizalı
    // değil").
    //
    // KÖK NEDEN: çipler başlık satırının sağında 168 dp'lik bir kutuya
    // sıkıştırılmış, üstelik her çip 80 dp'ye kırpılmıştı. 80 dp'ye bir çipin
    // dolgusu + silme (×) ikonundan sonra ~34 dp yazı kalıyor; "#yapılacak"
    // ekranda "#ya…" oluyordu. `Wrap` sağa dayalı olduğu için de çipler satır
    // satır kayıyor, hiçbir kenara hizalanmıyordu.
    //
    // Şimdi çipler başlığın ALTINDA, sayfa boyunca uzanan TEK satırlık yatay
    // bir şeritte: genişlik sınırı yok (etiket adı tam okunur), hepsi aynı
    // taban çizgisine hizalı ve sığmayanlar kaydırılarak görülür.
    // **BİR SATIR KAZANILDI** (kullanıcı isteği 2026-08-09: "etiket ve klasör
    // için olan artı butonu başlık satırında olsun; etiket yoksa etiket satırı
    // oluşmasın, eklenirse oluşsun"). Eskiden çip şeridi HER NOTTA 34 dp
    // yükseklikte duruyordu — içinde tek bir "+" düğmesi olsa bile. "+" artık
    // başlığın sağında; şerit ancak gerçekten bir çip (hatırlatıcı, klasör,
    // etiket) varsa kuruluyor, boş notta hiç yer kaplamıyor.
    final metaChips = metaChildren.isEmpty
        ? const SizedBox.shrink()
        : SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _kGutter),
              itemCount: metaChildren.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) =>
                  Align(alignment: Alignment.center, child: metaChildren[i]),
            ),
          );

    // Başlık satırı: alan + sağ kenarda "+" (ekleme/öneri menüsü).
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleField),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 10),
          child: actionsMenu,
        ),
      ],
    );

    // Sayfada yüzen görseller ve videolar: "ek olarak" işaretlenenler buraya
    // girmez, alt şeritte dosya eki olarak durur (bkz. Attachment.asFile).
    final imageAttachments = [
      for (final a in note.attachments)
        if (a.floatsOnPage && a.id != note.backgroundImageId) a,
    ];
    // Zemin görseli: ekler listesinde durur ama sayfada yüzmez, şeritte de
    // görünmez — arkada duvar kâğıdı gibi çizilir.
    final bgImage = note.backgroundImageId == null
        ? null
        : note.attachments
              .where((a) => a.id == note.backgroundImageId)
              .firstOrNull;

    // Görseller sayfanın üzerinde serbest katmanda yüzer ve metnin ÜSTÜne
    // çizilir. Yazılı metin görselin etrafından akar (bkz. text_wrap.dart),
    // ama ipucu metni DEKORASYONDUR — akmaz, sabit yerinde durur ve üste
    // sürüklenen görselin altında kaybolur.
    //
    // Eskiden bu, görseli bir satır aşağı ZORLAYARAK çözülüyordu (topLimit'e
    // bir satırlık pay eklenirdi); bedeli, kullanıcının görseli en üst satıra
    // hiç koyamamasıydı. Artık ters yönde çözülür: görsel serbest, ipucu
    // görselin altına iner (bkz. [NotePageCanvas.hint]).
    // İpucu satırının bandı = metnin GERÇEK satır yüksekliği.
    //
    // KÖK NEDEN: burada notun kendi yazı ölçeği (`fontScale`) yok sayılıyor
    // ve satır aralığı 1.45 diye TAHMİN ediliyordu. Alan ise satırlarını
    // stilin çıpasına kilitliyor (bkz. [wrapStrutStyle]); büyük puntolu bir
    // notta ipucu ile imleç bu yüzden ayrı satırlara düşüyordu.
    final hintLineHeight =
        MediaQuery.textScalerOf(context).scale(noteBodyStyle.fontSize ?? 16) *
        (noteBodyStyle.height ?? 1.45);
    // Tuval ipucunu yalnız gerçekten çakışma olabilecek durumda üstlenir:
    // gövde boş VE sayfada görsel var. Diğer hâllerde TextField'ın kendi
    // ipucu kullanılır (odak/animasyon davranışı bozulmasın).
    final useCanvasHint =
        note.type == NoteType.text &&
        note.body.trim().isEmpty &&
        imageAttachments.isNotEmpty;

    // Son güncelleme zamanı artık ÜST BARDA (başlık yerinde) duruyor: gövdenin
    // içinde her açılışta bir satır yer kaplıyordu ve "Düzenlendi:" öneki
    // tarihin kendisinden uzundu. Üst barda önek olmadan okunuyor.
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [titleRow, metaChips],
    );

    // Gövde metin alanı: saf metin modunda ve karışık (metin+madde) modda
    // aynı controller/focus'u paylaşır. Madde varken kısalır (2 satır tabanı).
    final bodyField = TextField(
      controller: _bodyController,
      focusNode: _bodyFocus,
      readOnly: widget.readOnly,
      // Sarma planı bu stille hesaplanır; TextField'ın örtük varsayılanına
      // bırakılırsa ölçüm ile çizim ayrışır ve satırlar yanlış kırılır.
      style: noteBodyStyle,
      // SATIR YÜKSEKLİĞİ ÇIPASI AÇIKÇA VERİLİR: alan zaten `forceStrutHeight`
      // ile çiziyor, sarma ölçümü de aynı çıpayı kullanıyor (bkz.
      // [wrapStrutStyle]). Açıkça vermek eşleşmeyi `EditableText`in
      // varsayılanına bırakmaz — kaymanın kök nedeni buydu.
      strutStyle: wrapStrutStyle(noteBodyStyle),
      onChanged: (value) =>
          _mutate((n) => n.copyWith(body: _bodyController.logicalText)),
      maxLines: null,
      minLines: note.items.isEmpty ? 8 : 2,
      keyboardType: TextInputType.multiline,
      // EK ETİKETİNE DOKUNUNCA ÖNİZLEME (kullanıcı isteği 2026-08-16).
      //
      // Span'in kendisine `TapGestureRecognizer` bağlanamıyor: düzenlenebilir
      // bir alanda dokunuş imleci taşımak için EditableText'e gidiyor ve
      // span tanıyıcıları hiç ateşlenmiyor. `onTap` ise dokunuş imleci
      // TAŞIDIKTAN SONRA çalışır — imlecin nereye düştüğüne bakmak, "etikete
      // dokunuldu mu" sorusunun bu alandaki tek doğru cevabı.
      onTap: () {
        final tagged = _selectedAttachmentTag();
        if (tagged != null) _openAttachmentTag(tagged, editing: false);
      },
      // Bağlantıya uzun basınca seçim menüsüne "Bağlantıyı aç" eklenir.
      // Düzenlenebilir bir alanda span'e tıklama Flutter'da çalışmaz (dokunuş
      // imleci taşımak için EditableText'e gider), bu yüzden yol seçim menüsü.
      contextMenuBuilder: (menuContext, editableState) =>
          _bodyContextMenu(menuContext, editableState),
      contentInsertionConfiguration: _keyboardImagePaste,
      decoration: InputDecoration(
        // Görsel ipucunun üstüne gelebiliyorsa ipucu tuvale devredilir.
        hintText: useCanvasHint ? null : l10n.bodyHint,
        filled: false,
        border: InputBorder.none,
        // İÇ DOLGU AÇIKÇA: ilk metin satırının alanın tepesinden ne kadar
        // aşağıda başladığı hem sarma ölçümüne ([_wrapped]) hem de tuval
        // ipucuna ([NotePageCanvas.textTop]) veriliyor. Flutter'ın örtük
        // varsayılanına bırakılırsa üç yer sessizce ayrışır.
        contentPadding: const EdgeInsets.symmetric(vertical: _kBodyTextTop),
      ),
    );

    // Başlık + çipler: yüksekliği görsellerin üst sınırıdır.
    final keyedHeader = KeyedSubtree(key: _bodyTopKey, child: header);

    // Sayfa içeriği not tipine göre değişir; SARAN KATMAN hepsinde aynıdır:
    // görseller (el yazısı çizimleri dahil) tüm sayfanın üzerinde serbest
    // katmanda yüzer, metnin sağına/soluna sürüklenir ve metin etrafından akar.
    final Widget pageContent;
    if (note.type.isPageNoteType) {
      // Belge notunda sayfa tuvali (yüzen görseller + metin sarma) YOK: gövde
      // iki sabit bölmeye ayrılır, bu yüzden `body` aşağıda ayrı kurulur ve
      // buradaki tuval içeriği kullanılmaz.
      pageContent = const SizedBox.shrink();
    } else if (note.type == NoteType.text && note.items.isEmpty) {
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
        key: _itemsEditorKey,
        items: note.items,
        showCheckboxes: true,
        expandItems: ref.watch(expandListItemsProvider),
        onChanged: (items) => _mutate((n) => n.copyWith(items: items)),
        floats: _floats,
        pageBox: _pageBox,
        shrinkWrap: true,
        contentInsertion: _keyboardImagePaste,
        richTheme: richTheme,
        textStyle: noteBodyStyle,
        onFieldFocused: _setFormatTarget,
        onFieldDisposed: _clearFormatTargetFor,
        // Madde satırlarındaki ek etiketleri de gövdedekiyle aynı çizilsin
        // ve dokunulunca açılsın (bkz. ItemsEditor.attachmentNames).
        attachmentNames: _bodyController.attachmentNames,
        onAttachmentTag: _openTagByName,
        // Paylaşım biçimi (☐/☑) — `- [ ]` değil (bkz. noteShareText).
        wholeNoteText: () => _note == null
            ? ''
            : noteShareText(_note!, pageLabel: context.l10n.pageLabel),
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
        key: _itemsEditorKey,
        items: note.items,
        showCheckboxes: note.type == NoteType.checklist,
        // İki sütun YALNIZ gerçek liste notunda (kullanıcı isteği
        // 2026-08-16). Metin notuna iliştirilmiş maddeler gövdenin altında
        // birkaç satır tutuyor; onları ikiye bölmek yalnız karıştırırdı.
        columns: note.listColumns,
        expandItems: ref.watch(expandListItemsProvider),
        onChanged: (items) => _mutate((n) => n.copyWith(items: items)),
        floats: _floats,
        pageBox: _pageBox,
        shrinkWrap: true,
        contentInsertion: _keyboardImagePaste,
        richTheme: richTheme,
        textStyle: noteBodyStyle,
        onFieldFocused: _setFormatTarget,
        onFieldDisposed: _clearFormatTargetFor,
        // Madde satırlarındaki ek etiketleri de gövdedekiyle aynı çizilsin
        // ve dokunulunca açılsın (bkz. ItemsEditor.attachmentNames).
        attachmentNames: _bodyController.attachmentNames,
        onAttachmentTag: _openTagByName,
        // Paylaşım biçimi (☐/☑) — `- [ ]` değil (bkz. noteShareText).
        wholeNoteText: () => _note == null
            ? ''
            : noteShareText(_note!, pageLabel: context.l10n.pageLabel),
        header: (note.body.trim().isNotEmpty || _listBodyOpen)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  keyedHeader,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _kGutter),
                    child: _wrapped(_bodyController, bodyField),
                  ),
                ],
              )
            : keyedHeader,
      );
    }

    _scheduleBodyTopMeasure();
    final hasBodyField =
        note.type == NoteType.text ||
        note.body.trim().isNotEmpty ||
        _listBodyOpen;
    // Gövde BOŞKEN "Not..." ipucu satırı görsellere kapalı bant sayılır.
    //
    // KLAVYE KARELERİNDE AĞACI YENİDEN KURMA (kullanıcı bulgusu 2026-08-10:
    // "klavye açılırken kasma sorunu var, geçmişte de vardı hâlâ tam
    // düzelmedi"): alt çubuk klavye yüksekliği kadar büyüyor, dolayısıyla
    // Scaffold gövdesinin KISITI animasyonun her karesinde değişiyor ve
    // `LayoutBuilder` her karede yeniden koşuyordu. Kurulan ağaç
    // (`SingleChildScrollView` + `NotePageCanvas` + her görselin kutusu)
    // karede bir baştan yaratılıyordu — oysa tuvalin tek ihtiyacı olan taban
    // yükseklik [_stableCanvasHeight] sayesinde ZATEN sabit.
    //
    // Çözüm: aynı taban için AYNI widget örneği döndürülür. Flutter
    // `updateChild`te birebir aynı örneği görünce alt ağacı hiç kurmaz, yani
    // klavye animasyonu boyunca yeniden kurulan tek şey `Padding` kalır.
    // Önbellek her editör build'inde sıfırlanır (bkz. build başındaki
    // `_canvasCache = null`) — yani not değişimi ya da yeni görsel bir kare
    // bile gecikmeden görünür.
    final body = note.type.isPageNoteType
        ? _pageNoteBody(note, keyedHeader, richTheme, noteBodyStyle)
        : LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = _stableCanvasHeight(constraints);
              final cached = _canvasCache;
              if (cached != null && _canvasCacheHeight == minHeight) {
                return cached;
              }
              final built = _buildCanvas(
                minHeight: minHeight,
                imageAttachments: imageAttachments,
                hintLineHeight: hintLineHeight,
                hintStyle: noteBodyStyle,
                useCanvasHint: useCanvasHint,
                hasBodyField: hasBodyField,
                pageContent: pageContent,
                l10n: l10n,
              );
              _canvasCache = built;
              _canvasCacheHeight = minHeight;
              return built;
            },
          );

    // ALT ÇUBUK — Scaffold'ın `bottomNavigationBar` YUVASINDA DEĞİL,
    // gövdenin dibinde bir `Column` çocuğu.
    //
    // KÖK NEDEN (kullanıcı 2026-08-16: "kasma sorunu tam çözülmemiş"):
    // yuvadayken çubuğun yüksekliği klavye kadar BÜYÜYORDU. Scaffold'ın
    // gövde alanı `bottom - max(viewInsets, altÇubukYüksekliği)` ile
    // hesaplandığı için çubuğun her karede değişen boyu Scaffold'ı ve
    // gövdeyi her karede yeniden YERLEŞTİRİYORDU. `Column`da ise esnek
    // OLMAYAN çocuk klavyeden bağımsız bir kısıtla ölçülür.
    //
    // ÇUBUK BURADA, `KeyboardSnap`in DIŞINDA kuruluyor (2026-08-22):
    // klavye boşluğu değişince `KeyboardSnap` gövde ağacını yeniden kurar;
    // çubuk o kapanışın içinde olsaydı — ek şeridi, biçim çubuğu,
    // BottomAppBar, AI ve mikrofon düğmeleriyle birlikte — her açılış ve
    // kapanışta baştan kurulurdu. Dışarıda kurulunca AYNI ÖRNEK olarak
    // geçirilir ve Flutter alt ağacı hiç ellemez.
    //
    // Balona yazılırken çubuk TÜMÜYLE gizlenir: klavye + belge bölmesi + iki
    // çubuk aynı ekrana sığmıyor ve balon kartı altta kalıyordu (kullanıcı
    // isteği 2026-08-08). Kip bitince geri gelir.
    //
    // RepaintBoundary: çubuk klavye animasyonu boyunca yer değiştiriyor;
    // ayrı katmanda olmazsa her karede GÖVDEYİ de yeniden boyatır.
    final Widget? bottomBar = _immersiveBubble
        ? null
        : RepaintBoundary(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sayfada yüzmeyen ekler (PDF/sunum/ses + "ek olarak"
                // işaretli görsel/video) SAYFANIN DİBİNDE, kapanabilir bir
                // şeritte. Görseller ve videolar her not tipinde TAM SAYFA
                // serbest katmanda kalır (NotePageCanvas — yukarıda).
                // Klavye açıkken şerit gizlenir: zaten görünmüyordu (klavyenin
                // altındaydı), yukarı kaldırılsaydı yazma alanını yerdi.
                // KÖK NEDEN: burada `if (keyboard == 0)` vardı.
                // `AttachmentStrip` klavye kontrolünü ZATEN kendi içinde
                // yapıyor (SizedBox.shrink döndürüyor); dıştaki koşul
                // widget'ı ağaçtan tümüyle düşürüyor, bütün State'ler
                // (ses oynatıcısı dahil) dispose ediliyor ve klavye
                // kapanınca sıfırdan kuruluyordu — şeridin kaydırma
                // konumu sıfırlanıyor, ÇALAN SES sessizce duruyordu.
                AttachmentStrip(
                  attachments: [
                    for (final a in note.attachments)
                      if (!a.floatsOnPage) a,
                  ],
                  onRemove: _removeAttachment,
                  onChanged: _updateAttachment,
                  onCopy: _copyAttachment,
                  // Belge (PDF/sunum) notunda gövde metni yok; etiket
                  // yazacak bir yer olmadığı için düğme çizilmez.
                  // Ek şeridindeki düğme artık BAĞLAMA KİPİNİ başlatır
                  // ("önce eki seç, sonra yazıyı"): dosya adını imlece
                  // yazmak yerine kullanıcı bağlanacak yazıyı seçer.
                  onInsertTag: note.type.isPageNoteType
                      ? null
                      : _startPendingEmbed,
                  // **"Sayfaya koy" BELGE NOTUNDA YOK** (kullanıcı bulgusu:
                  // "video ekinde bağla butonuna basınca video kayboluyor").
                  // KÖK NEDEN: düğme eki "şeritte değil, sayfada" diye
                  // işaretliyor; sayfa akışı ise yalnız METİN notunun
                  // tuvalinde var. PDF/sunum notunda üstteki bölme belgeyi
                  // çiziyor, yüzen ek için bir yer yok — ek şeritten
                  // kalkıyor, hiçbir yerde çizilmiyor, yani KAYBOLUYORDU
                  // (veri duruyordu ama kullanıcı için yok olmuş demekti).
                  onPlaceOnPage: note.type.isPageNoteType
                      ? null
                      : (a) => _setImageAsFile(a, false),
                  onVideoToNote: _videoToNote,
                  expanded: ref.watch(attachmentsExpandedProvider),
                  onToggle: () => ref
                      .read(attachmentsExpandedProvider.notifier)
                      .toggle(),
                ),
                // BAĞLAMA KİPİ şeridi: hangi dosyanın bağlanmayı
                // beklediğini söyler ve seçilen yazıya bağlar.
                // Kip görünmez olsaydı kullanıcı ne beklendiğini
                // bilemezdi (ek seçildi ama ekranda hiçbir şey
                // değişmiyor).
                if (_pendingEmbed != null)
                  _PendingEmbedBanner(
                    fileName: _pendingEmbed!.fileName,
                    // Parmak şeride DEĞDİĞİ an seçim yedeklenir: sonraki
                    // karede odak düşse bile bağlanacak yazı elde kalır.
                    onPointerDown: _rememberTargetSelection,
                    onLink: _finishPendingEmbed,
                    onCancel: () => setState(() => _pendingEmbed = null),
                  ),
                // Dikte açıkken kaçırılamayacak bir şerit: tek başına kırmızı
                // ikon yeterince belirgin değildi, mikrofon farkına varılmadan
                // açık kalabiliyordu.
                if (_aiTask != null) _AiBanner(label: _aiTask!),
                // CANLI DİKTE şeridi: mikrofon açıkken kaçırılamayacak bir
                // gösterge (aynı gerekçe — açık kalmış mikrofon fark
                // edilmiyordu). Dokunmak dikteyi bitirir.
                if (_dictating)
                  _AiBanner(
                    label: l10n.dictationListening,
                    icon: Icons.mic,
                    onTap: () => unawaited(_stopDictation()),
                  ),
                // Dosya işleri (kopyalama/yapıştırma) için aynı şerit,
                // ayrı simge: sessiz bekleme bitti (bkz. [_busyTask]).
                if (_busyTask != null)
                  _AiBanner(label: _busyTask!, icon: Icons.sync),
                // Yatay ekranda klavye + çubuk ekranı aşabilir; çubuk taşmak
                // yerine kendi içinde kaydırılır (Flexible + kaydırma).
                //
                // ZIPLAMA (kullanıcı bulgusu 2026-08-21): panel eskiden
                // `if (_formatBarOpen) Flexible(...)` ile Column'a ANINDA
                // (0 ms) eklenip çıkarılıyordu — klavyenin kendi hareketiyle
                // aynı karede çakışınca "zıplama" hissi veriyordu. Panel artık
                // her zaman ağaçta, `AnimatedSize` yüksekliğini yumuşak
                // kapatıyor/açıyor; kapalıyken `SizedBox.shrink()` yer
                // kaplamıyor.
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    alignment: Alignment.bottomCenter,
                    child: !_formatBarOpen || _findOpen
                        ? const SizedBox.shrink()
                        : SingleChildScrollView(
                            child: FormatBar(
                              target: _formatTarget,
                              onFormat: _applyFormat,
                              onClearFormat: _clearFormat,
                              onRemoveFormat: _removeFormat,
                              fontFamily: _titleIsTarget
                                  ? note.titleFontFamily
                                  : note.fontFamily,
                              fontScale: _titleIsTarget
                                  ? note.titleFontScale
                                  : note.fontScale,
                              textOpacity: _titleIsTarget
                                  ? note.titleTextOpacity
                                  : note.textOpacity,
                              hasSelection: _hasSelection,
                              onOpacityChanged: (value) => _mutate(
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleTextOpacity: value)
                                    : n.copyWith(textOpacity: value),
                              ),
                              onOpacityEnd: (value) => _applyStepOrNote(
                                RichFormat.opacity,
                                kRichOpacitySteps,
                                kRichOpacityDefault,
                                value,
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleTextOpacity: value)
                                    : n.copyWith(textOpacity: value),
                              ),
                              onFontChanged: (family) => _mutate(
                                (n) => _titleIsTarget
                                    ? (family == null
                                          ? n.copyWith(
                                              clearTitleFontFamily: true,
                                            )
                                          : n.copyWith(titleFontFamily: family))
                                    : (family == null
                                          ? n.copyWith(clearFontFamily: true)
                                          : n.copyWith(fontFamily: family)),
                                immediate: true,
                              ),
                              // Sürüklerken yalnız yerel durum + gecikmeli kayıt: her kare
                              // Firestore'a yazmak boşuna trafik olurdu.
                              onScaleChanged: (value) => _mutate(
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleFontScale: value)
                                    : n.copyWith(fontScale: value),
                              ),
                              onScaleEnd: (value) => _applyStepOrNote(
                                RichFormat.size,
                                kRichSizeSteps,
                                kRichSizeDefault,
                                value,
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleFontScale: value)
                                    : n.copyWith(fontScale: value),
                              ),
                              // Sayfa rengi/çerçeve/zemin görseli: "Ekle"
                              // levhasından buraya taşındı (bkz. FormatBar).
                              onPageStyle: _showColorSheet,
                              // Başlık yalnız GÖVDEDE ve maddelerde: notun
                              // başlık alanı zaten başlık.
                              onHeading: _titleIsTarget
                                  ? null
                                  : (h) => _runOnTarget(
                                      (c) => applyRichHeading(c, h),
                                    ),
                              onClose: () =>
                                  setState(() => _formatBarOpen = false),
                            ),
                          ),
                  ),
                ),
                // Alt bar: eskiden yedi ETİKETSİZ ikon yan yanaydı (palet, ataş,
                // hesap, biçim, liste, mikrofon, AI) ve hangisinin ne yaptığı
                // ancak basınca anlaşılıyordu. Şimdi üç etiketli segment tek
                // kapsülde; hesap makinesi üst bara, ek/renk seçenekleri
                // "Ekle" açılırına taşındı.
                if (_findOpen)
                  NoteFindBar(
                    controller: _findController,
                    focusNode: _findFocus,
                    count: _findHits.length,
                    index: _findIndex,
                    background: background,
                    onChanged: (_) => _runFind(),
                    onNext: () => _stepFind(1),
                    onPrevious: () => _stepFind(-1),
                    onList: () => unawaited(_openFindList()),
                    onClose: _closeFind,
                  )
                else
                BottomAppBar(
                  color: background,
                  height: 64,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final showSelect =
                          !note.type.isPageNoteType &&
                          note.items.isNotEmpty;
                      final showAttachments = fileAttachments.isNotEmpty;
                      // Genişliğe göre plan: taşma/kesik kapsül yerine önce
                      // düğmeler küçülür, sonra ⋮ menüsünde de bulunan
                      // Ara/Paylaş kapsülden çıkar (bkz. planEditorBar).
                      final plan = planEditorBar(
                        width: constraints.maxWidth,
                        fixedSegments: showSelect ? 3 : 2,
                        attachments: showAttachments,
                        pen: isDocumentNote,
                      );
                      return Row(
                        children: [
                          // Kapsül YATAY KAYAR ve `Expanded` içinde: segment
                          // sayısı nota göre değişiyor (Biçim + Ekle + Ekler +
                          // Seç). Segmentler Keep gibi yalnız SİMGE olduğundan
                          // dördü de en dar telefona sığar; kaydırma yalnız çok
                          // büyük sistem yazı ölçeğinde devreye giren son çare.
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _toolSegment(
                                      icon: Icons.text_format,
                                      label: l10n.formatTitle,
                                      active: _formatBarOpen,
                                      onTap: () => setState(
                                        () => _formatBarOpen =
                                            !_formatBarOpen,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    // "Metin ekle" / "Liste maddesi ekle" buradan
                                    // Ekle levhasının en üst bölümüne taşındı: çubuk
                                    // üç segmentle kalabalıktı ve ekleme işi iki ayrı
                                    // yere bölünmüştü (bkz. attach_sheet.dart).
                                    _addToolButton(l10n),
                                    // "SEÇ" BURADA (kullanıcı isteği 2026-08-09:
                                    // "seç burada olsun, yeni öğe eski yerinde"):
                                    // toplu kopyalama/silme girişi bir tur ekranın
                                    // dibinde yüzen bir düğmeydi ve alt paneli
                                    // örtüyordu. Alt çubuğun segmenti olunca hem
                                    // sayfanın neresinde olursak olalım görünür
                                    // kalıyor hem hiçbir şeyi kapatmıyor.
                                    // Madde yoksa gizli: seçilecek bir şey yok.
                                    //
                                    // SİMGE DEĞİŞTİ (kullanıcı bulgusu
                                    // 2026-09-01: "alt alandaki seç işareti
                                    // karışıyor, farklı bir simge
                                    // kullanalım"): `checklist` simgesi tam
                                    // yanındaki "Ekle" segmentinin açtığı
                                    // "liste maddesi ekle" işiyle aynı
                                    // resmi çiziyordu — ikisi de üç madde
                                    // ve bir tik. `select_all` kesikli
                                    // çerçevesiyle "toplu iş" anlamını
                                    // taşır ve başka hiçbir düğmeye
                                    // benzemez.
                                    if (showSelect) ...[
                                      const SizedBox(width: 3),
                                      _toolSegment(
                                        icon: Icons.select_all,
                                        label: l10n.select,
                                        onTap: () => _itemsEditorKey
                                            .currentState
                                            ?.startSelection(),
                                      ),
                                    ],
                                    // NOTTA ARA ve PAYLAŞ artık ⋮ menüsünün
                                    // içinde saklı değil, alt çubukta
                                    // (kullanıcı isteği 2026-09-01: "notta
                                    // ara seçeneğini alt alana büyüteç
                                    // işareti ile koyalım", "paylaş
                                    // seçeneğini de alt alana koyalım").
                                    // Menüdeki maddeleri KALDIRMADIK: aynı
                                    // eylem iki yerden çalışır, alışkanlık
                                    // bozulmaz.
                                    if (plan.search) ...[
                                      const SizedBox(width: 3),
                                      _toolSegment(
                                        icon: Icons.search,
                                        label: l10n.noteSearchTitle,
                                        onTap: _openNoteSearch,
                                      ),
                                    ],
                                    if (plan.share) ...[
                                      const SizedBox(width: 3),
                                      _toolSegment(
                                        icon: Icons.share_outlined,
                                        label: l10n.share,
                                        onTap: () => unawaited(_share()),
                                      ),
                                    ],
                                    // EKLER düğmesi: şeridin kendi başlık satırı
                                    // kalktı, aç/kapa buraya taşındı (kullanıcı
                                    // isteği 2026-08-08 — "ekler yazısı ve göster
                                    // gizlesi alt alana gelsin, bir satır alan
                                    // kurtarmış oluruz").
                                    if (showAttachments) ...[
                                      const SizedBox(width: 3),
                                      _attachmentsToggle(
                                        l10n,
                                        fileAttachments.length,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // PDF/sunum notunda KALEM alt çubukta: tam ekrana
                          // geçmeden sayfanın üzerine yazılabilsin (kullanıcı
                          // isteği 2026-08-08 — ekran görüntüsünde işaretlenen
                          // boşluk).
                          if (isDocumentNote) ...[
                            _penToolButton(l10n),
                            const SizedBox(width: 8),
                          ],
                          // YALNIZ SİMGE (kullanıcı bulgusu 2026-09-02: "alt
                          // kısım sığmıyor, AI yazan butondaki AI yazısını
                          // kaldır sadece simgesi kalsın"). Etiket önce
                          // "Yapay Zeka"dan "AI"ya kısaltılmıştı, o da
                          // yetmedi: düğme artık mikrofonlarla aynı kare
                          // ölçüde ve çubuk üçünü de sığdırıyor. Adı
                          // ipucunda duruyor.
                          _voiceButton(
                            size: plan.button,
                            tooltip: l10n.aiTitle,
                            icon: Icons.auto_awesome,
                            onTap: () => showAiSheet(
                              context,
                              note,
                              onAppendText: _appendText,
                              onReplaceText: _replaceText,
                              onCreateNote: _createNoteFromText,
                            ),
                          ),
                          SizedBox(width: plan.gap),
                          // İKİ MİKROFON (kullanıcı isteği 2026-09-01):
                          // soldaki YAPAY ZEKÂ yolu (levhada gözden geçir,
                          // özetle/böl), sağdaki DÜZ SESLE YAZMA (konuşulan
                          // söz imlecin olduğu yere anında düşer). Simgeler
                          // bilerek farklı: parıltılı mikrofon "burada AI
                          // var" der, sade mikrofon klavyenin dikte tuşunu
                          // anımsatır. Bkz. [_toggleDictation].
                          _voiceButton(
                            size: plan.button,
                            tooltip: l10n.voiceCaptureAi,
                            icon: Icons.mic_none,
                            badge: Icons.auto_awesome,
                            onTap: _captureVoice,
                          ),
                          SizedBox(width: plan.gap),
                          _voiceButton(
                            size: plan.button,
                            tooltip: l10n.liveDictation,
                            icon: _dictating ? Icons.stop : Icons.mic,
                            active: _dictating,
                            onTap: () => unawaited(_toggleDictation()),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );

    return Actions(
      actions: {
        // Klavyeden Kopyala/Kes (Ctrl+C / Ctrl+X): EditableText bu eylemleri
        // `Action.overridable` ile kaydettiğinden buradaki üst-ağaç eylemi
        // onları devralır ve panoya TEMİZ metin yazar (biçim işaretsiz,
        // çapasız). Uymayan durumlar varsayılana devredilir (callingAction).
        CopySelectionTextIntent: _CleanCopySelectionAction(this),
      },
      child: CallbackShortcuts(
        bindings: {
          if (_isDesktop)
            const SingleActivator(
              LogicalKeyboardKey.keyV,
              control: true,
              shift: true,
            ): _pasteImage,
          // Ctrl+Z: metin alanı odaktayken Flutter'ın kendi metin geri alması
          // önce davranır (yazılan harfleri geri alır); alan odakta değilken
          // buraya düşer ve NOTUN son değişikliği geri alınır.
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: true,
            shift: true,
          ): _redo,
        },
        // Geri tuşu önce CANLI ARAMAYI kapatır, notu değil.
        child: PopScope(
          canPop: !_findOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _findOpen) _closeFind();
          },
          child: Scaffold(
          backgroundColor: background,
          // **KASMA — klavye boşluğu artık KARARLI** (bkz. [KeyboardSnap]).
          // Scaffold gövdeyi klavye animasyonunun HER karesinde kısaltıyordu;
          // görselli/uzun notlarda ve PDF bölmesinde yalnızca bu yeniden
          // ölçüm bile takılma yaratıyor. Boşluk aşağıda, gövdenin
          // dolgusundan veriliyor ve bir açılış/kapanışta EN ÇOK BİR KEZ
          // değişiyor; çubuğun klavyeyle birlikte akan hareketi ise
          // [KeyboardSlide] ile yalnız boyama katmanında yapılıyor.
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: background,
            // Başlık yerinde düzenleme tarihi: notun kendi başlığı zaten gövdenin
            // en üstünde duruyor, üst barda ikinci kez göstermek yer harcıyordu.
            // Sabitlenmiş/yıldızlı göstergesi tarihin yanında — düğmeler ⋯
            // menüsüne taşındığı için durum bir yerde görünmeliydi.
            titleSpacing: 0,
            title: note.updatedAt == null
                ? null
                : Row(
                    children: [
                      Flexible(
                        child: Text(
                          DateFormat('d MMM y HH:mm').format(note.updatedAt!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (note.starred) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber.shade600,
                        ),
                      ],
                    ],
                  ),
            actions: [
              // KÖK NEDEN (kasma): bu akış `build`'in en başında izleniyordu.
              // `pendingWrites` her kayıtta false→true→false gidiyor, yani
              // yazarken (debounce 0,5 sn / en geç 3 sn) düzenli aralıklarla
              // 4000 satırlık editör build'i BAŞTAN koşuyordu — üstelik
              // tetikleyici Riverpod olduğu için `_mutate`'in "saf yazım"
              // kısayolu ve akış yankısı koruması ikisi de devreye giremiyordu.
              // Abonelik artık yalnız BU İKONA ait.
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Consumer(
                  builder: (context, ref, _) {
                    final owner = widget.ownerId;
                    final pending =
                        ref
                            .watch(
                              owner == null
                                  ? pendingWritesProvider(widget.noteId)
                                  : ownedPendingWritesProvider((
                                      ownerId: owner,
                                      noteId: widget.noteId,
                                    )),
                            )
                            .value ??
                        false;
                    // Yalnız bu cihazdaki not: bulut simgesi yerine telefon.
                    if (owner == null &&
                        (ref
                                .read(notesRepositoryProvider)
                                ?.isLocal(widget.noteId) ??
                            false)) {
                      return Tooltip(
                        message: l10n.localOnlyBadge,
                        child: Icon(
                          Icons.cloud_off_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      );
                    }
                    return Tooltip(
                      message: pending ? l10n.syncPending : l10n.synced,
                      child: Icon(
                        pending
                            ? Icons.cloud_upload_outlined
                            : Icons.cloud_done_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: pending ? 0.9 : 0.5),
                      ),
                    );
                  },
                ),
              ),
              // Geri al: son değişikliği (yazma dizisi, madde işaretleme, görsel
              // taşıma, AI ile değiştirme...) tek dokunuşta iptal eder. Yığın
              // boşken pasif durur — düğmenin yerini korur ki araç çubuğu
              // oynamasın.
              // SABİTLEME üst barda, AÇIK düğme olarak (kullanıcı isteği:
              // "sabitleme butonunu açığa koy görülsün"). ⋯ menüsündeyken hem
              // bulunması hem durumunun okunması iki dokunuş istiyordu;
              // başlıktaki küçük raptiye göstergesi yalnız DURUMU söylüyor,
              // dokunulabilir değil.
              // **ORTAK ÇALIŞAN** (kullanıcı isteği 2026-09-22: "ortak not
              // butonu keepteki gibi"). Keep'teki yeri: notun kendi
              // araçlarının yanında, tek dokunuşla. Paylaşılmışsa simge
              // doluya döner ve kişi sayısını rozetle gösterir — notun
              // başkalarına açık olduğu, menüye girmeden görünsün.
              // Abonelik yalnız bu düğmede (bkz. yukarıdaki kasma notu).
              Consumer(
                builder: (context, ref, _) {
                  final owner = widget.ownerId;
                  final count = owner == null
                      ? ref.watch(
                          myNoteSharesProvider.select(
                            (m) =>
                                m.value?[widget.noteId]?.sharedWith.length ?? 0,
                          ),
                        )
                      : 1;
                  // Yalnız bu cihazdaki not kimseyle paylaşılamaz.
                  if (owner == null &&
                      (ref
                              .read(notesRepositoryProvider)
                              ?.isLocal(widget.noteId) ??
                          false)) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    tooltip: count > 0
                        ? l10n.collaboratorsCount(count)
                        : l10n.collaborators,
                    icon: Badge(
                      isLabelVisible: owner == null && count > 0,
                      label: Text('$count'),
                      child: Icon(
                        count > 0
                            ? Icons.people_alt
                            : Icons.person_add_alt_1_outlined,
                      ),
                    ),
                    onPressed: () => showCollaboratorsSheet(
                      context,
                      ref,
                      noteId: widget.noteId,
                      ownerId: owner,
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: note.pinned ? l10n.unpin : l10n.pin,
                isSelected: note.pinned,
                icon: Icon(
                  note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                onPressed: () => _mutate(
                  (n) => n.copyWith(pinned: !n.pinned),
                  immediate: true,
                ),
              ),
              IconButton(
                tooltip: l10n.undo,
                icon: const Icon(Icons.undo),
                onPressed: _canUndo ? _undo : null,
              ),
              // Yinele yalnız kullanılabilirken görünür: yanlış "Geri al"dan
              // dönüş yolu. Sürekli görünse araç çubuğunda ölü yer kaplardı.
              if (_canRedo)
                IconButton(
                  tooltip: l10n.redo,
                  icon: const Icon(Icons.redo),
                  onPressed: _redo,
                ),
              // Hesap makinesi alt bardan buraya taşındı: alt bar üç etiketli
              // araca indi, hesap makinesi ise metin biçimiyle ilgisi olmayan
              // ayrı bir araç.
              IconButton(
                tooltip: l10n.calculatorTitle,
                icon: const Icon(Icons.calculate_outlined),
                onPressed: _openCalculator,
              ),
              // Yıldız ve sabitleme düğmeleri ⋯ menüsüne taşındı; durumları üst
              // barın başlık alanındaki göstergelerden okunuyor.
              // ⋮ artık açılır menü değil, iki sütunlu levha açar
              // (bkz. note_menu_sheet.dart — kullanıcı isteği 2026-08-09).
              IconButton(
                tooltip: l10n.noteMetaMenu,
                icon: const Icon(Icons.more_vert),
                onPressed: _openNoteMenu,
              ),
            ],
          ),
          // Renkli çerçeve: seçiliyse editör içeriğini saran ince renkli kenarlık.
          //
          // ALT ÇUBUK GÖVDENİN İÇİNDE (bkz. aşağıdaki `_bottomBar` yorumu):
          // `bottomNavigationBar` yuvasındayken yüksekliği klavyeyle
          // büyüyordu ve bu, Scaffold'ı her animasyon karesinde yeniden
          // yerleştiriyordu.
          //
          // `SafeArea(bottom: false)`: alt güvenli alanı BİLEREK uygulanmaz.
          // Çubuk `bottomNavigationBar` yuvasındayken Scaffold gövdeden alt
          // dolguyu zaten kaldırıyordu (çubuk aşağıda duruyordu); yuva
          // boşalınca dolgu geri gelir ve sayfa alanı sebepsiz kısalırdı.
          // Görünüm birebir korunur.
          body: KeyboardSnap(
            // Klavye durup gövde oturduktan sonra odaklı alanı görünür kıl —
            // gövde animasyon boyunca bilerek kısaltılmadığı için Flutter'ın
            // kendi imleç kaydırması bu işi yapamaz (bkz. [KeyboardSnap]).
            onSettled: (inset) {
              _keyboardInset = inset;
              if (inset <= 0) return;
              _keyboardMemory = inset;
              // Tahmin tuttuysa bu geçiş hiçbir şey yapmaz (imleç zaten
              // görünür); tutmadıysa farkı burada kapatır.
              _revealCaret();
            },
            builder: (context, keyboardInset) => Padding(
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Column(
                children: [
                  Expanded(
                    child: SafeArea(
                      bottom: false,
                      child: _withBackground(
                        note,
                        bgImage,
                        note.frameColor == NoteColor.none
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
                    ),
                  ),
                  // KLAVYE: Scaffold yalnız GÖVDEYİ klavyeye göre kısaltır, alt
                  // çubuğu ekranın dibinde bırakır — yani klavye açıkken alt
                  // çubuğun tamamı (biçim çubuğu dahil) klavyenin ALTINDA
                  // kalıyordu ve kullanılamıyordu ("düzenleme alanı güzel ama
                  // altta olduğu için klavyenin altında kalıyor"). Çubuk klavye
                  // kadar yukarı kaldırılır; böylece "Aa" düğmesi de yazarken
                  // erişilebilir olur — biçim çubuğunu açmak için klavyeyi
                  // kapatmak, kapatınca da seçimi kaybetmek gerekmez.
                  //
                  // ZIPLAMA + KASMA — HAREKET İLE YERLEŞİM AYRILDI (kullanıcı
                  // bulgusu 2026-08-22: "klavye açılıp kapanırken bu alan
                  // kayıyor"). Çubuk klavyeyle birlikte KARE KARE kayar ama
                  // yalnız BOYAMA katmanında ([KeyboardSlide] → `Transform`);
                  // gövdenin yerleşimi ise animasyon boyunca hiç değişmez,
                  // klavye durunca TEK SEFERDE oturur (bkz. [KeyboardSnap]).
                  // Eskiden ikisi de aynı kademeli değerden besleniyordu:
                  // yerleşim azalmıştı ama çubuk 96 dp'lik sıçramalarla
                  // yukarı çıkıyordu — kullanıcının gördüğü zıplama buydu.
                  if (bottomBar != null)
                    KeyboardSlide(inset: keyboardInset, child: bottomBar),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Klavyeden Kopyala/Kes'in temiz-metin sürümü.
///
/// EditableText, [CopySelectionTextIntent] eylemini `Action.overridable`
/// olarak kaydeder: odaklı alanın üst ağacında aynı Intent için bir eylem
/// varsa ONUN çalışmasına izin verir. Buradaki eylem, biçim çubuğunun zaten
/// izlediği son odaklı alanı ([FormatTarget]) kullanır; hedef odaklı değilse
/// ya da seçim yoksa varsayılan davranışa ([Action.callingAction]) devreder.
class _CleanCopySelectionAction extends Action<CopySelectionTextIntent> {
  _CleanCopySelectionAction(this.owner);

  final _NoteEditorScreenState owner;

  @override
  Object? invoke(CopySelectionTextIntent intent) {
    final target = owner._formatTarget;
    if (target == null || !target.focusNode.hasFocus) {
      return callingAction?.invoke(intent);
    }
    final controller = target.controller;
    final value = controller.value;
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return callingAction?.invoke(intent);
    }
    final text = clipboardTextOf(value);
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
    }
    if (intent.collapseSelection) {
      // Kes: seçilen ham aralık alandan silinir ve kayıt olağan yoldan akar.
      controller.value = TextEditingValue(
        text: value.text.replaceRange(selection.start, selection.end, ''),
        selection: TextSelection.collapsed(offset: selection.start),
      );
      target.commit();
    }
    return null;
  }
}

/// Dikte sürerken alt çubuğun üstünde duran uyarı şeridi. Amacı tek:
/// mikrofonun açık olduğu gözden kaçmasın.
/// Süren AI işini gösteren şerit: iş bitene kadar ekranda durur. Tek bir
/// SnackBar yeterli değildi — kayboluyor, kullanıcı "çalışıyor mu, dondu mu"
/// bilemiyordu.
/// BAĞLAMA KİPİ şeridi: seçilmiş ek + "bağlanacak yazıyı seç" yönergesi.
///
/// Kullanıcı isteği 2026-08-16 ("önce eki seçip sonra metni seçme de
/// olmalı"). Şerit alt çubuğun içinde durur; düğmeye basmak metin alanının
/// odağını düşürse bile seçim denetleyicide korunuyor (bkz.
/// `_finishPendingEmbed`).
class _PendingEmbedBanner extends StatelessWidget {
  const _PendingEmbedBanner({
    required this.fileName,
    required this.onPointerDown,
    required this.onLink,
    required this.onCancel,
  });

  final String fileName;

  /// Şeride PARMAK DEĞER DEĞMEZ (dokunuşun işlenmesinden, dolayısıyla olası
  /// odak/seçim kaybından ÖNCE) çağrılır — bkz. `_lastSelection`.
  final VoidCallback onPointerDown;
  final VoidCallback onLink;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // TextFieldTapRegion + ExcludeFocus: şeride dokunmak gövdenin odağını
    // DÜŞÜRMEZ, dolayısıyla seçim imlece çökmez (bkz. `_lastSelection`
    // kök nedeni). Aynı kural notta metin yazılırken açılan her yardımcı
    // arayüz için geçerli — bkz. balon kartındaki eylemler.
    return TextFieldTapRegion(
      child: ExcludeFocus(
        child: Listener(
          // `Listener` jest arenasına GİRMEZ: düğmelerin kendi dokunuşlarını
          // hiç etkilemez, yalnız haber verir.
          onPointerDown: (_) => onPointerDown(),
          child: Material(
          color: scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(
          children: [
            Icon(Icons.link, size: 18, color: scheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.attachmentTagPendingBanner(fileName),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: onLink,
              child: Text(l10n.attachmentTagLinkHere),
            ),
            IconButton(
              tooltip: l10n.cancel,
              icon: const Icon(Icons.close, size: 18),
              color: scheme.onTertiaryContainer,
              onPressed: onCancel,
            ),
          ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _AiBanner extends StatelessWidget {
  const _AiBanner({
    required this.label,
    this.icon = Icons.auto_awesome,
    this.onTap,
  });

  final String label;

  /// Şeridin simgesi: AI işlerinde yıldız, dosya işlerinde eşitleme oku,
  /// canlı diktede mikrofon.
  final IconData icon;

  /// Dolu ise şerit TIKLANABİLİR (dikteyi bitirmek gibi). AI/dosya işlerinde
  /// null: onların şeridi yalnız bilgi verir, iptal edilemez.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: InkWell(
        onTap: onTap,
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
                Icon(icon, size: 18, color: scheme.onSecondaryContainer),
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
      ),
    );
  }
}


/// Canlı aramanın tek eşleşmesi: hangi alanda, tamponun neresinde.
class _FindHit {
  const _FindHit({
    required this.controller,
    required this.focus,
    required this.where,
    required this.icon,
    required this.match,
    required this.index,
  });

  final WrapTextController controller;
  final FocusNode focus;
  final String where;
  final IconData icon;
  final TextSearchMatch match;

  /// Parça (snippet) üretmek için alanın arama dizini.
  final TextSearchIndex index;
}
