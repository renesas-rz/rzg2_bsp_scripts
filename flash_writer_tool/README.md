# Flash Writer Tool
* A script for automating the programming of boot loaders using the Renesas rzg2_flash_writer software utility.

## Supported Renesas evaluation boards
* RZ/G2H HiHope
* RZ/G2M HiHope
* RZ/G2N HiHope
* RZ/G2E EK874
* RZ/G2L SMARC
* RZ/G2LC SMARC
* RZ/G2UL SMARC
* RZ/V2L SMARC
* RZ/G3S SMARC

## Program Bootloaders using internal ROM and Flashwriter

### Description
* The RZ has a built-in ROM for downloading a binary to internal RAM and then executing it.
* That downloaded binary is call "Flash Writer" and is supplied with the BSP.
* This script helps automate the process of programming a SPI flash or eMMC by download image over a serial port to the board.
* If using a Renesas evaluation board, you can use the 'sw' command to print out how you need to modify the on-board switches to get into the correct modes.
* There are 2 methods to using this script: Command line or GUI menu

### Download

* If using Yocto to build, the script will automaticaly detect the EVK you are using if you download this script under Yocto.
 
**Options #1 : Clone entire repository in the base of the Yocto directory:**
<pre>
$ cd ~/yocto/rzg_bsp_v3.0.5
$ git clone https://github.com/renesas-rz/rzg2_bsp_scripts
$ cd rzg2_bsp_scripts/flash_writer_tool
$ ./flash_writer_tool.sh
</pre>

**Options #2 : Download just the script file in the Yoto output directory:**
<pre>
$ cd ~/yocto/rzg_bsp_v3.0.5/build/tmp/deploy/images/smarc-rzg2l
$ wget https://raw.githubusercontent.com/renesas-rz/rzg2_bsp_scripts/master/flash_writer_tool/flash_writer_tool.sh
$ chmod +x flash_writer_tool.sh
$ ./flash_writer_tool.sh
</pre>

**Options #3 : Download anywhere and use full file paths**
<pre>
$ git clone https://github.com/renesas-rz/rzg2_bsp_scripts
$ cd rzg2_bsp_scripts/flash_writer_tool
$ ./flash_writer_tool.sh
</pre>

### Using the GUI Menu Interface

* **This is the recommended way of using this tool**
* When you run the flash\_writer\_tool.sh script without any arguments, it will operate in a GUI menu mode. In this interface, you can select the files you wish to program. You can also start the programming operations.
* Please select your **Board** and **Target Flash** and **Interface** first, then choose the location (**FILES_DIR**) that contains your binary files to program.
* Your board configuration setting can be saved in a .ini file. You can using multiple different .ini files. By default, "config.ini" is chosen.
* GUI settings will be saved in the file "settings.txt"

### GUI Menu Items
 * **Board:** Select the board you are using. **Do this first.**
 * **Target Flash:** Select SPI Flash or eMMC Flash
 * **Interface:** Select the serial interface for your board.
 * **Speed:** Serial baud rate. Select 115,200 or 921,600.
 * **Config File:** File to save your settings to.
 * **Extra Settings:** Fun stuff.
* **Files:**
  * The "✓" symbol means the file exist. The "x" means the file is not detected.
  * **FILES_DIR:** Set this to the directory of your files to program.
  * **FLASHWRITER:** The filename of the Flash Writer binary
  * **RZ/G2H, /G2N, /G2M, /G2E:** Set SA0\_FILE, BL2\_FILE, SA6\_FILE, BL31\_FILE, UBOOT\_FILE
  * **RZ/G2L, /G2LC, /G2UL, /V2L, /G3S:** Set BL2\_FILE, FIP\_FILE
* **Operations:**
  * Select these menu items to perform the operations
  * The "★" symbols shows the operations can be performed next
  * The **Show switches** operation shows you how to set the boot mode switching on the board. **Very helpful!**
  * Use the **Download F.W.** operation first after setting the boot most switches

![name](gui.png?raw=true)

<br>

### How to Use
1. **Select your Board**
* Use either the GUI menu or a make a config.ini file to selection your board and files.

2. **Boot into SCIF download mode**
* Determine the switch settings for your board. You can find that information in the GUI menu interface "Show Switches".
* Some EVK board have a blue RESET button you can use to reboot into SCIF Downlaod Mode
* Some EVK boards do not have a RESET button, so you will need to remove power to the board, and then power again

3. **Monitor the Seral Port output**
* You can connect a serial terminal program such as **putty**, **GTKTerm** or **minicom** to watch the progress of the programming.
* Instead of a serail terminal program, you can also open a 2nd terminal window and type "cat /dev/ttyUSB0" in order to monitor the output from the board.

4. **Confirm SCIF Download Mode**
* If you press the RESET button the board, you should see a text message "SCIF Download mode .......  please send !"
* This message will confirm that you are in the correct mode.

7. **Download the flash writer binary**.
* Select the operation **Downlaod F.W.**
* This must be done **first** after RESET.
* This will downlaod the Flash Writer binary to your device's internal RAM. You cannot do any other operation until this is complete.

8. Perform the individual commands to download and program the binaries to the board.

<br>

### Using the Command Line Interface
* **Advanced users** or production programming

* When using the command line interface, you must store all the board settings a config.ini file and pass the filename on the command line.
* It is recommended to first make a copy of the example configuration (example_config.ini) and then edit it in a text editor.

<pre>
$ cp example_config.ini my_config.ini
$ gedit my_config.ini
</pre>

* You can see the list of commands by using the following command:
<pre>
$ ./flash_writer_tool.sh  h
</pre>

* The 'sw' command can be used to show the boot mode switch setting.
<pre>
$ ./flash_writer_tool.sh my_config.ini sw
</pre>

* Below is an example of programming all the files after you have edited the my_config.ini file. Note that the 'fw' command must be run first.
<pre>
# RZ/G2E, RZ/G2N, RZ/G2M, RZ/G2H:
$ ./flash_writer_tool.sh my_config.ini fw
$ ./flash_writer_tool.sh my_config.ini atf
$ ./flash_writer_tool.sh my_config.ini u-boot
</pre>
<pre>
# RZ/G2L, RZ/G2LC, RZ/G2UL, RZ/V2L:
$ ./flash_writer_tool.sh my_config.ini fw
$ ./flash_writer_tool.sh my_config.ini atf
</pre>

<br>

## Notes on USB Download mode
USB Download mode is supported for RZ/G2E, RZ/G2N and RZ/G2H devices.
In this mode, the RZ/G USB Function port is used as a USB CDC class USB-serial device when plugged into a host machine.
The HiHope boards were designed to support this.
In Windows, this works fine. However with a Linux PC, there are issues.

Please refer to file [USB_Download_Mode.md](USB_Download_Mode.md)
