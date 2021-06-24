#!/bin/bash

# This script will erase and reformat a USB Flash drive (or USB SD Card reader)
# to be used for RZ/G Linux systems.
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
	# Attached USB Drives
	TEXT=
	DISK_LIST=
	for i in a b c d
	do
	if [ -e /dev/sd${i} ] ; then
		dmesg | grep "sd${i}] Attached SCSI removable disk" > /dev/null
		if [ "$?" != "0" ] ; then
			continue
		fi
		DISK_LIST="$DISK_LIST $i"

		ITEM="/dev/sd${i}"
		DESC=`sudo fdisk -l /dev/sd${i} | grep -m1 sd${i} | sed "s:Disk /dev/sd${i}::"`
		#DESC=`sudo fdisk -l /dev/sd${i} | grep -m1 sd${i} | sed "s:Disk::"`

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


#echo "==== Attached USB Drives ====="
#DISK_LIST=
#echo -e "------------------------------------------------------------"
#for i in a b c d
#do
#  if [ -e /dev/sd${i} ] ; then
#     dmesg | grep "sd${i}] Attached SCSI removable disk" > /dev/null
#     if [ "$?" != "0" ] ; then
#       continue
#     fi
#
#    DISK_LIST="$DISK_LIST $i"
#    sudo fdisk -l /dev/sd${i} | grep sd${i}
#    echo -e "------------------------------------------------------------"
#  fi
#done


#if [ -e /dev/disk/by-label ] ; then
#  echo -e "\n==== Partition Lables ====="
#  echo -n "------------------------------------------------------------"
#  ls  -l /dev/disk/by-label | awk '{ print $9, $10, $11 }'
#  echo -e "------------------------------------------------------------"
#fi

#echo -n "Enter the sd drive letter (a,b,c,d) you want to format (pick one: $DISK_LIST ): "
#read answer
#DISK=/dev/sd${answer}
#
#
#if [ ! -e $DISK ] ; then
#  echo -e "\n\n------------------------------------------------------------"
#  echo -e "ERROR: Device does not exists: $DISK"
#  echo -e "------------------------------------------------------------"
#  exit
#fi

BEGIN=$(
whiptail --title "Confirm" --yesno "Begin formatting?" 0 0 \
	 3>&2 2>&1 1>&3	
)
if [ "$?" != "0" ] ; then
  echo "script canceled"
  exit
fi

sleep 1

echo -e "\nFormatting USB Disk /dev/sd${DISK}"
echo -en "3" ; sleep 1 ; echo -en "\b2" ; sleep 1 ; echo -en "\b1" ; sleep 1 ; echo -e "\b "

echo -e "\n== Unmounting current partitions =="
sleep 1
for i in 1 2 3 4
do
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
mkfs.vfat -F16 -n RZ_FAT ${DISK}1
sleep 1

echo -e "\n== Formatting $EXT_VER partition =="
mkfs.${EXT_VER} -F -L RZ_ext ${DISK}2
sleep 1

#echo -e "\n== Finished ==\nPlease unplug the USB drive and then plug it back in\n"
whiptail --title "== Finished ==" --msgbox "Please unplug the USB drive and then plug it back in" 0 0

#fdisk -l ${DISK}

#notify-send -t 2000 "Done"

