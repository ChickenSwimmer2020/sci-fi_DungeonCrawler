@echo off
setlocal enabledelayedexpansion
(
  set NL=^


)
echo Installing/updating dependencies, please stand by...

haxe -version >nul 2>&1

if %ERRORLEVEL% neq 0 (
    echo Haxe is not installed.
    echo "Please wait while we install it (a UAC popup may appear)..."

    :: Use PowerShell to download the LATEST 4.3.4 installer (64-bit)
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/HaxeFoundation/haxe/releases/download/4.3.4/haxe-4.3.4-win64.exe' -OutFile 'haxe_installer.exe'"

    echo Installing...
    :: Start the installer with the /S (Silent) flag and wait for it to finish
    start /wait haxe_installer.exe /S

    :: Clean up
    del haxe_installer.exe

    echo Haxe installation finished. 
    echo NOTE: You may need to restart your terminal to see the 'haxe' command.
    haxe -version
) else (
    echo Haxe is already installed.
    haxe -version
)

lime
if %ERRORLEVEL% neq 0 (
    echo lime is not installed, please wait while we install and set it up...
    haxelib install lime
    haxelib run lime setup
    lime
    if %ERRORLEVEL% neq 0 (
        echo We were unable to set up lime properly
        echo Please install and set lime up manually.
        pause
    )
)
echo lime installed, running haxelibs...
haxelib install flixel 6.1.2
haxelib install flixel-ui 2.6.4
haxelib install flixel-addons 3.3.2
haxelib install openfl 9.5.0
haxelib install hxcpp 4.3.2
echo install complete running autobuild wrapper...
./autobuild.bat