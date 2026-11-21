import '../../../app/app_frame.dart';
import '../../../core/app_icons.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
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
      appBar: HomeInBar(appBar: AppBar(
        title: Text(l10n.personalizeTitle),
        actions: [
          IconButton(
            key: const ValueKey('personalize-reset'),
            tooltip: l10n.personalizeReset,
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => _confirmReset(context),
          ),
        ],
      )),
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
              for (final s in const [
                CustomizeSurface.modules,
                CustomizeSurface.bottomBar,
                CustomizeSurface.topBar,
                CustomizeSurface.quickRow,
                CustomizeSurface.addPanel,
                CustomizeSurface.attach,
                CustomizeSurface.video,
                CustomizeSurface.pinned,
                CustomizeSurface.pen,
                CustomizeSurface.home,
              ])
                _SurfaceSection(s),
              const _BubblesSection(),
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

/// Bir yüzeyin bölümü (düzen merkeziyle aynı pano).
class _SurfaceSection extends StatelessWidget {
  const _SurfaceSection(this.surface);

  final CustomizeSurface surface;

  @override
  Widget build(BuildContext context) {
    final (title, icon) = surfaceLabel(context.l10n, surface);
    return _Section(
      title: title,
      icon: icon,
      child: CustomizeSurfacePanel(surface: surface),
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
