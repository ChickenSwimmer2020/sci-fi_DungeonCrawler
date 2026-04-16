#!/bin/bash

echo "Installing/updating dependencies, please stand by..."

# Check if Haxe is installed
#TODO: check if this actually works ig.
if ! command -v haxe &> /dev/null; then 
    echo "Haxe is not installed."
    echo "Please wait while we attempt to install it..."
    
    # Using the official Haxe installer script for Linux
    # Note: This usually requires sudo (admin) privileges
    curl -sSL https://haxe.org/website-static/install-haxe.sh | bash
    
    # Re-check if it worked
    if ! command -v haxe &> /dev/null; then
        echo "Haxe installation failed. Please install it manually from haxe.org."
        exit 1
    fi
fi

haxe -version

# Check if Lime is installed
if ! command -v lime &> /dev/null; then
    echo "lime is not installed, please wait while we install and set it up..."
    haxelib install lime
    haxelib run lime setup
    
    # Verify lime setup
    if ! command -v lime &> /dev/null; then
        echo "We were unable to set up lime properly."
        echo "Please install and set lime up manually."
        read -p -r "Press Enter to exit..."
        exit 1
    fi
fi

echo "lime installed, running haxelibs..."

# Install specific versions
haxelib install flixel 6.1.0 --always
haxelib install flixel-ui 2.6.4 --always
haxelib install flixel-addons 3.3.2 --always
haxelib install openfl 9.5.1 --always
haxelib install hxcpp 4.3.2 --always

clear
echo "Install complete, running autobuild wrapper..."
./autobuild.sh