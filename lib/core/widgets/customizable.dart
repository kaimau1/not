import 'package:flutter/material.dart';

import '../l10n_ext.dart';
import '../personalize.dart';
import '../../app/theme/app_tokens.dart';
import '../haptics.dart';

/// Kişiselleştirilebilir bir alan/düğme (bkz. `Personalize`).
///
/// Normalde: öğe görünürse [child], gizliyse [hidden] (varsayılan: hiçbir
/// şey — yer de kaplamaz).
///
/// DÜZENLEME MODUNDA: öğe gizli olsa da çizilir (soluk), köşesinde göz
/// rozeti durur ve öğenin KENDİ işi çalışmaz — dokunmak gizle/göster yapar
/// ve hemen kaydedilir (P50). Böylece kullanıcı ekranın kendisinde neyi görmek
/// istediğini seçer; ayar düğmeleri ekranda kalıcı yer kaplamaz.
///
/// Tercihi KENDİ dinler (P20): eskiden `StatelessWidget` + `ListenableBuilder`
/// — öğe başına iki kurulum; editörün ilk karesinde 11 öğe = 11 boşa kurulum.
class Customizable extends StatefulWidget {
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
  State<Customizable> createState() => _CustomizableState();
}

class _CustomizableState extends State<Customizable> {
  @override
  void initState() {
    super.initState();
    Personalize.listenable.addListener(_changed);
  }

  @override
  void dispose() {
    Personalize.listenable.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    final visible = Personalize.current.shows(id);
    if (!Personalize.editing) return visible ? widget.child : widget.hidden;
    return CustomizeFrame(
      visible: visible,
      inset: widget.badgeInset,
      onTap: () {
        AppHaptics.tick();
        Personalize.toggle(id);
      },
      child: widget.child,
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
                duration: AppMotion.of(context, AppMotion.quick),
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
/// Dokunuşlar anında kaydedilir; "Geri al" modun açıldığı ana döner,
/// "Bitti" modu kapatır (P50 — eskiden Vazgeç/Kaydet'li taslaktı).
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
            _CustomizeStrip(
              hiddenCount: draft.hidden.where((h) => !h.startsWith('+')).length,
              dirty: Personalize.dirty,
            )
          else
            const SizedBox.shrink(),
          // **EKRAN BOYU ŞERİDİN ALTINDAKİ ALAN** (kullanıcı bulgusu
          // 2026-11-01: "ekranı düzenle açılınca ekran alta kayıyor, alttaki
          // butonlar görülmüyor"). KÖK NEDEN: şerit içeriği aşağı itiyor
          // ama `MediaQuery.size` hâlâ TAM ekranı söylüyordu; not açılış
          // geçişi (note_open_route) sayfayı o boyla çiziyor, editörün alt
          // çubuğu şerit kadar ekranın dışına taşıyordu. Boy artık bu alanın
          // kendisi — `MediaQuery.sizeOf` okuyan her yer doğru ölçer. Ağaç
          // şekli mod açık/kapalı aynı (LayoutBuilder hep burada).
          Expanded(
            child: LayoutBuilder(
              // Tek MediaQuery: `removePadding(context:)` burada DIŞTAKİ
              // (tam ekran) veriyi okuyup boyu geri yazardı.
              builder: (context, box) => MediaQuery(
                data: MediaQuery.of(context)
                    .removePadding(removeTop: draft != null)
                    .copyWith(size: draft != null ? box.biggest : null),
                child: child!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomizeStrip extends StatelessWidget {
  const _CustomizeStrip({required this.hiddenCount, required this.dirty});

  final int hiddenCount;
  final bool dirty;

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
                      fontWeight: AppWeight.strong,
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
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const ValueKey('customize-undo'),
              style: TextButton.styleFrom(
                foregroundColor: scheme.onInverseSurface,
                disabledForegroundColor: scheme.onInverseSurface.withValues(
                  alpha: AppAlpha.disabled,
                ),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: dirty ? Personalize.revert : null,
              child: Text(l10n.undo),
            ),
            const SizedBox(width: 4),
            FilledButton(
              key: const ValueKey('customize-done'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.inversePrimary,
                foregroundColor: scheme.onPrimaryContainer,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: Personalize.done,
              child: Text(l10n.customizeDone),
            ),
          ],
        ),
      ),
    );
  }
}
