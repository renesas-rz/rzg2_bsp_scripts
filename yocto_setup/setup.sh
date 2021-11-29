#!/bin/bash

# Setup and Configuration GUI for Renesas RZ/G2 BSP

# Set environment variable "ADVANCED=1" to get full menu.
# For example:   $ ADVANCED=1 ./config.sh
if [ "$ADVANCED" == "1" ] ; then
  echo "Advanced menu"
fi

# Start in base directory of BSP
if [ ! -e "meta-rzg2" ] ; then cd .. ; fi
if [ ! -e "meta-rzg2" ] ; then cd .. ; fi
if [ ! -e "meta-rzg2" ] ; then
  echo -e "\nError: Please run this script from the base of the BSP directory\n"
  exit
fi

# Settings
LOCAL_CONF=build/conf/local.conf

# Text strings
FLASH_TEXT=("SPI Flash" "eMMC Flash")
GPLV3_TEXT=("Block all GPLv3 Packages" "Allow GLPv3 Packages")
DOCKER_TEXT=("disable" "enable")
APP_FRAMEWORK_TEXT=("None" "Qt" "HTML5")
INTERNET_TEXT=("Not Available (packages must be supplied)" "Available (packages will be downloaded)")
RT_TEXT=("No (Standard kernel)" "Yes (Realtime Linux kernel)")
CIP_MODE_TEXT=("Buster-full" "Buster-limited" "Jessie" "none (Default Yocto Packages)")

# Supported Boards
BOARD_NAME=(\
	"RZ/G2E EK874 by Silicon Linux" \
	"RZ/G2N HiHope by Hoperun Technology" \
	"RZ/G2M HiHope by Hoperun Technology" \
	"RZ/G2H HiHope by Hoperun Technology" \
	)
BOARD_MACHINE=(\
	"ek874" \
	"hihope-rzg2n" \
	"hihope-rzg2m" \
	"hihope-rzg2h" \
	)

##################################
function check_for_file
# Inputs
#   $1 : File to check
# Outputs
#   $MISSING_FILE : 1=file not found  (if file is found, not set)
{
  if [ ! -e $1 ] ; then
    echo "File $1 not found"
    MISSING_FILE=1
  fi
}

##################################
function detect_bsp
# Inputs
#   none
# Outputs
#   $BSP_VERSION
#   $BSP_VERSION_STR
#   $IS_RT
{
  # Detect BSP version based off commit id (first 12 characters) of CIP kernel
  BSP_VERSION=""

  # v1.0.8
  grep -q "0882431bf2fe" meta-rzg2/recipes-kernel/linux/linux-renesas_4.19.bb
  if [ "$?" == "0" ] ; then
    BSP_VERSION=108
    BSP_VERSION_STR="VLP64 v1.0.8"
    IS_RT_RELEASE=0
    IS_RT=0
  fi

  # v1.0.9-RT
  grep -q "ba8ac89871d7" meta-rzg2/recipes-kernel/linux/linux-renesas_4.19.bb
  if [ "$?" == "0" ] ; then
    BSP_VERSION=109
    BSP_VERSION_STR="VLP64 v1.0.9-RT"
    IS_RT_RELEASE=1
    IS_RT=1
  fi

  # v1.0.10
  grep -q "54f39790f577" meta-rzg2/recipes-kernel/linux/linux-renesas_4.19.bb
  if [ "$?" == "0" ] ; then
    BSP_VERSION=1010
    BSP_VERSION_STR="VLP64 v1.0.10"
    IS_RT_RELEASE=0
    IS_RT=0
  fi

  if [ "$BSP_VERSION" == "" ] ; then
    whiptail --msgbox "ERROR: BSP version not supported." 0 0
    exit
  fi

}

##################################
function check_host_os
# Inputs
#   none
# Outputs
#   Exit if a package not found
{
  grep "Ubuntu 16.04" /etc/issue > /dev/null 2>&1
  ubuntu_1604_check="$?"
  grep "Ubuntu 18.04" /etc/issue > /dev/null 2>&1
  ubuntu_1804_check="$?"
  if [ "$ubuntu_1804_check" != "0" ] && [ "$ubuntu_1604_check" != "0" ] ; then

    echo -en "\n"\
	"WARNING: You must use Ubuntu 18.04 or Ubuntu 16.04 as your host OS (or container) to build this Yocto BSP.\n"\
	"         You may configure your BSP now, but please switch to a Ubuntu 18.04 or 16.04 container before\n"\
	"         attempting to build.\n\n"\
	"Press Enter to continue..."
    read dummy

    BAD_OS=1
  fi
}

##################################
function check_host_packages
# Inputs
#   none
# Outputs
#   Exit if a package not found
{
  #Check for required host packages
  check_for_file /usr/bin/gawk
  check_for_file /usr/bin/wget
  check_for_file /usr/bin/git
  check_for_file /usr/bin/diffstat
  check_for_file /usr/bin/unzip
  #texinfo
  #gcc-multilib
  check_for_file /usr/bin/make ] #build-essential
  check_for_file /usr/bin/chrpath
  check_for_file /usr/bin/socat
  check_for_file /bin/cpio
  check_for_file /usr/bin/python
  check_for_file /usr/bin/python3
  #python3-pip
  #python3-pexpect
  check_for_file /usr/bin/xz
  #debianutils
  #iputils-ping
  #libsdl1.2-dev
  check_for_file /usr/bin/xterm
  check_for_file /usr/bin/7z

  if [ "$MISSING_FILE" == "1" ] ; then
    echo ""
    echo "You are missing one or more packages. Please run this command to make sure they are all installed"
    echo ""
    echo "sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib \\"
    echo " build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \\"
    echo " xz-utils debianutils iputils-ping libsdl1.2-dev xterm p7zip-full"
    exit
  fi

  # Check git is set up
  git config --list | grep user > /dev/null 2>&1
  if [ "$?" != "0" ] ; then
    echo "Git is not configure yet."
    echo "Please configure your git settings as shown below:"
    echo ""
    echo "$ git config --global user.email \"you@example.com\""
    echo "$ git config --global user.name \"Your Name\""
    exit
  fi
}

##################################
function get_current_value
# Inputs
#   $1 = Yocto variable to check
# Outputs
#   $VALUE = The value that was read from local.conf
{
	VALUE=""

	if [ ! -e "$LOCAL_CONF" ] ; then
		return
	fi

	# Read local.conf and skip any line that start with  #
	str_len=${#1}
	#echo "Searching for $1..."
	while IFS="" read -r line || [ -n "$line" ]
	do
		## trim leading white spaces
		#line_trimmed=$(echo "$line" | xargs)

		# Remove all spaces
		line_compact=${line// /}

		# skip blank lines
		if [ "$line_compact" == "" ] ; then continue;fi

		# skip commented lines
		if [ "${line_compact:0:1}" == "#" ] ; then continue; fi

		# Check if it is what we are looking for.
		# we nee to check "=" and "??="
		str_len_add_1=$((str_len+1))
		str_len_add_2=$((str_len+2))
		str_len_add_3=$((str_len+3))
		str_len_add_4=$((str_len+4))
		if [ "${line_compact:0:$str_len_add_1}" == "${1}=" ] ; then
			#printf '%s\n' "$line"
			#printf '%s\n' "$line_compact"

			#VALUE="${line_compact:$str_len_add_1}"

			# Remove quotes when returning
			VALUE=$(echo ${line_compact:$str_len_add_1} | tr -d '"')
		fi
		if [ "${line_compact:0:$str_len_add_3}" == "${1}??=" ] ; then
			#printf '%s\n' "$line"
			#printf '%s\n' "$line_compact"
			#VALUE="${line_compact:$str_len_add_3}"

			# Remove quotes when returning
			VALUE=$(echo ${line_compact:$str_len_add_3} | tr -d '"')
		fi

	done < $LOCAL_CONF
}

##################################
function do_menu_board()
{
  SELECT=$(whiptail --title "Board Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1.   ${BOARD_NAME[0]}" "" \
	"2.   ${BOARD_NAME[1]}" "" \
	"3.   ${BOARD_NAME[2]}" "" \
	"4.   ${BOARD_NAME[3]}" "" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) BOARD=0 ;;
      2.\ *) BOARD=1 ;;
      3.\ *) BOARD=2 ;;
      4.\ *) BOARD=3 ;;
      *) whiptail --msgbox "Unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##################################
function do_menu_rt()
{
  if [ "$IS_RT_RELEASE" == "1" ] ; then
    STTXT="(NOT fully tested)"
    RTTXT="(fully tested)"
  else
    STTXT="(fully tested)"
    RTTXT="(NOT fully tested)"
  fi

  SELECT=$(whiptail --title "Kernel selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1.   Standard Kernel" "$STTXT" \
	"2.   Realtime Kernel" "$RTTXT" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) IS_RT=0 ;;
      2.\ *) IS_RT=1 ;;
      *) whiptail --msgbox "Unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi

  if [ "$IS_RT_RELEASE" != "$IS_RT" ] ; then
    whiptail --msgbox "Please note that this version in this release was not fully tested." 0 0 0
  fi

}

##################################
function do_menu_ecc
{
  ECC_TEXT="
Configuration for ECC
Adds ecc to MACHINE_FEATURES to configure DRAM for ECC usage.
ECC_MODE Options: Full, Full Dual, Full Single, Partial
 - Full : DRAM is configured for FULL ECC support, half of memory is reduced for storing ECC code
          Default is Full Single for RZ/G2E, RZ/G2N, Full Dual for RZ/G2M(v1.3 & v3.0), RZ/G2H
 - Full Dual : DRAM is configured for FULL ECC Dual channel support, half of memory is reduced for storing ECC code
               Use only for RZ/G2M(v1.3 & v3.0) and RZ/G2H
 - Full Single: DRAM is configured for FULL ECC Single channel support, half of memory is reduced for storing ECC code
                Use only for RZ/G2E, RZ/G2N, RZ/G2M(v3.0) and RZ/G2H
 - Partial: Manual add/remove ECC area by u-boot command (Default mode)"

  SELECT=$(whiptail --title "ECC Selection" --menu "$ECC_TEXT You may use ESC+ESC to cancel." 0 0 0 \
	"1 None" "  (not set)" \
	"2 Full" "  " \
	"3 Full Dual" "  " \
	"4 Full Single" "  " \
	"5 Partial" "  " \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1\ *) ECC_MODE="None" ;;
      2\ *) ECC_MODE="Full" ;;
      3\ *) ECC_MODE="Full Dual" ;;
      4\ *) ECC_MODE="Full Single" ;;
      5\ *) ECC_MODE="Partial" ;;
      *) whiptail --msgbox "Unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##################################
function do_menu_docker()
{
  SELECT=$(whiptail --title "Docker Selection" --menu "Select if you want to include docker in the build.\n\nYou may use ESC+ESC to cancel." 0 0 0 \
	"1.   ${DOCKER_TEXT[0]}" "" \
	"2.   ${DOCKER_TEXT[1]}" "" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) DOCKER=0 ;;
      2.\ *) DOCKER=1 ;;
      *) whiptail --msgbox "Unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##################################
function do_menu_cip_mode()
{
  TEXT="
Switch among build setting Buster-full, Buster-limited and Jessie
 - Buster-full (default)            : build all supported Debian 10 Buster recipes
 - Buster-limited                   : build Debian 10 Buster, but only limited pakages similar to Jessie (4 main recipes)
 - Jessie                           : build Debian 8 Jessie packages (only 4 main recipes)
 - Not set (or different with above): not use CIP Core, use default packages version in Yocto
"

  SELECT=$(whiptail --title "CIP Mode Selection" --menu "$TEXT\n\nYou may use ESC+ESC to cancel." 0 0 0 \
	"1.   ${CIP_MODE_TEXT[0]}" "" \
	"2.   ${CIP_MODE_TEXT[1]}" "" \
	"3.   ${CIP_MODE_TEXT[2]}" "" \
	"4.   ${CIP_MODE_TEXT[3]}" "" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) CIP_MODE=0 ;;
      2.\ *) CIP_MODE=1 ;;
      3.\ *) CIP_MODE=2 ;;
      4.\ *) CIP_MODE=3 ;;
      *) whiptail --msgbox "Unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##################################
function do_menu_gplv3()
{
  TEXT="
Enable or disable GPLv3 and GPLv3+ Software.
This option should be used with meta-gplv2 which can help Yocto to search for old
versions which support GPLv2.

When GPLv3 packages are blocked, this will be added to your local.conf
INCOMPATIBLE_LICENSE = \"GPLv3 GPLv3+\"
"
  SELECT=$(whiptail --title "GPLv3 Selection" --menu "$TEXT\n\nYou may use ESC+ESC to cancel." 0 0 0 \
	"1.   ${GPLV3_TEXT[0]}" "" \
	"2.   ${GPLV3_TEXT[1]}" "" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) GPLV3=0 ;;
      2.\ *) GPLV3=1 ;;
      *) whiptail --msgbox "Unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}

##################################
function do_menu_internet()
{
  TEXT="
Select if Package can be downloaded from the Internet or an offline build is required.
"
  SELECT=$(whiptail --title "Internet Selection" --menu "$TEXT\n\nYou may use ESC+ESC to cancel." 0 0 0 \
	"1.   ${INTERNET_TEXT[0]}" "" \
	"2.   ${INTERNET_TEXT[1]}" "" \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) INTERNET=0 ;;
      2.\ *) INTERNET=1 ;;
      *) whiptail --msgbox "Unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}


##################################
function do_menu_target_flash
{
  SELECT=$(whiptail --title "Boot Flash Selection" --menu "You may use ESC+ESC to cancel." 0 0 0 \
	"1. ${FLASH_TEXT[0]}"  " " \
	"2. ${FLASH_TEXT[1]}"  " " \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 0 ] ; then
    case "$SELECT" in
      1.\ *) FLASH=0
        ;;
      2.\ *) FLASH=1
        ;;
      *) whiptail --msgbox "Unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  fi
}


##################################
function show_advanced_msg
{
  whiptail --msgbox "This option is only available in advanced mode." 0 0 0
}

##################################
function do_main_menu
{
export NEWT_COLORS='
root=,blue
'

  SELECT=$(whiptail --title "RZ/G2 BSP Configuration" --menu \
	"Version Detected: $BSP_VERSION_STR\n\nSelect your build options below. The Yocto environment will be set up and local.conf file changed.\nYou may use [ESC]+[ESC] to Cancel/Exit (no save). Use [Tab] key to select buttons.\n\nUse the <Change_Item> button (or enter) to make changes.\n\nUse the <Save> button to start the configuration process." \
	0 0 0 --cancel-button Save --ok-button Change_Item \
	--default-item "$LAST_SELECT" \
	"1.                       Board:" "  ${BOARD_NAME[$BOARD]}"  \
	"2.             Realtime kernel:" "  ${RT_TEXT[$IS_RT]}"  \
	"3.                  Boot Flash:" "  ${FLASH_TEXT[$FLASH]}" \
	"4.                    ECC Mode:" "  $ECC_MODE"  \
	"5.                    CIP Mode:" "  ${CIP_MODE_TEXT[$CIP_MODE]}"  \
	"6.                      Docker:" "  ${DOCKER_TEXT[$DOCKER]}"  \
	"7.       Application Framework:" "  ${APP_FRAMEWORK_TEXT[$APP_FRAMEWORK]}"  \
	"8.         Internet Connection:" "  ${INTERNET_TEXT[$INTERNET]}"  \
	"9.                GPLv3 GPLv3+:" "  ${GPLV3_TEXT[$GPLV3]}"  \
	"10.                       Save:" "  Configure the BSP and Exit"  \
	3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ] ; then
    # We used the 'cancel' button as Exit/Save button.
    echo "Preparing to configure..."
    SAVE_PRESSED="1"
  elif [ $RET -eq 0 ] ; then
    LAST_SELECT="$SELECT"
    case "$SELECT" in
      1.\ *) do_menu_board ;;
      2.\ *) do_menu_rt ;;
      3.\ *) if [ "$ADVANCED" == "1" ] ; then do_menu_target_flash ; else show_advanced_msg ; fi ;;
      4.\ *) do_menu_ecc ;;
      5.\ *) do_menu_cip_mode ;;
      6.\ *) do_menu_docker ;;
      7.\ *) whiptail --msgbox "Only Qt can be built using this setup.\nIf you want to build the BSP for HTML5, please refer to\nthe document \"Release Note for HTML5\" for the detailed instructions." 0 0 0 ;;
      8.\ *) do_menu_internet ;;
      9.\ *) do_menu_gplv3 ;;
      10.\ *) SAVE_PRESSED="1" ;;
      *) whiptail --msgbox "Unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
  else
    exit 1
  fi

}

##################################
# Start of script
##################################

# Check for correct version of Ubuntu
check_host_os

# Check Host machine for minimum packages and that git is set up
# Skip if not running the correct Ubuntu version
if [ "$BAD_OS" != "1" ] ; then
  check_host_packages
fi

# Defaults
BOARD=0
FLASH=0 # SPI Flash
CIP_MODE=0
DOCKER=0 # Not included
GLPV3=0 # No GPLv3 packages
APP_FRAMEWORK=1 # Qt
INTERNET=1 # Download packages from Internet
ECC_MODE="None" # No ECC
IS_RT=0

# Determine what BSP we are using
detect_bsp

# Warn if local.conf file already exists
if [ -e "$LOCAL_CONF" ] ; then
  whiptail --title "Existing local.conf detected" --defaultno --yesno "An existing $LOCAL_CONF file has been detected.\nIf you continue, it will be overwritten when you \"Save\" in the next screen.\n\nContinue?" 0 0
  if [ "$?" != "0" ] ; then
    exit
  fi
  # pre-select the current board
  get_current_value "MACHINE"
  case "$VALUE" in
    ("${BOARD_MACHINE[0]}") BOARD=0 ;;
    ("${BOARD_MACHINE[1]}") BOARD=1 ;;
    ("${BOARD_MACHINE[2]}") BOARD=2 ;;
    ("${BOARD_MACHINE[3]}") BOARD=3 ;;
    ("${BOARD_MACHINE[4]}") BOARD=4 ;;
    ("${BOARD_MACHINE[5]}") BOARD=5 ;;
  esac
fi

# Main loop
SAVE_PRESSED="0"
while [ "$SAVE_PRESSED" == "0" ] ; do
  do_main_menu
done

# If we are this far, then the user pressed "Save"

# Warn if local.conf file already exists
if [ -e "$LOCAL_CONF" ] ; then
  whiptail --title "Existing local.conf detected" --yesno "Your current local.conf will be overwritten\n\nContinue?" 8 78
  if [ "$?" != "0" ] ; then
    exit
  fi
fi

# First build?
if [ ! -e "$LOCAL_CONF" ] ; then
  echo "[Setting up build environment]"
  source poky/oe-init-build-env
  # This command will leave you in the 'build' directory
  cd ..

  echo "[Copying the default configuration files for the target board]"
  cp -v meta-rzg2/docs/sample/conf/${BOARD_MACHINE[$BOARD]}/linaro-gcc/*.conf build/conf/

  # Apply HDMI patches if exits
  ls extra/*HDMI*.patch > /dev/null 2>&1
  if [ "$?" == "0" ] ; then
    echo "[Applying HDMI patches]"
    cd meta-rzg2
    patch -p1 -i ../extra/*HDMI*.patch
    cd ..
  fi
else
  # Overwrite the existing local.conf
  echo "[Copying the default configuration files for the target board]"
  cp -v meta-rzg2/docs/sample/conf/${BOARD_MACHINE[$BOARD]}/linaro-gcc/*.conf build/conf/
fi

# Executing the copy script for proprietary software if not already done
if [ -e  proprietary/RCE3G001L4101ZDO_2_0_9.zip ] &&
   [ ! -e meta-rzg2/recipes-multimedia/omx-module/omx-user-module/RTM0AC0000XV264D30SL41C.tar.bz2 ] ; then
  echo "[Executing the copy script for proprietary software]"
  cd meta-rzg2
  sh docs/sample/copyscript/copy_proprietary_softwares.sh ../proprietary
  cd ..
fi

# Modify the local.conf file
echo "[Modifying the local.conf file]"


# Realtime kernel
if [ "$IS_RT" == "1" ] && [ "$IS_RT_RELEASE" == "0" ] ; then
  # Add value at the end
  echo -e "\n\n# Enable Realtime Linux Kerenl build" >> $LOCAL_CONF
  echo "IS_RT_BSP = \"1\"" >> $LOCAL_CONF
fi
if [ "$IS_RT" == "0" ] && [ "$IS_RT_RELEASE" == "1" ] ; then
  # Replace IS_RT_BSP = "1" with  IS_RT_BSP = "0"
  sed -i "s/IS_RT_BSP = \"1\"/IS_RT_BSP = \"0\"/g" $LOCAL_CONF
fi

# Boot Flash
if [ "$FLASH" == "1" ] ; then
  # eMMC boot
  echo -e "\n\n# Enable eMMC boot" >> $LOCAL_CONF
  echo "ATFW_OPT_append += \" RZG_SA6_TYPE=1 \"" >> $LOCAL_CONF
fi

# ECC Mode : $ECC_MODE
if [ "$ECC_MODE" != "None" ] ; then

  # MACHINE_FEATURES_append = " ecc"
  # ECC_MODE = "Partial"
  match="ECC_MODE = \"Partial\""
  insert="MACHINE_FEATURES_append = \" ecc\"\nECC_MODE = \"$ECC_MODE\""
  sed -i "s/$match/$match\n$insert/" $LOCAL_CONF
fi

# CIP Mode : $CIP_MODE
if [ "$CIP_MODE" != "0" ] ; then
  if [ "$CIP_MODE" == "3" ] ; then
    sed -i "s/CIP_MODE = \"Buster-full\"/CIP_MODE = \"none\"/g" $LOCAL_CONF
  else
    sed -i "s/CIP_MODE = \"Buster-full\"/CIP_MODE = \"${CIP_MODE_TEXT[$CIP_MODE]}\"/g" $LOCAL_CONF
    #BBMASK_append_cipcore = "|perl_debian"
    sed -i "s/.*|perl_debian.*/#BBMASK_append_cipcore = \"|perl_debian\"/g" $LOCAL_CONF
  fi
fi

# Docker : $DOCKER
if [ "$DOCKER" == "1" ] ; then
  # Configuration for Docker
  #MACHINE_FEATURES_append = " docker"
  sed -i 's/.* docker.*/MACHINE_FEATURES_append = \" docker\"/g' $LOCAL_CONF
fi

# Application Framework : $APP_FRAMEWORK

# Internet Connection : $INTERNET
if [ "$INTERNET" == "0" ] ; then
  get_current_value "BB_NO_NETWORK"
  if [ "$VALUE" != "" ] ; then
    # replace current line
    sed -i "s/.*BB_NO_NETWORK.*/BB_NO_NETWORK = \"1\"/g" $LOCAL_CONF
  else
    echo -e "\n\n# Offline build only" >> $LOCAL_CONF
    echo "BB_NO_NETWORK = \"1\"" >> $LOCAL_CONF
 fi
fi

# GPLv3 GPLv3+ : $GPLV3
if [ "$GPLV3" == "1" ] ; then
  #Comment out this line:  INCOMPATIBLE_LICENSE = "GPLv3 GPLv3+"
  sed -i "s/INCOMPATIBLE_LICENSE/#INCOMPATIBLE_LICENSE/g" $LOCAL_CONF
fi

echo -e "\n[Setup complete]\n"
