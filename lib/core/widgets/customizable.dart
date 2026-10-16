import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n_ext.dart';
import '../personalize.dart';

/// Kişiselleştirilebilir bir alan/düğme (bkz. `Personalize`).
///
/// Normalde: öğe görünürse [child], gizliyse [hidden] (varsayılan: hiçbir
/// şey — yer de kaplamaz).
///
/// DÜZENLEME MODUNDA: öğe gizli olsa da çizilir (soluk), köşesinde göz
/// rozeti durur ve öğenin KENDİ işi çalışmaz — dokunmak taslakta
/// gizle/göster yapar. Böylece kullanıcı ekranın kendisinde neyi görmek
/// istediğini seçer; ayar düğmeleri ekranda kalıcı yer kaplamaz.
class Customizable extends StatelessWidget {
  const Customizable({
    super.key,
    required this.id,
    required this.child,
    this.hidden = const SizedBox.shrink(),
    this.badgeInset = 0,
  });

  final String id;
  final Widget child;
  final Widget hidden;

  /// Rozetin köşeden içeri payı (sıkı yerleşimde taşmasın diye).
  final double badgeInset;

  /// Düzenleme modunda değilken [id] görünür mü — kurulumda okunur.
  static bool shows(String id) => Personalize.current.shows(id);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Personalize.listenable,
      builder: (context, _) {
        final prefs = Personalize.current;
        final visible = prefs.shows(id);
        if (!Personalize.editing) return visible ? child : hidden;
        return CustomizeFrame(
          visible: visible,
          inset: badgeInset,
          onTap: () {
            HapticFeedback.selectionClick();
            Personalize.toggle(id);
          },
          child: child,
        );
      },
    );
  }
}

/// Düzenleme modundaki çerçeve: soluk/kesik kenarlı içerik + göz rozeti.
/// İçeriğin dokunuşları KAPALI (dokunuş gizle/göster yapar).
class CustomizeFrame extends StatelessWidget {
  const CustomizeFrame({
    super.key,
    required this.visible,
    required this.onTap,
    required this.child,
    this.inset = 0,
  });

  final bool visible;
  final VoidCallback onTap;
  final Widget child;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final color = visible ? scheme.primary : scheme.outline;
    return Semantics(
      button: true,
      toggled: visible,
      label: visible ? l10n.customizeHideItem : l10n.customizeShowItem,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: visible ? 1 : 0.32,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: visible ? 0.55 : 0.8),
                      width: 1.2,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
            Positioned(
              top: -5 + inset,
              right: -5 + inset,
              child: IgnorePointer(
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: visible ? scheme.primary : scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.2),
                  ),
                  child: Icon(
                    visible ? Icons.visibility : Icons.visibility_off,
                    size: 11,
                    color: visible ? scheme.onPrimary : scheme.outline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uygulamanın TEPESİNDEKİ düzenleme modu şeridi: mod açıkken bütün
/// ekranların üstünde durur ve içeriği aşağı iter (hiçbir şeyi örtmez).
/// "Vazgeç" taslağı atar, "Kaydet" kalıcı yapar.
class CustomizeModeHost extends StatelessWidget {
  const CustomizeModeHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UiPrefs?>(
      valueListenable: Personalize.draft,
      // Çocuk SABİT örnek: mod açılıp kapanınca uygulamanın ağacı yeniden
      // kurulmaz, yalnız şerit eklenir/kalkar.
      child: child,
      // AĞAÇ ŞEKLİ SABİT: mod açılınca uygulamanın ağacı (Navigator dahil)
      // başka bir ebeveynin altına taşınsaydı yeniden kurulur, açık ekranlar
      // kaybolurdu. Şerit yuvası kapalıyken boş kutu.
      builder: (context, draft, child) => Column(
        children: [
          if (draft != null)
            _CustomizeStrip(hiddenCount: draft.hidden.length)
          else
            const SizedBox.shrink(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: draft != null,
              child: child!,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomizeStrip extends StatelessWidget {
  const _CustomizeStrip({required this.hiddenCount});

  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final hidden = hiddenCount;
    return Material(
      color: scheme.inverseSurface,
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, top + 4, 6, 4),
        child: Row(
          children: [
            Icon(Icons.tune_rounded, size: 18, color: scheme.onInverseSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.customizeModeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    hidden == 0
                        ? l10n.customizeModeHint
                        : l10n.customizeHiddenCount(hidden),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onInverseSurface.withValues(alpha: 0.75),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const ValueKey('customize-cancel'),
              style: TextButton.styleFrom(
                foregroundColor: scheme.onInverseSurface,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: Personalize.cancel,
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 4),
            FilledButton(
              key: const ValueKey('customize-save'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.inversePrimary,
                foregroundColor: scheme.onPrimaryContainer,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                Personalize.save();
                ScaffoldMessenger.maybeOf(context)
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(l10n.customizeSaved)));
              },
              child: Text(l10n.customizeSave),
            ),
          ],
        ),
      ),
    );
  }
}
