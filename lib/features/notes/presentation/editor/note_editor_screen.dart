import '../note_link_ui.dart';
import '../../../../core/widgets/back_closes.dart';
import '../../../../core/widgets/color_fade.dart';
import '../study_cards_screen.dart' show generateCardsForNote;
import '../note_card.dart' show openNoteRoute;
import '../../domain/note_links.dart';
import '../reminder_repeat_ui.dart';
import '../reminders_screen.dart'
    show maybeShowAutoStartHint;
import '../reminder_sheet.dart';
import '../../domain/reminder_repeat.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/a11y/min_tap_target.dart';
import '../../../../core/app_icons.dart';
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
import '../../../../app/window_class.dart';

export '../../../../app/window_class.dart' show kReadingWidth;
import '../../../auth/presentation/auth_providers.dart';
import '../../../../app/theme/note_colors.dart';
import '../../../../app/theme/note_themes.dart';
import '../../../../core/constants.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/web_file_drop.dart';
import '../../../../core/personalize.dart';
import '../../../../core/tips.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/doc_picker.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../core/utils/hard_keyboard.dart';
import '../../../../core/utils/voice_commands.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/utils/attachment_tag.dart';
import '../../../../core/utils/link_text.dart';
import '../../../../core/utils/markdown.dart';
import '../../../../core/utils/note_fonts.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/widgets/color_palette.dart';
import '../../../../core/utils/note_guard.dart';
import '../../../../core/utils/sentence_select.dart';
import '../../../../core/utils/pdf_ref.dart';
import '../../../../core/utils/video_time.dart';
import '../../../../core/utils/youtube.dart';
import '../../../../core/widgets/customizable.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import '../../../../core/widgets/note_route_closing.dart';
import '../../../../core/widgets/scale_settle.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import 'stylus_toggle.dart';
import 'pinned_side.dart';
import '../../data/note_format_memory.dart';
import '../../data/attachment_save.dart';
import '../../data/import_service.dart' show markdownAttachment;
import '../../data/note_shortcut.dart';
import '../../../ai/data/ai_gate.dart';
import '../../../auth/presentation/account_required.dart';
import '../../../ai/data/gemini_service.dart';
import '../../../ai/presentation/ai_sheet.dart';
import '../../../ai/presentation/listen_screen.dart';
import '../../../folders/data/folders_repository.dart';
import '../../../folders/domain/note_folder.dart';
import '../../../folders/presentation/folder_sheets.dart';
import '../../../settings/data/permissions_service.dart';
import '../../../settings/settings_providers.dart';
import '../../../calendar/data/task_note_sync.dart';
import '../../../calendar/presentation/note_calendar_links.dart';
import '../../../calendar/presentation/task_editor.dart';
import '../../../calendar/presentation/line_task_chip.dart';
import 'auto_spell.dart';
import 'spell_settings_sheet.dart';
import 'note_package.dart';
import 'editor_quick_row.dart';
import '../../../calendar/presentation/event_editor.dart';
import '../../../calendar/domain/agenda.dart' show noteDateSuggestion;
import '../../../../core/utils/spoken_datetime.dart' show parseSpokenDateTimeNow;
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
import '../../domain/bubble_view_retire.dart';
import '../collaborators_sheet.dart';
import '../../../../core/widgets/action_menu_sheet.dart';
import '../color_picker_sheet.dart';
import '../note_menu_model.dart';
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
import '../../../../app/app_commands.dart' show currentLocation, goHome;
import '../../../../app/app_frame.dart' show HomeInBar, kRailBreakpoint;
import '../../../../app/split_shell.dart';
import 'page_ink_layer.dart';
import '../place_reminder_sheet.dart';
import '../viewers/ink_layer.dart';
import 'pen_tray.dart';
import 'drawing_screen.dart';
import 'editor_bar_layout.dart';
import 'editor_bar_tags.dart';
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
import '../viewers/pen_policy.dart';
import '../viewers/video_viewer.dart';
import '../viewers/text_recognize_screen.dart';
import '../viewers/transcript_screen.dart';
import '../../domain/transcript.dart';
import 'tag_chips.dart';
import 'tag_tap.dart';
import 'text_wrap.dart';
import 'windowed_body.dart';
import 'video_hub_scope.dart';
import 'audio_card_box.dart' show kAudioBoxWidth, kAudioBoxHeight;
import 'text_page_box.dart' show kTextBoxWidth, kTextBoxHeight;
import 'attachment_actions.dart';
import 'view_mode_switch.dart';
import 'page_swipe.dart';
import 'title_fit.dart';
import '../../../../core/widgets/smooth_routes.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/friendly_error.dart';
import '../../../../core/a11y/chip_roles.dart';

part 'note_editor_actions.dart';
part 'note_editor_package.dart';
part 'note_editor_ai.dart';
part 'note_editor_appearance.dart';
part 'note_editor_attachments.dart';
part 'note_editor_find.dart';
part 'note_editor_gestures.dart';
part 'note_editor_media_view.dart';
part 'note_editor_parts.dart';
part 'note_editor_toolbar.dart';
part 'note_editor_voice.dart';
part 'note_editor_flow.dart';
part 'note_editor_video.dart';
part 'note_editor_embed.dart';

/// **OKUNURLUK — NOTUN İÇİ ZEMİNE GÖRE** (kullanıcı bulgusu 2026-11-04: "not
/// arka plan rengini değiştirince bazen yazı rengi sabit kaldığı için okuma
/// zorluğu oluyor"). Not zemini temanın yazısıyla okunmuyorsa
/// (`NoteColors.inkThemeFor` — açık temada koyu özel renk ya da tersi)
/// editör ZIT temayla çizilir: build notun zeminini hesaplayınca o temayı
/// burada saklar ve ağacı `Theme` ile sarar. Bu dosyada (ve parçalarında)
/// ekranın KENDİ bağlamından tema okuyan her yer `Theme.of` yerine bunu
/// kullanır — yoksa build içinde hesaplanan yazı stili (gövde, başlık, işaret
/// rengi) dış temada kalırdı. Başka bağlamlar (alt widget'lar) zaten sarılan
/// temanın altında, `Theme.of` ile doğru temayı görür.
/// Üst çubuk saydam olduğu için durum çubuğu simgesi sayfanın renginden seçilir.
SystemUiOverlayStyle _statusBarFor(Color page) {
  final dark = ThemeData.estimateBrightnessForColor(page) == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
  );
}

final _editorInk = Expando<ThemeData>('editorInk');

ThemeData _themeOf(BuildContext context) =>
    _editorInk[context] ?? Theme.of(context);

/// Otomatik kaydın sessizlik süresi ve aralıksız yazımdaki üst sınırı
/// (F22.2, KARAR 2026-11-03).
const kEditorSaveDelay = Duration(seconds: 2);
const kEditorSaveMaxWait = Duration(seconds: 10);

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
        // Ara başlık kutucuksuz, kalın çizilir.
        x.header != y.header ||
        x.align != y.align ||
        // Paket satırları özet hapına toplar (bkz. NoteItem.package).
        x.package != y.package ||
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
      a.pageInk.length != b.pageInk.length ||
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


/// Üst çubuk başlığının boşluğu (F38.2): tarih sayfa metninin sol kenarında.
/// Geri oku yokken 16 dp (derin bağlantı, web yenileme); geniş bölmede okuma
/// sütununa hizalı. [hasLeading]: solda 56 dp düğme var.
/// Üst çubuktaki düzenleme tarihi, KISA (kullanıcı isteği 2026-11-05: "üst
/// alanda sadeleşme" — "5 Kas 2026 13:…" dar çubukta kesiliyordu): bugün
/// yalnız saat, bu yıl gün + ay + saat, daha eskisi gün + ay + yıl.
String editorBarDate(DateTime at, DateTime now) {
  if (at.year == now.year && at.month == now.month && at.day == now.day) {
    return DateFormat('HH:mm').format(at);
  }
  if (at.year == now.year) return DateFormat('d MMM HH:mm').format(at);
  return DateFormat('d MMM y').format(at);
}

double editorTitleSpacing(double paneWidth, {required bool hasLeading}) {
  final textLeft = readingMargin(paneWidth) + 16;
  return hasLeading ? math.max(0, textLeft - kToolbarHeight) : textLeft;
}

/// Okuma sütununun bölme içindeki kenar boşluğu; dar ekranda 0.
double readingMargin(double paneWidth) =>
    paneWidth > kReadingWidth ? (paneWidth - kReadingWidth) / 2 : 0.0;

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.noteId,
    this.ownerId,
    this.readOnly = false,
    this.startDrawing = false,
    this.startSeparateDrawing = false,
    this.placementHintAttachmentId,
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
    this.revealItemId,
    this.initialFind,
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

  /// "Ayrı çizim": açılır açılmaz çizim ekranı (sonuç görsel eki olur).
  final bool startSeparateDrawing;

  /// Dışarıdan (paylaşım) gelen ek: not "Yeni ek nerede dursun?" ipucuyla açılır.
  final String? placementHintAttachmentId;

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

  /// `?item=<madde kimliği>`: açılışta bu maddeye kaydırılır (ana ekranın
  /// "zamanı gelenler" şeridinden satır görevine dokunulunca).
  final String? revealItemId;

  /// `?find=<sorgu>` (F56.1, Keep şikâyeti "arama sonucuna basınca kelimeye
  /// gitmiyor"): ana ekran aramasından açılınca not içi arama bu sorguyla
  /// açılır, ilk eşleşmeye kaydırılır ve vurgulanır. Klavye AÇILMAZ.
  final String? initialFind;

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

  /// Ek şeridi BU ekranda açıldı mı (alt çubuktaki ataç / şeridin başlığı)?
  /// Öyleyse geri önce şeridi kapatır ([BackCloses]). Kalıcı tercihle zaten
  /// açık gelen şerit geri tuşunu yakalamaz — her not çıkışı iki geri
  /// istemesin.
  bool _stripOpenedHere = false;

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

  /// Uzun notta yazarken alan yalnız imlecin çevresini taşır (F24.2).
  late final _bodyWindow = BodyWindow(_bodyController)
    ..addListener(() {
      if (mounted) _update(() {});
    });
  final _bodyFieldKey = GlobalKey();

  /// Metin alanına o an bağlı denetleyici; model hep [_bodyController].
  WrapTextController get _bodyField =>
      _bodyWindow.active ? _bodyWindow.win : _bodyController;

  /// Pencereli yazıma uygun mu? Ek etiketi çipleri, sarma, not içi arama ve
  /// bekleyen biçim alanın kendi metriklerine bakar: tek alanda kalırlar.
  bool _windowAllowed(Note note) =>
      _bodyFocus.hasFocus &&
      !_readOnly &&
      _floats.isEmpty &&
      !_findOpen &&
      !note.paged &&
      !note.hasPageInk &&
      _bodyController.pendingRange == null &&
      !_bodyController.text.contains('\u{1F4CE}');
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
  bool _pendingSeparateDrawing = false;
  bool _pendingVoice = false;
  bool _pendingDictation = false;
  bool _pendingVideo = false;
  bool _pendingPhoto = false;
  String? _pendingRevealItem;
  String? _pendingFind;
  bool _pendingScan = false;
  bool _pendingPdf = false;
  bool _pendingSlides = false;
  bool _pendingGalleryVideo = false;
  bool _pendingYouTube = false;
  bool _pendingTranscribe = false;
  bool _pendingAudioFile = false;

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

  /// Editörün üst çubuğunun yüksekliği (bkz. AppBar `toolbarHeight`).
  static const double _kEditorToolbarHeight = 48;

  /// Az önce BU EKRANDA eklenen ve sayfada yüzen ek — tuval onu seçip
  /// görünüm anahtarını ipucuyla gösterir (bkz.
  /// [NotePageCanvas.placementHintId]); gösterilince temizlenir.
  String? _placementHintId;

  void Function() _stopFileDrops = () {};

  /// Üst çubuğun başlığı: başlık alanı oraya taşındıysa (bkz.
  /// [_titleInBar]) dolu, değilse null (tarih gösterilir). `build` içinde
  /// gövdeyi kurarken yazılır, aynı build'deki AppBar okur.
  Widget? _barTitle;

  /// Başlık üst çubukta mı: medya notun tepesine SABİTLENMİŞ ya da not
  /// balonlu belge görünümünde (belge üstte, sayfa notu altta). Balona
  /// yazılırken (sürükleyici kip) başlık zaten gizlenir.
  bool _titleInBar(Note note) {
    if (note.type.isPageNoteType) {
      final kind = note.type == NoteType.slides
          ? AttachmentKind.slide
          : AttachmentKind.pdf;
      return note.attachments.any((a) => a.kind == kind);
    }
    return note.attachments.any((a) => a.isPinnedTop);
  }

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

  /// Yazma sürüyor mu (alt çubuk gizleme, bkz. [TypingBarHide]). Yalnız bu
  /// bildirici değişir: ekran setState ile yeniden kurulmaz.
  final _typingN = ValueNotifier<bool>(false);
  Timer? _typingTimer;

  /// Duraklamasız art arda yazılan değişiklik sayısı (bkz. [_noteTyping]).
  int _typedBurst = 0;

  /// Gizlenme gecikmesi sayacı (bkz. [typingBarHideDelayProvider]): yazma
  /// kesintisiz sürerse dolunca çubuk iner; duraklama ([_typingTimer]) iptal
  /// eder.
  Timer? _hideTimer;

  /// Son tuştan beri [_kStillTyping] geçmediyse etkin: gizlenme gecikmesi
  /// dolduğunda yazma HÂLÂ sürüyor mu (birkaç harf yazıp duran kullanıcının
  /// çubuğu, durduktan sonra inmesin).
  Timer? _recentKey;
  static const _kStillTyping = Duration(milliseconds: 500);

  /// Yazma "sürüyor" sayılırken iki tuş arası en uzun ara. Çubuk görünürken
  /// sabit (2026-11-08 ölçüsü); gizliyken ara ayardan gelir.
  static const _kTypingPause = Duration(milliseconds: 1100);

  static Duration _tenths(int value) => Duration(milliseconds: value * 100);

  /// Klavye açıkken her metin değişiminde çağrılır; durunca çubuk geri gelir.
  /// Süreler AYARLANABİLİR (F60.S7): gizlenme gecikmesi (varsayılan 0) ve
  /// yeniden görünme gecikmesi (varsayılan 1,1 sn) — Ayarlar → Kartlar.
  void _noteTyping() {
    if (_keyboardInset <= 0 || !ref.read(hideBarWhileTypingProvider)) return;
    // ÜÇ HARF KURALI (kullanıcı isteği 2026-11-08 üçüncü tur): çubuk tek
    // harflik düzeltmede / tek dokunuşta gitmesin; ancak duraklamasız art
    // arda 3 değişiklikten sonra (gerçekten yazılıyorsa) gizlenir. Sayaç,
    // duraklama zamanlayıcısı dolunca ([_showBarNow]) sıfırlanır.
    _typedBurst++;
    _typingTimer?.cancel();
    _recentKey?.cancel();
    _recentKey = Timer(_kStillTyping, () {});
    if (_typingN.value) {
      // Gizli: son tuştan "yeniden görünme gecikmesi" kadar sonra gelir.
      _typingTimer = Timer(
        _tenths(ref.read(typingBarShowDelayProvider)),
        _showBarNow,
      );
      return;
    }
    // Görünür: duraklama sayacı sıfırlar (ve bekleyen gizlemeyi iptal eder).
    _typingTimer = Timer(_kTypingPause, _showBarNow);
    if (_typedBurst < 3) return;
    final delay = _tenths(ref.read(typingBarHideDelayProvider));
    if (delay == Duration.zero) {
      _hideBarNow();
    } else {
      // Gecikme 3. değişiklikten sayılır; sonraki tuşlar uzatmaz.
      _hideTimer ??= Timer(delay, _hideBarNow);
    }
  }

  void _hideBarNow() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (!mounted || _typingN.value) return;
    // Bu arada klavye kapandıysa ya da ayar kapatıldıysa gizlenmez.
    if (_keyboardInset <= 0 || !ref.read(hideBarWhileTypingProvider)) return;
    // Gecikme doldu ama yazma durmuş: gizleme; sonraki tuş yeniden sayar.
    if (_recentKey?.isActive != true) return;
    _typingN.value = true;
    final prefs = ref.read(sharedPreferencesProvider);
    if (TipOnce.due(prefs, TipOnce.typingBarHide, sessionLimit: false)) {
      TipOnce.show(
        context,
        prefs,
        TipOnce.typingBarHide,
        context.l10n.tipHideBarTyping,
        sessionLimit: false,
      );
    }
    // Gizlendiği andan itibaren yeniden görünme gecikmesi işler.
    _typingTimer?.cancel();
    _typingTimer = Timer(
      _tenths(ref.read(typingBarShowDelayProvider)),
      _showBarNow,
    );
  }

  /// Alt çubuk HEMEN geri gelir: yeni maddeye/alana geçince ve klavye
  /// kapanınca (kullanıcı isteği 2026-11-08) — beklemeden.
  void _showBarNow() {
    _typingTimer?.cancel();
    _typingTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
    _typedBurst = 0;
    if (_typingN.value) _typingN.value = false;
  }

  /// Alt çubukta son karede "Notta ara" / "Paylaş" görünüyor muydu (F12.1):
  /// ⋮ menüsü çubukta duranı tekrar etmez, düşeni Araçlar'da gösterir.
  /// Kurulum sırasında yazılır (setState yok — yalnız menü açılınca okunur).
  bool _barHasSearch = false;

  /// Alt çubuğun renkli nottaki tonu (F75.3, K-D6): notun koyu tonu ve sayfa
  /// rengi; renksiz/temalı notta [_barInk] null → çubuk temanın renklerinde.
  /// Build'de [NoteAccent]'e giden değerlerden beslenir (yeni sağlayıcı yok).
  Color? _barInk;
  Color _barPage = Colors.transparent;

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

  void _clearFormatTargetFor(WrapTextController controller) {
    AutoSpell.detach(controller);
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
    // Yazım düzelt (hızlı satır): her alan; başlıkta kelime başları büyür
    // (2026-11-08).
    AutoSpell.attach(
      controller,
      commit,
      title: controller == _titleController,
    );
    if (changed) {
      _formatTargetN.value = _formatTarget;
      // Yeni maddeye/alana geçildi: gizlenmiş alt çubuk hemen gelir. Bildirim
      // odak dinleyicisinden (build dışı) geliyor; yine de kareye ertelenir.
      if (_typingN.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showBarNow();
        });
      }
    }
    _onAnyFocusChange();
    // Alan yeni odaklandı: imleci klavyenin üstüne al. Bu kapanış gövde,
    // başlık ve madde satırlarının HEPSİNDEN geçtiği için tek yer yeter.
    _revealCaretSoon();
    // Çubuk AÇIKKEN hedef değişmesi çizimi etkiler: aktif biçim vurgusu yeni
    // alanın imlecinden hesaplanmalı. Kapalıyken çizim değişmediği için
    // gereksiz yere setState çağırmıyoruz (odak her satırda değişiyor).
    if (changed && _formatBarOpen && mounted) setState(() {});
  }

  /// Seçimdeki tüm biçimleri siler.
  void _clearFormat() => _runOnTarget(clearRichFormat);

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

  /// Notun kendi yazı tipi/boyutu uygulanmış gövde stili (ölçüm ve çizim
  /// ortak kaynağı).
  TextStyle? _noteTextStyle() {
    final base = _themeOf(context).textTheme.bodyLarge;
    final note = _note;
    if (base == null || note == null) return base;
    return applyNoteFont(
      base.copyWith(fontSize: (base.fontSize ?? 16) * note.fontScale),
      note.fontFamily,
    );
  }

  /// F22.2 (KARAR 2026-11-03): ~2 sn boşluk, aralıksız yazımda en geç
  /// 10 sn. Her kayıt FlutterFire'da TÜM koleksiyonu ana iş parçacığında
  /// yeniden kodlatıyor (K3) — 0,5 sn / 3 sn'de yazarken saniyede bir blok
  /// demekti. Çıkış kapılarında (kapanış, arka plan, `inactive`) bekleyen
  /// kayıt hemen yazılır ([_saveNow]); bedel: uygulama öldürülürse en çok
  /// ~10 sn'lik yazı.
  final _debouncer = Debouncer(
    delay: kEditorSaveDelay,
    maxWait: kEditorSaveMaxWait,
  );

  /// Otomatik kayıt istemci saatiyle yazıldı mı (F22.3): kapanışta bir kez
  /// sunucu zamanı damgalanır ki sıralama/okunmamış hesabı cihaz saatine
  /// bağlı kalmasın.
  bool _clientStamped = false;

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

  /// Yeni boş not odağı bir kez denendi (bkz. `_focusIfNewEmptyNote`).
  bool _newNoteFocused = false;

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
    // Yazım v2: "bu notta dokunma" listesi her not için baştan (Faz 70).
    AutoSpell.beginNote();
    unawaited(AutoSpell.load().then((_) => _seedSpell()));
    FocusManager.instance.addListener(_onAnyFocusChange);
    InkToolMemory.autoStylusListenable.addListener(_onStylusToggle);
    // Kök gezgin: kapanış önerisi (F52.3) editör atıldıktan sonra açılır.
    _rootNavigator = Navigator.maybeOf(context, rootNavigator: true);
    // Uygulama arka plana alınırken/kapatılırken bekleyen kaydı zorlamak için
    // (bkz. [_saveNow] — "kapatınca not kayboluyor" kök nedeni).
    WidgetsBinding.instance.addObserver(this);
    noteRouteClosing.addListener(_holdSaveWhileClosing);
    // Arka plandaki boş not temizliği bu notu ATLASIN (bkz. cleanupEmptyNotes):
    // kullanıcı yazmaya yeni başladığında doküman kısa bir süre boş görünür.
    openEditorNoteIds.add(widget.noteId);
    // Listede açık not vurgusu (geniş ekran). Ağaç kurulurken sağlayıcı
    // yazılamaz → mikro görev; dispose'da `ref` yok → notifier saklanır.
    final openNotes = _openNotes = ref.read(openNoteIdsProvider.notifier);
    final openId = widget.noteId;
    unawaited(Future.microtask(() => openNotes.open(openId)));
    // F26.3: açıkken listede yerinde dursun (kapanış başlayınca bırakılır).
    final sortHold = ref.read(sortHeldNoteIdsProvider.notifier);
    _sortHold = sortHold;
    unawaited(Future.microtask(() => sortHold.hold(openId)));
    _previewHold = ref.read(heldNotePreviewProvider.notifier);
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
    _fullscreenNotifier = ref.read(noteFullscreenProvider.notifier);
    // İlk açılış kasması (madde 3): editör başlangıçta _note null olduğu için
    // bir kare boyunca CircularProgressIndicator gösterip ardından tüm editörü
    // kuruyordu; bu geçiş, sayfa animasyonuyla aynı anda büyük bir yerleşim
    // sıçraması yaratıyordu. Not zaten dashboard akışında yüklü olduğundan
    // (kullanıcı oradan geldi) onu SENKRON okuyup ilk kareyi dolu kur —
    // spinner→editör takası ve onunla gelen kasma ortadan kalkar.
    // Uzun basışla seçilen kelime, içinde bulunduğu CÜMLEYE genişletilir —
    // notta seçim neredeyse hep bir cümleyi taşımak/silmek için yapılıyor.
    attachSentenceSelection(_bodyController);
    attachSentenceSelection(_bodyWindow.win);
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
        // Kapanışta yerleşim yinelenmesin: sayfa zaten gidiyor.
        if (!noteRouteClosing.value) _bodyWindow.exit();
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
    _pendingSeparateDrawing = widget.startSeparateDrawing;
    _placementHintId = widget.placementHintAttachmentId;
    // Web: not açıkken bırakılan/yapıştırılan dosya BU nota girer (F41.4).
    if (!_readOnly) {
      _stopFileDrops = addFileDropHandler(
        (files) => unawaited(_attachFiles(files)),
      );
    }
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
    _pendingRevealItem = widget.revealItemId;
    _pendingFind = widget.initialFind;
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
            // Bizim çizgilerimiz henüz yazılmadıysa onlar kalır; yoksa gelen
            // (başka cihaz ya da ağır belgenin geç gelen çizimi).
            pageInk: _debouncer.hasPending || incoming.heavyMissing
                ? null
                : incoming.pageInk,
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // `resumed` dışındaki her evre bir "çıkış" olabilir: Android'de görev
    // listesi açılınca `inactive`, arka plana geçince `hidden`/`paused`,
    // öldürülmeden hemen önce `detached` gelir. Kayıt hepsinde zorlanır —
    // fazladan yazımın maliyeti yok (Firestore merge, aynı içerik).
    if (state != AppLifecycleState.resumed) _saveNow();
    // Arka plana geçiş gerçek bir çıkış olabilir (öldürülürse dispose yok):
    // istemci saatli son kayıt sunucu zamanıyla mühürlenir. `inactive`
    // (bildirim perdesi vb.) sık gelir — orada damgalanmaz.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stampServerTimeOnExit();
    }
  }

  /// F22.3: oturumda istemci saatli kayıt olduysa `updatedAt`i bir kez
  /// sunucu zamanıyla yazar ([_saveNow] zaten sunucu zamanıyla yazdıysa
  /// bayrak inmiş olur, ikinci yazım yok).
  void _stampServerTimeOnExit() {
    if (!_clientStamped || _deleted) return;
    _clientStamped = false;
    _notesRepo?.updateFields(widget.noteId, const {});
  }

  /// F23.3: not karttan küçülerek kapanırken bekleyen otomatik kayıt
  /// zamanlayıcısı DURUR — yazım + ardından gelen koleksiyon olayının
  /// kodlaması (K3) kapanış karelerine binmesin. Kayıt kaybolmaz: rota
  /// kalkınca [dispose] içindeki [_saveNow] yazar; geri çekme jesti
  /// vazgeçilirse zamanlayıcı yeniden kurulur.
  ///
  /// **KAPANIŞ KASMASI (2026-11-08):** sıralama tutması burada BIRAKILMAZ —
  /// eskiden kapanışın ilk karesinde (mikro görev) bırakılıyordu: o karede
  /// zaten panonun duraklatılmış abonelikleri sürüp `filteredNotesProvider`
  /// yeniden hesaplanıyor (F23.2 ölçümü ~3-4 ms) ve tutma bırakılınca İKİNCİ
  /// kez hesaplanıp pano ekranı yeniden kuruluyordu. Görünür faydası da yoktu:
  /// pano kapanış boyunca `FreezeWhenHidden` ile DONUK, küçülen not kartın
  /// donuk (eski) yerine iner. Bırakma rota kalkınca ([dispose]); yeni sıra
  /// panonun kapanış sonrası yetişmesine (+120 ms) katılır.
  void _holdSaveWhileClosing() {
    if (noteRouteClosing.value) {
      _debouncer.pause();
    } else {
      _debouncer.resume();
    }
  }

  /// F26.3 (bkz. [sortHeldNoteIdsProvider]); dispose'da `ref` yok.
  SortHeldNoteIdsNotifier? _sortHold;

  /// F68.1 (bkz. [heldNotePreviewProvider]); dispose'da `ref` yok.
  HeldNotePreviewNotifier? _previewHold;

  NavigatorState? _rootNavigator;

  /// Bu oturumda önerilmiş (not, zaman) çiftleri — aynı öneri yinelenmez.
  static final _suggested = <String>{};

  /// **NOTTA TARİH ÖNERİSİ** (TAKVIM F52.3): az önce düzenlenmiş notun son
  /// satırlarında zaman ifadesi varsa ve notun hatırlatıcısı yoksa, kapanışta
  /// tek bildirim: "Takvime ekle?". Yazarken hiçbir şey çalışmaz (tuş
  /// başına iş yok — akıcılık bütçesi); yalnız çıkışta bir kez ayrıştırılır.
  void _suggestCalendar(bool readOnly) {
    final note = _note;
    // `_readOnly` değil: ref atılırken okunamaz.
    if (note == null ||
        readOnly ||
        note.locked ||
        note.reminderAt != null) {
      return;
    }
    final edited = note.updatedAt;
    if (edited == null ||
        DateTime.now().difference(edited) > const Duration(minutes: 3)) {
      return;
    }
    final text = note.toPlainText();
    final hit = noteDateSuggestion(
      text.length > 2000 ? text.substring(text.length - 2000) : text,
      parseSpokenDateTimeNow,
    );
    if (hit == null || !_suggested.add('${note.id}|${hit.at}')) return;
    final messenger = rootScaffoldMessengerKey.currentState;
    final navigator = _rootNavigator;
    if (messenger == null || navigator == null || !navigator.mounted) return;
    final navContext = navigator.context;
    final l10n = AppLocalizations.of(navContext);
    final title = note.displayTitle.trim().isEmpty
        ? hit.line
        : note.displayTitle.trim();
    final noteId = note.id;
    unawaited(
      Future.microtask(
        () => messenger.showSnackBar(
          timedSnackBar(
            duration: const Duration(seconds: 6),
            content: Text(
              l10n.calendarSuggest(DateFormat.MMMEd().add_Hm().format(hit.at)),
            ),
            action: SnackBarAction(
              label: l10n.calendarSuggestAction,
              onPressed: () {
                if (!navigator.mounted) return;
                unawaited(
                  showEventEditor(
                    navigator.context,
                    start: hit.at,
                    linkNoteId: noteId,
                    initialTitle: title,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopFileDrops();
    _typingTimer?.cancel();
    _hideTimer?.cancel();
    _recentKey?.cancel();
    _typingN.dispose();
    FocusManager.instance.removeListener(_onAnyFocusChange);
    InkToolMemory.autoStylusListenable.removeListener(_onStylusToggle);
    _fieldFocusedN.dispose();
    WidgetsBinding.instance.removeObserver(this);
    noteRouteClosing.removeListener(_holdSaveWhileClosing);
    openEditorNoteIds.remove(widget.noteId);
    final openNotes = _openNotes;
    final openId = widget.noteId;
    unawaited(Future.microtask(() => openNotes.close(openId)));
    final sortHold = _sortHold;
    unawaited(Future.microtask(() => sortHold?.release(openId)));
    _previewHold?.release(openId);
    _pageInkCtl?.dispose();
    // Tam ekran nota bağlı; ağaç kilitliyken durum yazılamaz. Başka bir nota
    // GEÇİLDİYSE (yeni editör çoktan açık) tam ekran sürer.
    final fullscreen = _fullscreenNotifier;
    if (fullscreen != null) {
      unawaited(
        Future.microtask(() {
          if (openEditorNoteIds.isEmpty) fullscreen.set(false);
        }),
      );
    }
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
    _stampServerTimeOnExit();
    // Tarih ayrıştırma (2000 karakter, düzenli ifadeler) rota kalkış karesine
    // binmesin: panonun yetişmesinden (+120 ms) de sonra.
    final readOnly = widget.readOnly;
    Timer(const Duration(milliseconds: 700), () => _suggestCalendar(readOnly));
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
    _bodyWindow.dispose();
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

  /// Daire jestinin yapay zekâsı bu OTURUMDA kullanılamıyor mu (TUTARLILIK
  /// F36.5 — web'de dahili AI kapalıyken her kazara daire aynı hatayı
  /// basıyordu). İlk yetki hatasında bir kez söylenir, sonra jest sessiz.
  static bool _aiGestureUnavailable = false;

  /// Metin DIŞINDA görünür hiçbir şey değişmedi mi? (saf yazım tespiti)
  ///
  /// [ignoreAttachments]: değişiklik YALNIZ bir ekin mürekkebi (bkz.
  /// [_updateAttachmentInk]) — çizgi kendi katmanında zaten ekranda.
  static bool _sameVisual(Note a, Note b, {bool ignoreAttachments = false}) =>
      sameItemsVisually(a.items, b.items) &&
      a.activePage == b.activePage &&
      identical(a.textPages, b.textPages) &&
      (ignoreAttachments || identical(a.attachments, b.attachments)) &&
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

  /// Kök kurulmadan mürekkebi ilerleyen eklerin, widget ağacının ELİNDEKİ
  /// (bayat) çizgi listesi — bkz. [_updateAttachmentInk], [_withLiveInk].
  /// Kök her kurulduğunda ağaç tazelenir, kayıt boşalır.
  final Map<String, List<InkStroke>> _staleInk = {};

  /// [inkOnly]: [transform] yalnız bir ekin mürekkebini değiştirir (OTURTMA
  /// F60.1) — kök kurulmaz, kayıt debounce'lu.
  void _mutate(
    Note Function(Note) transform, {
    bool immediate = false,
    bool inkOnly = false,
  }) {
    final note = _note;
    if (note == null) return;
    if (!immediate && !inkOnly) _noteTyping();
    // F68.1: yazım/çizim sürerken listedeki kart beklesin; anında kayıt
    // (yıldız, sabitle, renk) kartta hemen görünsün.
    if (immediate) {
      _previewHold?.release(widget.noteId);
    } else {
      _previewHold?.touch(widget.noteId);
    }
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
      // YENİ EK (kullanıcının eklediği; akıştan gelen değil — o _mutate'ten
      // geçmez): sayfada yüzüyorsa yerleşim ipucu açılır.
      if (next.attachments.length > note.attachments.length) {
        final known = {for (final a in note.attachments) a.id};
        final added = next.attachments
            .where(
              (a) =>
                  !known.contains(a.id) &&
                  a.floatsOnPage &&
                  a.sourceId.isEmpty &&
                  a.id != next.backgroundImageId,
            )
            .lastOrNull;
        if (added != null) _placementHintId = added.id;
      }
    }
    // SAF YAZIM (yalnız başlık/gövde metni değişti, geri al düğmesinin durumu
    // dahil görünür hiçbir parça etkilenmedi): 3700 satırlık build'i her tuş
    // vuruşunda çalıştırmak "klavye açılırken kasıyor" şikayetinin başrolüydü
    // — denetleyici metni zaten ekranda, ekran geneli setState atlanır.
    final pureTyping =
        _sameVisual(note, next, ignoreAttachments: inkOnly) &&
        _undoStack.canUndo == wasUndo &&
        _undoStack.canRedo == wasRedo;
    if (pureTyping) {
      if (inkOnly) {
        for (final a in note.attachments) {
          _staleInk.putIfAbsent(a.id, () => a.ink);
        }
      }
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
        _clientStamped = true;
        _notesRepo?.updateNote(current, clientTime: true);
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
    // OKUMA GENİŞLİĞİ (geniş ekran, 2026-11-02): tam ekranda 1920 px'te
    // satırlar ~250 karaktere çıkıyordu. Sayfanın TAMAMI (metin, görseller,
    // mürekkep) ortada [kReadingWidth]'te durur: görsel x'i ve mürekkep
    // koordinatları sayfa genişliğine ORANLI saklandığından hepsi birlikte
    // ölçeklenir, metinle görsel birbirinden kaymaz. Kaydırma görünümü tam
    // genişlikte kalır — kenar boşluğunda da tekerlek kaydırır. Telefonda
    // (< 760) hiçbir şey değişmez.
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kReadingWidth),
        child: _withRuledLines(note, bodyStyle, PageInkStack(
      ink: _pageInkOf(note),
      page: textPagePosition(note).index + 1,
      penActive: _penMode,
      scroll: _pageScroll,
      child: NotePageCanvas(
      // KLAVYEDEN BAĞIMSIZ taban — bkz. [_stableCanvasHeight].
      minHeight: minHeight,
      placementHintId: _placementHintId,
      onPlacementHintShown: () => _placementHintId = null,
      images: imageAttachments,
      onRemove: _removeAttachment,
      onChanged: _updateAttachment,
      onInkChanged: _updateAttachmentInk,
      onChangedMany: _updateAttachments,
      onCrop: _cropImage,
      onRotate: _rotateImage,
      onExtractText: _ocrImage,
      onCopy: _copyAttachment,
      onCopyMany: _copyAttachments,
      onVideoToNote: _videoToNote,
      onTranscribe: _openTranscript,
      onSaveAs: (a) => unawaited(AttachmentSaveAs.run(context, ref, a)),
      onShare: (a) => unawaited(shareAttachment(context, ref, a)),
      onPinTop: _pinMediaTop,
      onPinHover: _setPinHover,
      onPinDrag: _setPinDrag,
      onViewChange: _readOnly
          ? null
          : (a, view) => unawaited(_setAttachmentView(a, view)),
      // Yazıya göm kısayolu (2026-11-01): gövdesi olan notta.
      onEmbed: _readOnly || note.type.isPageNoteType
          ? null
          : _startPendingEmbed,
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
              style: hintStyle.copyWith(color: _themeOf(context).hintColor),
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
    ))),
      ),
    ),
  );

  /// Belge notunda bir BALONA yazılıyor: editörün alt çubuğu gizlenir.
  bool _immersiveBubble = false;

  /// PDF/sunum sayfasının ÜZERİNE yazma kipi (alt çubuktaki kalem düğmesi).
  /// Tam ekrana geçmeden bölmede çizim yapılır; kip açıkken tek parmak çizer,
  /// iki parmak gezinir (kullanıcı isteği 2026-08-08).
  bool _penMode = false;

  NoteFullscreenNotifier? _fullscreenNotifier;

  late final OpenNoteIdsNotifier _openNotes;

  /// Metin/liste notunun sayfa üstü el yazısı (bkz. [PageInkStack]).
  InkController? _pageInkCtl;

  /// Metin/liste notunda kalem kipi mi (belge notunun kalemi kendi bölmesinde).
  bool get _pagePen => _penMode && !(_note?.type.isPageNoteType ?? false);

  /// Hızlı satırdaki kalem: AÇ / KAPA (kullanıcı isteği 2026-11-08: "kalem
  /// butonuna tekrar basınca kalem modu kapansın").
  void _togglePen() {
    _update(() => _penMode = !_penMode);
    if (_penMode) _penModeOpened();
  }

  /// Kalem kipi açıldı (düğmeyle ya da kalem değince). Kullanıcı isteği
  /// 2026-11-09: "kalem kipi açılınca 'sadece kalemle yaz açık/kapalı'
  /// söylenmeli, ipucuna tıklayıp ayara gidilmeli, her seferinde"; "kalem
  /// kipi ile yüzen kalem senkronu doğru çalışmalı" — kip açıkken yüzen
  /// düğme "kalem dokunur"da kalırsa kalem yazmıyordu.
  void _penModeOpened() {
    if (!InkToolMemory.autoStylus) InkToolMemory.saveAutoStylus(true);
    final note = _note;
    if (note == null || !mounted) return;
    final l10n = context.l10n;
    final page = !note.type.isPageNoteType;
    final ink = page ? _pageInkOf(note) : null;
    // Kalem görülmüş ve kullanıcı seçmemişse "yalnız kalem" ilk kalem
    // dokunuşunda KENDİLİĞİNDEN açılır (bkz. InkController.pointerDown) —
    // ipucu o andan önce okununca "parmak da yazar" diyordu ama parmak
    // yazmıyordu (cihazda görüldü 2026-11-10).
    final penOnly =
        (ink?.penOnly ?? InkToolMemory.penOnly) ||
        (InkToolMemory.stylusEver && !InkToolMemory.penOnlyChosen);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(
        penOnly ? l10n.penModePenOnlyOn : l10n.penModePenOnlyOff,
        duration: const Duration(seconds: 3),
        action: ink == null
            ? null
            : SnackBarAction(
                label: l10n.penModeSettings,
                onPressed: () => showInkSettings(context, ink),
              ),
      );
    // TELEFONDA ELLE YAZMA (F63.5, KALEM K5): parmak çiziyorsa sayfayı
    // kaydırmanın yolu iki parmak — cihazda bir kez söylenir.
    if (page && !penOnly) {
      TipOnce.show(
        context,
        ref.read(sharedPreferencesProvider),
        TipOnce.penTwoFinger,
        l10n.inkTwoFingerHint,
        sessionLimit: false,
      );
    }
  }

  /// Bu oturumda sayfaya çizilen çizgi sayısı (kalem ipuçlarının sırası).
  int _penStrokes = 0;

  /// Sayfa çizimi değişti: 2. çizgide "bekletince şekle oturur", 5.de
  /// "çizgiye basılı tut = silgi" (her biri cihazda bir kez).
  void _penTipAfterStroke() {
    _penStrokes++;
    final (String, String)? tip = switch (_penStrokes) {
      2 => (TipOnce.penShapeHold, context.l10n.tipPenShapeHold),
      5 => (TipOnce.penEraserHold, context.l10n.tipPenEraserHold),
      _ => null,
    };
    if (tip == null || !mounted) return;
    TipOnce.show(
      context,
      ref.read(sharedPreferencesProvider),
      tip.$1,
      tip.$2,
      sessionLimit: false,
    );
  }

  void _openPen() {
    _update(() => _penMode = true);
    _penModeOpened();
  }

  /// Tablette tam ekran düğmesi.
  Widget _fullscreenButton(AppLocalizations l10n) {
    final on = ref.watch(noteFullscreenProvider);
    return IconButton(
      key: const ValueKey('note-fullscreen'),
      tooltip: on ? l10n.noteFullscreenExit : l10n.noteFullscreen,
      icon: Icon(on ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
      onPressed: () => ref.read(noteFullscreenProvider.notifier).set(!on),
    );
  }

  /// Geniş ekranda not listesi şu an gizli mi (tam ekran ya da odak modu)?
  bool _listHidden(BuildContext context) =>
      SplitScope.maybeOf(context)?.listHidden ?? false;

  /// Tam ekrandan ve odak modundan çıkar: solda tek sütunluk liste görünür.
  void _showNoteList() {
    ref.read(noteFullscreenProvider.notifier).set(false);
    ref.read(listPaneCollapsedProvider.notifier).set(false);
    if (SplitScope.maybeOf(context)?.listAutoHides ?? false) {
      ref
          .read(listPeekLocationProvider.notifier)
          .set(currentLocation(GoRouter.of(context)));
    }
  }

  /// ☰ — gizli listeyi geri getirir (bkz. [_listHidden]).
  Widget _showListButton(AppLocalizations l10n) => IconButton(
    key: const ValueKey('note-show-list'),
    tooltip: l10n.showNoteList,
    icon: const Icon(Icons.menu_rounded),
    onPressed: _showNoteList,
  );

  /// Çubuğun sol yuvası: gizli liste ☰; dikey tablette açılmış liste kapanır.
  Widget? _listLeading(AppLocalizations l10n) {
    if (_listHidden(context)) return _showListButton(l10n);
    if (!(SplitScope.maybeOf(context)?.listAutoHides ?? false)) return null;
    return IconButton(
      key: const ValueKey('note-hide-list'),
      tooltip: l10n.listPaneHide,
      icon: const Icon(Icons.menu_open_rounded),
      onPressed: () => ref.read(listPeekLocationProvider.notifier).set(null),
    );
  }

  /// Klavye açıkken üst çubuğun başlık yuvası: hızlı işlev satırı
  /// (2026-11-08); kapalıyken [idle] (tarih + etiketler).
  Widget? _typingTitle(Note note, Widget? idle) {
    if (_readOnly || note.type.isPageNoteType) return idle;
    final pen = !note.type.isPageNoteType;
    // GENİŞ WEB'DE HEP AÇIK (kullanıcı isteği 2026-11-09: "webte hızlı menü
    // yok, kalemi açamıyorum"): web'de klavye boşluğu hiç oluşmadığından
    // satır hiç görünmüyordu. Geniş alanda düğmeler tarihin yanında sürekli;
    // sığmayanlar ⋮ menüsünde.
    final wide =
        kIsWeb && MediaQuery.sizeOf(context).width >= kRailBreakpoint;
    // Paket grubu (F60.2): satıra dokunmak açık paketi kapatmaz.
    final row = TapRegion(
      groupId: kNotePackageTapGroup,
      child: EditorQuickRow(
          fit: wide,
          onBold: () => _applyFormat(RichFormat.bold),
          onBullet: () => _runOnTarget(applyLineBullet),
          onCheckbox: note.type == NoteType.text ? _toggleChecklistLine : null,
          onHeading: () => _runOnTarget((c) {
            final next = switch (activeRichHeading(c)) {
              RichHeading.normal => RichHeading.h1,
              RichHeading.h1 => RichHeading.h2,
              RichHeading.h2 => RichHeading.normal,
            };
            return applyRichHeading(c, next);
          }),
          onPhoto: () {
            _rememberCaret();
            unawaited(_pickImage());
          },
          onFile: () => unawaited(_attachAnyFile()),
          onPen: pen ? _togglePen : null,
          penOn: _penMode,
          onPenSettings: pen
              ? () => showInkSettings(context, _pageInkOf(note))
              : null,
          onReminder: () => unawaited(_pickReminder()),
          // Ara başlık: satırı doğrudan alt başlık yapar (metin modu).
          onSubheading: note.type == NoteType.text
              ? () => _runOnTarget(
                  (c) => applyRichHeading(
                    c,
                    activeRichHeading(c) == RichHeading.h2
                        ? RichHeading.normal
                        : RichHeading.h2,
                  ),
                )
              : null,
          onSpell: () {
            AutoSpell.toggle();
            unawaited(_seedSpell());
          },
          onSpellSettings: () => showSpellSettings(context),
          onPackage: () => _packageFromQuickRow(note),
          packageHint:
              note.type == NoteType.text && suggestsPackage(note.body),
          onItalic: () => _applyFormat(RichFormat.italic),
          onUnderline: () => _applyFormat(RichFormat.underline),
          onHighlight: () => _applyFormat(RichFormat.highlight),
          onDictation: () => unawaited(_toggleDictation()),
          onCamera: kIsWeb
              ? null
              : () {
                  _rememberCaret();
                  unawaited(_takePhoto());
                },
          onScan: kIsWeb ? null : () => unawaited(_scanDocument()),
          onDate: () => _insertTextAtCaret(
            DateFormat.yMMMMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).add_Hm().format(DateTime.now()),
          ),
          onAttach: () => unawaited(_showAttachMenu()),
          onColor: () => _applyFormat(
            RichFormat.color,
            colorIndex: NoteFormatMemory.favoriteColor,
          ),
          onColorPick: () => unawaited(_pickFavoriteColor()),
          favoriteColor: _favoriteColorValue(),
          // Nota her girişte bir kez (durum örneği nota bağlı); setState
          // YOK — yalnız bir sonraki açılışta vurgulanmasın diye.
          hint: !_quickRowHinted,
          onHinted: () => _quickRowHinted = true,
      ),
    );
    if (wide) {
      return Row(
        children: [
          if (idle != null) Flexible(child: idle),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Align(alignment: AlignmentDirectional.centerStart, child: row)),
        ],
      );
    }
    return KeyboardSwitch(closed: idle, editing: _fieldFocusedN, open: row);
  }

  static Color _favoriteColorValue() {
    final i = NoteFormatMemory.favoriteColor;
    if (isCustomRichColor(i)) return Color(i);
    final palette = NoteColors.richPalette;
    return palette[(i - 1).clamp(0, palette.length - 1)];
  }

  /// Hızlı satırın Renk düğmesine basılı tut: renk seçilir, FAVORİ olur ve
  /// hemen uygulanır (kullanıcı isteği 2026-11-09).
  Future<void> _pickFavoriteColor() async {
    final selection = _bodyController.selection;
    final picked = await showColorPaletteSheet(
      context,
      title: context.l10n.formatTextColor,
    );
    if (picked == null || !mounted) return;
    final index = picked.toARGB32() | 0xFF000000;
    NoteFormatMemory.rememberFavoriteColor(index);
    // Levha açılırken seçim daralmış olabilir: renk seçilen yazıya gitsin.
    if (selection.isValid) _bodyController.selection = selection;
    setState(() {});
    _applyFormat(RichFormat.color, colorIndex: index);
  }

  /// Öğrenen yazım düzeltmenin kişisel sözlüğü: notların metni (arka
  /// planda, oturumda bir kez; yazım düzelt kapalıyken hiç).
  Future<void> _seedSpell() async {
    if (!mounted || !AutoSpell.enabled.value) return;
    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    await AutoSpell.seedFrom(
      () => [
        for (final n in notes.take(600)) ...[
          n.title,
          n.body,
          for (final i in n.items) i.text,
        ],
      ],
    );
  }

  /// Notun bir metin alanı (gövde, madde, başlık) odakta mı — tablette
  /// klavye boşluğu olmadan da hızlı satırı göstermek için
  /// ([KeyboardSwitch.editing]). Yalnız odak değişince güncellenir.
  final _fieldFocusedN = ValueNotifier<bool>(false);

  void _onAnyFocusChange() {
    if (!mounted) return;
    final node = _formatTarget?.focusNode;
    final on =
        node != null &&
        node.hasFocus &&
        _formatTarget?.controller != _titleController;
    if (_fieldFocusedN.value != on) _fieldFocusedN.value = on;
  }

  /// Bu not girişinde hızlı satır vurgusu gösterildi mi (bkz. [EditorQuickRow]).
  bool _quickRowHinted = false;

  /// Yazarken (klavye açık) üst çubukta yalnız hızlı satır + geri al/yinele
  /// kalır (kullanıcı isteği 2026-11-08): öbür düğmeler klavye açıkken
  /// gizlenir. Yaprak düzeyde ([KeyboardSwitch]) — ekran yeniden kurulmaz.
  Widget _hideWhileTyping(Note note, Widget child) =>
      _readOnly || note.type.isPageNoteType
      ? child
      : KeyboardSwitch(open: const SizedBox.shrink(), closed: child);

  /// Kalem kipinin sonu (tepsi/sütun sonunda): × kalemi kapatır (çizim
  /// kalır), ✓ bitirir — "Sayfaya yaz" ile açılan hızlı el yazısı notunda
  /// notu da kapatıp ana ekrana döner (kullanıcı isteği 2026-11-08).
  List<Widget> _penEndButtons(AppLocalizations l10n) {
    final scheme = _themeOf(context).colorScheme;
    return [
      IconButton.filledTonal(
        key: const ValueKey('pen-close'),
        tooltip: l10n.penModeDone,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHighest,
          foregroundColor: scheme.onSurfaceVariant,
        ),
        icon: const Icon(Icons.close_rounded, size: 20),
        onPressed: () => _update(() => _penMode = false),
      ),
      const SizedBox(width: 4),
      IconButton.filled(
        key: const ValueKey('pen-done'),
        tooltip: l10n.penModeFinish,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.check_rounded, size: 20),
        onPressed: () {
          _pageInkCtl?.save();
          _update(() => _penMode = false);
          if (!widget.startDrawing) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(Navigator.of(context).maybePop());
          });
        },
      ),
    ];
  }

  /// Bu açılışta ipucuna bakıldı mı (bkz. [_maybeShowTip]).
  bool _tipChecked = false;

  /// Balonlu görünümden sabite göç bir kez bakıldı mı (bkz. [_retireBubbleView]).
  bool _bubbleRetireChecked = false;

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

  /// Bir görsel taşınıyor: tepedeki hedef şerit (soluk) görünür (F13.6).
  bool _pinDrag = false;

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
                    color: _themeOf(context).colorScheme.onSurfaceVariant,
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
    // Web: Drive'daki belge önce iner (bkz. [WebDriveGate]); blob adresi
    // buluta yazılmaz (`Attachment.toMap`).
    final pane = WebDriveGate(
      attachment: doc,
      builder: (context, doc) => isSlides
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
          ),
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
  /// (PDF/sunum) sayfanın üstüne yazma kalemi, metin/liste notunda aynı
  /// sayfada kalem kipi (çizgi [PageInkStack]'te zaten başlamıştır). Ayar kalem ayarlarında ([InkToolMemory.autoStylus]); salt okunur
  /// notta, kalem kipi zaten açıkken ve yazma kartı açıkken çalışmaz. Kalemle
  /// araç çubuklarına dokunmak etkilenmez: dinleyici yalnız içerik alanında.
  /// Yüzen "kalem yazar / dokunur" düğmesi değişti (bkz. [StylusToggleOverlay]):
  /// kapanınca kalem kipi de kapanır, kalem metne/kaydırmaya gider.
  void _onStylusToggle() {
    if (!mounted) return;
    final ctl = _pageInkCtl;
    if (ctl != null) _syncPageInkKinds(ctl);
    if (!InkToolMemory.autoStylus && _penMode) {
      _update(() => _penMode = false);
    } else if (InkToolMemory.autoStylus &&
        !_penMode &&
        !_readOnly &&
        _note != null &&
        !_note!.type.isPageNoteType) {
      // Yüzen düğme "kalem yazar"a döndü: kalem kipi de açılır (senkron).
      _openPen();
    } else {
      setState(() {});
    }
  }

  void _onContentPointerDown(PointerDownEvent event) {
    // MADDE JESTLERİ her işaretçide izlenir; kalem maddede başladıysa el
    // yazısı tuvali açılmaz (bkz. note_editor_gestures.dart).
    if (_trackGestureDown(event)) return;
    if (event.kind != PointerDeviceKind.stylus &&
        event.kind != PointerDeviceKind.invertedStylus) {
      return;
    }
    // İlk kalem dokunuşunda yüzen düğme belirir (kalemsiz cihazda hiç yok).
    if (!InkToolMemory.stylusEver) {
      InkToolMemory.noteStylusEver();
      setState(() {});
    }
    final note = _note;
    if (note == null || _readOnly || !InkToolMemory.autoStylus) return;
    if (_gestureMode != _GestureMode.off) return;
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
    if (_penMode) return;
    HapticFeedback.selectionClick();
    // Neden açıldığı ve "yalnız kalem" durumu [_penModeOpened]'da söylenir.
    _openPen();
  }

  @override
  Widget build(BuildContext context) {
    // Drive'dan bir ek inince editör yeniden çizilir: ekranlar yerel
    // kopyayı çizim anında arıyor (bkz. localFilesRevisionProvider).
    ref.watch(localFilesRevisionProvider);
    // dispose'un kullanacağı bağımlılıklar her karede tazelenir (bkz. yukarı).
    _cacheDeps();
    // Ağaç bu kurulumla güncel eki alıyor: bayat mürekkep kaydı kalmaz.
    _staleInk.clear();
    // Tuval önbelleği YALNIZ bu build içindeki `LayoutBuilder` tekrarları
    // içindir (klavye animasyonunun kareleri). Editör yeniden kurulduğunda
    // bayat kalmasın diye burada, her şeyden önce düşürülür.
    _canvasCache = null;
    ref.listen<bool>(attachmentsExpandedProvider, (prev, next) {
      final opened = next && prev == false;
      if (opened != _stripOpenedHere) {
        setState(() => _stripOpenedHere = opened);
      }
    });
    final l10n = context.l10n;
    final note = _note;
    // Okunurluk teması aşağıda, not zemini hesaplanınca kurulur; o ana dek
    // (ve not yokken) dış tema.
    _editorInk[context] = null;
    // BİR KEZ ÇIKAN İPUCU (F14.6): not eline ilk geçtiğinde bir kez bakılır.
    if (!_tipChecked && note != null) {
      _tipChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTip());
    }
    // BALONLU GÖRÜNÜM KALKTI (2026-11-05): eski belge notu sabit görünüme
    // geçer. Ağır alanlar (balonlar) gelmeden yazılmaz; açılış geçişinin
    // ortasında yeniden çizim olmasın diye geçiş sonrasına.
    if (!_bubbleRetireChecked &&
        note != null &&
        !note.heavyMissing &&
        !_readOnly) {
      _bubbleRetireChecked = true;
      if (note.type.isPageNoteType || note.hasPageNotes) {
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) _retireBubbleView();
        });
      }
    }
    // Alt çubuğun iki yeni düğmesi için: sayfada YÜZMEYEN ekler (şerit) ve
    // notun belge notu olup olmadığı (kalem düğmesi yalnız orada anlamlı).
    final fileAttachments = [
      for (final a in (note?.attachmentsWithoutBackground ??
          const <Attachment>[]))
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
                        color: _themeOf(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noteNotFound,
                        textAlign: TextAlign.center,
                        style: _themeOf(context).textTheme.bodyMedium,
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
    // Zemin temanın yazısıyla okunmuyorsa notun içi zıt temada (bkz.
    // [_editorInk]). `Theme.of` BURADA bilerek dış tema: karar dış temaya göre.
    _editorInk[context] = NoteColors.inkThemeFor(Theme.of(context), background);
    // NOTUN VURGUSU — kartla AYNI (bkz. [NoteAccent]): kutucuk, "Yeni madde",
    // etiket/klasör/hatırlatıcı hapları ve raptiye bu tondan. Dış temadan
    // hesaplanır (zıt temada zemin yanlış hesaplanırdı).
    final noteAccent = NoteColors.noteInk(context, note);
    _barInk = noteAccent;
    _barPage = background;
    // Çizilmiş tema varsa sayfa ve üst çubuk saydam: süsleme arkadan görünür
    // (bkz. NoteThemeBackdrop); alt çubuk temanın alt tonunda düz kalır.
    final themed = NoteThemes.byId(note.theme) != null;
    // Satır içi biçimlendirmenin çizim ayarları: gövde ve maddeler AYNI
    // paleti kullanır (metindeki 1..5 indeksi her ikisinde aynı rengi verir).
    final richTheme = RichTextTheme(
      palette: NoteColors.richPalette,
      markerColor: _themeOf(
        context,
      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
      // Renkli yazı notun zeminine göre okunur hâle getirilir.
      background: background,
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
    final dark = _themeOf(context).brightness == Brightness.dark;
    if (!identical(note, _fedNote) || dark != _fedDark) {
      _fedNote = note;
      _fedDark = dark;
      _bodyController.attachmentNames = [
        // Eki silinmiş bağ etiket sayılmaz (çip görünümü kalmasın).
        for (final link in note.tagLinks)
          if (link.label.isNotEmpty &&
              (linkedNoteId(link) != null ||
                  note.attachments.any((a) => a.id == link.attachmentId)))
            link.label,
        for (final a in note.attachments) a.fileName,
      ];
      // Gömülü yazının ÇİP görünümü: ekin türüne göre renk ve rozet (bkz.
      // AttachmentTagChips). Denetleyici renkleri yalnız değişince alır.
      // Not bağlantısı (F18.16): hedef silinmiş/çöpteyse soluk.
      final liveIds = {
        for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
          if (n.deletedAt == null) n.id,
      };
      final tagLooks = embedTagLooks(note, dark: dark, liveNoteIds: liveIds);
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
    final theme = _themeOf(context);
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
    final titleInBar = _titleInBar(note);
    final titleBaseStyle = noteTitleStyle(
      theme,
      note,
      // Üst çubukta 48 dp'ye sığan boy (bkz. [_titleInBar]).
      fontSize:
          (titleInBar ? 18.0 : (theme.textTheme.headlineSmall?.fontSize ?? 24)) *
          note.titleFontScale,
    );
    // BAŞLIK ÜST ÇUBUKTA (kullanıcı isteği 2026-11-03: "üste sabitlemede
    // başlık sabitin üstünde olmalı; şu an not alanında kalıyor ve orayı
    // daraltıyor" + "balonlu PDF başlığını kaldır, ana sayfada yazmasına
    // gerek yok"): medya/belge notun TEPESİNDEYKEN (sabit bölme ya da
    // balonlu belge) başlık gövdeden kalkar, üst çubukta tarihin yerine
    // oturur — gövdede hiç satır harcamaz, belge ve not yukarı çıkar.
    final titleBaseSize = titleBaseStyle.fontSize ?? 24;
    final titleField = Padding(
      padding: titleInBar
          ? const EdgeInsetsDirectional.only(start: 4)
          : const EdgeInsetsDirectional.fromSTEB(16, 2, 4, 0),
      // Başlığın yazı ölçeği değişince yumuşak oturur (bkz. ScaleSettle).
      child: ScaleSettle(
      value: note.titleFontScale,
      // UZUN BAŞLIK KÜÇÜLEREK SIĞAR (kullanıcı isteği 2026-11-01, bkz.
      // [fitTitleFontSize]): yazı değiştikçe yalnız bu parça yeniden
      // kurulur. Satır yüksekliği taban boyda SABİT (strut) — yazı
      // küçülürken alttaki sayfa harf harf yukarı kaymasın.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _titleController,
        builder: (context, _, _) => LayoutBuilder(
          builder: (context, box) {
            // ÖLÇÜM ALANIN ÇİZDİĞİ STİLLE (kullanıcı bulgusu 2026-11-04:
            // "uzun başlık sağdaki çipin altına giriyor"). KÖK NEDEN:
            // TextField stili temanın `bodyLarge`ının ÜSTÜNE birleştirir;
            // başlık stili harf aralığı vermediği için alan `bodyLarge`ın
            // 0,5 aralığını miras alıyor, ölçüm ise aralıksız yapılıyordu —
            // 34 harflik başlık ~17 px dar ölçülüp "sığdı" sayılıyordu.
            final fieldStyle = fieldMergedStyle(
              Theme.of(context).textTheme.bodyLarge,
              titleBaseStyle,
            );
            final fitted = fitTitleFontSize(
              spanFor: (size) => _titleController.buildTextSpan(
                context: context,
                style: fieldStyle.copyWith(fontSize: size),
                withComposing: false,
              ),
              // İmleç ve iç dolgu payı.
              maxWidth: box.maxWidth - 8,
              baseSize: titleBaseSize,
              textScaler: MediaQuery.textScalerOf(context),
              textDirection: Directionality.of(context),
            );
            return TextField(
        controller: _titleController,
        focusNode: _titleFocus,
        readOnly: _readOnly,
        onChanged: (_) =>
            _mutate((n) => n.copyWith(title: _titleController.logicalText)),
        style: titleBaseStyle.copyWith(fontSize: fitted),
        strutStyle: StrutStyle(
          fontSize: titleBaseSize,
          height: titleBaseStyle.height,
          forceStrutHeight: true,
        ),
        // TEK SATIR (kullanıcı isteği 2026-08-08: "başlık tek satırdan
        // taşmasın"): sığmayan başlık önce küçülür (yukarıda), en küçük
        // boyda da sığmazsa alanın içinde yatay kayar.
        // ignore: avoid_redundant_argument_values
        maxLines: 1,
        // Başlıkta kelime başları büyük (kullanıcı isteği 2026-11-08): sanal
        // klavye kendisi büyütür; fiziksel klavye/web için yazım düzelt
        // açıkken [AutoSpell] (title kipi) aynı kuralı uygular.
        textCapitalization: TextCapitalization.words,
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
      );
          },
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
    // Ortak çalışan eklenebilir mi: yalnız bu cihazdaki not kimseyle
    // paylaşılamaz; kişiselleştirmede "Ortak çalışma" kapatılabilir.
    final canCollab =
        Customizable.shows(UiItem.topCollab) &&
        (widget.ownerId != null ||
            !(ref.read(notesRepositoryProvider)?.isLocal(widget.noteId) ??
                false));
    // TEK "+" (F38.3): ne dolu olduğu çip şeridinde; paylaşım durumu yanında
    // (paylaşılmışsa). Levha [_openMetaMenu]; `note-meta-chip` anahtarı korunur.
    final actionsMenu = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canCollab) _collabMarker(theme),
        IconButton(
          key: const ValueKey('note-meta-chip'),
          tooltip: l10n.noteMetaMenu,
          visualDensity: VisualDensity.compact,
          icon: ValueListenableBuilder<bool>(
            valueListenable: _titleGeneratingN,
            builder: (context, generating, _) => generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.add,
                    size: 22,
                    color: noteAccent ?? theme.colorScheme.onSurfaceVariant,
                  ),
          ),
          onPressed: () =>
              _openMetaMenu(note, noteFolder?.iconData, canCollab: canCollab),
        ),
      ],
    );

    // Çip yazısı: gövdeyle aynı aileden ama küçük — satır üst bar ile başlık
    // arasındaki dar banda sığmalı (bkz. [metaChips]).
    final chipLabelStyle = theme.textTheme.labelMedium?.copyWith(
      fontSize: 12.5,
      // Haplar kartın etiketiyle aynı: renkli notta koyu ton, renksizde soluk.
      color: noteAccent ?? theme.colorScheme.onSurfaceVariant,
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
          avatar: Icon(
            note.reminderRepeat.isEmpty ? Icons.alarm : Icons.repeat,
            size: 14,
          ),
          // Dar alanda çip etiketleri KISALTILIR (`...`): sığmayan bir metin
          // `Chip` içinde taşma hatası verir.
          label: Text(
            note.reminderRepeat.isEmpty
                ? DateFormat('d MMM HH:mm').format(note.reminderAt!)
                : '${DateFormat('d MMM HH:mm').format(note.reminderAt!)} · '
                      '${reminderRepeatLabel(context.l10n, ReminderRepeat.parse(note.reminderRepeat))}',
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
      // GERİ BAĞLANTILAR (F18.16): bu nota bağlanan notlar. YALNIZ varken
      // listeye girer — KÖK NEDEN (kullanıcı bulgusu 2026-11-05: "etiket
      // satırından kalan kısım boşluk olarak kalmış"): çip boşken kendini
      // `SizedBox.shrink` çiziyordu ama listede durduğu için şerit hiç boş
      // sayılmıyor, etiketler üst çubuğa taşındıktan sonra başlığın altında
      // 36 dp'lik boş bir bant kalıyordu.
      if (backlinksTo(
        note.id,
        ref.watch(notesStreamProvider).value ?? const <Note>[],
      ).isNotEmpty)
        BacklinksChip(
          noteId: note.id,
          notes: ref.watch(notesStreamProvider).value ?? const <Note>[],
          labelStyle: chipLabelStyle,
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
      // Etiketler üst çubukta, tarihin solunda (kullanıcı isteği
      // 2026-11-05); başlık çubuktayken tarih yok — o zaman burada.
      if (titleInBar)
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
            // Renkli notta hapların çerçevesi, simgesi ve × işareti notun
            // koyu tonunda (yazısı [chipLabelStyle]'da) — kartla aynı ton.
            child: ChipTheme(
              data: noteAccent == null
                  ? theme.chipTheme
                  : theme.chipTheme.copyWith(
                      side: BorderSide(
                        color: noteAccent.withValues(alpha: 0.45),
                      ),
                      deleteIconColor: noteAccent,
                      iconTheme: IconThemeData(color: noteAccent, size: 14),
                    ),
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
    final bubbleCaptionOwner = bubbleDocument == null
        ? null
        : note.attachments
              .where(
                (a) => a.id == bubbleDocument.sourceId && a.caption.isNotEmpty,
              )
              .firstOrNull;
    final titleRow = titleInBar
        // Başlık ve "+" üst çubukta; gövdede yalnız balonlu belgenin görünüm
        // anahtarı kalır (çip satırının sağında — ayrı satır harcamaz).
        ? null
        : Row(
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
    _barTitle = titleInBar
        ? Row(
            children: [
              Expanded(child: titleField),
              actionsMenu,
            ],
          )
        : null;

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
        ?titleRow,
        if (titleRow == null && bubbleSwitch != null)
          Row(
            children: [
              Expanded(child: metaChips),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 10, 2),
                child: bubbleSwitch,
              ),
            ],
          )
        else
          metaChips,
        // Takvim bağı hapı (TAKVIM F49.2): bağ yoksa yer kaplamaz.
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          child: NoteCalendarPills(noteId: note.id),
        ),
        // Görselden üretilmiş belgede açıklama görselindir (F40.7).
        if (bubbleCaptionOwner != null)
          Center(
            child: AttachmentCaptionBand(
              text: bubbleCaptionOwner.caption,
              onTap: _readOnly
                  ? null
                  : () => unawaited(_editCaption(bubbleCaptionOwner)),
            ),
          ),
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
      builder: (fieldContext) {
        void onBodyTap() {
        final editable = editableTextBelow(fieldContext);
        // PDF REFERANSI (📖 s.12): belge o sayfaya döner.
        final pdfRef = _tappedPdfRef(editable);
        if (pdfRef != null) {
          editable?.hideToolbar();
          _goToPdfPage(pdfRef.page);
          return;
        }
        final seconds = _tappedTimestamp(editable);
        if (seconds != null) {
          editable?.hideToolbar();
          _seekVideoTo(seconds);
          return;
        }
        // NOT BAĞLANTISI (F18.16): okurken açar, yazarken önerir.
        final linked = _tappedNoteLink(editable);
        if (linked != null) {
          editable?.hideToolbar();
          _openLinkedNote(linked, editing: _bodyTapPoint.wasFocused);
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
          displayText: _bodyField.text,
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
        }

        Widget fieldOf(bool top, bool bottom) => AttachmentTagChips(
        key: _bodyFieldKey,
        controller: _bodyField,
        looks: _tagLooks,
        child: _bodyTapPoint.wrap(
        TextField(
          controller: _bodyField,
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
            // `[[` yazınca not seçici (F18.16): iki parantez silinir, seçilen
            // notun başlığı bağlantı olarak imlece yazılır.
            _maybeLinkTrigger(before, after);
            if (_windowAllowed(note)) _bodyWindow.enter();
          },
          maxLines: null,
          minLines: _bodyWindow.active
              ? 1
              : note.items.isEmpty
              ? 8
              : 2,
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
          onTap: onBodyTap,
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
            contentPadding: EdgeInsets.only(
              top: top ? _kBodyTextTop : 0,
              bottom: bottom ? _kBodyTextTop : 0,
            ),
          ),
        ),
        // Damgaya/etikete dokunmak klavyeyi AÇMAZ (bkz. TapPointTracker.wrap).
        focusNode: _bodyFocus,
        keepsKeyboardClosed: (global) => linkAtPoint(
          editable: editableTextBelow(fieldContext),
          displayText: _bodyField.text,
          global: global,
          timestamps: _note != null && _hasVideo(_note!),
          pdfRefs: _note != null && _pdfForRefs(_note!) != null,
          tagNames: _bodyController.attachmentNames,
        ),
        ),
        );

        // Uzun notta yazarken (F24.2): alan aynı State'le ([_bodyFieldKey])
        // pencere parçalarının arasına taşınır, klavye kapanmaz.
        if (_bodyWindow.active && !_windowAllowed(note) && !noteRouteClosing.value) {
          _bodyWindow.exit(notify: false);
        }
        if (!_bodyWindow.active) return fieldOf(true, true);
        return WindowedBodyField(
          window: _bodyWindow,
          style: windowedFieldStyle(context, noteBodyStyle),
          strut: wrapStrutStyle(noteBodyStyle),
          linkColor: _themeOf(context).colorScheme.primary,
          topPadding: _kBodyTextTop,
          field: fieldOf,
          onTileTap: (offset, global) {
            _bodyWindow.moveCaretTo(offset);
            _bodyTapPoint
              ..last = global
              ..wasFocused = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) onBodyTap();
            });
          },
          onTileLongPress: (offset, global) {
            _bodyWindow.moveCaretTo(offset);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                selectWordAt(editableTextBelow(fieldContext), global);
              }
            });
          },
        );
      },
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
        onMakeTask: _readOnly ? null : (item) => _makeTask(note, item),
        onLineReminder: _readOnly
            ? null
            : (item) => unawaited(
                addLineReminder(
                  context,
                  ref,
                  noteId: note.id,
                  itemId: item.id,
                  text: item.text,
                ),
              ),
        lineTrailing: (item) => LineTaskChip(noteId: note.id, itemId: item.id),
        onItemChecked: (item, checked) =>
            syncItemToTasks(ref, note.id, item.id, checked),
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
        onMakeTask: _readOnly ? null : (item) => _makeTask(note, item),
        onLineReminder: _readOnly
            ? null
            : (item) => unawaited(
                addLineReminder(
                  context,
                  ref,
                  noteId: note.id,
                  itemId: item.id,
                  text: item.text,
                ),
              ),
        lineTrailing: (item) => LineTaskChip(noteId: note.id, itemId: item.id),
        onItemChecked: (item, checked) =>
            syncItemToTasks(ref, note.id, item.id, checked),
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
    // KALEM ÇEKMECESİ (kullanıcı isteği 2026-11-02): telefonda da tablette
    // de kalemler ALTTA, sayfanın üstünde yüzen bir çekmecede (bkz.
    // PenTray.dock). Sayfa yerleşimi kalem kipinde değişmez; çubuk yer
    // kaplamaz.
    // Sayfa ortada okuma sütununda mı (bkz. [_buildCanvas]): sabit medya ve
    // belge notunda sayfa bölmeyi doldurur, çubuklar da.
    final readingColumn = !note.type.isPageNoteType && !_titleInBar(note);
    // KISA PENCERE (F66.7/F67.4: yatay telefon, < 480 dp): üst çubuk 40 dp.
    // `sizeOf` klavyeyle değişmez — klavye kareleri kök kurulumu görmez.
    final toolbarHeight =
        WindowClass.of(context).height == WindowHeight.short
        ? 40.0
        : _kEditorToolbarHeight;
    final Widget? bottomBar = _immersiveBubble || _pagePen
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
                // Sayfa üstüne yazma kipi de geri tuşuyla biter (önce kip,
                // sonra not).
                BackCloses(
                  open: _penMode,
                  onClose: () => _update(() => _penMode = false),
                  child: const SizedBox.shrink(),
                ),
                BackCloses(
                  open:
                      _stripOpenedHere &&
                      ref.watch(attachmentsExpandedProvider),
                  onClose: () {
                    _stripOpenedHere = false;
                    ref.read(attachmentsExpandedProvider.notifier).toggle();
                  },
                  child: AttachmentStrip(
                  attachments: [
                    for (final a in note.attachmentsWithoutBackground)
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
                // WEB: Drive'daki ya da telefondan çıkmamış ekler için tek
                // şerit (kullanıcı bulgusu 2026-11-02: "ekler hâlâ webte
                // gelmiyor").
                if (kIsWeb) WebAttachmentsBanner(attachments: note.attachments),
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
                  // Paket grubu (F60.2): biçim paneli açık paketi kapatmaz.
                  child: TapRegion(
                  groupId: kNotePackageTapGroup,
                  child: AnimatedSize(
                    duration: _kBarSwap,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.bottomCenter,
                    child: !_formatBarOpen || _findOpen
                        ? const SizedBox.shrink()
                        : RevealUp(
                          child: SingleChildScrollView(
                            child: Center(
child: ConstrainedBox(
constraints: BoxConstraints(
maxWidth: readingColumn ? kReadingWidth : double.infinity,
),
child: ClipRRect(
// Sütunda sayfanın üstünde kart: köşesiz kutu kopuk duruyordu.
// Dar ekranda kenardan kenara, köşe yok.
clipBehavior:
readingColumn && MediaQuery.sizeOf(context).width > kReadingWidth
? Clip.antiAlias
: Clip.none,
borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                              onFontChanged: (family) {
                                // Gövdenin tipi yeni notlara da (F56.3).
                                if (!_titleIsTarget) {
                                  NoteFormatMemory.rememberFamily(family);
                                }
                                _mutate(
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
                              );
                              },
                              // Sürüklerken yalnız yerel durum + gecikmeli kayıt: her kare
                              // Firestore'a yazmak boşuna trafik olurdu.
                              onScaleChanged: (value) => _mutate(
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleFontScale: value)
                                    : n.copyWith(fontScale: value),
                              ),
                              onScaleEnd: (value) {
                                // Notun tamamına uygulandıysa yeni notlara da
                                // (F56.3); seçili aralık ve başlık hariç.
                                if (!_titleIsTarget &&
                                    !(_formatTarget != null &&
                                        _hasSelection())) {
                                  NoteFormatMemory.rememberScale(value);
                                }
                                _applyStepOrNote(
                                RichFormat.size,
                                kRichSizeSteps,
                                kRichSizeDefault,
                                value,
                                (n) => _titleIsTarget
                                    ? n.copyWith(titleFontScale: value)
                                    : n.copyWith(fontScale: value),
                              );
                              },
                              // Başlık yalnız GÖVDEDE ve maddelerde: notun
                              // başlık alanı zaten başlık.
                              onHeading: _titleIsTarget
                                  ? null
                                  : (h) => _runOnTarget(
                                      (c) => applyRichHeading(c, h),
                                    ),
                              onClose: () =>
                                  setState(() => _formatBarOpen = false),
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
                    builder: (context, _) => Center(
child: ConstrainedBox(
constraints: BoxConstraints(
maxWidth: readingColumn ? kReadingWidth : double.infinity,
),
child: NoteFindBar(
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
),
),
                  )
                // BİÇİM PANELİ AÇIKKEN alt çubuk GİZLİ (kullanıcı isteği
                // 2026-10-20: "biçim paneli açılınca alttaki ses, ek vb.
                // kısımlar gizlensin, yazmaya yer kalmıyor"). Panel kendi
                // kapat (⌄) düğmesiyle kapanır.
                else
                // Yazarken gizleme DIŞTA (2026-11-10): içte olunca
                // AnimatedSize onun tek adımlık boy değişimini de 260 ms'lik
                // kare kare yerleşime çeviriyordu.
                // Paket grubu (F60.2): alt çubuk açık paketi kapatmaz.
                // KISA PENCERE + KLAVYE (F67.4): alt çubuk gizli, hızlı satır
                // yeter. Kayıt/dikte sürerken durdur düğmesi kalsın.
                ShortKeyboardBarHide(
                keep: _voiceRecorder != null || _dictation != null,
                child: TapRegion(
                groupId: kNotePackageTapGroup,
                child: TypingBarHide(
                  hidden: _typingN,
                  enabled: ref.watch(hideBarWhileTypingProvider),
                  child: AnimatedSize(
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
                  color: _themeOf(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                // SIKI ÇUBUK (kullanıcı isteği 2026-11-03: "telefon
                // butonları ile kendi butonlarımız arasında boşluk çok,
                // satır aralığını daraltırsak yer açılır"): 64 → 56 dp,
                // dikey dolgu 8 → 4 (düğmeler 48 dp dokunma alanında kalır).
                // %10 daha alçak (kullanıcı isteği 2026-11-08): 56 → 50 dp,
                // dikey dolgu 4 → 1 — en büyük düğme (48 dp) hâlâ sığar.
                BottomAppBar(
                  color: background,
                  height: 50,
                  padding: const EdgeInsets.fromLTRB(12, 1, 12, 1),
                  // KİŞİSELLEŞTİRME (kullanıcı isteği 2026-10-16): her
                  // düğme gizlenebilir; düzenleme modunda hepsi çerçeveli
                  // görünür ve dokunmak gizle/göster yapar (bkz.
                  // Customizable). Çubuk yalnız bu tercihleri dinler.
                  // Okuma sütunuyla hizalı (F44.3); çubuğun zemini tam genişlik.
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: readingColumn
                            ? kReadingWidth - 24
                            : double.infinity,
                      ),
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
                      // KALEM (F75.1): metin/liste notunda sayfa kalemi
                      // (salt okunurda yok — hızlı satırla aynı kural), belge
                      // notunda sayfanın üzerine yazma.
                      final wantPen =
                          (isDocumentNote || !_readOnly) &&
                          on(UiItem.barPen);
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
                      // SONRADAN EKLENEN düğmeler (kullanıcı isteği
                      // 2026-11-13: Ayarlar → Kişiselleştir → Alt çubuk).
                      // Varsayılan gizli; açılınca kapsüle sırasıyla girer.
                      final extras = <String>[
                        if (!_readOnly) UiItem.barUndo,
                        if (!_readOnly) UiItem.barRedo,
                        UiItem.barReminder,
                        if (!_readOnly) UiItem.barPhoto,
                        if (!_readOnly && !kIsWeb) UiItem.barCamera,
                        if (!_readOnly && !kIsWeb) UiItem.barScan,
                        UiItem.barColor,
                        UiItem.barShare,
                      ].where(on).toList();
                      // Genişliğe göre plan: taşma/kesik kapsül yerine önce
                      // düğmeler küçülür, sonra ⋮ menüsünde de bulunan
                      // Ara, en son Kalem kapsülden çıkar (bkz.
                      // planEditorBar).
                      final plan = planEditorBar(
                        width: constraints.maxWidth,
                        fixedSegments:
                            (showFormat ? 1 : 0) +
                            (showAdd ? 1 : 0) +
                            (showCheckbox ? 1 : 0) +
                            (showSelect ? 1 : 0) +
                            extras.length,
                        attachments: showAttachments,
                        pen: wantPen,
                        aiButtons: aiCount,
                      );
                      final showPen = plan.pen;
                      final showSearch =
                          plan.search && on(UiItem.barSearch);
                      _barHasSearch = showSearch && !editingUi;
                      // Biçim · Ekle · Kalem · Ara · Ekler · (☑ | Seç).
                      // Gerekçeler:
                      // "Metin/Liste ekle" Ekle levhasında (attach_sheet);
                      // SEÇ burada (2026-08-09), simgesi `select_all`
                      // (2026-09-01: `checklist` "liste ekle" ile
                      // karışıyordu), madde yoksa gizli; ARA alt çubukta
                      // (2026-09-01) ve ⋮ menüsünde de; PAYLAŞ'ın yerine
                      // KALEM (K-D6, 2026-11-12 — Paylaş ⋮ menüsünün hızlı
                      // satırında); EKLER şeridin aç/kapası (2026-08-08).
                      Widget tool(
                        String id,
                        IconData icon,
                        String label,
                        VoidCallback onTap, {
                        bool active = false,
                      }) => Customizable(
                        id: id,
                        child: _toolSegment(
                          icon: icon,
                          label: label,
                          active: active,
                          onTap: onTap,
                        ),
                      );
                      // Kimlik → düğme(ler). Sıra KULLANICININ
                      // ([UiPrefs.barOrder]); varsayılan sıra
                      // [UiItem.barLeftDefault] (türe özgü ☑/Seç sonda).
                      final byId = <String, List<Widget>>{
                        if (showFormat)
                          UiItem.barFormat: [
                            tool(
                              UiItem.barFormat,
                              Icons.text_format,
                              l10n.formatTitle,
                              () => setState(
                                () => _formatBarOpen = !_formatBarOpen,
                              ),
                              active: _formatBarOpen,
                            ),
                            // Panel kapalıyken imlecin biçimleri (B/I/U, renk).
                            ActiveFormatBadges(target: _formatTargetN),
                          ],
                        if (showAdd)
                          UiItem.barAdd: [
                            Customizable(
                              id: UiItem.barAdd,
                              child: _addToolButton(l10n),
                            ),
                          ],
                        if (showPen)
                          UiItem.barPen: [
                            Customizable(
                              id: UiItem.barPen,
                              child: _penSegment(l10n, note),
                            ),
                          ],
                        if (showSearch)
                          UiItem.barSearch: [
                            tool(
                              UiItem.barSearch,
                              Icons.search,
                              l10n.noteSearchTitle,
                              _openNoteSearch,
                            ),
                          ],
                        // EKLER (F12.3): yalnız ekli notta; plan
                        // (planEditorBar) eki hesaba katar.
                        if (showAttachments)
                          UiItem.barAttachments: [
                            Customizable(
                              id: UiItem.barAttachments,
                              child: _attachmentsToggle(
                                l10n,
                                fileAttachments.length,
                              ),
                            ),
                          ],
                        if (showCheckbox)
                          UiItem.barCheckbox: [
                            tool(
                              UiItem.barCheckbox,
                              Icons.check_box_outlined,
                              l10n.checkboxToggle,
                              _toggleChecklistLine,
                            ),
                          ],
                        if (showSelect)
                          UiItem.barSelect: [
                            tool(
                              UiItem.barSelect,
                              Icons.select_all,
                              l10n.select,
                              () => _itemsEditorKey.currentState
                                  ?.startSelection(),
                            ),
                          ],
                        for (final id in extras)
                          id: [
                            switch (id) {
                              UiItem.barUndo => tool(
                                id,
                                Icons.undo,
                                l10n.undo,
                                () {
                                  if (_canUndo) _undo();
                                },
                              ),
                              UiItem.barRedo => tool(
                                id,
                                Icons.redo,
                                l10n.redo,
                                () {
                                  if (_canRedo) _redo();
                                },
                              ),
                              UiItem.barReminder => tool(
                                id,
                                Icons.alarm_add_outlined,
                                l10n.quickRowReminder,
                                () => unawaited(_pickReminder()),
                              ),
                              UiItem.barPhoto => tool(
                                id,
                                Icons.add_photo_alternate_outlined,
                                l10n.quickRowPhoto,
                                () {
                                  _rememberCaret();
                                  unawaited(_pickImage());
                                },
                              ),
                              UiItem.barCamera => tool(
                                id,
                                Icons.photo_camera_outlined,
                                l10n.quickRowCamera,
                                () {
                                  _rememberCaret();
                                  unawaited(_takePhoto());
                                },
                              ),
                              UiItem.barScan => tool(
                                id,
                                Icons.document_scanner_outlined,
                                l10n.quickRowScan,
                                () => unawaited(_scanDocument()),
                              ),
                              UiItem.barColor => tool(
                                id,
                                AppIcons.color,
                                l10n.color,
                                () => unawaited(_showColorSheet()),
                              ),
                              _ => tool(
                                id,
                                Icons.share_outlined,
                                l10n.share,
                                () => unawaited(_share()),
                              ),
                            },
                          ],
                      };
                      final segments = <Widget>[
                        for (final id in UiPrefs.orderOf(
                          UiItem.barLeftDefault,
                          uiPrefs.barOrder,
                        ))
                          ...?byId[id],
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
                              // Dolgu Row'un DIŞINDA değil içinde (F75.2):
                              // Row kapsülün tam boyunda (48 dp) olmalı ki
                              // segmentlerin dokunma payı (bkz. _barTarget)
                              // yakalansın. Görünüş aynı: çerçeve 1 + dolgu 3.
                              child: DecoratedBox(
                                key: const ValueKey('editor-tool-capsule'),
                                // Renkli notta notun tonu (F75.3, K-D6).
                                decoration: BoxDecoration(
                                  color: noteAccent == null
                                      ? _themeOf(context).colorScheme.surface
                                      : Color.alphaBlend(
                                          noteAccent.withValues(
                                            alpha: AppAlpha.hairline,
                                          ),
                                          background,
                                        ),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color:
                                        noteAccent?.withValues(
                                          alpha: AppAlpha.pressed,
                                        ) ??
                                        _themeOf(
                                          context,
                                        ).colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: SizedBox(
                                  height: _kToolSegment + 8,
                                  child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var i = 0;
                                        i < segments.length;
                                        i++) ...[
                                      if (i > 0)
                                        const SizedBox(
                                          width: kEditorBarSegmentGap,
                                        ),
                                      segments[i],
                                    ],
                                  ],
                                ),
                                ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                for (final id in UiPrefs.orderOf(
                                  UiItem.barRightDefault,
                                  uiPrefs.aiOrder,
                                ))
                                  if (id == UiItem.barAi && showAi)
                                  Customizable(
                                    id: UiItem.barAi,
                                    child: Consumer(
                                      builder: (context, ref, _) => _voiceButton(
                                      size: plan.button,
                                      gap: plan.gap,
                                      // Rozet görünmeyen için de durum.
                                      tooltip: aiStatusTitle(
                                        l10n,
                                        ref.watch(aiAvailabilityProvider),
                                      ),
                                      icon: Icons.auto_awesome,
                                      badge:
                                          ref.watch(aiAvailabilityProvider) ==
                                              AiAvailability.ready
                                          ? null
                                          : Icons.lock_outline,
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
                                  )
                                  else if (id == UiItem.barVoiceRecord &&
                                      showVoiceRecord)
                                  Customizable(
                                    id: UiItem.barVoiceRecord,
                                    child: _voiceButton(
                                      size: plan.button,
                                      gap: plan.gap,
                                      tooltip: _voiceRecorder == null
                                          ? l10n.recordAudio
                                          : l10n.stopAndSave,
                                      icon: AppIcons.voiceRecord,
                                      active: _voiceRecorder != null,
                                      onTap: () => unawaited(
                                        _voiceRecorder == null
                                            ? _recordAudio()
                                            : _finishVoiceRecording(),
                                      ),
                                    ),
                                  )
                                  else if (id == UiItem.barDictation &&
                                      showDictation)
                                  Customizable(
                                    id: UiItem.barDictation,
                                    child: _voiceButton(
                                      size: plan.button,
                                      gap: plan.gap,
                                      tooltip: l10n.liveDictation,
                                      icon: _dictating
                                          ? Icons.stop
                                          : AppIcons.dictation,
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
                  ),
                ),
                ],
                ),
                ),
                ),
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
          // Esc BURADA BAĞLANMAZ (tablet bulgusu 2026-11-09: "fiziksel
          // klavyede Esc geri yapmıyor"). KÖK NEDEN: `Navigator.maybePop`
          // bölünmüş ekranda kabuğun iç gezginine gidiyordu — tek sayfa,
          // kapanacak bir şey yok — ama tuş "işlendi" sayıldığı için
          // uygulamanın [EscBackAction]'ı (geri tuşu yolu: PopScope sırası →
          // tam ekran, arama, not) hiç çalışmıyordu.
          if (PenTray.useRail(context))
            const SingleActivator(
              LogicalKeyboardKey.keyF,
              control: true,
              shift: true,
            ): () => ref
                .read(noteFullscreenProvider.notifier)
                .set(!ref.read(noteFullscreenProvider)),
        },
        // Geri tuşu önce CANLI ARAMAYI kapatır, notu değil.
        child: PopScope(
          // Geri tuşu sırayla: tam ekran → kayıt → biçim paneli → canlı
          // arama → not.
          canPop:
              !_findOpen &&
              !_formatBarOpen &&
              _voiceRecorder == null &&
              !ref.watch(noteFullscreenProvider),
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            // Açık bir alt panel (ek şeridi, kalem/biçim tepsisi…) varsa geri
            // ONUN — ekranın kendi kipleri sonra.
            if (BackCloses.handling(context)) return;
            if (ref.read(noteFullscreenProvider)) {
              _showNoteList();
              return;
            }
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
          // Notun vurgusu alt ağaca (madde kutucukları, "Yeni madde") —
          // kartla aynı kaynak (bkz. [NoteAccent]).
          child: NoteAccent(
          accent: noteAccent,
          background: background,
          // Ağaç şekli hep aynı (Theme her zaman var): renk eşiği aşılınca
          // editörün alt ağacı yeniden kurulmasın (odak/kaydırma korunur).
          child: Theme(
          data: _themeOf(context),
          // Sayfa rengi Scaffold'un ARKASINDA, 200 ms'de değişir (F34.4):
          // editörün dev ağacı her karede yeniden kurulmaz. Üst çubuk saydam.
          child: ColorFade(
          color: themed ? Colors.transparent : background,
          identity: (note.id, Theme.of(context).brightness),
          builder: (context, color, child) =>
              ColoredBox(color: color, child: child),
          // Scaffold ve altı klavyenin karelerini GÖRMEZ (F60.S5): kararlı
          // MediaQuery; canlı değer yalnız [KeyboardInset.liveOf] okuyan
          // yapraklarda (bkz. [KeyboardInsetScope]).
          child: KeyboardInsetScope(
          child: Scaffold(
          backgroundColor: Colors.transparent,
          // **KASMA — klavye boşluğu artık KARARLI** (bkz. [KeyboardSnap]).
          // Scaffold gövdeyi klavye animasyonunun HER karesinde kısaltıyordu;
          // görselli/uzun notlarda ve PDF bölmesinde yalnızca bu yeniden
          // ölçüm bile takılma yaratıyor. Boşluk aşağıda, gövdenin
          // dolgusundan veriliyor ve bir açılış/kapanışta EN ÇOK BİR KEZ
          // değişiyor; çubuğun klavyeyle birlikte akan hareketi ise
          // [KeyboardSlide] ile yalnız boyama katmanında yapılıyor.
          resizeToAvoidBottomInset: false,
          // Kalem + tam ekran: üst de sayfa olur (çıkış sütunda).
          appBar: _pagePen && ref.watch(noteFullscreenProvider)
              ? null
              : HomeInBar(appBar: PreferredSize(
                  preferredSize: Size.fromHeight(toolbarHeight),
                  // Bölmenin genişliği: tarih okuma sütunuyla hizalı (F38.2).
                  // `_`: `_themeOf` ekranın kendi bağlamından okur.
                  child: LayoutBuilder(
                    builder: (_, box) => AppBar(
            // SIKI ÜST ÇUBUK (kullanıcı isteği 2026-11-03): 56 → 48 dp —
            // durum çubuğu ile düğmeler arasındaki boşluk yer harcıyordu;
            // simge düğmeleri 48 dp dokunma alanını korur.
            toolbarHeight: toolbarHeight,
            // Liste gizliyken (tam ekran / odak modu) geri okunun yerinde ☰:
            // tek dokunuşla liste geri gelir (kullanıcı isteği 2026-11-02:
            // "tam ekrandan çıkmak çok zor").
            leading: _listLeading(l10n),
            backgroundColor: Colors.transparent,
            // Düğmeler okuma sütununun sağ kenarında biter (F44.3).
            actionsPadding: EdgeInsetsDirectional.only(
              end: readingColumn ? readingMargin(box.maxWidth) : 0,
            ),
            // Saydam çubukta Flutter simge rengini zeminden çıkaramaz (çizilmiş
            // temalı notta beyaz simge kalıyordu): sayfanın rengine göre (F30.6).
            systemOverlayStyle: _statusBarFor(background),
            scrolledUnderElevation: 0,
            // Başlık yerinde düzenleme tarihi: notun kendi başlığı zaten gövdenin
            // en üstünde duruyor, üst barda ikinci kez göstermek yer harcıyordu.
            // Sabitlenmiş/yıldızlı göstergesi tarihin yanında — düğmeler ⋯
            // menüsüne taşındığı için durum bir yerde görünmeliydi.
            titleSpacing: editorTitleSpacing(
              readingColumn ? box.maxWidth : 0,
              hasLeading:
                  _listLeading(l10n) != null ||
                  (Navigator.maybeOf(context)?.canPop() ?? false),
            ),
            title: _barTitle ??
                _typingTitle(
                  note,
                  note.updatedAt == null && note.tags.isEmpty
                ? null
                : Customizable(
                    id: UiItem.editorDate,
                    child: Row(
                    children: [
                      // ETİKETLER TARİHİN SOLUNDA (kullanıcı isteği
                      // 2026-11-05): gövdedeki çip şeridi yalnız etiket
                      // için bir satır harcıyordu. Çok etiket yana kayar;
                      // dokununca "Etiketi kaldır".
                      if (note.tags.isNotEmpty)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: EditorBarTags(
                              tags: note.tags,
                              accent: noteAccent,
                              removeLabel: l10n.tagRemove,
                              onRemove: _removeTag,
                            ),
                          ),
                        ),
                      // Tarih kısa (bkz. [editorBarDate]); etiketler
                      // yer isteyince o kesilmesin diye esnek değil, tavanlı.
                      if (note.updatedAt != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 96),
                        child: Text(
                          editorBarDate(note.updatedAt!, DateTime.now()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _themeOf(
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
                ),
            actions: [
              // ANA SAYFAYA DÖN (F28.3): geniş ekranda/web'de ray bu sırada
              // çekmece ya da gizli; tek dokunuşla `/`. Telefonda yok.
              if (MediaQuery.sizeOf(context).width >= kRailBreakpoint)
                _hideWhileTyping(
                  note,
                  IconButton(
                    key: const ValueKey('editor-home'),
                    tooltip: '${l10n.goHome} (Alt+Home)',
                    icon: const Icon(Icons.home_outlined),
                    onPressed: () => goHome(ref, GoRouter.of(context)),
                  ),
                ),
              // ⌨ SANAL KLAVYE: yalnız fiziksel klavye takılıyken (tablet
              // bulgusu 2026-11-07); o sırada sanal klavye kendiliğinden
              // açılmaz (bkz. [HardKeyboard]).
              ValueListenableBuilder<bool>(
                valueListenable: HardKeyboard.present,
                builder: (context, present, _) => !present
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder<bool>(
                        valueListenable: HardKeyboard.softWanted,
                        builder: (context, soft, _) => IconButton(
                          key: const ValueKey('editor-soft-keyboard'),
                          tooltip: soft
                              ? l10n.softKeyboardHide
                              : l10n.softKeyboardShow,
                          isSelected: soft,
                          icon: const Icon(Icons.keyboard_outlined),
                          selectedIcon: const Icon(Icons.keyboard_hide_outlined),
                          onPressed: HardKeyboard.toggleSoft,
                        ),
                      ),
              ),
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
                    // Misafir hesabın notu da (F60.4): ana ekran ve hesap
                    // levhası "yalnız bu cihazda" diyor, burada
                    // "Senkronize" yazıyordu.
                    if (owner == null &&
                        (ref.watch(isAnonymousProvider) ||
                            (ref
                                    .read(notesRepositoryProvider)
                                    ?.isLocal(widget.noteId) ??
                                false))) {
                      return Tooltip(
                        message: l10n.localOnlyBadge,
                        child: Icon(
                          Icons.cloud_off_outlined,
                          size: 18,
                          color: _themeOf(context).colorScheme.tertiary,
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
                        color: _themeOf(context).colorScheme.onSurfaceVariant
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
              // ÜST ALANDA SADELEŞME (kullanıcı isteği 2026-11-05): geri al /
              // yinele yalnız bu oturumda geri alınacak bir şey olunca
              // belirir (ikisi birlikte — yinele hâlâ geri alın yanında
              // görünür); not yalnız açılıp okunurken çubukta iki soluk
              // düğme durmaz.
              // Yazarken geri al / yinele HEP görünür (2026-11-08); okurken
              // yalnız geri alınacak bir şey varken.
              Builder(
                builder: (context) {
                  final undo = Customizable(
                id: UiItem.topUndo,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SIKI İKİLİ (kullanıcı isteği 2026-11-08: "geri al
                    // ileri al çok yer kaplıyor, arası boş"): 48 → 36 dp
                    // genişlik, aralarında boşluk yok; yükseklik 48 kalır.
                    IconButton(
                      tooltip: l10n.undo,
                      icon: const Icon(Icons.undo),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 48,
                      ),
                      onPressed: _canUndo ? _undo : null,
                    ),
                    // Başlık üst çubuktayken yer dar: yinele yalnız
                    // kullanılabilirken.
                    if (_barTitle == null || _canRedo)
                      IconButton(
                        key: const ValueKey('editor-redo'),
                        tooltip: l10n.redo,
                        icon: const Icon(Icons.redo),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 48,
                        ),
                        onPressed: _canRedo ? _redo : null,
                      ),
                  ],
                ),
              );
                  return KeyboardSwitch(
                    open: undo,
                    closed: (_canUndo || _canRedo) ? undo : null,
                  );
                },
              ),
              // ORTAK ÇALIŞAN düğmesi buradaydı; 2026-11-01'den beri
              // başlığın yanındaki etiket/hatırlatıcı çipinde (bkz.
              // [_collabMarker]).
              // GÖRÜNÜM (tema şeridi) üst çubukta — örnek uygulamadaki palet
              // düğmesi; biçim panelinden ve Ekle levhasından da açılır.
              // Başlık üst çubuktayken görünüm ve sabitle ⋮ / biçim
              // panelinde (başlığa yer kalsın).
              // Görünüm (palet) 2026-11-05'te çubuktan ⋮ menüsüne indi (üst
              // alanda sadeleşme); biçim panelinden ve Ekle levhasından da
              // açılır.
              if (_barTitle == null)
              _hideWhileTyping(
                note,
              Customizable(
                id: UiItem.topPin,
                child: IconButton(
                  tooltip: note.pinned ? l10n.unpin : l10n.pin,
                  isSelected: note.pinned,
                  icon: Icon(
                    note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    // Sabitli not: kartın raptiyesiyle AYNI renk (notun
                    // koyu tonu, renksizde temanın sıcak vurgusu).
                    color: note.pinned
                        ? (noteAccent ?? _themeOf(context).colorScheme.secondary)
                        : null,
                  ),
                  onPressed: () => _mutate(
                    (n) => n.copyWith(pinned: !n.pinned),
                    immediate: true,
                  ),
                ),
              ),
              ),
              // HESAP MAKİNESİ ⋮ menüsünün hızlı satırında (2026-10-11):
              // üst çubuk notun DURUMUNA ayrıldı — geri al/yinele, sabitle,
              // ortak çalışan. Araçlar ⋮'te ve alt çubukta.
              // Yıldız ve sabitleme düğmeleri ⋯ menüsüne taşındı; durumları üst
              // barın başlık alanındaki göstergelerden okunuyor.
              // ⋮ artık açılır menü değil, iki sütunlu levha açar
              // (bkz. [noteMenuModel] — kullanıcı isteği 2026-08-09).
              if (PenTray.useRail(context))
                _hideWhileTyping(note, _fullscreenButton(l10n)),
              // ⋮ yazarken de görünür: hızlı satırın en sağında (kullanıcı
              // isteği 2026-11-08 — "3 nokta geri gelsin").
              IconButton(
                key: const ValueKey('editor-more'),
                tooltip: l10n.noteMenu,
                icon: const Icon(Icons.more_vert),
                onPressed: _openNoteMenu,
              ),
            ],
          ),
                  ),
                )),
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
          body: StylusToggleOverlay(
            visible:
                !_readOnly &&
                _penPolicy(PenSurface.page).showFloatingToggle,
            child: KeyboardSnap(
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
            builder: (context, keyboardInset) {
              // Klavye KAPANDI (onSettled kapanışta gelmez, bkz. HAFIZA):
              // yazarken gizlenen alt çubuk hemen gelsin.
              if (keyboardInset <= 0 && _typingN.value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _showBarNow();
                });
              }
              return Padding(
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Column(
                children: [
                  Expanded(
                    // Sütun yokken de Row: kaleme geçişte sayfa yeniden kurulmaz.
                    child: Row(
                      children: [
                        // Eski kalem sütununun yuvası (ağaç şekli sabit
                        // kalsın; kalemler artık alttaki çekmecede).
                        const SizedBox.shrink(),
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
                                !_penMode &&
                                textPagePosition(note).count > 1,
                            onSwipe: _swipePage,
                            child: PageTurn(
                              index: textPagePosition(note).index,
                              count: note.type.isPageNoteType
                                  ? 1
                                  : textPagePosition(note).count,
                              child: body,
                            ),
                          ),
                        ),
                      ),
                    ),
                          if (_gestureMode != _GestureMode.off)
                            Positioned.fill(
                              child: InkGestureLayer(
                                key: const ValueKey('ink-gesture-layer'),
                                color: _themeOf(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.7),
                                scrollPosition: _gestureScrollPosition,
                                onStroke: _onGestureStroke,
                              ),
                            ),
                          if (_pagePen)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              // Kalem kipi geri tuşuyla kapanır — tepsinin
                              // kendi panelleri önce (LIFO). Eskiden bu kayıt
                              // alt çubuktaydı; kalem kipinde alt çubuk yok,
                              // geri doğrudan ana ekrana atlıyordu.
                              child: BackCloses(
                                open: true,
                                onClose: () => _update(() => _penMode = false),
                                // Paket grubu (F60.2): tepsi açık paketi
                                // kapatmaz.
                                child: TapRegion(
                                groupId: kNotePackageTapGroup,
                                child: PenTray(
                                key: const ValueKey('page-pen-dock'),
                                controller: _pageInkOf(note),
                                dock: true,
                                followActive: true,
                                actions: [
                                  // Kalem + tam ekranda üst çubuk yok: listeye
                                  // dönüş tepside.
                                  if (_listHidden(context))
                                    _showListButton(l10n),
                                  if (PenTray.useRail(context))
                                    _fullscreenButton(l10n),
                                  ..._penEndButtons(l10n),
                                ],
                              ),
                              ),
                              ),
                            ),
                        ],
                      ),
                    ),
                        ),
                      ],
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
            );
            },
          ),
          ),
        )))),
        ),
        ),
        ),
      ),
    );
  }
}
