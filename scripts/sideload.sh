#!/bin/sh
# Sideload the latest UN1CA build via ADB with user confirmation

set -e

# Find the latest signed UN1CA zip in the output directory
ZIP_PATH="$(find "$OUT_DIR" -maxdepth 1 -type f -name 'UN1CA_*-sign.zip' | sort | tail -n 1)"

if [ -z "$ZIP_PATH" ] || [ ! -f "$ZIP_PATH" ]; then
    echo "Error: No signed UN1CA zip found in '$OUT_DIR'." >&2
    exit 1
fi

echo "Found package:"
echo "  $ZIP_PATH"
printf "Is the device connected to the PC and in sideload mode? (y/n): "
read -r confirm

case "$confirm" in
    y|Y)
        echo "Starting ADB sideload..."
        adb sideload "$ZIP_PATH"
        ;;
    *)
        echo "Aborted."
        exit 0
        ;;
esac
