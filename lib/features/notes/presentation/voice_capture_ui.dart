part of 'voice_capture_sheet.dart';

extension _VoiceCaptureUi on _VoiceCaptureSheetState {
  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final holdMode = ref.watch(voiceButtonModeProvider) == VoiceButtonMode.hold;
    final listening = _phase == _Phase.listening;
    // Sistem gezinme çubuğu (geri/ana sayfa) levhanın ALTINI örtüyordu:
    // showModalBottomSheet'in useSafeArea'sı üst/yanları korur, ALTI bilerek
    // korumaz (klavye için). Alt boşluğu levha kendi ekler; klavye açıkken
    // onun yüksekliği zaten daha büyüktür.

    // Bütün evreler AYNI yüzen kartın içinde (editörün dikte şeridiyle aynı
    // kenar boşluğu ve köşe — bkz. [ListeningCard]).
    // Alt pay (klavye ya da gezinme çubuğu, hangisi büyükse) yalnız ince
    // sarmalayıcıda okunur: klavye karesinde levha baştan kurulmaz (K-04).
    Widget framed(Widget child) => SheetInsetPadding(
      extra: AppSpace.s,
      floorViewPadding: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s,
          AppSpace.xs,
          AppSpace.s,
          0,
        ),
        child: child,
      ),
    );
    // Bütün evreler dinleme kartıyla AYNI kabukta (P63 PB5: üç ayrı elle
    // yazılmış kabuk tek bileşen oldu).
    Widget shell(Widget child) =>
        framed(ListeningSurface(mode: ListeningMode.ai, child: child));
    final text = AppText.of(Theme.of(context));

    if (!_ready || _phase == _Phase.processing) {
      return shell(
        Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(
                dimension: AppIconSize.l,
                child: CircularProgressIndicator(),
              ),
              if (_phase == _Phase.processing) ...[
                const SizedBox(height: AppSpace.l),
                Text(l10n.dictationProcessing, style: text.body),
              ],
            ],
          ),
        ),
      );
    }

    if (_phase == _Phase.error) {
      return shell(
        Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: _kErrorIcon, color: scheme.error),
              const SizedBox(height: AppSpace.m),
              Text(_errorMessage, textAlign: TextAlign.center, style: text.body),
              const SizedBox(height: AppSpace.l),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          ),
        ),
      );
    }

    final error = _errorMessage.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: AppSpace.s),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: text.meta.copyWith(color: scheme.error),
            ),
          );

    if (_phase != _Phase.ready) {
      final language = languageLabel(
        Localizations.localeOf(context).languageCode,
      );
      final holdActive = holdMode && !_latched;
      return framed(
        ListeningCard(
          mode: ListeningMode.ai,
          active: listening,
          // Gerçek ses düzeyi + sessizlik çizgisi (kayıt yolunda da düzey
          // 200 ms'de bir `reportLevel` ile gelir).
          level: _session?.level,
          silence: _session?.silence,
          // Başlık DURUMU söyler: basılı-tut modunda levha açılır açılmaz
          // "Dinliyorum..." yazması yanlıştı — mikrofon o an kapalıydı,
          // kullanıcı konuşup boş dönüyordu.
          title: listening ? l10n.voiceListening : l10n.voiceModeHold,
          // Kullanım ipucu düğmenin altında ayrı satır değil, alt başlıkta
          // (kart orta boyda kalsın).
          subtitle: _feedback.isNotEmpty
              ? '✓ $_feedback'
              : listening && _silence > 0
              ? l10n.voiceAutoStopSoon
              : !listening
              ? (holdActive ? l10n.dictationHoldHint : l10n.voiceTapHint)
              : l10n.voiceCapturePunctuation(language),
          clock: _clock(listening ? scheme.error : scheme.onSurfaceVariant),
          trailing: _headerButtons(l10n, scheme, ready: false),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _transcript(scheme, listening),
              ?error,
            ],
          ),
          action: _listenAction(l10n, holdMode, listening),
        ),
      );
    }

    // GÖZDEN GEÇİRME: aynı kart, dalga yerine düzenlenebilir döküm ve bitiş
    // düğmeleri.
    return shell(
      Padding(
        padding: const EdgeInsets.all(AppSpace.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(l10n, scheme, listening),
            const SizedBox(height: AppSpace.s),
            Flexible(child: _transcript(scheme, listening)),
            ?error,
            const SizedBox(height: AppSpace.m),
            _actions(l10n, scheme, holdMode, listening),
            // Çipler yapay zekâ ister; döküm zaten yapılamadıysa (ses eki
            // yolu) hepsi aynı hatayla düşerdi — gösterilmezler.
            if (!_hasReadyAudio) ...[
              const SizedBox(height: AppSpace.s),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _chips(l10n, scheme),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Gözden geçirme evresinin başlığı — dinleme kartının başlık satırıyla
  /// TEK bileşen ([ListeningHeader]): rozet, durum + kip etiketi, süre, kapat.
  Widget _header(AppLocalizations l10n, ColorScheme scheme, bool listening) =>
      ListeningHeader(
        mode: ListeningMode.ai,
        active: listening,
        title: l10n.voiceCaptureReady,
        subtitle: l10n.voiceCaptureEditHint,
        clock: _clock(scheme.onSurfaceVariant),
        trailing: _headerButtons(l10n, scheme, ready: true),
      );

  /// Süre sayacı: tabular rakam olmazsa saniye her tikte genişlik değiştirip
  /// başlığı oynatır. Dinlerken kayıt durumu rengi (`error`).
  Widget _clock(Color color) => Text(
    _format(_elapsed),
    style: AppText.of(Theme.of(context)).label.copyWith(
      fontWeight: AppWeight.strong,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color,
    ),
  );

  /// Kartın başlık satırındaki küçük düğmeler: akıllı komutlar, kapat.
  /// ("Doğrudan yazdırmaya geç" 2026-10-20'de kalktı: ana ekranın mikrofonu
  /// artık hep doğrudan yazdırıyor; bu levha bilinçli seçilen AI yolu.)
  List<Widget> _headerButtons(
    AppLocalizations l10n,
    ColorScheme scheme, {
    required bool ready,
  }) => [
    if (!ready) ...[
      MinTapTarget(
        child: Tooltip(
          message: l10n.dictationLocaleTooltip(
            _locale.startsWith('en') ? 'EN' : 'TR',
          ),
          child: InkWell(
            key: const ValueKey('voice-capture-locale'),
            borderRadius: BorderRadius.circular(AppRadius.s),
            onTap: () => unawaited(_toggleLocale()),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.s,
                vertical: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(
                  alpha: AppAlpha.muted,
                ),
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Text(
                _locale.startsWith('en') ? 'EN' : 'TR',
                style: AppText.of(Theme.of(context)).badge.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppWeight.strong,
                ),
              ),
            ),
          ),
        ),
      ),
      _commandsHelp(l10n, scheme),
    ],
    ListeningHeaderButton(
      tooltip: l10n.cancel,
      icon: Icons.close,
      onPressed: _cancel,
    ),
  ];

  /// Dinlerken salt okunur zengin metin (son iki kelime soluk = henüz
  /// kesinleşmemiş tanıma), bittiğinde düzenlenebilir alan.
  Widget _transcript(ColorScheme scheme, bool listening) {
    const style = TextStyle(fontSize: 16, height: 1.45);
    if (_phase == _Phase.ready) {
      final audio = _hasReadyAudio;
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60, maxHeight: 180),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ses eki rozeti: döküm yapılamadığında notun İÇİNDE ne
              // olacağını söyler — kullanıcı boş metin alanına bakıp
              // "hiçbir şey kaydedilmemiş" sanmasın.
              if (audio)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.voiceRecord, size: AppIconSize.xs, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${context.l10n.recordAudio} · ${_format(_elapsed)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: AppWeight.strong,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              // Söylenen başlık ("başlık X olsun"): gövdeden AYRI, düzeltilebilir.
              if (_title != null || _titleController.text.isNotEmpty)
                TextField(
                  key: const ValueKey('voice-title'),
                  controller: _titleController,
                  style: style.copyWith(fontWeight: AppWeight.strong),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.only(bottom: 6),
                    hintText: context.l10n.noteTitleLabel,
                  ),
                ),
              TextField(
                controller: _editController,
                maxLines: null,
                style: style,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: audio ? context.l10n.quickCaptureHint : null,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final words = _text.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    // Son iki kelime GEÇİCİ kabul edilir: cihaz tanıması sondaki kelimeleri
    // sık sık düzeltir, soluk göstermek bunun normal olduğunu anlatır.
    final settledCount = math.max(0, words.length - 2);
    final settled = words.take(settledCount).join(' ');
    final pending = words.skip(settledCount).join(' ');

    // Orta boy (kullanıcı isteği 2026-10-20): üç satır döküm görünür, fazlası
    // kayar — eski 74-210 px'lik alan levhayı ekranın yarısına çıkarıyordu.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
      child: SingleChildScrollView(
        reverse: true,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_title case final title?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${context.l10n.noteTitleLabel}: $title',
                    style: style.copyWith(
                      fontWeight: AppWeight.strong,
                      color: scheme.primary,
                    ),
                  ),
                ),
              Text.rich(
                TextSpan(
                  children: [
                    if (settled.isNotEmpty)
                      TextSpan(
                        text: settledCount == words.length
                            ? settled
                            : '$settled ',
                        style: style.copyWith(color: scheme.onSurface),
                      ),
                    if (pending.isNotEmpty)
                      TextSpan(
                        text: pending,
                        style: style.copyWith(
                          // Henüz oturmamış sözcük soluk ama okunur
                          // (F15.6: 0,6 → 0,8, ≥ 4,5:1).
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    if (listening)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          width: 2,
                          height: 20,
                          // Yönlü: RTL'de imleç metnin SOLUNDA değil, okuma
                          // yönünün sonunda (fiziksel solda) durmalı.
                          margin: const EdgeInsetsDirectional.only(start: 2),
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Akıllı komutların listesi. Anahtarların kendisi (Sessizlikte bitir,
  /// Akıllı komutlar) yalnız Ayarlar'da: levha zaten iki büyük düğme, üç
  /// işlem çipi ve "baştan dinle" taşıyor — dinlerken iki anahtar daha
  /// kalabalıktı (sadeleştirme 2026-10-19).
  Widget _commandsHelp(
    AppLocalizations l10n,
    ColorScheme scheme,
  ) => ListeningHeaderButton(
    key: const ValueKey('voice-commands-help'),
    tooltip: l10n.voiceSmartCommands,
    iconSize: AppIconSize.s,
    icon: Icons.info_outline,
    onPressed: () => showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.voiceSmartCommands),
        content: Text(
          '${l10n.voiceSmartCommandsInfo}\n\n${l10n.voiceAutoStopInfo}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      ),
    ),
  );

  /// Gözden geçirme evresinin bitiş düğmesi. İki düğme yan yana durduğunda
  /// etiketler dar ekranda sığmayabilir: metin tek satırda kalır ve gerekirse
  /// kısaltılır, ikon hangi düğme olduğunu etiket kırpılsa da anlatır.
  Widget _readyButton({
    required String label,
    required IconData? icon,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
  }) {
    final style = FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
    );
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: AppWeight.strong),
    );
    return SizedBox(
      height: _kReadyButton,
      child: icon == null
          ? FilledButton(onPressed: onPressed, style: style, child: text)
          : FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: AppIconSize.s),
              label: text,
            ),
    );
  }

  Widget _actions(
    AppLocalizations l10n,
    ColorScheme scheme,
    bool holdMode,
    bool listening,
  ) {
    if (_phase == _Phase.ready) {
      // ANA EKRAN: notu kimin kuracağı iki eşit düğmeyle sorulur — "AI not"
      // (asistan başlık/madde/hatırlatıcı çıkarır) ve "Düz not" (döküm olduğu
      // gibi). Eskiden "Yeni not oluştur" tek başına buradaydı, asistan yolu
      // ise altta çiplerin arasında ("Asistan oluştursun") kaybolmuştu;
      // kullanıcı isteği ikisinin YAN YANA ve kısa adlarıyla durması.
      //
      // Döküm yapılamadığında (ses eki yolu) asistan düğmesi YOK: yapay zekâ
      // zaten çağrılamıyor, tek yol kaydı düz notla saklamak.
      final assistant =
          widget.target == VoiceCaptureTarget.dashboard &&
          !_hasReadyAudio;
      return Row(
        children: [
          SizedBox(
            width: _kReadyButton,
            height: _kReadyButton,
            child: OutlinedButton(
              onPressed: _restart,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: scheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
              ),
              child: Tooltip(
                message: l10n.voiceCaptureRestart,
                child: const Icon(Icons.refresh),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s),
          // Ses eki yolunda (döküm yapılamadı) sürdürülecek metin yok.
          if (!_hasReadyAudio) ...[
            SizedBox(
              width: _kReadyButton,
              height: _kReadyButton,
              child: OutlinedButton(
                key: const ValueKey('voice-continue'),
                onPressed: _continue,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: scheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                ),
                child: Tooltip(
                  message: l10n.voiceCaptureContinue,
                  child: const Icon(AppIcons.dictation),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.s),
          ],
          if (assistant) ...[
            Expanded(
              child: _readyButton(
                label: l10n.voiceCaptureAiNote,
                icon: Icons.auto_awesome,
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
                onPressed: () => _submit(VoiceCaptureAction.compose),
              ),
            ),
            const SizedBox(width: AppSpace.s),
          ],
          Expanded(
            child: _readyButton(
              label: assistant
                  ? l10n.voiceCapturePlainNote
                  : widget.target == VoiceCaptureTarget.editor
                  ? l10n.voiceCaptureAddToNote
                  : l10n.voiceCaptureCreateNote,
              icon: assistant ? Icons.notes : null,
              background: scheme.primaryContainer,
              foreground: scheme.onPrimaryContainer,
              onPressed: () => _submit(VoiceCaptureAction.insert),
            ),
          ),
        ],
      );
    }

    // Dinleme evrelerinin düğmesi kartın içinde (bkz. [_listenAction]).
    return const SizedBox.shrink();
  }

  /// Dinleme kartının ana düğmesi (dalganın yanında): dinlerken "Bitir",
  /// beklerken "Başla" ya da "Basılı tut".
  Widget _listenAction(AppLocalizations l10n, bool holdMode, bool listening) {
    // Düğme "basılı tut" ile mi çalışıyor: kilitlendiyse artık dokunmalı
    // düğmedir (bas → bitir).
    final holdActive = holdMode && !_latched;

    // Basılı-tut modu: düğme idle ve listening evrelerinde AYNI ağaçta
    // kalmalı — aksi hâlde parmak basılıyken düğme ağaçtan kalkar ve bırakma
    // olayı hiç gelmez. (Eski dikte sayfasında bulunmuş bir tuzak; yerleşim
    // değişse de kural aynı.)
    final button = ListeningActionButton(
      key: const ValueKey('voice-listen-action'),
      listening: listening,
      // Basılı-tut modunda dokunma geri bildirimi Listener'dan gelir; düğme
      // yine de ETKİN görünür (eskiden disabled'dı ve soluk görünüyordu).
      onPressed: holdActive
          ? null
          : listening
          ? _finish
          : _startListening,
      label: listening
          ? (holdActive && _pressed ? l10n.voiceListening : l10n.voiceFinish)
          : (holdActive ? l10n.voiceModeHold : l10n.voiceStartShort),
    );
    if (!holdActive) return button;

    // Listener (GestureDetector.onLongPress DEĞİL): uzun basış tanıyıcısı
    // ~500 ms bekler, o süre boyunca konuşulanlar kaybolurdu. Parmak değer
    // değmez dinleme başlar.
    return Listener(
      onPointerDown: (_) => _pressStart(),
      onPointerUp: (_) => _pressEnd(),
      onPointerCancel: (_) => _pressEnd(),
      child: button,
    );
  }
}
