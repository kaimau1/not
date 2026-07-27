# Ceviri dosyalarini sablonla karsilastirir: eksik/fazla anahtar ve YER TUTUCU
# uyusmazligi. Yer tutucu ({count}, {error}...) toplu ceviride en sik kirilan
# yer ve gozle yakalanmiyor -- yanlis yer tutucu calisma aninda hata verir.
#
# Kullanim:  powershell -File tool/check_arb.ps1
$ErrorActionPreference = 'Stop'
$dir = Join-Path $PSScriptRoot '..\lib\l10n'
$template = Join-Path $dir 'app_tr.arb'

function Get-Entries($path) {
  $json = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
  $map = @{}
  foreach ($p in $json.PSObject.Properties) {
    if ($p.Name -like '@*') { continue }
    $map[$p.Name] = [string]$p.Value
  }
  return $map
}

function Get-Placeholders($text) {
  return (([regex]::Matches($text, '\{([A-Za-z0-9_]+)\}') | ForEach-Object { $_.Groups[1].Value }) | Sort-Object -Unique) -join ','
}

$base = Get-Entries $template
$fail = 0

foreach ($file in Get-ChildItem $dir -Filter 'app_*.arb') {
  if ($file.FullName -eq (Resolve-Path $template).Path) { continue }
  $other = Get-Entries $file.FullName
  $problems = @()

  foreach ($key in $base.Keys) {
    if (-not $other.ContainsKey($key)) { $problems += "EKSIK anahtar: $key"; continue }
    $a = Get-Placeholders $base[$key]
    $b = Get-Placeholders $other[$key]
    if ($a -ne $b) { $problems += "YER TUTUCU farkli: $key  (tr: [$a]  $($file.BaseName): [$b])" }
  }
  foreach ($key in $other.Keys) {
    if (-not $base.ContainsKey($key)) { $problems += "FAZLA anahtar (sablonda yok): $key" }
  }

  if ($problems.Count -eq 0) {
    Write-Host "$($file.Name): tamam ($($other.Count) anahtar)"
  } else {
    $fail = 1
    Write-Host "$($file.Name): $($problems.Count) sorun"
    $problems | ForEach-Object { Write-Host "  - $_" }
  }
}

exit $fail
