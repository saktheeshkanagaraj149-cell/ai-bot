@echo off
rem ==================================================================
rem  AI Bot — Offline Qwen Chatbot (Windows)
rem  Double-click this file to start llama-server and open the UI.
rem ==================================================================
setlocal enabledelayedexpansion

title AI Bot - Offline Qwen Chatbot
chcp 65001 >nul 2>&1

echo.
echo ========================================
echo   AI Bot - Offline Qwen Chatbot
echo ========================================
echo.

rem ------------------------------------------------------------------
rem  Script directory = folder containing this batch file
rem ------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
if not defined SCRIPT_DIR set "SCRIPT_DIR=%CD%"

rem ------------------------------------------------------------------
rem  User override: set AI_BOT_MODEL=1.5B or 3B before running
rem  Example: set AI_BOT_MODEL=1.5B && start.bat
rem ------------------------------------------------------------------

rem ------------------------------------------------------------------
rem  Detect total physical RAM (MB) via PowerShell / WMI
rem ------------------------------------------------------------------
set "TOTAL_RAM_MB="
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "try { $m = Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum; if ($m) { [math]::Round($m.Sum / 1MB, 0) } else { 4096 } } catch { 4096 }"') do set "TOTAL_RAM_MB=%%a"
if not defined TOTAL_RAM_MB set "TOTAL_RAM_MB=4096"
rem strip possible whitespace / CR
set "TOTAL_RAM_MB=%TOTAL_RAM_MB: =%"

rem ------------------------------------------------------------------
rem  Auto-select model: 1.5B if RAM < 6 GB, else 3B
rem ------------------------------------------------------------------
if not defined AI_BOT_MODEL (
    if %TOTAL_RAM_MB% LSS 6144 (
        set "CHOSEN_MODEL=1.5B"
    ) else (
        set "CHOSEN_MODEL=3B"
    )
) else (
    set "CHOSEN_MODEL=%AI_BOT_MODEL%"
)

rem ------------------------------------------------------------------
rem  Map model choice to filename + label
rem ------------------------------------------------------------------
if /I "%CHOSEN_MODEL%"=="1.5B" (
    set "MODEL_FILE=qwen2.5-1.5b-instruct-q4_k_m.gguf"
    set "MODEL_LABEL=Qwen2.5-1.5B-Instruct  (fast, low-RAM PCs)"
) else if /I "%CHOSEN_MODEL%"=="3B" (
    set "MODEL_FILE=qwen2.5-3b-instruct-q4_k_m.gguf"
    set "MODEL_LABEL=Qwen2.5-3B-Instruct    (better quality)"
) else (
    echo ERROR: Invalid AI_BOT_MODEL "%AI_BOT_MODEL%". Use 1.5B or 3B.
    echo.
    pause
    exit /b 1
)

set "BIN_DIR=%SCRIPT_DIR%bin"
set "MODEL_PATH=%SCRIPT_DIR%models\%MODEL_FILE%"
set "UI_PATH=%SCRIPT_DIR%app\index.html"
set "SERVER_EXE=%BIN_DIR%\llama-server.exe"

rem ------------------------------------------------------------------
rem  Validate that llama-server and the model exist
rem ------------------------------------------------------------------
if not exist "%SERVER_EXE%" (
    echo ERROR: llama-server not found at %SERVER_EXE%
    echo        Place the CPU build of llama-server.exe in the bin folder.
    echo        See README.txt for download details.
    echo.
    pause
    exit /b 1
)

if not exist "%MODEL_PATH%" (
    echo ERROR: Model file not found: %MODEL_PATH%
    echo        Download the GGUF file and place it in the models folder.
    echo        See README.txt for exact filenames and download links.
    echo.
    pause
    exit /b 1
)

rem ------------------------------------------------------------------
rem  Thread count: use CPU core count, cap at 8, floor at 1
rem ------------------------------------------------------------------
set "CPU_COUNT=4"
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "[Environment]::ProcessorCount"') do set "CPU_COUNT=%%a"
set /a THREADS=%CPU_COUNT% 2>nul
if not defined THREADS set "THREADS=4"
if %THREADS% GTR 8 set "THREADS=8"
if %THREADS% LSS 1 set "THREADS=1"

echo [AI Bot] Configuration
echo [AI Bot] -------------
echo [AI Bot] Model     : %MODEL_LABEL%
echo [AI Bot] Auto-pick : based on %TOTAL_RAM_MB% MB RAM
echo [AI Bot] Threads   : %THREADS%
echo [AI Bot] Context   : 4096
echo [AI Bot] API       : http://127.0.0.1:8080
echo.

rem ------------------------------------------------------------------
rem  Kill any stale llama-server so port 8080 is free
rem ------------------------------------------------------------------
taskkill /f /im llama-server.exe >nul 2>&1
timeout /t 2 >nul

rem ------------------------------------------------------------------
rem  Start llama-server in the background (same console window)
rem ------------------------------------------------------------------
echo [AI Bot] Starting llama-server...
start /b "" "%SERVER_EXE%" -m "%MODEL_PATH%" -c 4096 -t %THREADS% --host 127.0.0.1 --port 8080

rem ------------------------------------------------------------------
rem  Wait for the server to be ready (poll /health, up to 60 seconds)
rem ------------------------------------------------------------------
echo [AI Bot] Waiting for server to be ready...
set "READY=0"
for /L %%i in (1,1,60) do (
    powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8080/health' -TimeoutSec 2 -ErrorAction Stop; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
    if !errorlevel! equ 0 (
        set "READY=1"
        goto :server_ready
    )
    timeout /t 1 >nul
)

:server_not_ready
echo.
echo [AI Bot] ERROR: Server did not become ready in time.
echo [AI Bot] Check the console window above for error messages.
echo.
pause
exit /b 1

:server_ready
echo [AI Bot] Server is ready.
echo [AI Bot] Opening %UI_PATH% in your default browser...
start "" "%UI_PATH%"

echo.
echo ========================================
echo   The bot is running in your browser.
echo   Close this command window to stop the server.
echo   Watch the console window for server output.
echo ========================================
echo.

pause
endlocal
