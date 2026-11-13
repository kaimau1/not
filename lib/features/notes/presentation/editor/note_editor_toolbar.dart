part of 'note_editor_screen.dart';

/// Alt çubuk düğmeleri.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorToolbar on _NoteEditorScreenState {
  /// Sesli yazdırma. Cihazın yerleşik tanıması varsa düğme DOĞRUDAN dikteyi
  /// başlatır (alt sayfa açılmaz): konuşma anında nota akar, düğmeye tekrar
  /// basınca durur. Yerleşik tanıma yoksa (web) eski alt sayfa açılır.
  /// Alt bardaki araç segmentlerinden biri.
  ///
  /// RENKLİ NOTTA (F75.3, K-D6) çubuk notun tonunda: [_barInk] doluysa simge
  /// ve etkin zemin ondan, yoksa temanın renkleri. Saydamlıklar belirteçten
  /// (plandaki %14 / %18 → `AppAlpha.pressed`, DENEYIM §2.1 göç eşlemesi).
  Widget _toolSegment({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool active = false,
  }) {
    final scheme = _themeOf(context).colorScheme;
    final ink = _barInk;
    return _barTarget(
      Tooltip(
        message: label,
        child: Material(
          color: !active
              ? Colors.transparent
              : ink?.withValues(alpha: AppAlpha.pressed) ?? scheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            onLongPress: onLongPress,
            child: SizedBox(
              height: _NoteEditorScreenState._kToolSegment,
              width: _NoteEditorScreenState._kToolSegment,
              child: Icon(
                icon,
                size: 21,
                color:
                    ink ??
                    (active ? scheme.onPrimaryContainer : scheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 48 dp DOKUNMA ALANI (F75.2): segment 40 dp görünür, çubuk 50 dp kalır;
  /// pay dikeyde kapsülün dolgusuna (4 + 4), yatayda yalnız komşuyla aradaki
  /// boşluğun yarısına uzanır — komşunun görünen kutusuna taşmaz. Yer
  /// kaplamaz (bkz. [MinTapTarget]); ağaç şekli hep aynı.
  Widget _barTarget(Widget child) => MinTapTarget(
    minWidth: _NoteEditorScreenState._kToolSegment + kEditorBarSegmentGap,
    child: child,
  );

  /// KALEM segmenti (F75.1, K-D6): hızlı satırdaki kalemle AYNI iş
  /// ([_togglePen]; basılı tut = kalem ayarları). Belge notunda sayfanın
  /// ÜZERİNE yazma kipini açar/kapatır — eskiden kapsülün sağındaki ayrı
  /// düğmeydi (kullanıcı isteği 2026-08-08), iki kalem yan yana durmasın
  /// diye bu segmentle birleşti.
  Widget _penSegment(AppLocalizations l10n, Note note) {
    final document = note.type.isPageNoteType;
    return _toolSegment(
      key: const ValueKey('editor-bar-pen'),
      icon: Icons.draw_outlined,
      label: document
          ? (_penMode ? l10n.annotateDone : l10n.annotate)
          : l10n.quickRowPen,
      active: _penMode,
      onTap: document ? _toggleAnnotate : _togglePen,
      onLongPress: document
          ? null
          : () => showInkSettings(context, _pageInkOf(note)),
    );
  }

  /// Belge notunda sayfanın üzerine yazma kipi (alt çubuktaki Kalem, hangi
  /// kapsülde olursa olsun).
  void _toggleAnnotate() => _update(() => _penMode = !_penMode);

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
    final scheme = _themeOf(context).colorScheme;
    final open = ref.watch(attachmentsExpandedProvider);
    final noteInk = _barInk;
    return MinTapTarget(
      child: Tooltip(
      message: open ? l10n.hideAttachments : l10n.showAttachments,
      child: AnimatedBuilder(
        animation: _attachPulse,
        builder: (context, child) {
          // 0 → 1 → 0 iki kez: yanıp sönme. Renk ve metin rengi birlikte
          // döner ki rozet okunur kalsın.
          final t = _attachPulse.value;
          final glow = Color.lerp(
            !open
                ? Colors.transparent
                : noteInk?.withValues(alpha: AppAlpha.pressed) ?? scheme.secondaryContainer,
            noteInk ?? scheme.primary,
            t,
          )!;
          final ink = Color.lerp(
            noteInk ?? scheme.onSurface,
            noteInk != null ? _barPage : scheme.onPrimary,
            t,
          )!;
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
    double gap = 2,
  }) {
    final scheme = _themeOf(context).colorScheme;
    // Renkli notta notun tonu (F75.3): açıkken dolu ton + sayfa rengi simge.
    final noteInk = _barInk;
    final background = !active
        ? Colors.transparent
        : noteInk ?? scheme.primary;
    final ink = noteInk != null
        ? (active ? _barPage : noteInk)
        : (active ? scheme.onPrimary : scheme.onPrimaryContainer);
    return MinTapTarget(
      minWidth: size + gap,
      child: Tooltip(
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
    final scheme = _themeOf(context).colorScheme;
    // Renkli notta notun tonu (F75.3), çerçevesiz.
    final ink = _barInk;
    final fill = ink == null
        ? scheme.primaryContainer
        : Color.alphaBlend(ink.withValues(alpha: AppAlpha.pressed), _barPage);
    // Dolgu yatayda; dikeyde Row kapsülün tam boyunda (48 dp) — düğmelerin
    // dokunma payı yakalansın (F75.2). Görünüş aynı.
    return DecoratedBox(
      key: const ValueKey('editor-ai-capsule'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: _NoteEditorScreenState._kToolSegment + 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Ekle düğmesi (kullanıcı bulgusu 2026-10-30: "ek eklemek için olan artı
  /// işareti güzel değil"): çıplak ince "+" yerine segmentin içinde TONLU
  /// yuvarlak rozet ve kalın, yuvarlak uçlu artı — kapsüldeki diğer
  /// simgelerden ayrışır, "buradan ekle" diye okunur.
  ///
  /// Rozet "oluşturma" rolünde (K-D1, F73.1-2): `primaryContainer`; renkli
  /// notta notun tonu (F75.3).
  Widget _addToolButton(AppLocalizations l10n) {
    final scheme = _themeOf(context).colorScheme;
    final ink = _barInk;
    const segment = _NoteEditorScreenState._kToolSegment;
    return _barTarget(
      Tooltip(
      message: l10n.addAttachment,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: const ValueKey('editor-add-button'),
          borderRadius: BorderRadius.circular(10),
          onTap: _showAttachMenu,
          child: SizedBox(
            height: segment,
            width: segment,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      ink?.withValues(alpha: AppAlpha.pressed) ?? scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: segment * 0.72,
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    weight: 700,
                    color: ink ?? scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
