import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/attachment.dart';

/// Uygulama içi EK panosu: "Kopyala" ile alınan ek burada bekler, başka bir
/// notun (+) menüsündeki "Kopyalanan eki yapıştır" ile oraya kopyalanır.
///
/// Neden ayrı bir pano: sistem panosu yalnız görsel BAYTLARINI taşıyabiliyor
/// (PDF/sunum/ses için karşılığı yok, masaüstünde görsel yazımı da yok) ve
/// taşıdığında bile ekin çizimi, boyutu, "şeritte mi sayfada mı" bilgisi
/// kayboluyor. Uygulama içinde ekin KENDİSİ taşınır; sistem panosuna yazma
/// buna ek olarak, mümkün olan platformlarda yapılır (bkz. not editörü).
///
/// Pano yalnız bellekte durur: uygulama kapanınca boşalır. Kaynak dosya
/// silinirse yapıştırma "dosya bulunamadı" ile biter — kalıcı bir kopya
/// tutmak, kullanıcı hiç yapıştırmadığında yer israfı olurdu.
///
/// **ÇOKLU** (kullanıcı isteği 2026-08-09: "görsellerde çoklu seçim ve
/// kopyalama"): pano tek yuvalıydı, sayfadan iki görsel seçip kopyalamak
/// mümkün değildi. Artık sıralı bir liste tutar; tek ek kopyalamak da aynı
/// yoldan geçer (tek elemanlı liste).
final attachmentClipboardProvider =
    NotifierProvider<AttachmentClipboard, List<Attachment>>(
      AttachmentClipboard.new,
    );

class AttachmentClipboard extends Notifier<List<Attachment>> {
  @override
  List<Attachment> build() => const [];

  void copy(Attachment attachment) => state = [attachment];

  void copyAll(List<Attachment> attachments) =>
      state = List.unmodifiable(attachments);

  void clear() => state = const [];
}
