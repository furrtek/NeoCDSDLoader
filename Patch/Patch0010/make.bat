@echo off

echo Building for FRONT-SP1...
D:\neogeo\asw\asw main -L -quiet -D TARGET=1
..\..\tools\overlay main.p front-sp1_original.bin front-sp1_patched.bin
D:\neogeo\sgcc\flip front-sp1_patched.bin front-sp1_patched.bin
mv main.lst main-front.lst
copy main.p SPAT64DC.p

REM copy top-sp1-3_patched.bin D:\MAMEc\mame.git\mame\roms\neocd\top-sp1.bin

echo Building for TOP-SP1-2...
D:\neogeo\asw\asw main -L -quiet -D TARGET=2
..\..\tools\overlay main.p top-sp1-2_original.bin top-sp1-2_patched.bin
D:\neogeo\sgcc\flip top-sp1-2_patched.bin top-sp1-2_patched.bin
mv main.lst main1-2.lst
copy main.p SPATE10C.p
copy main.p SPATDC4C.p

copy top-sp1-2_patched.bin D:\MAMEc\mame.git\mame\roms\neocd\top-sp1.bin

echo Building for TOP-SP1-3...
D:\neogeo\asw\asw main -L -quiet -D TARGET=3
..\..\tools\overlay main.p top-sp1-3_original.bin top-sp1-3_patched.bin
D:\neogeo\sgcc\flip top-sp1-3_patched.bin top-sp1-3_patched.bin
mv main.lst main3.lst
copy main.p SPATEF2E.p

REM copy top-sp1-3_patched.bin D:\MAMEc\mame.git\mame\roms\neocd\top-sp1.bin
