import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/app_icons.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/voice_commands.dart' show SilenceGate;
import '../../../core/widgets/undo_snackbar.dart';
import '../../settings/settings_providers.dart';
import '../data/device_speech.dart';
import '../data/voice_listen_session.dart';
import '../domain/done_word.dart';
import '../domain/quick_entry.dart';
import 'voice_level_wave.dart';

/// **HIZLI GİRİŞ SATIRI** (kullanıcı isteği 2026-11-15): tek satıra yan yana
/// yazılır ya da söylenir; tamamlanan kelimeler [onItems] ile CANLI maddeye
/// döner, alanda yalnız henüz bitmemiş kısım kalır.
///
/// Yazı ve ses aynı ayrıştırıcıdan ([QuickParser]) geçer. Ses cihazın kendi
/// konuşma tanımasıdır ([DeviceSpeech]) — model/kota yok; tanıma yoksa (web)
/// mikrofon düğmesi hiç görünmez.
///
/// Durum dışarı sızmaz: yazarken yalnız bu satır değişir, ekranın geri kalanı
/// ancak madde ÇIKTIĞINDA haberdar olur.
class QuickEntryBar extends ConsumerStatefulWidget {
  const QuickEntryBar({
    super.key,
    required this.parser,
    required this.onItems,
    this.onTrailingQty,
    this.onSubmittedEmpty,
    this.focusNode,
    this.hint,
    this.autoListen = false,
    this.autoListenDelay = Duration.zero,
    this.onListeningChanged,
    this.raw = false,
    this.onRawChanged,
    this.onRawSubmitted,
    this.onSpeechEnd,
    this.onDoneWord,
    this.initialText = '',
  });

  final QuickParser parser;

  /// Alana yazılı gelen metin (HE-3, uygulama dışından hızlı ekle). ELLE
  /// YAZILMIŞ sayılır: kendiliğinden dinleme başlamaz (ham kipte tanıyıcı
  /// alanı baştan yazar). Değişim bildirilmez — çağıran kendisi çözer.
  final String initialText;

  /// Yeni çıkan maddeler (sırayla).
  final ValueChanged<List<QuickItem>> onItems;

  /// Maddesiz kalan miktar ("3 kg" + Enter): son eklenen maddeye yapışır.
  final ValueChanged<String>? onTrailingQty;

  /// Boş alanda Enter (ör. "bitti").
  final VoidCallback? onSubmittedEmpty;

  final FocusNode? focusNode;
  final String? hint;

  /// Kurulur kurulmaz dinlemeye başlar (izin varsa).
  final bool autoListen;

  /// Kendiliğinden dinleme bu kadar SONRA başlar: levha açılışı ve klavye
  /// animasyonu bitsin (kullanıcı bulgusu 2026-11-19: "hızlı ekle açıkken
  /// klavye kasıyor" — tanıyıcı oturumu levha + klavye animasyonuyla aynı
  /// karelerde açılıyordu). Bu arada kullanıcı yazmaya başlarsa dinleme hiç
  /// başlamaz.
  final Duration autoListenDelay;

  /// Kullanıcı mikrofonu ELLE açıp kapattı (tercihi hatırlamak için).
  final ValueChanged<bool>? onListeningChanged;

  /// HAM KİP ("şu nota ekle" levhası): metin maddeye dönüp alandan
  /// eksilmez; yazılan da söylenen de alanda durur, çağıran [onRawChanged]
  /// ile okur (önce hedef not çözülecek).
  final bool raw;
  final ValueChanged<String>? onRawChanged;
  final ValueChanged<String>? onRawSubmitted;

  /// Dinleme kendiliğinden bitti (sessizlik) — ham kipte "söyle, eklensin".
  final VoidCallback? onSpeechEnd;

  /// Konuşmanın sonunda "bitti" / "bu kadar" söylendi ([stripDoneWord]):
  /// dinleme durdu, söz metinden atıldı, kalan maddeler döküldü. Çağıran
  /// işi bitirir (notu oluşturur). Verilmezse söz sıradan metin sayılır.
  final VoidCallback? onDoneWord;

  @override
  ConsumerState<QuickEntryBar> createState() => QuickEntryBarState();
}

class QuickEntryBarState extends ConsumerState<QuickEntryBar> {
  final _c = TextEditingController();
  bool _applying = false;
  Timer? _idle;
  late String _lastText;

  final _listening = ValueNotifier<bool>(false);
  final _heard = ValueNotifier<String>('');
  final _micAvailable = ValueNotifier<bool>(false);
  final _hasText = ValueNotifier<bool>(false);
  VoiceListenSession? _session;
  String _spoken = '';
  int _spokenCount = 0;
  Timer? _autoTimer;

  /// Kullanıcı ELLE yazdı (konuşma tanımadan gelen metin değil).
  bool _typed = false;

  /// Alana tanıyıcı yazıyor: [_onChanged] bunu elle yazım saymaz.
  bool _fromSpeech = false;

  /// Ham kipte dinleme başlarken alanda duran yazı (konuşma sonuna eklenir).
  String _rawPrefix = '';

  /// H1: son konuşma sonucunun zamanı — yalın "bitti" yalnız [bareDonePause]
  /// sessizlikten sonra geldiyse bitiş sayılır ("süt bitti" listeyi kapatmaz).
  DateTime? _lastSpeechAt;
  static final bareDonePause = AppMotion.long + AppMotion.medium;

  @visibleForTesting
  static DateTime Function() debugClock = DateTime.now;

  /// Yazmayı bırakınca devamı beklenen öbek başı ("süt" → "süt tozu"
  /// olabilirdi) maddeye döner.
  static final idleDelay = AppMotion.long + AppMotion.medium;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialText;
    _lastText = initial;
    _hasText.value = initial.isNotEmpty;
    if (initial.isNotEmpty) {
      _c.value = TextEditingValue(
        text: initial,
        selection: TextSelection.collapsed(offset: initial.length),
      );
      _typed = true;
    }
    _c.addListener(_onChanged);
    unawaited(
      DeviceSpeech.isAvailable().then((ok) async {
        if (!mounted) return;
        _micAvailable.value = ok;
        // Kendiliğinden dinleme İZİN İSTEMEZ (KT-24): açıklamasız sistem
        // kutusu ilk dokunuşta çıkıyordu. İzin yoksa mikrofona basınca
        // istenir ([toggleListening] → [_startListening]).
        if (ok &&
            widget.autoListen &&
            await DeviceSpeech.micPermissionGranted() &&
            mounted) {
          void go() {
            if (mounted && !_typed) unawaited(_startListening(manual: false));
          }

          if (widget.autoListenDelay == Duration.zero) {
            go();
          } else {
            _autoTimer = Timer(widget.autoListenDelay, go);
          }
        }
      }),
    );
  }

  @override
  void dispose() {
    _idle?.cancel();
    _autoTimer?.cancel();
    unawaited(_session?.cancel());
    _c.dispose();
    _listening.dispose();
    _heard.dispose();
    _micAvailable.dispose();
    _hasText.dispose();
    super.dispose();
  }

  /// Alanda kalan her şeyi maddeye çevirir (Bitti / Enter).
  void flush() {
    if (widget.raw) return;
    _idle?.cancel();
    final spoken = _session != null;
    if (spoken) _finishSpeech();
    _consume(widget.parser.parse(_c.text, flush: true), _c.text);
  }

  /// Alandaki ham metin (hedef seçimi gibi işler için).
  String get text => _c.text;

  bool get isListening => _listening.value;

  /// Dinlemeyi dışarıdan başlatır (ör. ⚙ menüsünden "Açılınca dinle" açılınca).
  Future<bool> startListening({bool manual = true}) =>
      _startListening(manual: manual);

  /// Bekleyen ya da süren dinlemeyi durdurur.
  Future<void> stopListening() {
    _autoTimer?.cancel();
    return _stopListening();
  }

  /// Alanı temizler ve (ham kipte) süren konuşma oturumunu bırakır.
  void clear() {
    _autoTimer?.cancel();
    final session = _session;
    if (session != null && widget.raw) {
      _session = null;
      unawaited(session.cancel());
      _spoken = '';
      _rawPrefix = '';
      _listening.value = false;
    }
    if (_c.text.isEmpty) return;
    _applying = true;
    _lastText = '';
    _hasText.value = false;
    _c.clear();
    _applying = false;
    if (widget.raw) widget.onRawChanged?.call('');
  }

  void _emit(QuickParse r) {
    if (r.items.isNotEmpty) widget.onItems(r.items);
    if (r.trailingQty.isNotEmpty) widget.onTrailingQty?.call(r.trailingQty);
  }

  void _consume(QuickParse r, String text) {
    _emit(r);
    if (r.rest == text) return;
    _applying = true;
    _lastText = r.rest;
    _hasText.value = r.rest.isNotEmpty;
    _c.value = TextEditingValue(
      text: r.rest,
      selection: TextSelection.collapsed(offset: r.rest.length),
    );
    _applying = false;
  }

  void _onChanged() {
    if (_applying) return;
    final text = _c.text;
    // Odak / imleç / composing değişimi (metin aynıyken) elle yazım DEĞİLDİR:
    // levha açılışında focusAfterRouteOpens selection'ı (-1→0) değiştirince
    // bekleyen kendiliğinden dinleme zamanlayıcısı iptal oluyordu (2026-11-20).
    if (text == _lastText) return;
    _lastText = text;
    _hasText.value = text.isNotEmpty;
    if (!_fromSpeech) _onTyped();
    if (widget.raw) {
      widget.onRawChanged?.call(text);
      return;
    }
    _idle?.cancel();
    if (text.isEmpty) return;
    final r = widget.parser.parse(text);
    if (r.items.isNotEmpty || r.trailingQty.isNotEmpty) _consume(r, text);
    if (_c.text.trim().isEmpty) return;
    _idle = Timer(idleDelay, () {
      if (!mounted) return;
      final now = _c.text;
      // Yarım kelime beklenir: yalnız kelime bitmişse (sonda ayırıcı).
      if (now.isEmpty || now.trimRight() == now) return;
      final settled = widget.parser.parse(now, idle: true);
      if (settled.items.isNotEmpty) _consume(settled, now);
    });
  }

  /// ELLE YAZIM DİNLEMEYİ KESER (kullanıcı bulgusu 2026-11-19): ham kipte
  /// tanıyıcının her sonucu alanı baştan yazdığından, dinleme sürerken
  /// klavyeyle yazılan harfler bir sonraki sonuçta siliniyordu; tanıyıcı da
  /// klavyeyle aynı anda çalışıyordu. Kendiliğinden başlamış dinleme
  /// sessizce iptal edilir (yazılan kalır); bekleyen kendiliğinden başlatma
  /// da iptal. Elle açılan mikrofonda yalnız ham kipte kesilir.
  void _onTyped() {
    if (_typed && _session == null) return;
    _typed = true;
    _autoTimer?.cancel();
    final session = _session;
    if (session == null || !widget.raw) return;
    _session = null;
    unawaited(session.cancel());
    _spoken = '';
    _rawPrefix = '';
    _listening.value = false;
  }

  void _onSubmitted() {
    if (widget.raw) {
      widget.onRawSubmitted?.call(_c.text);
      return;
    }
    if (_c.text.trim().isEmpty) {
      widget.onSubmittedEmpty?.call();
      return;
    }
    flush();
  }

  // ── Ses ───────────────────────────────────────────────────────────────

  Future<void> toggleListening() async {
    if (_session != null) {
      await _stopListening();
      widget.onListeningChanged?.call(false);
    } else {
      final ok = await _startListening(manual: true);
      if (ok) widget.onListeningChanged?.call(true);
    }
  }

  Future<bool> _startListening({required bool manual}) async {
    _autoTimer?.cancel();
    if (_session != null) return true;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final permitted = manual
        ? await DeviceSpeech.ensureMicPermission()
        : await DeviceSpeech.micPermissionGranted();
    if (!permitted) {
      if (manual) messenger?.showMessage(l10n.micPermissionDenied);
      return false;
    }
    if (!mounted) return false;
    _spoken = '';
    _spokenCount = 0;
    _lastSpeechAt = null;
    _rawPrefix = _c.text.trim();
    late final VoiceListenSession session;
    session = VoiceListenSession(
      locale: l10n.localeName.startsWith('tr') ? 'tr-TR' : 'en-US',
      autoStop: () => ref.read(voiceAutoStopProvider),
      preferOffline: ref.read(voiceOfflineProvider),
      gate: SilenceGate(afterSpeech: ref.read(voiceSilenceProvider).duration),
      onText: (text) {
        if (mounted && identical(_session, session)) _onSpeech(text);
      },
      onEnd: (_) {
        if (!identical(_session, session)) return;
        unawaited(
          _stopListening().then((_) {
            if (mounted) widget.onSpeechEnd?.call();
          }),
        );
      },
      onError: (message) {
        if (!identical(_session, session)) return;
        unawaited(_stopListening());
        if (mounted) messenger?.showMessage(message);
      },
    );
    _session = session;
    _listening.value = true;
    session.start();
    return true;
  }

  /// Tanıyıcı o ana kadarki TAM metni verir; yalnız yeni tamamlanan maddeler
  /// çıkar. Son kelime bir sonraki gelene kadar bekler — tanıyıcının sonradan
  /// düzelttiği kelime listeye yanlış girmesin.
  void _onSpeech(String full) {
    final now = debugClock();
    final gap = _lastSpeechAt == null
        ? Duration.zero
        : now.difference(_lastSpeechAt!);
    _lastSpeechAt = now;
    if (widget.onDoneWord != null) {
      final done = parseDoneWord(full);
      // H1 (17K §4.1): yalın "bitti"/"done" yalnız ≥ 0,7 sn sessizlikten sonra
      // bitiş sayılır; "süt bitti" gibi bitişik cümle dinlemeyi kapatmaz.
      if (done != null && (!done.bare || gap >= bareDonePause)) {
        _onDoneWord(done.rest);
        return;
      }
    }
    _spoken = full;
    if (widget.raw) {
      final text = _rawPrefix.isEmpty ? full : '$_rawPrefix $full';
      _setFromSpeech(text);
      return;
    }
    final r = widget.parser.parse(full);
    if (r.items.length > _spokenCount) {
      widget.onItems(r.items.sublist(_spokenCount));
      _spokenCount = r.items.length;
    }
    _heard.value = r.rest.trim();
  }

  /// "Bitti" duyuldu: söz atılmış metinle son kez işlenir, oturum İPTAL
  /// edilir (durdurulsa son sonuç "bitti"yi yeniden getirirdi), çağırana
  /// haber verilir.
  void _onDoneWord(String rest) {
    final session = _session;
    _session = null;
    _lastSpeechAt = null;
    unawaited(session?.cancel());
    if (widget.raw) {
      final text = [_rawPrefix, rest].where((t) => t.isNotEmpty).join(' ');
      _setFromSpeech(text);
      _spoken = '';
    } else {
      _spoken = rest;
      _finishSpeech();
    }
    _listening.value = false;
    widget.onDoneWord?.call();
  }

  void _setFromSpeech(String text) {
    _fromSpeech = true;
    try {
      _c.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } finally {
      _fromSpeech = false;
    }
  }

  void _finishSpeech() {
    if (widget.raw) {
      _spoken = '';
      return;
    }
    final r = widget.parser.parse(_spoken, flush: true);
    if (r.items.length > _spokenCount) {
      widget.onItems(r.items.sublist(_spokenCount));
    }
    if (r.trailingQty.isNotEmpty) widget.onTrailingQty?.call(r.trailingQty);
    _spoken = '';
    _spokenCount = 0;
    _heard.value = '';
  }

  Future<void> _stopListening() async {
    final session = _session;
    if (session == null) return;
    // Önce bitiş metni gelsin (stop son sonucu getirir), sonra kalan dökülür.
    await session.stop();
    if (identical(_session, session)) _session = null;
    if (!mounted) return;
    _finishSpeech();
    _listening.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final row = Row(
      children: [
        const SizedBox(width: AppSpace.m),
        Icon(Icons.bolt_outlined, size: AppIconSize.m, color: scheme.primary),
        const SizedBox(width: AppSpace.s),
        Expanded(
          child: TextField(
            key: const ValueKey('quick-entry-field'),
            controller: _c,
            focusNode: widget.focusNode,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            // Enter klavyeyi kapatmaz: art arda madde yazılır.
            onEditingComplete: _onSubmitted,
            style: text.rowTitle,
            decoration: InputDecoration(
              hintText: widget.hint ?? l10n.quickEntryHint,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.m),
            ),
          ),
        ),
        if (widget.raw)
          // Temizle düğmesi: RenderOffstage doğrudan _hasText dinler — ilk
          // harfte 0 widget kurulumu (S56 yazma bütçesi).
          _OffstageWhen(
            show: _hasText,
            child: Semantics(
              button: true,
              label: l10n.clear,
              child: GestureDetector(
                key: const ValueKey('quick-entry-clear'),
                behavior: HitTestBehavior.opaque,
                onTap: clear,
                child: SizedBox(
                  width: AppSpace.xxxl + AppSpace.s,
                  height: AppSpace.xxl + AppSpace.xxl,
                  child: Icon(
                    Icons.close,
                    size: AppIconSize.s,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ValueListenableBuilder<bool>(
          valueListenable: _micAvailable,
          builder: (context, available, _) => !available
              ? const SizedBox(width: AppSpace.m)
              : ValueListenableBuilder<bool>(
                  valueListenable: _listening,
                  builder: (context, on, _) => IconButton(
                    key: const ValueKey('quick-entry-mic'),
                    tooltip: on ? l10n.quickEntryMicStop : l10n.quickEntryMic,
                    isSelected: on,
                    style: on
                        ? IconButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                          )
                        : null,
                    icon: const Icon(AppIcons.dictation),
                    onPressed: toggleListening,
                  ),
                ),
        ),
        const SizedBox(width: AppSpace.xs),
      ],
    );
    final box = widget.raw
        ? ValueListenableBuilder<bool>(
            valueListenable: _listening,
            builder: (context, on, child) => DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: on
                    ? Border.all(
                        color: scheme.primary.withValues(alpha: AppAlpha.muted),
                      )
                    : null,
              ),
              child: child,
            ),
            child: row,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.l),
            ),
            child: row,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        box,
        // Dinleme satırı: yeri HEP ayrılmış (boy sabit; açılıp kapanırken
        // altındaki liste oynamaz).
        SizedBox(
          height: 20,
          child: ValueListenableBuilder<bool>(
            valueListenable: _listening,
            builder: (context, on, _) => !on
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpace.m,
                      right: AppSpace.m,
                      top: AppSpace.xxs,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: ValueListenableBuilder<String>(
                            valueListenable: _heard,
                            builder: (context, heard, _) => Text(
                              heard.isEmpty
                                  ? l10n.quickEntryListening
                                  : '${l10n.quickEntryListening} $heard',
                              key: const ValueKey('quick-entry-heard'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.meta.copyWith(color: scheme.primary),
                            ),
                          ),
                        ),
                        if (_session != null) ...[
                          const SizedBox(width: AppSpace.s),
                          SizedBox(
                            width: AppSpace.xxxl + AppSpace.xxxl,
                            child: VoiceLevelWave(
                              key: const ValueKey('quick-entry-wave'),
                              active: true,
                              level: _session!.level,
                              color: scheme.primary,
                              height: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _OffstageWhen extends SingleChildRenderObjectWidget {
  const _OffstageWhen({required this.show, super.child});

  final ValueListenable<bool> show;

  @override
  _RenderOffstageWhen createRenderObject(BuildContext context) =>
      _RenderOffstageWhen(show);

  @override
  void updateRenderObject(BuildContext context, _RenderOffstageWhen r) =>
      r.show = show;
}

class _RenderOffstageWhen extends RenderOffstage {
  _RenderOffstageWhen(this._show) : super(offstage: !_show.value);

  ValueListenable<bool> _show;

  set show(ValueListenable<bool> v) {
    if (identical(_show, v)) return;
    if (attached) _show.removeListener(_sync);
    _show = v;
    if (attached) _show.addListener(_sync);
    _sync();
  }

  void _sync() => offstage = !_show.value;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _show.addListener(_sync);
    _sync();
  }

  @override
  void detach() {
    _show.removeListener(_sync);
    super.detach();
  }
}
