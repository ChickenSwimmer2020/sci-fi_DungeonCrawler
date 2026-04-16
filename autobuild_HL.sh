#!/bin/bash

clear

echo "Please wait as we switch to the git branch of Lime..."

# Attempt to install lime via git
if ! haxelib git lime https://github.com/openfl/lime; then
    echo "Something went wrong, and git failed."
    read -p -r "Press Enter to exit..."
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$0")

# Check if the native libraries directory exists
if [ -d "$SCRIPT_DIR/export/hl/obj" ]; then
    echo "Native libraries for Lime HashLink compilation already exist, continuing..."
else
    echo -e "Rebuilding Lime HashLink binaries, this will take a while. Please stand by...\n"
    
    if ! lime rebuild hl; then
        echo "Lime has failed to build HashLink. Please refer to the callstack for details."
        read -p -r "Press Enter to exit..."
        exit 1
    fi
fi

echo "Attempting launch..."
if ! lime test hashlink -debug; then
    echo "Something has gone wrong and lime failed to build."
    echo "This is a bad thing."
fi