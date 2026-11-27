import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../notes/domain/smart_lexicon_v2.dart';

/// Seyahat bavulu sihirbazı: gün sayısı, hava durumu ve seyahat türüne göre
/// ölçekli bavul listesi üretir.
Future<List<({String text, Map<String, dynamic> extras})>?>
showTripPackingWizardSheet(BuildContext context) {
  return showAppSheet<List<({String text, Map<String, dynamic> extras})>>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => const _TripPackingWizardSheet(),
  );
}

class _TripPackingWizardSheet extends StatefulWidget {
  const _TripPackingWizardSheet();

  @override
  State<_TripPackingWizardSheet> createState() =>
      _TripPackingWizardSheetState();
}

class _TripPackingWizardSheetState extends State<_TripPackingWizardSheet> {
  int _days = 4;
  TripWeather _weather = TripWeather.mild;
  TripStyle _style = TripStyle.city;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final isTr = l10n.localeName.startsWith('tr');
    final preview = generatePackingPlan(
      days: _days,
      weather: _weather,
      style: _style,
      isTr: isTr,
    );

    String weatherLabel(TripWeather w) => switch (w) {
      TripWeather.hot => l10n.smartListWeatherHot,
      TripWeather.mild => l10n.smartListWeatherMild,
      TripWeather.cold => l10n.smartListWeatherCold,
      TripWeather.rainy => l10n.smartListWeatherRainy,
    };

    String styleLabel(TripStyle s) => switch (s) {
      TripStyle.beach => l10n.smartListStyleBeach,
      TripStyle.city => l10n.smartListStyleCity,
      TripStyle.business => l10n.smartListStyleBusiness,
      TripStyle.international => l10n.smartListStyleIntl,
      TripStyle.camp => l10n.smartListStyleCamp,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, AppSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: l10n.smartListTripWizard),
          const SizedBox(height: AppSpace.s),
          Row(
            children: [
              Expanded(
                child: Text(l10n.smartListWizardDays, style: text.section),
              ),
              Text(
                '$_days',
                key: const ValueKey('wizard-days-value'),
                style: text.sheetTitle.copyWith(color: scheme.primary),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('wizard-days-slider'),
            value: _days.toDouble(),
            min: 1,
            max: 14,
            divisions: 13,
            label: '$_days',
            onChanged: (v) => setState(() => _days = v.round()),
          ),
          const SizedBox(height: AppSpace.s),
          Text(l10n.smartListWizardWeather, style: text.section),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.xs,
            children: [
              for (final w in TripWeather.values)
                ChoiceChip(
                  key: ValueKey('wizard-weather-${w.name}'),
                  label: Text(weatherLabel(w)),
                  selected: _weather == w,
                  showCheckmark: false,
                  onSelected: (_) {
                    AppHaptics.tick();
                    setState(() => _weather = w);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          Text(l10n.smartListWizardStyle, style: text.section),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.xs,
            children: [
              for (final s in TripStyle.values)
                ChoiceChip(
                  key: ValueKey('wizard-style-${s.name}'),
                  label: Text(styleLabel(s)),
                  selected: _style == s,
                  showCheckmark: false,
                  onSelected: (_) {
                    AppHaptics.tick();
                    setState(() => _style = s);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.l),
          FilledButton.icon(
            key: const ValueKey('wizard-apply-packing'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(kMinInteractiveDimension),
            ),
            onPressed: () {
              AppHaptics.thud();
              Navigator.pop(context, preview);
            },
            icon: const Icon(Icons.luggage_outlined),
            label: Text(l10n.smartListApplyPlan(preview.length)),
          ),
        ],
      ),
    );
  }
}

/// Etkinlik / davet sihirbazı: kişi sayısı ve davet türüne göre ölçekli liste.
Future<List<({String text, Map<String, dynamic> extras})>?>
showEventWizardSheet(BuildContext context) {
  return showAppSheet<List<({String text, Map<String, dynamic> extras})>>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => const _EventWizardSheet(),
  );
}

class _EventWizardSheet extends StatefulWidget {
  const _EventWizardSheet();

  @override
  State<_EventWizardSheet> createState() => _EventWizardSheetState();
}

class _EventWizardSheetState extends State<_EventWizardSheet> {
  int _guests = 8;
  EventStyle _style = EventStyle.birthday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final isTr = l10n.localeName.startsWith('tr');
    final preview = generateEventPlan(
      guests: _guests,
      style: _style,
      isTr: isTr,
    );

    String styleLabel(EventStyle s) => switch (s) {
      EventStyle.birthday => l10n.smartListEventBirthday,
      EventStyle.dinner => l10n.smartListEventDinner,
      EventStyle.picnic => l10n.smartListEventPicnic,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, 0, AppSpace.l, AppSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: l10n.smartListEventWizard),
          const SizedBox(height: AppSpace.s),
          Row(
            children: [
              Expanded(
                child: Text(l10n.smartListWizardGuests, style: text.section),
              ),
              Text(
                '$_guests',
                key: const ValueKey('wizard-guests-value'),
                style: text.sheetTitle.copyWith(color: scheme.primary),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('wizard-guests-slider'),
            value: _guests.toDouble(),
            min: 2,
            max: 40,
            divisions: 38,
            label: '$_guests',
            onChanged: (v) => setState(() => _guests = v.round()),
          ),
          const SizedBox(height: AppSpace.s),
          Text(l10n.smartListEventStyle, style: text.section),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.xs,
            children: [
              for (final s in EventStyle.values)
                ChoiceChip(
                  key: ValueKey('wizard-event-${s.name}'),
                  label: Text(styleLabel(s)),
                  selected: _style == s,
                  showCheckmark: false,
                  onSelected: (_) {
                    AppHaptics.tick();
                    setState(() => _style = s);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpace.l),
          FilledButton.icon(
            key: const ValueKey('wizard-apply-event'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(kMinInteractiveDimension),
            ),
            onPressed: () {
              AppHaptics.thud();
              Navigator.pop(context, preview);
            },
            icon: const Icon(Icons.celebration_outlined),
            label: Text(l10n.smartListApplyPlan(preview.length)),
          ),
        ],
      ),
    );
  }
}
