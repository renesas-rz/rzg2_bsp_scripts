#!/bin/bash

#---------------------------------------------------------------------------
# Please read the README.md file first for proper setup
#---------------------------------------------------------------------------

# The module (.ko) can be installed automatically on the target via scp
TARGET_INSTALL=FALSE
TARGET_IP_ADDRESS=192.168.10.125

# Do not edit below

set -ex

function save_setting_mmp() {

  if [ ! -e $SETTINGS_MMP_FILE ] ; then
    touch $SETTINGS_MMP_FILE # create file if does not exit
  fi

  sed '/^'"$1"'=/d' -i $SETTINGS_MMP_FILE
  echo  "$1=$2" >> $SETTINGS_MMP_FILE

  # Delete empty or blank lines
  sed '/^$/d' -i $SETTINGS_MMP_FILE

  # Sort the file to keep the same order
  sort -o $SETTINGS_MMP_FILE $SETTINGS_MMP_FILE
}


# Read in functions from build_common.sh
if [ ! -e build_common.sh ] ; then 
  echo -e "\n ERROR: File \"build_common.sh\" not found\n"
  exit
else
  source build_common.sh
fi

# Read our settings (board.ini) or whatever file SETTINGS_MMP_FILE was set to
read_setting

# First of all check that the kernel output directory exists
if [ ! -e ${KERNEL_DIR}/.out ] ; then 
  echo -e "\n Cannot build multimedia modules, kernel must be built first \n"
  exit
fi

# Define the defconfigs for Renesas boards
if [ "$MACHINE" == "hihope-rzg2m" ] ; then device=RZG2M ; fi
if [ "$MACHINE" == "hihope-rzg2n" ] ; then device=RZG2N ; fi
if [ "$MACHINE" == "hihope-rzg2h" ] ; then device=RZG2H ; fi
if [ "$MACHINE" == "ek874" ] ; then device=RZG2E ; fi
# RZ/G2L-LC not supported yet
if [ "$MACHINE" == "smarc-rzg2l" ] ; then echo "\n RZ/G2L not supported yet \n" ; fi
if [ "$MACHINE" == "smarc-rzg2lc" ] ; then echo "\n RZ/G2LC not supported yet \n" ; fi

# Set the output directory (because I like all my build files separate from the source code)
OUT=.mm

# Check for MACHINE setting
if [ "$MACHINE" == "" ] ; then
  echo ""
  echo "ERROR: Please set MACHINE in settings file ($SETTINGS_MMP_FILE)"
  echo ""
  exit
fi

# TO DO: allow other toolchains to be used, for now SDK only
# ============
#do_toolchain_menu() {
#  select_toolchain "MM_TOOLCHAIN_SETUP_NAME" "MM_TOOLCHAIN_SETUP"
#} 

#if [ "$UBOOT_TOOLCHAIN_SETUP_NAME" == "" ] ; then
#  whiptail --msgbox "Please select a Toolchain" 0 0 0
#  do_toolchain_menu
#  save_setting MM_TOOLCHAIN_SETUP_NAME "\"$MM_TOOLCHAIN_SETUP_NAME\""
#  save_setting MM_TOOLCHAIN_SETUP "\"$MM_TOOLCHAIN_SETUP\""
#fi

if [ ! $KERNEL_TOOLCHAIN_SETUP_NAME == "KERNEL_TOOLCHAIN_SETUP_NAME" ]; then
  echo -e "The SDK toolchain must be used, please select it and rebuild the kernel with it"
else
  SDK_SETUP=${KERNEL_TOOLCHAIN_SETUP}
fi
#=============

if [ -z "$(ls -A ./mm_packages)" ]; then
   echo "\n mm_packages is empty, please download and copy the multimedia package into it \n"
   exit
else
   pushd mm_packages
   tar -xvf "RZG2_Group_Evaluation_Software_Package_for_Linux_20200619.tar.gz"
   pushd proprietary
   unzip -o "*.zip"
   popd
   popd
fi


mkdir -p mmp
pushd mmp

SETTINGS_MMP_FILE="./config.ini"
# This is the path where the kernel is built
KERNEL_OUT_DIR=$PWD/../${KERNEL_DIR}/.out

save_setting_mmp device "\"$device\""
save_setting_mmp KERNEL_OUT_DIR "\"$KERNEL_OUT_DIR\""
save_setting_mmp SDK_SETUP "\"$SDK_SETUP\""
save_setting_mmp TARGET_INSTALL "\"$TARGET_INSTALL\""
save_setting_mmp TARGET_IP_ADDRESS "\"$TTARGET_IP_ADDRESS\""


mkdir -p build
mkdir -p gles
pushd gles
wget -N https://raw.githubusercontent.com/seebe/rzg_stuff/master/build_scripts/multimedia-modules/gles/build_gles.sh
chmod +x build_gles.sh
popd
mkdir -p mmngr
pushd mmngr
wget -N https://raw.githubusercontent.com/seebe/rzg_stuff/master/build_scripts/multimedia-modules/mmngr/build_mmngr.sh
chmod +x build_mmngr.sh
popd
mkdir -p qos
pushd qos
wget -N https://raw.githubusercontent.com/seebe/rzg_stuff/master/build_scripts/multimedia-modules/qos/build_qos.sh
chmod +x build_qos.sh
popd
mkdir -p uvcs
pushd uvcs
wget -N https://raw.githubusercontent.com/seebe/rzg_stuff/master/build_scripts/multimedia-modules/uvcs/build_uvcs.sh
chmod +x build_uvcs.sh
popd
mkdir -p vsp2
pushd vsp2
wget -N https://raw.githubusercontent.com/seebe/rzg_stuff/master/build_scripts/multimedia-modules/vsp2/build_vsp2.sh
chmod +x build_vsp2.sh
popd
mkdir -p vspm
pushd vspm
wget -N https://raw.githubusercontent.com/seebe/rzg_stuff/master/build_scripts/multimedia-modules/vspm/build_vspm.sh
chmod +x build_vspm.sh
popd
mkdir -p vspm_if
pushd vspm_if
wget -N https://raw.githubusercontent.com/seebe/rzg_stuff/master/build_scripts/multimedia-modules/vspm_if/build_vspm_if.sh
chmod +x build_vspm_if.sh
popd

mkdir -p patches
pushd patches
wget -N https://raw.githubusercontent.com/seebe/rzg_stuff/master/build_scripts/multimedia-modules/patches/patches.tar.gz
tar -xvf patches.tar.gz
popd 

# The sources are not available in github, so the tar file is required.
# It cannot be provided with the script because of licensing.
GLES_TAR_r8a774e1=../../mm_packages/proprietary/RCH3G001L4101ZDO_2_0_9/RCH3G001L4101ZDO/Software/GSX_KM_H3.tar.bz2
save_setting_mmp GLES_TAR_r8a774e1 "\"$GLES_TAR_r8a774e1\""
GLES_TAR_r8a774b1=../../mm_packages/proprietary/RCN3G001L4101ZDO_2_0_9/RCN3G001L4101ZDO/Software/GSX_KM_M3N.tar.bz2
save_setting_mmp GLES_TAR_r8a774b1 "\"$GLES_TAR_r8a774b1\""
GLES_TAR_r8a774a1=../../mm_packages/proprietary/RCM3G001L4101ZDO_2_0_9/RCM3G001L4101ZDO/Software/GSX_KM_M3.tar.bz2
save_setting_mmp GLES_TAR_r8a774a1 "\"$GLES_TAR_r8a774a1\""
GLES_TAR_r8a774c0=../../mm_packages/proprietary/RCE3G001L4101ZDO_2_0_9/RCE3G001L4101ZDO/Software/GSX_KM_E3.tar.bz2
save_setting_mmp GLES_TAR_r8a774c0 "\"$GLES_TAR_r8a774c0\""
UVCS_TAR=../../mm_packages/proprietary/RCG3VUDRL4101ZDO_3_0_17/RCG3VUDRL4101ZDO/Software/RCG3VUDRL4101ZDO.tar.bz2
save_setting_mmp UVCS_TAR "\"$UVCS_TAR\""

# These pathes are available in the VLP, path:
# meta-rzg2/recipes-kernel/kernel-module-gles/kernel-module-gles
GLES_PATCHES_PATH=../../patches/gles
save_setting_mmp GLES_PATCHES_PATH "\"$GLES_PATCHES_PATH\""

# These pathes are available in the VLP, path:
# meta-rzg2/recipes-kernel/kernel-module-mmngr/kernel-module-mmngr 
# meta-rzg2/recipes-kernel/kernel-module-mmngr/kernel-module-mmngrbuf 
MMNGR_PATCHES_PATH=../../patches/mmngr
save_setting_mmp MMNGR_PATCHES_PATH "\"$MMNGR_PATCHES_PATH\""

# These pathes are available in the VLP, path:
# meta-rzg2/recipes-kernel/kernel-module-qos/kernel-module-qos
QOS_PATCHES_PATH=../../patches/qos
save_setting_mmp QOS_PATCHES_PATH "\"$QOS_PATCHES_PATH\""

# These pathes are available in the VLP, path:
# meta-rzg2/recipes-kernel/kernel-module-uvcs/kernel-module-uvcs
UVCS_PATCHES_PATH=../../patches/uvcs
save_setting_mmp UVCS_PATCHES_PATH "\"$UVCS_PATCHES_PATH\""

# These pathes are available in the VLP, path:
# meta-rzg2/recipes-kernel/kernel-module-vspmif/kernel-module-vspmif 
VSPMIF_PATCHES_PATH=../../patches/vspmif
save_setting_mmp VSPMIF_PATCHES_PATH "\"$VSPMIF_PATCHES_PATH\""

pushd vspm
./build_vspm.sh
popd
pushd vspm_if
./build_vspm_if.sh
popd
pushd vsp2
./build_vsp2.sh
popd
pushd mmngr
./build_mmngr.sh
popd
pushd gles
./build_gles.sh
popd
pushd uvcs
./build_uvcs.sh
popd
pushd qos
./build_qos.sh
popd

exit

