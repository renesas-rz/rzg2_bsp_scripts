#!/bin/bash

# Most of this script is made of functions.
# You can search for "Script Start GUI" to find the start of execution for GUI menu
# You can search for "Script Start OPP" to find the start of execution of programming operations

# === How this script works ===
# When you start with no command line arguments, it goes into a GUI mode.
# The GUI mode is an endless loop until you exit.
# When you select an operation in the GUI to perform (programming), the script will call
# itself again (sub-script) using command line parameters. This is done using the do_cmd()
# function. When the sub-script is called with command line parameters, the GUI
# does not show and instead performs the operating on the command line. After
# that operation is complete, the sub-script exits and go back into main script
# where the GUI continues to show.
#
# You can also use this script as command line only (no GUI). In that case, you will need to pass
# a config filename the command line that has all the options and filenames included.


# Global Default Settings
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

FIP=0 # TF-A uses FIP instead of BL31
EMMC_4BIT=0 # eMMC uses 4-bit data, not 8-bit
if [ "$FW_GUI_MODE" == "" ] ; then
  FW_GUI_MODE=0
  # 0 = Command line only
  # 1 = Show main GUI interface
  # 2 = GUI is running the script again to do an operation
fi

# If nothing is passed on the command line, go into the GUI interface mode
if [ "$1" == "" ] ; then
  export FW_GUI_MODE=1
fi

# Set BOARD_NAME and SW_SETTINGS
switch_settings() {
  if [ "$BOARD" == "ek874" ] ; then
	BOARD_NAME="EK874 RZ/G2E by Silicon Linux"
	SW_SETTINGS="Please TURN OFF board power when changing switch settings.
Switch settings for SW12 which is placed near the micro SD card slot.

	SPI Flash boot              eMMC boot
	--------------              ---------
	1 = ON                      1 = OFF
	2 = ON                      2 = ON
	3 = ON                      3 = OFF
	4 = OFF                     4 = OFF
	5 = ON                      5 = ON
	6 = ON                      6 = ON

	SCIF Download mode         USB Download mode
	------------------         -----------------
	1 = OFF                    1 = OFF
	2 = OFF                    2 = OFF
	3 = OFF                    3 = ON
	4 = OFF                    4 = OFF
	5 = ON                     5 = ON
	6 = ON                     6 = ON
"
  fi

  if [ "$BOARD" == "hihope-rzg2m" ] || [ "$BOARD" == "hihope-rzg2n" ] || \
     [ "$BOARD" == "hihope-rzg2h" ] ; then

	if [ "$BOARD" == "hihope-rzg2m" ] ; then BOARD_NAME="HiHope RZ/G2M by Hoperun Technology" ; fi
	if [ "$BOARD" == "hihope-rzg2n" ] ; then BOARD_NAME="HiHope RZ/G2N by Hoperun Technology" ; fi
	if [ "$BOARD" == "hihope-rzg2h" ] ; then BOARD_NAME="HiHope RZ/G2H by Hoperun Technology" ; fi

	SW_SETTINGS="Please TURN OFF board power when changing switch settings.
Switch settings for SW1002.
    ----------  ----------
    | SW1003 |  | SW1002 | << this one
    ----------  ----------
                ----------
                | SW1001 |
                ----------

	SPI Flash boot              eMMC boot
	--------------              ---------
	1 = ON                      1 = ON
	2 = ON                      2 = ON
	3 = ON                      3 = ON
	4 = ON                      4 = ON
	5 = ON                      5 = OFF
	6 = OFF                     6 = OFF
	7 = ON                      7 = ON
	8 = ON                      8 = OFF

	SCIF Download mode         USB Download mode
	------------------         -----------------
	1 = ON                      1 = ON
	2 = ON                      2 = ON
	3 = ON                      3 = ON
	4 = ON                      4 = ON
	5 = OFF                     5 = OFF
	6 = OFF                     6 = OFF
	7 = OFF                     7 = OFF
	8 = OFF                     8 = ON
"
  fi

  if [ "$BOARD" == "smarc-rzg2l" ] || [ "$BOARD" == "smarc-rzg2lc" ] || [ "$BOARD" == "smarc-rzg2ul" ] ||\
     [ "$BOARD" == "smarc-rzv2l" ] || [ "$BOARD" == "smarc-rzg3s" ] ; then

	SW_NAME="SW11"

	if [ "$BOARD" == "smarc-rzg2l" ] ; then
		BOARD_NAME="RZ/G2L SMARC Board by Renesas"
		if [ "$BOARD_VERSION" == "PMIC" ] ; then
			BOARD_NAME="$BOARD (PMIC Version)"
		fi
		if [ "$BOARD_VERSION" == "DISCRETE" ] ; then
			BOARD_NAME="$BOARD (Discrete Version)"
		fi
		if [ "$BOARD_VERSION" == "WS1" ] ; then
			BOARD_NAME="$BOARD (WS1)"
		fi
	fi
	if [ "$BOARD" == "smarc-rzg2lc" ] ; then
		BOARD_NAME="RZ/G2LC SMARC Board by Renesas"
	fi
	if [ "$BOARD" == "smarc-rzg2ul" ] ; then
		BOARD_NAME="RZ/G2UL SMARC Board by Renesas"
	fi
	if [ "$BOARD" == "smarc-rzv2l" ] ; then
		BOARD_NAME="RZ/V2L SMARC Board by Renesas"
		if [ "$BOARD_VERSION" == "PMIC" ] ; then
			BOARD_NAME="$BOARD (PMIC Version)"
		fi
		if [ "$BOARD_VERSION" == "DISCRETE" ] ; then
			BOARD_NAME="$BOARD (Discrete Version)"
		fi
	fi
	if [ "$BOARD" == "smarc-rzg3s" ] ; then
		BOARD_NAME="RZ/G3S SMARC Board by Renesas"
		SW_NAME="SW_MODE"
	fi

	SW_SETTINGS="

Use switches ${SW_NAME} on Carrier board to set the boot mode.

   SCIF Download Mode       SPI Boot Mode        eMMC Boot Mode
----------------------------------------------------------------
      SW11-1 = OFF           SW11-1 = OFF          SW11-1 = ON
      SW11-2 = ON            SW11-2 = OFF          SW11-2 = OFF
      SW11-3 = OFF           SW11-3 = OFF          SW11-3 = OFF
      SW11-4 = ON            SW11-4 = ON           SW11-4 = ON

      +---------+           +---------+           +---------+
      | ON      |           | ON      |           | ON      |
 SW11 |   =   = |      SW11 |       = |      SW11 | =     = |
      | =   =   |           | = = =   |           |   = =   |
      | 1 2 3 4 |           | 1 2 3 4 |           | 1 2 3 4 |
      +---------+           +---------+           +---------+
"
  fi
}

# The Flash and RAM address for each device is different.
set_flash_address() {

  if [ "$BOARD" == "hihope-rzg2m" ] || [ "$BOARD" == "hihope-rzg2n" ] || \
     [ "$BOARD" == "hihope-rzg2h" ] || [ "$BOARD" == "ek874" ] ; then

    SPI_SA0_RAM="E6320000"    ; SPI_SA0_FLASH="000000"
    SPI_BL2_RAM="E6304000"    ; SPI_BL2_FLASH="040000"
    SPI_SA6_RAM="E6320000"    ; SPI_SA6_FLASH="180000"
    SPI_BL31_RAM="44000000"   ; SPI_BL31_FLASH="1C0000"
    SPI_UBOOT_RAM="50000000"  ; SPI_UBOOT_FLASH="300000"
    SPI_FIP_RAM=""            ; SPI_FIP_FLASH="" # not used

    EMMC_SA0_RAM="E6320000"   ; EMMC_SA0_PART="1"   ; EMMC_SA0_SECTOR="000000"
    EMMC_BL2_RAM="E6304000"   ; EMMC_BL2_PART="1"   ; EMMC_BL2_SECTOR="00001E"
    EMMC_SA6_RAM="E6320000"   ; EMMC_SA6_PART="1"   ; EMMC_SA6_SECTOR="000180"
    EMMC_BL31_RAM="44000000"  ; EMMC_BL31_PART="1"  ; EMMC_BL31_SECTOR="000200"
    EMMC_UBOOT_RAM="50000000" ; EMMC_UBOOT_PART="2" ; EMMC_UBOOT_SECTOR="000000"
    EMMC_FIP_RAM=""           ; EMMC_FIP_PART=""    ; EMMC_FIP_SECTOR="" # not used
  fi

  if [ "$BOARD" == "smarc-rzg2l" ] || [ "$BOARD" == "smarc-rzg2lc" ] || [ "$BOARD" == "smarc-rzg2ul" ] || \
     [ "$BOARD" == "smarc-rzv2l" ] ; then

    LONGER_CMD_DELAY=1	# These parts need more time between sending commands

    SPI_SA0_RAM=""      ; SPI_SA0_FLASH="" # not used
    SPI_BL2_RAM="11E00" ; SPI_BL2_FLASH="0"
    SPI_SA6_RAM=""      ; SPI_SA6_FLASH="" # not used
    SPI_BL31_RAM=""     ; SPI_BL31_FLASH="" # not used
    SPI_UBOOT_RAM=""    ; SPI_UBOOT_FLASH="" # not used
    SPI_FIP_RAM="0"     ; SPI_FIP_FLASH="1D200"

    EMMC_SA0_RAM=""          ; EMMC_SA0_PART=""   ; EMMC_SA0_SECTOR=""   # not used
    EMMC_BL2_RAM="11E00"     ; EMMC_BL2_PART="1"  ; EMMC_BL2_SECTOR="1"
    EMMC_SA6_RAM=""          ; EMMC_SA6_PART=""   ; EMMC_SA6_SECTOR=""   # not used
    EMMC_BL31_RAM=""         ; EMMC_BL31_PART=""  ; EMMC_BL31_SECTOR=""  # not used
    EMMC_UBOOT_RAM=""        ; EMMC_UBOOT_PART="" ; EMMC_UBOOT_SECTOR="" # not used
    EMMC_FIP_RAM="0"         ; EMMC_FIP_PART="1"  ; EMMC_FIP_SECTOR="100"
  fi

  if [ "$BOARD" == "smarc-rzg3s" ] ; then

    LONGER_CMD_DELAY=1	# These parts need more time between sending commands

    SPI_SA0_RAM=""      ; SPI_SA0_FLASH="" # not used
    SPI_BL2_RAM="A1E00" ; SPI_BL2_FLASH="0"
    SPI_SA6_RAM=""      ; SPI_SA6_FLASH="" # not used
    SPI_BL31_RAM=""     ; SPI_BL31_FLASH="" # not used
    SPI_UBOOT_RAM=""    ; SPI_UBOOT_FLASH="" # not used
    SPI_FIP_RAM="0"     ; SPI_FIP_FLASH="64000"

    EMMC_SA0_RAM=""          ; EMMC_SA0_PART=""   ; EMMC_SA0_SECTOR=""   # not used
    EMMC_BL2_RAM="11E00"     ; EMMC_BL2_PART="1"  ; EMMC_BL2_SECTOR="1"
    EMMC_SA6_RAM=""          ; EMMC_SA6_PART=""   ; EMMC_SA6_SECTOR=""   # not used
    EMMC_BL31_RAM=""         ; EMMC_BL31_PART=""  ; EMMC_BL31_SECTOR=""  # not used
    EMMC_UBOOT_RAM=""        ; EMMC_UBOOT_PART="" ; EMMC_UBOOT_SECTOR="" # not used
    EMMC_FIP_RAM="0"         ; EMMC_FIP_PART="1" ; EMMC_FIP_SECTOR="100"
  fi
}

clear_filenames() {
  unset FLASHWRITER
  unset SA0_FILE
  unset BL2_FILE
  unset SA6_FILE
  unset BL31_FILE
  unset FIP_FILE
  unset UBOOT_FILE
}

# Use this function to determine if any config settings have changed
config_hash() {
  CONFIG_HASH_RESULT=$(echo "$BOARD" \
  "$BOARD_VERSION" \
  "$FLASH" \
  "$SERIAL_DEVICE_INTERFACE" \
  "$SERIAL_DEVICE_SPEED" \
  "$FILES_DIR" \
  "$FLASHWRITER" \
  "$FW_PREBUILT" \
  "$SA0_FILE" \
  "$BL2_FILE" \
  "$SA6_FILE" \
  "$BL31_FILE" \
  "$FIP_FILE" \
  "$UBOOT_FILE" \
  | md5sum)
}

# Use this function to determine if any app settings have changed
settings_hash() {
  SETTINGS_HASH_RESULT=$(echo "$CONFIG_FILE" \
  "$NEWT_COLORS" \
  | md5sum)
}

# Check if flash_writer binary has already been downloaded
check_fw_first() {

	unset CMD_ABORT

	if [ "$FW_NOT_DL_YET" == "1" ] ; then
		ANSWER=$(whiptail --yesno --defaultno "WARNING !\n\nThe Flash writer binary has not been downloaded yet.\
\n\nThe Flash Writer program must be downloaded and running for programming to work.\n\nContinue anyway?" 0 0 3>&1 1>&2 2>&3; echo $?)
		# 0=yes, 1=no
		if [ "$ANSWER" != "0" ] ; then
			CMD_ABORT=1
		else
			# Set to "2" so we only warn once
			export FW_NOT_DL_YET=2
		fi
	fi
}

# Common settings for Renesas boards
set_filenames() {

  if [ "$BOARD" == "ek874" ] || [ "$BOARD" == "hihope-rzg2m" ] || \
     [ "$BOARD" == "hihope-rzg2n" ] || [ "$BOARD" == "hihope-rzg2h" ] ; then

	if [ "$FILES_DIR" == "" ] ; then
		FILES_DIR="."
	fi
	if [ "$FLASHWRITER" == "" ] ; then
		if [ "$BOARD" == "hihope-rzg2m" ] || [ "$BOARD" == "hihope-rzg2n" ] || [ "$BOARD" == "hihope-rzg2h" ] ; then
			FLASHWRITER=$FILES_DIR/AArch64_Flash_writer_SCIF_DUMMY_CERT_E6300400_hihope.mot
		else
			FLASHWRITER=$FILES_DIR/AArch64_Flash_writer_SCIF_DUMMY_CERT_E6300400_${BOARD}.mot
		fi
	fi
	if [ "$SA0_FILE" == "" ] ; then
		SA0_FILE=$FILES_DIR/bootparam_sa0.srec
	fi
	if [ "$BL2_FILE" == "" ] ; then
		BL2_FILE=$FILES_DIR/bl2-${BOARD}.srec
	fi
	if [ "$SA6_FILE" == "" ] ; then
		SA6_FILE=$FILES_DIR/cert_header_sa6.srec
	fi
	if [ "$BL31_FILE" == "" ] ; then
		BL31_FILE=$FILES_DIR/bl31-${BOARD}.srec
	fi
	if [ "$UBOOT_FILE" == "" ] ; then
		UBOOT_FILE=$FILES_DIR/u-boot-elf-${BOARD}.srec
	fi
  fi

  if [ "$BOARD" == "smarc-rzg2l" ] || [ "$BOARD" == "smarc-rzg2lc" ] || [ "$BOARD" == "smarc-rzg2ul" ] || \
     [ "$BOARD" == "smarc-rzv2l" ] || [ "$BOARD" == "smarc-rzg3s" ] ; then

	FIP=1
	EMMC_4BIT=1

	if [ "$FILES_DIR" == "" ] ; then
		FILES_DIR="."
	fi
	if [ "$FLASHWRITER" == "" ] && [ "$BOARD" == "smarc-rzg2l" ]; then
		if [ "$BOARD_VERSION" == "PMIC" ] ; then
			FLASHWRITER="$FILES_DIR/Flash_Writer_SCIF_RZG2L_SMARC_PMIC_DDR4_2GB_1PCS.mot"
			BL2_FILE=$FILES_DIR/bl2_bp-${BOARD}_pmic.srec
			FIP_FILE=$FILES_DIR/fip-${BOARD}_pmic.srec
		else
			FLASHWRITER="$FILES_DIR/Flash_Writer_SCIF_RZG2L_SMARC_DDR4_2GB.mot"
		fi
	fi
	if [ "$FLASHWRITER" == "" ] && [ "$BOARD" == "smarc-rzg2lc" ]; then
		FLASHWRITER="$FILES_DIR/Flash_Writer_SCIF_RZG2LC_SMARC_DDR4_1GB_1PCS.mot"
	fi
	if [ "$FLASHWRITER" == "" ] && [ "$BOARD" == "smarc-rzg2ul" ]; then
		FLASHWRITER="$FILES_DIR/Flash_Writer_SCIF_RZG2UL_SMARC_DDR4_1GB_1PCS.mot"
	fi
	if [ "$FLASHWRITER" == "" ] && [ "$BOARD" == "smarc-rzv2l" ]; then
		if [ "$BOARD_VERSION" == "PMIC" ] ; then
			FLASHWRITER="$FILES_DIR/Flash_Writer_SCIF_RZV2L_SMARC_PMIC_DDR4_2GB_1PCS.mot"
			BL2_FILE=$FILES_DIR/bl2_bp-${BOARD}_pmic.srec
			FIP_FILE=$FILES_DIR/fip-${BOARD}_pmic.srec
		else
			FLASHWRITER="$FILES_DIR/Flash_Writer_SCIF_RZV2L_SMARC_DDR4_4GB.mot"
		fi
	fi
	if [ "$FLASHWRITER" == "" ] && [ "$BOARD" == "smarc-rzg3s" ]; then
		FLASHWRITER="$FILES_DIR/FlashWriter-smarc-rzg3s.mot"
	fi
	if [ "$BL2_FILE" == "" ] ; then
		BL2_FILE=$FILES_DIR/bl2_bp-${BOARD}.bin
	fi

	# New BSP releases will have separate BL2 files for SPI and eMMC.
	# If no BL2 file exits, check for _spi and _emmc versions
	if [ ! -e $BL2_FILE ] ; then

		if [ "$FLASH" == "0" ] ; then
			if [ -e $FILES_DIR/bl2_bp_spi-${BOARD}.bin ] ; then
				BL2_FILE=$FILES_DIR/bl2_bp_spi-${BOARD}.bin
			fi
		else
			if [ -e $FILES_DIR/bl2_bp_emmc-${BOARD}.bin ] ; then
				BL2_FILE=$FILES_DIR/bl2_bp_emmc-${BOARD}.bin
			fi
		fi
	fi

	if [ "$FIP_FILE" == "" ] ; then
		FIP_FILE=$FILES_DIR/fip-${BOARD}.bin
	fi

	# NOTE: 2024-02-02
	# RZ/G3S Binary is not working. So, only use .srec
	if [ "$BOARD" == "smarc-rzg3s" ] ; then
		if [ "${BL2_FILE: -3}" == "bin"  ] ; then
			# replace .bin with .srec
			BL2_FILE_BASE="${BL2_FILE:0:-3}"
			BL2_FILE="${BL2_FILE_BASE}srec"
		fi
		if [ "${FIP_FILE: -3}" == "bin"  ] ; then
			# replace .bin with .srec
			FIP_FILE_BASE="${FIP_FILE:0:-3}"
			FIP_FILE="${FIP_FILE_BASE}srec"
		fi
	fi

	# Clear file settings we do not use
	SA0_FILE=""
	SA6_FILE=""
	BL31_FILE=""
	UBOOT_FILE=""
  fi
}

set_fw_binary() {
  if [ "$FW_PREBUILT" == "1" ] ; then
    if [ "${BOARD:0:6}" == "hihope" ] ; then
      B_NAME="hihope"
    fi
    if [ "$BOARD" == "ek874" ] ; then
      B_NAME="ek874"
    fi
    if [ "$FLASH" == "0" ] ; then
      F_NAME="SPI"
    else
      F_NAME="eMMC"
    fi
    if [ "${SERIAL_DEVICE_INTERFACE:8:3}" == "ACM" ] ; then
      S_NAME="USB"
    else
      S_NAME="SCIF"
    fi

    FLASHWRITER="./binaries/Flash_writer_${B_NAME}_${S_NAME}_${F_NAME}.mot"

    if [ "$BOARD" == "smarc-rzg2l" ] ; then
      FLASHWRITER="./binaries/Flash_Writer_SCIF_RZG2L_SMARC_DDR4_2GB.mot"
    fi
    if [ "$BOARD" == "smarc-rzg2lc" ] ; then
      FLASHWRITER="./binaries/Flash_Writer_SCIF_RZG2LC_SMARC_DDR4_1GB_1PCS.mot"
    fi
    if [ "$BOARD" == "smarc-rzg2ul" ] ; then
      FLASHWRITER="./binaries/Flash_Writer_SCIF_RZG2UL_SMARC_DDR4_1GB_1PCS.mot"
    fi

  fi
}

do_menu_config() {
  SELECT=$(whiptail --title "Config File Selection" --menu "You may use ESC+ESC to cancel.\n\nHow do you want to select the file?" 0 0 0 \
	"1 File Browse" "  Use a GUI File broswer " \
	"2 Enter"        "  Manual enter the filename." \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *)
		which zenity > /dev/null
		if [ "$?" != "0" ] ; then
			whiptail --yesno "ERROR: You need the (small) \"zenity\" dialog box utility installed.\nYou can install by running:\n\n$ sudo apt-get install zenity\n\nRun that command now to install?" 0 0 0
			if [ "$?" == "0" ] ; then
				echo "sudo apt-get install zenity"
				sudo apt-get install zenity
				echo "--------------------------"
				echo " Install complete"
				echo "--------------------------"
				sleep 2
				do_menu_config
			fi
		else
			FILE=`zenity --file-selection --filename="$CONFIG_FILE"  --file-filter=*.ini --title="Select your config file (*.ini)"`
			case $? in
			0)
				# Strip out the full path if it is in the same directory
				PWD="$(pwd)/"
				SELECT=$(echo $FILE | sed "s:$PWD::")
				CONFIG_FILE="$SELECT"
				source "$CONFIG_FILE"
				config_hash
				CONFIG_HASH=$CONFIG_HASH_RESULT
				;;
			-1)
				whiptail --msgbox "An unexpected error has occurred." 0 0 0
				;;
			esac
		fi
		;;
      2\ *)
		SELECT=$(whiptail --title "Config File Selection" --inputbox "You may use ESC+ESC to cancel.\n\n Enter the filename to your config file." 0 100 \
		"config.ini"  \
		3>&1 1>&2 2>&3)
		RET=$?
		if [ $RET -eq 0 ] ; then

			if [ ! -e "$SELECT" ] ; then
				whiptail --msgbox "New file?\n\nFile \"$SELECT\" does not exist.\nThis file will be created if you save and exit.\n" 0 0 0
			fi
			CONFIG_FILE="$SELECT"
			source "$CONFIG_FILE"
			config_hash
			CONFIG_HASH=$CONFIG_HASH_RESULT
		fi
		;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

do_menu_board() {
  SELECT=$(whiptail --title "Board Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1 ek874"        "  EK874 RZ/G2E by Silicon Linux" \
	"2 hihope-rzg2m" "  HiHope RZ/G2M by Hoperun Technology" \
	"3 hihope-rzg2n" "  HiHope RZ/G2N by Hoperun Technology" \
	"4 hihope-rzg2h" "  HiHope RZ/G2H by Hoperun Technology" \
	"5 smarc-rzg2l " "  SMARC RZ/G2L by Renesas Electronics" \
	"6 smarc-rzg2lc " " SMARC RZ/G2LC by Renesas Electronics" \
	"7 smarc-rzg2ul " " SMARC RZ/G2UL by Renesas Electronics" \
	"8 smarc-rzv2l " "  SMARC RZ/V2L by Renesas Electronics" \
	"9 smarc-rzg3s " "  SMARC RZ/G3S by Renesas Electronics" \
	"0 CUSTOM"       "  (manually edit ini file)" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    FIP=0
    EMMC_4BIT=0
    case "$SELECT" in
      1\ *) BOARD=ek874 ;;
      2\ *) BOARD=hihope-rzg2m ;;
      3\ *) BOARD=hihope-rzg2n ;;
      4\ *) BOARD=hihope-rzg2h ;;
      5\ *) BOARD=smarc-rzg2l ; FIP=1 ; EMMC_4BIT=1
	whiptail --yesno --yes-button PMIC_Power --no-button Discrete_Power "Board Version:\n\nIs the board 'PMIC Power' version or the 'Discrete Power' version?\n\nThe PMIC version has \"Reneas\" printed in the middle of the SOM board.\nThe Discrete version has \"Renesas\" printed at the edge of the SOM baord.   " 0 0 0
	if [ "$?" == "0" ] ; then
		BOARD_VERSION="PMIC"
	else
		BOARD_VERSION="DISCRETE"
	fi
      ;;
      6\ *) BOARD=smarc-rzg2lc ; FIP=1 ; EMMC_4BIT=1 ;;
      7\ *) BOARD=smarc-rzg2ul ; FIP=1 ; EMMC_4BIT=1 ;;
      8\ *) BOARD=smarc-rzv2l ; FIP=1 ; EMMC_4BIT=1
	whiptail --yesno --yes-button PMIC_Power --no-button Discrete_Power "Board Version:\n\nIs the board 'PMIC Power' version or the 'Discrete Power' version?" 0 0 0
	if [ "$?" == "0" ] ; then
		BOARD_VERSION="PMIC"
	else
		BOARD_VERSION="DISCRETE"
	fi
      ;;
      9\ *) BOARD=smarc-rzg3s ; FIP=1 ; EMMC_4BIT=1 ;;
      0\ *) BOARD=CUSTOM ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1

    unset FILES_DIR
    switch_settings
    set_flash_address
    clear_filenames
    set_filenames
    set_fw_binary

  fi
}

do_menu_target_flash() {
  SELECT=$(whiptail --title "Target Flash Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1 SPI Flash"  " " \
	"2 eMMC Flash" " " \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) FLASH=0 ;
        # Sometimes the file names are different between SPI and eMMC builds
        #clear_filenames  # Clear all file names
	BL2_FILE="" # only clear BL2, the rest should have the same name
        set_filenames
        ;;
      2\ *) FLASH=1
        # Sometimes the file names are different between SPI and eMMC builds
        #clear_filenames  # Clear all file names
	BL2_FILE="" # only clear BL2, the rest should have the same name
        set_filenames
        ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi

  set_fw_binary
}

do_menu_dev() {
  SELECT=$(whiptail --title "Interface Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1 /dev/ttyUSB0" "  SCIF Download mode" \
	"2 /dev/ttyACM0" "  USB Download mode" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) SERIAL_DEVICE_INTERFACE="/dev/ttyUSB0" ;;
      2\ *) SERIAL_DEVICE_INTERFACE="/dev/ttyACM0" ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi

  set_fw_binary
}

do_menu_speed() {
  SELECT=$(whiptail --title "Interface Speed Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1 115200" "  Default for all devices" \
	"2 921600" "  Issue SUP command before downloads" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) SERIAL_DEVICE_SPEED="115200" ;;
      2\ *) SERIAL_DEVICE_SPEED="921600" ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}


do_menu_colors() {
  SELECT=$(whiptail --title "GUI menu colors" --menu "You may use ESC+ESC to cancel.\n\nSelect the color theme you want to use" 0 0 0 \
	"1  Default" " " \
	"2  Black and Green" " " \
	"3  Black and White" " " \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *)
export NEWT_COLORS='
root=,blue
'
;;
      2\ *)
export NEWT_COLORS='
    root=green,black
    border=green,black
    title=green,black
    roottext=white,black
    window=green,black
    textbox=white,black
    button=black,green
    compactbutton=white,black
    listbox=white,black
    actlistbox=black,white
    actsellistbox=black,green
    checkbox=green,black
    actcheckbox=black,green
'
;;
      3\ *)
export NEWT_COLORS='
    root=white,black
    border=black,lightgray
    window=lightgray,lightgray
    shadow=black,gray
    title=black,lightgray
    button=black,cyan
    actbutton=white,cyan
    compactbutton=black,lightgray
    checkbox=black,lightgray
    actcheckbox=lightgray,cyan
    entry=black,lightgray
    disentry=gray,lightgray
    label=black,lightgray
    listbox=black,lightgray
    actlistbox=black,cyan
    sellistbox=lightgray,black
    actsellistbox=lightgray,black
    textbox=black,lightgray
    acttextbox=black,cyan
    emptyscale=,gray
    fullscale=,cyan
    helpline=white,black
    roottext=lightgrey,black
'
;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

do_menu_extra() {
  SELECT=$(whiptail --title "Extra menu" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1  Change GUI Colors" " " \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) do_menu_colors ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

do_menu_file_dir() {

  # Save to check later
  ORIG_FILES_DIR=$FILES_DIR

  SELECT=$(whiptail --title "File Directory Selection" --menu "You may use ESC+ESC to cancel.\n\nHow do you want to select the directory?" 0 0 0 \
	"1 File Browse" "  Use a GUI File broswer " \
	"2 Enter"        "  Manual enter the directory." \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *)
		which zenity > /dev/null
		if [ "$?" != "0" ] ; then
			whiptail --yesno "ERROR: You need the (small) \"zenity\" dialog box utility installed.\nYou can install by running:\n\n$ sudo apt-get install zenity\n\nRun that command now to install?" 0 0 0
			if [ "$?" == "0" ] ; then
				echo "sudo apt-get install zenity"
				sudo apt-get install zenity
				echo "--------------------------"
				echo " Install complete"
				echo "--------------------------"
				sleep 2
				do_menu_file_dir
			fi
		else
			FILE=`zenity --directory --file-selection --filename=".."  --title="Select your base directory"`
			case $? in
			0)
				FILES_DIR="$FILE"
				;;
			-1)
				whiptail --msgbox "An unexpected error has occurred." 0 0 0
				;;
			esac
		fi
		;;
      2\ *)
		SELECT=$(whiptail --title "File Direcotry Selection" --inputbox "You may use ESC+ESC to cancel.\n\n Enter the base directory you want to use." 0 100 \
		"$FILES_DIR"  \
		3>&1 1>&2 2>&3)
		RET=$?
		if [ $RET -eq 0 ] ; then

			if [ ! -e "$SELECT" ] ; then
				whiptail --msgbox "Warning: Directory does not exist\n" 0 0 0
			fi
			FILES_DIR="$SELECT"
		fi
		;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi

  # If we changed the value, then update all the other files
  if [ "$ORIG_FILES_DIR" != "$FILES_DIR" ] ; then
    clear_filenames
    set_filenames
  fi
}

do_menu_file_fw() {
  SELECT=$(whiptail --title "Flash Writer Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1. Enter filename" " " \
	"2. Use included prebuilt binaries (auto select)" " " \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) FW_PREBUILT=0 ;;
      2.\ *) FW_PREBUILT=1 ; set_fw_binary ; return ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi

  SELECT=$(whiptail --title "Flash Writer File Selection" --inputbox "You may use ESC+ESC to cancel.\n\n Enter file path to Flash Writer File." 0 100 \
	"AArch64_Flash_writer_SCIF_DUMMY_CERT_E6300400_${BOARD}.mot"  \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
   FLASHWRITER="$SELECT"
  fi
}

do_menu_file_sa0() {
  SELECT=$(whiptail --title "SA0 File Selection" --inputbox "You may use ESC+ESC to cancel.\n\n Enter file path to SA0 File." 0 100 \
	"${SA0_FILE}"  \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
   SA0_FILE="$SELECT"
  fi
}

do_menu_file_bl2() {
  SELECT=$(whiptail --title "BL2 File Selection" --inputbox "You may use ESC+ESC to cancel.\n\n Enter file path to BL2 File." 0 100 \
	"${BL2_FILE}"  \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
   BL2_FILE="$SELECT"
  fi
}

do_menu_file_sa6() {
  SELECT=$(whiptail --title "SA6 File Selection" --inputbox "You may use ESC+ESC to cancel.\n\n Enter file path to SA6 File." 0 100 \
	"${SA6_FILE}"  \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
   SA6_FILE="$SELECT"
  fi
}

do_menu_file_bl31() {
  SELECT=$(whiptail --title "BL31 File Selection" --inputbox "You may use ESC+ESC to cancel.\n\n Enter file path to BL31 File." 0 100 \
	"${BL31_FILE}"  \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
   BL31_FILE="$SELECT"
  fi
}

do_menu_file_fip() {
  SELECT=$(whiptail --title "FIP File Selection" --inputbox "You may use ESC+ESC to cancel.\n\n Enter file path to FIP File." 0 100 \
	"${FIP_FILE}"  \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
   FIP_FILE="$SELECT"
  fi
}

do_menu_file_uboot() {
  SELECT=$(whiptail --title "u-boot File Selection" --inputbox "You may use ESC+ESC to cancel.\n\n Enter file path to u-boot File." 0 100 \
	"${UBOOT_FILE}"  \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
   UBOOT_FILE="$SELECT"
  fi
}

do_cmd_atf() {
	FW_GUI_MODE=2
	echo "${SCRIPT_DIR}/flash_writer_tool.sh atf"
	"${SCRIPT_DIR}"/flash_writer_tool.sh atf
	FW_GUI_MODE=1
}

do_cmd_all() {
	FW_GUI_MODE=2
	echo "${SCRIPT_DIR}/flash_writer_tool.sh all"
	"${SCRIPT_DIR}"/flash_writer_tool.sh all
	FW_GUI_MODE=1
}

do_cmd_sw() {
	#printf '%s\n' "$SW_SETTINGS"
	#read dummy
	whiptail --title "$BOARD_NAME" --msgbox "$SW_SETTINGS" 0 0
}

do_cmd() {
	export SERIAL_DEVICE_SPEED=$SERIAL_DEVICE_SPEED

	# Create a temporary config file and pass to sub-script
	CFG_TMP_FILE="/tmp/tmp_gui_config.ini"
	CONFIG_FILE_SAVE=$CONFIG_FILE
	CONFIG_FILE=$CFG_TMP_FILE
	save_config
	CONFIG_FILE=$CONFIG_FILE_SAVE  # restore

	echo "FW_GUI_MODE=2 ${SCRIPT_DIR}/flash_writer_tool.sh $CFG_TMP_FILE $CMD"
	FW_GUI_MODE=2 "${SCRIPT_DIR}"/flash_writer_tool.sh $CFG_TMP_FILE $CMD
}

save_config() {

	echo "# This file was created by the flash_writer_tool.sh" > $CONFIG_FILE
	echo "BOARD=$BOARD" >> $CONFIG_FILE
	echo "BOARD_VERSION=$BOARD_VERSION" >> $CONFIG_FILE
	echo "FLASH=$FLASH" >> $CONFIG_FILE
	echo "SERIAL_DEVICE_INTERFACE=$SERIAL_DEVICE_INTERFACE" >> $CONFIG_FILE
	echo "SERIAL_DEVICE_SPEED=$SERIAL_DEVICE_SPEED" >> $CONFIG_FILE

	echo "FILES_DIR=$FILES_DIR" >> $CONFIG_FILE
	echo "FW_PREBUILT=$FW_PREBUILT" >> $CONFIG_FILE
	echo "FLASHWRITER=$FLASHWRITER" >> $CONFIG_FILE
	echo "FIP=$FIP" >> $CONFIG_FILE
	echo "EMMC_4BIT=$EMMC_4BIT" >> $CONFIG_FILE
	echo "SA0_FILE=$SA0_FILE" >> $CONFIG_FILE
	echo "BL2_FILE=$BL2_FILE" >> $CONFIG_FILE
	echo "SA6_FILE=$SA6_FILE" >> $CONFIG_FILE
	echo "BL31_FILE=$BL31_FILE" >> $CONFIG_FILE
	echo "FIP_FILE=$FIP_FILE" >> $CONFIG_FILE
	echo "UBOOT_FILE=$UBOOT_FILE" >> $CONFIG_FILE
}

save_settings() {
	echo "CONFIG_FILE=$CONFIG_FILE" > settings.txt
	echo -e "\n# Whiptail colors\nexport NEWT_COLORS='""$NEWT_COLORS""'" >> settings.txt
}


#################################################################
# Script Start GUI
#################################################################
if [ "$FW_GUI_MODE" == "1" ] ; then

  # Set Default Whiptail color (blue looks better than purple)
  export NEWT_COLORS='
  root=,blue
  '

  # Default board file
  CONFIG_FILE=config.ini

  # Change Terminal size (because I like to double-click in the file manager to run this this)
  # Do not do this if you are in a SSH or docker session
  if [ "$DISPLAY" != "" ] ; then
    #printf '\033[8;40;120t'
    resize -s 43 120  > /dev/null
  fi

  # Read what we used last time
  if [ -e "settings.txt" ] ; then
    source settings.txt
    source "$CONFIG_FILE"
  fi

  # Some default entries if first use
  if [ "$BOARD" == "" ] ; then
    # Check for Yocto output files
    if [ -e ../../build/tmp/deploy/images ] ; then
      IMAGES_DIR=../../build/tmp/deploy/images
    elif [ -e build/tmp/deploy/images ] ; then
      IMAGES_DIR=build/tmp/deploy/images
    else
      IMAGES_DIR=".."
    fi

    if [ -e ${IMAGES_DIR}/hihope-rzg2h ] ; then
      BOARD="hihope-rzg2h"
      DETECTED=1
    elif [ -e ${IMAGES_DIR}/hihope-rzg2m ] ; then
      BOARD="hihope-rzg2m"
      DETECTED=1
    elif [ -e ${IMAGES_DIR}/hihope-rzg2n ] ; then
      BOARD="hihope-rzg2n"
      DETECTED=1
    elif [ -e ${IMAGES_DIR}/ek874 ] ; then
      BOARD="ek874"
      DETECTED=1
    elif [ -e ${IMAGES_DIR}/smarc-rzg2l ] ; then
      BOARD="smarc-rzg2l"
      FIP=1
      EMMC_4BIT=1
      DETECTED=1
      # Select PMIC version as default
      BOARD_VERSION="PMIC"
    elif [ -e ${IMAGES_DIR}/smarc-rzg2lc ] ; then
      BOARD="smarc-rzg2lc"
      FIP=1
      EMMC_4BIT=1
      DETECTED=1
    elif [ -e ${IMAGES_DIR}/smarc-rzg2ul ] ; then
      BOARD="smarc-rzg2ul"
      FIP=1
      EMMC_4BIT=1
      DETECTED=1
    elif [ -e ${IMAGES_DIR}/smarc-rzv2l ] ; then
      BOARD="smarc-rzv2l"
      FIP=1
      EMMC_4BIT=1
      DETECTED=1
      # Select PMIC version as default
      BOARD_VERSION="PMIC"
    elif [ -e ${IMAGES_DIR}/smarc-rzg3s ] ; then
      BOARD="smarc-rzg3s"
      FIP=1
      EMMC_4BIT=1
      DETECTED=1
    else
      # default to RZ/G2M
      BOARD="hihope-rzg2m"
      FILES_DIR=~/yocto/rzg2_bsp_eva_v106/build/tmp/deploy/images/${BOARD}
    fi

    if [ "$DETECTED" == "1" ] ; then
      if [ "$IMAGES_DIR" == ".." ] ; then
         # script is running in directory with the files
         FILES_DIR="."
      else
         FILES_DIR=${IMAGES_DIR}/${BOARD}
      fi

      whiptail --msgbox "Detected Yocto output files for board \"$BOARD\"\n\nSetting FILES_DIR=${FILES_DIR}" 0 0 1
    fi

    # default values
    SERIAL_DEVICE_INTERFACE="/dev/ttyUSB0"
    SERIAL_DEVICE_SPEED=115200
    FLASH="0"
    CONFIG_FILE="config.ini"
  fi

  config_hash
  CONFIG_HASH=$CONFIG_HASH_RESULT
  settings_hash
  SETTINGS_HASH=$SETTINGS_HASH_RESULT

  export FW_NOT_DL_YET=1

  while true ; do

    # Set BOARD_NAME and SW_SETTINGS
    switch_settings

    # Set Flash and RAM addresses
    set_flash_address

    # Set files for Renesas boards
    set_filenames

    # change the text that is displayed on the screen
    FLASH_TEXT=("SPI Flash" "eMMC Flash")
    if [ "${FLASHWRITER:0:6}" != "binaries" ] && [ "${FLASHWRITER:2:8}" != "binaries" ] ; then
      FLASHWRITER_TEXT=$(echo $FLASHWRITER | sed "s:$FILES_DIR:\$(FILES_DIR):")
    else
      if [ "$FW_PREBUILT" == "1" ] ; then
        FLASHWRITER_TEXT="$FLASHWRITER (auto select)"
      else
        FLASHWRITER_TEXT="$FLASHWRITER"
      fi
    fi
    SA0_FILE_TEXT=$(echo $SA0_FILE | sed "s:$FILES_DIR:\$(FILES_DIR):")
    BL2_FILE_TEXT=$(echo $BL2_FILE | sed "s:$FILES_DIR:\$(FILES_DIR):")
    SA6_FILE_TEXT=$(echo $SA6_FILE | sed "s:$FILES_DIR:\$(FILES_DIR):")
    BL31_FILE_TEXT=$(echo $BL31_FILE | sed "s:$FILES_DIR:\$(FILES_DIR):")
    FIP_FILE_TEXT=$(echo $FIP_FILE | sed "s:$FILES_DIR:\$(FILES_DIR):")
    UBOOT_FILE_TEXT=$(echo $UBOOT_FILE | sed "s:$FILES_DIR:\$(FILES_DIR):")

    # check if files exits
    if [ -e "$FILES_DIR" ] ; then FD_EXIST="✓" ; else FD_EXIST="x" ; fi
    if [ -e "$FLASHWRITER" ] ; then FW_EXIST="✓" ; else FW_EXIST="x" ; fi
    if [ -e "$SA0_FILE" ] ; then SA0_EXIST="✓" ; else SA0_EXIST="x" ; fi
    if [ -e "$BL2_FILE" ] ; then BL2_EXIST="✓" ; else BL2_EXIST="x" ; fi
    if [ -e "$SA6_FILE" ] ; then SA6_EXIST="✓" ; else SA6_EXIST="x" ; fi
    if [ -e "$BL31_FILE" ] ; then BL31_EXIST="✓" ; else BL31_EXIST="x" ; fi
    if [ -e "$FIP_FILE" ] ; then FIP_EXIST="✓" ; else FIP_EXIST="x" ; fi
    if [ -e "$UBOOT_FILE" ] ; then UBOOT_EXIST="✓" ; else UBOOT_EXIST="x" ; fi

    # Remove entries based on FIP
    if [ "$FIP" == "0" ] ; then
      FIP_EXIST=" " ; FIP_FILE_TEXT=""
    else
      SA0_EXIST=" " ; SA0_FILE_TEXT=""
      SA6_EXIST=" " ; SA6_FILE_TEXT=""
      BL31_EXIST=" " ; BL31_FILE_TEXT=""
      UBOOT_EXIST=" " ; UBOOT_FILE_TEXT=""
    fi

    # Remind users to run flash writer first (FWR =Flash Writer Reminder)
    # Show what operations the user can choose
    OP1=" " # SA0, SA6, BL31, u-boot, ALL
    OP2=" " # BL2, ATF
    OP3=" " # FIP
    OP4=" " # eMMC

    if [ "$FW_NOT_DL_YET" == "1" ] ; then
      FWR="★"
    else
      FWR=" "
      if [ "$FLASH" == "1" ] ; then
        OP4="★"
      fi
      if [ "$FIP" == "0" ] ; then
        OP1="★"
        OP2="★"
      else
        OP2="★"
        OP3="★"
      fi
    fi

    # Files directory does not exist, remind user to set(FDR = FILES DIR Reminder)
    if [ ! -e "$FILES_DIR" ] ; then  FDR="★" ; else FDR=" " ; fi

    # check if any settings have changed
    config_hash
    settings_hash
    if [ "$CONFIG_HASH" != "$CONFIG_HASH_RESULT" ] || [ "$SETTINGS_HASH" != "$SETTINGS_HASH_RESULT" ] ; then
      CHANGE_TEXT="\n             !!!! WARNING: Changes not saved yet  !!!!!"
      OK_TEXT="SAVE-and-EXIT"
    else
      CHANGE_TEXT=""
      OK_TEXT="EXIT"
    fi

    if [ "${SERIAL_DEVICE_INTERFACE:8:3}" == "ACM" ] ; then DL_TYPE="USB Download Mode" ; else DL_TYPE="SCIF Download Mode" ; fi

    SELECT=$(whiptail --title "RZ/G2 Flash Writer Tool" --menu \
	"Select your programming options.\nYou may use [ESC]+[ESC] to Cancel/Exit (no save). Use [Tab] key to select buttons.\n\nUse the <Change> button (or enter) to make changes.\n$CHANGE_TEXT" 0 0 0 --cancel-button $OK_TEXT --ok-button Change \
	--default-item "$LAST_SELECT" \
	"               Board:" "  $BOARD_NAME"  \
	"        Target Flash:" "  ${FLASH_TEXT[$FLASH]}" \
	"           Interface:" "  $SERIAL_DEVICE_INTERFACE  ($DL_TYPE)"  \
	"               Speed:" "  $SERIAL_DEVICE_SPEED"  \
	"         Config File:" "  $CONFIG_FILE"  \
	"      Extra Settings:" "  GUI Colors, windows size, etc..."  \
	"_______Files_________" "" \
	"    $FDR      FILES_DIR:" "$FD_EXIST $FILES_DIR" \
	"         FLASHWRITER:" "$FW_EXIST $FLASHWRITER_TEXT" \
	"            SA0_FILE:" "$SA0_EXIST $SA0_FILE_TEXT" \
	"            BL2_FILE:" "$BL2_EXIST $BL2_FILE_TEXT" \
	"            SA6_FILE:" "$SA6_EXIST $SA6_FILE_TEXT" \
	"           BL31_FILE:" "$BL31_EXIST $BL31_FILE_TEXT" \
	"           FIP_FILE:" "$FIP_EXIST $FIP_FILE_TEXT" \
	"          UBOOT_FILE:" "$UBOOT_EXIST $UBOOT_FILE_TEXT" \
	"______Operations_____" "" \
	"a. $FWR Download F.W.   " "  Downloads the Flash Writer binary (must be run first)" \
	"b. $OP1 Program SA0     " "  SA0 (Boot Parameters)" \
	"c. $OP2 Program BL2     " "  BL2 (Trusted Boot Firmware)" \
	"d. $OP1 Program SA6     " "  SA6 (Cert Header)" \
	"e. $OP1 Program BL31    " "  BL31 (EL3 Runtime Software)" \
	"f. $OP3 Program FIP     " "  FIP (Firmware Image Package)" \
	"g. $OP1 Program u-boot  " "  u-boot (BL33, Non-trusted Firmware)" \
	"h. $OP2 Program ATF     " "  Program all arm-trusted-firmware files (SA0,BL2,SA6,BL31,FIP)" \
	"i. $OP1 Program All     " "  Programs all files (SA0,BL2,SA6,BL31 and u-boot)" \
	"j. $OP4 eMMC boot setup " "  Configure an eMMC device for booting (only needed once)" \
	"s. $FWR Show switches   " "  Show the switch settings for Renesas boards (in case you forgot)" \
	"x1. $OP1 Erase BootPart1 " "  Erases eMMC Boot Partition 1 (needed when re-flashing to clear u-boot)" \
	"x2. $OP1 Erase BootPart2 " "  Erases eMMC Boot Partition 2 (needed when re-flashing to clear u-boot env)" \
	"x0. $OP1 Erase UserPart  " "  Erases eMMC User Partition 0 (optional)" \
	3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ] ; then
      # save if changes
      config_hash
      if [ "$CONFIG_HASH" != "$CONFIG_HASH_RESULT" ] || [ ! -e "$CONFIG_FILE" ] ; then
        save_config
      fi

      # Global Settings
      settings_hash
      if [ "$SETTINGS_HASH" != "$SETTINGS_HASH_RESULT" ]  || [ ! -e settings.txt ] ; then
        save_settings
      fi

      if [ "$SERIAL_DEVICE_SPEED" == "921600" ] ; then
        # Put baud rate back to default
        stty -F $SERIAL_DEVICE_INTERFACE 115200
      fi

      break;
    elif [ $RET -eq 0 ] ; then
      LAST_SELECT="$SELECT"
      case "$SELECT" in
        *Board:*) do_menu_board ;;
        *Target\ Flash:*) do_menu_target_flash ;;
        *Interface:*) do_menu_dev ;;
        *Speed:*) do_menu_speed ;;
        *Config\ File:*) do_menu_config ;;
        *Extra\ Settings:*) do_menu_extra ;;

        *Files*) ;;

        *FILES_DIR:*) do_menu_file_dir ;;
        *FLASHWRITER:*) do_menu_file_fw ;;
        *SA0_FILE:*) if [ "$FIP" == "1" ] ; then continue ; fi ; do_menu_file_sa0 ;;
        *BL2_FILE:*) do_menu_file_bl2 ;;
        *SA6_FILE:*) if [ "$FIP" == "1" ] ; then continue ; fi ; do_menu_file_sa6 ;;
        *BL31_FILE:*) if [ "$FIP" == "1" ] ; then continue ; fi ; do_menu_file_bl31 ;;
        *FIP_FILE:*) if [ "$FIP" == "0" ] ; then continue ; fi ; do_menu_file_fip ;;
        *UBOOT_FILE:*) if [ "$FIP" == "1" ] ; then continue ; fi ; do_menu_file_uboot ;;

        *Operations*) ;;

        *Download\ F.W.*) whiptail --title "Download mode" --msgbox "Make sure the board is configured for \"SCIF Download mode\" or \"USB Download mode\"\n\nPower on the board and press the RESET button.\n\nThen, press ENTER on the keyboard to continue." 0 0 ;
		CMD=fw FILE_TO_SEND=$FLASHWRITER ; do_cmd ; export FW_NOT_DL_YET=0 ;;
        *Erase\ UserPart*) CMD=x0 ; FILE_TO_SEND= ; do_cmd ;;
        *Erase\ BootPart1*) CMD=x1 ; FILE_TO_SEND= ; do_cmd ;;
        *Erase\ BootPart2*) CMD=x2 ; FILE_TO_SEND= ; do_cmd ;;
        *Program\ SA0*) if [ "$FIP" == "1" ] ; then continue ; fi ; check_fw_first ; if [ "$CMD_ABORT" != "1" ] ; then CMD=sa0 ; FILE_TO_SEND=$SA0_FILE ; do_cmd ; fi ;;
        *Program\ BL2*) check_fw_first ; if [ "$CMD_ABORT" != "1" ] ; then CMD=bl2 ; FILE_TO_SEND=$BL2_FILE ; do_cmd ; fi ;;
        *Program\ SA6*) if [ "$FIP" == "1" ] ; then continue ; fi ; check_fw_first ; if [ "$CMD_ABORT" != "1" ] ; then CMD=sa6 ; FILE_TO_SEND=$SA6_FILE ; do_cmd ; fi ;;
        *Program\ BL31*) if [ "$FIP" == "1" ] ; then continue ; fi ; check_fw_first ; if [ "$CMD_ABORT" != "1" ] ; then CMD=bl31 ; FILE_TO_SEND=$BL31_FILE ; do_cmd ; fi ;;
        *Program\ FIP*) if [ "$FIP" == "0" ] ; then continue ; fi ; check_fw_first ; if [ "$CMD_ABORT" != "1" ] ; then CMD=fip ; FILE_TO_SEND=$FIP_FILE ; do_cmd ; fi ;;
        *Program\ u-boot*) if [ "$FIP" == "1" ] ; then continue ; fi ; check_fw_first ; if [ "$CMD_ABORT" != "1" ] ; then CMD=uboot ; FILE_TO_SEND=$UBOOT_FILE ; do_cmd ; fi ;;
        *Program\ ATF*) check_fw_first ; if [ "$CMD_ABORT" != "1" ] ; then
		if [ "$FIP" == "0" ] ; then
		  CMD=sa0 ; FILE_TO_SEND=$SA0_FILE ; do_cmd ; sleep 1 ;
		  CMD=bl2 ; FILE_TO_SEND=$BL2_FILE ; do_cmd ; sleep 2 ;
		  CMD=sa6 ; FILE_TO_SEND=$SA6_FILE ; do_cmd ;  sleep 1 ;
		  CMD=bl31 ; FILE_TO_SEND=$BL31_FILE ; do_cmd ;  sleep 2 ;
		else
		 CMD=bl2 ; FILE_TO_SEND=$BL2_FILE ; do_cmd ; sleep 2 ;
		 CMD=fip ; FILE_TO_SEND=$FIP_FILE ; do_cmd ; sleep 2 ;
		fi
		fi ;;
        *Program\ All*) if [ "$FIP" == "1" ] ; then continue ; fi ; check_fw_first ; if [ "$CMD_ABORT" != "1" ] ; then
		CMD=sa0 ; FILE_TO_SEND=$SA0_FILE ; do_cmd ;  sleep 1 ;
		CMD=bl2 ; FILE_TO_SEND=$BL2_FILE ; do_cmd ;  sleep 2 ;
		CMD=sa6 ; FILE_TO_SEND=$SA6_FILE ; do_cmd ;  sleep 1 ;
		CMD=bl31 ; FILE_TO_SEND=$BL31_FILE ; do_cmd ;  sleep 2 ;
		CMD=uboot ; FILE_TO_SEND=$UBOOT_FILE ; do_cmd ;  sleep 2 ;
		fi ;;
        *eMMC*) CMD=emmc_config ; FILE_TO_SEND= ; do_cmd ;;
        *switches*) do_cmd_sw ;;
        *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
    else
      exit 1
    fi
  done
  exit
fi

# do_xls2
# $1 = string
# $2 = RAM address to download to
# $3 = SPI address to write to
# $4 = filename
do_xls2() {
	# Flash writer just looks for CR. If it see LF, it ignores it.
	echo "Writting $1 ($4)"
	echo "Sending XLS2 command..."
	echo -en "XLS2\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "$2\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "$3\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo "Sending file..."
	#cat $4 > $SERIAL_DEVICE_INTERFACE
	stat -L --printf="%s bytes\n" $4
	dd if=$4 of=$SERIAL_DEVICE_INTERFACE bs=1k status=progress
	sleep $CMD_DELAY

	# You only need to send a 'y', not the 'y' + CR. But, if the flash is already
	# blank, flash writer will not ask you to confirm, so we send y + CR
	# just in case. So if the flash is already blank you will just see an
	# extra 'command not found' message which does not hurt anything.
	echo -en "y\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo ""
}

# do_xls3
# $1 = string
# $2 = SPI address to write to
# $3 = filename
do_xls3() {
	# Flash writer just looks for CR. It ignores LF characters.
	echo "Writting $1 ($3)"
	echo "Sending XLS3 command..."
	echo -en "XLS3\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY

	# get the file size of our binary
	SIZE_DEC=$(stat -L --printf="%s" $3)
	SIZE_HEX=$(printf '%X' $SIZE_DEC)
	echo -en "$SIZE_HEX\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY

	echo -en "$2\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY

	echo "Sending file..."
	#cat $3 > $SERIAL_DEVICE_INTERFACE
	stat -L --printf="%s bytes\n" $3
	dd if=$3 of=$SERIAL_DEVICE_INTERFACE bs=1k status=progress
	sleep $CMD_DELAY

	# You only need to send a 'y', not the 'y' + CR. But, if the flash is already
	# blank, flash writer will not ask you to confirm, so we send y + CR
	# just in case. So if the flash is already blank you will just see an
	# extra 'command not found' message which does not hurt anything.
	echo -en "y\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo ""
}

# do_em_e
# $1 = partition number
do_em_e() {
	if [ "$1" == "0" ] ; then
		echo "Erasing 0 (User Partition Area on eMMC)"
	elif [ "$1" == "1" ] ; then
		echo "Erasing 1 (Boot Partition 1 on eMMC)"
	elif [ "$1" == "2" ] ; then
		echo "Erasing 2 (Boot Partition 2 on eMMC)"
	else
		echo "Invalid partition number '$1'"
		return 1
	fi
	echo "Sending EM_E command..."
	echo -en "EM_E\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "$1\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo ""
}

# do_em_w
# $1 = string
# $2 = partition number
# $3 = eMMC block address to write to
# $4 = RAM address to download to
# $5 = filename
do_em_w() {
	# Flash writer just looks for CR. It ignores LF characters.
	echo "Writting $1 ($5)"
	echo "Sending EM_W command..."
	echo -en "EM_W\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "$2\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "$3\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "$4\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo "Sending file..."
	#cat $5 > $SERIAL_DEVICE_INTERFACE
	stat -L --printf="%s bytes\n" $5
	dd if=$5 of=$SERIAL_DEVICE_INTERFACE bs=1k status=progress
	sleep $CMD_DELAY
	echo ""
}

# do_em_wb
# $1 = string
# $2 = partition number
# $3 = eMMC block address to write to
# $4 = filename
do_em_wb() {
	# Flash writer just looks for CR. It ignores LF characters.
	echo "Writting $1 ($4)"
	echo "Sending EM_WB command..."
	echo -en "EM_WB\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "$2\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "$3\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY

	# get the file size of our binary
	SIZE_DEC=$(stat -L --printf="%s" $4)
	SIZE_HEX=$(printf '%X' $SIZE_DEC)
	echo -en "$SIZE_HEX\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY

	echo "Sending file..."
	#cat $4 > $SERIAL_DEVICE_INTERFACE
	stat -L --printf="%s bytes\n" $4
	dd if=$4 of=$SERIAL_DEVICE_INTERFACE bs=1k status=progress
	sleep $CMD_DELAY
	echo ""
}

# do_spi_write
# $1 = string
# $2 = RAM address to download to
# $3 = SPI address to write to
# $4 = filename
do_spi_write() {

	# Send a CR (\r) just to make sure there are not extra characters left over from the last transfer
	#echo -en "\r" > $SERIAL_DEVICE_INTERFACE

	# Check if file is SREC or bin
	FILENAME=$(basename $4)
	FILENAME_EXT=`echo ${FILENAME: -5}`
	if [ "$FILENAME_EXT" == ".srec" ] ; then
		# S-Record Write
		do_xls2 "$1" $2 $3 $4
	else
		# Binary Write (RAM address not needed)
		do_xls3 "$1" $3 $4
	fi
}

# do_emmc_write
# $1 = string
# $2 = partition number
# $3 = eMMC starting block to write
# $4 = RAM address to download to
# $5 = filename
do_emmc_write() {
	# Send a CR (\r) just to make sure there are not extra characters left over from the last transfer
	#echo -en "\r" > $SERIAL_DEVICE_INTERFACE

	# Check if file is SREC or bin
	FILENAME=$(basename $5)
	FILENAME_EXT=`echo ${FILENAME: -5}`
	if [ "$FILENAME_EXT" == ".srec" ] ; then
		# S-Record Write
		do_em_w "$1" $2 $3 $4 $5
	else
		# Binary Write
		do_em_wb "$1" $2 $3 $5
	fi
}

print_usage() {
	echo "Usage: [config file] [operation]" \
	"config file"
	echo "config file         # If no file specified, config.ini is assumed"
	echo "$0 fw               # Downloads the flash writer program after RESET (must be run first)"
	echo ""
	echo "$0 x0               # erases User Partition Area on eMMC"
	echo "$0 x1               # erases Boot Partition 1 on eMMC"
	echo "$0 x2               # erases Boot Partition 2 on eMMC"
	echo "$0 sa0              # programs SA0 (Boot Parameters)"
	echo "$0 bl2              # programs BL2 (Trusted Boot Firmware)"
	echo "$0 sa6              # programs SA6 (Cert Header)"
	echo "$0 bl31             # programs BL31 (EL3 Runtime Software)"
	echo "$0 fip              # programs FIP (Firmware Image Package)"
	echo "$0 uboot            # programs u-boot (BL33, Non-trusted Firmware)"
	echo "$0 atf              # programs sa0+bl2+sa6+bl31 or bl2+fip all at once"
	echo "$0 all              # programs sa0+bl2+sa6+bl31+uboot or bl2+fip all at once"
	echo ""
	echo "$0 emmc_config      # Configure an eMMC for booting (only needed once)"
	echo ""
	echo "$0 sw               # Show the switch settings for Renesas boards (in case you forgot)"
	echo ""
	echo "$0 h                # Show this help menu"
	echo ""
	echo "   Note: You can also pass a filename on the command line."
	echo "         Example: $ $0 bl2"
}

#################################################################
# Script Start OPP
#################################################################

# If the first argument is a filename, assume it is the config file.
if [ -e "$1" ] ; then
  # Read in our settings
  source $1
  CONFIG_FILE=$1

  # The 2nd argument is the command
  CMD=$2
else
  # The 1st argument is the command
  CMD=$1

  # If BOARD is not already set, assume config.ini as default
  if [ "$BOARD" == "" ] && [ -e "config.ini" ] ; then
    source config.ini
    CONFIG_FILE=config.ini
  else
    if [ "$FW_GUI_MODE" != "2" ] ; then
      echo "ERROR: Default file \"config.ini\" does not exit."
      echo "       Please make a copy the example_config.ini file"
      echo "         $ cp  example_config.ini  config.ini"
      echo ""
      echo "       or pass a config filename on the command line as the first argument"
      echo "         $ cp  my_config.ini help"
      echo "       "
      echo "       Please see Readme.md."
    fi
  fi
fi

# Usage is displayed when no arguments on command line
if [ "$CMD" == "h" ] ; then
	print_usage
	exit
fi

if [ "$BOARD" == "" ] ; then
  echo "ERROR: Board not selected in config.ini"
  echo "Please edit config.ini in a text editor before continuing"
  exit
fi


# Set BOARD_NAME and SW_SETTINGS
switch_settings

# Set Flash and RAM addresses
set_flash_address

# 0 = SPI Flash
# 1 = eMMC
if [ "$FLASH" == "" ] ; then
	echo "ERROR: FLASH not selected in config.ini"
	echo "Please edit config.ini in a text editor before continuing"
	exit
fi

# Set default tty interface if not set
if [ "$SERIAL_DEVICE_INTERFACE" == "" ] ; then
	SERIAL_DEVICE_INTERFACE=/dev/ttyUSB0
	#SERIAL_DEVICE_INTERFACE=/dev/ttyACM0
fi

# Turn off some conversions that disrupt sending binary files over tty connections.
# These are already the defaults for /dev/ttyUSB0, so this requirement is really only for
# when using /dev/ttyACM0
stty -icrnl -onlcr -isig -icanon -echoe -opost -F $SERIAL_DEVICE_INTERFACE

# Change the inter-command delay times based on the interface and flash type
if [ "${SERIAL_DEVICE_INTERFACE:8:3}" == "ACM" ] ; then
  # USB is so fast, almost no delay is needed.
  CMD_DELAY="0.2"
elif [ "$FLASH" == "1" ] ; then
  # eMMC commands over SPI flash seem to need more time because more
  # text is output for each entry
  CMD_DELAY="1"
else
  # Programming SPI Flash over SCIF seems to only need a short delay
  CMD_DELAY="0.5"

  if [ "$LONGER_CMD_DELAY" == "1" ] ; then
    CMD_DELAY="1.5"
  fi
fi

# Print current selected board
if [ "$FLASH" == "0" ] ; then
	FLASH_TEXT="SPI Flash"	# 0 = SPI Flash
else
	FLASH_TEXT="eMMC Flash"	# 1 = eMMC
fi

echo "----------------------------------------------------"
echo "   Board: $BOARD_NAME"
echo "  Target: $FLASH_TEXT"
if [ "$CONFIG_FILE" != "" ] ; then
echo "  Config: $CONFIG_FILE"
fi
echo "----------------------------------------------------"

if [ "$CMD" == "fw" ] ; then

	if [ "$FLASHWRITER" == "" ] && [ "$2" != "" ] ; then
		FLASHWRITER=$2
	fi

	if [ "$FW_GUI_MODE" != "2" ] ; then
		echo "-----------------------------------------------------------------"
		echo " Make sure the board is configured for \"SCIF Download mode"\"
		echo " Power on the board and press the RESET button."
		echo " Then, press ENTER on the keyboard to continue."
		echo "-----------------------------------------------------------------"
		read dummy
	fi

	# Check if already running at 115200
	stty -F $SERIAL_DEVICE_INTERFACE | grep -q 115200
	if [ "$?" != "0" ] ; then
		stty -F $SERIAL_DEVICE_INTERFACE 115200
		sleep 0.5
	fi

	echo "Sending Flash Writter Binary ($FLASHWRITER)"
	stat -L --printf="%s bytes\n" $FLASHWRITER
	#cat $FLASHWRITER > $SERIAL_DEVICE_INTERFACE
	dd if=$FLASHWRITER of=$SERIAL_DEVICE_INTERFACE bs=1k status=progress
	sleep 0.5
	# Clear out the extra left over characters
	echo -en "\r" > $SERIAL_DEVICE_INTERFACE
	echo "Complete"
	exit
fi

if [ "$CMD" == "sw" ] ; then
	switch_settings
	printf '%s\n' "$SW_SETTINGS"
	exit
fi

############################################
echo "SERIAL_DEVICE_SPEED = $SERIAL_DEVICE_SPEED"
# Change to faster baud rate if needed
if [ "$SERIAL_DEVICE_SPEED" == "921600" ] ; then
	# Check if already running fast
	stty -F $SERIAL_DEVICE_INTERFACE | grep -q 921600
	if [ "$?" != "0" ] ; then
		# send SUP command
		echo -en "SUP\r" > $SERIAL_DEVICE_INTERFACE
		sleep 1
			# Switch to high speed
		stty -F $SERIAL_DEVICE_INTERFACE 921600
		sleep 0.5
	fi
fi

if [ "$CMD" == "emmc_config" ] ; then

	# Set the EXT_CSD register 177 (0xB1) BOOT_BUS_CONDITIONS:
	# RZ/G2E, RZ/G2N, RZ/G2M, RZ/G2H
	#  * BOOT_MODE bit[4:3] = 0x1 (Use single data rate + High Speed timings in boot operation mode)(50MHz SDR)
	#  * BOOT_BUS_WIDTH bit[1:0] = 0x2 (x8 bus width in boot operation mode)
	# RZ/G2L, RZ/V2L
	#  * BOOT_MODE bit[4:3] = 0x0 (Use single data rate + backward compatible timings in boot operation (50MHz SDR) (default)
	#  * BOOT_BUS_WIDTH bit[1:0] = 0x1 (x4 bus width in boot operation mode)
	echo "Setting EXT_CSD regiser 177..."
	echo -en "EM_SECSD\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "b1\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	if [ "$EMMC_4BIT" == "1" ] ; then
		echo -en "02\r" > $SERIAL_DEVICE_INTERFACE
	else
		echo -en "0a\r" > $SERIAL_DEVICE_INTERFACE
	fi
	sleep $CMD_DELAY

	# Set the EXT_CSD register 179 (0xB3) PARTITION_CONFIG:
	#   * BOOT_ACK bit[6] = 0x0 (No boot acknowledge sent)
	#   * BOOT_PARTITION_ENABLE bit[5:3] = 0x1 (Boot partition 1 enabled for boot)
	echo "Setting EXT_CSD regiser 179..."
	echo -en "EM_SECSD\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "b3\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
	echo -en "08\r" > $SERIAL_DEVICE_INTERFACE
	sleep $CMD_DELAY
fi


if [ "$CMD" == "x0" ] || [ "$CMD" == "x1" ] || [ "$CMD" == "x2" ] ; then
	if [ "$CMD" == "x0" ] ; then
		do_em_e 0
	fi
	if [ "$CMD" == "x1" ] ; then
		do_em_e 1
	fi
	if [ "$CMD" == "x2" ] ; then
		do_em_e 2
	fi
fi

if [ "$CMD" == "sa0" ] || [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] && [ "$FIP" == "0" ] ; then
	if [ "$SA0_FILE" == "" ] && [ "$2" != "" ] ; then
		SA0_FILE=$2
	fi

	if [ "$FLASH" == "0" ] ; then
		do_spi_write "bootparam SA0" $SPI_SA0_RAM $SPI_SA0_FLASH $SA0_FILE
	else
		do_emmc_write "bootparam SA0" $EMMC_SA0_PART $EMMC_SA0_SECTOR $EMMC_SA0_RAM $SA0_FILE
	fi

	if [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] ; then
		# We need extra time before starting the next operation
		sleep 1
	fi
fi

if [ "$CMD" == "bl2" ] || [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] ; then
	if [ "$BL2_FILE" == "" ] && [ "$2" != "" ] ; then
		BL2_FILE=$2
	fi
	if [ "$FLASH" == "0" ] ; then
		do_spi_write "BL2" $SPI_BL2_RAM $SPI_BL2_FLASH $BL2_FILE
	else
		do_emmc_write "BL2" $EMMC_BL2_PART $EMMC_BL2_SECTOR $EMMC_BL2_RAM $BL2_FILE
	fi

	if [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] ; then
		# We need extra time before starting the next operation
		sleep 3
	fi
fi

if [ "$CMD" == "sa6" ] || [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] && [ "$FIP" == "0" ] ; then
	if [ "$SA6_FILE" == "" ] && [ "$2" != "" ] ; then
		SA6_FILE=$2
	fi
	if [ "$FLASH" == "0" ] ; then
		do_spi_write "Cert Header SA6" $SPI_SA6_RAM $SPI_SA6_FLASH $SA6_FILE
	else
		do_emmc_write "Cert Header SA6" $EMMC_SA6_PART $EMMC_SA6_SECTOR $EMMC_SA6_RAM $SA6_FILE
	fi

	if [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] ; then
		# We need extra time before starting the next operation
		sleep 1
	fi
fi

if [ "$CMD" == "bl31" ] || [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] && [ "$FIP" == "0" ] ; then
	if [ "$BL31_FILE" == "" ] && [ "$2" != "" ] ; then
		BL31_FILE=$2
	fi
	if [ "$FLASH" == "0" ] ; then
		do_spi_write "BL31" $SPI_BL31_RAM $SPI_BL31_FLASH $BL31_FILE
	else
		do_emmc_write "BL31" $EMMC_BL31_PART $EMMC_BL31_SECTOR $EMMC_BL31_RAM $BL31_FILE
	fi

	if [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] ; then
		# We need extra time before starting the next operation
		sleep 3
	fi
fi

if [ "$CMD" == "uboot" ] || [ "$CMD" == "all" ] && [ "$FIP" == "0" ] ; then
	if [ "$UBOOT_FILE" == "" ] && [ "$2" != "" ] ; then
		UBOOT_FILE=$2
	fi
	if [ "$FLASH" == "0" ] ; then
		do_spi_write "u-boot" $SPI_UBOOT_RAM $SPI_UBOOT_FLASH $UBOOT_FILE
	else
		do_emmc_write "u-boot" $EMMC_UBOOT_PART $EMMC_UBOOT_SECTOR $EMMC_UBOOT_RAM $UBOOT_FILE
	fi

	if [ "$CMD" == "all" ] ; then
		# We need extra time before starting the next operation
		sleep 3
	fi
fi

if [ "$CMD" == "fip" ] || [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] && [ "$FIP" == "1" ] ; then
	if [ "$FIP_FILE" == "" ] && [ "$2" != "" ] ; then
		FIP_FILE=$2
	fi
	if [ "$FLASH" == "0" ] ; then
		do_spi_write "FIP" $SPI_FIP_RAM $SPI_FIP_FLASH $FIP_FILE
	else
		do_emmc_write "FIP" $EMMC_FIP_PART $EMMC_FIP_SECTOR $EMMC_FIP_RAM $FIP_FILE
	fi

	if [ "$CMD" == "atf" ] || [ "$CMD" == "all" ] ; then
		# We need extra time before starting the next operation
		sleep 3
	fi
fi
