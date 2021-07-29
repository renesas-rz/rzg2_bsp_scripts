## Notes on USB Download mode
USB Download mode is supported for RZ/G2E, RZ/G2N and RZ/G2H devices.
In this mode, the RZ/G USB Function port is used as a USB CDC class USB-serial device when plugged into a host machine.
The HiHope boards were designed to support this.
In Windows, this works fine. However with a Linux PC, there are issues.


### 1. Disable Modem Manager
In Ubuntu, ModemManager comes pre-installed as part of the network manager software.
Therefore, on Linux machines with ModemManager installed and active, the device may show up as busy for ~15 seconds while
modem manager tries to decide if its a modem. This means it will send data to our RZ/G device and crash the ROM loader
inside the RZ/G.

The easiest way to fix this is just disable ModemManager (especially if you don't have a modem connected)
```
$ sudo systemctl status ModemManager.service
$ sudo systemctl stop ModemManager.service
$ sudo systemctl disable ModemManager.service
$ sudo apt-get purge modemmanager
```
(Optional). If you still connect to the Internet with a dial-up modem and need to keep ModemManager, you could add a rule to udev to make it ignore
```
$ sudo bash -c 'echo "# RZ/G2N, RZ/G2H" >> /etc/udev/rules.d/90-Renesas-USB-Downloader.rules'
$ sudo bash -c 'echo "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"045b\", ATTRS{idProduct}==\"0248\", ENV{ID_MM_DEVICE_IGNORE}=\"1\"" >> /etc/udev/rules.d/90-Renesas-USB-Downloader.rules'
$ sudo bash -c 'echo "" >> /etc/udev/rules.d/90-Renesas-USB-Downloader.rules'
$ sudo bash -c 'echo "# RZ/G2E" >> /etc/udev/rules.d/90-Renesas-USB-Downloader.rules'
$ sudo bash -c 'echo "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"045b\", ATTRS{idProduct}==\"024D\", ENV{ID_MM_DEVICE_IGNORE}=\"1\"" >> /etc/udev/rules.d/90-Renesas-USB-Downloader.rules'
$ sudo udevadm control --reload-rules && sudo udevadm trigger

```

### 2. Modify Host cdc-acm Kernel Driver (if needed)

If you are running Ubuntu 20.04-LTS, and your kernel is equal to are newer then the follow versions, you can **skip this section**.
Use the command "uname -a" to check:
```
$ uname -a
```
Ubuntu-20.04 with a 5.8 kernel
* 5.8.0-**44**-generic   (44 or higher)

Ubuntu-20.04 with a 5.4 kernel
* 5.4.0-**57**-generic   (57 or higher)

What happens is when the board is powered up, /dev/ttyACM0 is created.
On the USB side, the only other thing that happens other USB enumeration is that the kernel (Ubuntu) set the ??virtual?? baud rate to 9600 on the USB control pipe (so that doesn??t matter).

However in the Ubuntu kernel, by default in the cdc_acm driver, echo is on by default for all ACM devices.
This means as soon as someone accesses the board over USB (ie, open), the board sends out this message over the USB BULK endpoint.

USB Download mode (w/o verification)
(C) Renesas Electronics Corp.
-- please send file---------------!
The issue is that the cdc_acm driver will then echo that message back to the board (one bulk packet at a time). And, the internal ROM code is not expecting that. It only wants to see an S-Record, so it instantly errors out.

### Mainline Kernel Fix
The mainline kernel was patched for RZ/G2 devices and was fixed for the Linux-5.10 release. Additionally, the patch was back ported to stable kernels.
Here is the list of kernels that have the patch:
* 5.10 (and later)
* 5.9.9
* 5.4.78
* 4.19.158
* 4.14.207
* 4.9.244
* 4.4.244

For Ubuntu, you can use this website to check what mainline kernel version you are using.
https://people.canonical.com/~kernel/info/kernel-version-map.html

I would suggest you first **get all the latest Ubuntu updates** and then try connecting to your board. It is very likely that you do not need to manually modify your kernel code.
```
$ sudo apt update ; sudo apt upgrade
```
If you board does not connect, then you will need to follow the procedure below.

### Automatic Build Script
There is a script **patch-cdc-acm.sh** that will perform **all the steps below for you automatically** including downloading, modifying, building and installing the driver.
It will automatically detect the Ubuntu version and kernel version you are currently running, so no changes should be needed.
The entire kernel source code repository will be downloaded to your home directory.
For example, ~/ubuntu-bionic.
Note that this will take up about 3 GB worth of disk space.
I would suggest you do not delete this since every time you get a kernel update from Ubuntu, you will have to rebuild this driver again.


### 2.1 Download the source code for your kernel
* Since I was using Ubuntu-18.04, I will need to get the code for the 'Bionic' repository.

```
$ sudo apt-get install build-essential
$ cd ~
$ git clone git://kernel.ubuntu.com/ubuntu/ubuntu-bionic.git
$ cd ubuntu-bionic
````
* Use the Linux command "uname -r" to determine what the kernel version you are running. For example:
```
$ uname -r
5.3.0-53-generic
```
### 2.2 Get the correct driver source code version to modify
* Check out that specific version. Note, you can use the 'git tag' command to find out the exact syntax of the release tag name since "generic" wasn't really in the tag name:
```
$ git tag | grep 5.3.0-53
Ubuntu-hwe-5.3.0-53.47_18.04.1

$ git checkout Ubuntu-hwe-5.3.0-53.47_18.04.1
```
* (**Optional, not needed**). By default, the cdc-acm driver is already configured to be build as a module in the kernel. If it wasn't, we would need to rebuild kernel. These would have been the steps to do that....but again, we do not need to do this.
$ cp /boot/config-5.3.0-51-generic .config
$ make oldconfig
$ make menuconfig
$ make kernelversion
$ make

### 2.3 Patch and build a new cdc-acm driver

* We really only need 2 files, so we'll copy them into a separate directory.
```
$ mkdir z_module_cdc-acm
$ cp drivers/usb/class/cdc-acm.* z_module_cdc-acm
```
* We need a very simple Makefile to build our module.
```
$ cd z_module_cdc-acm

$ echo -e 'KERNEL = $(shell uname -r)' > Makefile
$ echo -e 'obj-m = cdc-acm.o\n' >> Makefile
$ echo -e 'all:' >> Makefile
$ echo -e '\tmake -C /lib/modules/$(KERNEL)/build M=$(PWD) modules' >> Makefile
$ echo -e 'clean:' >> Makefile
$ echo -e '\tmake -C /lib/modules/$(KERNEL)/build M=$(PWD) clean' >> Makefile
```
* Check to make sure the driver has support for the **DISABLE_ECHO** flag. This flag was added in kernel linux-5.0. However, it was marked to be backported to older longterm supported kernels, so it might already be in the kernel source you are using.
Check your cdc-acm.h file to see if DISABLE_ECHO is defined.
```
$ grep DISABLE_ECHO cdc-acm.h
#define DISABLE_ECHO			BIT(9)
```
* If DISABLE_ECHO  it is **not** defined, you will need to manually apply the mainline patch (commit eafb27fa5283599ce6c5492ea18cf636a28222bb) located here:
https://github.com/torvalds/linux/commit/eafb27fa5283599ce6c5492ea18cf636a28222bb
(or also located here)
https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/drivers/usb/class?id=eafb27fa5283599ce6c5492ea18cf636a28222bb

* Manually edit cdc-acm.c and add the 3 USB ID for RZ/G2H, G2N and G2E to the table as shown below.
```
$ diff -u cdc-acm.c.orig cdc-acm.c
--- cdc-acm.c.orig    2020-06-05 07:13:20.395582047 -0400
+++ cdc-acm.c   2020-06-05 07:41:41.816674789 -0400
@@ -1668,6 +1668,15 @@
	{ USB_DEVICE(0x0e8d, 0x2000), /* MediaTek Inc Preloader */
	.driver_info = DISABLE_ECHO, /* DISABLE ECHO in termios flag */
	},
+	{ USB_DEVICE(0x045b, 0x023c), /* Renesas USB Download mode */
+	.driver_info = DISABLE_ECHO, /* DISABLE ECHO in termios flag */
+	},
+	{ USB_DEVICE(0x045b, 0x0248), /* Renesas USB Download mode */
+	.driver_info = DISABLE_ECHO, /* DISABLE ECHO in termios flag */
+	},
+	{ USB_DEVICE(0x045b, 0x024D), /* Renesas USB Download mode */
+	.driver_info = DISABLE_ECHO, /* DISABLE ECHO in termios flag */
+	},
	{ USB_DEVICE(0x0e8d, 0x3329), /* MediaTek Inc GPS */
	.driver_info = NO_UNION_NORMAL, /* has no union descriptor */
	},
```
* Now build your module. By simply running, make, you should end up with a loadable kernel module
```
$ make
$ ls -l cdc-acm.ko
```
### 2.4 Replace the default cdc-acm driver with your new one
* Remove the current cdc-acm module your kernel has running, and replace it with the one you just built.
```
$ sudo rmmod cdc-acm
$ sudo insmod cdc-acm.ko
```

* If you do not want to do this every time you boot your system, you could simply replace the file that the system loads by default.
```
$ mv /lib/modules/5.3.0-51-generic/kernel/drivers/usb/class/cdc-acm.ko   /lib/modules/5.3.0-51-generic/kernel/drivers/usb/class/cdc-acm.ko.orig
$ cp cdc-acm.ko /lib/modules/5.3.0-51-generic/kernel/drivers/usb/class/cdc-acm.ko
```

### 3. A note on kernel updates
Please note that as you get Ubuntu system updates, the kernel and all it's modules might get updated. Mean, you will have to repeat this process again. However, at least in your ubuntu-bionic.git repository, you can do a 'git pull' in order to just download the updated code instead of cloning the entire repository again.

### 4. Device or resource busy error
If you got "/dev/ttyACM0":Device or resource busy error while writing files, please make sure that Modem Manager service was disabled. If not, Please follow step 1 "Disable Modem Manager" to disable it.  
