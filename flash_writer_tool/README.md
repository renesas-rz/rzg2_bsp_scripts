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

## Program Bootloaders using internal ROM and Flashwriter

### Description
* The RZ/G2 has a built-in ROM for downloading a binary to internal RAM and then executing it.
* That downloaded binary is call "Flash Writer" and is supplied with the VLP64 BSP.
* This script helps automate the process of programming a SPI flash or eMMC by download image over a serial port to the board.
* If using a Renesas evaluation board, you can use the 'sw' command to print out how you need to modify the on-board switches to get into the correct modes.
* There are 2 methods to using this script: Command line or GUI menu

### Using the GUI Menu Interface

* **This is the recommended way of using this tool**
* When you run the flash\_writer\_tool.sh script without any arguments, it will operate in a GUI menu mode. In this interface, you can select the files you wish to program. You can also start the programming operations.
* Please select your **Board** and **Target Flash**  and **Interface** first, then choose the location (**FILES_DIR**) that contains your binary files to program.
* Your board configuration setting can be saved in a .ini file. You can using multiple different .ini files. By default, "config.ini" is chosen.
* GUI settings will be saved in the file "settings.txt"


* **Setup Items**
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
  * **RZ/G2L, /G2LC, /G2UL, /V2L:** Set BL2\_FILE, FIP\_FILE
* **Operations:**
  * Select these menu items to perform the operations
  * The "★" symbols shows the operations can be performed next
  * The **Show switches** operation shows you how to set the boot mode switching on the board. **Very helpful!**
  * Use the **Download F.W.** operation first after setting the boot most switches

![name](gui.png?raw=true)

<br>

<br>

### Using the Command Line Interface
* **Advanced users** or production programming
* If you wish to use only the command line, you can see the list of commands by using the following command:

<pre>
$ ./flash_writer_tool.sh  h
</pre>

* When using the command line interface, you may either pass all board settings and file names on the command line, or store them in a .ini file and pass the filename on the command line.

* When using the command line interface, it is recommended to first make a copy of the example configuration (example_config.ini) and then edit it in a text editor.

<pre>
$ cp example_config.ini my_config.ini
$ gedit my_config.ini
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

### Instructions
1. Use either the GUI menu or a .ini config file to selection your board and files.

2. Power **off** the board

3. Determine the **switch settings** for your board. You can find that information in the GUI menu interface, or by using the "sw" command on the command line. Put the device into **SCIF download mode**.

4. Power **on** the board

5. Open a 2nd terminal window and type "cat /dev/ttyUSB0" in order to monitor the output from the board. If you press the RESET button the board, you should see a text message "SCIF Download mode .......  please send !"

6. **Download the flash writer binary**. This must be done first after RESET.

7. Perform the individual commands to download and program the binaries to the board.

## Notes on USB Download mode
USB Download mode is supported for RZ/G2E, RZ/G2N and RZ/G2H devices.
In this mode, the RZ/G USB Function port is used as a USB CDC class USB-serial device when plugged into a host machine.
The HiHope boards were designed to support this.
In Windows, this works fine. However with a Linux PC, there are issues.

Please refer to file [USB_Download_Mode.md](USB_Download_Mode.md)
