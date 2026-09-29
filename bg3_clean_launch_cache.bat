@echo off
setlocal EnableExtensions
title BG3 + NVIDIA Cache Cleaner

rem ============================================================================
rem  BG3 + NVIDIA  Shader/Level Cache Cleaner
rem  ---------------------------------------------------------------------------
rem  Purpose : clear the disk shader / level caches that can cause the
rem            "works once, then crashes on the next launch" early D3D11 fault.
rem  Robust  : files that are currently in use (locked) are NOT force-killed;
rem            they are simply listed as [LOCKED] so you can close whatever is
rem            holding them and re-run. The script never hangs or aborts.
rem  Safe    : only touches cache folders. Saves, settings and MODs live in
rem            OTHER folders and are NOT touched.
rem ============================================================================

rem --- Toggle: also stop the NVIDIA display helper so it releases DXCache.
rem     It is a background helper that restarts itself automatically.
rem     Set to 0 if you prefer to leave every process untouched.
set "KILL_PROCS=1"

set "NPX=%USERPROFILE%"
set "DX=%NPX%\AppData\Local\NVIDIA\DXCache"
set "LC=%NPX%\AppData\Local\Larian Studios\Baldur's Gate 3\LevelCache"
set "TP=%NPX%\AppData\Local\Larian Studios\Baldur's Gate 3\Temp"
set "DS=%NPX%\AppData\Local\D3DSCache"

rem apostrophe-safe copies for the PowerShell size reporter
set "DXP=%DX:'=''%"
set "LCP=%LC:'=''%"
set "TPP=%TP:'=''%"
set "DSP=%DS:'=''%"

echo.
echo ============================================================================
echo   BG3 Cache Cleaner
echo ============================================================================
echo   Targets:
echo     [1] %DX%
echo     [2] %LC%
echo     [3] %TP%
echo     [4] %DS%
echo.

rem ---- 1) make sure the game is closed (it locks the BG3 caches) ----
:check_game
set "GAME=0"
tasklist /fi "imagename eq bg3.exe" 2>nul    | find /i "bg3.exe"       >nul && set "GAME=1"
tasklist /fi "imagename eq bg3_dx11.exe" 2>nul | find /i "bg3_dx11.exe" >nul && set "GAME=1"
if "%GAME%"=="1" (
  echo   [!] Baldur's Gate 3 is still RUNNING - close it and try again.
  echo   [!] The game locks the LevelCache and Temp cache files.
  echo.
  pause >nul
  goto check_game
)

rem ---- 2) optionally release the NVIDIA cache lock ----
if "%KILL_PROCS%"=="1" (
  echo.
  echo   Stopping NVIDIA display helper nvsphelper64.exe ...
  taskkill /f /im nvsphelper64.exe >nul 2>&1
  echo   Done.
)

echo.
echo   --- Size BEFORE ---
call :sizes

echo.
echo   Press any key to start cleaning ...
pause >nul

rem ---- 3) clean each cache ----
call :clean "%DX%"
call :clean "%LC%"
call :clean "%TP%"
call :clean "%DS%"

echo.
echo   --- Size AFTER ---
call :sizes

echo.
echo ============================================================================
echo   Finished.
echo   Any [LOCKED] line above = that file is in use right now
echo   (usually a running app, antivirus, or the Windows indexer).
echo   Close the holder, then re-run this script to finish.
echo   Re-running is safe - already-clean folders just skip quickly.
echo ============================================================================
echo.
pause
exit /b 0

rem ============================================================================
rem  Subroutines
rem ============================================================================

rem :sizes - print current size of every target (PowerShell = locale independent)
:sizes
powershell -NoProfile -Command "$d=@('%DXP%','%LCP%','%TPP%','%DSP%'); foreach($x in $d){ if(Test-Path -LiteralPath $x){$o=Get-ChildItem -LiteralPath $x -Recurse -Force -File -ErrorAction SilentlyContinue;$c=$o.Count;$sum=($o|Measure-Object Length -Sum).Sum;$s=[math]::Round($sum/1MB,2)} else {$c=0;$s=0}; Write-Host ('   '+$x+'   :   '+$c+' files,  '+$s+' MB') }"
goto :eof

rem :clean <dir> - delete every file (incl hidden/system); report the locked ones
:clean
set "CDIR=%~1"
if not exist "%CDIR%" (
  echo.
  echo  [%CDIR%]  - not present, skipping.
  goto :eof
)
echo.
echo  Cleaning: %CDIR%
set "OK=0"
set "LOCKED=0"
for /f "delims=" %%F in ('dir /b /a-d /s "%CDIR%" 2^>nul') do (
  del /f /q "%%F" 2>nul
  if errorlevel 1 (
    set /a LOCKED+=1
    echo      [LOCKED]  %%F
  ) else (
    set /a OK+=1
  )
)
rem best-effort: remove the now-empty tree in one shot. rmdir /s walks deepest
rem first and removes all subdirs at once. If a file is still locked it just
rem stops on that branch (already reported above as [LOCKED]) - re-run after
rem closing the holder.
rmdir /s /q "%CDIR%" 2>nul
echo      Deleted %OK% file(s).  Still locked (in use): %LOCKED% file(s).
goto :eof
