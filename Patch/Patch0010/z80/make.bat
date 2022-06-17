del object.o
"D:\Program Files\WLA-DX\wla-z80.exe" -o z80.asm object.o
echo [objects]>linkfile
echo object.o>>linkfile
"D:\Program Files\WLA-DX\wlalink.exe" -drv linkfile z80.bin
del linkfile
del object.o
REM romwak /p cphd.m1 cphd.m1 64 0
REM romwak /p m1.z80 m1.z80 64 0
REM pause