import '../app_background_layers.dart';
import '../note_link_ui.dart';
import 'editor_chrome_palette.dart';
import 'glyph_button.dart';
import 'ime_hide_detector.dart';
import 'inline_parse_bar.dart';
import 'shopping_summary_bar.dart';
import 'smart_list_mode_header.dart';
import '../../../shopping/data/barcode_lookup.dart';
import '../../../shopping/domain/shop_aisles.dart';
import '../../../shopping/domain/shop_recipes.dart';
import '../../../shopping/presentation/shop_aisle_order_sheet.dart';
import '../../../shopping/presentation/shop_price_sheet.dart';
import '../../../shopping/presentation/shop_receipt_sheet.dart';
import '../../../shopping/presentation/shop_recipes_sheet.dart';
import '../../../smart_lists/presentation/smart_wizards.dart';
import '../../domain/list_mode.dart';
import '../../domain/routine_reset.dart';
import '../../../../core/widgets/back_closes.dart';
import '../../../../core/widgets/color_fade.dart';
import '../note_card.dart' show openNoteRoute;
import '../../domain/note_links.dart';
import '../reminder_repeat_ui.dart';
import '../reminders_screen.dart' show maybeShowAutoStartHint;
import '../expiry_sheet.dart';
import '../reminder_sheet.dart';
import '../../domain/reminder_repeat.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/a11y/min_tap_target.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/haptics.dart';

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
import '../../../../core/save_cadence.dart';
import 'note_slice.dart';
import '../../../../core/widgets/toggle_pop.dart';
import '../../../../app/router.dart';
import '../../../../app/window_class.dart';

export '../../../../app/window_class.dart' show kReadingWidth;
import '../../../auth/presentation/auth_providers.dart';
import '../../../settings/presentation/app_lock.dart' show AppLockSecureScope;
import '../../../../app/theme/dashboard_wallpapers.dart';
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
import '../../../../core/utils/local_file.dart';
import '../../../../core/utils/attachment_tag.dart';
import '../../../../core/utils/link_text.dart';
import '../../../../core/utils/markdown.dart';
import '../../../../core/utils/note_fonts.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/widgets/color_palette.dart';
import '../../../../core/utils/note_e2ee_session.dart';
import '../../../../core/utils/note_guard.dart';
import '../../../../core/utils/sentence_select.dart';
import '../../../../core/utils/pdf_ref.dart';
import '../../../../core/utils/video_time.dart';
import '../../../../core/utils/youtube.dart';
import '../../../../core/widgets/customizable.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import '../../../settings/presentation/appearance_studio_sheet.dart';
import '../../../../core/widgets/note_route_closing.dart';
import '../../../../core/widgets/scale_settle.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import 'stylus_toggle.dart';
import 'pinned_side.dart';
import '../../data/note_format_memory.dart';
import '../../data/attachment_save.dart';
import '../../data/import_service.dart' show markdownAttachment;
import '../../data/note_shortcut.dart';
import '../../../auth/presentation/account_required.dart';
import '../../../entitlement/data/entitlement_service.dart';
import '../../../entitlement/domain/entitlement.dart';
import '../../../entitlement/presentation/pro_lock.dart';
import '../../../ai/data/ai_policy.dart';
import '../../../ai/data/decisions/decision_flag.dart';
import '../../../ai/data/decisions/decision_profiles.dart';
import '../../../ai/data/decisions/decision_service.dart';
import '../../../ai/data/list_ai_service.dart';
import '../../../ai/presentation/ai_consent_sheet.dart';
import '../../../ai/data/speech_service.dart';
import '../../../ai/domain/smart_categorize.dart';
import '../../../folders/data/folders_repository.dart';
import '../../../folders/domain/note_folder.dart';
import '../../../folders/presentation/folder_sheets.dart';
import '../../../shopping/data/shop_memory.dart';
import '../../../shopping/domain/shop_item_meta.dart';
import '../../../settings/data/permissions_service.dart';
import '../../../settings/settings_providers.dart';
import '../../../calendar/data/task_note_sync.dart';
import '../../../calendar/presentation/note_calendar_links.dart';
import '../../../calendar/presentation/task_editor.dart';
import '../../../calendar/presentation/line_task_chip.dart';
import '../../data/quick_entry_memory.dart';
import '../../domain/ghost_suggestion_engine.dart';
import '../../domain/smart_list.dart';
import '../text_extract_sheet.dart';
import 'ghost_suggestions_section.dart';
import '../../domain/spell_review.dart';
import 'auto_spell.dart';
import '../../../../core/utils/speech_output.dart' show SpeechOutputController;
import 'dictation_controller.dart';
import 'selection_toolbar.dart';
import 'spell_review_sheet.dart';
import 'spell_settings_sheet.dart';
import 'spell_underline.dart';
import 'note_package.dart';
import 'editor_quick_row.dart';
import '../../../calendar/presentation/event_editor.dart';
import '../../../calendar/domain/agenda.dart' show noteDateSuggestion;
import '../../../../core/utils/spoken_datetime.dart'
    show parseSpokenDateTimeNow;
import '../../data/attachment_repository.dart';
import '../../data/device_speech.dart';
import '../../data/document_scan.dart';
import '../../data/note_speech.dart';
import '../../data/note_share.dart';
import '../../data/lite_sync.dart';
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
import '../../domain/quick_entry.dart';
import '../../domain/bubble_view_retire.dart';
import '../collaborators_sheet.dart';
import '../../../../core/widgets/action_menu_sheet.dart';
import '../color_picker_sheet.dart';
import '../note_menu_model.dart';
import '../note_stats_sheet.dart';
import '../note_template_sheet.dart';
import '../notes_providers.dart';
import '../pdf_export_screen.dart';
import '../qr_scan_screen.dart';
import '../scan_review_screen.dart';
import '../share_sheet.dart';
import '../listening_visuals.dart';
import '../voice_capture_sheet.dart';
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
import '../../../../app/second_note.dart';
import '../../../../app/split_shell.dart';
import 'page_ink_layer.dart';
import '../place_reminder_sheet.dart';
import '../viewers/ink_layer.dart';
import 'pen_tray.dart';
import 'drawing_screen.dart';
import 'editor_bar_layout.dart';
import 'editor_bar_more_menu.dart';
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
import '../viewers/area_actions.dart';
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
import 'table_page_box.dart';
import 'table_screen.dart';
import '../../domain/note_table.dart';
import 'attachment_actions.dart';
import 'view_mode_switch.dart';
import 'page_swipe.dart';
import 'title_fit.dart';
import '../../../../core/widgets/smooth_routes.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/friendly_error.dart';
import '../../../../core/a11y/chip_roles.dart';

part 'note_editor_actions.dart';
part 'note_editor_actions_extra.dart';
part 'note_editor_package.dart';
part 'note_editor_ai.dart';
part 'note_editor_appearance.dart';
part 'note_editor_attachments.dart';
part 'note_editor_attachment_updates.dart';
part 'note_editor_find.dart';
part 'note_editor_gestures.dart';
part 'note_editor_media_view.dart';
part 'note_editor_media_links.dart';
part 'note_editor_parts.dart';
part 'note_editor_toolbar.dart';
part 'note_editor_voice.dart';
part 'note_editor_flow.dart';
part 'note_editor_video.dart';
part 'note_editor_embed.dart';
part 'note_editor_helpers.dart';
part 'note_editor_fields.dart';
part 'note_editor_lifecycle.dart';
part 'note_editor_canvas_helpers.dart';
part 'note_editor_content.dart';
part 'note_editor_bottom_bar.dart';
part 'note_editor_scaffold.dart';

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
    with
        WidgetsBindingObserver,
        SingleTickerProviderStateMixin,
        _NoteEditorFields {
  void _syncUndoN() => _undoN.value = (_undoStack.canUndo, _undoStack.canRedo);

  void _onAnyFocusChange() => _handleAnyFocusChange();
  void _holdSaveWhileClosing() => _handleHoldSaveWhileClosing();
  bool _onHardKey(KeyEvent event) => _handleHardKey(event);
  void _tableCellFocused(
    WrapTextController c,
    FocusNode f,
    VoidCallback commit,
    ValueNotifier<TextAlign> align,
  ) => _setFormatTarget(c, f, commit, align: align);
  void _tableCellDisposed(WrapTextController c) => _clearFormatTargetFor(c);
  void _onTargetSelection() => _rememberTargetSelection();

  /// `setState` konu dosyalarındaki uzantılardan (F9.3) — orada korumalı
  /// üyeye doğrudan erişilemez.
  void _update(VoidCallback fn) => setState(fn);

  /// Ataç rozetinin "yeni ek geldi" yanıp sönmesi (bkz.
  /// [_attachmentsToggle]). Değer 0 → 1 → 0 gider; iki tur döner.
  late final AnimationController _attachPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Uzun notta yazarken alan yalnız imlecin çevresini taşır (F24.2).
  late final _bodyWindow = BodyWindow(_bodyController)
    ..addListener(() {
      if (mounted) _update(() {});
    });

  /// Metin alanına o an bağlı denetleyici; model hep [_bodyController].
  WrapTextController get _bodyField =>
      _bodyWindow.active ? _bodyWindow.win : _bodyController;

  /// Gövde metninin sayfa kenarlarından boşluğu.
  static const double _kGutter = 16;

  /// Editörün üst çubuğunun yüksekliği (bkz. AppBar `toolbarHeight`).
  static const double _kEditorToolbarHeight = 48;

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

  static const _kStillTyping = Duration(milliseconds: 500);

  /// Yazma "sürüyor" sayılırken iki tuş arası en uzun ara. Çubuk görünürken
  /// sabit (2026-11-08 ölçüsü); gizliyken ara ayardan gelir.
  static const _kTypingPause = Duration(milliseconds: 1100);

  static Duration _tenths(int value) => Duration(milliseconds: value * 100);

  void _syncBgTone(Attachment? bgImage) {
    if (bgImage == null) {
      _bgToneKey = null;
      _bgTone = null;
      return;
    }
    final key =
        '${bgImage.id}|${bgImage.localPath}|${bgImage.downloadUrl}|'
        '${bgImage.sizeBytes}|${bgImage.width}x${bgImage.height}';
    if (_bgToneKey == key) return;
    final hit = BgImageTone.cached(key);
    if (hit != null) {
      _bgToneKey = key;
      _bgTone = hit;
      return;
    }
    final provider = _backgroundProvider(bgImage);
    if (provider == null) {
      _bgToneKey = null;
      _bgTone = null;
      return;
    }
    _bgToneKey = key;
    _bgTone = null;
    unawaited(
      BgImageTone.load(key, provider).then((tone) {
        if (!mounted || _bgToneKey != key) return;
        if (tone == null) {
          _bgToneKey = null;
          return;
        }
        if (tone == _bgTone) return;
        setState(() => _bgTone = tone);
      }),
    );
  }

  void _onTopOrder() {
    final order = Personalize.current.topOrder;
    if (listEquals(order, _topOrder)) return;
    setState(() => _topOrder = order);
  }

  @override
  void initState() {
    super.initState();
    _initNoteServices();
    _ghostDismissedN.value = GhostSuggestionEngine.loadDismissed(
      ref.read(sharedPreferencesProvider),
    );
    _loadGuard = Timer(const Duration(seconds: 6), () {
      if (mounted && _note == null) setState(() => _loadFailed = true);
    });
    _initPendingIntents();
    final owner = widget.ownerId;
    _sub = ref.listenManual(
      owner == null
          ? noteStreamProvider(widget.noteId)
          : ownedNoteStreamProvider((ownerId: owner, noteId: widget.noteId)),
      (previous, next) {
        final incoming = next.value;
        if (incoming == null) return;
        _onIncomingNoteSnapshot(
          incoming,
          owner: owner,
          onFirstLoad: (loaded) => setState(() {
            _note = loaded;
            _titleController.text = loaded.title;
            _bodyController.text = loaded.body;
          }),
        );
      },
      fireImmediately: true,
    );
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

  /// Üst çubuğun "Notta ara" düğmesi (kullanıcı isteği 2026-11-16) — AYNI
  /// örnek: çubuk her kurulduğunda düğme yeniden kurulmaz (kasma listesi
  /// m. 3). İLK KAREDE görünür (kullanıcı bulgusu: "yarım saniye sonra bir
  /// anda geliyor" — eskiden açılış geçişi bitince kuruluyordu); hız bütçesi
  /// (S18/S19) için simge + dokunma + ekran okuyucu adı tek render nesnesinde
  /// ([GlyphButton]), Builder yalnız dil için.
  late final Widget _topSearchButton = Builder(
    builder: (context) => GlyphButton(
      key: const ValueKey('editor-top-search'),
      icon: AppIcons.search,
      label: context.l10n.noteSearchTitle,
      onTap: _openNoteSearch,
    ),
  );

  late final Widget _topPinButton = Customizable(
    id: UiItem.topPin,
    // Dar dinleme (P20 M4): sabitle kökü kurmaz.
    child: NoteSlice<bool>(
      source: _noteN,
      select: (n) => n.pinned,
      builder: (context, pinned) {
        final l10n = context.l10n;
        final accent = NoteAccent.maybeOf(context)?.accent;
        return IconButton(
          key: const ValueKey('editor-top-pin'),
          tooltip: pinned ? l10n.unpin : l10n.pin,
          isSelected: pinned,
          icon: TogglePop(
            on: pinned,
            child: Icon(
              pinned ? Icons.push_pin : Icons.push_pin_outlined,
              // Sabitli not: kartın raptiyesiyle AYNI renk (notun
              // koyu tonu, renksizde temanın sıcak vurgusu).
              color: pinned
                  ? (accent ?? _themeOf(context).colorScheme.secondary)
                  : null,
            ),
          ),
          onPressed: () =>
              _mutate((n) => n.copyWith(pinned: !n.pinned), immediate: true),
        );
      },
    ),
  );

  late final Widget _topPinAndSearch = Row(
    mainAxisSize: MainAxisSize.min,
    children: [_topPinButton, _topSearchButton],
  );

  // Yıldızlı göstergesi üst çubukta; dokununca yıldız kalkar (menüye
  // gitmeden geri alınabilsin). Dar dinleme (P20 M4): yıldız kökü kurmaz;
  // şekil sabit (kasma md. 4), tepki TogglePop (P38).
  late final Widget _starBadge = NoteSlice<bool>(
    source: _noteN,
    select: (n) => n.starred,
    builder: (context, on) => TogglePop(
      on: on,
      child: on
          ? IconButton(
              tooltip: context.l10n.unstar,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.star,
                size: AppIconSize.xs,
                color: Colors.amber.shade600,
              ),
              onPressed: () =>
                  _mutate((n) => n.copyWith(starred: false), immediate: true),
            )
          : const SizedBox.shrink(),
    ),
  );

  // ACİL göstergesi (2026-11-16): yıldızla aynı kalıp — dar dinleme,
  // dokununca işaret kalkar.
  late final Widget _urgentBadge = NoteSlice<bool>(
    source: _noteN,
    select: (n) => n.urgent,
    builder: (context, on) => on
        ? IconButton(
            key: const ValueKey('editor-urgent'),
            tooltip: context.l10n.urgentUnmark,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.priority_high_rounded,
              size: AppIconSize.xs,
              color: _themeOf(context).colorScheme.error,
            ),
            onPressed: () => _setUrgent(false),
          )
        : const SizedBox.shrink(),
  );

  late final Widget _bareStatusBadges = Row(
    mainAxisSize: MainAxisSize.min,
    children: [_starBadge, _urgentBadge],
  );

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _handleMetricsChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _handleLifecycleChanged(state);
  }

  /// Bu oturumda önerilmiş (not, zaman) çiftleri — aynı öneri yinelenmez.
  static final _suggested = <String>{};

  @override
  void dispose() {
    _disposeEditorState();
    super.dispose();
  }

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
      // pinned/starred YOK: üst çubukta NoteSlice dinliyor (P20 M4).
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
      (a.listColumns, a.listKind, a.listMode, a.resetSchedule,
          a.lastResetAt, a.contextTimeSlot, a.isQuickInbox) ==
          (b.listColumns, b.listKind, b.listMode, b.resetSchedule,
          b.lastResetAt, b.contextTimeSlot, b.isQuickInbox) &&
      _sameInts(a.resetCustomDays, b.resetCustomDays) &&
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
      // Zaman çipleri (hatırlatıcı + ZAMANLI NOT süresi) tek terim.
      (a.reminderAt, a.expiresAt) == (b.reminderAt, b.expiresAt) &&
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

  /// [inkOnly]: [transform] yalnız bir ekin mürekkebini değiştirir (OTURTMA
  /// F60.1) — kök kurulmaz, kayıt debounce'lu.
  ///
  /// [tableOnly]: yalnız tablo hücreleri/yapısı değişti (kullanıcı isteği
  /// 2026-11-23: "kasma, editörün baştan kurulmasını yaşatmaz"): tablo
  /// kendi kutusunda zaten çizili — kök kurulmaz, kayıt debounce'lu.
  ///
  /// [itemsShown]: değişiklik [ItemsEditor]'dan geliyor ve maddeleri o
  /// ZATEN kendi `setState`'iyle çizdi. KÖK NEDEN (kullanıcı bulgusu
  /// 2026-11-15 "normal madde notunda kasma"): işaretleme / Enter / silme
  /// `sameItemsVisually`'yi bozduğu için her seferinde KÖK de kuruluyordu —
  /// 40 maddede olay başına ~850 gereksiz widget (çubuklar, ipuçları, düzen
  /// sarmalayıcıları). Kök maddelerden yalnız "liste boş mu"ya bakar
  /// (gövde `minLines`, metin/karışık kip, Seç düğmesi); o değişmedikçe
  /// kök kurulmaz.
  void _mutate(
    Note Function(Note) transform, {
    bool immediate = false,
    bool inkOnly = false,
    bool itemsShown = false,
    bool tableOnly = false,
  }) {
    final note = _note;
    if (note == null) return;
    final next = _prepareMutateNext(
      note,
      transform,
      immediate: immediate,
      inkOnly: inkOnly,
    );
    final pureTyping = _sameVisual(
      note,
      itemsShown && note.items.isEmpty == next.items.isEmpty
          ? next.copyWith(items: note.items)
          : next,
      ignoreAttachments: inkOnly || tableOnly,
    );
    if (pureTyping) {
      _applyPureTypingMutate(
        note,
        next,
        inkOnly: inkOnly,
        tableOnly: tableOnly,
      );
    } else {
      setState(() => _note = next);
    }
    _finishMutateSave(immediate: immediate);
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

  /// İlk açılışta klavye hiç ölçülmemiş olur; Android'de tipik yükseklik.
  /// Tahmin tutmazsa oturma anındaki ikinci geçiş düzeltir.
  static const double _kKeyboardGuess = 300;

  void _togglePen() {
    final open = !_penMode;
    if (open && _formatBarOpen) _formatBarOpen = false;
    _update(() => _penMode = open);
    if (open) {
      if (_dictating) unawaited(_stopDictation());
      _penModeOpened();
    }
  }

  void _openPen() {
    if (_formatBarOpen) _formatBarOpen = false;
    _update(() => _penMode = true);
    if (_dictating) unawaited(_stopDictation());
    _penModeOpened();
  }

  /// Açık editörler (K32: yan yana iki not) — tek mikrofon denetimi.
  static final _live = <_NoteEditorScreenState>{};

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

  /// Kalem kipinden yazıya dönüş (tepsinin sonunda). Eski × / ✓ ikilisi
  /// kalktı (kullanıcı isteği 2026-11-15: "onay butonlarına gerek yok, oto
  /// kaydedilmesi lazım"): çizgi bitince zaten kaydedilir, burada yalnız
  /// bekleyen varsa yazılır. Geri tuşu ve hızlı satırdaki kalem de kapatır.
  Widget _penCloseButton(AppLocalizations l10n) => IconButton(
    key: const ValueKey('pen-close'),
    tooltip: l10n.penModeDone,
    visualDensity: VisualDensity.compact,
    icon: const Icon(Icons.keyboard_outlined),
    onPressed: () {
      _pageInkCtl?.save();
      _update(() => _penMode = false);
    },
  );

  void _setImmersiveBubble(bool value) {
    if (_immersiveBubble == value || !mounted) return;
    setState(() => _immersiveBubble = value);
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

  /// GALERİDEN video (kullanıcı isteği 2026-10-11: "not içerisine video
  /// koyma"). Kamera yolu gibi cihazda kalır ve sayfaya yerleşir; süre
  /// sınırı YOK (o sınır yalnız AI'a gönderim içindi — uzun videoda
  /// "videodan not çıkar" boyut uyarısını kendisi verir).
  static const _videoExtensions = ['mp4', 'mov', 'mkv', '3gp', 'webm'];

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
      'mp3',
      'm4a',
      'aac',
      'wav',
      'ogg',
      'oga',
      'opus',
      'flac',
      'amr',
    };
    const video = {'mp4', 'mov', 'mkv', '3gp', 'webm', 'm4v'};
    const image = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'bmp'};
    if (audio.contains(ext)) return AttachmentKind.audio;
    if (video.contains(ext)) return AttachmentKind.video;
    if (image.contains(ext)) return AttachmentKind.image;
    return null;
  }

  Widget _pageNoteBody(
    Note note,
    Widget header,
    RichTextTheme richTheme,
    TextStyle textStyle,
  ) => _buildPageNoteBodyContent(
    note,
    header,
    richTheme,
    textStyle,
    onPenModeChanged: (value) => setState(() => _penMode = value),
  );

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
    final document = note.type == NoteType.pdf || note.type == NoteType.slides;
    if (document) {
      // Balona yazılırken kalem kartın alanlarına dokunuyor olabilir.
      if (_penMode || _immersiveBubble) return;
      setState(() => _penMode = true);
      _showSnack(context.l10n.inkStylusDetected);
      return;
    }
    if (_penMode) return;
    AppHaptics.tick();
    // Neden açıldığı ve "yalnız kalem" durumu [_penModeOpened]'da söylenir.
    _openPen();
  }

  Color _editorTertiary(BuildContext context) =>
      _themeOf(context).colorScheme.tertiary;

  @override
  Widget build(BuildContext context) {
    // Drive'dan bir ek inince editör yeniden çizilir: ekranlar yerel
    // kopyayı çizim anında arıyor (bkz. localFilesRevisionProvider).
    ref.watch(localFilesRevisionProvider);
    // dispose'un kullanacağı bağımlılıklar her karede tazelenir (bkz. yukarı).
    _cacheDeps();
    // Ağaç bu kurulumla güncel eki alıyor: bayat mürekkep/tablo kaydı kalmaz.
    _staleInk.clear();
    _staleTable.clear();
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
      for (final a
          in (note?.attachmentsWithoutBackground ?? const <Attachment>[]))
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

    if (note == null) return _buildLoadingScaffold(context, l10n);
    _syncSecureScreen(note.locked);
    // Zemin görseli: ekler listesinde durur ama sayfada yüzmez, şeritte de
    // görünmez — arkada duvar kâğıdı gibi bütün ekranı kaplar.
    final bgImage = note.backgroundImageId == null
        ? null
        : note.attachments
              .where((a) => a.id == note.backgroundImageId)
              .firstOrNull;
    _syncBgTone(bgImage);
    final style = _prepareBuildStyle(context, note, bgImage);
    final headerData = _buildEditorHeader(
      context,
      l10n: l10n,
      note: note,
      noteAccent: style.noteAccent,
      theme: style.theme,
      noteBodyStyle: style.noteBodyStyle,
    );
    final content = _buildEditorContent(
      context,
      l10n: l10n,
      note: note,
      richTheme: style.richTheme,
      noteBodyStyle: style.noteBodyStyle,
      imageAttachments: headerData.imageAttachments,
      hintLineHeight: headerData.hintLineHeight,
      useCanvasHint: headerData.useCanvasHint,
      header: headerData.header,
    );
    final bottomArea = _buildEditorBottomArea(
      context,
      l10n: l10n,
      note: note,
      fileAttachments: fileAttachments,
      isDocumentNote: isDocumentNote,
      chrome: style.chrome,
      background: style.background,
      chromeSeeThrough: style.chromeSeeThrough,
      noteBodyStyle: style.noteBodyStyle,
      pageBarDock: content.pageBarDock,
      readingColumn: content.readingColumn,
      onClearPendingEmbed: () => setState(() => _pendingEmbed = null),
    );
    final fullscreenNow = ref.watch(noteFullscreenProvider);
    final PreferredSizeWidget? topAppBar =
        _pagePen && !_secondary && fullscreenNow
        ? null
        : HomeInBar(
            appBar: _buildEditorTopBar(
              context,
              l10n: l10n,
              note: note,
              chrome: style.chrome,
              noteAccent: style.noteAccent,
              toolbarHeight: content.toolbarHeight,
              readingColumn: content.readingColumn,
            ),
          );
    return _buildEditorScaffold(
      context,
      l10n: l10n,
      note: note,
      bgImage: bgImage,
      chrome: style.chrome,
      background: style.background,
      noteAccent: style.noteAccent,
      themed: style.themed,
      effectiveThemeId: style.effectiveThemeId,
      dashBg: style.dashBg,
      noteBodyStyle: style.noteBodyStyle,
      body: content.body,
      readingColumn: content.readingColumn,
      toolbarHeight: content.toolbarHeight,
      findSlot: bottomArea.findSlot,
      bottomBar: bottomArea.bottomBar,
      fullscreenNow: fullscreenNow,
      appBar: topAppBar,
    );
  }
}
