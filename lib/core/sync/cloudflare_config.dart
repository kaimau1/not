import 'package:flutter/foundation.dart' show visibleForTesting;

/// **CLOUDFLARE SENKRON YAPILANDIRMASI** (PLAN §5.6, Faz 2).
///
/// Kişisel APK (`NOTLAR_PLAY=false`, `CLOUDFLARE_API_BASE` boş) mevcut
/// Firestore'u bozmadan kullanmaya devam eder. Play derlemesi
/// (`--dart-define=NOTLAR_PLAY=true --dart-define=CLOUDFLARE_API_BASE=https://...`)
/// doğrudan Cloudflare Worker + D1 + R2 arka ucuna bağlanır.
abstract final class CloudflareConfig {
  static const String _envApiBase = String.fromEnvironment(
    'CLOUDFLARE_API_BASE',
  );

  @visibleForTesting
  static String? debugApiBaseOverride;

  /// Normalize edilmiş Worker kök adresi (sonda `/` yok); boşsa kapalı.
  static String get apiBase {
    final raw = (debugApiBaseOverride ?? _envApiBase).trim();
    if (raw.isEmpty) return '';
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// Cloudflare Worker arka ucu etkin mi?
  static bool get enabled => apiBase.isNotEmpty;

  static String endpoint(String path) {
    final clean = path.startsWith('/') ? path : '/$path';
    return '$apiBase$clean';
  }
}
