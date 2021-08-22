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

SetupMain:
	; Palettes should already be set up correctly by InstallDataDRAM
	; CDPPalData is patched with the new palettes

    move.w  #SCREEN_IDLE,CurrentScreen

	move.b  #$FF,REG_Z80RST		; Copied from original routine

    move.b  d0,REG_NOSHADOW     ; Required after exiting from Ironclad

	move.w  #$0100,REG_LSPCMODE ; Set auto-animation speed

	move.b  #1,REG_ENVIDEO
	move.b  #0,REG_DISBLSPR
	move.b  #0,REG_DISBLFIX

    moveq.l #0,d0
    move.b  d0,IsInIGM
	move.b  d0,FileCursor
	move.b  d0,FileCursorPrev
	move.b  d0,MenuShift
	move.b  d0,LetterCursor
	move.b  d0,CurrentMsgBox
	move.b  d0,IsLoading
	move.l  d0,ActiveLetters
    move.w  d0,TotalFileCount
    move.w  d0,UITemp           ; Used as delay timer to start scrolling file names
	move.b  d0,FlagSelectStart
	st.b    PollStatus

	; RefreshFlags bits use in ui_main:
	; 0: Redraw file list
	; 1: Redraw letter cursor
	; 2: Redraw file cursor
	; 3: Redraw current file name for scrolling
	; 4: Show msgbox about game count exceeding MAX_FILES
	; 5: -
	; 6: -
	; 7: -
    move.b  #%00000111,RefreshFlags

    jsr     WaitVBL                 ; Wait for vblank to hide dirty things

    lea     IGMPalettes,a0
	lea     (2*16*2)+PALETTES,a1	; Set up palette 2 for msgbox text
    jsr     CopyPalette

    jsr     ClearFix

    jsr     ClearFileList
    jsr     ClearMainSprites

    IFDEF MAMEDEBUG
    jsr     DebugSetupMain
	bra     .setup_interface
    ENDIF

    jsr     GetMCUStatus

	btst.b  #7,MCUStatus
	beq     .setup_interface   ; SD card absent, skip loading game list

    IFNDEF MAMEDEBUG
	jsr     InitSD
	bcs     .setup_interface   ; SD card error, skip loading game list

    ; Check if there's already a custom bg loaded
    tst.b   CustomBGLoaded
    beq     .notloaded
    move.w  CustomBGBackdrop,BACKDROP   ; Restore custom BG backdrop color in case we exited from screen saver
    bra     .nocustombg
.notloaded:
	; Check if there's a custom bg file available
    move.b  #BG_CODE,MCUCmdParams
    MCUCMD  MCU_CMD_SELECTGAME
    bcc     .notimeouta
    jsr     DispErrorTimeout
    bra     .nocustombg
.notimeouta:
    jsr     MCURead4Words
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    beq     .nocustombg
    jsr     LoadCustomBG
.nocustombg:

    move.w  #$2000,FixWriteConfig   ; Palette #2 bank 0
    lea     FixStrLoadingList,a0
	move.w  #FIXMAP+13+(10*32),d0
	jsr     WriteFix

    ; Ask MCU for game list
    clr.l   MCUCmdParams
    MCUCMD  MCU_CMD_GETGAMES
    bcc     .notimeoutc
    jsr     DispErrorTimeout
    bra     .setup_interface
.notimeoutc:
    jsr     MCURead4Words
    jsr     CheckACK
    bcs     .setup_interface
    ; Ok, get file count
    moveq.l #0,d0
    move.b  MCUReplyBuffer+1,d0
    cmp.b   #EXCEED_CODE,d0
    bne     .noexceed
    ; Available games count exceed MAX_FILES
    ; Cap to MAX_FILES and warn user with msgbox after listing
    move.b  #MAX_FILES,d0
    bset.b  #4,RefreshFlags     ; Request warning msgbox
.noexceed:
    move.w  d0,TotalFileCount

    ; Retrieve file names
    move.w  TotalFileCount,d6
    tst.w   d6
    beq     .setup_interface    ; Skip if no files
    lea     FileList,a1    
.listfiles:
    move.w  #16,d3              ; 1+30+1, ID.b + string + /0 (no /0 if LFN)
    jsr     MCURead4WordsMult

    lea     MCUReplyBuffer,a0
    move.w  #$0100,d0           ; "Entry used" flag
    tst.b   MAX_FILENAME+1(a0)
    beq     .shortname
    ori.w   #$0200,d0           ; Add "long filename" flag
.shortname:
    move.b  (a0)+,d0
    move.w  d0,(a1)+            ; File index + flags

    movea.l a1,a2
    moveq.l #MAX_FILENAME-1,d7
.cp:
    move.b  (a0)+,(a2)+         ; Copy file name, cap to MAX_FILENAME chars
	subq.b  #1,d7
	bne     .cp
    move.b  #0,(a2)+            ; Force last char to 0

    lea     32-2(a1),a1

	subq.w  #1,d6
	bne     .listfiles

    move.b  #0,(a1)+            ; Terminate
    ENDIF

.setup_interface:

    jsr     ClearFix            ; Erase any "Please wait" messages

    ; Prepare ActiveLetters
    moveq.l #0,d3
    move.w  TotalFileCount,d7
    tst.w   d7
    beq     .noactive           ; Skip if no files
    lea     FileList,a0
    lea     LetterLUT,a1
    move.l  ActiveLetters,d2
    moveq.l #0,d0
.setupactive
    move.b  #0,d1
    move.b  2(a0),d0            ; Get game's name first letter
    cmp.b   #'@',d0
    blo     .notletter
    cmp.b   #'z',d0
    bhi     .notletter
    subi.b  #64,d0
    move.b  0(a1,d0),d1         ; Look up corresponding ActiveLetters bit position
.notletter:
    bset.l  d1,d2
    bne     .alreadyset         ; BSET does a BTST before setting the bit
    addq.b  #1,d3
.alreadyset:
    lea     32(a0),a0
    subq.w  #1,d7
    bne     .setupactive
    move.l  d2,ActiveLetters
.noactive:
    move.b  d3,LetterCount
    
    ; Wait for vblank to hide dirty things
    jsr     WaitVBL

    tst.b   CustomBGLoaded
    beq     .defaultbg
	; Setup sprites for custom background
	move.w  #1,REG_VRAMMOD
	move.w  #256,d0                 ; First tile number
	move.w  #SCB1+(SPR_BG*2*32),d2	; Tile map
	move.w  #20,d7					; 20 sprites wide
.setup_c_map:
	move.w  d2,REG_VRAMADDR
	move.w  #14,d6					; 14 tiles high
.setup_c_tiles:
	nop
	move.w  d0,REG_VRAMRW	     	; Tile number
	addq.w  #1,d0
	nop
	move.w  #$1000,REG_VRAMRW		; Palette #16
	subq.w  #1,d6
	bne     .setup_c_tiles
	addi.w  #2*32,d2				; Next sprite
	subq.w  #1,d7
	bne     .setup_c_map
	bra     .bgdone
.defaultbg:
	; Setup sprites for default background

	move.w  #1,REG_VRAMMOD
	lea     bg_pal_map,a0
	move.w  #SCB1+(SPR_BG*2*32),d2	; Tile map
	move.w  #20,d7					; 20 sprites wide
.setup_d_map:
	move.w  d2,REG_VRAMADDR
	move.w  #16,d6					; 16 tiles high
.setup_d_tiles:
	nop
	move.w  #$0040,REG_VRAMRW		; Tile number
	move.b  (a0)+,d0
	lsl.w   #8,d0
    ori.w   #$0008,d0
    move.w  d0,REG_VRAMRW		    ; Palette + 3bit auto-animation
	subq.w  #1,d6
	bne     .setup_d_tiles
	addi.w  #2*32,d2				; Next sprite
	subq.w  #1,d7
	bne     .setup_d_map
.bgdone:

	move.w  #SPR_BG,d0
	move.w  #$0FFF,d1				; No shrink
	move.w  #20,d7					; 20 sprites wide
	jsr     SetSprZ
	move.w  #SPR_BG,d0
	move.w  #((496-0)<<7)+16,d1		; Top Y, 16 tiles high
	move.w  #20,d7					; 20 sprites wide
	jsr     SetSprY
	move.w  #SPR_BG,d0
	move.w  #0,d1					; Left X
	move.w  #20,d7					; 20 sprites wide
	jsr     SetSprX

	; Setup sprites for logo
	lea     map_logo,a0
	move.w  #SPR_LOGO,d3
	jsr     AutoMap
	move.w  #SPR_LOGO,d0
	move.w  #$0FFF,d1
	move.w  #7,d7
	jsr     SetSprZ
	move.w  #SPR_LOGO,d0
	move.w  #((496-14)<<7)+2,d1
	move.w  #7,d7
	jsr     SetSprY
	move.w  #SPR_LOGO,d0
	move.w  #32,d1
	move.w  #7,d7
	jsr     SetSprX
	
	; Setup sprites for first letters
	move.b  #27,d7
	move.w  #1,REG_VRAMMOD
	move.w  #SPR_LETTERS*2*32,d0
	move.l  ActiveLetters,d1
	move.w  #$0060,d2  ; Top tile for '#'
.setletters:
    lsr.l   #1,d1
    bcs     .enabled
	addq.w  #2,d2      ; Skip 2 tiles
	subq.b  #1,d7
	bne     .setletters
	bra     .setdone
.enabled:
    move.w  d0,REG_VRAMADDR
	nop
	nop
	move.w  d2,REG_VRAMRW
	nop
	addq.w  #1,d2
	move.w  #$0B00,REG_VRAMRW 		; Palette
	nop
	addi.w  #2*32,d0
	move.w  d2,REG_VRAMRW
	nop
	addq.w  #1,d2
	move.w  #$0B00,REG_VRAMRW
    bra     .setletters
.setdone:

	move.b  LetterCount,d7
	beq     .noletters
    move.w  #SPR_LETTERS,d0
	move.w  #$0FFF,d1
	moveq.l #0,d7
	move.b  LetterCount,d7
	jsr     SetSprZ
	move.w  #SPR_LETTERS,d0

	moveq.l #0,d7
	move.b  LetterCount,d7
	move.w  #SPR_LETTERS+$8200,REG_VRAMADDR
	move.w  #((496-46)<<7)+2,d0
.setlettersy
	move.w  d0,REG_VRAMRW
	nop
	subq.b  #1,d7
	bne     .setlettersy

	moveq.l #0,d7
	move.b  LetterCount,d7
	; Horizontally align
	moveq.l #0,d0
	move.b  d7,d0
	mulu.w  #600,d0
	lsr.l   #6,d0      ; .6 Fixed point to int
    addi.w  #-320,d0   ; Display width
    neg     d0
    lsr.w   #1,d0      ; /2
	move.w  d0,d1
    lsl.w   #6,d1      ; Int to .6 fixed point
    move.w  d1,LettersXPos
    lsl.w   #7,d0      ; Position for VRAM X data
	move.w  #SPR_LETTERS+$8400,REG_VRAMADDR
.setlettersx
	move.w  d0,REG_VRAMRW
	addi.w  #600<<1,d0
	subq.b  #1,d7
	bne     .setlettersx

    ; Restore cursors to last valid ones
	tst.b   CursorsValid
	beq     .invalid
	move.b  LastFileCursor,FileCursor
	move.b  LastMenuShift,MenuShift
	move.b  LastLetterCursor,LetterCursor
.invalid:
	jsr     SetLetterCursorX

	; Setup sprites for left/right arrows
	lea     map_arrows,a0
	move.w  #SPR_ARROW_L,d3
	jsr     AutoMap

	move.w  #SPR_ARROW_L,d0
	move.w  #$0FFF,d1
	move.w  #2,d7
	jsr     SetSprZ

	move.w  #SPR_ARROW_L,d0
	move.w  #((496-46)<<7)+2,d1
	move.w  #1,d7
	jsr     SetSprY

	move.w  #SPR_ARROW_R,d0
	move.w  #((496-46)<<7)+2,d1
	move.w  #1,d7
	jsr     SetSprY

    move.w  LettersXPos,d1
    subi.w  #600,d1
    lsr.w   #6,d1           ; Remove fractional part
	move.w  #SPR_ARROW_L,d0
	move.w  #1,d7
	jsr     SetSprX

    moveq.l #0,d1
	move.b  LetterCount,d1
    mulu    #600,d1
    add.w   LettersXPos,d1
    lsr.w   #6,d1           ; Remove fractional part
	move.w  #SPR_ARROW_R,d0
	move.w  #1,d7
	jsr     SetSprX
.noletters:

	; Setup sprite for letter cursor
	move.w  #SPR_LETTER_CUR*2*32,REG_VRAMADDR	; Sprite map
	nop
	nop
	move.w  #TILE_CURSOR,REG_VRAMRW	; Tile #
	nop
	nop
	move.w  #$0904,REG_VRAMRW 		; Palette and auto-anim
	nop
	nop
	move.w  #TILE_CURSOR+4,REG_VRAMRW	; Tile #
	nop
	nop
	move.w  #$0904,REG_VRAMRW 		; Palette and auto-anim
	move.w  #SPR_LETTER_CUR,d0
	move.w  #$0FFF,d1
	move.w  #1,d7
	jsr     SetSprZ
	move.w  #SPR_LETTER_CUR,d0
	move.w  #((496-47)<<7)+2,d1
	move.w  #1,d7
	jsr     SetSprY
	; X position will be set during next v-blank

	; Draw button press instructions
	move.w  #$0500,FixWriteConfig
	move.w  #FIXMAP+4+(20*32),d0
	IF TARGET==1
    lea     FixStrPressFront,a0
	ELSE
    lea     FixStrPressTop,a0
	ENDIF
	jsr     WriteFix

	; Draw nationality flag
	lea     FlagLUT,a0
	moveq.l #0,d0
	move.b  SettingCountry,d0
	add.w   d0,d0
	add.w   d0,d0
	movea.l (a0,d0),a0
	move.w  #$1500,d0
	move.w  #FIXMAP+4+(34*32),REG_VRAMADDR
	move.w  #32,REG_VRAMMOD    ; 20
	nop                        ; 4
	nop                        ; 4
	move.b  (a0)+,d0           ; 8
	move.w  d0,REG_VRAMRW      ; 16
	nop                        ; 4
	nop                        ; 4
	move.b  (a0)+,d0           ; 8
	move.w  d0,REG_VRAMRW      ; 16
	nop
	nop
	move.b  (a0)+,d0
	move.w  d0,REG_VRAMRW
	nop
	nop
	move.w  #FIXMAP+5+(34*32),REG_VRAMADDR
	nop
	nop
	move.b  (a0)+,d0
	move.w  d0,REG_VRAMRW
	nop
	nop
	move.b  (a0)+,d0
	move.w  d0,REG_VRAMRW
	nop
	nop
	move.b  (a0),d0
	move.w  d0,REG_VRAMRW

	; Draw IGM shortcut reminder
    lea     FixStrIGMShortcut,a0
	move.w  #FIXMAP+27+(4*32),d0
	jsr     WriteFix

	; Draw patch version
    lea     FixStrVersion,a0
	move.w  #FIXMAP+27+(29*32),d0
	jsr     WriteFix
                                     
    jsr     BuildFileList

	move.w  #SCREEN_MAIN,CurrentScreen
	rts


; Sets LetterCursorX (sprite position) according to LetterCursor (letter index)
SetLetterCursorX:
    moveq.l #0,d0
    move.b  LetterCursor,d0
    mulu    #600,d0
    add.w   LettersXPos,d0
	move.w  d0,LetterCursorX
	rts


BuildFileList:
    ; Build file list for a given letter

	clr.b   LetterGameCount     ; Reset entry count

    tst.b   LetterCount
    beq     .done
	; Look up selected letter
	moveq.l #0,d2
	move.b  LetterCursor,d0
	move.l  ActiveLetters,d1
	;move.l  #27,d7
.countbits:
    lsr.l   #1,d1
    bcc     .zero               ; Unused letter
    tst.b   d0
    beq     .found
    subq.b  #1,d0
.zero:
    addq.b  #1,d2
    bra     .countbits
.found:
	lea     MenuLetterList,a0
	move.b  0(a0,d2),d1

	; Search game names starting with selected letter and build index list
	moveq.l #MAX_MENU_LIST,d7
	moveq.l #0,d6
	lea     LetterLUT,a0
	lea     FileList,a1
	lea     MenuIndexList,a2
	moveq.l #0,d0
.disp:
	tst.b   (a1)+
	beq     .done               ; Reached last file in GameList
	addq.l  #1,a1               ; Skip file number byte for now
	tst.b   d1
	bne     .letter
	; Match any number
	cmp.b   #'9',(a1)
	bhi     .skip
	bra     .number
.letter:
    ; Match letter, case insensitive
    move.b  (a1),d0
    cmp.b   #'@',d0             ; Check if this is really a letter
    blo     .skip
    cmp.b   #'z',d0
    bhi     .skip
    subi.b  #'@',d0
	move.b  0(a0,d0),d0         ; Convert to lower case
	addi.b  #'@',d0
	cmp.b   d0,d1
	bne     .skip
.number:
	; Entry matches !
    move.b  d6,(a2)+            ; Add index to list
	addq.b  #1,LetterGameCount

	subq.w  #1,d7
	beq     .done			    ; Max files per letter reached, stop here
.skip:

	addq.w  #1,d6
	cmp.w   #MAX_FILES,d6
    beq     .done               ; Reached end of GameList

    lea     30(a1),a1			; Next entry (32-2)
	bra     .disp
.done:

	bset.b  #0,RefreshFlags 	; File list needs refresh
	bset.b  #1,RefreshFlags 	; Letter cursor needs refresh
	tst.b   CursorsValid
	bne     .keepcursor
	clr.b   FileCursor          ; Reset file cursor to top
	clr.b   MenuShift
	bset.b  #2,RefreshFlags     ; File cursor needs refresh
	rts
.keepcursor:
    clr.b   CursorsValid
    rts


FlagLUT:
    dc.l    FixMapFlagJP
    dc.l    FixMapFlagUS
    dc.l    FixMapFlagEU
    dc.l    FixMapFlagBR


map_arrows:
    dc.w $0101
    dc.w $B096, $B097
    dc.w $B098, $B099
