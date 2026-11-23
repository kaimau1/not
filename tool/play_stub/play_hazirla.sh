#!/usr/bin/env bash
# Play derlemesi için ONNX eklentisini kukla paketle değiştirir (docs/play_hazirlik.md).
# `flutter pub get`'ten ÖNCE çalıştır. Geri almak: `bash tool/play_stub/play_hazirla.sh geri`
# (pubspec_overrides.yaml silinir; pubspec.lock'u `git checkout pubspec.lock` ile geri al).
set -euo pipefail
cd "$(dirname "$0")/../.."
if [ "${1:-}" = "geri" ]; then
  rm -f pubspec_overrides.yaml
  echo "Kukla kaldırıldı; 'git checkout pubspec.lock' + 'flutter pub get' çalıştır."
  exit 0
fi
cat > pubspec_overrides.yaml <<'YAML'
dependency_overrides:
  flutter_onnxruntime:
    path: tool/play_stub/flutter_onnxruntime
YAML
echo "pubspec_overrides.yaml yazıldı; şimdi 'flutter pub get' çalıştır."
