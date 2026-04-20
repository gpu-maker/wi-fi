@echo off
title OMEGA NET MAX
mode con: cols=110 lines=35
color 0a
setlocal EnableDelayedExpansion

set logfile=omega_log.txt
set subnet=192.168.1

:: ===== AUTO DETECT SUBNET =====
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    set ip=%%a
)
for /f "tokens=1-3 delims=." %%a in ("%ip%") do (
    set subnet=%%a.%%b.%%c
)

:: ===== MENU =====
:menu
cls
echo ===========================================================
echo                    OMEGA NET MAX
echo ===========================================================
echo Subnet: %subnet%.x
echo.
echo 1. Scan Network
echo 2. Show Devices
echo 3. Analyze Device
echo 4. Latency Graph
echo 5. Port Check (Common)
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
echo Scanning %subnet%.1-50 ...
del devices.txt 2>nul

for /l %%i in (1,1,50) do (
    ping %subnet%.%%i -n 1 -w 100 >nul
)

arp -a > arp_raw.txt

for /f "tokens=1" %%a in (arp_raw.txt) do (
    echo %%a >> devices.txt
)

echo Scan complete.
pause
goto menu

:: ===== SHOW =====
:show
cls
if not exist devices.txt (
    echo No scan data.
    pause
    goto menu
)

set count=0
for /f %%a in (devices.txt) do (
    set /a count+=1
    set ip!count!=%%a
    echo !count!. %%a
)

echo.
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
for /f %%a in (devices.txt) do (
    set /a count+=1
    set ip!count!=%%a
    echo !count!. %%a
)

echo.
set /p pick=Select device:
set target=!ip%pick%!

cls
echo === ANALYZING %target% ===
echo ==== %target% ==== >> %logfile%

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
tracert %target% -h 5
tracert %target% -h 5 >> %logfile%

pause
goto menu

:: ===== LATENCY GRAPH =====
:graph
cls
set /p target=Enter IP:
echo Press CTRL+C to stop
:graphloop
for /f "tokens=7 delims== " %%a in ('ping %target% -n 1 ^| find "TTL"') do (
    set ms=%%a
    set ms=!ms:ms=!
)

set bars=
set /a count=ms/5
for /l %%i in (1,1,!count!) do set bars=!bars!#

echo %ms% ms  !bars!
goto graphloop

:: ===== PORT CHECK =====
:ports
cls
set /p target=Enter IP:

echo Checking common ports...
echo ==== PORT CHECK %target% ==== >> %logfile%

for %%p in (21 22 23 53 80 110 139 443 445 3389) do (
    (echo >nul) 2>nul <nul set /p ="Port %%p: "
    (echo quit | telnet %target% %%p >nul 2>&1) && (
        echo OPEN
        echo Port %%p OPEN >> %logfile%
    ) || (
        echo CLOSED
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
