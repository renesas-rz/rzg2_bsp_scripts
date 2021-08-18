#!/bin/bash

# This script will erase and reformat a 'USB Flash drive', a 'USB SD Card reader',
# or a 'SD Card reader' (plugged directly into a laptop) to be used for RZ/G Linux systems.
# It will have 2 partitions:
#   1.  FAT16 partition (that can be access by Windows)
#   2.  ext partition that can hold a Linux file system.

# This script must run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "This script must be run as root. \nRestarting as root...\n"
   echo -e "sudo $0\n"
   sudo $0
   exit 1
fi

which whiptail > /dev/null
if [ "$?" != "0" ] ; then
  echo "Whiptail not installed"
  exit
fi

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
		fi
	done
}

# Discover our drives
Find_Drives

# Add exit at the end of the array
TEXT=("${TEXT[@]}" "EXIT" "Cancel and exit the script")

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
else
  # add in the + sign
  FAT_SZ="+${FAT_SZ}"
  echo FAT_SZ=$FAT_SZ
fi

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
    "max" "(recomended) Use whatever is left"\
	"EXIT" "Cancel and exit the script" \
	 3>&2 2>&1 1>&3	
)
if [ "$EXT_SZ" == "" ] || [ "$EXT_SZ" == "EXIT" ] ; then
  echo "script canceled"
  exit
else
  if [ "$EXT_SZ" == "max" ] ; then
    # leave blank
    EXT_SZ=
  else
    # add in the + sign
    EXT_SZ="+${EXT_SZ}"
  fi
  echo EXT_SZ=$EXT_SZ
fi

EXT_VER=$(
whiptail --title "Select EXT Partition filesystem" --default-item ext4 --menu "What filesystem would you like the EXT partition to be?\n\
" 0 0 0 \
	"ext2" ""\
	"ext3" ""\
	"ext4" "(recomended) "\
	"EXIT" "Cancel and exit the script" \
	 3>&2 2>&1 1>&3	
)
if [ "$EXT_VER" == "" ] || [ "$EXT_VER" == "EXIT" ] ; then
  echo "script canceled"
  exit
fi

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


# Create 2 primary partitions
# 500MB (FAT16) + 6GB (ext3)
echo -e "\n== Creating partitions =="
sleep 1
echo -e "n\np\n1\n\n${FAT_SZ}\n"\
        "n\np\n2\n\n${EXT_SZ}\n"\
        "t\n1\n6\n"\
        "p\nw\n" | fdisk -u ${DISK}

echo -e "\n== Formatting FAT16 partition =="
if [ "${DISK}" == "/dev/mmcblk0" ] ; then
  PART_NUMBER="p1"
else
  PART_NUMBER="1"
fi

mkfs.vfat -F16 -n RZ_FAT ${DISK}${PART_NUMBER}
sleep 1

echo -e "\n== Formatting $EXT_VER partition =="
if [ "${DISK}" == "/dev/mmcblk0" ] ; then
  PART_NUMBER="p2"
else
  PART_NUMBER="2"
fi
mkfs.${EXT_VER} -F -L RZ_ext ${DISK}${PART_NUMBER}
sleep 1

if [ "${DISK}" == "/dev/mmcblk0" ] ; then
  whiptail --title "== Finished ==" --msgbox "Please remove the SD Card from the system, then plug it back in" 0 0
else
  whiptail --title "== Finished ==" --msgbox "Please unplug the USB drive from the system, then plug it back in" 0 0
fi
#fdisk -l ${DISK}

#notify-send -t 2000 "Done"

