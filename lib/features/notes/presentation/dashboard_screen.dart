import 'dart:io';

import 'package:flutter/material.dart';
// ScrollCacheExtent (ızgara önbellek payı) yalnız rendering katmanında.
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/gemini_service.dart';
import '../../ai/data/semantic_search.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../settings/data/permissions_service.dart';
import '../../settings/settings_providers.dart';
import '../../settings/presentation/permissions_onboarding.dart';
import '../data/attachment_repository.dart';
import '../data/notes_repository.dart';
import '../data/reminder_service.dart';
import '../data/share_intake.dart';
import '../data/upload_queue.dart';
import '../data/widget_service.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'color_picker_sheet.dart';
import 'filter_sheet.dart';
import 'note_card.dart';
import 'notes_providers.dart';
import 'qr_scan_screen.dart';
import 'quick_add_fab.dart';
import 'voice_assistant.dart';
import 'voice_assistant_widgets.dart';
import 'voice_capture_sheet.dart';

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
        // displayTitle: başlık biçimlendirilebiliyor, işaretler panoya sızmasın.
        if (n.locked) n.displayTitle.trim() else n.toPlainText(),
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

  // Sıralama seçici alt sayfası (_pickSort) kaldırıldı: sıralama artık Süz
  // levhasının SIRALAMA bölümünde, süzgeçlerle aynı yerde.

  /// Ana ekranı yatay çekince (madde 1) aktif görünümü sonraki/önceki
  /// segmente taşır. Gezinme sırası: Tümü → görünür filtreler (kullanıcı
  /// sırası) → klasörler. [direction] +1 sola çekiş (sonraki), -1 sağa çekiş.
  void _cycleFilterFolder(int direction) {
    // Çip barı kalkınca "kullanıcının seçtiği görünür süzgeçler" listesi de
    // kalktı; çekiş artık süzgeçlerin TAMAMINI geziyor. Gizli klasörler yine
    // atlanır — kaydırma kullanıcıyı görünmez bir klasöre sokmamalı.
    final revealHidden = ref.read(hiddenFoldersRevealedProvider);
    final folders = [
      for (final f
          in ref.read(foldersStreamProvider).value ?? const <NoteFolder>[])
        if (!f.hidden || revealHidden) f,
    ];
    final segments = <(NoteFilter, String?)>[
      for (final f in NoteFilter.values) (f, null),
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

  /// Yeni notu açar; DÖNÜŞTE o notu ana ekranda vurgular.
  ///
  /// Kullanıcı isteği: "kişi yeni bir not oluşturup dashboard'a döndüğünde o
  /// nota odak gitmeli ve notun çerçevesi hafif yanıp sönmeli" — uzun bir
  /// listede yeni notun nereye düştüğü görünmüyordu (asistanın oluşturduğu
  /// notlarda bu zaten vardı, aynı yol elle oluşturulanlara da açıldı).
  Future<void> _openNew(String id, {String query = ''}) async {
    if (!mounted) return;
    await context.push(noteRoutePath(id, query: query));
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
        SnackBar(
          content: Text(l10n.assistantNoteCreated),
          duration: const Duration(seconds: 3),
          // TUZAK: bu Flutter sürümünde AKSİYONLU SnackBar'ın varsayılanı
          // `persist: true` — zamanlayıcı hiç kurulmuyor ve "Not oluşturuldu"
          // uyarısı elle kapatılana dek ekranda KALIYORDU. persist: false
          // eski davranışı (süre dolunca kapan) geri getirir.
          persist: false,
          action: SnackBarAction(
            label: l10n.openNote,
            onPressed: () => _openNew(id),
          ),
        ),
      );
  }

  Future<void> _createNote(NoteType type) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    // Klasör TEK yazımda: createNote + ayrı updateFields arasında doküman bir
    // an klasörsüz/boş kalıyordu (bkz. NotesRepository.createNote yorumu).
    final id = await repo.createNote(
      type,
      folderId: ref.read(selectedFolderProvider),
    );
    await _openNew(id);
    // Dönüşte notu GİZLEYECEK süzgeçler temizlenir — hızlı yakalama satırında
    // çözülen kök neden ("Yıldızlı"/etiket/arama açıkken yeni not listede hiç
    // görünmüyordu) FAB yolunda açık kalmıştı. Klasör süzgeci kalır (not o
    // klasöre doğdu); boş bırakılıp silinen not için süzgeçlere dokunulmaz.
    if (!mounted) return;
    // Kısa bekleme ŞART: push future'ı POP anında tamamlanır, editörün son
    // yazımı ise dispose'daki _saveNow'da (çıkış animasyonundan sonra) düşer.
    // Hemen bakılsaydı hızlı yazıp çıkan kullanıcının notu akışta hâlâ boş
    // görünür ve süzgeçler temizlenmezdi — düzeltmenin hedeflediği senaryo.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final kept = ref.read(notesStreamProvider).value ?? const <Note>[];
    final survives = kept.any((n) => n.id == id && !n.isEmpty);
    if (!survives) return;
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
            result.text,
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
          _showSnack(
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
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  /// El yazısı modu: not oluşturulur ve editör doğrudan çizim tuvalini
  /// açarak başlar; çizim nota görsel eki olarak kaydedilir.
  Future<void> _createHandwritingNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    await _openNew(id, query: '?draw=1');
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
    await _openNew(id, query: '?voice=1');
  }

  /// Görüntülü not: not oluşturulur ve editör açılır açılmaz kamera açılır;
  /// çekilen video YALNIZCA cihazda saklanır (buluta yüklenmez).
  Future<void> _createVideoNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    await _openNew(id, query: '?video=1');
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
    await _openNew(id, query: '?photo=1');
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
    await _openNew(id, query: '?scan=1');
  }

  /// "PDF ekle not al": PDF tipinde not oluşturulur ve editör açılır açılmaz
  /// dosya seçici gelir; seçilen belge notun içine gömülür, ekran ÜSTTE sayfa
  /// ALTTA o sayfanın notu olacak şekilde ikiye bölünür. Seçim iptal edilirse
  /// boş not çıkışta kendiliğinden silinir (fotoğraf/tarama yollarının aynısı).
  Future<void> _createPdfNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.pdf);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    await _openNew(id, query: '?pdf=1');
  }

  /// "Sunum ekle not al": PDF yolunun slayt eşi.
  Future<void> _createSlidesNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.slides);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    await _openNew(id, query: '?slides=1');
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
    await _openNew(id);
  }

  /// Ayarlardan seçilen ana ekran zemin görseli (yoksa boş liste).
  List<Widget> _dashboardBackground(WidgetRef ref) {
    final background = ref.watch(dashboardBackgroundProvider);
    final path = background.path;
    if (path == null) return const [];
    // Önbellekli varlık denetimi: build her tuş vuruşunda çalışıyor, senkron
    // stat her seferinde ödenmesin. Çözünürlük ekran genişliğiyle sınırlı —
    // sınırsız decode tam boy bitmap'i bellekte tutuyordu.
    if (!localFileExists(path)) return const [];
    final targetWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    return [
      Positioned.fill(
        child: Opacity(
          opacity: background.opacity.clamp(0.05, 1),
          child: Image(
            image: ResizeImage(FileImage(File(path)), width: targetWidth),
            fit: BoxFit.cover,
          ),
        ),
      ),
    ];
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
    // Elle sıralama yalnız süzgeçsiz görünümde anlamlı (alt kümede sıra
    // bozulur); aksi hâlde menü maddesi hiç görünmez ki kullanıcı tıklayıp
    // "neden olmuyor" demesin.
    final reorderAvailable =
        !searchActive &&
        ref.watch(noteFilterProvider) == NoteFilter.all &&
        ref.watch(selectedFolderProvider) == null &&
        ref.watch(selectedTagProvider) == null;
    final hiddenRevealed = ref.watch(hiddenFoldersRevealedProvider);

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
                                        // Yapay Zeka yeniden KENDİ düğmesi oldu.
                                        // Bir süre ⋮ menüsünde durmuştu çünkü arama
                                        // alanının içindeki ✨ (akıllı arama) ile
                                        // karışıyordu; o ✨ artık Metin/Anlam
                                        // segmenti olduğundan karışıklık kalktı.
                                        Tooltip(
                                          message: l10n.aiHubTitle,
                                          child: SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: Material(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: () =>
                                                    context.push('/ai'),
                                                child: Icon(
                                                  Icons.auto_awesome,
                                                  size: 22,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSecondaryContainer,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        PopupMenuButton<String>(
                                          // Menü ekranın altına taşıp sistem gezinme
                                          // çubuğunun arkasında kalıyordu; yükseklik
                                          // sınırlanınca içerik kaydırılabilir olur.
                                          constraints: BoxConstraints(
                                            maxHeight:
                                                MediaQuery.sizeOf(
                                                  context,
                                                ).height *
                                                0.55,
                                          ),
                                          onSelected: (action) =>
                                              switch (action) {
                                                'hidden' =>
                                                  _toggleHiddenFolders(),
                                                'reorder' =>
                                                  ref
                                                      .read(
                                                        reorderModeProvider
                                                            .notifier,
                                                      )
                                                      .set(true),
                                                'reminders' => context.push(
                                                  '/reminders',
                                                ),
                                                'archive' => context.push(
                                                  '/archive',
                                                ),
                                                'trash' => context.push(
                                                  '/trash',
                                                ),
                                                'settings' => context.push(
                                                  '/settings',
                                                ),
                                                _ => null,
                                              },
                                          // Tasarım bu menüyü dörde indiriyor
                                          // (Hatırlatıcılar, Arşiv, Çöp, Ayarlar).
                                          // Sıralama Süz levhasına taşındı; elle
                                          // sıralama ve gizli klasörler tasarımda
                                          // hiç yok ama başka girişi olmadığı için
                                          // burada KALDI — kaldırsaydım iki özellik
                                          // erişilemez olurdu.
                                          itemBuilder: (context) => [
                                            // Elle sıralama yalnız süzgeçsiz
                                            // görünümde anlamlı (alt kümede sıra
                                            // bozulur); aksi hâlde madde hiç
                                            // görünmez ki kullanıcı tıklayıp
                                            // "neden olmuyor" demesin.
                                            if (reorderAvailable)
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
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                l10n.hiddenFoldersMenu,
                                              ),
                                            // Ayırıcı yalnız üstünde madde VARSA:
                                            // ikisi de gizliyken menü bir çizgiyle
                                            // başlıyordu, bozuk görünüyordu.
                                            if (reorderAvailable ||
                                                hasHiddenFolders)
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
                              );
                            },
                          ),
                        // "Süz" düğmesi + yalnız UYGULANMIŞ süzgeçler. Eski
                        // dokuz artı çipli bar (dashboard_chips.dart) ve ona
                        // bağlı "hangi çip görünsün" ayarları kaldırıldı;
                        // süzme tek yoldan, Süz levhasından yapılıyor.
                        const DashboardFilterRow(),
                        // Hızlı yakala: "+" → editör → yaz → geri yolunu tek
                        // satıra indirir. Tasarım bunu kaydırma akışının
                        // içine koyuyordu; sabit satırda tutuyorum ki liste
                        // aşağıdayken yukarı kaydırmadan da yazılabilsin.
                        // Varsayılan GİZLİ (Ayarlar > "Hızlı not satırı"):
                        // satır yer kaplıyordu, aynı iş "+" menüsünde de var.
                        if (ref.watch(quickCaptureRowProvider))
                          _QuickCaptureRow(
                            onCreateChecklist: () =>
                                _createNote(NoteType.checklist),
                            onSaved: _afterQuickCapture,
                          ),
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
                const PositionedDirectional(
                  start: 8,
                  end: 88,
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
                        // Asistan: ortak dinleme levhasını açar. Eski "Asistan"
                        // yazılı 68 px'lik yuvarlak düğme kaldırıldı — kayıt
                        // durumunu levha gösteriyor, düğmenin nefes almasına
                        // gerek kalmadı.
                        Tooltip(
                          message: l10n.voiceAssistantTitle,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Material(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _captureVoiceNote,
                                child: Icon(
                                  Icons.mic_none,
                                  size: 24,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Keep tarzı açılan "+": metin/madde/sıralı/el yazısı.
                        QuickAddFab(
                          onVoiceCapture: _createVoiceCaptureNote,
                          onVideoNote: _createVideoNote,
                          onPhotoNote: _createPhotoNote,
                          onScanNote: _createScanNote,
                          onPdfNote: _createPdfNote,
                          onSlidesNote: _createSlidesNote,
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

    /// Liste görünümü: tek sütun, kompakt satır. Sürükle-sırala BURADA yok —
    /// o mod ızgaraya özgü (hücre genişliğiyle çalışıyor); liste görünümünde
    /// ⋮ menüsündeki sıralama maddesi zaten görünmüyor.
    Widget rows(List<Note> items) => SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final note = items[index];
        // Consumer + select: vurgu/seçim değişince yalnız İLGİLİ satır
        // yeniden çizilsin — ekranın ref'i izleseydi 4 sn'lik vurgu döngüsü
        // ve her seçim tüm dashboard'u yeniden kurar (eskiden kuruyordu).
        return Consumer(
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
            );
          },
        );
      },
    );

    Widget grid(List<Note> items) => SliverMasonryGrid.count(
      crossAxisCount: columns,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childCount: items.length,
      itemBuilder: (context, index) {
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
    final bucketsActive = ref.read(noteSortProvider) == NoteSort.updated;

    if (!bucketsActive) {
      if (pinned.isEmpty || others.isEmpty) {
        return [
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverPadding(
            padding: gridPadding,
            sliver: listView ? rows(notes) : grid(notes),
          ),
        ];
      }
      return [
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
              // Alan dışına dokununca odak bırakılır; bar daralır.
              onTapOutside: (_) => focusNode?.unfocus(),
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
          Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SearchModeTab(
                    label: l10n.searchModeText,
                    selected: !semantic,
                    onTap: () {
                      if (semantic) {
                        ref
                            .read(semanticSearchEnabledProvider.notifier)
                            .toggle();
                      }
                    },
                  ),
                  _SearchModeTab(
                    label: l10n.searchModeMeaning,
                    selected: semantic,
                    onTap: () {
                      if (!semantic) {
                        ref
                            .read(semanticSearchEnabledProvider.notifier)
                            .toggle();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _SearchModeTab extends StatelessWidget {
  const _SearchModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
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
