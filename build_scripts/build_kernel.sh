#!/bin/bash
#---------------------------------------------------------------------------
# Please read the README.md file first for proper setup
#---------------------------------------------------------------------------

# Settings
# All build output files will be in .out (to keep them separate from the source code)
OUT=.out

# Direct where the config files are kept
CONFIG_DIR=.config_options

# Read in functions from build_common.sh
if [ ! -e build_common.sh ] ; then
  echo -e "\n ERROR: File \"build_common.sh\" not found\n."
  exit
else
  source build_common.sh
fi

# Read our settings (board.ini) or whatever file SETTINGS_FILE was set to
read_setting

# Identify the BSP type
BSP_TYPE=""
if [ "$MACHINE" == "hihope-rzg2m" ]   ; then BSP_TYPE="RZG2" ; DTB="multiple" ; fi
if [ "$MACHINE" == "hihope-rzg2n" ]   ; then BSP_TYPE="RZG2" ; DTB="multiple" ; fi
if [ "$MACHINE" == "hihope-rzg2h" ]   ; then BSP_TYPE="RZG2" ; DTB="multiple" ; fi
if [ "$MACHINE" == "ek874" ]          ; then BSP_TYPE="RZG2" ; DTB="multiple" ; fi
if [ "$MACHINE" == "smarc-rzg2l" ]    ; then BSP_TYPE="RZG2L" ; DTB="r9a07g044l2-smarc.dtb" ; fi
if [ "$MACHINE" == "smarc-rzg2lc" ]   ; then BSP_TYPE="RZG2L" ; DTB="r9a07g044c2-smarc.dtb" ; fi
if [ "$MACHINE" == "smarc-rzg2ul" ]   ; then BSP_TYPE="RZG2L" ; DTB="r9a07g043u11-smarc.dtb" ; fi
if [ "$MACHINE" == "smarc-rzv2l" ]    ; then BSP_TYPE="RZV2L" ; DTB="r9a07g054l2-smarc.dtb" ; fi
if [ "$MACHINE" == "smarc-rzg3s" ]    ; then BSP_TYPE="RZG3S" ; DTB="r9a08g045s33-smarc.dtb" ; fi
if [ "$MACHINE" == "dev-rzt2h" ]      ; then BSP_TYPE="RZT2H" ; DTB="r9a09g077m44-dev.dtb" ; fi
if [ "$MACHINE" == "rzv2h-evk-ver1" ] ; then BSP_TYPE="RZV2H" ; DTB="r9a09g057h4-evk-ver1.dtb" ; fi

do_toolchain_menu() {

  select_toolchain "KERNEL_TOOLCHAIN_SETUP_NAME" "KERNEL_TOOLCHAIN_SETUP"

}

# Use common toolchain if specific toolchain not set
if [ "$KERNEL_TOOLCHAIN_SETUP_NAME" == "" ] ; then
  if [ "$COMMON_TOOLCHAIN_SETUP_NAME" != "" ] ; then
    KERNEL_TOOLCHAIN_SETUP_NAME=$COMMON_TOOLCHAIN_SETUP_NAME
    KERNEL_TOOLCHAIN_SETUP=$COMMON_TOOLCHAIN_SETUP
  else
    whiptail --msgbox "Please select a Toolchain" 0 0 0
    do_toolchain_menu
    save_setting KERNEL_TOOLCHAIN_SETUP_NAME "\"$KERNEL_TOOLCHAIN_SETUP_NAME\""
    save_setting KERNEL_TOOLCHAIN_SETUP "\"$KERNEL_TOOLCHAIN_SETUP\""
  fi
fi

# Help Menu
if [ "$1" == "" ] ; then
  echo "
Standard kernel make command options:
	defconfig                # Configure the kernel (Must do first before you can build)
	all                      # Build the kernel and Device Trees
	dtbs                     # Build the Device Trees
	menuconfig               # Kernel Configuration Tool
	clean                    # make clean
	distclean                # make distclean (clean but also deletes .config)

Special Renesas command options:
	deploy                   # copy all the output files to $OUT_DIR

Example build:
  $ ./build.sh k defconfig
  $ ./build.sh k all
  $ ./build.sh k deploy"
  exit
fi


echo "cd $KERNEL_DIR"
cd $KERNEL_DIR

if [ "${KERNEL_TOOLCHAIN_SETUP_NAME:0:4}" == "Poky" ] ; then
  # The environment-setup script does not work with the kernel.
  echo "INFO: Using Poky Toolchain binaries directly (not environment-setup)"

  # Get path from KERNEL_TOOLCHAIN_SETUP
  POKY_PATH=$(echo $KERNEL_TOOLCHAIN_SETUP | sed "s:source ::" | sed "s:/environment-setup-aarch64-poky-linux::" )

  # Set path and CROSS_COMPILE, asm as if we were using Linaro
  PATH=${POKY_PATH}/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux:$PATH
  export CROSS_COMPILE="aarch64-poky-linux-"
else
  echo "$KERNEL_TOOLCHAIN_SETUP"
  eval $KERNEL_TOOLCHAIN_SETUP
fi

export ARCH=arm64

# Check that the binutils in the toolchain supports the linker option "--fix-cortex-a53-843419".
# NOTE: In binutils 2.25, the option "--fix-cortex-a53" was added, but in 2.26 it was renamed to "--fix-cortex-a53-843419".
# https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=7a2a1c793578a8468604e661dda025ecb8d0bd20
${CROSS_COMPILE}ld --fix-cortex-a53-843419 2>&1 >/dev/null | grep 'unrecognized option' >/dev/null
if [ "$?" == "0" ] ; then
	echo "ERROR: Toolchain does not support option --fix-cortex-a53-843419"
	echo "Please use an SDK from VLP64 1.0.4 or later"
	exit
fi

# As for GCC 4.9, you can get a colorized output
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Find out how many CPU processor cores we have on this machine
# so we can build faster by using multithreaded builds
NPROC=2
if [ "$(which nproc)" != "" ] ; then  # make sure nproc is installed
  NPROC=$(nproc)
fi
BUILD_THREADS=$(expr $NPROC + $NPROC)

# Let the Makefile handle setting up the CFLAGS and LDFLAGS as it is a standalone application
unset CFLAGS
unset CPPFLAGS
unset LDFLAGS
unset AS
unset LD

if [ "$1" == "deploy" ] ; then

  mkdir -p $OUT_DIR

  # Kernel (rename to match Yocto output...but it's all the same kernel)
  cp -v "$OUT/arch/arm64/boot/Image" "$OUT_DIR"
  cp -v "$OUT/arch/arm64/boot/Image" "$OUT_DIR/Image-${MACHINE}.bin"

  # Device Tree
  case "$MACHINE" in
    hihope-rzg2m)
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774a1-hihope-rzg2m.dtb    $OUT_DIR/Image-r8a774a1-hihope-rzg2m.dtb
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774a1-hihope-rzg2m-ex.dtb $OUT_DIR/Image-r8a774a1-hihope-rzg2m-ex.dtb
      ;;
    hihope-rzg2n)
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774b1-hihope-rzg2n.dtb    $OUT_DIR/Image-r8a774b1-hihope-rzg2n.dtb
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774b1-hihope-rzg2n-ex.dtb $OUT_DIR/Image-r8a774b1-hihope-rzg2n-ex.dtb
      ;;
    hihope-rzg2h)
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774e1-hihope-rzg2h.dtb    $OUT_DIR/Image-r8a774e1-hihope-rzg2h.dtb
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774e1-hihope-rzg2h-ex.dtb $OUT_DIR/Image-r8a774e1-hihope-rzg2h-ex.dtb
      ;;
    ek874)
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774c0-cat874.dtb      $OUT_DIR/Image-r8a774c0-cat874.dtb
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774c0-ek874.dtb       $OUT_DIR/Image-r8a774c0-ek874.dtb
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774c0-es10-cat874.dtb $OUT_DIR/Image-r8a774c0-es10-cat874.dtb
      cp -v $OUT/arch/arm64/boot/dts/renesas/r8a774c0-es10-ek874.dtb  $OUT_DIR/Image-r8a774c0-es10-ek874.dtb
      ;;
    *)
      cp -v "$OUT/arch/arm64/boot/dts/renesas/${DTB}" "$OUT_DIR"
      cp -v "$OUT/arch/arm64/boot/dts/renesas/${DTB}" "$OUT_DIR/Image-${DTB}"
      ;;
  esac

  #cp -v "$OUT/arch/arm64/boot/dts/renesas/r9a*.dtb" "$OUT_DIR"

  # Modules
  mkdir -p $OUT_DIR/kernel_modules
  make O=$OUT INSTALL_MOD_PATH=$OUT_DIR/kernel_modules/ modules_install

    # "deploy" is not a kernel make command, so always exit
    exit
fi

# Add '-s' for silent Build
MAKE="make -j$BUILD_THREADS O=$OUT"

# If this is the first time building, we need to configure first
if [ ! -e "$OUT/.config" ] && [ "$1" != "defconfig" ] ; then
  echo "ERROR: First you must run: ./build.sh k make_config"
  exit
fi
CMD="$MAKE $1 $2 $3"
echo $CMD ; $CMD
