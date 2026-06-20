echo "Fix up /product/etc/build.prop"
sed -i "/# Removed by /d" "$WORK_DIR/system/system/product/etc/build.prop" \
    && sed -i "s/#bluetooth./bluetooth./g" "$WORK_DIR/system/system/product/etc/build.prop" \
    && sed -i "s/?=/=/g" "$WORK_DIR/system/system/product/etc/build.prop" \
    && sed -i "$(sed -n "/provisioning.hostname/=" "$WORK_DIR/system/system/product/etc/build.prop" | sed "2p;d")d" "$WORK_DIR/system/system/product/etc/build.prop"

echo "Remove unsupported permissions"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.nsflp_level_601.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.sensorhub_level40.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/init/rscmgr_a36x.rc"
