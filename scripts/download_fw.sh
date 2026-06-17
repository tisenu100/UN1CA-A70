#!/usr/bin/env bash
#
# Copyright (C) 2026 Salvo Giangreco
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

# shellcheck disable=SC2162

set -e

# [
GET_LATEST_FIRMWARE()
{
    samloader -m "$MODEL" -r "$REGION" checkupdate
}

DOWNLOAD_FIRMWARE()
{
    local PDR
    PDR="$(pwd)"

    cd "$ODIN_DIR"

    if [ ! -f "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" ]; then
	mkdir -p "$ODIN_DIR/${MODEL}_${REGION}"
        { samloader -m "$MODEL" -r "$REGION" -i "$IMEI" download -O "$ODIN_DIR/${MODEL}_${REGION}" > /dev/null; } 2>&1 \
            && touch "$ODIN_DIR/${MODEL}_${REGION}/.downloaded" \
            || exit 1

	echo "$(GET_LATEST_FIRMWARE)" > "$ODIN_DIR/${MODEL}_${REGION}/.downloaded"
    fi

    ZIP_FILE="$(find "$ODIN_DIR/${MODEL}_${REGION}" -type f \( -iname '*.zip' \) | sort -r | head -n1)"

    if [ -z "$ZIP_FILE" ]; then
        echo "No ZIP file found in $ODIN_DIR/${MODEL}_${REGION}"
        exit 1
    fi

    echo "Unpacking $(basename "$ZIP_FILE")"

    unzip -o "$ZIP_FILE" -d "$ODIN_DIR/${MODEL}_${REGION}" \
        && rm -f "$ZIP_FILE" \
        || exit 1

    if find "$ODIN_DIR/${MODEL}_${REGION}" -type f -name "AP*" | grep -q .; then
        rm -f "$ZIP_FILE"

    echo ""
    cd "$PDR"
}

RETRY_DOWNLOAD()
{
    DOWNLOAD_FIRMWARE || return 1

    if find "$DIR" -type f -iname "*.zip" | grep -q .; then
        return 1
    fi

    if ! find "$DIR" -type f -name "AP*" | grep -q .; then
        return 1
    fi
}

FIRMWARES=( "$SOURCE_FIRMWARE" )
IFS=':' read -a TARGET_FIRMWARE <<< "$TARGET_FIRMWARE"
if [ "${#TARGET_FIRMWARE[@]}" -ge 1 ]; then
    for i in "${TARGET_FIRMWARE[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
IFS=':' read -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
    for i in "${SOURCE_EXTRA_FIRMWARES[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
IFS=':' read -a TARGET_EXTRA_FIRMWARES <<< "$TARGET_EXTRA_FIRMWARES"
if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
    for i in "${TARGET_EXTRA_FIRMWARES[@]}"
    do
        FIRMWARES+=( "$i" )
    done
fi
# ]

FORCE=false

while [ "$#" != 0 ]; do
    case "$1" in
        "-f" | "--force")
            FORCE=true
            ;;
        *)
            echo "Usage: download_fw [options]"
            echo " -f, --force : Force firmware download"
            exit 1
            ;;
    esac

    shift
done

mkdir -p "$ODIN_DIR"

for i in "${FIRMWARES[@]}"
do
    MODEL=$(echo -n "$i" | cut -d "/" -f 1)
    REGION=$(echo -n "$i" | cut -d "/" -f 2)
    IMEI=$(echo -n "$i" | cut -d "/" -f 3)

    DIR="$ODIN_DIR/${MODEL}_${REGION}"

    if [ -f "$DIR/.downloaded" ] && has_ap; then
        current="$(cat "$DIR/.downloaded")"
        latest="$(GET_LATEST_FIRMWARE)"

        [ -z "$latest" ] && continue

        if [[ "$latest" != "$current" ]]; then
            if $FORCE; then
                echo "- Updating $MODEL firmware with $REGION CSC..."
                RETRY_DOWNLOAD || continue
                echo "$latest" > "$DIR/.downloaded"
            else
                echo "- $MODEL firmware with $REGION CSC already downloaded"
                echo "  A newer version of this device's firmware is available."
                echo -e "  To download, run with \"--force\"\n"
                continue
            fi
        else
            echo -e "- $MODEL firmware with $REGION CSC already downloaded\n"
            continue
        fi
    else
        echo "- Downloading $MODEL firmware with $REGION CSC..."
        RETRY_DOWNLOAD || continue
        echo "$(GET_LATEST_FIRMWARE)" > "$DIR/.downloaded"
    fi
done

exit 0
