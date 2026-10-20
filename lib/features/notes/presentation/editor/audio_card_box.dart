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

/// Sayfaya gömülen SES kartının ekte saklanan oranı (bkz. `kTextBoxWidth`):
/// geniş, alçak bir oynatıcı şeridi.
const int kAudioBoxWidth = 1000;
const int kAudioBoxHeight = 280;

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
      ScaffoldMessenger.of(
        context,
      ).showMessage(context.l10n.videoTimeUnknown);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final player = _player;
    return LayoutBuilder(
      builder: (context, box) {
        // Kart, sayfadaki kutunun ölçüsüne göre sıkışır: dar kutuda süre ve
        // ⏱ düşer, oynat düğmesi ve ilerleme hep kalır.
        final w = box.maxWidth.isFinite ? box.maxWidth : 320.0;
        final h = box.maxHeight.isFinite ? box.maxHeight : 88.0;
        final button = (h * 0.62).clamp(28.0, 52.0);
        final roomy = w >= 200;
        final showNoteAt =
            widget.noteAtButton && w >= 240 && _hub?.onNoteAt != null;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primaryContainer,
                Color.alphaBlend(
                  scheme.tertiary.withValues(alpha: 0.18),
                  scheme.primaryContainer,
                ),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: h * 0.14),
            child: Row(
              children: [
                _PlayButton(
                  player: player,
                  size: button,
                  color: scheme.primary,
                  onColor: scheme.onPrimary,
                  tooltip: l10n.mediaPlay,
                  onTap: _toggle,
                ),
                SizedBox(width: h * 0.14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (h * 0.16).clamp(10.0, 14.0),
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      _Progress(
                        player: player,
                        drag: _drag,
                        showTime: roomy,
                        onDrag: (v) => setState(() => _drag = v),
                        onDragEnd: (v) async {
                          setState(() => _drag = null);
                          final p = await _ensure();
                          final total = p?.duration;
                          if (p == null || total == null) return;
                          await p.seek(total * v);
                        },
                      ),
                    ],
                  ),
                ),
                if (showNoteAt)
                  IconButton(
                    key: const ValueKey('audio-note-at'),
                    tooltip: l10n.videoNoteAtTime,
                    visualDensity: VisualDensity.compact,
                    onPressed: _noteAt,
                    icon: Icon(
                      Icons.more_time_rounded,
                      color: scheme.onPrimaryContainer,
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

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.player,
    required this.size,
    required this.color,
    required this.onColor,
    required this.tooltip,
    required this.onTap,
  });

  final AudioPlayer? player;
  final double size;
  final Color color;
  final Color onColor;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget face(bool playing, bool busy) => Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 1.5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: busy
              ? Padding(
                  padding: EdgeInsets.all(size * 0.3),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: onColor,
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
                    color: onColor,
                    size: size * 0.58,
                  ),
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

class _Progress extends StatelessWidget {
  const _Progress({
    required this.player,
    required this.drag,
    required this.showTime,
    required this.onDrag,
    required this.onDragEnd,
  });

  final AudioPlayer? player;
  final double? drag;
  final bool showTime;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget row(Duration position, Duration? total) {
      final t = total ?? Duration.zero;
      final value =
          drag ??
          (t > Duration.zero
              ? (position.inMilliseconds / t.inMilliseconds).clamp(0.0, 1.0)
              : 0.0);
      return Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: scheme.primary,
                inactiveTrackColor: scheme.primary.withValues(alpha: 0.22),
                thumbColor: scheme.primary,
              ),
              child: SizedBox(
                height: 22,
                child: Slider(
                  value: value.toDouble(),
                  onChanged: onDrag,
                  onChangeEnd: onDragEnd,
                ),
              ),
            ),
          ),
          if (showTime)
            Text(
              total == null
                  ? formatVideoTimestamp(position)
                  : '${formatVideoTimestamp(position)} / '
                        '${formatVideoTimestamp(t)}',
              style: TextStyle(
                fontSize: 10.5,
                color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      );
    }

    final p = player;
    if (p == null) return row(Duration.zero, null);
    // Yalnız bu satır konumla tazelenir (kartın geri kalanı değil).
    return StreamBuilder<Duration>(
      stream: p.createPositionStream(
        maxPeriod: const Duration(milliseconds: 400),
      ),
      initialData: p.position,
      builder: (context, snap) => row(snap.data ?? Duration.zero, p.duration),
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
