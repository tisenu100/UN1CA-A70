#!/bin/bash
#
# Copyright (C) 2023 BlackMesa123
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

set -e

# [
SRC_DIR="$(git rev-parse --show-toplevel)"
OUT_DIR="$SRC_DIR/out"

source "$SRC_DIR/target/$1/config.sh"

GEN_CONFIG_FILE()
{
    [ -f "$OUT_DIR/config.sh" ] && rm "$OUT_DIR/config.sh"

    echo "# Automatically generated by unica/config.sh" >> "$OUT_DIR/config.sh"
    echo "API_LEVEL=$API_LEVEL" >> "$OUT_DIR/config.sh"
    echo -n "FIRMWARES=( " >> "$OUT_DIR/config.sh"
    [ -n "$BASE_FIRMWARE" ] && echo -n "\"$BASE_FIRMWARE\" " >> "$OUT_DIR/config.sh"
    for i in "${DEVICE_FIRMWARES[@]}"
    do
        echo -n "\"$i\" " >> "$OUT_DIR/config.sh"
    done
    echo ")" >> "$OUT_DIR/config.sh"
}
# ]

# Current API level
API_LEVEL=34

# Base ROM firmware
# Qualcomm: Galaxy S23
if [[ "$SINGLE_SYSTEM_IMAGE" == "qssi" ]]; then
    BASE_FIRMWARE="SM-S911B/EUX"
else
    echo "\"$SINGLE_SYSTEM_IMAGE\" is not a valid system image."
    exit 1
fi

GEN_CONFIG_FILE

exit 0
