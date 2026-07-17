@echo off
REM ============================================================================
REM  Notlar - Windows surumunu YEREL olarak derler.
REM  Windows derlemesi CI'dan cikarildi (yavas ve nadiren gerekiyor); gerektiginde
REM  bu dosyaya cift tiklayarak masaustunde derle.
REM
REM  On kosullar:
REM    - Flutter (stable >= 3.44)  -> https://docs.flutter.dev/get-started/install
REM    - Visual Studio 2022, "Desktop development with C++" is yuku
REM    - Google girisi icin: proje kokunde env.json (asagiya bak; env.example.json'u kopyala)
REM
REM  Cikti: build\windows\x64\runner\Release\  (icindeki notlar.exe'yi calistir)
REM ============================================================================

setlocal
cd /d "%~dp0"

echo.
echo === Notlar - Windows derlemesi ===
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo [HATA] flutter bulunamadi. Once Flutter'i kurup PATH'e ekleyin:
  echo        https://docs.flutter.dev/get-started/install/windows
  echo.
  pause
  exit /b 1
)

REM Gizli degerler env.json'dan okunur (gitignore'da; depoya YAZILMAZ).
REM Yoksa uygulama yine derlenir ama Windows'ta Google girisi calismaz.
set DEFINE_ARG=
if exist "env.json" (
  set DEFINE_ARG=--dart-define-from-file=env.json
  echo env.json bulundu; masaustu Google kimlik bilgileri gomulecek.
) else (
  echo [UYARI] env.json yok; uygulama Google girisi OLMADAN derlenecek.
  echo         Google girisi icin env.example.json'u env.json olarak kopyalayip doldurun.
)
echo.

echo Bagimliliklar indiriliyor...
call flutter pub get
if errorlevel 1 goto :fail

echo.
echo Windows surumu derleniyor (release)...
call flutter build windows --release %DEFINE_ARG%
if errorlevel 1 goto :fail

echo.
echo === Basarili ===
echo Cikti: %cd%\build\windows\x64\runner\Release
echo Icindeki notlar.exe'yi calistirabilirsiniz.
echo.
REM Cikti klasorunu Gezgin'de ac
start "" "%cd%\build\windows\x64\runner\Release"
pause
exit /b 0

:fail
echo.
echo [HATA] Derleme basarisiz oldu. Yukaridaki ciktiyi kontrol edin.
echo.
pause
exit /b 1
