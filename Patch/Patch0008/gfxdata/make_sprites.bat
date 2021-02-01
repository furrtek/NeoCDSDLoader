D:\neogeo\gfx\tools\gfxcc -optim 0 ..\gfx\tile_scroll_bg.bmp -o tile_scroll_bg.spr -o tile_scroll_bg.pal
D:\neogeo\gfx\tools\gfxcc -optim 0 ..\gfx\menu_logo.bmp -o menu_logo.spr -o menu_logo.pal
D:\neogeo\gfx\tools\gfxcc -optim 0 ..\gfx\letter_cursor.bmp -o letter_cursor.spr -o letter_cursor.pal
D:\neogeo\gfx\tools\gfxcc -optim 0 ..\gfx\menu_letters.bmp -o menu_letters.spr -o menu_letters.pal
D:\neogeo\gfx\tools\gfxcc -optim 0 ..\gfx\ssaver_sprite.bmp -o ssaver_sprite.spr
D:\neogeo\gfx\tools\gfxcc -optim 0 ..\gfx\sdcard.bmp -o sdcard.spr -o sdcard.pal

copy /b sdcard.spr+tile_scroll_bg.spr+menu_logo.spr+pad2.spr+letter_cursor.spr+menu_letters.spr+ssaver_sprite.spr sprites.bin

pause