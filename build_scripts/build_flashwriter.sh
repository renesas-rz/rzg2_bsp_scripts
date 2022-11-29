#!/bin/bash

# Whiptail colors
export NEWT_COLORS='
root=,blue
'

################################
#    Board options
################################
#BOARD=HIHOPE
#BOARD=EK874
#BOARD=RZG2L_SMARC
#BOARD=RZG2L_SMARC_PMIC
#BOARD=RZG2L_15MMSQ_DEV
#BOARD=RZG2L_21MMSQ_DEV
#BOARD=RZG2LC_SMARC
#BOARD=RZG2UL_SMARC
#BOARD=RZG2LC_DEV
#BOARD=RZV2LC_SMARC
#BOARD=RZV2L_SMARC_PMIC

################################
# Makefile options
################################

#BOOT=WRITER_WITH_CERT
#BOOT=WRITER

#SERIAL_FLASH=ENABLE
#SERIAL_FLASH=DISABLE

#EMMC=ENABLE
#EMMC=DISABLE

#USB=ENABLE
#USB=DISABLE

# Read in functions from build_common.sh
if [ ! -e build_common.sh ] ; then
  echo -e "\n ERROR: File \"build_common.sh\" not found\n."
  exit
else
  source build_common.sh
fi

# Read our settings (board.ini) or whatever file SETTINGS_FILE was set to
read_setting

do_board_menu() {
  SELECT=$(whiptail --title "Board Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1   HIHOPE" "HiHope RZ/G2M, RZ/G2N, RZ/G2H" \
	"2   EK874" "Silicon Linux RZ/G2E" \
	"3   RZG2L_SMARC" "Renesas SMARC RZ/G2L" \
	"4   RZG2L_SMARC_PMIC" "Renesas SMARC RZ/G2L (PMIC Version)" \
	"5   RZG2LC_SMARC" "Renesas SMARC RZ/G2LC" \
	"6   RZG2L_15MMSQ_DEV" "Renesas Internal Dev Board" \
	"7   RZG2L_21MMSQ_DEV" "Renesas Internal Dev Board" \
	"8   RZG2LC_DEV" "Renesas Internal Dev Board" \
	"9   RZV2L_SMARC" "Renesas SMARC RZ/V2L" \
	"10  RZV2L_SMARC_PMIC" "Renesas SMARC RZ/V2L (PMIC Version)" \
	"11  RZV2L_15MMSQ_DEV" "Renesas Internal Dev Board" \
	"12  RZG2UL_SMARC" "Renesas SMARC RZ/G2UL" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) FW_BOARD=HIHOPE ;;
      2\ *) FW_BOARD=EK874 ;;
      3\ *) FW_BOARD=RZG2L_SMARC ;;
      4\ *) FW_BOARD=RZG2L_SMARC_PMIC ;;
      5\ *) FW_BOARD=RZG2LC_SMARC ;;
      6\ *) FW_BOARD=RZG2L_15MMSQ_DEV ;;
      7\ *) FW_BOARD=RZG2L_21MMSQ_DEV ;;
      8\ *) FW_BOARD=RZG2LC_DEV ;;
      9\ *) FW_BOARD=RZV2L_SMARC ;;
      10\ *) FW_BOARD=RZV2LC_SMARC_PMIC ;;
      11\ *) FW_BOARD=RZV2L_15MMSQ_DEV ;;
      12\ *) FW_BOARD=RZG2UL_SMARC ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}
do_boot_menu() {
  SELECT=$(whiptail --title "Boot Certificate Selection" --menu "You may use ESC+ESC to cancel.\n\nA Blank entry means use default board settings." 0 0 0 \
	"1  WRITER_WITH_CERT" "Include Dummy Cert (recommended)" \
	"2  WRITER" "Writer only (no cert)" \
	"3  (default)" "Use Makefile default" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) FW_BOOT=WRITER_WITH_CERT ;;
      2\ *) FW_BOOT=WRITER ;;
      3\ *) FW_BOOT= ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}
do_serial_menu() {
  SELECT=$(whiptail --title "SPI Flash Programming Support" --menu "You may use ESC+ESC to cancel.\n\nA Blank entry means use default board settings." 0 0 0 \
	"1  ENABLE" "" \
	"2  DISABLE" "" \
	"3  (default)" "Use Makefile default" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) FW_SERIAL_FLASH=ENABLE ;;
      2\ *) FW_SERIAL_FLASH=DISABLE ;;
      3\ *) FW_SERIAL_FLASH= ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}
do_emmc_menu() {
  SELECT=$(whiptail --title "eMMC Flash Programming Support" --menu "You may use ESC+ESC to cancel.\n\nA Blank entry means use default board settings." 0 0 0 \
	"1  ENABLE" "" \
	"2  DISABLE" "" \
	"3  (default)" "Use Makefile default" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) FW_EMMC=ENABLE ;;
      2\ *) FW_EMMC=DISABLE ;;
      3\ *) FW_EMMC= ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}
do_usb_menu() {
  SELECT=$(whiptail --title "USB Download Mode Support" --menu "You may use ESC+ESC to cancel.\n\nA Blank entry means use default board settings.\n\nNOTE: This feature not supported on all boards." 0 0 0 \
	"1  ENABLE" "" \
	"2  DISABLE" "" \
	"3  (default)" "Use Makefile default" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) FW_USB=ENABLE ;;
      2\ *) FW_USB=DISABLE ;;
      3\ *) FW_USB= ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

do_toolchain_menu() {
  select_toolchain "FW_TOOLCHAIN_SETUP_NAME" "FW_TOOLCHAIN_SETUP"
}

# Use common toolchain if specific toolchain not set
if [ "$FW_TOOLCHAIN_SETUP_NAME" == "" ] ; then
  if [ "$COMMON_TOOLCHAIN_SETUP_NAME" != "" ] ; then
    FW_TOOLCHAIN_SETUP_NAME=$COMMON_TOOLCHAIN_SETUP_NAME
    FW_TOOLCHAIN_SETUP=$COMMON_TOOLCHAIN_SETUP
  else
    whiptail --msgbox "Please select a Toolchain" 0 0 0
    do_toolchain_menu
  fi
fi

# If no arguments pass, use GUI interface
if [ "$1" == "" ] ; then

  while true ; do

    # Determine Outfile based on board
    case "$FW_BOARD" in
      HIHOPE) OUTFILE=AArch64_Flash_writer_SCIF_DUMMY_CERT_E6300400_hihope.mot ;;
      EK874) OUTFILE=AArch64_Flash_writer_SCIF_DUMMY_CERT_E6300400_ek874.mot ;;
      RZG2L_SMARC) OUTFILE=Flash_Writer_SCIF_RZG2L_SMARC_DDR4_2GB.mot ;;
      RZG2L_SMARC_PMIC) OUTFILE=Flash_Writer_SCIF_RZG2L_SMARC_PMIC_DDR4_2GB_1PCS.mot ;;
      RZG2LC_SMARC) OUTFILE=Flash_Writer_SCIF_RZG2LC_SMARC_DDR4_1GB_1PCS.mot ;;
      RZG2L_15MMSQ_DEV) OUTFILE=Flash_Writer_SCIF_RZG2L_15MMSQ_DEV_DDR4_4GB.mot ;;
      RZG2L_21MMSQ_DEV) OUTFILE=Flash_Writer_SCIF_RZG2L_21MMSQ_DEV_DDR4_4GB.mot ;;
      RZG2LC_DEV) OUTFILE=Flash_Writer_SCIF_RZG2LC_DEV_DDR3L_1GB.mot ;;
      RZG2UL_SMARC) OUTFILE=Flash_Writer_SCIF_RZG2UL_SMARC_DDR4_1GB_1PCS.mot ;;
      RZV2L_SMARC) OUTFILE=Flash_Writer_SCIF_RZV2L_SMARC_DDR4_4GB.mot ;;
      RZV2L_SMARC_PMIC) OUTFILE=Flash_Writer_SCIF_RZV2L_SMARC_PMIC_DDR4_2GB_1PCS.mot ;;
      *) OUTFILE="*.mot" ;;
    esac

    # In case of no setting, display as 'default'
    if [ "$FW_BOOT" == "" ] ; then BOOT_TEXT="(default)" ; else BOOT_TEXT="$FW_BOOT" ; fi
    if [ "$FW_SERIAL_FLASH" == "" ] ; then SERIAL_FLASH_TEXT="(default)" ; else SERIAL_FLASH_TEXT="$FW_SERIAL_FLASH" ; fi
    if [ "$FW_EMMC" == "" ] ; then EMMC_TEXT="(default)" ; else EMMC_TEXT="$FW_EMMC" ; fi
    if [ "$FW_USB" == "" ] ; then USB_TEXT="(default)" ; else USB_TEXT="$FW_USB" ; fi


    SELECT=$(whiptail --title "RZ/G2 Flash Writer Configuration" --menu "Select your build options.\nYou may use [ESC]+[ESC] to cancel/exit.\nUse [Tab] key to select buttons at the bottom.\n\nUse the <Change> button (or enter) to make changes.\nUse the <Build> button to start the build." 0 0 0 --cancel-button Build --ok-button Change \
	"1.              Select your board:" "  $FW_BOARD"  \
	"2.             Include Dummy cert:" "  $BOOT_TEXT" \
	"3.  SPI Flash programming support:" "  $SERIAL_FLASH_TEXT"  \
	"4. eMMC Flash programming support:" "  $EMMC_TEXT" \
	"5.      USB Download Mode support:" "  $USB_TEXT" \
	"6.                Toolchain setup:" "  $FW_TOOLCHAIN_SETUP_NAME" \
	3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ] ; then
      # Save to our settings file
      save_setting FW_BOARD "$FW_BOARD"
      save_setting FW_BOOT "$FW_BOOT"
      save_setting FW_SERIAL_FLASH "$FW_SERIAL_FLASH"
      save_setting FW_EMMC "$FW_EMMC"
      save_setting FW_USB "$FW_USB"
      if [ "$FW_TOOLCHAIN_SETUP_NAME" != "$COMMON_TOOLCHAIN_SETUP_NAME" ] ; then
        save_setting FW_TOOLCHAIN_SETUP_NAME "\"$FW_TOOLCHAIN_SETUP_NAME\""
        save_setting FW_TOOLCHAIN_SETUP "\"$FW_TOOLCHAIN_SETUP\""
      fi

      # Set up Toolchain in current environment
      echo "$FW_TOOLCHAIN_SETUP"
      eval $FW_TOOLCHAIN_SETUP
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

      # Start the build
      cd $FW_DIR
      echo "make clean"
      make clean

      # If not set, do add to command line
      if [ "$FW_BOOT" != "" ] ; then
        ARG_BOOT="BOOT=$FW_BOOT"
      fi
      if [ "$FW_USB" != "" ] ; then
        ARG_USB="USB=$FW_USB"
      fi
      if [ "$FW_SERIAL_FLASH" != "" ] ; then
        ARG_SERIAL_FLASH="SERIAL_FLASH=$FW_SERIAL_FLASH"
      fi
      if [ "$FW_EMMC" != "" ] ; then
        ARG_EMMC="EMMC=$FW_EMMC"
      fi

      CMD="make BOARD=$FW_BOARD $ARG_BOOT $ARG_USB $ARG_SERIAL_FLASH $ARG_EMMC"
      echo "$CMD"
      $CMD

      # copy to output directory
      if [ -e AArch64_output/$OUTFILE ] && [ "$OUT_DIR" != "" ] ; then
        mkdir -p $OUT_DIR
        cp -v AArch64_output/$OUTFILE $OUT_DIR
        echo -e "File AArch64_output/$OUTFILE copied to $OUT_DIR"
      fi

      break;
    elif [ $RET -eq 0 ] ; then
      case "$SELECT" in
        1.\ *) do_board_menu ;;
        2.\ *) do_boot_menu ;;
        3.\ *) do_serial_menu ;;
        4.\ *) do_emmc_menu ;;
        5.\ *) do_usb_menu ;;
        6.\ *) do_toolchain_menu ;;
        *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
    else
      exit 1
    fi
  done
  exit
fi

if [ "$CROSS_COMPILE" == "" ] ; then
  echo "Cross Compiler (CROSS_COMPILE) not set."
  echo ""
  echo "Yocto SDK environment set up:"
  echo "   source /opt/poky/2.4.3/environment-setup-aarch64-poky-linux"
  echo ""
  echo "Linaro environment set up:"
  echo "   PATH=/opt/linaro/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin:\$PATH ; export CROSS_COMPILE=aarch64-linux-gnu-"
  echo ""
  exit
fi

# Set up Toolchain in current environment
echo "$FW_TOOLCHAIN_SETUP"
eval $FW_TOOLCHAIN_SETUP
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

if [ "$CC" == "" ] ; then
  # We need to set these before calling make (that's why makefile.linaro exists, but we don't need to use it)
  export CC=${CROSS_COMPILE}gcc
  export AS=${CROSS_COMPILE}as
  export LD=${CROSS_COMPILE}ld
  export AR=${CROSS_COMPILE}ar
  export OBJDUMP=${CROSS_COMPILE}objdump
  export OBJCOPY=${CROSS_COMPILE}objcopy
fi

cd $FW_DIR
CMD="make BOARD=$FW_BOARD BOOT=$FW_BOOT USB=$FW_USB SERIAL_FLASH=$FW_SERIAL_FLASH EMMC=$FW_EMMC $1 $2 $3"
echo "$CMD"
$CMD

# copy to output directory
if [ -e AArch64_output/$OUTFILE ] && [ "$OUT_DIR" != "" ] ; then
  mkdir -p $OUT_DIR
  cp -v AArch64_output/$OUTFILE $OUT_DIR
  echo -e "File AArch64_output/$OUTFILE copied to $OUT_DIR"
fi
