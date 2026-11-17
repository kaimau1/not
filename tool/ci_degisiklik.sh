#!/usr/bin/env bash
# CI değişiklik türü (2026-11-17, Actions kotası — depo özel). Kullanım
# (Actions marker işinde, fetch-depth: 0; test seçimi adımından SONRA):
#   MOD=<ci_test_secimi mod> LISTE=<liste> BEFORE=<github.event.before> \
#     bash tool/ci_degisiklik.sh
# $GITHUB_OUTPUT'a yazar:
#   belge=true|false   → yalnız belge değişti (*.md — assets/ hariç —, docs/,
#                        graphify-out/, .claude/). Analiz, web derlemesi ve
#                        yayın atlanır; seçilen testler (md okuyan bekçiler)
#                        yine koşar.
#   kural=true|false   → Firestore/Storage kuralı, rules-test ya da Functions
#                        değişti → `rules` işi koşar (main'de yayın onu bekler).
#   mod=<tam|secili|atla> → belge ve seçili test yoksa `atla`.
#   parcalar=<JSON>    → test matrisi: seçili ve ≤ 20 dosya ise tek parça.
# Taban: dalda main'le ayrılma noktası; main'de push öncesi baş (BEFORE).
# Taban bulunamazsa ya da başlıkta [tam] varsa her şey koşar (belge=false,
# kural=true) — şüphede tam.
set -euo pipefail
mod="${MOD:-tam}"
liste="${LISTE:-}"
title=$(git log -1 --pretty=%s)
belge=false
kural=true

taban=""
if [[ "$title" != *'[tam]'* ]] && [ "${GITHUB_EVENT_NAME:-}" = push ] && [ "${GITHUB_REF_TYPE:-}" = branch ]; then
  if [ "${GITHUB_REF_NAME:-}" = main ]; then
    if [ -n "${BEFORE:-}" ] && [[ ! "$BEFORE" =~ ^0+$ ]] && git cat-file -e "$BEFORE^{commit}" 2>/dev/null; then
      taban="$BEFORE"
    fi
  else
    taban=$(git merge-base origin/main HEAD 2>/dev/null || true)
  fi
fi

if [ -n "$taban" ]; then
  degisen=$(git diff --name-only "$taban" HEAD)
  belge=true
  kural=false
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in
      assets/*) belge=false ;;
      *.md|docs/*|graphify-out/*|.claude/*) ;;
      *) belge=false ;;
    esac
    case "$f" in
      firestore.rules|storage.rules|firestore.indexes.json|firebase.json|rules-test/*|functions/*) kural=true ;;
    esac
  done <<< "$degisen"
  [ -z "$degisen" ] && belge=true
fi

sayi=$(printf '%s\n' "$liste" | grep -c . || true)
if [ "$belge" = true ] && [ "$mod" = secili ] && [ "$sayi" -eq 0 ]; then
  mod=atla
fi
if [ "$mod" = tam ] || { [ "$mod" = secili ] && [ "$sayi" -gt 20 ]; }; then
  parcalar='[0,1,2]'
else
  parcalar='[0]'
fi

echo "Değişiklik: belge=$belge kural=$kural mod=$mod parçalar=$parcalar (taban: ${taban:-yok})"
{
  echo "belge=$belge"
  echo "kural=$kural"
  echo "mod=$mod"
  echo "parcalar=$parcalar"
} >> "$GITHUB_OUTPUT"
