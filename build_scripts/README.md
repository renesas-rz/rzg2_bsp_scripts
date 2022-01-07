# RZ/G2 Build Scripts

* These scripts allow you to build BSP software components outside of the Yocto build environment.
* The following boards are supported:

<table cellpadding=2 border=1 style="border:1px solid black; border-collapse: collapse;">
<tr><th>SoC</th><th>Board</th><th>BSP</th></tr>
<tr><td>RZ/G2E</td><td>EK874</td><td>RZ/G2 VLP64</td></tr>
<tr><td>RZ/G2M</td><td>HiHope</td><td>RZ/G2 VLP64</td></tr>
<tr><td>RZ/G2N</td><td>HiHope</td><td>RZ/G2 VLP64</td></tr>
<tr><td>RZ/G2H</td><td>HiHope</td><td>RZ/G2 VLP64</td></tr>
<tr><td>RZ/G2L</td><td>SMARC</td><td>RZ/G2L BSP</td></tr>
<tr><td>RZ/G2LC</td><td>SMARC</td><td>RZ/G2L BSP</td></tr>
</table>

## Repository Installs

* These scripts will not download any source code repositories. You must do that manually.
* Please refer to file **Repository Installs.txt** to find copy/paste commands to get the source code for each BSP software component.
* Note that for some repositories, especially the kernel repositories, you may need additional patches that are not in the public github repositories. Those patches are only distributed in the BSP pacakge that is downloaded from renesas.com.

## Toolchain Installs

* You can use the Yocto SDK Toolchain from the Renesas BSP.
* You can also use an external toolchain such as Linaro or ARM.
* Please refer to file **Toolchain Installs.txt** to find copy/paste commands to download and install pre-built Toolchains.

## Source Code Directory Locations and Names

* This script assumes that your source code repositories are kept in a directory under this one and they use the **same directory names** as below.
* To use a different directly name, you can manually edit the **board.ini** file.

* For example:
<pre>
├── build_scripts
│   ├── mbedtls/                   <<<<<<
│   ├── renesas-u-boot-cip/        <<<<<<
│   ├── rzg2_flash_writer/         <<<<<<
│   ├── rzg_trusted-firmware-a/    <<<<<<
│   ├── rz_linux-cip/              <<<<<<
│   ├── build.sh
│   ├── build_xxxx.sh
│   ├── build_xxxx.sh
│   ├── README.html
│   └── README.md
</pre>

**Hint:**<br>
* You can create a new directory and use symlinks to the build.sh files.
* This will allow you to keep 1 copy of this bsp scripts repository on your PC, but use the build files in multiple places.
* Then if you update your \rzg2\_bsp\_scripts repository (git pull), all your build scripts will be also updated (because they all point back to the same place).<br>
* For example:
<pre>
$ mkdir rzg2l_code
$ cd rzg2l_code
$ for i in ~/rzg2_bsp_scripts/build_scripts/build*.sh ; do ln -vs $i ; done
$ ls -l
</pre>

## Board Settings File (board.ini)

* All the configuration settings for your board will be saved in a **board.ini** file.
* This file will be automatically created for you when you use the setup command **./build.sh s**
* You should not need to modify any of the build_xxx.sh files.

## Output Directory

* After each build, the files you need will be copied to an output directory named output_xxxx where xxxx is the name of your board.

<pre>
├── build_scripts
│   ├── rzg_trusted-firmware-a/
│   ├── renesas-u-boot-cip/
│   ├── output_xxxx/               <<<<<<
│   ├── build.sh
│   └── README.md
</pre>

## Getting Started

1) Install a toolchain as explained in the **Toolchain Installs.txt** document.

2) Download (clone) the source code repositories as explained in the **Repository Installs.txt** document and apply any patches that are needed.

3) Use command 's' first to **select** your board and toolchain.
<pre>
$ ./build.sh s
</pre>

4) Run the **build.sh** script with no arguments to get a list of command options. **Do not run the other build_xxx.sh file directly.** Only call build.sh.
Example:
<pre>
$ ./build.sh s             # Select your target board
$ ./build.sh               # Show a list of command options
$ ./build.sh f             # Build flash writer
$ ./build.sh u             # Build u-boot
$ ./build.sh t             # Build trusted firmware
$ ./build.sh k             # Build Linux kernel
</pre>
