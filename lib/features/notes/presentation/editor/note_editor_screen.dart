import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
// `AppExitResponse` (didRequestAppExit'in dönüş tipi) dart:ui'de yaşıyor;
// material/services onu yeniden dışa AKTARMIYOR. `show` ile alınır ki
// dart:ui'nin Color/TextStyle gibi tipleri material'ınkilerle çakışmasın.

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
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/app_update.dart';
import '../../../../app/router.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../../app/theme/note_colors.dart';
import '../../../../core/constants.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/doc_picker.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../core/utils/voice_commands.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/utils/attachment_tag.dart';
import '../../../../core/utils/link_text.dart';
import '../../../../core/utils/markdown.dart';
import '../../../../core/utils/note_fonts.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/note_guard.dart';
import '../../../../core/utils/sentence_select.dart';
import '../../../../core/utils/video_time.dart';
import '../../../../core/utils/youtube.dart';
import '../../../../core/widgets/customizable.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../data/attachment_save.dart';
import '../../../inbox/presentation/send_note_sheet.dart';
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
import '../../data/voice_listen_session.dart';
import '../../data/document_scan.dart';
import '../../data/note_speech.dart';
import '../../data/note_share.dart';
import '../../data/note_shares_repository.dart';
import '../../data/shared_note_activity.dart';
import '../../data/upload_queue.dart';
import '../../data/note_pdf.dart';
import '../../data/notes_repository.dart';
import '../../data/pdf_edit.dart';
import '../../data/scan/scan_ocr.dart';
import '../../data/scan/scan_pdf.dart';
import '../../data/scan/scan_title.dart';
import '../../data/user_templates.dart';
import '../../data/video_frame.dart';
import '../../data/web_video.dart';
import '../../domain/text_merge.dart';
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
import '../listening_visuals.dart';
import '../voice_capture_sheet.dart';
import 'ai_result_sheet.dart';
import 'attach_sheet.dart';
import 'attachment_clipboard.dart';
import 'attachment_strip.dart';
import 'audio_recorder_sheet.dart';
import 'calculator_sheet.dart';
import '../../data/place_reminders.dart';
import '../../data/drive_store.dart' show localFilesRevisionProvider;
import '../drive_ui.dart';
import '../place_reminder_sheet.dart';
import 'drawing_screen.dart';
import 'editor_bar_layout.dart';
import 'format_bar.dart';
import 'format_menu.dart';
import 'image_layout.dart';
import 'items_editor.dart';
import 'note_images.dart';
import 'pinned_media_pane.dart';
import 'embed_sheet.dart';
import '../../domain/note_pages.dart';
import '../../data/notebook_copy.dart';
import '../../domain/notebook_migration.dart';
import 'notebook_paper.dart';
import '../file_use_sheet.dart';
import 'note_history_sheet.dart';
import 'note_presence.dart';
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
import '../viewers/transcript_screen.dart';
import '../../domain/transcript.dart';
import 'tag_chips.dart';
import 'tag_tap.dart';
import 'text_wrap.dart';
import 'video_hub_scope.dart';
import 'audio_card_box.dart' show kAudioBoxWidth, kAudioBoxHeight;
import 'text_page_box.dart' show kTextBoxWidth, kTextBoxHeight;
import 'view_mode_switch.dart';
import '../../../../core/widgets/smooth_routes.dart';
import '../../../../core/widgets/app_sheet.dart';

part 'note_editor_parts.dart';

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
      // Sayfa geçişi/ekleme çubuğu ve tuvali değiştirir (Note.textPages).
      a.activePage != b.activePage ||
      a.textPages.length != b.textPages.length ||
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
      // Defter görünümü ve kâğıt deseni (bkz. `_sameVisual` kök neden notu).
      a.paged != b.paged ||
      a.archivePaper != b.archivePaper ||
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
        // Üste sabitleme/bölme yüksekliği ve YouTube bağlantısı da çizimi
        // değiştirir — sayılmasaydı sabitlenen görsel ekranda yerinde kalırdı.
        x.pinHeight != y.pinHeight ||
        x.webUrl != y.webUrl ||
        x.section != y.section ||
        // Sabit/sayfadaki belge kutusu balonları da çizer (bkz. PdfPageBox).
        x.bubblesHidden != y.bubblesHidden ||
        !_sameBubbles(x.bubbles, y.bubbles) ||
        !identical(x.ink, y.ink)) {
      return false;
    }
  }
  return true;
}

/// Balonların GÖRÜNEN hâli aynı mı (her anlık görüntü yeni liste kurduğu
/// için kimlik değil içerik karşılaştırılır).
bool _sameBubbles(List<PageBubble> a, List<PageBubble> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.id != y.id ||
        x.page != y.page ||
        x.x != y.x ||
        x.y != y.y ||
        x.title != y.title ||
        x.text != y.text ||
        x.color != y.color ||
        x.size != y.size ||
        x.collapsed != y.collapsed ||
        x.starred != y.starred ||
        x.urgent != y.urgent ||
        x.plain != y.plain ||
        x.rects.length != y.rects.length) {
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
    this.startGalleryVideo = false,
    this.startYouTube = false,
    this.startTranscribe = false,
    this.startAudioFile = false,
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

  /// (+) menüsündeki "Galeriden video": açılışta galeri açılır, seçilen
  /// video notun ÜSTÜNE sabitlenir (üstte video, altta not).
  final bool startGalleryVideo;

  /// (+) menüsündeki "YouTube videosu": açılışta bağlantı sorulur, video
  /// notun ÜSTÜNE sabitlenir ve izlerken altına not yazılır.
  final bool startYouTube;

  /// (+) menüsündeki "Dosyayı metne dök": açılışta ses/video/görsel seçilir,
  /// nota eklenir ve metne dökülür; metin notun gövdesine yazılır.
  final bool startTranscribe;

  /// (+) → Dosya → ses → "Ses eki olarak ekle": açılışta ses dosyası
  /// seçilir (önceden seçildiyse sormadan) ve nota çalınabilir ek olarak
  /// girer.
  final bool startAudioFile;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// Salt okunur: yalnız okuma yetkili paylaşım (`?ro=1`) YA DA bu sürüm
  /// eski kalmış (F1.5 — `config/app.minClient`): eski istemci notu
  /// kaydedip yeni sürümün verisini bozmasın.
  bool get _readOnly => widget.readOnly || ref.read(updateRequiredProvider);

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
  /// Denetleyicilerin en son beslendiği not ve tema parlaklığı (bkz.
  /// build'deki besleme bloğu).
  Note? _fedNote;
  bool? _fedDark;

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

  /// Gövdeye yapılan son dokunuşun konumu (etiket önizlemesi, bkz.
  /// [_tappedEmbed]).
  final _bodyTapPoint = TapPointTracker();

  /// Gömülü yazıların çip görünümü (etiket adı → türün simgesi/rengi);
  /// her `build`de nottan yeniden çıkarılır.
  Map<String, TagLook> _tagLooks = const {};

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
  ///
  /// `ValueNotifier` (F2.7): gösterge açılıp kapanınca yalnız şerit yeniden
  /// kurulur, 1.500 satırlık editör build'i değil.
  final _aiTaskN = ValueNotifier<String?>(null);
  String? get _aiTask => _aiTaskN.value;

  /// Süren DOSYA işinin adı (kopyalama, yapıştırma, ek hazırlama). AI'dan
  /// ayrı bir alan: ikisi aynı anda koşabilir ve biri ötekini susturmamalı.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-08-10: "görüntü kopyalanırken veya
  /// başka bir şey yüklenirken sessizlik var, yüklenme dönencesi lazım"):
  /// pano işleri ancak BİTİNCE bir SnackBar gösteriyordu. Büyük bir görselin
  /// baytlarını okumak (bulut kopyasında: indirmek) saniyeler sürebiliyor ve o
  /// süre boyunca ekranda hiçbir iz yoktu — kullanıcı düğmeye basmadığını
  /// sanıp tekrar basıyordu.
  final _busyTaskN = ValueNotifier<String?>(null);

  /// Uzun süren DOSYA işlerinin ortak sarmalayıcısı: şeritteki göstergeyi
  /// açar/kapatır. AI'nın [_runAi]'ı ile aynı desen; hata yönetimi çağırana
  /// bırakılır (her işin kendi anlamlı mesajı var).
  Future<T> _runBusy<T>(String label, Future<T> Function() body) async {
    _busyTaskN.value = label;
    try {
      return await body();
    } finally {
      if (mounted) _busyTaskN.value = null;
    }
  }

  /// Uzun süren AI işlerinin TEK giriş noktası: göstergeyi açar/kapatır,
  /// hataları tek biçimde bildirir. Yeni bir AI özelliği eklenirken
  /// göstergeyi ayrıca düşünmek gerekmesin diye burada toplandı.
  Future<void> _runAi(String label, Future<void> Function() body) async {
    if (_aiTask != null) return;
    _aiTaskN.value = label;
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
      if (mounted) _aiTaskN.value = null;
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
  bool _pendingGalleryVideo = false;
  bool _pendingYouTube = false;
  bool _pendingTranscribe = false;
  bool _pendingAudioFile = false;

  void _runPendingIntents() {
    if (!mounted || _note == null) return;
    if (_pendingDraw) {
      _pendingDraw = false;
      _addDrawing();
    }
    if (_pendingVoice) {
      _pendingVoice = false;
      // Sesli not, uygulamanın her yerinde AYNI levhayla (bkz. _captureVoice).
      unawaited(_captureVoice());
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
    // Videodan doğan not "üstte video, altta not" düzeniyle açılır: video
    // sabit bölmede oynarken not altında yazılır (kullanıcının kendi
    // kurduğu düzen; elle sürükleyip sabitlemek gerekmesin).
    if (_pendingGalleryVideo) {
      _pendingGalleryVideo = false;
      unawaited(() async {
        final added = await _addVideoFromGallery();
        if (added != null && mounted) _pinMediaTop(added);
      }());
    }
    if (_pendingYouTube) {
      _pendingYouTube = false;
      unawaited(() async {
        final added = await _addYouTube();
        if (added != null && mounted) _pinMediaTop(added);
      }());
    }
    if (_pendingTranscribe) {
      _pendingTranscribe = false;
      unawaited(_transcribeFile());
    }
    if (_pendingAudioFile) {
      _pendingAudioFile = false;
      unawaited(_pickAudioFile());
    }
  }

  void _cacheDeps() {
    // Paylaşılan not SAHİBİNİN koleksiyonuna yazılır (bkz.
    // [NoteEditorScreen.ownerId]); kendi notlarımda eski yol aynen sürer.
    final owner = widget.ownerId;
    _notesRepo = _readOnly
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

  /// Yeni ek hazırlarken kullanılacak depo: paylaşılan notta SAHİBİN yolu.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-17: "eklerin paylaşımında sorun",
  /// "web tarafında eksikler"): ek ekleyen yolların hepsi ana depoyu
  /// (`users/{BEN}/…`) kullanıyordu. Cihazda zararsızdı (önce yerel kopya,
  /// kuyruk sonra sahibin yoluna yükler) ama WEB'de `_store` baytları HEMEN
  /// Storage'a yazıyor — paylaşılan nota web'den eklenen dosya ekleyenin
  /// kendi yoluna gidiyor, not sahibi ve öbür ortak çalışanlar onu hiç
  /// okuyamıyordu (kural reddi). Her çağrıda taze okunur: Drive bağlanınca
  /// ana depo değişiyor.
  AttachmentRepository? get _attachments {
    final base = ref.read(attachmentRepositoryProvider);
    final owner = widget.ownerId;
    return owner == null ? base : base?.forOwner(owner);
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

  /// ÜÇ YÖNLÜ BİRLEŞTİRMENİN TABANI (F4.1): bu editörün sunucuyla en son
  /// ORTAK gördüğü içerik. Başkasından gelen değişiklik yerelde henüz
  /// kaydedilmemiş yazıyla bu tabana göre birleştirilir (bkz. text_merge).
  String _baseTitle = '';
  String _baseBody = '';
  List<NoteItem> _baseItems = const [];

  void _setBase(Note note) {
    _baseTitle = note.title;
    _baseBody = note.body;
    _baseItems = note.items;
  }
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
    // Notu AÇMAK da bir çalışma izidir ("en çok çalışılan" sıralaması).
    // GEÇİŞ BİTİNCE (kullanıcı bulgusu 2026-10-20: "notu açarken ufak
    // donma"): ilk kareden hemen sonra yazılınca "en çok çalışılan"
    // sıralamasındaki ana ekran, editör kayarak gelirken bütün ızgarasını
    // yeniden kuruyordu. Sayaç beklesin; kimse bunu o anda görmüyor.
    Timer(const Duration(milliseconds: 650), () {
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
    _videoHub.onNoteAt = _noteAtVideoTime;
    _pendingDraw = widget.startDrawing;
    _pendingVoice = widget.startVoiceCapture;
    _pendingDictation = widget.startDictation;
    _pendingVideo = widget.startVideo;
    _pendingPhoto = widget.startPhoto;
    _pendingScan = widget.startScan;
    _pendingPdf = widget.startPdf;
    _pendingSlides = widget.startSlides;
    _pendingGalleryVideo = widget.startGalleryVideo;
    _pendingYouTube = widget.startYouTube;
    _pendingTranscribe = widget.startTranscribe;
    _pendingAudioFile = widget.startAudioFile;
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
      // Paylaşılan notu açık tutmak = bakıyorum: gelen her değişiklik
      // okunmuş sayılır (bkz. sharedNoteUnreadProvider — ana ekran rozeti
      // ve bildirim bu damgaya bakar).
      if (owner != null) {
        ref
            .read(sharedNoteSeenProvider.notifier)
            .markSeen(sharedNoteKey(owner, widget.noteId));
      }
      if (_note == null) {
        // ESKİ DEFTER (F3.5): açılışta sayfalı nota çevrilir ve yazılır.
        final loaded = incoming.type == NoteType.archive
            ? notebookToPagedNote(incoming, pageId: (_) => const Uuid().v4())
            : incoming;
        setState(() {
          _note = loaded;
          _titleController.text = loaded.title;
          _bodyController.text = loaded.body;
        });
        // Açıldığı hâl ilk değişiklikte sürüm olur (F4.2).
        if (!_readOnly) _notesRepo?.rememberVersionBase(loaded);
        _setBase(incoming);
        if (!identical(loaded, incoming) && !_readOnly) {
          unawaited(_notesRepo?.updateNote(loaded));
        }
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
        // AĞIR BELGE İLK KEZ GELDİ (F3.13): ekler olduğu gibi benimsenir —
        // yereldeki hafif kopyanın düzen alanları (PDF işaretleri dahil)
        // boş; birleştirme onları ağır veriye tercih ederdi.
        final hydrating = incoming.heavyLoaded && !previous.heavyLoaded;
        Note merged;
        {
          merged = previous.copyWith(
            heavyRef: incoming.heavyRef,
            heavyLoaded: previous.heavyLoaded || incoming.heavyLoaded,
            attachments: hydrating
                ? incoming.attachments
                : mergeAttachmentLayout(
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
            paged: incoming.paged,
            archivePaper: incoming.archivePaper,
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
            _setBase(incoming);
          } else {
            merged = _mergeConcurrent(merged, incoming, localTitle, localBody);
          }
        }
        _note = merged;
        if (!sameRenderedNote(previous, merged)) _setStateAfterOpening();
      }
    }, fireImmediately: true);
  }

  /// Akıştan gelen değişikliğin yeniden çizimi — rota AÇILIRKEN geçişin
  /// sonuna ertelenir.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-20: "ana ekranda notu açmaya
  /// bastığımda ufak bir donma oluyor"): editör önbellekteki HAFİF notla
  /// açılıyor (bkz. [_cachedNote]); notun kendi belgesi (ağır alanlar, son
  /// sürüm) çoğu zaman sayfa kayarken geliyor ve 4000 satırlık build geçişin
  /// ORTASINDA bir kez daha koşuyordu — kayan sayfa bir an takılıyordu. Veri
  /// (`_note`) hemen güncel; yalnız çizim geçiş bitince yapılır.
  ///
  /// Rotanın animasyonuna `ModalRoute.of` ile BAKILMAZ: o, editörü rotanın
  /// her durum değişimine (üstüne görüntüleyici açılınca) bağlar ve 4000
  /// satırlık build'i o geçişin ortasında koşturur. Açılıştan geçen süre
  /// yeter: geçiş ~420 ms (bkz. SmoothPageTransitionsBuilder); geniş ekranda
  /// geçiş yoksa en kötü ihtimalle ilk yarım saniyedeki bir çizim bekler.
  void _setStateAfterOpening() {
    const opening = Duration(milliseconds: 450);
    final left = opening - _openedFor.elapsed;
    if (left <= Duration.zero) {
      setState(() {});
      return;
    }
    if (_redrawAfterOpening) return;
    _redrawAfterOpening = true;
    Timer(left, () {
      _redrawAfterOpening = false;
      if (mounted) setState(() {});
    });
  }

  /// Editör ne zamandır açık (bkz. [_setStateAfterOpening]).
  final _openedFor = Stopwatch()..start();

  /// Geçiş sonuna ertelenmiş bir yeniden çizim bekliyor mu.
  bool _redrawAfterOpening = false;

  /// **EŞZAMANLI DÜZENLEME** (F4.1): kullanıcı yazarken başka biri (ya da
  /// ikinci cihaz) aynı notu değiştirdi. Eskiden uzaktaki içerik yok
  /// sayılıyor, editörün sonraki tam-doküman kaydı onu SİLİYORDU. Artık
  /// tabana göre üç yönlü birleştirilir ve sonuç kaydedilir; aynı paragraf
  /// iki tarafta farklı değiştiyse ikisi de tutulur ve kullanıcıya söylenir.
  /// Kendi yazımımızın yankısı birleştirilmez, yalnız tabanı ilerletir.
  Note _mergeConcurrent(
    Note merged,
    Note incoming,
    String localTitle,
    String localBody,
  ) {
    final remoteChanged =
        incoming.title != _baseTitle ||
        incoming.body != _baseBody ||
        !sameItems(incoming.items, _baseItems);
    if (!remoteChanged) return merged;
    final repo = _notesRepo;
    if (repo == null || repo.isOwnEcho(incoming)) {
      _setBase(incoming);
      return merged;
    }
    final body = mergeText3(_baseBody, localBody, incoming.body);
    final title = localTitle != _baseTitle ? localTitle : incoming.title;
    final items = mergeItems3(_baseItems, _note!.items, incoming.items);
    _setBase(incoming);
    if (title != localTitle) _titleController.text = title;
    if (body.text != localBody) {
      final caret = _bodyController.selection;
      _bodyController.text = body.text;
      if (caret.isValid) {
        final at = caret.baseOffset.clamp(0, body.text.length);
        _bodyController.selection = TextSelection.collapsed(offset: at);
      }
    }
    final result = merged.copyWith(title: title, body: body.text, items: items);
    // Birleşik hâl hemen yazılır: öbür taraf da görsün, taban ilerlesin.
    _debouncer.cancel();
    _notesRepo?.updateNote(result);
    if (body.conflict) _showSnack(context.l10n.mergeConflictKept);
    return result;
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    openEditorNoteIds.remove(widget.noteId);
    // Dikte açıkken editörden çıkılabiliyor: mikrofon ekranla birlikte
    // kapanmazsa arka planda dinlemeye devam ederdi.
    if (_dictation != null) {
      _dictation!.cancel();
      _dictation = null;
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
    _videoHub.dispose();
    _aiTaskN.dispose();
    _busyTaskN.dispose();
    _titleGeneratingN.dispose();
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
      a.activePage == b.activePage &&
      identical(a.textPages, b.textPages) &&
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
      // KÖK NEDEN (kullanıcı bulgusu 2026-10-20: "defter görünümünde kâğıt
      // tipi seçimi çalışmıyor"): Defter görünümü ve kâğıt deseni burada
      // KARŞILAŞTIRILMIYORDU. İlk değişiklikten sonra (geri al düğmesi zaten
      // etkin) seçim "saf yazım" sayılıyor, `setState` atlanıyor ve yeni
      // desen ancak başka bir yeniden çizimde görünüyordu.
      a.paged == b.paged &&
      a.archivePaper == b.archivePaper &&
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
  Attachment _placeNewImage(Attachment placed, Note note) {
    // METİN ve SES kutusunun kendi ölçüsü yok: sayfadaki kutunun oranı ekte
    // saklanır (metin kâğıt sayfası 1:1,3, ses oynatıcı kartı ~3,6:1) ki
    // tuvalin bütün oran hesapları (sarma, yerleşim, boyutlandırma)
    // görseldeki gibi çalışsın (bkz. text_page_box.dart, audio_card_box.dart).
    final image = placed.width != null && placed.height != null
        ? placed
        : switch (placed.kind) {
            AttachmentKind.text => placed.copyWith(
              width: kTextBoxWidth,
              height: kTextBoxHeight,
            ),
            AttachmentKind.audio => placed.copyWith(
              width: kAudioBoxWidth,
              height: kAudioBoxHeight,
            ),
            // Sunum 16:9 başlar; kutu ilk slaydı açınca gerçek oranı yazar
            // (bkz. SlidePageBox).
            AttachmentKind.slide => placed.copyWith(width: 1600, height: 900),
            _ => placed,
          };
    // PDF kutusu GENİŞ başlar: 0,32 genişlikte bir sayfada yazı okunmuyor,
    // kullanıcı her belgeyi elle büyütmek zorunda kalıyordu. Görselde 0,32
    // kalıyor — satıra üç görsel sığsın (bkz. packSlot). Metin okunacak,
    // ses kartı da düğmeleri sığacak kadar geniş başlar.
    final width = switch (image.kind) {
      AttachmentKind.pdf => 0.6,
      AttachmentKind.text ||
      AttachmentKind.audio ||
      AttachmentKind.slide => 0.8,
      _ => 0.32,
    };
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
    // SAYFALI NOT: görsel ETKİN sayfaya aittir (bkz. Note.textPages).
    final section = note.activePage;
    if (pageWidth <= 0) {
      return image.copyWith(displayWidth: width, section: section);
    }

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
          if (a.floatsOnPage &&
              a.section == note.activePage &&
              (a.pageY != null || a.y != null))
            boxOf(a),
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
      section: section,
    );
  }

  /// [asFile] true ise görsel sayfaya yerleşmez, alt şeritte dosya eki olur.
  /// Eklenen eki döner (gömme akışı onu seçili yazıya bağlar).
  Future<Attachment?> _addImageBytes(
    Uint8List bytes,
    String fileName, {
    bool asFile = false,
  }) async {
    final repo = _attachments;
    if (repo == null) return null;
    try {
      // Sıkıştırma + diske yazma büyük fotoğrafta saniyeler sürüyor ve o süre
      // boyunca ekranda hiçbir iz yoktu (bkz. [_busyTaskN]).
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () => repo.prepareImage(
          noteId: widget.noteId,
          bytes: bytes,
          fileName: fileName,
        ),
      );
      if (!mounted) return null;
      Attachment? added;
      _mutate((n) {
        added = asFile
            ? attachment.copyWith(asFile: true)
            : _placeNewImage(attachment, n);
        return n.copyWith(attachments: [...n.attachments, added!]);
      }, immediate: true);
      return added;
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      // Yalnız FileTooLargeException yakalanıyordu; başka her hata (web'de
      // dosya sistemi yok, disk dolu, izin reddi) yukarı kaçıp await'i
      // tamamlanmadan bırakıyordu → ekran donmuş görünüyor, mesaj çıkmıyordu.
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
    return null;
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

  /// **TEK "DOSYA EKLE"** (2026-10-20): her desteklenen dosya tek seçiciden;
  /// tür uzantıdan. Görsel sayfaya yerleşir; PDF, sunum, ses ve video kendi
  /// yollarına seçici SORULMADAN verilir ([DocPicker.preselect]). HEIC
  /// görsel PNG'ye çevrilir.
  Future<void> _attachAnyFile() async {
    final l10n = context.l10n;
    final files = await DocPicker.pickMany(
      XTypeGroup(
        label: l10n.quickAddFile,
        extensions: PickedFileKind.allExtensions,
        mimeTypes: [
          'image/*',
          'video/*',
          'audio/*',
          'application/pdf',
          DocPicker.byExtension['pptx']!,
        ],
      ),
      chooserTitle: l10n.quickAddFile,
    );
    if (files.isEmpty || !mounted) return;
    String nameOf(XFile f) => f.name.isEmpty ? f.path : f.name;
    final kind = PickedFileKind.of(nameOf(files.first));
    if (kind == null) {
      _showSnack(l10n.quickAddFileUnsupported);
      return;
    }
    var same = [
      for (final f in files)
        if (PickedFileKind.of(nameOf(f)) == kind) f,
    ];
    Future<void> handOff(
      List<XFile> pick,
      Future<Object?> Function() flow,
    ) async {
      DocPicker.preselect(pick);
      try {
        await flow();
      } finally {
        DocPicker.takePreselected();
      }
    }

    switch (kind) {
      case PickedFileKind.image:
        same = await normalizeHeicImages(same);
        if (same.isEmpty) {
          if (mounted) _showSnack(l10n.quickAddFileUnsupported);
          return;
        }
        for (final f in same) {
          if (!mounted) return;
          await _addImageBytes(
            await f.readAsBytes(),
            nameOf(f).split(RegExp(r'[\\/]')).last,
          );
        }
      case PickedFileKind.pdf:
        await handOff(same, _pickPdf);
      case PickedFileKind.slides:
        await handOff([same.first], _pickSlide);
      case PickedFileKind.video:
        await handOff([same.first], _addVideoFromGallery);
      case PickedFileKind.audio:
        await handOff([same.first], _pickAudioFile);
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

  /// "Belge tara": kamerayla belge tarar. Sayfalar önce İNCELEME ekranından geçer (köşe düzeltme, filtre,
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
    } else {
      _showSnack(l10n.scanUnsupported);
      return;
    }
    if (pages == null || pages.isEmpty || !mounted) return;

    final result = await ScanReviewScreen.open(context, pages);
    if (result == null || !mounted) return;

    final pdfBytes = result.pdfBytes;
    if (pdfBytes != null) {
      final repo = _attachments;
      if (repo == null) return;
      try {
        final attachment = await _runBusy(
          context.l10n.attachmentUploading,
          () => repo.preparePdf(
            noteId: widget.noteId,
            bytes: pdfBytes,
            fileName: scanFileName(result.title, DateTime.now()),
          ),
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

  // Gövdenin imleç altındaki bağlantı/etiket sorguları seçim menüsünün
  // ortak kurucusuna taşındı (bkz. [_selectionMenu]) — madde satırları da
  // aynı yolu kullanıyor.

  /// Gövdede DOKUNULAN etiket (imleç etiketin İÇİNDE — sınırlar hariç, bkz.
  /// [attachmentTagInside]) ve bağlı olduğu ek.
  ///
  /// Sınırda (son harfin sağ yarısı) dokunuşun KONUMUNA bakılır — bkz.
  /// [tappedAttachmentTag].
  ({String label, Attachment attachment})? _tappedEmbed(
    EditableTextState? editable,
  ) {
    final note = _note;
    final selection = _bodyController.selection;
    if (note == null || !selection.isValid || !selection.isCollapsed) {
      return null;
    }
    final tag = tappedAttachmentTag(
      logicalText: _bodyController.logicalText,
      logicalCaret: wrapToLogicalOffset(
        _bodyController.text,
        selection.baseOffset,
      ),
      displayText: _bodyController.text,
      selection: selection,
      names: _bodyController.attachmentNames,
      editable: editable,
      tapGlobal: _bodyTapPoint.last,
    );
    if (tag == null) return null;
    final attachment = _attachmentForTag(note, tag.fileName);
    if (attachment == null) return null;
    return (label: tag.fileName, attachment: attachment);
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
    if (attachment.isUnsupported) {
      showUnsupportedAttachmentDialog(context);
      return;
    }
    // Metin eki (transkript) dosyasız: okuma ekranında açılır.
    if (attachment.kind == AttachmentKind.text) {
      unawaited(_openTranscript(attachment));
      return;
    }
    // Drive'daki ek bu cihaza henüz inmediyse ŞİMDİ indirilir, sonra açılır
    // (bkz. drive_ui.dart — arka plan kuyruğunu beklemesin).
    if (!localFileExists(attachment.localPath) &&
        attachment.isInDrive &&
        !attachment.isUploaded) {
      if (kIsWeb) {
        // Web: Drive'dan belleğe (F4.4) — `blob:` adresiyle yeniden açılır.
        resolveWebDriveAttachment(context, ref, attachment).then((resolved) {
          if (resolved != null && mounted) {
            _openAttachmentTag(resolved, editing: editing);
          }
        });
        return;
      }
      fetchAttachmentNow(context, ref, attachment).then((ok) {
        if (ok && mounted) _openAttachmentTag(attachment, editing: editing);
      });
      return;
    }
    if (!localFileExists(attachment.localPath) &&
        !attachment.isUploaded &&
        !attachment.isWebVideo) {
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
      MediaRoute<void>(
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
          // Metin eki yukarıda kendi ekranına gider; dal yalnız bütünlük için.
          AttachmentKind.audio ||
          AttachmentKind.text ||
          AttachmentKind.unknown => ImageViewerScreen(attachment: attachment),
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
    if (attachment != null) _showEmbedPreviewFor(attachment, name);
  }

  /// "+ Ekle" levhasından gelen gömme akışı.
  ///
  /// Seçim VARSA seçici o yazı için açılır ve sonuç doğrudan ona gömülür.
  /// Seçim yoksa önce NE gömüleceği seçilir, sonra bağlama kipine geçilir
  /// (kullanıcı yazıyı sonra seçer — istenen "ters" yön).
  Future<void> _embedAttachmentFlow() async {
    final note = _note;
    if (note == null) return;
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
      final range = trimmedRange(logical, start, end);
      if (range != null) {
        await _embedRange(range.start, range.end);
        return;
      }
    }
    final chosen = await _pickEmbedTarget(label: '');
    if (chosen == null || !mounted) return;
    _startPendingEmbed(chosen);
  }

  /// Gömme seçicisi + gerekiyorsa YENİ eki oluşturma. Yeni ek şeride girer
  /// (gömülü dosya sayfayı kalabalıklaştırmasın); seçilen/oluşan eki döner.
  Future<Attachment?> _pickEmbedTarget({required String label}) async {
    final note = _note;
    if (note == null) return null;
    final pick = await showEmbedPicker(
      context,
      label: label,
      attachments: note.attachments,
    );
    if (pick == null || !mounted) return null;
    if (pick.attachment != null) return pick.attachment;
    switch (pick.create) {
      case 'pdf':
        const group = XTypeGroup(
          label: 'PDF',
          extensions: ['pdf'],
          mimeTypes: ['application/pdf'],
        );
        final files = await DocPicker.pickMany(
          group,
          chooserTitle: context.l10n.pickPdfTitle,
        );
        if (files.isEmpty || !mounted) return null;
        return _addPdfFile(files.first, asFile: true);
      case 'image':
        final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 2400,
          maxHeight: 2400,
        );
        if (file == null || !mounted) return null;
        return _addImageBytes(await file.readAsBytes(), file.name, asFile: true);
      case 'video':
        return _addVideoFromGallery(asFile: true);
      case 'youtube':
        return _addYouTube(asFile: true);
    }
    return null;
  }

  /// Gövdedeki [start]–[end] aralığına (mantıksal metin) gömer: önce seçici.
  Future<void> _embedRange(int start, int end) async {
    final logical = _bodyController.logicalText;
    final range = trimmedRange(logical, start, end);
    if (range == null) return;
    final label = logical.substring(range.start, range.end);
    final chosen = await _pickEmbedTarget(label: label);
    if (chosen == null || !mounted) return;
    // Seçici açıkken metin değişmiş olabilir (dikte, eşitleme): aralık hâlâ
    // AYNI yazıyı gösteriyorsa gömülür, yoksa imlece dosya adıyla.
    final now = _bodyController.logicalText;
    if (range.end <= now.length &&
        now.substring(range.start, range.end) == label) {
      _applyEmbed(
        label: label,
        attachment: chosen,
        start: range.start,
        end: range.end,
      );
    } else {
      _insertTagAtCaret(chosen);
    }
  }

  /// Gömülü yazıya dokununca: YERİNDE önizleme kartı (tam ekrana atlamaz).
  void _showEmbedPreviewFor(Attachment attachment, String label) {
    _dismissKeyboard();
    final editable =
        attachment.kind == AttachmentKind.pdf ||
        attachment.kind == AttachmentKind.image;
    showEmbedPreview(
      context,
      attachment: attachment,
      label: label,
      onOpen: () => _openAttachmentTag(attachment, editing: false),
      onEdit: editable
          ? () => _openAttachmentTag(attachment, editing: true)
          : null,
      onChanged: _updateAttachment,
      onReplace: () => unawaited(_replaceEmbed(label)),
      onUnlink: () => _unlinkEmbed(label),
    );
  }

  /// Gömülü yazının bağladığı eki DEĞİŞTİRİR (yazı aynı kalır).
  Future<void> _replaceEmbed(String label) async {
    final chosen = await _pickEmbedTarget(label: label);
    if (chosen == null || !mounted) return;
    _mutate(
      (n) => n.copyWith(
        tagLinks: [
          for (final l in n.tagLinks)
            if (l.label != label) l,
          NoteTagLink(label: label, attachmentId: chosen.id),
        ],
      ),
      immediate: true,
    );
    _showSnack(context.l10n.attachmentTagInserted);
  }

  /// GÖMMEYİ KALDIRIR: yazı kalır, ataç ve bağ gider (gövde + maddeler).
  void _unlinkEmbed(String label) {
    final body = removeAttachmentTags(_bodyController.logicalText, label);
    if (body != _bodyController.logicalText) {
      _bodyController.setLogical(body, body.length);
    }
    _mutate(
      (n) => n.copyWith(
        body: body,
        items: [
          for (final i in n.items)
            i.text.contains(attachmentTagFor(label))
                ? i.copyWith(text: removeAttachmentTags(i.text, label))
                : i,
        ],
        tagLinks: [
          for (final l in n.tagLinks)
            if (l.label != label) l,
        ],
      ),
      immediate: true,
    );
    _showSnack(context.l10n.embedRemoved);
  }

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
    // Aralığın iki ucundaki boşluklar etikete girmez ve YUTULMAZ (bkz.
    // [trimmedRange]); etiketin kendisi de kırpılmış hâlidir.
    final range = trimmedRange(logical, start, end);
    if (range != null) {
      start = range.start;
      end = range.end;
      label = logical.substring(start, end);
    }
    // Yazı ZATEN bir etiketse (yeniden gömme) ikinci ataç eklenmez, yalnız
    // bağ değişir.
    final alreadyTagged =
        start >= kAttachmentTagPrefix.length &&
        logical.substring(start - kAttachmentTagPrefix.length, start) ==
            kAttachmentTagPrefix;
    // Metne yalnız ATAÇ eklenir; seçilen yazı olduğu gibi kalır.
    final tagged = alreadyTagged ? label : '$kAttachmentTagPrefix$label';
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
  ///
  /// [target] verilirse seçim O ALANDA (madde satırı); verilmezse gövdede.
  Future<void> _embedIntoSelection(
    WrapTextController controller, {
    FormatTarget? target,
  }) async {
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final logical = controller.logicalText;
    final start = wrapToLogicalOffset(
      controller.text,
      selection.start,
    ).clamp(0, logical.length);
    final end = wrapToLogicalOffset(
      controller.text,
      selection.end,
    ).clamp(start, logical.length);
    if (target == null) {
      await _embedRange(start, end);
      return;
    }
    final range = trimmedRange(logical, start, end);
    if (range == null) return;
    final label = logical.substring(range.start, range.end);
    final chosen = await _pickEmbedTarget(label: label);
    if (chosen == null || !mounted) return;
    // Seçici açıkken satırın metni değiştiyse (silindi, eşitlendi) gömülmez.
    final now = controller.logicalText;
    if (range.end <= now.length &&
        now.substring(range.start, range.end) == label) {
      _applyEmbed(
        label: label,
        attachment: chosen,
        start: range.start,
        end: range.end,
        target: target,
      );
    }
  }

  /// Gövdenin seçim menüsü (bkz. [_selectionMenu]).
  Widget _bodyContextMenu(BuildContext menuContext, EditableTextState state) =>
      _selectionMenu(
        state,
        _bodyController,
        commit: () => _mutate(
          (n) => n.copyWith(body: _bodyController.logicalText),
          immediate: true,
        ),
      );

  /// GÖVDE ve MADDE SATIRLARININ ortak seçim menüsü (kullanıcı bulgusu
  /// 2026-10-15: "metin seçim mantığı ve kalitesi düzeltilmeli" — madde
  /// satırında ek gömme, etiket önizleme ve bağlantıyı aç hiç yoktu; sıra
  /// için bkz. [arrangeSelectionMenu]).
  ///
  /// [target] madde satırında alanın kendisi (gömme oraya yazılır); gövdede
  /// null. [trailing] alanın kendi ek seçenekleri (Tüm notu kopyala).
  Widget _selectionMenu(
    EditableTextState state,
    WrapTextController controller, {
    required VoidCallback commit,
    FormatTarget? target,
    List<ContextMenuButtonItem> trailing = const [],
  }) {
    final l10n = context.l10n;
    final selection = state.textEditingValue.selection;
    final hasSelection = selection.isValid && !selection.isCollapsed;
    final note = _note;
    final logical = controller.logicalText;
    final caret = selection.isValid
        ? wrapToLogicalOffset(
            controller.text,
            selection.baseOffset,
          ).clamp(0, logical.length)
        : -1;
    final url = caret < 0 ? null : linkAt(logical, caret);
    final tagLabel = caret < 0 || note == null
        ? null
        : attachmentTagAt(logical, caret, controller.attachmentNames);
    final tagged = tagLabel == null ? null : _attachmentForTag(note!, tagLabel);
    void run(VoidCallback action) {
      state.hideToolbar();
      action();
    }

    final leading = <ContextMenuButtonItem>[
      // BAĞLAMA KİPİ açıksa ilk madde odur: kullanıcı yazıyı yeni seçti,
      // yapacağı tek iş bağlamak.
      if (_pendingEmbed != null && hasSelection)
        ContextMenuButtonItem(
          label: l10n.attachmentTagLinkHere,
          onPressed: () => run(_finishPendingEmbed),
        ),
      // İmleç bir EK ETİKETİNİN üstündeyse önizleme birinci iş.
      if (tagged != null)
        ContextMenuButtonItem(
          label: l10n.attachmentTagPreview,
          onPressed: () => run(() => _showEmbedPreviewFor(tagged, tagLabel!)),
        ),
      if (url != null)
        ContextMenuButtonItem(
          label: l10n.openLink,
          onPressed: () => run(() {
            openLink(url).then((opened) {
              if (!opened && mounted) _showSnack(l10n.linkOpenFailed);
            });
          }),
        ),
    ];
    final afterClipboard = <ContextMenuButtonItem>[
      // Biçim: seçili metne kalın/italik/altı çizili/renk uygular. Giriş
      // noktası SEÇİM çubuğu — biçim zaten "şu metne" uygulanır.
      if (hasSelection)
        ContextMenuButtonItem(
          label: l10n.formatMenu,
          onPressed: () => run(
            () => showFormatSheet(
              context,
              controller: controller,
              onApplied: commit,
            ),
          ),
        ),
      // SEÇİLİ YAZIYA EK GÖM: seçim varsa ve o seçim zaten bir etiket değilse.
      if (hasSelection && tagged == null && !_readOnly)
        ContextMenuButtonItem(
          label: l10n.attachmentTagEmbed,
          onPressed: () => run(
            () => unawaited(_embedIntoSelection(controller, target: target)),
          ),
        ),
      if (tagged != null) ...[
        ContextMenuButtonItem(
          label: l10n.attachmentTagEdit,
          onPressed: () => run(() => _openAttachmentTag(tagged, editing: true)),
        ),
        ContextMenuButtonItem(
          label: l10n.embedRemove,
          onPressed: () => run(() => _unlinkEmbed(tagLabel!)),
        ),
      ],
    ];
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: arrangeSelectionMenu(
        // Kes/Kopyala temiz-metin sürümleri: varsayılanlar panoya biçim
        // işaretlerini (`**`, `%%1:`) ve görünmez sarma çapalarını HAM
        // yazıyordu — dışarı yapıştıran kullanıcı çöp görüyordu.
        platform: cleanClipboardMenuItems(state),
        leading: leading,
        afterClipboard: afterClipboard,
        trailing: trailing,
      ),
    );
  }

  /// Madde satırının seçim menüsü: gövdeyle aynı kurucu, gömme o satıra.
  Widget _itemSelectionMenu(
    EditableTextState state,
    WrapTextController controller,
    VoidCallback commit,
    List<ContextMenuButtonItem> own,
  ) => _selectionMenu(
    state,
    controller,
    commit: commit,
    target: FormatTarget(
      controller: controller,
      focusNode: state.widget.focusNode,
      commit: commit,
    ),
    trailing: own,
  );

  /// **ÇOKLU SEÇİM** (kullanıcı isteği 2026-08-09: "aynı anda birden fazla ek
  /// yüklenebilsin"): seçilen belgeler sırayla eklenir; biri hata verse
  /// (tavanı aşan dosya, okunamayan içerik) kalanlar yine girer.
  Future<void> _pickPdf() async {
    const group = XTypeGroup(
      label: 'PDF',
      extensions: ['pdf'],
      mimeTypes: ['application/pdf'],
    );
    final files = await DocPicker.pickMany(
      group,
      chooserTitle: context.l10n.pickPdfTitle,
    );
    for (final file in files) {
      if (!mounted) return;
      await _addPdfFile(file);
    }
  }

  /// [asFile] true ise PDF sayfaya konmaz, ek şeridinde durur (gömme
  /// akışı). Eklenen eki döner.
  Future<Attachment?> _addPdfFile(XFile file, {bool asFile = false}) async {
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
      if (proceed != true) return null;
    }
    if (!mounted) return null;
    final repo = _attachments;
    if (repo == null) return null;
    try {
      // Başka bir Not kullanıcısının gönderdiği "balonlu PDF" ise damga
      // katmanı sökülür ve balonlar/çizimler DÜZENLENEBİLİR olarak geri
      // yüklenir (bkz. PdfEdit.readSharedPdf). Sıradan PDF'te null döner.
      final restored = await PdfEdit.readSharedPdfInBackground(bytes);
      if (!mounted) return null;
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () => repo.preparePdf(
          noteId: widget.noteId,
          bytes: restored == null ? bytes : restored['bytes'] as Uint8List,
          fileName: _documentFileName(file.name, '.pdf'),
        ),
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
      Attachment? added;
      _mutate((n) {
        added = asFile ? stored : _placePdf(stored, n);
        return n.copyWith(attachments: [...n.attachments, added!]);
      }, immediate: true);
      return added;
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
    return null;
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
    final file = await DocPicker.pickOne(
      group,
      chooserTitle: context.l10n.pickSlidesTitle,
    );
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
    final repo = _attachments;
    if (repo == null) return;
    try {
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () => repo.prepareSlide(
          noteId: widget.noteId,
          bytes: bytes,
          fileName: _documentFileName(file.name, '.pptx'),
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
    final repo = _attachments;
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
    // YouTube ekinin dosyası yok: sistem panosuna BAĞLANTISI yazılır
    // (kullanıcı bulgusu 2026-10-11: "videoların bağlantı adresi
    // kopyalanmıyor" — eskiden yalnız uygulama içi panoya giriyordu,
    // başka uygulamaya yapıştırılacak bir şey yoktu).
    final links = [
      for (final a in attachments)
        if (a.isWebVideo) a.webUrl,
    ];
    if (links.isNotEmpty && links.length == attachments.length) {
      await Clipboard.setData(ClipboardData(text: links.join('\n')));
      if (mounted) _showSnack(l10n.videoLinkCopied);
      return;
    }
    final repo = _attachments;
    final attachment = attachments.first;
    try {
      // Baytları okumak (bulut kopyasında: indirmek) uzun sürebilir; şeritte
      // canlı gösterge dursun (bkz. [_busyTaskN]).
      await _runBusy(l10n.attachmentCopying, () async {
        if (attachment.kind == AttachmentKind.image) {
          final bytes = await repo?.readBytes(attachment);
          if (bytes != null) await Pasteboard.writeImage(bytes);
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
    final repo = _attachments;
    if (sources.isEmpty || repo == null) return;
    try {
      // Baytların yeniden yazılması saniyeler sürebilir: gösterge şeritte
      // dursun, kullanıcı düğmenin çalıştığını görsün (bkz. [_busyTaskN]).
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
    final moved = image.placedOnPage(!asFile);
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
    final repo = _attachments;
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
    final repo = _attachments;
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
      onTranscribe: _openTranscript,
      onSaveAs: (a) => unawaited(AttachmentSaveAs.run(context, ref, a)),
      onPinTop: _pinMediaTop,
      onPinHover: _setPinHover,
      onViewChange: _readOnly
          ? null
          : (a, view) => unawaited(_setAttachmentView(a, view)),
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
      pageNote: _note?.type.isPageNoteType ?? false,
      // Gömme seçicisi yeni ek de ekleyebildiği için eki olmayan notta da
      // anlamlı (gömme yeniden tasarımı, 2026-10-11).
      canEmbed: !(_note?.type.isPageNoteType ?? false),
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
      case 'new-page':
        _addPage();
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
      case 'any-file':
        await _attachAnyFile();
      case 'pdf':
        await _pickPdf();
      case 'slide':
        await _pickSlide();
      case 'drawing':
        await _addDrawing();
      case 'audio':
        await _recordAudio();
      case 'audio-file':
        await _pickAudioFile();
      case 'transcribe':
        await _transcribeFile();
      case 'video':
        await _addVideo();
      case 'video-gallery':
        await _addVideoFromGallery();
      case 'youtube':
        await _addYouTube();
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

  final _titleGeneratingN = ValueNotifier<bool>(false);

  /// "Başlık öner" çipi: nota AI ile kısa bir başlık üretir ve doğrudan
  /// başlık alanına yazar (etiket önerisi gibi bağımsız, isteğe bağlı buton;
  /// eski "kapanırken otomatik başlık" genel ayarının yerini aldı).
  Future<void> _suggestTitle() async {
    final note = _note;
    if (note == null || note.isEmpty || _titleGeneratingN.value) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    _titleGeneratingN.value = true;
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
      if (mounted) _titleGeneratingN.value = false;
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
    final selected = await showAppSheet<String>(
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
      paged: note.paged,
      locked: note.locked,
      archived: note.archivedAt != null,
      isList: note.type == NoteType.checklist || note.type == NoteType.ordered,
      twoColumns: note.listColumns == 2,
      hasFloatingImages: note.attachments.any((a) => a.floatsOnPage),
      hasAttachments: note.attachments.isNotEmpty,
      bubbleView: _readOnly || _switchableDocument(note) == null
          ? null
          : note.type.isPageNoteType,
      canTemplate: canSaveAsTemplate(note),
      canRemoveParts: !_readOnly && _hasBothParts(note),
      // Yalnız KENDİ notum (başkasının notu yerel yapılamaz) ve özellik
      // destekleniyorsa (web'de yok).
      localOnly: widget.ownerId == null && localOnlySupported(ref)
          ? ref.read(notesRepositoryProvider)?.isLocal(note.id) ?? false
          : null,
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'docView':
        _toggleDocumentView();
      case 'pin':
        _mutate((n) => n.copyWith(pinned: !n.pinned), immediate: true);
      case 'star':
        _mutate((n) => n.copyWith(starred: !n.starred), immediate: true);
      case 'paged':
        _mutate((n) => n.copyWith(paged: !n.paged), immediate: true);
      case 'paper':
        await _pickPaper();
      case 'search':
        await _openNoteSearch();
      case 'history':
        await _openHistory();
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
      case 'removeList':
        _removeListPart();
      case 'removeText':
        _removeTextPart();
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
      case 'customize':
        // Düzenleme modu: alt/üst çubuktaki öğelere dokunarak gizle/göster,
        // üstteki şeritten Kaydet (bkz. Personalize).
        FocusManager.instance.primaryFocus?.unfocus();
        Personalize.startEditing();
      case 'calculator':
        _openCalculator();
      case 'sendToFriend':
        _flushPending(_titleController);
        _flushPending(_bodyController);
        if (mounted) {
          await showSendNoteToFriendSheet(context, ref, _note ?? note);
        }
      case 'duplicate':
        await _duplicateNote();
      case 'delete':
        _delete();
    }
  }

  /// Notu çoğaltır (ana ekrandaki kart menüsüyle aynı iş — editörün ⋮
  /// menüsünde yoktu, 2026-10-11 menü taramasında eklendi). Kopya açılmaz;
  /// geri al onu kalıcı siler.
  Future<void> _duplicateNote() async {
    _flushPending(_titleController);
    _flushPending(_bodyController);
    final note = _note;
    final repo = ref.read(notesRepositoryProvider);
    if (note == null || repo == null) return;
    final l10n = context.l10n;
    final id = await repo.duplicateNote(note);
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: note.attachments.isEmpty
          ? l10n.noteDuplicated
          : l10n.noteDuplicatedNoAttachments,
      undoLabel: l10n.undo,
      onUndo: () => repo.hardDelete(id),
    );
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
        if ((n.paged || n.type == NoteType.archive) &&
            n.deletedAt == null &&
            n.id != note.id)
          n,
    ];
    if (notebooks.isEmpty) {
      _showSnack(context.l10n.archiveNoNotebook);
      return;
    }
    final chosen = await showAppSheet<Note>(
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
              // PDF/metin/sesin yerini `onPage` söylüyor (bkz.
              // Attachment.placedOnPage); onlara `asFile` yazmak kutuyu
              // sayfada bırakırdı.
              a.placedOnPage(false)
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

  // ── KARIŞIK İÇERİKTE BÖLÜM KALDIRMA ───────────────────────────────────
  //
  // Kullanıcı isteği 2026-10-16: "liste veya metin notu kısımlarını
  // kaldırabilme, her ikisi de varken". Metin notunun altına madde listesi,
  // liste notunun başına serbest metin eklenebiliyordu ama bir bölümü
  // toptan kaldırmanın yolu yoktu (maddeleri tek tek silmek, metni seçip
  // silmek gerekiyordu). "Metne çevir/Listeye çevir" DÖNÜŞTÜRÜR; bunlar
  // bölümü SİLER. İkisi de geri alınabilir (snackbar + üst çubukta geri al).

  /// Notta hem serbest metin bölümü hem madde listesi var mı?
  bool _hasBothParts(Note note) {
    if (note.type.isPageNoteType || note.items.isEmpty) return false;
    // Metin notunda gövde alanı HEP görünür (boş olsa da bir bölümdür);
    // liste notunda ancak doluysa ya da elle açıldıysa.
    return note.type == NoteType.text ||
        note.body.trim().isNotEmpty ||
        _listBodyOpen;
  }

  /// Madde listesini kaldırır; not saf metin notu olur.
  void _removeListPart() {
    final note = _note;
    if (note == null || note.items.isEmpty) return;
    _flushPending(_bodyController);
    FocusManager.instance.primaryFocus?.unfocus();
    _mutate(
      (n) => n.copyWith(type: NoteType.text, items: const []),
      immediate: true,
    );
    _showUndoSnack(context.l10n.listPartRemoved);
  }

  /// Serbest metni kaldırır; not saf liste notu olur (sıralı liste sıralı
  /// kalır).
  void _removeTextPart() {
    final note = _note;
    if (note == null || note.items.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _bodyController.setLogical('', 0);
    setState(() => _listBodyOpen = false);
    _mutate(
      (n) => n.copyWith(
        type: n.type == NoteType.text ? NoteType.checklist : n.type,
        body: '',
      ),
      immediate: true,
    );
    _showUndoSnack(context.l10n.textPartRemoved);
  }

  void _showUndoSnack(String message) {
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        timedSnackBar(
          content: Text(message),
          action: SnackBarAction(label: l10n.undo, onPressed: _undo),
        ),
      );
  }

  /// "+ Yeni öğe" satırının sağındaki BÖLÜMLER menüsü (yalnız iki bölüm
  /// birden varken).
  Widget? _partsMenu(Note note) {
    if (_readOnly || !_hasBothParts(note)) return null;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      key: const ValueKey('note-parts-menu'),
      tooltip: l10n.notePartsMenu,
      icon: Icon(
        Icons.splitscreen_outlined,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      onSelected: (v) =>
          v == 'list' ? _removeListPart() : _removeTextPart(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'list',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.playlist_remove_rounded),
            title: Text(l10n.removeListPart),
          ),
        ),
        PopupMenuItem(
          value: 'text',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.format_clear_rounded),
            title: Text(l10n.removeTextPart),
          ),
        ),
      ],
    );
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
    final choice = await showAppSheet<ItemSort>(
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

  /// Sürüm geçmişi (F4.2): seçilen sürüme dönmeden önce bugünkü hâl de
  /// sürüm olarak saklanır — dönüş de geri alınabilir.
  Future<void> _openHistory() async {
    final repo = _notesRepo;
    final note = _note;
    if (repo == null || note == null) return;
    _flushPending(_titleController);
    _flushPending(_bodyController);
    final version = await showNoteHistorySheet(context, repo, note.id);
    if (version == null || !mounted) return;
    final current = _note ?? note;
    await repo.saveVersion(current, reason: 'restore');
    if (!mounted) return;
    final restored = version.applyTo(current);
    _titleController.text = restored.title;
    _bodyController.text = restored.body;
    _mutate((_) => restored, immediate: true);
    _showSnack(context.l10n.versionRestored);
  }

  /// "Notu değiştir" sonrası geri alma: eski not anlık görüntüsüne (metin,
  /// öğeler, tip, başlık) tek dokunuşla döner.
  void _offerReplaceUndo(Note before) {
    // AI değiştirmeden önceki hâl sürüm geçmişinde de kalır (F4.2): geri
    // alma 4 sn sonra kaybolur, sürüm kalır.
    unawaited(_notesRepo?.saveVersion(before, reason: 'ai'));
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
    if (mounted) context.pushNote(noteRoutePath(id));
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
    final repo = _attachments;
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
  /// GİTMEZ, yalnızca cihazda kalır (kullanıcı isteği).
  ///
  /// Süre sınırı 60 sn'den 10 dk'ya (ses kaydıyla aynı) çıktı (2026-10-17):
  /// 60 sn, videonun BÜTÜNÜYLE AI'a satır içi gönderilebilmesi içindi. Artık
  /// transkript yalnız SES İZİNİ gönderiyor (Android'de ayrılır, dakikası
  /// ~1 MB); "Videodan not çıkar" ise boyutu kendisi denetleyip büyük videoda
  /// açıkça uyarıyor. Uzun ders/toplantı kaydı 60 sn'de kesiliyordu.
  static const _maxVideoSeconds = 600;

  Future<void> _addVideo() async {
    final repo = _attachments;
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

  /// GALERİDEN video (kullanıcı isteği 2026-10-11: "not içerisine video
  /// koyma"). Kamera yolu gibi cihazda kalır ve sayfaya yerleşir; süre
  /// sınırı YOK (o sınır yalnız AI'a gönderim içindi — uzun videoda
  /// "videodan not çıkar" boyut uyarısını kendisi verir).
  static const _videoExtensions = ['mp4', 'mov', 'mkv', '3gp', 'webm'];

  Future<Attachment?> _addVideoFromGallery({bool asFile = false}) async {
    final repo = _attachments;
    if (repo == null) return null;
    final l10n = context.l10n;
    try {
      // "+ → Dosya ekle"de seçilmiş video varsa galeri sorulmaz (F3.2).
      final picked =
          DocPicker.takePreselected(_videoExtensions)?.first ??
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked == null || !mounted) return null;
      final attachment = await repo.prepareVideo(
        noteId: widget.noteId,
        sourcePath: picked.path,
        duration: await VideoFrame.duration(picked.path),
      );
      if (!mounted) return null;
      Attachment? added;
      _mutate((n) {
        added = asFile
            ? attachment.copyWith(asFile: true)
            : _placeNewImage(attachment, n);
        return n.copyWith(attachments: [...n.attachments, added!]);
      }, immediate: true);
      _showSnack(l10n.videoLocalOnly);
      return added;
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
    return null;
  }

  /// YOUTUBE videosu: bağlantı sorulur (panoda YouTube bağlantısı varsa hazır
  /// gelir), video dosyasız bir ek olarak sayfaya yerleşir ve gömülü
  /// oynatıcıda (resim içinde resim destekli) oynar. Başlık arka planda
  /// YouTube'dan alınır; gelmezse ek "YouTube" adıyla kalır.
  Future<Attachment?> _addYouTube({bool asFile = false}) async {
    final l10n = context.l10n;
    String initial = '';
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      initial = firstYouTubeUrl(clip?.text ?? '') ?? '';
    } catch (_) {}
    if (!mounted) return null;
    final url = await showDialog<String>(
      context: context,
      builder: (context) => _YouTubeLinkDialog(initial: initial),
    );
    if (url == null || !mounted) return null;
    final attachment = webVideoAttachment(url);
    if (attachment == null) {
      _showSnack(l10n.youTubeInvalidLink);
      return null;
    }
    Attachment? added;
    _mutate((n) {
      // Görsel gibi imlecin satırına (16:9 kutu); büyütmek köşe
      // tutamağıyla. Genişliği burada büyütmek, konumu dar kutuya göre
      // hesaplanmış kutuyu sayfa kenarından taşırırdı.
      added = asFile
          ? attachment.copyWith(asFile: true)
          : _placeNewImage(attachment, n);
      return n.copyWith(attachments: [...n.attachments, added!]);
    }, immediate: true);
    // Başlık arka planda gelir; ek hemen kullanılabilir.
    unawaited(() async {
      final title = await fetchYouTubeTitle(attachment.webUrl);
      if (title == null || !mounted) return;
      final current = _note?.attachments.where((a) => a.id == attachment.id);
      if (current == null || current.isEmpty) return;
      _updateAttachment(current.first.copyWith(fileName: title));
    }());
    return added;
  }

  // ── NOTUN SAYFALARI (bkz. Note.textPages / note_pages.dart) ───────────

  /// Sayfa geçişi notun İÇERİĞİNİ değiştirir: metin alanının denetleyicisi
  /// nottan beslenmediği için (geri al ile aynı) elle yazılır. Geri al
  /// yığınına GİRER: silinen sayfa "Geri al" ile döner; geri alınan anlık
  /// görüntü sayfa bilgisini de taşıdığı için içerik hep tutarlı kalır.
  void _applyPageChange(Note next) {
    _bodyController.text = next.body;
    _mutate((_) => next, immediate: true);
    // Yeni sayfa tepeden başlar.
    if (_pageScroll.hasClients) _pageScroll.jumpTo(0);
  }

  /// Etkin sayfanın arkasına boş sayfa ekler ve ona geçer (kullanıcı isteği
  /// 2026-10-11: "bir nota yeni sayfa ekleme").
  void _addPage() {
    final note = _note;
    if (note == null || note.type.isPageNoteType) return;
    _dismissKeyboard();
    _applyPageChange(addTextPage(note, const Uuid().v4()));
    final pos = textPagePosition(_note!);
    _showSnack(context.l10n.pageAdded(pos.index + 1));
  }

  void _goToPage(String id) {
    final note = _note;
    if (note == null || id == note.activePage) return;
    _dismissKeyboard();
    _applyPageChange(switchTextPage(note, id));
  }

  /// Komşu sayfaya geçer ([delta] -1 / +1).
  void _stepPage(int delta) {
    final note = _note;
    if (note == null) return;
    final pages = resolvedTextPages(note);
    final i = textPagePosition(note).index + delta;
    if (i < 0 || i >= pages.length) return;
    _goToPage(pages[i].id);
  }

  /// Etkin sayfayı siler (onaylı). Görselleri komşu sayfaya taşınır; yazı
  /// "Geri al" ile döner.
  Future<void> _deleteActivePage() async {
    final note = _note;
    if (note == null || note.textPages.length < 2) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.archiveDeletePage),
        content: Text(l10n.deletePageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.archiveDeletePage),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final current = _note;
    if (current == null) return;
    _applyPageChange(deleteTextPage(current, current.activePage));
  }

  /// Başlığın altındaki SAYFA ÇUBUĞU: ‹ Sayfa 2 / 3 › · yeni sayfa · ⋮.
  /// Yalnız sayfalı notta görünür (tek sayfalı notta yer kaplamaz).
  Widget _pageBar(Note note) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pos = textPagePosition(note);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kGutter - 8),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('page-prev'),
            tooltip: l10n.archivePrevPage,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left),
            onPressed: pos.index > 0 ? () => _stepPage(-1) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.pageOf(pos.index + 1, pos.count),
              key: const ValueKey('page-label'),
              style: TextStyle(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('page-next'),
            tooltip: l10n.archiveNextPage,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right),
            onPressed: pos.index < pos.count - 1 ? () => _stepPage(1) : null,
          ),
          const Spacer(),
          IconButton(
            tooltip: l10n.archiveNewPage,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.note_add_outlined),
            onPressed: _addPage,
          ),
          IconButton(
            tooltip: l10n.archiveDeletePage,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _deleteActivePage,
          ),
        ],
      ),
    );
  }

  // ── ÜSTE SABİTLİ MEDYA ("üstte video/resim, altta not") ────────────────

  /// Görsel sabitleme bölgesinin üstündeyken true: "Bırak" şeridi görünür.
  bool _pinHover = false;

  // ── BALONLU ⇄ KLASİK GÖRÜNÜM ─────────────────────────────────────────
  //
  // Kullanıcı isteği 2026-10-15: "balonlu mod ve normal ek arasında hızlı,
  // sürükleyerek veya başka şekilde geçiş; düzenler kaydedilsin". Kip
  // eskiden YALNIZ notu oluştururken seçiliyordu ve bir daha
  // değiştirilemiyordu. Geçiş artık üç yoldan:
  //  * başlığın altındaki görünüm çipi (tek dokunuş, iki yönde),
  //  * klasik notta sayfadaki PDF'i ekranın TEPESİNE sürüklemek (görseli
  //    üste sabitlemenin aynı hareketi — "üstte belge, altta not"),
  //  * ⋮ menüsü ve sayfadaki PDF kutusunun menüsü.
  // Geçiş VERİ SİLMEZ: balonlar/vurgular/çizimler ekte, sayfa notları notta,
  // klasik yerleşim (belgenin sayfadaki yeri, boyutu, sayfası) ekte kalır —
  // geri dönünce iki düzen de olduğu gibi gelir (bkz. Note.classicDocument).

  /// Görünümü değiştirilebilecek belge: notun ilk PDF/sunum eki.
  static Attachment? _switchableDocument(Note note) => note.attachments
      .where(
        (a) => a.kind == AttachmentKind.pdf || a.kind == AttachmentKind.slide,
      )
      .firstOrNull;

  void _toggleDocumentView() {
    final note = _note;
    if (note == null) return;
    if (note.type.isPageNoteType) {
      _switchToClassic();
    } else {
      _switchToBubbles();
    }
  }

  /// KLASİK → BALONLU: belge notun kendisi olur (üstte sayfa, altta sayfa
  /// notu; üzerine balon/vurgu/kalem). [document] verilmezse ilk belge.
  void _switchToBubbles([Attachment? document]) {
    final note = _note;
    if (note == null || note.type.isPageNoteType || _readOnly) return;
    final doc = document ?? _switchableDocument(note);
    if (doc == null) return;
    if (_pinHover) setState(() => _pinHover = false);
    _dismissKeyboard();
    final hadText =
        note.body.trim().isNotEmpty ||
        note.items.any((i) => i.text.trim().isNotEmpty);
    // Sabit bölmeden balonluya geçen belge (ya da kaynağı olan görsel)
    // sabitlikten çıkar: balonlu görünümde bölme yok, klasiğe dönünce
    // kendiliğinden yeniden sabitlenmiş görünmesin. Bölme yüksekliği
    // hatırlanır (işaret negatif — bkz. Attachment.pinHeight).
    Attachment released(Attachment a) =>
        (a.id == doc.id || a.id == doc.sourceId) && a.pinHeight > 0
        ? a.copyWith(pinHeight: -a.pinHeight)
        : a;
    _mutate(
      (n) => n.copyWith(
        type: doc.kind == AttachmentKind.slide ? NoteType.slides : NoteType.pdf,
        classicDocument: false,
        // Belge bölmesi türünün İLK ekini gösterir: seçilen belge öne alınır
        // (sıra dışında hiçbir alan değişmez — klasik düzen ekte kalır).
        attachments: [
          for (final a in n.attachments)
            if (a.id == doc.id) released(a),
          for (final a in n.attachments)
            if (a.id != doc.id) released(a),
        ],
      ),
      immediate: true,
    );
    HapticFeedback.mediumImpact();
    final l10n = context.l10n;
    _showSnack(
      hadText
          ? '${l10n.docViewSwitchedBubbles} ${l10n.docViewTextKept}'
          : l10n.docViewSwitchedBubbles,
    );
  }

  /// BALONLU → KLASİK: not yeniden metin notu olur, belge sayfada (ya da
  /// önceden durduğu şeritte) bir ek olarak görünür.
  void _switchToClassic({bool announce = true}) {
    final note = _note;
    if (note == null || !note.type.isPageNoteType || _readOnly) return;
    final kind = note.type == NoteType.slides
        ? AttachmentKind.slide
        : AttachmentKind.pdf;
    final doc = note.attachments.where((a) => a.kind == kind).firstOrNull;
    _dismissKeyboard();
    _mutate((n) {
      final asText = n.copyWith(type: NoteType.text, classicDocument: true);
      return asText.copyWith(
        attachments: [
          for (final a in n.attachments)
            // Balonlu doğmuş (sayfada hiç yeri olmamış) PDF sayfaya yerleşir;
            // klasikte bir yeri olan belge KENDİ yerine döner — sayfada ya da
            // şeritte (kullanıcı oraya koyduysa) olduğu gibi.
            // Görselden üretilmiş belge (bkz. Attachment.sourceId) sayfaya
            // KONMAZ: klasikte görselin kendisi görünür, belge gizlenir.
            if (doc != null &&
                a.id == doc.id &&
                a.kind == AttachmentKind.pdf &&
                a.sourceId.isEmpty &&
                a.x == null &&
                a.pageY == null)
              _placePdf(a, asText)
            else
              a,
        ],
      );
    }, immediate: true);
    HapticFeedback.mediumImpact();
    if (announce) _showSnack(context.l10n.docViewSwitchedClassic);
  }

  /// Görseli/videoyu notun üstündeki sabit bölmeye alır. Bölmede TEK medya
  /// olur: önceden sabitlenmiş olan sayfaya geri döner. Daha önce
  /// sabitlenmişse bölme ESKİ yüksekliğiyle açılır.
  void _pinMediaTop(Attachment media) {
    if (_pinHover) setState(() => _pinHover = false);
    // PDF de GERÇEKTEN sabitlenir (kullanıcı bulgusu 2026-10-16: "PDF'lerde
    // üste sabitleme yapamıyorum"). Eskiden PDF'i tepeye sürüklemek balonlu
    // görünüme geçiriyordu; balonlu artık görünüm anahtarının ayrı kipi.
    final height =
        media.rememberedPinHeight ??
        defaultPinnedHeight(media, MediaQuery.sizeOf(context));
    _dismissKeyboard();
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == media.id)
              a.copyWith(pinHeight: height, asFile: false)
            else if (a.pinHeight > 0)
              a.copyWith(pinHeight: -a.pinHeight)
            else
              a,
        ],
      ),
      immediate: true,
    );
    HapticFeedback.mediumImpact();
  }

  /// Sabit medyayı sayfaya geri koyar: sayfadaki ESKİ yeri ve genişliği
  /// sabitlerken silinmediği için olduğu gibi döner; bölme yüksekliği de bir
  /// sonraki sabitleme için saklanır (işaret negatife çevrilir).
  void _unpinMedia(Attachment media) {
    final current = _note?.attachments.where((a) => a.id == media.id);
    final latest = current == null || current.isEmpty ? media : current.first;
    if (latest.pinHeight <= 0) return;
    _updateAttachment(latest.copyWith(pinHeight: -latest.pinHeight));
  }

  /// Ek üstteki sabit bölmede mi çiziliyor (o zaman şeritte gösterilmez).
  /// Belge notunda bölme yok — sabitli ek orada şeritte görünmeye devam eder.
  /// İki cihazda aynı anda sabitlenmiş (çakışan) ikinci medya bölmede
  /// gösterilmez; o da şeritte kalır, kaybolmaz.
  bool _inPinnedPane(Note note, Attachment a) =>
      a.isPinnedTop &&
      !note.type.isPageNoteType &&
      note.attachments.firstWhere((x) => x.isPinnedTop).id == a.id;

  void _setPinHover(bool value) {
    if (_pinHover != value && mounted) setState(() => _pinHover = value);
  }

  // ── GÖRÜNÜM: SABİT / YÜZEN / BALONLU ──────────────────────────────────
  //
  // Kullanıcı isteği 2026-10-16: "sabitleme, yüzen ve balonlu arasında
  // kolay geçiş TÜM ekler için olmalı; geçişin yeri ve düzeni iyi değil".
  // Üç kip tek anahtarda (bkz. view_mode_switch.dart) ve anahtar ekin
  // YANINDA: sayfada seçilince araç panelinde, sabit bölmenin çubuğunda,
  // balonlu görünümde sayfa çubuğunda.

  /// [a] şu an hangi görünümde.
  AttachmentView _viewOf(Note note, Attachment a) {
    if (note.type.isPageNoteType) {
      final kind = note.type == NoteType.slides
          ? AttachmentKind.slide
          : AttachmentKind.pdf;
      final doc = note.attachments.where((x) => x.kind == kind).firstOrNull;
      if (doc != null && (doc.id == a.id || doc.sourceId == a.id)) {
        return AttachmentView.bubbles;
      }
    }
    if (a.isPinnedTop) return AttachmentView.pinned;
    // Belge notunda (balonlu) her ek şeritte durur; klasikte şeritteki ek
    // "Ek" kipindedir.
    if (note.type.isPageNoteType || a.offPage) {
      return AttachmentView.attached;
    }
    return AttachmentView.floating;
  }

  /// [a]'nın görünüm anahtarı; salt okunurda ya da tek seçenekte null.
  Widget? _viewSwitchFor(Note note, Attachment a, {bool dense = false}) {
    if (_readOnly) return null;
    final available = availableViews(a);
    if (available.length < 2) return null;
    return AttachmentViewSwitch(
      current: _viewOf(note, a),
      available: available,
      dense: dense,
      onChanged: (view) => unawaited(_setAttachmentView(a, view)),
    );
  }

  /// Anahtardan gelen geçiş.
  Future<void> _setAttachmentView(Attachment a, AttachmentView view) async {
    final note = _note;
    if (note == null || _readOnly) return;
    if (_viewOf(note, a) == view) return;
    switch (view) {
      case AttachmentView.attached:
        // → ALT ŞERİT: balonluysa önce klasik; sabitse bölmeden iner;
        // sayfadaysa şeride taşınır (yeri/boyu hatırlanır).
        var target = a;
        if (note.type.isPageNoteType) {
          if (a.sourceId.isNotEmpty) {
            target =
                note.attachments.where((x) => x.id == a.sourceId).firstOrNull ??
                a;
          }
          _switchToClassic(announce: false);
        }
        final latest =
            _note?.attachments.where((x) => x.id == target.id).firstOrNull ??
            target;
        var next = latest.pinHeight > 0
            ? latest.copyWith(pinHeight: -latest.pinHeight)
            : latest;
        if (!next.offPage) next = next.placedOnPage(false);
        if (!identical(next, latest)) {
          _updateAttachment(next);
          HapticFeedback.selectionClick();
        }
        // Şerit kapalıysa açılır: ek nereye gitti diye aranmasın.
        if (!ref.read(attachmentsExpandedProvider)) {
          ref.read(attachmentsExpandedProvider.notifier).toggle();
        }
      case AttachmentView.bubbles:
        if (a.kind == AttachmentKind.image) {
          await _imageToBubbles(a);
        } else if (a.kind == AttachmentKind.text) {
          await _textToBubbles(a);
        } else if (a.kind == AttachmentKind.pdf ||
            a.kind == AttachmentKind.slide) {
          _switchToBubbles(a);
        }
      case AttachmentView.floating:
        if (note.type.isPageNoteType) {
          // Balonlu → yüzen: not klasiğe döner. Görselden üretilmiş belgede
          // görselin kendisi sayfasına döner (belge gizlenir).
          _switchToClassic(announce: false);
          final source = a.sourceId.isEmpty
              ? null
              : _note?.attachments.where((x) => x.id == a.sourceId).firstOrNull;
          _floatOnPage(source ?? a);
          _showSnack(context.l10n.viewModeSwitchedFloating);
          return;
        }
        _floatOnPage(a);
      case AttachmentView.pinned:
        var target = a;
        if (note.type.isPageNoteType) {
          // Balonlu → sabit: önce klasik, sonra sabit bölme. Görselden
          // üretilmiş belgede sabitlenen GÖRSELİN kendisi.
          if (a.sourceId.isNotEmpty) {
            target =
                note.attachments.where((x) => x.id == a.sourceId).firstOrNull ??
                a;
          }
          _switchToClassic(announce: false);
        }
        final latest =
            _note?.attachments.where((x) => x.id == target.id).firstOrNull ??
            target;
        _pinMediaTop(latest);
    }
  }

  /// Eki SAYFAYA (yüzen) alır: sabitse bölmeden iner, şeritteyse sayfaya
  /// konur. Sayfada önceden bir yeri varsa oraya döner.
  void _floatOnPage(Attachment a) {
    final note = _note;
    if (note == null) return;
    final latest = note.attachments.where((x) => x.id == a.id).firstOrNull ?? a;
    var next = latest.pinHeight > 0
        ? latest.copyWith(pinHeight: -latest.pinHeight)
        : latest;
    if (next.offPage) {
      final moved = next.placedOnPage(true);
      next = moved.x != null || moved.pageY != null
          ? moved
          : _placeNewImage(moved, note);
    }
    if (identical(next, latest)) return;
    _updateAttachment(next);
    HapticFeedback.selectionClick();
  }

  /// GÖRSEL → BALONLU: görsel tek sayfalık bir belgeye çevrilir (yakalama
  /// levhasındaki "balonlu" kipin yolu — bkz. `ScanPdf`), üstündeki çizim
  /// ve balonlar belgeye taşınır. Belge görsele bağlıdır
  /// ([Attachment.sourceId]): klasiğe dönünce gizlenir, yeniden balonluya
  /// alınınca AYNI belge (balonlarıyla) geri gelir.
  Future<void> _imageToBubbles(Attachment image) async {
    final note = _note;
    if (note == null) return;
    final existing = note.attachments
        .where((a) => a.kind == AttachmentKind.pdf && a.sourceId == image.id)
        .firstOrNull;
    if (existing != null) {
      _switchToBubbles(existing);
      return;
    }
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    _showSnack(l10n.imageNotePreparing);
    File? temp;
    try {
      var path = image.localPath;
      if (!localFileExists(path)) {
        final bytes = await repo.readBytes(image);
        if (bytes == null) {
          if (mounted) _showSnack(l10n.attachmentNotSynced);
          return;
        }
        final dir = await getTemporaryDirectory();
        temp = File(
          '${dir.path}${Platform.pathSeparator}balon_'
          '${DateTime.now().microsecondsSinceEpoch}.img',
        );
        await temp.writeAsBytes(bytes);
        path = temp.path;
      }
      final pdfBytes = await ScanPdf.build([path]);
      if (!mounted) return;
      final dot = image.fileName.lastIndexOf('.');
      final base = dot > 0 ? image.fileName.substring(0, dot) : image.fileName;
      final pdf = await repo.preparePdf(
        noteId: widget.noteId,
        bytes: pdfBytes,
        fileName: '${base.isEmpty ? 'gorsel' : base}.pdf',
      );
      if (!mounted) return;
      final w = image.width ?? 0;
      final h = image.height ?? 0;
      final frame = ScanPdf.imageFrameOnPage(w, h);
      final hasFrame = w > 0 && h > 0;
      final derived = pdf.copyWith(
        sourceId: image.id,
        ink: hasFrame ? placeInk(image.ink, frame) : const [],
        bubbles: hasFrame ? placeBubbles(image.bubbles, frame) : const [],
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, derived]),
        immediate: true,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _switchToBubbles(derived);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.genericError('$e'));
    } finally {
      temp?.delete().ignore();
    }
  }

  /// METİN → BALONLU (kullanıcı isteği 2026-10-17: "txt dosyaları da ...
  /// balonlu mod geçişi"): metin ekinden A4 sayfalı bir belge üretilir
  /// (notun PDF dışa aktarımıyla aynı dizgi — Türkçe yazı tipi gömülü) ve
  /// görseldeki gibi kaynağa bağlanır ([Attachment.sourceId]): klasikte
  /// gizlenir, yeniden balonluya alınınca AYNI belge balonlarıyla gelir.
  /// Metin sonradan düzenlendiyse ([Attachment.sourceDigest] tutmuyor) belge
  /// aynı kimlikle YENİDEN dizilir — balonlar ve sayfa notları korunur.
  Future<void> _textToBubbles(Attachment textAttachment) async {
    final note = _note;
    if (note == null) return;
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    final existing = note.attachments
        .where(
          (a) => a.kind == AttachmentKind.pdf && a.sourceId == textAttachment.id,
        )
        .firstOrNull;
    final digest = Attachment.digestOf(textAttachment.text);
    if (existing != null && existing.sourceDigest == digest) {
      _switchToBubbles(existing);
      return;
    }
    _showSnack(l10n.textToBubblesPreparing);
    try {
      final dot = textAttachment.fileName.lastIndexOf('.');
      final base = dot > 0
          ? textAttachment.fileName.substring(0, dot)
          : textAttachment.fileName;
      final pdfBytes = await NotePdf.build(
        title: base,
        content: textAttachment.text,
      );
      if (!mounted) return;
      final Attachment derived;
      if (existing == null) {
        final pdf = await repo.preparePdf(
          noteId: widget.noteId,
          bytes: pdfBytes,
          fileName: '${base.isEmpty ? 'metin' : base}.pdf',
        );
        derived = pdf.copyWith(
          sourceId: textAttachment.id,
          sourceDigest: digest,
        );
      } else {
        final replaced = await repo.replaceDocumentBytes(
          noteId: widget.noteId,
          attachment: existing,
          bytes: pdfBytes,
        );
        derived = replaced.copyWith(sourceDigest: digest);
      }
      if (!mounted) return;
      _mutate(
        (n) => n.copyWith(
          attachments: existing == null
              ? [...n.attachments, derived]
              : [
                  for (final a in n.attachments)
                    if (a.id == existing.id) derived else a,
                ],
        ),
        immediate: true,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _switchToBubbles(derived);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.genericError('$e'));
    }
  }

  // ── VİDEO ZAMAN DAMGALARI ─────────────────────────────────────────────
  //
  // Kullanıcı isteği 2026-10-16: "videolarda altta dk sn notu YouTube'daki
  // gibi, tıklayınca video o dk sn'ye gider; tersi de: video akarken
  // kenarda 'bu dakikaya not al' düğmesi madde ekler ya da metne dk sn
  // yazar ve not alanına odaklar".

  /// Nottaki oynatıcıların buluşma noktası (bkz. video_time.dart).
  final _videoHub = NoteVideoHub();

  /// Notta video (dosya ya da YouTube) var mı — damgalar ancak o zaman
  /// bağlantı gibi çizilir.
  ///
  /// SES de sayılır (2026-10-17): ders kaydının yanında alınan `12:30`
  /// damgası sesi oraya sarar (bkz. AudioCardBox).
  static bool _hasVideo(Note note) => note.attachments.any(
    (a) => a.kind == AttachmentKind.video || a.kind == AttachmentKind.audio,
  );

  /// Sabit bölmedeki videonun "Bu ana not al" düğmesi.
  /// Sabit videonun ⤢ düğmesi: GERÇEK tam ekran, KALDIĞI YERDEN.
  ///
  /// Kullanıcı bulgusu 2026-10-19: "video sabitken tam ekran yapma seçeneği
  /// yok". Düğme oynatıcı ekranını açıyordu ama video baştan başlıyor, ekran
  /// dikey ve çubuklu kalıyordu. Artık küçük oynatıcının konumu okunur, o
  /// durdurulur, tam ekran o andan açılır; kapanınca küçük oynatıcı tam
  /// ekranda kalınan yere sarılır ve oynuyorsa oynamayı sürdürür.
  Future<void> _openPinnedVideoFullscreen(Attachment video) async {
    // Dosyası henüz bu cihazda olmayan video için eski yol (indirme/uyarı).
    if (!video.isWebVideo && !localFileExists(video.localPath)) {
      _openAttachmentTag(video, editing: true);
      return;
    }
    final source = _videoHub.sourceFor(video.id);
    final wasPlaying = source?.isPlaying ?? false;
    final at = await source?.position();
    await source?.pause();
    if (!mounted) return;
    Duration? end;
    await Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => VideoViewerScreen(
          attachment: video,
          start: at,
          fullscreen: true,
          onClose: (position) => end = position,
        ),
      ),
    );
    final back = end;
    // Küçük oynatıcı tam ekran açıkken yeniden kurulmuş olabilir: güncelini al.
    final latest = _videoHub.sourceFor(video.id);
    if (!mounted || latest == null) return;
    if (back != null) await latest.seekTo(back);
    if (wasPlaying) await latest.play();
  }

  Future<void> _noteAtPinned(Attachment video) async {
    final source = _videoHub.sourceFor(video.id);
    if (source == null || !await _videoHub.noteAt(source)) {
      if (mounted) _showSnack(context.l10n.videoTimeUnknown);
    }
  }

  /// Damgaya dokunuldu: video oraya sarılır. Oynatıcısı açık olan video
  /// (son oynatılan, yoksa sabitli olan) önce gelir; hiçbiri açık değilse
  /// sabit/sayfadaki YouTube kutusu o saniyeden başlar, o da yoksa video
  /// tam ekranda o andan açılır.
  void _seekVideoTo(int seconds) {
    final note = _note;
    if (note == null) return;
    final media = [
      for (final a in note.attachments)
        if (a.kind == AttachmentKind.video || a.kind == AttachmentKind.audio)
          a,
    ];
    if (media.isEmpty) return;
    HapticFeedback.selectionClick();
    final pinned = media.where((a) => _inPinnedPane(note, a)).firstOrNull;
    final source = _videoHub.target(preferId: pinned?.id);
    if (source != null) {
      _videoHub.touch(source);
      unawaited(source.seekTo(Duration(seconds: seconds)));
      return;
    }
    final videos = [
      for (final a in media)
        if (a.kind == AttachmentKind.video) a,
    ];
    // Yalnız ŞERİTTE duran ses var (oynatıcı kartı çizili değil): ses
    // tepeye sabitlenir ve kart kurulunca o saniyeye sarılır — damgaya
    // dokunan dinlemek ister, sesin nerede çalacağını aramasın.
    if (videos.isEmpty) {
      final audio = media.first;
      if (_readOnly || note.type.isPageNoteType) return;
      _pinMediaTop(audio);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pinnedSource = _videoHub.sourceFor(audio.id);
        if (pinnedSource == null) return;
        _videoHub.touch(pinnedSource);
        unawaited(pinnedSource.seekTo(Duration(seconds: seconds)));
      });
      return;
    }
    final pinnedVideo = pinned?.kind == AttachmentKind.video ? pinned : null;
    final inPage =
        pinnedVideo ??
        videos.where((a) => a.isWebVideo && a.floatsOnPage).firstOrNull;
    if (inPage != null && inPage.isWebVideo) {
      _videoHub.requestStart(inPage.id, seconds);
      return;
    }
    final video = pinnedVideo ?? videos.first;
    Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => VideoViewerScreen(
          attachment: video,
          start: Duration(seconds: seconds),
          onNoteAt: _readOnly
              ? null
              : (position) => _noteAtVideoTime(video.id, position),
        ),
      ),
    );
  }

  /// "Bu ana not al": liste notunda (ya da odak bir maddedeyken) damgalı
  /// YENİ MADDE açılır; metinde imlecin satırına (boşsa) ya da altına yeni
  /// satıra damga yazılır. Her iki durumda odak oraya gider, klavye açılır.
  void _noteAtVideoTime(String attachmentId, Duration position) {
    final note = _note;
    if (note == null || _readOnly) return;
    final stamp = formatVideoTimestamp(position);
    HapticFeedback.selectionClick();
    final target = _formatTarget?.controller;
    final itemsState = _itemsEditorKey.currentState;
    final isList =
        note.type == NoteType.checklist || note.type == NoteType.ordered;
    final focusedItem =
        target != null &&
        target != _bodyController &&
        target != _titleController;
    if (itemsState != null && (focusedItem || (isList && !_listBodyOpen))) {
      itemsState.addItemWithText('$stamp ', after: focusedItem ? target : null);
      return;
    }
    final logical = _bodyController.logicalText;
    final selection = _bodyController.selection;
    final caret = selection.isValid
        ? wrapToLogicalOffset(_bodyController.text, selection.extentOffset)
        : -1;
    final result = insertTimestampLine(logical, caret, stamp);
    _bodyController.setLogical(result.text, result.caret);
    _mutate((n) => n.copyWith(body: result.text), immediate: true);
    if (!_bodyFocus.hasFocus) _bodyFocus.requestFocus();
    _revealCaretSoon();
  }

  /// Gövdede dokunulan damga (saniye); yoksa null.
  int? _tappedTimestamp(EditableTextState? editable) {
    final note = _note;
    if (note == null || !_hasVideo(note)) return null;
    return tappedVideoTimestamp(
      displayText: _bodyController.text,
      selection: _bodyController.selection,
      editable: editable,
      tapGlobal: _bodyTapPoint.last,
    );
  }

  /// Gövdeyi (sayfa notu değilse) sabit medya bölmesi ve sürükleme sırasında
  /// tepede beliren "Bırak: üste sabitle" şeridiyle sarar.
  Widget _withPinnedMedia(Note note, Widget body) {
    if (note.type.isPageNoteType) return body;
    final pinned = note.attachments.where((a) => a.isPinnedTop).firstOrNull;
    final content = pinned == null
        ? body
        : PinnedMediaPane(
            media: pinned,
            onHeightChanged: (h) =>
                _updateAttachment(pinned.copyWith(pinHeight: h)),
            // Bölmeden çıkış (ayracı tepeye çekmek, ⋮ → Sayfaya göm) eki
            // SAYFAYA koyar — şeritten sabitlenmiş belge/metin/ses de dahil.
            onUnpin: () =>
                unawaited(_setAttachmentView(pinned, AttachmentView.floating)),
            onOpen: pinned.kind == AttachmentKind.video
                ? () => unawaited(_openPinnedVideoFullscreen(pinned))
                : () => _openAttachmentTag(pinned, editing: true),
            onCopyLink: () => _copyAttachment(pinned),
            onChanged: _updateAttachment,
            viewSwitch: _viewSwitchFor(note, pinned, dense: true),
            onNoteAt:
                (pinned.kind == AttachmentKind.video ||
                        pinned.kind == AttachmentKind.audio) &&
                    !_readOnly
                ? () => _noteAtPinned(pinned)
                : null,
            // Sabit bölmenin ⋮ menüsü (kullanıcı bulgusu 2026-10-16: "video
            // sabitken kaldırmak yok, gömülü hale getirmek gerekiyor").
            onRemove: _readOnly
                ? null
                : () {
                    _removeAttachment(pinned);
                    final l10n = context.l10n;
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        timedSnackBar(
                          content: Text(l10n.attachmentRemoved),
                          action: SnackBarAction(
                            label: l10n.undo,
                            onPressed: _undo,
                          ),
                        ),
                      );
                  },
            // PDF'in seçilebilir metni var; transkript ses/video/görselde.
            onTranscribe: Transcripts.canTranscribe(pinned)
                ? () => unawaited(_openTranscript(pinned))
                : null,
            onSaveAs: pinned.isWebVideo
                ? null
                : () => unawaited(AttachmentSaveAs.run(context, ref, pinned)),
            onDetach: _readOnly || pinned.isWebVideo
                ? null
                : () {
                    _unpinMedia(pinned);
                    final latest =
                        _note?.attachments
                            .where((a) => a.id == pinned.id)
                            .firstOrNull ??
                        pinned;
                    _setImageAsFile(latest, true);
                  },
            // Görsel balonlu görünümden sabite alındıysa balonları onun
            // türetilmiş belgesinde (bkz. Attachment.sourceId).
            bubbleDoc: pinned.kind == AttachmentKind.image
                ? note.attachments
                      .where(
                        (a) =>
                            a.sourceId == pinned.id &&
                            a.kind == AttachmentKind.pdf,
                      )
                      .firstOrNull
                : null,
            child: body,
          );
    return Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            child: AnimatedSlide(
              offset: _pinHover ? Offset.zero : const Offset(0, -1.2),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.vertical_align_top,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.l10n.pinMediaRelease,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// **TRANSKRİPT** — ekin metne dökümünü açar (kullanıcı isteği
  /// 2026-10-17). [target] bir metin ekiyse doğrudan okunur; ses/video/
  /// görselse kayıtlı transkripti açılır, yoksa döküm başlar ve bitince nota
  /// METİN EKİ olarak kaydedilir. Ekrandan seçilen parça nota eklenir.
  Future<void> _openTranscript(
    Attachment target, {
    bool autoInsert = false,
  }) async {
    final note = _note;
    if (note == null) return;
    _dismissKeyboard();
    final Attachment? source;
    final Attachment? existing;
    if (target.kind == AttachmentKind.text) {
      existing = target;
      source = note.attachments
          .where((a) => a.id == target.transcriptOf)
          .firstOrNull;
    } else {
      source = target;
      existing = Transcripts.of(note.attachments, target);
    }
    final suffix = context.l10n.transcriptFileSuffix;
    final readOnly = _readOnly;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TranscriptScreen(
          source: source,
          transcript: existing,
          autoInsert: autoInsert,
          onSave: readOnly
              ? null
              : (text, saved) {
                  if (!mounted) return null;
                  // Ekran açıkken başka cihaz/geri al eki değiştirmiş olabilir:
                  // nottaki GÜNCEL kayıt esas alınır.
                  final current = saved == null
                      ? null
                      : _note?.attachments
                            .where((a) => a.id == saved.id)
                            .firstOrNull;
                  if (current != null) {
                    final updated = Transcripts.withText(current, text);
                    _updateAttachment(updated);
                    return updated;
                  }
                  if (source == null) return null;
                  final created = Transcripts.create(
                    source,
                    text,
                    fileSuffix: suffix,
                  );
                  _mutate(
                    (n) =>
                        n.copyWith(attachments: [...n.attachments, created]),
                    immediate: true,
                  );
                  return created;
                },
          onInsert: readOnly
              ? null
              : (text) {
                  if (mounted) _appendText(text);
                },
          onCreateNote: (text) =>
              _createNoteFromTranscript(text, source ?? target),
          onDelete: readOnly
              ? null
              : (a) {
                  if (mounted) _removeAttachment(a);
                },
        ),
      ),
    );
  }

  /// Transkriptten YENİ metin notu: başlık kaynağın adı, gövde seçilen metin,
  /// klasör bu notunki.
  Future<void> _createNoteFromTranscript(String text, Attachment media) async {
    if (!mounted) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || text.trim().isEmpty) return;
    final name = media.isWebVideo
        ? media.fileName
        : media.fileName.replaceAll(RegExp(r'\.[A-Za-z0-9]{1,5}$'), '');
    final title = context.l10n.transcriptNoteTitle(name);
    final id = await repo.createNote(
      NoteType.text,
      title: title,
      body: text.trim(),
      folderId: _note?.folderId,
    );
    if (mounted) context.pushNote(noteRoutePath(id));
  }

  /// **SES DOSYASI EKLE** — cihazdaki MP3/M4A/WAV... nota ses eki olur
  /// (kayıt yolundan ayrı: adı korunur, türü dosyadan okunur).
  Future<Attachment?> _pickAudioFile() async {
    final repo = _attachments;
    if (repo == null) return null;
    final l10n = context.l10n;
    final picked = await DocPicker.pickOne(
      const XTypeGroup(
        label: 'audio',
        mimeTypes: ['audio/*'],
        extensions: [
          'mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac', 'amr', 'webm',
        ],
      ),
      chooserTitle: l10n.addAudioFile,
    );
    if (picked == null || !mounted) return null;
    try {
      final attachment = await _runBusy(
        context.l10n.attachmentUploading,
        () => repo.prepareAudioFile(
          noteId: widget.noteId,
          sourcePath: picked.path,
          fileName: picked.name,
        ),
      );
      if (!mounted) return null;
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
      return attachment;
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
    return null;
  }

  /// **DOSYAYI METNE DÖK** — ses, video ya da görsel seçilir, nota ek olarak
  /// girer ve transkript ekranı açılır; metin bitince nota da yazılır
  /// ("onları nota dönüştürme"). Görsel sayfaya değil şeride konur: gövdeye
  /// gelen metin görselin etrafından akmasın.
  Future<void> _transcribeFile() async {
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    final picked = await DocPicker.pickOne(
      const XTypeGroup(
        label: 'media',
        mimeTypes: ['audio/*', 'video/*', 'image/*'],
        extensions: [
          'mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac', 'amr', 'webm',
          'mp4', 'mov', 'mkv', '3gp', 'jpg', 'jpeg', 'png', 'webp', 'heic',
        ],
      ),
      chooserTitle: l10n.transcriptPickTitle,
    );
    if (picked == null || !mounted) return;
    final kind = _mediaKindOf(picked.name.isEmpty ? picked.path : picked.name);
    if (kind == null) {
      _showSnack(l10n.transcriptUnsupportedFile);
      return;
    }
    try {
      final Attachment attachment;
      switch (kind) {
        case AttachmentKind.audio:
          attachment = await repo.prepareAudioFile(
            noteId: widget.noteId,
            sourcePath: picked.path,
            fileName: picked.name,
          );
        case AttachmentKind.video:
          attachment = (await repo.prepareVideo(
            noteId: widget.noteId,
            sourcePath: picked.path,
            duration: await VideoFrame.duration(picked.path),
          )).copyWith(asFile: true);
        default:
          attachment = (await repo.prepareImage(
            noteId: widget.noteId,
            bytes: await picked.readAsBytes(),
            fileName: picked.name.isEmpty ? 'gorsel.jpg' : picked.name,
          )).copyWith(asFile: true);
      }
      if (!mounted) return;
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
      await _openTranscript(attachment, autoInsert: true);
    } on FileTooLargeException catch (e) {
      if (mounted) _showSnack(_tooLargeMessage(e));
    } catch (e) {
      if (mounted) _showSnack(l10n.attachmentFailed('$e'));
    }
  }

  /// Seçilen dosyanın ek türü (uzantıdan); metne dökülemiyorsa null.
  static AttachmentKind? _mediaKindOf(String name) {
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    const audio = {
      'mp3', 'm4a', 'aac', 'wav', 'ogg', 'oga', 'opus', 'flac', 'amr',
    };
    const video = {'mp4', 'mov', 'mkv', '3gp', 'webm', 'm4v'};
    const image = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'bmp'};
    if (audio.contains(ext)) return AttachmentKind.audio;
    if (video.contains(ext)) return AttachmentKind.video;
    if (image.contains(ext)) return AttachmentKind.image;
    return null;
  }

  /// Videodan (görüntü + ses) detaylı not çıkarır ve gövdeye ekler.
  Future<void> _videoToNote(Attachment video) async {
    final repo = _attachments;
    if (repo == null) return;
    final l10n = context.l10n;
    // Satır içi gönderim sınırı: büyük video istekte reddediliyor ve hata
    // dakikalar sonra geliyordu. Sınır ÖNCEDEN, anlaşılır biçimde söylenir.
    //
    // BOYUT OKUMADAN ÖNCE (bellek — 2026-10-17): eskiden video TAMAMEN
    // belleğe okunup sonra ölçülüyordu; 300 MB'lık bir kayıt, yalnız "çok
    // büyük" demek için 300 MB ayırıyor, düşük bellekli telefonda uygulamayı
    // öldürebiliyordu. Dosyanın boyu diskten okunur.
    const maxInlineBytes = GeminiService.maxInlineMediaBytes;
    final onDisk = localFileExists(video.localPath)
        ? await File(video.localPath).length()
        : video.sizeBytes;
    if (!mounted) return;
    if (onDisk > maxInlineBytes) {
      _showSnack(l10n.videoTooBigForAi(onDisk ~/ (1024 * 1024)));
      return;
    }
    final bytes = await repo.readBytes(video);
    if (!mounted) return;
    if (bytes == null) {
      _showSnack(l10n.attachmentNotSynced);
      return;
    }
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
    final target = await showAppSheet<String>(
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
            // ÇERÇEVE GERİ GELDİ (kullanıcı isteği 2026-10-20) — yalnız ana
            // ekran kartında çizilir; alt satır bunu söyler.
            ListTile(
              leading: _colorLeading(note.frameColor, frame: true),
              title: Text(l10n.frameColor),
              subtitle: Text(l10n.frameColorInfo),
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
    // Editörde şerit CANLI çalışır: dokunulan renk anında uygulanır ve şerit
    // açık kalır (Keep davranışı). Çerçeve editörde çizilmediği için onun
    // sonucu ana ekrana dönünce kartta görünür.
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

  /// DEFTER GÖRÜNÜMÜ (F3.5): kâğıt deseni gövdenin arkasında, satır
  /// aralığı gövde metninin satır yüksekliği.
  Widget _withPaper(Note note, TextStyle bodyStyle, Widget child) {
    if (!note.paged) return child;
    final size = bodyStyle.fontSize ?? 16;
    return NotebookPaper(
      style: note.archivePaper,
      gap: size * (bodyStyle.height ?? 1.4),
      scroll: _pageScroll,
      child: child,
    );
  }

  /// Defter görünümünün kâğıt deseni: önizlemeli döşemeler, dokunuş ANINDA
  /// uygulanır ve levha açık kalır (bkz. [NotebookPaperPicker]).
  Future<void> _pickPaper() async {
    final note = _note;
    if (note == null) return;
    await showAppSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: NotebookPaperPicker(
            initial: note.archivePaper,
            onChanged: (picked) {
              if (!mounted) return;
              _mutate(
                (n) => n.copyWith(archivePaper: picked),
                immediate: true,
              );
            },
          ),
        ),
      ),
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
    await showAppSheet<void>(
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
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (file == null) return;
    bytes = await file.readAsBytes();
    name = file.name;
    final repo = _attachments;
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
  /// basınca durur. Yerleşik tanıma yoksa (web) eski alt sayfa açılır.
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
    final background = active ? scheme.primary : Colors.transparent;
    final ink = active ? scheme.onPrimary : scheme.onPrimaryContainer;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: _kToolSegment,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: ink),
                if (badge != null)
                  Positioned(
                    top: 6,
                    right: size / 2 - 17,
                    child: Icon(badge, size: 10, color: ink),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Alt çubuğun SAĞ grubu: AI + iki mikrofon tek vurgu renkli kapsülde
  /// (soldaki araç kapsülüyle aynı yükseklik ve köşe — bkz.
  /// [planEditorBar]).
  Widget _aiCapsule({
    required double segment,
    required double gap,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('editor-ai-capsule'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: scheme.primaryContainer),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            children[i],
          ],
        ],
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
  VoiceListenSession? _dictation;

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

  bool get _dictating => _dictation != null;

  /// Diktenin başladığı an (şeritteki süre sayacı).
  DateTime _dictationStart = DateTime.now();

  /// Sade mikrofon: dikteyi başlatır, açıksa bitirir.
  Future<void> _toggleDictation() async {
    if (_dictating) {
      await _stopDictation();
      return;
    }
    final l10n = context.l10n;
    // Yerleşik tanıma yoksa (web) canlı yazma mümkün değil: kullanıcı
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

    // Dinlemenin yaşam döngüsü (sessizlikte bitiş, yerli kapanış, üst
    // sınır) levhayla ORTAK oturumda (bkz. VoiceListenSession).
    late final VoiceListenSession session;
    session = VoiceListenSession(
      autoStop: () => ref.read(voiceAutoStopProvider),
        preferOffline: ref.read(voiceOfflineProvider),
        gate: SilenceGate(afterSpeech: ref.read(voiceSilenceProvider).duration),
      onText: (text) {
        if (mounted && identical(_dictation, session)) {
          _writeDictationAtCaret(text);
        }
      },
      // Sessizlik ya da yerli kapanış bir hata değil, bitiştir: yazılan
      // metin zaten notta.
      onEnd: (_) => unawaited(_stopDictation()),
      onError: (message) {
        unawaited(_stopDictation());
        if (mounted) _showSnack(message);
      },
    );
    setState(() {
      _dictation = session;
      _dictationStart = DateTime.now();
    });
    session.start();
  }

  /// Dikteyi bitirir: akış kapatılır, şerit iner, metin olduğu gibi kalır.
  Future<void> _stopDictation() async {
    final sub = _dictation;
    if (sub == null) return;
    _dictation = null;
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
    // AKILLI KOMUTLAR: birleştirme HAM metin üstünde yapılır (geriye gitmeme
    // kuralı silme komutunu yutmasın), komutlar sonra uygulanır — "son
    // kelimeyi sil" söylenince aralık kısalır, yazma yine en sondan sürer.
    var written = merged;
    if (ref.read(voiceSmartCommandsProvider)) {
      final outcome = applyVoiceCommands(merged);
      written = outcome.text;
      if (outcome.stop) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_stopDictation()),
        );
      }
    }
    // Yazma kuralının kendisi saf bir işlevde (sınanabilsin diye). Komutlar
    // her şeyi sildiyse ("hepsini sil") aralık boşaltılır — dictationReplace
    // boş parçada metne dokunmaz.
    final start = _dictationAt.clamp(0, logical.length);
    final result = written.trim().isEmpty
        ? (
            text: logical.replaceRange(
              start,
              (start + _dictationLength).clamp(start, logical.length),
              '',
            ),
            caret: start,
            length: 0,
          )
        : dictationReplace(logical, _dictationAt, _dictationLength, written);
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

    // "başlık X olsun" söylendiyse notun başlığı olur (açıkça istendiği için
    // var olan başlığın yerine geçer).
    final spokenTitle = result.title;
    if (spokenTitle != null) {
      _titleController.text = spokenTitle;
      _mutate((n) => n.copyWith(title: spokenTitle), immediate: true);
    }

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
    _aiTaskN.value = l10n.aiThinking;
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
      if (mounted) _aiTaskN.value = null;
    }
  }

  /// Sesli yakalama levhasından dönen (dökümü yapılamamış) kaydı nota ek olarak
  /// bağlar. Yol levhadan devralınır: burada kullanılmazsa dosya silinir.
  Future<void> _attachVoiceAudio(String path, Duration duration) async {
    final repo = _attachments;
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

  // Keep tarzı sesli not (`_startVoiceCapture`: Google'ın tanıma EKRANI,
  // metin + Google'ın kaydettiği AMR ses) 2026-10-19 sadeleştirmesinde
  // kaldırıldı. Dördüncü bir arayüzdü ve tek getirisi düşük kaliteli ses
  // dosyasıydı; `?voice=1` artık ortak levhayı açar. (Kotlin'deki
  // `voiceInputWithAudio` köprüsü kullanılmıyor; bir sonraki APK turunda
  // derlenerek sökülecek.)

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
    // Drive'dan bir ek inince editör yeniden çizilir: ekranlar yerel
    // kopyayı çizim anında arıyor (bkz. localFilesRevisionProvider).
    ref.watch(localFilesRevisionProvider);
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
        if (!a.floatsOnPage &&
            !_inPinnedPane(note!, a) &&
            !note.hidesDerivedDocument(a))
          a,
    ];
    final isDocumentNote =
        note != null &&
        (note.type == NoteType.pdf || note.type == NoteType.slides);
    // Ataç rozeti: sayı ARTTIYSA yanıp söner (bkz. [_pulseAttachBadge]).
    // Build sırasında animasyon başlatmak güvenli değil — bir kareye
    // ertelenir.
    // Yalnız sayı DEĞİŞİNCE (F2.7): eskiden her build bir kare-sonrası
    // geri çağrısı planlıyordu.
    if (note != null && fileAttachments.length != _lastAttachmentCount) {
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
    // Denetleyici beslemeleri YALNIZ not ya da tema parlaklığı değişince
    // (F2.7): build başka nedenlerle de koşuyor (odak, klavye, biçim
    // çubuğu) ve her seferinde ad listesi + çip görünümleri baştan
    // kuruluyordu.
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!identical(note, _fedNote) || dark != _fedDark) {
      _fedNote = note;
      _fedDark = dark;
      _bodyController.attachmentNames = [
        for (final link in note.tagLinks)
          if (link.label.isNotEmpty) link.label,
        for (final a in note.attachments) a.fileName,
      ];
      // Gömülü yazının ÇİP görünümü: ekin türüne göre renk ve rozet (bkz.
      // AttachmentTagChips). Denetleyici renkleri yalnız değişince alır.
      final tagLooks = embedTagLooks(note, dark: dark);
      _tagLooks = tagLooks;
      _bodyController.tagChipColors = {
        for (final e in tagLooks.entries) e.key: e.value.color,
      };
      // Notta video varken "1:23" gibi damgalar bağlantı gibi çizilir ve
      // dokununca video oraya gider (bkz. video_time.dart).
      _bodyController.videoTimestamps = _hasVideo(note);
    }
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
        readOnly: _readOnly,
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
      // YENİ SAYFA BURADA (kullanıcı isteği 2026-10-11: "yeni sayfa ekleyi
      // üst alana koyabilir miyiz"). "Ekle" levhasının en üst bölümündeydi;
      // ama sayfa notun İÇERİĞİ değil YAPISI — başlığın yanındaki bu menü
      // (hatırlatıcı, klasör, etiket: notun kendisine dair olanlar) onun
      // doğal yeri. Sayfalar arası geçiş de hemen altındaki çubukta.
      if (!note.type.isPageNoteType) ...[
        PopupMenuItem(
          value: 'new-page',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.note_add_outlined),
            title: Text(l10n.archiveNewPage),
          ),
        ),
        const PopupMenuDivider(height: 8),
      ],
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
          case 'new-page':
            _addPage();
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
        avatar: ValueListenableBuilder<bool>(
          valueListenable: _titleGeneratingN,
          builder: (context, generating, _) => generating
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add, size: 16),
        ),
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

    // BALONLU ⇄ KLASİK görünüm çipleri buradaydı (başlığın altında, etiket ve
    // klasör çipleriyle aynı kayan şeritte). Kullanıcı bulgusu 2026-10-16:
    // "kolay geçişin yeri ve düzeni iyi değil". Görünüm artık EKİN YANINDA
    // tek bir üçlü anahtar (Sabit / Yüzen / Balonlu — bkz.
    // view_mode_switch.dart); balonlu görünümde başlık satırının sağında.
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
    // Şerit kişiselleştirmede gizlenebilir (bkz. UiItem.editorTags).
    final metaChips = metaChildren.isEmpty
        ? const SizedBox.shrink()
        : Customizable(
            id: UiItem.editorTags,
            badgeInset: 8,
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: _kGutter),
                itemCount: metaChildren.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) =>
                    Align(alignment: Alignment.center, child: metaChildren[i]),
              ),
            ),
          );

    // Başlık satırı: alan + sağ kenarda "+" (ekleme/öneri menüsü). Balonlu
    // görünümde belgenin görünüm anahtarı da burada — not başlığının
    // hemen yanında, sayfa çubuğunu kalabalıklaştırmadan.
    // Bölmedeki belge: türü notun türüyle aynı OLAN ilk ek (sunum notunda
    // sunum, PDF notunda PDF — bkz. [_viewOf]).
    final bubbleDocument = note.type.isPageNoteType
        ? note.attachments
              .where(
                (a) =>
                    a.kind ==
                    (note.type == NoteType.slides
                        ? AttachmentKind.slide
                        : AttachmentKind.pdf),
              )
              .firstOrNull
        : null;
    final bubbleSwitch = bubbleDocument == null
        ? null
        : _viewSwitchFor(note, bubbleDocument, dense: true);
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleField),
        if (bubbleSwitch != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: bubbleSwitch,
          ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 10),
          child: actionsMenu,
        ),
      ],
    );

    // Sayfada yüzen görseller ve videolar: "ek olarak" işaretlenenler buraya
    // girmez, alt şeritte dosya eki olarak durur (bkz. Attachment.asFile).
    // SAYFALI NOT: yalnız ETKİN sayfanın görselleri (bkz. Note.textPages —
    // ilk sayfanınki bölümsüz '').
    final imageAttachments = [
      for (final a in note.attachments)
        if (a.floatsOnPage &&
            a.id != note.backgroundImageId &&
            a.section == note.activePage &&
            !note.hidesDerivedDocument(a))
          a,
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
      children: [
        titleRow,
        metaChips,
        if ((note.textPages.isNotEmpty || note.paged) &&
            !note.type.isPageNoteType)
          _pageBar(note),
      ],
    );

    // Gövde metin alanı: saf metin modunda ve karışık (metin+madde) modda
    // aynı controller/focus'u paylaşır. Madde varken kısalır (2 satır tabanı).
    // `Builder`: dokunuşta alanın KENDİ EditableText'i bulunur (başlığınki
    // değil); sarmalayıcı dokunuşun konumunu tutar (bkz. [_tappedEmbed]).
    final bodyField = Builder(
      builder: (fieldContext) => AttachmentTagChips(
        controller: _bodyController,
        looks: _tagLooks,
        child: _bodyTapPoint.wrap(
        TextField(
          controller: _bodyController,
          focusNode: _bodyFocus,
          readOnly: _readOnly,
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
          // YENİ (gömme yeniden tasarımı): tam ekran yerine YERİNDE önizleme
          // kartı; yalnız dokunuş etiketin İÇİNE düşünce (yanına imleç koymak
          // yazmaya devam etmektir, önizleme açmaz).
          onTap: () {
            final editable = editableTextBelow(fieldContext);
            final seconds = _tappedTimestamp(editable);
            if (seconds != null) {
              editable?.hideToolbar();
              _seekVideoTo(seconds);
              return;
            }
            final tapped = _tappedEmbed(editable);
            if (tapped != null) {
              // Dokunuşun açtığı Yapıştır menüsü önizlemenin altında kalmasın.
              editable?.hideToolbar();
              _showEmbedPreviewFor(tapped.attachment, tapped.label);
            }
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
        ),
        // Damgaya/etikete dokunmak klavyeyi AÇMAZ (bkz. TapPointTracker.wrap).
        focusNode: _bodyFocus,
        keepsKeyboardClosed: (global) => linkAtPoint(
          editable: editableTextBelow(fieldContext),
          displayText: _bodyController.text,
          global: global,
          timestamps: _note != null && _hasVideo(_note!),
          tagNames: _bodyController.attachmentNames,
        ),
        ),
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
        tagLooks: _tagLooks,
        onAttachmentTag: _openTagByName,
        selectionMenu: _itemSelectionMenu,
        videoTimestamps: _bodyController.videoTimestamps,
        onVideoTimestamp: _seekVideoTo,
        addRowTrailing: _partsMenu(note),
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
        tagLooks: _tagLooks,
        onAttachmentTag: _openTagByName,
        selectionMenu: _itemSelectionMenu,
        videoTimestamps: _bodyController.videoTimestamps,
        onVideoTimestamp: _seekVideoTo,
        addRowTrailing: _partsMenu(note),
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
    final pageBody = note.type.isPageNoteType
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
    // Oynatıcılar (sabit bölme, sayfadaki video kutuları) notun video
    // merkezine buradan ulaşır (bkz. VideoHubScope).
    final body = VideoHubScope(
      hub: _videoHub,
      child: _withPinnedMedia(note, pageBody),
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
                      if (!a.floatsOnPage &&
                          !_inPinnedPane(note, a) &&
                          !note.hidesDerivedDocument(a))
                        a,
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
                  // GÖRÜNÜM ANAHTARI her döşemede (Sabit / Yüzen / Balonlu
                  // / Ek). "Yüzen" belge notunda önce klasiğe döner, sonra
                  // eki sayfaya koyar — eskiden buradaki "sayfaya koy"
                  // düğmesi belge notunda eki sayfası olmayan bir yere
                  // taşıyıp KAYBEDİYORDU (bkz. _setAttachmentView).
                  viewOf: _readOnly ? null : (a) => _viewOf(note, a),
                  onSetView: _readOnly
                      ? null
                      : (a, view) => unawaited(_setAttachmentView(a, view)),
                  onVideoToNote: _videoToNote,
                  onTranscribe: _openTranscript,
                  foreign: widget.ownerId != null,
                  expanded: ref.watch(attachmentsExpandedProvider),
                  onToggle: () => ref
                      .read(attachmentsExpandedProvider.notifier)
                      .toggle(),
                  // Alt çubuktaki ataç kişiselleştirmede gizlendiyse şerit
                  // kapalıyken kendi ince tutamağını gösterir — açmanın
                  // yolu hiç kaybolmasın.
                  collapsedHandle: !Personalize.current.shows(
                    UiItem.barAttachments,
                  ),
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
                ValueListenableBuilder<String?>(
                  valueListenable: _aiTaskN,
                  builder: (context, task, _) => task == null
                      ? const SizedBox.shrink()
                      : _AiBanner(label: task),
                ),
                // CANLI DİKTE şeridi: mikrofon açıkken kaçırılamayacak bir
                // gösterge (aynı gerekçe — açık kalmış mikrofon fark
                // edilmiyordu). Dokunmak dikteyi bitirir.
                if (_dictating)
                  _DictationPanel(
                    start: _dictationStart,
                    onStop: () => unawaited(_stopDictation()),
                  ),
                // Dosya işleri (kopyalama/yapıştırma) için aynı şerit,
                // ayrı simge: sessiz bekleme bitti (bkz. [_busyTaskN]).
                ValueListenableBuilder<String?>(
                  valueListenable: _busyTaskN,
                  builder: (context, busy, _) => busy != null
                      // Web'de ek DOĞRUDAN yükleniyor: oran şeride yüzde
                      // olarak.
                      ? ValueListenableBuilder<double?>(
                          valueListenable:
                              AttachmentRepository.directUploadProgress,
                          builder: (context, fraction, _) => _AiBanner(
                            label: fraction == null
                                ? busy
                                : '$busy ${formatUploadPercent(context, fraction)}',
                            icon: Icons.sync,
                            progress: fraction,
                          ),
                        )
                      // Arka planda buluta çıkan ekler (kullanıcı bulgusu
                      // 2026-10-17: "ek yüklerken sessizlik var"): şerit
                      // kapalı ya da ek sayfaya gömülüyken de görünür bir iz.
                      : _NoteUploadsBanner(attachments: note.attachments),
                ),
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
                else ...[
                // İnce ayraç: kaydırılan metnin son satırı çubuğun hemen
                // üstünde YARIM kesiliyordu ve çubuk sayfanın parçası gibi
                // görünüyordu (kullanıcının 2026-10-11'de işaretlediği alt
                // alan).
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                BottomAppBar(
                  color: background,
                  height: 64,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  // KİŞİSELLEŞTİRME (kullanıcı isteği 2026-10-16): her
                  // düğme gizlenebilir; düzenleme modunda hepsi çerçeveli
                  // görünür ve dokunmak gizle/göster yapar (bkz.
                  // Customizable). Çubuk yalnız bu tercihleri dinler.
                  child: ListenableBuilder(
                    listenable: Personalize.listenable,
                    builder: (context, _) => LayoutBuilder(
                    builder: (context, constraints) {
                      final editingUi = Personalize.editing;
                      final uiPrefs = Personalize.current;
                      bool on(String id) => editingUi || uiPrefs.shows(id);
                      final showFormat = on(UiItem.barFormat);
                      final showAdd = on(UiItem.barAdd);
                      final showSelect =
                          !note.type.isPageNoteType &&
                          note.items.isNotEmpty &&
                          on(UiItem.barSelect);
                      final showAttachments =
                          fileAttachments.isNotEmpty &&
                          on(UiItem.barAttachments);
                      final showAi = on(UiItem.barAi);
                      // "AI ile sesli not" ÇUBUKTAN KALKTI (kullanıcı isteği
                      // 2026-10-20: "AI sesli notu AI menüsünün üzerine
                      // alalım, ana çubukta doğrudan yazma olsun"): yapay
                      // zekâ levhasının en üst satırında. Çubukta iki
                      // mikrofon (parıltılı + düz) yan yana neyin ne
                      // olduğunu karıştırıyordu.
                      // Dikte SÜRERKEN düğme gizlenmez — durdurma yolu kalsın.
                      final showDictation =
                          _dictating || on(UiItem.barDictation);
                      final aiCount = [
                        showAi,
                        showDictation,
                      ].where((v) => v).length;
                      // Genişliğe göre plan: taşma/kesik kapsül yerine önce
                      // düğmeler küçülür, sonra ⋮ menüsünde de bulunan
                      // Ara/Paylaş kapsülden çıkar (bkz. planEditorBar).
                      final plan = planEditorBar(
                        width: constraints.maxWidth,
                        fixedSegments:
                            (showFormat ? 1 : 0) +
                            (showAdd ? 1 : 0) +
                            (showSelect ? 1 : 0),
                        attachments: showAttachments,
                        pen: isDocumentNote,
                        aiButtons: aiCount,
                      );
                      final showSearch =
                          plan.search && on(UiItem.barSearch);
                      final showShare = plan.share && on(UiItem.barShare);
                      // Biçim · Ekle · Seç · Ara · Paylaş · Ekler. Gerekçeler:
                      // "Metin/Liste ekle" Ekle levhasında (attach_sheet);
                      // SEÇ burada (2026-08-09), simgesi `select_all`
                      // (2026-09-01: `checklist` "liste ekle" ile
                      // karışıyordu), madde yoksa gizli; ARA ve PAYLAŞ alt
                      // çubukta (2026-09-01) ve ⋮ menüsünde de; EKLER şeridin
                      // aç/kapası (2026-08-08).
                      final segments = <Widget>[
                        if (showFormat)
                          Customizable(
                            id: UiItem.barFormat,
                            child: _toolSegment(
                              icon: Icons.text_format,
                              label: l10n.formatTitle,
                              active: _formatBarOpen,
                              onTap: () => setState(
                                () => _formatBarOpen = !_formatBarOpen,
                              ),
                            ),
                          ),
                        if (showAdd)
                          Customizable(
                            id: UiItem.barAdd,
                            child: _addToolButton(l10n),
                          ),
                        // EKLER Ekle'nin hemen YANINDA (kullanıcı bulgusu
                        // 2026-10-17: "alttaki ek alanı göster gizle
                        // yapılamıyor"): kapsülün SONUNDAYKEN dar ekranda
                        // yatay kaydırmanın dışında kalıyor, görünmüyordu.
                        if (showAttachments)
                          Customizable(
                            id: UiItem.barAttachments,
                            child: _attachmentsToggle(
                              l10n,
                              fileAttachments.length,
                            ),
                          ),
                        if (showSelect)
                          Customizable(
                            id: UiItem.barSelect,
                            child: _toolSegment(
                              icon: Icons.select_all,
                              label: l10n.select,
                              onTap: () => _itemsEditorKey.currentState
                                  ?.startSelection(),
                            ),
                          ),
                        if (showSearch)
                          Customizable(
                            id: UiItem.barSearch,
                            child: _toolSegment(
                              icon: Icons.search,
                              label: l10n.noteSearchTitle,
                              onTap: _openNoteSearch,
                            ),
                          ),
                        if (showShare)
                          Customizable(
                            id: UiItem.barShare,
                            child: _toolSegment(
                              icon: Icons.share_outlined,
                              label: l10n.share,
                              onTap: () => unawaited(_share()),
                            ),
                          ),
                      ];
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
                                    for (var i = 0;
                                        i < segments.length;
                                        i++) ...[
                                      if (i > 0) const SizedBox(width: 3),
                                      segments[i],
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
                          // AI + SES TEK KAPSÜLDE (kullanıcı isteği
                          // 2026-10-11: "işaretli alanlar mantıklı biçimde
                          // düzenlenmeli"). Üç ayrı gölgeli kare düğme
                          // çubuğun yarısını kaplıyor, soldaki araç
                          // kapsülüyle iki farklı dil konuşuyordu. Şimdi
                          // çubuk İKİ GRUP: solda düzenleme araçları (yüzey
                          // renginde), sağda yapay zekâ ve ses (vurgu
                          // renginde). Parıltı = AI levhası (en üst satırı
                          // "AI ile sesli not", 2026-10-20), sade mikrofon =
                          // doğrudan yazdırma (bkz. [_toggleDictation]).
                          if (aiCount > 0)
                            _aiCapsule(
                              segment: plan.button,
                              gap: plan.gap,
                              children: [
                                if (showAi)
                                  Customizable(
                                    id: UiItem.barAi,
                                    child: _voiceButton(
                                      size: plan.button,
                                      tooltip: l10n.aiTitle,
                                      icon: Icons.auto_awesome,
                                      onTap: () => showAiSheet(
                                        context,
                                        note,
                                        onAppendText: _appendText,
                                        onReplaceText: _replaceText,
                                        onCreateNote: _createNoteFromText,
                                        onTranscribe: _openTranscript,
                                        onVoiceNote: _captureVoice,
                                      ),
                                    ),
                                  ),
                                if (showDictation)
                                  Customizable(
                                    id: UiItem.barDictation,
                                    child: _voiceButton(
                                      size: plan.button,
                                      tooltip: l10n.liveDictation,
                                      icon: _dictating
                                          ? Icons.stop
                                          : Icons.mic,
                                      active: _dictating,
                                      onTap: () =>
                                          unawaited(_toggleDictation()),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                  ),
                ),
                ],
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
                : Customizable(
                    id: UiItem.editorDate,
                    child: Row(
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
                      // Yıldızlı göstergesi tarihin yanında; dokununca
                      // yıldız kalkar (menüye gitmeden geri alınabilsin).
                      if (note.starred)
                        IconButton(
                          tooltip: l10n.unstar,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                          onPressed: () => _mutate(
                            (n) => n.copyWith(starred: false),
                            immediate: true,
                          ),
                        ),
                    ],
                  ),
                  ),
            actions: [
              // Ortak notta başka biri düzenliyorsa (F4.1).
              NotePresenceIndicator(
                noteId: widget.noteId,
                ownerId: widget.ownerId,
              ),
              // KÖK NEDEN (kasma): bu akış `build`'in en başında izleniyordu.
              // `pendingWrites` her kayıtta false→true→false gidiyor, yani
              // yazarken (debounce 0,5 sn / en geç 3 sn) düzenli aralıklarla
              // 4000 satırlık editör build'i BAŞTAN koşuyordu — üstelik
              // tetikleyici Riverpod olduğu için `_mutate`'in "saf yazım"
              // kısayolu ve akış yankısı koruması ikisi de devreye giremiyordu.
              // Abonelik artık yalnız BU İKONA ait.
              Customizable(
                id: UiItem.topSync,
                child: Padding(
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
              // SIRA (2026-10-11 düzeni): önce DÜZENLEME geçmişi (geri al /
              // yinele, yan yana), sonra notun durumu (sabitle, ortak
              // çalışan), en sağda ⋮. Eskiden geri al, raptiye ile hesap
              // makinesinin arasına sıkışmıştı.
              Customizable(
                id: UiItem.topUndo,
                child: IconButton(
                  tooltip: l10n.undo,
                  icon: const Icon(Icons.undo),
                  onPressed: _canUndo ? _undo : null,
                ),
              ),
              // Yinele yalnız kullanılabilirken görünür: yanlış "Geri al"dan
              // dönüş yolu. Sürekli görünse araç çubuğunda ölü yer kaplardı.
              if (_canRedo)
                IconButton(
                  tooltip: l10n.redo,
                  icon: const Icon(Icons.redo),
                  onPressed: _redo,
                ),
              Customizable(
                id: UiItem.topCollab,
                child: Consumer(
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
              ),
              Customizable(
                id: UiItem.topPin,
                child: IconButton(
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
              ),
              // HESAP MAKİNESİ ⋮ menüsünün hızlı satırında (2026-10-11):
              // üst çubuk notun DURUMUNA ayrıldı — geri al/yinele, sabitle,
              // ortak çalışan. Araçlar ⋮'te ve alt çubukta.
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
                      // ÇERÇEVE EDİTÖRDE ÇİZİLMEZ (kullanıcı isteği
                      // 2026-10-20: "çerçeve sadece dashboarda görünsün"):
                      // notun içi sade kalır, renk kartta görünür.
                      child: _withBackground(
                        note,
                        bgImage,
                        _withPaper(note, noteBodyStyle, body),
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
