#!/bin/bash

# Clear the screen
clear

echo "AutoBuilder loading..."
echo "1. A: Android"
echo "2. H: Hashlink"
echo "3. W: Web"
echo "4. M: Windows (UNSUPPORTED ON PLATFORM)"
echo ""

# Read a single character of input
read -n 1 -p -r "Select an option: " choice
echo "" # Move to a new line after input

case "$choice" in
    [Aa])
        echo "Understood, running autobuild_ANDROID.sh..."
        chmod +x ./autobuild_ANDROID.sh
        ./autobuild_ANDROID.sh
        ;;
    [Hh])
        echo "Understood, running autobuild_HL.sh..."
        chmod +x ./autobuild_HL.sh
        ./autobuild_HL.sh
        ;;
    [Ww])
        echo "Understood, running autobuild_HTML5.sh..."
        chmod +x ./autobuild_HTML5.sh
        ./autobuild_HTML5.sh
        ;;
    *)
        echo "Invalid selection. Exiting."
        exit 1
        ;;
esac

read -p -r "Press Enter to continue..."