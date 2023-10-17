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

SetupMenu:
    jsr     ClearFixTop
    jsr     ClearMainSprites

	move.b  #0,FileCursor
	move.b  #0,FileCursorPrev
	move.b  #4,RefreshFlags

	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

    lea     FixStrMenu,a0
	move.w  #FIXMAP+12+(10*32),d0
	jsr     WriteFix

	move.b  #1,REG_ENVIDEO
	move.b  #0,REG_DISBLSPR
	move.b  #0,REG_DISBLFIX

	move.w  #SCREEN_MENU,CurrentScreen
	rts
	
VBLProcMenu:
	; Refresh stuff in VRAM while we're at the beginning of the vblank

	btst.b  #2,RefreshFlags
	beq     .norefresh_cur
	; Erase previous cursor
	moveq.l #0,d0
	move.b  FileCursorPrev,d0
	add.w   #FIXMAP+12+(9*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	move.w  #$0520,REG_VRAMRW	; Space, palette 0, bank 5
	; Draw new cursor
	move.b  FileCursor,d0
	andi.w  #$007F,d0
	move.b  d0,d1
	addi.w  #FIXMAP+12+(9*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	move.w  #$0511,REG_VRAMRW	; Arrow pointing right, palette 0, bank 5
	move.b  d1,FileCursorPrev
	bclr.b  #2,RefreshFlags
.norefresh_cur:

	; Handle input to move cursor
	TESTREPEAT CNT_UP
    beq     .no_up
    tst.b   FileCursor
    beq     .no_up
    ; Move cursor
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    subq.b  #1,FileCursor
	bset.b  #2,RefreshFlags
    bra     .no_up
.no_up:

	TESTREPEAT CNT_DOWN
    beq     .no_down
    move.b  FileCursor,d0
    addq.b  #1,d0
    cmp.b   #6,d0      	    ; Last item
    beq     .no_down
    ; Move cursor
    move.b  d0,FileCursor
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
	bset.b  #2,RefreshFlags
.no_down:

	TESTCHANGE CNT_A
    beq     .no_a
    ; Select item
    move.b  #SFX_VAL,d0
    jsr     PlaySFX
	lea     JT_MenuSetups,a0
	moveq.l #0,d0
	move.b  FileCursor,d0
	lsl.w   #2,d0				; JT_MenuSetups has 4-byte entries
	move.l  0(a0,d0),a0
	jsr     (a0)
.no_a:

	TESTCHANGE CNT_B
    beq     .no_b
    move.b  #SFX_EXIT,d0
    jsr     PlaySFX
    jsr     SetupMain
.no_b:

	rts

JT_MenuSetups:
    dc.l SetupSettings
    dc.l SetupSavesMenu
    dc.l SetupStoreSave
    dc.l SetupLoadSave
    dc.l DoUpdate
    dc.l SetupAbout
