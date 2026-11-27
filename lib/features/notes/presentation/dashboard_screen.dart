import '../../../core/haptics.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../app/window_class.dart';
import '../../../core/utils/web_file_drop.dart';
import '../../../core/app_icons.dart';
import '../../../core/app_update.dart' show UpdateBanner;
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/widgets/back_closes.dart';
import '../../../core/widgets/hold_progress_ring.dart';
import '../../../core/widgets/sheet_header.dart';
// ScrollCacheExtent (ızgara önbellek payı) yalnız rendering katmanında.
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_commands.dart';
import 'due_banner.dart';
import 'drag_trash_target.dart';
import 'reorder_hover_gate.dart';
import '../../../app/app_frame.dart';
import '../../../app/router.dart';
import '../../../app/split_shell.dart';
import '../../../app/web_workspace/web_dashboard_header.dart';
import '../../../app/web_workspace/web_workspace_scope.dart';
import '../../../app/theme/note_colors.dart';
import 'dart:math' as math;

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_design.dart' show AppSwipe, AppTone;
import '../../../core/a11y/motion.dart';
import '../../../core/widgets/snapshot_when_leaving.dart';
import '../../../core/widgets/action_menu_sheet.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import '../../../core/tips.dart';
import '../../../core/widgets/customizable.dart';
import '../../../core/widgets/freeze_when_hidden.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/connectivity.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../folders/data/folder_order.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/data/folder_activity.dart';
import '../../folders/domain/note_folder.dart';
import '../../folders/presentation/folder_header_panel.dart';
import '../../folders/presentation/folder_nav.dart';
import '../../folders/presentation/folder_sheets.dart';
import '../../folders/presentation/folder_tile.dart';
import '../../folders/presentation/shared_folder_home.dart';
import '../../auth/presentation/account_sheet.dart';
import '../../auth/presentation/guest_backup_card.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/presentation/home_invites.dart';
import '../../settings/settings_providers.dart';
import '../../settings/presentation/theme_picker.dart' show showThemePickerSheet;
import '../../calendar/data/calendar_repository.dart'
    show noteCalendarDayProvider;
import '../../calendar/presentation/home_calendar_strip.dart';
import '../data/attachment_repository.dart';
import '../data/notes_repository.dart';
import '../data/upload_queue.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import '../domain/note_type.dart';
import 'color_picker_sheet.dart';
import 'app_background_layers.dart';
import 'dashboard_background_sheet.dart';
import 'filter_sheet.dart';
import 'home_snapshot.dart';
import 'folder_hold_button.dart';
import 'note_card.dart';
import 'note_link_ui.dart' show noteLinkLabel;
import 'note_grid.dart';
import 'shared_notes_screen.dart';
import '../../inbox/data/inbox_repository.dart' show inboxNotesProvider;
import '../../inbox/presentation/shared_hub_screen.dart' show sharedHubPlaceholder, sharedHubSlivers, showSharedHubOnHome;
import '../data/shared_note_activity.dart' show sharedNotesVisibleCountProvider;
import 'notes_providers.dart';
import 'quick_add_actions.dart';
import 'quick_add_fab.dart';
import 'quick_drop_sheet.dart' show showQuickDropSheet;
import 'voice_assistant.dart';
import 'voice_assistant_widgets.dart';
import 'voice_capture_sheet.dart';
import 'drive_ui.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/error_log.dart';
import '../../../core/friendly_error.dart';

import 'dashboard_scroll_memory.dart';

part 'dashboard_widgets.dart';
part 'dashboard_gestures.dart';
part 'dashboard_ops.dart';
part 'dashboard_build.dart';
part 'dashboard_selection.dart';
part 'dashboard_menu.dart';
part 'dashboard_shelf.dart';
part 'dashboard_slivers.dart';

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

/// Ana ekranın kart ızgarası: kaydırma payı [narrow]'a göre (250 px ya da
/// [_kGridCacheExtent]). [tick] değişince YALNIZ bu görünüm kurulur; sliver'lar
/// aynı örnekler kaldığı için kart kurulmaz, yerleşim eksik payı tamamlar.
///
/// Araya dinleyen bir widget koymak yerine öğenin kendisi dinler: ağaca katman
/// eklenmez (bütçe S24 ilk kare, mandal).
///
const double _kFabClearance = 96;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver, QuickAddActions
    implements HomeDoors {
  // ---- Ray ve kısayol kapıları (bkz. HomeDoors) ------------------------
  @override
  QuickAddActions get quickAddActions => this;

  @override
  void dictateNote() => unawaited(_dictateNote());

  @override
  void captureVoiceNote() => unawaited(_captureVoiceNote());

  /// Yana çekişin açık olduğu durumla aynı kural (bkz. [FolderSwipe.enabled]).
  @override
  void cycleFolder(int direction) {
    if (ref.read(selectedNoteIdsProvider).isNotEmpty ||
        ref.read(reorderModeProvider) ||
        _dragNoteId != null ||
        ref.read(swipeModeProvider) == SwipeMode.off) {
      return;
    }
    _cycleFilterFolder(direction);
  }

  /// "Tümünü seç" düğmesiyle aynı kapsam: ekranda görünen notlar.
  @override
  void selectAllVisible() => ref
      .read(selectedNoteIdsProvider.notifier)
      .selectAll(ref.read(filteredNotesProvider).value?.map((n) => n.id) ?? const []);

  @override
  void deleteSelection() {
    final ids = ref.read(selectedNoteIdsProvider);
    if (ids.isNotEmpty) unawaited(_deleteSelected(ids));
  }

  /// Yeni gelen bölümün (süzgeç|klasör|etiket) anahtarı: geçiş sürerken
  /// ızgarası dar kaydırma payıyla kurulur (P46, bütçe S23). Eskiden gelen
  /// ızgara ilk karesinde görünen kartlara ek 1600 px'lik payı da kuruyordu
  /// (geçişin en ağır karesi); pay artık geçiş bitince, boşta genişler.
  String? _freshSegment;
  Timer? _cacheWiden;
  final _cacheTick = ValueNotifier<int>(0);

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

  /// Şu an görünen ızgara bölümünün anahtarı (kaydırma hafızası için).
  String _segmentKey = '';

  /// Kart widget'ı önbelleği (F2.1): not ÖRNEĞİ ve arama sorgusu aynıysa
  /// AYNI `NoteCard` örneği döner — Flutter aynı örneği görünce o kartın alt
  /// ağacını hiç kurmaz. Bir notun yazımı (editörde otomatik kayıt) ana ekranı
  /// yeniden kurduğunda görünen BÜTÜN kartlar (medya planı, zengin önizleme
  /// ayrıştırması, kapak) baştan kuruluyordu; artık yalnız değişen kart.
  ///
  /// Anahtar sorgunun KENDİSİ değil yalnız "arama var mı" (F21.6): sorgu
  /// harf harf değişirken kartlar aynı örnek kalır, vurgu [_liveQuery]
  /// üzerinden yalnız yeniden BOYANIR (bkz. `SearchHighlight`).
  final Map<String, (Note, bool, DateTime?, Widget)> _cardCache = {};

  /// Kartların izlediği canlı arama sorgusu (F21.6).
  final _liveQuery = ValueNotifier<String>('');


  /// Kullanıcı bu kadar aşağıdaysa "başa dön" düğmesi görünür. Bir ekran
  /// yüksekliğinden fazlası: kısa bir kaydırmada düğme çıkıp kaybolmasın.
  static const _kBackToTopAfter = 800.0;

  /// Klasör menüsünü açan aşağı çekiş mesafesi (dp, parmak hareketi).
  static const _kFolderPullDistance = 80.0;
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
  ///
  /// TEMBEL OLAMAZ (F44.8 kök nedeni): gizli listede sayfa hiç kurulmaz
  /// ([FreezeWhenHidden]), ilk erişim `dispose`a kalır ve `ref` orada patlar:
  /// not açıkken pencere daralınca istisna.
  late final TextEditingController _searchController;
  final _searchFocus = FocusNode();

  /// "+" menüsünün demirlendiği nokta: "+" düğmesi (mikrofon solunda).
  final _fabColumnLink = LayerLink();

  /// Filtreler arası geçiş yönü (madde 2): sola çekiş → sonraki (sağdan girer),
  /// sağa çekiş → önceki (soldan girer). Geçiş animasyonu bu yönü kullanır.
  bool _swipeForward = true;

  /// Yana çekişle ayrılan görünüm (bölüm anahtarı) ve parmağın bıraktığı
  /// konum (genişlik oranı): ayrılan ızgara oradan devam eder
  /// ([FolderSwipe.continuesInPlace]). Geçiş bitince temizlenir.
  String? _leavingKey;
  double _leavingFrom = 0;
  Timer? _leavingClear;

  bool _continueSwipe(int direction, double releaseFraction) {
    if (_swipeOpensCalendar(direction) || _swipeStop(direction) == null) {
      return false;
    }
    _leavingKey = _segmentKey;
    _leavingFrom = releaseFraction;
    _leavingClear?.cancel();
    _leavingClear = Timer(AppMotion.medium * 2, () {
      _leavingKey = null;
      _leavingFrom = 0;
    });
    return true;
  }

  /// İskelet görünürken true: ilk içerik solarak gelir, sonra hep anında (F31.7).
  bool _skeletonShown = false;

  /// Veri dalı kurulduktan sonraki karede bayrağı indirir (liste öğesi üretmez).
  Iterable<Widget> _afterSkeleton() {
    if (_skeletonShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _skeletonShown = false);
    }
    return const [];
  }

  /// Izgara kaydırma ipucuna bu açılışta bakıldı mı (bkz. dashboard_shelf).
  bool _gridTipChecked = false;

  void Function() _stopFileDrops = () {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
    homeDoors = this;
    _stopFileDrops = addFileDropHandler((files) {
      // Paylaşılan klasörde dosya akışı notu KENDİ koleksiyonuma açardı (F43.2).
      if (ref.read(selectedSharedFolderProvider) != null) {
        showQuickAddSnack(context.l10n.sharedFolderNoFileDrop);
        return;
      }
      unawaited(useFiles(files));
    });
    // KÖK NEDEN (kasma): burada `_searchFocus.addListener(() => setState(...))`
    // vardı — arama alanına her dokunuş EKRANIN TAMAMINI (ve önbellek
    // payındaki ~130 kartı) yeniden kuruyordu. Odak artık yalnız arama
    // çubuğunu saran `ListenableBuilder` tarafından dinleniyor.
    // Widget/derin bağlantı bu ekran mount olmadan önce bas-başlat istemiş
    // olabilir (uygulama kapalıyken ya da başka ekrandayken). İlk kareden
    // sonra kontrol et; take() varsa asistanı başlatır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScroll();
      _maybeAutostartVoice();
      _maybeOpenQuickDrop();
      // İLK AÇILIŞ İZİN LEVHASI KALKTI (F11.9, kullanıcı kararı 2026-10-31):
      // her izin ilk kullanıldığı yerde, kısa açıklamayla istenir; toplu
      // görünüm Ayarlar → İzinler'de.
      if (!mounted) return;
      final notes = ref.read(notesStreamProvider).value;
      if (notes != null) migrateDefaultNoteSort(ref, notes);
      unawaited(maybeShowDriveOnboarding(context, ref));
    });
    // Kendi e-posta → uid kaydını tazele (kişiler/klasör paylaşımı bunu
    // arar — bkz. FriendsRepository). Ucuz (tek doküman, merge), e-postası
    // olmayan (anonim/yerel) hesapta hiçbir şey yapmaz.
    WidgetsBinding.instance.addObserver(this);
    _syncOwnDirectoryEntry();
  }

  void _syncOwnDirectoryEntry() {
    final repo = ref.read(friendsRepositoryProvider);
    if (repo == null) return;
    unawaited(
      repo
          .syncOwnDirectoryEntry(discoverable: ref.read(discoverableProvider))
          .catchError((Object e, StackTrace s) {
            ErrorLog.record('directory-sync', e, s);
          }),
    );
  }

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
    if (state == AppLifecycleState.resumed) {
      _syncOwnDirectoryEntry();
      // ZAMANLI NOT: arkadayken süresi dolanlar öne gelişte arşive (akış o
      // an yayın yapmayabilir).
      final notes = ref.read(notesStreamProvider).value;
      if (notes != null) {
        unawaited(
          ref.read(notesRepositoryProvider)?.archiveExpired(notes) ??
              Future<void>.value(),
        );
      }
    }
    if (state == AppLifecycleState.paused &&
        _isDefaultHome(
          searchActive: ref.read(searchQueryProvider).trim().isNotEmpty,
        )) {
      final notes = ref.read(filteredNotesProvider).value;
      if (notes != null) unawaited(saveHomeSnapshot(ref, notes));
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

  /// **YUKARIDAN ÇEK → KLASÖR MENÜSÜ** (kullanıcı isteği 2026-11-06, 5. tur):
  /// liste tepedeyken aşağı çekilen mesafe (dp). Eşik [_kFolderPullDistance]
  /// aşılıp bırakılınca sol alttaki klasör düğmesiyle AYNI menü açılır.
  /// `ValueNotifier`: göstergeyi çizer, ekranı yeniden kurmaz.
  final _folderPull = ValueNotifier<double>(0);

  /// Son sürükleme liste tepedeyken mi başladı (KT-22): yalnız öyleyse
  /// aşağı çekiş sayılır.
  bool _pullArmed = false;

  /// Kaydırma bildirimini ayırıcıya bağlar; `false` dönerek bildirimi
  /// yukarıya (iç içe kaydırıcılara) geçirmeye devam eder.
  bool _onGridScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.depth == 0) _trackFolderPull(notification);
    final pixels = notification.metrics.pixels;
    // Kesme noktası geçişinde (F18.11) liste başka bir yerde YENİDEN kurulur
    // (dar: rota sayfası, geniş: sol panel) → konum hafızada taşınır.
    if (notification.depth == 0) {
      DashboardScrollMemory.save(
        _segmentKey,
        pixels,
        notification.metrics.maxScrollExtent,
      );
    }
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

  /// Aşağı çekişi izler: Android'de (sıkıştırma fiziği) tepede çekiş
  /// `OverscrollNotification`, iOS'ta (yaylı) eksi konum olarak gelir.
  /// Yalnız PARMAKLA çekiş sayılır (fırlatmanın tepeye çarpması değil).

  /// Klasör düğmesindeki ve aşağı çekişteki duraklar (ilki "Tümü").
  List<FolderStop> _folderStops(WidgetRef ref) {
    final counts = ref.watch(folderNoteCountsProvider);
    final rawFolders = ref.watch(visibleOrderedFoldersProvider);
    final folders = emptyFoldersLast(
      rawFolders,
      ref.watch(folderSortProvider),
      counts,
    );
    final hub = ref.watch(sharedHubFolderProvider);
    final int inboxCount = ref.watch(
      inboxNotesProvider.select((s) => s.value?.length ?? 0),
    );
    final int sharedCount = ref.watch(sharedNotesVisibleCountProvider);
    final hubCount = inboxCount + sharedCount;
    return [
      FolderStop(
        id: null,
        name: context.l10n.allNotesChip,
        icon: Icons.dashboard_outlined,
      ),
      // GELEN de menüde (kullanıcı bulgusu 2026-11-06: "Gelen klasörü üst
      // alanda görülmüyor") — şeritteki yerinde, gizliyse yok.
      for (final f in hub.hidden
          ? folders
          : withSharedHub(folders, hub, hub.order ?? 0))
        if (f.id == kSharedHubFolderId)
          FolderStop(
            id: kSharedHubFolderId,
            name: f.name.isEmpty ? context.l10n.sharedHubShort : f.name,
            icon: f.icon.isEmpty ? AppIcons.inbox : f.iconData,
            color: f.color == null
                ? Theme.of(context).colorScheme.tertiary
                : f.accent,
            count: hubCount,
          )
        else
          FolderStop(
            id: f.id,
            name: f.name,
            icon: f.iconData,
            color: f.accent,
            count: counts[f.id],
          ),
    ];
  }

  /// Menüde seçili durak: Gelen açıksa onun kimliği.
  String? _currentStopId(WidgetRef ref) => ref.watch(sharedHubOnHomeProvider)
      ? kSharedHubFolderId
      : ref.watch(selectedFolderProvider);


  /// Izgaranın son genişliği ve sütun sayısı (döndürmede oran geri yüklemesi).
  (double, int)? _gridColumnsAt;

  /// Son kurulumda liste bölmesi dar mıydı (F67.3; ⋮ levhası ve mikrofon
  /// okur). Izgaranın LayoutBuilder'ında ölçülür; yüzen düğmeler onun
  /// dışında olduğundan bildirici kare sonunda güncellenir.
  final _narrowPaneN = ValueNotifier<bool>(false);

  /// ⚡ HIZLI EKLE yüzen düğmesi (kullanıcı isteği 2026-11-16: "hızlı ekleyi
  /// yüzen buton yap"). TEK ÖRNEK: ana ekran her kurulduğunda aynı örnek
  /// döner, alt ağaç kurulmaz (bütçe S18/S23/S30/S37/S45); dar bölmede
  /// mikrofonla birlikte gizlenir; ilk kareden sonra belirir (S24).
  late final Widget _quickDropFab = _AfterFirstFrame(
    child: ValueListenableBuilder<bool>(
      valueListenable: _narrowPaneN,
      builder: (_, narrow, button) => Offstage(offstage: narrow, child: button),
      child: const _QuickDropFab(),
    ),
  );

  /// Geniş ekranda sol panelin son sütun kipi (tek sütun = not açık).
  bool? _singleColumn;

  /// Not açılıp kapanınca (geniş ekran) sütun sayısı değişir; piksel konumu
  /// artık aynı kartları göstermez. Önce konum ORANLA taşınır (kabaca aynı
  /// bölge), sonra açılan/kapatılan notun kartı vurgusuz görünür alana
  /// getirilir — "kaldığın yer" (kullanıcı isteği 2026-11-02).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pane = DashboardPaneScope.maybeOf(context);
    final single = pane?.singleColumn ?? false;
    final anchor = pane?.anchorNoteId;
    if (_singleColumn != null && single != _singleColumn && anchor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScroll();
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _revealCard(anchor),
        );
      });
    }
    _singleColumn = single;
  }


  @override
  void dispose() {
    // Dar↔geniş geçişinde yeni örnek önce kurulur, kapıyı ondan alma.
    if (identical(homeDoors, this)) homeDoors = null;
    _stopFileDrops();
    _hoverRetry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _narrowPaneN.dispose();
    _liveQuery.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _gridScrolled.dispose();
    _folderPull.dispose();
    _leavingClear?.cancel();
    _cacheWiden?.cancel();
    _cacheTick.dispose();
    _gridScroll.dispose();
    super.dispose();
  }

  /// Gizli klasörleri göster/sakla. Göstermek KİMLİK DOĞRULAMASI ister
  /// (cihazda kilit yoksa engel çıkarılmaz — bkz. authenticateForNote);
  /// saklamak serbesttir. Açık hâl kalıcı değildir: uygulama yeniden
  /// açıldığında klasörler yine gizlidir.
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

  /// Sürükleme başındaki sıra: hiç yer değişmediyse kayıt yapılmaz.
  List<String>? _dragOriginal;

  /// Sürüklemede parmağın aldığı yol (dp): ~0 = yalnız basılı tutuldu.
  double _dragTravel = 0;

  /// P56: önizleme hedefine histerezis (durma + soğuma + itilen kartı
  /// kilitle) — iki sütun sınırında kart sağ/sol gidip gelmesin.
  final ReorderHoverGate _hoverGate = ReorderHoverGate();
  Timer? _hoverRetry;

  /// Parmak hedefte durdu ama `onMove` yeniden gelmedi (fare/kalem durgun):
  /// süre dolunca aynı hedef bir kez daha denenir.
  void _scheduleHoverRetry(String targetId) {
    _hoverRetry?.cancel();
    final wait = _hoverGate.remaining();
    if (wait == null) return;
    _hoverRetry = Timer(wait, () {
      if (!mounted || _hoverGate.candidate != targetId) return;
      final index = _dragOrder?.indexWhere((n) => n.id == targetId) ?? -1;
      if (index >= 0) _previewCardDrop(index);
    });
  }

  void _leaveCardHover(String targetId) => _hoverGate.leave(targetId);

  void _startCardDrag(String id, List<Note> section) {
    _hoverRetry?.cancel();
    _hoverGate.reset();
    setState(() {
      _dragNoteId = id;
      _dragOrder = List.of(section);
      _dragOriginal = [for (final n in section) n.id];
    });
    _dragTravel = 0;
  }

  /// Parmak [toIndex] hücresinin üzerinde: notu oraya taşıyıp yeniden çiz.
  void _previewCardDrop(int toIndex) {
    final order = _dragOrder;
    final id = _dragNoteId;
    if (order == null || id == null) return;
    // Çöpe yaklaşırken sıra önizlemesi DONAR (kullanıcı bulgusu 2026-11-12:
    // kart küçüldükçe üstüne gelen hücreler değişip notlar hızla zıplıyordu).
    if (DragTrashTarget.pullOf(DragTrashTarget.pull.value) > 0) return;
    final from = order.indexWhere((n) => n.id == id);
    if (from < 0 || from == toIndex) return;
    if (toIndex < 0 || toIndex >= order.length) return;
    final targetId = order[toIndex].id;
    if (!_hoverGate.offer(targetId)) {
      _scheduleHoverRetry(targetId);
      return;
    }
    _hoverRetry?.cancel();
    final next = List.of(order);
    final item = next.removeAt(from);
    next.insert(toIndex.clamp(0, next.length), item);
    setState(() => _dragOrder = next);
    AppHaptics.tick();
  }

  /// Parmak kalktı: GÖRÜNEN sıra kaydedilir. Bırakma bir kartın üstünde
  /// olmasa bile önizlenen sıra korunur — kullanıcı zaten onu görüyordu.
  ///
  /// [onNoMove]: sürükleme başladı ama kart yerinden oynamadı (yalnız basılı
  /// tutuldu) — o zaman sıra kaydedilmez (ölçüt "elle"ye dönmez) ve uzun
  /// basışın olağan işi (seçim) yapılır.
  void _endCardDrag([VoidCallback? onNoMove]) {
    final order = _dragOrder;
    final id = _dragNoteId;
    final original = _dragOriginal;
    _hoverRetry?.cancel();
    _hoverGate.reset();
    setState(() {
      _dragNoteId = null;
      _dragOrder = null;
      _dragOriginal = null;
    });
    if (order == null || id == null) return;
    final unchanged =
        original != null &&
        original.length == order.length &&
        [for (var i = 0; i < order.length; i++) order[i].id == original[i]]
            .every((same) => same);
    if (unchanged) {
      if (_dragTravel < 12) onNoMove?.call();
      return;
    }
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    if (ref.read(noteSortProvider) != NoteSort.manual) {
      ref.read(noteSortProvider.notifier).set(NoteSort.manual);
    }
    repo.reorderNotes(order);
    AppHaptics.heavy();
  }

  bool _hasSoftKeyboardInset(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0;

  @override
  Widget build(BuildContext context) {
    // Arka plan servisleri artık kökte (bkz. `AppServices`, F2.4).

    // Ana ekran mikrofon widget'ından (notlar://voice) gelen bas-başlat
    // isteği: uygulama zaten ana sayfadayken gelirse burada yakalanır.
    // (Uygulama başka ekrandayken/soğuk açılışta gelen istek initState'teki
    // kontrolle okunur; take() çift başlatmayı önler.)
    // Eski "Elle" varsayılanından geçiş (F11.4) — notlar ilk geldiğinde bir kez.
    ref.listen(notesStreamProvider, (_, next) {
      final notes = next.value;
      if (notes != null) migrateDefaultNoteSort(ref, notes);
    });
    // Ctrl+K (bkz. AppShortcuts): arama kutusuna odaklan, yazılı sorguyu
    // seç ki doğrudan üstüne yazılabilsin.
    ref.listen(searchFocusRequestProvider, (_, _) {
      _searchFocus.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
    });
    ref.listen(focusedNoteProvider, (_, id) {
      if (id == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealFocused(id));
    });
    ref.listen(voiceAutostartProvider, (previous, next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeAutostartVoice(),
        );
      }
    });
    ref.listen(quickDropRequestProvider, (previous, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeOpenQuickDrop(),
        );
      }
    });

    final l10n = context.l10n;
    final query = ref.watch(debouncedSearchQueryProvider);
    // Paylaşılan klasör süzgeci (K8): ızgarayı o klasörün notları doldurur.
    final sharedFolder = ref.watch(selectedSharedFolderProvider);
    final notesAsync = ref.watch(filteredNotesProvider);
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
        sharedFolder == null &&
        !ref.watch(showAllNotesProvider) &&
        !ref.watch(sharedHubOnHomeProvider) &&
        ref.watch(selectedTagProvider) == null;
    // **"GELEN" SÜZGECİ** (2026-11-01, bkz. [sharedHubOnHomeProvider]):
    // başka bir klasör/süzgeç/etiket seçilince kendiliğinden kapanır —
    // klasör çipleri, yana çekiş, Süz levhası hepsi bu dört sağlayıcıdan
    // birini değiştirir. Yalnız "seçildi" yönü kapatır: Gelen'e geçerken
    // ötekiler varsayılana döner, o geçiş Gelen'i kapatmaz.
    void closeHub() {
      if (ref.read(sharedHubOnHomeProvider)) {
        ref.read(sharedHubOnHomeProvider.notifier).set(false);
      }
    }

    ref.listen(selectedFolderProvider, (_, next) {
      if (next != null) closeHub();
    });
    ref.listen(selectedSharedFolderProvider, (_, next) {
      if (next != null) closeHub();
    });
    // Paylaşım kaldırıldıysa ya da klasör silindiyse süzgeç kendiliğinden
    // kalkar: ekran ulaşılamayan klasörde boş durmasın.
    ref.listen(sharedFolderRefsProvider, (_, next) {
      final shares = next.value;
      final open = ref.read(selectedSharedFolderProvider);
      if (shares == null || open == null) return;
      if (!shares.any(
        (s) => s.folderId == open.folderId && s.ownerId == open.ownerId,
      )) {
        ref.read(selectedSharedFolderProvider.notifier).set(null);
      }
    });
    ref.listen(showAllNotesProvider, (_, next) {
      if (next) closeHub();
    });
    ref.listen(noteFilterProvider, (_, next) {
      if (next != NoteFilter.all) closeHub();
    });
    ref.listen(selectedTagProvider, (_, next) {
      if (next != null) closeHub();
    });
    // Ana ekrandaki paylaşılanlar bölümünün YERİ (kullanıcı isteği
    // 2026-11-01: "paylaşılan notlar en üstte görülüyor, sıralaması
    // ayarlanabilmeli") — üstte (varsayılan) ya da kendi notlarımın altında.
    final sharedAtBottom = ref.watch(homeSharedAtBottomProvider);
    final hubActive =
        ref.watch(sharedHubOnHomeProvider) &&
        !selectionActive &&
        sharedFolder == null &&
        ref.watch(selectedFolderProvider) == null;
    // **KLASÖR RAFI görünür mü / şerit mi** (2026-11-07). Kural eskisiyle
    // aynı: yalnız kök süzgeçte, aramasız, sıralama dışı; gizlenebilir ama
    // bir klasörün İÇİNDEYKEN hep görünür (kullanıcı isteği 2026-11-06).
    final desktopWeb = WebWorkspaceScope.activeOf(context);
    final sidebarHasFolders = WebWorkspaceScope.sidebarExpandedOf(context);
    final selectedFolderId = ref.watch(selectedFolderProvider);
    final inFolderView =
        hubActive ||
        sharedFolder != null ||
        selectedFolderId != null;
    final hideDuplicateStrip =
        sidebarHasFolders &&
        !inFolderView &&
        !ref.watch(folderShelfExpandedProvider);
    final showShelf =
        !hideDuplicateStrip &&
        !searchActive &&
        !reorderActive &&
        ref.watch(noteFilterProvider) == NoteFilter.all &&
        ref.watch(selectedTagProvider) == null &&
        (!ref.watch(homeFolderStripHiddenProvider) || inFolderView);
    // Şerit, yana kaydırılan ızgaranın DIŞINDA tek bir örnek (kullanıcı
    // 2026-11-07: "sağa sola kaydırıp klasör geçişinde üst klasör satırı çok
    // hareket ediyor"). KÖK NEDEN: şerit ızgaranın (segmentKey'li
    // CustomScrollView) bir sliver'ıydı → çekişte parmakla birlikte kayıyor,
    // geçişte ızgarayla solup öbür yandan giriyor, yeni örneğin yatay
    // konumu 0'dan başlayıp seçili çipe doğru yeniden kayıyordu (üç ayrı
    // hareket). Artık şerit yerinde durur; yalnız vurgu değişir ve çip
    // görünür alanda değilse en kısa yoldan kaydırılır.
    final shelfAsStrip =
        showShelf &&
        (inFolderView || !ref.watch(folderShelfExpandedProvider));
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

    // Zemin katmanları (renk/desen/görsel) ve gezinme çubuğu payı. Pay
    // `viewPadding`'den: klavye açılınca DEĞİŞMEZ (yalnız döndürmede) — ana
    // ekran klavye karelerinde yeniden kurulmaz.
    final backgroundLayers = _dashboardBackground(ref);
    final hasBackground = backgroundLayers.isNotEmpty;
    final navInset = MediaQuery.viewPaddingOf(context).bottom;
    final page = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          final folder = ref.read(selectedSharedFolderProvider);
          if (folder == null) {
            unawaited(createNote(NoteType.text));
            return;
          }
          final role =
              (ref.read(sharedFolderRefsProvider).value ??
                      const <SharedFolderRef>[])
                  .where((s) => s.folderId == folder.folderId)
                  .firstOrNull
                  ?.role ??
              FolderRole.both;
          unawaited(createInSharedFolder(context, ref, folder, role));
        },
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
          body: Stack(
            children: [
              // Ana ekran ZEMİN görseli (Ayarlar → Görünüm). Kart
              // ızgarasının arkasında durur; görünürlük ayarı okunurluğu
              // korumak için varsayılan olarak düşüktür.
              // TAM EKRAN (kullanıcı 2026-11-25: "arka plan zemini tüm ekranı
              // kaplamıyor, üst ve alt alan kaplanmalı"): zemin eskiden
              // `SafeArea`nın İÇİNDEYDİ — durum çubuğu ve alttaki gezinme
              // çubuğu şeridi düz renk kalıyordu, arama çubuğu da (AppBar)
              // üstüne kendi zeminini boyuyordu. Zemin artık ekranın tamamında;
              // arama çubuğu zemin varken saydam, ızgara gezinme çubuğunun
              // altına kadar uzanır (son kart [navInset] kadar yukarı kayabilir).
              ...backgroundLayers,
              SafeArea(
                bottom: false,
                child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Sütun sayısı: kullanıcı iki parmakla zoom yaptıysa onun
                    // seçimi (1–4), yoksa ekran genişliğinden otomatik.
                    final manualColumns = ref.watch(gridColumnsProvider);
                    // Not açıkken solda dar liste: TEK sütun (kullanıcı
                    // isteği 2026-11-02, bkz. kNoteSplitBreakpoint); ayraç
                    // sürüklenip genişletilince 2–3 sütun (tablet isteği
                    // 2026-11-09).
                    // Mini pano (P59): kıstırma/Ctrl+tekerlek ölçeği kartları
                    // büyütür, sütun genişliğe göre 1–4.
                    final paneMode = DashboardPaneScope.singleColumnOf(context);
                    final columns = paneMode
                        ? paneColumnsFor(
                            constraints.maxWidth,
                            ref.watch(paneCardScaleProvider),
                          )
                        : manualColumns > 0
                        ? manualColumns
                        : desktopWeb
                        ? (constraints.maxWidth / 270).floor().clamp(2, 5)
                        : (constraints.maxWidth / 220).floor().clamp(2, 6);
                    // Telefon döndürülünce (F66.7'den beri yatayda da aynı
                    // örnek kalır) sütun sayısı değişir; piksel konumu başka
                    // kartlara denk gelir → ORAN yeniden uygulanır (F18.11).
                    // DAR LİSTE BÖLMESİ (F67.3, B15): bölünmüş görünümde
                    // liste < 420 dp iken şeritler çizilmez, arama hapı
                    // kısalır (AI ve süz ⋮'e iner), mikrofon gizlenir.
                    // Ağaç şekli sabit: Offstage (State korunur).
                    final narrowPane =
                        DashboardPaneScope.singleColumnOf(context) &&
                        constraints.maxWidth < kNarrowListPane;
                    if (narrowPane != _narrowPaneN.value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _narrowPaneN.value = narrowPane;
                      });
                    }
                    final lastCols = _gridColumnsAt;
                    _gridColumnsAt = (constraints.maxWidth, columns);
                    if (lastCols != null &&
                        lastCols.$1 != constraints.maxWidth &&
                        lastCols.$2 != columns) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _restoreScroll(),
                      );
                    }
                    // Masonry hücre genişliği: sürükle-sırala sırasında taşınan
                    // notun "hayalet" kopyası (feedback) bu genişlikte çizilir.
                    // Izgara payları `kGridInset` / `kGridGap`.
                    final desktopGutter =
                        desktopWeb && !paneMode ? AppSpace.m : 0.0;
                    final cellWidth =
                        (constraints.maxWidth -
                            2 * desktopGutter -
                            2 * kGridInset -
                            kGridGap * (columns - 1)) /
                        columns;
                    Widget padDesktopGutter(Widget child) => desktopGutter > 0
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: desktopGutter,
                            ),
                            child: child,
                          )
                        : child;
                    // Aktif segment (filtre|klasör|etiket) anahtarı: değişince
                    // AnimatedSwitcher yeni görünümü kaydırarak getirir (madde 2).
                    // Arama sorgusu anahtara DAHİL DEĞİL — her tuşta yeniden
                    // animasyon tetiklenmez.
                    final segmentKey =
                        '${ref.watch(noteFilterProvider)}'
                        '|${ref.watch(selectedFolderProvider) ?? ''}'
                        '|${sharedFolder?.folderId ?? ''}'
                        '|${ref.watch(selectedTagProvider) ?? ''}'
                        '|${hubActive ? 'hub' : ''}';
                    if (segmentKey != _segmentKey && _segmentKey.isNotEmpty) {
                      _holdNarrowCache(segmentKey);
                    }
                    _segmentKey = segmentKey;
                    // Başlık (arama/seçim barı + filtre çipleri) kaydırma
                    // görünümünün DIŞINDA sabit durur: liste kayarken çipler
                    // yerinde kalır; filtre değişim animasyonu yalnız not
                    // listesine uygulanır (arama barı artık birlikte kaymaz).
                    // Dar sütunda kart kompakt (bkz. [NoteCardWidth]).
                    return NoteCardWidth(
                      width: cellWidth,
                      child: Column(
                      children: [
                        _buildDashboardAppBar(
                          l10n,
                          reorderActive: reorderActive,
                          selectionActive: selectionActive,
                          visibleIds: visibleIds,
                          notesAsync: notesAsync,
                          desktopWeb: desktopWeb,
                          narrowPane: narrowPane,
                          sharedFolder: sharedFolder,
                          hubActive: hubActive,
                          selectedFolderId: selectedFolderId,
                          hasHiddenFolders: hasHiddenFolders,
                          hiddenRevealed: hiddenRevealed,
                          hasBackground: hasBackground,
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
                        // TAKVİM ŞERİDİ (2026-11-08, takvim zemininin yerine):
                        // bugünden itibaren 10 gün; kapalıyken tek ince satır.
                        // YENİ SÜRÜM ŞERİDİ (2026-11-10): kalıcı, kapatılamaz;
                        // yeni sürüm yokken sıfır yer.
                        const UpdateBanner(),
                        if (desktopWeb && !narrowPane)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpace.xl,
                              AppSpace.s,
                              AppSpace.xl,
                              AppSpace.xs,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppTokens.of(context).card,
                                borderRadius: BorderRadius.circular(AppRadius.m),
                                border: Border.all(
                                  color: AppTokens.of(context).hairline,
                                ),
                              ),
                              child: const HomeCalendarStrip(),
                            ),
                          )
                        else
                          Offstage(
                            offstage: narrowPane,
                            child: const HomeCalendarStrip(),
                          ),
                        // Zamanı gelen hatırlatıcı/görev şeridi (2026-11-08).
                        Offstage(
                          offstage: narrowPane,
                          child: const DueBanner(),
                        ),
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
                        if (shelfAsStrip)
                          _folderStrip(
                            ref.watch(visibleOrderedFoldersProvider),
                            selectedFolderId: ref.watch(selectedFolderProvider),
                            sharedFolder: sharedFolder,
                          ),
                        _HeaderSeparator(scrolled: _gridScrolled),
                        Expanded(
                          // İki parmakla zoom: 1 → 2 → 3 → 4 sütun arasında
                          // geçiş. Ölçek jesti tek parmakta hiç tepki vermez
                          // (pointerCount kontrolü), böylece içteki yatay
                          // çekiş ve dikey kaydırma olduğu gibi çalışır.
                          child: padDesktopGutter(
                            FolderPullIndicator(
                          progress: _folderPull,
                          icon: switch (ref
                              .watch(homePullGestureProvider)
                              .kind) {
                            HomeGestureKind.calendar => Icons.calendar_month_outlined,
                            HomeGestureKind.note => Icons.description_outlined,
                            _ => Icons.folder_outlined,
                          },
                          distance: _kFolderPullDistance,
                          child: PinchColumns(
                            columns: columns,
                            onCommit: paneMode
                                ? (c) => ref
                                      .read(paneCardScaleProvider.notifier)
                                      .setColumns(c, constraints.maxWidth)
                                : ref.read(gridColumnsProvider.notifier).set,
                            child: NotificationListener<ScrollNotification>(
                              onNotification: _onGridScroll,
                              child: FolderSwipe(
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
                                enabled:
                                    !selectionActive &&
                                    !reorderActive &&
                                    _dragNoteId == null &&
                                    (ref.watch(swipeModeProvider) !=
                                            SwipeMode.off ||
                                        ref
                                                .watch(
                                                  homeSwipeRightGestureProvider,
                                                )
                                                .kind !=
                                            HomeGestureKind.none),
                                nextLabel: _swipeStopLabel,
                                nextIcon: _swipeStopIcon,
                                onCommit: _cycleFilterFolder,
                                continuesInPlace: _continueSwipe,
                                child: AnimatedSwitcher(
                                  duration: AppMotion.of(
                                    context,
                                    AppMotion.medium,
                                  ),
                                  switchInCurve: AppMotion.curveOf(
                                    context,
                                    AppMotion.enter,
                                  ),
                                  switchOutCurve: AppMotion.curveOf(
                                    context,
                                    AppMotion.exit,
                                  ),
                                  transitionBuilder: (child, animation) {
                                    // Çekiş yönüne göre yumuşak kaydır + soldur.
                                    final incoming =
                                        child.key == ValueKey(segmentKey);
                                    // Hareketi azalt: yalnız solma (F34.7).
                                    final dir = !motionOf(context)
                                        ? 0.0
                                        : _swipeForward
                                        ? 1.0
                                        : -1.0;
                                    final rtl =
                                        Directionality.of(context) ==
                                        TextDirection.rtl;
                                    // Ekranda hareket yönü (sola = -1).
                                    final move = -dir * (rtl ? -1 : 1);
                                    // Çekişle ayrılan görünüm parmağın
                                    // bıraktığı yerden ekran dışına doğru
                                    // akar; gelen diğer kenardan çakışmadan
                                    // girer.
                                    final from =
                                        !incoming &&
                                            child.key == ValueKey(_leavingKey)
                                        ? _leavingFrom
                                        : null;
                                    final Offset begin;
                                    final Offset end;
                                    if (from != null) {
                                      begin = Offset(from + move * 0.55, 0);
                                      end = Offset(from, 0);
                                    } else {
                                      final swiped =
                                          incoming && _leavingKey != null;
                                      begin = Offset(
                                        (incoming ? -move : move) *
                                            (swiped ? 0.52 : 0.14),
                                        0,
                                      );
                                      end = Offset.zero;
                                    }
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween(
                                          begin: begin,
                                          end: end,
                                        ).animate(animation),
                                        // F26.4: ayrılan ızgara donmuş
                                        // görüntü (her karede rasterleşmez).
                                        child: SnapshotWhenLeaving(
                                          leaving: !incoming,
                                          child: child,
                                        ),
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
                                  child: _GridScrollView(
                                    key: ValueKey(segmentKey),
                                    // Az notta da tepeden aşağı çekilebilsin
                                    // (klasör menüsü — [_trackFolderPull]).
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    // "Başa dön" düğmesi buradan tepeye döner.
                                    controller: _gridScroll,
                                    tick: _cacheTick,
                                    // Her sorguda sonuç ızgarası baştan kurulur,
                                    // açılışın ilk içerik karesi ve yeni gelen bölüm
                                    // de: ekran dışı kart bekletmesin.
                                    narrow: () =>
                                        searchActive ||
                                        notesAsync.isLoading ||
                                        _freshSegment == segmentKey,
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
                                      //
                                      // 2026-11-07: ŞERİT hâli artık burada
                                      // DEĞİL, ızgaranın üstünde sabit (bkz.
                                      // [shelfAsStrip]); burada yalnız kök
                                      // görünümün KARO rafı kalır.
                                      if (showShelf && !shelfAsStrip)
                                        _folderShelf(
                                          columns,
                                          selectedFolderId: ref.watch(
                                            selectedFolderProvider,
                                          ),
                                          hubSelected: hubActive,
                                          sharedFolder: sharedFolder,
                                        ),
                                      ..._buildDashboardGridSlivers(
                                        context,
                                        searchActive: searchActive,
                                        reorderActive: reorderActive,
                                        selectionActive: selectionActive,
                                        hubActive: hubActive,
                                        sharedFolder: sharedFolder,
                                        sharedAtBottom: sharedAtBottom,
                                        columns: columns,
                                        cellWidth: cellWidth,
                                        selectedFolderId: selectedFolderId,
                                        query: query,
                                        notesAsync: notesAsync,
                                        navInset: navInset,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ),
                          ),
                        ),
                      ],
                    ));
                  },
                ),
                ..._buildDashboardFloatingOverlays(
                  l10n,
                  navInset: navInset,
                  selectionActive: selectionActive,
                  sharedFolder: sharedFolder,
                ),
              ],
            ),
              ),
            ],
          ),
        ),
      ),
    );

    // Geri tuşu: seçim ya da sıralama modu açıkken uygulamadan ÇIKMAZ, önce
    // modu kapatır. Ana ekran yığının kökü olduğu için sistem geri tuşu
    // doğrudan uygulamayı kapatıyordu; kullanıcı yanlışlıkla bir notu seçince
    // (uzun basış) seçimi kapatmanın tek yolu ekrandaki "×" idi.
    // KLASÖR SÜZGECİ (2026-10-28): klasör artık ana ekranın süzgeci; geri
    // tuşu önce klasörden çıkar (eski klasör sayfasındaki gibi).
    final inFolder =
        ref.watch(selectedFolderProvider) != null ||
        sharedFolder != null ||
        ref.watch(sharedHubOnHomeProvider);
    // Arama da mod: geri önce aramayı kapatır (cihaz turu 2026-11-05: uygulamadan
    // çıkıyor, yeniden açılınca süzgeç duruyordu).
    final searching = ref.watch(
      searchQueryProvider.select((q) => q.isNotEmpty),
    );
    return PopScope(
      canPop: !selectionActive && !reorderActive && !inFolder && !searching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (BackCloses.handling(context)) return;
        // "+" paneli açıksa geri tuşu ONUN: Flutter aynı rotadaki tüm
        // PopScope geri çağrılarını çalıştırıyor, yoksa tek geri hem paneli
        // hem seçim modunu birden kapatırdı.
        if (quickAddPanelOpen.value) return;
        if (selectionActive) {
          ref.read(selectedNoteIdsProvider.notifier).clear();
        } else if (reorderActive) {
          ref.read(reorderModeProvider.notifier).set(false);
        } else if (searching) {
          _searchController.clear();
          ref.read(searchQueryProvider.notifier).set('');
          FocusManager.instance.primaryFocus?.unfocus();
        } else if (inFolder) {
          _swipeForward = false;
          ref.read(selectedFolderProvider.notifier).set(null);
          ref.read(selectedSharedFolderProvider.notifier).set(null);
          ref.read(sharedHubOnHomeProvider.notifier).set(false);
        }
      },
      // Editör (ya da bir bölüm) ana ekranı TAMAMEN örtünce ızgara yeniden
      // kurulmaz; görünür olunca bir kez güncellenir (bkz. FreezeWhenHidden).
      child: FreezeWhenHidden(child: page),
    );
  }

}
