; Copyright (C) 2020 Sean Gonsalves
;
; Neo CD SD Loader system ROM patch
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

	ORG $C0AFEE					; Replacement to avoid using DMA copy in DMAClearPalettes
	jmp DMAClearPalettes
	ORG $C0B03A                 ; Replacement to avoid using DMA copy in DMAClearPCMDRAM
	jmp DMAClearPCMDRAM
	ORG $C0BC50					; Replacement to avoid using DMA copy
	dc.l UploadFIXDMABytes
	ORG $C0BC58					; Replacement to avoid using DMA copy
	dc.l UploadZ80DMABytes
	ORG $C0BD92					; Avoid using DMA copy in UploadPRGCopyLongwords
	nop
	nop
	nop
	nop
	ORG $C0BDBE					; Avoid using DMA copy in UploadPalCopyLongwords
	nop
	nop
	nop
	nop
	ORG $C0BDDE					; Avoid using DMA copy in UploadSPRDMAWords
	nop
	nop
	nop
	nop
	;ORG $C0BE76				; Avoid using DMA copy in UploadPCMDMABytes
	;nop                        ; Leave this removed ! Was causing data corruption during IGLs
	;nop
	;nop
	;nop
	ORG $C0BF08					; Avoid using DMA copy in UploadZ80DMABytes
	nop
	nop
	nop
	nop
	ORG $C0BF26					; Avoid using DMA copy in UploadPRGDMAWords
	nop
	nop
	nop
	nop
	ORG $C0BF42					; Avoid using DMA copy in UploadPalDMAWords
	nop
	nop
	nop
	nop
	ORG $C0BF6A					; Replace RunDMADirect for UploadPRGDMAWords, UploadPalDMAWords and UploadSPRDMAWords
	jmp    RunDMADirect    ;RunDMADirectMulti
	ORG $C0BFE2
	jmp    CopyBytesToWordCPU	; Cache-to-DRAM copy speed optimization attempt to speed up PCM loads

	ORG $C0C27A
	dc.l   CDPlayerVBLProc		; Replace pointer to CDPlayerVBLProc by one to new code

	ORG $C0C3E4
	jsr    IGMVBL               ; Replace CD lid check in SYSTEM_INT1
	nop

	ORG $C0C4C4
	jsr    ConsoleStart

    ORG $C0C736
	jsr    LoadDebugDIPs		; Insertion - Called at game start
	nop

    ORG $C0C8D8
	jmp    PUPPETStuff			; Insertion - Called at startup, initializes some new stuff

    ORG $C0CAAC
	jsr    InitRAM				; Insertion - Avoid tripping in-game copy protections and set nationality
	nop
	
	ORG $C0CAE2
	nop                         ; Disable getting nationality from jumpers
	nop

	ORG $C0CC0A
	jmp    CDPLAYER_Init		; Insertion - Make call BIOSF_CDPLAYER re-init the SD card and values in RAM

    ;ORG $C0CC6A
	;nop							; Bypass CD lid check in SYSTEM_IO
	;nop

    ORG $C0CDE4
	jmp    SystemIOCustom       ; Replace CheckLid with jsr to cheat engine - Causes it to be run at each SYSTEM_IO call

	ORG $C0CF46
	jsr    ProcessZ80CDDA       ; Insertion - ReadCDDAFromZ80

    ORG $C0D554                 ; Insertion - BIOSF_CDDACMD
    jmp    BIOSF_CDDACMD

	ORG $C0E658
	rts                         ; Disables PushCDOp

    ; Disables CDC IRQ handling - Maybe not needed
	ORG $C0C2C8
	move.b #$20,$FF000F
    move.b d0,REG_DIPSW
    rte
    ; Disables CDD IRQ handling - Maybe not needed
	ORG $C0C2EA
	move.b #$10,$FF000F
    move.b d0,REG_DIPSW
    rte

	;ORG $C0E712
	;jmp    DrawProgressAnimation	; Replaces custom loading animation code with current sector display

	ORG $C0E9D2
	jmp    SetupMain			; Added to InitCDPlayerScreen (was ParseSDFiles)

	ORG $C0EA08
	bra    $C0EA9E             	; Skip CD player interface updating, just go to rts

    IFDEF MAMEDEBUG
	ORG $C0ECD2
	rts
	ELSE
	ORG $C0ECD2
	nop							; Disable CDValidFlag check
	nop
	nop
	nop
	nop                         ; Disable CD mech detection in CheckCDValid
	nop                         ; Overwrite up to movem.l ...
	nop
	nop
	nop
	nop
	nop
	nop
	ENDIF

	ORG $C0ED04
	nop							; Disable "WAIT A MOMENT" message
	nop

	ORG $C0ED2E
	nop							; Disable "WAIT A MOMENT" message (again)
	nop

	ORG $C0ED52
	jsr     LoadCDSectorFromSD	; Load first sector (CD001...)
	move.b  d0,REG_DIPSW
	bra     $C0ED76				; Skip first sector loading wait, there's no more CD :)

    ORG $C0EF0E                 ; LOGO file loading
	jsr     LoadCDSectorFromSD
	jsr     $C0BC16             ; "UploadData2"
	tst.w   $10F688				; "SectorCounter"
	beq     $C0EF42				; No more sectors to load: go to rts
	bra     $C0EF0E

	ORG $C0EF46
	nop							; Bypass CD lid check

    ORG $C0EF4E
	jmp     CDCheckDone         ; Insertion - Used to detect validity of "CD"

	ORG $C0F094                 ; "GetCDFileList"
	tst.w   $10F688				; "SectorCounter"
	beq     $C0F118				; No more sectors to load: go to rts
	jsr     LoadCDSectorFromSD
	bra     $C0F0AE

	ORG $C0F0B4					; Bypass CD lid check
	nop
	nop
	nop

	ORG $C0F162					; Disable waiting for CD Op to be processed
	rts

    IFDEF DEBUGBUILD
	ORG $C0F46C
	bra     $C0F490				; Prevent loading custom loading screens
	ORG $C0F4CA
	bra     $C0F4F2             ; Same
	ENDIF
	
	ORG $C0F1F2					; Disable waiting for CD to stop after IPL load
	jsr     LoadingFinished     ; Insertion
	nop

	ORG $C0F62C					; Disable waiting for CD to stop after BIOSF_LOADFILE
	jsr     LoadingFinished     ; Insertion
	nop

	ORG $C0CBC8
	jsr     StopCDDA
	nop
	
	ORG $C0CC54
	jsr     SYSTEM_IO_WDKICK

	ORG $C0F744
	jmp     LoadFile			; Patch original LoadFile

    ORG $C0F952
    jmp     LoadPRGVectorTable  ; Avoid using DMA in LoadPRGSectors - Double Dragon needs this

	ORG $C0FEC0
	jsr     LoadCDSectorFromSD	; Load sector in SearchForFile
	bra     $C0FED0				; Skip waiting

	ORG $C100F0					; WaitForCD
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10134					; WaitForNewSector (useless now ?)
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10178					; WaitForCD2
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10282					; WaitForLoaded
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10354
    jmp     LoadFromCD			; Patch original "LoadFromCD" (multiple calls)
    
    ORG $C10618
    nop                         ; Disable LC8951->DRAM DMA, shouldn't be used anyways
    nop
    nop

	ORG $C118EE
	rts
	;;jsr     $C0B278			; Just jump to ClearSprites ?
	;lea     $100040,a6        	; Disable CD player display and erase finger cursor from splash screen
	;move.b  #0,4(a6)			; Sprite height
	;bra     $C16CF2			; "SpriteUpdateVRAM"
	
	ORG $C16964
	moveq.l #1,d0
	move.b  d0,$764E(a5)
	move.b  d0,$7656(a5)		; Init "CDValidFlag" to 1 instead of 0 to kickstart CD checking

	ORG $C20BE0
	dc.w $4CF0					; Make the loading bar green, just for fun :]
	dc.w $5AF0
	dc.w $28F0
	dc.w $24F0
	dc.w $20D0
	
	PADDING ON

    IFDEF DEBUGBUILD
	ORG $C20C10   				; Define palette #3 during loading screen for debug text
	dc.w BLACK, WHITE, BLACK
    ENDIF
    
    ORG $C1695A
    jsr SetLEDStartup
    nop
    nop

	;ORG $C16A26
	;move.l #360,$101B2E			; Reduce splash duration (10s -> 6s)
    ORG $C16A26
    jsr     SplashInit          ; Patch up to before $C16A3A
    nop
    nop
    nop
    nop
    nop
    nop
    nop

	;ORG $C16D10
	;move.l  #$920000,$20(a6)	; Loop start X position
	ORG $C16D10
	jsr     SplashStartCurve
	nop

	;ORG $C16D78
	;move.l  #$50000,d0			; Loop curve width (oval)
	ORG $C16D78
	jsr     SplashLetterCurve

	ORG $C16F12
	move.b  d2,(4,a6)			; Sprite height bugfix :)

	;ORG $C16F66
	;dc.w 96						; X position for SD card image
	;ORG $C16F66+20
	;dc.w 88						; X position for faces image

	;ORG $C17012
	;dc.w $FFFF                  ; Disable "C" and "D" letters

	;ORG $C16F97                 ; Final letter X positions
	;dc.b $48
	;ORG $C16F97+20
	;dc.b $48+28
	;ORG $C16F97+40
	;dc.b $48+54
	;ORG $C16F97+60
	;dc.b $48+83
	;ORG $C16F97+80
	;dc.b $48+94
	;ORG $C16F97+100
	;dc.b $48+121
	;ORG $C16F97+120
	;dc.b $48+147

	;ORG $C17036
	;dc.w $F4					; "D" final X position

    ;ORG $C20080
	;BINCLUDE "gfxdata\sdcard.map"		; Replaces CD image
	ORG $C16EF4
	jsr     SplashMapSprite     ; Patch MapSprite to switch between CD and SD card sprite map
    nop                         ; Patch up to before $C16F02
    nop
    nop
    nop

    ORG $C209AE
	BINCLUDE "gfxdata\menu_font.pal"	; Replaces palette (0) used for fix
    ORG $C209CE
	BINCLUDE "gfxdata\menu_picto.pal"	; Replaces palette (1) used for fix
	; Palette (2) is used for msgbox text, leave it alone
    ORG $C20A0E
	BINCLUDE "gfxdata\menu_font_hl.pal"	; Replaces palette (3) used for fix
	;ORG $C20A4E
	;BINCLUDE "gfxdata\finger.pal"		; Replaces faces palette (5)
    ORG $C20A8E
	BINCLUDE "gfxdata\sdcard.pal" 		; Replaces CD palette (7)
    ORG $C20AAE
	BINCLUDE "gfxdata\tile_scroll_bg.pal" 	; Replaces CD player bg palette (8)
    ORG $C20ACE
	BINCLUDE "gfxdata\letter_cursor.pal" 	; Replaces buttons palette (9)
    ORG $C20AEE
	BINCLUDE "gfxdata\menu_logo.pal" 	    ; Replaces R vu-meter palette (10)
    ORG $C20B0E
	BINCLUDE "gfxdata\menu_letters.pal" 	; Replaces cursor palette (11)
    ORG $C20B2E
	BINCLUDE "gfxdata\scroll_shadow.pal" 	; Replaces buttons palette (12)

	ORG $C30000
	BINCLUDE "z80\z80.bin"
	
	ORG $C3FEB0+$1D200
	BINCLUDE "sfx\sfx.bin"

	; DataFix = $C5FEB0 (first bank), there are 8 banks
	; Bank #0: Standard SFIX 8x8 charset
	; Bank #1: Standard SFIX 8x16 charset top
	; Bank #2: Standard SFIX 8x16 charset bottom
	; Bank #3: Palette test, CD player 8x16 charset top, emptyness
	; Bank #4: CD player 8x8 charset, 8x16 charset bottom, emptyness
	; Bank #5: CD player message box tiles and Japanese chars
	; Bank #6: Loading screen box and progressbar, emptyness
	; Bank #7: Loading screen juggling monkey

    ORG $C5FEB0                                ; Overwrite bank #0: $C5FEB0+(0*$2000)=$C5FEB0
FixBankZero:
	BINCLUDE "gfxdata\fix_alphabet_bank.bin"   ; Replace with un-shittized standard font

	ORG $C69EB0 				               ; Overwrite bank #5: $C5FEB0+(5*$2000)=$C69EB0
	BINCLUDE "gfxdata\fix_menu_bank.bin"	   ; Replace with menu font & pictos

    IFDEF DEBUGBUILD
	ORG $C6DEB0 				               ; Overwrite bank #7: $C5FEB0+(7*$2000)=$C6DEB0
	BINCLUDE "gfxdata\fix_alphabet_bank.bin"   ; Replace with un-shittized standard font
    ENDIF

	; DataSprites = $C6FEB0
    ORG $C6FEB0
	BINCLUDE "gfxdata\sprites.bin"

