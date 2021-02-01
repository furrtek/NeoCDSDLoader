Encode 16-bit signed mono 18500Hz wav files with D:\neogeo\adpcma.git\trunk
Fix the end of each bin file to avoid pop, silence bytes must be == 0x80
Concat all bin files to sfx.bin with "copy /b a+b+c... sfx.bin"
sfx.bin will used when assembling the patches
