import 'dart:async';

import 'package:flutter/widgets.dart';

/// **GERİ ÖNCE PANELİ KAPATIR** (kullanıcı isteği 2026-11-06: "ek kısmı
/// açıkken geri tuşu notu kapatıyor; önce o paneli kapatmalı — bu tüm bu tür
/// olaylar için geçerli, tek tek düzeltmek istemiyorum").
///
/// Ekranın İÇİNDE açılan, rota olmayan her panel (ek şeridi, kalem tepsisi,
/// biçim tepsisi, sayfa notu alanı, takvimin ay paneli…) [open] iken kendini
/// buraya kaydeder; geri tuşu SON AÇILANI kapatır ([onClose]), ekran ancak
/// hiçbir panel açık değilken kapanır.
///
/// Neden tek yer: Flutter aynı rotadaki BÜTÜN `PopScope` geri çağrılarını
/// çalıştırır — her panel kendi `PopScope`unu koyunca tek geri iki paneli
/// (ya da paneli ve ekranın kendi kipini: arama, seçim) birden kapatıyordu.
/// Burada kayıt LIFO; bir geri olayında yalnız EN ÜSTTEKİ kapanır. Ekranın
/// kendi `PopScope`u ([NoteEditorScreen], ana ekran) işine başlamadan önce
/// [BackCloses.handling] sorar: true ise bu geri bir panelindir, dokunmaz.
class BackCloses extends StatefulWidget {
  const BackCloses({
    super.key,
    required this.open,
    required this.onClose,
    required this.child,
  });

  final bool open;
  final VoidCallback onClose;
  final Widget child;

  /// Bu geri olayı bir panele mi ait (o rotada açık panel var ya da bu olayda
  /// biri zaten kapandı)? Ekranın kendi geri işi önce bunu sorar.
  static bool handling(BuildContext context) {
    if (_consumed) return true;
    final route = ModalRoute.of(context);
    return _stack.any((e) => e.route == route);
  }

  /// Testler için: açık panel sayısı.
  @visibleForTesting
  static int get openCount => _stack.length;

  static final List<_BackClosesState> _stack = [];

  /// Bir geri olayı sırasında true (aynı olayda ikinci panel kapanmasın).
  static bool _consumed = false;

  @override
  State<BackCloses> createState() => _BackClosesState();
}

class _BackClosesState extends State<BackCloses> {
  ModalRoute<Object?>? route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    route = ModalRoute.of(context);
  }

  @override
  void initState() {
    super.initState();
    if (widget.open) BackCloses._stack.add(this);
  }

  @override
  void didUpdateWidget(BackCloses old) {
    super.didUpdateWidget(old);
    if (widget.open && !old.open) {
      BackCloses._stack
        ..remove(this)
        ..add(this);
    } else if (!widget.open && old.open) {
      BackCloses._stack.remove(this);
    }
  }

  @override
  void dispose() {
    BackCloses._stack.remove(this);
    super.dispose();
  }

  void _onPop(bool didPop, Object? _) {
    if (didPop || BackCloses._consumed) return;
    // Bu rotadaki en son açılan panel (başka rotanınki değil).
    final top = BackCloses._stack.lastWhere(
      (e) => e.route == route,
      orElse: () => this,
    );
    BackCloses._consumed = true;
    scheduleMicrotask(() => BackCloses._consumed = false);
    BackCloses._stack.remove(top);
    top.widget.onClose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.open,
    onPopInvokedWithResult: _onPop,
    child: widget.child,
  );
}
