import '../../../core/haptics.dart';
import '../../../core/app_icons.dart';
import '../../../core/widgets/tag_pill.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/note_open_route.dart';
import '../../../app/router.dart';
import '../../../app/second_note.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/color_fade.dart';
import '../../../app/theme/note_colors.dart';
import '../../../app/theme/note_themes.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/note_fonts.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../folders/data/folders_repository.dart';
import '../../settings/settings_providers.dart';
import '../data/note_shares_repository.dart';
import '../data/notes_repository.dart';
import '../domain/archive_paper.dart';
import '../domain/note.dart';
import 'expiry_sheet.dart' show noteExpiryLeft;
import '../domain/note_item.dart';
import '../domain/note_type.dart';
import '../domain/page_notes.dart';
import '../domain/sensitive_text.dart';
import '../data/drive_store.dart' show localFilesRevisionProvider;
import 'card_preview.dart';
import 'search_highlight.dart';
import 'editor/notebook_paper.dart';
import 'editor/title_fit.dart';
import 'note_actions_sheet.dart';
import 'item_divider_style.dart';
import 'note_card_media.dart';
import 'notes_providers.dart';

part 'note_card_helpers.dart';

/// Dashboard'daki kompakt not kartı.
/// **OKUNURLUK — KART ZEMİNE GÖRE** (kullanıcı bulgusu 2026-11-04; editördeki
/// `_editorInk` ile aynı kural). Kartın zemini temanın yazısıyla okunmuyorsa
/// (koyu özel renk açık temada, ya da tersi) kartın içi ZIT temayla çizilir.
/// [NoteCard.build] kararı kendi bağlamına yazar; bu dosyada kart bağlamından
/// tema okuyan her yer `Theme.of` yerine bunu kullanır.
final _cardInk = Expando<ThemeData>('cardInk');

ThemeData _cardThemeOf(BuildContext context) =>
    _cardInk[context] ?? Theme.of(context);

/// Izgara hücresinin genişliği (ana ekran verir); kart dar sütunda
/// sıkışır (bkz. [noteCardSqueeze]). Yoksa kart normal çizilir.
/// Kart durum simgelerinin boyu (kardeş simgelerin 13'üyle aynı).
const _statusIconSize = 13.0;

class NoteCardWidth extends InheritedWidget {
  const NoteCardWidth({super.key, required this.width, required super.child});

  final double width;

  static double? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NoteCardWidth>()?.width;

  @override
  bool updateShouldNotify(NoteCardWidth old) =>
      noteCardSqueezeFor(old.width) != noteCardSqueezeFor(width);
}

/// 0 normal, 1 dar (telefonda 3 sütun ≈128 dp), 2 çok dar (4 sütun ≈94 dp).
int noteCardSqueezeFor(double? width) => width == null
    ? 0
    : width < 112
    ? 2
    : width < 150
    ? 1
    : 0;

int noteCardSqueeze(BuildContext context) =>
    noteCardSqueezeFor(NoteCardWidth.of(context));

/// Kart başlığı boyu sıkışıklığa göre.
const _kCardTitleSize = [16.0, 14.5, 13.0];

/// "+N madde daha" — dar kartta yalnız "+N" (üç satıra yayılıyordu).
String _moreItemsLabel(BuildContext context, int count) =>
    noteCardSqueeze(context) > 0
    ? '+$count'
    : context.l10n.moreItemsCount(count);

class NoteCard extends ConsumerWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.highlightQuery = '',
    this.liveQuery,
    this.ownerId,
    this.readOnly = false,
    this.showFolder = true,
    this.frame,
    this.calendarDay,
  });

  final Note note;

  /// Not takvimde bir GÜNE bağlıysa o gün: alt satırda "📅 27 Kas" hapı
  /// (kullanıcı isteği 2026-11-22: takvimden geldiği belli olsun).
  final DateTime? calendarDay;

  /// Kartın çevresine çizilen hale (ana ekranda odak / açık not vurgusu).
  /// Hücrede ayrı `Consumer` YOK (F21.4): odak ve açık not da kartın TEK
  /// aboneliğinden gelir — kaydırmada hücre başına bir bağlama eksik.
  final Widget Function(Widget card, {required bool focused, required bool open})?
  frame;

  /// Arama sürerken notun klasör adı kartta yazsın mı? Klasörün kendi
  /// ekranında (zaten o klasördeyiz) false.
  final bool showFolder;

  /// PAYLAŞILAN klasörde çizilen kartta notun SAHİBİ; kendi notlarımda null.
  /// Kart bunu editöre taşır, yoksa editör notu kendi koleksiyonumda arar ve
  /// bulamaz (bkz. `NoteEditorScreen.ownerId`).
  final String? ownerId;

  /// Paylaşılan klasörde YALNIZ OKUMA yetkisi varsa true — editör kilitli
  /// açılır (bkz. `NoteEditorScreen.readOnly`).
  final bool readOnly;

  /// Aktif arama sorgusu; boş değilse eşleşmeler vurgulanır.
  final String highlightQuery;

  /// CANLI sorgu (F21.6, ana ekran): verilirse [highlightQuery] yerine bu
  /// izlenir ve sorgu değişince kart yeniden KURULMAZ, yalnız vurgu
  /// katmanı boyanır. Sözleşme: değer boş ↔ dolu arasında geçerken çağıran
  /// kartı yeniden kurar (aramada biçim/klasör adı yapısal olarak değişir).
  final ValueListenable<String>? liveQuery;

  /// Kartın izlediği sorgu kaynağı.
  ValueListenable<String> get _query =>
      liveQuery ??
      (highlightQuery.isEmpty ? FixedQuery.empty : FixedQuery(highlightQuery));

  Future<void> _openNote(BuildContext context) => openNoteRoute(
    context,
    note,
    ownerId: ownerId,
    readOnly: readOnly,
    // Kilitli notun içeriği aranmaz (kartta da gizli) — sorgu taşınmaz.
    find: note.locked ? '' : _query.value.trim(),
  );

  void _delete(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    // Kart önce küçülüp solar, sonra silinir (bkz. leavingNotesProvider).
    ref.read(leavingNotesProvider.notifier).leave([note.id], () {
      repo.softDelete(note.id);
      final ctx = context.mounted
          ? context
          : rootScaffoldMessengerKey.currentContext;
      if (ctx == null) return;
      showUndoSnackBar(
        ctx,
        message: l10n.noteDeleted,
        undoLabel: l10n.undo,
        onUndo: () => repo.restore(note.id),
      );
    });
  }

  Future<void> _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
  ) async {
    final l10n = context.l10n;
    final openSide = canOpenSide(context, note.id);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'pin',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(note.pinned ? l10n.unpin : l10n.pin),
          ),
        ),
        PopupMenuItem(
          value: 'star',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(note.starred ? Icons.star : Icons.star_outline),
            title: Text(note.starred ? l10n.unstar : l10n.star),
          ),
        ),
        PopupMenuItem(
          value: 'urgent',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.priority_high_rounded),
            title: Text(note.urgent ? l10n.urgentUnmark : l10n.urgentMark),
          ),
        ),
        if (openSide)
          PopupMenuItem(
            value: 'side',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.vertical_split_outlined),
              title: Text(l10n.noteOpenSide),
            ),
          ),
        PopupMenuItem(
          value: 'more',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.more_horiz),
            title: Text(l10n.noteMenu),
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
    );
    if (!context.mounted) return;
    switch (action) {
      case 'pin':
        unawaited(AppHaptics.tick());
        ref.read(notesRepositoryProvider)?.setPinned(note.id, !note.pinned);
      case 'star':
        unawaited(AppHaptics.tick());
        ref.read(notesRepositoryProvider)?.setStarred(note.id, !note.starred);
      case 'urgent':
        unawaited(AppHaptics.tick());
        ref.read(notesRepositoryProvider)?.setUrgent(note.id, !note.urgent);
      case 'side':
        if (note.locked &&
            !await authenticateForNote(l10n.unlockAuthReason)) {
          return;
        }
        if (!context.mounted) return;
        unawaited(AppHaptics.tick());
        ref.read(secondNoteProvider.notifier).open(SecondNote(note.id));
      case 'more':
        unawaited(showNoteActionsSheet(context, ref, note));
      case 'delete':
        _delete(context, ref);
    }
  }

  /// Kart içeriğini notun TEMASININ (çizilmiş zemin) ve zemin görselinin
  /// üstüne serer — editörde ne görünüyorsa kartta da o (küçülmüş hâli).
  Widget _withNoteBackground(Note note, Widget child, double radius) {
    final withImage = _withNoteImage(note, child, radius);
    if (NoteThemes.byId(note.theme) == null) return withImage;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: NoteThemeBackdrop(themeId: note.theme, child: withImage),
    );
  }

  Widget _withNoteImage(Note note, Widget child, double radius) {
    final id = note.backgroundImageId;
    if (id == null) return child;
    final image = note.attachments.where((a) => a.id == id).firstOrNull;
    if (image == null) return child;
    ImageProvider provider;
    if (localFileExists(image.localPath)) {
      provider = FileImage(File(image.localPath));
    } else if (image.downloadUrl.isNotEmpty) {
      provider = CachedNetworkImageProvider(image.downloadUrl);
    } else {
      return child;
    }
    // Zemin görseli 1600 px'e kadar saklanıyor; kart genişliği için 800 px
    // fazlasıyla yeter. Sınırsız çözme, kart başına ~10 MB bitmap demekti
    // (ızgarada onlarca kart aynı anda ayakta).
    provider = ResizeImage(provider, width: 800);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          // PİL: görselin kendi opaklığı; `Opacity` widget'ı her kart için
          // ayrı bir birleştirme katmanı açıyordu (ızgarada onlarca kart).
          Positioned.fill(
            child: Image(
              image: provider,
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(
                note.backgroundOpacity.clamp(0.05, 1).toDouble(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// Kartın gövdesini notun defter kâğıdıyla çizer (bkz. [Note.paged]).
  static Widget _withCardPaper(
    BuildContext context,
    Note note,
    Widget child,
    BorderRadius radius,
  ) {
    final paper = note.archivePaper;
    final inks = PaperInks.of(
      _cardThemeOf(context),
      accent: NoteColors.noteInk(context, note),
    );
    final line = inks.line;
    // Kartın küçük yazısına göre satır aralığı (bodyMedium ~14 × 1.43).
    const gap = 20.0;
    Widget body = child;
    if (paper.ruled) {
      body = RuledLines(
        gap: gap,
        color: line,
        dashed: paper == ArchivePaper.dashed,
        anchorParagraphs: true,
        child: body,
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CustomPaint(
        painter: NotebookPaperPainter(
          style: paper,
          line: line,
          margin: inks.margin,
          spine: inks.spine,
          gap: 14,
          contentRuled: true,
        ),
        child: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Zemin ve okunurluk teması DIŞ temaya göre (bkz. [_cardInk]).
    final background = NoteColors.noteSurface(context, note);
    final inkTheme = NoteColors.inkThemeFor(Theme.of(context), background);
    _cardInk[context] = inkTheme;
    final accent = NoteColors.noteInk(context, note);
    final tokens = AppTokens.of(context);
    final radius = tokens.cardRadius;
    final scheme = _cardThemeOf(context).colorScheme;
    final query = _query;
    // TEK abonelik (F21.4, bkz. [_cardEnvProvider]). select() ŞART: seçim
    // kümesi her değişimde yeni bir Set; kümeyi izlemek TEK not seçilince
    // görünürdeki BÜTÜN kartları yeniden çiziyordu — yalnız durumu değişen
    // kart çizilir.
    final env = ref.watch(
      _cardEnvProvider.select(
        (e) => (
          display: e.display,
          rich: e.rich,
          hideSensitive: e.hideSensitive,
          filesRevision: e.filesRevision,
          selectionActive: e.selected.isNotEmpty,
          selected: e.selected.contains(note.id),
          leaving: e.leaving.contains(note.id),
          // Yalnız BU notun paylaşım durumu: ayna akışı her değiştiğinde
          // bütün kartlar yeniden kurulmasın.
          shared: e.shares?.containsKey(note.id) ?? false,
          allView: e.allView,
          focused: frame != null && e.focused == note.id,
          open: frame != null && e.open == note.id,
        ),
      ),
    );
    final selectionActive = env.selectionActive;
    final selected = env.selected;
    final richPreview = env.rich;
    // HASSAS İÇERİK (B1): parola notunun içeriği kartta çizilmez, öbür
    // notlarda IBAN/kart numarası örtülür. Yalnız gösterim (bkz.
    // sensitive_text.dart); ayar Ayarlar → Görünüm.
    final hideSensitive = env.hideSensitive;
    // Kartta hangi öğeler görünsün (Ayarlar → Görünüm → Kartlar).
    final display = env.display;
    // Dilim, örtme, parola taraması not sürümü başına bir kez (F21.1/F21.2).
    final preview = CardPreview.of(note, hideSensitive: hideSensitive);
    final credential = hideSensitive && !note.locked && preview.credential;

    void toggleSelection() =>
        ref.read(selectedNoteIdsProvider.notifier).toggle(note.id);

    final hasTitle = note.title.trim().isNotEmpty;
    final shared = ownerId != null || env.shared;
    // Durum simgeleri ALT meta satırına indi. Eskiden başlık satırının sağında
    // akıyorlardı ve başlığı sola sıkıştırıyorlardı: üç rozetli bir notta
    // başlık iki kelimede kesiliyordu. Altta, tarihle aynı bantta duruyorlar.
    final statusIcons = <Widget>[
      // ACİL: ilk sırada, hata renginde ünlem (2026-11-16). Durum simgeleri
      // kapalıyken de görünür — işaretin tek işi gözden kaçmamak.
      if (note.urgent)
        Icon(
          Icons.priority_high_rounded,
          key: const ValueKey('card-urgent'),
          size: _statusIconSize,
          color: scheme.error,
        ),
      if (display.statusIcons) ...[
        // Sabitli ve yıldızlı: temanın SICAK vurgusu (TEMA_PLANI F31.4).
        if (note.pinned)
          Icon(Icons.push_pin, size: 13, color: accent ?? scheme.secondary),
        if (note.starred)
          Icon(Icons.star, size: 13, color: accent ?? scheme.secondary),
        if (!note.locked && note.aiSummary != null)
          Icon(Icons.auto_awesome, size: 13, color: scheme.primary),
        // ORTAK NOT: başkalarıyla paylaşılan (ya da bana paylaşılmış) not
        // kartında da belli olsun — Keep'teki ortak çalışan simgesi gibi.
        if (shared)
          Icon(AppIcons.shared, size: 13, color: accent ?? scheme.primary),
        // YALNIZ BU CİHAZDA (senkron kapalı) — kart bakışta söylesin.
        if (note.localOnly)
          Icon(Icons.cloud_off_outlined, size: 13, color: scheme.tertiary),
        // Hatırlatıcı en sonda: yakınsa yanında saati (F37.2), editörün
        // çipiyle aynı simge ve ton.
        if (note.reminderAt != null)
          Icon(
            note.reminderRepeat.isEmpty ? Icons.alarm : Icons.repeat,
            size: 13,
            color: accent ?? scheme.onSurfaceVariant,
          ),
        // ZAMANLI NOT: sessiz kum saati, yanında kalan süre (dar kartta yalnız
        // simge).
        if (note.expiresAt != null)
          Icon(
            Icons.hourglass_bottom,
            size: _kExpiryIcon,
            color: accent ?? scheme.onSurfaceVariant,
          ),
      ],
    ];
    final reminderLabel = display.statusIcons && note.reminderAt != null
        ? cardReminderLabel(context.l10n, note.reminderAt!, DateTime.now())
        : null;
    // ponytail: kart yeniden kurulana dek bayat kalabilir (cardReminderLabel
    // ile aynı ödünleşim).
    final expiryLabel = display.statusIcons && note.expiresAt != null
        ? noteExpiryLeft(context.l10n, note.expiresAt!, DateTime.now())
        : null;
    final showTag = display.tag && note.tags.isNotEmpty;
    final showDate = display.date && note.updatedAt != null;
    // Üst satır yalnızca başlık varsa çizilir. Başlıksız notta (madde 5) boş
    // bir üst bant bırakılmaz; içerik doğrudan tepeden başlar.
    final showTopRow = hasTitle;
    // DAR SÜTUN (kullanıcı bulgusu 2026-11-07: "3 ve 4 sütun görünümü iyi
    // değil"): başlık sözcük ortasından bölünüyor ("Harit-a"), alt satırda
    // etiket hapı boş lekeye dönüyor, simgeler tarihin üstüne biniyordu.
    final squeeze = noteCardSqueeze(context);
    // Kilitli notta içerik (ekler dahil) kartta gösterilmez; ekler ayardan
    // da kapatılabilir.
    final media =
        note.locked ||
            note.cardMediaHidden ||
            (!display.media && !display.files)
        ? null
        : CardMediaPlan.of(
            note,
            showVisuals: display.media,
            showFiles: display.files,
          );
    // Önizlemesi gizli eklerin tek satırlık özeti (F60.S8): ek var ama kart
    // çizmiyorsa "hiçbir şey yokmuş gibi" durmasın. Not sürümü başına ucuz.
    final hiddenMedia = CardHiddenMedia.of(
      note,
      showVisuals: display.media,
      showFiles: display.files,
    );
    final hero = media?.hero;
    // Balonlu notun belge kapağı (video/görsel kapağıyla aynı yerde).
    final cover = media?.cover;
    final hasCover = hero != null || cover != null;
    final borderWidth = note.hasFrame ? 2.5 : 1.0;
    // ARAMA SONUCUNDA KLASÖR (kullanıcı isteği 2026-10-20: "not ararken
    // bulunan notun hangi klasörde olduğu da yazmalı"). Yalnız arama
    // sürerken: normal ızgarada kart zaten klasörün içinde ya da klasör
    // şeridinin altında. Kart yalnız KENDİ klasörünün adını izler.
    // "Tümü" görünümünde de (klasördekiler ana ekrana karıştığı için).
    final folderId = note.folderId;
    final folderName =
        !showFolder ||
            !display.folder ||
            folderId == null ||
            (query.value.trim().isEmpty && !env.allView)
        ? null
        : ref.watch(
            foldersStreamProvider.select(
              (async) => async.value
                  ?.where((f) => f.id == folderId)
                  .firstOrNull
                  ?.name,
            ),
          );

    final padded = Padding(
      // Başlıksız kartta sağdan biraz içerik payı bırakılır ki ilk satır
      // köşedeki üç nokta düğmesinin altına girmesin (kapak varsa düğme
      // kapağın üstünde durur, pay gerekmez).
      padding: EdgeInsetsDirectional.fromSTEB(
        squeeze >= 2 ? 8 : 12,
        hasCover ? 8 : 10,
        showTopRow || hasCover ? (squeeze >= 2 ? 8 : 12) : 20,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTopRow)
            Padding(
              // Sağdaki 22px köşedeki üç nokta / seçim kutusuna yer açar; uzun
              // başlık düğmenin altına girmeden kısalır (…).
              padding: EdgeInsetsDirectional.only(
                bottom: 6,
                end: squeeze >= 2 ? 16 : 22,
              ),
              child: noteBodyText(
                context,
                // Biçimli başlık kartta da biçimli görünür; ayar kapalıyken
                // (ya da arama sürerken) düz `displayTitle` çizilir.
                preview.title,
                query,
                rich: richPreview,
                maxLines: 2,
                background: background,
                // Editör başlığının ailesi, ağırlığı, aralığı (K9, F37.1); boyu
                // 24 → 16, notun başlık ölçeğiyle oranlı.
                style: noteTitleStyle(
                  _cardThemeOf(context),
                  note,
                  fontSize:
                      _kCardTitleSize[squeeze] *
                      note.titleFontScale.clamp(0.8, 1.4),
                ),
              ),
            ),
          ...[
          // Kilitli not: içerik kartta gösterilmez; yalnızca kilit satırı.
          if (note.locked)
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                // Dar hücrede / büyük yazı ölçeğinde taşmasın.
                Flexible(
                  child: Text(
                    context.l10n.lockedNote,
                    overflow: TextOverflow.ellipsis,
                    style: _cardThemeOf(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          else if (credential)
            _SensitiveHidden(
              onLock: ownerId != null || readOnly
                  ? null
                  : () async {
                      final reason = context.l10n.unlockAuthReason;
                      final repo = ref.read(notesRepositoryProvider);
                      if (repo == null) return;
                      if (!await ensureNoteE2eeKeyForLock(reason)) return;
                      await repo.setLocked(note, true);
                    },
            )
          else ...[
            _NotePreview(
              note: note,
              preview: preview,
              highlightQuery: query,
              rich: richPreview,
              showProgress: display.progress,
              showMoreCount: display.moreCount,
              collapseChecked: !display.checked,
            ),
            // Ekler: belge kartı, küçük karolar, dosya/ses satırları (kapak
            // ayrıca kartın tepesinde). Zemin görseli ek sayılmaz.
            if (media != null &&
                ((media.heroDocument != null && cover == null) ||
                    media.strip.isNotEmpty ||
                    media.docs.isNotEmpty ||
                    media.audioCount > 0 ||
                    media.transcriptCount > 0)) ...[
              const SizedBox(height: 8),
              CardMediaBody(plan: media),
            ],
            if (!hiddenMedia.isEmpty) ...[
              const SizedBox(height: 8),
              CardHiddenMediaLine(media: hiddenMedia),
            ],
            if (note.hasPageInk) ...[
              const SizedBox(height: 8),
              CardPageInk(note: note),
            ],
          ],
          if (folderName != null && folderName.isNotEmpty) ...[
            const SizedBox(height: 8),
            _FolderBadge(name: folderName),
          ],
          // ALT META SATIRI: durum simgeleri · ilk etiket · sağda tarih.
          // Üçü tek bantta olduğu için kartın yüksekliği rozet sayısına göre
          // değişmiyor; eskiden etiketler Wrap ile ikinci satıra taşıyordu.
          if (statusIcons.isNotEmpty ||
              showTag ||
              showDate ||
              calendarDay != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                // Sol grup Expanded: tarih hep sağa yaslı. Spacer + Flexible
                // boşluğu oranla böler, kullanılmayan pay boş kalıp tarihi
                // ortaya bırakıyordu; saat de yer varken kesiliyordu (F37.2).
                Expanded(
                  child: Row(
                    children: [
                      for (final icon in squeeze >= 2
                          ? statusIcons.take(1)
                          : statusIcons)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 4),
                          child: icon,
                        ),
                      if (reminderLabel != null && squeeze == 0)
                        Flexible(
                          flex: 8,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: Text(
                              reminderLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: AppWeight.strong,
                                color: accent ?? scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      if (expiryLabel != null && squeeze == 0)
                        Flexible(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: Text(
                              expiryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.of(_cardThemeOf(context)).badge
                                  .copyWith(
                                    color: accent ?? scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                      if (calendarDay case final day?)
                        Flexible(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: CardCalendarPill(day: day, accent: accent),
                          ),
                        ),
                      // Dar kartta etiket hapı sıfıra sıkışıp boş bir
                      // mavi leke kalıyordu (kullanıcı bulgusu 2026-11-07).
                      if (showTag && squeeze == 0)
                        Flexible(
                          flex: 3,
                          child: TagPill(tag: note.tags.first, accent: accent),
                        ),
                    ],
                  ),
                ),
                if (showDate)
                  Text(
                    formatNoteDate(note.updatedAt!),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: squeeze >= 2 ? 10.5 : 12,
                      fontWeight: AppWeight.strong,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
          ],
        ],
      ),
    );

    // KAPAK kartın tepesinde, KENARDAN KENARA (Keep'teki gibi): üste
    // sabitli video/görsel ya da notun tek görseli/videosu. Kenarlık `Ink`
    // tarafından çocuğa dolgu olarak eklendiği için kapak çerçevenin İÇİNDE
    // kalır; köşe yarıçapı kenarlık kadar küçültülür.
    // DEFTER KÂĞIDI KARTTA DA (kullanıcı isteği 2026-10-20: "defter modu
    // açık olanlar dashboard'da da öyle görünmeli — çizgili sayfa kartta da
    // çizgili"). Desen editördekiyle aynı; çizgili desenlerde çizgiler
    // kartın yazı satırlarının altına oturur (bkz. RuledLines).
    final paperBody = note.paged && !note.locked && display.paper
        ? _withCardPaper(
            context,
            note,
            padded,
            // Cilt gölgesi köşelerden taşmasın; kapak varsa üst köşeler düz.
            hasCover
                ? BorderRadius.vertical(
                    bottom: Radius.circular(radius - borderWidth),
                  )
                : BorderRadius.circular(radius - borderWidth),
          )
        : padded;
    final content = !hasCover
        ? paperBody
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius - borderWidth),
                ),
                child: hero != null
                    ? CardHeroMedia(attachment: hero)
                    : CardDocumentCover(
                        document: cover!,
                        bubbleCount: media!.bubbleCount,
                      ),
              ),
              paperBody,
            ],
          );

    // Okunurluk teması ve koyu ton içeriğe iner; kart kabuğu (zemin, çizgi,
    // dokunuş dalgası) dış temada kalır.
    Widget inner = NoteAccent(
      accent: accent,
      background: NoteColors.effectiveSurface(context, note),
      child: content,
    );
    if (inkTheme != null) {
      inner = Theme(
        data: inkTheme,
        // Renksiz `Text` kart Material'ının (dış tema) stilini miras alır.
        child: DefaultTextStyle.merge(
          style: TextStyle(color: inkTheme.colorScheme.onSurface),
          child: inner,
        ),
      );
    }
    // Not rengi 200 ms'de değişir (F34.4); denetleyici yalnız değişince kurulur.
    final card = ColorFade(
      color: background,
      identity: (note.id, tokens.family, Theme.of(context).brightness),
      builder: (context, color, child) => Material(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        // Seçim modunda dokunuş seçimi değiştirir; normalde notu açar. Uzun
        // basış dashboard sarmalayıcısında yönetilir: yerinde bırakınca çoklu
        // seçim, sürükleyince yeniden sıralama (üç nokta menüsündeki "Seç" de
        // durur).
        onTap: selectionActive ? toggleSelection : () => _openNote(context),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            // SEÇİM BURADA DEĞİL: seçili kenarlık ayrı bir katman olarak
            // kartın ÜZERİNE çizilir (aşağıdaki Positioned.fill).
            //
            // KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "ana ekranda notları
            // basılı tutup seçerken kaymalar oluyor"): `Ink`, dekorasyonun
            // kenarlığını çocuğa DOLGU olarak ekler
            // (`BoxDecoration.padding == border.dimensions`). Seçince kenarlık
            // 1 → 2 px olunca kart 2 px uzuyordu; masonry ızgarada bir kartın
            // 2 px'i altındaki bütün sütunu kaydırıyor, arka arkaya seçimde
            // liste gözle görülür biçimde zıplıyordu. Kenarlık artık sabit
            // kalınlıkta; seçim yalnız BOYA katmanı, yerleşimi hiç etkilemez.
            // KENAR ÇİZGİSİ (TEMA_PLANI F31.1): renksiz kartta mürekkep %8,
            // renkli kartta kendi koyu tonu %16 — gri çizgi renkli kartı
            // kirletiyordu. Kalınlık sabit (yukarıdaki kök neden).
            border: Border.all(
              color:
                  NoteColors.noteFrame(
                    note,
                    dark: Theme.of(context).brightness == Brightness.dark,
                  ) ??
                  (accent?.withValues(alpha: 0.16) ?? tokens.hairline),
              width: borderWidth,
            ),
          ),
          // Notun ZEMİN görseli kartta da görünür (kullanıcı isteği: "her
          // notun zemin görseli dashboard'ta da görülmeli"). Editördeki
          // görünürlük ayarı burada da geçerli; görsel kartın köşelerine
          // kırpılır ve içeriğin ARKASINDA durur.
          child: _withNoteBackground(note, inner, radius),
        ),
      ),
    );
    // KÂĞIT MASADAN AYRILIR (TEMA_PLANI F31.2, K4): bulanıksız 1 dp alt
    // kenar — bulanık gölge Adreno ≤ 650'de (GLES, AKICILIK K7) her karede
    // yeniden taranırdı. Yumuşak gölge telefonda ölçülünce (KALANLAR §2).
    final shadowed = tokens.cardShadow.isEmpty
        ? card
        : DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: tokens.cardShadow,
            ),
            child: card,
          );

    // **EKRAN OKUYUCU** (TalkBack/Narrator): kart onlarca küçük parçadan
    // (başlık, gövde, madde satırları, rozetler, tarih) oluşuyor ve hepsi tek
    // tek okunuyordu — bir notu geçmek için on kaydırma gerekiyordu. Kart
    // artık TEK bir düğüm: "başlık, özet, durum" tek seferde okunur, seçili
    // olup olmadığı da söylenir.
    // Etiket UCUZ tutulur: `toPlainText()` notun bütün maddelerini dolaşıp
    // yeni bir dizgi kurar ve bu KART BAŞINA, HER build'de olurdu (önbellek
    // payında ~130 kart canlı). Ekran okuyucunun önizlemesi için notun ilk
    // birkaç satırı zaten yeterli; gövde hazır önizlemeden (ilk 160 karakter).
    final semanticLabel = [
      if (note.locked)
        context.l10n.lockedNote
      else if (credential) ...[
        if (hasTitle) note.displayTitle.trim(),
        context.l10n.sensitiveHiddenOnCard,
      ] else ...[
        if (hasTitle) note.displayTitle.trim(),
        preview.label,
        if (note.items.any((i) => i.text.trim().isNotEmpty))
          context.l10n.noteStatsItems(
            note.items.where((i) => i.text.trim().isNotEmpty).length,
          ),
      ],
      if (note.urgent) context.l10n.sectionUrgent,
      if (note.pinned) context.l10n.pin,
      if (note.starred) context.l10n.filterStarred,
      if (note.reminderAt != null) context.l10n.remindersTitle,
    ].where((s) => s.isNotEmpty).join('. ');

    // SİLİNİRKEN küçülüp solar (bkz. leavingNotesProvider) — yalnız bu kart
    // yeniden kurulur (tek abonelikteki `leaving`).
    final leaving = env.leaving;
    // BASINCA HAFİFÇE ÇÖKER (iOS dokunsal hissi — bkz. PressScale): dönüşüm
    // RepaintBoundary'nin DIŞINDA, yani kartın önbellekli katmanı yalnız
    // ölçeklenir, yeniden boyanmaz.
    final framed = frame;
    final out = _Leaving(
      leaving: leaving,
      child: PressScale(
        enabled: !selectionActive,
        child: RepaintBoundary(
          child: Semantics(
            container: true,
            button: true,
            selected: selectionActive ? selected : null,
            label: semanticLabel,
            // F15.3: kartın İÇİ okunmaz (aşağıdaki ExcludeSemantics) — tek
            // düğüm, tek etiket; dokunuş eylemi burada.
            onTap: selectionActive ? toggleSelection : () => _openNote(context),
            child: GestureDetector(
              // Ekran okuyucuda ADSIZ bir "dokun" düğümü açıyordu (F15.7);
              // aynı menü ⋮ düğmesinde, ekran okuyucu oradan ulaşır.
              excludeFromSemantics: true,
              // Sağ tık HER platformda: fareli tablet (Android) ve web de
              // masaüstü gibi bağlam menüsü alır. Dokunmatik ekran ikincil
              // dokunuş üretmediği için telefonda davranış değişmez.
              // Paylaşılan notun menüsü yok (bkz. aşağıdaki ⋮ notu).
              onSecondaryTapUp: ownerId != null
                  ? null
                  : (details) =>
                        _showContextMenu(context, ref, details.globalPosition),
              child: _CardHover(
                child: Stack(
                children: [
                  ExcludeSemantics(child: shadowed),
                  // Üç nokta hızlı işlem düğmesi (madde 5): kartın SAĞ ÜST KÖŞESİnde
                  // durur — ikon köşeye hizalı, dokunma alanı 48dp (F15.4). Seçim modunda
                  // gizlenir; yerine tik rozeti gelir. Katmandan bağımsız olduğu için
                  // başlık satırının yerleşimini değiştirmez (masonry sütun dengesi
                  // seçim sırasında sabit kalır).
                  // PAYLAŞILAN notta ⋮ YOK: levhadaki işlemlerin hepsi
                  // `notesRepositoryProvider` üzerinden, yani BENİM koleksiyonuma
                  // yazar — başkasının notunda o işlemler kendi altımda aynı
                  // kimlikle HAYALET bir doküman yaratırdı. Paylaşılan notu
                  // düzenlemek editörden geçer (o, sahibin deposuna yazar).
                  if (!selectionActive && ownerId == null)
                    PositionedDirectional(
                      top: 2,
                      end: 2,
                      // Ekran okuyucuda kendi adıyla AYRI düğüm (F15.2);
                      // dokunma alanı 48 dp (F15.4) — simge köşede aynı
                      // yerde kalır, alan yalnız içeri doğru büyür.
                      child: Semantics(
                        container: true,
                        button: true,
                        label: context.l10n.noteMenu,
                        excludeSemantics: true,
                        onTap: () => showNoteActionsSheet(context, ref, note),
                        child: _RevealOnCardHover(
                        child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const ValueKey('note-card-menu'),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          onTap: () => showNoteActionsSheet(context, ref, note),
                          child: SizedBox(
                            width: kMinInteractiveDimension,
                            height: kMinInteractiveDimension,
                            child: Align(
                              alignment: AlignmentDirectional.topEnd,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                // Kapağın üstünde düğme koyu yuvarlakla okunur
                                // kalır (açık renkli fotoğrafta kaybolmasın).
                                // F74.4(b): düz kartta soluk (krom susar),
                                // görselli kartta 28 dp siyah %32 daire.
                                child: !hasCover
                                    ? Icon(
                                        Icons.more_vert,
                                        size: AppIconSize.s,
                                        color: scheme.onSurfaceVariant
                                            .withValues(alpha: AppAlpha.muted),
                                      )
                                    : DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: AppAlpha.scrim,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const SizedBox.square(
                                          dimension: 28,
                                          child: Icon(
                                            Icons.more_vert,
                                            size: AppIconSize.s,
                                            color: Colors.white,
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
                    ),
                  // Seçim çerçevesi: yerleşimi değiştirmeyen boya katmanı
                  // (yukarıdaki kök nedene bak). `IgnorePointer` şart — katman
                  // kartın tamamını kapladığı için dokunuşu yutardı.
                  if (selected)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(color: scheme.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                  if (selected)
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
    return framed == null
        ? out
        : framed(out, focused: env.focused, open: env.open);
  }
}


class _NotePreview extends StatelessWidget {
  const _NotePreview({
    required this.note,
    required this.preview,
    required this.rich,
    this.highlightQuery = FixedQuery.empty,
    this.showProgress = false,
    this.showMoreCount = true,
    this.collapseChecked = false,
  });

  final Note note;

  /// Notun hazır (dilimlenmiş, gerekirse örtülmüş) metinleri — gösterilen
  /// her metin buradan gelir (F21.1/F21.2, hassas numaralar B1).
  final CardPreview preview;

  /// Yapılacaklar ilerlemesi ("3/10") ve "+N öğe daha" satırı çizilsin mi
  /// (Ayarlar → Görünüm → Kartlar).
  final bool showProgress;
  final bool showMoreCount;

  /// İşaretliler tek satır özete insin mi (F74.4; `card_show_checked` kapalı).
  final bool collapseChecked;
  final ValueListenable<String> highlightQuery;

  /// Satır içi biçim çizilsin mi (Ayarlar → Görünüm).
  final bool rich;

  @override
  Widget build(BuildContext context) {
    final scheme = _cardThemeOf(context).colorScheme;
    // Kart önizlemesi notun KENDİ yazı tipini ve boyut çarpanını kullanır:
    // kullanıcı yazı tipini değiştirdiğinde ana ekranda da görmeli, yoksa
    // seçim yalnız editörde varmış gibi duruyordu. Kartın kendi küçük taban
    // boyutu korunur; çarpan onun üzerine biner (ızgara bozulmasın diye
    // makul bir tavanla).
    final cardBase = _cardThemeOf(context).textTheme.bodySmall ?? const TextStyle();
    final bodyStyle = applyNoteOpacity(
      applyNoteFont(
        cardBase.copyWith(
          color: scheme.onSurface.withValues(alpha: AppAlpha.strong),
          fontSize: (cardBase.fontSize ?? 12) * note.fontScale.clamp(0.8, 1.4),
        ),
        note.fontFamily,
      ),
      // Notun şeffaflığı kartta da görünür (yazı tipiyle aynı gerekçe); kart
      // yazısı zaten soluk olduğundan çarpım 0.85 üzerinden gider.
      note.textOpacity,
      scheme.onSurface,
    );

    switch (note.type) {
      // ARŞİV DEFTERİ kartta kendini belli eder (kullanıcı bulgusu
      // 2026-08-16: "arşiv notu ekledim ama görünümü farklı olmalı,
      // dashboard'ta arşiv notu olduğu belli olmalı"). Sıradan bir notla
      // aynı görününce defterin ne olduğu ancak açınca anlaşılıyordu.
      // Rozet, defterin içindekileri de sayar: kaç dosya, kaç metin girdisi.
      case NoteType.archive:
        final files = note.attachmentsWithoutBackground.length;
        final texts = note.items.where((i) => i.text.trim().isNotEmpty).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 13,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.l10n.archiveNotebook,
                    style: bodyStyle.copyWith(
                      color: scheme.onTertiaryContainer,
                      fontWeight: AppWeight.strong,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.archiveCardSummary(files, texts),
              style: bodyStyle,
            ),
            if (note.archivePages.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note.archivePages.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        );
      case NoteType.text:
        // Karışık içerik: metin notu hem gövde hem checklist maddesi taşıyabilir.
        final hasBody = note.body.trim().isNotEmpty;
        // Editörle aynı düzen: işaretsiz (aktif) maddeler üstte, işaretliler
        // altta. Depodaki ham sıra işaretlileri araya serpiştirebiliyor; kart
        // bunları sıralamadan gösterince aktif maddelerin bir kısmı önizlemede
        // görünmüyordu (kullanıcı: "notta 4 madde var, kartta 2 görünüyor").
        final rawItems = [
          for (final i in note.items)
            if (i.text.trim().isNotEmpty) i,
        ];
        final items = [
          for (final i in rawItems)
            if (!i.checked) i,
          for (final i in rawItems)
            if (i.checked) i,
        ];
        if (!hasBody && items.isEmpty) return const SizedBox.shrink();
        // Madde varsa metin 2 satıra kısalır ki maddelere yer kalsın; yoksa
        // 4 satır (8 satır 2 sütunlu ızgarada metin duvarına dönüşüyordu).
        final maxItems = hasBody ? 3 : 5;
        final bodyLines = items.isEmpty ? 4 : 2;
        final slice = cardItemSlice(
          items,
          maxItems,
          collapseChecked: collapseChecked,
        );
        // Aramada eşleşme gövdenin görünen başında değilse onun çevresi
        // gösterilir (F21.3) — yoksa vurgu kartta hiç görünmezdi.
        // Kesit sorgunun KENDİSİNE bağlı (eşleşmenin konumu) — yalnız bu
        // parça sorguyu izler, kartın gerisi kurulmaz (F21.6).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBody)
              _SearchExcerptBody(
                preview: preview,
                query: highlightQuery,
                rich: rich,
                maxLines: bodyLines,
                style: bodyStyle,
              ),
            if (items.isNotEmpty) ...[
              if (hasBody) const SizedBox(height: 6),
              for (final item in slice.shown)
                _CardItemRow(
                  item: item,
                  text: preview.item(item.text),
                  style: bodyStyle,
                  query: highlightQuery,
                  rich: rich,
                  checkbox: true,
                ),
              if (showMoreCount && slice.more > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _moreItemsLabel(context, slice.more),
                    style: _cardThemeOf(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (slice.done > 0)
                _CardDoneLine(done: slice.done, allDone: slice.allDone),
              if (showProgress) _ChecklistProgress(items: items),
            ],
          ],
        );
      case NoteType.checklist:
      case NoteType.ordered:
        final raw = [
          for (final item in note.items)
            if (item.text.trim().isNotEmpty) item,
        ];
        // Checklist'te işaretsizler önce (editördeki düzen); sıralı listede
        // numara sırası korunmalı, dokunma.
        final visible = note.type == NoteType.checklist
            ? [
                for (final i in raw)
                  if (!i.checked) i,
                for (final i in raw)
                  if (i.checked) i,
              ]
            : raw;
        if (visible.isEmpty) return const SizedBox.shrink();
        // Sıralı listede numara sırası anlamlı: işaretliler özete inmez.
        final slice = cardItemSlice(
          visible,
          6,
          collapseChecked:
              collapseChecked && note.type == NoteType.checklist,
        );
        final shown = slice.shown;
        final remaining = slice.more;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < shown.length; i++)
              _CardItemRow(
                item: shown[i],
                text: preview.item(shown[i].text),
                style: bodyStyle,
                query: highlightQuery,
                rich: rich,
                checkbox: note.type == NoteType.checklist,
                numbered: note.type == NoteType.ordered,
                number: note.type == NoteType.ordered
                    ? itemOrderNumber(shown, i)
                    : null,
              ),
            if (showMoreCount && remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _moreItemsLabel(context, remaining),
                  style: _cardThemeOf(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (slice.done > 0)
              _CardDoneLine(done: slice.done, allDone: slice.allDone),
            if (showProgress && note.type == NoteType.checklist)
              _ChecklistProgress(items: visible),
          ],
        );
      case NoteType.pdf:
      case NoteType.slides:
        // Kartta belgenin kendisi değil, KULLANICININ YAZDIĞI görünür: sayfa
        // notları sayfa numarasıyla, sırayla. (Belge zaten alttaki ek
        // önizlemesinde PDF rozetiyle duruyor.)
        final pages = [
          for (final a in note.attachments)
            ...orderedPageNotes(attachment: a, pageNotes: note.pageNotes),
        ];
        if (pages.isEmpty) return const SizedBox.shrink();
        final shownPages = pages.take(5).toList();
        final morePages = pages.length - shownPages.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in shownPages)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: Text(
                        '${entry.page}.',
                        style: bodyStyle.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: noteBodyText(
                        context,
                        preview.item(entry.text),
                        highlightQuery,
                        rich: rich,
                        maxLines: 1,
                        style: bodyStyle,
                      ),
                    ),
                  ],
                ),
              ),
            if (showMoreCount && morePages > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _moreItemsLabel(context, morePages),
                  style: _cardThemeOf(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
    }
  }
}

