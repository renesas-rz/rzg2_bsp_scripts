#!/bin/bash

#---------------------------------------------------------------------------
# Please read the README.md file first for proper setup
#---------------------------------------------------------------------------

# This build script can be used to build
#  * Trusted Firmware-A
#  * u-boot
#  * Renesas Flash Writer
#  * Linux Kernel

# Please read "Repository Installs.txt" to install the toolchains.

# Please read "Toolchain Installs.txt" to install the toolchains.

# The output files you need will be copied to the 'output_xxxxx' directory. xxx will be the name of your board.

# Supported Boards
# MACHINE=hihope-rzg2m	# HiHope RZ/G2M
# MACHINE=hihope-rzg2n	# HiHope RZ/G2N
# MACHINE=hihope-rzg2h	# HiHope RZ/G2H
# MACHINE=ek874		# Silicon Linux RZ/G2E
# MACHINE=smarc-rzg2l	# Renesas RZ/G2L EVK
#   BOARD_VERSION: DISCRETE, PMIC, WS1
# MACHINE=smarc-rzg2lc	# Renesas RZ/G2LC EVK
# MACHINE=smarc-rzv2l	# Renesas RZ/V2L EVK
#   BOARD_VERSION: DISCRETE, PMIC


#----------------------------------------------
# Default Settings
#----------------------------------------------
TFA_DIR_DEFAULT=rzg_trusted-firmware-a
UBOOT_DIR_DEFAULT=renesas-u-boot-cip
FW_DIR_DEFAULT=rzg2_flash_writer
KERNEL_DIR_DEFAULT=rz_linux-cip
OUT_DIR=output_${MACHINE}

# Read in functions from build_common.sh
if [ ! -e build_common.sh ] ; then
  echo -e "\n ERROR: File \"build_common.sh\" not found\n."
  exit
else
  source build_common.sh
fi


# Toolchain Selection GUI
# Since each sub-script will want to ask the user what toolchain to use, we will keep a common interface in this file.
if [ "$1" == "toolchain_select" ] ; then

    SELECT=$(whiptail --title "Toolchain setup" --menu "You may use ESC+ESC to cancel.\nEnter the command line you want to run before build.\n" 0 0 0 \
	"1  SDK Toolchain (Rocko/Poky 2.4.3)" "  /opt/poky/2.4.3/environment-setup-aarch64-poky-linux" \
	"2  Linaro gcc-linaro-7.5.0-2019.12" "  /opt/linaro/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu" \
	"3  ARM gcc-arm-10.2-2020.11" "  /opt/arm/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf" \
	"0  (none)" "  No setup" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *)
      		x_TOOLCHAIN_SETUP_NAME="SDK Toolchain (Poky 2.4.3)" ; x_TOOLCHAIN_SETUP="source /opt/poky/2.4.3/environment-setup-aarch64-poky-linux" ;;
      2\ *)
      		x_TOOLCHAIN_SETUP_NAME="Linaro gcc-linaro-7.5.0-2019.12" ; x_TOOLCHAIN_SETUP="PATH=/opt/linaro/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin:\$PATH ; export CROSS_COMPILE=aarch64-linux-gnu-" ;;
      3\ *)
      		x_TOOLCHAIN_SETUP_NAME="ARM gcc-arm-10.2-2020.11" ; x_TOOLCHAIN_SETUP="PATH=/opt/arm/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf/bin:\$PATH ; export CROSS_COMPILE=aarch64-none-elf-" ;;
      0\ *)
		x_TOOLCHAIN_SETUP_NAME="(none)" ; x_TOOLCHAIN_SETUP= ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi

  # Save our replies to some tmp file so other scripts can read it
  echo "x_TOOLCHAIN_SETUP_NAME=\"$x_TOOLCHAIN_SETUP_NAME\"" > /tmp/toolchain_reply.txt
  echo "x_TOOLCHAIN_SETUP=\"$x_TOOLCHAIN_SETUP\"" >> /tmp/toolchain_reply.txt

  exit
fi

# $1 = env variable to save
# $2 = value
# Remember, we we share this file with other scripts, so we only want to change
# the lines used by this script
save_setting() {


  if [ ! -e $SETTINGS_FILE ] ; then
    touch $SETTINGS_FILE # create file if does not exit
  fi

  # Do not change the file if we did not make any changes
  grep -q "^$1=$2$" $SETTINGS_FILE
  if [ "$?" == "0" ] ; then
    return
  fi

  sed '/^'"$1"'=/d' -i $SETTINGS_FILE
  echo  "$1=$2" >> $SETTINGS_FILE

  # Delete empty or blank lines
  sed '/^$/d' -i $SETTINGS_FILE

  # Sort the file to keep the same order
  sort -o $SETTINGS_FILE $SETTINGS_FILE
}


# Save Settings to file
# Since each sub-script will want to save their settings, we will keep a common interface in this file.
if [ "$1" == "save_setting" ] ; then

  if [ "$SETTINGS_FILE" == "" ] ; then
    echo -e "\nERROR: SETTINGS_FILE not set\n"
    exit
  fi

  # Call the function in this file
  save_setting "$2" "$3"

  exit
fi

# Setting are kept in a board.ini file.
# If you want to use a different board.in file, you can define it before you run this script
#    $ export SETTINGS_FILE=my_board.ini
#    $ ./build.sh

if [ "$SETTINGS_FILE" == "" ] ; then
  # If not set, use default file name
  SETTINGS_FILE=board.ini
  export SETTINGS_FILE=$SETTINGS_FILE

  # Read in our settings
  if [ -e "$SETTINGS_FILE" ] ; then
    source $SETTINGS_FILE
  fi
fi

if [ "$MACHINE" == "" ] && [ "$1" != "s" ] ; then
  echo -e "\nERROR: No board selected. Please run \"./build.sh s\"\n"
  exit
fi


#----------------------------------------------
# Help Menu
#----------------------------------------------
if [ "$1" == "" ] ; then

  if [ "$BOARD_VERSION" != "" ] ; then
    BOARD_VERSION_TEXT="($BOARD_VERSION)"
  fi

  echo "\

Board: $MACHINE $BOARD_VERSION_TEXT

Please select what you want to build:

  ./build.sh f                       # Build Renesas Flash Writer
  ./build.sh t                       # Build Trusted Firmware-A
  ./build.sh u                       # Build u-boot
  ./build.sh k                       # Build Linux Kernel
  ./build.sh m                       # Build Linux Kernel multimedia modules

  ./build.sh s                       # Setup - Choose board and build options
"
  exit
fi

if [ "$1" == "t" ] ; then
  ./build_tfa.sh $2 $3 $4
  exit
fi
if [ "$1" == "u" ] ; then
  ./build_uboot.sh $2 $3 $4
  exit
fi
if [ "$1" == "f" ] ; then
  ./build_flashwriter.sh $2 $3 $4
  exit
fi
if [ "$1" == "k" ] ; then
  ./build_kernel.sh $2 $3 $4
  exit
fi
if [ "$1" == "m" ] ; then
  ./build_mm.sh $2 $3 $4
  exit
fi


if [ "$1" == "s" ] ; then

  # Check for required Host packages
  check_packages

  SELECT=$(whiptail --title "Board Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1  hihope-rzg2m" "HiHope RZ/G2M" \
	"2  hihope-rzg2n" "HiHope RZ/G2N" \
	"3  hihope-rzg2h" "HiHope RZ/G2H" \
	"4  ek874" "Silicon Linux RZ/G2E" \
	"5  smarc-rzg2l" "Renesas SMARC RZ/G2L" \
	"6  smarc-rzg2lc" "Renesas SMARC RZ/G2LC" \
	"7  smarc-rzv2l" "Renesas SMARC RZ/V2L" \
	"8  smarc-rzg2ul" "Renesas SMARC RZ/G2UL" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    BOARD_VERSION=""  # Clear out BOARD_VERSION in case there is not one
    case "$SELECT" in
      1\ *) FW_BOARD=HIHOPE ; MACHINE=hihope-rzg2m ;;
      2\ *) FW_BOARD=HIHOPE ; MACHINE=hihope-rzg2n ;;
      3\ *) FW_BOARD=HIHOPE ; MACHINE=hihope-rzg2h ;;
      4\ *) FW_BOARD=EK874 ; MACHINE=ek874 ;;
      5\ *) FW_BOARD=RZG2L_SMARC ; MACHINE=smarc-rzg2l
	whiptail --yesno --yes-button PMIC_Power --no-button Discrete_Power "Board Version:\n\nIs the board 'PMIC Power' version or the 'Discrete Power' version?\n\nThe PMIC version has \"Reneas\" printed in the middle of the SOM board.\nThe Discrete version has \"Renesas\" printed at the edge of the SOM baord.   " 0 0 0
	if [ "$?" == "0" ] ; then
		BOARD_VERSION="PMIC"
		FW_BOARD=RZG2L_SMARC_PMIC
	else
		BOARD_VERSION="DISCRETE"
		FW_BOARD=RZG2L_SMARC
	fi
      ;;
      6\ *) FW_BOARD=RZG2LC_SMARC ; MACHINE=smarc-rzg2lc ;;
      7\ *) FW_BOARD=RZV2L_SMARC ; MACHINE=smarc-rzv2l ;;
      8\ *) FW_BOARD=RZG2UL_SMARC ; MACHINE=smarc-rzg2ul
	whiptail --yesno --yes-button PMIC_Power --no-button Discrete_Power "Board Version:\n\nIs the board 'PMIC Power' version or the 'Discrete Power' version?\n\nThe PMIC version has \"Reneas\" printed in the middle of the SOM board.\nThe Discrete version has \"Renesas\" printed at the edge of the SOM baord.   " 0 0 0
	if [ "$?" == "0" ] ; then
		BOARD_VERSION="PMIC"
		FW_BOARD=RZV2L_SMARC_PMIC
	else
		BOARD_VERSION="DISCRETE"
		FW_BOARD=RZV2L_SMARC
	fi
      ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  else
    # canceled
    exit
  fi

  # Clear out the current settings file
  echo "" > $SETTINGS_FILE

  # Select common toolchain
  whiptail --msgbox "Please select a Toolchain" 0 0 0
  select_toolchain "COMMON_TOOLCHAIN_SETUP_NAME" "COMMON_TOOLCHAIN_SETUP"
  save_setting COMMON_TOOLCHAIN_SETUP_NAME "\"$COMMON_TOOLCHAIN_SETUP_NAME\""
  save_setting COMMON_TOOLCHAIN_SETUP "\"$COMMON_TOOLCHAIN_SETUP\""

  # Save our default directories
  save_setting TFA_DIR $TFA_DIR_DEFAULT
  save_setting UBOOT_DIR $UBOOT_DIR_DEFAULT
  save_setting FW_DIR $FW_DIR_DEFAULT
  save_setting KERNEL_DIR $KERNEL_DIR_DEFAULT

  # The board
  save_setting MACHINE $MACHINE
  save_setting OUT_DIR output_${MACHINE}
  save_setting BOARD_VERSION $BOARD_VERSION

  # Set defaults for Flash Writer script
  save_setting FW_BOARD $FW_BOARD

  # Set defaults for Flash Writer script
  if [ "$MACHINE" == "smarc-rzg2l" ] || [ "$MACHINE" == "smarc-rzg2lc" ] || [ "$MACHINE" == "smarc-rzv2l" ] || [ "$MACHINE" == "smarc-rzg2ul" ]; then
    save_setting TFA_FIP 1
  else
    save_setting TFA_FIP 0
  fi

fi
