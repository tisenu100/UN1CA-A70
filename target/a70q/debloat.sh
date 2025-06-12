#
# Copyright (C) 2023 Salvo Giangreco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Debloat list for Galaxy A70 (a70q)
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Wi-Fi Overlay
SYSTEM_DEBLOAT+="
system/app/WifiRROverlayAppH2E
"

# Device Specific Overlay
PRODUCT_DEBLOAT+="
overlay/framework-res__a36xqnaxx__auto_generated_rro_product.apk
"

# Google Assistant
PRODUCT_DEBLOAT+="
priv-app/HotwordEnrollmentXGoogleEx6_WIDEBAND_SMALL
priv-app/HotwordEnrollmentYGoogleEx6_WIDEBAND_SMALL
"

# Face Unlock
SYSTEM_DEBLOAT+="
system/priv-app/FaceService
"

# Camera SDK
SYSTEM_DEBLOAT+="
system/etc/default-permissions/default-permissions-com.samsung.android.globalpostprocmgr.xml
system/etc/permissions/privapp-permissions-com.samsung.android.globalpostprocmgr.xml
system/lib64/libppvdis_wrapper.so
system/priv-app/GlobalPostProcMgr
"

# Single Take
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.singletake.service.xml
system/priv-app/SingleTakeService
"

# Photo Remaster Service
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.photoremasterservice.xml
system/priv-app/PhotoRemasterService
"

# Apps debloat
SYSTEM_DEBLOAT+="
system/etc/permissions/privapp-permissions-com.samsung.android.app.earphonetypec.xml
system/priv-app/EarphoneTypeC
system/priv-app/SohService
"

# Android Car
SYSTEM_DEBLOAT+="
system/etc/permissions/org.carconnectivity.android.digitalkey.rangingintent.xml
system/etc/permissions/org.carconnectivity.android.digitalkey.secureelement.xml
"

# Qualcomm Specific Services
SYSTEM_EXT_DEBLOAT+="
app/QCC
bin/qccsyshal@1.2-service
etc/init/qspa_system.rc
etc/init/usbudev.rc
etc/init/vendor.qti.hardware.qccsyshal@1.2-service.rc
etc/init/vendor.qti.qccsyshal_aidl-service.rc
etc/permissions/com.qti.location.sdk.xml
etc/permissions/com.qualcomm.location.xml
etc/permissions/privapp-permissions-com.qualcomm.location.xml
etc/vintf/manifest/vendor.qti.hardware.systemhelperaidl.xml
etc/vintf/manifest/vendor.qti.qccsyshal_aidl-service.xml
framework/com.qti.location.sdk.jar
framework/org.carconnectivity.android.digitalkey.rangingintent.jar
framework/org.carconnectivity.android.digitalkey.secureelement.jar
lib64/libqcc.so
lib64/libqcc_file_agent_sys.so
lib64/libqccdme.so
lib64/libqccfileservice.so
lib64/vendor.qti.hardware.qccsyshal@1.0.so
lib64/vendor.qti.hardware.qccsyshal@1.1.so
lib64/vendor.qti.hardware.qccsyshal@1.2-halimpl.so
lib64/vendor.qti.hardware.qccsyshal@1.2.so
lib64/vendor.qti.hardware.qccvndhal@1.0.so
lib64/vendor.qti.qccvndhal_aidl-V1-ndk.so
priv-app/com.qualcomm.location
priv-app/com.qualcomm.qti.services.systemhelper
"
