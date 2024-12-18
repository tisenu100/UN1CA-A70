SKIPUNZIP=1

# [
ADD_TO_WORK_DIR()
{
    local PARTITION="$1"
    local FILE_PATH="$2"
    local TMP

    case "$PARTITION" in
        "system_ext")
            if $TARGET_HAS_SYSTEM_EXT; then
                FILE_PATH="system_ext/$FILE_PATH"
            else
                PARTITION="system"
                FILE_PATH="system/system/system_ext/$FILE_PATH"
            fi
        ;;
        *)
            FILE_PATH="$PARTITION/$FILE_PATH"
            ;;
    esac

    mkdir -p "$WORK_DIR/$(dirname "$FILE_PATH")"
    cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/$FILE_PATH" "$WORK_DIR/$FILE_PATH"

    TMP="$FILE_PATH"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "$TMP " "$WORK_DIR/configs/fs_config-$PARTITION"; then
            if [[ "$TMP" == "$FILE_PATH" ]]; then
                echo "$TMP $3 $4 $5 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            elif [[ "$PARTITION" == "vendor" ]]; then
                echo "$TMP 0 2000 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            else
                echo "$TMP 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-$PARTITION"
            fi
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done

    TMP="$(echo "$FILE_PATH" | sed 's/\./\\\./g')"
    [[ "$PARTITION" == "system" ]] && TMP="$(echo "$TMP" | sed 's.^system/system/.system/.')"
    while [[ "$TMP" != "." ]]
    do
        if ! grep -q "/$TMP " "$WORK_DIR/configs/file_context-$PARTITION"; then
            echo "/$TMP $6" >> "$WORK_DIR/configs/file_context-$PARTITION"
        else
            break
        fi

        TMP="$(dirname "$TMP")"
    done
}

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE/d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

echo "Prepairing..."

if [[ "$SOURCE_EXTRA_FIRMWARES" != "SM-S911"* ]]; then
    echo "Not a valid firmware to inherit"
    exit 1
fi

IFS=':' read -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
MODEL=$(echo -n "${SOURCE_EXTRA_FIRMWARES[0]}" | cut -d "/" -f 1)
REGION=$(echo -n "${SOURCE_EXTRA_FIRMWARES[0]}" | cut -d "/" -f 2)


REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib"

# Copy libraries from system... Easy
echo "Copying all valid libraries 1/2 (system)"
cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system/system/lib/"* "$WORK_DIR/system/system/lib"
cat "$FW_DIR/${MODEL}_${REGION}/fs_config-system" | grep -F "system/lib/" >> "$WORK_DIR/configs/fs_config-system"
cat "$FW_DIR/${MODEL}_${REGION}/file_context-system" | grep -F "system/lib/" >> "$WORK_DIR/configs/file_context-system"

# Copy libraries from system_ext... Hard
echo "Copying all valid libraries 2/2 (system_ext)"

mkdir $WORK_DIR/system/system/system_ext/lib
echo "system/system_ext/lib 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
echo "system/system_ext/lib u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"

cp -a --preserve=all "$FW_DIR/${MODEL}_${REGION}/system_ext/lib/"* "$WORK_DIR/system/system/system_ext/lib"

# Intentionally break the source firmwares file contexts to make our life easier
{
    sed "s/^\/system_ext/\/system\/system_ext/g" "$FW_DIR/${MODEL}_${REGION}/file_context-system_ext"
} >> "$FW_DIR/${MODEL}_${REGION}/file_context-system"

{
    sed "1d" "$FW_DIR/${MODEL}_${REGION}/fs_config-system_ext" | sed "s/^system_ext/system\/system_ext/g"
} >> "$FW_DIR/${MODEL}_${REGION}/fs_config-system"

cat "$FW_DIR/${MODEL}_${REGION}/fs_config-system" | grep -F "system/system_ext/lib" >> "$WORK_DIR/configs/fs_config-system"
cat "$FW_DIR/${MODEL}_${REGION}/file_context-system" | grep -F "system/system_ext/lib" >> "$WORK_DIR/configs/file_context-system"

#
# Real patching
#

echo "Patching linker"
ADD_TO_WORK_DIR "system" "system/apex/com.android.runtime.apex" 0 0 644 "u:object_r:system_file:s0"

echo "Adding miscellaneous System APEX components"
ADD_TO_WORK_DIR "system" "system/apex/com.android.apex.cts.shim.apex" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/apex/com.android.btservices.apex" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/apex/com.android.devicelock.apex" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/apex/com.android.i18n.apex" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/apex/com.android.rkpd.apex" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/apex/com.android.uwb.capex" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/apex/com.android.virt.apex" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/apex/com.android.vndk.current.apex" 0 0 644 "u:object_r:system_file:s0"

#
# All the patches below target mostly A52/A70 vendor
#

if [[ "$SOURCE_VNDK_VERSION" != "$TARGET_VNDK_VERSION" ]]; then
echo "Support legacy APEX"

# This might get depracated in OneUI 7 unless we use Galaxy S25's firmware
mkdir $WORK_DIR/system/system/system_ext/apex
echo "system/system_ext/apex 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
echo "system/system_ext/apex u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
fi

echo "Patching Gatekeeper"
ADD_TO_WORK_DIR "system" "system/bin/gatekeeperd" 0 2000 755 "u:object_r:gatekeeperd_exec:s0"

echo "Patching Engmode"
ADD_TO_WORK_DIR "system" "system/lib64/lib.engmode.samsung.so" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "system" "system/lib64/lib.engmodejni.samsung.so" 0 0 644 "u:object_r:system_file:s0"

echo "Patching Snap"
ADD_TO_WORK_DIR "system" "system/lib64/libsnap_aidl.snap.samsung.so" 0 0 644 "u:object_r:system_file:s0"

echo "Patching SDHMS"
ADD_TO_WORK_DIR "system" "system/priv-app/SamsungDeviceHealthManagerService/SamsungDeviceHealthManagerService.apk" 0 0 644 "u:object_r:system_file:s0"

echo "Desixtyfication complete"