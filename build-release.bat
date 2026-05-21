@echo off
setlocal

echo ============================================================
echo  Konta - Build Release (AAB)
echo ============================================================

for /f "tokens=2 delims= " %%v in ('findstr /r "^version:" pubspec.yaml') do set VERSION=%%v
echo Versao: %VERSION%
echo.

echo [1/3] Limpando build anterior...
call flutter clean >nul 2>&1

echo [2/3] Buscando dependencias...
call flutter pub get
if %errorlevel% neq 0 ( echo ERRO: flutter pub get falhou && pause && exit /b 1 )

echo [3/3] Buildando AAB para Play Store...
call flutter build appbundle --release
if %errorlevel% neq 0 ( echo ERRO: flutter build appbundle falhou && pause && exit /b 1 )

echo.
echo ============================================================
echo  SUCESSO!
echo  AAB: build\app\outputs\bundle\release\app-release.aab
echo ============================================================
echo.

start "" "build\app\outputs\bundle\release"

pause
