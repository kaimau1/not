import 'package:flutter/widgets.dart';

/// Açılır bölümün içeriğini AŞAĞI DOĞRU kayarak açan/kapatan sarmalayıcı —
/// ayarların akordeon alanları ve "Gelişmiş" gibi iç bölümler hep bununla
/// açılır.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-20: "ayarlarda bazı menüler aşağı
/// doğru animasyonla açılırken bazılarında yok gibi"): alanlar
/// `AnimatedSize`, iç bölümler `ExpansionTile` ile açılıyordu. İkisinde de
/// animasyon içeriğin KURULDUĞU karede başlıyor. Hafif alanda (Görünüm) bu
/// fark edilmez; ağır alanda (Yapay zekâ, Hesap, Ses — sağlayıcı okumaları,
/// uzun satır listeleri) o ilk kare 250-400 ms sürüyor ve bir sonraki
/// karede animasyonun süresi ZATEN dolmuş oluyordu: içerik tek karede "pat"
/// diye beliriyordu. Hangi alanın ağır olduğu dışarıdan görünmediği için
/// davranış rastgele tutarsız görünüyordu.
///
/// Burada içerik ilk karede TAM kurulup ölçülür ama yüksekliği sıfırdan
/// başlar; denetleyici BİR SONRAKİ karede ileri sarılır. İlk kare ne kadar
/// uzun sürerse sürsün açılışın tamamı oynar. Kapanınca içerik animasyon
/// bitene dek ağaçta kalır, sonra düşer (kapalı bölüm boşuna kurulmaz).
class ExpandReveal extends StatefulWidget {
  const ExpandReveal({
    super.key,
    required this.open,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
  });

  final bool open;
  final Widget child;
  final Duration duration;

  @override
  State<ExpandReveal> createState() => _ExpandRevealState();
}

class _ExpandRevealState extends State<ExpandReveal>
    with SingleTickerProviderStateMixin {
  // initState'te kurulur (tembel DEĞİL): kapalı başlayan bölümde
  // denetleyiciye ilk erişim açılış anında olur ve tembel kurulum o anki
  // `open = true` değerini alıp animasyonsuz açılırdı.
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.open ? 1 : 0,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  /// İçerik ağaçta mı (açıkken ve kapanış animasyonu sürerken).
  late bool _built = widget.open;

  @override
  void didUpdateWidget(ExpandReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    if (widget.open) {
      _built = true;
      // Açılış İÇERİK KURULDUKTAN SONRA başlar (bkz. sınıf notu).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.open) _controller.forward();
      });
    } else {
      _controller.reverse().whenCompleteOrCancel(() {
        if (mounted && !widget.open) setState(() => _built = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_built) return const SizedBox(width: double.infinity);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.open
          ? widget.child
          : const SizedBox(width: double.infinity);
    }
    // SAYDAMLIK YOK, BOYAMA SINIRI VAR (kullanıcı bulgusu 2026-10-20:
    // "ayarlar ekranı kasıyor menüler arası gezerken"). Eskiden içerik bir
    // `FadeTransition` altındaydı: açılış/kapanışın HER karesinde bütün alan
    // (onlarca satır, anahtar, kaydırıcı) ekran dışı bir katmana yeniden
    // çiziliyordu — Impeller'da saydamlık katmanı ayrı bir çizim geçişi
    // demek. Şimdi yalnız kırpma büyür; içerik `RepaintBoundary` ile bir kez
    // çizilip her karede aynen kullanılır.
    return SizeTransition(
      sizeFactor: _curve,
      alignment: AlignmentDirectional.topStart,
      child: RepaintBoundary(child: widget.child),
    );
  }
}
