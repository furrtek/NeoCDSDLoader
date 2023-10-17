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
                  
; See pack_cheats.py or doc for data format

IGMSetupCheats:
	move.b  #1,IGMMode     ; Cheats mode
    clr.b   IGMCursor
    clr.b   IGMCursorShift

    jsr     DrawIGMBox
    jsr     DrawCheatList

    tst.b   IGMItems
    beq     .nocheats
	lea     StrCheats,a0
	DIIRQ
    move.w  #FIXMAP+9+(7*32),d0
	jsr     WriteFix
	ENIRQ
	rts

.nocheats:
    lea     StrNoCheats,a0
	move.w  #FIXMAP+9+(7*32),d0
	jmp     WriteFix
	rts


IGMVBLProcCheats:
    tst.b   IGMItems
    beq     .nocheats

    TESTREPEAT CNT_UP
    beq     .no_up
    tst.b   IGMCursor
    beq     .top
    ; Move cursor
    subq.b  #1,IGMCursor
    jsr     DrawCheatList
    bra     .no_up
.top:
    tst.b   IGMCursorShift
    beq     .no_up
    ; Scroll
    subq.b  #1,IGMCursorShift
    jsr     DrawCheatList
.no_up:

	TESTREPEAT CNT_DOWN
    beq     .no_down
    move.b  IGMCursor,d0
	add.b   IGMCursorShift,d0
	addq.b  #1,d0
    cmp.b   IGMItems,d0
    bhs     .no_down
    cmp.b   #MAX_CHEAT_LINES-1,IGMCursor		; Max lines at once
    beq     .scrolldown
    ; Move cursor
    addq.b  #1,IGMCursor
    jsr     DrawCheatList
    bra     .no_down
.scrolldown:
    ; Scroll
    addq.b  #1,IGMCursorShift
    jsr     DrawCheatList
.no_down:

    TESTCHANGE CNT_A
    beq     .no_a
    ; Toggle cheat
    moveq.l #1,d1
    move.b  IGMCursor,d0
	add.b   IGMCursorShift,d0
    lsl.l   d0,d1
    eor.l   d1,CheatsBitmap
    jsr     DrawCheatList
.no_a:

.nocheats:

    ; B press and release
    move.b  BIOS_P1CURRENT,d0
    move.b  BIOS_P1PREVIOUS,d1
    eor.b   d1,d0
    and.b   d1,d0
    andi.b  #1<<CNT_B,d0
    beq     .no_b
	tst.b   IGMItems		; No cheats found
    beq     .close
	tst.l   CheatsBitmap	; No cheats enabled
    beq     .close
    jsr     InstallCheats
.close:
    jsr     CloseIGM
.no_b:
    rts


DrawCheatList:
	; Search for NGH in cheat data
	clr.b   IGMItems
    lea     CheatData,a0
    movea.l a0,a2
    move.w  (a0)+,d7                ; Game count
    move.w  (a0)+,d0                ; Offset to dictionary
    lea     0(a2,d0),a2
    move.w  HEADER_NGH,d0
.search:
    cmp.w   (a0),d0
    beq     .found
    addq.l  #4,a0
    subq.b  #1,d7
    bne     .search
    bra     .done                   ; No cheats found
.found:
    ; Cheats found :D
    moveq.l #0,d0
    move.w  2(a0),d0                ; Get data offset
    lea     CheatData,a0
    lea     0(a0,d0),a0
    movea.l a0,CheatDataAddr        ; Store data address for this game for later

    move.b  (a0)+,d7                ; Cheats count
    move.b  d7,IGMItems
    beq     .done                   ; No cheats

    move.l  CheatsBitmap,d3
    move.b  #MAX_CHEAT_LINES,d6
    move.b  IGMCursor,d4
    move.b  IGMCursorShift,d1
    move.w  #32,REG_VRAMMOD
    move.w  #FIXMAP+11+(6*32),d2
    moveq.l #0,d5
.list:
    addq.l  #2,a0

    tst.b   d1
    beq     .drawline
    subq.b  #1,d1
.skipdesc:
    tst.b   (a0)+           ; Skip description text
    bne     .skipdesc
    lsr.l   #1,d3
    subq.b  #1,d7
    bne     .list

.drawline:
    ; Draw or clear cursor
    move.w  d2,REG_VRAMADDR
	move.w  #$E000,d0      ; Palette #14

    move.b  #' ',d0
    cmp.b   d5,d4
    bne     .nocur
    move.b  #CHAR_ARROW_RIGHT,d0
.nocur
    move.w  d0,REG_VRAMRW

    ; Draw tick boxes
	move.w  #$F000,d0      ; Palette #15
	move.w  d0,FixWriteConfig
    move.b  #CHAR_BOX,d0
    lsr.l   #1,d3
    bcc     .disabled
    move.b  #CHAR_BOX_CHECKED,d0
.disabled
    move.w  d0,REG_VRAMRW

	move.w  d2,d0
	addi.w  #64,d0
	jsr     WriteFixDict

    subq.b  #1,d7
    beq     .done       ; Reached last cheat
    subq.b  #1,d6
    beq     .done       ; Reached max lines

	addq.w  #1,d2       ; Next line
    addq.b  #1,d5
    bra     .list
.done:
	move.w  #$E000,FixWriteConfig   ; Palette #14
	
    ; Show or hide "more cheats" arrow
    move.w  #FIXMAP+19+(32*32),REG_VRAMADDR
    move.w  FixWriteConfig,d1
    move.b  #' ',d1
	move.b  IGMCursorShift,d0
	addi.b  #MAX_CHEAT_LINES,d0
    cmp.b   IGMItems,d0
    bhs     .no_arrow
    move.b  #CHAR_ARROW_DOWN,d1
.no_arrow:
    move.w  d1,REG_VRAMRW

    rts
