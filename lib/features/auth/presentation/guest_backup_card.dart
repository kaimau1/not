import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/notes_repository.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/settings_providers.dart';
import 'auth_providers.dart';

/// **MİSAFİR HESAP HATIRLATMASI** (F4.3, 2026-10-19).
///
/// İlk açılışta sessizce anonim oturum açılır (bkz. `login_screen.dart`);
/// notlar yalnız o uid'de durur — uygulama silinince ya da cihaz değişince
/// geri getirilemez. Kullanıcı bunu fark etmeden onlarca not biriktirebilir.
/// Ana ekranın tepesinde "Google ile giriş yap" kartı İLK AÇILIŞTAN itibaren
/// çıkar (kullanıcı isteği 2026-10-28: "ilk girişte google girişini bulmak
/// çok zor").
///
/// F11.3 (2026-10-31): "Sonra" artık 7 gün sonra aynı kocaman kartı geri
/// getirmez; kart TEK SATIRLIK şeride iner (giriş yolu yine görünür, notlara
/// yer kalır). Not sayısı [kGuestReminderFullAt] eşiklerinden birini "Sonra"
/// denildiği andaki sayıdan sonra geçince tam kart BİR KEZ geri gelir.
const kGuestReminderFullAt = [5, 20];
const _laterCountKey = 'guest_reminder_later_count';
// Eski (≤ Faz 10) "Sonra" kaydı: süreli erteleme. Varsa "0 notta Sonra
// denmiş" sayılır.
const _legacySnoozeKey = 'guest_reminder_snoozed_until';

/// Misafir hatırlatmasının görünümü.
enum GuestReminderMode { none, strip, full }

/// Saf karar (test edilir). [laterAtCount]: "Sonra"ya basıldığı andaki not
/// sayısı (hiç basılmadıysa null).
GuestReminderMode guestReminderMode({
  required bool anonymous,
  required int noteCount,
  int? laterAtCount,
}) {
  if (!anonymous) return GuestReminderMode.none;
  if (laterAtCount == null) return GuestReminderMode.full;
  for (final t in kGuestReminderFullAt) {
    if (laterAtCount < t && noteCount >= t) return GuestReminderMode.full;
  }
  return GuestReminderMode.strip;
}

class GuestBackupCard extends ConsumerStatefulWidget {
  const GuestBackupCard({super.key});

  @override
  ConsumerState<GuestBackupCard> createState() => _GuestBackupCardState();
}

class _GuestBackupCardState extends ConsumerState<GuestBackupCard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final notes = ref.watch(notesStreamProvider).value ?? const [];
    final prefs = ref.watch(sharedPreferencesProvider);
    final noteCount = notes.where((n) => !n.isEmpty).length;
    final laterAt =
        prefs.getInt(_laterCountKey) ??
        (prefs.containsKey(_legacySnoozeKey) ? 0 : null);
    final mode = guestReminderMode(
      anonymous: user?.isAnonymous ?? false,
      noteCount: noteCount,
      laterAtCount: laterAt,
    );
    if (mode == GuestReminderMode.none) return const SizedBox.shrink();
    if (mode == GuestReminderMode.strip) return _strip(context);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Card(
        color: scheme.tertiaryContainer,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.guestReminderTitle,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(color: scheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.guestReminderBody,
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () {
                        unawaited(prefs.setInt(_laterCountKey, noteCount));
                        setState(() {});
                      },
                      child: Text(l10n.guestReminderLater),
                    ),
                    FilledButton.icon(
                      onPressed: () => linkGuestAccount(context, ref),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: Text(l10n.signInWithGoogle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Sonra"dan sonraki tek satırlık şerit: dokununca Google bağlanır.
  Widget _strip(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Material(
        color: scheme.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: const ValueKey('guest-reminder-strip'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => linkGuestAccount(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 18,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.guestReminderTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onTertiaryContainer),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.guestReminderConnect,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onTertiaryContainer,
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
