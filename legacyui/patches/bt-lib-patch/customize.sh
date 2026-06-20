if [ ! -f "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" ]; then
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"

    unzip -q -j "$WORK_DIR/system/system/apex/com.android.bt.apex" \
        "apex_payload.img" -d "$TMP_DIR"

    mkdir -p "$TMP_DIR/tmp_out"
    sudo mount -o ro "$TMP_DIR/apex_payload.img" "$TMP_DIR/tmp_out"
    sudo cat "$TMP_DIR/tmp_out/lib64/libbluetooth_jni.so" > "$WORK_DIR/system/system/lib64/libbluetooth_jni.so"

    sudo umount "$TMP_DIR/tmp_out"
    rm -rf "$TMP_DIR"

    SET_METADATA "system" "system/lib64/libbluetooth_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi

#https://github.com/3arthur6/BluetoothLibraryPatcher/blob/master/hexpatch.sh#L12
HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
    "97753948050037360080" "9775392a000014360080"
HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
    "97773948050037360080" "9777392a000014360080"
HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
    "3a009048050037330080" "3a00902a000014330080"
HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
    "f6713948050037330080" "f671392a000014330080"
HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
    "f6733948050037330080" "f673392a000014330080"
HEX_PATCH "$WORK_DIR/system/system/lib64/libbluetooth_jni.so" \
    "76743948050037330080" "7674392a000014330080"
