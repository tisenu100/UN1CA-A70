# Parrot Board

DECODE_APK "system/framework/esecomm.jar"
DECODE_APK "system/framework/services.jar"
DECODE_APK "system/framework/ssrm.jar"
DECODE_APK "system/priv-app/SecSettings/SecSettings.apk"
DECODE_APK "system/framework/framework.jar"
DECODE_APK "system/framework/gamemanager.jar"
DECODE_APK "system/framework/secinputdev-service.jar"
DECODE_APK "system/priv-app/SettingsProvider/SettingsProvider.apk"
DECODE_APK "system_ext/priv-app/SystemUI/SystemUI.apk"

echo "Applying MAINLINE_API_LEVEL patches"
FTP="
system/framework/esecomm.jar/smali/com/sec/esecomm/EsecommAdapter.smali
system/framework/services.jar/smali/com/android/server/SystemServer.smali
system/framework/services.jar/smali/com/android/server/enterprise/hdm/HdmVendorController.smali
system/framework/services.jar/smali_classes2/com/android/server/power/PowerManagerUtil.smali
system/framework/services.jar/smali_classes2/com/android/server/sepunion/EngmodeService\$EngmodeTimeThread.smali
"
for f in $FTP; do
sed -i \
"s/\"MAINLINE_API_LEVEL: 35\"/\"MAINLINE_API_LEVEL: 30\"/g" \
"$APKTOOL_DIR/$f"
sed -i "s/\"35\"/\"30\"/g" "$APKTOOL_DIR/$f"
done


echo "Applying mDNIe features patches"
FTP="
system/framework/services.jar/smali_classes2/com/samsung/android/hardware/display/SemMdnieManagerService.smali
"
for f in $FTP; do
sed -i "s/\"37905\"/\"46097\"/g" "$APKTOOL_DIR/$f"
sed -i "s/\"3\"/\"0\"/g" "$APKTOOL_DIR/$f"
done


echo "Applying HFR_MODE patches"
FTP="
system/framework/framework.jar/smali_classes6/com/samsung/android/rune/CoreRune.smali
system/framework/framework.jar/smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali
system/framework/gamemanager.jar/smali/com/samsung/android/game/GameManagerService.smali
system/framework/secinputdev-service.jar/smali/com/samsung/android/hardware/secinputdev/SemInputDeviceManagerService.smali
system/framework/secinputdev-service.jar/smali/com/samsung/android/hardware/secinputdev/SemInputFeatures.smali
system/framework/secinputdev-service.jar/smali/com/samsung/android/hardware/secinputdev/SemInputFeaturesExtra.smali
system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali
system/priv-app/SettingsProvider/SettingsProvider.apk/smali/com/android/providers/settings/DatabaseHelper.smali
system_ext/priv-app/SystemUI/SystemUI.apk/smali/com/android/systemui/LsRune.smali
"
for f in $FTP; do
sed -i "s/\"2\"/\"0\"/g" "$APKTOOL_DIR/$f"
done


echo "Applying HFR_SUPPORTED_REFRESH_RATE patches"
FTP="
system/framework/framework.jar/smali_classes6/com/samsung/android/hardware/display/RefreshRateConfig.smali
system/priv-app/SecSettings/SecSettings.apk/smali_classes4/com/samsung/android/settings/display/SecDisplayUtils.smali
"
for f in $FTP; do
if [[ "$TARGET_HFR_SUPPORTED_REFRESH_RATE" != "none" ]]; then
sed -i "s/\"60,120\"/\"60\"/g" "$APKTOOL_DIR/$f"
else
sed -i "s/\"60,120\"/\"\"/g" "$APKTOOL_DIR/$f"
fi
done


echo "Applying SemMultiMicManager patches"
FTP="
system/framework/framework.jar/smali_classes5/com/samsung/android/camera/mic/SemMultiMicManager.smali
"
for f in $FTP; do
sed -i "s/08020/07002/g" "$APKTOOL_DIR/$f"
done

echo "Applying SSRM patches"
FTP="
system/framework/ssrm.jar/smali/com/android/server/ssrm/Feature.smali
"
for f in $FTP; do
sed -i "s/dvfs_policy_default/dvfs_policy_sm6150_xx/g" "$APKTOOL_DIR/$f"
sed -i "s/siop_a36xq_sm6475/siop_a70q_sm6150/g" "$APKTOOL_DIR/$f"
done


echo "Applying model detection patches"
FTP="
system/framework/framework.jar/smali_classes6/com/samsung/android/rune/CoreRune.smali
system/framework/services.jar/smali/com/android/server/am/FreecessController.smali
"
for f in $FTP; do
sed -i "s/ro\.product\.model/ro\.product\.vendor\.model/g" "$APKTOOL_DIR/$f"
done
