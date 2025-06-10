DECODE_APK "system/framework/services.jar"

echo "Patching Audio"

# For compatibility purposes
FTP="
system/framework/services.jar/smali/com/android/server/audio/BtHelper\$\$ExternalSyntheticLambda0.smali
system/framework/services.jar/smali_classes2/com/android/server/vibrator/VibratorManagerService\$SamsungBroadcastReceiver\$\$ExternalSyntheticLambda1.smali
system/framework/services.jar/smali_classes2/com/android/server/vibrator/VirtualVibSoundHelper.smali
"
for f in $FTP; do
rm -rf "$APKTOOL_DIR/$f"
done
