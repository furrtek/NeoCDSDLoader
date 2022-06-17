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

CDPlayerVBLProc:
    jsr     CDPControllerStuff  ; Copied from original routine

    IFNDEF MAMEDEBUG
    tst.b   PollStatus
    beq     .skipstat
    tst.b   SetMCUConfig        ; Set/get MCU status immediately if SetMCUConfig requested
    bne     .getstat
    move.w  FrameCounter,d0     ; Get status byte from MCU every 32 frames = ~0.5s, if allowed
    andi.w  #$001F,d0
    bne     .skipstat
.getstat:
    jsr     GetMCUStatus
.skipstat:
    ENDIF

    ; Reset the screen saver timer on joypad activity
    move.b  BIOS_P1CURRENT,d0
    or.b    BIOS_P2CURRENT,d0
    beq     .no_kick
    move.w  #0,SSaverTimer
.no_kick:

    ; Call proc for current screen
    moveq.l #0,d0
    move.w  CurrentScreen,d0
    lsl.l   #2,d0
    lea     JT_VBLProcs,a0
    move.l  0(a0,d0),a0
    jsr     (a0)

    move.w  #0,d0
    move.b  SettingSSaver,d1
    andi.b  #1,d1
    beq     .no_ss
    cmp.w   #SCREEN_SSAVER,CurrentScreen
    beq     .no_ss
    move.w  SSaverTimer,d0
    addq.w  #1,d0
    cmp.w   #SSAVER_TIMEOUT*60,d0
    blo     .no_ss
    ; If screen saver activates while a msgbox is shown, close it first to restore the correct CurrentScreen value
    tst.b   CurrentMsgBox
    beq     .no_msgbox
    jsr     MessageBoxClose
.no_msgbox:
    jsr     SetupSSaver
    move.w  #0,d0
.no_ss:
    move.w  d0,SSaverTimer

    addq.w  #1,FrameCounter

    rts


VBLProcNothing:
    move.b  d0,REG_DIPSW
    rts
    

VBLProcBExit:
	TESTCHANGE CNT_B
    beq     .no_b
    jsr     SetupMenu
.no_b:
    rts


; d0: SFX code, see equ.asm
PlaySFX:
    tst.b   SettingSFX
    beq .nosfx
    move.b  d0,REG_SOUND
.nosfx:
    rts
    

DrawFileList:
	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

    ; Erase previously drawn list
	move.w  #32,REG_VRAMMOD         ; Line by line
	move.w  #FIXMAP+11+(8*32),d0
	move.w  #MAX_MENU_LINES,d7
.cl_line:
	move.w  d0,REG_VRAMADDR
	move.w  #MAX_FILENAME,d6
.cl_char:
	move.w  #$0520,REG_VRAMRW	; Space, palette 0, bank 5
	nop
	subq.w  #1,d6
	bne     .cl_char
	addq.w  #1,d0				; Next line
	subq.w  #1,d7
	bne     .cl_line

	bclr.b  #0,RefreshFlags

    ; Does new list have entries ?
	tst.b   LetterGameCount
	bne     .files
    lea     FixStrNoFiles,a0
	btst.b  #7,MCUStatus
	bne     .cardpresent
    lea     FixStrNoCard,a0
.cardpresent:
	move.w  #FIXMAP+12+(8*32),d0
	jsr     WriteFix
	bset.b  #2,RefreshFlags     ; Force update to hide cursor
	rts
.files:

	; Draw new list
	moveq.l #MAX_MENU_LINES,d7
	moveq.l #0,d0
	move.b  MenuShift,d0		; Matched entries to skip, for scrolling
	move.b  d0,d6
	add.l   #MenuIndexList,d0
	movea.l d0,a1
	move.w  #FIXMAP+11+(8*32),d2
.disp:
    cmp.b   LetterGameCount,d6
    beq     .done               ; Reached end of MenuIndexList
    ; Get file name pointer from index
	moveq.l #0,d0
    move.b  (a1)+,d0
    lsl.w   #5,d0               ; *32
	add.l   #FileList+2,d0      ; Skip flag and file number bytes
	movea.l d0,a0

    ; Write file name
	move.w  d2,d0
	jsr     WriteFix
	addq.w  #1,d2				; Next FIX line

    addq.w  #1,d6

	subq.w  #1,d7
	bne     .disp			    ; Max lines reached, stop
.done:

	rts
	

ClearMainSprites:
    ; Clear all sprites except logo and background
    move.w  #1,REG_VRAMMOD
	move.w  #SCB3+SPR_LETTERS,REG_VRAMADDR
	move.w  #((496-264)<<7)+0,d1
	move.w  #384-SPR_LETTERS,d7
.clrspr:
	move.w  d1,REG_VRAMRW
	nop
	subq.w  #1,d7
	bne     .clrspr
    rts


; This is used in ui_loadsaves and ui_main
FileListNav:
    ; Handle input for selection of game from list
	TESTREPEAT CNT_UP
    beq     .no_up
    tst.b   FileCursor
    beq     .top
    ; Move cursor
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    subq.b  #1,FileCursor
	bset.b  #2,RefreshFlags
    bra     .no_up
.top:
    tst.b   MenuShift       
    beq     .no_up
    ; Scroll
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    subq.b  #1,MenuShift
	bset.b  #0,RefreshFlags
.no_up:

	TESTREPEAT CNT_DOWN
    beq     .no_down
    move.b  FileCursor,d0
	add.b   MenuShift,d0
	addq.b  #1,d0
    cmp.b   LetterGameCount,d0
    bhs     .no_down
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    cmp.b   #MAX_MENU_LINES-1,FileCursor		; Max lines at once
    beq     .scrolldown
    ; Move cursor
    addq.b  #1,FileCursor
	bset.b  #2,RefreshFlags
    bra     .no_down
.scrolldown:
    ; Scroll
    addq.b  #1,MenuShift
	bset.b  #0,RefreshFlags
.no_down:
    rts


; This must match SCREEN_ equs !
JT_VBLProcs:
    dc.l VBLProcNothing
    dc.l VBLProcMain
    dc.l VBLProcNothing     ; Free to use
    dc.l VBLProcNothing     ; Free to use
    dc.l VBLProcNothing     ; Free to use
    dc.l VBLProcNothing     ; Free to use
    dc.l VBLProcNothing     ; Free to use
    dc.l VBLProcMenu
    dc.l VBLProcStoreSave
    dc.l VBLProcLoadSave
    dc.l VBLProcSettings
    IFDEF LOADTEST
    dc.l VBLProcDebugLoading
    ELSE
    dc.l VBLProcNothing
    ENDIF
    dc.l VBLProcAbout
    dc.l VBLProcSSaver
    dc.l VBLProcNothing
    dc.l VBLProcMsgBox

    INCLUDE "msgbox.asm"
	INCLUDE "ui_bg.asm"
	INCLUDE "ui_ssaver.asm"
	INCLUDE "ui_main_setup.asm"
	INCLUDE "ui_main_vbl.asm"
	INCLUDE "ui_menu.asm"
	INCLUDE "ui_storesaves.asm"
	INCLUDE "ui_loadsaves.asm"
	INCLUDE "ui_settings.asm"
	INCLUDE "ui_debug.asm"
	INCLUDE "ui_update.asm"
	INCLUDE "ui_about.asm"
    INCLUDE "ui_igm.asm"
    INCLUDE "ui_cheats.asm"
    INCLUDE "ui_sdips.asm"
    ;INCLUDE "ui_savestate.asm"
    ;INCLUDE "ui_loadstate.asm"
