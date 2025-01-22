#!/bin/bash

# Script to add `timescale 1ps / 1ps` to the first line of all .v files in the current directory

# Check if there are any .v files in the current directory
if ls *.v 1>/dev/null 2>&1; then
    for file in *.v; do
        # Add the timescale line at the top of each file
        sed -i '1i`timescale 1ps / 1ps' "$file"
        echo "Updated $file"
    done
else
    echo "No .v files found in the current directory."
fi
