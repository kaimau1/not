import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/language_names.dart';
import '../../../core/utils/voice_commands.dart';
import '../../ai/data/gemini_service.dart';
import '../../settings/settings_providers.dart';
import '../data/device_speech.dart';
import '../data/voice_listen_session.dart';
import '../../../core/widgets/app_sheet.dart';

/// Sesli yakalama levhası — ana ekran ve not editörünün ORTAK bileşeni.
///
/// Cihazın YERLEŞİK konuşma tanıması varsa (Android) onu kullanır: metin
/// konuşuldukça anlık akar, ücretsizdir ve Gemini kotası harcamaz. Yerleşik
/// tanıma yoksa (Windows) ses kaydedilir ve bitişte tek seferde yazıya
/// dökülür. Bu iki yol eski `editor/dictation_sheet.dart`ten olduğu gibi
/// taşındı; değişen kabuk ve bitiş akışı.
///
/// ESKİDEN: dinleme biter bitmez metin nota YAZILIYORDU (editörde satır satır
/// canlı). ŞİMDİ: araya bir gözden geçirme evresi girdi — metin levhada durur,
/// kullanıcı düzeltebilir, sonra ne yapılacağını seçer. Bu yüzden levha artık
/// düz `String` değil, metin + SEÇİLEN EYLEM döndürür; yapay zekâ dönüşümünü
/// (özetle/böl/düzelt) çağıran ekran uygular — levha AI'a hiç dokunmaz.
enum VoiceCaptureAction {
  /// Metni olduğu gibi kullan.
  insert,

  /// Özetleyerek ekle / kaydet.
  summarize,

  /// Maddelere böl (editör).
  toItems,

  /// Liste notu yap (ana ekran).
  asList,

  /// Yazım/noktalama düzelt.
  fix,

  /// Asistan notu kendisi kursun (yalnız ana ekran).
  ///
  /// Tasarımın dört çipinde YOK; mevcut sesli asistanın konuşmadan başlık,
  /// madde ve HATIRLATICI çıkaran akışı (`voiceAssistantProvider`) yalnız bu
  /// yolla erişilebilir kaldığı için eklendi — bkz. test/spoken_datetime_test.dart.
  compose,
}

/// Levhanın hangi ekrandan açıldığı: yalnız etiketleri ve çipleri değiştirir.
enum VoiceCaptureTarget { editor, dashboard }

/// Levhanın sonucu.
///
/// [audioPath] yalnızca DÖKÜM YAPILAMADIĞINDA dolu olur (bkz.
/// `_toAudioFallback`): cihazda yerleşik tanıma yoksa konuşma ses olarak
/// kaydedilip yazıya dökülmek üzere yapay zekâya gönderilir; anahtar yoksa,
/// kota bittiyse ya da ağ yoksa o çağrı düşer. ESKİDEN kayıt o noktada
/// SİLİNİYOR ve kullanıcı hata ekranıyla baş başa kalıyordu — konuşulan her
/// şey yok oluyordu. Artık kayıt korunur ve nota SES EKİ olarak girer:
/// yapay zekâ olmasa da not oluşur. Çağıran ekran dolu geldiğinde eki nota
/// bağlamakla yükümlüdür; [audioDuration] ek etiketinde görünen süredir.
/// [title] "başlık X olsun" komutuyla söylenen (ya da gözden geçirmede
/// düzeltilen) başlık; söylenmediyse null.
typedef VoiceCaptureResult = ({
  String text,
  VoiceCaptureAction action,
  String? audioPath,
  Duration audioDuration,
  String? title,
});

/// Seçilen eylemin modele verilecek yönergesi.
///
/// `insert` ve `asList` için `null`: ikisi de yapay zekâ ÇAĞIRMAZ — biri metni
/// olduğu gibi kullanır, öteki notu liste tipine çevirir (bu, çağıran ekranın
/// yerel işi). Yönergeler kullanıcıya gösterilmez, modele gider; bu yüzden
/// çevrilmez — projedeki diğer istemlerle aynı kural (bkz. ai_sheet.dart).
String? voiceCaptureInstruction(VoiceCaptureAction action) => switch (action) {
  // compose de null: onu yapay zekâya veren ayrı bir akış (asistan) var,
  // buradaki genel "yeniden yaz" yönergesiyle karıştırılmamalı.
  VoiceCaptureAction.insert ||
  VoiceCaptureAction.asList ||
  VoiceCaptureAction.compose => null,
  VoiceCaptureAction.summarize =>
    'Bu konuşma dökümünü kısa bir özete indir: ayrıntıları at, ana noktaları '
        'koru, yorum ekleme',
  VoiceCaptureAction.toItems =>
    'Bu konuşma dökümünü maddelere böl: her satır tek bir madde olsun, '
        'başına işaret veya numara koyma',
  VoiceCaptureAction.fix =>
    'Bu konuşma dökümünün yazım ve noktalamasını düzelt; kelimeleri, anlamı '
        've üslubu değiştirme',
};

/// Levhayı açar. Kullanıcı iptal ederse `null` döner.
///
/// Tam ekran DEĞİL (en fazla yüksekliğin %74'ü): arkadaki not ya da liste
/// görünür kalmalı, kullanıcı neyin üstüne konuştuğunu görsün.
Future<VoiceCaptureResult?> showVoiceCaptureSheet(
  BuildContext context, {
  required VoiceCaptureTarget target,
}) => showAppSheet<VoiceCaptureResult>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  // Karartıya dokunuş ve aşağı sürükleme AÇIK: levhanın tek çıkışı sol
  // üstteki çarpı olduğu sürece kapatmak zahmetliydi. İçerik kaybı riski
  // kapıları kilitleyerek değil, çıkarken SORARAK karşılanıyor — dört
  // kapanış yolu da `_askBeforeClosing`'e düşüyor (bkz. PopScope).
  isDismissible: true,
  enableDrag: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  barrierColor: Colors.black.withValues(alpha: 0.32),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.74,
  ),
  builder: (_) => _VoiceCaptureSheet(target: target),
);

/// idle yalnızca "basılı tut" modunda görülür: kullanıcı düğmeyi tutana dek
/// dinleme başlamaz. ready = konuşma bitti, metin gözden geçiriliyor.
enum _Phase { idle, listening, processing, ready, error }

/// Basılı-tut modunda bu süreden KISA basış "dinlemeyi kilitler": parmak
/// kalksa da dinleme sürer, kullanıcı "Bitir"e basana dek durmaz.
///
/// KÖK NEDEN: mod tek yolluydu — düğme bırakılınca dinleme her hâlükârda
/// biterdi. Parmağını bir an kaydıran ya da uzun konuşmak isteyen kullanıcı
/// "ses kısmı çalışmıyor" diyordu; boş dökümle hata ekranına düşülüyordu.
/// Kilit, iki modu tek düğmede birleştirir: tut-konuş-bırak ya da dokun-konuş-
/// bitir. İkisi de aynı düğmeden, ayar değiştirmeden çalışır.
const _kHoldLatchThreshold = Duration(milliseconds: 600);

/// Tek oturumda en uzun dinleme/kayıt. Sınırsızken levhayı açık unutan
/// kullanıcıda mikrofon + kodlayıcı (konuşma yolunda tanıyıcı döngüsü)
/// süresiz çalışıyordu; dolunca biriken içerik gözden geçirmeye taşınır.
const _maxCaptureDuration = Duration(minutes: 10);

class _VoiceCaptureSheet extends ConsumerStatefulWidget {
  const _VoiceCaptureSheet({required this.target});

  final VoiceCaptureTarget target;

  @override
  ConsumerState<_VoiceCaptureSheet> createState() => _VoiceCaptureSheetState();
}

class _VoiceCaptureSheetState extends ConsumerState<_VoiceCaptureSheet> {
  AudioRecorder? _recorder;

  /// Dinlemenin yaşam döngüsü (abonelik, sessizlik, üst sınır, yerli
  /// kapanış) ortak oturumda — editörün sade mikrofonu da aynısını kullanır.
  VoiceListenSession? _session;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  String _text = '';
  String? _recordPath;
  _Phase _phase = _Phase.idle;
  String _errorMessage = '';

  /// ready evresinde metin düzenlenebilir olur; denetleyici o an kurulur.
  final _editController = TextEditingController();

  /// Yerleşik tanıma kullanılıyor mu (yoksa kayıt + toplu döküm).
  bool _useSpeech = false;
  bool _ready = false;

  /// Parmak şu an düğmenin üstünde mi (basılı-tut modu).
  bool _pressed = false;

  /// Basış anı — kısa dokunuşu (kilit) uzun basıştan ayırmak için.
  DateTime? _pressedAt;

  /// Kısa dokunuşla kilitlendi mi: dinleme parmak kalksa da sürer ve düğme
  /// "Bitir"e döner.
  bool _latched = false;

  /// Dökümü yapılamamış ama korunan ses kaydının yolu; dolu olduğunda not
  /// SES EKİYLE oluşur (bkz. [_toAudioFallback]).
  String? _readyAudioPath;

  /// Tanıyıcının gönderdiği HAM metin; ekrandaki [_text] bunun sesli
  /// komutları uygulanmış hâli (bkz. [applyVoiceCommands]). Ham metin
  /// saklanır ki "Akıllı komutlar" dinlerken kapatılıp açılabilsin.
  String _rawText = '';

  /// "Devam et" ile sürdürülen dinlemede ÖNCEKİ metin: yeni konuşma onun
  /// sonuna eklenir (bkz. [_continue]).
  String _prefix = '';

  /// "başlık X olsun" ile söylenen başlık; gözden geçirmede düzenlenebilir.
  String? _title;
  final _titleController = TextEditingController();

  /// Sessizlik geri sayımının oranı (0–1); arayüzde ince şerit.
  double _silence = 0;

  /// Kayıt yolunda (yerleşik tanıma yok) ses seviyesi — konuşma kanıtı.
  StreamSubscription<Amplitude>? _ampSub;

  /// Uygulanan komut sayısı: artışı yeni bir komut demektir (kısa geri
  /// bildirim + titreşim).
  int _commandCount = 0;
  String _feedback = '';
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    _useSpeech = await DeviceSpeech.isAvailable();
    if (!mounted) return;
    setState(() => _ready = true);
    // Dokunmalı modda levha açılır açılmaz dinlemeye başla; basılı-tut
    // modunda kullanıcı düğmeyi tutana dek bekle.
    if (ref.read(voiceButtonModeProvider) == VoiceButtonMode.tap) {
      await _startListening();
      return;
    }
    // Basılı-tut: izin kutusunu ŞİMDİ aç. Eskiden ilk basışta açılıyordu;
    // parmak düğmedeyken sistem kutusu çıkıyor, kullanıcı "İzin ver"e basmak
    // için parmağını kaldırınca bırakma olayı dinlemeyi hiç başlamadan
    // bitiriyor ve "konuşma algılanamadı" hatası çıkıyordu.
    if (_useSpeech) await DeviceSpeech.ensureMicPermission();
  }

  Future<void> _startListening() async {
    if (_phase == _Phase.listening) return;
    setState(() {
      _phase = _Phase.listening;
      _errorMessage = '';
    });
    final micDenied = context.l10n.micPermissionDenied;
    try {
      // İzin yokken SpeechRecognizer sormadan hata verir; önce iste.
      if (_useSpeech && !await DeviceSpeech.ensureMicPermission()) {
        _fail(micDenied);
        return;
      }
      if (!mounted) return;
      final session = VoiceListenSession(
        useDevice: _useSpeech,
        // Üst sınır: levha açık unutulursa mikrofon süresiz kalmasın; o ana
        // kadarki metin/kayıt gözden geçirme evresine taşınır.
        maxDuration: _maxCaptureDuration,
        autoStop: () => ref.read(voiceAutoStopProvider),
        gate: SilenceGate(afterSpeech: ref.read(voiceSilenceProvider).duration),
        // Basılı-tut modunda parmak düğmedeyken kullanıcı "dinlemeye devam"
        // diyor demektir.
        holdOpen: () => _pressed,
        onText: (text) {
          _rawText = text;
          _applyRaw();
        },
        // Her bitiş (sessizlik, yerli kapanış, üst sınır) gözden geçirmeye
        // taşır: biriken metin kullanılır, hata gösterilmez.
        onEnd: (_) {
          if (mounted) _finish();
        },
        // Biriken metin korunur; kullanıcı "Bitir" ile kullanabilsin diye
        // hata yalnızca gösterilir.
        onError: (message) {
          if (mounted) setState(() => _errorMessage = message);
        },
        onSilence: (progress) {
          if (mounted) setState(() => _silence = progress);
        },
      );
      _session = session;
      if (!_useSpeech) await _startRecording(session);
      if (_phase != _Phase.listening) return;
      session.start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed += const Duration(seconds: 1));
      });
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// Yerleşik tanıma yoksa: dosyaya kaydet, bitince toplu döküm.
  Future<void> _startRecording(VoiceListenSession session) async {
    final micDenied = context.l10n.micPermissionDenied;
    final recorder = AudioRecorder();
    _recorder = recorder;
    if (!await recorder.hasPermission()) {
      _fail(micDenied);
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordPath = p.join(
      dir.path,
      'dikte_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: _recordPath!,
    );
    // Döküm bitişte yapıldığından konuşmanın kanıtı ses seviyesidir: -30
    // dBFS üstü konuşma sayılır (sessiz oda ~-50, konuşma -25…-10).
    _ampSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((a) {
          session.reportLevel(((a.current + 50) / 50).clamp(0.0, 1.0));
          if (a.current > -30) session.reportSpeech();
        });
  }

  /// Ham metne (ayar açıksa) sesli komutları uygular ve ekranı tazeler.
  void _applyRaw() {
    if (!ref.read(voiceSmartCommandsProvider)) {
      _text = _joinPrefix(_rawText);
      if (mounted) setState(() {});
      return;
    }
    final outcome = applyVoiceCommands(_rawText, base: _prefix);
    _text = outcome.text;
    if (outcome.title != null) _title = outcome.title;
    if (outcome.commands > _commandCount) {
      _commandCount = outcome.commands;
      _showCommandFeedback(outcome.last);
    } else if (outcome.commands < _commandCount) {
      // Tanıyıcı kuyruğu düzeltti ve komut metinden çıktı: sayaç geri iner
      // ki aynı komut yeniden söylenince yine geri bildirim versin.
      _commandCount = outcome.commands;
    }
    if (mounted) setState(() {});
    if (outcome.stop && _phase == _Phase.listening) _finish();
  }

  /// Komutlar kapalıyken önceki metinle yeni konuşmayı boşlukla birleştirir.
  String _joinPrefix(String spoken) {
    final next = spoken.trim();
    if (_prefix.isEmpty) return next;
    return next.isEmpty ? _prefix : '$_prefix $next';
  }

  void _showCommandFeedback(VoiceCommand? command) {
    if (command == null || command == VoiceCommand.stop || !mounted) return;
    final l10n = context.l10n;
    HapticFeedback.selectionClick();
    _feedbackTimer?.cancel();
    _feedback = switch (command) {
      VoiceCommand.deleteWords ||
      VoiceCommand.deleteSentence => l10n.voiceCmdDeleted,
      VoiceCommand.clearAll => l10n.voiceCmdCleared,
      VoiceCommand.replace => l10n.voiceCmdReplaced,
      VoiceCommand.newLine => l10n.voiceCmdNewLine,
      VoiceCommand.undo => l10n.voiceCmdUndone,
      VoiceCommand.punctuation => l10n.voiceCmdPunctuation,
      VoiceCommand.title => l10n.voiceCmdTitle,
      VoiceCommand.stop => '',
    };
    _feedbackTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _feedback = '');
    });
  }

  /// Dinlemeyi bitirir ve gözden geçirme evresine geçer (artık POP ETMEZ).
  Future<void> _finish() async {
    // Bitiş birden çok yoldan gelebilir (düğme, sessizlik, "dinlemeyi
    // bitir" komutu, yerli kapanış); aşağıdaki beklemeler sürerken evre hâlâ
    // listening olduğundan ikinci çağrı ayrıca kesilir.
    if (_phase != _Phase.listening || _finishing) return;
    _finishing = true;
    try {
      await _finishListening();
    } finally {
      _finishing = false;
    }
  }

  bool _finishing = false;

  Future<void> _finishListening() async {
    final l10n = context.l10n;
    _ticker?.cancel();
    _stopSilenceWatch();

    if (_useSpeech) {
      // Son sonucu al, akışı kapat.
      await _session?.stop();
      _session = null;
      if (!mounted) return;
      _toReview(_text.trim(), l10n.voiceNothingHeard);
      return;
    }

    setState(() => _phase = _Phase.processing);
    // Kaydın yolu try DIŞINDA tutulur: döküm düşerse dosya SİLİNMEZ, nota ses
    // eki olarak eklenmek üzere elde kalır (bkz. [_toAudioFallback]).
    String? path;
    try {
      path = await _recorder?.stop();
      if (path == null) throw StateError(l10n.voiceNothingHeard);
      final bytes = await File(path).readAsBytes();
      final text = await ref
          .read(geminiServiceProvider)
          .transcribeAudio(bytes, 'audio/mp4');
      if (!mounted) return;
      if (text.trim().isEmpty) {
        _toAudioFallback(path, l10n.voiceNothingHeard);
        return;
      }
      // Döküm elde: ses dosyasına artık gerek yok.
      File(path).delete().ignore();
      // Kayıt yolunda komutlar dökümden SONRA uygulanır (canlı metin yok).
      var clean = _joinPrefix(text);
      if (ref.read(voiceSmartCommandsProvider)) {
        final outcome = applyVoiceCommands(text, base: _prefix);
        clean = outcome.text;
        if (outcome.title != null) _title = outcome.title;
      }
      _toReview(clean.trim(), l10n.voiceNothingHeard);
    } on GeminiException catch (e) {
      _toAudioFallback(path, e.isAuthError ? l10n.aiNoApiKey : e.message);
    } catch (e) {
      _toAudioFallback(path, e.toString());
    }
  }

  void _toReview(String text, String emptyMessage) {
    if (text.isEmpty) {
      _fail(emptyMessage);
      return;
    }
    setState(() {
      _text = text;
      _editController.text = text;
      _titleController.text = _title ?? '';
      _phase = _Phase.ready;
    });
  }

  /// Döküm yapılamadı ama ELDE KAYIT VAR.
  ///
  /// KÖK NEDEN (kullanıcı: "API key yoksa not oluşmuyor, AI olmasa dahi
  /// oluşmalı"): cihazda yerleşik tanıma yoksa konuşma önce ses olarak
  /// kaydedilip yazıya dökülmek üzere yapay zekâya gönderiliyor. Anahtar yok,
  /// kota dolu ya da ağ yoksa o çağrı düşüyordu ve levha hata ekranına
  /// geçiyordu — kayıt da silinmiş olduğundan konuşulan her şey yok oluyordu.
  /// Artık kayıt korunur, levha gözden geçirme evresine geçer ve not SES EKİ
  /// ile oluşturulur; kullanıcı isterse metni kendisi yazar.
  void _toAudioFallback(String? path, String message) {
    if (!mounted) return;
    if (path == null) {
      _fail(message);
      return;
    }
    setState(() {
      _readyAudioPath = path;
      _text = '';
      _editController.text = '';
      _errorMessage = message;
      _phase = _Phase.ready;
    });
  }

  /// "Baştan dinle": biriken metni atar ve yeniden dinlemeye geçer.
  Future<void> _restart() async {
    await _teardown();
    if (!mounted) return;
    setState(() {
      _text = '';
      _rawText = '';
      _prefix = '';
      _title = null;
      _titleController.clear();
      _commandCount = 0;
      _feedback = '';
      _editController.clear();
      _elapsed = Duration.zero;
      _phase = _Phase.idle;
      _pressed = false;
      _pressedAt = null;
      _latched = false;
      _errorMessage = '';
    });
    if (ref.read(voiceButtonModeProvider) == VoiceButtonMode.tap) {
      await _startListening();
    }
  }

  /// "Devam et": gözden geçirilen (ve belki elle düzeltilen) metin KORUNUR,
  /// dinleme yeniden açılır, yeni konuşma onun SONUNA eklenir. Eskiden tek
  /// seçenek "Baştan dinle"ydi — bir cümle eklemek isteyen her şeyi baştan
  /// söylemek zorundaydı. Süre sayacı da kaldığı yerden sürer.
  Future<void> _continue() async {
    final prefix = _editController.text.trim();
    final title = _titleController.text.trim();
    await _teardown();
    if (!mounted) return;
    setState(() {
      _prefix = prefix;
      _title = title.isEmpty ? null : title;
      _text = prefix;
      _rawText = '';
      _commandCount = 0;
      _feedback = '';
      _phase = _Phase.idle;
      _pressed = false;
      _pressedAt = null;
      _latched = false;
      _errorMessage = '';
    });
    if (ref.read(voiceButtonModeProvider) == VoiceButtonMode.tap) {
      await _startListening();
    }
  }

  void _submit(VoiceCaptureAction action) {
    final text = _editController.text.trim();
    // Metin boş olsa da ses kaydı varsa not oluşur: dökümü yapılamamış bir
    // konuşma da nottur (ek olarak girer).
    if (text.isEmpty && _readyAudioPath == null) return;
    final audio = _readyAudioPath;
    // Yol çağırana devredildi: levha artık o dosyayı SİLMEZ.
    _readyAudioPath = null;
    Navigator.pop(context, (
      text: text,
      action: action,
      audioPath: audio,
      audioDuration: _elapsed,
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
    ));
  }

  /// Levhayı kapatma isteğinin ORTAK kapısı: sol üstteki çarpı, geri tuşu,
  /// aşağı sürükleme ve karartıya dokunuş hepsi buraya düşer.
  ///
  /// KÖK NEDEN (kullanıcı: "sesle yazmanın edit sayfası sadece sol üstteki
  /// çarpıdan kapanıyor, kullanışsız bu şekilde; ama yanlışlıkla kapatmaya da
  /// çözüm bulmalıyız, kişi baştan söylemesin her şeyi"): levha
  /// `isDismissible: false, enableDrag: false` ile açılıyordu ÇÜNKÜ tek
  /// koruma buydu — 10 dakikalık bir dökümü yanlış bir dokunuşla kaybetmek
  /// kabul edilemezdi. Ama bedeli, kapatmanın tek ve uzak bir düğmeye
  /// bağlanmasıydı. Doğru çözüm kapıları KAPATMAK değil, kapıdan çıkarken
  /// SORMAK: artık dört yoldan da kapanıyor ve içerik varsa ne olacağını
  /// kullanıcı seçiyor — konuşulanlar hiçbir dalda sessizce çöpe gitmiyor.
  Future<void> _askBeforeClosing() async {
    final l10n = context.l10n;
    final choice = await showAppSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                l10n.voiceCloseTitle,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: Text(
                widget.target == VoiceCaptureTarget.editor
                    ? l10n.voiceCaptureAddToNote
                    : l10n.voiceCapturePlainNote,
              ),
              onTap: () => Navigator.pop(sheetContext, 'save'),
            ),
            ListTile(
              leading: const Icon(Icons.mic_none),
              title: Text(l10n.voiceCloseKeepTalking),
              onTap: () => Navigator.pop(sheetContext, 'stay'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                l10n.delete,
                style: TextStyle(
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
              ),
              onTap: () => Navigator.pop(sheetContext, 'discard'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'save':
        _submit(VoiceCaptureAction.insert);
      case 'discard':
        await _teardown();
        if (mounted) Navigator.pop(context);
      // 'stay' ve levhayı kapatmak (null): hiçbir şey olmaz, metin durur.
    }
  }

  Future<void> _cancel() async {
    // Çarpı da öteki kapanış yollarıyla AYNI kapıdan geçer: içerik varken
    // sessizce silmez, yoksa hiç sormadan kapanır.
    if (_hasContent && _phase == _Phase.ready) {
      await _askBeforeClosing();
      return;
    }
    await _teardown();
    if (mounted) Navigator.pop(context);
  }

  /// Sessizlik izlemesini ve kayıt yolunun seviye aboneliğini bırakır.
  void _stopSilenceWatch() {
    // Kayıt yolunda oturum mikrofona dokunmaz; yalnız zamanlayıcısı durur
    // (konuşma yolunda bitiş [_finishListening]'de son sonucu bekler).
    if (!_useSpeech) {
      _session?.cancel();
      _session = null;
    }
    _ampSub?.cancel();
    _ampSub = null;
    _silence = 0;
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    _stopSilenceWatch();
    await _session?.cancel();
    _session = null;
    try {
      final path = await _recorder?.stop();
      if (path != null) File(path).delete().ignore();
    } catch (_) {}
    _recorder?.dispose();
    _recorder = null;
    // Kullanılmayan (gönderilmemiş) kayıt geçici klasörde kalmasın.
    final leftover = _readyAudioPath;
    _readyAudioPath = null;
    if (leftover != null) File(leftover).delete().ignore();
  }

  void _fail(String message) {
    _ticker?.cancel();
    _stopSilenceWatch();
    _session?.cancel();
    _session = null;
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _errorMessage = message;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    _feedbackTimer?.cancel();
    _session?.cancel();
    _titleController.dispose();
    _recorder?.dispose();
    _editController.dispose();
    // Gönderilmeden kapatıldıysa kayıt geçici klasörde kalmasın (gönderildiyse
    // _submit yolu null'lar).
    final leftover = _readyAudioPath;
    if (leftover != null) File(leftover).delete().ignore();
    super.dispose();
  }

  String _format(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  /// İçerik varken geri tuşu KAYBETTİRMEZ: dinlemedeyken gözden geçirmeye
  /// taşır, gözden geçirmede metni/kaydı olduğu gibi kaydederek çıkar.
  /// (Editördeki ses kaydı ve çizim ekranıyla aynı ilke.)
  bool get _hasContent =>
      _phase == _Phase.listening && _text.trim().isNotEmpty ||
      _phase == _Phase.ready &&
          (_editController.text.trim().isNotEmpty || _readyAudioPath != null);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasContent,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Dinlerken kapatma isteği önce DİNLEMEYİ bitirir: konuşulan metin
        // gözden geçirmeye taşınır, hiçbir şey kaybolmaz.
        if (_phase == _Phase.listening) {
          _finish();
          return;
        }
        if (_phase == _Phase.ready) _askBeforeClosing();
      },
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final holdMode = ref.watch(voiceButtonModeProvider) == VoiceButtonMode.hold;
    final listening = _phase == _Phase.listening;
    // Sistem gezinme çubuğu (geri/ana sayfa) levhanın ALTINI örtüyordu:
    // showModalBottomSheet'in useSafeArea'sı üst/yanları korur, ALTI bilerek
    // korumaz (klavye için). Alt boşluğu levha kendi ekler; klavye açıkken
    // onun yüksekliği zaten daha büyüktür.
    final bottomGap = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.viewPaddingOf(context).bottom,
    );

    if (!_ready || _phase == _Phase.processing) {
      return Padding(
        padding: EdgeInsets.fromLTRB(32, 32, 32, 32 + bottomGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (_phase == _Phase.processing) ...[
              const SizedBox(height: 16),
              Text(l10n.dictationProcessing),
            ],
          ],
        ),
      );
    }

    if (_phase == _Phase.error) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: scheme.error),
            const SizedBox(height: 12),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 8, 14, 14 + bottomGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutamak
          Container(
            width: 34,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outline.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _header(l10n, scheme, listening),
          const SizedBox(height: 4),
          Flexible(child: _transcript(scheme, listening)),
          // Sessizlik geri sayımı: dolunca dinleme kendiliğinden biter.
          SizedBox(
            height: 3,
            child: AnimatedOpacity(
              opacity: listening && _silence > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: LinearProgressIndicator(
                key: const ValueKey('voice-silence-bar'),
                value: _silence,
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 7),
          _Waveform(active: listening, scheme: scheme),

          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: 12),
          _actions(l10n, scheme, holdMode, listening),
          // Çipler yapay zekâ ister; döküm zaten yapılamadıysa (ses eki yolu)
          // hepsi aynı hatayla düşerdi — gösterilmezler.
          if (_phase == _Phase.ready && _readyAudioPath == null) ...[
            const SizedBox(height: 10),
            _chips(l10n, scheme),
          ],
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n, ColorScheme scheme, bool listening) {
    final ready = _phase == _Phase.ready;
    final language = languageLabel(
      Localizations.localeOf(context).languageCode,
    );
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: IconButton(
              tooltip: l10n.cancel,
              icon: const Icon(Icons.close),
              onPressed: _cancel,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  // Başlık DURUMU söyler: basılı-tut modunda levha açılır
                  // açılmaz "Dinliyorum..." yazması yanlıştı — mikrofon o an
                  // kapalıydı, kullanıcı konuşup boş dönüyordu.
                  ready
                      ? l10n.voiceCaptureReady
                      : listening
                      ? l10n.voiceListening
                      : l10n.voiceModeHold,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ready
                      ? l10n.voiceCaptureEditHint
                      : _feedback.isNotEmpty
                      ? '✓ $_feedback'
                      : listening && _silence > 0
                      ? l10n.voiceAutoStopSoon
                      : l10n.voiceCapturePunctuation(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!ready) _commandsHelp(l10n, scheme),
          Text(
            _format(_elapsed),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              // Süre sayacı: tabular rakam olmazsa saniye her tikte genişlik
              // değiştirip başlığı oynatır.
              fontFeatures: const [FontFeature.tabularFigures()],
              color: listening ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Dinlerken salt okunur zengin metin (son iki kelime soluk = henüz
  /// kesinleşmemiş tanıma), bittiğinde düzenlenebilir alan.
  Widget _transcript(ColorScheme scheme, bool listening) {
    const style = TextStyle(fontSize: 17, height: 1.55);
    if (_phase == _Phase.ready) {
      final audio = _readyAudioPath != null;
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 74, maxHeight: 210),
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
                      Icon(Icons.mic_none, size: 16, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${context.l10n.recordAudio} · ${_format(_elapsed)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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
                  style: style.copyWith(fontWeight: FontWeight.w700),
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

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 74, maxHeight: 210),
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
                      fontWeight: FontWeight.w700,
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
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
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
  Widget _commandsHelp(AppLocalizations l10n, ColorScheme scheme) => IconButton(
    key: const ValueKey('voice-commands-help'),
    tooltip: l10n.voiceSmartCommands,
    visualDensity: VisualDensity.compact,
    iconSize: 18,
    icon: Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    return SizedBox(
      height: 54,
      child: icon == null
          ? FilledButton(onPressed: onPressed, style: style, child: text)
          : FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 18),
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
          _readyAudioPath == null;
      return Row(
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: OutlinedButton(
              onPressed: _restart,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: scheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Tooltip(
                message: l10n.voiceCaptureRestart,
                child: const Icon(Icons.refresh),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Ses eki yolunda (döküm yapılamadı) sürdürülecek metin yok.
          if (_readyAudioPath == null) ...[
            SizedBox(
              width: 54,
              height: 54,
              child: OutlinedButton(
                key: const ValueKey('voice-continue'),
                onPressed: _continue,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: scheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Tooltip(
                  message: l10n.voiceCaptureContinue,
                  child: const Icon(Icons.mic_none),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
            const SizedBox(width: 8),
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

    // Düğme "basılı tut" ile mi çalışıyor: kilitlendiyse artık dokunmalı
    // düğmedir (bas → bitir).
    final holdActive = holdMode && !_latched;

    // Basılı-tut modu: düğme idle ve listening evrelerinde AYNI ağaçta
    // kalmalı — aksi hâlde parmak basılıyken düğme ağaçtan kalkar ve bırakma
    // olayı hiç gelmez. (Eski dikte sayfasında bulunmuş bir tuzak; yerleşim
    // değişse de kural aynı.)
    final button = SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton.icon(
        // Basılı-tut modunda dokunma geri bildirimi Listener'dan gelir; düğme
        // yine de ETKİN kalır (eskiden disabled'dı ve soluk görünüyordu).
        onPressed: holdActive
            ? null
            : listening
            ? _finish
            : _startListening,
        style: FilledButton.styleFrom(
          backgroundColor: listening ? scheme.error : scheme.primaryContainer,
          foregroundColor: listening
              ? scheme.onError
              : scheme.onPrimaryContainer,
          // Basılı-tutta düğme "devre dışı" görünmemeli: parmak orada duracak.
          disabledBackgroundColor: listening
              ? scheme.error
              : scheme.primaryContainer,
          disabledForegroundColor: listening
              ? scheme.onError
              : scheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(listening ? Icons.stop_circle : Icons.mic),
        label: Text(
          listening
              ? (holdActive && _pressed
                    ? l10n.voiceListening
                    : l10n.voiceFinish)
              : (holdActive ? l10n.voiceModeHold : l10n.voiceModeTap),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    // Düğmenin altındaki tek satırlık kullanım ipucu: hangi modda ne
    // yapılacağı düğmenin kendisinde değil burada yazar (etiket kısa kalsın).
    // Dinlerken dokunmalı modda ipucu YOK: düğme zaten "Bitir" diyor.
    final hintText = holdActive
        ? l10n.dictationHoldHint
        : listening
        ? ''
        : l10n.voiceTapHint;
    final hint = hintText.isEmpty
        ? const SizedBox(height: 6)
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              hintText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          );

    if (!holdActive) {
      return Column(mainAxisSize: MainAxisSize.min, children: [button, hint]);
    }

    // Listener (GestureDetector.onLongPress DEĞİL): uzun basış tanıyıcısı
    // ~500 ms bekler, o süre boyunca konuşulanlar kaybolurdu. Parmak değer
    // değmez dinleme başlar.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerDown: (_) => _pressStart(),
          onPointerUp: (_) => _pressEnd(),
          onPointerCancel: (_) => _pressEnd(),
          child: button,
        ),
        hint,
      ],
    );
  }

  /// Parmak düğmeye değdi: beklemeden dinlemeye başla.
  void _pressStart() {
    _pressedAt = DateTime.now();
    setState(() => _pressed = true);
    HapticFeedback.selectionClick();
    if (_phase == _Phase.idle) _startListening();
  }

  /// Parmak kalktı: uzun basışsa döküme geç, kısa dokunuşsa dinlemeyi KİLİTLE
  /// (bkz. [_kHoldLatchThreshold]).
  void _pressEnd() {
    if (!_pressed) return;
    final start = _pressedAt;
    final quick =
        start == null ||
        DateTime.now().difference(start) < _kHoldLatchThreshold;
    setState(() {
      _pressed = false;
      if (quick) _latched = true;
    });
    if (!quick) _finish();
  }

  Widget _chips(AppLocalizations l10n, ColorScheme scheme) {
    final editor = widget.target == VoiceCaptureTarget.editor;
    final entries = <(String, VoiceCaptureAction)>[
      (
        editor ? l10n.voiceChipSummarizeAdd : l10n.voiceChipSummarizeSave,
        VoiceCaptureAction.summarize,
      ),
      (
        editor ? l10n.voiceChipToItems : l10n.voiceChipAsList,
        editor ? VoiceCaptureAction.toItems : VoiceCaptureAction.asList,
      ),
      (l10n.voiceChipFix, VoiceCaptureAction.fix),
      // "Asistan oluştursun" ARTIK ÇİP DEĞİL: ana ekranda bitiş satırındaki
      // "AI not" düğmesi oldu (bkz. _actions). Çipler arasında dururken hem
      // öteki üçüyle aynı ağırlıkta görünüyor — oysa notu baştan sona o
      // kuruyor — hem de asıl düğmeyle arasındaki seçim belirsiz kalıyordu.
    ];
    // ÇİPLER SATIRA SIĞAR: eskiden yatay kaydırılan bir liste vardı ve son çip
    // ekranın dışında kalıyordu — kaydırılabildiği belli olmadığı için o
    // seçenek yok sayılıyordu. Wrap taşanı ALT SATIRA indirir; hepsi tek
    // bakışta görünür.
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (label, action) in entries)
          ActionChip(
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: scheme.secondaryContainer,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onPressed: () => _submit(action),
          ),
      ],
    );
  }
}

/// Dalga çubukları.
///
/// TEK ticker, TEK CustomPaint: her çubuğun kendi `AnimationController`ı
/// olsaydı 24 denetleyici dönerdi. Eskiden tek ticker vardı ama her vsync'te
/// `setState` 24 Expanded/FractionallySizedBox/DecoratedBox'lık alt ağacı
/// yeniden KURUYORDU — mikrofon zaten açıkken (en pahalı durum) kare başına
/// boşuna widget işi. Artık ticker bir ValueNotifier'ı besliyor ve yalnız
/// painter yeniden ÇİZİYOR; widget ağacına hiç dokunulmuyor. Her çubuğun
/// ölçeği kendi periyodundan (560 + i·41 ms) hesaplanır — tasarımdaki kayan
/// dalga etkisi aynen çıkar.
class _Waveform extends StatefulWidget {
  const _Waveform({required this.active, required this.scheme});

  final bool active;
  final ColorScheme scheme;

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _elapsed = ValueNotifier<Duration>(Duration.zero);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!widget.active) return;
      _elapsed.value = elapsed;
    });
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(_Waveform old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.active && _ticker.isActive) {
      _ticker.stop();
      // Durunca çubuklar bekleme yüksekliğine insin (painter active'e bakar;
      // notifier'ı dürtmek son bir çizim tetikler).
      _elapsed.value = Duration.zero;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          elapsed: _elapsed,
          active: widget.active,
          color: widget.active
              ? widget.scheme.primary
              : widget.scheme.outlineVariant,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.elapsed,
    required this.active,
    required this.color,
  }) : super(repaint: elapsed);

  static const _barCount = 24;
  static const _gap = 4.0;

  final ValueListenable<Duration> elapsed;
  final bool active;
  final Color color;

  /// Dinleme bitince çubuklar %16'ya iner ve durur.
  double _factor(int index) {
    if (!active) return 0.16;
    final period = 560 + index * 41;
    final phase = (elapsed.value.inMilliseconds % period) / period;
    // .32 → 1 → .32 arası yumuşak gidiş geliş.
    return 0.32 + 0.68 * (0.5 - 0.5 * math.cos(2 * math.pi * phase));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final barWidth = (size.width - _gap * (_barCount - 1)) / _barCount;
    if (barWidth <= 0) return;
    for (var i = 0; i < _barCount; i++) {
      final height = size.height * _factor(i);
      final left = i * (barWidth + _gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, (size.height - height) / 2, barWidth, height),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.active != active || old.color != color || old.elapsed != elapsed;
}
