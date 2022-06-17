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

; For FRONT, TOP-SP1, TOP-SP1-2 and TOP-SP1-3

    cpu 68000
    supmode on

;MAMEDEBUG equ 1        ; Uncomment to assemble for MAME debugging
;DEBUGBUILD equ 1		; Uncomment to enable debug messages
;LOADTEST equ 1		    ; Uncomment to enable CD data load with B press

    IFNDEF TARGET
        ERROR "TARGET is undefined"
    ENDIF

    INCLUDE "defs.asm"
	INCLUDE "equ.asm"
	INCLUDE "ram.asm"
    INCLUDE "vectors.asm"
    IF TARGET==1
        IF MOMPASS==1
            MESSAGE "Using FRONT-SP1 patches"
        ENDIF
        INCLUDE "patchesfront.asm"
    ELSEIF TARGET==2
        IF MOMPASS==1
            MESSAGE "Using TOP-SP1-1/2 patches"
        ENDIF
        INCLUDE "patches1-2.asm"
    ELSEIF TARGET==3
        IF MOMPASS==1
            MESSAGE "Using TOP-SP1-3 patches"
        ENDIF
        INCLUDE "patches3.asm"
    ENDIF

	; Added code starts here
    ; Approx 30kB of free space starting at $C19000
	ORG $C19000
	dc.w VERSION_MAJ<<8+VERSION_MIN    ; DO NOT MOVE !

PUPPETStuff:
    ; Copied from original routine
	move.w  #0,$FF0000
	move.w  #$550,$FF0002
    move.w  #$731,$FF0004
    move.b  #$FE,$FF0011
    move.b  #$3C,$FF000E
	move.w  #7,REG_IRQACK
	andi.w  #$F8FF,sr
    ; Added
	move.w  #0,SSaverTimer
	move.b  #1,$10F6DC           ; Prevents a leftover debug routine (?) from being triggered. See $C0D7CC.
    ; Get MCU FW version to load MCUVersion
    move.w  #$FFFF,MCUVersion    ; Invalidate
    MCUCMD  MCU_CMD_GETID
    bcs     .done                ; Can't show errors at this early boot stage, just ignore
    ; Read 24 bytes from the MCU (see doc) CHANGED
    move.w  #12,d3
    jsr     MCURead4WordsMult
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .done                ; Can't show errors at this early boot stage, just ignore
    lea     MCUReplyBuffer+13,a0
    move.b  (a0)+,d0
    move.b  d0,MCUVersion
    move.b  (a0),d0
    move.b  d0,MCUVersion+1
.done:
	rts
	

ConsoleStart:
    ; Copied from original routine
    move.b  #0,REG_ENVIDEO
    ; Added
	moveq.l #0,d0
	move.b  d0,IsInIGM
	move.w  d0,FixWriteConfig
	move.b  d0,DebugDIP1
	move.b  d0,DebugDIP2
	move.w  d0,SSaverTimer
    move.b  d0,CustomBGLoaded
    move.b  d0,CursorsValid
    move.b  d0,CardEvent
	jsr     LoadSettings
	move.w  #$0600,d0           ; Stop CDDA - Now useless ?
	jsr     CDDACommand
	rts


SetLEDStartup:
    st.b    SetMCUConfig
    jmp     GetMCUStatus


GetMCUStatus:
    moveq.l #0,d4
    move.b  d4,MCUCmdParams
    tst.b   SetMCUConfig
    beq     .noset
    move.b  SettingLEDIdle,d4
    addq.b  #1,d4
    lsl.b   #3,d4
    or.b    SettingLEDLoad,d4
    addq.b  #1,d4
    ori.b   #$80,d4
    move.b  d4,MCUCmdParams
	clr.b   SetMCUConfig
.noset:
    MCUCMD  MCU_CMD_GETSTATUS
    bcc     .notimeout
    jsr     DispErrorTimeout
    rts
.notimeout:
    jsr     MCURead4Words
    jsr     CheckACK
    bcc     .cmdok
    rts
.cmdok:
    move.b  MCUReplyBuffer+1,d0
    move.b  d0,MCUStatus
    btst.l  #6,d0
    beq     .nocardevent
    clr.b   CursorsValid
    st.b    CardEvent
.nocardevent:
    rts


CDPLAYER_Init:
    ; This is run when a game exits to the CD player interface
	move.w  #$0000,FixWriteConfig
	move.w  #0,SSaverTimer
	jmp     MainLoopEnd


InitRAM:
    IF TARGET==1
    clr.b   $7E84(a5)			; Copied from original routine
    clr.b   $7E85(a5)			; Make MSFMismatchCntr non-zero to make Robo Army happy
    ELSE
	clr.l   $775C(a5)			; CDLidCompareB - Copied from original routine
	st.b    $7E85(a5)			; Make MSFMismatchCntr non-zero to make Robo Army happy
    ENDIF
    rts


ResetCountry:
    move.w  REG_CDCONFIG,d0
    lsr.w   #8,d0
    not.b   d0
    andi.b  #3,d0
    move.b  d0,SettingCountry
    rts


LoadDebugDIPs:
    move.b  DebugDIP1,(a0)+		; Uses a0 set by original routine
    move.b  DebugDIP2,(a0)+		; Init debug DIPs to custom values instead of zero
    rts

InitSoftDIPs:
	move.b  (a0)+,d0			; Copied from original routine
	lsr.b   #4,d0				; Init soft DIPs to default values
	move.b  d0,(a1)+
	dbra    d7,InitSoftDIPs
	move.b  d0,REG_DIPSW		; Just to be sure
    jsr     LoadSDIPs			; Load soft DIPs from SD card if there are any
    rts


	INCLUDE "loading.asm"
	INCLUDE "ui.asm"
	INCLUDE "settings.asm"
	INCLUDE "saves.asm"
	INCLUDE "copy.asm"
	INCLUDE "mcu.asm"
	INCLUDE "sectors.asm"
	INCLUDE "cdda.asm"
	INCLUDE "splash.asm"
	INCLUDE "sdips.asm"
	INCLUDE "cheats.asm"
	if TARGET==1
	INCLUDE "front.asm"
    ENDIF

    ALIGN 2
map_logo:
	BINCLUDE "gfxdata\menu_logo.map"

CodeEndA:
    IF CodeEndA > $C1E000
        FATAL "\aAdded code in zone A is too large !"
    ELSE
        IF MOMPASS==1
            OUTRADIX 10
            MESSAGE "\aFree space zone A: \{($C1E000-CodeEndA)} bytes"
        ENDIF
    ENDIF
    
    ; CPLD registers here, so useful data or code MUST NOT be in C1E000~C1E2FF

	ORG $C1E300
	INCLUDE "util.asm"
	INCLUDE "print.asm"
	INCLUDE "debug.asm"
    INCLUDE "exceptions.asm"
	INCLUDE "strings.asm"

CodeEndB:
    IF CodeEndB > $C1FF00
        FATAL "\aAdded code in zone B is too large !"
    ELSE
        IF MOMPASS==1
            OUTRADIX 10
            MESSAGE "\aFree space zone B: \{($C1FF00-CodeEndB)} bytes"
        ENDIF
    ENDIF
    ; Approx 52kB of free space starting at $C23000
	ORG $C23000

map_ssaver_sprite:
	BINCLUDE "gfxdata\ssaver_sprite.map"
bg_pal_map:
	BINCLUDE "gfxdata\bg_pal_map.bin"	; Palette numbers for default bg tiles
map_splash_sdcard:
    BINCLUDE "gfxdata\sdcard.map"
pal_sd_card:
	BINCLUDE "gfxdata\sdcard.pal"

    ALIGN 2
CheatData:
	BINCLUDE "cheats\out.bin"
CheatDataEnd:
    IF CheatDataEnd > $C30000
        FATAL "\aCheat data is too large !"
    ENDIF

    IFDEF MAMEDEBUG
    ALIGN 2
DebugCustomBgData:
    dc.b 0
;    BINCLUDE "gfxdata\debug_custom_bg.bmp"
    ENDIF

	ORG $C7FFFE
    dc.w $600D                  ; "GOOD" magic word
