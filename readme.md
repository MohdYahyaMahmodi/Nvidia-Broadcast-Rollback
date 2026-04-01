# Nvidia Broadcast Rollback

[![GitHub release](https://img.shields.io/github/v/release/MohdYahyaMahmodi/Nvidia-Broadcast-Rollback)](https://github.com/MohdYahyaMahmodi/Nvidia-Broadcast-Rollback/releases)
[![Downloads](https://img.shields.io/github/downloads/MohdYahyaMahmodi/Nvidia-Broadcast-Rollback/total)](https://github.com/MohdYahyaMahmodi/Nvidia-Broadcast-Rollback/releases)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-0%2F72%20Clean-brightgreen)](https://www.virustotal.com/gui/file/30b48e5a842963c6593e354550c77b8cbbaec23ceb1ac7655effd634417a6806)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

NVIDIA Broadcast v2.x crashes a lot of systems with a `HYPERVISOR_ERROR (0x20001)` blue screen. It happens when the installer finishes or when the app launches. Disabling Hyper-V, VBS, and every virtualization feature in Windows doesn't fix it.

This script installs Broadcast v1.4.0.39 (last stable version) and blocks it from auto-updating back to v2.x.

## Quick Install

Open PowerShell as admin and paste this:

```powershell
irm https://raw.githubusercontent.com/MohdYahyaMahmodi/Nvidia-Broadcast-Rollback/main/broadcast-rollback.bat -OutFile "$env:TEMP\broadcast-rollback.bat"; Start-Process "$env:TEMP\broadcast-rollback.bat" -Verb RunAs
```

Or just download `broadcast-rollback.bat` from this repo and run it.

## What It Does

1. Downloads Broadcast v1.4.0.39 directly from NVIDIA's servers
2. Launches the installer
3. Adds a firewall rule to block update nags

That's it. No patching, no cracks, no sketchy downloads. Just an older official build and a firewall rule.

## Unblocking Updates

If NVIDIA ever fixes the crash and you want to update:

```
broadcast-rollback.bat --unblock
```

## Why v1.4.0.39?

It's the last version before the v2.x rewrite that introduced the crash. Noise removal, background removal, auto frame — everything works fine on it. You're not missing anything important.

## Requirements

- Windows 10 or 11 (64-bit)
- NVIDIA RTX 20, 30, or 40 series GPU
- Admin privileges

## What Doesn't Fix the Crash

For anyone who hasn't tried this yet and wants to exhaust other options first, none of these work:

- `bcdedit /set hypervisorlaunchtype off`
- `bcdedit /set vsmlaunchtype off`
- Disabling Hyper-V, Virtual Machine Platform, Windows Hypervisor Platform in Windows Features
- Turning off Memory Integrity in Core Isolation
- Updating to the latest Studio or Game Ready drivers

If you find a way to run v2.x without crashing, open an issue and let me know.

## How the Script Works

Full breakdown of every section so you know exactly what's running on your machine.

---

### Setup

```batch
@echo off
setlocal enabledelayedexpansion
title Nvidia Broadcast Rollback
```

`@echo off` stops the terminal from printing every command as it runs. `setlocal enabledelayedexpansion` lets the script handle variables that change inside `if` blocks and loops — without this, batch sometimes reads variables before they've been updated. `title` just sets the window title.

---

### Admin Check

```batch
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Restarting with admin privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
```

`net session` is a command that only succeeds if you're running as admin. The output gets thrown away (`>nul 2>&1`), we only care about the exit code. If it fails (not admin), the script relaunches itself using PowerShell's `Start-Process` with `-Verb RunAs`, which triggers the UAC prompt. `%~f0` is the full path to the current script. The original non-admin instance then exits.

---

### Unblock Mode

```batch
if /i "%~1"=="--unblock" (
    echo Removing update block...
    netsh advfirewall firewall delete rule name="Nvidia Broadcast Rollback - Block Updates" >nul 2>&1
    echo Done. Broadcast can now check for updates.
    pause
    exit /b
)
```

`%~1` is the first argument passed to the script. If you run `broadcast-rollback.bat --unblock`, it skips the entire install process and just deletes the firewall rule that was blocking Broadcast from checking for updates. `/i` makes the comparison case-insensitive so `--Unblock` and `--UNBLOCK` work too.

---

### Config

```batch
set "DOWNLOAD_URL=https://international.download.nvidia.com/Windows/broadcast/1.4.0.39/NVIDIA_Broadcast_v1.4.0.39.exe"
set "INSTALLER=%TEMP%\NVIDIA_Broadcast_v1.4.0.39.exe"
set "INSTALL_DIR=C:\Program Files\NVIDIA Corporation\NVIDIA Broadcast"
set "RULE_NAME=Nvidia Broadcast Rollback - Block Updates"
```

All the variables in one place. The download URL points directly to NVIDIA's CDN, not some mirror. The installer gets saved to your Windows temp folder (`%TEMP%` is usually `C:\Users\YourName\AppData\Local\Temp`). The install directory is where Broadcast installs by default. The rule name is what shows up in Windows Firewall.

---

### Step 1: Download

```batch
curl -L --progress-bar -o "%INSTALLER%" "%DOWNLOAD_URL%"
if not exist "%INSTALLER%" (
    echo [X] Download failed. Check your internet connection.
    pause
    exit /b 1
)
```

Uses `curl` which comes built into Windows 10 and 11. `-L` follows redirects (NVIDIA's CDN sometimes redirects). `--progress-bar` shows a simple progress bar instead of the verbose default output. `-o` sets the output file path. If the file doesn't exist after the download attempt, something went wrong so it tells you and exits with error code 1.

---

### Step 2: Install

```batch
start /wait "" "%INSTALLER%"
del "%INSTALLER%" 2>nul

if not exist "%INSTALL_DIR%\NVIDIA Broadcast UI.exe" (
    echo [!] Could not find Broadcast at default path.
    set /p "INSTALL_DIR=     Enter install path: "
)
```

`start /wait` launches the NVIDIA installer and pauses the script until you close it. The empty `""` is required by the `start` command as a window title placeholder when the path has quotes. Once installation is done, `del` cleans up the installer from your temp folder. `2>nul` suppresses any error if the file is already gone. Then it checks if `NVIDIA Broadcast UI.exe` exists at the default install path. If you installed it somewhere else, it asks you to type the path so the firewall rule targets the right executable.

---

### Step 3: Block Updates

```batch
netsh advfirewall firewall delete rule name="%RULE_NAME%" >nul 2>&1

netsh advfirewall firewall add rule name="%RULE_NAME%" ^
    dir=out action=block profile=any ^
    program="%INSTALL_DIR%\NVIDIA Broadcast UI.exe" >nul

netsh advfirewall firewall add rule name="%RULE_NAME%" ^
    dir=in action=block profile=any ^
    program="%INSTALL_DIR%\NVIDIA Broadcast UI.exe" >nul
```

First it deletes any existing rules with the same name to avoid duplicates if you run the script more than once. Then it creates two new firewall rules using `netsh`. One blocks outbound traffic (`dir=out`) so Broadcast can't phone home to check for updates. The other blocks inbound traffic (`dir=in`) so NVIDIA's servers can't push anything to it either. `profile=any` means the rules apply whether you're on a public, private, or domain network. `^` is batch's line continuation character so the command can span multiple lines.

---

That's the entire script. Nothing runs in the background after it finishes, nothing persists as a service, and the only thing it leaves behind is two firewall rules that you can remove at any time.

## License

MIT
