import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/note_fonts.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../settings/settings_providers.dart';
import '../data/note_shares_repository.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import '../domain/page_notes.dart';
import '../data/drive_store.dart' show localFilesRevisionProvider;
import 'note_actions_sheet.dart';
import 'note_card_media.dart';
import 'notes_providers.dart';

/// Kartın YAKLAŞIK yüksekliği (dp), [width] genişliğinde çizildiğinde.
///
/// NEDEN TAHMİN: ana ekran ızgarası kartları sütunlara ÇİZMEDEN ÖNCE dağıtır
/// (bkz. `dashboard_screen.dart` → `_balancedColumns`). Gerçek yükseklikler
/// ancak yerleşimden sonra bilinir; onlara göre dağıtmak — masonry ızgaranın
/// yaptığı buydu — kartın hangi sütuna düşeceğini her yerleşimde yeniden
/// hesaplatıyor, kart yükseklikleri kıpırdadıkça (seçim, küçük resim yüklenmesi,
/// not güncellemesi) kartlar sütun değiştiriyor ve kullanıcının gördüğü
/// "kaymalar / sağ sütunda kalan boşluklar" oluşuyordu.
///
/// Tahmin YALNIZ DENGEYİ etkiler: sıra ve yerleşim her zaman deterministiktir
/// (n. kart hangi sütuna atandıysa orada, bir öncekinin hemen altında durur),
/// tahmin şaşarsa yalnız en alttaki sütun boşluğu bir miktar büyür.
double estimateNoteCardHeight(Note note, double width) {
  // Kart gövde yazısı ~12 dp; ortalama karakter genişliği yazı boyunun ~0.52'si
  // (kartta not kendi ölçeğini kullanıyor, bkz. [_NotePreview]).
  final charWidth = 12 * note.fontScale.clamp(0.8, 1.4) * 0.52;
  final textWidth = math.max(40.0, width - 24);
  final perLine = math.max(8, textWidth ~/ charWidth);
  int lines(String text, int maxLines) =>
      math.max(1, math.min(maxLines, (text.trim().length / perLine).ceil()));

  var height = 20.0; // dikey dolgu (10 + 10)
  if (note.title.trim().isNotEmpty) {
    height += lines(note.title, 2) * 17.0 + 6;
  }
  if (note.locked) {
    height += 18;
    return height + 24; // kilit satırı + alt meta bandı
  }

  const itemHeight = 19.0;
  switch (note.type) {
    // Arşiv defteri kartta metin notu gibi ölçülür: kartta gösterdiği şey
    // açıklaması + metin girdileri (ekler zaten ek rozetiyle sayılıyor).
    case NoteType.archive:
    case NoteType.text:
      final hasBody = note.body.trim().isNotEmpty;
      final items = [
        for (final i in note.items)
          if (i.text.trim().isNotEmpty) i,
      ];
      if (hasBody) height += lines(note.body, items.isEmpty ? 4 : 2) * 16.0;
      if (items.isNotEmpty) {
        if (hasBody) height += 6;
        final maxItems = hasBody ? 3 : 5;
        height += math.min(items.length, maxItems) * itemHeight;
        if (items.length > maxItems) height += 16;
      }
    case NoteType.checklist:
    case NoteType.ordered:
      // Ayrı ad: `switch` gövdesi TEK kapsam — `items` yukarıda tanımlı.
      final listItems = [
        for (final i in note.items)
          if (i.text.trim().isNotEmpty) i,
      ];
      height += math.min(listItems.length, 6) * itemHeight;
      if (listItems.length > 6) height += 16;
    case NoteType.pdf:
    case NoteType.slides:
      final pages = note.pageNotes.length;
      height += math.min(pages, 5) * itemHeight;
      if (pages > 5) height += 16;
  }

  // Ek önizlemesi (kapak, belge kartı, karolar, dosya satırları): çizimle
  // AYNI plandan ölçülür (bkz. CardMediaPlan).
  final media = CardMediaPlan.of(note);
  if (!media.isEmpty) height += media.estimateHeight(width) + 8;

  // Alt meta satırı (rozet · etiket · tarih) neredeyse her kartta var.
  height += 24;
  return height;
}

/// Tarih biçimlendiricileri (desen + DİL) başına BİR kez kurulur.
///
/// KÖK NEDEN (perf): [formatNoteDate] her çağrısında yeni bir [DateFormat]
/// kuruyordu ve bu çağrı KART BAŞINA yapılır. Ana ekranın önbellek payında
/// ~130 kart canlı duruyor (bkz. dashboard `_kGridCacheExtent`), yani her
/// yeniden çizimde yüzden fazla biçimlendirici kuruluyor ve her biri yerel
/// ayarın tarih sembollerini arıyordu.
///
/// Anahtara DİL de giriyor: `static final` bir biçimlendirici ilk açılıştaki
/// dili ömür boyu taşırdı, kullanıcı Ayarlar'dan dili değiştirince kart
/// tarihleri eski dilde kalırdı.
final Map<String, DateFormat> _dateFormatCache = {};

DateFormat _dateFormat(String pattern) => _dateFormatCache.putIfAbsent(
  '$pattern|${Intl.defaultLocale ?? ''}',
  () => DateFormat(pattern),
);

/// Not tarihini kısa gösterir: bugünse saat, aynı yılsa "5 Tem",
/// eski yıllarsa "5 Tem 2025".
String formatNoteDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return _dateFormat('HH:mm').format(date);
  }
  if (date.year == now.year) return _dateFormat('d MMM').format(date);
  return _dateFormat('d MMM y').format(date);
}

/// Testlerin (ve dil kataloğu değişirse çalışma anının) önbelleği
/// boşaltabilmesi için.
@visibleForTesting
void clearNoteDateFormatCache() => _dateFormatCache.clear();

/// Notu açar; kilitliyse önce kimlik doğrulaması ister.
///
/// Hem ızgara kartı hem liste satırı buradan geçer — kilit kontrolünü iki
/// yerde tekrarlamak, birinde unutulduğunda sessiz bir veri sızıntısı olurdu.
///
/// [_openingNoteId]: aynı karta art arda iki dokunuş (özellikle geniş
/// ekranda liste hep görünürken) aynı notun İKİ editörünü üst üste
/// açabiliyordu; açılış sürerken gelen ikinci dokunuş yutulur.
String? _openingNoteId;

/// [ownerId] verilirse not BAŞKASININ koleksiyonundadır (paylaşılan klasör);
/// editör onu sahibinin altından açar (bkz. `NoteEditorScreen.ownerId`).
/// [readOnly] yalnız okuma yetkisi verilmiş paylaşımlarda alanları kilitler.
Future<void> openNoteRoute(
  BuildContext context,
  Note note, {
  String? ownerId,
  bool readOnly = false,
}) async {
  if (_openingNoteId == note.id) return;
  _openingNoteId = note.id;
  try {
    if (note.locked) {
      final ok = await authenticateForNote(context.l10n.unlockAuthReason);
      if (!ok || !context.mounted) return;
    }
    if (context.mounted) {
      final params = [
        if (ownerId != null) 'owner=$ownerId',
        if (readOnly) 'ro=1',
      ];
      // Arşiv defteri kendi ekranında açılır (bkz. archiveNoteRoutePath).
      // Arşiv/çöp gibi kabuk dışı ekranlardan da doğru yol (bkz.
      // notePushPath — "arşivdeki not siyah ekran" kök nedeni).
      final push = context.pushNote(
        note.type == NoteType.archive
            ? archiveNoteRoutePath(note.id)
            : noteRoutePath(
                note.id,
                query: params.isEmpty ? '' : '?${params.join('&')}',
              ),
      );
      // Rota yığına girdikten hemen sonra kilit açılır (push editör
      // KAPANANA dek tamamlanmaz; onu bekleseydik editör açıkken karttan
      // ikinci kez açmak da engellenirdi — o ayrı bir tercih).
      await Future<void>.delayed(const Duration(milliseconds: 400));
      unawaited(push);
    }
  } finally {
    _openingNoteId = null;
  }
}

/// Kart önizlemesinde notun SATIR İÇİ biçimi (renk, vurgu, kalın, italik,
/// altı çizili, boyut) çizilsin mi? Ayarlar → Görünüm'den kapatılabilir.
///
/// Arama sürerken biçim ÇİZİLMEZ: eşleşmenin sarı vurgusu ile notun kendi
/// renk/vurgu biçimi üst üste binince hangisinin arama sonucu olduğu
/// okunmuyordu. Sorgu boşalınca biçimli görünüm geri gelir.
Widget noteBodyText(
  BuildContext context,
  String text,
  String query, {
  required bool rich,
  TextStyle? style,
  int? maxLines,
}) {
  if (!rich || query.isNotEmpty) {
    // Biçim işaretleri (**kalın**, %%2:renk%%) ham hâlleriyle GÖSTERİLMEZ.
    return highlightedText(
      context,
      stripRichMarkers(text),
      query,
      style: style,
      maxLines: maxLines,
    );
  }
  return Text.rich(
    TextSpan(
      style: style,
      children: richSpans(
        text,
        style,
        // Kart bir editör değil: bağlantılar tıklanamadığı için ayrıca
        // renklendirilmez (linkColor null = ölçüm yolundaki davranış).
        palette: NoteColors.richPalette,
        markerColor: const Color(0x00000000),
      ),
    ),
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
  );
}

/// Aranan kelimeyi kalın ve renkli vurgulayan metin parçaları üretir.
Widget highlightedText(
  BuildContext context,
  String text,
  String query, {
  TextStyle? style,
  int? maxLines,
}) {
  if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
  final scheme = Theme.of(context).colorScheme;
  final lower = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final spans = <TextSpan>[];
  var start = 0;
  while (true) {
    final index = lower.indexOf(lowerQuery, start);
    if (index < 0) {
      spans.add(TextSpan(text: text.substring(start)));
      break;
    }
    if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
    spans.add(
      TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: scheme.primary,
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.45),
        ),
      ),
    );
    start = index + query.length;
  }
  return Text.rich(
    TextSpan(style: style, children: spans),
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : null,
  );
}

/// Dashboard'daki kompakt not kartı.
class NoteCard extends ConsumerWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.highlightQuery = '',
    this.ownerId,
    this.readOnly = false,
  });

  final Note note;

  /// PAYLAŞILAN klasörde çizilen kartta notun SAHİBİ; kendi notlarımda null.
  /// Kart bunu editöre taşır, yoksa editör notu kendi koleksiyonumda arar ve
  /// bulamaz (bkz. `NoteEditorScreen.ownerId`).
  final String? ownerId;

  /// Paylaşılan klasörde YALNIZ OKUMA yetkisi varsa true — editör kilitli
  /// açılır (bkz. `NoteEditorScreen.readOnly`).
  final bool readOnly;

  /// Aktif arama sorgusu; boş değilse eşleşmeler vurgulanır.
  final String highlightQuery;

  Future<void> _openNote(BuildContext context) =>
      openNoteRoute(context, note, ownerId: ownerId, readOnly: readOnly);

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
        ref.read(notesRepositoryProvider)?.setPinned(note.id, !note.pinned);
      case 'star':
        ref.read(notesRepositoryProvider)?.setStarred(note.id, !note.starred);
      case 'delete':
        _delete(context, ref);
    }
  }

  /// Kart içeriğini notun zemin görselinin üstüne serer.
  Widget _withNoteBackground(Note note, Widget child) {
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
      borderRadius: BorderRadius.circular(12),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // select() ŞART: küme her değişimde yeni bir Set olduğundan kümenin
    // kendisini izlemek, TEK not seçilince görünürdeki BÜTÜN kartları yeniden
    // çiziyordu; artık yalnız durumu değişen kart çizilir.
    final selectionActive = ref.watch(
      selectedNoteIdsProvider.select((s) => s.isNotEmpty),
    );
    final selected = ref.watch(
      selectedNoteIdsProvider.select((s) => s.contains(note.id)),
    );
    final richPreview = ref.watch(cardRichPreviewProvider);
    // Drive'dan bir ek inince kart küçük resmini yerel kopyadan çizsin.
    ref.watch(localFilesRevisionProvider);

    void toggleSelection() =>
        ref.read(selectedNoteIdsProvider.notifier).toggle(note.id);

    final hasTitle = note.title.trim().isNotEmpty;
    // Yalnız BU notun paylaşım durumu izlenir: ayna akışı her değiştiğinde
    // bütün kartlar yeniden kurulmasın.
    final shared =
        ownerId != null ||
        ref.watch(
          myNoteSharesProvider.select(
            (m) => m.value?.containsKey(note.id) ?? false,
          ),
        );
    // Durum simgeleri ALT meta satırına indi. Eskiden başlık satırının sağında
    // akıyorlardı ve başlığı sola sıkıştırıyorlardı: üç rozetli bir notta
    // başlık iki kelimede kesiliyordu. Altta, tarihle aynı bantta duruyorlar.
    final statusIcons = <Widget>[
      if (note.pinned)
        Icon(Icons.push_pin, size: 13, color: scheme.onSurfaceVariant),
      if (note.starred)
        Icon(Icons.star, size: 13, color: Colors.amber.shade600),
      if (!note.locked && note.aiSummary != null)
        Icon(Icons.auto_awesome, size: 13, color: scheme.primary),
      if (note.reminderAt != null)
        Icon(Icons.alarm, size: 13, color: scheme.onSurfaceVariant),
      // ORTAK NOT: başkalarıyla paylaşılan (ya da bana paylaşılmış) not
      // kartında da belli olsun — Keep'teki ortak çalışan simgesi gibi.
      if (shared) Icon(Icons.people_alt, size: 13, color: scheme.primary),
      // YALNIZ BU CİHAZDA (senkron kapalı) — kart bakışta söylesin.
      if (note.localOnly)
        Icon(Icons.cloud_off_outlined, size: 13, color: scheme.tertiary),
    ];
    // Üst satır yalnızca başlık varsa çizilir. Başlıksız notta (madde 5) boş
    // bir üst bant bırakılmaz; içerik doğrudan tepeden başlar.
    final showTopRow = hasTitle;
    // Kilitli notta içerik (ekler dahil) kartta gösterilmez.
    final media = note.locked ? null : CardMediaPlan.of(note);
    final hero = media?.hero;
    // Balonlu notun belge kapağı (video/görsel kapağıyla aynı yerde).
    final cover = media?.cover;
    final hasCover = hero != null || cover != null;
    final borderWidth = note.frameColor != NoteColor.none ? 2.5 : 1.0;

    final padded = Padding(
      // Başlıksız kartta sağdan biraz içerik payı bırakılır ki ilk satır
      // köşedeki üç nokta düğmesinin altına girmesin (kapak varsa düğme
      // kapağın üstünde durur, pay gerekmez).
      padding: EdgeInsetsDirectional.fromSTEB(
        12,
        hasCover ? 8 : 10,
        showTopRow || hasCover ? 12 : 20,
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
              padding: const EdgeInsetsDirectional.only(bottom: 6, end: 22),
              child: noteBodyText(
                context,
                // Biçimli başlık kartta da biçimli görünür; ayar kapalıyken
                // (ya da arama sürerken) düz `displayTitle` çizilir.
                note.title,
                highlightQuery,
                rich: richPreview,
                maxLines: 2,
                // Başlık kartta da KENDİ yazı tipini kullanır (gövdeninkini
                // değil): başlığın yazı tipi artık gövdeden bağımsız.
                style: applyNoteFont(
                  (Theme.of(context).textTheme.titleSmall ?? const TextStyle())
                      .copyWith(fontWeight: FontWeight.w600),
                  note.titleFontFamily,
                ),
              ),
            ),
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
                Text(
                  context.l10n.lockedNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          else ...[
            _NotePreview(
              note: note,
              highlightQuery: highlightQuery,
              rich: richPreview,
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
          ],
          // ALT META SATIRI: durum simgeleri · ilk etiket · sağda tarih.
          // Üçü tek bantta olduğu için kartın yüksekliği rozet sayısına göre
          // değişmiyor; eskiden etiketler Wrap ile ikinci satıra taşıyordu.
          if (statusIcons.isNotEmpty ||
              note.tags.isNotEmpty ||
              note.updatedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (final icon in statusIcons)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: icon,
                  ),
                if (note.tags.isNotEmpty)
                  Flexible(
                    child: Text(
                      '#${note.tags.first}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const Spacer(),
                if (note.updatedAt != null)
                  Text(
                    formatNoteDate(note.updatedAt!),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    // KAPAK kartın tepesinde, KENARDAN KENARA (Keep'teki gibi): üste
    // sabitli video/görsel ya da notun tek görseli/videosu. Kenarlık `Ink`
    // tarafından çocuğa dolgu olarak eklendiği için kapak çerçevenin İÇİNDE
    // kalır; köşe yarıçapı kenarlık kadar küçültülür.
    final content = !hasCover
        ? padded
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12 - borderWidth),
                ),
                child: hero != null
                    ? CardHeroMedia(attachment: hero)
                    : CardDocumentCover(
                        document: cover!,
                        bubbleCount: media!.bubbleCount,
                      ),
              ),
              padded,
            ],
          );

    final card = Material(
      color: NoteColors.surface(context, note.color),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Seçim modunda dokunuş seçimi değiştirir; normalde notu açar. Uzun
        // basış dashboard sarmalayıcısında yönetilir: yerinde bırakınca çoklu
        // seçim, sürükleyince yeniden sıralama (üç nokta menüsündeki "Seç" de
        // durur).
        onTap: selectionActive ? toggleSelection : () => _openNote(context),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
            border: Border.all(
              color: note.frameColor != NoteColor.none
                  ? NoteColors.swatch(note.frameColor)
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: borderWidth,
            ),
          ),
          // Notun ZEMİN görseli kartta da görünür (kullanıcı isteği: "her
          // notun zemin görseli dashboard'ta da görülmeli"). Editördeki
          // görünürlük ayarı burada da geçerli; görsel kartın köşelerine
          // kırpılır ve içeriğin ARKASINDA durur.
          child: _withNoteBackground(note, content),
        ),
      ),
    );

    // **EKRAN OKUYUCU** (TalkBack/Narrator): kart onlarca küçük parçadan
    // (başlık, gövde, madde satırları, rozetler, tarih) oluşuyor ve hepsi tek
    // tek okunuyordu — bir notu geçmek için on kaydırma gerekiyordu. Kart
    // artık TEK bir düğüm: "başlık, özet, durum" tek seferde okunur, seçili
    // olup olmadığı da söylenir.
    // Etiket UCUZ tutulur: `toPlainText()` notun bütün maddelerini dolaşıp
    // yeni bir dizgi kurar ve bu KART BAŞINA, HER build'de olurdu (önbellek
    // payında ~130 kart canlı). Ekran okuyucunun önizlemesi için notun ilk
    // birkaç satırı zaten yeterli; gövde sınırlı bir dilimden alınır.
    const previewLimit = 160;
    final rawBody = note.body.length > previewLimit
        ? note.body.substring(0, previewLimit)
        : note.body;
    final semanticLabel = [
      if (note.locked)
        context.l10n.lockedNote
      else ...[
        if (hasTitle) note.displayTitle.trim(),
        stripRichMarkers(rawBody).trim(),
        if (note.items.isNotEmpty)
          context.l10n.noteStatsItems(
            note.items.where((i) => i.text.trim().isNotEmpty).length,
          ),
      ],
      if (note.pinned) context.l10n.pin,
      if (note.starred) context.l10n.star,
      if (note.reminderAt != null) context.l10n.remindersTitle,
    ].where((s) => s.isNotEmpty).join('. ');

    // SİLİNİRKEN küçülüp solar (bkz. leavingNotesProvider) — yalnız bu kart
    // izler, ızgaranın geri kalanı yeniden çizilmez.
    final leaving = ref.watch(
      leavingNotesProvider.select((s) => s.contains(note.id)),
    );
    // BASINCA HAFİFÇE ÇÖKER (iOS dokunsal hissi — bkz. PressScale): dönüşüm
    // RepaintBoundary'nin DIŞINDA, yani kartın önbellekli katmanı yalnız
    // ölçeklenir, yeniden boyanmaz.
    return _Leaving(
      leaving: leaving,
      child: PressScale(
        enabled: !selectionActive,
        child: RepaintBoundary(
          child: Semantics(
            container: true,
            button: true,
            selected: selectionActive ? selected : null,
            label: semanticLabel,
            child: GestureDetector(
              // Sağ tık HER platformda: fareli tablet (Android) ve web de
              // masaüstü gibi bağlam menüsü alır. Dokunmatik ekran ikincil
              // dokunuş üretmediği için telefonda davranış değişmez.
              // Paylaşılan notun menüsü yok (bkz. aşağıdaki ⋮ notu).
              onSecondaryTapUp: ownerId != null
                  ? null
                  : (details) =>
                        _showContextMenu(context, ref, details.globalPosition),
              child: Stack(
                children: [
                  card,
                  // Üç nokta hızlı işlem düğmesi (madde 5): kartın SAĞ ÜST KÖŞESİnde
                  // durur — ikon köşeye hizalı, dokunma alanı 36dp. Seçim modunda
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
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => showNoteActionsSheet(context, ref, note),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Align(
                              alignment: AlignmentDirectional.topEnd,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                // Kapağın üstünde düğme koyu yuvarlakla okunur
                                // kalır (açık renkli fotoğrafta kaybolmasın).
                                child: !hasCover
                                    ? Icon(
                                        Icons.more_vert,
                                        size: 18,
                                        color: scheme.onSurfaceVariant,
                                      )
                                    : DecoratedBox(
                                        decoration: const BoxDecoration(
                                          color: Color(0x66000000),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(2),
                                          child: Icon(
                                            Icons.more_vert,
                                            size: 18,
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
                  // Seçim çerçevesi: yerleşimi değiştirmeyen boya katmanı
                  // (yukarıdaki kök nedene bak). `IgnorePointer` şart — katman
                  // kartın tamamını kapladığı için dokunuşu yutardı.
                  if (selected)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }
}

// _MiniBadge (etiket/alarm için küçük hap rozeti) kaldırıldı: kart meta
// satırı artık düz simge + metin, ayrı bir zemin kutusu taşımıyor.

class _NotePreview extends StatelessWidget {
  const _NotePreview({
    required this.note,
    required this.rich,
    this.highlightQuery = '',
  });

  final Note note;
  final String highlightQuery;

  /// Satır içi biçim çizilsin mi (Ayarlar → Görünüm).
  final bool rich;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Kart önizlemesi notun KENDİ yazı tipini ve boyut çarpanını kullanır:
    // kullanıcı yazı tipini değiştirdiğinde ana ekranda da görmeli, yoksa
    // seçim yalnız editörde varmış gibi duruyordu. Kartın kendi küçük taban
    // boyutu korunur; çarpan onun üzerine biner (ızgara bozulmasın diye
    // makul bir tavanla).
    final cardBase = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final bodyStyle = applyNoteOpacity(
      applyNoteFont(
        cardBase.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.85),
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
        final files = note.attachments.length;
        final texts = note.items.where((i) => i.text.trim().isNotEmpty).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 13,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.l10n.archiveNotebook,
                    style: bodyStyle.copyWith(
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBody)
              noteBodyText(
                context,
                note.body,
                highlightQuery,
                rich: rich,
                maxLines: items.isEmpty ? 4 : 2,
                style: bodyStyle,
              ),
            if (items.isNotEmpty) ...[
              if (hasBody) const SizedBox(height: 6),
              for (final item in items.take(maxItems))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: 6,
                          top: 1,
                        ),
                        child: Icon(
                          item.checked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: noteBodyText(
                          context,
                          item.text,
                          highlightQuery,
                          // İşaretli madde ÜSTÜ ÇİZİLİ ve soluk çizilir; o
                          // stil satır içi biçimin üstünde kalmalı, bu yüzden
                          // biçimli çizim yalnız işaretsiz maddede.
                          rich: rich && !item.checked,
                          maxLines: 1,
                          style: item.checked
                              ? bodyStyle.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                )
                              : bodyStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              if (items.length > maxItems)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    context.l10n.moreItemsCount(items.length - maxItems),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
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
        final shown = visible.take(6).toList();
        final remaining = visible.length - shown.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < shown.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.type == NoteType.checklist)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: 6,
                          top: 1,
                        ),
                        child: Icon(
                          shown[i].checked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: Text('${i + 1}.', style: bodyStyle),
                      ),
                    Expanded(
                      child: noteBodyText(
                        context,
                        // Ham biçim işaretleri (**kalın**, %%2:renk%%) HİÇBİR
                        // durumda görünmez: ayar kapalıyken sökülür, açıkken
                        // görünmez çizilip yerine biçim uygulanır. KÖK NEDEN:
                        // bu dal bir dönem atlanmıştı, liste notlarının
                        // önizlemesinde ham işaretler görünüyordu.
                        shown[i].text,
                        highlightQuery,
                        rich:
                            rich &&
                            !(shown[i].checked &&
                                note.type == NoteType.checklist),
                        maxLines: 1,
                        style:
                            shown[i].checked && note.type == NoteType.checklist
                            ? bodyStyle.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              )
                            : bodyStyle,
                      ),
                    ),
                  ],
                ),
              ),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  context.l10n.moreItemsCount(remaining),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
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
                        entry.text,
                        highlightQuery,
                        rich: rich,
                        maxLines: 1,
                        style: bodyStyle,
                      ),
                    ),
                  ],
                ),
              ),
            if (morePages > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  context.l10n.moreItemsCount(morePages),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
    }
  }
}

/// Liste görünümündeki not satırı.
///
/// Izgaradaki [NoteCard]'ın "tek sütuna sıkıştırılmış" hâli DEĞİL: kart
/// yüksekliği içeriğe göre değişir, satır sabittir. Tarama için tasarlandı —
/// çok notu olan kullanıcı kartlarda ikinci ekrana taşan bir listeyi
/// kaydırmak yerine tek bakışta on beş başlık görsün.
class NoteListRow extends ConsumerWidget {
  const NoteListRow({
    super.key,
    required this.note,
    required this.selected,
    required this.selectionActive,
  });

  final Note note;
  final bool selected;
  final bool selectionActive;

  /// Satırın türünü anlatan simge. Kilitli not içeriğini göstermediği için
  /// kilit simgesi tür simgesinin önüne geçer.
  IconData get _icon {
    if (note.locked) return Icons.lock_outline;
    return switch (note.type) {
      NoteType.checklist => Icons.checklist,
      NoteType.ordered => Icons.format_list_numbered,
      NoteType.pdf => Icons.picture_as_pdf_outlined,
      NoteType.slides => Icons.slideshow_outlined,
      NoteType.archive => Icons.inventory_2_outlined,
      NoteType.text => Icons.notes,
    };
  }

  /// Satırın solu: notun görseli/videosu varsa küçük resmi (video oynat
  /// işaretiyle), yoksa tür simgesi. Kilitli notta hep simge.
  Widget _rowLeading(ColorScheme scheme) {
    final media = note.locked ? null : CardMediaPlan.of(note);
    final visual = media?.hero ?? media?.strip.firstOrNull;
    if (visual == null) {
      return Icon(_icon, size: 20, color: scheme.onSurfaceVariant);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 40,
        height: 40,
        child: CardMediaTile(attachment: visual),
      ),
    );
  }

  /// Tek satırlık önizleme. Kilitli notta içerik SIZDIRILMAZ.
  String _preview(BuildContext context) {
    if (note.locked) return context.l10n.lockedNote;
    // Biçim işaretleri BURADA da sökülür: satır önizlemesi tek satırda 46
    // karakterde kesiliyor, işaretli metin hem ham `**` gösteriyor hem de
    // kesme işaretin ortasına düşebiliyordu (kart önizlemesi bunu çoktan
    // yapıyordu, satır dalı atlanmıştı).
    final source = note.body.trim().isNotEmpty
        ? stripRichMarkers(note.body)
        : [for (final i in note.items) stripRichMarkers(i.text)].join(' · ');
    final flat = source.replaceAll('\n', ' ').trim();
    // 46 karakter: iki satırlık bir cümlenin başı. Daha uzunu zaten
    // ellipsize edilirdi, kısaltmak ölçümü ucuzlatıyor.
    return flat.length > 46 ? '${flat.substring(0, 46)}…' : flat;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _preview(context);
    return Material(
      color: selected ? scheme.secondaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: selectionActive
            ? () => ref.read(selectedNoteIdsProvider.notifier).toggle(note.id)
            : () => openNoteRoute(context, note),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowLeading(scheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      note.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (note.updatedAt != null)
                    Text(
                      formatNoteDate(note.updatedAt!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.pinned)
                        Icon(
                          Icons.push_pin,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      if (note.starred)
                        Icon(
                          Icons.star,
                          size: 13,
                          color: Colors.amber.shade600,
                        ),
                      if (note.reminderAt != null)
                        Icon(
                          Icons.alarm,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Silinen kartın çıkışı: küçülerek solar (bkz. [leavingNotesProvider]).
/// Çıkarken dokunuş almaz — ikinci bir dokunuş silinmekte olan notu açmasın.
class _Leaving extends StatelessWidget {
  const _Leaving({required this.leaving, required this.child});

  final bool leaving;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: leaving,
    child: AnimatedScale(
      scale: leaving ? 0.82 : 1,
      duration: LeavingNotesNotifier.exit,
      curve: Curves.easeInCubic,
      child: AnimatedOpacity(
        opacity: leaving ? 0 : 1,
        duration: LeavingNotesNotifier.exit,
        curve: Curves.easeIn,
        child: child,
      ),
    ),
  );
}
