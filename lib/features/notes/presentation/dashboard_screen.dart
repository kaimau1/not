import 'package:flutter/material.dart';
// ScrollCacheExtent (ızgara önbellek payı) yalnız rendering katmanında.
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/semantic_search.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../settings/data/permissions_service.dart';
import '../../settings/presentation/permissions_onboarding.dart';
import '../data/notes_repository.dart';
import '../data/reminder_service.dart';
import '../data/share_intake.dart';
import '../data/upload_queue.dart';
import '../data/widget_service.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'color_picker_sheet.dart';
import 'dashboard_chips.dart';
import 'note_card.dart';
import 'notes_providers.dart';
import 'qr_scan_screen.dart';
import 'quick_add_fab.dart';
import 'voice_assistant.dart';
import 'voice_assistant_widgets.dart';

/// Ana ekran ızgarasının önbellek payı (px). Masonry ızgaranın toplam
/// uzunluğunu TAHMİN etmesini engellemek için kartların tamamının bu pay
/// içinde ölçülmesi istenir (bkz. [_DashboardScreenState.build]). ~10 bin px,
/// iki sütunlu düzende yüzden fazla nota karşılık gelir.
const double _kGridCacheExtent = 10000;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
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
  ///
  /// Eşik neden 1.25: her karede oran biraz oynadığından ham yuvarlama sütunu
  /// ileri geri titretiyordu. Bir adım için parmak arasının en az %25
  /// değişmesi istenir; adım atıldıktan sonra taban güncellenir ki aynı jestle
  /// 1 → 4 arası gezilebilsin.
  void _handleZoom(ScaleUpdateDetails details, int columns) {
    if (details.pointerCount < 2) return;
    const threshold = 1.25;
    final scale = details.scale;
    if (scale <= 0) return;
    final int target;
    if (scale >= threshold) {
      target = _zoomBaseColumns - 1;
    } else if (scale <= 1 / threshold) {
      target = _zoomBaseColumns + 1;
    } else {
      return;
    }
    final clamped = target.clamp(
      GridColumnsNotifier.minColumns,
      GridColumnsNotifier.maxColumns,
    );
    _zoomBaseColumns = clamped;
    if (clamped == columns) return;
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
  }

  @override
  void initState() {
    super.initState();
    // Odak değişince aksiyon butonlarını gizle/göster (dar ekranlarda arama
    // alanına yer açmak için).
    _searchFocus.addListener(() => setState(() {}));
    // Widget/derin bağlantı bu ekran mount olmadan önce bas-başlat istemiş
    // olabilir (uygulama kapalıyken ya da başka ekrandayken). İlk kareden
    // sonra kontrol et; take() varsa asistanı başlatır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutostartVoice();
      // İlk açılışta izin tanıtımı (bir kez).
      if (mounted) PermissionsOnboarding.maybeShow(context, ref);
    });
  }

  /// Ana ekran mikrofon widget'ının bas-başlat isteği varsa Sesli Not
  /// Asistanı'nı başlatır (tek seferlik — bayrak take ile tüketilir).
  void _maybeAutostartVoice() {
    if (!mounted) return;
    if (ref.read(voiceAutostartProvider.notifier).take()) {
      ref
          .read(voiceAssistantProvider.notifier)
          .start(
            micPermissionDeniedText: context.l10n.micPermissionDenied,
            genericErrorText: context.l10n.assistantGenericError,
          );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Seçilen notları çöp kutusuna taşır; tek dokunuşla geri alınabilir.
  void _deleteSelected(Set<String> ids) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    for (final id in ids) {
      repo.softDelete(id);
    }
    ref.read(selectedNoteIdsProvider.notifier).clear();
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
    final parts = [
      for (final n in _selectedNotes(ids))
        if (n.locked) n.title.trim() else n.toPlainText(),
    ];
    return parts.where((t) => t.trim().isNotEmpty).join('\n\n———\n\n');
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
    final text = _joinSelected(ids);
    ref.read(selectedNoteIdsProvider.notifier).clear();
    if (text.trim().isEmpty) return;
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
      _showSnack(l10n.hiddenFoldersHiddenAgain);
      return;
    }
    if (!await authenticateForNote(l10n.hiddenFolderAuthReason)) return;
    ref.read(hiddenFoldersRevealedProvider.notifier).set(true);
    if (!mounted) return;
    _showSnack(l10n.hiddenFoldersShown);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Dashboard sıralama ölçütünü seçtiren alt sayfa.
  Future<void> _pickSort() async {
    final l10n = context.l10n;
    final current = ref.read(noteSortProvider);
    final options = <(NoteSort, String, IconData)>[
      (NoteSort.manual, l10n.sortManual, Icons.drag_indicator),
      (NoteSort.updated, l10n.sortUpdated, Icons.update),
      (NoteSort.created, l10n.sortCreated, Icons.schedule_outlined),
      (NoteSort.title, l10n.sortTitle, Icons.sort_by_alpha),
    ];
    final picked = await showModalBottomSheet<NoteSort>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.sortBy,
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
            ),
            for (final (sort, label, icon) in options)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: current == sort
                    ? Icon(
                        Icons.check,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, sort),
              ),
          ],
        ),
      ),
    );
    if (picked != null) ref.read(noteSortProvider.notifier).set(picked);
  }

  /// Ana ekranı yatay çekince (madde 1) aktif görünümü sonraki/önceki
  /// segmente taşır. Gezinme sırası: Tümü → görünür filtreler (kullanıcı
  /// sırası) → klasörler. [direction] +1 sola çekiş (sonraki), -1 sağa çekiş.
  void _cycleFilterFolder(int direction) {
    final visibleFilters = ref.read(visibleNoteFiltersProvider);
    // Çip barında görünmeyen klasörler (gizli olanlar ve çipi kapatılanlar)
    // çekiş turunda da atlanır — yoksa kaydırma kullanıcıyı görünmez bir
    // klasöre sokuyordu.
    final revealHidden = ref.read(hiddenFoldersRevealedProvider);
    final hiddenChips = ref.read(hiddenFolderChipsProvider);
    final folders = [
      for (final f
          in ref.read(foldersStreamProvider).value ?? const <NoteFolder>[])
        if ((!f.hidden || revealHidden) && !hiddenChips.contains(f.id)) f,
    ];
    final segments = <(NoteFilter, String?)>[
      (NoteFilter.all, null),
      for (final f in visibleFilters) (f, null),
      for (final folder in folders) (NoteFilter.all, folder.id),
    ];
    if (segments.length < 2) return;
    final curFilter = ref.read(noteFilterProvider);
    final curFolder = ref.read(selectedFolderProvider);
    var index = segments.indexWhere(
      (s) => s.$1 == curFilter && s.$2 == curFolder,
    );
    if (index < 0) index = 0;
    var next = (index + direction) % segments.length;
    if (next < 0) next += segments.length;
    final (filter, folderId) = segments[next];
    // Geçiş animasyonunun yönünü çekiş yönüne göre ayarla (madde 2).
    _swipeForward = direction > 0;
    ref.read(noteFilterProvider.notifier).set(filter);
    ref.read(selectedFolderProvider.notifier).set(folderId);
    HapticFeedback.selectionClick();
  }

  /// Bir bölümde (sabitliler / diğerleri) notu basılı tutup sürükleyince
  /// (madde 1) çağrılır: [draggedId] notunu [toIndex] konumuna taşır ve yeni
  /// sırayı kalıcılaştırır. Elle sıra görünsün diye sıralama ölçütü manuel'e
  /// alınır.
  void _reorderSection(List<Note> section, String draggedId, int toIndex) {
    final from = section.indexWhere((n) => n.id == draggedId);
    if (from < 0 || from == toIndex) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final list = [...section];
    final item = list.removeAt(from);
    var target = toIndex;
    if (from < target) target -= 1;
    list.insert(target, item);
    if (ref.read(noteSortProvider) != NoteSort.manual) {
      ref.read(noteSortProvider.notifier).set(NoteSort.manual);
    }
    repo.reorderNotes(list);
    HapticFeedback.mediumImpact();
  }

  Future<void> _createNote(NoteType type) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(type);
    // Aktif bir klasör filtresi varsa yeni not o klasöre doğar.
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    if (mounted) await context.push('/note/$id');
  }

  /// El yazısı modu: not oluşturulur ve editör doğrudan çizim tuvalini
  /// açarak başlar; çizim nota görsel eki olarak kaydedilir.
  Future<void> _createHandwritingNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    if (mounted) await context.push('/note/$id?draw=1');
  }

  /// Sesli not modu (Keep'teki gibi): not oluşturulur, editör açılır açılmaz
  /// ses kaydı başlar ve konuşma dökümü nota canlı yazılır; bitişte ses
  /// m4a eki olarak nota bağlanır.
  Future<void> _createVoiceCaptureNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    if (mounted) await context.push('/note/$id?voice=1');
  }

  /// Görüntülü not: not oluşturulur ve editör açılır açılmaz kamera açılır;
  /// çekilen video YALNIZCA cihazda saklanır (buluta yüklenmez).
  Future<void> _createVideoNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    if (mounted) await context.push('/note/$id?video=1');
  }

  /// "Foto çek not al": not oluşturulur ve editör açılır açılmaz fotoğraf
  /// makinesi açılır; çekilen kare nota gömülür, kullanıcı hemen yazmaya
  /// başlar. Fotoğrafı iptal ederse boş not çıkışta kendiliğinden silinir.
  Future<void> _createPhotoNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    if (mounted) await context.push('/note/$id?photo=1');
  }

  /// "Belge tara not al": not oluşturulur ve editör açılır açılmaz belge
  /// tarayıcı başlar; düzeltilmiş sayfalar nota girer, istenirse yazıları da
  /// tanınıp gövdeye yazılır. Tarama iptal edilirse boş not çıkışta silinir.
  Future<void> _createScanNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    if (mounted) await context.push('/note/$id?scan=1');
  }

  /// QR kod okur ve içeriğini yeni bir nota yazar. Not tarama BAŞARILI olunca
  /// oluşturulur — iptal edilirse ortada boş not kalmaz.
  Future<void> _createQrNote() async {
    final l10n = context.l10n;
    final perms = ref.read(permissionsServiceProvider);
    if (!await perms.cameraGranted() && !await perms.requestCamera()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.permCameraInfo)));
      }
      return;
    }
    if (!mounted) return;
    final code = await openQrScanner(context);
    if (code == null || !mounted) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = ref.read(selectedFolderProvider);
    repo.updateFields(id, {
      'body': code,
      // Null-aware eleman: klasör süzgeci yoksa anahtar hiç yazılmaz.
      'folderId': ?folderId,
    });
    if (mounted) await context.push('/note/$id');
  }

  @override
  Widget build(BuildContext context) {
    // Arka plan servislerini ayakta tut: ek yükleme kuyruğu, hatırlatıcı
    // bildirimleri, ana ekran widget'ı ve derin bağlantı dinleyicisi.
    ref.watch(uploadQueueProvider);
    ref.watch(reminderServiceProvider);
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
    ref.listen(voiceAutostartProvider, (previous, next) {
      if (next) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeAutostartVoice(),
        );
      }
    });

    final l10n = context.l10n;
    final query = ref.watch(searchQueryProvider);
    final semanticActive =
        ref.watch(semanticSearchEnabledProvider) && query.trim().length > 2;
    final notesAsync = semanticActive
        ? ref.watch(semanticSearchProvider(query.trim()))
        : ref.watch(filteredNotesProvider);
    final selectedIds = ref.watch(selectedNoteIdsProvider);
    final selectionActive = selectedIds.isNotEmpty;
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
    final hasHiddenFolders = ref.watch(hiddenFolderIdsProvider).isNotEmpty;
    final hiddenRevealed = ref.watch(hiddenFoldersRevealedProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final searchExpanded =
        _searchFocus.hasFocus &&
        keyboardOpen &&
        MediaQuery.sizeOf(context).width < 600;

    final page = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            _createNote(NoteType.text),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
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
                          )
                        else if (selectionActive)
                          AppBar(
                            leading: IconButton(
                              tooltip: l10n.cancel,
                              icon: const Icon(Icons.close),
                              onPressed: () => ref
                                  .read(selectedNoteIdsProvider.notifier)
                                  .clear(),
                            ),
                            title: Text(l10n.selectedCount(selectedIds.length)),
                            // Kopyala/arşivle/sil ve diğer tüm not işlemleri
                            // seçim yapılınca BURADA toplanır (madde 3): sık
                            // kullanılanlar simge, gerisi taşma menüsünde.
                            actions: [
                              IconButton(
                                tooltip: l10n.archive,
                                icon: const Icon(Icons.archive_outlined),
                                onPressed: () => _archiveSelected(selectedIds),
                              ),
                              IconButton(
                                tooltip: l10n.copy,
                                icon: const Icon(Icons.copy_outlined),
                                onPressed: () => _copySelected(selectedIds),
                              ),
                              IconButton(
                                tooltip: l10n.deleteSelected,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteSelected(selectedIds),
                              ),
                              PopupMenuButton<String>(
                                tooltip: l10n.noteMetaMenu,
                                onSelected: (action) {
                                  switch (action) {
                                    case 'pin':
                                      _setPinnedSelected(selectedIds, true);
                                    case 'unpin':
                                      _setPinnedSelected(selectedIds, false);
                                    case 'star':
                                      _setStarredSelected(selectedIds, true);
                                    case 'unstar':
                                      _setStarredSelected(selectedIds, false);
                                    case 'share':
                                      _shareSelected(selectedIds);
                                    case 'color':
                                      _colorSelected(selectedIds, frame: false);
                                    case 'frame':
                                      _colorSelected(selectedIds, frame: true);
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
                                  _menuItem('unstar', Icons.star, l10n.unstar),
                                  const PopupMenuDivider(),
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
                          )
                        else
                          AppBar(
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
                                    // AI merkezinin AYRI düğmesi kaldırıldı:
                                    // arama çubuğunun içindeki ✨ (akıllı arama)
                                    // ile yan yana duruyor, ikisi karışıyordu.
                                    // Girişi artık ⋮ menüsünün ilk maddesi.
                                    PopupMenuButton<String>(
                                      // Menü ekranın altına taşıp sistem gezinme
                                      // çubuğunun arkasında kalıyordu; yükseklik
                                      // sınırlanınca içerik kaydırılabilir olur.
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.sizeOf(context).height *
                                            0.55,
                                      ),
                                      onSelected: (action) => switch (action) {
                                        'ai' => context.push('/ai'),
                                        'sort' => _pickSort(),
                                        'hidden' => _toggleHiddenFolders(),
                                        'reorder' =>
                                          ref
                                              .read(
                                                reorderModeProvider.notifier,
                                              )
                                              .set(true),
                                        'reminders' => context.push(
                                          '/reminders',
                                        ),
                                        'archive' => context.push('/archive'),
                                        'trash' => context.push('/trash'),
                                        'settings' => context.push('/settings'),
                                        _ => null,
                                      },
                                      // Yalnız sıralama + içerik yerleri +
                                      // ayarlar kaldı; AI maddeleri /ai'de.
                                      itemBuilder: (context) => [
                                        _menuItem(
                                          'ai',
                                          Icons.auto_awesome,
                                          l10n.aiHubTitle,
                                        ),
                                        const PopupMenuDivider(),
                                        _menuItem(
                                          'sort',
                                          Icons.sort,
                                          l10n.sortBy,
                                        ),
                                        // Elle sıralama yalnız süzgeçsiz
                                        // görünümde anlamlı (alt kümede sıra
                                        // bozulur); aksi hâlde madde hiç
                                        // görünmez ki kullanıcı tıklayıp
                                        // "neden olmuyor" demesin.
                                        if (!searchActive &&
                                            ref.watch(noteFilterProvider) ==
                                                NoteFilter.all &&
                                            ref.watch(selectedFolderProvider) ==
                                                null &&
                                            ref.watch(selectedTagProvider) ==
                                                null)
                                          _menuItem(
                                            'reorder',
                                            Icons.swap_vert,
                                            l10n.reorderNotes,
                                          ),
                                        // Gizli klasörler yalnız gizli klasörü
                                        // OLAN kullanıcıda görünür: yoksa
                                        // menüde ölü bir madde durmaz.
                                        if (hasHiddenFolders)
                                          _menuItem(
                                            'hidden',
                                            hiddenRevealed
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            l10n.hiddenFoldersMenu,
                                          ),
                                        const PopupMenuDivider(),
                                        _menuItem(
                                          'reminders',
                                          Icons.alarm_outlined,
                                          l10n.remindersTitle,
                                        ),
                                        _menuItem(
                                          'archive',
                                          Icons.archive_outlined,
                                          l10n.archiveTitle,
                                        ),
                                        _menuItem(
                                          'trash',
                                          Icons.delete_outline,
                                          l10n.trashTitle,
                                        ),
                                        const PopupMenuDivider(),
                                        _menuItem(
                                          'settings',
                                          Icons.settings_outlined,
                                          l10n.settings,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                          ),
                        // Filtre + klasör + etiket çipleri tek kompakt satırda,
                        // kaydırma görünümünün dışında sabit.
                        const DashboardChipsRow(),
                        Expanded(
                          // İki parmakla zoom: 1 → 2 → 3 → 4 sütun arasında
                          // geçiş. Ölçek jesti tek parmakta hiç tepki vermez
                          // (pointerCount kontrolü), böylece içteki yatay
                          // çekiş ve dikey kaydırma olduğu gibi çalışır.
                          child: GestureDetector(
                            onScaleStart: (_) => _zoomBaseColumns = columns,
                            onScaleUpdate: (details) =>
                                _handleZoom(details, columns),
                            child: GestureDetector(
                              // Yatay çekişle filtreler/klasörler arasında
                              // gezin. Dikey kaydırma CustomScrollView'de
                              // kalır; eksenler farklı olduğundan çakışmaz.
                              onHorizontalDragEnd: (details) {
                                final velocity = details.primaryVelocity ?? 0;
                                if (velocity.abs() < 200) return;
                                _cycleFilterFolder(velocity < 0 ? 1 : -1);
                              },
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  // Çekiş yönüne göre yumuşak kaydır + soldur.
                                  final begin = Offset(
                                    _swipeForward ? 0.12 : -0.12,
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
                                  // KÖK NEDEN (aşağı kaydırırken liste yukarı
                                  // sıçraması): SliverMasonryGrid tembeldir ve
                                  // toplam kaydırma uzunluğunu yalnızca O AN
                                  // yerleşmiş kartların ORTALAMA yüksekliğinden
                                  // TAHMİN eder. Masonry'de kart boyları çok
                                  // farklı olduğundan tahmin her karede oynuyor;
                                  // tahmin o anki konumun altına düştüğü an
                                  // ScrollPosition kendini düzeltip listeyi
                                  // yukarı çekiyordu (sona yaklaşıldıkça sık).
                                  // Geniş önbellek payı kartların TAMAMINI ilk
                                  // yerleşimde ölçtürür: uzunluk tahmin değil
                                  // gerçek olur, düzeltme/sıçrama hiç olmaz.
                                  // Bedeli, bu pay içindeki kartların önceden
                                  // kurulması; bu sınırın (≈130 kart) ötesinde
                                  // tembelliğe geri dönülür.
                                  scrollCacheExtent:
                                      const ScrollCacheExtent.pixels(
                                        _kGridCacheExtent,
                                      ),
                                  slivers: [
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
                                      loading: () => [
                                        const SliverFillRemaining(
                                          hasScrollBody: false,
                                          child: Center(
                                            child: CircularProgressIndicator(),
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
                                    const SliverToBoxAdapter(
                                      child: SizedBox(height: 88),
                                    ),
                                  ],
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
                const Positioned(
                  left: 8,
                  right: 88,
                  bottom: 16,
                  child: VoiceAssistantPanel(),
                ),
                // Düğmeler Scaffold.floatingActionButton yerine BURADA durur:
                // Scaffold bir FAB tanıdığında yüzen bildirimleri ("not
                // silindi") onun ÜSTÜne iter. Düğmeler Stack'te olunca
                // bildirim ekranın dibinde, düğmelerin solunda kalır.
                Positioned(
                  right: 16,
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
                        // Sesli Not Asistanı: sayfa değiştirmeden burada dinler.
                        const VoiceAssistantButton(),
                        const SizedBox(height: 6),
                        // Keep tarzı açılan "+": metin/madde/sıralı/el yazısı.
                        QuickAddFab(
                          onVoiceCapture: _createVoiceCaptureNote,
                          onVideoNote: _createVideoNote,
                          onPhotoNote: _createPhotoNote,
                          onScanNote: _createScanNote,
                          onQrNote: _createQrNote,
                          anchor: _fabColumnLink,
                          onCreate: _createNote,
                          onHandwriting: _createHandwritingNote,
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
        if (selectionActive) {
          ref.read(selectedNoteIdsProvider.notifier).clear();
        } else if (reorderActive) {
          ref.read(reorderModeProvider.notifier).set(false);
        }
      },
      child: page,
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem<String>(
        value: value,
        height: 40,
        // ListTile satırı daima erişilebilir tüm genişliği kaplıyordu; menü de
        // bu yüzden sağ-sol ekseninde gereksiz genişliyordu (madde 5). İçeriğe
        // göre daralan Row ile menü yalnız ikon + etiket kadar yer kaplar.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      );

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
              ? EmptyState(icon: Icons.search_off, title: l10n.emptySearch)
              : EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: l10n.emptyNotes,
                  subtitle: l10n.emptyNotesHint,
                ),
        ),
      ];
    }

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

    Widget grid(List<Note> items) => SliverMasonryGrid.count(
      crossAxisCount: columns,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childCount: items.length,
      itemBuilder: (context, index) {
        final note = items[index];
        final card = NoteCard(note: note, highlightQuery: query);
        void select() =>
            ref.read(selectedNoteIdsProvider.notifier).toggle(note.id);
        // Olağan hâl: uzun basış toplu seçime girer.
        if (!reorderEnabled) {
          return KeyedSubtree(
            key: ValueKey(note.id),
            child: GestureDetector(onLongPress: select, child: card),
          );
        }
        return _ReorderableNoteCell(
          key: ValueKey(note.id),
          noteId: note.id,
          index: index,
          cellWidth: cellWidth,
          inSection: (id) => items.any((n) => n.id == id),
          onReorder: (draggedId, to) => _reorderSection(items, draggedId, to),
          feedback: SizedBox(
            width: cellWidth,
            child: NoteCard(note: note, highlightQuery: query),
          ),
          child: card,
        );
      },
    );

    Widget header(String text) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );

    const gridPadding = EdgeInsets.symmetric(horizontal: 12);

    if (pinned.isEmpty || others.isEmpty) {
      return [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverPadding(padding: gridPadding, sliver: grid(notes)),
      ];
    }
    return [
      header(l10n.sectionPinned),
      SliverPadding(padding: gridPadding, sliver: grid(pinned)),
      header(l10n.sectionOthers),
      SliverPadding(padding: gridPadding, sliver: grid(others)),
    ];
  }
}

/// Bir not kartını basılı tutup sürükleyerek yeniden sıralamayı sağlayan
/// sarmalayıcı. YALNIZCA sıralama modunda kullanılır ([reorderModeProvider]):
/// uzun basış sürüklemeyi başlatır, başka bir kartın üzerine bırakılınca
/// [onReorder] çağrılır. Sürükleme aynı bölümle sınırlıdır ([inSection]) —
/// sabitliler ile diğerleri karışmaz.
///
/// Uzun basış artık seçim YAPMAZ; mod dışında seçim zaten sade bir
/// GestureDetector ile yapılıyor. (Eskiden tek jest ikisine birden hizmet
/// ediyordu ve kullanıcı seçmek isterken kartı kazara taşıyordu.)
class _ReorderableNoteCell extends StatelessWidget {
  const _ReorderableNoteCell({
    super.key,
    required this.noteId,
    required this.index,
    required this.cellWidth,
    required this.inSection,
    required this.onReorder,
    required this.feedback,
    required this.child,
  });

  final String noteId;
  final int index;
  final double cellWidth;
  final bool Function(String draggedId) inSection;
  final void Function(String draggedId, int toIndex) onReorder;
  final Widget feedback;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          details.data != noteId && inSection(details.data),
      onAcceptWithDetails: (details) => onReorder(details.data, index),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return LongPressDraggable<String>(
          data: noteId,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: cellWidth, child: feedback),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hovering ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: child,
          ),
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
    final query = ref.watch(searchQueryProvider);
    final semantic = ref.watch(semanticSearchEnabledProvider);
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (value) => ref.read(searchQueryProvider.notifier).set(value),
      // Alan dışına dokununca odak bırakılır; bar daralır, butonlar döner.
      onTapOutside: (_) => focusNode?.unfocus(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: semantic
            ? context.l10n.semanticSearchHint
            : context.l10n.searchHint,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.l10n.semanticSearchToggle,
              icon: Icon(
                Icons.auto_awesome,
                size: 18,
                color: semantic ? scheme.primary : scheme.onSurfaceVariant,
              ),
              onPressed: () =>
                  ref.read(semanticSearchEnabledProvider.notifier).toggle(),
            ),
            if (query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  ref.read(searchQueryProvider.notifier).set('');
                },
              ),
          ],
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
