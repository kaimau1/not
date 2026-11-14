part of '../settings_screen.dart';

/// **KALEM, YAZIM VE EKRAN** (kullanıcı isteği 2026-11-10: "ayarlarda eksik
/// ayarlar var, yeni bir kategori aç, eksiklerin hepsini oraya koy"). Bu
/// alandaki her ayar daha önce YALNIZ kendi ekranından (kalem tepsisinin
/// ayar kartı, hızlı satırdaki yazım düğmesine basılı tutmak, Süz levhası,
/// takvim şeridi) değiştirilebiliyordu; Ayarlar'da ve ayar aramasında yoktu.
/// Kayıt aynı yer: buradaki anahtar ile o ekrandaki anahtar aynı değeri
/// değiştirir.
List<_SettingRow> _writingRows(AppLocalizations l10n) => [
  _SettingRow(
    SectionLabel(l10n.settingsPenSection),
    title: l10n.settingsPenSection,
    keywords: 'kalem stylus s pen el yazisi',
  ),
  _SettingRow(
    _InkSwitch(
      key: const ValueKey('settings-ink-auto-stylus'),
      icon: Icons.draw_outlined,
      title: l10n.inkAutoStylusTitle,
      subtitle: l10n.inkAutoStylusInfo,
      read: () => InkToolMemory.autoStylus,
      write: InkToolMemory.saveAutoStylus,
    ),
    title: l10n.inkAutoStylusTitle,
    keywords: '${l10n.inkAutoStylusInfo} kalem algila otomatik',
  ),
  _SettingRow(
    InkFingerToolPicker(
      key: const ValueKey('settings-ink-finger-tool'),
      onChanged: (t) {
        InkToolMemory.saveFingerTool(t);
        InkToolMemory.toolChanged();
      },
    ),
    title: l10n.inkFingerToolTitle,
    keywords:
        '${l10n.inkPenOnlyTitle} ${l10n.inkFingerToolInfo} parmak kaydir ciz sil silgi avuc',
  ),
  _SettingRow(
    _InkSwitch(
      icon: Icons.line_weight_rounded,
      title: l10n.inkPressureTitle,
      subtitle: l10n.inkPressureInfo,
      read: () => InkToolMemory.pressure,
      write: InkToolMemory.savePressure,
    ),
    title: l10n.inkPressureTitle,
    keywords: '${l10n.inkPressureInfo} basinc kalinlik',
  ),
  _SettingRow(
    _InkSwitch(
      icon: Icons.category_outlined,
      title: l10n.inkShapeSnapTitle,
      subtitle: l10n.inkShapeSnapInfo,
      read: () => InkToolMemory.shapeSnap,
      write: InkToolMemory.saveShapeSnap,
    ),
    title: l10n.inkShapeSnapTitle,
    keywords: '${l10n.inkShapeSnapInfo} sekil cizgi daire kare',
  ),
  _SettingRow(
    _InkSwitch(
      icon: Icons.auto_fix_high_outlined,
      title: l10n.inkShapeSuggestTitle,
      subtitle: l10n.inkShapeSuggestInfo,
      read: () => InkToolMemory.shapeSuggest,
      write: InkToolMemory.saveShapeSuggest,
    ),
    title: l10n.inkShapeSuggestTitle,
    keywords: '${l10n.inkShapeSuggestInfo} sekil oneri',
  ),
  _SettingRow(
    _InkSwitch(
      icon: Icons.spellcheck_rounded,
      title: l10n.inkMarkFixTitle,
      subtitle: l10n.inkMarkFixInfo,
      read: () => InkToolMemory.markFix ?? false,
      write: InkToolMemory.saveMarkFix,
    ),
    title: l10n.inkMarkFixTitle,
    keywords: '${l10n.inkMarkFixInfo} isaret duzelt karala',
  ),
  _SettingRow(
    _InkSwitch(
      icon: Icons.cleaning_services_outlined,
      title: l10n.inkPartialEraserTitle,
      subtitle: l10n.inkPartialEraserInfo,
      read: () => InkToolMemory.partialEraser,
      write: InkToolMemory.savePartialEraser,
    ),
    title: l10n.inkPartialEraserTitle,
    keywords: '${l10n.inkPartialEraserInfo} silgi',
  ),
  _SettingRow(
    SectionLabel(l10n.settingsSpellSection),
    title: l10n.settingsSpellSection,
    keywords: 'yazim duzelt otomatik',
  ),
  _SettingRow(
    ValueListenableBuilder<bool>(
      valueListenable: AutoSpell.enabled,
      builder: (_, on, _) => SwitchListTile(
        key: const ValueKey('settings-spell-auto'),
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.spellcheck_rounded, size: 20),
        title: Text(l10n.spellAutoTitle),
        subtitle: Text(l10n.spellAutoSubtitle),
        value: on,
        onChanged: (_) => AutoSpell.toggle(),
      ),
    ),
    title: l10n.spellAutoTitle,
    keywords: '${l10n.spellAutoSubtitle} yazim duzelt',
  ),
  _SettingRow(
    ValueListenableBuilder<bool>(
      valueListenable: AutoSpell.learning,
      builder: (_, on, _) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.school_outlined, size: 20),
        title: Text(l10n.spellLearnTitle),
        value: on,
        onChanged: AutoSpell.setLearning,
      ),
    ),
    title: l10n.spellLearnTitle,
    keywords: 'ogrenen yazim',
  ),
  _SettingRow(
    Builder(
      builder: (context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(AppIcons.notebook, size: 20),
        title: Text(l10n.spellLearnedTitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => unawaited(showSpellSettings(context)),
      ),
    ),
    title: l10n.spellLearnedTitle,
    keywords: 'ogrenilen kelime sozluk sil',
  ),
  _SettingRow(
    SectionLabel(l10n.settingsScreenSection),
    title: l10n.settingsScreenSection,
    keywords: 'ana ekran serit',
  ),
  _SettingRow(
    _PrefSwitch(
      provider: homeCalendarStripProvider,
      icon: Icons.calendar_view_week_outlined,
      title: l10n.homeCalendarStrip,
      subtitle: l10n.homeCalendarStripInfo,
    ),
    title: l10n.homeCalendarStrip,
    keywords: '${l10n.homeCalendarStripInfo} takvim serit',
  ),
  _SettingRow(
    _PrefSwitch(
      provider: showHolidaysProvider,
      icon: Icons.celebration_outlined,
      title: l10n.calendarHolidays,
    ),
    title: l10n.calendarHolidays,
    keywords: 'tatil bayram resmi dini takvim',
  ),
  _SettingRow(
    _PrefSwitch(
      provider: homeFolderStripHiddenProvider,
      icon: Icons.folder_off_outlined,
      title: l10n.homeFolderStripHide,
    ),
    title: l10n.homeFolderStripHide,
    keywords: 'klasor satir serit gizle',
  ),
  _SettingRow(
    _PrefSwitch(
      provider: showAllNotesProvider,
      icon: Icons.all_inbox_outlined,
      title: l10n.settingsShowAllNotes,
      subtitle: l10n.settingsShowAllNotesInfo,
    ),
    title: l10n.settingsShowAllNotes,
    keywords: '${l10n.settingsShowAllNotesInfo} tumu klasor ana ekran',
  ),
  _SettingRow(
    _PrefSwitch(
      provider: allNotesGroupByFolderProvider,
      icon: Icons.view_agenda_outlined,
      title: l10n.groupByFolder,
    ),
    title: l10n.groupByFolder,
    keywords: 'tumu klasor baslik grupla',
  ),
  _SettingRow(
    _PrefSwitch(
      provider: attachmentsExpandedProvider,
      icon: Icons.attach_file_rounded,
      title: l10n.settingsAttachmentsExpanded,
    ),
    title: l10n.settingsAttachmentsExpanded,
    keywords: 'ek serit not ekrani acik',
  ),
  _SettingRow(
    _PrefSwitch(
      provider: listPaneCollapsedProvider,
      icon: Icons.view_sidebar_outlined,
      title: l10n.settingsListPaneCollapsed,
      subtitle: l10n.settingsListPaneCollapsedInfo,
    ),
    title: l10n.settingsListPaneCollapsed,
    keywords:
        '${l10n.settingsListPaneCollapsedInfo} odak tablet liste gizle genis',
  ),
];

/// Kalem tercihi anahtarı: değer [InkToolMemory]'de (ProviderScope dışında,
/// kalem katmanı doğrudan okur) — yerel durumla çizilir.
class _InkSwitch extends StatefulWidget {
  const _InkSwitch({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.read,
    required this.write,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool Function() read;
  final void Function(bool) write;

  @override
  State<_InkSwitch> createState() => _InkSwitchState();
}

class _InkSwitchState extends State<_InkSwitch> {
  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    secondary: Icon(widget.icon, size: 20),
    title: Text(widget.title),
    subtitle: Text(widget.subtitle),
    value: widget.read(),
    onChanged: (v) => setState(() => widget.write(v)),
  );
}
