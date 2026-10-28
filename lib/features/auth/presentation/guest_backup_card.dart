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
/// Ana ekranın tepesinde "Google ile giriş yap" kartı çıkar — 2026-10-28'den
/// beri İLK AÇILIŞTAN itibaren (kullanıcı isteği: "ilk girişte google
/// girişini bulmak çok zor, girince ana ekranda üstte görülsün"; eskiden 3.
/// nottan sonra geliyordu); "Sonra" kartı [kGuestReminderSnooze] boyunca gizler,
/// süre bitince kart geri gelir (bağlanana dek kalıcı).
const kGuestReminderNotes = 0;
const kGuestReminderSnooze = Duration(days: 7);
const _snoozeKey = 'guest_reminder_snoozed_until';

/// Saf karar (test edilir).
bool shouldShowGuestReminder({
  required bool anonymous,
  required int noteCount,
  required DateTime now,
  DateTime? snoozedUntil,
}) =>
    anonymous &&
    noteCount >= kGuestReminderNotes &&
    (snoozedUntil == null || now.isAfter(snoozedUntil));

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
    final until = prefs.getInt(_snoozeKey);
    final show = shouldShowGuestReminder(
      anonymous: user?.isAnonymous ?? false,
      noteCount: notes.where((n) => !n.isEmpty).length,
      now: DateTime.now(),
      snoozedUntil: until == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(until),
    );
    if (!show) return const SizedBox.shrink();
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
                        prefs.setInt(
                          _snoozeKey,
                          DateTime.now()
                              .add(kGuestReminderSnooze)
                              .millisecondsSinceEpoch,
                        );
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
}
