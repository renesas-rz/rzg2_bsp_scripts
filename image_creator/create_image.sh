#!/bin/bash

# Copyright (c) 2021 Renesas
# SPDX-License-Identifier: MIT

# pass a file that contains all the settings
# For example: ./create_image.sh example_config.ini

if [ "$1" == "" ] ; then
	echo "ERROR: Please pass the location of a config file on the command line"
	echo "       Example: $ ./create_image.sh example_config.txt"
	exit
fi

# Make default /tmp. User can override with the config file.
TMP="/tmp"
source $1

message() {

echo -----------------------------------------
echo $1
echo -----------------------------------------

}

# Some tools do not like ~ character, they want the full path
TMP="${TMP/#\~/$HOME}"
OUTFILE="${OUTFILE/#\~/$HOME}"

# Create the direcotry if it does not exist
if [ ! -d ${TMP} ]; then
  mkdir -p $TMP
  chmod a+rwx $TMP
fi

# Test that we can create the output file
DIR=$(dirname "${OUTFILE}")
FILENAME=$(basename "${OUTFILE}")
mkdir -p $DIR
touch "$OUTFILE"
if [ ! -e $OUTFILE ] ; then
  echo "ERROR: Cannot create output file ${OUTFILE}"
  exit
fi

message "Creating an empty blank image file"

# MB = 1000*1000
# M = 1024*1024,
# GB = 1000*1000*1000
# G = 1024*1024*1024

if [ "${TOTAL_IMAGE_SIZE: -1}" == "G" ] ; then
  BS_SIZE=1M
  COUNT=${TOTAL_IMAGE_SIZE::-1}
  let COUNT*=1024
fi
if [ "${TOTAL_IMAGE_SIZE: -1}" == "M" ] ; then
  BS_SIZE=1M
  COUNT=${TOTAL_IMAGE_SIZE::-1}
fi
if [ "${TOTAL_IMAGE_SIZE: -2}" == "MB" ] ; then
  BS_SIZE=1MB
  COUNT=${TOTAL_IMAGE_SIZE::-2}
fi
if [ "${TOTAL_IMAGE_SIZE: -2}" == "GB" ] ; then
  BS_SIZE=1MB
  COUNT=${TOTAL_IMAGE_SIZE::-2}
  let COUNT*=1000
fi
#echo TOTAL_IMAGE_SIZE=$TOTAL_IMAGE_SIZE ; echo BS_SIZE=$BS_SIZE ; echo COUNT=$COUNT

echo dd if=/dev/zero of=$OUTFILE bs=$BS_SIZE count=$COUNT
dd if=/dev/zero of=$OUTFILE bs=$BS_SIZE count=$COUNT

# (Optional) Verify your file size
#ls -l $OUTFILE

# Create 2 primary partitions inside our image file
# (FAT16) + (ext3/4)

message "Creating partitions"

echo -e "n\np\n1\n\n+${FAT_SIZE}\n"\
        "n\np\n2\n\n\n"\
        "t\n1\n6\n"\
        "p\nw\n" | fdisk -u $OUTFILE

# (Optional) Verify your file partitioning
# fdisk -l $OUTFILE

# Find the start address for each partition inside the file
FAT_START=$(fdisk -l $OUTFILE | grep "6 FAT16" | awk '{print $2}')
let FAT_START*=512
EXT_START=$(fdisk -l $OUTFILE | grep "83 Linux" | awk '{print $2}')
let EXT_START*=512

# Loop mount our FAT16 partition.
message "Loop mount and format at FAT16"
sudo losetup -v -f -o $FAT_START  $OUTFILE

# Find out our loop device name
LOOP_DEVICE=$(losetup --list | grep $OUTFILE | awk '{print $1}');

# format as FAT16
sudo mkfs.vfat -F 16 -n $FAT_LABEL $LOOP_DEVICE

# mount this loop device (partition) so we can copy files into it
mkdir -p ${TMP}/loop_mount/fat16
sudo mount $LOOP_DEVICE ${TMP}/loop_mount/fat16
sudo cp -r $FAT_FILES/* ${TMP}/loop_mount/fat16
sudo umount  ${TMP}/loop_mount/fat16

# Release the loop device
sudo losetup -d $LOOP_DEVICE

# Loop mount our ext partition.
message "Loop mount and format at ext3/ext4"
sudo losetup -v -f -o $EXT_START  $OUTFILE

# Find out our loop device name
LOOP_DEVICE=$(losetup --list | grep $OUTFILE | awk '{print $1}');

# format as ext3/ext4
sudo mkfs.${EXT_TYPE} -L $EXT_LABEL $LOOP_DEVICE

# mount this loop device (partition) so we can copy files into it
mkdir -p ${TMP}/loop_mount/ext
sudo mount $LOOP_DEVICE ${TMP}/loop_mount/ext
sudo cp -r $EXT_FILES/* ${TMP}/loop_mount/ext
sudo umount  ${TMP}/loop_mount/ext

# Release the loop device
sudo losetup -d $LOOP_DEVICE

# Create bzip2
if [ "$CREATE_BZ2" == "yes" ] ; then
	message "Compressing image (bz2)"
	if [ -e ${OUTFILE}.bz2 ] ; then
	  rm ${OUTFILE}.bz2
	fi
	bzip2 -v -k $OUTFILE
fi

# Create gzip
if [ "$CREATE_GZIP" == "yes" ] ; then
	message "Compressing image (gzip)"
	if [ -e ${OUTFILE}.gz ] ; then
	  rm ${OUTFILE}.gz
	fi
	gzip -v -k $OUTFILE
fi

# Create zip
if [ "$CREATE_ZIP" == "yes" ] ; then
	message "Compressing image (zip)"
	if [ -e ${OUTFILE}.zip ] ; then
	  rm ${OUTFILE}.zip
	fi
	zip -j ${OUTFILE}.zip ${OUTFILE}
fi

echo -e "\n\n"
message "Output Files"
ls -lh ${OUTFILE}*

