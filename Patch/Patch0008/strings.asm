; Copyright (C) 2020 Sean Gonsalves
;
; This file is part of Neo CD SD Loader.
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2, or (at your option)
; any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; see the file COPYING.  If not, write to
; the Free Software Foundation, Inc., 51 Franklin Street,
; Boston, MA 02110-1301, USA.

	PADDING OFF

; See print.asm for special char codes

StrIGMItems:
    dc.b "In-Game Menu",1,1,4
    dc.b "Cheats",1,1,5
    dc.b "Soft DIPs",1,1,7
    dc.b "Quit game",1,0,11
    dc.b "Up/Down:Select A:Go B:Exit",0

StrCheats:
    dc.b "CHEATS",1,0,11
    dc.b "A:Toggle B:Exit",0
StrNoCheats
    dc.b "CHEATS",1,0,3
    dc.b "No cheats available",1,0,4
    dc.b "for this game :(",1,0,11
    dc.b "B:Exit",0

StrSDIP:
    dc.b 1,1,0,"SOFT DIPS",1,0,11
    dc.b "L/R:Change B:Exit C:Defaults",0
StrNoSDIP:
    dc.b 1,1,0,"SOFT DIPS",1,0,3
    dc.b "No soft DIP settings",1,0,4
    dc.b "for this game :(",1,0,11
    dc.b "B:Exit",0
StrWITHOUT:
    dc.b "WITHOUT ",0
StrINFINITE:
    dc.b "INFINITE",0

FixStrLoadingBG:
    dc.b $AF,$01,[18]$16,$02,1,0,1
    dc.b $14,"Loading background",$15,1,0,2
    dc.b $14,"Please wait...    ",$15,1,0,3
    dc.b $03,[18]$17,$04,0

FixStrLoadingList:
    dc.b $AF,$01,[18]$16,$02,1,0,1
    dc.b $14,"Loading game list ",$15,1,0,2
    dc.b $14,"Please wait...    ",$15,1,0,3
    dc.b $03,[18]$17,$04,0

; Special tiles for compact "START+SELECT" text in pictos tileset
FixStrIGMShortcut:
    dc.b $AF,$A0,$AF,$A1,$AF,$A2,$AF,$A3,$AF,$A4,$AF,$A5,":In-Game Menu",0

FixStrMenu:
    dc.b "Settings",1,0,1
    dc.b "Saves menu",1,0,2
    dc.b "Store saves",1,0,3
    dc.b "Load saves",1,0,4
	dc.b "Update firmware",1,0,5
	dc.b "About",1,0,8
    dc.b $BA,":Select    ",$BB,":Exit",0

FixStrAbout:
;         0123456789ABCDEF0123456789ABCDE
;         Neo CD SD Loader    0123456789A
;                             0123456789A
    dc.b "NEO CD SD Loader    ",5,6,7,8,9,10,11,12,13,14,15,1,20,1
    dc.b 21,22,23,24,25,26,27,28,29,30,31,1,0,3
;         SN: 01234567 01234567 01234567
    dc.b "SN: ",$F0," ",$F1," ",$F2,1,0,4
	dc.b "Menu: V",$C3,"\{VERSION_MAJ}.\{VERSION_MIN}",$A0,1,0,5
	dc.b "MCU: V",$C3,$EC,".",$ED,$A0,1,0,6
	dc.b "CPLD: V",$C3,$EE,".",$EF,$A0,1,0,9
    dc.b "Thanks to:",1,0,10
    dc.b $C3,"Aergan, Bjorn, CeL, Elbarto,",1,0,11
    dc.b "GadgetUK164, Kaneda, Kuk,",1,0,12
    dc.b "Pugsy, RetroRGB, Sk8er000,",1,0,13
    dc.b "TurfMasta, Valter Custodio",$A0,1,4,15
    dc.b     "THANK YOU FOR PLAYING",0


; Store save UI layout:
; 01234567890123456789012345678901
; Store saves to SD card
;
; File name:0123456789012345
;           ^
;
; A B C D E F G H I J K L
; M N O P Q R S T U V W X
; Y Z 0 1 2 3 4 5 6 7 8 9
;   ! # % & ( ) + - = @ _
;     Exit        Save
;
; B:Backspace
; C:Upper/lower case

FixStrStoreSaveUI:
    dc.b "Store saves to SD card",1,0,3
    dc.b "File name:",1,8,10
    dc.b "Exit        Save",1,0,12
    dc.b $BB,":Backspace",1,0,13
    dc.b $BC,":Upper/lower case",0

FixStrNoFileName:
    dc.b "Please enter a file",1,0,1
    dc.b "name.",0

FixStrFileExists:
    dc.b "The save file already",1,0,1
    dc.b "exists.",1,0,2
    dc.b "Do you want to",1,0,3
    dc.b "overwrite it ?",1,0,5
    dc.b $BA,":Yes  ",$BB,":No",0

FileNameClear:
    dc.b "                ",1,0,1   ; This must match the max file name length
    dc.b "                 ",0      ; This must match the max file name length+1

KeyboardMapUC:
    dc.b "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !#%&()+-=@_",0
KeyboardMapLC:
    dc.b "abcdefghijklmnopqrstuvwxyz0123456789 !#%&()+-=@_",0

FixStrLoadSaveUI:
    dc.b "Load saves from SD card",1,0,1
    dc.b $BA,":Load ",$BB,":Exit ",$BC,":Delete",0

FixStrLoadConfirm:
    dc.b "This will overwrite",1,0,1
    dc.b "your current saves.",1,0,2
    dc.b "Are you sure to load",1,0,3
    dc.b "this save file ?",1,0,5
    dc.b $BA,":Yes  ",$BB,":No",0

FixStrDeleteConfirm:
    dc.b "Are you sure you",1,0,1
    dc.b "want to delete this",1,0,2
    dc.b "save file ?",1,0,5
    dc.b $BA,":Yes  ",$BB,":No",0

FixStrLoadOK:
    dc.b "Saves loaded OK !",1,0,2
	dc.b $BB,":Exit",0

FixStrSaveChkError:
    dc.b "Loading failed:",1,0,2
    dc.b "This save file is",1,0,3
    dc.b "corrupt.",0

; Settings
; 
; Country: <      >
; Reset country
;
; Debug DIP 1: <        >
; Debug DIP 2: <        >
; Dev mode:    <        >
;
; Idle LED:    <       >
; Loading LED: <       >
; Screen saver:<        >
; Sound effects:<        >
; Startup animation:<   >
FixStrSettings:
    dc.b "Settings",1,0,2
    dc.b "Country: ",CHAR_ARROW_LEFT,"      ",CHAR_ARROW_RIGHT,1,0,3
    dc.b "Reset country",1,0,5
    dc.b "Debug DIP 1: ",CHAR_ARROW_LEFT,"        ",CHAR_ARROW_RIGHT,1,0,6
    dc.b "Debug DIP 2: ",CHAR_ARROW_LEFT,"        ",CHAR_ARROW_RIGHT,1,0,7
    dc.b "Dev mode:    ",CHAR_ARROW_LEFT,"        ",CHAR_ARROW_RIGHT,1,0,9
    dc.b "Idle LED:    ",CHAR_ARROW_LEFT,"       ",CHAR_ARROW_RIGHT,1,0,10
    dc.b "Loading LED: ",CHAR_ARROW_LEFT,"       ",CHAR_ARROW_RIGHT,1,0,11
    dc.b "Screen saver:",CHAR_ARROW_LEFT,"        ",CHAR_ARROW_RIGHT,1,0,12
    dc.b "Sound effects:",CHAR_ARROW_LEFT,"        ",CHAR_ARROW_RIGHT,1,0,13
    dc.b "Startup animation:",CHAR_ARROW_LEFT,"   ",CHAR_ARROW_RIGHT,1,0,15
    dc.b $BA,":Select/Toggle DIP",1,0,16
    dc.b $BB,":Exit",0

FixStrRED:
    dc.b "RED    ",0
FixStrYELLOW:
    dc.b "YELLOW ",0
FixStrGREEN:
    dc.b "GREEN  ",0
FixStrCYAN:
    dc.b "CYAN   ",0
FixStrBLUE:
    dc.b "BLUE   ",0
FixStrMAGENTA:
    dc.b "MAGENTA",0
FixStrWHITE:
    dc.b "WHITE  ",0

FixStrJAPAN:
    dc.b "JAPAN ",0
FixStrUSA:
    dc.b "USA   ",0
FixStrEUROPE:
    dc.b "EUROPE",0
FixStrBRAZIL:
    dc.b "BRAZIL",0
    
FixStrBrazilWarning:
    dc.b "WARNING:",1,0,2
    dc.b "Some games were not",1,0,3
    dc.b "designed to support",1,0,4
    dc.b "the Brazil region",1,0,5
    dc.b "setting.",1,0,7
    dc.b "They may crash !",0

    IFDEF 0
FixStrROMDump:
    dc.b "Dump system ROM to",1,0,1
    dc.b "SD card ?",1,0,3
    dc.b "WARNING: Console",1,0,4
    dc.b "will reset !",1,0,6
    dc.b $BA,":OK     ",$BB,":Cancel",0
    ENDIF
    
FixStrSaveStored:
    dc.b "The save file was",1,0,1
    dc.b "successfully stored !",0

FixStrSaveLoaded:
    dc.b "The save file was",1,0,1
    dc.b "successfully loaded !",0

StrMsgBoxInvalidGame:
    dc.b "INVALID GAME DATA",1,0,2
    dc.b "Please make sure that",1,0,3
    dc.b "it's a known good",1,0,4
    dc.b "copy.",0

StrMsgBoxNoUpdate:
    dc.b "NO UPDATE FILE",1,0,2
    dc.b "Please make sure that",1,0,3
    dc.b "a valid update file",1,0,4
    dc.b "is present in the",1,0,5
    dc.b "root of the SD card.",0
    
StrMsgBoxExceedGames:
    dc.b "There are too many",1,0,1
    dc.b "games to list.",1,0,3
    dc.b "Only \{MAX_FILES} will be",1,0,4
    dc.b "shown.",0

FixStrBExit:
    dc.b $BB,":Exit",0

FixStrClear:
    dc.b "            ",0
FixStrLongwordVal:
	dc.b "",$F0,0

FixStrPress:
    dc.b $BA,":Load game",1,0,1
    dc.b $BC,":Options",1,0,2
    dc.b $BD,":CD menu",0
    
FixMapFlagJP:
    dc.b $80,$81,$82,$90,$91,$92
FixMapFlagUS:
    dc.b $83,$84,$85,$93,$94,$95
FixMapFlagEU:
    dc.b $86,$87,$88,$96,$97,$98
FixMapFlagBR:
    dc.b $89,$8A,$8B,$99,$9A,$9B
;FixStrDebugPictos:
;    dc.b $8C,$8D,$8E,$8F,1,0,1
;    dc.b $9C,$9D,$9E,$9F,0

MenuLetterList:
    dc.b 0,"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
LetterLUT:  ; For chars 64~127
    dc.b  0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15
    dc.b 16,17,18,19,20,21,22,23,24,25,26, 0, 0, 0, 0, 0
    dc.b  0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15
    dc.b 16,17,18,19,20,21,22,23,24,25,26, 0, 0, 0, 0, 0
FixStrNoFiles:
    dc.b "No files found",0
FixStrNoCard:
    dc.b "No card present",0
FixStrVersion:
    dc.b "VER \{VERSION_MAJ}.\{VERSION_MIN}",0

FixStrError:
    dc.b "NEO CD SD LOADER",1,0,2
    dc.b "Error code:",1,0,3
    dc.b $E0,"-",$E1,$E2,"-",$E3,$E4,1,8,11
    dc.b $E5," M",$E6,$E7," U",$E8,$E9,0

    IFDEF MAMEDEBUG
DEBUGFILECOUNT equ 23
GameDebugList:
    dc.b $01,0, "2020 Baseball"
    dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dc.b $01,1, "3 Count Bout"
    dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dc.b $01,2, "double dragon" ; Lower case test
    dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dc.b $01,3, "Zintrick"
    dc.b 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    dc.b 0,0,0,0
    dc.b $01,4, "Entry #0 9012345678901234",0,0,0,0,0
    dc.b $01,5, "Entry #1 9012345678901234",0,0,0,0,0
    dc.b $01,6, "Entry #2 9012345678901234",0,0,0,0,0
    dc.b $01,7, "Entry #3 9012345678901234",0,0,0,0,0
    dc.b $01,8, "Entry #4 9012345678901234",0,0,0,0,0
    dc.b $03,9, "Entry #5 A Long One 01234",0,0,0,0,0
    dc.b $01,10,"Entry #6 9012345678901234",0,0,0,0,0
    dc.b $01,11,"Entry #7 9012345678901234",0,0,0,0,0
    dc.b $01,12,"Entry #8 9012345678901234",0,0,0,0,0
    dc.b $01,13,"Entry #9 9012345678901234",0,0,0,0,0
    dc.b $01,14,"Entry #10 012345678901234",0,0,0,0,0
    dc.b $01,15,"Entry #11 012345678901234",0,0,0,0,0
    dc.b $01,16,"Entry #12 012345678901234",0,0,0,0,0
    dc.b $01,17,"Entry #13 012345678901234",0,0,0,0,0
    dc.b $01,18,"Entry #14 012345678901234",0,0,0,0,0
    dc.b $01,19,"Entry #15 012345678901234",0,0,0,0,0
    dc.b $01,20,"Entry #16 012345678901234",0,0,0,0,0
    dc.b $01,21,"Entry #17 012345678901234",0,0,0,0,0
    dc.b $01,22,"@special char entry 01234",0,0,0,0,0
    dc.b 0,0,0,0
DEBUGSAVECOUNT equ 23
SaveDebugList:
    dc.b $01,0, "Save file #0 345678901234",0,0,0,0,0
    dc.b $01,1, "Save file #1 345678901234",0,0,0,0,0
    dc.b $01,2, "Save file #2 345678901234",0,0,0,0,0
    dc.b $01,3, "Save file #3 345678901234",0,0,0,0,0
    dc.b $01,4, "Save file #4 345678901234",0,0,0,0,0
    dc.b $01,5, "Save file #5 345678901234",0,0,0,0,0
    dc.b $01,6, "Save file #6 345678901234",0,0,0,0,0
    dc.b $01,7, "Save file #7 345678901234",0,0,0,0,0
    dc.b $01,8, "Save file #8 345678901234",0,0,0,0,0
    dc.b $01,9, "Save file #9 345678901234",0,0,0,0,0
    dc.b $01,10, "Save file #10 45678901234",0,0,0,0,0
    dc.b $01,11, "Save file #11 45678901234",0,0,0,0,0
    dc.b $01,12, "Save file #12 45678901234",0,0,0,0,0
    dc.b $01,13, "Save file #13 45678901234",0,0,0,0,0
    dc.b $01,14, "Save file #14 45678901234",0,0,0,0,0
    dc.b $01,15, "Save file #15 45678901234",0,0,0,0,0
    dc.b $01,16, "Save file #16 45678901234",0,0,0,0,0
    dc.b $01,17, "Save file #17 45678901234",0,0,0,0,0
    dc.b $01,18, "Save file #18 45678901234",0,0,0,0,0
    dc.b $01,19, "Save file #19 45678901234",0,0,0,0,0
    dc.b $01,20, "Save file #20 45678901234",0,0,0,0,0
    dc.b $01,21, "Save file #21 45678901234",0,0,0,0,0
    dc.b $01,22, "Save file #22 45678901234",0,0,0,0,0
    dc.b 0,0,0,0
    ENDIF

; Debug strings
    IFDEF LOADTEST
FixStrDebugLoad:
    dc.b "Loading test",1,7,2
	dc.b "Runs:",$F0,1,7,3
	dc.b "Pass:",$F1,1,6,4
	dc.b "Wrong:",$F2,1,0,5
	dc.b "Last error @",$F3,0
	ENDIF

    IFDEF DEBUGBUILD
FixStrGameLoad:
	dc.b "A:Load #0   B:Exit",0
FixStrReqSec:
    dc.b "LOAD MMSSFF ",$F0,0
FixStrCDSecCnt:
	dc.b "CD SECTORS  ",$F0,0
FixStrDebug:
    dc.b "MCU comm test",1,0,2
	dc.b "   Next:",$F0,1,0,3
	dc.b "   Pass:",$F1,1,0,4
	dc.b "  Wrong:",$F2,1,0,5
	dc.b "Timeout:",$F3,1,0,6
	dc.b "   Last:",$F4,1,0,8
	dc.b "A:Pause   B:Exit",0
FixStrFileCount:
    dc.b "File count: ",$F0,0
FixStrCmdDumpNOK:
    dc.b "DUMP ROM NOK",0
FixStrSDV1:
    dc.b "SD OK, Type: SD/MMC",0
FixStrSDV2:
    dc.b "SD OK, Type: SDHC",0       
    ENDIF

FixStrVBL:
    dc.b "VBL:",$F0," BIOSV:",$E4,0
FixStrErrBus:
    dc.b "BUS ERROR",0
FixStrErrAddr:
    dc.b "ADDRESS ERROR",0
FixStrErrIllegal:
    dc.b "ILLEGAL INSTRUCTION",0
FixStrErrGeneric:
    dc.b "RESET3 ERROR",0
FixStrErrUninit:
    dc.b "UNINIT. VECTOR",0
FixStrWarmReset:
    dc.b "WARM RESET",0
FixStrDRegsDump:
    dc.b "D0:",$F0,1,0,1
    dc.b "D1:",$F1,1,0,2
    dc.b "D2:",$F2,1,0,3
    dc.b "D3:",$F3,1,0,4
    dc.b "D4:",$F4,1,0,5
    dc.b "D5:",$F5,1,0,6
    dc.b "D6:",$F6,1,0,7
    dc.b "D7:",$F7,0
FixStrARegsDump:
    dc.b "A0:",$F0,1,0,1
    dc.b "A1:",$F1,1,0,2
    dc.b "A2:",$F2,1,0,3
    dc.b "A3:",$F3,1,0,4
    dc.b "A4:",$F4,1,0,5
    dc.b "A5:",$F5,1,0,6
    dc.b "A6:",$F6,1,0,7
    dc.b "PC:",$F7,0
FixStrStackDump:
    dc.b " SP:",$F0,1,0,1
    dc.b " +0:",$F1," +4:",$F2,1,0,2
    dc.b " +8:",$F3," +C:",$F4,1,0,3
    dc.b "+10:",$F5,"+14:",$F6,1,0,4
    dc.b "+18:",$F7,"+1C:",$F8,1,0,5
    dc.b "+20:",$F9,"+24:",$FA,0
FixStrAtPCDump:
    dc.b "(PC):",1,0,1
    dc.b " -4:",$F0," +0:",$F1,1,0,2
    dc.b " +4:",$F2," +8:",$F3,0
