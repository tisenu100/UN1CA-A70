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


