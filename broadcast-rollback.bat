@echo off
setlocal enabledelayedexpansion
title Nvidia Broadcast Rollback
:: ============================================================
:: Nvidia Broadcast Rollback - by Mohd Mahmodi
:: Rolls NVIDIA Broadcast back to v1.4.0.39 and prevents
:: auto-update by blocking outbound network access.
:: https://github.com/MohdYahyaMahmodi/Nvidia-Broadcast-Rollback
:: ============================================================
:: --- Check for admin ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Restarting with admin privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
:: --- Unblock mode ---
if /i "%~1"=="--unblock" (
    echo Removing update block...
    netsh advfirewall firewall delete rule name="Nvidia Broadcast Rollback - Block Updates" >nul 2>&1
    echo Done. Broadcast can now check for updates.
    pause
    exit /b
)
:: --- Config ---
set "DOWNLOAD_URL=https://international.download.nvidia.com/Windows/broadcast/1.4.0.39/NVIDIA_Broadcast_v1.4.0.39.exe"
set "INSTALLER=%TEMP%\NVIDIA_Broadcast_v1.4.0.39.exe"
set "INSTALL_DIR=C:\Program Files\NVIDIA Corporation\NVIDIA Broadcast"
set "RULE_NAME=Nvidia Broadcast Rollback - Block Updates"
echo.
echo   ========================================
echo    Nvidia Broadcast Rollback v1.0
echo    by Mohd Mahmodi
echo   ========================================
echo.
:: --- Step 1: Download ---
echo [1/3] Downloading NVIDIA Broadcast v1.4.0.39...
curl -L --progress-bar -o "%INSTALLER%" "%DOWNLOAD_URL%"
if not exist "%INSTALLER%" (
    echo [X] Download failed. Check your internet connection.
    pause
    exit /b 1
)
echo      Done.
echo.
:: --- Step 2: Install ---
echo [2/3] Launching installer...
echo      Complete the installer, then come back here.
start /wait "" "%INSTALLER%"
del "%INSTALLER%" 2>nul
if not exist "%INSTALL_DIR%\NVIDIA Broadcast UI.exe" (
    echo [!] Could not find Broadcast at default path.
    set /p "INSTALL_DIR=     Enter install path: "
)
echo      Done.
echo.
:: --- Step 3: Block updates ---
echo [3/3] Blocking auto-updates via firewall...
netsh advfirewall firewall delete rule name="%RULE_NAME%" >nul 2>&1
netsh advfirewall firewall add rule name="%RULE_NAME%" ^
    dir=out action=block profile=any ^
    program="%INSTALL_DIR%\NVIDIA Broadcast UI.exe" >nul
netsh advfirewall firewall add rule name="%RULE_NAME%" ^
    dir=in action=block profile=any ^
    program="%INSTALL_DIR%\NVIDIA Broadcast UI.exe" >nul
echo      Done. Broadcast is now locked to v1.4.0.39.
echo.
echo   To unblock updates later, run:
echo   broadcast-rollback.bat --unblock
echo.
echo   All done. Press any key to exit.
pause >nul