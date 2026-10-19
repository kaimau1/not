import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../ai/data/ai_gate.dart';
import '../../ai/data/gemini_service.dart';
import '../../ai/data/semantic_search.dart';
import '../../folders/data/folder_order.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/data/folder_activity.dart';
import '../../folders/data/shared_activity_service.dart';
import '../../folders/domain/note_folder.dart';
import '../../folders/presentation/folder_sheets.dart';
import '../../folders/presentation/folder_tile.dart';
import '../../auth/presentation/account_sheet.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../friends/presentation/home_invites.dart';
import '../../inbox/presentation/inbox_screen.dart';
import '../../inbox/presentation/shared_hub_screen.dart';
import '../../settings/settings_providers.dart';
import '../../settings/presentation/permissions_onboarding.dart';
import '../data/attachment_repository.dart';
import '../data/notes_repository.dart';
import '../data/reminder_service.dart';
import '../data/share_intake.dart';
import '../data/place_reminders.dart';
import '../data/upload_queue.dart';
import '../data/widget_service.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import '../domain/note_templates.dart';
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

/// Izgaranın altında bırakılan boşluk: sağ alttaki düğme sütunu (iki
/// mikrofon 48 + "+" 56 + aralıklar 20 + alt pay 16 = 188, + 12 nefes payı)
/// ızgaranın ÜSTÜNDE yüzüyor.
///
/// KÖK NEDEN (ana sayfa düzeni, 2026-09-23): boşluk 88 px idi — sütun tek bir
/// FAB'ken yazılmış bir değer. Sütun üç düğmeye çıkınca sağ sütunun son
/// kartının alt yarısı listenin en sonuna kaydırıldığında bile düğmelerin
/// ARKASINDA kalıyordu; kartın altındaki metne/tarihe hiç ulaşılamıyordu.
const double _kFabClearance = 200;

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

  /// "+" menüsünün demirlendiği nokta: mikrofon + "+" sütununun tamamı.
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
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.gridColumnsCount(clamped)),
          duration: const Duration(milliseconds: 900),
        ),
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
      for (final id in ids) {
        repo.softDelete(id);
      }
    });
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: l10n.notesDeletedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () {
        for (final id in ids) {
          repo.restore(id);
        }
      },
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
    for (final id in ids) {
      repo.updateFields(id, {'folderId': picked.isEmpty ? null : picked});
    }
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      message: l10n.notesMovedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () {
        for (final entry in previous.entries) {
          repo.updateFields(entry.key, {'folderId': entry.value});
        }
      },
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
    for (final id in ids) {
      repo.setArchived(id, true);
    }
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      message: l10n.notesArchivedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () {
        for (final id in ids) {
          repo.setArchived(id, false);
        }
      },
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
    for (final id in ids) {
      repo.setPinned(id, pinned);
    }
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }

  void _setStarredSelected(Set<String> ids, bool starred) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    for (final id in ids) {
      repo.setStarred(id, starred);
    }
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
      ..showSnackBar(SnackBar(content: Text(l10n.copied)));
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
        ..showSnackBar(SnackBar(content: Text(l10n.shareAsTextEmpty)));
      return;
    }
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _colorSelected(Set<String> ids, {required bool frame}) async {
    final picked = await showNoteColorPicker(context, frame: frame);
    if (picked == null) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    for (final id in ids) {
      if (frame) {
        repo.setFrameColor(id, picked);
      } else {
        repo.setColor(id, picked);
      }
    }
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
      folderIds: [
        for (final f in ref.read(visibleOrderedFoldersProvider)) f.id,
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
    // Arşiv defteri kendi ekranında açılır (bkz. archiveNoteRoutePath).
    await context.pushNote(
      type == NoteType.archive
          ? archiveNoteRoutePath(id)
          : noteRoutePath(id, query: query),
    );
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
    // Arka plan servislerini ayakta tut: ek yükleme kuyruğu, hatırlatıcı
    // bildirimleri, ana ekran widget'ı ve derin bağlantı dinleyicisi.
    ref.watch(uploadQueueProvider);
    ref.watch(reminderServiceProvider);
    // Silinen/arşivlenen notların konum hatırlatıcılarını kaldırır.
    ref.watch(placeReminderCleanupProvider);
    // Paylaşılan klasörlerdeki hareketi izler: rozet + telefon bildirimi
    // (kullanıcı isteği 2026-09-04).
    ref.watch(sharedActivityServiceProvider);
    ref.watch(widgetServiceProvider);
    ref.watch(deepLinkHandlerProvider);
    // Premium akışını canlı tut: AI kapısı (AiGate.consume) senkron okur.
    ref.watch(premiumProvider);
    // Paylaş menüsünden gelen içerikleri dinle (Android).
    ref.watch(shareIntakeProvider);

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
                // YAPAY ZEKÂ "+"nın SOLUNDA (kullanıcı isteği 2026-10-17:
                // "üstteki AI butonunu alttaki artı butonunun soluna al").
                // "+" 56 dp; AI 48 dp — dikey ortaları hizalı.
                if (!selectionActive)
                  PositionedDirectional(
                    end: 16 + 56 + 12,
                    bottom: 16 + 4,
                    child: Customizable(
                      id: UiItem.homeAi,
                      child: _DashVoiceButton(
                        key: const ValueKey('home-ai'),
                        tooltip: l10n.aiHubTitle,
                        icon: Icons.auto_awesome,
                        onTap: () => context.push('/ai'),
                      ),
                    ),
                  ),
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
                  // Bağlantı noktası TÜM sütunu sarar: "+" menüsü kendi
                  // düğmesine değil sütunun tepesine demirlenir, böylece
                  // açılınca mikrofonun üstünü örtmez. Mikrofon yüksekliğini
                  // sabit sayı olarak yazmaya gerek kalmaz.
                  child: CompositedTransformTarget(
                    link: _fabColumnLink,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      // Merkezden hizalı: mikrofon 84 px'lik sabit kutuda,
                      // "+" ise 56 px'lik FAB. Sağa dayalıyken merkezleri
                      // 14 px kayıyor ve göz bunu hizasızlık olarak görüyordu.
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                padding: const EdgeInsets.only(bottom: 10),
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
                        // İKİ MİKROFON — editörün alt çubuğundakiyle AYNI
                        // ayrım (kullanıcı isteği 2026-09-01: "ana ekrandaki
                        // ses butonunu da güncelle"):
                        //  * sade mikrofon → SESLE YAZ: boş bir not açılır ve
                        //    konuşulan söz doğrudan nota yazılır, levha yok.
                        //  * parıltılı mikrofon → asistan/ses yakalama
                        //    levhası (eski davranış): metin gözden geçirilir,
                        //    özetlenebilir, hatırlatıcıya çevrilebilir.
                        // İkisi de kişiselleştirmede gizlenebilir (bkz.
                        // UiItem.homeVoiceAi / homeDictation); aralık
                        // düğmeyle birlikte gider.
                        Customizable(
                          id: UiItem.homeVoiceAi,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DashVoiceButton(
                              tooltip: l10n.voiceAssistantTitle,
                              icon: Icons.mic_none,
                              badge: Icons.auto_awesome,
                              onTap: _captureVoiceNote,
                            ),
                          ),
                        ),
                        Customizable(
                          id: UiItem.homeDictation,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DashVoiceButton(
                              tooltip: l10n.liveDictation,
                              icon: Icons.mic,
                              onTap: createDictationNote,
                            ),
                          ),
                        ),
                        // Keep tarzı açılan "+": metin/madde/sıralı/el yazısı.
                        QuickAddFab(
                          // Hızlı ekle → Sesli not: ana ekranın mikrofonuyla
                          // aynı levha; boş not önceden açılmaz.
                          onVoiceCapture: _captureVoiceNote,
                          onVideoNote: createVideoNote,
                          onPhotoNote: createPhotoNote,
                          onScanNote: createScanNote,
                          onPdfNote: createPdfNote,
                          onImageNote: createImageNote,
                          onSlidesNote: createSlidesNote,
                          onQrNote: createQrNote,
                          onGalleryVideo: createGalleryVideoNote,
                          onYouTube: createYouTubeNote,
                          onTranscribe: kIsWeb ? null : createTranscribeNote,
                          anchor: _fabColumnLink,
                          onCreate: createNote,
                          onHandwriting: createHandwritingNote,
                          onTemplate: createFromTemplate,
                          onShopping: () =>
                              createFromTemplate(NoteTemplate.shopping),
                        ),
                      ],
                    ),
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
      case 'account':
        showAccountSheet(context);
      case 'inbox':
        InboxScreen.open(context);
      case 'friends':
        openFriendsScreenOrExplain(context, ref);
      case 'hidden':
        _toggleHiddenFolders();
      case 'reminders':
        context.push('/reminders');
      case 'archive':
        context.push('/archive');
      case 'background':
        showDashboardBackgroundSheet(context);
      case 'trash':
        context.push('/trash');
      case 'template':
        createFromTemplate();
      case 'folderOrder':
        showFolderOrderSheet(context);
      case 'settings':
        context.push('/settings');
      case 'personalize':
        context.push('/personalize');
      case 'guide':
        context.push('/guide');
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
                  for (final share in hotShared) ...[
                    SharedFolderChip(
                      key: ValueKey('shared-chip-${share.folderId}'),
                      share: share,
                    ),
                    const SizedBox(width: 6),
                  ],
                  for (final folder in folders) ...[
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
              child: NoteCard(note: note, highlightQuery: query),
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

/// Sabit başlık (arama çubuğu + süzgeç çipleri) ile kayan not ızgarası
/// arasındaki sınır çizgisi.
///
/// Liste tepedeyken görünmez: sayfa duruyorken bir çizgi çekmek gereksiz bir
/// bölme yaratır. Kaydırma başlar başlamaz belirir ve altına yumuşak bir gölge
/// düşürür — kartlar artık başlığın "ALTINDAN" geçtiği belli olur
/// (bkz. [_DashboardScreenState._gridScrolled]).
class _HeaderSeparator extends StatelessWidget {
  const _HeaderSeparator({required this.scrolled});

  final ValueNotifier<bool> scrolled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<bool>(
      valueListenable: scrolled,
      builder: (context, on, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 1,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: on ? scheme.outlineVariant : Colors.transparent,
          boxShadow: on
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
      ),
    );
  }
}

/// Sıralama modundaki karonun sabit yüksekliği. Eşit karo = önceden bilinen
/// hücre: sürüklerken görülen önizleme ile bırakınca oluşan yerleşim aynı.
const double _kReorderTileHeight = 104;

/// Sıralama modunun kompakt not karosu: renk, başlık, kısa önizleme ve sıra
/// numarası. Tam kartın kendisi kullanılmaz — içeriğe göre uzayan kart eşit
/// hücreye sığmaz, sığdırmak için kırpılınca da okunmaz olurdu.
class _ReorderTile extends StatelessWidget {
  const _ReorderTile({required this.note, required this.order});

  final Note note;

  /// Kartın bölümdeki 1 tabanlı sırası: taşırken "kaçıncı sıraya gitti"
  /// sorusunun cevabı ekranda dursun.
  final int order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final framed = note.frameColor != NoteColor.none;
    final title = note.title.trim();
    final preview = stripRichMarkers(note.toPlainText()).trim();
    return Material(
      color: NoteColors.surface(context, note.color),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: framed
                ? NoteColors.swatch(note.frameColor)
                : scheme.outlineVariant.withValues(alpha: 0.5),
            width: framed ? 2.5 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.pinned) ...[
                  Icon(Icons.push_pin, size: 13, color: scheme.primary),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    title.isEmpty ? preview : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$order',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                title.isEmpty ? '' : preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.25,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.drag_indicator,
                  size: 15,
                  color: scheme.onSurfaceVariant,
                ),
                const Spacer(),
                if (note.attachments.isNotEmpty)
                  Icon(
                    Icons.attach_file,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir not kartını basılı tutup sürükleyerek yeniden sıralamayı sağlayan
/// sarmalayıcı. Sıralama modunda ([reorderModeProvider]) ve seçim kipinde
/// SEÇİLİ kartlarda kullanılır: uzun basış sürüklemeyi başlatır, parmak
/// gezdikçe üst katman sırayı CANLI önizler ([onHover]), parmak kalkınca
/// görünen sıra kaydedilir ([onDragEnd]). Sürükleme aynı bölümle sınırlıdır
/// ([inSection]) — sabitliler ile diğerleri karışmaz.
///
/// Sürüklenemeyen hücreler yalnız BIRAKMA HEDEFİDİR; onlarda uzun basış
/// seçim yapar ([onLongPress]).
class _ReorderableNoteCell extends StatelessWidget {
  const _ReorderableNoteCell({
    super.key,
    required this.noteId,
    required this.cellWidth,
    required this.inSection,
    required this.onDragStart,
    required this.onHover,
    required this.onDragEnd,
    required this.feedback,
    required this.child,
    this.draggable = true,
    this.onLongPress,
  });

  final String noteId;
  final double cellWidth;
  final bool Function(String draggedId) inSection;

  /// Bu karttan sürükleme başladı.
  final VoidCallback onDragStart;

  /// Sürüklenen kart BU hücrenin üzerinde: üst katman sırayı önizler.
  final VoidCallback onHover;

  /// Parmak kalktı (kabul edilsin edilmesin): görünen sıra kaydedilir.
  final VoidCallback onDragEnd;
  final Widget feedback;
  final Widget child;

  /// Bu hücre sürüklenebilir mi? false ise yalnız BIRAKMA HEDEFİ olur —
  /// seçim kipinde yalnız seçili kart taşınır, ötekiler hedeftir.
  final bool draggable;

  /// Sürüklenemeyen hücrede uzun basış (seçime al/çıkar).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          details.data != noteId && inSection(details.data),
      // Parmak bu hücrenin üzerine geldi: sıra CANLI önizlenir. Bırakma
      // (`onAccept`) beklenmez — kullanıcı sonucu sürüklerken görmeli.
      onMove: (_) => onHover(),
      onAcceptWithDetails: (_) {},
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        // Üzerine bırakılmak üzere olan hücre vurgulanır; kenarlık HER ZAMAN
        // 2 px (saydam) — kalınlığı değiştirmek yerleşimi oynatırdı.
        final framed = AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovering ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: child,
        );
        if (!draggable) {
          return GestureDetector(onLongPress: onLongPress, child: framed);
        }
        return LongPressDraggable<String>(
          data: noteId,
          onDragStarted: onDragStart,
          // Nereye bırakılırsa bırakılsın (kartın üstü, boşluk, ekran dışı)
          // önizlenen sıra kaydedilir; kullanıcı zaten onu görüyordu.
          onDragEnd: (_) => onDragEnd(),
          onDraggableCanceled: (_, _) => onDragEnd(),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.9,
              child: SizedBox(width: cellWidth, child: feedback),
            ),
          ),
          // Kart önizlemede zaten YENİ yerinde duruyor; burada soluk bir
          // hayalet bırakmak "gideceği yer" hissini tamamlıyor.
          childWhenDragging: Opacity(opacity: 0.25, child: child),
          child: framed,
        );
      },
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.controller, this.focusNode});

  final TextEditingController controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(searchQueryProvider);
    final semantic = ref.watch(semanticSearchEnabledProvider);
    final scheme = Theme.of(context).colorScheme;
    // Anlamsal arama ESKİDEN alanın içindeki ✨ düğmesiydi: açık mı kapalı mı
    // olduğu yalnız ikon renginden anlaşılıyor, "akıllı arama" diye bir şeyin
    // varlığı hiç fark edilmiyordu. İki sekmeli segment modu okunur kılıyor.
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(Icons.search, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).set(value),
              // Alan dışına dokununca odak bırakılır; bar daralır. Sorgu da
              // o anda "son aramalar"a düşer — kullanıcı arama yapıp bir
              // nota geçtiğinde geçmişe yazılmasının doğal anı burası.
              onTapOutside: (_) {
                ref.read(searchHistoryProvider.notifier).remember(query);
                focusNode?.unfocus();
              },
              onSubmitted: (value) =>
                  ref.read(searchHistoryProvider.notifier).remember(value),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: semantic ? l10n.semanticSearchHint : l10n.searchHint,
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: scheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (query.isNotEmpty)
            IconButton(
              tooltip: l10n.close,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                controller.clear();
                ref.read(searchQueryProvider.notifier).set('');
              },
            ),
          // TEK AI ANAHTARI (kullanıcı isteği 2026-10-17: "metin/anlam
          // yazıları çok yer kaplıyor, sadece bir AI işareti olsun, basınca
          // açılıp kapansın — metin ve anlam arasında geçiş"): açıkken dolu
          // vurgu rengi (anlamla arama), kapalıyken soluk çerçeve (metin).
          _SemanticToggle(
            on: semantic,
            onTap: () =>
                ref.read(semanticSearchEnabledProvider.notifier).toggle(),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// Arama kutusunun altındaki "son aramalar" şeridi.
///
/// Boşken hiç yer kaplamaz. Çipe dokunmak sorguyu geri getirir, çipteki ×
/// onu geçmişten siler (yanlış yazılmış ya da bir daha aranmayacak bir
/// sorgu listede kalmasın).
class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.visible, required this.onPick});

  final bool visible;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visible) return const SizedBox.shrink();
    if (ref.watch(searchQueryProvider).isNotEmpty) {
      return const SizedBox.shrink();
    }
    final history = ref.watch(searchHistoryProvider);
    if (history.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.recentSearches,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: ref.read(searchHistoryProvider.notifier).clear,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  l10n.clearRecentSearches,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final query = history[index];
                return InputChip(
                  label: Text(query, style: const TextStyle(fontSize: 12)),
                  avatar: const Icon(Icons.history, size: 14),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onPick(query),
                  onDeleted: () =>
                      ref.read(searchHistoryProvider.notifier).forget(query),
                  deleteIcon: const Icon(Icons.close, size: 14),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SemanticToggle extends StatelessWidget {
  const _SemanticToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Tooltip(
      message: l10n.semanticSearchToggle,
      child: Semantics(
        toggled: on,
        button: true,
        label: l10n.searchModeMeaning,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            key: const ValueKey('search-ai-toggle'),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: on ? scheme.primary : scheme.surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: on ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: onTap,
                child: Icon(
                  on ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                  size: 18,
                  color: on ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Asistanın dokunduğu notu görünür alana kaydırıp kısa süre vurgulayan
/// sarmalayıcı.
///
/// Vurgu KARTIN İÇİNE değil çevresine çizilir: kartın kendi kenarlığı/rengi
/// notun ayarı, geçici bir işaret onu değiştirmemeli. Kaydırma yalnız bir kez,
/// vurgu ilk göründüğünde yapılır — kullanıcı sonra elle kaydırırsa kart geri
/// zıplamaz.
class _FocusHalo extends StatefulWidget {
  const _FocusHalo({
    required this.focused,
    required this.noteId,
    required this.child,
  });

  final bool focused;
  final String noteId;
  final Widget child;

  @override
  State<_FocusHalo> createState() => _FocusHaloState();
}

class _FocusHaloState extends State<_FocusHalo>
    with SingleTickerProviderStateMixin {
  bool _scrolled = false;

  /// Çerçevenin YANIP SÖNMESİ: sabit bir kenarlık uzun listede gözden
  /// kaçıyordu (kullanıcı: "notun çerçevesinden hafif yanıp sönmeli").
  /// Nefes alır gibi, göz yormayan bir ritim.
  /// TEMBEL: yalnız ODAKLI kartta kurulur (bkz. [_syncPulse] kök nedeni).
  AnimationController? _pulse;

  AnimationController _ensurePulse() => _pulse ??= AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(covariant _FocusHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focused && !oldWidget.focused) _scrolled = false;
    _maybeScroll();
    _syncPulse();
  }

  @override
  void initState() {
    super.initState();
    _maybeScroll();
    _syncPulse();
  }

  /// KÖK NEDEN (kasma): denetleyici ODAKLANMAMIŞ kartta da yaratılıyordu.
  /// `_FocusHalo` her kartı sarıyor ve kaydırma önbelleği ~130 kartı canlı
  /// tuttuğu için, tek bir notu vurgulamak uğruna 130 `AnimationController` +
  /// 130 `Ticker` kuruluyor, kaydırdıkça sürekli kurulup yıkılıyordu.
  void _syncPulse() {
    if (!widget.focused) {
      // Hiç kurulmadıysa kurma: odaklanmamış kart için denetleyiciye gerek yok.
      _pulse
        ?..stop()
        ..value = 0;
      return;
    }
    final pulse = _ensurePulse();
    if (!pulse.isAnimating) pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  void _maybeScroll() {
    if (!widget.focused || _scrolled) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.3,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!widget.focused) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: widget.child,
      );
    }
    final pulse = _ensurePulse();
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.35 + 0.65 * pulse.value),
            width: 2,
          ),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Ana ekranın en üstündeki tek satırlık not girişi.
///
/// Kısa notlar için editöre gitmek gereksiz bir tur: aç, yaz, geri dön.
/// Burada Enter'a basmak notu doğrudan kaydeder ve satır temizlenir; kullanıcı
/// arka arkaya beş not düşecekse ekrandan hiç ayrılmaz.
class _QuickCaptureRow extends ConsumerStatefulWidget {
  const _QuickCaptureRow({
    required this.onCreateChecklist,
    required this.onSaved,
  });

  final VoidCallback onCreateChecklist;

  /// Not oluşturulduktan sonra çağrılır (yeni notun id'si ile): ana ekran
  /// kartı vurgular ve bildirim gösterir.
  final void Function(String noteId) onSaved;

  @override
  ConsumerState<_QuickCaptureRow> createState() => _QuickCaptureRowState();
}

class _QuickCaptureRowState extends ConsumerState<_QuickCaptureRow> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    // Satır ÖNCE temizlenir: kayıt ağ üzerinden dönerken kullanıcı ikinci
    // notu yazmaya başlayabilsin, yazdığı harfler ilkinin üstüne binmesin.
    _controller.clear();
    setState(() => _hasText = false);
    // Metin TEK yazımda gider (önce boş not + sonra gövde DEĞİL): iki yazım
    // arasında doküman boş kalıyor ve o ara akışa düşerse not ana ekran
    // süzgecinden eleniyordu — "bazen oluşuyor bazen oluşmuyor"un kaynağı.
    final id = await repo.createNote(
      NoteType.text,
      body: text,
      folderId: ref.read(selectedFolderProvider),
    );
    // Klavye kapanır: not kaydedildi, imleç boş satırda yanıp sönmesin —
    // "kaydettim ama bir şey olmadı" hissinin bir parçası da buydu.
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSaved(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (v) {
                  final has = v.trim().isNotEmpty;
                  if (has != _hasText) setState(() => _hasText = has);
                },
                onSubmitted: (_) => _save(),
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: l10n.quickCaptureHint,
                  hintStyle: TextStyle(
                    fontSize: 14.5,
                    color: scheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_hasText)
              SizedBox(
                height: 34,
                child: FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    l10n.quickCaptureSave,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              // Mikrofon buradan KALDIRILDI: sağ altta zaten kalıcı bir sesli
              // yakalama düğmesi var, aynı iş iki yerde duruyordu.
              _QuickCaptureIcon(
                icon: Icons.checklist,
                tooltip: l10n.filterChecklist,
                onTap: widget.onCreateChecklist,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickCaptureIcon extends StatelessWidget {
  const _QuickCaptureIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Icon(
            icon,
            size: 19,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ),
  );
}

/// İki parmak "sıkıştırma" hareketini ARENAYA GİRMEDEN ölçen sarmalayıcı.
///
/// KÖK NEDEN (kullanıcı 2026-08-08: ana ekranda iki parmakla sütun değişimi
/// çalışmıyordu): eskiden bir `GestureDetector.onScaleUpdate` kullanılıyordu.
/// O tanıyıcı, altındaki kaydırma görünümünün dikey sürükleme tanıyıcısıyla
/// AYNI jest arenasında yarışır ve sürükleme İLK parmakta kabul edildiği için
/// çoğu zaman önce kazanır — ikinci parmak indiğinde iş işten geçmiş olur.
///
/// `Listener` arenaya hiç girmez: işaretçileri sessizce dinler, kaydırmayı
/// bozmaz ve iki parmak arasındaki uzaklık yeterince değişince haber verir.
/// (Aynı çözüm PDF metin seçim katmanında da kullanılıyor.)
class _PinchColumns extends StatefulWidget {
  const _PinchColumns({
    required this.child,
    required this.onStart,
    required this.onScale,
  });

  final Widget child;

  /// İkinci parmak indi: çağıran o anki sütun sayısını taban alır.
  final VoidCallback onStart;

  /// Taban uzaklığa göre O ANKİ oran (>1 = parmaklar açılıyor).
  /// **true dönerse bir adım atıldı** ve taban uzaklık şimdiki değere
  /// çekilir; yoksa oran eşiğin üstünde kaldığı sürece her karede bir adım
  /// daha atılır ve tek jestte en uca fırlanırdı.
  final bool Function(double scale) onScale;

  @override
  State<_PinchColumns> createState() => _PinchColumnsState();
}

class _PinchColumnsState extends State<_PinchColumns> {
  final _points = <int, Offset>{};

  /// İki parmak indiği andaki uzaklık; oran buna göre ölçülür. Çağıran bir
  /// adım attığında sıfırlanır ki aynı jestle 1 → 4 arası gezilebilsin.
  double _base = 0;

  void _recompute() {
    if (_points.length != 2) {
      _base = 0;
      return;
    }
    final values = _points.values.toList();
    final distance = (values[0] - values[1]).distance;
    if (_base == 0) {
      if (distance < 24) return; // parmaklar üst üste: ölçüm anlamsız
      _base = distance;
      widget.onStart();
      return;
    }
    if (widget.onScale(distance / _base)) _base = distance;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _points[e.pointer] = e.position;
      _recompute();
    },
    onPointerMove: (e) {
      if (!_points.containsKey(e.pointer)) return;
      _points[e.pointer] = e.position;
      _recompute();
    },
    onPointerUp: (e) {
      _points.remove(e.pointer);
      _base = 0;
    },
    onPointerCancel: (e) {
      _points.remove(e.pointer);
      _base = 0;
    },
    child: widget.child,
  );
}

/// Ana ekranın sağ alt sütunundaki mikrofon düğmesi.
///
/// İki örneği var ve tek fark [badge]: parıltılı olan yapay zekâ yolunu
/// (asistan levhası), sade olan doğrudan dikteyi açar. Editörün alt
/// çubuğundaki ikili ile bilerek aynı görünür — aynı iş, aynı simge.
class _DashVoiceButton extends StatelessWidget {
  const _DashVoiceButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String tooltip;
  final IconData icon;
  final IconData? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Material(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 24, color: scheme.onPrimaryContainer),
                if (badge != null)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Icon(
                      badge,
                      size: 11,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// **KAYDIRARAK HIZLI İŞLEM** (kullanıcı isteği 2026-09-23): liste
/// görünümünde satırı sağa çekmek sabitler (ya da sabitlemeyi kaldırır),
/// sola çekmek arşivler — geri alınabilir.
///
/// Yalnız LİSTE görünümünde: ızgarada yatay çekiş süzgeçler arasında
/// geziyor ([_cycleFilterFolder]) ve kartlar sütunlarda yan yana duruyor;
/// orada kartın kendisini çekmek, hangi işin olacağını belirsizleştirirdi.
///
/// `confirmDismiss` işi yapıp FALSE döner: satır yerine geri kayar, notun
/// listeden çıkması (arşiv) ya da sabitlilere taşınması Firestore akışından
/// gelir. `true` dönülseydi akış o kareye yetişmediğinde Flutter "kapatılmış
/// Dismissible hâlâ ağaçta" hatası verirdi.
class _SwipeActions extends StatelessWidget {
  const _SwipeActions({
    required this.note,
    required this.enabled,
    required this.onPin,
    required this.onArchive,
    required this.child,
  });

  final Note note;

  /// Seçim kipinde kapalı: orada çekiş seçimle karışırdı.
  final bool enabled;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget background({
      required AlignmentGeometry alignment,
      required IconData icon,
      required String label,
      required Color color,
      required Color ink,
    }) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ink, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: ink, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    return Dismissible(
      key: ValueKey('swipe-${note.id}'),
      direction: enabled ? DismissDirection.horizontal : DismissDirection.none,
      // Yanlışlıkla tetiklenmesin: satırın en az %35'i çekilmeli.
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      background: background(
        alignment: AlignmentDirectional.centerStart,
        icon: note.pinned ? Icons.push_pin_outlined : Icons.push_pin,
        label: note.pinned ? l10n.unpin : l10n.pin,
        color: scheme.secondaryContainer,
        ink: scheme.onSecondaryContainer,
      ),
      secondaryBackground: background(
        alignment: AlignmentDirectional.centerEnd,
        icon: Icons.archive_outlined,
        label: l10n.archive,
        color: scheme.tertiaryContainer,
        ink: scheme.onTertiaryContainer,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onPin();
        } else {
          onArchive();
        }
        return false;
      },
      child: child,
    );
  }
}


/// **SENKRON BEKLEYEN EKLER** göstergesi (kullanıcı isteği 2026-09-23).
///
/// Çevrimdışı eklenen fotoğraf öbür cihazda görünmüyordu ve bunun nedeni
/// hiçbir yerde yazmıyordu — kullanıcı "senkron bozuk" sanıyordu. Bekleyen
/// ek varken filtre satırının altında ince bir şerit durur; dokununca
/// açıklama çıkar. Hiç bekleyen yokken hiç yer kaplamaz.
///
/// Kendi `Consumer`ı: sayaç her değiştiğinde ana ekranın tamamı yeniden
/// kurulmasın.
class _PendingUploadsBar extends ConsumerWidget {
  const _PendingUploadsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingUploadsProvider);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Google hesabı ama Drive bağlanmadı: ekler bağlantı bekliyor — şerit
    // bunu söyler ve dokununca bağlar (kullanıcı isteği 2026-10-15).
    final needsDrive = state.needsDrive;
    final failing = state.failed > 0 && !needsDrive;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: state.pending == 0
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Material(
                color: failing
                    ? scheme.errorContainer
                    : scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: needsDrive
                      ? () => connectDrive(context, ref)
                      : () => ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(l10n.pendingUploadsInfo)),
                          ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          needsDrive
                              ? Icons.add_to_drive_outlined
                              : failing
                              ? Icons.cloud_off_outlined
                              : Icons.cloud_upload_outlined,
                          size: 18,
                          color: failing
                              ? scheme.onErrorContainer
                              : scheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            needsDrive
                                ? l10n.driveWaiting(state.pending)
                                : failing
                                ? l10n.pendingUploadsFailed(state.failed)
                                : l10n.pendingUploads(state.pending),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: failing
                                  ? scheme.onErrorContainer
                                  : scheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        // Dönen çark YOK (bilerek): bağlantı yokken şerit
                        // saatlerce durabilir; sürekli animasyon pili yakardı.
                        Icon(
                          needsDrive ? Icons.link : Icons.info_outline,
                          size: 16,
                          color: failing
                              ? scheme.onErrorContainer
                              : scheme.onSecondaryContainer,
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


/// Yatay şeritteki seçili çipi görünür alana kaydırır: yana çekişle ekran
/// dışındaki bir klasöre gelinince şerit de oraya kayar.
class _EnsureVisible extends StatefulWidget {
  const _EnsureVisible({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_EnsureVisible> createState() => _EnsureVisibleState();
}

class _EnsureVisibleState extends State<_EnsureVisible> {
  @override
  void initState() {
    super.initState();
    if (widget.active) _reveal();
  }

  @override
  void didUpdateWidget(_EnsureVisible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _reveal();
  }

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
