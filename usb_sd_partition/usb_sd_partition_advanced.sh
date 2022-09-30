#!/bin/bash

# This script will erase and reformat a 'USB Flash drive', a 'USB SD Card reader',
# or a 'SD Card reader' (plugged directly into a laptop) to be used for RZ/G Linux systems.
# You can choose up to 4 partitions.

# This script must run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "This script must be run as root. \nRestarting as root...\n"
   echo -e "sudo $0\n"
   sudo $0
   exit 1
fi

# Check that whiptail is installed
which whiptail > /dev/null
if [ "$?" != "0" ] ; then
  echo "Whiptail not installed"
  exit
fi

FOUND_ONE="NO"

# Look for any Removable drives. By looking in dmesg, we can know if the attached
# device is a Removable Flash drive or a USB HDD because a flash drive will say
# "Attached SCSI removable disk" in dmesg (but a HDD will not).
# We could also have checked if /sys/class/block/sda/removable is '1'
function Find_Drives {
	# Attached USB Drives show as /dev/sd#
	# Laptops have SD card slots that show up as /dev/mmcblk
	TEXT=
	for i in sda sdb sdc sdd mmcblk0
	do
	if [ -e /dev/${i} ] ; then

		if [ "${i:0:1}" == "s" ] ; then
			dmesg | grep "${i}] Attached SCSI removable disk" > /dev/null
			if [ "$?" != "0" ] ; then
				continue
			fi
		fi
		if [ "${i:0:1}" == "m" ] ; then
			dmesg | grep "mmc0" | grep "card" > /dev/null
			if [ "$?" != "0" ] ; then
				continue
			fi
		fi

		ITEM="/dev/${i}"
		DESC=`sudo fdisk -l /dev/${i} | grep -m1 ${i} | sed "s:Disk /dev/${i}::"`

		# add to end of array
		TEXT=("${TEXT[@]}" "$ITEM" "$DESC")
		FOUND_ONE="YES"
		fi
	done
}

# Discover our drives
Find_Drives

# Add exit at the end of the array
if [ $FOUND_ONE == "YES" ] ; then
	TEXT=("${TEXT[@]}" "EXIT" "Cancel and exit the script")
else
	TEXT=("${TEXT[@]}" "EXIT" "No drives found! Cancel and exit the script")
fi


if [ "${TEXT[7]}" != "" ] ; then
	DISK=$(
	whiptail --title "Select your Drive" --menu "Below is a list of Removable Media found on your system" 0 0 0 \
		"${TEXT[1]}" "${TEXT[2]}"\
		"${TEXT[3]}" "${TEXT[4]}"\
		"${TEXT[5]}" "${TEXT[6]}"\
		"${TEXT[7]}" "${TEXT[8]}"\
		 3>&2 2>&1 1>&3
	)
elif [ "${TEXT[5]}" != "" ] ; then
	DISK=$(
	whiptail --title "Select your Drive" --menu "Below is a list of Removable Media found on your system" 0 0 0 \
		"${TEXT[1]}" "${TEXT[2]}"\
		"${TEXT[3]}" "${TEXT[4]}"\
		"${TEXT[5]}" "${TEXT[6]}"\
		 3>&2 2>&1 1>&3
	)
elif [ "${TEXT[3]}" != "" ] ; then
	DISK=$(
	whiptail --title "Select your Drive" --menu "Below is a list of Removable Media found on your system" 0 0 0 \
		"${TEXT[1]}" "${TEXT[2]}"\
		"${TEXT[3]}" "${TEXT[4]}"\
		 3>&2 2>&1 1>&3
	)
else
	DISK=$(
	whiptail --title "Select your Drive" --menu "Below is a list of Removable Media found on your system" 0 0 0 \
		"${TEXT[1]}" "${TEXT[2]}"\
		 3>&2 2>&1 1>&3
	)
fi

if [ "$DISK" == "" ] || [ "$DISK" == "EXIT" ] ; then
  echo "script canceled"
  exit
else
  echo DISK=$DISK
fi

PARTIION_FORMAT[0]="FAT16"
PARTIION_SIZE[0]="500M"
PARTIION_FORMAT[1]="ext4"
PARTIION_SIZE[1]="remaining space"
PARTIION_FORMAT[2]="(do not create)"
PARTIION_SIZE[2]=""
PARTIION_FORMAT[3]="(do not create)"
PARTIION_SIZE[3]=""

function select_fs_type {
	FS_TYPE=$(
	whiptail --title "Select Partition filesystem type" --menu "What filesystem would you like this partition to be?\n\
	" 0 0 0 \
		"FAT16" ""\
		"ext2" ""\
		"ext3" ""\
		"ext4" ""\
		"(do not create)" ""\
		"EXIT" "Cancel and exit the script" \
		 3>&2 2>&1 1>&3
	)
	if [ "$FS_TYPE" == "" ] || [ "$FS_TYPE" == "EXIT" ] ; then
	  echo "script canceled"
	  exit
	fi
}

function select_fat_size {
	FAT_SZ=$(
	whiptail --title "Select Size of FAT Partition" --default-item "500M" --menu "What would you like the size of the FAT partition to be?\nThis will hold the kernel and Device Tree" 0 0 0 \
		"250M" ""\
		"500M" "(recomended)"\
		"750M" ""\
		"1G" ""\
		"EXIT" "Cancel and exit the script" \
		 3>&2 2>&1 1>&3
	)
	if [ "$FAT_SZ" == "" ] || [ "$FAT_SZ" == "EXIT" ] ; then
	  echo "script canceled"
	  exit
	fi
}

function select_ext_size {
	EXT_SZ=$(
	whiptail --title "Select Size of EXT Partition" --default-item "max" --menu "What would you like the size of the EXT partition to be?\n\
	This will hold the entire file system.\n\
	You can select only a portion (2GB) of the remaining space in case you would\n\
	like to keep multiple images on this disk.\n\
	FYI: The larger the partition size, the longer it takes to format." 0 0 0 \
		"1G" ""\
		"2G" ""\
		"3G" ""\
		"4G" ""\
		"5G" ""\
		"6G" ""\
	    "remaining space" " (Use whatever space is left for this partition)"\
		"EXIT" "Cancel and exit the script" \
		 3>&2 2>&1 1>&3
	)
	if [ "$EXT_SZ" == "" ] || [ "$EXT_SZ" == "EXIT" ] ; then
	  echo "script canceled"
	  exit
	fi
}

function define_partition {
	select_fs_type
	PARTIION_FORMAT[$1]="$FS_TYPE"

	if  [ "$FS_TYPE" == "(do not create)" ] ; then
		PARTIION_SIZE[$1]=""
		return
	fi

	if [ "$FS_TYPE" == "FAT16" ] ; then
		select_fat_size
		PARTIION_SIZE[$1]="$FAT_SZ"
	else
		select_ext_size
		PARTIION_SIZE[$1]="$EXT_SZ"
	fi
}


if [ "$1" == "" ] ; then

  while true ; do

    LINE_TEXT=\
"Select the format and size for each partition.\n\n"\
"- The default setting of only 2 partitions (FAT16 + ext4) is recommended\n"\
"  for Renesas EVK boards.\n"\
"- Advanced users that want to store multiple rootfs images can create\n"\
"  multiple partitions (2,3,4).\n"\
"- If you select [remaining space], it must be the last partition.\n"\
"- Hint: A 8GB card is only about 7.5BG. Be careful with setting sizes.\n"\
"\nYou may use [ESC]+[ESC] to cancel/exit.\n"\
"Use [Tab] key to select buttons at the bottom.\n"\
"Use the <Change> button (or enter) to make changes.\n"\
"Use the <Begin> button to start formatting"


    SELECT=$(whiptail --title "Partition Selection" --menu "${LINE_TEXT}" 0 0 0 --cancel-button Begin --ok-button Change \
	"Partition 1" "  ${PARTIION_FORMAT[0]}, ${PARTIION_SIZE[0]}"\
	"Partition 2" "  ${PARTIION_FORMAT[1]}, ${PARTIION_SIZE[1]}"\
	"Partition 3" "  ${PARTIION_FORMAT[2]}, ${PARTIION_SIZE[2]}"\
	"Partition 4" "  ${PARTIION_FORMAT[3]}, ${PARTIION_SIZE[3]}"\
	"Begin" "  Start formatting..."\
	3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ] ; then
	break
    elif [ $RET -eq 0 ] ; then
      case "$SELECT" in
        "Partition 1") define_partition 0 ;;
        "Partition 2") define_partition 1 ;;
        "Partition 3") define_partition 2 ;;
        "Partition 4") define_partition 3 ;;
        "Begin") break ;;
        *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $SELECT" 20 60 1
    else
      exit 1
    fi

  done
fi

# Change the setting to match what fdisk wants
for i in 0 1 2 3
do
	if [ "${PARTIION_SIZE[$i]}" == "" ] ; then
		echo ""
	elif [ "${PARTIION_SIZE[$i]}" == "remaining space" ] ; then
		# for reset of the disk, fdisk wants you to just hit enter
		PARTIION_SIZE[$i]=""
	else
	  # add in the + sign
	  PARTIION_SIZE[$i]="+${PARTIION_SIZE[$i]}"
	fi
done
echo "${PARTIION_FORMAT[0]} ${PARTIION_SIZE[0]}"
echo "${PARTIION_FORMAT[1]} ${PARTIION_SIZE[1]}"
echo "${PARTIION_FORMAT[2]} ${PARTIION_SIZE[2]}"
echo "${PARTIION_FORMAT[3]} ${PARTIION_SIZE[3]}"


BEGIN=$(
whiptail --title "Confirm" --yesno "Begin formatting?" 0 0 \
	 3>&2 2>&1 1>&3
)
if [ "$?" != "0" ] ; then
  echo "script canceled"
  exit
fi

sleep 1

echo -e "\nFormatting Flash Device ${DISK}"
echo -en "3" ; sleep 1 ; echo -en "\b2" ; sleep 1 ; echo -en "\b1" ; sleep 1 ; echo -e "\b "

echo -e "\n== Unmounting current partitions =="
sleep 1
for i in 1 2 3 4
do
  if [ "${DISK}" == "/dev/mmcblk0" ] ; then
    i="p${i}"
  fi

  CHECK=`mount | grep ${DISK}${i}`
  if [ "$CHECK" != "" ] ; then
    echo "Unmounting ${DISK}${i} : umount ${DISK}${i}"
    umount ${DISK}${i}
    sleep 1
  fi
done

echo -e "\n== Destroying Master Boot Record (sector 0) =="
sleep 1
echo dd if=/dev/zero of=${DISK} bs=512 count=1
dd if=/dev/zero of=${DISK} bs=512 count=1
sync


# Create primary partitions
sleep 1

if [ "${PARTIION_FORMAT[1]}" == "(do not create)" ] ; then
	echo -e "\n== Creating 1 partition =="
	# 1 partition
	echo -e "n\np\n1\n\n${PARTIION_SIZE[0]}\n"\
		"p\nw\n" | fdisk -u ${DISK}

elif [ "${PARTIION_FORMAT[2]}" == "(do not create)" ] ; then
	echo -e "\n== Creating 2 partitions =="
	# 2 partitions
	echo -e "n\np\n1\n\n${PARTIION_SIZE[0]}\n"\
		"n\np\n2\n\n${PARTIION_SIZE[1]}\n"\
		"t\n1\n6\n"\
		"p\nw\n" | fdisk -u ${DISK}

elif [ "${PARTIION_FORMAT[3]}" == "(do not create)" ] ; then
	echo -e "\n== Creating 3 partitions =="
	# 3 partitions
	echo -e "n\np\n1\n\n${PARTIION_SIZE[0]}\n"\
		"n\np\n2\n\n${PARTIION_SIZE[1]}\n"\
		"n\np\n3\n\n${PARTIION_SIZE[2]}\n"\
		"t\n1\n6\n"\
		"p\nw\n" | fdisk -u ${DISK}

else
	echo -e "\n== Creating 4 partitions =="
	# 4 partitions
	echo -e "n\np\n1\n\n${PARTIION_SIZE[0]}\n"\
		"n\np\n2\n\n${PARTIION_SIZE[1]}\n"\
		"n\np\n3\n\n${PARTIION_SIZE[2]}\n"\
		"n\np\n4\n\n${PARTIION_SIZE[3]}\n"\
		"t\n1\n6\n"\
		"p\nw\n" | fdisk -u ${DISK}

fi

if [ "${PARTIION_FORMAT[0]}" == "FAT16" ] ; then
	# partition 1 is FAT16
	echo -e "\n== Formatting FAT16 partition =="
	if [ "${DISK}" == "/dev/mmcblk0" ] ; then
	PART_NUMBER="p1"
	else
	PART_NUMBER="1"
	fi
	mkfs.vfat -F16 -n RZ_FAT ${DISK}${PART_NUMBER}
	sleep 1
else
	# partition 1 must be ext
	echo -e "\n== Formatting ext partition =="
	if [ "${DISK}" == "/dev/mmcblk0" ] ; then
	  PART_NUMBER="p1"
	else
	  PART_NUMBER="1"
	fi
	mkfs.${PARTIION_FORMAT[0]} -F -L RZ_ext ${DISK}${PART_NUMBER}
	sleep 1
fi

# partition 2
if [ "${PARTIION_FORMAT[1]}" != "(do not create)" ] ; then
	echo -e "\n== Formatting ext partition 2 =="
	if [ "${DISK}" == "/dev/mmcblk0" ] ; then
	  PART_NUMBER="p2"
	else
	  PART_NUMBER="2"
	fi
	if [ "${PARTIION_FORMAT[0]}" == "FAT16" ] ; then
		PART_NAME="RZ_ext"
	else
		PART_NAME="RZ_ext_p2"
	fi

	mkfs.${PARTIION_FORMAT[1]} -F -L $PART_NAME ${DISK}${PART_NUMBER}
	sleep 1
fi

# partition 3
if [ "${PARTIION_FORMAT[1]}" != "(do not create)" ] ; then
	echo -e "\n== Formatting ext partition 3 =="
	if [ "${DISK}" == "/dev/mmcblk0" ] ; then
	  PART_NUMBER="p3"
	else
	  PART_NUMBER="3"
	fi
	mkfs.${PARTIION_FORMAT[2]} -F -L RZ_ext_p3 ${DISK}${PART_NUMBER}
	sleep 1
fi

# partition 4
if [ "${PARTIION_FORMAT[1]}" != "(do not create)" ] ; then
	echo -e "\n== Formatting ext partition 4 =="
	if [ "${DISK}" == "/dev/mmcblk0" ] ; then
	  PART_NUMBER="p4"
	else
	  PART_NUMBER="4"
	fi
	mkfs.${PARTIION_FORMAT[3]} -F -L RZ_ext_p4 ${DISK}${PART_NUMBER}
	sleep 1
fi

if [ "${DISK}" == "/dev/mmcblk0" ] ; then
  whiptail --title "== Finished ==" --msgbox "Please remove the SD Card from the system, then plug it back in" 0 0
else
  whiptail --title "== Finished ==" --msgbox "Please unplug the USB drive from the system, then plug it back in" 0 0
fi
#fdisk -l ${DISK}

#notify-send -t 2000 "Done"

