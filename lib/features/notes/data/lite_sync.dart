import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entitlement/data/entitlement_service.dart';
import '../../entitlement/domain/entitlement.dart';
import '../../folders/data/folders_repository.dart';
import '../domain/note.dart';
import 'note_shares_repository.dart';
import 'notes_repository.dart';

/// **LITE EŞİTLEME** (PLAN §1.5 katman tablosu: ücretsizde eşitleme
/// "aralıklı"; yürütücü varsayılanı: 5 dk + arka plana geçerken bir kez +
/// elle "şimdi eşitle").
///
/// Seyreltilen YALNIZ editörün otomatik kaydının bulut yazımıdır
/// ([NotesRepository.updateNote], `SaveCadence.liteInterval`); okuma /
/// dinleme, kart eylemleri (yıldız, sabitle, arşiv…) ve paylaşılan notlar
/// değişmez. Mekanizma editörün mevcut `Debouncer`ıdır — ikinci bir yazma
/// kuyruğu yok. Veri kaybı olmasın diye bekleyen içerik her kayıt
/// aralığında ([SaveCadence.delay]) diskteki günlüğe de yazılır
/// ([NotesRepository.journalNote]); çıkış kapıları (kapanış, arka plan)
/// buluta hemen yazar, çöken oturumun artığını açılışta
/// [liteJournalRecoveryProvider] yazar.
///
/// KİŞİSEL APK / WEB: `instantSync` kapısı bayraksız derlemede hep açık
/// ([EntitlementGate.active] false) → [liteSyncProvider] hep false, hiçbir
/// şey değişmez.
final liteSyncProvider = Provider<bool>(
  (ref) => !ref.watch(proFeatureProvider(ProFeature.instantSync)),
);

/// Editörün bu not için bulut yazımını geciktirmesi gerekir mi — SAF karar.
///
/// * [lite]: `instantSync` hakkı yok.
/// * [ownNote]: başkasının (paylaşılan klasör / ortak not) koleksiyonuna
///   değil kendi koleksiyonuma yazılıyor.
/// * [sharedByMe]: ben başkalarıyla paylaşıyorum (ortak düzenleme anında).
/// * [deviceOnly]: yalnız bu cihazdaki not — buluta zaten gitmez.
/// * [journalReady]: diskteki günlük kullanılabilir (web'de yok → ertelenmez,
///   çünkü çökmeye karşı güvencesiz erteleme veri kaybıdır).
bool liteHoldsCloudWrite({
  required bool lite,
  required bool ownNote,
  required bool sharedByMe,
  required bool deviceOnly,
  required bool journalReady,
}) => lite && ownNote && !sharedByMe && !deviceOnly && journalReady;

/// Not başkalarıyla paylaşılıyor mu (ortak not ya da paylaşılan klasör)?
/// `upload_queue.dart` `_isShared` ile aynı kural, tek seferlik okuma.
///
/// Paylaşım bilgisi HENÜZ gelmediyse (akış yükleniyor) paylaşılıyor sayılır:
/// belirsizlikte ortak düzenleme bozulmasın, kayıt anında gitsin.
bool noteSharedByMe(WidgetRef ref, Note note) {
  final shares = ref.read(myNoteSharesProvider);
  if (!shares.hasValue) return true;
  if (shares.requireValue.containsKey(note.id)) return true;
  final folderId = note.folderId;
  if (folderId == null) return false;
  final folders = ref.read(foldersStreamProvider);
  if (!folders.hasValue) return true;
  return folders.requireValue.any((f) => f.id == folderId && f.isShared);
}

/// Açılışta bir kez: önceki oturumda buluta ulaşmadan kalmış editör içeriğini
/// yazar (bkz. [NotesRepository.recoverJournal]). Günlük boşsa hiçbir şey
/// yapmaz.
final liteJournalRecoveryProvider = Provider<void>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null || !repo.canJournal) return;
  unawaited(repo.recoverJournal());
});
