#!/bin/sh
#
# This file was automatically generated.
#
# It can be overwritten by nios2-flash-programmer-generate or nios2-flash-programmer-gui.
#

#
# Converting SOF File: D:\Dropbox\Develop\Projects\UA3REO\FPGA\output_files\UA3REO.sof to: "..\flash/UA3REO_epcs_flash_controller_0.flash"
#
sof2flash --input="D:/Dropbox/Develop/Projects/UA3REO/FPGA/output_files/UA3REO.sof" --output="../flash/UA3REO_epcs_flash_controller_0.flash" --epcs 

#
# Programming File: "..\flash/UA3REO_epcs_flash_controller_0.flash" To Device: epcs_flash_controller_0
#
nios2-flash-programmer "../flash/UA3REO_epcs_flash_controller_0.flash" --base=0x8000 --epcs --sidp=0x9030 --id=0x12345678 --timestamp=1523222918 --device=1 --instance=0 '--cable=USB-Blaster on localhost [USB-1]' --program 

#
# Converting ELF File: D:\Dropbox\Develop\Projects\UA3REO\FPGA\software\ua3reo_nios\ua3reo_nios.elf to: "..\flash/ua3reo_nios_epcs_flash_controller_0.flash"
#
elf2flash --input="D:/Dropbox/Develop/Projects/UA3REO/FPGA/software/ua3reo_nios/ua3reo_nios.elf" --output="../flash/ua3reo_nios_epcs_flash_controller_0.flash" --epcs --after="../flash/UA3REO_epcs_flash_controller_0.flash" 

#
# Programming File: "..\flash/ua3reo_nios_epcs_flash_controller_0.flash" To Device: epcs_flash_controller_0
#
nios2-flash-programmer "../flash/ua3reo_nios_epcs_flash_controller_0.flash" --base=0x8000 --epcs --sidp=0x9030 --id=0x12345678 --timestamp=1523222918 --device=1 --instance=0 '--cable=USB-Blaster on localhost [USB-1]' --program 

