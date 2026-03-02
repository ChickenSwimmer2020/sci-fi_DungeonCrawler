@echo off
setlocal enabledelayedexpansion
(
  set NL=^


)
echo Please wait as we switch to the git branch of Lime...
haxelib git lime https://github.com/openfl/lime
if %ERRORLEVEL% neq 0 (
    echo Something went wrong, and git failed.
    echo Please make sure Haxelib is updated, and git is installed, then try again.
    pause
)
if exist "%~dp0export/hl/obj" (
    echo Native libraries for Lime HashLink compilation already exist, continuing...
    GOTO LAUNCH
) else (
    echo Rebuilding Lime HashLink binaries, this will take a while. Please stand by...!NL!!NL!
    lime rebuild hl
    if %ERRORLEVEL% neq 0 (
        echo Lime has failed to build HashLink. please refer to the callstack for details.
        pause
    )
    GOTO LAUNCH
)
:LAUNCH
echo Attempting launch...
lime test hashlink