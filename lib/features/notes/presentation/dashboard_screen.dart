import '../../../app/window_class.dart';
import '../../gmail/data/gmail_auth.dart';
import '../../../core/utils/web_file_drop.dart';
import '../../../core/app_icons.dart';
import '../../../core/app_update.dart' show UpdateBanner;
import 'dart:async';
import 'dart:io';

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
import '../../../app/app_frame.dart';
import '../../../app/router.dart';
import '../../../app/split_shell.dart';
import '../../../app/theme/note_colors.dart';
import 'dart:math' as math;

import '../../../app/theme/app_tokens.dart';
import '../../../core/a11y/motion.dart';
import '../../../core/widgets/snapshot_when_leaving.dart';
import '../../../core/widgets/action_menu_sheet.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import '../../../core/tips.dart';
import '../../../core/widgets/customizable.dart';
import '../../../core/widgets/freeze_when_hidden.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/connectivity.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/gemini_service.dart';
import '../../ai/data/semantic_search.dart';
import '../../folders/data/folder_order.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/data/folder_activity.dart';
import '../../folders/domain/note_folder.dart';
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
import '../../calendar/presentation/home_calendar_strip.dart';
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
import 'home_snapshot.dart';
import 'folder_hold_button.dart';
import 'note_card.dart';
import 'note_grid.dart';
import 'shared_notes_screen.dart';
import '../../inbox/presentation/shared_hub_screen.dart' show sharedHubPlaceholder, sharedHubSlivers, showSharedHubOnHome;
import 'notes_providers.dart';
import 'quick_add_actions.dart';
import 'quick_add_fab.dart';
import 'voice_assistant.dart';
import 'voice_assistant_widgets.dart';
import 'voice_capture_sheet.dart';
import 'drive_ui.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/friendly_error.dart';

import 'dashboard_scroll_memory.dart';

part 'dashboard_widgets.dart';
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
/// KÖK NEDEN (aşağı kaydırırken liste yukarı sıçraması, tarihçe): masonry
/// toplam uzunluğu yerleşmiş kartların ortalamasından TAHMİN ediyordu.
/// 2026-10-16: masonry kalktı (tembel deterministik sütunlar) — pay artık
/// yalnız hızlı kaydırma için.
class _GridScrollView extends CustomScrollView {
  const _GridScrollView({
    super.key,
    super.controller,
    super.physics,
    required super.slivers,
    required this.tick,
    required this.narrow,
  });

  final Listenable tick;
  final bool Function() narrow;

  @override
  StatelessElement createElement() => _GridScrollElement(this);

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) => Viewport(
    axisDirection: axisDirection,
    offset: offset,
    slivers: slivers,
    scrollCacheExtent: ScrollCacheExtent.pixels(
      narrow() ? 250 : _kGridCacheExtent,
    ),
  );
}

class _GridScrollElement extends StatelessElement {
  _GridScrollElement(_GridScrollView super.widget);

  // [tick] ekranın ömrü boyunca aynı nesne: güncellemede yeniden bağlanmaz.
  Listenable get _tick => (widget as _GridScrollView).tick;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _tick.addListener(markNeedsBuild);
  }

  @override
  void unmount() {
    _tick.removeListener(markNeedsBuild);
    super.unmount();
  }
}

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
  final Map<String, (Note, bool, Widget)> _cardCache = {};

  /// Kartların izlediği canlı arama sorgusu (F21.6).
  final _liveQuery = ValueNotifier<String>('');

  /// [searching] ızgaranın GECİKTİRİLMİŞ arama durumudur (hücre sarmalayıcısı
  /// da onunla değişir): anlık sorguyla kurulunca ilk harfte kartlar iki kez
  /// kuruluyordu — önce tuşta, sonra gecikme dolup sarmalayıcı değişince
  /// (P46, bütçe S21: harf başına 114 → 57).
  Widget _cachedCard(Note note, {required bool searching}) {
    final hit = _cardCache[note.id];
    if (hit != null && identical(hit.$1, note) && hit.$2 == searching) {
      return hit.$3;
    }
    final card = NoteCard(
      note: note,
      liveQuery: searching ? _liveQuery : null,
      frame: (child, {required focused, required open}) => _FocusHalo(
        focused: focused,
        open: open,
        noteId: note.id,
        child: child,
      ),
    );
    _cardCache[note.id] = (note, searching, card);
    return card;
  }

  /// Yeni gelen bölümün (süzgeç|klasör|etiket) anahtarı: geçiş sürerken
  /// ızgarası dar kaydırma payıyla kurulur (P46, bütçe S23). Eskiden gelen
  /// ızgara ilk karesinde görünen kartlara ek 1600 px'lik payı da kuruyordu
  /// (geçişin en ağır karesi); pay artık geçiş bitince, boşta genişler.
  String? _freshSegment;
  Timer? _cacheWiden;
  final _cacheTick = ValueNotifier<int>(0);

  void _holdNarrowCache(String segmentKey) {
    _freshSegment = segmentKey;
    _cacheWiden?.cancel();
    _cacheWiden = Timer(AppMotion.medium + AppMotion.short, () {
      _freshSegment = null;
      _cacheTick.value++;
    });
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
      // İLK AÇILIŞ İZİN LEVHASI KALKTI (F11.9, kullanıcı kararı 2026-10-31):
      // her izin ilk kullanıldığı yerde, kısa açıklamayla istenir; toplu
      // görünüm Ayarlar → İzinler'de.
      if (!mounted) return;
      final notes = ref.read(notesStreamProvider).value;
      if (notes != null) migrateDefaultNoteSort(ref, notes);
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
    if (state == AppLifecycleState.paused &&
        _isDefaultHome(
          searchActive: ref.read(searchQueryProvider).trim().isNotEmpty,
        )) {
      final notes = ref.read(filteredNotesProvider).value;
      if (notes != null) unawaited(saveHomeSnapshot(ref, notes));
    }
  }

  /// Ana ekranın süzgeçsiz hâli mi: özet yalnız bu görünümün karşılığı (F25.2).
  bool _isDefaultHome({required bool searchActive}) =>
      !searchActive &&
      ref.read(noteFilterProvider) == NoteFilter.all &&
      ref.read(selectedTagProvider) == null &&
      ref.read(selectedFolderProvider) == null &&
      ref.read(selectedSharedFolderProvider) == null;

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

  /// **YUKARIDAN ÇEK → KLASÖR MENÜSÜ** (kullanıcı isteği 2026-11-06, 5. tur):
  /// liste tepedeyken aşağı çekilen mesafe (dp). Eşik [_kFolderPullDistance]
  /// aşılıp bırakılınca sol alttaki klasör düğmesiyle AYNI menü açılır.
  /// `ValueNotifier`: göstergeyi çizer, ekranı yeniden kurmaz.
  final _folderPull = ValueNotifier<double>(0);

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
  void _trackFolderPull(ScrollNotification n) {
    final m = n.metrics;
    var pull = _folderPull.value;
    if (n is OverscrollNotification) {
      if (n.dragDetails != null && n.overscroll < 0 && _folderPullAllowed()) {
        pull -= n.overscroll;
      }
    } else if (n is ScrollUpdateNotification) {
      if (n.dragDetails == null) {
        pull = 0;
      } else if (m.pixels < m.minScrollExtent) {
        pull = _folderPullAllowed() ? m.minScrollExtent - m.pixels : 0;
      } else if (pull > 0) {
        // Çekip geri itti: mesafe azalır.
        pull = (pull - (n.scrollDelta ?? 0)).clamp(0, double.infinity);
      }
    } else if (n is ScrollEndNotification) {
      final open = pull >= _kFolderPullDistance;
      _setFolderPull(0);
      if (open) _openFolderMenu();
      return;
    }
    _setFolderPull(pull);
  }

  void _setFolderPull(double pull) {
    final before = _folderPull.value >= _kFolderPullDistance;
    final after = pull >= _kFolderPullDistance;
    if (after && !before) unawaited(HapticFeedback.selectionClick());
    if (_folderPull.value != pull) _folderPull.value = pull;
  }

  /// Klasör düğmesinin görünmediği kiplerde (seçim, paylaşılan klasör,
  /// arama, sıralama, kart sürükleme) çekiş menü açmaz.
  bool _folderPullAllowed() =>
      ref.read(selectedNoteIdsProvider).isEmpty &&
      !ref.read(reorderModeProvider) &&
      _dragNoteId == null &&
      ref.read(selectedSharedFolderProvider) == null &&
      ref.read(searchQueryProvider).trim().isEmpty;

  /// Klasör düğmesindeki ve aşağı çekişteki duraklar (ilki "Tümü").
  List<FolderStop> _folderStops(WidgetRef ref) {
    final counts = ref.watch(folderNoteCountsProvider);
    final folders = ref.watch(visibleOrderedFoldersProvider);
    final hub = ref.watch(sharedHubFolderProvider);
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

  void _openFolderMenu() {
    if (!mounted || !_folderPullAllowed()) return;
    unawaited(
      openFolderMenu(
        context,
        stops: _folderStops(ref),
        currentId: _currentStopId(ref),
        onOpen: () => unawaited(context.push('/folders')),
        onSelect: _selectFolderFromHold,
        // Ekle / sırala · sil menünün içinden; iş bitince menü yeniden açılır
        // (kullanıcı o ekranda kalır, yeni sıra/klasör hemen görünür).
        onNewFolder: () => unawaited(
          showFolderEditorDialog(context, ref).then((_) => _openFolderMenu()),
        ),
        onEditFolders: () => unawaited(
          showFolderOrderSheet(context).then((_) => _openFolderMenu()),
        ),
      ),
    );
  }

  /// Telefon ↔ geniş ekran geçişinde (F18.11) önceki örneğin kaldığı yere
  /// döner — yalnız AYNI bölümdeyse. İçerik henüz ölçülmediyse bir kare daha
  /// beklenir (en çok birkaç kez).
  void _restoreScroll([int tries = 0, double? lastExtent]) {
    if (!mounted || !_gridScroll.hasClients) return;
    final positions = _gridScroll.positions.toList();
    if (positions.length != 1) return;
    final p = positions.single;
    final extent = p.maxScrollExtent;
    final target = DashboardScrollMemory.restoreOffset(_segmentKey, extent);
    if (target == null) return;
    p.jumpTo(target.clamp(0.0, extent));
    // KÖK NEDEN (cihaz turu 2026-11-05, telefonu çevirince liste tepeye
    // atlıyordu): tembel listede maxScrollExtent ilk karelerde yalnız kurulan
    // kartlardan TAHMİN; oran o küçük tahmine uygulanınca liste başa yakın
    // kalıyordu. Tahmin oturana dek aynı oran yeniden uygulanır.
    if (tries < 8 && extent != lastExtent) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restoreScroll(tries + 1, extent),
      );
    }
  }

  /// Izgaranın son genişliği ve sütun sayısı (döndürmede oran geri yüklemesi).
  (double, int)? _gridColumnsAt;

  /// Son kurulumda liste bölmesi dar mıydı (F67.3; ⋮ levhası ve mikrofon
  /// okur). Izgaranın LayoutBuilder'ında ölçülür; yüzen düğmeler onun
  /// dışında olduğundan bildirici kare sonunda güncellenir.
  final _narrowPaneN = ValueNotifier<bool>(false);
  bool get _narrowPane => _narrowPaneN.value;

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

  /// [noteId]'nin kartı kuruluysa (kaydırma önbelleğinde) görünür alana
  /// kaydırır. Kartlar `ValueKey(note.id)` ile sarılı (dashboard_slivers).
  void _revealCard(String noteId) {
    if (!mounted) return;
    final key = ValueKey(noteId);
    Element? found;
    void visit(Element e) {
      if (found != null) return;
      if (e.widget.key == key) {
        found = e;
        return;
      }
      e.visitChildren(visit);
    }

    context.visitChildElements(visit);
    final card = found;
    if (card == null) return;
    Scrollable.ensureVisible(
      card,
      alignment: 0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Izgarayı tepeye döndürür. `animateTo` birden çok konumla çalışır
  /// (bkz. [_gridScroll]).
  /// Geniş ekranda sağda açık not varsa kapatıp `/`'a döner (🏠 şeridi).
  bool _closeOpenNote() {
    final router = GoRouter.of(context);
    if (!isNoteLocation(currentLocation(router))) return false;
    goHome(ref, router);
    return true;
  }

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
    // Dar↔geniş geçişinde yeni örnek önce kurulur, kapıyı ondan alma.
    if (identical(homeDoors, this)) homeDoors = null;
    _stopFileDrops();
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
  /// Tümü görünümünde sağa çekiş (geri yön) takvimi açar (2026-11-06).
  bool _swipeOpensCalendar(int direction) => swipeOpensCalendar(
    enabled: ref.read(swipeLeftCalendarProvider),
    direction: direction,
    atAllNotes:
        ref.read(selectedFolderProvider) == null &&
        ref.read(selectedSharedFolderProvider) == null &&
        !ref.read(sharedHubOnHomeProvider) &&
        ref.read(selectedTagProvider) == null &&
        ref.read(noteFilterProvider) == NoteFilter.all,
  );

  void _cycleFilterFolder(int direction) {
    if (_swipeOpensCalendar(direction)) {
      HapticFeedback.selectionClick();
      unawaited(context.push('/calendar'));
      return;
    }
    final stop = _swipeStop(direction);
    if (stop == null) return;
    // Geçiş animasyonunun yönünü çekiş yönüne göre ayarla (madde 2).
    _swipeForward = direction > 0;
    // Paylaşılan klasör de bir durak (K8), kendi klasör gibi.
    final sharedStop = _sharedStopOf(stop.folderId);
    if (sharedStop != null) {
      openFolder(context, sharedStop.folderId, ownerId: sharedStop.ownerId);
      HapticFeedback.selectionClick();
      return;
    }
    ref.read(selectedSharedFolderProvider.notifier).set(null);
    if (stop.folderId == kSharedHubFolderId) {
      ref.read(sharedHubOnHomeProvider.notifier).set(false);
      showSharedHubOnHome(context);
      HapticFeedback.selectionClick();
      return;
    }
    ref.read(sharedHubOnHomeProvider.notifier).set(false);
    ref.read(selectedFolderProvider.notifier).set(stop.folderId);
    ref.read(noteFilterProvider.notifier).set(stop.filter);
    ref.read(selectedTagProvider.notifier).set(stop.tag);
    HapticFeedback.selectionClick();
  }

  /// Klasör düğmesinden seçim: süzgeçsiz o klasör (Tümü = null).
  void _selectFolderFromHold(String? folderId) {
    _swipeForward = true;
    if (folderId == kSharedHubFolderId) {
      if (!ref.read(sharedHubOnHomeProvider)) showSharedHubOnHome(context);
      HapticFeedback.selectionClick();
      return;
    }
    ref.read(selectedSharedFolderProvider.notifier).set(null);
    ref.read(sharedHubOnHomeProvider.notifier).set(false);
    ref.read(selectedFolderProvider.notifier).set(folderId);
    ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
    ref.read(selectedTagProvider.notifier).set(null);
    HapticFeedback.selectionClick();
  }

  SharedFolderRef? _sharedStopOf(String? stopId) => stopId == null
      ? null
      : (ref.read(sharedFolderRefsProvider).value ?? const <SharedFolderRef>[])
            .where((s) => sharedFolderStopId(s) == stopId)
            .firstOrNull;

  /// Çekişin kenarında görünen sonraki durağın adı (F39.3); durak yoksa null.
  String? _swipeStopLabel(int direction) {
    if (_swipeOpensCalendar(direction)) return context.l10n.calendarTitle;
    final stop = _swipeStop(direction);
    if (stop == null) return null;
    final l10n = context.l10n;
    if (stop.folderId == kSharedHubFolderId) return l10n.sharedHubShort;
    final sharedStop = _sharedStopOf(stop.folderId);
    if (sharedStop != null) return sharedStop.name;
    if (ref.read(swipeModeProvider) == SwipeMode.filters) {
      return stop.tag != null
          ? '#${stop.tag}'
          : stop.filter == NoteFilter.all
          ? l10n.allNotesChip
          : filterLabel(l10n, stop.filter);
    }
    final id = stop.folderId;
    if (id == null) return l10n.allNotesChip;
    for (final f in ref.read(visibleOrderedFoldersProvider)) {
      if (f.id == id) return f.name;
    }
    return null;
  }

  HomeSwipeStop? _swipeStop(int direction) {
    final suppressed = ref.read(suppressedFolderIdsProvider);
    final notes = [
      for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
        if (n.archivedAt == null &&
            !n.isEmpty &&
            !suppressed.contains(n.folderId))
          n,
    ];
    final mode = ref.read(swipeModeProvider);
    final hub = ref.read(sharedHubFolderProvider);
    final folderIds = [
      // Şeritle AYNI sıra: boş klasörler sonda (B3).
      for (final f in emptyFoldersLast(
        ref.read(visibleOrderedFoldersProvider),
        ref.read(folderSortProvider),
        ref.read(folderNoteCountsProvider),
      ))
        f.id,
    ];
    // Paylaşılanlar şeritteki sırayla: okunmamışı olan başta, kalanı sonda.
    final shares =
        ref.read(sharedFolderRefsProvider).value ?? const <SharedFolderRef>[];
    bool hot(SharedFolderRef s) =>
        ref.read(
          folderUnreadProvider((ownerId: s.ownerId, folderId: s.folderId)),
        ) >
        0;
    final selectedShared = ref.read(selectedSharedFolderProvider);
    return nextHomeSwipeStop(
      mode: mode,
      notes: notes,
      // GELEN de bir durak (2026-11-02), gizli değilse şeritteki yerinde.
      folderIds: [
        for (final s in shares)
          if (hot(s)) sharedFolderStopId(s),
        ...hub.hidden
            ? folderIds
            : withSharedHub(folderIds, kSharedHubFolderId, hub.order ?? 0),
        for (final s in shares)
          if (!hot(s)) sharedFolderStopId(s),
      ],
      folderId: mode == SwipeMode.filters
          ? ref.read(selectedFolderProvider)
          : selectedShared != null
          ? '${selectedShared.ownerId}/${selectedShared.folderId}'
          : ref.read(sharedHubOnHomeProvider)
          ? kSharedHubFolderId
          : ref.read(selectedFolderProvider),
      filter: ref.read(noteFilterProvider),
      tag: ref.read(selectedTagProvider),
      direction: direction,
    );
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

  /// Sürükleme başındaki sıra: hiç yer değişmediyse kayıt yapılmaz.
  List<String>? _dragOriginal;

  /// Sürüklemede parmağın aldığı yol (dp): ~0 = yalnız basılı tutuldu.
  double _dragTravel = 0;

  void _startCardDrag(String id, List<Note> section) {
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
    final next = List.of(order);
    final item = next.removeAt(from);
    next.insert(toIndex.clamp(0, next.length), item);
    setState(() => _dragOrder = next);
    HapticFeedback.selectionClick();
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
    HapticFeedback.mediumImpact();
  }

  /// Sürüklenen not "silmeye hazır" çöp hedefine bırakıldı (F60.S9).
  ///
  /// Bırakma kartın `onDragEnd`'inden ÖNCE gelir: önizlenen sıra burada
  /// atılır ki [_endCardDrag] çöpe giden notun sürükleme yolunu "yeni sıra"
  /// diye kaydetmesin. Silme olağan yoldan: kilitli not doğrulama ister,
  /// kart küçülüp solar ([leavingNotesProvider]), geri al çubuğu çıkar.
  Future<void> _trashDraggedNote(String id) async {
    _dragOrder = null;
    _dragOriginal = null;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    final note = _selectedNotes({id}).firstOrNull;
    if (note == null) return;
    if (note.locked && !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    if (!mounted) return;
    if (ref.read(selectedNoteIdsProvider).contains(id)) {
      ref.read(selectedNoteIdsProvider.notifier).toggle(id);
    }
    await ref.read(leavingNotesProvider.notifier).leave([id], () {
      repo.softDelete(id);
    });
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: l10n.noteDeleted,
      undoLabel: l10n.undo,
      onUndo: () => repo.restore(id),
    );
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
            describeError: (e) => aiErrorText(l10n, e),
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
                ? aiErrorText(l10n, e)
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
  Future<void> _dictateNote() {
    TipOnce.show(
      context,
      ref.read(sharedPreferencesProvider),
      TipOnce.homeMicHold,
      context.l10n.tipHomeMicHold,
    );
    return createDictationNote();
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
      if (mounted) showQuickAddSnack(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
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
    // Paylaşılan klasör süzgeci (K8): ızgarayı o klasörün notları doldurur.
    final sharedFolder = ref.watch(selectedSharedFolderProvider);
    final semanticActive =
        sharedFolder == null &&
        ref.watch(semanticSearchEnabledProvider) &&
        query.trim().length > 2;
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
        !searchActive &&
        !selectionActive &&
        ref.watch(selectedFolderProvider) == null;
    // **KLASÖR RAFI görünür mü / şerit mi** (2026-11-07). Kural eskisiyle
    // aynı: yalnız kök süzgeçte, aramasız, sıralama dışı; gizlenebilir ama
    // bir klasörün İÇİNDEYKEN hep görünür (kullanıcı isteği 2026-11-06).
    final inFolderView =
        hubActive ||
        sharedFolder != null ||
        ref.watch(selectedFolderProvider) != null;
    final showShelf =
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
                    final cellWidth =
                        (constraints.maxWidth -
                            2 * kGridInset -
                            kGridGap * (columns - 1)) /
                        columns;
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
                                    icon: const Icon(AppIcons.archive),
                                    onPressed: () =>
                                        _archiveSelected(selectedIds),
                                  ),
                                  IconButton(
                                    tooltip: l10n.copy,
                                    icon: const Icon(AppIcons.copy),
                                    onPressed: () => _copySelected(selectedIds),
                                  ),
                                  IconButton(
                                    tooltip: l10n.deleteSelected,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _deleteSelected(selectedIds),
                                  ),
                                  IconButton(
                                    tooltip: l10n.moreActions,
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () =>
                                        _openSelectionMenu(selectedIds),
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
                                  WindowClass.of(context).width ==
                                      WindowWidth.compact;
                              return AppBar(
                                // SOLDA GERİ OKU YOK (kullanıcı bulgusu
                                // 2026-11-06: kutu bir sağa bir sola
                                // kayıyordu). Sol kenar sabit; aramayı
                                // bırakma düğmesi sağda, hesap + ⋮'nin yerinde.
                                titleSpacing: 12,
                                automaticallyImplyLeading: false,
                                // Satırı UÇTAN UCA doldurur (kullanıcı bulgusu
                                // 2026-11-09: "webte arama alanının sağında
                                // ölü boşluk"): F44.4'ün 720 dp tavanı ve
                                // sağdaki fazladan 12 dp kaldırıldı — iki
                                // kenar da titleSpacing (12).
                                title: SizedBox(
                                  width: double.infinity,
                                  child: _SearchField(
                                    compact: narrowPane,
                                    controller: _searchController,
                                    focusNode: _searchFocus,
                                    // HESAP SİMGESİ ve ⋮ ARTIK KUTUNUN İÇİNDE
                                    // (kullanıcı isteği 2026-11-06: "üst
                                    // arama çubuğu profil ve 3 noktayı da
                                    // kapsasın"). Hesap kişiselleştirmede
                                    // gizlenebilir (Customizable); ⋮ alt
                                    // levhayı açar (bkz. [ActionMenu]).
                                    // Gelen/paylaşılan sayısı avatar
                                    // rozetinde (F11.1).
                                    trailing: searchExpanded
                                        ? [
                                            // TextFieldTapRegion: basış
                                            // "alan dışı" sayılırsa odak
                                            // pointer-down'da düşer, düğme
                                            // kaybolur, dokunuş kutuya geçip
                                            // klavyeyi GERİ açardı (bulgu
                                            // 2026-11-06).
                                            TextFieldTapRegion(
                                            child: IconButton(
                                              key: const ValueKey(
                                                'search-done',
                                              ),
                                              tooltip: l10n.close,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              icon: const Icon(
                                                Icons.keyboard_hide_outlined,
                                              ),
                                              onPressed: _searchFocus.unfocus,
                                            ),
                                            ),
                                          ]
                                        : [
                                            const Customizable(
                                              id: UiItem.homeAccount,
                                              child: AccountAvatarButton(),
                                            ),
                                            IconButton(
                                              tooltip: l10n.more,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              icon: const Icon(
                                                Icons.more_vert,
                                              ),
                                              onPressed: () => unawaited(
                                                _openHomeMenu(
                                                  hasHiddenFolders:
                                                      hasHiddenFolders,
                                                  hiddenRevealed:
                                                      hiddenRevealed,
                                                ),
                                              ),
                                            ),
                                          ],
                                  ),
                                ),
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
                        // TAKVİM ŞERİDİ (2026-11-08, takvim zemininin yerine):
                        // bugünden itibaren 10 gün; kapalıyken tek ince satır.
                        // YENİ SÜRÜM ŞERİDİ (2026-11-10): kalıcı, kapatılamaz;
                        // yeni sürüm yokken sıfır yer.
                        const UpdateBanner(),
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
                          child: FolderPullIndicator(
                          progress: _folderPull,
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
                                        ref.watch(swipeLeftCalendarProvider)),
                                nextLabel: _swipeStopLabel,
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
                                    // bıraktığı yerden AYNI yönde sürer;
                                    // gelen de o yönde, daha uzaktan girer
                                    // (sayfa çevirme hissi). Düğme/çip
                                    // geçişinde eski kısa kayma.
                                    final from =
                                        !incoming &&
                                            child.key == ValueKey(_leavingKey)
                                        ? _leavingFrom
                                        : null;
                                    final Offset begin;
                                    final Offset end;
                                    if (from != null) {
                                      begin = Offset(from + move * 0.35, 0);
                                      end = Offset(from, 0);
                                    } else {
                                      final swiped =
                                          incoming && _leavingKey != null;
                                      begin = Offset(
                                        (incoming ? -move : move) *
                                            (swiped ? 0.3 : 0.12),
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
                                      // BENİMLE PAYLAŞILANLAR (seçenek,
                                      // varsayılan kapalı — bkz.
                                      // homeShowSharedProvider): kök
                                      // görünümde, kendi notlarımın üstünde.
                                      if (!searchActive &&
                                          !reorderActive &&
                                          !selectionActive &&
                                          !hubActive &&
                                          sharedFolder == null &&
                                          !sharedAtBottom &&
                                          ref.watch(homeShowSharedProvider) &&
                                          ref.watch(noteFilterProvider) ==
                                              NoteFilter.all &&
                                          ref.watch(selectedTagProvider) ==
                                              null &&
                                          ref.watch(selectedFolderProvider) ==
                                              null)
                                        SharedNotesHomeSection(
                                          columns: columns,
                                          cellWidth: cellWidth,
                                        ),
                                      if (sharedFolder != null)
                                        ...sharedFolderSlivers(
                                          context,
                                          ref,
                                          folder: sharedFolder,
                                          columns: columns,
                                          cellWidth: cellWidth,
                                          query: query,
                                        )
                                      else if (hubActive)
                                        ..._hubSlivers(
                                          context,
                                          columns,
                                          cellWidth,
                                        )
                                      else
                                      ...notesAsync.when(
                                        data: (notes) => [
                                          ..._afterSkeleton(),
                                          // Aynı sarmalayıcı özette de var:
                                          // kartlar yeniden kurulmaz (F25.2).
                                          for (final sliver
                                              in _buildNoteSlivers(
                                                context,
                                                notes,
                                                columns,
                                                cellWidth: cellWidth,
                                                selectionActive:
                                                    selectionActive,
                                                searchActive: searchActive,
                                                reorderEnabled: reorderActive,
                                              ))
                                            SliverIgnorePointer(
                                              ignoring: false,
                                              sliver: SliverRevealFade(
                                                play: _skeletonShown,
                                                sliver: sliver,
                                              ),
                                            ),
                                        ],
                                        // Yüklenirken diskteki özet, dokunuşa
                                        // kapalı (F25.2, home_snapshot.dart);
                                        // yoksa kart İSKELETİ (skeleton.dart).
                                        loading: () {
                                          final snapshot =
                                              _isDefaultHome(
                                                searchActive: searchActive,
                                              )
                                              ? ref.watch(homeSnapshotProvider)
                                              : const <Note>[];
                                          if (snapshot.isEmpty) {
                                            _skeletonShown = true;
                                            return [
                                              SliverToBoxAdapter(
                                                child: NoteGridSkeleton(
                                                  columns: columns,
                                                ),
                                              ),
                                            ];
                                          }
                                          return [
                                            for (final sliver
                                                in _buildNoteSlivers(
                                                  context,
                                                  snapshot,
                                                  columns,
                                                  cellWidth: cellWidth,
                                                  selectionActive: false,
                                                  searchActive: false,
                                                  reorderEnabled: false,
                                                ))
                                              SliverIgnorePointer(
                                                sliver: SliverRevealFade(
                                                  play: false,
                                                  sliver: sliver,
                                                ),
                                              ),
                                          ];
                                        },
                                        error: (e, _) => [
                                          SliverFillRemaining(
                                            hasScrollBody: false,
                                            child: ErrorState(error: e),
                                          ),
                                        ],
                                      ),
                                      // Paylaşılanlar ALTTA seçildiyse
                                      // (bkz. homeSharedAtBottomProvider).
                                      if (!searchActive &&
                                          !reorderActive &&
                                          !selectionActive &&
                                          !hubActive &&
                                          sharedFolder == null &&
                                          sharedAtBottom &&
                                          ref.watch(homeShowSharedProvider) &&
                                          ref.watch(noteFilterProvider) ==
                                              NoteFilter.all &&
                                          ref.watch(selectedTagProvider) ==
                                              null &&
                                          ref.watch(selectedFolderProvider) ==
                                              null)
                                        SharedNotesHomeSection(
                                          columns: columns,
                                          cellWidth: cellWidth,
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
                        ),
                      ],
                    ));
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
                // SÜRÜKLERKEN ÇÖP KUTUSU (F60.S9): HEP ağaçta, yalnız
                // boyamada belirir — sürükleme başlayınca ağaç şekli
                // değişmez (kasma listesi 4, 6).
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: DragTrashTarget(
                      active: _dragNoteId != null,
                      onTrash: _trashDraggedNote,
                    ),
                  ),
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
                // KLASÖR DÜĞMESİ KALKTI (kullanıcı isteği 2026-11-09: "sol
                // alttaki klasörler butonunu kaldır"). Klasör menüsü liste
                // tepedeyken aşağı çekişle ve yan çubuktan açılır.
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
                      //
                      // Ray görünürken kapılar rayda (K3, F44.1): Builder yalnız
                      // bu dalı ray durumuna bağlar.
                      Builder(
                        builder: (context) => AppRailScope.visible(context)
                            ? const SizedBox.shrink()
                            : sharedFolder != null
                            ? SharedFolderFab(folder: sharedFolder)
                            : Row(
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
                          ValueListenableBuilder<bool>(
                            valueListenable: _narrowPaneN,
                            builder: (_, narrow, mic) =>
                                Offstage(offstage: narrow, child: mic),
                            child: Customizable(
                            id: UiItem.homeMic,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(end: 12),
                              child: _DashVoiceButton(
                                key: const ValueKey('home-mic'),
                                tooltip: l10n.voiceMicTooltipDictate,
                                icon: AppIcons.dictation,
                                onTap: _dictateNote,
                                onLongPress: _captureVoiceNote,
                              ),
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
                              actions: () => this,
                            ),
                          ),
                        ],
                      ),
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
