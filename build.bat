@echo off
setlocal enabledelayedexpansion
(
  set NL=^


)
echo Installing/updating dependencies, please stand by...
haxe -version
if %ERRORLEVEL% neq 0 (
    echo Haxe is not installed.
    echo Please install haxe from https://haxe.org then try again.
    pause
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
haxelib install openfl 9.5.1
haxelib install hxcpp 4.3.2
echo install complete running autobuild wrapper...
./autobuild.bat