SKIPUNZIP=1

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
}

REMOVE_FROM_WORK_DIR()
{
    local FILE_PATH="$1"

    if [ -e "$FILE_PATH" ] || [ -L "$FILE_PATH" ]; then
        local FILE
        local PARTITION
        FILE="$(echo -n "$FILE_PATH" | sed "s.$WORK_DIR/..")"
        PARTITION="$(echo -n "$FILE" | cut -d "/" -f 1)"

        echo "Debloating /$FILE"
        rm -rf "$FILE_PATH"

        [[ "$PARTITION" == "system" ]] && FILE="$(echo "$FILE" | sed 's.^system/system/.system/.')"
        FILE="$(echo -n "$FILE" | sed 's/\//\\\//g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/fs_config-$PARTITION"

        FILE="$(echo -n "$FILE" | sed 's/\./\\\\\./g')"
        sed -i "/$FILE /d" "$WORK_DIR/configs/file_context-$PARTITION"
    fi
}

SET_PROP()
{
    local PROP="$1"
    local VALUE="$2"
    local FILE="$3"

    if [ ! -f "$FILE" ]; then
        echo "File not found: $FILE"
        return 1
    fi

    if [[ "$2" == "-d" ]] || [[ "$2" == "--delete" ]]; then
        PROP="$(echo -n "$PROP" | sed 's/=//g')"
        if grep -Fq "$PROP" "$FILE"; then
            echo "Deleting \"$PROP\" prop in $FILE" | sed "s.$WORK_DIR..g"
            sed -i "/^$PROP/d" "$FILE"
        fi
    else
        if grep -Fq "$PROP" "$FILE"; then
            local LINES

            echo "Replacing \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            LINES="$(sed -n "/^${PROP}\b/=" "$FILE")"
            for l in $LINES; do
                sed -i "$l c${PROP}=${VALUE}" "$FILE"
            done
        else
            echo "Adding \"$PROP\" prop with \"$VALUE\" in $FILE" | sed "s.$WORK_DIR..g"
            if ! grep -q "Added by scripts" "$FILE"; then
                echo "# Added by scripts/internal/apply_modules.sh" >> "$FILE"
            fi
            echo "$PROP=$VALUE" >> "$FILE"
        fi
    fi
}
# ]

echo "A70 System Adaptor"

# We wipe the A52 blobs we don't need
echo "Remove A52 blobs"

#NFC
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/bin/hw/sec.android.hardware.nfc@1.2-service"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/firmware/nfc/sec_s3nrn4v_firmware.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/init/sec.android.hardware.nfc@1.2-service.rc"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/libnfc-sec-vendor.conf"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/nfc/sec_s3nrn4v_hwreg.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/nfc/sec_s3nrn4v_swreg.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/vendor.samsung.hardware.nfc@2.0.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/nfc_nci_sec.so"

#fstab
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/fstab.default"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/fstab.emmc"

#Sensors
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/atoll_default_sensors.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/atoll_dynamic_sensors.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/atoll_lsm6dso_0.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/atoll_qrd_ak991x_0.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/atoll_qrd_ak991x_2.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/atoll_qrd_ak991x_6.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/atoll_qrd_lsm6dso_0.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/atoll_qrd_stk31610_0.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_amd.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_amd_sw_disabled.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_amd_sw_enabled.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_aont.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_basic_gestures.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_bring_to_ear.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_ccd.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_ccd_v2_walk.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_ccd_v3_1_walk.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_ccd_v3_walk.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_cm.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_dae.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_device_orient.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_diag_filter.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_distance_bound.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_dpc.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_facing.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_fmv.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_geomag_rv.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_gyro_cal.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_heart_rate.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_mag_cal.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_mag_cal_legacy.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_multishake.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_pedometer.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_rmd.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_rotv.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_smd.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_tilt.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_tilt_sw_disabled.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_tilt_sw_enabled.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_tilt_to_wake.json"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/etc/sensors/config/sns_wrist_pedo.json"

#Camera
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.tuned.lsi_gc5035.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/uw_dual_calibration.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.2_0_lsi_s5k3l6.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensor.gc5035.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.tuned.lsi_s5kgd2.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.tuned.sony_imx682.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.tuned.sony_imx616.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.qti.eeprom.sec2qcconversion.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensor.s5kgw1p.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.1_0_sony_imx616.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.3_lsi_gc5035.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.4_0_lsi_gc5035_macro.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.8_1_lsi_s5kgd2_full_otp.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.1_1_lsi_s5kgd2_otp.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.0_1_lsi_s5kgw1p_otp.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.tuned.hynix_hi1336.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/f_dual_calibration.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensor.s5k3l6.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensor.imx682.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.0_1_lsi_s5kgw1p.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensor.imx616.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.4_1_lsi_dv_gc5035_macro_hw_2.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.afd.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.fcv.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.awb.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.gpu.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.aec.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.haf.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/libdepthmapwrapper.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qtistatic.stats.aec.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.eisv2.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.uniplugin_recording.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.stich.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.realtimebokeh.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.bayerfuse.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.capture_fusion.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qtistatic.stats.awb.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.wrapper.stats.af.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.smooth_transition.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.uniplugin_capture.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.bayercheck.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/libMOTION.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.wrapper.stats.pdlib.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.capture_bokeh.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.asd.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qtistatic.stats.af.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.uniplugin_vdis.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.eisv3.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.uniplugin_preview.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.dummyrtb.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.eisv3.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.camx.chiiqutils.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.swregistration.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.depth.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.eisv2.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.wrapper.stats.awb.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.wrapper.stats.aec.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.pdlibwrapper.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.memcpy.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.samsung.node.remosaic.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.af.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.node.dummysat.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.pdlibsony.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qtistatic.stats.pdlib.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.hafoverride.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/components/com.qti.stats.pdlib.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.tuned.lsi_s5k3l6.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/w_dual_calibration.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.qti.eeprom.n24s64b_imx616.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensor.hi1336.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensor.s5kgd2.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/ois_mcu_stm32g_fw.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.2_1_hynix_hi1336.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensor.gc5035_macro.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.8_0_sony_imx616_full.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.tuned.lsi_s5kgw1p.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.1_1_lsi_s5kgd2.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.8_1_lsi_s5kgd2_full.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.tuned.lsi_gc5035_macro.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib/camera/com.samsung.sensormodule.0_0_sony_imx682.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.tuned.lsi_gc5035.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.2_0_lsi_s5k3l6.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensor.gc5035.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.tuned.lsi_s5kgd2.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.tuned.sony_imx682.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.tuned.sony_imx616.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.qti.eeprom.sec2qcconversion.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensor.s5kgw1p.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.1_0_sony_imx616.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.3_lsi_gc5035.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.4_0_lsi_gc5035_macro.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.8_1_lsi_s5kgd2_full_otp.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.1_1_lsi_s5kgd2_otp.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.0_1_lsi_s5kgw1p_otp.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.tuned.hynix_hi1336.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensor.s5k3l6.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensor.imx682.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.0_1_lsi_s5kgw1p.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensor.imx616.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.4_1_lsi_dv_gc5035_macro_hw_2.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.stats.afd.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.fcv.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.gpu.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/libdepthmapwrapper.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qtistatic.stats.aec.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.eisv2.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.stich.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.samsung.node.realtimebokeh.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.samsung.node.bayerfuse.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.samsung.node.capture_fusion.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qtistatic.stats.awb.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.wrapper.stats.af.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.samsung.node.smooth_transition.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.samsung.node.bayercheck.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.wrapper.stats.pdlib.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.samsung.node.capture_bokeh.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.stats.asd.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qtistatic.stats.af.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.eisv3.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.dummyrtb.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.eisv3.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.camx.chiiqutils.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.swregistration.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.depth.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.eisv2.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.wrapper.stats.awb.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.wrapper.stats.aec.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.stats.pdlibwrapper.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.memcpy.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.samsung.node.remosaic.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.node.dummysat.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.stats.pdlibsony.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qtistatic.stats.pdlib.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/components/com.qti.stats.hafoverride.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.tuned.lsi_s5k3l6.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.qti.eeprom.n24s64b_imx616.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensor.hi1336.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensor.s5kgd2.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.2_1_hynix_hi1336.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensor.gc5035_macro.so"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.8_0_sony_imx616_full.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.tuned.lsi_s5kgw1p.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.1_1_lsi_s5kgd2.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.8_1_lsi_s5kgd2_full.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.tuned.lsi_gc5035_macro.bin"
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/lib64/camera/com.samsung.sensormodule.0_0_sony_imx682.bin"

# Take down System now
echo "Remove System Blobs"
REMOVE_FROM_WORK_DIR "$WORK_DIR/product/overlay/framework-res__auto_generated_rro_product.apk"
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/system/lib64/lib_SoundBooster_ver2000.so"

# Copy the blobs
echo "Installing A70 drivers"
cp -r $SRC_DIR/target/a70q/patches/restructor/A705FN/* $WORK_DIR

# SELinux and prop config
echo "Configuring properties"
CONTEXTS_LIST="
lib/libmpbase.so
lib/libcom.qti.chinodeutils.so
lib/libcdfw.so
lib/liblocation_api.so
lib/libdrmtime.so
lib/libegis_fp_normal_sensor_test.so
lib/liblocationservice.so
lib/libuniplugin.so
lib/libgeofencing.so
lib/libswvdec.so
lib/liboemcrypto.so
lib/libsmartfocusengine.so
lib/libtzdrmgenprov.so
lib/android.hardware.camera.provider@2.4-legacy.so
lib/vendor.qti.gnss@1.2.so
lib/camera.device@1.0-impl.so
lib/libdualcam_refocus_image.so
lib/vendor.qti.gnss@2.0.so
lib/hw/vendor.samsung.hardware.camera.provider@4.0-impl.so
lib/hw/camera.qcom.so
lib/hw/com.samsung.chi.override.so
lib/hw/android.hardware.gnss@2.1-impl-qti.so
lib/hw/vendor.samsung.hardware.gnss@2.0-impl-sec.so
lib/hw/audio.primary.atoll.so
lib/vendor.samsung.hardware.camera.device@5.0.so
lib/mediadrm/libwvdrmengine.so
lib/vendor.samsung.hardware.camera.device@5.0-impl.so
lib/libwvhidl.so
lib/libllhdr_interface.so
lib/libgnss.so
lib/libjpegQtable_interface.so
lib/libsaiv_BeautySolutionVideo.so
lib/libDualCamBokehCapture.camera.samsung.so
lib/camera/uw_dual_calibration.bin
lib/camera/com.samsung.sensor.gc5035.so
lib/camera/com.samsung.sensormodule.3_lsi_gc5035.bin
lib/camera/com.samsung.tuned.s5k4ha.bin
lib/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_dv.bin
lib/camera/f_dual_calibration.bin
lib/camera/com.samsung.sensormodule.0_lsi_s5kgd1_pv_OLD.bin
lib/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_pv_OLD.bin
lib/camera/components/com.qti.stats.afd.so
lib/camera/components/com.qti.node.fcv.so
lib/camera/components/com.qti.stats.awb.so
lib/camera/components/com.qti.node.gpu.so
lib/camera/components/com.qti.stats.aec.so
lib/camera/components/com.qti.stats.haf.so
lib/camera/components/libdepthmapwrapper.so
lib/camera/components/com.qtistatic.stats.aec.so
lib/camera/components/com.qti.eisv2.so
lib/camera/components/libmmcamera_cac3.so
lib/camera/components/com.samsung.node.uniplugin_recording.so
lib/camera/components/com.qti.node.stich.so
lib/camera/components/com.samsung.node.realtimebokeh.so
lib/camera/components/com.samsung.node.bayerfuse.so
lib/camera/components/com.samsung.node.capture_fusion.so
lib/camera/components/com.qtistatic.stats.awb.so
lib/camera/components/com.wrapper.stats.af.so
lib/camera/components/com.samsung.node.smooth_transition.so
lib/camera/components/com.samsung.node.uniplugin_capture.so
lib/camera/components/com.samsung.node.bayercheck.so
lib/camera/components/com.wrapper.stats.pdlib.so
lib/camera/components/com.samsung.node.capture_bokeh.so
lib/camera/components/com.qti.stats.asd.so
lib/camera/components/com.qtistatic.stats.af.so
lib/camera/components/com.samsung.node.uniplugin_vdis.so
lib/camera/components/com.qti.eisv3.so
lib/camera/components/com.samsung.node.uniplugin_preview.so
lib/camera/components/com.qti.node.dummyrtb.so
lib/camera/components/com.qti.node.eisv3.so
lib/camera/components/com.qti.camx.chiiqutils.so
lib/camera/components/com.qti.node.swregistration.so
lib/camera/components/com.qti.node.depth.so
lib/camera/components/com.qti.node.eisv2.so
lib/camera/components/com.wrapper.stats.awb.so
lib/camera/components/com.wrapper.stats.aec.so
lib/camera/components/com.qti.stats.pdlibwrapper.so
lib/camera/components/com.qti.node.memcpy.so
lib/camera/components/com.samsung.node.remosaic.so
lib/camera/components/com.qti.stats.af.so
lib/camera/components/com.qti.node.dummysat.so
lib/camera/components/com.qti.stats.pdlibsony.so
lib/camera/components/com.qtistatic.stats.pdlib.so
lib/camera/components/com.qti.stats.hafoverride.so
lib/camera/components/com.qti.stats.pdlib.so
lib/camera/com.samsung.sensor.s5kgd1_front.so
lib/camera/w_dual_calibration.bin
lib/camera/com.samsung.sensor.s5k4ha.so
lib/camera/com.samsung.tuned.s5kgd1_front.bin
lib/camera/com.samsung.tuned.s5kgd1.bin
lib/camera/com.samsung.sensormodule.2_lsi_s5k4ha.bin
lib/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_pv_NEW.bin
lib/camera/com.samsung.sensormodule.0_lsi_s5kgd1_pv_NEW.bin
lib/camera/com.samsung.sensor.s5kgd1.so
lib/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_dv.bin
lib/camera/com.samsung.sensormodule.0_lsi_s5kgd1_dv.bin
lib/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_pv_NEW.bin
lib/camera/com.samsung.tuned.gc5035.bin
lib/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_pv_OLD.bin
lib/libcamxstatscore.so
lib/libcpion.so
lib/android.hardware.camera.provider@2.5-legacy.so
lib/libswregistrationalgo.so
lib/libsmartfocus_interface.so
lib/libjnihelper.so
lib/libloc_socket.so
lib/libcamxswprocessalgo.so
lib/libfloatingfeature.so
lib/libbatching.so
lib/libgarden.so
lib/libloc_core.so
lib/liblbs_core.so
lib/liblivefocus_capture_engine.so
lib/vendor.qti.gnss@1.1.so
lib/libchiss3alogdebug.so
lib/libcamxfdengine.so
lib/libizat_client_api.so
lib/libpvr.so
lib/libgnsspps.so
lib/camera.device@3.3-impl.so
lib/libqfp_sensortest.so
lib/libbauthtzcommon.so
lib/camera.device@3.5-impl.so
lib/libsns_device_mode_stub.so
lib/libqti_vndfwk_detect.so
lib/libloc_api_v02.so
lib/liblow_light_hdr.so
lib/libsnsapi.so
lib/libgf_in_system_lib.so
lib/libdualcam_optical_zoom.so
lib/libOpenCv.camera.samsung.so
lib/camera.device@3.2-impl.so
lib/camera.device@3.4-impl.so
lib/vendor.qti.hardware.camera.device@1.0.so
lib/libdualcam_optical_zoom_control.so
lib/libcdfw_remote_api.so
lib/libsns_fastRPC_util.so
lib/libcamera_nn_stub.so
lib/libdualcam_refocus_video.so
lib/libcamxfdalgov8.so
lib/libgps.utils.so
lib/vendor.samsung.hardware.camera.provider@4.0.so
lib/vendor.samsung.hardware.camera.provider@4.0-legacy.so
lib/vendor.qti.gnss@2.1.so
lib/liblowi_client.so
lib/libc++_shared.so
lib/libcppf.so
lib/liblivefocus_preview_interface.so
lib/libizat_core.so
lib/libFacePreProcessing.camera.samsung.so
lib/libcamxtintlessalgo.so
lib/vendor.qti.gnss@3.0.so
lib/vendor.samsung.hardware.gnss@2.0.so
lib/vendor.qti.gnss@1.0.so
lib/libdataitems.so
lib/vendor.qti.gnss@4.0.so
lib/libbauthserver.so
lib/libdrmfs.so
lib/libdualcapture.so
lib/libcamxfdalgov7.so
lib/libsynaFpSensorTestNwd.so
lib/libsns_low_lat_stream_stub.so
lib/liblivefocus_capture_interface.so
lib/libqcwrappercommon.so
lib/liblocationservice_glue.so
lib/liblivefocus_preview_engine.so
lib64/libmpbase.so
lib64/libcom.qti.chinodeutils.so
lib64/libcdfw.so
lib64/libsnpe_wrapper.so
lib64/liblocation_api.so
lib64/libdrmtime.so
lib64/libegis_fp_normal_sensor_test.so
lib64/liblocationservice.so
lib64/libuniplugin.so
lib64/libgeofencing.so
lib64/libswvdec.so
lib64/liboemcrypto.so
lib64/libsmartfocusengine.so
lib64/libtzdrmgenprov.so
lib64/android.hardware.camera.provider@2.4-legacy.so
lib64/libSNPE.so
lib64/vendor.qti.gnss@1.2.so
lib64/camera.device@1.0-impl.so
lib64/libdualcam_refocus_image.so
lib64/vendor.qti.gnss@2.0.so
lib64/hw/vendor.samsung.hardware.camera.provider@4.0-impl.so
lib64/hw/camera.qcom.so
lib64/hw/com.samsung.chi.override.so
lib64/hw/android.hardware.gnss@2.1-impl-qti.so
lib64/hw/vendor.samsung.hardware.gnss@2.0-impl-sec.so
lib64/vendor.samsung.hardware.camera.device@5.0.so
lib64/vendor.samsung.hardware.camera.device@5.0-impl.so
lib64/vendor.samsung.hardware.security.widevine.keyprov@1.0.so
lib64/libgnss.so
lib64/libLocalTM_preview_core.so
lib64/libjpegQtable_interface.so
lib64/libDLInterface.camera.samsung.so
lib64/libDualCamBokehCapture.camera.samsung.so
lib64/libremosaiclib.so
lib64/camera/com.samsung.sensor.gc5035.so
lib64/camera/com.samsung.sensormodule.3_lsi_gc5035.bin
lib64/camera/com.samsung.tuned.s5k4ha.bin
lib64/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_dv.bin
lib64/camera/com.samsung.sensormodule.0_lsi_s5kgd1_pv_OLD.bin
lib64/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_pv_OLD.bin
lib64/camera/components/com.qti.stats.afd.so
lib64/camera/components/com.qti.node.fcv.so
lib64/camera/components/com.qti.node.gpu.so
lib64/camera/components/libdepthmapwrapper.so
lib64/camera/components/com.qtistatic.stats.aec.so
lib64/camera/components/com.qti.eisv2.so
lib64/camera/components/libmmcamera_cac3.so
lib64/camera/components/com.qti.node.stich.so
lib64/camera/components/com.samsung.node.realtimebokeh.so
lib64/camera/components/com.samsung.node.bayerfuse.so
lib64/camera/components/com.samsung.node.capture_fusion.so
lib64/camera/components/com.qtistatic.stats.awb.so
lib64/camera/components/com.wrapper.stats.af.so
lib64/camera/components/com.samsung.node.smooth_transition.so
lib64/camera/components/com.samsung.node.bayercheck.so
lib64/camera/components/com.wrapper.stats.pdlib.so
lib64/camera/components/com.samsung.node.capture_bokeh.so
lib64/camera/components/com.qti.stats.asd.so
lib64/camera/components/com.qtistatic.stats.af.so
lib64/camera/components/com.qti.eisv3.so
lib64/camera/components/com.qti.node.dummyrtb.so
lib64/camera/components/com.qti.node.eisv3.so
lib64/camera/components/com.qti.camx.chiiqutils.so
lib64/camera/components/com.qti.node.swregistration.so
lib64/camera/components/com.qti.node.depth.so
lib64/camera/components/com.qti.node.eisv2.so
lib64/camera/components/com.wrapper.stats.awb.so
lib64/camera/components/com.wrapper.stats.aec.so
lib64/camera/components/com.qti.stats.pdlibwrapper.so
lib64/camera/components/com.qti.node.memcpy.so
lib64/camera/components/com.samsung.node.remosaic.so
lib64/camera/components/com.qti.node.dummysat.so
lib64/camera/components/com.qti.stats.pdlibsony.so
lib64/camera/components/com.qtistatic.stats.pdlib.so
lib64/camera/components/com.qti.stats.hafoverride.so
lib64/camera/com.samsung.sensor.s5kgd1_front.so
lib64/camera/com.samsung.sensor.s5k4ha.so
lib64/camera/com.samsung.tuned.s5kgd1_front.bin
lib64/camera/com.samsung.tuned.s5kgd1.bin
lib64/camera/com.samsung.sensormodule.2_lsi_s5k4ha.bin
lib64/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_pv_NEW.bin
lib64/camera/com.samsung.sensormodule.0_lsi_s5kgd1_pv_NEW.bin
lib64/camera/com.samsung.sensor.s5kgd1.so
lib64/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_dv.bin
lib64/camera/com.samsung.sensormodule.0_lsi_s5kgd1_dv.bin
lib64/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_pv_NEW.bin
lib64/camera/com.samsung.tuned.gc5035.bin
lib64/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_pv_OLD.bin
lib64/libcamxstatscore.so
lib64/libcpion.so
lib64/android.hardware.camera.provider@2.5-legacy.so
lib64/libswregistrationalgo.so
lib64/libsmartfocus_interface.so
lib64/libFacialStickerEngine.arcsoft.so
lib64/libjnihelper.so
lib64/libcamxswprocessalgo.so
lib64/libfloatingfeature.so
lib64/libbatching.so
lib64/libgarden.so
lib64/liblbs_core.so
lib64/liblivefocus_capture_engine.so
lib64/libhigh_dynamic_range_bokeh.so
lib64/vendor.qti.gnss@1.1.so
lib64/vendor.nxp.nxpnfc@1.1.so
lib64/libchiss3alogdebug.so
lib64/libcamxfdengine.so
lib64/libizat_client_api.so
lib64/libpvr.so
lib64/libgnsspps.so
lib64/camera.device@3.3-impl.so
lib64/libqfp_sensortest.so
lib64/libbauthtzcommon.so
lib64/camera.device@3.5-impl.so
lib64/libsns_device_mode_stub.so
lib64/libqti_vndfwk_detect.so
lib64/libqdma_file_agent.so
lib64/liblow_light_hdr.so
lib64/libsnsapi.so
lib64/libgf_in_system_lib.so
lib64/libLocalTM_capture_core.camera.samsung.so
lib64/libdualcam_optical_zoom.so
lib64/libOpenCv.camera.samsung.so
lib64/libsnpe_dsp_domains_v2.so
lib64/nfc_nci_nxp.so
lib64/camera.device@3.2-impl.so
lib64/camera.device@3.4-impl.so
lib64/vendor.qti.hardware.camera.device@1.0.so
lib64/libdualcam_optical_zoom_control.so
lib64/libcdfw_remote_api.so
lib64/libsns_fastRPC_util.so
lib64/libcamera_nn_stub.so
lib64/libremosaic_daemon.so
lib64/libcamxfdalgov8.so
lib64/libLocalTM_wrapper.camera.samsung.so
lib64/libgps.utils.so
lib64/vendor.samsung.hardware.camera.provider@4.0.so
lib64/vendor.samsung.hardware.camera.provider@4.0-legacy.so
lib64/libHpr_RecGAE_cvFeature_v1.0.camera.samsung.so
lib64/vendor.qti.gnss@2.1.so
lib64/liblowi_client.so
lib64/libc++_shared.so
lib64/liblivefocus_preview_interface.so
lib64/libizat_core.so
lib64/libFacePreProcessing.camera.samsung.so
lib64/libcamxtintlessalgo.so
lib64/vendor.qti.gnss@3.0.so
lib64/vendor.samsung.hardware.gnss@2.0.so
lib64/vendor.qti.gnss@1.0.so
lib64/libhigh_dynamic_range.so
lib64/libdataitems.so
lib64/vendor.qti.gnss@4.0.so
lib64/libsnsdiaglog.so
lib64/libbauthserver.so
lib64/libdrmfs.so
lib64/libHprFace_GAE_api.camera.samsung.so
lib64/libdualcapture.so
lib64/libcamxfdalgov7.so
lib64/libsynaFpSensorTestNwd.so
lib64/libswldc_capture_core.camera.samsung.so
lib64/libsns_low_lat_stream_stub.so
lib64/vendor.nxp.nxpnfc@1.0.so
lib64/liblivefocus_capture_interface.so
lib64/liblocationservice_glue.so
lib64/liblivefocus_preview_engine.so
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$context" 0 2000 644 "u:object_r:vendor_lib_file:s0"
done

CONTEXTS_LIST="
system/lib/libsamsungSoundbooster_plus_legacy.so
system/lib/lib_SoundBooster_ver1000.so
system/lib64/libsamsungSoundbooster_plus_legacy.so
system/lib64/lib_SoundBooster_ver1000.so
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "system" "$context" 0 0 644 "u:object_r:system_lib_file:s0"
done

CONTEXTS_LIST="
etc/audio_io_policy.conf
etc/media_codecs.xml
etc/libnfc-nci.conf
etc/init/hw/init.samsung.bsp.rc
etc/init/hw/init.target.rc
etc/init/hw/init.qcom.rc
etc/init/hw/init.qcom.factory.rc
etc/init/hw/init.a52q.rc
etc/init/hw/init.qti.ufs.rc
etc/init/hw/init.samsung.rc
etc/init/hw/init.qcom.usb.rc
etc/init/hw/init.samsung.display.rc
etc/init/nxp.android.hardware.nfc@1.1-service.rc
etc/init/vendor.samsung.hardware.biometrics.fingerprint@3.0-service.rc
etc/init/android.hardware.drm@1.3-service.clearkey.rc
etc/init/android.hardware.drm@1.3-service.widevine.rc
etc/init/android.hardware.gnss@2.1-service-qti.rc
etc/audio_platform_info_diff.xml
etc/audconf/SER/workspaceFile.qwsp
etc/audconf/SER/Headset_cal.acdb
etc/audconf/SER/Bluetooth_cal.acdb
etc/audconf/SER/Global_cal.acdb
etc/audconf/SER/Speaker_cal.acdb
etc/audconf/SER/Hdmi_cal.acdb
etc/audconf/SER/General_cal.acdb
etc/audconf/SER/Handset_cal.acdb
etc/audconf/SER/Codec_cal.acdb
etc/audconf/AFR/workspaceFile.qwsp
etc/audconf/AFR/Headset_cal.acdb
etc/audconf/AFR/Bluetooth_cal.acdb
etc/audconf/AFR/Global_cal.acdb
etc/audconf/AFR/Speaker_cal.acdb
etc/audconf/AFR/Hdmi_cal.acdb
etc/audconf/AFR/General_cal.acdb
etc/audconf/AFR/Handset_cal.acdb
etc/audconf/AFR/Codec_cal.acdb
etc/audconf/SKZ/workspaceFile.qwsp
etc/audconf/SKZ/Headset_cal.acdb
etc/audconf/SKZ/Bluetooth_cal.acdb
etc/audconf/SKZ/Global_cal.acdb
etc/audconf/SKZ/Speaker_cal.acdb
etc/audconf/SKZ/Hdmi_cal.acdb
etc/audconf/SKZ/General_cal.acdb
etc/audconf/SKZ/Handset_cal.acdb
etc/audconf/SKZ/Codec_cal.acdb
etc/audconf/XFE/workspaceFile.qwsp
etc/audconf/XFE/Headset_cal.acdb
etc/audconf/XFE/Bluetooth_cal.acdb
etc/audconf/XFE/Global_cal.acdb
etc/audconf/XFE/Speaker_cal.acdb
etc/audconf/XFE/Hdmi_cal.acdb
etc/audconf/XFE/General_cal.acdb
etc/audconf/XFE/Handset_cal.acdb
etc/audconf/XFE/Codec_cal.acdb
etc/audconf/BTC/workspaceFile.qwsp
etc/audconf/BTC/Headset_cal.acdb
etc/audconf/BTC/Bluetooth_cal.acdb
etc/audconf/BTC/Global_cal.acdb
etc/audconf/BTC/Speaker_cal.acdb
etc/audconf/BTC/Hdmi_cal.acdb
etc/audconf/BTC/General_cal.acdb
etc/audconf/BTC/Handset_cal.acdb
etc/audconf/BTC/Codec_cal.acdb
etc/audconf/ECT/workspaceFile.qwsp
etc/audconf/ECT/Headset_cal.acdb
etc/audconf/ECT/Bluetooth_cal.acdb
etc/audconf/ECT/Global_cal.acdb
etc/audconf/ECT/Speaker_cal.acdb
etc/audconf/ECT/Hdmi_cal.acdb
etc/audconf/ECT/General_cal.acdb
etc/audconf/ECT/Handset_cal.acdb
etc/audconf/ECT/Codec_cal.acdb
etc/audconf/XFA/workspaceFile.qwsp
etc/audconf/XFA/Headset_cal.acdb
etc/audconf/XFA/Bluetooth_cal.acdb
etc/audconf/XFA/Global_cal.acdb
etc/audconf/XFA/Speaker_cal.acdb
etc/audconf/XFA/Hdmi_cal.acdb
etc/audconf/XFA/General_cal.acdb
etc/audconf/XFA/Handset_cal.acdb
etc/audconf/XFA/Codec_cal.acdb
etc/audconf/DKR/workspaceFile.qwsp
etc/audconf/DKR/Headset_cal.acdb
etc/audconf/DKR/Bluetooth_cal.acdb
etc/audconf/DKR/Global_cal.acdb
etc/audconf/DKR/Speaker_cal.acdb
etc/audconf/DKR/Hdmi_cal.acdb
etc/audconf/DKR/General_cal.acdb
etc/audconf/DKR/Handset_cal.acdb
etc/audconf/DKR/Codec_cal.acdb
etc/audconf/XFV/workspaceFile.qwsp
etc/audconf/XFV/Headset_cal.acdb
etc/audconf/XFV/Bluetooth_cal.acdb
etc/audconf/XFV/Global_cal.acdb
etc/audconf/XFV/Speaker_cal.acdb
etc/audconf/XFV/Hdmi_cal.acdb
etc/audconf/XFV/General_cal.acdb
etc/audconf/XFV/Handset_cal.acdb
etc/audconf/XFV/Codec_cal.acdb
etc/audconf/MID/workspaceFile.qwsp
etc/audconf/MID/Headset_cal.acdb
etc/audconf/MID/Bluetooth_cal.acdb
etc/audconf/MID/Global_cal.acdb
etc/audconf/MID/Speaker_cal.acdb
etc/audconf/MID/Hdmi_cal.acdb
etc/audconf/MID/General_cal.acdb
etc/audconf/MID/Handset_cal.acdb
etc/audconf/MID/Codec_cal.acdb
etc/audconf/AFG/workspaceFile.qwsp
etc/audconf/AFG/Headset_cal.acdb
etc/audconf/AFG/Bluetooth_cal.acdb
etc/audconf/AFG/Global_cal.acdb
etc/audconf/AFG/Speaker_cal.acdb
etc/audconf/AFG/Hdmi_cal.acdb
etc/audconf/AFG/General_cal.acdb
etc/audconf/AFG/Handset_cal.acdb
etc/audconf/AFG/Codec_cal.acdb
etc/audconf/SEK/workspaceFile.qwsp
etc/audconf/SEK/Headset_cal.acdb
etc/audconf/SEK/Bluetooth_cal.acdb
etc/audconf/SEK/Global_cal.acdb
etc/audconf/SEK/Speaker_cal.acdb
etc/audconf/SEK/Hdmi_cal.acdb
etc/audconf/SEK/General_cal.acdb
etc/audconf/SEK/Handset_cal.acdb
etc/audconf/SEK/Codec_cal.acdb
etc/audconf/CPW/workspaceFile.qwsp
etc/audconf/CPW/Headset_cal.acdb
etc/audconf/CPW/Bluetooth_cal.acdb
etc/audconf/CPW/Global_cal.acdb
etc/audconf/CPW/Speaker_cal.acdb
etc/audconf/CPW/Hdmi_cal.acdb
etc/audconf/CPW/General_cal.acdb
etc/audconf/CPW/Handset_cal.acdb
etc/audconf/CPW/Codec_cal.acdb
etc/audconf/THR/workspaceFile.qwsp
etc/audconf/THR/Headset_cal.acdb
etc/audconf/THR/Bluetooth_cal.acdb
etc/audconf/THR/Global_cal.acdb
etc/audconf/THR/Speaker_cal.acdb
etc/audconf/THR/Hdmi_cal.acdb
etc/audconf/THR/General_cal.acdb
etc/audconf/THR/Handset_cal.acdb
etc/audconf/THR/Codec_cal.acdb
etc/audconf/ACR/workspaceFile.qwsp
etc/audconf/ACR/Headset_cal.acdb
etc/audconf/ACR/Bluetooth_cal.acdb
etc/audconf/ACR/Global_cal.acdb
etc/audconf/ACR/Speaker_cal.acdb
etc/audconf/ACR/Hdmi_cal.acdb
etc/audconf/ACR/General_cal.acdb
etc/audconf/ACR/Handset_cal.acdb
etc/audconf/ACR/Codec_cal.acdb
etc/audconf/XSG/workspaceFile.qwsp
etc/audconf/XSG/Headset_cal.acdb
etc/audconf/XSG/Bluetooth_cal.acdb
etc/audconf/XSG/Global_cal.acdb
etc/audconf/XSG/Speaker_cal.acdb
etc/audconf/XSG/Hdmi_cal.acdb
etc/audconf/XSG/General_cal.acdb
etc/audconf/XSG/Handset_cal.acdb
etc/audconf/XSG/Codec_cal.acdb
etc/audconf/TUR/workspaceFile.qwsp
etc/audconf/TUR/Headset_cal.acdb
etc/audconf/TUR/Bluetooth_cal.acdb
etc/audconf/TUR/Global_cal.acdb
etc/audconf/TUR/Speaker_cal.acdb
etc/audconf/TUR/Hdmi_cal.acdb
etc/audconf/TUR/General_cal.acdb
etc/audconf/TUR/Handset_cal.acdb
etc/audconf/TUR/Codec_cal.acdb
etc/audconf/OPEN/workspaceFile.qwsp
etc/audconf/OPEN/Headset_cal.acdb
etc/audconf/OPEN/Bluetooth_cal.acdb
etc/audconf/OPEN/Global_cal.acdb
etc/audconf/OPEN/Speaker_cal.acdb
etc/audconf/OPEN/Hdmi_cal.acdb
etc/audconf/OPEN/General_cal.acdb
etc/audconf/OPEN/Handset_cal.acdb
etc/audconf/OPEN/Codec_cal.acdb
etc/audconf/CAU/workspaceFile.qwsp
etc/audconf/CAU/Headset_cal.acdb
etc/audconf/CAU/Bluetooth_cal.acdb
etc/audconf/CAU/Global_cal.acdb
etc/audconf/CAU/Speaker_cal.acdb
etc/audconf/CAU/Hdmi_cal.acdb
etc/audconf/CAU/General_cal.acdb
etc/audconf/CAU/Handset_cal.acdb
etc/audconf/CAU/Codec_cal.acdb
etc/audconf/EGY/workspaceFile.qwsp
etc/audconf/EGY/Headset_cal.acdb
etc/audconf/EGY/Bluetooth_cal.acdb
etc/audconf/EGY/Global_cal.acdb
etc/audconf/EGY/Speaker_cal.acdb
etc/audconf/EGY/Hdmi_cal.acdb
etc/audconf/EGY/General_cal.acdb
etc/audconf/EGY/Handset_cal.acdb
etc/audconf/EGY/Codec_cal.acdb
etc/audconf/TKD/workspaceFile.qwsp
etc/audconf/TKD/Headset_cal.acdb
etc/audconf/TKD/Bluetooth_cal.acdb
etc/audconf/TKD/Global_cal.acdb
etc/audconf/TKD/Speaker_cal.acdb
etc/audconf/TKD/Hdmi_cal.acdb
etc/audconf/TKD/General_cal.acdb
etc/audconf/TKD/Handset_cal.acdb
etc/audconf/TKD/Codec_cal.acdb
etc/audconf/CAC/workspaceFile.qwsp
etc/audconf/CAC/Headset_cal.acdb
etc/audconf/CAC/Bluetooth_cal.acdb
etc/audconf/CAC/Global_cal.acdb
etc/audconf/CAC/Speaker_cal.acdb
etc/audconf/CAC/Hdmi_cal.acdb
etc/audconf/CAC/General_cal.acdb
etc/audconf/CAC/Handset_cal.acdb
etc/audconf/CAC/Codec_cal.acdb
etc/audconf/PAK/workspaceFile.qwsp
etc/audconf/PAK/Headset_cal.acdb
etc/audconf/PAK/Bluetooth_cal.acdb
etc/audconf/PAK/Global_cal.acdb
etc/audconf/PAK/Speaker_cal.acdb
etc/audconf/PAK/Hdmi_cal.acdb
etc/audconf/PAK/General_cal.acdb
etc/audconf/PAK/Handset_cal.acdb
etc/audconf/PAK/Codec_cal.acdb
etc/audconf/LYS/workspaceFile.qwsp
etc/audconf/LYS/Headset_cal.acdb
etc/audconf/LYS/Bluetooth_cal.acdb
etc/audconf/LYS/Global_cal.acdb
etc/audconf/LYS/Speaker_cal.acdb
etc/audconf/LYS/Hdmi_cal.acdb
etc/audconf/LYS/General_cal.acdb
etc/audconf/LYS/Handset_cal.acdb
etc/audconf/LYS/Codec_cal.acdb
etc/audconf/ILO/workspaceFile.qwsp
etc/audconf/ILO/Headset_cal.acdb
etc/audconf/ILO/Bluetooth_cal.acdb
etc/audconf/ILO/Global_cal.acdb
etc/audconf/ILO/Speaker_cal.acdb
etc/audconf/ILO/Hdmi_cal.acdb
etc/audconf/ILO/General_cal.acdb
etc/audconf/ILO/Handset_cal.acdb
etc/audconf/ILO/Codec_cal.acdb
etc/audconf/KSA/workspaceFile.qwsp
etc/audconf/KSA/Headset_cal.acdb
etc/audconf/KSA/Bluetooth_cal.acdb
etc/audconf/KSA/Global_cal.acdb
etc/audconf/KSA/Speaker_cal.acdb
etc/audconf/KSA/Hdmi_cal.acdb
etc/audconf/KSA/General_cal.acdb
etc/audconf/KSA/Handset_cal.acdb
etc/audconf/KSA/Codec_cal.acdb
etc/audconf/TUN/workspaceFile.qwsp
etc/audconf/TUN/Headset_cal.acdb
etc/audconf/TUN/Bluetooth_cal.acdb
etc/audconf/TUN/Global_cal.acdb
etc/audconf/TUN/Speaker_cal.acdb
etc/audconf/TUN/Hdmi_cal.acdb
etc/audconf/TUN/General_cal.acdb
etc/audconf/TUN/Handset_cal.acdb
etc/audconf/TUN/Codec_cal.acdb
etc/msm_irqbalance.conf
etc/lowi.conf
etc/system_properties.xml
etc/media_profiles.xml
etc/mixer_paths_idp.xml
etc/gps.conf
etc/audio_effects.xml
etc/wifi/wpa_supplicant.conf
etc/wifi/p2p_supplicant_overlay.conf
etc/wifi/WCNSS_qcom_cfg.ini
etc/wifi/icm.conf
etc/wifi/indoorchannel.info
etc/wifi/wpa_supplicant_overlay.conf
etc/sec_config
etc/acdbdata/adsp_avs_config.acdb
etc/flp.conf
etc/fstab.qcom
etc/audio_effects.conf
etc/media_codecs_performance.xml
etc/SoundBoosterParam.txt
etc/libnfc-mtp-SN100.conf
etc/nfc/libnfc-nxp_RF.conf
etc/libnfc-nxp.conf
etc/audio_platform_info_intcodec.xml
etc/libnfc-qrd-SN100.conf
etc/sensors/sns_reg_config
etc/sensors/hals.conf
etc/sensors/config/sns_amd.json
etc/sensors/config/sns_ccd.json
etc/sensors/config/talos_lsm6dsm_0.json
etc/sensors/config/sns_rmd.json
etc/sensors/config/talos_ak991x_1.json
etc/sensors/config/sns_tilt.json
etc/sensors/config/sns_aont.json
etc/sensors/config/talos_ak991x_nfc_1.json
etc/sensors/config/sns_mag_cal.json
etc/sensors/config/sns_amd_sw_enabled.json
etc/sensors/config/sns_cm.json
etc/sensors/config/talos_ak991x_mst_0.json
etc/sensors/config/sns_tilt_sw_enabled.json
etc/sensors/config/sns_gyro_cal.json
etc/sensors/config/sns_tilt_sw_disabled.json
etc/sensors/config/sns_amd_sw_disabled.json
etc/sensors/config/talos_tcs3407_0.json
etc/sensors/config/talos_stk3x3x_0.json
etc/sensors/config/lsm6dsm_0.json
etc/sensors/config/talos_ak991x_0.json
etc/sensors/config/default_sensors.json
etc/sensors/config/talos_power_0.json
etc/sensors/config/talos_ak991x_mst_1.json
etc/sensors/config/sns_rotv.json
etc/sensors/config/sns_dae.json
etc/sensors/config/sns_diag_filter.json
etc/sensors/config/sns_geomag_rv.json
etc/sensors/config/sns_smd.json
etc/sensors/config/talos_ak991x_nfc_0.json
etc/sensors/config/sns_hw_revision.json
etc/gnss_antenna_info.conf
etc/libnfc-qrd-SN100_38_4MHZ.conf
etc/audio_platform_info.xml
etc/audio_policy_configuration.xml
etc/media_profiles_V1_0.xml
etc/libnfc-mtp-SN100_38_4MHZ.conf
etc/izat.conf
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$context" 0 0 644 "u:object_r:vendor_configs_file:s0"
done

CONTEXTS_LIST="
firmware/CAMERA_ICP.elf
firmware/wlan/qca_cld/grippower.info
firmware/wlan/qca_cld/WCNSS_qcom_cfg.ini
firmware/wlan/qca_cld/regdb.bin
firmware/wlan/qca_cld/bdwlan.bin
firmware/nfc/libpn553_fw.so
firmware/wlanmdsp.mbn
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$context" 0 0 644 "u:object_r:vendor_firmware_file:s0"
done

ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/hw/android.hardware.gnss@2.1-service-qti" 0 2000 755 "u:object_r:vendor_hal_gnss_qti_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/xtra-daemon" 0 2000 755 "u:object_r:vendor_location_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/loc_launcher" 0 2000 755 "u:object_r:vendor_location_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/lowi-server" 0 2000 755 "u:object_r:vendor_location_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/hw/android.hardware.drm@1.3-service.clearkey" 0 2000 755 "u:object_r:vendor_hal_drm_clearkey_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/hw/android.hardware.drm@1.3-service.widevine" 0 2000 755 "u:object_r:vendor_hal_drm_widevine_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/hw/vendor.samsung.hardware.camera.provider@4.0-service" 0 2000 755 "u:object_r:hal_camera_default_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "bin/wvkprov" 0 2000 755 "u:object_r:wvkprov_exec:s0"

ADD_TO_WORK_DIR_CONTEXT "vendor" "overlay/framework-res__auto_generated_rro_vendor.apk" 0 2000 755 "u:object_r:vendor_file:s0"

CONTEXTS_LIST="
etc/audconf/SER
etc/audconf/AFR
etc/audconf/SKZ
etc/audconf/XFE
etc/audconf/BTC
etc/audconf/ECT
etc/audconf/XFA
etc/audconf/DKR
etc/audconf/XFV
etc/audconf/MID
etc/audconf/AFG
etc/audconf/SEK
etc/audconf/CPW
etc/audconf/THR
etc/audconf/ACR
etc/audconf/XSG
etc/audconf/TUR
etc/audconf/OPEN
etc/audconf/CAU
etc/audconf/EGY
etc/audconf/TKD
etc/audconf/CAC
etc/audconf/PAK
etc/audconf/LYS
etc/audconf/ILO
etc/audconf/KSA
etc/audconf/TUN
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$context" 0 2000 755 "u:object_r:vendor_configs_file:s0"
done

# ODM
REMOVE_FROM_WORK_DIR "$WORK_DIR/vendor/odm"

echo "Patching ODM under vendor"

ADD_TO_WORK_DIR_CONTEXT "vendor" "odm/etc/media_profiles_V1_0.xml" 0 2000 644 "u:object_r:vendor_lib_file:s0"

echo "Revert to VNDK30 ODM SEPolicy"
ADD_TO_WORK_DIR "odm" "etc/selinux/precompiled_sepolicy" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "odm" "etc/selinux/precompiled_sepolicy.plat_sepolicy_and_mapping.sha256" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "odm" "etc/selinux/precompiled_sepolicy.product_sepolicy_and_mapping.sha256" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "odm" "etc/selinux/precompiled_sepolicy.system_ext_sepolicy_and_mapping.sha256" 0 0 644 "u:object_r:vendor_configs_file:s0"

cp -r $WORK_DIR/odm $WORK_DIR/vendor

{
    sed "1d" "$WORK_DIR/configs/fs_config-odm" | sed "s/^odm/vendor\/odm/g"
} >> "$WORK_DIR/configs/fs_config-vendor"

{
    sed "s/^\/odm/\/vendor\/odm/g" "$WORK_DIR/configs/file_context-odm"
} >> "$WORK_DIR/configs/file_context-vendor"

echo "Patch media_profiles_V1_0.xml on new odm"
cp -r $WORK_DIR/vendor/etc/media_profiles_V1_0.xml $WORK_DIR/vendor/odm/etc

# Update NFC Props
echo "Update NFC props"
SET_PROP "ro.vendor.nfc.feature.chipname" "NXP_SN100U" "$WORK_DIR/vendor/build.prop"
SET_PROP "ro.vendor.nfc.support.ese" "true" "$WORK_DIR/vendor/build.prop"

# A70 doesn't provide any info about it's antenna position
SET_PROP "ro.vendor.nfc.info.antpos" "-d" "$WORK_DIR/vendor/build.prop"
SET_PROP "ro.vendor.nfc.info.antposX" "-d" "$WORK_DIR/vendor/build.prop"
SET_PROP "ro.vendor.nfc.info.antposY" "-d" "$WORK_DIR/vendor/build.prop"
SET_PROP "ro.vendor.nfc.info.deviceWidth" "-d" "$WORK_DIR/vendor/build.prop"
SET_PROP "ro.vendor.nfc.info.deviceHeight" "-d" "$WORK_DIR/vendor/build.prop"

echo "Restruction was completed successfully!"
