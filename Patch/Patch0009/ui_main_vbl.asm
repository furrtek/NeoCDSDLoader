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

VBLProcMain:
    IFNDEF MAMEDEBUG
    ; Check MCU card event flag
    tst.b   CardEvent
    beq     .nocardevent
    ; A card event occured
    clr.b   CardEvent
	jmp     SetupMain
    ;btst.b  #7,MCUStatus
    ;beq     .cardremoved
    ;; Try to re-init card if it is now inserted
    ;bset.b  #7,RefreshFlags
    ;bra     .nocardevent
;.cardremoved:
    ;; Show message if card is removed
    ;;lea     StrMsgBoxCardAbsent,a0
    ;;jsr     MessageBox
    ;bset.b  #6,RefreshFlags
.nocardevent:
    ENDIF

	; Refresh stuff in VRAM while we're at the beginning of the vblank
	btst.b  #0,RefreshFlags
	beq     .norefresh0
	jsr     DrawFileList
	move.b  #0,ScrollX
	move.b  #0,UITemp           ; Reset timer
.norefresh0:

	btst.b  #1,RefreshFlags
	beq     .norefresh1
	move.w  #320,d1             ; Out of visible display
	tst.b   LetterCount
	beq     .hidecursor
	move.w  LetterCursorX,d1
    lsr.w   #6,d1               ; Remove fractional part
.hidecursor:
	move.w  #SPR_LETTER_CUR,d0
	move.w  #1,d7
	jsr     SetSprX
	bclr.b  #1,RefreshFlags
.norefresh1:

	btst.b  #2,RefreshFlags
	beq     .norefresh_cur
	; Erase previous cursor
	moveq.l #0,d0
	move.b  FileCursorPrev,d0
	add.w   #FIXMAP+11+(7*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	move.w  #$0520,REG_VRAMRW	; Space, palette 0, bank 5
	tst.b   LetterGameCount
	beq     .norefresh_cur      ; No files in list, don't draw cursor
	; Draw new cursor
	moveq.l #0,d0
	move.b  FileCursor,d0
	move.b  d0,FileCursorPrev
	addi.w  #FIXMAP+11+(7*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	move.w  #$05<<8+CHAR_ARROW_RIGHT,REG_VRAMRW	; Palette 0, bank 5
	move.b  #0,UITemp           ; Reset timer  
	tst.b   ScrollX
	beq     .noredraw
	; Force redraw list to restore currently scrolling filename to start
	jsr     DrawFileList
.noredraw:
	bclr.b  #2,RefreshFlags
.norefresh_cur:

	btst.b  #3,RefreshFlags
	beq     .noscrolling
	; Redraw currently selected filename with scrolling shift
	moveq.l #0,d0
	move.l  d0,d1
	move.b  FileCursor,d0
	addi.w  #FIXMAP+11+(8*32),d0
	; Display MAX_FILENAME-1 chars starting from (GUBuffer+ScrollX)
	move.w  #32,REG_VRAMMOD
	lea     GUBuffer,a0
	move.b  ScrollX,d1
	add.l   d1,a0
	move.w  FixWriteConfig,d1
    move.w  d0,REG_VRAMADDR
    moveq.l #MAX_FILENAME-1,d7
.write:
    move.b  (a0)+,d1
    tst.b   d1
    beq     .strend
	move.w  d1,REG_VRAMRW
	subq.b  #1,d7
	bne     .write
.strend:
	bclr.b  #3,RefreshFlags
.noscrolling:

	btst.b  #4,RefreshFlags
	beq     .nomsgbox
    lea     StrMsgBoxExceedGames,a0
    jsr     MessageBox
	bclr.b  #4,RefreshFlags
.nomsgbox:

	; Prevent from navigating lists if there are no games found
	tst.w   TotalFileCount
	beq     .cantmove

    cmp.b   #40,UITemp
    blo     .noscroll
    bne     .scroll
    ; Does the current filename need scrolling ?
	moveq.l #0,d0
	move.b  MenuShift,d0		; Matched entries to skip, for scrolling
	add.b   FileCursor,d0
	lea     MenuIndexList,a0
    ; Get file name pointer from index
	moveq.l #0,d1
    move.b  0(a0,d0),d1
    move.b  d1,d0
    lsl.w   #5,d0               ; *32
    lea     FileList,a0
	btst.b  #1,0(a0,d0)         ; Check "long filename" flag
	beq     .scrolling          ; No
    ; ==40: Init file name scrolling
	; Ask MCU for full filename and store in GUBuffer
    move.b  #1,MCUCmdParams
    move.b  d1,MCUCmdParams+1
    MCUCMD  MCU_CMD_GETGAMES
    bcs     .scrolling          ; Silently ignore
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .scrolling          ; Silently ignore
    ; Ok, retrieve full filename data
	lea     CPLDREG_DATA,a0
	lea     GUBuffer,a1
	move.w  #256/2,d7 		   ; Load filename in words
.readdata:
	move.w  (a0),(a1)+         ; Get two bytes at once
	move.b  d0,REG_DIPSW       ; Shouldn't be necessary
	subq.w  #1,d7
	bne     .readdata
	move.b  #0,(a1)            ; Make sure filename is null terminated
	; Init scrolling vars
    moveq.l #0,d0
    move.b  d0,ScrollX
    move.b  d0,ScrollTimer
    bra     .noscroll
.scroll:
    ; >=41: Do scrolling
    move.b  ScrollTimer,d0
    addq.b  #1,d0
    move.b  d0,ScrollTimer
    andi.b  #7,d0
    bne     .scrolling
    ; Is next filename char null ?
    lea     GUBuffer+MAX_FILENAME-1,a0
    moveq.l #0,d0
    move.b  ScrollX,d0
    tst.b   0(a0,d0)
    beq     .scrolling         ; Don't scroll more
    addq.b  #1,d0
    bset.b  #3,RefreshFlags
    move.b  d0,ScrollX
    bra     .scrolling
.noscroll:
    addq.b  #1,UITemp
.scrolling:

	; Handle input to move letter cursor
	TESTREPEAT CNT_LEFT
    beq     .no_left
    tst.b   LetterCursor
    bne     .left
    ; Warp to rightmost letter
    moveq.l #0,d0
	move.b  LetterCount,d0
    subq.b  #1,d0
    move.b  d0,LetterCursor
    jsr     SetLetterCursorX
	bra     .left_done
.left:
    subq.b  #1,LetterCursor
	subi.w  #600,LetterCursorX  ; Move left 9.375px
.left_done:
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    jsr     BuildFileList
.no_left:

	TESTREPEAT CNT_RIGHT
    beq     .no_right
    move.b  LetterCount,d0
    subq.b  #1,d0
    cmp.b   LetterCursor,d0
    bne     .right
    ; Warp back to leftmost letter
	move.b  #0,LetterCursor
    move.w  LettersXPos,LetterCursorX
	bra     .right_done
.right:
    addq.b  #1,LetterCursor
	addi.w  #600,LetterCursorX  ; Move right 9.375px
.right_done:
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    jsr     BuildFileList
.no_right:

    ; Handle input for selection of game from list
    jsr     FileListNav

	TESTCHANGE CNT_A
    beq     .no_a
    tst.b   LetterGameCount
    beq     .no_a
    ; Load selected game
	move.w  #$0000,FixWriteConfig
	; Get selected file number, double lookup
	lea     MenuIndexList,a0
	moveq.l #0,d0
	move.b  FileCursor,d0
	add.b   MenuShift,d0
	moveq.l #0,d1
	move.b  0(a0,d0),d1
	lea     FileList,a0
	lsl.w   #5,d1                   ; *32
	move.b  1(a0,d1),d0
	jsr     LoadGame
.no_a:

.cantmove:

    IF TARGET==1
    ; B: Open/close try on front-loaders
	TESTCHANGE CNT_B
    beq     .no_b
    jsr     ToggleTray
.no_b:
    ENDIF

    ; C: Go to options menu
	TESTCHANGE CNT_C
    beq     .no_c
    move.b  #SFX_VAL,d0
    jsr     PlaySFX
    jsr     SetupMenu
.no_c:

    ; D: Reset to original SP ROM
	TESTCHANGE CNT_D
    beq     .no_d
    lea     StrMsgBoxResetConfirm,a0
    lea     ResetConfirm,a1
    jsr     MessageBoxCustom
.notimeout:
.no_d:

	btst   	#7,$10F6B9			; "GameStartState"
	beq     .idle
	jmp     StartGameCD

.idle:
	rts


ResetConfirm:
	TESTCHANGE CNT_A
    beq     .no_a
    lea     MCUCmdParams,a0
    st.b    (a0)+               ; SetRunStock(1)
    ; Send country patch parameters to MCU, MCU will send them to the CPLD
    move.b  SettingCountry,(a0)+
    move.b  #RegionPatch>>16,(a0)+
    move.b  #(RegionPatch>>8)&255,(a0)+
    move.b  #(RegionPatch)&255,(a0)
    MCUCMD  MCU_CMD_RESET
    bcs     .timeout
    rts
.timeout:
    jmp     DispErrorTimeout
.no_a:
    move.b  #SFX_NEG,d0
    jmp     PlaySFX
