
echo "Decoding resources if not decoded already"
DECODE_APK "system/framework/services.jar"
DECODE_APK "system/framework/framework.jar"

echo "Removing HDM Blobs"

DELETE_FROM_WORK_DIR "system" "system/priv-app/HdmApk"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.hdmapp.xml"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.tlc.hdm@1.0.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.tlc.hdm@1.1.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.tlc.hdm@1.2.so"

FTP="
system/framework/services.jar/smali/com/android/server/enterprise/hdm
system/framework/services.jar/smali_classes2/vendor/samsung/hardware/khdm
"
for f in $FTP; do
rm -rf "$APKTOOL_DIR/$f"
done

echo "Removing eSE Blobs"

DELETE_FROM_WORK_DIR "system" "system/bin/sem_daemon"
DELETE_FROM_WORK_DIR "system" "system/etc/init/sem.rc"

DELETE_FROM_WORK_DIR "system" "system/etc/framework/service-samsung-blockchain.jar"
DELETE_FROM_WORK_DIR "system" "system/lib64/blockchain_aidl_comm_client.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libtlc_blockchain_comm.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libtlc_blockchain_direct_comm.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/libtlc_blockchain_keystore.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.tlc.blockchain-V1-ndk.so"

rm -rf "$APKTOOL_DIR/system/framework/framework.jar/smali_classes6/com/android/server/SemService*.smali"
rm -rf "$APKTOOL_DIR/system/framework/services.jar/smali_classes6/com/android/server/blockchain"

echo "Removing MPOS Blobs"

DELETE_FROM_WORK_DIR "system" "system/priv-app/KnoxMposAgent"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.knox.mpos.xml"
DELETE_FROM_WORK_DIR "system" "system/lib64/libhidl_comm_mpos_tui_client.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.mpos-V1-ndk.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.tlc.mpos_tui@1.0.so"

FTP="
system/framework/services.jar/smali/com/android/server/enterprise/mpos
system/framework/services.jar/smali_classes2/vendor/samsung/hardware/mpos
"
for f in $FTP; do
rm -rf "$APKTOOL_DIR/$f"
done

echo "Adding Donor Components"
echo "Note: They're inherited from the 32-bit stack base. THIS IS NOT CLEAN"

ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "system" "system/lib64/libandroid_servers.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "system" "system/lib64/libmdf.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "system" "system/priv-app/KnoxCore/KnoxCore.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "system" "system/priv-app/KnoxZtFramework/KnoxZtFramework.apk" 0 0 644 "u:object_r:system_file:s0"
