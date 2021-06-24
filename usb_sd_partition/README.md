# Partitioning Script
This script will erase and reformat a **USB Flash drive** or **SD Card** (via USB card reader) so that it can be used for RZ/G Linux systems.


## Partion Types
It will have 2 partitions:

1. FAT16 partition (that can be access by Windows)
2. ext2/3/4 partion that can hold a Linux file system.

## Partition Sizes
The **500MB partition** size is recommended because it doesn't really hold anything else other than the kernel and device tree. But, you might want to copy something into this partition (like an MP3, a JPG or maybe a demo app) from a Windows machine so that you can use access it on your board after it boots up.

The **max** partition size is default because it will always work for any size drive. However you don't really need a lot of space, and the bigger you make it, the longer it takes to format. I would say **2GB** is about as much as you need for the file system.

## Partition Labels
The script also assigns volume labels to the partitions: **RZ_FAT ** and **RZ_ext**.
This makes the partitions easy to identify in your Linux host machine.
In Ubuntu, when you plug this formatted drive in, they partitions should automatically get mapped to the following locations:

* /media/chris/RZ_FAT
* /media/chris/RZ_ext

(of course, 'chris' will be your username instead)

## Usage
* Plug in a USB Flash drive (or USB SD card reader)
* Run:   $ sudo ./usb_partition.sh
* Remove the drive (first, right click on USB icon on Desktop and select "Eject")
* Insert the drive back in

## How to copy the RZ/G files
Since the partitions have labels and should show up in your system under /media, you can use the commands below to install your files.
The FAT partition will need the Device Tree Blob/binary (.dtb file) and the Linux kernel.
The ext partition should contain the root file system files. Yocto will output a single file with all the file system files tar-ed ('zipped') up, so you will actually be decompressing and copying in the same command.
The files you need to copy will be in:  
**rzg2_bsp_eva_v10x/build/tmp/deploy/images/ek874/**

Execute the follow commands from that directory.

**Copy Device Tree**

    $ cp -av Image-r8a774c0-ek874.dtb  /media/chris/RZ_FAT

**Copy Kernel**

    $ cp -av Image-ek874.bin  /media/chris/RZ_FAT

**Copy/Expand Root File System**  
(don't forget the -C before the target directory)

    $ sudo tar -xvf core-image-weston-ek874.tar.gz   -C /media/chris/RZ_ext

**Sync**
(makes sure all files are written out before disconnecting)

    $ sync
    $ eject /media/chris/RZ_FAT

