@echo off
setlocal

echo ============================================================
echo  Konta — Build Release (AAB + APK)
echo ============================================================

:: Lê a versão do pubspec.yaml
for /f "tokens=2 delims= " %%v in ('findstr /r "^version:" pubspec.yaml') do set VERSION=%%v
echo Versao: %VERSION%
echo.

:: Limpa build anterior
echo [1/4] Limpando build anterior...
call flutter clean >nul 2>&1

:: Busca dependencias
echo [2/4] Buscando dependencias...
call flutter pub get
if %errorlevel% neq 0 ( echo ERRO: flutter pub get falhou && pause && exit /b 1 )

:: Gera codigo Hive (build_runner)
echo [3/4] Gerando codigo Hive...
call dart run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 ( echo ERRO: build_runner falhou && pause && exit /b 1 )

:: Build AAB (Play Store)
echo [4/4] Buildando AAB para Play Store...
call flutter build appbundle --release
if %errorlevel% neq 0 ( echo ERRO: flutter build appbundle falhou && pause && exit /b 1 )

echo.
echo ============================================================
echo  SUCESSO!
echo  AAB: build\app\outputs\bundle\release\app-release.aab
echo ============================================================
echo.

:: Abre a pasta com o AAB
start "" "build\app\outputs\bundle\release"

pause
