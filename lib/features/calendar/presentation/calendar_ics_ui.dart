import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/friendly_error.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/doc_picker.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/calendar_repository.dart';
import '../data/ics.dart';

/// Takvimi `.ics` olarak paylaş/kaydet (TAKVIM F52.4).
Future<void> exportCalendarIcs(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(calendarRepositoryProvider);
  if (repo == null) return;
  try {
    final events = await repo.watchEvents().first;
    if (events.isEmpty) {
      messenger.showMessage(l10n.calendarEmpty);
      return;
    }
    final bytes = utf8.encode(encodeIcs(events));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, name: 'takvim.ics', mimeType: 'text/calendar'),
        ],
        fileNameOverrides: const ['takvim.ics'],
        subject: l10n.calendarTitle,
      ),
    );
  } catch (e) {
    messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
  }
}

/// `.ics` dosyasından etkinlikleri içe aktarır; var olanlar atlanır.
Future<void> importCalendarIcs(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(calendarRepositoryProvider);
  if (repo == null) return;
  final file = await DocPicker.pickOne(
    const XTypeGroup(
      label: 'iCalendar',
      extensions: ['ics'],
      mimeTypes: ['text/calendar', 'application/octet-stream'],
    ),
  );
  if (file == null) return;
  try {
    final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    final incoming = parseIcs(text);
    final fresh = newIcsEvents(incoming, await repo.watchEvents().first);
    for (final e in fresh) {
      repo.saveEvent(e);
    }
    messenger.showMessage(
      l10n.calendarIcsImported(fresh.length, incoming.length - fresh.length),
    );
  } catch (e) {
    messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
  }
}
