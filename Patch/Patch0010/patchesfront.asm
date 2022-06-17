; Copyright (C) 2021 Sean Gonsalves
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

CheckCDValid        equ $C0F29A
CDCheckDoneEnd      equ $C0F55C
JTFileLoaders       equ $C0FD94
MainLoopEnd         equ $C0D3EC
StartGameCD         equ $C0F248
CDPControllerStuff  equ $C0EFF4
ProcessCDDACmds     equ $C0D6E6
MemCardMenu         equ $C1474A
ReadCDDAFromZ80End  equ $C0D5DE
SpriteInitData      equ $C174C8
CDPPalData          equ $C209A0
RegionPatch         equ $C0D326 ; "not.b d1" instruction to patch in InitRAM original system ROM routine
DrawProgressAnimation equ $C0ED80

    ORG $C0B486					; Replacement to avoid using DMA copy in DMAClearPalettes
	jmp DMAClearPalettes
	ORG $C0B4CC                 ; Replacement to avoid using DMA copy in DMAClearPCMDRAM
	jmp DMAClearPCMDRAM
	ORG $C0C0D6					; Replacement to avoid using DMA copy
	dc.l UploadDMABytes
	ORG $C0C0DE					; Replacement to avoid using DMA copy
	dc.l UploadDMABytes
	ORG $C0C218					; Avoid using DMA copy in UploadPRGCopyLongwords
	nop
	nop
	nop
	nop
	ORG $C0C244					; Avoid using DMA copy in UploadPalCopyLongwords
	nop
	nop
	nop
	nop
	ORG $C0C264					; Avoid using DMA copy in UploadSPRDMAWords
	nop
	nop
	nop
	nop
	;ORG $C0BDF2				; Avoid using DMA copy in UploadPCMDMABytes
	;nop                        ; Leave this removed ! Was causing data corruption during IGLs
	;nop
	;nop
	;nop
	ORG $C0C398					; Avoid using DMA copy in UploadZ80DMABytes
	nop
	nop
	nop
	nop
	ORG $C0C3C0					; Avoid using DMA copy in UploadPRGDMAWords
	nop
	nop
	nop
	nop
	ORG $C0C3DC					; Avoid using DMA copy in UploadPalDMAWords
	nop
	nop
	nop
	nop
	ORG $C0C404					; Replace RunDMADirect for UploadPRGDMAWords, UploadPalDMAWords and UploadSPRDMAWords
	jmp    RunDMADirect         ;RunDMADirectMulti
    ORG $C0C47C
	jmp    CopyBytesToWordCPU	; Cache-to-DRAM copy speed optimization attempt to speed up PCM loads

	ORG $C0C83A
	dc.l   CDPlayerVBLProc		; Replace pointer to CDPlayerVBLProc by one to new code

	ORG $C0C998
    jmp    FrontIGMVBLInsert


	ORG $C0CD08
	jsr    ConsoleStart

    ORG $C0CF72
	jsr    LoadDebugDIPs		; Insertion - Called at game start
	nop

    ORG $C0CE46
	jmp    InitSoftDIPs			; Insertion - Called just before game start in ReadCDDAFlagSDIPs

    ORG $C0D114
	jmp    PUPPETStuff			; Insertion - Called at startup, initializes some new stuff

    ORG $C0D2E4
    jsr    InitRAM  			; Insertion - Avoid tripping some in-game copy protections and set nationality
	nop

	ORG $C0D32C
	nop                         ; Disable getting nationality from jumpers
	nop

	ORG $C0D3DC
	jmp    CDPLAYER_Init		; Insertion - Make call SYS_CDPLAYER re-init the SD card and values in RAM

    ;ORG $C0CBD2
	;nop						; Bypass CD lid check in SYSTEM_IO
	;nop

	ORG $C0D442
	jmp    FrontCheatInsert     ; Insert call in SYSTEM_IO call

	ORG $C0D572
	jmp    ProcessZ80CDDA       ; Insertion - ReadCDDAFromZ80

    ORG $C0DB80                 ; Insertion - BIOSF_CDDACMD
    jmp    BIOSF_CDDACMD

	ORG $C0EBEC
	rts                         ; Disables PushCDOp

    ; Disables CDC IRQ handling - Maybe not needed
	ORG $C0C880
	move.b #$20,$FF000F
    move.b d0,REG_DIPSW
    rte

    ; !!! TESTING !!! This is causing the glitches in NTM
    ORG $C0DEFC
    jmp    DoCDDComm            ; CDD IRQ handling, DoCDDComm hijack - Needed to open/close tray
    
    ;ORG $C0CC8E
    ;rts		; Disable ResetCDDIfCrashed TESTING - Not this, remove
    ;ORG $C0D194
    ;nop
    ;nop
    ;nop
    ;nop

    ; DEBUG - TO REMOVE
    ;ORG $C1415E
    ;move.l d6,d0
    ;move.w d0,$10F301   ; Trigger address error
    ;ORG $C0FBCC
    ;clr.b  $10FDDC  ; LoadWithAnimFlag - Solves problem !
    ;nop
    ;ORG $C0EC2E
    ;rts       ; Disable ProcessLOGOFile - Solves problem !
    ;ORG $C0EC64
    ;rts        ; Disable ProcessLOGOFile - Solves problem !
    ;ORG $C0ECA2
    ;rts        ; Disable ProcessLOGOFile - Does NOT solve problem
    ;ORG $C0EC4C
    ;move.b  REG_P1CNT,d0
	;btst.l  #7,d0      ; D button
    ;bne     .no_view
    ;movea.l #$120000,a1
    ;jmp     MemoryViewer
;.no_view:
    ;rts

	;ORG $C0E712
	;jmp    DrawProgressAnimation	; Replaces custom loading animation code with current sector display

	ORG $C0EF0A
	jmp    SetupMain			; Added to InitCDPlayerScreen (was ParseSDFiles)

	ORG $C0EF40
	bra    $C0EFCE             	; Skip CD player interface updating, just go to rts - Not needed anymore ?

    IFDEF MAMEDEBUG
	ORG $C0EB96
	rts
	ELSE
	ORG $C0F29A
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

	ORG $C0F2C8
	nop							; Disable "WAIT A MOMENT" message
	nop

	ORG $C0F2F2
	nop							; Disable "WAIT A MOMENT" message (again)
	nop

	ORG $C0F316
	jsr     LoadCDSectorFromSD	; Load first sector (CD001...)
	move.b  d0,REG_DIPSW
	bra     $C0F33C				; Skip first sector loading wait, there's no more CD :)

	ORG $C0F4E8                 ; LOGO file loading
	jsr     LoadCDSectorFromSD
	jsr     $C0C0A2             ; "UploadData2"
	tst.w   $10F688				; "SectorCounter"
	beq     $C0F51C				; No more sectors to load: go to rts
	bra     $C0F4E8

	;ORG $C0EE04
	;nop						; Bypass CD lid check

    ORG $C0F522
	jmp     CDCheckDone         ; Insertion - Used to detect validity of "CD"

	ORG $C0F658                 ; "GetCDFileList"
	tst.w   $10F688				; "SectorCounter"
	beq     $C0F6CE				; No more sectors to load: go to rts
	jsr     LoadCDSectorFromSD
	bra     $C0F66A

	;ORG $C0EF6C				; Bypass CD lid check
	;nop
	;nop
	;nop

	ORG $C0F7AC					; Disable waiting for CD Op to be processed
	rts

    IFDEF DEBUGBUILD
	ORG $C0FAAE
	bra     $C0FAD2				; Prevent loading custom loading screens
	ORG $C0FB0C
	bra     $C0FB34             ; Same
	ENDIF
	
	ORG $C0F834					; Disable waiting for CD to stop after IPL load
	jsr     LoadingFinished     ; Insertion
	nop

	ORG $C0FC6E					; Disable waiting for CD to stop after BIOSF_LOADFILE
	jsr     LoadingFinished     ; Insertion
	nop

	ORG $C0D3A6
	jsr     StopCDDA
	nop

	ORG $C0D42C
	jsr     SYSTEM_IO_WDKICK

	ORG $C0FD86
	jmp     LoadFile			; Patch original LoadFile

    ;ORG $C0FF98                ; TESTING: Called in LoadPRGSectorsPatch
    ;jmp     LoadPRGVectorTable  ; Avoid using DMA in LoadPRGSectors - Double Dragon needs this

    ORG $C0FF3A ;C0FF0E
    jmp     LoadPRGSectorsPatch ; Direct copy
    ORG $C10148 ;C100F6
    jmp     LoadSPRSectorsPatch ; Direct copy
    ORG $C102B2 ;C10262
    jmp     LoadPCMSectorsPatch ; Direct copy

	ORG $C104FC
	jsr     LoadCDSectorFromSD	; Load sector in SearchForFile
	bra     $C10506				; Skip waiting

	ORG $C106EE					; WaitForCD
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10732					; WaitForNewSector (useless now ?)
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10774					; WaitForCD2
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10878					; WaitForLoaded
	jsr     LoadCDSectorFromSD
	rts

	ORG $C10934
    jmp     LoadFromCD			; Patch original "LoadFromCD" (multiple calls)

    ORG $C10BF8
    nop                         ; Disable LC8951->DRAM DMA, shouldn't be used anyways
    nop
    nop

	ORG $C11E96
	rts
	;;jsr     $C0B278			; Just jump to ClearSprites ?
	;lea     $100040,a6        	; Disable CD player display and erase finger cursor from splash screen
	;move.b  #0,4(a6)			; Sprite height
	;bra     $C16CF2			; "SpriteUpdateVRAM"
	
	ORG $C16EFA
	moveq.l #1,d0
	move.b  d0,$764E(a5)
	move.b  d0,$7656(a5)		; Init "CDValidFlag" to 1 instead of 0 to kickstart CD checking

	ORG $C20BD2
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
    
    ORG $C16EF0
    jsr SetLEDStartup
    nop
    nop


    ORG $C16F90
    jsr     SplashInit          ; Patch up to before $C16FA4
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    ORG $C1727A
	jsr     SplashStartCurve
	nop

    ORG $C172E2
	jsr     SplashLetterCurve

	ORG $C1747C
	move.b  d2,(4,a6)			; Sprite height bugfix :)

	ORG $C1745E
	jsr     SplashMapSprite     ; Patch MapSprite to switch between CD and SD card sprite map
    nop                         ; Patch up to before $C1746C
    nop
    nop
    nop

    ORG $C0CF02
    jmp     InstallPalettes


    ORG $C209A0
	BINCLUDE "gfxdata\menu_font.pal"	; Replaces palette (0) used for fix
    ORG $C209C0
	BINCLUDE "gfxdata\menu_picto.pal"	; Replaces palette (1) used for fix
	; Palette (2) is used for msgbox text, leave it alone
    ORG $C20A00
	BINCLUDE "gfxdata\menu_font_hl.pal"	; Replaces palette (3) used for fix
    ORG $C20AA0
	BINCLUDE "gfxdata\tile_scroll_bg.pal" 	; Replaces CD player bg palette (8)
    ORG $C20AC0
	BINCLUDE "gfxdata\letter_cursor.pal" 	; Replaces buttons palette (9)
    ORG $C20AE0
	BINCLUDE "gfxdata\menu_logo.pal" 	    ; Replaces R vu-meter palette (10)
    ORG $C20B00
	BINCLUDE "gfxdata\menu_letters.pal" 	; Replaces cursor palette (11)
    ORG $C20B20
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
