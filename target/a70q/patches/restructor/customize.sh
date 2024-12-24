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
REMOVE_FROM_WORK_DIR "$WORK_DIR/system/lib64/lib_SoundBooster_ver2000.so"

# Copy the blobs
echo "Installing A70 drivers"
cp -r $SRC_DIR/target/a70q/patches/restructor/A705FN/* $WORK_DIR

# SELinux and prop config
echo "Configuring properties"
CONTEXTS_LIST="
vendor/lib/libmpbase.so
vendor/lib/libcom.qti.chinodeutils.so
vendor/lib/libcdfw.so
vendor/lib/liblocation_api.so
vendor/lib/libdrmtime.so
vendor/lib/libegis_fp_normal_sensor_test.so
vendor/lib/liblocationservice.so
vendor/lib/libuniplugin.so
vendor/lib/libgeofencing.so
vendor/lib/libswvdec.so
vendor/lib/liboemcrypto.so
vendor/lib/libsmartfocusengine.so
vendor/lib/libtzdrmgenprov.so
vendor/lib/android.hardware.camera.provider@2.4-legacy.so
vendor/lib/vendor.qti.gnss@1.2.so
vendor/lib/camera.device@1.0-impl.so
vendor/lib/libdualcam_refocus_image.so
vendor/lib/vendor.qti.gnss@2.0.so
vendor/lib/hw/vendor.samsung.hardware.camera.provider@4.0-impl.so
vendor/lib/hw/camera.qcom.so
vendor/lib/hw/com.samsung.chi.override.so
vendor/lib/hw/android.hardware.gnss@2.1-impl-qti.so
vendor/lib/hw/vendor.samsung.hardware.gnss@2.0-impl-sec.so
vendor/lib/hw/audio.primary.atoll.so
vendor/lib/vendor.samsung.hardware.camera.device@5.0.so
vendor/lib/mediadrm/libwvdrmengine.so
vendor/lib/vendor.samsung.hardware.camera.device@5.0-impl.so
vendor/lib/libwvhidl.so
vendor/lib/libllhdr_interface.so
vendor/lib/libgnss.so
vendor/lib/libjpegQtable_interface.so
vendor/lib/libsaiv_BeautySolutionVideo.so
vendor/lib/libDualCamBokehCapture.camera.samsung.so
vendor/lib/camera/uw_dual_calibration.bin
vendor/lib/camera/com.samsung.sensor.gc5035.so
vendor/lib/camera/com.samsung.sensormodule.3_lsi_gc5035.bin
vendor/lib/camera/com.samsung.tuned.s5k4ha.bin
vendor/lib/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_dv.bin
vendor/lib/camera/f_dual_calibration.bin
vendor/lib/camera/com.samsung.sensormodule.0_lsi_s5kgd1_pv_OLD.bin
vendor/lib/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_pv_OLD.bin
vendor/lib/camera/components/com.qti.stats.afd.so
vendor/lib/camera/components/com.qti.node.fcv.so
vendor/lib/camera/components/com.qti.stats.awb.so
vendor/lib/camera/components/com.qti.node.gpu.so
vendor/lib/camera/components/com.qti.stats.aec.so
vendor/lib/camera/components/com.qti.stats.haf.so
vendor/lib/camera/components/libdepthmapwrapper.so
vendor/lib/camera/components/com.qtistatic.stats.aec.so
vendor/lib/camera/components/com.qti.eisv2.so
vendor/lib/camera/components/libmmcamera_cac3.so
vendor/lib/camera/components/com.samsung.node.uniplugin_recording.so
vendor/lib/camera/components/com.qti.node.stich.so
vendor/lib/camera/components/com.samsung.node.realtimebokeh.so
vendor/lib/camera/components/com.samsung.node.bayerfuse.so
vendor/lib/camera/components/com.samsung.node.capture_fusion.so
vendor/lib/camera/components/com.qtistatic.stats.awb.so
vendor/lib/camera/components/com.wrapper.stats.af.so
vendor/lib/camera/components/com.samsung.node.smooth_transition.so
vendor/lib/camera/components/com.samsung.node.uniplugin_capture.so
vendor/lib/camera/components/com.samsung.node.bayercheck.so
vendor/lib/camera/components/com.wrapper.stats.pdlib.so
vendor/lib/camera/components/com.samsung.node.capture_bokeh.so
vendor/lib/camera/components/com.qti.stats.asd.so
vendor/lib/camera/components/com.qtistatic.stats.af.so
vendor/lib/camera/components/com.samsung.node.uniplugin_vdis.so
vendor/lib/camera/components/com.qti.eisv3.so
vendor/lib/camera/components/com.samsung.node.uniplugin_preview.so
vendor/lib/camera/components/com.qti.node.dummyrtb.so
vendor/lib/camera/components/com.qti.node.eisv3.so
vendor/lib/camera/components/com.qti.camx.chiiqutils.so
vendor/lib/camera/components/com.qti.node.swregistration.so
vendor/lib/camera/components/com.qti.node.depth.so
vendor/lib/camera/components/com.qti.node.eisv2.so
vendor/lib/camera/components/com.wrapper.stats.awb.so
vendor/lib/camera/components/com.wrapper.stats.aec.so
vendor/lib/camera/components/com.qti.stats.pdlibwrapper.so
vendor/lib/camera/components/com.qti.node.memcpy.so
vendor/lib/camera/components/com.samsung.node.remosaic.so
vendor/lib/camera/components/com.qti.stats.af.so
vendor/lib/camera/components/com.qti.node.dummysat.so
vendor/lib/camera/components/com.qti.stats.pdlibsony.so
vendor/lib/camera/components/com.qtistatic.stats.pdlib.so
vendor/lib/camera/components/com.qti.stats.hafoverride.so
vendor/lib/camera/components/com.qti.stats.pdlib.so
vendor/lib/camera/com.samsung.sensor.s5kgd1_front.so
vendor/lib/camera/w_dual_calibration.bin
vendor/lib/camera/com.samsung.sensor.s5k4ha.so
vendor/lib/camera/com.samsung.tuned.s5kgd1_front.bin
vendor/lib/camera/com.samsung.tuned.s5kgd1.bin
vendor/lib/camera/com.samsung.sensormodule.2_lsi_s5k4ha.bin
vendor/lib/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_pv_NEW.bin
vendor/lib/camera/com.samsung.sensormodule.0_lsi_s5kgd1_pv_NEW.bin
vendor/lib/camera/com.samsung.sensor.s5kgd1.so
vendor/lib/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_dv.bin
vendor/lib/camera/com.samsung.sensormodule.0_lsi_s5kgd1_dv.bin
vendor/lib/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_pv_NEW.bin
vendor/lib/camera/com.samsung.tuned.gc5035.bin
vendor/lib/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_pv_OLD.bin
vendor/lib/libcamxstatscore.so
vendor/lib/libcpion.so
vendor/lib/android.hardware.camera.provider@2.5-legacy.so
vendor/lib/libswregistrationalgo.so
vendor/lib/libsmartfocus_interface.so
vendor/lib/libjnihelper.so
vendor/lib/libloc_socket.so
vendor/lib/libcamxswprocessalgo.so
vendor/lib/libfloatingfeature.so
vendor/lib/libbatching.so
vendor/lib/libgarden.so
vendor/lib/libloc_core.so
vendor/lib/liblbs_core.so
vendor/lib/liblivefocus_capture_engine.so
vendor/lib/vendor.qti.gnss@1.1.so
vendor/lib/libchiss3alogdebug.so
vendor/lib/libcamxfdengine.so
vendor/lib/libizat_client_api.so
vendor/lib/libpvr.so
vendor/lib/libgnsspps.so
vendor/lib/camera.device@3.3-impl.so
vendor/lib/libqfp_sensortest.so
vendor/lib/libbauthtzcommon.so
vendor/lib/camera.device@3.5-impl.so
vendor/lib/libsns_device_mode_stub.so
vendor/lib/libqti_vndfwk_detect.so
vendor/lib/libloc_api_v02.so
vendor/lib/liblow_light_hdr.so
vendor/lib/libsnsapi.so
vendor/lib/libgf_in_system_lib.so
vendor/lib/libdualcam_optical_zoom.so
vendor/lib/libOpenCv.camera.samsung.so
vendor/lib/camera.device@3.2-impl.so
vendor/lib/camera.device@3.4-impl.so
vendor/lib/vendor.qti.hardware.camera.device@1.0.so
vendor/lib/libdualcam_optical_zoom_control.so
vendor/lib/libcdfw_remote_api.so
vendor/lib/libsns_fastRPC_util.so
vendor/lib/libcamera_nn_stub.so
vendor/lib/libdualcam_refocus_video.so
vendor/lib/libcamxfdalgov8.so
vendor/lib/libgps.utils.so
vendor/lib/vendor.samsung.hardware.camera.provider@4.0.so
vendor/lib/vendor.samsung.hardware.camera.provider@4.0-legacy.so
vendor/lib/vendor.qti.gnss@2.1.so
vendor/lib/liblowi_client.so
vendor/lib/libc++_shared.so
vendor/lib/libcppf.so
vendor/lib/liblivefocus_preview_interface.so
vendor/lib/libizat_core.so
vendor/lib/libFacePreProcessing.camera.samsung.so
vendor/lib/libcamxtintlessalgo.so
vendor/lib/vendor.qti.gnss@3.0.so
vendor/lib/vendor.samsung.hardware.gnss@2.0.so
vendor/lib/vendor.qti.gnss@1.0.so
vendor/lib/libdataitems.so
vendor/lib/vendor.qti.gnss@4.0.so
vendor/lib/libbauthserver.so
vendor/lib/libdrmfs.so
vendor/lib/libdualcapture.so
vendor/lib/libcamxfdalgov7.so
vendor/lib/libsynaFpSensorTestNwd.so
vendor/lib/libsns_low_lat_stream_stub.so
vendor/lib/liblivefocus_capture_interface.so
vendor/lib/libqcwrappercommon.so
vendor/lib/liblocationservice_glue.so
vendor/lib/liblivefocus_preview_engine.so
vendor/lib64/libmpbase.so
vendor/lib64/libcom.qti.chinodeutils.so
vendor/lib64/libcdfw.so
vendor/lib64/libsnpe_wrapper.so
vendor/lib64/liblocation_api.so
vendor/lib64/libdrmtime.so
vendor/lib64/libegis_fp_normal_sensor_test.so
vendor/lib64/liblocationservice.so
vendor/lib64/libuniplugin.so
vendor/lib64/libgeofencing.so
vendor/lib64/libswvdec.so
vendor/lib64/liboemcrypto.so
vendor/lib64/libsmartfocusengine.so
vendor/lib64/libtzdrmgenprov.so
vendor/lib64/android.hardware.camera.provider@2.4-legacy.so
vendor/lib64/libSNPE.so
vendor/lib64/vendor.qti.gnss@1.2.so
vendor/lib64/camera.device@1.0-impl.so
vendor/lib64/libdualcam_refocus_image.so
vendor/lib64/vendor.qti.gnss@2.0.so
vendor/lib64/hw/vendor.samsung.hardware.camera.provider@4.0-impl.so
vendor/lib64/hw/camera.qcom.so
vendor/lib64/hw/com.samsung.chi.override.so
vendor/lib64/hw/android.hardware.gnss@2.1-impl-qti.so
vendor/lib64/hw/vendor.samsung.hardware.gnss@2.0-impl-sec.so
vendor/lib64/vendor.samsung.hardware.camera.device@5.0.so
vendor/lib64/vendor.samsung.hardware.camera.device@5.0-impl.so
vendor/lib64/vendor.samsung.hardware.security.widevine.keyprov@1.0.so
vendor/lib64/libgnss.so
vendor/lib64/libLocalTM_preview_core.so
vendor/lib64/libjpegQtable_interface.so
vendor/lib64/libDLInterface.camera.samsung.so
vendor/lib64/libDualCamBokehCapture.camera.samsung.so
vendor/lib64/libremosaiclib.so
vendor/lib64/camera/com.samsung.sensor.gc5035.so
vendor/lib64/camera/com.samsung.sensormodule.3_lsi_gc5035.bin
vendor/lib64/camera/com.samsung.tuned.s5k4ha.bin
vendor/lib64/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_dv.bin
vendor/lib64/camera/com.samsung.sensormodule.0_lsi_s5kgd1_pv_OLD.bin
vendor/lib64/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_pv_OLD.bin
vendor/lib64/camera/components/com.qti.stats.afd.so
vendor/lib64/camera/components/com.qti.node.fcv.so
vendor/lib64/camera/components/com.qti.node.gpu.so
vendor/lib64/camera/components/libdepthmapwrapper.so
vendor/lib64/camera/components/com.qtistatic.stats.aec.so
vendor/lib64/camera/components/com.qti.eisv2.so
vendor/lib64/camera/components/libmmcamera_cac3.so
vendor/lib64/camera/components/com.qti.node.stich.so
vendor/lib64/camera/components/com.samsung.node.realtimebokeh.so
vendor/lib64/camera/components/com.samsung.node.bayerfuse.so
vendor/lib64/camera/components/com.samsung.node.capture_fusion.so
vendor/lib64/camera/components/com.qtistatic.stats.awb.so
vendor/lib64/camera/components/com.wrapper.stats.af.so
vendor/lib64/camera/components/com.samsung.node.smooth_transition.so
vendor/lib64/camera/components/com.samsung.node.bayercheck.so
vendor/lib64/camera/components/com.wrapper.stats.pdlib.so
vendor/lib64/camera/components/com.samsung.node.capture_bokeh.so
vendor/lib64/camera/components/com.qti.stats.asd.so
vendor/lib64/camera/components/com.qtistatic.stats.af.so
vendor/lib64/camera/components/com.qti.eisv3.so
vendor/lib64/camera/components/com.qti.node.dummyrtb.so
vendor/lib64/camera/components/com.qti.node.eisv3.so
vendor/lib64/camera/components/com.qti.camx.chiiqutils.so
vendor/lib64/camera/components/com.qti.node.swregistration.so
vendor/lib64/camera/components/com.qti.node.depth.so
vendor/lib64/camera/components/com.qti.node.eisv2.so
vendor/lib64/camera/components/com.wrapper.stats.awb.so
vendor/lib64/camera/components/com.wrapper.stats.aec.so
vendor/lib64/camera/components/com.qti.stats.pdlibwrapper.so
vendor/lib64/camera/components/com.qti.node.memcpy.so
vendor/lib64/camera/components/com.samsung.node.remosaic.so
vendor/lib64/camera/components/com.qti.node.dummysat.so
vendor/lib64/camera/components/com.qti.stats.pdlibsony.so
vendor/lib64/camera/components/com.qtistatic.stats.pdlib.so
vendor/lib64/camera/components/com.qti.stats.hafoverride.so
vendor/lib64/camera/com.samsung.sensor.s5kgd1_front.so
vendor/lib64/camera/com.samsung.sensor.s5k4ha.so
vendor/lib64/camera/com.samsung.tuned.s5kgd1_front.bin
vendor/lib64/camera/com.samsung.tuned.s5kgd1.bin
vendor/lib64/camera/com.samsung.sensormodule.2_lsi_s5k4ha.bin
vendor/lib64/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_pv_NEW.bin
vendor/lib64/camera/com.samsung.sensormodule.0_lsi_s5kgd1_pv_NEW.bin
vendor/lib64/camera/com.samsung.sensor.s5kgd1.so
vendor/lib64/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_dv.bin
vendor/lib64/camera/com.samsung.sensormodule.0_lsi_s5kgd1_dv.bin
vendor/lib64/camera/com.samsung.sensormodule.8_lsi_s5kgd1_front_full_pv_NEW.bin
vendor/lib64/camera/com.samsung.tuned.gc5035.bin
vendor/lib64/camera/com.samsung.sensormodule.1_lsi_s5kgd1_front_pv_OLD.bin
vendor/lib64/libcamxstatscore.so
vendor/lib64/libcpion.so
vendor/lib64/android.hardware.camera.provider@2.5-legacy.so
vendor/lib64/libswregistrationalgo.so
vendor/lib64/libsmartfocus_interface.so
vendor/lib64/libFacialStickerEngine.arcsoft.so
vendor/lib64/libjnihelper.so
vendor/lib64/libcamxswprocessalgo.so
vendor/lib64/libfloatingfeature.so
vendor/lib64/libbatching.so
vendor/lib64/libgarden.so
vendor/lib64/liblbs_core.so
vendor/lib64/liblivefocus_capture_engine.so
vendor/lib64/libhigh_dynamic_range_bokeh.so
vendor/lib64/vendor.qti.gnss@1.1.so
vendor/lib64/vendor.nxp.nxpnfc@1.1.so
vendor/lib64/libchiss3alogdebug.so
vendor/lib64/libcamxfdengine.so
vendor/lib64/libizat_client_api.so
vendor/lib64/libpvr.so
vendor/lib64/libgnsspps.so
vendor/lib64/camera.device@3.3-impl.so
vendor/lib64/libqfp_sensortest.so
vendor/lib64/libbauthtzcommon.so
vendor/lib64/camera.device@3.5-impl.so
vendor/lib64/libsns_device_mode_stub.so
vendor/lib64/libqti_vndfwk_detect.so
vendor/lib64/libqdma_file_agent.so
vendor/lib64/liblow_light_hdr.so
vendor/lib64/libsnsapi.so
vendor/lib64/libgf_in_system_lib.so
vendor/lib64/libLocalTM_capture_core.camera.samsung.so
vendor/lib64/libdualcam_optical_zoom.so
vendor/lib64/libOpenCv.camera.samsung.so
vendor/lib64/libsnpe_dsp_domains_v2.so
vendor/lib64/nfc_nci_nxp.so
vendor/lib64/camera.device@3.2-impl.so
vendor/lib64/camera.device@3.4-impl.so
vendor/lib64/vendor.qti.hardware.camera.device@1.0.so
vendor/lib64/libdualcam_optical_zoom_control.so
vendor/lib64/libcdfw_remote_api.so
vendor/lib64/libsns_fastRPC_util.so
vendor/lib64/libcamera_nn_stub.so
vendor/lib64/libremosaic_daemon.so
vendor/lib64/libcamxfdalgov8.so
vendor/lib64/libLocalTM_wrapper.camera.samsung.so
vendor/lib64/libgps.utils.so
vendor/lib64/vendor.samsung.hardware.camera.provider@4.0.so
vendor/lib64/vendor.samsung.hardware.camera.provider@4.0-legacy.so
vendor/lib64/libHpr_RecGAE_cvFeature_v1.0.camera.samsung.so
vendor/lib64/vendor.qti.gnss@2.1.so
vendor/lib64/liblowi_client.so
vendor/lib64/libc++_shared.so
vendor/lib64/liblivefocus_preview_interface.so
vendor/lib64/libizat_core.so
vendor/lib64/libFacePreProcessing.camera.samsung.so
vendor/lib64/libcamxtintlessalgo.so
vendor/lib64/vendor.qti.gnss@3.0.so
vendor/lib64/vendor.samsung.hardware.gnss@2.0.so
vendor/lib64/vendor.qti.gnss@1.0.so
vendor/lib64/libhigh_dynamic_range.so
vendor/lib64/libdataitems.so
vendor/lib64/vendor.qti.gnss@4.0.so
vendor/lib64/libsnsdiaglog.so
vendor/lib64/libbauthserver.so
vendor/lib64/libdrmfs.so
vendor/lib64/libHprFace_GAE_api.camera.samsung.so
vendor/lib64/libdualcapture.so
vendor/lib64/libcamxfdalgov7.so
vendor/lib64/libsynaFpSensorTestNwd.so
vendor/lib64/libswldc_capture_core.camera.samsung.so
vendor/lib64/libsns_low_lat_stream_stub.so
vendor/lib64/vendor.nxp.nxpnfc@1.0.so
vendor/lib64/liblivefocus_capture_interface.so
vendor/lib64/liblocationservice_glue.so
vendor/lib64/liblivefocus_preview_engine.so
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$blob" 0 2000 644 "u:object_r:vendor_lib_file:s0"
done

CONTEXTS_LIST="
system/lib/libsamsungSoundbooster_plus_legacy.so
system/lib/lib_SoundBooster_ver1000.so
system/lib64/libsamsungSoundbooster_plus_legacy.so
system/lib64/lib_SoundBooster_ver1000.so
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "system" "$blob" 0 0 644 "u:object_r:system_lib_file:s0"
done

CONTEXTS_LIST="
vendor/etc/audio_io_policy.conf
vendor/etc/media_codecs.xml
vendor/etc/libnfc-nci.conf
vendor/etc/init/hw/init.samsung.bsp.rc
vendor/etc/init/hw/init.target.rc
vendor/etc/init/hw/init.qcom.rc
vendor/etc/init/hw/init.qcom.factory.rc
vendor/etc/init/hw/init.a52q.rc
vendor/etc/init/hw/init.qti.ufs.rc
vendor/etc/init/hw/init.samsung.rc
vendor/etc/init/hw/init.qcom.usb.rc
vendor/etc/init/hw/init.samsung.display.rc
vendor/etc/init/nxp.android.hardware.nfc@1.1-service.rc
vendor/etc/init/android.hardware.drm@1.3-service.clearkey.rc
vendor/etc/init/android.hardware.drm@1.3-service.widevine.rc
vendor/etc/init/android.hardware.gnss@2.1-service-qti.rc
vendor/etc/audio_platform_info_diff.xml
vendor/etc/audconf/SER/workspaceFile.qwsp
vendor/etc/audconf/SER/Headset_cal.acdb
vendor/etc/audconf/SER/Bluetooth_cal.acdb
vendor/etc/audconf/SER/Global_cal.acdb
vendor/etc/audconf/SER/Speaker_cal.acdb
vendor/etc/audconf/SER/Hdmi_cal.acdb
vendor/etc/audconf/SER/General_cal.acdb
vendor/etc/audconf/SER/Handset_cal.acdb
vendor/etc/audconf/SER/Codec_cal.acdb
vendor/etc/audconf/AFR/workspaceFile.qwsp
vendor/etc/audconf/AFR/Headset_cal.acdb
vendor/etc/audconf/AFR/Bluetooth_cal.acdb
vendor/etc/audconf/AFR/Global_cal.acdb
vendor/etc/audconf/AFR/Speaker_cal.acdb
vendor/etc/audconf/AFR/Hdmi_cal.acdb
vendor/etc/audconf/AFR/General_cal.acdb
vendor/etc/audconf/AFR/Handset_cal.acdb
vendor/etc/audconf/AFR/Codec_cal.acdb
vendor/etc/audconf/SKZ/workspaceFile.qwsp
vendor/etc/audconf/SKZ/Headset_cal.acdb
vendor/etc/audconf/SKZ/Bluetooth_cal.acdb
vendor/etc/audconf/SKZ/Global_cal.acdb
vendor/etc/audconf/SKZ/Speaker_cal.acdb
vendor/etc/audconf/SKZ/Hdmi_cal.acdb
vendor/etc/audconf/SKZ/General_cal.acdb
vendor/etc/audconf/SKZ/Handset_cal.acdb
vendor/etc/audconf/SKZ/Codec_cal.acdb
vendor/etc/audconf/XFE/workspaceFile.qwsp
vendor/etc/audconf/XFE/Headset_cal.acdb
vendor/etc/audconf/XFE/Bluetooth_cal.acdb
vendor/etc/audconf/XFE/Global_cal.acdb
vendor/etc/audconf/XFE/Speaker_cal.acdb
vendor/etc/audconf/XFE/Hdmi_cal.acdb
vendor/etc/audconf/XFE/General_cal.acdb
vendor/etc/audconf/XFE/Handset_cal.acdb
vendor/etc/audconf/XFE/Codec_cal.acdb
vendor/etc/audconf/BTC/workspaceFile.qwsp
vendor/etc/audconf/BTC/Headset_cal.acdb
vendor/etc/audconf/BTC/Bluetooth_cal.acdb
vendor/etc/audconf/BTC/Global_cal.acdb
vendor/etc/audconf/BTC/Speaker_cal.acdb
vendor/etc/audconf/BTC/Hdmi_cal.acdb
vendor/etc/audconf/BTC/General_cal.acdb
vendor/etc/audconf/BTC/Handset_cal.acdb
vendor/etc/audconf/BTC/Codec_cal.acdb
vendor/etc/audconf/ECT/workspaceFile.qwsp
vendor/etc/audconf/ECT/Headset_cal.acdb
vendor/etc/audconf/ECT/Bluetooth_cal.acdb
vendor/etc/audconf/ECT/Global_cal.acdb
vendor/etc/audconf/ECT/Speaker_cal.acdb
vendor/etc/audconf/ECT/Hdmi_cal.acdb
vendor/etc/audconf/ECT/General_cal.acdb
vendor/etc/audconf/ECT/Handset_cal.acdb
vendor/etc/audconf/ECT/Codec_cal.acdb
vendor/etc/audconf/XFA/workspaceFile.qwsp
vendor/etc/audconf/XFA/Headset_cal.acdb
vendor/etc/audconf/XFA/Bluetooth_cal.acdb
vendor/etc/audconf/XFA/Global_cal.acdb
vendor/etc/audconf/XFA/Speaker_cal.acdb
vendor/etc/audconf/XFA/Hdmi_cal.acdb
vendor/etc/audconf/XFA/General_cal.acdb
vendor/etc/audconf/XFA/Handset_cal.acdb
vendor/etc/audconf/XFA/Codec_cal.acdb
vendor/etc/audconf/DKR/workspaceFile.qwsp
vendor/etc/audconf/DKR/Headset_cal.acdb
vendor/etc/audconf/DKR/Bluetooth_cal.acdb
vendor/etc/audconf/DKR/Global_cal.acdb
vendor/etc/audconf/DKR/Speaker_cal.acdb
vendor/etc/audconf/DKR/Hdmi_cal.acdb
vendor/etc/audconf/DKR/General_cal.acdb
vendor/etc/audconf/DKR/Handset_cal.acdb
vendor/etc/audconf/DKR/Codec_cal.acdb
vendor/etc/audconf/XFV/workspaceFile.qwsp
vendor/etc/audconf/XFV/Headset_cal.acdb
vendor/etc/audconf/XFV/Bluetooth_cal.acdb
vendor/etc/audconf/XFV/Global_cal.acdb
vendor/etc/audconf/XFV/Speaker_cal.acdb
vendor/etc/audconf/XFV/Hdmi_cal.acdb
vendor/etc/audconf/XFV/General_cal.acdb
vendor/etc/audconf/XFV/Handset_cal.acdb
vendor/etc/audconf/XFV/Codec_cal.acdb
vendor/etc/audconf/MID/workspaceFile.qwsp
vendor/etc/audconf/MID/Headset_cal.acdb
vendor/etc/audconf/MID/Bluetooth_cal.acdb
vendor/etc/audconf/MID/Global_cal.acdb
vendor/etc/audconf/MID/Speaker_cal.acdb
vendor/etc/audconf/MID/Hdmi_cal.acdb
vendor/etc/audconf/MID/General_cal.acdb
vendor/etc/audconf/MID/Handset_cal.acdb
vendor/etc/audconf/MID/Codec_cal.acdb
vendor/etc/audconf/AFG/workspaceFile.qwsp
vendor/etc/audconf/AFG/Headset_cal.acdb
vendor/etc/audconf/AFG/Bluetooth_cal.acdb
vendor/etc/audconf/AFG/Global_cal.acdb
vendor/etc/audconf/AFG/Speaker_cal.acdb
vendor/etc/audconf/AFG/Hdmi_cal.acdb
vendor/etc/audconf/AFG/General_cal.acdb
vendor/etc/audconf/AFG/Handset_cal.acdb
vendor/etc/audconf/AFG/Codec_cal.acdb
vendor/etc/audconf/SEK/workspaceFile.qwsp
vendor/etc/audconf/SEK/Headset_cal.acdb
vendor/etc/audconf/SEK/Bluetooth_cal.acdb
vendor/etc/audconf/SEK/Global_cal.acdb
vendor/etc/audconf/SEK/Speaker_cal.acdb
vendor/etc/audconf/SEK/Hdmi_cal.acdb
vendor/etc/audconf/SEK/General_cal.acdb
vendor/etc/audconf/SEK/Handset_cal.acdb
vendor/etc/audconf/SEK/Codec_cal.acdb
vendor/etc/audconf/CPW/workspaceFile.qwsp
vendor/etc/audconf/CPW/Headset_cal.acdb
vendor/etc/audconf/CPW/Bluetooth_cal.acdb
vendor/etc/audconf/CPW/Global_cal.acdb
vendor/etc/audconf/CPW/Speaker_cal.acdb
vendor/etc/audconf/CPW/Hdmi_cal.acdb
vendor/etc/audconf/CPW/General_cal.acdb
vendor/etc/audconf/CPW/Handset_cal.acdb
vendor/etc/audconf/CPW/Codec_cal.acdb
vendor/etc/audconf/THR/workspaceFile.qwsp
vendor/etc/audconf/THR/Headset_cal.acdb
vendor/etc/audconf/THR/Bluetooth_cal.acdb
vendor/etc/audconf/THR/Global_cal.acdb
vendor/etc/audconf/THR/Speaker_cal.acdb
vendor/etc/audconf/THR/Hdmi_cal.acdb
vendor/etc/audconf/THR/General_cal.acdb
vendor/etc/audconf/THR/Handset_cal.acdb
vendor/etc/audconf/THR/Codec_cal.acdb
vendor/etc/audconf/ACR/workspaceFile.qwsp
vendor/etc/audconf/ACR/Headset_cal.acdb
vendor/etc/audconf/ACR/Bluetooth_cal.acdb
vendor/etc/audconf/ACR/Global_cal.acdb
vendor/etc/audconf/ACR/Speaker_cal.acdb
vendor/etc/audconf/ACR/Hdmi_cal.acdb
vendor/etc/audconf/ACR/General_cal.acdb
vendor/etc/audconf/ACR/Handset_cal.acdb
vendor/etc/audconf/ACR/Codec_cal.acdb
vendor/etc/audconf/XSG/workspaceFile.qwsp
vendor/etc/audconf/XSG/Headset_cal.acdb
vendor/etc/audconf/XSG/Bluetooth_cal.acdb
vendor/etc/audconf/XSG/Global_cal.acdb
vendor/etc/audconf/XSG/Speaker_cal.acdb
vendor/etc/audconf/XSG/Hdmi_cal.acdb
vendor/etc/audconf/XSG/General_cal.acdb
vendor/etc/audconf/XSG/Handset_cal.acdb
vendor/etc/audconf/XSG/Codec_cal.acdb
vendor/etc/audconf/TUR/workspaceFile.qwsp
vendor/etc/audconf/TUR/Headset_cal.acdb
vendor/etc/audconf/TUR/Bluetooth_cal.acdb
vendor/etc/audconf/TUR/Global_cal.acdb
vendor/etc/audconf/TUR/Speaker_cal.acdb
vendor/etc/audconf/TUR/Hdmi_cal.acdb
vendor/etc/audconf/TUR/General_cal.acdb
vendor/etc/audconf/TUR/Handset_cal.acdb
vendor/etc/audconf/TUR/Codec_cal.acdb
vendor/etc/audconf/OPEN/workspaceFile.qwsp
vendor/etc/audconf/OPEN/Headset_cal.acdb
vendor/etc/audconf/OPEN/Bluetooth_cal.acdb
vendor/etc/audconf/OPEN/Global_cal.acdb
vendor/etc/audconf/OPEN/Speaker_cal.acdb
vendor/etc/audconf/OPEN/Hdmi_cal.acdb
vendor/etc/audconf/OPEN/General_cal.acdb
vendor/etc/audconf/OPEN/Handset_cal.acdb
vendor/etc/audconf/OPEN/Codec_cal.acdb
vendor/etc/audconf/CAU/workspaceFile.qwsp
vendor/etc/audconf/CAU/Headset_cal.acdb
vendor/etc/audconf/CAU/Bluetooth_cal.acdb
vendor/etc/audconf/CAU/Global_cal.acdb
vendor/etc/audconf/CAU/Speaker_cal.acdb
vendor/etc/audconf/CAU/Hdmi_cal.acdb
vendor/etc/audconf/CAU/General_cal.acdb
vendor/etc/audconf/CAU/Handset_cal.acdb
vendor/etc/audconf/CAU/Codec_cal.acdb
vendor/etc/audconf/EGY/workspaceFile.qwsp
vendor/etc/audconf/EGY/Headset_cal.acdb
vendor/etc/audconf/EGY/Bluetooth_cal.acdb
vendor/etc/audconf/EGY/Global_cal.acdb
vendor/etc/audconf/EGY/Speaker_cal.acdb
vendor/etc/audconf/EGY/Hdmi_cal.acdb
vendor/etc/audconf/EGY/General_cal.acdb
vendor/etc/audconf/EGY/Handset_cal.acdb
vendor/etc/audconf/EGY/Codec_cal.acdb
vendor/etc/audconf/TKD/workspaceFile.qwsp
vendor/etc/audconf/TKD/Headset_cal.acdb
vendor/etc/audconf/TKD/Bluetooth_cal.acdb
vendor/etc/audconf/TKD/Global_cal.acdb
vendor/etc/audconf/TKD/Speaker_cal.acdb
vendor/etc/audconf/TKD/Hdmi_cal.acdb
vendor/etc/audconf/TKD/General_cal.acdb
vendor/etc/audconf/TKD/Handset_cal.acdb
vendor/etc/audconf/TKD/Codec_cal.acdb
vendor/etc/audconf/CAC/workspaceFile.qwsp
vendor/etc/audconf/CAC/Headset_cal.acdb
vendor/etc/audconf/CAC/Bluetooth_cal.acdb
vendor/etc/audconf/CAC/Global_cal.acdb
vendor/etc/audconf/CAC/Speaker_cal.acdb
vendor/etc/audconf/CAC/Hdmi_cal.acdb
vendor/etc/audconf/CAC/General_cal.acdb
vendor/etc/audconf/CAC/Handset_cal.acdb
vendor/etc/audconf/CAC/Codec_cal.acdb
vendor/etc/audconf/PAK/workspaceFile.qwsp
vendor/etc/audconf/PAK/Headset_cal.acdb
vendor/etc/audconf/PAK/Bluetooth_cal.acdb
vendor/etc/audconf/PAK/Global_cal.acdb
vendor/etc/audconf/PAK/Speaker_cal.acdb
vendor/etc/audconf/PAK/Hdmi_cal.acdb
vendor/etc/audconf/PAK/General_cal.acdb
vendor/etc/audconf/PAK/Handset_cal.acdb
vendor/etc/audconf/PAK/Codec_cal.acdb
vendor/etc/audconf/LYS/workspaceFile.qwsp
vendor/etc/audconf/LYS/Headset_cal.acdb
vendor/etc/audconf/LYS/Bluetooth_cal.acdb
vendor/etc/audconf/LYS/Global_cal.acdb
vendor/etc/audconf/LYS/Speaker_cal.acdb
vendor/etc/audconf/LYS/Hdmi_cal.acdb
vendor/etc/audconf/LYS/General_cal.acdb
vendor/etc/audconf/LYS/Handset_cal.acdb
vendor/etc/audconf/LYS/Codec_cal.acdb
vendor/etc/audconf/ILO/workspaceFile.qwsp
vendor/etc/audconf/ILO/Headset_cal.acdb
vendor/etc/audconf/ILO/Bluetooth_cal.acdb
vendor/etc/audconf/ILO/Global_cal.acdb
vendor/etc/audconf/ILO/Speaker_cal.acdb
vendor/etc/audconf/ILO/Hdmi_cal.acdb
vendor/etc/audconf/ILO/General_cal.acdb
vendor/etc/audconf/ILO/Handset_cal.acdb
vendor/etc/audconf/ILO/Codec_cal.acdb
vendor/etc/audconf/KSA/workspaceFile.qwsp
vendor/etc/audconf/KSA/Headset_cal.acdb
vendor/etc/audconf/KSA/Bluetooth_cal.acdb
vendor/etc/audconf/KSA/Global_cal.acdb
vendor/etc/audconf/KSA/Speaker_cal.acdb
vendor/etc/audconf/KSA/Hdmi_cal.acdb
vendor/etc/audconf/KSA/General_cal.acdb
vendor/etc/audconf/KSA/Handset_cal.acdb
vendor/etc/audconf/KSA/Codec_cal.acdb
vendor/etc/audconf/TUN/workspaceFile.qwsp
vendor/etc/audconf/TUN/Headset_cal.acdb
vendor/etc/audconf/TUN/Bluetooth_cal.acdb
vendor/etc/audconf/TUN/Global_cal.acdb
vendor/etc/audconf/TUN/Speaker_cal.acdb
vendor/etc/audconf/TUN/Hdmi_cal.acdb
vendor/etc/audconf/TUN/General_cal.acdb
vendor/etc/audconf/TUN/Handset_cal.acdb
vendor/etc/audconf/TUN/Codec_cal.acdb
vendor/etc/msm_irqbalance.conf
vendor/etc/lowi.conf
vendor/etc/system_properties.xml
vendor/etc/media_profiles.xml
vendor/etc/mixer_paths_idp.xml
vendor/etc/gps.conf
vendor/etc/audio_effects.xml
vendor/etc/wifi/wpa_supplicant.conf
vendor/etc/wifi/p2p_supplicant_overlay.conf
vendor/etc/wifi/WCNSS_qcom_cfg.ini
vendor/etc/wifi/icm.conf
vendor/etc/wifi/indoorchannel.info
vendor/etc/wifi/wpa_supplicant_overlay.conf
vendor/etc/sec_config
vendor/etc/acdbdata/adsp_avs_config.acdb
vendor/etc/flp.conf
vendor/etc/fstab.qcom
vendor/etc/audio_effects.conf
vendor/etc/media_codecs_performance.xml
vendor/etc/SoundBoosterParam.txt
vendor/etc/libnfc-mtp-SN100.conf
vendor/etc/nfc/libnfc-nxp_RF.conf
vendor/etc/libnfc-nxp.conf
vendor/etc/audio_platform_info_intcodec.xml
vendor/etc/libnfc-qrd-SN100.conf
vendor/etc/sensors/sns_reg_config
vendor/etc/sensors/hals.conf
vendor/etc/sensors/config/sns_amd.json
vendor/etc/sensors/config/sns_ccd.json
vendor/etc/sensors/config/talos_lsm6dsm_0.json
vendor/etc/sensors/config/sns_rmd.json
vendor/etc/sensors/config/talos_ak991x_1.json
vendor/etc/sensors/config/sns_tilt.json
vendor/etc/sensors/config/sns_aont.json
vendor/etc/sensors/config/talos_ak991x_nfc_1.json
vendor/etc/sensors/config/sns_mag_cal.json
vendor/etc/sensors/config/sns_amd_sw_enabled.json
vendor/etc/sensors/config/sns_cm.json
vendor/etc/sensors/config/talos_ak991x_mst_0.json
vendor/etc/sensors/config/sns_tilt_sw_enabled.json
vendor/etc/sensors/config/sns_gyro_cal.json
vendor/etc/sensors/config/sns_tilt_sw_disabled.json
vendor/etc/sensors/config/sns_amd_sw_disabled.json
vendor/etc/sensors/config/talos_tcs3407_0.json
vendor/etc/sensors/config/talos_stk3x3x_0.json
vendor/etc/sensors/config/lsm6dsm_0.json
vendor/etc/sensors/config/talos_ak991x_0.json
vendor/etc/sensors/config/default_sensors.json
vendor/etc/sensors/config/talos_power_0.json
vendor/etc/sensors/config/talos_ak991x_mst_1.json
vendor/etc/sensors/config/sns_rotv.json
vendor/etc/sensors/config/sns_dae.json
vendor/etc/sensors/config/sns_diag_filter.json
vendor/etc/sensors/config/sns_geomag_rv.json
vendor/etc/sensors/config/sns_smd.json
vendor/etc/sensors/config/talos_ak991x_nfc_0.json
vendor/etc/sensors/config/sns_hw_revision.json
vendor/etc/gnss_antenna_info.conf
vendor/etc/libnfc-qrd-SN100_38_4MHZ.conf
vendor/etc/audio_platform_info.xml
vendor/etc/audio_policy_configuration.xml
vendor/etc/media_profiles_V1_0.xml
vendor/etc/libnfc-mtp-SN100_38_4MHZ.conf
vendor/etc/izat.conf
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$blob" 0 0 644 "u:object_r:vendor_configs_file:s0"
done

CONTEXTS_LIST="
vendor/firmware/CAMERA_ICP.elf
vendor/firmware/wlan/qca_cld/grippower.info
vendor/firmware/wlan/qca_cld/WCNSS_qcom_cfg.ini
vendor/firmware/wlan/qca_cld/regdb.bin
vendor/firmware/wlan/qca_cld/bdwlan.bin
vendor/firmware/nfc/libpn553_fw.so
vendor/firmware/wlanmdsp.mbn
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$blob" 0 0 644 "u:object_r:vendor_firmware_file:s0"
done

ADD_TO_WORK_DIR_CONTEXT "vendor" "vendor/bin/hw/android.hardware.gnss@2.1-service-qti" 0 2000 755 "u:object_r:vendor_hal_gnss_qti_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "vendor/bin/xtra-daemon" 0 2000 755 "u:object_r:vendor_location_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "vendor/bin/loc_launcher" 0 2000 755 "u:object_r:vendor_location_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "vendor/bin/lowi-server" 0 2000 755 "u:object_r:vendor_location_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "vendor/bin/hw/android.hardware.drm@1.3-service.clearkey" 0 2000 755 "u:object_r:vendor_hal_drm_clearkey_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "vendor/bin/hw/android.hardware.drm@1.3-service.widevine" 0 2000 755 "u:object_r:vendor_hal_drm_widevine_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "vendor/bin/hw/vendor.samsung.hardware.camera.provider@4.0-service" 0 2000 755 "u:object_r:hal_camera_default_exec:s0"
ADD_TO_WORK_DIR_CONTEXT "vendor" "vendor/bin/wvkprov" 0 2000 755 "u:object_r:wvkprov_exec:s0"

ADD_TO_WORK_DIR_CONTEXT "vendor" "vendor/overlay/framework-res__auto_generated_rro_vendor.apk" 0 2000 755 "u:object_r:vendor_file:s0"

CONTEXTS_LIST="
vendor/etc/audconf/SER
vendor/etc/audconf/AFR
vendor/etc/audconf/SKZ
vendor/etc/audconf/XFE
vendor/etc/audconf/BTC
vendor/etc/audconf/ECT
vendor/etc/audconf/XFA
vendor/etc/audconf/DKR
vendor/etc/audconf/XFV
vendor/etc/audconf/MID
vendor/etc/audconf/AFG
vendor/etc/audconf/SEK
vendor/etc/audconf/CPW
vendor/etc/audconf/THR
vendor/etc/audconf/ACR
vendor/etc/audconf/XSG
vendor/etc/audconf/TUR
vendor/etc/audconf/OPEN
vendor/etc/audconf/CAU
vendor/etc/audconf/EGY
vendor/etc/audconf/TKD
vendor/etc/audconf/CAC
vendor/etc/audconf/PAK
vendor/etc/audconf/LYS
vendor/etc/audconf/ILO
vendor/etc/audconf/KSA
vendor/etc/audconf/TUN
"
for context in $CONTEXTS_LIST
do
    ADD_TO_WORK_DIR_CONTEXT "vendor" "$blob" 0 2000 755 "u:object_r:vendor_configs_file:s0"
done

# Update NFC Prop
echo "Update NFC prop"
SET_PROP "ro.vendor.nfc.feature.chipname" "NXP_SN100U" "$WORK_DIR/vendor/build.prop"
SET_PROP "ro.vendor.nfc.support.ese" "true" "$WORK_DIR/vendor/build.prop"

# A70 doesn't provide any info about it's antenna position
SET_PROP -d "ro.vendor.nfc.info.antpos" "$WORK_DIR/vendor/build.prop"
SET_PROP -d "ro.vendor.nfc.info.antposX" "$WORK_DIR/vendor/build.prop"
SET_PROP -d "ro.vendor.nfc.info.antposY" "$WORK_DIR/vendor/build.prop"
SET_PROP -d "ro.vendor.nfc.info.deviceWidth" "$WORK_DIR/vendor/build.prop"
SET_PROP -d "ro.vendor.nfc.info.deviceHeight" "$WORK_DIR/vendor/build.prop"

