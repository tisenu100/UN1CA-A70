# [
ADD_TO_WORK_DIR_CONTEXT()
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
# ]

echo "Installing FM Radio"

# Un1ca's build system handles that one

echo "Setting up contexts"

CONTEXTS_LIST="
system/lib/libfmradio_jni.so
system/system_ext/lib/fm_helium.so
system/system_ext/lib/vendor.qti.hardware.fm@1.0.so
system/system_ext/lib/libfm-hci.so
system/lib64/libfmradio_jni.so
system/system_ext/lib64/fm_helium.so
system/system_ext/lib64/vendor.qti.hardware.fm@1.0.so
system/system_ext/lib64/libfm-hci.so
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "system" "$context" 0 0 644 "u:object_r:system_lib_file:s0"
done

CONTEXTS_LIST="
system/etc/permissions/privapp-permissions-com.sec.android.app.fm.xml
system/etc/sysconfig/preinstalled-packages-com.sec.android.app.fm.xml
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "system" "$context" 0 0 644 "u:object_r:system_lib_file:s0"
done

ADD_TO_WORK_DIR_CONTEXT "system" "system/priv-app/HybridRadio" 0 0 755 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR_CONTEXT "system" "system/priv-app/HybridRadio/HybridRadio.apk" 0 0 644 "u:object_r:system_file:s0"

echo "FM Radio was installed successfully!"
