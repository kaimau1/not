import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/attachment.dart';

/// Önizleme tavanı (bayt) — `storage.rules` `users/{uid}/thumbs/` ile aynı.
const kThumbMaxBytes = 40 * 1024;

/// Önizlemenin Storage yolu.
String thumbStoragePath(String uid, String attachmentId) =>
    'users/$uid/thumbs/$attachmentId.jpg';

/// Buluta önizlemesi giden türler: görsel ve PDF'in ilk sayfası (F65.5 —
/// dosyası bu cihazda olmayan kart, web dahil, indirmeden çizer).
bool wantsCloudThumb(AttachmentKind kind) =>
    kind == AttachmentKind.image || kind == AttachmentKind.pdf;

/// **KART ÖNİZLEMESİ** (F28.2-B, 2026-11-04): görselden ≤ [kThumbMaxBytes]
/// JPEG üretir; Storage'a yalnız bu gider, asıl dosya Drive'da.
///
/// Önce uzun kenar [maxSide]'a indirilir, sonra kalite basamakla düşürülür;
/// hâlâ büyükse kenar küçültülür. Çözülemeyen/görsel olmayan veri → null
/// (kart tür simgesini gösterir). Ağır iş: çağıran `compute` ile ayrı
/// izolede çalıştırır.
Uint8List? makeThumbnail(Uint8List source, {int maxSide = 320}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(source);
  } catch (_) {
    return null; // tanınmayan biçim: decodeImage fırlatabiliyor
  }
  if (decoded == null) return null;
  var side = maxSide;
  while (side >= 64) {
    final longest = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    final scaled = longest <= side
        ? decoded
        : (decoded.width >= decoded.height
              ? img.copyResize(decoded, width: side)
              : img.copyResize(decoded, height: side));
    for (final q in const [80, 65, 50, 35]) {
      final out = img.encodeJpg(scaled, quality: q);
      if (out.lengthInBytes <= kThumbMaxBytes) return out;
    }
    side = (side * 0.7).floor();
  }
  return null;
}
