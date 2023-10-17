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

SetupStoreSave:
	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

    jsr     ClearFixTop

    moveq.l #0,d0
    move.b  #1,UITemp       ; Used as Uppercase/lowercase flag
    move.b  d0,FileCursor   ; Used for keyboard column
	move.b  d0,FileCursorPrev
    move.b  d0,LetterCursor ; Used for keyboard row
	move.b  d0,LetterCursorPrev
	move.b  d0,FileNameCursor

	; RefreshFlags bits use in ui_storesaves:
	; 0: Redraw keyboard
	; 1: Redraw keyboard cursor
	; 2: Redraw filename
	; 3: -
	; 4: -
	; 5: -
	; 6: -
	; 7: -
	move.b  #%00000111,RefreshFlags

    lea     FixStrStoreSaveUI,a0
	move.w  #FIXMAP+9+(5*32),d0
	jsr     WriteFix

	moveq.l #0,d0
	move.l d0,FileNameBuffer
	move.l d0,FileNameBuffer+4
	move.l d0,FileNameBuffer+8
	move.l d0,FileNameBuffer+12
	move.b d0,FilenameBuffer+16

	move.w  #SCREEN_STORE_SAVE,CurrentScreen
	rts

VBLProcStoreSave:
	; Refresh stuff in VRAM while we're at the beginning of the vblank

	btst.b  #0,RefreshFlags
	beq     .norefresh_kbd
	; Redraw keyboard
	move.w  #FIXMAP+15+(9*32),d0
	move.b  UITemp,d1
	jsr     DrawKeyboard
	bset.b  #1,RefreshFlags    ; Redrawing the keyboard erased the cursor, request redraw
	bclr.b  #0,RefreshFlags
.norefresh_kbd:

	btst.b  #1,RefreshFlags
	beq     .norefresh_cur
	; Erase previous cursor
	moveq.l #0,d0
	move.l  d0,d1
	move.b  FileCursorPrev,d1
	move.b  LetterCursorPrev,d0
	jsr     SetKbdVRAMAddr
	move.w  #$0520,REG_VRAMRW	; Space, palette 0, bank 5      
	moveq.l #0,d0
	; Draw new cursor
	moveq.l #0,d0
	move.l  d0,d1
	move.b  FileCursor,d1
	move.b  LetterCursor,d0
	jsr     SetKbdVRAMAddr
	move.w  #$05<<8+CHAR_ARROW_RIGHT,REG_VRAMRW	; Palette 0, bank 5
	move.b  FileCursor,FileCursorPrev
	move.b  LetterCursor,LetterCursorPrev
	bclr.b  #1,RefreshFlags
.norefresh_cur:

	btst.b  #2,RefreshFlags
	beq     .norefresh_filename
	; Erase previous file name and cursor
	move.w  #$3500,FixWriteConfig    ; Highlight palette
    lea     FileNameClear,a0
	move.w  #FIXMAP+12+(15*32),d0
	jsr     WriteFix
	; Redraw file name
    lea     FileNameBuffer,a0
	move.w  #FIXMAP+12+(15*32),d0
	jsr     WriteFix
	; Redraw cursor
	move.w  #$0500,FixWriteConfig
	moveq.l #0,d0
	move.b  FileNameCursor,d0
	lsl.w   #5,d0
	addi.w  #FIXMAP+13+(15*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	bclr.b  #2,RefreshFlags
	move.w  #$05<<8+CHAR_ARROW_UP,REG_VRAMRW	; Palette 0, bank 5
.norefresh_filename:

	TESTREPEAT CNT_UP
    beq     .no_up
    bset.b  #1,RefreshFlags     ; Request cursor refresh
    tst.b   FileCursor
    bne     .no_zero
    move.b  #4,FileCursor
    move.b  #0,LetterCursor
    bra     .no_up
.no_zero:
    subq.b  #1,FileCursor
.no_up:

	TESTREPEAT CNT_DOWN
    beq     .no_down
    bset.b  #1,RefreshFlags     ; Request cursor refresh
    cmp.b   #4,FileCursor
    bne     .no_last
    move.b  #0,FileCursor
    move.b  #0,LetterCursor
    bra     .no_down
.no_last:
    addq.b  #1,FileCursor
    cmp.b   #4,FileCursor
    bne     .no_down
    move.b  #0,LetterCursor
.no_down:

	TESTREPEAT CNT_LEFT
    beq     .no_left
    bset.b  #1,RefreshFlags     ; Request cursor refresh
    cmp.b   #4,FileCursor
    bne     .no_last2
    move.b  #0,LetterCursor
    bra     .no_left
.no_last2:
    tst.b   LetterCursor
    bne     .no_zero2
    move.b  #11,LetterCursor
    bra     .no_left
.no_zero2:
    subq.b  #1,LetterCursor
.no_left:

	TESTREPEAT CNT_RIGHT
    beq     .no_right
    bset.b  #1,RefreshFlags     ; Request cursor refresh
    cmp.b   #4,FileCursor
    bne     .no_last3
    move.b  #1,LetterCursor
    bra     .no_right
.no_last3:
    cmp.b   #11,LetterCursor
    bne     .no_last4
    move.b  #0,LetterCursor
    bra     .no_right
.no_last4:
    addq.b  #1,LetterCursor
.no_right:

	TESTCHANGE CNT_A
    beq     .no_a
    cmp.b   #4,FileCursor
    bne     .kbd_a
    ; We're on Save/Exit line
    tst.b   LetterCursor
    beq     .exit
    ; Check that file name isn't empty
    tst.b   FileNameCursor
    bne     .storesaves
    lea     FixStrNoFileName,a0
    jmp     MessageBox
.storesaves:
    clr.b   d0                  ; Check if file exists
    jmp     StoreSaves
.exit:
    move.b  #SFX_EXIT,d0
    jsr     PlaySFX
    jmp     SetupMenu
.kbd_a:
    ; Is max file name length reached ?
    cmp.b   #16,FileNameCursor
    beq     .no_a
    ; Get char
    moveq.l #0,d0
    move.b  FileCursor,d0
    lsl.b   #2,d0               ; *4
    move.b  d0,d1
    add.b   d0,d0               ; *8
    add.b   d1,d0               ; +*4 = *12
    add.b   LetterCursor,d0
    lea     KeyboardMapLC,a0
    tst.b   UITemp
    beq     .lowercase
    lea     KeyboardMapUC,a0
.lowercase:
    move.b  0(a0,d0),d1
    ; Write char
    lea     FileNameBuffer,a0
    move.b  FileNameCursor,d0
    move.b  d1,0(a0,d0)
    ; Inc file name cursor
    addq.b  #1,d0
    move.b  d0,FileNameCursor
    bset.b  #2,RefreshFlags     ; Request file name refresh
.no_a:

	TESTCHANGE CNT_B
    beq     .no_b
    ; Is file name already empty ?
    tst.b   FileNameCursor
    beq     .no_b
    ; Erase char
    lea     FileNameBuffer,a0
    move.b  FileNameCursor,d0
    subq.b  #1,d0
    move.b  #0,0(a0,d0)
    move.b  d0,FileNameCursor
    bset.b  #2,RefreshFlags     ; Request file name refresh
.no_b:

	TESTCHANGE CNT_C
    beq     .no_c
    ; Change case
    eori.b  #1,UITemp
    bset.b  #0,RefreshFlags     ; Request keyboard refresh
.no_c:

	rts


; d0: VRAM address
; d1: Upper/lower case
DrawKeyboard:
	move.w  #$3500,FixWriteConfig    ; Highlight palette
    lea     KeyboardMapLC,a0
    tst.b   d1
    beq     .lowercase
    lea     KeyboardMapUC,a0
.lowercase:
	move.w  #32,REG_VRAMMOD
	move.w  FixWriteConfig,d1
    nop
    nop
.row:
	move.b  #12,d7
    move.w  d0,REG_VRAMADDR
    nop
.char:
    move.b  (a0)+,d1
    tst.b   d1
    beq     .done
	move.w  d1,REG_VRAMRW
	nop
	nop
	nop
	move.b  #$20,d1
	move.w  d1,REG_VRAMRW
	subq.b  #1,d7
	bne     .char
	addi.w  #1,d0
    bra     .row
.done:
	move.w  #$0500,FixWriteConfig
    rts

; d0.w: x pos
; d1.w: y pos
SetKbdVRAMAddr:
	cmp.b   #4,d1
    bne     .kbdzone
    add.w   d0,d0   ; *2
    move.w  d0,d2
    add.w   d0,d0   ; *4
    add.w   d2,d0   ; *2+*4 = *6
    addi.b  #2,d0   ; All this will be *2 just below
.kbdzone:
	lsl.w   #6,d0               ; Fixmap x*2
	add.b   d1,d0               ; Fixmap y
	add.w   #FIXMAP+15+(8*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	rts
