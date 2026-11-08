#!/bin/bash
# ORTAK BULUT KURULUM BETİĞİ — bütün projeler (not, dosya-okuyucu, ezber,
# harita, YouTube, …) için TEK betik. claude.ai/code → ortam → Edit →
# Setup script alanına bu dosyanın içeriği yapıştırılır. Asıl kopya burası
# (kaimau1/not/tool/ortak_kurulum.sh); değişince ortama yeniden yapıştır.
#
# Ne yapar: oturumdaki depoları bulur, türüne göre araç kurar.
#   pubspec.yaml      → Flutter (sürüm: CI'daki FLUTTER_VERSION / .fvmrc,
#                       yoksa varsayılan) + flutter pub get
#   package.json      → npm ci (kilit dosyası varsa) / npm install
#   requirements.txt  → pip install -r
# Hiçbir adım oturumu düşürmez: hata olursa uyarı yazar, sürer.
# Deneme: KURULUM_DENEME=1 bash ortak_kurulum.sh → yalnız ne yapacağını yazar.

VARSAYILAN_FLUTTER="3.47.9"
DENEME="${KURULUM_DENEME:-0}"

yap() { echo "+ $*"; [ "$DENEME" = 1 ] || "$@"; }
uyar() { echo "UYARI: $*" >&2; }

# Depoları bul: çalışma dizini + /home/user altındaki git depoları.
depolar=()
for d in "$PWD" /home/user/*/; do
  d="${d%/}"
  [ -d "$d/.git" ] && depolar+=("$d")
done
mapfile -t depolar < <(printf '%s\n' "${depolar[@]}" | sort -u)
echo "Bulunan depolar: ${depolar[*]:-(yok)}"

flutter_surumu() {
  local d="$1" v=""
  if [ -f "$d/.fvmrc" ]; then
    v=$(sed -nE 's/.*"flutter" *: *"([0-9.]+)".*/\1/p' "$d/.fvmrc" | head -1)
  fi
  if [ -z "$v" ] && [ -d "$d/.github/workflows" ]; then
    v=$(grep -hoE "(FLUTTER_VERSION|flutter-version):\s*['\"]?[0-9]+\.[0-9]+\.[0-9]+" \
        "$d"/.github/workflows/*.y*ml 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  fi
  echo "${v:-$VARSAYILAN_FLUTTER}"
}

flutter_kur() {
  local v="$1" hedef="/opt/flutter-$1"
  if [ -x "$hedef/bin/flutter" ]; then echo "Flutter $v zaten kurulu."; return 0; fi
  local url="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${v}-stable.tar.xz"
  local gecici; gecici=$(mktemp -d)
  yap curl -fsSLo "$gecici/f.tar.xz" "$url" || { uyar "Flutter $v indirilemedi"; return 1; }
  yap tar -xJf "$gecici/f.tar.xz" -C "$gecici" || { uyar "Flutter $v açılamadı"; return 1; }
  yap mv "$gecici/flutter" "$hedef"
  rm -rf "$gecici"
  yap git config --global --add safe.directory "$hedef"
}

flutter_ilk=""
for d in "${depolar[@]}"; do
  echo "== $d"
  if [ -f "$d/pubspec.yaml" ]; then
    v=$(flutter_surumu "$d")
    echo "Flutter projesi → $v"
    if flutter_kur "$v"; then
      [ -z "$flutter_ilk" ] && flutter_ilk="$v"
      (cd "$d" && yap "/opt/flutter-$v/bin/flutter" pub get) || uyar "pub get başarısız: $d"
      # pubspec.lock'u kurulum değiştirdiyse geri al (bağımlılık eklenmedi).
      [ "$DENEME" = 1 ] || git -C "$d" checkout -- pubspec.lock 2>/dev/null || true
    fi
  fi
  # package.json: kökte ve bir alt klasörde (functions/, rules-test/ …).
  while IFS= read -r pj; do
    pd=$(dirname "$pj")
    if [ -f "$pd/package-lock.json" ]; then
      (cd "$pd" && yap npm ci --no-audit --no-fund) || uyar "npm ci başarısız: $pd"
    else
      (cd "$pd" && yap npm install --no-audit --no-fund --package-lock=false) || uyar "npm install başarısız: $pd"
    fi
  done < <(find "$d" -maxdepth 2 -name package.json -not -path '*/node_modules/*' 2>/dev/null)
  while IFS= read -r rq; do
    yap pip install -q -r "$rq" || uyar "pip başarısız: $rq"
  done < <(find "$d" -maxdepth 2 -name requirements.txt 2>/dev/null)
done

# Depo henüz klonlanmadıysa (betik klondan önce koşuyorsa) varsayılan Flutter.
if [ -z "$flutter_ilk" ] && [ ${#depolar[@]} -eq 0 ]; then
  flutter_kur "$VARSAYILAN_FLUTTER" && flutter_ilk="$VARSAYILAN_FLUTTER"
fi

# Ortak yol: /opt/flutter → ilk projenin sürümü; PATH'e ekle.
if [ -n "$flutter_ilk" ]; then
  yap ln -sfn "/opt/flutter-$flutter_ilk" /opt/flutter
  grep -q '/opt/flutter/bin' ~/.bashrc 2>/dev/null ||
    { [ "$DENEME" = 1 ] || echo 'export PATH="/opt/flutter/bin:$PATH"' >> ~/.bashrc; }
  [ "$DENEME" = 1 ] || /opt/flutter/bin/flutter --version | head -1
fi
echo "Kurulum bitti."
exit 0
