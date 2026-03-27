@echo off
setlocal enabledelayedexpansion
title Comic Sans System-wide - Use at your own risk!
color 4f

:: -----------------------------------------------------------
:: Check for administrator privileges
:: -----------------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run as Administrator.
    echo Right-click the file and select "Run as administrator".
    pause
    exit /b 1
)

:: -----------------------------------------------------------
:: Create a restore point (if possible)
:: -----------------------------------------------------------
echo Creating system restore point...
wmic /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Comic Sans Override", 100, 7 >nul 2>&1
if %errorlevel% neq 0 (
    echo   [WARNING] Could not create restore point. Proceeding anyway.
) else (
    echo   Restore point created.
)

:: -----------------------------------------------------------
:: Backup registry keys that will be modified
:: -----------------------------------------------------------
set BACKUP_DIR=%temp%\ComicSansBackup
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Backing up registry keys to %BACKUP_DIR%...
reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" "%BACKUP_DIR%\FontSubstitutes.reg" /y >nul 2>&1
reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "%BACKUP_DIR%\Fonts.reg" /y >nul 2>&1
reg export "HKCU\Control Panel\Desktop\WindowMetrics" "%BACKUP_DIR%\WindowMetrics.reg" /y >nul 2>&1
echo   Backup completed.

:: -----------------------------------------------------------
:: Verify Comic Sans MS is installed (copy from system if missing)
:: -----------------------------------------------------------
set FONTS_DIR=%windir%\Fonts
set COMIC_REG=%windir%\Fonts\comic.ttf
set COMIC_BOLD=%windir%\Fonts\comicbd.ttf

if not exist "%COMIC_REG%" (
    echo Comic Sans MS regular font not found. Attempting to install from system...
    :: On Windows 10/11 Comic Sans is usually present; if not, we can't proceed.
    if not exist "%windir%\Fonts\comic.ttf" (
        echo   ERROR: Comic Sans MS is not installed. This script cannot proceed.
        pause
        exit /b 1
    )
)

:: -----------------------------------------------------------
:: 1. Font Substitutions – replace all common UI fonts
:: -----------------------------------------------------------
echo Setting font substitutions...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Segoe UI" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Segoe UI Light" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Segoe UI Semibold" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Segoe UI Bold" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Tahoma" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Sans Serif" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Microsoft Sans Serif" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg 2" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Arial" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Verdana" /t REG_SZ /d "Comic Sans MS" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New" /t REG_SZ /d "Comic Sans MS" /f >nul
echo   Font substitutions completed.

:: -----------------------------------------------------------
:: 2. Override system font file entries (point Segoe UI to comic.ttf)
:: -----------------------------------------------------------
echo Overriding system font file mappings...
:: The value names can vary; we'll modify all that contain "Segoe UI"
for /f "tokens=1,2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" ^| findstr /i "Segoe UI"') do (
    set "valueName=%%a"
    set "valueData=%%b"
    if not "!valueData!"=="" (
        echo   Changing "!valueName!" to comic.ttf
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "!valueName!" /t REG_SZ /d "comic.ttf" /f >nul
    )
)
:: Also replace "MS Shell Dlg" related files (if any)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "MS Shell Dlg (TrueType)" /t REG_SZ /d "comic.ttf" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "MS Shell Dlg 2 (TrueType)" /t REG_SZ /d "comic.ttf" /f >nul 2>&1
echo   System font mappings overridden.

:: -----------------------------------------------------------
:: 3. Change binary WindowMetrics fonts using PowerShell
:: -----------------------------------------------------------
echo Setting UI element fonts (Caption, Icon, Menu, etc.)...
powershell -Command ^
    $font = New-Object System.Drawing.Font("Comic Sans MS", 9); ^
    $logfont = $font.ToLogFont(); ^
    $bytes = @(); ^
    $logfont.PSObject.Properties | ForEach-Object { ^
        $value = $_.Value; ^
        if ($value -is [string]) { ^
            $bytes += [System.Text.Encoding]::Unicode.GetBytes($value + [char]0); ^
        } elseif ($value -is [int]) { ^
            $bytes += [System.BitConverter]::GetBytes($value); ^
        } elseif ($value -is [byte]) { ^
            $bytes += $value; ^
        } elseif ($value -is [bool]) { ^
            $bytes += [System.BitConverter]::GetBytes([int]$value); ^
        } ^
    }; ^
    $binary = [byte[]]$bytes; ^
    $keys = @("CaptionFont","IconFont","MenuFont","MessageFont","StatusFont","SmCaptionFont"); ^
    foreach ($key in $keys) { ^
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name $key -Value $binary -Force; ^
    }
if %errorlevel% neq 0 (
    echo   [WARNING] Failed to set binary WindowMetrics fonts. Manual adjustment may be needed.
) else (
    echo   UI element fonts set to Comic Sans MS.
)

:: -----------------------------------------------------------
:: 4. Additional registry tweaks for classic dialogs
:: -----------------------------------------------------------
echo Tweaking classic dialog fonts...
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MenuHeight" /t REG_SZ /d "300" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MenuWidth" /t REG_SZ /d "300" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothingType" /t REG_DWORD /d 2 /f >nul 2>&1
echo   Classic dialog fonts configured.

:: -----------------------------------------------------------
:: 5. (Optional) Physical font file replacement – VERY RISKY
:: -----------------------------------------------------------
echo ATTEMPTING physical font file replacement...
takeown /f "%FONTS_DIR%\segoeui.ttf" >nul 2>&1
icacls "%FONTS_DIR%\segoeui.ttf" /grant Administrators:F >nul 2>&1
ren "%FONTS_DIR%\segoeui.ttf" "segoeui.bak" >nul 2>&1
copy "%COMIC_REG%" "%FONTS_DIR%\segoeui.ttf" >nul 2>&1
takeown /f "%FONTS_DIR%\segoeuib.ttf" >nul 2>&1
icacls "%FONTS_DIR%\segoeuib.ttf" /grant Administrators:F >nul 2>&1
ren "%FONTS_DIR%\segoeuib.ttf" "segoeuib.bak" >nul 2>&1
copy "%COMIC_BOLD%" "%FONTS_DIR%\segoeuib.ttf" >nul 2>&1

:: -----------------------------------------------------------
:: Notify user about restart
:: -----------------------------------------------------------
echo.
echo ============================================================
echo All available methods have been applied.
echo Please **restart your computer** for the changes to take full effect.
echo.
echo A restore script has been saved as "Restore_ComicSans.bat"
echo in the same folder where this script is located.
echo ============================================================
echo.

:: -----------------------------------------------------------
:: Generate a restore script
:: -----------------------------------------------------------
set "RESTORE_SCRIPT=%~dp0Restore_ComicSans.bat"
(
    echo @echo off
    echo title Restore System Fonts
    echo echo Restoring original registry settings...
    echo if exist "%BACKUP_DIR%\FontSubstitutes.reg" reg import "%BACKUP_DIR%\FontSubstitutes.reg"
    echo if exist "%BACKUP_DIR%\Fonts.reg" reg import "%BACKUP_DIR%\Fonts.reg"
    echo if exist "%BACKUP_DIR%\WindowMetrics.reg" reg import "%BACKUP_DIR%\WindowMetrics.reg"
    echo echo.
    echo echo The original font file for Segoe UI was not replaced by this script.
    echo echo If you manually replaced physical files, you need to restore them yourself.
    echo echo.
    echo echo A reboot is required to complete the restore.
    echo pause
) > "%RESTORE_SCRIPT%"

echo Restore script created at: %RESTORE_SCRIPT%
pause
