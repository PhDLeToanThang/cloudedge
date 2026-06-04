@echo off
chcp 65001 >nul
title Move Project to C:\cloudedge

echo ========================================
echo  Chuyen project tu D:\hol.cloud.edu.vn
echo               sang
echo          C:\cloudedge
echo ========================================
echo.
echo Buoc 1: Dang AionUI (neu chua dong)
tasklist /FI "IMAGENAME eq AionUi.exe" 2>NUL | find /I /N "AionUi.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo  Dang tat AionUI...
    taskkill /F /IM AionUi.exe >nul 2>&1
    timeout /t 3 /nobreak >nul
)
echo  OK
echo.

echo Buoc 2: Xoa D:\hol.cloud.edu.vn
if exist D:\hol.cloud.edu.vn (
    rmdir /S /Q D:\hol.cloud.edu.vn
    if exist D:\hol.cloud.edu.vn (
        echo  LOI: Khong the xoa D:\hol.cloud.edu.vn
        echo  Dang thu lai sau 5 giay...
        timeout /t 5 /nobreak >nul
        rmdir /S /Q D:\hol.cloud.edu.vn
    )
)
echo  OK
echo.

echo Buoc 3: Xoa cache AionUI workspace
if exist "%APPDATA%\AionUi\Local Storage\leveldb" (
    del /F /S /Q "%APPDATA%\AionUi\Local Storage\leveldb\*.ldb" >nul 2>&1
    del /F /S /Q "%APPDATA%\AionUi\Local Storage\leveldb\*.log" >nul 2>&1
    del /F /S /Q "%APPDATA%\AionUi\Cache\Cache_Data\*" >nul 2>&1
)
if exist "%APPDATA%\AionUi\aionui\aionui-backend.db-wal" (
    del /F "%APPDATA%\AionUi\aionui\aionui-backend.db-wal" >nul 2>&1
)
echo  OK
echo.

echo Buoc 4: Mo AionUI voi project root moi
set "AIONUI_PATH="
for %%P in (
    "%LOCALAPPDATA%\Programs\AionUi\AionUi.exe"
    "%PROGRAMFILES%\AionUi\AionUi.exe"
    "%PROGRAMFILES(X86)%\AionUi\AionUi.exe"
) do (
    if exist %%P set "AIONUI_PATH=%%~fP"
)
if defined AIONUI_PATH (
    start "" "%AIONUI_PATH%" "C:\cloudedge"
    echo  Da mo AionUI voi C:\cloudedge
) else (
    echo  KHONG tim thay AionUi.exe
    echo  Vui long tu dong mo AionUI va chon Open Project ^> C:\cloudedge
)
echo.

echo ========================================
echo  HOAN TAT!
echo  Project panel se hien thi C:\cloudedge
echo ========================================
timeout /t 5 /nobreak >nul
