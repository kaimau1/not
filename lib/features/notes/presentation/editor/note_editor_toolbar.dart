part of 'note_editor_screen.dart';

/// Alt çubuk düğmeleri.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorToolbar on _NoteEditorScreenState {
  /// Sesli yazdırma. Cihazın yerleşik tanıması varsa düğme DOĞRUDAN dikteyi
  /// başlatır (alt sayfa açılmaz): konuşma anında nota akar, düğmeye tekrar
  /// basınca durur. Yerleşik tanıma yoksa (web) eski alt sayfa açılır.
  /// Alt bardaki üç araç segmentinden biri.
  Widget _toolSegment({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: Material(
        color: active ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: _NoteEditorScreenState._kToolSegment,
            width: _NoteEditorScreenState._kToolSegment,
            child: Icon(
              icon,
              size: 21,
              color: active ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  /// Alt çubuğun "Ekle" segmenti: TEK levhayı açar (attach_sheet.dart).
  ///
  /// Eski hâli iki katmanlıydı — küçük bir açılır menü (madde/görsel/PDF/renk)
  /// ve onun içinden açılan ikinci bir "tüm ekler" levhası. Aynı seçenek iki
  /// yerde duruyor, "Ekle" adı üç kez geçiyordu. Artık tek dokunuş, tek sayfa.
  /// Ek şeridini açıp kapatan düğme (sayı rozetli). Şeridin kendi başlık
  /// satırı kaldırıldı: kapalıyken artık HİÇ yer kaplamıyor.
  ///
  /// **Yeni ek geldiğinde YANIP SÖNER** (kullanıcı isteği 2026-08-09: "ek
  /// eklendiğinde alttaki ataç kısmı renklenmeli ve hafif yanıp sönmeli"):
  /// şerit kapalıyken (varsayılan) ek eklemek ekranda hiçbir iz bırakmıyordu —
  /// dosya gerçekten girdi mi, kullanıcı ancak ataca basıp bakınca
  /// anlıyordu. Sayı artınca düğme iki kez vurgu rengine yanar
  /// (bkz. [_attachPulse]).
  Widget _attachmentsToggle(AppLocalizations l10n, int count) {
    final scheme = Theme.of(context).colorScheme;
    final open = ref.watch(attachmentsExpandedProvider);
    return Tooltip(
      message: open ? l10n.hideAttachments : l10n.showAttachments,
      child: AnimatedBuilder(
        animation: _attachPulse,
        builder: (context, child) {
          // 0 → 1 → 0 iki kez: yanıp sönme. Renk ve metin rengi birlikte
          // döner ki rozet okunur kalsın.
          final t = _attachPulse.value;
          final glow = Color.lerp(
            open ? scheme.secondaryContainer : Colors.transparent,
            scheme.primary,
            t,
          )!;
          final ink = Color.lerp(scheme.onSurface, scheme.onPrimary, t)!;
          return Material(
            color: glow,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () =>
                  ref.read(attachmentsExpandedProvider.notifier).toggle(),
              child: Container(
                height: _NoteEditorScreenState._kToolSegment,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file, size: 19, color: ink),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// PDF/sunum sayfasının ÜZERİNE yazma kalemi. Açıkken bölmede tek parmak
  /// çizer, iki parmak gezinir; renk/kalınlık/silgi/ok çubuğu bölmenin
  /// altında belirir (bkz. PdfNotePane.penMode).
  Widget _penToolButton(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: _penMode ? l10n.annotateDone : l10n.annotate,
      child: SizedBox(
        height: 44,
        width: 46,
        child: Material(
          color: _penMode ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => _update(() => _penMode = !_penMode),
            child: Icon(
              _penMode ? Icons.edit : Icons.edit_outlined,
              size: 20,
              color: _penMode ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// Alt çubuğun sağındaki MİKROFON düğmesi (iki tane: AI ve düz dikte).
  ///
  /// [badge] verilirse simgenin sağ üstüne küçük bir parıltı konur — iki
  /// mikrofonu tek bakışta ayıran işaret budur. [active] dikte AÇIKKEN
  /// düğmeyi vurgu rengine boyar: mikrofonun açık kaldığı fark edilmiyordu.
  Widget _voiceButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    IconData? badge,
    bool active = false,
    double size = 48,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final background = active ? scheme.primary : Colors.transparent;
    final ink = active ? scheme.onPrimary : scheme.onPrimaryContainer;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: size,
        height: _NoteEditorScreenState._kToolSegment,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: ink),
                if (badge != null)
                  Positioned(
                    top: 6,
                    right: size / 2 - 17,
                    child: Icon(badge, size: 10, color: ink),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Alt çubuğun SAĞ grubu: AI + iki mikrofon tek vurgu renkli kapsülde
  /// (soldaki araç kapsülüyle aynı yükseklik ve köşe — bkz.
  /// [planEditorBar]).
  Widget _aiCapsule({
    required double segment,
    required double gap,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('editor-ai-capsule'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: scheme.primaryContainer),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _addToolButton(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: l10n.addAttachment,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _showAttachMenu,
          child: SizedBox(
            height: _NoteEditorScreenState._kToolSegment,
            width: _NoteEditorScreenState._kToolSegment,
            child: Icon(Icons.add, size: 21, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
