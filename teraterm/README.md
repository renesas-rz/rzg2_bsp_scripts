# RZ Teraterm Macro

This TeraTerm macro programs the first files starting with "bl2" and "fip"
stored in the <DIR> folder in the RZ QSPI FLASH or eMMC. Both bin and srec
files can be used but take in account that bin files programming is
significantly faster than srec. The macro can optionally program the
environment variables binary (created with mkenvimage), only if the file is
present in the same folder as the binaries. The ENV_VAR_* parameters should
be potentially modified and the macro can program the parameters in the eMMC
only. Both eMMC boot partitions can be selected as target.
Assuming the files are there, launch the script and then reset the device.
You probably just need to adjust the COM port and Flash Writer srec file name
as well as selecting the device and QSPI or eMMC as target.

## Usage
To use this script:

1. Please select Flash Writer mot file, e.g.:
<pre>
; If it is parameter is set to "" then Flash Writer is not sent
; and it is expected to be already running
FLASH_WRITER = "Flash_Writer_SCIF_RZG2L_SMARC_DDR4_2GB.mot"
</pre>

2. Please modify the COM variable to the port to which the device is connected.
<pre>
; COM port 
COM = 17
</pre>

3. Please modify the DIR variable to the match the directory path which conn the required binaries.
<pre>
; Directory containing Binaries
DIR = "Binaries/"
</pre>

3. Select QSPI or eMMC as target.
<pre>
; Program QSPI or eMMC. QSPI -> 1, eMMC -> 0
QSPI_NOT_eMMC = 1
</pre>

4. Please select which boot partition to target (eMMC only)
<pre>
; When eMMC is selected, choose eMMC boot partition 1 or 2
eMMC_BOOT_PART_TARGET = 2
</pre>

5. Optional: Modify the u-boot variable binaries. Follow the instructions at this [link](https://renesas.info/wiki/RZ-G/RZ-G2L_Flash_Programming#Generating_u-boot_variables_binary) here to generate the binary. Afterwards modify using these variables.
<pre>
; Environment variables partition, 0=USER, 1=BOOT PARTITION 1, 2=BOOT PARTITION 2
ENV_VAR_PART_NUM = "2"

; Environment variables start sector
ENV_VAR_START_ADDRESS = "FB00"
</pre>

6. Set baudrate option
<pre>
; Use high baudrate (921600) instead of standard (115200)
; 0 do not use high baud
; 1 use high baud via "SUP" command (make sure Flash Writer supports it)
; 2 use high baud via additional accelerator loader (minimal_baudrate_SCIF.mot)
;   Note: this option works with RZ/G2L only
; 0 slowest, 2 fastest
USE_HIGH_BAUD = 2
</pre>

7. Select the device
<pre>
; Choose device
; 0 -> RZ/G2L, RZ/G2LC, RZ/G2UL, RZ/V2L
; 1 -> RZ/FIVE
; 2 -> RZ/G3S
DEVICE = 2
</pre>

8. Run the macro using the TeraTerm macro option.

