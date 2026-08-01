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
final attachmentClipboardProvider =
    NotifierProvider<AttachmentClipboard, Attachment?>(AttachmentClipboard.new);

class AttachmentClipboard extends Notifier<Attachment?> {
  @override
  Attachment? build() => null;

  void copy(Attachment attachment) => state = attachment;

  void clear() => state = null;
}
