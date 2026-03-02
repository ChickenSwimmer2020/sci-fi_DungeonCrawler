@echo off
setlocal enabledelayedexpansion
(
  set NL=^


)
echo Please make sure you have Android SDK, NDK(28.2.13676358), and JDK-21.
echo Please wait as we switch to the git branch of Lime...
haxelib git lime https://github.com/openfl/lime
if %ERRORLEVEL% neq 0 (
    echo Something went wrong, and git failed.
    echo Please make sure Haxelib is updated, and git is installed, then try again.
    pause
)
if exist "%~dp0export/android/obj" (
    echo Native libraries for Lime Android compilation already exist, continuing...
    GOTO PROMPT
) else (
    echo Rebuilding Lime android binaries, this will take a while. Please stand by...!NL!!NL!
    echo Excercise caution, this was tested on an Samsung Galaxy S25FE, older phones are not garenteed to work.!NL!!NL!
    lime rebuild android
    if %ERRORLEVEL% neq 0 (
        echo Lime has failed to build android. please refer to the callstack for details.
        pause
    )
)
:PROMPT
CHOICE /M "Would you like to launch the Android Virtual Device?!NL!(If you have a physical device connected, and USB Debugging enabled. Select N now)!NL!" /C YN
IF %ERRORLEVEL% EQU 1 GOTO AVD
IF %ERRORLEVEL% EQU 2 GOTO APD
GOTO PROMPT
:AVD
echo Attempting to launch Android Virtual Device Emulator...
lime test android -simulator
IF %ERRORLEVEL% neq 0 (
    GOTO ERR
)
GOTO FIN
:ERR
echo Something went wrong, and compilation failed. please refer to the callstack.
goto FINB
:APD
echo Attempting physical device debug...
lime test android
IF %ERRORLEVEL% neq 0 (
    GOTO ERR
)
GOTO FIN
:FINB
pause
:FIN
echo Attempting launch...
pause