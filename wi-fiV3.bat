@echo off
title OMEGA NET ELITE
mode con: cols=120 lines=35
color 0a
setlocal EnableDelayedExpansion

set logfile=omega_log.txt

:: ===== GET IP + SUBNET =====
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do set ip=%%a
set ip=%ip: =%

for /f "tokens=1-3 delims=." %%a in ("%ip%") do set subnet=%%a.%%b.%%c

:: ===== GET GATEWAY =====
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "Default Gateway"') do set gw=%%a
set gw=%gw: =%

:: ===== MENU =====
:menu
cls
echo ===============================================================
echo                    OMEGA NET ELITE
echo ===============================================================
echo IP: %ip%     Gateway: %gw%
echo Subnet: %subnet%.x
echo.
echo 1. Scan Network
echo 2. Show Devices (Table)
echo 3. Analyze Device
echo 4. Latency Graph
echo 5. Port Check
echo 6. Live Monitor
echo 7. View Logs
echo 8. Exit
echo.
set /p choice=Select:

if "%choice%"=="1" goto scan
if "%choice%"=="2" goto show
if "%choice%"=="3" goto analyze
if "%choice%"=="4" goto graph
if "%choice%"=="5" goto ports
if "%choice%"=="6" goto monitor
if "%choice%"=="7" goto logs
if "%choice%"=="8" exit
goto menu

:: ===== SCAN =====
:scan
cls
echo Scanning %subnet%.1-100 ...

del devices.txt 2>nul

for /l %%i in (1,1,100) do (
    ping %subnet%.%%i -n 1 -w 60 >nul
)

arp -a | findstr "%subnet%." > raw.txt

:: remove duplicates + store IP + MAC
for /f "tokens=1,2" %%a in (raw.txt) do (
    find "%%a" devices.txt >nul 2>nul || echo %%a %%b >> devices.txt
)

echo Scan complete.
pause
goto menu

:: ===== SHOW TABLE =====
:show
cls
if not exist devices.txt (
    echo No scan data.
    pause
    goto menu
)

echo ===============================================================
echo #    IP ADDRESS        MAC ADDRESS
echo ===============================================================

set count=0
for /f "tokens=1,2" %%a in (devices.txt) do (
    set /a count+=1
    set ip!count!=%%a
    echo !count!    %%a     %%b
)

echo ===============================================================
echo Total: !count!
pause
goto menu

:: ===== ANALYZE =====
:analyze
cls
if not exist devices.txt (
    echo Run scan first.
    pause
    goto menu
)

set count=0
for /f "tokens=1,2" %%a in (devices.txt) do (
    set /a count+=1
    set ip!count!=%%a
    echo !count!. %%a
)

echo.
set /p pick=Select device:
set target=!ip%pick%!

if "%target%"=="" (
    echo Invalid selection
    pause
    goto menu
)

cls
echo ================= ANALYSIS =================
echo Target: %target%
echo ==========================================

echo ==== %date% %time% %target% ==== >> %logfile%

ping %target% -n 2 > ping.txt
find "TTL=" ping.txt >nul

if %errorlevel%==0 (
    echo Status: ONLINE
    echo Status: ONLINE >> %logfile%
) else (
    echo Status: OFFLINE
    echo Status: OFFLINE >> %logfile%
)

type ping.txt
type ping.txt >> %logfile%

echo.
echo --- ROUTE ---
tracert %target% -h 5
tracert %target% -h 5 >> %logfile%

echo.
echo --- DNS ---
nslookup %target% 2>nul
nslookup %target% >> %logfile%

pause
goto menu

:: ===== LATENCY GRAPH =====
:graph
cls
set /p target=Enter IP:
echo Press CTRL+C to stop

:loopgraph
for /f "tokens=6 delims== " %%a in ('ping %target% -n 1 ^| find "time="') do set ms=%%a
set ms=%ms:ms=%

set bars=
set /a count=ms/4
for /l %%i in (1,1,!count!) do set bars=!bars!#

echo %ms% ms  !bars!
goto loopgraph

:: ===== PORT CHECK =====
:ports
cls
set /p target=Enter IP:

echo ==== PORT CHECK %date% %time% %target% ==== >> %logfile%

for %%p in (21 22 53 80 139 443 445 3389) do (
    echo Checking port %%p...
    powershell -Command "Test-NetConnection %target% -Port %%p -WarningAction SilentlyContinue" | find "True" >nul && (
        echo Port %%p OPEN
        echo Port %%p OPEN >> %logfile%
    ) || (
        echo Port %%p CLOSED
    )
)

pause
goto menu

:: ===== MONITOR =====
:monitor
cls
set /p target=Enter IP:
echo Monitoring %target% (CTRL+C to stop)

:loop
ping %target% -n 1
goto loop

:: ===== LOGS =====
:logs
cls
if exist %logfile% (
    type %logfile%
) else (
    echo No logs yet.
)
pause
goto menu
