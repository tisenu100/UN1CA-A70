
echo "Decoding resources if not decoded already"
DECODE_APK "system/framework/services.jar"

echo "Removing KnoxGuard"

DELETE_FROM_WORK_DIR "system" "system/priv-app/KnoxGuard"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.kgclient.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/signature-permissions-com.samsung.android.kgclient.xml"

FTP="
system/framework/services.jar/smali_classes2/com/samsung/android/knoxguard
system/framework/services.jar/smali_classes2/com/samsung/android/knoxguard30
"
for f in $FTP; do
rm -rf "$APKTOOL_DIR/$f"
done
