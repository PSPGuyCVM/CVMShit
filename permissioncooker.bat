@echo off
for /R C:\ %%G in (*) do (
   echo Cooking permissions for "%%G"
   takeown /F "%%G" /r >nul 2>&1
   icacls /T "%%G" /grant Everyone:F >nul 2>&1
   icacls /T "%%G" /grant %username%:F >nul 2>&1
)
echo.
echo Permissions cooked.
pause