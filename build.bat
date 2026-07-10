@echo off
setlocal enabledelayedexpansion
(
  set NL=^


)
REM check for admin perms before anything, if we dont have it we cant install haxe therefore, abore init.
NET SESSION >NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO Requesting admin perms...
    POWERSHELL -Command "Start-Process -FilePath '%0' -Verb RunAs"
    EXIT /b
)

REM go back to position everytime, we request and gain admin access and that sets us to SYSTEM32, which is a nono folder!
CD %~dp0 
REM initial setup, EG; install haxe if not already installed, install haxelibs, so on and so forth.
ECHO Scanning for haxe...
haxe -version
IF %ERRORLEVEL% NEQ 0 (
    ECHO Haxe is not installed..
    ECHO Haxe is a required compiler for this game, would you like to install it?

    CHOICE /c YN /m "Press [Y] to install HAXE!NL!Press [N] to cancel install and abort build process"
    IF %ERRORLEVEL% EQU 1 GOTO HAXEINSTALLVALID
    IF %ERRORLEVEL% EQU 2 GOTO HAXEINSTALLABORT


    REM User said yeah to installing HAXE, continue with setup process
    :HAXEINSTALLVALID
        REM CD /D "%USERPROFILE%\Downloads"
        POWERSHELL -Command "Invoke-WebRequest https://github.com/HaxeFoundation/haxe/releases/download/4.3.7/haxe-4.3.7-win64.exe -OutFile %USERPROFILE%\Downloads\haxe-4.3.7-win64.exe"

        C:\Users\%USERNAME%\Downloads\haxe-4.3.7-win64.exe
        ECHO when you finish installing HAXE:
        PAUSE

        IF EXIST "C:/HaxeToolKit" (
            REM remove the haxe installer as its not needed anymore.
            DEL "C:\Users\%USERNAME%\Downloads\haxe-4.3.7-win64.exe"
            GOTO HAXEREADY
        ) ELSE (
            ECHO Haxe either failed to install correctly, or your computer needs to be restarted...
            ECHO Please verify that haxe was added to your PATH, and that the folder `HaxeToolKit` exists at your windows install location.
            PAUSE
            EXIT /b
        )
    REM User said no to install, so cancel the process.
    :HAXEINSTALLABORT
        CLS
        ECHO Understood!!NL!Aborting build process... 
) else (
    ECHO Haxe is installed, continuing...
    GOTO HAXEREADY
)

:HAXEREADY
GOTO INITLIME REM yeah... i know this looks stupid as fuck, but it works so who cares.


:INITLIME
REM check for lime and install it if needbe...
lime -verison
IF %ERRORLEVEL% neq 0 (
    haxelib install lime; haxelib run lime setup;
    PAUSE

    lime -version
    IF %ERRORLEVEL% neq 0 (
        ECHO Something went wrong, and lime couldnt be installed/updated...
        ECHO Please install lime manually, then try again.
    )
) ELSE (
    ECHO lime installed. setting version and continuing...
    haxelib install lime 8.3.1
    haxelib set lime 8.3.1
    ECHO Lime version installed and set to 8.3.1, continuing...
    GOTO HAXELIBS
)

:HAXELIBS
    haxelib install flixel 6.1.2
    haxelib install flixel-ui 2.6.4
    haxelib install flixel-addons 3.3.2
    haxelib install openfl 9.5.0
    haxelib install hxcpp 4.3.2
    haxelib install haxeui-core 1.7.0
    haxelib install haxeui-flixel 1.7.0
    haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc.git

    ECHO Libraries installed... loading autobuilder...
    CLS

CHOICE /C AHWM /M "AutoBuilder loaded...!NL!1. A:Android!NL!2. H:Hashlink(Windows)!NL!3. W:Web!NL!4. M:Windows!NL!"

IF %ERRORLEVEL% EQU 1 GOTO ANDROID
IF %ERRORLEVEL% EQU 2 GOTO HASHLINK
IF %ERRORLEVEL% EQU 3 GOTO WEBSITE
IF %ERRORLEVEL% EQU 4 GOTO WINDOWS

:ANDROID
    ECHO Understood, running Building selected Platform...
    GOTO ANDROIDAUTOBUILDER

:HASHLINK
    ECHO Understood, running Building selected Platform...
    GOTO HASHLINKAUTOBUILDER

:WINDOWS
    ECHO Understood, running Building selected Platform...
    GOTO WINDOWSAUTOBUILDER

:WEBSITE
    ECHO Understood, running Building selected Platform...
    GOTO HTMLAUTOBUILDER

REM autobuilders.
:ANDROIDAUTOBUILDER
    CHOICE /c YN /m Exercise caution, this BUILD system is in-depth, and requires futher setup. would you like to continue?
    IF %ERRORLEVEL% == 1 GOTO ANDROIDBUILD
    IF %ERRORLEVEL% == 2 GOTO END

    :ANDROIDBUILD
        ECHO Understood, beginning...
        ECHO Switching to git branch of lime...

        haxelib git lime https://github.com/openfl/lime
        IF %ERRORLEVEL% NEQ 0 (
            ECHO Something went wrong, and git failed.
            ECHO Please make sure Haxelib is updated, and git is installed, then try again.
            PAUSE
        )

        IF EXIST "%~dp0export/android/obj" (
            ECHO Native libraries for Lime Android compilation already exist, continuing...
            GOTO ANDROIDBUILDPROMPT
        ) ELSE (
            ECHO Rebuilding Lime android binaries, this will take a while. Please stand by...!NL!!NL!
            ECHO Excercise caution, this was tested on an Samsung Galaxy S25FE, older phones are not garenteed to work.!NL!!NL!
            lime rebuild android
            IF %ERRORLEVEL% NEQ 0 (
                ECHO Lime has failed to build android. please refer to the callstack for details.
                PAUSE
            )
        )

        :ANDROIDBUILDPROMPT
        CHOICE /C YN /M "Would you like to launch the Android Virtual Device?!NL!(If you have a physical device connected, and USB Debugging enabled. Select N now)!NL!"
        IF %ERRORLEVEL% EQU 1 GOTO AVD
        IF %ERRORLEVEL% EQU 2 GOTO APD
        GOTO ANDROIDBUILDPROMPT
        :AVD
            ECHO Attempting to launch Android Virtual Device Emulator...
            lime test android -simulator
            IF %ERRORLEVEL% NEQ 0 (
                GOTO AERR
            )
            GOTO FIN

        :APD
            ECHO Attempting physical device debug...
            ECHO Rebuilding binaries as a precaution...
            haxelib run lime rebuild android
            lime test android
            IF %ERRORLEVEL% NEQ 0 (
                GOTO AERR
            )
            GOTO FIN

        :AERR
            ECHO Something went wrong, and compilation failed. please refer to the callstack.
            pause

        :FIN
        echo Attempting launch...
        EXIT /b

:HASHLINKAUTOBUILDER
    CLS
    ECHO Running sanity check...
    haxelib set lime 8.3.1
    ECHO Building hashlink...
    lime test hashlink -debug
    EXIT /b

:WINDOWSAUTOBUILDER
    ECHO Sanity check...
    haxelib set lime 8.3.1
    ECHO Attempting build...
    lime test windows -debug
    PAUSE
    EXIT /b
:HTMLAUTOBUILDER
    ECHO Initilizing...
    REM Sanity check...
    haxelib set lime 8.3.1
    ECHO SOLAR PLEASE MAKE SURE THAT THIS WORKS NOT JUST ON MY COMPUTER.
    lime test html5
REM end of autobuilders (its indented, and stupid.)

ECHO Build complete.
PAUSE