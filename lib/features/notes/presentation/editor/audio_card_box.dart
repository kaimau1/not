import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/utils/video_time.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../domain/attachment.dart';
import 'video_hub_scope.dart';
import 'voice_note_recorder.dart';

/// Sayfaya gömülen SES kartının ekte saklanan oranı (bkz. `kTextBoxWidth`):
/// geniş, alçak bir oynatıcı HAPI (2026-10-28: 280 → 190; sayfada boy ayrıca
/// 52–76 dp aralığında tutulur, bkz. `_NotePageCanvasState._sizeOf`).
const int kAudioBoxWidth = 1000;
const int kAudioBoxHeight = 190;

/// **SES EKİ SAYFADA ve TEPEDE** (kullanıcı isteği 2026-10-17: "sabit,
/// gömme ve balonlu geçiş olabilecek TÜM türler için çalışmalı").
///
/// Ses eskiden yalnız alt şeritteki küçük oynatıcıdan çalınıyordu: ders
/// kaydını dinlerken not almak için ses ile yazı aynı ekranda duramıyordu.
/// Artık ses kartı sayfada yüzer (görsel gibi taşınır/boyutlanır) ya da
/// notun tepesinde sabit durur. Kart notun video merkezine ([NoteVideoHub])
/// kaydolur: metindeki `1:23` damgasına dokunmak sesi oraya sarar, ⏱ "Bu ana
/// not al" sesin o anını nota yazar, sabit bölmenin denetim çubuğu (±sn,
/// hız) videodaki gibi çalışır.
///
/// Oynatıcı TEMBEL: kart çizilince değil ▶'de (ya da damga dokunuşunda)
/// kurulur — sesli bir notu açmak yerel çözücü ayağa kaldırmasın.
class AudioCardBox extends StatefulWidget {
  const AudioCardBox({
    super.key,
    required this.attachment,
    this.noteAtButton = true,
  });

  final Attachment attachment;

  /// ⏱ "Bu ana not al" düğmesi (sabit bölmede çubukta olduğu için kapalı).
  final bool noteAtButton;

  @override
  State<AudioCardBox> createState() => _AudioCardBoxState();
}

class _AudioCardBoxState extends State<AudioCardBox> {
  AudioPlayer? _player;
  Future<AudioPlayer?>? _loading;
  NoteVideoHub? _hub;
  _AudioTimeSource? _source;

  /// Sürüklenen kaydırıcının değeri (bırakınca sarılır).
  double? _drag;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_source != null) return;
    final hub = VideoHubScope.maybeOf(context);
    if (hub == null) return;
    final source = _AudioTimeSource(widget.attachment.id, _ensure);
    _hub = hub..register(source);
    _source = source;
  }

  @override
  void dispose() {
    final source = _source;
    if (source != null) _hub?.unregister(source);
    source?.dispose();
    _player?.dispose();
    super.dispose();
  }

  /// Oynatıcıyı BİR KEZ kurar (eşzamanlı çağrılar aynı işi bekler).
  Future<AudioPlayer?> _ensure() => _loading ??= _load();

  Future<AudioPlayer?> _load() async {
    final a = widget.attachment;
    final player = AudioPlayer();
    try {
      if (localFileExists(a.localPath)) {
        await player.setFilePath(a.localPath);
      } else if (a.isUploaded) {
        await player.setUrl(a.downloadUrl);
      } else {
        await player.dispose();
        _loading = null;
        if (mounted) {
          showAppMessage(context, context.l10n.attachmentNotSynced);
        }
        return null;
      }
    } catch (_) {
      await player.dispose();
      _loading = null;
      return null;
    }
    if (!mounted) {
      await player.dispose();
      return null;
    }
    _source?.attach(player);
    setState(() => _player = player);
    return player;
  }

  Future<void> _toggle() async {
    unawaited(HapticFeedback.selectionClick());
    final player = await _ensure();
    if (player == null) return;
    final source = _source;
    if (source != null) _hub?.touch(source);
    if (player.playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      unawaited(player.play());
    }
  }

  Future<void> _noteAt() async {
    final source = _source;
    final hub = _hub;
    if (source == null || hub == null) return;
    if (!await hub.noteAt(source) && mounted) {
      ScaffoldMessenger.of(context).showMessage(context.l10n.videoTimeUnknown);
    }
  }

  /// Dalgaya dokunma/sürükleme: oran olarak sarar.
  Future<void> _seekTo(double fraction) async {
    final p = await _ensure();
    final total = p?.duration ?? recordedDuration(widget.attachment);
    if (p == null || total == null) return;
    await p.seek(total * fraction.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final player = _player;
    final a = widget.attachment;
    return LayoutBuilder(
      builder: (context, box) {
        // HAP (kullanıcı isteği 2026-10-28, örnek uygulamadaki sesli not):
        // oynat halkası · süre · dalga. Dar kutuda süre ve ⏱ düşer, oynat
        // düğmesi ve dalga hep kalır.
        final w = box.maxWidth.isFinite ? box.maxWidth : 320.0;
        final h = box.maxHeight.isFinite ? box.maxHeight : 64.0;
        final button = (h * 0.64).clamp(28.0, 46.0);
        final showTime = w >= 170;
        final showNoteAt =
            widget.noteAtButton && w >= 300 && _hub?.onNoteAt != null;
        // Kayıt dışı ses dosyasının ADI (ders.mp3) yer varsa dalganın üstünde.
        final showTitle = !isVoiceRecording(a) && h >= 60 && w >= 200;
        final accent = scheme.primary;
        final wave = Expanded(
          child: _WaveSeek(
            player: player,
            wave: a.displayWave,
            drag: _drag,
            active: accent,
            inactive: accent.withValues(alpha: 0.28),
            onDrag: (v) => setState(() => _drag = v),
            onDragEnd: (v) async {
              setState(() => _drag = null);
              await _seekTo(v);
            },
          ),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            // Notun zemini ne olursa olsun hafif koyulaşan yarı saydam hap:
            // kâğıt rengi altından geçer (örnekteki gibi).
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.07),
              scheme.onSurface.withValues(alpha: 0.05),
            ),
            borderRadius: BorderRadius.circular(h / 2),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: (h - button) / 2,
              end: h * 0.28,
            ),
            child: Row(
              children: [
                _PlayButton(
                  player: player,
                  size: button,
                  color: accent,
                  tooltip: l10n.mediaPlay,
                  onTap: _toggle,
                ),
                SizedBox(width: (h * 0.18).clamp(8.0, 14.0)),
                if (showTime) ...[
                  _TimeLabel(
                    player: player,
                    total: recordedDuration(a),
                    color: scheme.onSurface.withValues(alpha: 0.78),
                  ),
                  const SizedBox(width: 12),
                ],
                if (showTitle)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(
                          height: (h * 0.42).clamp(18.0, 40.0),
                          child: Row(children: [wave]),
                        ),
                      ],
                    ),
                  )
                else
                  wave,
                if (showNoteAt)
                  IconButton(
                    key: const ValueKey('audio-note-at'),
                    tooltip: l10n.videoNoteAtTime,
                    visualDensity: VisualDensity.compact,
                    onPressed: _noteAt,
                    icon: Icon(
                      Icons.more_time_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Kaydın SÜRESİ — oynatıcı kurulmadan önce de bilinsin diye dosya adından
/// (`kayit_12s.m4a`, bkz. `AttachmentRepository.prepareAudio`).
Duration? recordedDuration(Attachment a) {
  final m = RegExp(r'^kayit_(\d+)s\.').firstMatch(a.fileName);
  if (m == null) return null;
  return Duration(seconds: int.parse(m.group(1)!));
}

/// Uygulamanın kendi ses kaydı mı (adı anlamsız: başlık gösterilmez).
bool isVoiceRecording(Attachment a) => a.fileName.startsWith('kayit_');

/// OYNAT halkası: çalmıyorken ince halka + üçgen, çalarken dolu daire +
/// duraklat (örnek uygulamadaki gibi sakin, hapın içinde kaybolmayan).
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.player,
    required this.size,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final AudioPlayer? player;
  final double size;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onColor = Theme.of(context).colorScheme.onPrimary;
    Widget face(bool playing, bool busy) => InkResponse(
      onTap: onTap,
      radius: size * 0.62,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: playing ? color : color.withValues(alpha: 0),
          border: Border.all(color: color, width: size >= 36 ? 2.2 : 1.8),
        ),
        child: busy
            ? Padding(
                padding: EdgeInsets.all(size * 0.28),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: playing ? onColor : color,
                ),
              )
            // Oynat ⇄ duraklat simgesi yumuşakça döner (ani değişim
            // yerine — küçük ama "premium" hissin büyük kısmı bu).
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(playing),
                  color: playing ? onColor : color,
                  size: size * 0.58,
                ),
              ),
      ),
    );
    final p = player;
    final button = p == null
        ? face(false, false)
        : StreamBuilder<PlayerState>(
            stream: p.playerStateStream,
            initialData: p.playerState,
            builder: (context, snap) {
              final state = snap.data;
              final busy =
                  state?.processingState == ProcessingState.loading ||
                  state?.processingState == ProcessingState.buffering;
              final playing =
                  (state?.playing ?? false) &&
                  state?.processingState != ProcessingState.completed;
              return face(playing, busy && (state?.playing ?? false));
            },
          );
    return Tooltip(message: tooltip, child: button);
  }
}

/// Süre yazısı: dururken toplam süre, çalarken geçen süre (`00:04`).
class _TimeLabel extends StatelessWidget {
  const _TimeLabel({
    required this.player,
    required this.total,
    required this.color,
  });

  final AudioPlayer? player;
  final Duration? total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget label(Duration d) => Text(
      formatClock(d),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final p = player;
    if (p == null) return label(total ?? Duration.zero);
    return StreamBuilder<Duration>(
      stream: p.createPositionStream(
        maxPeriod: const Duration(milliseconds: 400),
      ),
      initialData: p.position,
      builder: (context, snap) {
        final position = snap.data ?? Duration.zero;
        final whole = p.duration ?? total ?? Duration.zero;
        final idle =
            !p.playing &&
            (position == Duration.zero ||
                p.processingState == ProcessingState.completed);
        return label(idle ? whole : position);
      },
    );
  }
}

/// Dalga + sarma: dokununca o noktaya, sürükleyince parmakla sarar. Yalnız
/// bu parça konumla tazelenir (kartın geri kalanı değil).
class _WaveSeek extends StatelessWidget {
  const _WaveSeek({
    required this.player,
    required this.wave,
    required this.drag,
    required this.active,
    required this.inactive,
    required this.onDrag,
    required this.onDragEnd,
  });

  final AudioPlayer? player;
  final List<int> wave;
  final double? drag;
  final Color active;
  final Color inactive;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    Widget bars(double progress) => LayoutBuilder(
      builder: (context, box) {
        double at(Offset local) =>
            (local.dx / box.maxWidth).clamp(0.0, 1.0).toDouble();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => onDragEnd(at(d.localPosition)),
          onHorizontalDragUpdate: (d) => onDrag(at(d.localPosition)),
          onHorizontalDragEnd: (_) => onDragEnd(drag ?? progress),
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(box.maxWidth, box.maxHeight),
              painter: WaveformBarsPainter(
                wave: wave,
                progress: drag ?? progress,
                active: active,
                inactive: inactive,
              ),
            ),
          ),
        );
      },
    );
    final p = player;
    if (p == null) return bars(0);
    return StreamBuilder<Duration>(
      stream: p.createPositionStream(
        maxPeriod: const Duration(milliseconds: 120),
      ),
      initialData: p.position,
      builder: (context, snap) {
        final total = p.duration;
        final position = snap.data ?? Duration.zero;
        final done = p.processingState == ProcessingState.completed;
        final progress = total == null || total <= Duration.zero || done
            ? 0.0
            : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
        return bars(progress.toDouble());
      },
    );
  }
}

/// Ses oynatıcısının not tarafına açılan yüzü (bkz. [VideoTimeSource]).
/// Oynatıcı tembel kurulduğu için kayıt ÖNCEDEN yapılır; ilk sarma/oynatma
/// isteği oynatıcıyı kurar.
class _AudioTimeSource extends VideoTimeSource {
  _AudioTimeSource(this.attachmentId, this._ensure);

  @override
  final String attachmentId;
  final Future<AudioPlayer?> Function() _ensure;

  AudioPlayer? _player;
  final _changes = ValueNotifier<int>(0);
  StreamSubscription<Object?>? _subs;
  StreamSubscription<Object?>? _pos;

  void attach(AudioPlayer player) {
    _player = player;
    _subs = player.playerStateStream.listen((_) => _changes.value++);
    _pos = player
        .createPositionStream(
          minPeriod: const Duration(milliseconds: 500),
          maxPeriod: const Duration(milliseconds: 1000),
        )
        .listen((_) => _changes.value++);
    _changes.value++;
  }

  void dispose() {
    _subs?.cancel();
    _pos?.cancel();
    _changes.dispose();
  }

  @override
  Listenable get changes => _changes;

  /// Hiç çalınmamış ses BAŞINDADIR: "bu ana not al" 0:00 yazar (videodaki
  /// "okunamadı" durumu seste yok — konum her zaman bilinir).
  @override
  Future<Duration?> position() async => _player?.position ?? Duration.zero;

  @override
  Future<void> seekTo(Duration position) async {
    final player = await _ensure();
    if (player == null) return;
    await player.seek(
      shiftedPosition(position, Duration.zero, player.duration),
    );
    unawaited(player.play());
  }

  @override
  bool get isPlaying => _player?.playing ?? false;

  @override
  Duration? get lastPosition => _player?.position;

  @override
  Duration? get duration => _player?.duration;

  @override
  Future<void> play() async {
    final player = await _ensure();
    if (player == null) return;
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    unawaited(player.play());
  }

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> seekBy(Duration delta) async {
    final player = await _ensure();
    if (player == null) return;
    await player.seek(shiftedPosition(player.position, delta, player.duration));
  }

  @override
  double get speed => _player?.speed ?? 1;

  @override
  Future<void> setSpeed(double value) async {
    final player = await _ensure();
    await player?.setSpeed(value);
  }
}
