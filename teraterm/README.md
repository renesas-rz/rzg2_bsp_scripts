# RZ/G2L Teraterm Macro

This TeraTerm macro programs the first files starting with "bl2" and "fip" stored 
in the same folder in the RZ/G2L QSPI FLASH or eMMC. Both bin and srec files can be
used but take in account that bin files programming is significantly faster than srec.
The macro can optionally program the environment variables binary (created with mkenvimage),
only if the file is present in the same folder as the binaries. The ENV_VAR_* parameters should
be potentially modified and the macro can program the parameters in the eMMC only. Assuming the
files are there, launch the script and then reset the device.
You probably just need to adjust the COM port and Flash Writer srec file name
as well as select QSPI or eMMC as target


## Usage
To use this script:

1. Please modify the COM variable to the port to which the device is connected.
<pre>
; COM port 
COM = 17
</pre>

2. Please modify the DIR variable to the match the directory path which conn the required binaries.
<pre>
; Directory containing Binaries
DIR = "Binaries/"
</pre>

3. Select QSPI or eMMC as target.
<pre>
; Program QSPI or eMMC. QSPI -> 1, eMMC -> 0
QSPI_NOT_eMMC = 1
</pre>

4. Optional: Modify the u-boot variable binaries. Follow the instructions at this [link](https://renesas.info/wiki/RZ-G/RZ-G2L_Flash_Programming#Generating_u-boot_variables_binary) here to generate the binary. Afterwards modify using these variables.
<pre>
; Environment variables partition, 0=USER, 1=BOOT PARTITION 1, 2=BOOT PARTITION 2
ENV_VAR_PART_NUM = "2"

; Environment variables start sector
ENV_VAR_START_ADDRESS = "FB00"
</pre>

5. Run the macro using the TeraTerm macro option.

