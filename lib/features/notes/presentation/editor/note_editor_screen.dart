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
import 'package:flutter/gestures.dart' show PointerDeviceKind;
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
import '../../../../app/theme/note_themes.dart';
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
import '../../../../core/widgets/scale_settle.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../data/attachment_save.dart';
import '../../data/note_shortcut.dart';
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
import '../../domain/archive_paper.dart';
import '../../domain/list_convert.dart';
import '../../domain/note_item.dart';
import '../../domain/note_type.dart';
import '../../domain/page_notes.dart';
import '../collaborators_sheet.dart';
import '../color_picker_sheet.dart';
import '../note_theme_sheet.dart';
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
import 'voice_note_recorder.dart';
import 'calculator_sheet.dart';
import '../../data/place_reminders.dart';
import '../../data/drive_store.dart' show localFilesRevisionProvider;
import '../drive_ui.dart';
import '../place_reminder_sheet.dart';
import 'drawing_screen.dart';
import 'editor_bar_layout.dart';
import 'format_bar.dart';
import 'format_menu.dart';
import 'ink_gestures.dart';
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
import 'note_find_controller.dart';
import 'note_search_sheet.dart';
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
import '../viewers/ink_tools.dart';
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
import 'page_swipe.dart';
import '../../../../core/widgets/smooth_routes.dart';
import '../../../../core/widgets/app_sheet.dart';

part 'note_editor_actions.dart';
part 'note_editor_ai.dart';
part 'note_editor_appearance.dart';
part 'note_editor_attachments.dart';
part 'note_editor_find.dart';
part 'note_editor_gestures.dart';
part 'note_editor_media_view.dart';
part 'note_editor_parts.dart';
part 'note_editor_toolbar.dart';
part 'note_editor_voice.dart';

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
        // Madde altı ayırıcı çizgi de satırda çiziliyor.
        x.divider != y.divider ||
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
      a.lineSpacing != b.lineSpacing ||
      a.color != b.color ||
      a.frameColor != b.frameColor ||
      a.customColor != b.customColor ||
      a.customFrameColor != b.customFrameColor ||
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
      a.theme != b.theme ||
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
        // Görselin altındaki açıklama ve sesin dalgası da kutuda çizilir.
        x.caption != y.caption ||
        !_sameInts(x.wave, y.wave) ||
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

  /// `setState` konu dosyalarındaki uzantılardan (F9.3) — orada korumalı
  /// üyeye doğrudan erişilemez.
  void _update(VoidCallback fn) => setState(fn);

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

  /// Biçim paneli ⇄ alt çubuk geçişinin süresi (ikisi aynı eğriyle).
  static const _kBarSwap = Duration(milliseconds: 260);

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

  /// [_formatTarget]in dinlenebilir eşi: alt çubuktaki etkin biçim rozetleri
  /// ([ActiveFormatBadges]) odak değişimini editörü yeniden kurmadan izler.
  final _formatTargetN = ValueNotifier<FormatTarget?>(null);

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
    // Bildirim build'den sonra (bu kapanış build sırasında da gelebilir).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formatTargetN.value = _formatTarget;
    });
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
    if (changed) _formatTargetN.value = _formatTarget;
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

  /// **TÜMÜNE / MADDEYE UYGULA** (biçim paneli, kullanıcı isteği
  /// 2026-10-28): imleçte etkin olan biçimler ([carried] — bekleyenler dahil)
  /// alanın TAMAMINA yazılır, alanın tamamı seçili kalır: sonraki her biçim
  /// dokunuşu da bütün metne (maddede bütün maddeye) işler. Başlık düzeyi
  /// taşınmaz — satır başına anlamlı, tüm metni başlık yapmak istenmez.
  void _applyToAll(RichMark carried) {
    final target = _formatTarget;
    if (target == null) return;
    final c = target.controller;
    if (c.text.isEmpty) return;
    unawaited(HapticFeedback.selectionClick());
    // Bekleyen biçim zaten [carried]da; imleçte boş işaret bırakmasın.
    c.clearPendingFormat();
    c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
    final whole = activeRichFormats(c);
    var changed = false;
    void all() =>
        c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
    for (final (on, already, format) in [
      (carried.bold, whole.bold, RichFormat.bold),
      (carried.italic, whole.italic, RichFormat.italic),
      (carried.underline, whole.underline, RichFormat.underline),
    ]) {
      if (!on || already) continue;
      all();
      changed |= applyRichFormat(c, format);
    }
    for (final (index, current, format) in [
      (carried.color, whole.color, RichFormat.color),
      (carried.highlight, whole.highlight, RichFormat.highlight),
    ]) {
      if (index == null || index == current) continue;
      all();
      changed |= applyRichFormat(c, format, colorIndex: index);
    }
    for (final (index, current, format) in [
      (carried.size, whole.size, RichFormat.size),
      (carried.opacity, whole.opacity, RichFormat.opacity),
    ]) {
      if (index == null || index == current) continue;
      all();
      changed |= applyRichStep(c, format, index);
    }
    all();
    if (changed) target.commit();
    if (!target.focusNode.hasFocus) target.focusNode.requestFocus();
  }

  /// Renk/vurgu paletindeki "Kaldır": yalnız o biçmi düşürür (bkz.
  /// [removeRichFormat] — geri dönüşün keşfedilebilir tek yolu).
  void _removeFormat(RichFormat format) =>
      _runOnTarget((c) => removeRichFormat(c, format));

  /// Biçim panelinin hedefi bir MADDE alanıysa o maddenin kimliği.
  String? get _formatItemId {
    final controller = _formatTarget?.controller;
    if (controller == null ||
        identical(controller, _bodyController) ||
        _titleIsTarget) {
      return null;
    }
    return _itemsEditorKey.currentState?.itemIdForController(controller);
  }

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
      _note = _repairOrphanDocumentMode(cached);
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
            : _repairOrphanDocumentMode(incoming);
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
        // boş; birleştirme onları ağır veriye tercih ederdi. Kaydedilmemiş yerel
        // ek değişikliği varsa liste yerel kalır (F5.6, `hydrateAttachments`).
        final hydrating = incoming.heavyLoaded && !previous.heavyLoaded;
        Note merged;
        {
          merged = previous.copyWith(
            heavyRef: incoming.heavyRef,
            heavyLoaded: previous.heavyLoaded || incoming.heavyLoaded,
            attachments: hydrating
                ? hydrateAttachments(
                    local: previous.attachments,
                    incoming: incoming.attachments,
                    localPending: _debouncer.hasPending,
                  )
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
            customColor: incoming.customColor,
            clearCustomColor: incoming.customColor == null,
            customFrameColor: incoming.customFrameColor,
            clearCustomFrameColor: incoming.customFrameColor == null,
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
            lineSpacing: incoming.lineSpacing,
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
    // Kayıt sürerken ekran beklenmedik biçimde kapandıysa (geri tuşu kaydı
    // önce bitirir — bkz. PopScope) mikrofon açık kalmasın.
    final recorder = _voiceRecorder;
    if (recorder != null) {
      _voiceRecorder = null;
      unawaited(recorder.cancel().whenComplete(recorder.dispose));
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
    // Kapanıştaki son kayıttan SONRA: depodaki oturum kayıtları (F6.2).
    _notesRepo?.releaseNote(widget.noteId);
    _loadGuard?.cancel();
    _debouncer.dispose();
    _sub?.close();
    _titleController.dispose();
    _formatTargetN.dispose();
    _titleFocus.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
    _pageScroll.dispose();
    _find.dispose();
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
      a.lineSpacing == b.lineSpacing &&
      a.frameColor == b.frameColor &&
      a.customColor == b.customColor &&
      a.customFrameColor == b.customFrameColor &&
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
      a.theme == b.theme &&
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

  /// Belge (balonlu) notunun belgesi kalmadıysa not METİN notuna döner.
  ///
  /// KÖK NEDEN (kullanıcı bulgusu 2026-10-30): PDF balonlu kipe alınıp ek
  /// olarak silinince not `NoteType.pdf` kalıyordu; belge bölmesi boş,
  /// gövde/maddeler çizilmiyordu ("PDF eklenmeden yazılar görülmüyor").
  /// Kipler birleştiği için belgesiz belge notu diye bir hâl YOK: tek
  /// boğaz noktası burası (+ açılış, bkz. [_repairOrphanDocumentMode]).
  static Note _withoutOrphanDocumentMode(Note n) {
    if (!n.type.isPageNoteType || n.hasModeDocument) return n;
    return n.copyWith(type: NoteType.text, classicDocument: true);
  }

  /// Açılışta belgesiz belge notu onarılır — "PDF/sunum ekle" niyetiyle
  /// açılan boş not HARİÇ (belge seçiciden birazdan gelecek).
  Note _repairOrphanDocumentMode(Note n) {
    if (widget.startPdf || widget.startSlides) return n;
    return _withoutOrphanDocumentMode(n);
  }

  void _mutate(Note Function(Note) transform, {bool immediate = false}) {
    final note = _note;
    if (note == null) return;
    final wasUndo = _undoStack.canUndo;
    final wasRedo = _undoStack.canRedo;
    // Tek boğaz noktası: sarma çapaları düzenleme tamponunda yaşar, nota
    // asla yazılmaz. Gövde hangi yoldan gelirse gelsin burada temizlenir —
    // her çağrı yerine ayrı koruma koymak yerine tek yerde.
    // Belgeyi SİLEN değişiklik belge kipini de kaldırır (boş "PDF ekle"
    // notunda belge henüz gelmedi — o yüzden yalnız kaybolunca).
    final raw = transform(note);
    final transformed = note.hasModeDocument
        ? _withoutOrphanDocumentMode(raw)
        : raw;
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

  /// Eşleşmeler ve odak (F9.3): çubuk bunu dar builder'la dinler.
  final _find = NoteFindController();
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

  /// Jest kipi (bkz. note_editor_gestures.dart): maddelere jest ya da
  /// "Buraya bağla"da daire çizme.
  _GestureMode _gestureMode = _GestureMode.off;

  /// Maddeye çizilen jestin izi (bkz. `_trackGestureDown`).
  int _contentPointers = 0;
  int? _gesturePointer;
  List<Offset> _gesturePoints = [];
  Duration? _gestureStartedAt;
  Duration? _gestureMovedAt;
  double? _gestureScrollStart;
  TextSelection? _gestureSelectionStart;

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

  /// Levha açılırken alınan seçim anlık görüntüsü (bkz. [_showAttachMenu]).
  TextSelection? _selectionSnapshot;

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

  /// Nottan çıkarılan ama BAYTLARI henüz silinmemiş ekler.
  ///
  /// Dosya eskiden ek nottan çıkarılır çıkarılmaz siliniyordu; "Geri al" ile
  /// geri gelen ek bu yüzden boş bir yer tutucu olurdu. Silme editörden
  /// çıkarken yapılır: o an nota geri dönmemiş olanlar gerçekten gider.
  final _pendingAttachmentDeletes = <Attachment>[];

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
    required Note note,
    required TextStyle bodyStyle,
  }) => SingleChildScrollView(
    controller: _pageScroll,
    padding: const EdgeInsets.only(bottom: 96),
    child: _withRuledLines(note, bodyStyle, NotePageCanvas(
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
    )),
  );

  /// Belge notunda bir BALONA yazılıyor: editörün alt çubuğu gizlenir.
  bool _immersiveBubble = false;

  /// PDF/sunum sayfasının ÜZERİNE yazma kipi (alt çubuktaki kalem düğmesi).
  /// Tam ekrana geçmeden bölmede çizim yapılır; kip açıkken tek parmak çizer,
  /// iki parmak gezinir (kullanıcı isteği 2026-08-08).
  bool _penMode = false;

  /// Kalem dokunuşu el yazısı tuvalini açıyor (ikinci dokunuş ikinci tuval
  /// açmasın — bkz. [_onContentPointerDown]).
  bool _stylusOpening = false;

  void _setImmersiveBubble(bool value) {
    if (_immersiveBubble == value || !mounted) return;
    setState(() => _immersiveBubble = value);
  }

  final _titleGeneratingN = ValueNotifier<bool>(false);

  /// Görüntülü not: kamerayla video çeker ve nota ek yapar. Video buluta
  /// GİTMEZ, yalnızca cihazda kalır (kullanıcı isteği).
  ///
  /// Süre sınırı 60 sn'den 10 dk'ya (ses kaydıyla aynı) çıktı (2026-10-17):
  /// 60 sn, videonun BÜTÜNÜYLE AI'a satır içi gönderilebilmesi içindi. Artık
  /// transkript yalnız SES İZİNİ gönderiyor (Android'de ayrılır, dakikası
  /// ~1 MB); "Videodan not çıkar" ise boyutu kendisi denetleyip büyük videoda
  /// açıkça uyarıyor. Uzun ders/toplantı kaydı 60 sn'de kesiliyordu.
  static const _maxVideoSeconds = 600;

  /// GALERİDEN video (kullanıcı isteği 2026-10-11: "not içerisine video
  /// koyma"). Kamera yolu gibi cihazda kalır ve sayfaya yerleşir; süre
  /// sınırı YOK (o sınır yalnız AI'a gönderim içindi — uzun videoda
  /// "videodan not çıkar" boyut uyarısını kendisi verir).
  static const _videoExtensions = ['mp4', 'mov', 'mkv', '3gp', 'webm'];

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

  /// Notun içinde süren SESLİ NOT kaydı (alt şeritteki hap; bkz.
  /// [VoiceRecordPanel], `_recordAudio`).
  VoiceNoteRecorder? _voiceRecorder;

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

  /// Diktenin başladığı an (şeritteki süre sayacı).
  DateTime _dictationStart = DateTime.now();

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

  /// **☑ ONAY KUTUSU — KOLAY EKLE / KALDIR** (kullanıcı isteği 2026-10-28,
  /// örnek uygulamadaki alt çubuk): imleç GÖVDEDEYSE bulunduğu satır kutulu
  /// madde olur (listenin başına — gövde maddelerin hemen üstünde durduğu
  /// için son satır yerinden kımıldamaz); imleç bir MADDEDEYSE kutusu kalkar
  /// ve metni gövdenin sonuna döner (ilk maddede bu tam tersi işlemdir).
  /// Hiçbir yer odakta değilse boş bir kutulu madde açılır.
  void _toggleChecklistLine() {
    final note = _note;
    if (note == null || note.type != NoteType.text) return;
    unawaited(HapticFeedback.selectionClick());
    final items = _itemsEditorKey.currentState;
    final focused = items?.focusedItemId;
    if (items != null && focused != null) {
      final text = items.takeItem(focused);
      if (text == null) return;
      final body = _bodyController.logicalText;
      final next = body.trim().isEmpty
          ? text
          : (body.endsWith('\n') ? '$body$text' : '$body\n$text');
      _bodyController.setLogical(next, next.length);
      _mutate((n) => n.copyWith(body: next), immediate: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _bodyFocus.requestFocus();
        _bodyController.selection = TextSelection.collapsed(
          offset: _bodyController.text.length,
        );
      });
      return;
    }
    final body = _bodyController.logicalText;
    var line = '';
    var rest = body;
    if (_bodyFocus.hasFocus && body.isNotEmpty) {
      final selection = _bodyController.selection;
      final caret = selection.isValid
          ? wrapToLogicalOffset(
              _bodyController.text,
              selection.baseOffset,
            ).clamp(0, body.length)
          : body.length;
      final start = caret == 0 ? 0 : body.lastIndexOf('\n', caret - 1) + 1;
      var end = body.indexOf('\n', caret);
      if (end < 0) end = body.length;
      line = body.substring(start, end);
      rest = end < body.length
          ? body.substring(0, start) + body.substring(end + 1)
          : (start > 0 ? body.substring(0, start - 1) : '');
    }
    const uuid = Uuid();
    final item = NoteItem(id: uuid.v4(), text: line.trim());
    if (rest != body) _bodyController.setLogical(rest, rest.length);
    _mutate(
      (n) => n.copyWith(body: rest, items: [item, ...n.items]),
      immediate: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _itemsEditorKey.currentState?.focusItem(item.id);
    });
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
      ..showMessage(message);
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

  /// **KALEMİ OTOMATİK ALGILA** (kullanıcı isteği 2026-10-30: "otomatik
  /// kalem algılama olsun", Samsung Notes gibi): kalem (S Pen vb.) notun
  /// içeriğine değince yazma kipi kendiliğinden açılır — belge notunda
  /// (PDF/sunum) sayfanın üstüne yazma kalemi, metin/liste notunda el yazısı
  /// tuvali. Ayar kalem ayarlarında ([InkToolMemory.autoStylus]); salt okunur
  /// notta, kalem kipi zaten açıkken ve yazma kartı açıkken çalışmaz. Kalemle
  /// araç çubuklarına dokunmak etkilenmez: dinleyici yalnız içerik alanında.
  void _onContentPointerDown(PointerDownEvent event) {
    // MADDE JESTLERİ her işaretçide izlenir; kalem maddede başladıysa el
    // yazısı tuvali açılmaz (bkz. note_editor_gestures.dart).
    if (_trackGestureDown(event)) return;
    if (event.kind != PointerDeviceKind.stylus &&
        event.kind != PointerDeviceKind.invertedStylus) {
      return;
    }
    final note = _note;
    if (note == null || _readOnly || !InkToolMemory.autoStylus) return;
    if (_stylusOpening) return;
    // Yalnız bu ekran en üstteyken (levha/menü açıkken dokunuş onlarındır).
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final document =
        note.type == NoteType.pdf || note.type == NoteType.slides;
    if (document) {
      // Balona yazılırken kalem kartın alanlarına dokunuyor olabilir.
      if (_penMode || _immersiveBubble) return;
      setState(() => _penMode = true);
      _showSnack(context.l10n.inkStylusDetected);
      return;
    }
    // Metin/liste notu: imleç koymak için kalemle alana dokunan da olabilir
    // — klavye açıkken (yazıyor) el yazısına geçilmez.
    if (MediaQuery.viewInsetsOf(context).bottom > 0) return;
    _stylusOpening = true;
    HapticFeedback.selectionClick();
    unawaited(_addDrawing().whenComplete(() => _stylusOpening = false));
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

    final background = NoteColors.noteSurface(context, note);
    // Çizilmiş tema varsa sayfa ve üst çubuk saydam: süsleme arkadan görünür
    // (bkz. NoteThemeBackdrop); alt çubuk temanın alt tonunda düz kalır.
    final themed = NoteThemes.byId(note.theme) != null;
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
        // Eki silinmiş bağ etiket sayılmaz (çip görünümü kalmasın).
        for (final link in note.tagLinks)
          if (link.label.isNotEmpty &&
              note.attachments.any((a) => a.id == link.attachmentId))
            link.label,
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
          // DEFTER SATIR ARALIĞI (D1): satır yüksekliğine biner; çizgiler
          // yazıya bağlı olduğundan onlar da açılır (bkz. [_paperGap]).
          height: note.paged && note.lineSpacing != 1
              ? (bodyBase.height ?? 1.45) * note.lineSpacing
              : null,
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
      // Başlığın yazı ölçeği değişince yumuşak oturur (bkz. ScaleSettle).
      child: ScaleSettle(
      value: note.titleFontScale,
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
                  // w500: kalın (w800) başlıkta açıkça ayırt edilsin (bkz.
                  // rich_text `markStyle`).
                  fontWeight: FontWeight.w500,
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
        // ignore: avoid_redundant_argument_values
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
                    Align(child: metaChildren[i]),
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
    // Notun yazı ölçeği değişince gövde eski boyundan yenisine yumuşakça
    // oturur (yalnız boyama; yüzen görsel varken kapalı — sarma ölçümü
    // dönüşümden etkilenmesin).
    final bodyField = ScaleSettle(
      value: note.fontScale,
      enabled: _floats.isEmpty,
      child: Builder(
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
          onChanged: (value) {
            final before = _note?.body ?? '';
            final after = _bodyController.logicalText;
            _mutate((n) => n.copyWith(body: after));
            // Yapıştırılan YouTube bağlantısı videoyu gömer.
            _maybeEmbedPastedVideo(before, after);
          },
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
              return;
            }
            // BAĞLANTIYA DOKUNUŞ (2026-10-28): okurken açar, yazarken önerir.
            final link = tappedLink(
              displayText: _bodyController.text,
              editable: editable,
              tapGlobal: _bodyTapPoint.last,
            );
            if (link != null) {
              editable?.hideToolbar();
              handleLinkTap(
                context,
                link,
                editing: _bodyTapPoint.wasFocused,
                onEmbedVideo: _readOnly || note.type.isPageNoteType
                    ? null
                    : _embedLinkedVideo,
              );
            }
          },
          // Bağlantıya uzun basınca seçim menüsüne "Bağlantıyı aç" eklenir.
          // Düzenlenebilir bir alanda span'e tıklama Flutter'da çalışmaz (dokunuş
          // imleci taşımak için EditableText'e gider), bu yüzden yol seçim menüsü.
          contextMenuBuilder: _bodyContextMenu,
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
        onEmbedVideo: _readOnly ? null : _embedLinkedVideo,
        addRowTrailing: _partsMenu(note),
        paperLines: note.paged && note.archivePaper.ruled,
        onMoveToPage: textPagePosition(note).count > 1
            ? _moveItemToPage
            : null,
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
        onEmbedVideo: _readOnly ? null : _embedLinkedVideo,
        addRowTrailing: _partsMenu(note),
        paperLines: note.paged && note.archivePaper.ruled,
        onMoveToPage: textPagePosition(note).count > 1
            ? _moveItemToPage
            : null,
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
                note: note,
                bodyStyle: noteBodyStyle,
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
                if (_gestureMode != _GestureMode.off)
                  _GestureModeBanner(
                    onClose: () => _setGestureMode(_GestureMode.off),
                  )
                else if (_pendingEmbed != null)
                  _PendingEmbedBanner(
                    fileName: _pendingEmbed!.fileName,
                    // Parmak şeride DEĞDİĞİ an seçim yedeklenir: sonraki
                    // karede odak düşse bile bağlanacak yazı elde kalır.
                    onPointerDown: _rememberTargetSelection,
                    onLink: _finishPendingEmbed,
                    // DAİRE İÇİNE AL (kullanıcı isteği 2026-10-30): yazıyı
                    // elle seçmek yerine parmakla halka çizilir.
                    onLasso: () => _setGestureMode(_GestureMode.embedLasso),
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
                // SESLİ NOT hapı: kayıt notun içinde sürer, yazmaya devam
                // edilebilir. Belirişi yumuşak (alttan süzülür).
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  child: _voiceRecorder == null
                      ? const SizedBox(width: double.infinity)
                      : VoiceRecordPanel(
                          recorder: _voiceRecorder!,
                          onStop: () => unawaited(_finishVoiceRecording()),
                          onCancel: () => unawaited(
                            _finishVoiceRecording(keep: false),
                          ),
                        ),
                ),
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
                // 2026-10-28 ("biçim menüsü daha yumuşak"): panel ile alt
                // çubuk AYNI süre ve eğriyle yer değiştirir (biri büyürken öbürü
                // küçülür — toplam boy sıçramaz), panelin içeriği hafifçe
                // yukarı süzülerek belirir.
                Flexible(
                  child: AnimatedSize(
                    duration: _kBarSwap,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.bottomCenter,
                    child: !_formatBarOpen || _findOpen
                        ? const SizedBox.shrink()
                        : RevealUp(
                          child: SingleChildScrollView(
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
                              onApplyToAll: _formatTarget == null
                                  ? null
                                  : _applyToAll,
                              applyToAllLabel:
                                  _formatTarget?.controller == _bodyController ||
                                      _titleIsTarget
                                  ? l10n.formatApplyAll
                                  : l10n.formatApplyItem,
                              // Hedef MADDEYSE alt çizgi sırası (2026-10-30:
                              // uzun basış menüsünden buraya taşındı).
                              dividerKind: _formatItemId == null
                                  ? null
                                  : _itemsEditorKey.currentState
                                        ?.dividerKindOf(_formatItemId!),
                              onDivider: (kind) => _itemsEditorKey
                                  .currentState
                                  ?.setDividerOf(_formatItemId ?? '', kind),
                              onDividerStyle: () => unawaited(
                                _itemsEditorKey.currentState
                                    ?.editDividerStyleOf(_formatItemId ?? ''),
                              ),
                            ),
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
                  ListenableBuilder(
                    listenable: _find,
                    builder: (context, _) => NoteFindBar(
                      controller: _find.query,
                      focusNode: _find.focus,
                      count: _find.hits.length,
                      index: _find.index,
                      background: background,
                      onChanged: (_) => _runFind(),
                      onNext: () => _stepFind(1),
                      onPrevious: () => _stepFind(-1),
                      onList: () => unawaited(_openFindList()),
                      onClose: _closeFind,
                    ),
                  )
                // BİÇİM PANELİ AÇIKKEN alt çubuk GİZLİ (kullanıcı isteği
                // 2026-10-20: "biçim paneli açılınca alttaki ses, ek vb.
                // kısımlar gizlensin, yazmaya yer kalmıyor"). Panel kendi
                // kapat (⌄) düğmesiyle kapanır.
                else
                AnimatedSize(
                  duration: _kBarSwap,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _formatBarOpen
                      ? const SizedBox(width: double.infinity)
                      : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      // SESLİ NOT (kayıt, 2026-10-28): kayıt SÜRERKEN düğme
                      // gizlenmez — bitirme yolu kalsın. Web'de kayıt eki yok.
                      final showVoiceRecord =
                          !kIsWeb &&
                          (_voiceRecorder != null ||
                              on(UiItem.barVoiceRecord));
                      // ☑ yalnız metin notunda (liste notunda her satır
                      // zaten madde).
                      final showCheckbox =
                          note.type == NoteType.text &&
                          on(UiItem.barCheckbox);
                      final aiCount = [
                        showAi,
                        showDictation,
                        showVoiceRecord,
                      ].where((v) => v).length;
                      // Genişliğe göre plan: taşma/kesik kapsül yerine önce
                      // düğmeler küçülür, sonra ⋮ menüsünde de bulunan
                      // Ara/Paylaş kapsülden çıkar (bkz. planEditorBar).
                      final plan = planEditorBar(
                        width: constraints.maxWidth,
                        fixedSegments:
                            (showFormat ? 1 : 0) +
                            (showAdd ? 1 : 0) +
                            (showCheckbox ? 1 : 0) +
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
                        // Panel kapalıyken imlecin biçimleri (B/I/U, renk).
                        if (showFormat)
                          ActiveFormatBadges(target: _formatTargetN),
                        if (showAdd)
                          Customizable(
                            id: UiItem.barAdd,
                            child: _addToolButton(l10n),
                          ),
                        if (showCheckbox)
                          Customizable(
                            id: UiItem.barCheckbox,
                            child: _toolSegment(
                              icon: Icons.check_box_outlined,
                              label: l10n.checkboxToggle,
                              onTap: _toggleChecklistLine,
                            ),
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
                                if (showVoiceRecord)
                                  Customizable(
                                    id: UiItem.barVoiceRecord,
                                    child: _voiceButton(
                                      size: plan.button,
                                      tooltip: _voiceRecorder == null
                                          ? l10n.recordAudio
                                          : l10n.stopAndSave,
                                      icon: Icons.graphic_eq_rounded,
                                      active: _voiceRecorder != null,
                                      onTap: () => unawaited(
                                        _voiceRecorder == null
                                            ? _recordAudio()
                                            : _finishVoiceRecording(),
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
          // Geri tuşu sırayla: kayıt → biçim paneli → canlı arama → not.
          canPop: !_findOpen && !_formatBarOpen && _voiceRecorder == null,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            // Kayıt sürerken geri = kaydı BİTİR ve ekle, sonra çık (eski
            // kayıt levhasının "geri kaydeder" kuralı — kayıt kaybolmasın).
            if (_voiceRecorder != null) {
              final navigator = Navigator.of(context);
              unawaited(
                _finishVoiceRecording().whenComplete(() {
                  if (mounted) navigator.maybePop();
                }),
              );
              return;
            }
            // Biçim paneli açıkken geri PANELİ kapatır (kullanıcı isteği
            // 2026-10-28), notu değil.
            if (_formatBarOpen) {
              setState(() => _formatBarOpen = false);
              return;
            }
            if (_findOpen) _closeFind();
          },
          // NOT TEMASI (2026-10-28): çizilmiş zemin üst çubuğun da
          // arkasında; sayfa ve üst çubuk saydamlaşır.
          child: NoteThemeBackdrop(
          themeId: note.theme,
          child: Scaffold(
          backgroundColor: themed ? Colors.transparent : background,
          // **KASMA — klavye boşluğu artık KARARLI** (bkz. [KeyboardSnap]).
          // Scaffold gövdeyi klavye animasyonunun HER karesinde kısaltıyordu;
          // görselli/uzun notlarda ve PDF bölmesinde yalnızca bu yeniden
          // ölçüm bile takılma yaratıyor. Boşluk aşağıda, gövdenin
          // dolgusundan veriliyor ve bir açılış/kapanışta EN ÇOK BİR KEZ
          // değişiyor; çubuğun klavyeyle birlikte akan hareketi ise
          // [KeyboardSlide] ile yalnız boyama katmanında yapılıyor.
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: themed ? Colors.transparent : background,
            scrolledUnderElevation: themed ? 0 : null,
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
              // GERİ GETİR (yinele) HEP GÖRÜNÜR (kullanıcı isteği 2026-10-30:
              // "geri al gibi geri getir de olsun"): eskiden yalnız
              // kullanılabilirken beliriyordu, kullanıcı varlığını bilmiyordu.
              // İkisi tek kişiselleştirme öğesi; boşken ikisi de soluk.
              Customizable(
                id: UiItem.topUndo,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.undo,
                      icon: const Icon(Icons.undo),
                      onPressed: _canUndo ? _undo : null,
                    ),
                    IconButton(
                      key: const ValueKey('editor-redo'),
                      tooltip: l10n.redo,
                      icon: const Icon(Icons.redo),
                      onPressed: _canRedo ? _redo : null,
                    ),
                  ],
                ),
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
              // GÖRÜNÜM (tema şeridi) üst çubukta — örnek uygulamadaki palet
              // düğmesi; biçim panelinden ve Ekle levhasından da açılır.
              if (!_readOnly)
                Customizable(
                  id: UiItem.topTheme,
                  child: IconButton(
                    tooltip: l10n.noteAppearance,
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: () => unawaited(_showColorSheet()),
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
                    // KALEMİ OTOMATİK ALGILA (bkz. [_onContentPointerDown]).
                    child: Listener(
                      onPointerDown: _onContentPointerDown,
                      onPointerMove: _onContentPointerMove,
                      onPointerUp: _onContentPointerUp,
                      onPointerCancel: _onContentPointerCancel,
                      // JEST KİPİ örtüsü içeriğin ÜSTÜNDE; ağacın şekli kiple
                      // değişmesin diye yığın koşulsuz (ilk çocuk sabit).
                      child: Stack(
                        children: [
                          SafeArea(
                      bottom: false,
                      // ÇERÇEVE EDİTÖRDE ÇİZİLMEZ (kullanıcı isteği
                      // 2026-10-20: "çerçeve sadece dashboarda görünsün"):
                      // notun içi sade kalır, renk kartta görünür.
                      child: _withBackground(
                        note,
                        bgImage,
                        _withPaper(
                          note,
                          noteBodyStyle,
                          // Sayfalı notta yana çekiş sayfa çevirir.
                          PageSwipeDetector(
                            enabled:
                                !note.type.isPageNoteType &&
                                textPagePosition(note).count > 1,
                            onSwipe: _swipePage,
                            child: body,
                          ),
                        ),
                      ),
                    ),
                          if (_gestureMode != _GestureMode.off)
                            Positioned.fill(
                              child: InkGestureLayer(
                                key: const ValueKey('ink-gesture-layer'),
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.7),
                                scrollPosition: _gestureScrollPosition,
                                onStroke: _onGestureStroke,
                              ),
                            ),
                        ],
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
      ),
    );
  }
}
