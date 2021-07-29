#!/bin/bash

# This will be the base directory to hold the kernel source code.
# It will create a sub-direcotry (for example, ~/ubuntu-focal) that will
# be a git repository of the entire Ubuntu Linxu kernel.
BASE_DIR=~

# Check if build-essential is installed
dpkg -l build-essential > /dev/null dpkg 2>&1
if [ "$?" != "0" ] ; then
	echo -e "\nThe package build-essential is requried.\n\n"
	echo "sudo apt-get install -y build-essential"
	sudo apt-get install -y build-essential
fi

# Determine Ubuntu version
source /etc/os-release
echo -e "\n$NAME $VERSION"

# Determine current kernel verison
KERNEL_VER=`uname -r`
echo "Kernel version = $KERNEL_VER"

if [ "$NAME" != "Ubuntu" ] ; then
	echo "ERROR: Only Ubuntu is supported."
	exit
fi

# The name "DISTRIB_CODENAME" has changed to "UBUNTU_CODENAME" in /etc/os-release 
# starting with in 20.04,
#        DISTRIB_CODENAME=xenial
#        DISTRIB_CODENAME=xenial
#        UBUNTU_CODENAME=focal
# so we'll just use the lsb_release app
CODENAME=`lsb_release -cs`
REPO_NAME="ubuntu-${CODENAME}"

# Clone the kernel repo or update it if it already exists
cd $BASE_DIR
if [ ! -e $REPO_NAME ] ; then
	echo -e "\n---[ Cloning kernel from official Ubuntu repository ]---"
	git clone git://kernel.ubuntu.com/ubuntu/${REPO_NAME}.git
	cd $REPO_NAME
else
	echo -e "\n---[ Updating existing kernel repository ]---"
	cd $REPO_NAME
	git fetch
fi


echo -e "\n---[ Get the correct driver source code version to modify ]---"
# Check out that specific version. Note, you can use the 'git tag' command to find out the exact
# syntax of the release tag name since "generic" wasn't really in the tag name

# Remove the -generic at the end
KERNEL_VER_NUM=`echo $KERNEL_VER | sed 's/-generic//'`
#echo "KERNEL_VER_NUM = $KERNEL_VER_NUM"

# Find the exact tag name
TAG_NAME=`git tag | grep $KERNEL_VER_NUM`
#echo "TAG_NAME = $TAG_NAME"

# Check out the code at that point
echo "git checkout $TAG_NAME"
git checkout $TAG_NAME

# We really only need 2 files, so we'll copy them into a separate directory.
echo -e "\n---[ Make a copy of the driver files ]---"
mkdir -p z_module_cdc-acm/$KERNEL_VER
cp -v drivers/usb/class/cdc-acm.* z_module_cdc-acm/$KERNEL_VER
cd z_module_cdc-acm/$KERNEL_VER

# We need a very simple Makefile to build our module.
echo -e 'KERNEL = $(shell uname -r)' > Makefile
echo -e 'obj-m = cdc-acm.o\n' >> Makefile
echo -e 'all:' >> Makefile
echo -e '\tmake -C /lib/modules/$(KERNEL)/build M=$(PWD) modules' >> Makefile
echo -e 'clean:' >> Makefile
echo -e '\tmake -C /lib/modules/$(KERNEL)/build M=$(PWD) clean' >> Makefile

# Make a copy of what we started with
cp cdc-acm.c cdc-acm.c.orig

echo -e "\n---[ Modify the cdc-acm driver ]---"
# Manually edit cdc-acm.c and add the 3 USB ID for RZ/G2N, G2H, G2E to the table as shown below.

#	{ USB_DEVICE(0x0e8d, 0x2000), /* MediaTek Inc Preloader */
#	.driver_info = DISABLE_ECHO, /* DISABLE ECHO in termios flag */
#	},
#+	{ USB_DEVICE(0x045b, 0x023c), /* Renesas USB Download mode */
#+	.driver_info = DISABLE_ECHO, /* DISABLE ECHO in termios flag */
#+	},
#+	{ USB_DEVICE(0x045b, 0x0248), /* Renesas USB Download mode */
#+	.driver_info = DISABLE_ECHO, /* DISABLE ECHO in termios flag */
#+	},
#+	{ USB_DEVICE(0x045b, 0x024D), /* Renesas USB Download mode */
#+	.driver_info = DISABLE_ECHO, /* DISABLE ECHO in termios flag */
#+	},
#	{ USB_DEVICE(0x0e8d, 0x3329), /* MediaTek Inc GPS */
#	.driver_info = NO_UNION_NORMAL, /* has no union descriptor */
#	},

sed -i 's:MediaTek Inc Preloader:MediaTek Inc Preloader \*/\
\t.driver_info = DISABLE_ECHO, /\* DISABLE ECHO in termios flag \*/\
\t},\
\t{ USB_DEVICE(0x045b, 0x023c), /\* Renesas USB Download mode \*/\
\t.driver_info = DISABLE_ECHO, /\* DISABLE ECHO in termios flag \*/\
\t},\
\t{ USB_DEVICE(0x045b, 0x0248), /\* Renesas USB Download mode \*/\
\t.driver_info = DISABLE_ECHO, /\* DISABLE ECHO in termios flag \*/\
\t},\
\t{ USB_DEVICE(0x045b, 0x024D), /\* Renesas USB Download mode:g' cdc-acm.c

echo -e "\n---[ Build the module ]---"
echo "make"
make
ls -l cdc-acm.ko

# Remove the current cdc-acm module your kernel has running, and replace it with the one you just built.
echo -e "\n---[ Replace the current running module]---"
echo -e "sudo rmmod cdc-acm"
sudo rmmod cdc-acm
echo -e "sudo insmod cdc-acm.ko"
sudo insmod cdc-acm.ko

# If you do not want to do this every time you boot your system, you could simply replace the file that the system loads by default.
echo -e "\n---[ Replace the file in the /lib/modules directory so it will automaticaly load each boot ]---"
echo -e "sudo mv /lib/modules/${KERNEL_VER}/kernel/drivers/usb/class/cdc-acm.ko   /lib/modules/${KERNEL_VER}/kernel/drivers/usb/class/cdc-acm.ko.orig"
sudo mv /lib/modules/${KERNEL_VER}/kernel/drivers/usb/class/cdc-acm.ko   /lib/modules/${KERNEL_VER}/kernel/drivers/usb/class/cdc-acm.ko.orig

echo -e "sudo cp cdc-acm.ko /lib/modules/${KERNEL_VER}/kernel/drivers/usb/class/cdc-acm.ko"
sudo cp cdc-acm.ko /lib/modules/${KERNEL_VER}/kernel/drivers/usb/class/cdc-acm.ko

echo -e "\n\ndone!"
