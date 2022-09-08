#!/bin/bash

#---------------------------------------------------------------------------
# Please read the README.md file first for proper setup
#---------------------------------------------------------------------------

# MACHINE=hihope-rzg2m
# MACHINE=hihope-rzg2n
# MACHINE=hihope-rzg2h
# MACHINE=ek874
# MACHINE=smarc-rzg2l
#   BOARD_VERSION: DISCRETE, PMIC, WS1
# MACHINE=smarc-rzg2lc
# MACHINE=smarc-rzg2ul
# MACHINE=smarc-rzgvl
#   BOARD_VERSION: DISCRETE, PMIC

#TFA_BOOT: 0=SPI Flash, 1=eMMC
#TFA_ECC_FULL: 0=no ECC, 1=ECC dual channel, 2=ECC single channel
#TFA_FIP: 0=no FIP, 1= yes FIP

# Read in functions from build_common.sh
if [ ! -e build_common.sh ] ; then
  echo -e "\n ERROR: File \"build_common.sh\" not found\n."
  exit
else
  source build_common.sh
fi

# Read our settings (board.ini) or whatever file SETTINGS_FILE was set to
read_setting

if [ "$MACHINE" == "" ] ; then
  echo "You need to set MACHINE first"
  exit
fi

##############################
# Defaults
##############################
if [ "$TFA_BOOT" == "" ] ; then
  TFA_BOOT=0
fi
if [ "$TFA_ECC_FULL" == "" ] ; then
  TFA_ECC_FULL=0
fi
if [ "$TFA_LOG_LEVEL" == "" ] ; then
  TFA_LOG_LEVEL=20
fi
if [ "$TFA_DEBUG" == "" ] ; then
  TFA_DEBUG=0
fi
if [ "$TFA_FIP" == "" ] ; then

  if [ "$MACHINE" == "smarc-rzg2l" ] || [ "$MACHINE" == "smarc-rzg2lc" ] || [ "$MACHINE" == "smarc-rzv2l" ] || [ "$MACHINE" == "smarc-rzg2ul" ]; then
    TFA_FIP=1
  else
    TFA_FIP=0
  fi
fi


###############################
# Trusted Firmware Version
##############################

# Get version number from Makefile
TFA_VERSION_MAJOR=`grep "^VERSION_MAJOR" $TFA_DIR/Makefile | awk '{print $3}'`
TFA_VERSION_MINOR=`grep "^VERSION_MINOR" $TFA_DIR/Makefile | awk '{print $3}'`
TFA_VERSION="$TFA_VERSION_MAJOR.$TFA_VERSION_MINOR"
#echo TFA_VERSION=$TFA_VERSION

# Some setting names switched from RZG_xx to RCAR_xxx after the code mainlined for release 2.5 since the
# same code alrady exists for R-Car in mainline, so they just used the same names
if [ "$TFA_VERSION" \< "2.5" ] ; then
  TFA_BEFORE_2_5="1"
fi

###############################
# Text strings
##############################
BOOT_TEXT_STR=("SPI Flash" "eMMC Flash")
ECC_TEXT_STR=("no ECC" "ECC dual channel" "ECC single channel")
DEBUG_STR=("Release Build" "Debug Build")


##############################
do_toolchain_menu() {
  select_toolchain "TFA_TOOLCHAIN_SETUP_NAME" "TFA_TOOLCHAIN_SETUP"
}


##############################
do_boot_menu() {
  SELECT=$(whiptail --title "Boot Flash Selection" --menu "You may use ESC+ESC to cancel.\n\nA Blank entry means use default board settings." 0 0 0 \
	"1  ${BOOT_TEXT_STR[0]}" "" \
	"2  ${BOOT_TEXT_STR[1]}" "" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) TFA_BOOT=0 ;;
      2\ *) TFA_BOOT=1 ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##############################
do_ecc_menu() {
  SELECT=$(whiptail --title "ECC Selection" --menu "You may use ESC+ESC to cancel.\n\nA Blank entry means use default board settings." 0 0 0 \
	"1  ${ECC_TEXT_STR[0]}" "" \
	"2  ${ECC_TEXT_STR[1]}" "" \
	"3  ${ECC_TEXT_STR[2]}" "" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) TFA_ECC_FULL=0 ;;
      2\ *) TFA_ECC_FULL=1 ;;
      3\ *) TFA_ECC_FULL=2 ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##############################
do_log_menu() {
  SELECT=$(whiptail --title "Log Level Selection" --menu "You may use ESC+ESC to cancel.\n\nA Blank entry means use default board settings." 0 0 0 \
	"0"  " No functions output logs" \
	"10" "ERROR()" \
	"20" "ERROR(), NOTICE()" \
	"30" "ERROR(), NOTICE(), WARN()" \
	"40" "ERROR(), NOTICE(), WARN(), INFO()" \
	"50" "ERROR(), NOTICE(), WARN(), INFO(), VERBOSE()" \
	"default" "Use Makefile default" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      0) TFA_LOG_LEVEL=0 ;;
      10) TFA_LOG_LEVEL=10 ;;
      20) TFA_LOG_LEVEL=20 ;;
      30) TFA_LOG_LEVEL=30 ;;
      40) TFA_LOG_LEVEL=40 ;;
      50) TFA_LOG_LEVEL=50 ;;
      default) TFA_LOG_LEVEL=20 ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##############################
do_debug_menu() {
  SELECT=$(whiptail --title "Debug Selection" --menu "You may use ESC+ESC to cancel.\n\nA Blank entry means use default board settings." 0 0 0 \
	"1  ${DEBUG_STR[0]}" "" \
	"2  ${DEBUG_STR[1]}" "(Add debug symbols to build)" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) TFA_DEBUG=0 ;;
      2\ *) TFA_DEBUG=1 ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}


##############################
create_bootparams() {

  # Create bootparams.bin
  # - bootparams.bin totls size is 512 bytes
  # - First 4 bytes is the size of bl2.bin (4-byte aligned)
  # - Last 2 bytes are 0x55, 0xAA
  # - Middle of the file is 0xFF

  if [ "$TFA_DEBUG" == "1" ] ; then
    cd build/${PLATFORM}/debug
  else
    cd build/${PLATFORM}/release
  fi

  echo -e "\n[Creating bootparams.bin]"
  SIZE=$(stat -L --printf="%s" bl2.bin)
  SIZE_ALIGNED=$(expr $SIZE + 3)
  SIZE_ALIGNED2=$((SIZE_ALIGNED & 0xFFFFFFFC))
  SIZE_HEX=$(printf '%08x\n' $SIZE_ALIGNED2)
  echo "  bl2.bin size=$SIZE, Aligned size=$SIZE_ALIGNED2 (0x${SIZE_HEX})"
  STRING=$(echo \\x${SIZE_HEX:6:2}\\x${SIZE_HEX:4:2}\\x${SIZE_HEX:2:2}\\x${SIZE_HEX:0:2})
  printf "$STRING" > bootparams.bin
  for i in `seq 1 506` ; do printf '\xff' >> bootparams.bin ; done
  printf '\x55\xaa' >> bootparams.bin

  # Combine bootparams.bin and bl2.bin into single binary
  # Only if a new version of bl2.bin is created
  if [ "bl2.bin" -nt "bl2_bp.bin" ] || [ ! -e "bl2_bp.bin" ] ; then
    echo -e "\n[Adding bootparams.bin to bl2.bin]"
    cat bootparams.bin bl2.bin > bl2_bp.bin
  fi

  cd ../../..
}

##############################
create_fip_and_copy() {

  if [ "$TFA_DEBUG" == "1" ] ; then
    BUILD_DIR=debug
  else
    BUILD_DIR=release
  fi

  # Build the Fip Tool
  echo -e "\n[Building FIP tool]"
  cd tools/fiptool
  make PLAT=${PLATFORM}
  cd ../..

  EXTRA=""

  # RZ/G2L PMIC board have _pmic at the end of the filename
  if [ "$MACHINE" == "smarc-rzg2l" ] && [ "$BOARD_VERSION" == "PMIC" ] ; then
    EXTRA="_pmic"
  fi

  # RZ/V2L PMIC board have _pmic at the end of the filename
  if [ "$MACHINE" == "smarc-rzv2l" ] && [ "$BOARD_VERSION" == "PMIC" ] ; then
    EXTRA="_pmic"
  fi

  echo -e "[Create fip.bin]"
  tools/fiptool/fiptool create --align 16 --soc-fw build/${PLATFORM}/$BUILD_DIR/bl31.bin --nt-fw ../$OUT_DIR/u-boot.bin fip.bin
  cp fip.bin ../$OUT_DIR/fip-${MACHINE}${EXTRA}.bin

  echo -e "[Copy BIN file]"
  cp -v build/${PLATFORM}/$BUILD_DIR/bl2_bp.bin ../$OUT_DIR/bl2_bp-${MACHINE}${EXTRA}.bin

  echo -e "[Copy BIN file (no boot parameters)]"
  cp -v build/${PLATFORM}/$BUILD_DIR/bl2.bin ../$OUT_DIR/bl2-${MACHINE}${EXTRA}.bin

  echo -e "[Copy boot parameters]"
  cp -v build/${PLATFORM}/$BUILD_DIR/bootparams.bin ../$OUT_DIR/bootparams-${MACHINE}${EXTRA}.bin

  echo -e "[Convert BIN to SREC format]"
  #<BL2>
  ${CROSS_COMPILE}objcopy -I binary -O srec --adjust-vma=0x00011E00 --srec-forceS3 build/${PLATFORM}/$BUILD_DIR/bl2_bp.bin ../$OUT_DIR/bl2_bp-${MACHINE}${EXTRA}.srec

  #<FIP>
  ${CROSS_COMPILE}objcopy -I binary -O srec --adjust-vma=0x00000000 --srec-forceS3 fip.bin ../$OUT_DIR/fip-${MACHINE}${EXTRA}.srec
}


# Use common toolchain if specific toolchain not set
if [ "$TFA_TOOLCHAIN_SETUP_NAME" == "" ] ; then
  if [ "$COMMON_TOOLCHAIN_SETUP_NAME" != "" ] ; then
    TFA_TOOLCHAIN_SETUP_NAME=$COMMON_TOOLCHAIN_SETUP_NAME
    TFA_TOOLCHAIN_SETUP=$COMMON_TOOLCHAIN_SETUP
  else
    whiptail --msgbox "Please select a Toolchain" 0 0 0
    do_toolchain_menu
  fi
fi

##############################
# GUI
##############################
# If no arguments passed, use GUI interface
if [ "$1" == "" ] ; then

  while true ; do

    # In case of no setting, display as 'default'
    if [ "$TFA_BOOT" == "" ] ; then BOOT_TEXT="(default)" ; else BOOT_TEXT="${BOOT_TEXT_STR[$TFA_BOOT]}" ; fi
    if [ "$TFA_LOG_LEVEL" == "" ] ; then LOG_TEXT="(default)" ; else LOG_TEXT="$TFA_LOG_LEVEL" ; fi
    if [ "$TFA_ECC_FULL" == "" ] ; then ECC_TEXT="(default)" ; else ECC_TEXT="${ECC_TEXT_STR[$TFA_ECC_FULL]}" ; fi

    if [ "$BOARD_VERSION" != "" ] ; then
      BOARD_VERSION_TEXT="($BOARD_VERSION)"
    else
      BOARD_VERSION_TEXT=""
   fi

    SELECT=$(whiptail --title "Trusted Firmware-A Configuration" --menu "Select your build options.\nYou may use [ESC]+[ESC] to cancel/exit.\nUse [Tab] key to select buttons at the bottom.\n\nUse the <Change> button (or enter) to make changes.\nUse the <Build> button to start the build." 0 0 0 --cancel-button Build --ok-button Change \
	"1.              Select your board:" "  $MACHINE $BOARD_VERSION_TEXT"\
	"2.                    Boot Device:" "  $BOOT_TEXT" \
	"3.                   TFA_ECC_FULL:" "  $ECC_TEXT"  \
	"4.                      Log Level:" "  $TFA_LOG_LEVEL" \
	"5.                          Build:" "  ${DEBUG_STR[$TFA_DEBUG]}" \
	"6.                Toolchain setup:" "  $TFA_TOOLCHAIN_SETUP_NAME" \
	3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ] ; then
      # Save to our settings file
      save_setting TFA_BOOT "$TFA_BOOT"
      save_setting TFA_ECC_FULL "$TFA_ECC_FULL"
      save_setting TFA_LOG_LEVEL "$TFA_LOG_LEVEL"
      save_setting TFA_DEBUG "$TFA_DEBUG"
      save_setting TFA_FIP "$TFA_FIP"
      if [ "$TFA_TOOLCHAIN_SETUP_NAME" != "$COMMON_TOOLCHAIN_SETUP_NAME" ] ; then
        save_setting TFA_TOOLCHAIN_SETUP_NAME "\"$TFA_TOOLCHAIN_SETUP_NAME\""
        save_setting TFA_TOOLCHAIN_SETUP "\"$TFA_TOOLCHAIN_SETUP\""
      fi
      break;
    elif [ $RET -eq 0 ] ; then
      case "$SELECT" in
        1.\ *) echo "" ;;
        2.\ *) do_boot_menu ;;
        3.\ *) do_ecc_menu ;;
        4.\ *) do_log_menu ;;
        5.\ *) do_debug_menu ;;
        6.\ *) do_toolchain_menu ;;
        *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
    else
      exit 1
    fi

  done
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


# PLAT
#	Set string is "rcar" (VLP v1.0.0-4) or "rzg" (VLP v1.0.5+)

# LOG_LEVEL
#	The IPL provides logging functions ERROR(), NOTICE(), WARN(), INFO() and VERBOSE().
#	50 is all functions for output logs
#
#	Log level   Valid logging function
#	-------------------------------------------------------
#	0           No functions output logs
#	10          ERROR()
#	20          ERROR(), NOTICE()
#	30          ERROR(), NOTICE(), WARN()
#	40          ERROR(), NOTICE(), WARN(), INFO()
#	50          ERROR(), NOTICE(), WARN(), INFO(), VERBOSE()

# DEBUG
#	Set value is 0 or 1. 0 is a release build, and 1 is a debug build
#	If LOG_LEVEL value hasn??t been set, LOG_LEVEL is set as the DEBUG value in the following table
#
#	DEBUG build    LOG_LEVEL  Valid logging functions
#	-------------------------------------------------------
#	0     release  20         ERROR(), NOTICE()
#	1     debug    40         ERROR(), NOTICE(), WARN(), INFO()

# SPD
#	The IPL provides configuration to load image of BL32
#	Set string is ??none?? or ??opteed??.
#	"none" = Does not load the image of BL32
#	"opteed" = Load the image of BL32 from HyperFlash / QSPI Flash / eMMC

# RCAR_QOS_TYPE
#	AXI-bus has the QoS arbitration to control latency and bandwidth.
#	0 = Enable the QoS arbitration setting (Default setting)
#	3 = Disable the QoS arbitration setting


# RZG_DRAM_SPLIT
# RCAR_DRAM_SPLIT  (before BSP 1.0.7)
#	DRAM split setting in the SDRAM setting
#	0 = Linear (No split)
#	1 = 4 channel split
#	2 = 2 channel split
#	3 = R-Car H3: 4 channel split / R-Car M3: 2 channel split / R-Car M3N:Linear / R-Car E3: Linear

# PMIC_ROHM_BD9571
#	This option represents the range of code implementation depending on the PMIC (ROHM BD9571) mounted on the
#	evaluation board described in 3.1 hardware environment.


# RCAR_AVS_SETTING_ENABLE
#	PMIC initial voltage setting
#	This option must be set to disabled in the case of R-Car E3.
#	0 = disable
#	1 = enable


# LSI
#	G2E,G2M,G2N,G2H

# RZG_SA6_TYPE:
# RCAR_SA6_TYPE:   (before BSP 1.0.7)
#	0 = for Hyper Flash / QPSI Flash boot (Default setting)
#	1 = for eMMC boot

# RCAR_BL33_EXECUTION_EL
#	Set the exception level of BL33
#	0 = EL1 (Default setting)
#	1 = EL2
#

# RCAR_SYSTEM_SUSPEND
#	0 = No Suspend to RAM
#	1 = Suspend to RAM

# RCAR_REF_INT
#	Select DRAM refresh interval.
#	0 = Default setting (H3, M3, M3N 1.95us / E3 3.90us)
#	1 = Optional setting (H3, M3, M3N 3.90us / E3 7.80us)

# RCAR_REWT_TRAINING
#	Select "periodic write DQ training" mode.
#	0 = not available
#	1 = available (Default setting)

# RCAR_BL2_DCACHE
#	enables MMU and D-cache (L1 data cache / L2 cache) on IPL.
#	0 = Disable the D-cache setting (Default setting)
#	1 = Enable the D-cache setting

# RCAR_SA0_SIZE
#	Switch the IPL size of dummy certificate
#	0 = For R-Car E3, IPL size is 80KB.
#	1 = For R-Car H3/M3/M3N, IPL size is 170KB. (Default setting)

# RCAR_DRAM_DDR3L_MEMCONF
#	Select DRAM memory size.
#	0 = 1G Byte
#	1 = 2G Byte (Default setting)

# RCAR_DRAM_DDR3L_MEMDUAL
#	Select the SoC output (the number of connected SDRAM on board)
#	0 = CS0, ODT0 enable and CS1, ODT1 disable (SDRAM 2pieces)
#	1 = CS0, ODT0, CS1, ODT1 enable (SDRAM 4pieces) (Default setting)

# RCAR_DRAM_LPDDR4_MEMCONF
#	(RZ/G2H only)
#	The LPDDR4 settings code included in the IPL release supports 2 types of memory configurations for R-Car H3
#	0 = 1G Byte x 4 channel : 4GB
#	1 = 2G Byte x4 channel : 8GB (Default setting)

echo "cd $TFA_DIR"
cd $TFA_DIR

if [ "$TFA_FIP" == "1" ] && [ ! -e "../$OUT_DIR/u-boot.bin" ] ; then
  echo -e "\nERROR: You must build u-boot first since it is added to the BL31/FIP image".
  exit
fi


# ECC and video decompression settings
if [ "$TFA_ECC_FULL" != "0" ] ; then
  G2E_ECC="LIFEC_DBSC_PROTECT_ENABLE=0 RZG_DRAM_ECC=1"
  G2M_ECC="LIFEC_DBSC_PROTECT_ENABLE=0 RCAR_DRAM_SPLIT=0 RZG_DRAM_ECC=1"
  G2N_ECC="LIFEC_DBSC_PROTECT_ENABLE=0 RZG_DRAM_ECC=1"
  G2H_ECC="LIFEC_DBSC_PROTECT_ENABLE=0 RCAR_DRAM_SPLIT=0 RZG_DRAM_ECC=1"
else
  # If ECC is not set, we will assume that we want to reserve a
  # Lossy Decompression area for multimedia.
  G2E_LOSSY=""   # not needed for RZ/G2E
  G2M_LOSSY="RCAR_LOSSY_ENABLE=1"
  G2N_LOSSY="RCAR_LOSSY_ENABLE=1"
  G2H_LOSSY="RCAR_LOSSY_ENABLE=1"
fi

# Board Settings
case "$MACHINE" in
  "smarc-rzg2l")

    # Old directory structure
    if [ -e plat/renesas/rzg2l/platform.mk ] ; then
      PLATFORM=rzg2l
      # "BOARD_RZG2L_EVA" was renamed to "RZG2L_SMARC_EVK"
      # "BOARD_RZG2L_15MMSQ" was renamed to "RZG2L_DEVELOPMENT_BOARD"
      # "BOARD_RZG2LC_13MMSQ" was renamed to "RZG2LC_DEVELOPMENT_BOARD"
      grep -q "BOARD_RZG2L_EVA" plat/renesas/rzg2l/platform.mk
      if [ "$?" == "0" ] ; then
        # old
        TFA_OPT="BOARD_TYPE=BOARD_RZG2L_EVA"
        #TFA_OPT="BOARD_TYPE=BOARD_RZG2L_15MMSQ"
        #TFA_OPT="BOARD_TYPE=BOARD_RZG2LC_13MMSQ"
      else
        # new
        TFA_OPT="BOARD_TYPE=RZG2L_SMARC_EVK"
        #TFA_OPT=BOARD_TYPE=RZG2L_DEVELOPMENT_BOARD"
        #TFA_OPT=BOARD_TYPE=RZG2LC_DEVELOPMENT_BOARD"
      fi
    fi

    # New directory structure
    if [ -e plat/renesas/rz ] ; then
      PLATFORM=g2l
      if [ "$BOARD_VERSION" == "PMIC" ] ; then
        TFA_OPT="BOARD=smarc_pmic_2"
      else
        TFA_OPT="BOARD=smarc_2"
      fi

    # Internal Renesas Boards
    #TFA_OPT="BOARD=dev15_4" #rzg2l-dev
    #TFA_OPT="BOARD=dev13_1" #rzg2lc-dev
  fi

    #PLATFORM=g2l
    TOOL=
    ;;

  "smarc-rzg2lc")
    PLATFORM=g2l
    TFA_OPT="BOARD=smarc_1"

    TOOL=
    ;;

  "smarc-rzg2ul")
    PLATFORM=g2ul
    TFA_OPT="BOARD=g2ul_smarc SOC_TYPE=1 SPI_FLASH=AT25QL128A"

    TOOL=
    ;;

  "smarc-rzv2l")
   PLATFORM=v2l
   if [ "$BOARD_VERSION" == "PMIC" ] ; then
     TFA_OPT="BOARD=smarc_pmic_2"
   else
     TFA_OPT="BOARD=smarc_4"
   fi

    # Internal Renesas Boards
    #TFA_OPT="BOARD=dev15_4" #rzv2l-dev

    TOOL=
    ;;

  "ek874")
    TFA_OPT="LSI=G2E RCAR_DRAM_DDR3L_MEMCONF=1 RCAR_DRAM_DDR3L_MEMDUAL=1 SPD="none" $G2E_ECC $G2E_LOSSY"

    # Common Settings for RZ/G2E
    TFA_OPT="$TFA_OPT RCAR_SA0_SIZE=0 RCAR_RPC_HYPERFLASH_LOCKED=0"
    PLATFORM=rzg
    TOOL=rzg
    ;;
  "hihope-rzg2m")
    TFA_OPT="LSI=G2M RZG_DRAM_SPLIT=2 SPD="none" $G2M_ECC $G2M_LOSSY"

    # Common Settings for RZ/G2M
    TFA_OPT="$TFA_OPT RCAR_RPC_HYPERFLASH_LOCKED=0"
    PLATFORM=rzg
    TOOL=rzg
    ;;
  "hihope-rzg2n")
    TFA_OPT="LSI=G2N SPD="none" $G2N_ECC $G2N_LOSSY"

    # Common Settings for RZ/G2N
    TFA_OPT="$TFA_OPT RCAR_RPC_HYPERFLASH_LOCKED=0"
    PLATFORM=rzg
    TOOL=rzg
    ;;
  "hihope-rzg2h")
    TFA_OPT="LSI=G2H RZG_DRAM_SPLIT=2 RZG_DRAM_LPDDR4_MEMCONF=1 RCAR_DRAM_CHANNEL=5 SPD="none" $G2H_ECC $G2H_LOSSY"

    # Common Settings for RZ/G2H
    TFA_OPT="$TFA_OPT RCAR_RPC_HYPERFLASH_LOCKED=0"
    PLATFORM=rzg
    TOOL=rzg
    ;;
esac

# For eMMC boot, you need to set RCAR_SA6_TYPE=1
if [ "$TFA_BOOT" == "1" ] ; then
    TFA_OPT="$TFA_OPT RCAR_SA6_TYPE=1"
fi

# MBED is required for VLP v1.0.5+
if [ "$PLATFORM" == "rzg" ] &&  [ "$MBEDTLS_DIR" == "" ] ; then
  if [ -e mbedtls ] ; then
    MBEDTLS_DIR=mbedtls
  elif [ -e ../mbedtls ] ; then
    MBEDTLS_DIR=../mbedtls
  else
    echo "ERROR: You need to have the mbed TLS repo to build"
    exit
  fi
fi

# For versions before v2.5, RZG_ was used for some settings instead of RCAR_
if [ "${TFA_BEFORE_2_5}" ] ; then

  # RCAR_SA6_TYPE -> RZG_SA6_TYPE
  TFA_OPT_NEW=$(echo $TFA_OPT | sed 's/RCAR_SA6_TYPE/RZG_SA6_TYPE/')
  TFA_OPT="$TFA_OPT_NEW"

  # RCAR_SA0_SIZE -> RZG_SA0_SIZE
  TFA_OPT_NEW=$(echo $TFA_OPT | sed 's/RCAR_SA0_SIZE/RZG_SA0_SIZE/')
  TFA_OPT="$TFA_OPT_NEW"

  # RCAR_DRAM_DDR3L_MEMCONF -> RZG_DRAM_DDR3L_MEMCONF
  TFA_OPT_NEW=$(echo $TFA_OPT | sed 's/RCAR_DRAM_DDR3L_MEMCONF/RZG_DRAM_DDR3L_MEMCONF/')
  TFA_OPT="$TFA_OPT_NEW"

  # RCAR_DRAM_DDR3L_MEMDUAL -> RZG_DRAM_DDR3L_MEMDUAL
  TFA_OPT_NEW=$(echo $TFA_OPT | sed 's/RCAR_DRAM_DDR3L_MEMDUAL/RZG_DRAM_DDR3L_MEMDUAL/')
  TFA_OPT="$TFA_OPT_NEW"

  # RCAR_DRAM_SPLIT -> RZG_DRAM_SPLIT
  TFA_OPT_NEW=$(echo $TFA_OPT | sed 's/RCAR_DRAM_SPLIT/RZG_DRAM_SPLIT/')
  TFA_OPT="$TFA_OPT_NEW"

  # RCAR_DRAM_CHANNEL -> RZG_DRAM_CHANNEL
  TFA_OPT_NEW=$(echo $TFA_OPT | sed 's/RCAR_DRAM_CHANNEL/RZG_DRAM_CHANNEL/')
  TFA_OPT="$TFA_OPT_NEW"

  # RCAR_RPC_HYPERFLASH_LOCKED -> RZG_RPC_HYPERFLASH_LOCKED
  TFA_OPT_NEW=$(echo $TFA_OPT | sed 's/RCAR_RPC_HYPERFLASH_LOCKED/RZG_RPC_HYPERFLASH_LOCKED/')
  TFA_OPT="$TFA_OPT_NEW"
fi

# Set up Toolchain in current environment
echo "$TFA_TOOLCHAIN_SETUP"
eval $TFA_TOOLCHAIN_SETUP
if [ "$TARGET_PREFIX" == "" ] ; then
  # Not using SDK (poky) toolchain (assuming Linaro)
  # We need to set these before calling make (that's why makefile.linaro exists, but we don't need to use it)
  export CC=${CROSS_COMPILE}gcc
  export AS=${CROSS_COMPILE}as
  export LD=${CROSS_COMPILE}ld
  export AR=${CROSS_COMPILE}ar
  export OBJDUMP=${CROSS_COMPILE}objdump
  export OBJCOPY=${CROSS_COMPILE}objcopy
fi

# Let the Makefile handle setting up the CFLAGS and LDFLAGS as it is a standalone application
unset CFLAGS
unset LDFLAGS
unset AS
unset LD

# distclean
if [ "$1" == "" ] ; then
  echo "make distclean"
  make distclean
fi

if [ "$TFA_DEBUG" == "1" ] ; then
  ADD_DEBUG="DEBUG=1"
  BUILD_DIR=debug
else
  ADD_DEBUG=
  BUILD_DIR=release
fi

# make
CMD="make -j $BUILD_THREADS bl2 bl31 ${TOOL} PLAT=${PLATFORM} ${TFA_OPT} RZG_DRAM_ECC_FULL=${TFA_ECC_FULL} LOG_LEVEL=$TFA_LOG_LEVEL ${ADD_DEBUG} \
	MBEDTLS_DIR=$MBEDTLS_DIR \
	$1 $2 $3"
echo "$CMD"
$CMD

# If this was just a clean, exit now
if [ ! -e "build/${PLATFORM}/$BUILD_DIR/bl2/bl2.elf" ] ; then
  exit
fi

# FIP build
if [ "$TFA_FIP" == "1" ] ; then
  create_bootparams
  create_fip_and_copy

  #### STOP HERE for FIP Builds ####
  exit
fi


# Copy files to deploy folder
DEPLOYDIR=z_deploy
mkdir -p $DEPLOYDIR
cp build/${PLATFORM}/release/bl2/bl2.elf ${DEPLOYDIR}/bl2-${MACHINE}.elf
cp build/${PLATFORM}/release/bl2.bin ${DEPLOYDIR}/bl2-${MACHINE}.bin
cp build/${PLATFORM}/release/bl2.srec ${DEPLOYDIR}/bl2-${MACHINE}.srec
cp build/${PLATFORM}/release/bl31/bl31.elf ${DEPLOYDIR}/bl31-${MACHINE}.elf
cp build/${PLATFORM}/release/bl31.bin ${DEPLOYDIR}/bl31-${MACHINE}.bin
cp build/${PLATFORM}/release/bl31.srec ${DEPLOYDIR}/bl31-${MACHINE}.srec
# VLP 1.0.4
if [ -e tools/dummy_create/bootparam_sa0.srec ] ; then
	cp tools/dummy_create/bootparam_sa0.srec ${DEPLOYDIR}/bootparam_sa0.srec
	cp tools/dummy_create/cert_header_sa6.srec ${DEPLOYDIR}/cert_header_sa6.srec
fi
# VLP 1.0.5+
if [ -e tools/renesas/rzg_layout_create/bootparam_sa0.srec ] ; then
	cp tools/renesas/rzg_layout_create/bootparam_sa0.srec ${DEPLOYDIR}/bootparam_sa0.srec
	cp tools/renesas/rzg_layout_create/cert_header_sa6.srec ${DEPLOYDIR}/cert_header_sa6.srec
fi

# Save what build this was
CURRENT_BRANCH=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
echo "Built from branch \"$CURRENT_BRANCH\"" > ${DEPLOYDIR}/build_version.txt
echo -e "\nOutput files copied to directory $TFA_DIR_DEFAULT/$DEPLOYDIR\n"

# copy to output directory
if [ -e build/${PLATFORM}/release/bl2.bin ] && [ "$OUT_DIR" != "" ] ; then

  mkdir -p ../$OUT_DIR
  cp build/${PLATFORM}/release/bl2/bl2.elf   ../$OUT_DIR/bl2-${MACHINE}.elf
  cp build/${PLATFORM}/release/bl2.bin       ../$OUT_DIR/bl2-${MACHINE}.bin
  cp build/${PLATFORM}/release/bl2.srec      ../$OUT_DIR/bl2-${MACHINE}.srec
  cp build/${PLATFORM}/release/bl31/bl31.elf ../$OUT_DIR/bl31-${MACHINE}.elf
  cp build/${PLATFORM}/release/bl31.bin      ../$OUT_DIR/bl31-${MACHINE}.bin
  cp build/${PLATFORM}/release/bl31.srec     ../$OUT_DIR/bl31-${MACHINE}.srec
  cp tools/renesas/rzg_layout_create/bootparam_sa0.srec   ../$OUT_DIR/bootparam_sa0.srec
  cp tools/renesas/rzg_layout_create/cert_header_sa6.srec ../$OUT_DIR/cert_header_sa6.srec

  echo -e "\nOutput files copied to output directory $OUT_DIR\n"

  # Save what this was build with
  echo "MACHINE=$MACHINE" > ../$OUT_DIR/manifest_tfa.txt
  echo "BOARD_VERSION=$BOARD_VERSION" > ../$OUT_DIR/manifest_tfa.txt
  echo "TFA_BOOT=$TFA_BOOT" >> ../$OUT_DIR/manifest_tfa.txt
  echo "TFA_LOG_LEVEL=$TFA_LOG_LEVEL" >> ../$OUT_DIR/manifest_tfa.txt
  echo "TFA_ECC_FULL=$TFA_ECC_FULL" >> ../$OUT_DIR/manifest_tfa.txt
  echo "TFA_TOOLCHAIN_SETUP_NAME=$TFA_TOOLCHAIN_SETUP_NAME" >> ../$OUT_DIR/manifest_tfa.txt
  CURRENT_BRANCH=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
  echo "Built from branch \"$CURRENT_BRANCH\"" >> ../$OUT_DIR/manifest_tfa.txt


  # Use the same filenames as the Yocto output
  #cp -v $OUT/u-boot.bin ../$OUT_DIR/u-boot-${MACHINE}.bin
  #cp -v $OUT/u-boot.srec ../$OUT_DIR//u-boot-${MACHINE}.srec
fi

