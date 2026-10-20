import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
// ScrollCacheExtent (ızgara önbellek payı) yalnız rendering katmanında.
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_commands.dart';
import '../../../app/router.dart';
import '../../../app/theme/note_colors.dart';
import '../../../core/widgets/action_menu_sheet.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import '../../../core/widgets/customizable.dart';
import '../../../core/widgets/freeze_when_hidden.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/gemini_service.dart';
import '../../ai/data/semantic_search.dart';
import '../../folders/data/folder_order.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/data/folder_activity.dart';
import '../../folders/domain/note_folder.dart';
import '../../folders/presentation/folder_sheets.dart';
import '../../folders/presentation/folder_tile.dart';
import '../../auth/presentation/account_sheet.dart';
import '../../auth/presentation/guest_backup_card.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../friends/presentation/home_invites.dart';
import '../../inbox/presentation/inbox_screen.dart';
import '../../inbox/presentation/shared_hub_screen.dart';
import '../../settings/settings_providers.dart';
import '../../settings/presentation/permissions_onboarding.dart';
import '../data/attachment_repository.dart';
import '../data/notes_repository.dart';
import '../data/upload_queue.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import '../domain/note_type.dart';
import 'color_picker_sheet.dart';
import 'dashboard_background_sheet.dart';
import 'dashboard_pattern.dart';
import 'filter_sheet.dart';
import 'note_card.dart';
import 'note_grid.dart';
import 'notes_providers.dart';
import 'quick_add_actions.dart';
import 'quick_add_fab.dart';
import 'voice_assistant.dart';
import 'voice_assistant_widgets.dart';
import 'voice_capture_sheet.dart';
import 'drive_ui.dart';
import '../../../core/widgets/skeleton.dart';

part 'dashboard_widgets.dart';

/// Ana ekran ızgarasının önbellek payı (px): görünen alanın altında/üstünde
/// önceden kurulan kartlar — hızlı kaydırmada kart boş gelmesin diye ~2
/// ekran boyu.
///
/// **2026-10-16 — 10 000'DEN İNDİRİLDİ** (kullanıcı: "FPS düşük, her alanda
/// süper akıcı olsun"). Geniş pay, MASONRY ızgaranın toplam uzunluğunu
/// tahmin edip listeyi yukarı sıçratmasına karşı konmuştu: kartların
/// tamamını (~130 kart, kapakları ve küçük resimleriyle) ilk yerleşimde
/// ölçtürüyordu. Masonry artık yok: ızgara deterministik sütunlu TEMBEL
/// listeler (bkz. `sliverBalancedNoteColumns`). Her sütun bir `SliverList`:
/// bir kart görünmeden önce bu pay içinde yerleşir, son kartlar da sona
/// varılmadan ölçülmüş olur — uzunluk aşağı kaydırırken küçülüp konumu
/// geri çekmez. Pay yalnız hızlı kaydırmada boş kart görülmesin diye var.
const double _kGridCacheExtent = 1600;

/// Izgaranın altında bırakılan boşluk: sağ alttaki düğme satırı
/// (mikrofon + "+" yan yana, 56 + alt pay 16 = 72, + 24 nefes payı)
/// ızgaranın ÜSTÜNDE yüzüyor. 2026-10-20 (B2): üç düğmeli sütun tek satıra
/// indi, pay 200 → 96.
///
/// KÖK NEDEN (ana sayfa düzeni, 2026-09-23): boşluk 88 px idi — sütun tek bir
/// FAB'ken yazılmış bir değer. Sütun üç düğmeye çıkınca sağ sütunun son
/// kartının alt yarısı listenin en sonuna kaydırıldığında bile düğmelerin
/// ARKASINDA kalıyordu; kartın altındaki metne/tarihe hiç ulaşılamıyordu.
const double _kFabClearance = 96;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver, QuickAddActions {
  /// Kart ızgarasının kaydırma denetleyicisi — "başa dön" düğmesi buradan
  /// tepeye döner.
  ///
  /// TUZAK: ızgara bölüm değişiminde `AnimatedSwitcher` ile yenilenir ve geçiş
  /// süresince ESKİ ve YENİ görünüm aynı anda ayakta olabilir; ikisi de bu
  /// denetleyiciye bağlanır. Bu yüzden konum `_gridScroll.offset` ile
  /// OKUNMAZ (tek konum varsayar, iki konumda fırlatır) — konum kaydırma
  /// bildiriminden izlenir. `animateTo` çok konumla çalışır.
  ///
  /// `keepScrollOffset: false` BİLEREK: ızgara segment (süzgeç|klasör|etiket)
  /// değişince `ValueKey` ile yeniden kurulur ve tek bir denetleyici paylaşan
  /// iki görünüm arasında konum TAŞINABİLİRDİ — yeni süzgeç, eskisinin
  /// kaldığı yerden açılırdı (kısa listede boş ekran). Kapalıyken her yeni
  /// segment tepeden başlar; aynı segment içinde konum zaten korunur (widget
  /// aynı kalır, konum nesnesi yeniden kurulmaz).
  final _gridScroll = ScrollController(keepScrollOffset: false);

  /// Kart widget'ı önbelleği (F2.1): not ÖRNEĞİ ve arama sorgusu aynıysa
  /// AYNI `NoteCard` örneği döner — Flutter aynı örneği görünce o kartın alt
  /// ağacını hiç kurmaz. Bir notun yazımı (editörde otomatik kayıt) ana ekranı
  /// yeniden kurduğunda görünen BÜTÜN kartlar (medya planı, zengin önizleme
  /// ayrıştırması, kapak) baştan kuruluyordu; artık yalnız değişen kart.
  final Map<String, (Note, String, Widget)> _cardCache = {};

  Widget _cachedCard(Note note, String query) {
    final hit = _cardCache[note.id];
    if (hit != null && identical(hit.$1, note) && hit.$2 == query) {
      return hit.$3;
    }
    final card = NoteCard(note: note, highlightQuery: query);
    _cardCache[note.id] = (note, query, card);
    return card;
  }

  /// Silinmiş/ekrandan çıkmış notların kartlarını önbellekten düşürür.
  void _pruneCardCache(List<Note> visible) {
    if (_cardCache.length <= visible.length + 32) return;
    final ids = {for (final n in visible) n.id};
    _cardCache.removeWhere((id, _) => !ids.contains(id));
  }

  /// Kullanıcı bu kadar aşağıdaysa "başa dön" düğmesi görünür. Bir ekran
  /// yüksekliğinden fazlası: kısa bir kaydırmada düğme çıkıp kaybolmasın.
  static const _kBackToTopAfter = 800.0;
  bool _showBackToTop = false;

  // ---- Yüzen "+" düğmesinin kancaları (bkz. QuickAddActions) -------------

  /// Yeni not, ana ekranda o an SEÇİLİ olan klasöre doğar.
  @override
  String? get quickAddFolderId => ref.read(selectedFolderProvider);

  @override
  Future<void> openNewNote(String id, {String query = '', NoteType? type}) =>
      _openNew(id, query: query, type: type);

  /// Ana ekranın arama kutusu var: yeni not yazılı bir arama yüzünden
  /// listeden elenmesin.
  @override
  void clearQuickAddSearchBox() => _searchController.clear();

  /// Metin provider'dan başlar: dar↔geniş kesme noktası geçişinde (tablet
  /// döndürme, pencere boyutlandırma) ekran BAŞKA bir DashboardScreen
  /// instance'ına geçiyor; kutu boş başlasaydı liste görünmez bir sorguyla
  /// süzülü kalırdı (searchQueryProvider global, kutu ise State'te).
  late final _searchController = TextEditingController(
    text: ref.read(searchQueryProvider),
  );
  final _searchFocus = FocusNode();

  /// "+" menüsünün demirlendiği nokta: "+" düğmesi (mikrofon solunda).
  final _fabColumnLink = LayerLink();

  /// Filtreler arası geçiş yönü (madde 2): sola çekiş → sonraki (sağdan girer),
  /// sağa çekiş → önceki (soldan girer). Geçiş animasyonu bu yönü kullanır.
  bool _swipeForward = true;

  /// İki parmak zoom başlangıcındaki sütun sayısı. Hedef sütun bu değere göre
  /// hesaplanır; canlı değere bakmak hareketi katlardı (parmak sabit dururken
  /// sütunlar kaymaya devam ederdi).
  int _zoomBaseColumns = 2;

  /// İki parmakla açma/kapama hareketini sütun sayısına çevirir: parmaklar
  /// açılınca (scale > 1) kartlar büyür → sütun AZALIR, kapanınca artar.
  /// 1 ↔ 2 ↔ 3 ↔ 4 sütun arasında gezilir.
  ///
  /// Eşik neden 1.25: her karede oran biraz oynadığından ham yuvarlama sütunu
  /// ileri geri titretiyordu. Bir adım için parmak arasının en az %25
  /// değişmesi istenir; adım atıldıktan sonra taban güncellenir ki aynı jestle
  /// 1 → 4 arası gezilebilsin.
  bool _applyZoom(double scale, int columns) {
    const threshold = 1.25;
    if (scale <= 0) return false;
    final int target;
    if (scale >= threshold) {
      target = _zoomBaseColumns - 1;
    } else if (scale <= 1 / threshold) {
      target = _zoomBaseColumns + 1;
    } else {
      return false;
    }
    final clamped = target.clamp(
      GridColumnsNotifier.minColumns,
      GridColumnsNotifier.maxColumns,
    );
    _zoomBaseColumns = clamped;
    if (clamped == columns) return true;
    ref.read(gridColumnsProvider.notifier).set(clamped);
    HapticFeedback.selectionClick();
    // Yeni düzen kaç sütun oldu — kısa bir bildirim, jest "bir şey yaptı" mı
    // sorusunu bırakmaz.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(
        context.l10n.gridColumnsCount(clamped),
        duration: const Duration(milliseconds: 900),
      );
    return true;
  }

  @override
  void initState() {
    super.initState();
    // KÖK NEDEN (kasma): burada `_searchFocus.addListener(() => setState(...))`
    // vardı — arama alanına her dokunuş EKRANIN TAMAMINI (ve önbellek
    // payındaki ~130 kartı) yeniden kuruyordu. Odak artık yalnız arama
    // çubuğunu saran `ListenableBuilder` tarafından dinleniyor.
    // Widget/derin bağlantı bu ekran mount olmadan önce bas-başlat istemiş
    // olabilir (uygulama kapalıyken ya da başka ekrandayken). İlk kareden
    // sonra kontrol et; take() varsa asistanı başlatır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutostartVoice();
      // İlk açılışta izin tanıtımı (bir kez).
      if (mounted) PermissionsOnboarding.maybeShow(context, ref);
    });
    // Kendi e-posta → uid kaydını tazele (kişiler/klasör paylaşımı bunu
    // arar — bkz. FriendsRepository). Ucuz (tek doküman, merge), e-postası
    // olmayan (anonim/yerel) hesapta hiçbir şey yapmaz.
    WidgetsBinding.instance.addObserver(this);
    _syncOwnDirectoryEntry();
  }

  void _syncOwnDirectoryEntry() => ref
      .read(friendsRepositoryProvider)
      ?.syncOwnDirectoryEntry(discoverable: ref.read(discoverableProvider));

  /// **KÖK NEDEN (kullanıcı bulgusu 2026-08-18: "böyle bir hesap var ama
  /// bulamıyor").** Dizin kaydı yalnız `initState`te, yani State ilk
  /// KURULDUĞUNDA yazılıyordu. APK GÜNCELLENİP uygulama tam kapat-aç
  /// yapılmadan (arka planda kalıp öne getirilerek) devam edildiğinde
  /// `initState` bir daha ÇALIŞMIYOR — eski sürümde arkadaş özelliği
  /// yokken açılmış oturum, güncellemeden sonra da hâlâ aynı State'i
  /// kullanıyor, yeni eklenen senkron kodu hiç tetiklenmiyor. Kullanıcının
  /// e-postası dizine hiç yazılmıyor, arkadaşı onu "bulamıyor."
  ///
  /// ÇÖZÜM: uygulama ÖNE her getirildiğinde (resume) de tazelenir — ucuz
  /// bir tek-doküman `merge` yazımı, güncelleme sonrası ilk "arkaya al/öne
  /// getir" bunu kendiliğinden düzeltir.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) _syncOwnDirectoryEntry();
  }

  /// Ana ekran mikrofon widget'ının isteği varsa sesli not levhasını açar
  /// (tek seferlik — bayrak take ile tüketilir).
  void _maybeAutostartVoice() {
    if (!mounted) return;
    // Widget/kısayol da ana ekran mikrofonuyla AYNI levhayı açar (eskiden
    // ayrı bir asistan kaydı başlatıyordu — sadeleştirme 2026-10-19).
    if (ref.read(voiceAutostartProvider.notifier).take()) {
      unawaited(_captureVoiceNote());
    }
  }

  /// Not ızgarası kaydırıldı mı — başlık bloğunun (arama çubuğu + süzgeç
  /// çipleri) altındaki AYIRICI bunu izler.
  ///
  /// KÖK NEDEN (kullanıcı ekran görüntüsü 2026-08-09: "üst işaretli alan
  /// kayarken beraber kaymasın, görüntüyü bozuyor"): başlık bloğu zaten
  /// kaydırma görünümünün DIŞINDA sabit duruyor, ama arkası saydam ve altında
  /// hiçbir sınır yoktu. Kartlar bloğun dibinden kırpılarak geçtiği için
  /// yarım kalan kart çiplerin devamı gibi okunuyor, göz başlığın da kaydığını
  /// sanıyordu. Kaydırma başlar başlamaz beliren gölgeli ayırıcı iki katmanı
  /// birbirinden ayırır.
  ///
  /// `ValueNotifier`: kaydırma bildirimi ekranın TAMAMINI değil yalnız bu
  /// ince çizgiyi yeniden çizsin (ızgara önbelleğinde ~130 kart var).
  final _gridScrolled = ValueNotifier(false);

  /// Kaydırma bildirimini ayırıcıya bağlar; `false` dönerek bildirimi
  /// yukarıya (iç içe kaydırıcılara) geçirmeye devam eder.
  bool _onGridScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final pixels = notification.metrics.pixels;
    final scrolled = pixels > 2;
    if (_gridScrolled.value != scrolled) _gridScrolled.value = scrolled;
    // "Başa dön" düğmesinin görünürlüğü de AYNI bildirimden beslenir; ayrı
    // bir dinleyici ikinci bir yeniden çizim demekti.
    final showTop = pixels > _kBackToTopAfter;
    if (showTop != _showBackToTop && mounted) {
      setState(() => _showBackToTop = showTop);
    }
    return false;
  }

  /// Izgarayı tepeye döndürür. `animateTo` birden çok konumla çalışır
  /// (bkz. [_gridScroll]).
  void _backToTop() {
    if (!_gridScroll.hasClients) return;
    _gridScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocus.dispose();
    _gridScrolled.dispose();
    _gridScroll.dispose();
    super.dispose();
  }

  /// Seçilen notları çöp kutusuna taşır; tek dokunuşla geri alınabilir.
  Future<void> _deleteSelected(Set<String> ids) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    // Kilitli not toplu yoldan da doğrulamasız silinmesin (tekli eylem
    // levhasıyla aynı kural).
    if (_selectedNotes(ids).any((n) => n.locked) &&
        !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    if (!mounted) return;
    ref.read(selectedNoteIdsProvider.notifier).clear();
    // Seçili kartlar birlikte küçülüp solar, sonra silinir (bkz.
    // leavingNotesProvider).
    await ref.read(leavingNotesProvider.notifier).leave(ids, () {
      repo.softDeleteAll(ids);
    });
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: l10n.notesDeletedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.restoreAll(ids),
    );
  }

  /// Seçilen notları TEK levhada bir klasöre taşır.
  ///
  /// NEDEN: klasöre taşıma yalnız TEKLİ eylem levhasındaydı. Yirmi notu
  /// düzenlemek isteyen kullanıcı yirmi kez basılı tutup yirmi kez levha
  /// açmak zorundaydı — oysa toplu seçim çubuğunda arşivleme, silme,
  /// renklendirme zaten vardı.
  Future<void> _moveSelectedToFolder(Set<String> ids) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    // Eski klasörler geri alma için önce not edilir.
    final previous = {for (final n in _selectedNotes(ids)) n.id: n.folderId};
    final picked = await showFolderPickSheet(context, ref);
    if (picked == null || !mounted) return;
    unawaited(
      repo.batchUpdate(ids, {'folderId': picked.isEmpty ? null : picked}),
    );
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      message: l10n.notesMovedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.batchUpdateEach({
        for (final entry in previous.entries)
          entry.key: {'folderId': entry.value},
      }),
    );
  }

  /// Seçilen notların kopyalarını oluşturur (bkz.
  /// [NotesRepository.duplicateNote] — ekler kopyalanmaz).
  Future<void> _duplicateSelected(Set<String> ids) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    final notes = _selectedNotes(ids);
    if (notes.any((n) => n.locked) &&
        !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    final created = <String>[];
    for (final note in notes) {
      created.add(await repo.duplicateNote(note));
    }
    if (!mounted) return;
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      // Ekli notlarda ekler kopyaya taşınmaz (bkz. note_actions_sheet).
      message: notes.any((n) => n.attachments.isNotEmpty)
          ? l10n.noteDuplicatedNoAttachments
          : l10n.notesDuplicatedCount(created.length),
      undoLabel: l10n.undo,
      // Kopyalar henüz hiç düzenlenmedi: geri alma onları kalıcı siler,
      // çöpe düşürüp kullanıcıya ikinci bir temizlik işi bırakmaz.
      onUndo: () {
        for (final id in created) {
          repo.hardDelete(id);
        }
      },
    );
  }

  List<Note> _selectedNotes(Set<String> ids) {
    final all = ref.read(notesStreamProvider).value ?? const <Note>[];
    return [
      for (final n in all)
        if (ids.contains(n.id)) n,
    ];
  }

  void _archiveSelected(Set<String> ids) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    repo.setArchivedAll(ids, true);
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      message: l10n.notesArchivedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.setArchivedAll(ids, false),
    );
  }

  /// Liste satırını SAĞA çekmek: sabitle / sabitlemeyi kaldır.
  void _swipePin(Note note) {
    ref.read(notesRepositoryProvider)?.setPinned(note.id, !note.pinned);
    HapticFeedback.selectionClick();
  }

  /// Liste satırını SOLA çekmek: arşivle (geri alınabilir).
  void _swipeArchive(Note note) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    repo.setArchived(note.id, true);
    HapticFeedback.mediumImpact();
    showUndoSnackBar(
      context,
      message: context.l10n.noteArchived,
      undoLabel: context.l10n.undo,
      onUndo: () => repo.setArchived(note.id, false),
    );
  }

  void _setPinnedSelected(Set<String> ids, bool pinned) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    repo.batchUpdate(ids, {'pinned': pinned});
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }

  void _setStarredSelected(Set<String> ids, bool starred) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    repo.batchUpdate(ids, {'starred': starred});
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }

  /// Seçili notların metnini birleştirir. Kilitli notlardan yalnız başlık
  /// alınır (içerik kimlik doğrulaması olmadan sızmasın).
  String _joinSelected(Set<String> ids) {
    final l10n = context.l10n;
    // Paylaş levhasıyla AYNI biçim (bkz. noteShareText): `- [ ]` yerine
    // ☐/☑, sayfa notlarında "Sayfa 3". Kilitli notun yalnız başlığı gider.
    return joinShareTexts([
      for (final n in _selectedNotes(ids))
        // displayTitle: başlık biçimlendirilebiliyor, işaretler panoya sızmasın.
        if (n.locked)
          n.displayTitle.trim()
        else
          noteShareText(n, pageLabel: l10n.pageLabel),
    ]);
  }

  Future<void> _copySelected(Set<String> ids) async {
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: _joinSelected(ids)));
    ref.read(selectedNoteIdsProvider.notifier).clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(l10n.copied);
  }

  Future<void> _shareSelected(Set<String> ids) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final text = _joinSelected(ids);
    ref.read(selectedNoteIdsProvider.notifier).clear();
    // Sessiz kapanmak YOK: yalnız belge notu seçildiyse (düz metni boştur)
    // düğmenin neden bir şey yapmadığı söylenir.
    if (text.trim().isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(l10n.shareAsTextEmpty);
      return;
    }
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _colorSelected(Set<String> ids, {required bool frame}) async {
    final picked = await showNoteColorPicker(context, frame: frame);
    if (picked == null) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    unawaited(
      repo.batchUpdate(ids, {
        frame ? 'frameColor' : 'color': picked.color.id,
        frame ? 'customFrameColor' : 'customColor': picked.custom,
      }),
    );
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }

  /// Gizli klasörleri göster/sakla. Göstermek KİMLİK DOĞRULAMASI ister
  /// (cihazda kilit yoksa engel çıkarılmaz — bkz. authenticateForNote);
  /// saklamak serbesttir. Açık hâl kalıcı değildir: uygulama yeniden
  /// açıldığında klasörler yine gizlidir.
  Future<void> _toggleHiddenFolders() async {
    final l10n = context.l10n;
    final revealed = ref.read(hiddenFoldersRevealedProvider);
    if (revealed) {
      ref.read(hiddenFoldersRevealedProvider.notifier).set(false);
      // Gizli bir klasör o an seçiliyse süzgeç bırakılır; aksi hâlde ekran
      // artık ulaşılamayan bir klasörde boş kalırdı.
      final selected = ref.read(selectedFolderProvider);
      if (selected != null &&
          ref.read(hiddenFolderIdsProvider).contains(selected)) {
        ref.read(selectedFolderProvider.notifier).set(null);
      }
      if (!mounted) return;
      showQuickAddSnack(l10n.hiddenFoldersHiddenAgain);
      return;
    }
    if (!await authenticateForNote(l10n.hiddenFolderAuthReason)) return;
    ref.read(hiddenFoldersRevealedProvider.notifier).set(true);
    if (!mounted) return;
    showQuickAddSnack(l10n.hiddenFoldersShown);
  }
  // Sıralama seçici alt sayfası (_pickSort) kaldırıldı: sıralama artık Süz
  // levhasının SIRALAMA bölümünde, süzgeçlerle aynı yerde.

  /// Ana ekranı yatay çekince (madde 1) aktif görünümü sonraki/önceki
  /// durağa taşır: Tümü → notu olan durum süzgeçleri → etiketler. [direction]
  /// +1 sonraki, -1 önceki. Durakların kuralı saf bir işlevde ve ölçülüyor
  /// (bkz. [nextSwipeStop]).
  ///
  /// **KLASÖRLER GEZİDE** (kullanıcı isteği 2026-09-26: "sağ sol
  /// kaydırmada klasörler arası geçiş"). 2026-08-18'de çıkarılmışlardı;
  /// neyin gezileceği artık Ayarlar → Notlar'da seçiliyor (bkz. [SwipeMode],
  /// varsayılan: klasörler). Sıra, kullanıcının klasör sırasıdır (bkz.
  /// `visibleOrderedFoldersProvider`).
  void _cycleFilterFolder(int direction) {
    final suppressed = ref.read(suppressedFolderIdsProvider);
    final notes = [
      for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
        if (n.archivedAt == null &&
            !n.isEmpty &&
            !suppressed.contains(n.folderId))
          n,
    ];
    final stop = nextHomeSwipeStop(
      mode: ref.read(swipeModeProvider),
      notes: notes,
      // Şeritle AYNI sıra: boş klasörler sonda (B3).
      folderIds: [
        for (final f in emptyFoldersLast(
          ref.read(visibleOrderedFoldersProvider),
          ref.read(folderSortProvider),
          ref.read(folderNoteCountsProvider),
        ))
          f.id,
      ],
      folderId: ref.read(selectedFolderProvider),
      filter: ref.read(noteFilterProvider),
      tag: ref.read(selectedTagProvider),
      direction: direction,
    );
    if (stop == null) return;
    // Geçiş animasyonunun yönünü çekiş yönüne göre ayarla (madde 2).
    _swipeForward = direction > 0;
    ref.read(selectedFolderProvider.notifier).set(stop.folderId);
    ref.read(noteFilterProvider.notifier).set(stop.filter);
    ref.read(selectedTagProvider.notifier).set(stop.tag);
    HapticFeedback.selectionClick();
  }

  /// Bir bölümde (sabitliler / diğerleri) notu basılı tutup sürükleyince
  /// (madde 1) çağrılır: [draggedId] notunu [toIndex] konumuna taşır ve yeni
  /// sırayı kalıcılaştırır. Elle sıra görünsün diye sıralama ölçütü manuel'e
  /// alınır.
  // ── SÜRÜKLEYEREK SIRALAMA: CANLI ÖNİZLEME ───────────────────────────────
  // KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "notları sıralada doğru
  // çalışmıyor, istediğim yere koyamıyorum; elimle gezdirirken notun nasıl
  // olacağı canlı olarak görülmeli"): sürükleme boyunca ızgara HİÇ
  // değişmiyordu — yalnız üzerine gelinen kartın kenarı vurgulanıyordu.
  // Masonry'de kartlar farklı boyda olduğu için o ince çerçeve "nereye
  // düşeceğini" anlatmıyor; kullanıcı bırakana kadar sonucu göremiyor,
  // yanlış yere düşünce de baştan deniyordu.
  //
  // Artık sürükleme başında bölümün sırası anlık görüntüye alınır, parmak
  // gezdikçe not o sıranın içinde YERİNİ DEĞİŞTİRİR ve ızgara gerçekten
  // yeniden dizilir; bırakınca görünen sıra olduğu gibi kaydedilir.

  /// Sürüklenen notun kimliği (null = sürükleme yok).
  String? _dragNoteId;

  /// O an ÖNİZLENEN bölüm sırası — ızgara bunu çizer.
  List<Note>? _dragOrder;

  void _startCardDrag(String id, List<Note> section) {
    setState(() {
      _dragNoteId = id;
      _dragOrder = List.of(section);
    });
  }

  /// Parmak [toIndex] hücresinin üzerinde: notu oraya taşıyıp yeniden çiz.
  void _previewCardDrop(int toIndex) {
    final order = _dragOrder;
    final id = _dragNoteId;
    if (order == null || id == null) return;
    final from = order.indexWhere((n) => n.id == id);
    if (from < 0 || from == toIndex) return;
    final next = List.of(order);
    final item = next.removeAt(from);
    next.insert(toIndex.clamp(0, next.length), item);
    setState(() => _dragOrder = next);
    HapticFeedback.selectionClick();
  }

  /// Parmak kalktı: GÖRÜNEN sıra kaydedilir. Bırakma bir kartın üstünde
  /// olmasa bile önizlenen sıra korunur — kullanıcı zaten onu görüyordu.
  void _endCardDrag() {
    final order = _dragOrder;
    final id = _dragNoteId;
    setState(() {
      _dragNoteId = null;
      _dragOrder = null;
    });
    if (order == null || id == null) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    if (ref.read(noteSortProvider) != NoteSort.manual) {
      ref.read(noteSortProvider.notifier).set(NoteSort.manual);
    }
    repo.reorderNotes(order);
    HapticFeedback.mediumImpact();
  }

  /// Yeni notu açar; DÖNÜŞTE o notu ana ekranda vurgular.
  ///
  /// Kullanıcı isteği: "kişi yeni bir not oluşturup dashboard'a döndüğünde o
  /// nota odak gitmeli ve notun çerçevesi hafif yanıp sönmeli" — uzun bir
  /// listede yeni notun nereye düştüğü görünmüyordu (asistanın oluşturduğu
  /// notlarda bu zaten vardı, aynı yol elle oluşturulanlara da açıldı).
  Future<void> _openNew(String id, {String query = '', NoteType? type}) async {
    if (!mounted) return;
    await context.pushNote(noteRoutePath(id, query: query));
    if (!mounted) return;
    ref.read(focusedNoteProvider.notifier).focus(id);
  }

  /// Ana ekranda (hızlı yakalama satırı ya da sesli yakalama) not oluşturuldu:
  /// kullanıcı GÖRSÜN.
  ///
  /// KÖK NEDEN (kullanıcı: "kaydet dememe rağmen not oluşturmuyor"): not
  /// gerçekte oluşuyordu ama ekranda HİÇBİR ŞEY değişmiyordu — yeni not
  /// sabitlenmiş notların altındaki bölüme, çoğu zaman görünür alanın dışına
  /// düşüyor, satır da sessizce temizleniyordu; kullanıcı kaydın kaybolduğunu
  /// sanıyordu. Artık kart vurgulanıp görünür alana kaydırılır ve tek dokunuşla
  /// açılabilen bir bildirim çıkar.
  /// İKİNCİ KÖK NEDEN (kullanıcı: "bazen oluşuyor bazen oluşmuyor"): açık bir
  /// SÜZGEÇ ya da arama, yeni notu listeden eliyordu. Yeni not sade bir metin
  /// notudur: "Yıldızlı" süzgeci, bir etiket seçimi ya da yazılı bir arama
  /// varken hiçbirine uymaz ve ekranda hiç belirmez — kullanıcı için bu,
  /// notun oluşmamasıyla aynı şey. Notu gizleyecek süzgeçler kaydın hemen
  /// ardından temizlenir (klasör süzgeci KALIR: not zaten o klasöre doğuyor).
  void _afterQuickCapture(String id) {
    if (!mounted) return;
    final l10n = context.l10n;
    if (ref.read(noteFilterProvider) != NoteFilter.all) {
      ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
    }
    if (ref.read(selectedTagProvider) != null) {
      ref.read(selectedTagProvider.notifier).set(null);
    }
    if (ref.read(searchQueryProvider).trim().isNotEmpty) {
      _searchController.clear();
      ref.read(searchQueryProvider.notifier).set('');
    }
    ref.read(focusedNoteProvider.notifier).focus(id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        // Geri sayımla kendiliğinden kapanır (bkz. timedSnackBar).
        timedSnackBar(
          content: Text(l10n.assistantNoteCreated),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: l10n.openNote,
            onPressed: () => _openNew(id),
          ),
        ),
      );
  }

  /// Sağ alttaki asistan düğmesi: ortak dinleme levhasını açar ve seçilen
  /// eyleme göre notu kurar.
  ///
  /// Levha, Ayarlar'daki "basılı tut / bas-başlat" tercihine kendi içinde
  /// uyar; bu yüzden düğme TEK DOKUNUŞLA açılıyor. Tasarım "basılı tutunca
  /// açılsın" diyordu ama o zaman bas-başlat'ı seçmiş kullanıcı ana ekranda
  /// yine basılı tutmak zorunda kalırdı — ayar anlamsızlaşırdı.
  Future<void> _captureVoiceNote() async {
    final l10n = context.l10n;
    final result = await showVoiceCaptureSheet(
      context,
      target: VoiceCaptureTarget.dashboard,
    );
    if (result == null || !mounted) return;
    if (result.action == VoiceCaptureAction.dictate) {
      await _dictateNote();
      return;
    }

    // "Asistan oluştursun": notu döküme bakarak asistan kurar — başlık,
    // maddeler ve HATIRLATICI çıkarır (bkz. voice_assistant.dart).
    // Ses eki yolunda (döküm yapılamadı) bu çip zaten gösterilmez; yine de
    // gelirse aşağıdaki düz akış çalışır — kayıt kaybolmasın.
    if (result.action == VoiceCaptureAction.compose &&
        result.audioPath == null) {
      await ref
          .read(voiceAssistantProvider.notifier)
          .composeFromTranscript(
            // Söylenen başlık asistana metnin başında verilir; notu o kurar.
            result.title == null
                ? result.text
                : '${l10n.noteTitleLabel}: ${result.title}\n${result.text}',
            nothingHeardText: l10n.voiceNothingHeard,
            savedText: l10n.voiceNoteSaved,
            noApiKeyText: l10n.aiNoApiKey,
            genericErrorText: l10n.assistantGenericError,
            historyLabel: l10n.aiHistoryVoiceNote,
          );
      return;
    }

    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;

    var text = result.text;
    final instruction = voiceCaptureInstruction(result.action);
    // Metin varsa ve bir dönüşüm istendiyse yapay zekâya gidilir. Metin BOŞSA
    // (yalnız ses kaydı elde) çağrı hiç yapılmaz: gönderilecek bir şey yok.
    if (instruction != null && text.trim().isNotEmpty) {
      try {
        final rewritten = await ref
            .read(geminiServiceProvider)
            .rewriteText(text, instruction);
        if (rewritten.trim().isNotEmpty) text = rewritten.trim();
      } catch (e) {
        // Metin KAYBOLMAZ: yapay zekâ dönüşümü başarısızsa not ham dökümle
        // kurulur, kullanıcı konuştuklarını yeniden söylemek zorunda kalmasın.
        // HER hata yakalanır (yalnız GeminiException değil): anahtar yokken
        // ağ/eklenti kaynaklı başka bir istisna da çıkabiliyor ve o zaman not
        // hiç oluşmuyordu. `mounted` kontrolü de yalnız BİLDİRİMİ atlar,
        // fonksiyondan çıkmaz — eskiden çıkıyordu ve not oluşmadan dönüyordu.
        if (mounted) {
          showQuickAddSnack(
            e is GeminiException
                ? (e.isAuthError ? l10n.aiNoApiKey : e.message)
                : l10n.assistantGenericError,
          );
        }
      }
    }

    // TEK yazımda kur: createNote + ayrı updateFields arasında doküman bir an
    // boş/süzgeçsiz kalıyor ve o anki akış görüntüsünde listeden düşebiliyordu
    // (hızlı yakalama satırında çözülen kök neden burada açık kalmıştı).
    final asList = result.action == VoiceCaptureAction.asList;
    final folderId = ref.read(selectedFolderProvider);
    final id = await repo.createNote(
      asList ? NoteType.checklist : NoteType.text,
      title: result.title ?? '',
      body: asList ? '' : (text.trim().isNotEmpty ? text : ''),
      folderId: folderId,
    );
    if (asList) {
      repo.updateFields(id, {
        'items': [
          for (final line in text.split('\n'))
            if (line.trim().isNotEmpty)
              // Şemanın anahtarı 'checked' ('done' yabancı alan olarak
              // kalıyordu; fromMap onu hiç okumuyor).
              {'id': const Uuid().v4(), 'text': line.trim(), 'checked': false},
        ],
      });
    }
    // Dökümü yapılamamış konuşma: kayıt nota SES EKİ olarak girer, böylece
    // yapay zekâ hiç çalışmasa da konuşma kaybolmaz.
    final audioPath = result.audioPath;
    if (audioPath != null) {
      await _attachVoiceAudio(id, audioPath, result.audioDuration);
    }
    if (!mounted) return;
    _afterQuickCapture(id);
  }

  /// Ana ekran mikrofonunun dokunuşu: doğrudan yazdır (boş not, söz nota).
  Future<void> _dictateNote() => createDictationNote();

  /// Sesli yakalamadan dönen ses kaydını yeni nota ek olarak bağlar.
  Future<void> _attachVoiceAudio(
    String noteId,
    String path,
    Duration duration,
  ) async {
    final attachments = ref.read(attachmentRepositoryProvider);
    final repo = ref.read(notesRepositoryProvider);
    if (attachments == null || repo == null) {
      File(path).delete().ignore();
      return;
    }
    try {
      final attachment = await attachments.prepareAudio(
        noteId: noteId,
        sourcePath: path,
        duration: duration,
      );
      repo.updateFields(noteId, {
        'attachments': [attachment.toMap()],
      });
    } catch (e) {
      File(path).delete().ignore();
      if (mounted) showQuickAddSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  /// Ana ekran zemini: **renk → desen → görsel** (üçü de isteğe bağlı, üst
  /// üste binebilirler — bkz. `dashboard_background_sheet.dart`).
  List<Widget> _dashboardBackground(WidgetRef ref) {
    final background = ref.watch(dashboardBackgroundProvider);
    final layers = <Widget>[];
    final color = background.color;
    if (color != null) {
      layers.add(Positioned.fill(child: ColoredBox(color: Color(color))));
    }
    if (background.pattern != DashboardPattern.none) {
      layers.add(
        Positioned.fill(
          child: DashboardPatternLayer(
            pattern: background.pattern,
            opacity: background.opacity,
          ),
        ),
      );
    }
    final path = background.path;
    // Önbellekli varlık denetimi: build her tuş vuruşunda çalışıyor, senkron
    // stat her seferinde ödenmesin. Çözünürlük ekran genişliğiyle sınırlı —
    // sınırsız decode tam boy bitmap'i bellekte tutuyordu.
    if (path != null && localFileExists(path)) {
      final targetWidth =
          (MediaQuery.sizeOf(context).width *
                  MediaQuery.devicePixelRatioOf(context))
              .round();
      layers.add(
        Positioned.fill(
          // PİL: `Opacity` widget'ı yerine görselin KENDİ opaklığı — ayrı bir
          // birleştirme katmanı (saveLayer) açmadan, çizimde alfa uygulanır.
          // Zemin ızgaranın arkasında ekran boyunda duruyor; ayrı katman her
          // kaydırma karesinde GPU'ya fazladan tam ekran bir geçiş demekti.
          child: RepaintBoundary(
            child: Image(
              image: ResizeImage(FileImage(File(path)), width: targetWidth),
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(
                background.opacity.clamp(0.05, 1).toDouble(),
              ),
            ),
          ),
        ),
      );
    }
    return layers;
  }

  @override
  Widget build(BuildContext context) {
    // Arka plan servisleri artık kökte (bkz. `AppServices`, F2.4).

    // Ana ekran mikrofon widget'ından (notlar://voice) gelen bas-başlat
    // isteği: uygulama zaten ana sayfadayken gelirse burada yakalanır.
    // (Uygulama başka ekrandayken/soğuk açılışta gelen istek initState'teki
    // kontrolle okunur; take() çift başlatmayı önler.)
    // Ctrl+K (bkz. AppShortcuts): arama kutusuna odaklan, yazılı sorguyu
    // seç ki doğrudan üstüne yazılabilsin.
    ref.listen(searchFocusRequestProvider, (_, _) {
      _searchFocus.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
    });
    ref.listen(voiceAutostartProvider, (previous, next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeAutostartVoice(),
        );
      }
    });

    final l10n = context.l10n;
    // Geciktirilmiş sorgu: anlamsal arama her tuş vuruşunda ayrı bir
    // embedding HTTP isteği atmasın (bkz. debouncedSearchQueryProvider).
    final query = ref.watch(debouncedSearchQueryProvider);
    final semanticActive =
        ref.watch(semanticSearchEnabledProvider) && query.trim().length > 2;
    // Anlamsal sonuçlara da uygulanmış süzgeçler (klasör/etiket/durum) uygulanır:
    // eskiden "İş" klasörü seçiliyken anlam modu TÜM klasörlerden not getiriyor,
    // üstteki çip ise hâlâ "İş" diyordu — metin/anlam modları sessizce farklı
    // davranıyordu.
    // Bu üçü YALNIZ anlam modu açıkken gerekli; koşulsuz izlenince anlam modu
    // kapalıyken bile üç sağlayıcıya abone olup ekranı yeniden kurduruyorlardı.
    final semanticFolder = semanticActive
        ? ref.watch(selectedFolderProvider)
        : null;
    final semanticTag = semanticActive ? ref.watch(selectedTagProvider) : null;
    final semanticFilter = semanticActive
        ? ref.watch(noteFilterProvider)
        : NoteFilter.all;
    final notesAsync = semanticActive
        ? ref
              .watch(semanticSearchProvider(query.trim()))
              .whenData(
                (list) => [
                  for (final n in list)
                    if ((semanticFolder == null ||
                            n.folderId == semanticFolder) &&
                        (semanticTag == null || n.tags.contains(semanticTag)) &&
                        noteMatchesFilter(n, semanticFilter))
                      n,
                ],
              )
        : ref.watch(filteredNotesProvider);
    // KÖK NEDEN (kasma): burası TÜM seçim kümesini izliyordu. Küme her
    // seçim değişiminde yeni bir `Set` olduğu için tek bir nota dokunmak
    // dashboard'ın tamamını (ve önbellek payındaki bütün kartları) yeniden
    // kuruyor, kartın kendi `select` optimizasyonunu boşa çıkarıyordu.
    // Ekranın bilmesi gereken tek şey seçim modunun AÇIK olup olmadığı;
    // kümenin kendisi yalnız toplu eylemlerde (ref.read ile) gerekiyor.
    final selectionActive = ref.watch(
      selectedNoteIdsProvider.select((s) => s.isNotEmpty),
    );
    // "Tümünü seç"in KAPSAMI: ekranda o an görünen (süzülmüş/aranmış)
    // notlar. Ekran dışındaki notları sessizce seçmek toplu silmeyi
    // tehlikeli yapardı. Seçim çubuğu yokken hesaplanmaz.
    final visibleIds = selectionActive
        ? [for (final n in notesAsync.value ?? const <Note>[]) n.id]
        : const <String>[];
    // Sıralama modu yalnız süzgeçsiz görünümde geçerlidir: kullanıcı mod
    // açıkken bir klasör/etiket çipine dokunursa mod kendiliğinden kapanır —
    // aksi hâlde şerit durur ama kartlar sürüklenmez, kullanıcı bozuk sanır.
    final searchActive = query.trim().isNotEmpty;
    final reorderActive =
        ref.watch(reorderModeProvider) &&
        !selectionActive &&
        !searchActive &&
        ref.watch(noteFilterProvider) == NoteFilter.all &&
        ref.watch(selectedFolderProvider) == null &&
        !ref.watch(showAllNotesProvider) &&
        ref.watch(selectedTagProvider) == null;
    // Dar ekranda arama odaklıyken sağdaki butonlar gizlenir; arama alanı
    // tüm genişliği kullanır. Klavye kapatılınca (sistem geri tuşu dahil)
    // odak sürse bile bar kendiliğinden daralır — viewInsets bunu izler.
    // Gizli klasör durumu ⋮ menüsünde kullanılır; sağlayıcılar BURADA (build
    // içinde) okunur — itemBuilder menü açılınca, yani build dışında çalışır.
    // Kümenin KENDİSİ değil yalnız "gizli klasör var mı" izlenir: klasör
    // akışının her yayınında yeni bir `Set` geliyor ve ekranın tamamı boşuna
    // yeniden kuruluyordu.
    final hasHiddenFolders = ref.watch(
      hiddenFolderIdsProvider.select((s) => s.isNotEmpty),
    );
    final hiddenRevealed = ref.watch(hiddenFoldersRevealedProvider);

    final page = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            createNote(NoteType.text),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          // **KASMA — ana ekran klavyeyle YENİDEN ÖLÇÜLMESİN** (kullanıcı
          // bulgusu 2026-08-18: "kasma devam ediyor klavye açılırken … arama /
          // levhalarda"). Aramaya dokunmak klavyeyi açıyor, Scaffold da
          // gövdeyi animasyonun her karesinde kısaltıyordu: ızgara geniş bir
          // önbellek payıyla kartların TAMAMINI ölçtüğü için (bkz.
          // [_kGridCacheExtent]) her kare yüzlerce kartın yeniden
          // yerleşimi demekti.
          //
          // Arama alanı ekranın TEPESİNDE olduğu için gövdenin kısalmasına
          // zaten gerek yok; klavye yalnız yüzen düğmelerin üstünü örter,
          // onlar da yazarken kullanılmıyor.
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Stack(
              children: [
                // Ana ekran ZEMİN görseli (Ayarlar → Görünüm). Kart
                // ızgarasının arkasında durur; görünürlük ayarı okunurluğu
                // korumak için varsayılan olarak düşüktür.
                ..._dashboardBackground(ref),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Sütun sayısı: kullanıcı iki parmakla zoom yaptıysa onun
                    // seçimi (1–4), yoksa ekran genişliğinden otomatik.
                    final manualColumns = ref.watch(gridColumnsProvider);
                    final columns = manualColumns > 0
                        ? manualColumns
                        : (constraints.maxWidth / 220).floor().clamp(2, 6);
                    // Masonry hücre genişliği: sürükle-sırala sırasında taşınan
                    // notun "hayalet" kopyası (feedback) bu genişlikte çizilir.
                    // gridPadding yatayda 12+12, crossAxisSpacing 8.
                    final cellWidth =
                        (constraints.maxWidth - 24 - 8 * (columns - 1)) /
                        columns;
                    // Aktif segment (filtre|klasör|etiket) anahtarı: değişince
                    // AnimatedSwitcher yeni görünümü kaydırarak getirir (madde 2).
                    // Arama sorgusu anahtara DAHİL DEĞİL — her tuşta yeniden
                    // animasyon tetiklenmez.
                    final segmentKey =
                        '${ref.watch(noteFilterProvider)}'
                        '|${ref.watch(selectedFolderProvider) ?? ''}'
                        '|${ref.watch(selectedTagProvider) ?? ''}';
                    // Başlık (arama/seçim barı + filtre çipleri) kaydırma
                    // görünümünün DIŞINDA sabit durur: liste kayarken çipler
                    // yerinde kalır; filtre değişim animasyonu yalnız not
                    // listesine uygulanır (arama barı artık birlikte kaymaz).
                    return Column(
                      children: [
                        // Sıralama modu: kartlar sürüklenebilir. Moddan
                        // çıkmadan başka iş yapılamayacağı için üstte kalıcı
                        // ve tek düğmeli bir bar durur.
                        if (reorderActive)
                          AppBar(
                            leading: IconButton(
                              tooltip: l10n.reorderDone,
                              icon: const Icon(Icons.close),
                              onPressed: () => ref
                                  .read(reorderModeProvider.notifier)
                                  .set(false),
                            ),
                            title: Text(l10n.reorderModeActive),
                            actions: [
                              TextButton(
                                onPressed: () => ref
                                    .read(reorderModeProvider.notifier)
                                    .set(false),
                                child: Text(l10n.reorderDone),
                              ),
                              const SizedBox(width: 4),
                            ],
                            // Modun ne beklediği yazılı: kartın kendisi
                            // dokununca AÇILMIYOR, uzun basış gerekiyor —
                            // yazmadan bunu ancak deneyerek anlamak gerekiyordu.
                            bottom: PreferredSize(
                              preferredSize: const Size.fromHeight(22),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  l10n.reorderHint,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                          )
                        else if (selectionActive)
                          // Seçim kümesinin KENDİSİ yalnız burada gerekiyor;
                          // abonelik bu çubuğa hapsedilir (bkz. yukarıdaki
                          // `selectionActive` kök nedeni).
                          Consumer(
                            builder: (context, ref, _) {
                              final selectedIds = ref.watch(
                                selectedNoteIdsProvider,
                              );
                              return AppBar(
                                leading: IconButton(
                                  tooltip: l10n.cancel,
                                  icon: const Icon(Icons.close),
                                  onPressed: () => ref
                                      .read(selectedNoteIdsProvider.notifier)
                                      .clear(),
                                ),
                                title: Text(
                                  l10n.selectedCount(selectedIds.length),
                                ),
                                // Kopyala/arşivle/sil ve diğer tüm not işlemleri
                                // seçim yapılınca BURADA toplanır (madde 3): sık
                                // kullanılanlar simge, gerisi taşma menüsünde.
                                actions: [
                                  // **TÜMÜNÜ SEÇ** — "hepsini arşivle" gibi
                                  // en olağan toplu iş için notları tek tek
                                  // işaretlemek gerekiyordu. Kapsam ekranda
                                  // GÖRÜNEN notlarla sınırlı: süzgeç/arama
                                  // açıkken ekran dışındakiler seçilmez.
                                  IconButton(
                                    tooltip:
                                        selectedIds.length == visibleIds.length
                                        ? l10n.selectNone
                                        : l10n.selectAll,
                                    icon: Icon(
                                      selectedIds.length == visibleIds.length
                                          ? Icons.deselect
                                          : Icons.select_all,
                                    ),
                                    onPressed: () => ref
                                        .read(selectedNoteIdsProvider.notifier)
                                        .selectAll(visibleIds),
                                  ),
                                  IconButton(
                                    tooltip: l10n.archive,
                                    icon: const Icon(Icons.archive_outlined),
                                    onPressed: () =>
                                        _archiveSelected(selectedIds),
                                  ),
                                  IconButton(
                                    tooltip: l10n.copy,
                                    icon: const Icon(Icons.copy_outlined),
                                    onPressed: () => _copySelected(selectedIds),
                                  ),
                                  IconButton(
                                    tooltip: l10n.deleteSelected,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _deleteSelected(selectedIds),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: l10n.noteMetaMenu,
                                    onSelected: (action) {
                                      switch (action) {
                                        case 'pin':
                                          _setPinnedSelected(selectedIds, true);
                                        case 'unpin':
                                          _setPinnedSelected(
                                            selectedIds,
                                            false,
                                          );
                                        case 'star':
                                          _setStarredSelected(
                                            selectedIds,
                                            true,
                                          );
                                        case 'unstar':
                                          _setStarredSelected(
                                            selectedIds,
                                            false,
                                          );
                                        case 'share':
                                          _shareSelected(selectedIds);
                                        case 'folder':
                                          _moveSelectedToFolder(selectedIds);
                                        case 'duplicate':
                                          _duplicateSelected(selectedIds);
                                        case 'color':
                                          _colorSelected(
                                            selectedIds,
                                            frame: false,
                                          );
                                        case 'frame':
                                          _colorSelected(
                                            selectedIds,
                                            frame: true,
                                          );
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      _menuItem(
                                        'pin',
                                        Icons.push_pin_outlined,
                                        l10n.pin,
                                      ),
                                      _menuItem(
                                        'unpin',
                                        Icons.push_pin,
                                        l10n.unpin,
                                      ),
                                      _menuItem(
                                        'star',
                                        Icons.star_outline,
                                        l10n.star,
                                      ),
                                      _menuItem(
                                        'unstar',
                                        Icons.star,
                                        l10n.unstar,
                                      ),
                                      const PopupMenuDivider(),
                                      _menuItem(
                                        'folder',
                                        Icons.folder_outlined,
                                        l10n.moveToFolder,
                                      ),
                                      _menuItem(
                                        'duplicate',
                                        Icons.content_copy_outlined,
                                        l10n.duplicateNote,
                                      ),
                                      _menuItem(
                                        'color',
                                        Icons.palette_outlined,
                                        l10n.backgroundColor,
                                      ),
                                      _menuItem(
                                        'frame',
                                        Icons.border_color_outlined,
                                        l10n.frameColor,
                                      ),
                                      _menuItem(
                                        'share',
                                        Icons.share_outlined,
                                        l10n.share,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              );
                            },
                          )
                        else
                          // KÖK NEDEN (kasma): `keyboardOpen`/`searchExpanded`
                          // ekranın ANA build'inde okunuyordu. `viewInsets`
                          // klavye animasyonunun HER KARESİNDE değişiyor, yani
                          // arama kutusuna dokunmak 250 ms boyunca ızgaranın
                          // tamamını 15–30 kez yeniden kurduruyordu. Okuma
                          // artık yalnız bu çubuğu kapsıyor.
                          ListenableBuilder(
                            listenable: _searchFocus,
                            builder: (context, _) {
                              final searchExpanded =
                                  _searchFocus.hasFocus &&
                                  MediaQuery.viewInsetsOf(context).bottom > 0 &&
                                  MediaQuery.sizeOf(context).width < 600;
                              return AppBar(
                                titleSpacing: searchExpanded ? 0 : 12,
                                // Genişkenken geri oku: odağı bırakır, bar daralır.
                                leading: searchExpanded
                                    ? IconButton(
                                        tooltip: l10n.close,
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed: _searchFocus.unfocus,
                                      )
                                    : null,
                                automaticallyImplyLeading: false,
                                title: _SearchField(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                ),
                                actions: searchExpanded
                                    ? const [SizedBox(width: 4)]
                                    : [
                                        // **HESAP SİMGESİ** (kullanıcı isteği
                                        // 2026-08-18: "giriş yapıldıysa üst
                                        // alanda profil simgesi görülsün,
                                        // yapılmadıysa yerel hesap simgesi
                                        // olsun"). Hangi hesapla çalışıldığı
                                        // ayarlara girmeden görünsün.
                                        // ANA EKRAN KİŞİSELLEŞTİRİLİR
                                        // (kullanıcı bulgusu 2026-10-16:
                                        // "ana ekran kişiselleştirilemiyor"):
                                        // hesap, Yapay zekâ, Süz, görünüm ve
                                        // iki mikrofon gizlenebilir; düzenleme
                                        // modunda dokunarak (bkz.
                                        // Customizable).
                                        const Customizable(
                                          id: UiItem.homeAccount,
                                          child: AccountAvatarButton(),
                                        ),
                                        const SizedBox(width: 6),
                                        // GELEN VE PAYLAŞILANLAR (kullanıcı
                                        // isteği 2026-10-17): Yapay zekâ
                                        // düğmesinin yeri; o alttaki "+"nın
                                        // SOLUNA indi. Gelen not ya da yeni
                                        // ortak not varsa köşede sayı rozeti.
                                        const SharedHubButton(),
                                        const SizedBox(width: 6),
                                        // ⋮ ARTIK ALT LEVHA (kullanıcı isteği
                                        // 2026-10-11: "menüler yeniden dizayn
                                        // edilmeli"). On bir maddelik açılır
                                        // menü ekranın %55'inde kesiliyor,
                                        // "Kullanım kılavuzu" kaydırmadan
                                        // görünmüyordu. Levha not menüleriyle
                                        // aynı dili konuşur (bkz. [ActionMenu]).
                                        IconButton(
                                          tooltip: l10n.more,
                                          icon: const Icon(Icons.more_vert),
                                          onPressed: () => unawaited(
                                            _openHomeMenu(
                                              hasHiddenFolders:
                                                  hasHiddenFolders,
                                              hiddenRevealed: hiddenRevealed,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                              );
                            },
                          ),
                        // "Süz" düğmesi + yalnız UYGULANMIŞ süzgeçler. Eski
                        // dokuz artı çipli bar (dashboard_chips.dart) ve ona
                        // bağlı "hangi çip görünsün" ayarları kaldırıldı;
                        // süzme tek yoldan, Süz levhasından yapılıyor.
                        // **BEKLEYEN DAVETLER** (kullanıcı isteği 2026-08-18:
                        // "arkadaşlık isteği geldiğinde ana sayfada görülsün",
                        // "klasör paylaşıldığında kabul et veya reddet
                        // seçeneği olsun"). Bir şey beklemiyorsa hiç
                        // çizilmez — boşken sıfır yer kaplar.
                        const HomeInvites(),
                        const DashboardFilterRow(),
                        // Buluta yüklenmeyi bekleyen ekler — yoksa sıfır yer.
                        const _PendingUploadsBar(),
                        // **SON ARAMALAR** — yalnız arama kutusu odaklıyken
                        // ve kutu BOŞKEN. Yazmaya başlayınca kaybolur:
                        // sonuçların üstünde bir çip şeridi durmasın.
                        ListenableBuilder(
                          listenable: _searchFocus,
                          builder: (context, _) => _RecentSearches(
                            visible: _searchFocus.hasFocus,
                            onPick: (q) {
                              _searchController.text = q;
                              _searchController.selection =
                                  TextSelection.collapsed(offset: q.length);
                              ref.read(searchQueryProvider.notifier).set(q);
                            },
                          ),
                        ),
                        // Hızlı yakala: "+" → editör → yaz → geri yolunu tek
                        // satıra indirir. Tasarım bunu kaydırma akışının
                        // içine koyuyordu; sabit satırda tutuyorum ki liste
                        // aşağıdayken yukarı kaydırmadan da yazılabilsin.
                        // Varsayılan GİZLİ (Ayarlar > "Hızlı not satırı"):
                        // satır yer kaplıyordu, aynı iş "+" menüsünde de var.
                        if (ref.watch(quickCaptureRowProvider))
                          _QuickCaptureRow(
                            onCreateChecklist: () =>
                                createNote(NoteType.checklist),
                            onSaved: _afterQuickCapture,
                          ),
                        // Sabit başlık ile kayan ızgara arasındaki SINIR
                        // (bkz. [_gridScrolled]).
                        _HeaderSeparator(scrolled: _gridScrolled),
                        Expanded(
                          // İki parmakla zoom: 1 → 2 → 3 → 4 sütun arasında
                          // geçiş. Ölçek jesti tek parmakta hiç tepki vermez
                          // (pointerCount kontrolü), böylece içteki yatay
                          // çekiş ve dikey kaydırma olduğu gibi çalışır.
                          child: _PinchColumns(
                            onStart: () => _zoomBaseColumns = columns,
                            onScale: (scale) => _applyZoom(scale, columns),
                            child: NotificationListener<ScrollNotification>(
                              onNotification: _onGridScroll,
                              child: GestureDetector(
                                // Yatay çekişle filtreler/klasörler arasında
                                // gezin. Dikey kaydırma CustomScrollView'de
                                // kalır; eksenler farklı olduğundan çakışmaz.
                                //
                                // Çekiş YOK SAYILIR: seçim modunda (görünüm
                                // değişince seçili notlar ekrandan kaybolur
                                // ama seçili kalır — "Sil" görünmeyen notları
                                // da silerdi), sıralama modunda ve bir kart
                                // sürüklenirken (sıralama yalnız süzgeçsiz
                                // görünümde geçerli; çekiş modu sessizce
                                // kapatıyordu).
                                onHorizontalDragEnd:
                                    selectionActive ||
                                        reorderActive ||
                                        _dragNoteId != null ||
                                        ref.watch(swipeModeProvider) ==
                                            SwipeMode.off
                                    ? null
                                    : (details) {
                                        final velocity =
                                            details.primaryVelocity ?? 0;
                                        if (velocity.abs() < 300) return;
                                        // Sağdan sola yazılan dillerde "sonraki"
                                        // sağa çekiştir (sayfa yönü ters).
                                        final rtl =
                                            Directionality.of(context) ==
                                            TextDirection.rtl;
                                        final forward = rtl
                                            ? velocity > 0
                                            : velocity < 0;
                                        _cycleFilterFolder(forward ? 1 : -1);
                                      },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    // Çekiş yönüne göre yumuşak kaydır + soldur.
                                    //
                                    // KÖK NEDEN ("kaydırınca liste ters
                                    // yöne gidiyor"): aynı geçiş ÇIKAN görünüme
                                    // de uygulanıyor (animasyonu tersten
                                    // oynayarak). Tek bir `begin` ile giden
                                    // liste, gelenin GELDİĞİ yöne kayıyordu —
                                    // sola çekince eski notlar parmağın tersine,
                                    // sağa gidiyordu. Çıkan görünüm artık öbür
                                    // yana çıkar.
                                    final incoming =
                                        child.key == ValueKey(segmentKey);
                                    final dir = _swipeForward ? 1.0 : -1.0;
                                    final rtl =
                                        Directionality.of(context) ==
                                        TextDirection.rtl;
                                    final begin = Offset(
                                      (incoming ? 0.12 : -0.12) *
                                          dir *
                                          (rtl ? -1 : 1),
                                      0,
                                    );
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween(
                                          begin: begin,
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  layoutBuilder:
                                      (currentChild, previousChildren) => Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          ...previousChildren,
                                          ?currentChild,
                                        ],
                                      ),
                                  child: CustomScrollView(
                                    key: ValueKey(segmentKey),
                                    // "Başa dön" düğmesi buradan tepeye döner.
                                    controller: _gridScroll,
                                    // KÖK NEDEN (aşağı kaydırırken liste yukarı
                                    // sıçraması): SliverMasonryGrid tembeldir ve
                                    // toplam kaydırma uzunluğunu yalnızca O AN
                                    // yerleşmiş kartların ORTALAMA yüksekliğinden
                                    // TAHMİN eder. Masonry'de kart boyları çok
                                    // farklı olduğundan tahmin her karede oynuyor;
                                    // tahmin o anki konumun altına düştüğü an
                                    // ScrollPosition kendini düzeltip listeyi
                                    // yukarı çekiyordu (sona yaklaşıldıkça sık).
                                    // 2026-10-16: masonry kalktı (tembel
                                    // deterministik sütunlar) — pay artık
                                    // yalnız hızlı kaydırma için (bkz.
                                    // [_kGridCacheExtent]).
                                    scrollCacheExtent:
                                        const ScrollCacheExtent.pixels(
                                          _kGridCacheExtent,
                                        ),
                                    slivers: [
                                      // Misafir hesap hatırlatması (F4.3).
                                      if (!searchActive && !reorderActive)
                                        const SliverToBoxAdapter(
                                          child: GuestBackupCard(),
                                        ),
                                      // **KLASÖR RAFI**: ana ekranın tepesinde,
                                      // notlarla aynı ızgarada. Yalnız kök
                                      // görünümde çizilir — arama/süzgeç/etiket
                                      // sonuçlarının arasında klasör karosu
                                      // görmek kafa karıştırırdı.
                                      //
                                      // Yana çekişle bir KLASÖRE gelinince
                                      // şerit (karo değil) yine çizilir ve
                                      // o klasörün çipi vurgulanır: kullanıcı
                                      // klasörler arasında nerede olduğunu
                                      // görsün (2026-09-26).
                                      if (!searchActive &&
                                          !reorderActive &&
                                          ref.watch(noteFilterProvider) ==
                                              NoteFilter.all &&
                                          ref.watch(selectedTagProvider) ==
                                              null)
                                        _folderShelf(
                                          columns,
                                          selectedFolderId: ref.watch(
                                            selectedFolderProvider,
                                          ),
                                        ),
                                      ...notesAsync.when(
                                        data: (notes) => _buildNoteSlivers(
                                          context,
                                          notes,
                                          columns,
                                          cellWidth: cellWidth,
                                          selectionActive: selectionActive,
                                          searchActive: searchActive,
                                          reorderEnabled: reorderActive,
                                        ),
                                        // Yüklenirken kart İSKELETİ (tek
                                        // çark yerine — bkz. skeleton.dart).
                                        loading: () => [
                                          SliverToBoxAdapter(
                                            child: NoteGridSkeleton(
                                              columns: columns,
                                            ),
                                          ),
                                        ],
                                        error: (e, _) => [
                                          SliverFillRemaining(
                                            hasScrollBody: false,
                                            child: EmptyState(
                                              icon: Icons.error_outline,
                                              title: l10n.genericError(
                                                e.toString(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Listenin sonu düğme sütununun
                                      // ÜSTÜNE çıkabilsin (bkz.
                                      // [_kFabClearance]).
                                      const SliverToBoxAdapter(
                                        child: SizedBox(
                                          height: _kFabClearance,
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
                  },
                ),
                // Sesli asistan paneli düğmelerin ÜSTÜnde sabit konumda yüzer.
                // Düğmeler floatingActionButton'da kaldığından panel açılıp
                // kapanırken yerinden oynamaz (stabil); yalnız kayıt/işleme/
                // sonuç sırasında görünür, ana sayfanın ortasına yakın.
                // Asistan paneli, "not silindi" bildirimiyle aynı yerleşimi
                // kullanır: düğmelerin ÜSTÜnde değil SOLUNDA, ekranın dibinde.
                // Sağda düğme sütunu kadar boşluk bırakılır.
                const PositionedDirectional(
                  start: 8,
                  end: 144,
                  bottom: 16,
                  child: VoiceAssistantPanel(),
                ),
                // ✨ YAPAY ZEKÂ DÜĞMESİ KALKTI (geliştirme raporu B2,
                // 2026-10-20): mikrofon + ✨ + "+" üç ayrı yüzen düğme sağ
                // alttaki kartın yarısını örtüyordu. Yapay Zekâ ⋮ menüsünün
                // hızlı satırında ilk sırada; AI ile sesli not mikrofona basılı
                // tutunca açılır (değişmedi).
                // Düğmeler Scaffold.floatingActionButton yerine BURADA durur:
                // Scaffold bir FAB tanıdığında yüzen bildirimleri ("not
                // silindi") onun ÜSTÜne iter. Düğmeler Stack'te olunca
                // bildirim ekranın dibinde, düğmelerin solunda kalır.
                // YÖNE BAĞLI: sabit `right` sağdan sola dillerde düğmeleri
                // sağda bırakıyor, asistan paneli ise (end: 88) SOLDA yer
                // ayırıyordu — panel düğmelerin üstüne biniyordu.
                PositionedDirectional(
                  end: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // "Başa dön" "+"nın tam üstünde: sağa dayalı, küçük
                    // düğme (40) "+"nın (56) ortasına 8 dp payla oturur.
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // **BAŞA DÖN** — yüz notluk bir kitaplıkta en alta
                      // inen kullanıcının tepeye (ve arama kutusuna)
                      // dönmesinin tek yolu aynı yolu geri kaydırmaktı.
                      // Yalnız gerçekten aşağıdayken çıkar; seçim/sıralama
                      // kipinde çıkmaz (o çubuklar zaten sayfayı yönetir).
                      AnimatedSlide(
                        offset: _showBackToTop && !selectionActive
                            ? Offset.zero
                            : const Offset(0, 0.6),
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedOpacity(
                          opacity: _showBackToTop && !selectionActive ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: IgnorePointer(
                            ignoring: !_showBackToTop || selectionActive,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                bottom: 10,
                                end: 8,
                              ),
                              child: FloatingActionButton.small(
                                heroTag: 'backToTop',
                                tooltip: l10n.scrollToTop,
                                onPressed: _backToTop,
                                child: const Icon(Icons.arrow_upward),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // MİKROFON "+"nın SOLUNDA, aynı satırda (B2): sütun
                      // eskiden iki düğme boyu yükseliyor ve sağ sütunun
                      // son kartını örtüyordu; tek satır 56 dp.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TEK MİKROFON (F3.1) = DOĞRUDAN YAZDIR (kullanıcı
                          // isteği 2026-10-20: "AI sesli notu AI menüsüne
                          // alalım, ana ekrandaki doğrudan yazma olsun").
                          // Eskiden dokunuş SON kullanılan kipi açıyordu; aynı
                          // düğmenin bir gün AI levhası, bir gün dikte açması
                          // tahmin edilemezdi. AI ile sesli not Yapay Zekâ
                          // ekranının en üstünde; basılı tutmak kısayol olarak
                          // onu açar.
                          Customizable(
                            id: UiItem.homeMic,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(end: 12),
                              child: _DashVoiceButton(
                                key: const ValueKey('home-mic'),
                                tooltip: l10n.voiceMicTooltipDictate,
                                icon: Icons.mic,
                                onTap: _dictateNote,
                                onLongPress: _captureVoiceNote,
                              ),
                            ),
                          ),
                          // Keep tarzı açılan "+": metin/madde/sıralı/el yazısı.
                          // Dört kapılı "+" (F3.2). Sesli not menüde YOK:
                          // ana ekranın kendi tek mikrofonu var (F3.1).
                          // "+" menüsü YALNIZ "+"ya demirlenir: mikrofon
                          // yanında, menü onun üstüne inmez.
                          CompositedTransformTarget(
                            link: _fabColumnLink,
                            child: QuickAddFab(
                              anchor: _fabColumnLink,
                              actions: this,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Geri tuşu: seçim ya da sıralama modu açıkken uygulamadan ÇIKMAZ, önce
    // modu kapatır. Ana ekran yığının kökü olduğu için sistem geri tuşu
    // doğrudan uygulamayı kapatıyordu; kullanıcı yanlışlıkla bir notu seçince
    // (uzun basış) seçimi kapatmanın tek yolu ekrandaki "×" idi.
    return PopScope(
      canPop: !selectionActive && !reorderActive,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // "+" paneli açıksa geri tuşu ONUN: Flutter aynı rotadaki tüm
        // PopScope geri çağrılarını çalıştırıyor, yoksa tek geri hem paneli
        // hem seçim modunu birden kapatırdı.
        if (quickAddPanelOpen.value) return;
        if (selectionActive) {
          ref.read(selectedNoteIdsProvider.notifier).clear();
        } else if (reorderActive) {
          ref.read(reorderModeProvider.notifier).set(false);
        }
      },
      // Editör (ya da bir bölüm) ana ekranı TAMAMEN örtünce ızgara yeniden
      // kurulmaz; görünür olunca bir kez güncellenir (bkz. FreezeWhenHidden).
      child: FreezeWhenHidden(child: page),
    );
  }

  /// Gelecekteki hatırlatıcı sayısı (⋮ menüsündeki rozet).
  int _upcomingReminderCount() {
    final now = DateTime.now();
    return [
      for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
        if (n.reminderAt != null &&
            n.reminderAt!.isAfter(now) &&
            n.archivedAt == null)
          n,
    ].length;
  }

  /// ⋮ menüsünün satırı. [count] > 0 ise sağda küçük sayı rozeti
  /// (kullanıcı isteği 2026-09-26: menü "görsel ve işlevsel olarak
  /// geliştirilsin" — Gelen notlar/Hatırlatıcılar/Arşiv'de ne beklediği
  /// açmadan görünsün). [highlight]: bekleyen iş (gelen not) vurgulu rozet.
  /// Ana ekranın ⋮ levhası: hızlı satırda en sık gidilen dört yer (sayılı),
  /// altında kişiler, ana ekran ve uygulama grupları. Sayılar levha
  /// AÇILIRKEN okunur (ref.read) — ekran bu sayılar için yeniden kurulmaz.
  Future<void> _openHomeMenu({
    required bool hasHiddenFolders,
    required bool hiddenRevealed,
  }) async {
    final l10n = context.l10n;
    final action = await showActionMenuSheet(
      context,
      ActionMenu(
        quick: [
          // YAPAY ZEKÂ ilk sırada (B2): ana ekrandaki ✨ yüzen düğmesi kalktı.
          if (Personalize.current.shows(UiItem.homeAi))
            MenuAction('ai', l10n.aiHubTitle, Icons.auto_awesome),
          MenuAction(
            'reminders',
            l10n.remindersTitle,
            Icons.alarm_outlined,
            count: _upcomingReminderCount(),
          ),
          MenuAction(
            'archive',
            l10n.archiveTitle,
            Icons.archive_outlined,
            count: ref.read(archivedNotesProvider).value?.length ?? 0,
          ),
          MenuAction('trash', l10n.trashTitle, Icons.delete_outline),
          // AYARLAR hızlı satırda, GRİ (kullanıcı isteği 2026-10-17:
          // "ayarlar butonunu üstteki 3'lü buton gibi yap ve oraya al,
          // rengini de ayrıştır gri olsun").
          MenuAction(
            'settings',
            l10n.settings,
            Icons.settings_outlined,
            neutral: true,
          ),
          // Şablondan not "+" menüsünde de var; burada YALNIZ orada
          // gizlenmişse çıkar (toparlama 2026-10-17: aynı işin iki kapısı).
          if (!Personalize.current.shows(UiItem.quickAdd('template')))
            MenuAction(
              'template',
              l10n.fromTemplate,
              Icons.dashboard_customize_outlined,
            ),
        ],
        sections: [
          // **HESAP** (kullanıcı isteği 2026-08-18: "hesap seçeneklerini
          // ana sayfadaki sağ üstteki 3 noktaya da koy").
          MenuSection(l10n.menuSectionPeople, [
            MenuAction(
              'account',
              l10n.account,
              Icons.account_circle_outlined,
            ),
            MenuAction('friends', l10n.friendsTitle, Icons.people_outline),
            // GELEN NOTLAR menüden kalktı: üst çubuktaki "Gelen ve
            // paylaşılanlar" düğmesinde (bkz. SharedHubButton).
          ]),
          MenuSection(l10n.menuSectionHome, [
            MenuAction('folderOrder', l10n.folderOrderTitle, Icons.swap_vert),
            // Zemin görseli AYARLARDAN BURAYA taşındı (2026-08-16).
            MenuAction(
              'background',
              l10n.dashboardBackground,
              Icons.wallpaper,
            ),
            // Gizli klasörler yalnız gizli klasörü OLAN kullanıcıda.
            if (hasHiddenFolders)
              MenuAction(
                'hidden',
                l10n.hiddenFoldersMenu,
                hiddenRevealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
          ]),
          MenuSection(l10n.menuSectionApp, [
            // KİŞİSELLEŞTİR (kullanıcı isteği 2026-10-16): hangi alan ve
            // düğme görünsün — menüden; ekranda kalıcı ayar düğmesi yok.
            MenuAction(
              'personalize',
              l10n.personalizeTitle,
              Icons.tune_rounded,
            ),
            MenuAction('guide', l10n.guideTitle, Icons.menu_book_outlined),
          ]),
        ],
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'ai':
        unawaited(context.push('/ai'));
      case 'account':
        unawaited(showAccountSheet(context));
      case 'inbox':
        unawaited(InboxScreen.open(context));
      case 'friends':
        openFriendsScreenOrExplain(context, ref);
      case 'hidden':
        unawaited(_toggleHiddenFolders());
      case 'reminders':
        unawaited(context.push('/reminders'));
      case 'archive':
        unawaited(context.push('/archive'));
      case 'background':
        unawaited(showDashboardBackgroundSheet(context));
      case 'trash':
        unawaited(context.push('/trash'));
      case 'template':
        unawaited(createFromTemplate());
      case 'folderOrder':
        unawaited(showFolderOrderSheet(context));
      case 'settings':
        unawaited(context.push('/settings'));
      case 'personalize':
        unawaited(context.push('/personalize'));
      case 'guide':
        unawaited(context.push('/guide'));
    }
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    int count = 0,
    bool highlight = false,
  }) => PopupMenuItem<String>(
    value: value,
    height: 42,
    // ListTile satırı daima erişilebilir tüm genişliği kaplıyordu; menü de
    // bu yüzden sağ-sol ekseninde gereksiz genişliyordu (madde 5). İçeriğe
    // göre daralan Row ile menü yalnız ikon + etiket kadar yer kaplar.
    child: Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: highlight
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: highlight
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );

  /// Ana ekranın tepesindeki **klasör rafı**: her klasör bir karo, sonda
  /// "Yeni klasör". Karolar not kartlarıyla AYNI sütun düzenini kullanır ki
  /// raf ızgaranın devamı gibi dursun, ayrı bir bölüm gibi değil.
  ///
  /// Gizli klasörler yalnız o oturumda açığa çıkarıldıysa çizilir — karonun
  /// adı bile gizli notların varlığını ele verirdi.
  Widget _folderShelf(int columns, {String? selectedFolderId}) {
    // Kullanıcının KLASÖR SIRASI (Ayarlar → Notlar → Klasör sırası; bkz.
    // FolderSort). Gizli klasörler yalnız açığa çıkarıldıysa.
    final folders = ref.watch(visibleOrderedFoldersProvider);
    if (selectedFolderId != null) {
      return _folderStrip(folders, selectedFolderId: selectedFolderId);
    }
    // **YER SORUNU** (kullanıcı isteği 2026-08-18: "klasörler ana ekranda çok
    // fazla yer kaplıyor, farklı bir çözüm bulalım"): karo rafı üç klasörde
    // bir 92 px'lik satır açıyor ve notlar ekranın altına iniyordu. Varsayılan
    // artık TEK SATIRLIK yatay çip şeridi (~40 px, kaç klasör olursa olsun);
    // karo görünümü tek dokunuşla geri gelir ve tercih hatırlanır (bkz.
    // [folderShelfExpandedProvider]).
    if (!ref.watch(folderShelfExpandedProvider)) {
      return _folderStrip(folders);
    }
    // **PAYLAŞILAN klasörler AYNI RAFTA** (kullanıcı isteği 2026-08-18:
    // "ortak notlar klasörü kişiler bağlanır notları ortak görür"). Kendi
    // klasörlerimden SONRA gelirler — kendi düzenim önce, arkadaşlarımınki
    // sonra; iki liste ayrı kaynaktan geldiği için gizli klasör süzgeci
    // burada geçerli değil (paylaşılan bir klasör asla "benim gizli
    // klasörüm" olamaz).
    final shared = ref.watch(sharedFolderRefsProvider).value ?? const [];
    final total = folders.length + shared.length;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Row(
            children: [
              // Ortak notlar artık üst çubuktaki "Gelen ve paylaşılanlar"
              // düğmesinde (bkz. SharedHubButton).
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 12),
                child: AllNotesChip(),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    ref.read(folderShelfExpandedProvider.notifier).toggle(),
                icon: const Icon(Icons.unfold_less, size: 18),
                label: Text(context.l10n.folderShelfCollapse),
              ),
            ],
          ),
        ),
        _folderGrid(columns, folders, shared, total),
      ],
    );
  }

  /// Klasör rafının KARO (açık) hâli — bkz. [_folderShelf].
  Widget _folderGrid(
    int columns,
    List<NoteFolder> folders,
    List<SharedFolderRef> shared,
    int total,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: FolderTile.height,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == total) return const NewFolderTile();
          if (index < folders.length) {
            final folder = folders[index];
            return FolderTile(
              key: ValueKey('folder-${folder.id}'),
              folder: folder,
            );
          }
          final share = shared[index - folders.length];
          return SharedFolderTile(
            key: ValueKey('shared-folder-${share.folderId}'),
            share: share,
          );
        }, childCount: total + 1),
      ),
    );
  }

  /// Klasör rafının KOMPAKT (varsayılan) hâli: tek satır, yatay kaydırılan
  /// çipler. Yükseklik klasör sayısından BAĞIMSIZ — asıl kazanç bu.
  Widget _folderStrip(List<NoteFolder> folders, {String? selectedFolderId}) {
    final shared = ref.watch(sharedFolderRefsProvider).value ?? const [];
    // YENİ HAREKET ÖNE (kullanıcı bulgusu 2026-10-17: "paylaşılanlarda yeni
    // bir şey geldiğinde anlaşılmıyor"): okunmamışı olan paylaşılan
    // klasörler şeridin SONUNDAydı — birkaç klasörden sonra ekran dışında
    // kalıyor, rozet görünmüyordu. Okunmamış varsa en başa geçerler.
    // ORTAK NOTLAR çipi şeritten kalktı (2026-10-17: "gelen ve paylaşılan
    // notları birleştir, tek alandan yönetilsin") — üst çubuktaki rozetli
    // "Gelen ve paylaşılanlar" düğmesinde (bkz. SharedHubButton).
    final hotShared = [
      for (final share in shared)
        if (ref.watch(
              folderUnreadProvider((
                ownerId: share.ownerId,
                folderId: share.folderId,
              )),
            ) >
            0)
          share,
    ];
    final calmShared = [
      for (final share in shared)
        if (!hotShared.contains(share)) share,
    ];
    // BOŞ KLASÖRLER SONA (geliştirme raporu B3: "Genel 0", "Borç 0" şeridin
    // başında yer kaplıyordu); çip ayrıca soluk (bkz. FolderChip). Sayılar
    // yalnız BOŞ KÜMEYİ izleyen seçimle okunur (virgüllü kimlikler) — her
    // not yazımında şerit yeniden dizilmesin.
    final emptyKey = ref.watch(
      folderNoteCountsProvider.select(
        (m) => [
          for (final f in folders)
            if ((m[f.id] ?? 0) == 0) f.id,
        ].join(','),
      ),
    );
    final empty = emptyKey.split(',').toSet();
    final ordered = emptyFoldersLast(folders, ref.watch(folderSortProvider), {
      for (final f in folders) f.id: empty.contains(f.id) ? 0 : 1,
    });
    return SliverToBoxAdapter(
      child: SizedBox(
        height: FolderChip.stripHeight,
        child: Row(
          children: [
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                children: [
                  // "Tümü" en başta (kullanıcı isteği 2026-10-20).
                  const AllNotesChip(),
                  const SizedBox(width: 6),
                  for (final share in hotShared) ...[
                    SharedFolderChip(
                      key: ValueKey('shared-chip-${share.folderId}'),
                      share: share,
                    ),
                    const SizedBox(width: 6),
                  ],
                  for (final folder in ordered) ...[
                    _EnsureVisible(
                      key: ValueKey('folder-chip-${folder.id}'),
                      active: folder.id == selectedFolderId,
                      child: FolderChip(
                        folder: folder,
                        selected: folder.id == selectedFolderId,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  for (final share in calmShared) ...[
                    SharedFolderChip(
                      key: ValueKey('shared-chip-${share.folderId}'),
                      share: share,
                    ),
                    const SizedBox(width: 6),
                  ],
                  const NewFolderChip(),
                ],
              ),
            ),
            // Karo görünümüne geçiş: klasörleri bir arada görmek isteyen
            // kullanıcı için kapı açık kalsın.
            IconButton(
              tooltip: context.l10n.folderShelfExpand,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.unfold_more, size: 18),
              onPressed: () =>
                  ref.read(folderShelfExpandedProvider.notifier).toggle(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNoteSlivers(
    BuildContext context,
    List<Note> notes,
    int columns, {
    required double cellWidth,
    required bool selectionActive,
    required bool searchActive,
    required bool reorderEnabled,
  }) {
    final l10n = context.l10n;
    if (notes.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: searchActive
              ? EmptyState(
                  icon: Icons.search_off,
                  title: l10n.emptySearch,
                  // Aramada sonuç yoksa anlamsal aramayı hatırlat: kelimesi
                  // geçmeyen ama konusu tutan not orada bulunuyor.
                  subtitle: ref.read(semanticSearchEnabledProvider)
                      ? null
                      : l10n.emptySearchSemanticHint,
                )
              : EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: l10n.emptyNotes,
                  subtitle: l10n.emptyNotesHint,
                ),
        ),
      ];
    }

    // **ARAMA SONUÇ SAYISI**: "aradığım şey kaç notta var" sorusunun cevabı
    // hiçbir yerde yoktu; kullanıcı kartları saymak zorundaydı.
    final countHeader = <Widget>[
      if (searchActive)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.searchResultCount(notes.length),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
    ];

    _pruneCardCache(notes);
    final pinned = [
      for (final n in notes)
        if (n.pinned) n,
    ];
    final others = [
      for (final n in notes)
        if (!n.pinned) n,
    ];

    final query = ref.read(searchQueryProvider).trim();
    // [reorderEnabled] çağırandan gelir: sürükle-sırala artık ⋮ → "Notları
    // sırala" ile açılan AYRI bir moddur ([reorderModeProvider]). Eskiden
    // kalıcı olarak açıktı ve uzun basış sürüklemeyi başlatıyordu; seçmek
    // isteyen kullanıcı kartı kazara taşıyordu. Mod dışında uzun basış
    // her zaman SEÇER.

    final listView = ref.watch(noteListViewProvider);

    // Elle taşımanın anlamlı olduğu görünüm: süzgeçsiz, aramasız, tam liste.
    // (Aynı koşul ⋮ menüsündeki "Notları sırala" maddesinde de var.)
    final manualReorderAllowed =
        !searchActive &&
        ref.read(noteFilterProvider) == NoteFilter.all &&
        ref.read(selectedFolderProvider) == null &&
        !ref.read(showAllNotesProvider) &&
        ref.read(selectedTagProvider) == null;

    /// Liste görünümü: tek sütun, kompakt satır. Sürükle-sırala BURADA yok —
    /// o mod ızgaraya özgü (hücre genişliğiyle çalışıyor); liste görünümünde
    /// ⋮ menüsündeki sıralama maddesi zaten görünmüyor.
    Widget rows(List<Note> items) => SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final note = items[index];
        // ANAHTAR ŞART: anahtarsız satırlarda bir not silinince ya da sıra
        // değişince `_FocusHaloState` YANLIŞ nota bağlanır — vurgu başka
        // satırda yanıp söner ve state boşuna taşınır. Izgarada zaten var,
        // liste görünümünde eksikti.
        //
        // RepaintBoundary: tek satırın vurgusu değişince görünen listenin
        // TAMAMI yeniden boyanıyordu.
        return KeyedSubtree(
          key: ValueKey(note.id),
          child: RepaintBoundary(
            child: Consumer(
              builder: (context, cellRef, _) {
                final focused = cellRef.watch(
                  focusedNoteProvider.select((id) => id == note.id),
                );
                final selected = cellRef.watch(
                  selectedNoteIdsProvider.select((s) => s.contains(note.id)),
                );
                return _FocusHalo(
                  focused: focused,
                  noteId: note.id,
                  child: _SwipeActions(
                    note: note,
                    enabled: !selectionActive,
                    onPin: () => _swipePin(note),
                    onArchive: () => _swipeArchive(note),
                    child: GestureDetector(
                      onLongPress: () => cellRef
                          .read(selectedNoteIdsProvider.notifier)
                          .toggle(note.id),
                      child: NoteListRow(
                        note: note,
                        selected: selected,
                        selectionActive: selectionActive,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    Widget grid(List<Note> section) {
      // Sürükleme sürerken ızgara ÖNİZLENEN sırayı çizer (bkz.
      // [_startCardDrag]) — kullanıcı notun nereye düşeceğini canlı görür.
      // Uzunluk denetimi: akış sürükleme ortasında yeni bir liste
      // yayınlarsa bayat önizlemeye düşmeyelim.
      final preview = _dragOrder;
      final items =
          (preview != null &&
              preview.length == section.length &&
              _dragNoteId != null &&
              section.any((n) => n.id == _dragNoteId))
          ? preview
          : section;
      // SIRALAMA MODU AYRI BİR IZGARA ÇİZER: eşit yükseklikte kompakt karolar.
      //
      // KÖK NEDEN (kullanıcı: "not sıralama sorunlu, yan yana koyamıyorum,
      // otomatik dizilmeli"): mod normal masonry ızgarayı kullanıyordu ve
      // orada kart yüksekliği içeriğe göre değişir. Masonry her kartı O AN en
      // kısa sütuna atar; iki notu yan yana getirmek, aralarındaki bütün
      // kartların yüksekliklerinin denk gelmesine bağlıydı — kullanıcının
      // seçtiği sıra ile ekranda oluşan yerleşim tutmuyor, kartların arasında
      // koca boşluklar kalıyordu (4. ekran görüntüsü). Eşit karolarda n.
      // sıradaki not HER ZAMAN (n ~/ sütun, n % sütun) hücresine düşer:
      // sürüklerken görülen önizleme ile bırakınca oluşan sıra birebir aynı.
      if (reorderEnabled) {
        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: _kReorderTileHeight,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final note = items[index];
            final tile = _ReorderTile(note: note, order: index + 1);
            return _ReorderableNoteCell(
              key: ValueKey(note.id),
              noteId: note.id,
              cellWidth: cellWidth,
              inSection: (id) => items.any((n) => n.id == id),
              onDragStart: () => _startCardDrag(note.id, items),
              onHover: () => _previewCardDrop(index),
              onDragEnd: _endCardDrag,
              feedback: SizedBox(
                width: cellWidth,
                height: _kReorderTileHeight,
                child: tile,
              ),
              child: tile,
            );
          },
        );
      }
      // Tek bir kart hücresi. İki yerleşim (deterministik sütunlar ve tembel
      // masonry) AYNI hücreyi kullanır: sürükle-sırala, seçim ve odak vurgusu
      // davranışı ikisinde de birebir aynı kalsın.
      Widget cell(BuildContext context, int index) {
        final note = items[index];
        // Asistanın dokunduğu not: kart kısa süre vurgulanır ve görünür alana
        // kaydırılır (bkz. focusedNoteProvider). Anahtar, kaydırma için
        // kartın bağlamını bulmaya yarar. Consumer + select: vurgu değişince
        // tüm dashboard değil yalnız ilgili hücre yeniden çizilir.
        final card = Consumer(
          builder: (context, cellRef, _) {
            final focused = cellRef.watch(
              focusedNoteProvider.select((id) => id == note.id),
            );
            return _FocusHalo(
              focused: focused,
              noteId: note.id,
              child: _cachedCard(note, query),
            );
          },
        );
        void select() =>
            ref.read(selectedNoteIdsProvider.notifier).toggle(note.id);
        // Olağan hâl: uzun basış toplu seçime girer. SEÇİLİ bir kartta ise
        // İKİNCİ uzun basış sürüklemeyi başlatır (kullanıcı isteği
        // 2026-08-09: "basılı tutup notu seçince, tekrar basılı tutarsak
        // sıralama için sürüklenebilsin") — böylece ayrı bir sıralama moduna
        // girmeden tek not yerinden alınıp taşınabilir. Süzgeç/arama açıkken
        // kapalı: alt kümede taşımak asıl sırayı bozar (⋮ menüsündeki
        // sıralama maddesi de aynı gerekçeyle o hâlde gizleniyor).
        if (!reorderEnabled) {
          // Seçim KAPALIYKEN sade davranış: uzun basış seçer.
          if (!selectionActive || !manualReorderAllowed) {
            return KeyedSubtree(
              key: ValueKey(note.id),
              child: GestureDetector(onLongPress: select, child: card),
            );
          }
          // Seçim AÇIKKEN her hücre bir BIRAKMA HEDEFİ olur; sürüklemeyi
          // yalnız SEÇİLİ kart başlatır.
          //
          // KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "tekrar basılı tutup
          // sürükleme doğru çalışmıyor"): önce yalnız seçili kart
          // `_ReorderableNoteCell` ile sarılıyordu. `DragTarget` de o
          // sarmalayıcının içinde olduğundan seçilmemiş kartlar hedef
          // DEĞİLDİ — sürüklenen kartı bırakacak yer yoktu, jest hiçbir şey
          // yapmadan bitiyordu. Artık hedef hepsi, sürükleyen seçili olan.
          return KeyedSubtree(
            key: ValueKey(note.id),
            child: Consumer(
              builder: (context, cellRef, _) {
                final isSelected = cellRef.watch(
                  selectedNoteIdsProvider.select((s) => s.contains(note.id)),
                );
                return _ReorderableNoteCell(
                  noteId: note.id,
                  cellWidth: cellWidth,
                  draggable: isSelected,
                  onLongPress: select,
                  inSection: (id) => items.any((n) => n.id == id),
                  onDragStart: () => _startCardDrag(note.id, items),
                  onHover: () => _previewCardDrop(index),
                  onDragEnd: _endCardDrag,
                  feedback: SizedBox(
                    width: cellWidth,
                    child: NoteCard(note: note, highlightQuery: query),
                  ),
                  child: card,
                );
              },
            ),
          );
        }
        return _ReorderableNoteCell(
          key: ValueKey(note.id),
          noteId: note.id,
          cellWidth: cellWidth,
          inSection: (id) => items.any((n) => n.id == id),
          onDragStart: () => _startCardDrag(note.id, items),
          onHover: () => _previewCardDrop(index),
          onDragEnd: _endCardDrag,
          feedback: SizedBox(
            width: cellWidth,
            child: NoteCard(note: note, highlightQuery: query),
          ),
          child: card,
        );
      }

      // TEMBEL deterministik ızgara (bkz. [sliverBalancedNoteColumns]):
      // eskiden bölümün bütün kartları tek kutuda kuruluyordu.
      return sliverBalancedNoteColumns(
        items: items,
        columns: columns,
        cellWidth: cellWidth,
        cell: cell,
      );
    }

    // Başlık metni ZATEN büyük harfli anahtarlardan gelir; kodda
    // `toUpperCase()` çağırmıyoruz — Türkçe'de "Etiket" → "ETIKET" olur
    // (noktasız I), Dart'ın büyük harfe çevirmesi yerel ayar tanımıyor.
    Widget header(String text, int count) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.sectionNoteCount(count),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    const gridPadding = EdgeInsets.symmetric(horizontal: 12);

    // Tarih kovaları yalnız "Son düzenlenen" sıralamasında anlamlı: kullanıcı
    // Başlık ya da Renk sıralamasını seçtiyse "BUGÜN" başlığı altındaki sıra
    // tarihe göre olmaz, başlık yalan söyler. O modlarda tek akış kalır.
    //
    // SIRALAMA MODUNDA da kapalı: kartlar yalnız kendi bölümlerinin içinde
    // taşınabiliyor (bkz. `inSection`), yani "BUGÜN" ile "DAHA ÖNCE" arasına
    // hiçbir not geçemezdi — kullanıcı taşımayı deneyip tutmayınca sıralamayı
    // bozuk sanıyordu. Modda tek liste (sabitliler + gerisi) kalır.
    final bucketsActive =
        !reorderEnabled && ref.read(noteSortProvider) == NoteSort.updated;

    if (!bucketsActive) {
      if (pinned.isEmpty || others.isEmpty) {
        return [
          ...countHeader,
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverPadding(
            padding: gridPadding,
            sliver: listView ? rows(notes) : grid(notes),
          ),
        ];
      }
      return [
        ...countHeader,
        header(l10n.sectionPinnedShort, pinned.length),
        SliverPadding(
          padding: gridPadding,
          sliver: listView ? rows(pinned) : grid(pinned),
        ),
        header(l10n.sectionOthers, others.length),
        SliverPadding(
          padding: gridPadding,
          sliver: listView ? rows(others) : grid(others),
        ),
      ];
    }

    final buckets = <(String, List<Note>)>[
      (l10n.sectionPinnedShort, pinned),
      for (final (label, list) in dateBuckets(others, DateTime.now()))
        (
          switch (label) {
            NoteBucket.today => l10n.sectionToday,
            NoteBucket.thisWeek => l10n.sectionThisWeek,
            NoteBucket.earlier => l10n.sectionEarlier,
          },
          list,
        ),
    ];

    return [
      ...countHeader,
      // Boş kova hiç çizilmez — başlık tek başına duran bir çizgi olurdu.
      for (final (label, list) in buckets)
        if (list.isNotEmpty) ...[
          header(label, list.length),
          SliverPadding(
            padding: gridPadding,
            sliver: listView ? rows(list) : grid(list),
          ),
        ],
    ];
  }
}
