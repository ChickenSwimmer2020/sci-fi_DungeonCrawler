#!/bin/bash

# Clear the screen
clear

echo "Attempting build... (Lime does not need to be compiled for HTML Binaries. [I think])"
echo "If this returns errors, please make me aware."
echo "SOLAR PLEASE MAKE SURE THAT THIS WORKS NOT JUST ON MY COMPUTER."

if ! lime test html5 -debug; then
    echo "something has gone wrong, and lime failed."
    echo "this is a bad thing."
fi