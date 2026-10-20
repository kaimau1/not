import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../settings/data/permissions_service.dart';
import '../data/place_reminders.dart';
import '../domain/note.dart';
import '../../../core/widgets/app_sheet.dart';

/// **KONUM HATIRLATICISI levhası** (kullanıcı isteği 2026-09-23: "markete
/// gelince hatırlat").
///
/// Yer iki yoldan seçilir: şu anki konum (tek dokunuş — "evden çıkınca
/// hatırlat") ya da adres araması (sistemin Geocoder'ı; harita anahtarı
/// gerekmiyor). Ardından varınca/ayrılınca ve yarıçap. İzin iki adımda
/// istenir: önce konum, sonra ayrı bir açıklamayla "her zaman" — Android
/// ikisini tek istekte vermiyor ve gerekçesi söylenmeden istenen arka plan
/// izni çoğu kullanıcıda reddediliyor.
Future<void> showPlaceReminderSheet(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  await ref.read(placeRemindersProvider.notifier).refresh();
  if (!context.mounted) return;
  await showAppSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _PlaceSheet(note: note),
    ),
  );
}

class _PlaceSheet extends ConsumerStatefulWidget {
  const _PlaceSheet({required this.note});

  final Note note;

  @override
  ConsumerState<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends ConsumerState<_PlaceSheet> {
  final _query = TextEditingController();
  final _debounce = Debouncer();
  List<({String name, double lat, double lng})> _results = const [];
  bool _searching = false;
  bool _busy = false;

  ({String name, double lat, double lng})? _picked;
  bool _exit = false;
  double _radius = 200;

  PlaceReminderService get _service => ref.read(placeReminderServiceProvider);

  @override
  void dispose() {
    _query.dispose();
    _debounce.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(message);
  }

  /// Ön plan konum izni (konum okumak ve adres araması için yeter).
  Future<bool> _ensureForeground() async {
    var state = await _service.permission();
    if (state == PlacePermission.none) {
      state = await _service.request(background: false);
    }
    if (state == PlacePermission.none) {
      if (mounted) _snack(context.l10n.placeNeedPermission);
      return false;
    }
    return true;
  }

  /// "Her zaman" izni — geofence uygulama kapalıyken ancak bununla çalışır.
  Future<bool> _ensureBackground() async {
    if (!await _ensureForeground()) return false;
    if (await _service.permission() == PlacePermission.background) return true;
    if (!mounted) return false;
    final l10n = context.l10n;
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.placeBackgroundTitle),
        content: Text(l10n.placeNeedBackground),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.placeOpenSettings),
          ),
        ],
      ),
    );
    if (go != true) return false;
    final state = await _service.request(background: true);
    if (state == PlacePermission.background) return true;
    // Bazı sürümlerde istek sessizce reddediliyor: ayar sayfasına yönlendir.
    await ref.read(permissionsServiceProvider).openAppSettings();
    return false;
  }

  Future<void> _useCurrent() async {
    if (!await _ensureForeground()) return;
    setState(() => _busy = true);
    final here = await _service.currentLocation();
    if (!mounted) return;
    setState(() => _busy = false);
    if (here == null) {
      _snack(context.l10n.placeNoLocation);
      return;
    }
    setState(
      () => _picked = (
        name: context.l10n.placeCurrent,
        lat: here.lat,
        lng: here.lng,
      ),
    );
  }

  void _onQuery(String value) {
    _debounce(() async {
      final q = value.trim();
      if (q.length < 3) {
        if (mounted) setState(() => _results = const []);
        return;
      }
      if (mounted) setState(() => _searching = true);
      final found = await _service.geocode(q);
      if (!mounted || _query.text.trim() != q) return;
      setState(() {
        _results = found;
        _searching = false;
      });
    });
  }

  Future<void> _save() async {
    final picked = _picked;
    if (picked == null) return;
    if (!await _ensureBackground()) return;
    if (!mounted) return;
    final l10n = context.l10n;
    final title = widget.note.displayTitle.trim().isEmpty
        ? l10n.remindersUntitled
        : widget.note.displayTitle.trim();
    setState(() => _busy = true);
    final error = await _service.add(
      PlaceReminder(
        id: widget.note.id,
        lat: picked.lat,
        lng: picked.lng,
        radius: _radius,
        exit: _exit,
        title: title,
        body: _exit
            ? l10n.placeLeftBody(picked.name)
            : l10n.placeArrivedBody(picked.name),
        place: picked.name,
      ),
    );
    await ref.read(placeRemindersProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      _snack(switch (error) {
        'no_permission' => l10n.placeNeedPermission,
        'no_background' => l10n.placeNeedBackground,
        'location_off' => l10n.placeLocationOff,
        _ => l10n.placeFailed,
      });
      return;
    }
    Navigator.pop(context);
    _snack(l10n.placeSet);
  }

  Future<void> _remove() async {
    await _service.remove(widget.note.id);
    await ref.read(placeRemindersProvider.notifier).refresh();
    if (!mounted) return;
    Navigator.pop(context);
    _snack(context.l10n.placeRemoved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final existing = ref
        .watch(placeRemindersProvider)
        .value?[widget.note.id];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.place_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.placeReminder,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.placeReminderHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (existing != null) ...[
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(existing.place),
                    subtitle: Text(
                      '${existing.exit ? l10n.placeLeave : l10n.placeArrive}'
                      ' · ${existing.radius.round()} m',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _remove,
                  icon: const Icon(Icons.location_off_outlined),
                  label: Text(l10n.placeRemove),
                ),
                const Divider(height: 28),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location),
                title: Text(l10n.placeCurrent),
                selected: _picked?.name == l10n.placeCurrent,
                onTap: _busy ? null : _useCurrent,
              ),
              TextField(
                controller: _query,
                onChanged: _onQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.placeSearchHint,
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (!_searching &&
                  _query.text.trim().length >= 3 &&
                  _results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.placeSearchNone),
                ),
              for (final r in _results)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(
                    r.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: _picked == r,
                  onTap: () => setState(() => _picked = r),
                ),
              if (_picked != null) ...[
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.login),
                      label: Text(l10n.placeArrive),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.placeLeave),
                    ),
                  ],
                  selected: {_exit},
                  onSelectionChanged: (v) => setState(() => _exit = v.first),
                ),
                const SizedBox(height: 12),
                Text(l10n.placeRadius, style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final r in const [100.0, 200.0, 500.0, 1000.0])
                      ChoiceChip(
                        label: Text(r >= 1000 ? '1 km' : '${r.round()} m'),
                        selected: _radius == r,
                        onSelected: (_) => setState(() => _radius = r),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : () => unawaited(_save()),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(l10n.placeSave),
                ),
              ],
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
