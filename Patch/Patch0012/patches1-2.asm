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

CheckCDValid        equ $C0EB96
CDCheckDoneEnd      equ $C0EE4E
JTFileLoaders       equ $C0F60A
MainLoopEnd         equ $C0CB7C
StartGameCD         equ $C0EB44
CDPControllerStuff  equ $C0E9A0
ProcessCDDACmds     equ $C0D022
MemCardMenu         equ $C1404E
ReadCDDAFromZ80End  equ $C0CF1A
SpriteInitData      equ $C16DF8
CDPPalData          equ $C209AE
RegionPatch         equ $C0CA40 ; "not.b d1" instruction to patch in InitRAM original system ROM routine
DrawProgressAnimation equ $C0E712

    ORG $C0AF6A					; Replacement to avoid using DMA copy in DMAClearPalettes
	jmp DMAClearPalettes
	ORG $C0AFB6                 ; Replacement to avoid using DMA copy in DMAClearPCMDRAM
	jmp DMAClearPCMDRAM
	ORG $C0BBCC					; Replacement to avoid using DMA copy
	dc.l UploadDMABytes
	ORG $C0BBD4					; Replacement to avoid using DMA copy
	dc.l UploadDMABytes
	ORG $C0BD0E					; Avoid using DMA copy in UploadPRGCopyLongwords
	nop
	nop
	nop
	nop
	ORG $C0BD3A					; Avoid using DMA copy in UploadPalCopyLongwords
	nop
	nop
	nop
	nop
	ORG $C0BD5A					; Avoid using DMA copy in UploadSPRDMAWords
	nop
	nop
	nop
	nop
	;ORG $C0BDF2				; Avoid using DMA copy in UploadPCMDMABytes
	;nop                        ; Leave this removed ! Was causing data corruption during IGLs
	;nop
	;nop
	;nop
	ORG $C0BE84					; Avoid using DMA copy in UploadZ80DMABytes
	nop
	nop
	nop
	nop
	ORG $C0BEA2					; Avoid using DMA copy in UploadPRGDMAWords
	nop
	nop
	nop
	nop
	ORG $C0BEBE					; Avoid using DMA copy in UploadPalDMAWords
	nop
	nop
	nop
	nop
	ORG $C0BEE6					; Replace RunDMADirect for UploadPRGDMAWords, UploadPalDMAWords and UploadSPRDMAWords
	jmp    RunDMADirect         ;RunDMADirectMulti
    ORG $C0BF5E
	jmp    CopyBytesToWordCPU	; Cache-to-DRAM copy speed optimization attempt to speed up PCM loads

	ORG $C0C1F6
	dc.l   CDPlayerVBLProc		; Replace pointer to CDPlayerVBLProc by one to new code

	ORG $C0C360
	jsr    IGMVBL               ; Replace CD lid check in SYSTEM_INT1
	nop

	; ADDED in 0.11
	ORG $C0C65C
	jsr    CountryNoBrazil		; Force soft DIPs init to Japan region if region is set to Brazil
	nop

	ORG $C0C440
	jsr    ConsoleStart

    ORG $C0C6B2
	jsr    LoadDebugDIPs		; Insertion - Called at game start
	nop
	
    ORG $C0C586
	jmp    InitSoftDIPs			; Insertion - Called just before game start in ReadCDDAFlagSDIPs

    ORG $C0C854
	jmp    PUPPETStuff			; Insertion - Called at startup, initializes some new stuff

    ORG $C0CA28
	jsr    InitRAM				; Insertion - Avoid tripping in-game copy protections and set nationality
	nop

	ORG $C0CA46
	nop                         ; Disable getting nationality from jumpers
	nop

	ORG $C0CB72
	jmp    CDPLAYER_Init		; Insertion - Make call SYS_CDPLAYER re-init the SD card and values in RAM

    ;ORG $C0CBD2
	;nop						; Bypass CD lid check in SYSTEM_IO
	;nop

    ORG $C0CD4C
	jmp    SystemIOCustom       ; Replace CheckLid with jsr to cheat engine - Causes it to be run at each SYSTEM_IO call

	ORG $C0CEAE
	jmp    ProcessZ80CDDA       ; Insertion - ReadCDDAFromZ80

    ORG $C0D4BC                 ; Insertion - BIOSF_CDDACMD
    jmp    BIOSF_CDDACMD

	ORG $C0E53A
	rts                         ; Disables PushCDOp

    ; Disables CDC IRQ handling - Maybe not needed
	ORG $C0C244
	move.b #$20,$FF000F
    move.b d0,REG_DIPSW
    rte
    ; Disables CDD IRQ handling - Maybe not needed
	ORG $C0C266
	move.b #$10,$FF000F
    move.b d0,REG_DIPSW
    rte

	;ORG $C0E712
	;jmp    DrawProgressAnimation	; Replaces custom loading animation code with current sector display

	ORG $C0E89C
	jmp    SetupMain			; Added to InitCDPlayerScreen (was ParseSDFiles)

	ORG $C0E8D2
	bra    $C0E968             	; Skip CD player interface updating, just go to rts - Not needed anymore ?

    IFDEF MAMEDEBUG
	ORG $C0EB96
	rts
	ELSE
	ORG $C0EB96
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

	ORG $C0EBC8
	nop							; Disable "WAIT A MOMENT" message
	nop

	ORG $C0EBF2
	nop							; Disable "WAIT A MOMENT" message (again)
	nop

	ORG $C0EC16
	jsr     LoadCDSectorFromSD	; Load first sector (CD001...)
	move.b  d0,REG_DIPSW
	bra     $C0EC3A				; Skip first sector loading wait, there's no more CD :)

	; ADDED in 0.11
	ORG $C0ED8C
	jsr     CountryNoBrazil     ; Force LOGO file choice to Japan if region set to Brazil
	nop

	ORG $C0EDCC                 ; LOGO file loading
	jsr     LoadCDSectorFromSD
	jsr     $C0BB92             ; "UploadData2"
	tst.w   $10F688				; "SectorCounter"
	beq     $C0EE00				; No more sectors to load: go to rts
	bra     $C0EDCC

	ORG $C0EE04
	nop							; Bypass CD lid check

    ORG $C0EE0C
	jmp     CDCheckDone         ; Insertion - Used to detect validity of "CD"

	ORG $C0EF4C                 ; "GetCDFileList"
	tst.w   $10F688				; "SectorCounter"
	beq     $C0EFD0				; No more sectors to load: go to rts
	jsr     LoadCDSectorFromSD
	bra     $C0EF66

	ORG $C0EF6C					; Bypass CD lid check
	nop
	nop
	nop

	ORG $C0F022					; Disable waiting for CD Op to be processed
	rts

    IFDEF DEBUGBUILD
	ORG $C0F324
	bra     $C0F348				; Prevent loading custom loading screens
	ORG $C0F382
	bra     $C0F3AA             ; Same
	ENDIF
	
	ORG $C0F0AA					; Disable waiting for CD to stop after IPL load
	jsr     LoadingFinished     ; Insertion
	nop

	ORG $C0F4E4					; Disable waiting for CD to stop after BIOSF_LOADFILE
	jsr     LoadingFinished     ; Insertion
	nop

	ORG $C0CB30
	jsr     StopCDDA
	nop

	ORG $C0CBBC
	jsr     SYSTEM_IO_WDKICK

	ORG $C0F5FC
	jmp     LoadFile			; Patch original LoadFile

    ;ORG $C0F80A                ; TESTING: Called in LoadPRGSectorsPatch
    ;jmp     LoadPRGVectorTable  ; Avoid using DMA in LoadPRGSectors - Double Dragon needs this

    ORG $C0F7B0 ;C0F784
    jmp     LoadPRGSectorsPatch ; Direct copy
    ORG $C0F9BE ;C0F96C
    jmp     LoadSPRSectorsPatch ; Direct copy
    ORG $C0FA60
    move.w  #$7FF,d0			; Fix original system ROM Z80 RAM clearing bug - Thanks Justin !
    ORG $C0FB28 ;C0FAD8
    jmp     LoadPCMSectorsPatch ; Direct copy

	ORG $C0FD78
	jsr     LoadCDSectorFromSD	; Load sector in SearchForFile
	bra     $C0FD88				; Skip waiting

	ORG $C0FFA2					; WaitForCD
	jsr     LoadCDSectorFromSD
	rts

	ORG $C0FFE6					; WaitForNewSector (useless now ?)
	jsr     LoadCDSectorFromSD
	rts

	ORG $C1002A					; WaitForCD2
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10134					; WaitForLoaded
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10206
    jmp     LoadFromCD			; Patch original "LoadFromCD" (multiple calls)

    ORG $C104CA
    nop                         ; Disable LC8951->DRAM DMA, shouldn't be used anyways
    nop
    nop

	ORG $C11788
	rts
	;;jsr     $C0B278			; Just jump to ClearSprites ?
	;lea     $100040,a6        	; Disable CD player display and erase finger cursor from splash screen
	;move.b  #0,4(a6)			; Sprite height
	;bra     $C16CF2			; "SpriteUpdateVRAM"
	
	ORG $C167FE
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

    ORG $C167F4
    jsr SetLEDStartup
    nop
    nop


    ORG $C168C0
    jsr     SplashInit          ; Patch up to before $C168D4
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    
    ORG $C16BAA
	jsr     SplashStartCurve
	nop

	ORG $C16C12
	jsr     SplashLetterCurve

	ORG $C16DAC
	move.b  d2,(4,a6)			; Sprite height bugfix :)

	ORG $C16D8E
	jsr     SplashMapSprite     ; Patch MapSprite to switch between CD and SD card sprite map
    nop                         ; Patch up to before $C16D9C
    nop
    nop
    nop

    ORG $C0C642
    jmp     InstallPalettes


    ORG $C209AE
	BINCLUDE "gfxdata\menu_font.pal"	; Replaces palette (0) used for fix
    ORG $C209CE
	BINCLUDE "gfxdata\menu_picto.pal"	; Replaces palette (1) used for fix
	; Palette (2) is used for msgbox text, leave it alone
    ORG $C20A0E
	BINCLUDE "gfxdata\menu_font_hl.pal"	; Replaces palette (3) used for fix
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

FixSizeCheckA:
    IF FixSizeCheckA > $C5FEB0+$2000
        FATAL "\aFix file #1 is larger than 8kB !"
    ENDIF

	ORG $C69EB0 				               ; Overwrite bank #5: $C5FEB0+(5*$2000)=$C69EB0
	BINCLUDE "gfxdata\fix_menu_bank.bin"	   ; Replace with menu font & pictos

FixSizeCheckB:
    IF FixSizeCheckB > $C69EB0+$2000
        FATAL "\aFix file #2 is larger than 8kB !"
    ENDIF

    IFDEF DEBUGBUILD
	ORG $C6DEB0 				               ; Overwrite bank #7: $C5FEB0+(7*$2000)=$C6DEB0
	BINCLUDE "gfxdata\fix_alphabet_bank.bin"   ; Replace with un-shittized standard font
    ENDIF

	; DataSprites = $C6FEB0
    ORG $C6FEB0
	BINCLUDE "gfxdata\sprites.bin"
SpriteDataEnd:
    IF SpriteDataEnd > $C6FEB0+(4*64*128)
        FATAL "\aSprite data overflows banks 0~3 !"
    ENDIF
