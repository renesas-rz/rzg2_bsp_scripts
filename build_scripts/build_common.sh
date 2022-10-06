#!/bin/bash

#########################################################
# This file contains functions common to all the scripts
# Each script sour 'source' this file at the beginning.
#########################################################



# Toolchain Selection GUI
# Since each sub-script will want to ask the user what toolchain to use, we will keep a common interface in this file.
# $1 = env variable to save TOOLCHAIN_SETUP_NAME
# $2 = env variable to save TOOLCHAIN_SETUP
select_toolchain() {

  # Get a list of directories under /opt/arm, /opt/linaro, /opt/poky
  array_arm=( $(find /opt/arm -mindepth 1 -maxdepth 1 -type d))
  array_arm_size=${#array_arm[@]}
  array_linaro=( $(find /opt/linaro -mindepth 1 -maxdepth 1 -type d))
  array_linaro_size=${#array_linaro[@]}
  array_poky=( $(find /opt/poky -mindepth 1 -maxdepth 1 -type d))
  array_poky_size=${#array_poky[@]}

  INDEX=0
  # No Toolchain setup
  tc_array_text+=("(none)")
  tc_array_setup+=("")
  # put menu text at the end....
  #menu_text="$menu_text \"$INDEX (none)\" \"Build script do not set up toolchian (advanced)\""
  INDEX=$((INDEX+1))

  # Poky (SDK) Toolchains
  for i in $(seq $array_poky_size) ; do
    #echo $i ${array_poky[$((i-1))]}
    tc_version=$(basename ${array_poky[$((i-1))]})
    tc_array_text+=("Poky (Yocto SDK) ($tc_version)")
    tc_array_setup+=("source ${array_poky[$((i-1))]}/environment-setup-aarch64-poky-linux")

    menu_text="$menu_text \"$INDEX Poky (Yocto SDK)\" \"${array_poky[$((i-1))]}\""
    INDEX=$((INDEX+1))
  done
  
  # ARM Toolchians
  for i in $(seq $array_arm_size) ; do
    #echo $i ${array_arm[$((i-1))]}

    tc_version=$(echo $(basename ${array_arm[$((i-1))]}) | sed "s/-x86.*//")
    tc_array_text+=("ARM ($tc_version)")
    tc_array_setup+=("PATH=${array_arm[$((i-1))]}/bin:\$PATH ; export CROSS_COMPILE=aarch64-none-elf-")

    menu_text="$menu_text \"$INDEX ARM Toolchain\" \"${array_arm[$((i-1))]}\""
    INDEX=$((INDEX+1))
  done

  # Linaro Toolchians
  for i in $(seq $array_linaro_size) ; do
    #echo $i ${array_linaro[$((i-1))]}
    tc_version=$(echo $(basename ${array_arm[$((i-1))]}) | sed "s/-x86.*//")
    tc_array_text+=("Linaro ($tc_version)")
    tc_array_setup+=("PATH=${array_linaro[$((i-1))]}/bin:\$PATH ; export CROSS_COMPILE=aarch64-linux-gnu-")

    menu_text="$menu_text \"$INDEX Linaro\" \"${array_linaro[$((i-1))]}\""
    INDEX=$((INDEX+1))
  done

  # No Toolchain setup (menu text)
  # Even though this option is 0, let's put it at the end.
  menu_text="$menu_text \"0 (none)\" \"No toolchian setup (advanced users)\""

  # Create our Whiptail command as a script, then execute it using 'eval'
  # Because we are using eval, we have to redirect the stdout to a file in /tmp
  WT_CMD="whiptail --title \"Toolchain Selection\" --menu \"Choose the toolchain you want to use.\nPlease refer to file [Toolchain Installs.txt] for how to install.\nBelow are the current toolchains installed under /opt/poky, /opt/arm, /opt/linaro\n\" 0 0 0 \
	$menu_text "
  eval "$WT_CMD 3>&1 1>&2 2>&3" > /tmp/wt_result.txt
  # Read in our selection. We just want the number at the beginning since it will be our index to our array
  SELECT=$(cat /tmp/wt_result.txt | awk '{ print $1 }')

  x_TOOLCHAIN_SETUP_NAME="${tc_array_text[$SELECT]}"
  x_TOOLCHAIN_SETUP="${tc_array_setup[$SELECT]}"

  DO_SET="export $1=\"$x_TOOLCHAIN_SETUP_NAME\""
  eval "$DO_SET"

  DO_SET="export $2=\"$x_TOOLCHAIN_SETUP\""
  DO_SET=$(echo "$DO_SET" | sed s/\$PATH/\\\\\$PATH/)  # Keep $PATH from being expanded
  eval "$DO_SET"
}


read_setting() {
  if [ -e "$SETTINGS_FILE" ] ; then
    source "$SETTINGS_FILE"
  else
    echo -e "\nERROR: Settings file ($SETTINGS_FILE) not found."
    exit
  fi
}

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

# Check for required Host packages
# If a package is missing, then kill the script (exit)
check_packages() {

  MISSING_A_PACKAGE=0
  PACKAGE_LIST=(git make gcc g++ python3 bison flex)

  for i in ${PACKAGE_LIST[@]} ; do
    CHECK=$(which $i)
    if [ "$CHECK" == "" ] ; then
      echo "ERROR: Missing host package: $i"
      MISSING_A_PACKAGE=1
    fi
  done
  CHECK=$(dpkg -l 'libncurses5-dev' | grep '^ii')
  if [ "$CHECK" == "" ] ; then
    MISSING_A_PACKAGE=1
  fi

  # File /usr/include/openssl/sha.h is required to build Trusted Firmware-A
  CHECK=$(dpkg -l 'libssl-dev' | grep '^ii')
  if [ "$CHECK" == "" ] ; then
    MISSING_A_PACKAGE=1
  fi

  if [ "$MISSING_A_PACKAGE" != "0" ] ; then
    echo "ERROR: Missing mandatory host packages"
    echo "Please make sure the following packages are installed on your machine."
    echo "    ${PACKAGE_LIST[@]} libncurses5-dev libncursesw5-dev libssl-dev"
    echo ""
    echo "The following command line will ensure all packages are installed."
    echo ""
    echo "   sudo apt-get install ${PACKAGE_LIST[@]} libncurses5-dev libncursesw5-dev"
    echo ""
    exit 1
  fi
}
