@echo off
CLS
setlocal enabledelayedexpansion
(
  set NL=^


)

CHOICE /C AHWM /M "AutoBuilder loading...!NL!1. A:Android!NL!2. H:Hashlink(Windows)!NL!3. W:Web!NL!4. M:Windows!NL!"

IF %ERRORLEVEL% EQU 1 GOTO ANDROID
IF %ERRORLEVEL% EQU 2 GOTO HASHLINK
IF %ERRORLEVEL% EQU 3 GOTO WEBSITE
IF %ERRORLEVEL% EQU 4 GOTO WINDOWS

:ANDROID
echo Understood, running autobuild_ANDROID.bat...
start "Android AutoBuild" autobuild_ANDROID.bat
GOTO END

:HASHLINK
echo Understood, running autobuild_HashLink.bat...
start "HashLink AutoBuild" autobuild_HL.bat
GOTO END

:WINDOWS
echo Understood, running autobuild_WINDOWS.bat...
start "Windows AutoBuild" autobuild_WINDOWS.bat
GOTO END

:WEBSITE
echo Understood, running autobuild_HTML5.bat...
start "Website AutoBuild" autobuild_HTML5.bat
GOTO END

:END
PAUSE