echo "Applying Adapative Brightness fix"
HEX_PATCH "$WORK_DIR/system/system/lib64/libsensorservice.so" \
    "884b00942000805202000014e0031f2a" "884b00940000805202000014e0031f2a"
echo "Adapative Brightness fix was applied successfully!"