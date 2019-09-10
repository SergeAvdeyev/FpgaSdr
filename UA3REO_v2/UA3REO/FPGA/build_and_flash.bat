SET PATH=%PATH%;C:\intelFPGA\17.1\nios2eds\bin;C:\intelFPGA\17.1\quartus\bin64;C:\intelFPGA\17.1\nios2eds\bin\gnu\H-x86_64-mingw32\bin
sof2flash --input="output_files\UA3REO.sof" --output="output_files\hwimage.flash" --epcs --verbose --debug 
elf2flash --input="software\ua3reo_nios\ua3reo_nios.elf" --output="output_files\swimage.flash" --epcs --after="output_files\hwimage.flash" --verbose --debug 
nios2-elf-objcopy --input-target srec --output-target ihex output_files\hwimage.flash output_files\UA3REO.hex
nios2-flash-programmer "output_files\hwimage.flash" --base=0x11000 --epcs --accept-bad-sysid --device=1 --instance=0 --cable=1 --program --verbose 
nios2-flash-programmer "output_files\swimage.flash" --base=0x11000 --epcs --accept-bad-sysid --device=1 --instance=0 --cable=1 --program --verbose --go
pause
