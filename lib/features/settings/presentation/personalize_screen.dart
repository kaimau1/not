import '../../../app/app_frame.dart';
import '../../../app/theme/app_design.dart';
import '../../../core/app_icons.dart';

import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import '../../../core/widgets/horizontal_wheel_strip.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../notes/presentation/viewers/bubble_layer.dart' show BubbleLook;
import '../../../app/theme/app_tokens.dart';
import 'customize_hub.dart';

/// **KİŞİSELLEŞTİR** ekranı — bütün kişisel düzen TEK menüde.
///
/// Kullanıcı isteği 2026-10-16: "bütün alanlar bir eklenti gibi açılıp
/// kapatılabilsin; not ekleme alanı özelleştirilebilsin, hangilerinin
/// görüneceği seçilsin; bu düzenlemeler bir menü üzerinden yapılmalı, ekranda
/// ayar düğmesi olarak yer kaplamamalı — bir düzenleme modu olsun".
///
/// İki yol aynı kayda yazar (bkz. `Personalize`):
///  1. Buradaki seçiciler — değişiklik anında kaydedilir.
///  2. "Düzenleme modunu başlat": ekranlara dönülür, öğelere dokunarak
///     gizle/göster yapılır, üstteki şeritten Kaydet.
///
/// Sonuç [Navigator.pop] ile 'edit' döner: ayarlar ekranı da kapanır ki
/// kullanıcı doğrudan düzenleyeceği ekrana insin.
class PersonalizeScreen extends StatelessWidget {
  const PersonalizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: HomeInBar(
        appBar: AppBar(
          title: Text(l10n.personalizeTitle),
          actions: [
            IconButton(
              key: const ValueKey('personalize-reset'),
              tooltip: l10n.personalizeReset,
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: () => _confirmReset(context),
            ),
          ],
        ),
      ),
      // KÖK NEDEN (kullanıcı bulgusu 2026-10-16: "kişiselleştirme ayarlar
      // kısmında aç kapa yapılamıyor"; "kapatıyorum, girip çıkınca başka
      // şeyler kapanmış oluyor"): bölümler burada `const` idi ve kaydı
      // dinleyen tek yer bu listenin ÜSTÜNDEKİ ListenableBuilder'dı. `const`
      // örnek her yeniden kurulumda AYNI nesne olduğu için Flutter alt ağacı
      // hiç yeniden kurmuyordu: anahtar kaydediliyor ama ekranda yerinden
      // oynamıyordu. Çiplerde daha kötüsü — `onSelected` bayat `selected`
      // değerinin tersini yazdığından ikinci dokunuş geri açmıyor, aynı
      // değeri bir daha yazıyordu; kullanıcı ekrandan çıkıp girince
      // beklemediği öğeleri kapalı buluyordu. Artık kaydı okuyan her bölüm
      // KENDİSİ dinliyor ([_Live]).
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.xxl + MediaQuery.paddingOf(context).bottom,
            ),
            // DÜZEN MERKEZİNİN yüzeyleri ALT ALTA (P63 PB2): levhadaki
            // çipli merkezle aynı panolar; burada hepsi tek kaydırmada.
            children: [
              const _EditModeCard(),
              const SizedBox(height: AppSpace.m),
              const _UiProfilesSection(),
              const SizedBox(height: AppSpace.m),
              _PersonalizeCategoryCard(
                key: const ValueKey('personalize-group-modules'),
                title: l10n.personalizeModules,
                icon: Icons.extension_outlined,
                initiallyExpanded: true,
                child: const PersonalizeModuleSwitches(),
              ),
              const SizedBox(height: AppSpace.m),
              _PersonalizeCategoryCard(
                key: const ValueKey('personalize-group-editor'),
                title: l10n.personalizeGroupEditor,
                icon: Icons.edit_note_outlined,
                initiallyExpanded: true,
                child: const _SurfaceSwitcherGroup(
                  surfaces: [
                    CustomizeSurface.bottomBar,
                    CustomizeSurface.topBar,
                    CustomizeSurface.quickRow,
                    CustomizeSurface.pen,
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.m),
              _PersonalizeCategoryCard(
                key: const ValueKey('personalize-group-add'),
                title: l10n.personalizeGroupAddAttach,
                icon: Icons.attach_file_rounded,
                child: const _SurfaceSwitcherGroup(
                  surfaces: [
                    CustomizeSurface.addPanel,
                    CustomizeSurface.attach,
                    CustomizeSurface.pinned,
                    CustomizeSurface.video,
                  ],
                  includeBubbles: true,
                ),
              ),
              const SizedBox(height: AppSpace.m),
              _PersonalizeCategoryCard(
                key: const ValueKey('personalize-group-home'),
                title: surfaceLabel(l10n, CustomizeSurface.home).$1,
                icon: Icons.home_outlined,
                initiallyExpanded: true,
                child: const CustomizeSurfacePanel(
                  surface: CustomizeSurface.home,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.personalizeReset),
        content: Text(l10n.personalizeResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.personalizeReset),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Personalize.reset();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(l10n.personalizeResetDone);
  }
}

/// Kişiselleştirme kaydını (ve düzenleme taslağını) dinleyerek kurar: kaydı
/// okuyan her parça değişince KENDİSİ tazelenir (bkz. ekrandaki kök neden).
class _Live extends StatelessWidget {
  const _Live(this.builder);

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Personalize.listenable,
    builder: (context, _) => builder(context),
  );
}

/// Ekranın başındaki kart: düzenleme modunu başlatır. Düz zemin (P63 PB2 —
/// gradyan zemin genel yapılmayacaklarda).
class _EditModeCard extends StatelessWidget {
  const _EditModeCard();

  @override
  Widget build(BuildContext context) => _Live(_build);

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final editing = Personalize.editing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: AppAlpha.soft),
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(
          color: scheme.primary.withValues(alpha: AppAlpha.soft),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.s),
                    child: Icon(
                      Icons.touch_app_outlined,
                      size: AppIconSize.m,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.customizeStartTitle,
                        style: text.rowTitle.copyWith(
                          fontWeight: AppWeight.strong,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(l10n.customizeStartInfo, style: text.meta),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                key: const ValueKey('personalize-start-edit'),
                onPressed: editing
                    ? null
                    : () {
                        Personalize.startEditing();
                        Navigator.of(context).pop('edit');
                      },
                icon: Icon(
                  editing ? Icons.check_rounded : Icons.tune_rounded,
                  size: AppIconSize.s,
                ),
                label: Text(
                  editing ? l10n.customizeActive : l10n.customizeStart,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bölüm: başlık + içerik kartı (her yüzey bento menülerle aynı kılıkta).
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.m),
      // Material (DecoratedBox DEĞİL): içindeki anahtar satırları
      // (ListTile) zeminlerini ve dokunma dalgalarını en yakın Material'a
      // çizer; renkli bir DecoratedBox onları örterdi.
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(
                        alpha: AppAlpha.soft,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.s),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.xs),
                      child: Icon(
                        icon,
                        size: AppIconSize.s,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: Text(title, style: sectionLabelStyle(context)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalizeCategoryCard extends StatelessWidget {
  const _PersonalizeCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final text = AppText.of(theme);
    return Container(
      decoration: AppSurface.sheetCard(theme),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.l,
              vertical: AppSpace.xs,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              0,
              AppSpace.l,
              AppSpace.l,
            ),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tokens.resolvedTintSoft(scheme),
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Icon(icon, size: AppIconSize.s, color: scheme.primary),
            ),
            title: Text(title, style: text.section),
            children: [child],
          ),
        ),
      ),
    );
  }
}

class _SurfaceSwitcherGroup extends StatefulWidget {
  const _SurfaceSwitcherGroup({
    required this.surfaces,
    this.includeBubbles = false,
  });

  final List<CustomizeSurface> surfaces;
  final bool includeBubbles;

  @override
  State<_SurfaceSwitcherGroup> createState() => _SurfaceSwitcherGroupState();
}

class _SurfaceSwitcherGroupState extends State<_SurfaceSwitcherGroup> {
  late CustomizeSurface? _selected = widget.surfaces.first;
  bool _showBubbles = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HorizontalScrollStrip(
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in widget.surfaces) ...[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSpace.s),
                    child: Builder(
                      builder: (context) {
                        final (label, icon) = surfaceLabel(l10n, s);
                        return ChoiceChip(
                          avatar: Icon(icon, size: AppIconSize.s),
                          label: Text(label),
                          selected: !_showBubbles && _selected == s,
                          onSelected: (_) {
                            AppHaptics.tick();
                            setState(() {
                              _showBubbles = false;
                              _selected = s;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                if (widget.includeBubbles)
                  ChoiceChip(
                    avatar: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: AppIconSize.s,
                    ),
                    label: Text(l10n.personalizeBubbles),
                    selected: _showBubbles,
                    onSelected: (_) {
                      AppHaptics.tick();
                      setState(() => _showBubbles = true);
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.m),
        if (_showBubbles)
          const _BubblesSection()
        else if (_selected != null)
          CustomizeSurfacePanel(surface: _selected!),
      ],
    );
  }
}

/// Eklentilerin aç/kapa anahtarları. Kişiselleştir ekranında ve AYARLARIN
/// "Kişiselleştir" alanında aynı parça (kullanıcı isteği 2026-10-16:
/// "ayarlar kısmından da aç kapa yapılabilmeli").
class PersonalizeModuleSwitches extends StatelessWidget {
  const PersonalizeModuleSwitches({super.key});

  @override
  Widget build(BuildContext context) => _Live(_build);

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final prefs = Personalize.prefs.value;
    final modules = <(UiModule, IconData, String, String)>[
      (UiModule.ai, Icons.auto_awesome, l10n.moduleAi, l10n.moduleAiInfo),
      (
        UiModule.voice,
        AppIcons.dictation,
        l10n.moduleVoice,
        l10n.moduleVoiceInfo,
      ),
      (
        UiModule.video,
        Icons.smart_display_outlined,
        l10n.moduleVideo,
        l10n.moduleVideoInfo,
      ),
      (
        UiModule.scan,
        Icons.document_scanner_outlined,
        l10n.moduleScan,
        l10n.moduleScanInfo,
      ),
      (
        UiModule.drawing,
        Icons.draw_outlined,
        l10n.moduleDrawing,
        l10n.moduleDrawingInfo,
      ),
      (
        UiModule.templates,
        Icons.dashboard_customize_outlined,
        l10n.moduleTemplates,
        l10n.moduleTemplatesInfo,
      ),
      (
        UiModule.tags,
        Icons.sell_outlined,
        l10n.moduleTags,
        l10n.moduleTagsInfo,
      ),
      (
        UiModule.collaboration,
        AppIcons.shared,
        l10n.moduleCollaboration,
        l10n.moduleCollaborationInfo,
      ),
    ];
    return Column(
      children: [
        for (final (module, icon, title, info) in modules)
          Builder(
            builder: (context) {
              final state = prefs.moduleState(module);
              return SwitchListTile(
                key: ValueKey('module-${module.id}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (state == false ? scheme.outline : scheme.primary)
                        .withValues(alpha: AppAlpha.pressed),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Icon(
                    icon,
                    size: AppIconSize.m,
                    color: state == false ? scheme.outline : scheme.primary,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: AppWeight.strong),
                ),
                subtitle: Text(
                  state == null ? '$info · ${l10n.moduleMixed}' : info,
                ),
                value: state != false,
                onChanged: (on) =>
                    Personalize.update((p) => p.withModule(module, on)),
              );
            },
          ),
      ],
    );
  }
}

class _BubblesSection extends StatelessWidget {
  const _BubblesSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Section(
      title: l10n.personalizeBubbles,
      icon: Icons.chat_bubble_outline_rounded,
      child: ValueListenableBuilder<double>(
        valueListenable: BubbleLook.scale,
        builder: (context, scale, _) => Row(
          children: [
            Text(
              l10n.bubbleSizeSetting,
              style: const TextStyle(fontWeight: AppWeight.strong),
            ),
            Expanded(
              child: Slider(
                key: const ValueKey('bubble-scale-slider'),
                value: scale,
                min: BubbleLook.min,
                max: BubbleLook.max,
                divisions: ((BubbleLook.max - BubbleLook.min) / 0.05).round(),
                label: '${(scale * 100).round()}%',
                onChanged: BubbleLook.setScale,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${(scale * 100).round()}%',
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: AppWeight.strong),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faz 4 — **3 hazır arayüz profili** (*Sade / Standart / Tablet & Kalem*).
class _UiProfilesSection extends StatelessWidget {
  const _UiProfilesSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final text = AppText.of(theme);

    final profiles = [
      (
        profile: UiProfile.simple,
        icon: Icons.auto_awesome_mosaic_outlined,
        title: l10n.uiProfileSimple,
        desc: l10n.uiProfileSimpleDesc,
      ),
      (
        profile: UiProfile.standard,
        icon: Icons.dashboard_outlined,
        title: l10n.uiProfileStandard,
        desc: l10n.uiProfileStandardDesc,
      ),
      (
        profile: UiProfile.tabletPen,
        icon: Icons.draw_outlined,
        title: l10n.uiProfileTabletPen,
        desc: l10n.uiProfileTabletPenDesc,
      ),
    ];

    return _Live((context) {
      final active = Personalize.activeProfile;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s),
            child: SectionLabel(l10n.uiProfileSectionTitle),
          ),
          Column(
            children: [
              for (var i = 0; i < profiles.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpace.s),
                _ProfileTile(
                  key: ValueKey('ui-profile-${profiles[i].profile.name}'),
                  icon: profiles[i].icon,
                  title: profiles[i].title,
                  desc: profiles[i].desc,
                  selected: active == profiles[i].profile,
                  scheme: scheme,
                  tokens: tokens,
                  text: text,
                  onTap: () {
                    Personalize.applyProfile(profiles[i].profile);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showMessage(l10n.uiProfileApplied(profiles[i].title));
                  },
                ),
              ],
            ],
          ),
        ],
      );
    });
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.desc,
    required this.selected,
    required this.scheme,
    required this.tokens,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final bool selected;
  final ColorScheme scheme;
  final AppTokens tokens;
  final AppText text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: AppAlpha.soft)
          : tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(
          color: selected
              ? tokens.resolvedAccentBorder(scheme)
              : tokens.hairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.m,
            vertical: AppSpace.m,
          ),
          child: Row(
            children: [
              Container(
                width: AppSpace.xxl + AppSpace.xs,
                height: AppSpace.xxl + AppSpace.xs,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.m,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: text.rowTitle.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      desc,
                      style: text.meta.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: AppIconSize.m,
                  color: scheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
