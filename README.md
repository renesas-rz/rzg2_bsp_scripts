# RZ/G2 BSP Scripts

This repository contains helpful scripts to be used with the official Renesas BSPs.

## Install
To install, clone this repository under your Yocto BSP directory.
This is helpful for scripts like flash_writer_tool to automatically find the output binary files it needs for programming.

<pre>
$ cd /home/xxx/rzg2_bsp_v3.0.0
$ git clone https://github.com/renesas-rz/rzg2_bsp_scripts
</pre>

## What is included:

### build_scripts
* Scripts that allow you to build BSP software components outside of the Yocto build environment.

### docker_setup
* Instructions for setting up a docker container for build BSP images. Some BSPs required older versions of Ubuntu which you could use a docker container running in any version of Ubuntu.

### flash\_writer\_tool
* A graphical front end for the flash writer programming utility

### image_creator
* A script that will create a complete image file (sd_card.img) that can be programmed into an SD Card, eMMC or USB Flash drive.

### usb\_sd\_partition
* A SD Card & USB Flash Drive Partitioning Script
