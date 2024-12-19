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

        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".camera.samsung.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-camera.samsung.txt"
        fi
        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".arcsoft.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-arcsoft.txt"
        fi
        if [[ "$PARTITION" == "system" ]] && [[ "$FILE" == *".media.samsung.so" ]]; then
            sed -i "/$(basename "$FILE")/d" "$WORK_DIR/system/system/etc/public.libraries-media.samsung.txt"
        fi

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}
# ]

MODEL=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 1)
REGION=$(echo -n "$TARGET_FIRMWARE" | cut -d "/" -f 2)

BLOBS_LIST="
/system/lib64/libBeauty_v4.camera.samsung.so
/system/lib64/libexifa.camera.samsung.so
/system/lib64/libjpega.camera.samsung.so
/system/lib64/libOpenCv.camera.samsung.so
/system/lib64/libaifrcInterface.camera.samsung.so
/system/lib64/libVideoClassifier.camera.samsung.so
/system/lib64/libImageScreener.camera.samsung.so
/system/lib64/libMyFilter.camera.samsung.so
/system/lib64/libtflite2.myfilters.camera.samsung.so
/system/lib64/libSmartScan.camera.samsung.so
/system/lib64/libRectify.camera.samsung.so
/system/lib64/libDocRectifyWrapper.camera.samsung.so
/system/lib64/libstartrail.camera.samsung.so
/system/lib64/libUltraWideDistortionCorrection.camera.samsung.so
/system/lib64/libWideDistortionCorrection.camera.samsung.so
/system/lib64/libFace_Landmark_API.camera.samsung.so
/system/lib64/libHpr_RecGAE_cvFeature_v1.0.camera.samsung.so
/system/lib64/libHprFace_GAE_api.camera.samsung.so
/system/lib64/libFacialBasedSelfieCorrection.camera.samsung.so
/system/lib64/libHprFace_GAE_jni.camera.samsung.so
/system/lib64/libcolor_engine.camera.samsung.so
/system/lib64/libDLInterface_aidl.camera.samsung.so
/system/lib64/libImageTagger.camera.samsung.so
/system/lib64/libPetClustering.camera.samsung.so
/system/lib64/libLightObjectDetector_v1.camera.samsung.so
/system/lib64/libSceneDetector_v1.camera.samsung.so
/system/lib64/libQREngine.camera.samsung.so
/system/lib64/libEventDetector.camera.samsung.so
/system/lib64/libFood.camera.samsung.so
/system/lib64/libFoodDetector.camera.samsung.so
/system/lib64/libAEBHDR_wrapper.camera.samsung.so
/system/lib64/libdtsr_wrapper_v1.camera.samsung.so
/system/lib64/libRemasterEngine.camera.samsung.so
/system/lib64/libtensorflowlite_c.camera.samsung.so
/system/lib64/libmidas_core.camera.samsung.so
/system/lib64/libmidas_DNNInterface.camera.samsung.so
/system/lib64/libsrib_MQA.camera.samsung.so
/system/lib64/libDualCamBokehCapture.camera.samsung.so
/system/lib64/libFaceRestoration.camera.samsung.so
/system/lib64/libhybridHDR_wrapper.camera.samsung.so
/system/lib64/libAIQSolution_MPISingleRGB40.camera.samsung.so
/system/lib64/libMPISingleRGB40.camera.samsung.so
/system/lib64/libPortraitSolution.camera.samsung.so
/system/lib64/libsrib_CNNInterface.camera.samsung.so
/system/lib64/libsrib_humanaware_engine.camera.samsung.so
/system/lib64/libAIQSolution_MPI.camera.samsung.so
/system/lib64/libSwIsp_wrapper_v1.camera.samsung.so
/system/lib64/libMultiFrameProcessing30.camera.samsung.so
/system/lib64/libLocalTM_pcc.camera.samsung.so
/system/lib64/libInteractiveSegmentation.camera.samsung.so
/system/lib64/libImageCropper.camera.samsung.so
/system/lib64/libsmart_cropping.camera.samsung.so
/system/lib64/libdvs.camera.samsung.so
/system/lib64/libStride.camera.samsung.so
/system/lib64/libStrideTensorflowLite.camera.samsung.so
/system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so
/system/lib64/libtensorflowLite.camera.samsung.so
/system/lib64/libtensorflowlite_inference_api.camera.samsung.so
/system/lib64/libFace_Landmark_Engine.camera.samsung.so
/system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so
/system/lib64/libFacePreProcessing_jni.camera.samsung.so
/system/lib64/libhumantracking_util.camera.samsung.so
/system/lib64/libsec_camerax_util_jni.camera.samsung.so
/system/lib64/libsecjpeginterface.camera.samsung.so
/system/lib64/libMyFilterPlugin.camera.samsung.so
/system/lib64/libsurfaceutil.camera.samsung.so
/system/lib64/libcore2nativeutil.camera.samsung.so
/system/lib64/libsecimaging_pdk.camera.samsung.so
/system/lib64/libsecimaging.camera.samsung.so
/system/lib64/libhumantracking.arcsoft.so
/system/lib64/libPortraitDistortionCorrection.arcsoft.so
/system/lib64/libPortraitDistortionCorrectionCali.arcsoft.so
/system/lib64/libface_landmark.arcsoft.so
/system/lib64/libFacialStickerEngine.arcsoft.so
/system/lib64/libfrtracking_engine.arcsoft.so
/system/lib64/libFaceRecognition.arcsoft.so
/system/lib64/libveengine.arcsoft.so
/system/lib64/lib_pet_detection.arcsoft.so
/system/lib64/libae_bracket_hdr.arcsoft.so
/system/lib64/libdigital_tele_scope.arcsoft.so
/system/lib64/libdigital_tele_scope_rawsr.arcsoft.so
/system/lib64/libsf_tetra_enhance.arcsoft.so
/system/lib64/libhybrid_high_dynamic_range.arcsoft.so
/system/lib64/libimage_enhancement.arcsoft.so
/system/lib64/liblow_light_hdr.arcsoft.so
/system/lib64/libhigh_dynamic_range.arcsoft.so
/system/lib64/libobjectcapture_jni.arcsoft.so
/system/lib64/libobjectcapture.arcsoft.so
/system/lib64/libFacialAttributeDetection.arcsoft.so
/system/lib64/libSEF.quram.so
/system/lib64/libimagecodec.quram.so
/system/lib64/libagifencoder.quram.so
"
for blob in $BLOBS_LIST
do
    REMOVE_FROM_WORK_DIR "$WORK_DIR/system/$blob"
done

echo "Fix AI Photo Editor"
cp -a --preserve=all \
    "$FW_DIR/${MODEL}_${REGION}/system/system/cameradata/portrait_data/single_bokeh_feature.json" \
    "$WORK_DIR/system/system/cameradata/portrait_data/unica_bokeh_feature.json"
if ! grep -q "unica_bokeh_feature" "$WORK_DIR/configs/file_context-system"; then
    {
        echo "/system/cameradata/portrait_data/unica_bokeh_feature\.json u:object_r:system_file:s0"
    } >> "$WORK_DIR/configs/file_context-system"
fi
if ! grep -q "unica_bokeh_feature" "$WORK_DIR/configs/fs_config-system"; then
    {
        echo "system/cameradata/portrait_data/unica_bokeh_feature.json 0 0 644 capabilities=0x0"
    } >> "$WORK_DIR/configs/fs_config-system"
fi
sed -i "s/MODEL_TYPE_INSTANCE_CAPTURE/MODEL_TYPE_OBJ_INSTANCE_CAPTURE/g" \
    "$WORK_DIR/system/system/cameradata/portrait_data/single_bokeh_feature.json"
sed -i \
    's/system\/cameradata\/portrait_data\/single_bokeh_feature.json/system\/cameradata\/portrait_data\/unica_bokeh_feature.json\x00/g' \
    "$WORK_DIR/system/system/lib64/libPortraitSolution.camera.samsung.so"

echo "Fix MIDAS model detection"
sed -i "s/ro.product.device/ro.product.vendor.device/g" "$WORK_DIR/vendor/etc/midas/midas_config.json"
