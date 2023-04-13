# Image Creator

## Overview

This script will create a complete image file (sd_card.img) that can be programmed into an SD Card, eMMC or USB Flash drive using a tool such as Win32DiskImager(Windows), balenaEtcher(Windows or Linux), Rufus(Windows) or 'dd'(Linux). These programs provide a sector by sector copy, partition table and all.

Since the default RZ/G boot process in the Renesas BSP is to read the Device Tree and kernel from a FAT16 partition (partition 1) and then mount a root file system (ext3 or ext4) found on partition 2, your image must contain the Master Boot Record (MBR) and partition table at the very beginning of the drive (sector 0), and then the correctly formatted and populated partitions in the correct locations in the image file.

One way to do this is to prepare an real SD Card the way you want it, then read it out sector by sector to a file (using dd for example). But, that takes time. Also, fragments of old "deleted files" might still exist through out the storage area, so when you try to compress your image, it will not compress down as much as it should.

This script instead will:
 - Create a blank (all zeros) file that will be our final image. Since any space that is not used will be 0x00, this will make your image file compress well
 - Use fdisk to write a MBR and partition table to the file that will contain a FAT16 and ext3/4 partition
 - Mount that formatted file as a loop device so that you can copy files into the partitions as if it were an actual directory on your machine.
 - Finally the script will compress (zip) the image file for you so it is easier to store and send

## Instructions

Simply copy/paste a copy of 'example_config.ini' and edit it as needed. All the settings are explained inside that example file.
To run the program, pass your configuration file that you just created on the command line of the script.
Example:

    $ cp example_config.ini my_demo_config.ini
    $ gedit my_demo_config.ini
    $ ./create_image.sh my_demo_config.ini

Note that the script uses 'sudo' to run some commands, so you might be prompted to enter your account password.


