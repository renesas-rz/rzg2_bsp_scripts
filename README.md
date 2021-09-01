# RZ/G2 BSP Scripts

This repository contains helpful scripts to be used with the official Renesas BSP

## Supported BSP versions
* VLP64 v1.0.8
* VLP64 v1.0.9-RT

## Install
To install, please place this repository as a directory named 'scripts' under the yocto BSP directory.<br>
For example, we will us the VLP64 v1.0.8 BSP (rzg2\_bsp\_eva\_v108.tar.gz) that can be downloaded from renesas.com
<pre>
$ mkdir rzg2_bsp_eva_v108
$ tar xf rzg2_bsp_eva_v108.tar.gz -C rzg2_bsp_eva_v108
$ cd rzg2_bsp_eva_v108
$ git clone https://github.com/renesas-rz/rzg2_bsp_scripts  scripts
</pre>

## Setup and Configure the Yocto BSP
Below is an example of how to configure your yocto BSP before building the first time.<br>
Please note that this is intended to only be done once. If you need to change the configuration
after building, please edit the local.conf file directly.
<pre>
$ scripts/yocto_setup/setup.sh
</pre>
In the GUI menu, choose your board and then select "Save" to start the setup and configuration.

After complete, you can build your Yocto BSP.<br>
<pre>
$ source poky/oe-init-build-env
$ bitbake core-image-qt
</pre>
Please refer to the BSP 'Release Note' for more details on building and advanced configurations.

