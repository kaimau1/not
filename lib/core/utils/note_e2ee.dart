import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Faz 4 — **Uçtan Uca Şifreli (E2EE) Kilitli Notlar** (`AES-256-GCM`).
///
/// Saf Dart, sıfır harici bağımlılık (Android + Web bire bir aynı çalışır):
///  * FIPS-197 AES-256 blok şifreleyici
///  * NIST SP 800-38D GCM (96-bit rastgele nonce, 128-bit doğrulama etiketi)
///  * PBKDF2-HMAC-SHA256 anahtar türetimi (`deriveKey`)
///
/// Şifreli zarf biçimi:
/// `e2ee:v1:<base64url(nonce[12] || ciphertext || tag[16])>`
///
/// Eski düz metin kilitli notlarla geriye uyumludur: [isEncrypted] `false`
/// dönen metinler şifresiz kabul edilip olduğu gibi okunur.
abstract final class NoteE2ee {
  static const String prefix = 'e2ee:v1:';
  static const int keyLength = 32;
  static const int nonceLength = 12;
  static const int tagLength = 16;

  /// Verilen metin E2EE zarfı mı?
  static bool isEncrypted(String? text) =>
      text != null && text.startsWith(prefix);

  /// Kullanıcı sırrından (şifre/desen/kurtarma parolası) + tuzdan 256-bit
  /// anahtar türetir (PBKDF2-HMAC-SHA256).
  static Uint8List deriveKey(
    String secret,
    String salt, {
    int iterations = 20000,
  }) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    var u = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  /// Rastgele 256-bit cihaz anahtarı üretir (SecureStorage için).
  static Uint8List generateKey([Random? random]) {
    final rnd = random ?? Random.secure();
    return Uint8List.fromList([
      for (var i = 0; i < keyLength; i++) rnd.nextInt(256),
    ]);
  }

  /// Düz metni AES-256-GCM ile şifreler ve `e2ee:v1:...` zarfına sarar.
  static String encryptText(
    String plaintext,
    Uint8List key, {
    String aad = '',
    Uint8List? nonce,
    Random? random,
  }) {
    final iv = nonce ?? _randomNonce(random);
    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));
    final aadBytes = Uint8List.fromList(utf8.encode(aad));
    final sealed = _Aes256Gcm(key).encrypt(plainBytes, iv, aad: aadBytes);
    final packed = Uint8List(iv.length + sealed.length)
      ..setRange(0, iv.length, iv)
      ..setRange(iv.length, iv.length + sealed.length, sealed);
    return '$prefix${base64Url.encode(packed)}';
  }

  /// `e2ee:v1:...` zarfını çözer. Kimlik doğrulama etiketi uyuşmazsa (yanlış
  /// anahtar veya bozulmuş veri) `null` döner. Şifreli değilse metni olduğu
  /// gibi döner (eski düz metin kilitli notlarla geriye uyumluluk).
  static String? decryptText(String input, Uint8List key, {String aad = ''}) {
    if (!isEncrypted(input)) return input;
    try {
      final packed = base64Url.decode(input.substring(prefix.length));
      if (packed.length < nonceLength + tagLength) return null;
      final iv = packed.sublist(0, nonceLength);
      final body = packed.sublist(nonceLength);
      final aadBytes = Uint8List.fromList(utf8.encode(aad));
      final plain = _Aes256Gcm(key).decrypt(body, iv, aad: aadBytes);
      if (plain == null) return null;
      return utf8.decode(plain);
    } catch (_) {
      return null;
    }
  }

  /// Notun gövdesini, madde metinlerini ve isteğe bağlı ek metin sayfaları /
  /// sayfa notlarını tek JSON yükü hâlinde şifreler.
  static String encryptNotePayload({
    required String body,
    required List<Map<String, dynamic>> items,
    required Uint8List key,
    String noteId = '',
    List<Map<String, dynamic>>? textPages,
    Map<String, String>? pageNotes,
  }) {
    final json = jsonEncode({
      'b': body,
      'i': items,
      if (textPages != null && textPages.isNotEmpty) 'tp': textPages,
      if (pageNotes != null && pageNotes.isNotEmpty) 'pn': pageNotes,
    });
    return encryptText(json, key, aad: noteId);
  }

  /// Şifreli not yükünü geri çözer; başarısızsa `null`.
  static ({
    String body,
    List<Map<String, dynamic>> items,
    List<Map<String, dynamic>> textPages,
    Map<String, String> pageNotes,
  })?
  decryptNotePayload({
    required String envelope,
    required Uint8List key,
    String noteId = '',
  }) {
    final raw = decryptText(envelope, key, aad: noteId);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final b = decoded['b'] as String? ?? '';
      final rawItems = decoded['i'] as List? ?? const [];
      final rawTextPages = decoded['tp'] as List? ?? const [];
      final rawPageNotes = decoded['pn'] as Map?;
      return (
        body: b,
        items: [
          for (final e in rawItems)
            if (e is Map) Map<String, dynamic>.from(e),
        ],
        textPages: [
          for (final e in rawTextPages)
            if (e is Map) Map<String, dynamic>.from(e),
        ],
        pageNotes: rawPageNotes == null
            ? const <String, String>{}
            : {
                for (final e in rawPageNotes.entries)
                  e.key.toString(): e.value?.toString() ?? '',
              },
      );
    } catch (_) {
      return null;
    }
  }

  static Uint8List _randomNonce([Random? random]) {
    final rnd = random ?? Random.secure();
    return Uint8List.fromList([
      for (var i = 0; i < nonceLength; i++) rnd.nextInt(256),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Saf Dart FIPS-197 AES-256 + NIST SP 800-38D GCM
// ---------------------------------------------------------------------------

class _Aes256Gcm {
  _Aes256Gcm(Uint8List key) {
    if (key.length != 32) {
      throw ArgumentError('AES-256 requires a 32-byte key');
    }
    _roundKeys = _expandKey(key);
    _h = _encryptBlock(Uint8List(16));
  }

  late final Uint8List _roundKeys; // 15 * 16 = 240 bytes
  late final Uint8List _h;

  Uint8List encrypt(Uint8List plaintext, Uint8List nonce, {Uint8List? aad}) {
    if (nonce.length != 12) {
      throw ArgumentError('GCM requires a 12-byte nonce');
    }
    final j0 = Uint8List(16)
      ..setRange(0, 12, nonce)
      ..[15] = 1;
    final ct = _gctr(_inc32(j0), plaintext);
    final s = _ghash(aad ?? Uint8List(0), ct);
    final tagMask = _encryptBlock(j0);
    final out = Uint8List(ct.length + 16)..setRange(0, ct.length, ct);
    for (var i = 0; i < 16; i++) {
      out[ct.length + i] = s[i] ^ tagMask[i];
    }
    return out;
  }

  Uint8List? decrypt(
    Uint8List ciphertextAndTag,
    Uint8List nonce, {
    Uint8List? aad,
  }) {
    if (nonce.length != 12 || ciphertextAndTag.length < 16) return null;
    final ctLen = ciphertextAndTag.length - 16;
    final ct = ciphertextAndTag.sublist(0, ctLen);
    final tag = ciphertextAndTag.sublist(ctLen);
    final j0 = Uint8List(16)
      ..setRange(0, 12, nonce)
      ..[15] = 1;
    final s = _ghash(aad ?? Uint8List(0), ct);
    final tagMask = _encryptBlock(j0);
    var diff = 0;
    for (var i = 0; i < 16; i++) {
      diff |= tag[i] ^ (s[i] ^ tagMask[i]);
    }
    if (diff != 0) return null;
    return _gctr(_inc32(j0), ct);
  }

  Uint8List _gctr(Uint8List icb, Uint8List input) {
    final out = Uint8List(input.length);
    var cb = Uint8List.fromList(icb);
    for (var off = 0; off < input.length; off += 16) {
      final keystream = _encryptBlock(cb);
      final len = (input.length - off) < 16 ? (input.length - off) : 16;
      for (var i = 0; i < len; i++) {
        out[off + i] = input[off + i] ^ keystream[i];
      }
      cb = _inc32(cb);
    }
    return out;
  }

  Uint8List _inc32(Uint8List block) {
    final next = Uint8List.fromList(block);
    var carry = 1;
    for (var i = 15; i >= 12 && carry > 0; i--) {
      final sum = next[i] + carry;
      next[i] = sum & 0xff;
      carry = sum >> 8;
    }
    return next;
  }

  Uint8List _ghash(Uint8List aad, Uint8List ct) {
    final y = Uint8List(16);
    void feed(Uint8List data) {
      for (var off = 0; off < data.length; off += 16) {
        final len = (data.length - off) < 16 ? (data.length - off) : 16;
        for (var i = 0; i < len; i++) {
          y[i] ^= data[off + i];
        }
        _gfMul(y, _h);
      }
    }

    feed(aad);
    feed(ct);
    final lenBlock = Uint8List(16);
    _writeUint64BE(lenBlock, 0, aad.length * 8);
    _writeUint64BE(lenBlock, 8, ct.length * 8);
    for (var i = 0; i < 16; i++) {
      y[i] ^= lenBlock[i];
    }
    _gfMul(y, _h);
    return y;
  }

  static void _writeUint64BE(Uint8List dst, int offset, int value) {
    var v = value;
    for (var i = 7; i >= 0; i--) {
      dst[offset + i] = v & 0xff;
      v = v ~/ 256;
    }
  }

  /// GF(2^128) multiplication with polynomial x^128 + x^7 + x^2 + x + 1.
  static void _gfMul(Uint8List x, Uint8List y) {
    final z = Uint8List(16);
    final v = Uint8List.fromList(y);
    for (var i = 0; i < 128; i++) {
      if ((x[i >> 3] & (0x80 >> (i & 7))) != 0) {
        for (var j = 0; j < 16; j++) {
          z[j] ^= v[j];
        }
      }
      final lsb = (v[15] & 1) != 0;
      for (var j = 15; j > 0; j--) {
        v[j] = ((v[j] >> 1) | ((v[j - 1] & 1) << 7)) & 0xff;
      }
      v[0] >>= 1;
      if (lsb) v[0] ^= 0xe1;
    }
    x.setAll(0, z);
  }

  static const _sbox = <int>[
    0x63,
    0x7c,
    0x77,
    0x7b,
    0xf2,
    0x6b,
    0x6f,
    0xc5,
    0x30,
    0x01,
    0x67,
    0x2b,
    0xfe,
    0xd7,
    0xab,
    0x76,
    0xca,
    0x82,
    0xc9,
    0x7d,
    0xfa,
    0x59,
    0x47,
    0xf0,
    0xad,
    0xd4,
    0xa2,
    0xaf,
    0x9c,
    0xa4,
    0x72,
    0xc0,
    0xb7,
    0xfd,
    0x93,
    0x26,
    0x36,
    0x3f,
    0xf7,
    0xcc,
    0x34,
    0xa5,
    0xe5,
    0xf1,
    0x71,
    0xd8,
    0x31,
    0x15,
    0x04,
    0xc7,
    0x23,
    0xc3,
    0x18,
    0x96,
    0x05,
    0x9a,
    0x07,
    0x12,
    0x80,
    0xe2,
    0xeb,
    0x27,
    0xb2,
    0x75,
    0x09,
    0x83,
    0x2c,
    0x1a,
    0x1b,
    0x6e,
    0x5a,
    0xa0,
    0x52,
    0x3b,
    0xd6,
    0xb3,
    0x29,
    0xe3,
    0x2f,
    0x84,
    0x53,
    0xd1,
    0x00,
    0xed,
    0x20,
    0xfc,
    0xb1,
    0x5b,
    0x6a,
    0xcb,
    0xbe,
    0x39,
    0x4a,
    0x4c,
    0x58,
    0xcf,
    0xd0,
    0xef,
    0xaa,
    0xfb,
    0x43,
    0x4d,
    0x33,
    0x85,
    0x45,
    0xf9,
    0x02,
    0x7f,
    0x50,
    0x3c,
    0x9f,
    0xa8,
    0x51,
    0xa3,
    0x40,
    0x8f,
    0x92,
    0x9d,
    0x38,
    0xf5,
    0xbc,
    0xb6,
    0xda,
    0x21,
    0x10,
    0xff,
    0xf3,
    0xd2,
    0xcd,
    0x0c,
    0x13,
    0xec,
    0x5f,
    0x97,
    0x44,
    0x17,
    0xc4,
    0xa7,
    0x7e,
    0x3d,
    0x64,
    0x5d,
    0x19,
    0x73,
    0x60,
    0x81,
    0x4f,
    0xdc,
    0x22,
    0x2a,
    0x90,
    0x88,
    0x46,
    0xee,
    0xb8,
    0x14,
    0xde,
    0x5e,
    0x0b,
    0xdb,
    0xe0,
    0x32,
    0x3a,
    0x0a,
    0x49,
    0x06,
    0x24,
    0x5c,
    0xc2,
    0xd3,
    0xac,
    0x62,
    0x91,
    0x95,
    0xe4,
    0x79,
    0xe7,
    0xc8,
    0x37,
    0x6d,
    0x8d,
    0xd5,
    0x4e,
    0xa9,
    0x6c,
    0x56,
    0xf4,
    0xea,
    0x65,
    0x7a,
    0xae,
    0x08,
    0xba,
    0x78,
    0x25,
    0x2e,
    0x1c,
    0xa6,
    0xb4,
    0xc6,
    0xe8,
    0xdd,
    0x74,
    0x1f,
    0x4b,
    0xbd,
    0x8b,
    0x8a,
    0x70,
    0x3e,
    0xb5,
    0x66,
    0x48,
    0x03,
    0xf6,
    0x0e,
    0x61,
    0x35,
    0x57,
    0xb9,
    0x86,
    0xc1,
    0x1d,
    0x9e,
    0xe1,
    0xf8,
    0x98,
    0x11,
    0x69,
    0xd9,
    0x8e,
    0x94,
    0x9b,
    0x1e,
    0x87,
    0xe9,
    0xce,
    0x55,
    0x28,
    0xdf,
    0x8c,
    0xa1,
    0x89,
    0x0d,
    0xbf,
    0xe6,
    0x42,
    0x68,
    0x41,
    0x99,
    0x2d,
    0x0f,
    0xb0,
    0x54,
    0xbb,
    0x16,
  ];

  static const _rcon = <int>[0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40];

  static Uint8List _expandKey(Uint8List key) {
    final out = Uint8List(240)..setRange(0, 32, key);
    var bytes = 32;
    var rconIdx = 0;
    final temp = Uint8List(4);
    while (bytes < 240) {
      for (var i = 0; i < 4; i++) {
        temp[i] = out[bytes - 4 + i];
      }
      if (bytes % 32 == 0) {
        final t = temp[0];
        temp[0] = _sbox[temp[1]] ^ _rcon[rconIdx++];
        temp[1] = _sbox[temp[2]];
        temp[2] = _sbox[temp[3]];
        temp[3] = _sbox[t];
      } else if (bytes % 32 == 16) {
        for (var i = 0; i < 4; i++) {
          temp[i] = _sbox[temp[i]];
        }
      }
      for (var i = 0; i < 4; i++) {
        out[bytes] = out[bytes - 32] ^ temp[i];
        bytes++;
      }
    }
    return out;
  }

  static int _xtime(int b) => ((b << 1) ^ (((b >> 7) & 1) * 0x1b)) & 0xff;

  Uint8List _encryptBlock(Uint8List input) {
    final s = Uint8List.fromList(input);
    for (var i = 0; i < 16; i++) {
      s[i] ^= _roundKeys[i];
    }
    for (var round = 1; round <= 14; round++) {
      // SubBytes
      for (var i = 0; i < 16; i++) {
        s[i] = _sbox[s[i]];
      }
      // ShiftRows (column-major)
      var t = s[1];
      s[1] = s[5];
      s[5] = s[9];
      s[9] = s[13];
      s[13] = t;

      t = s[2];
      s[2] = s[10];
      s[10] = t;
      t = s[6];
      s[6] = s[14];
      s[14] = t;

      t = s[15];
      s[15] = s[11];
      s[11] = s[7];
      s[7] = s[3];
      s[3] = t;

      // MixColumns (rounds 1..13)
      if (round < 14) {
        for (var c = 0; c < 4; c++) {
          final i = c * 4;
          final a0 = s[i];
          final a1 = s[i + 1];
          final a2 = s[i + 2];
          final a3 = s[i + 3];
          final xor = a0 ^ a1 ^ a2 ^ a3;
          s[i] ^= xor ^ _xtime(a0 ^ a1);
          s[i + 1] ^= xor ^ _xtime(a1 ^ a2);
          s[i + 2] ^= xor ^ _xtime(a2 ^ a3);
          s[i + 3] ^= xor ^ _xtime(a3 ^ a0);
        }
      }
      // AddRoundKey
      final rk = round * 16;
      for (var i = 0; i < 16; i++) {
        s[i] ^= _roundKeys[rk + i];
      }
    }
    return s;
  }
}
