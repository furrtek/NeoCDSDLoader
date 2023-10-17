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

; Non UI-related routines are in sdips.asm

IGMSetupSDIP:
	move.b  #2,IGMMode     ; SDIP mode
    clr.b   IGMCursor

    jsr     DrawIGMBox
    jsr     InitSDIPList

    move.w  #FIXMAP+9+(6*32),d0
    tst.b   SDIPCount
    beq     .nosdips
	lea     StrSDIP,a0
	DIIRQ
	jsr     WriteFix
	ENIRQ
    jsr     DrawSDIP
    jsr     DrawSDIPCursor
    rts

.nosdips:
	lea     StrNoSDIP,a0
	DIIRQ
	jsr     WriteFix
	ENIRQ
	rts


IGMVBLProcSDIP:
    tst.b   SDIPCount
    beq     .nosdips

    TESTREPEAT CNT_UP
    beq     .no_up
    move.b  IGMCursor,d0
    beq     .no_up
    subq.b  #1,d0
    move.b  d0,IGMCursor
    cmp.b   #7,d0          ; Just went from 8 to 7
    bne     .done_up
    ; Go to first page
    jsr     ClearIGM
    jsr     DrawSDIP       ; Refresh display
.done_up:
    jsr     DrawSDIPCursor
.no_up:

	TESTREPEAT CNT_DOWN
    beq     .no_down
    move.b  IGMCursor,d0
    move.b  SDIPCount,d1
    subq.b  #1,d1          ; Count -> max
    cmp.b   d1,d0          ; Cursor on last item: no move
    bhs     .no_down
    addq.b  #1,d0
    move.b  d0,IGMCursor
    cmp.b   #8,d0          ; Just went from 7 to 8
    bne     .done_down
    ; Go to second page
    jsr     ClearIGM
    jsr     DrawSDIP       ; Refresh display
.done_down:
    jsr     DrawSDIPCursor
.no_down:

    TESTREPEAT CNT_LEFT
    beq     .no_left
    ; Look up required proc to decrease value
    jsr     GetSDIPEntryType
    lea     JT_SDIPDec,a1
    move.l  (a1,d0),a1
    jsr     GetSDIPValueCursor
    jsr     (a1)
    jsr     SetSDIPValue
    jsr     DrawSDIP       ; Refresh display
.no_left:

    TESTREPEAT CNT_RIGHT
    beq     .no_right
    ; Look up required proc to decrease value
    jsr     GetSDIPEntryType
    lea     JT_SDIPInc,a1
    move.l  (a1,d0),a1
    jsr     GetSDIPValueCursor
    jsr     (a1)
    jsr     SetSDIPValue
    jsr     DrawSDIP       ; Refresh display
.no_right:

    TESTCHANGE CNT_C
    beq     .no_c
    ; Copy default settings to BIOS_GAME_DIP
    move.l  SDIPAddr,a0
    lea     16(a0),a0      ; Skip game name
    lea     BIOS_GAME_DIP,a1
    move.l  (a0)+,(a1)+    ; Special settings
    move.w  (a0)+,(a1)+
    moveq.l #10,d7         ; Normal settings
.lpdef:
    move.b  (a0)+,d0
    lsr.b   #4,d0
    move.b  d0,(a1)+
    subq.b  #1,d7
    bne     .lpdef
    jsr     InitSDIPList
    jsr     DrawSDIP       ; Refresh display
.no_c:

.nosdips:

    ; B press and release
    move.b  BIOS_P1CURRENT,d0
    move.b  BIOS_P1PREVIOUS,d1
    eor.b   d1,d0
    and.b   d1,d0
    andi.b  #1<<CNT_B,d0
    beq     .no_b
    jsr     StoreSDIPs
    jsr     CloseIGM
.no_b:

    rts


DrawSDIPCursor:
	DIIRQ
	move.w  FixWriteConfig,d1

    ; Erase previous cursor
    moveq.l #0,d0
    move.b  PrevIGMCursor,d0
    andi.b  #7,d0
    addi.w  #FIXMAP+11+(7*32),d0
    move.w  d0,REG_VRAMADDR
    move.b  #' ',d1
    moveq.l #0,d0
    move.b  IGMCursor,d0
    move.w  d1,REG_VRAMRW

    ; Draw new cursor
    andi.b  #7,d0
    addi.w  #FIXMAP+11+(7*32),d0
    move.w  d0,REG_VRAMADDR
    move.b  #CHAR_ARROW_RIGHT,d1
    move.b  IGMCursor,PrevIGMCursor
    nop
    nop
    move.w  d1,REG_VRAMRW
    ENIRQ
    rts


DrawSDIP:
	DIIRQ
    lea     SDIPItems,a0
    cmp.b   #8,IGMCursor
    blo     .firstpage
    lea     4*8(a0),a0     ; Second page: skip first 8 entries
.firstpage:
    move.l  SDIPAddr,a1
    lea     32(a1),a1      ; String list

    move.w  #FIXMAP+11+(8*32),d2    ; First line position
	move.w  #32,REG_VRAMMOD

    moveq.l #8,d7          ; Max entries per page
.drawlp:
    moveq.l #0,d0
    move.b  (a0),d0        ; Get type and count
    cmp.b   #$FF,d0
    beq     .done
    move.l  d0,d3

    move.b  1(a0),d0       ; Get address of setting's first string
    mulu.w  #12,d0
    move.l  a1,a3
    add.l   d0,a3

    move.w  d2,REG_VRAMADDR
    jsr     DrawSDIPString

    moveq.l #0,d0
    move.b  3(a0),d0      ; Get value's index in BIOS_GAME_DIP
    jsr     GetSDIPValueIndex   ; Get value in d0

	move.w  #$F000,FixWriteConfig  ; Palette #15

    lsr.b   #4,d3
    add.b   d3,d3
    add.b   d3,d3
    lea     JT_SDIPDraw,a2
    move.l  (a2,d3),a2
    jsr     (a2)

	move.w  #$E000,FixWriteConfig  ; Palette #14

    lea     4(a0),a0      ; Next entry in SDIPItems

    addq.w  #1,d2         ; Next line
    subq.b  #1,d7
    bne     .drawlp

.done:
    ENIRQ
    rts

    
JT_SDIPDraw:
    dc.l SDIPDrawNormal
    dc.l SDIPDrawCount
    dc.l SDIPDrawTimer

SDIPDrawNormal:
    move.w  d2,d1
    addi.w  #13*32,d1

    mulu.w  #12,d0
    add.l   d0,a3

    move.w  d1,REG_VRAMADDR
    jsr     DrawSDIPString
    rts

SDIPDrawCount:
    move.w  d2,d1
    addi.w  #13*32,d1

    tst.b   d0
    beq     .without
    cmp.b   #100,d0
    bhs     .infinite

    move.w  d1,REG_VRAMADDR

    jsr     HexToBCD
    jsr     WriteByte

	move.b  #' ',d1        ; Clear 8 - 2 = 6 chars in case previous value was WITHOUT or INFINITE
    moveq.l #6,d6
.clearchar:
	nop
	move.w  d1,REG_VRAMRW
	subq.b  #1,d6
	bne     .clearchar
    rts
    
.without:
    movem.l a0,-(sp)
	lea     StrWITHOUT,a0
    move.w  d1,d0
	jsr     WriteFix
    movem.l (sp)+,a0
	rts

.infinite:
    movem.l a0,-(sp)
	lea     StrINFINITE,a0
    move.w  d1,d0
	jsr     WriteFix
    movem.l (sp)+,a0
	rts

SDIPDrawTimer:
    move.w  d2,d1
    addi.w  #(13*32)+(3*32),d1
    move.w  d1,REG_VRAMADDR

    jsr     WriteByte
    nop
    move.b  #'s',d1
	move.w  d1,REG_VRAMRW

    move.w  d2,d1
    addi.w  #(13*32),d1
    move.w  d1,REG_VRAMADDR

    lsr.w   #8,d0
    jsr     WriteByte
    nop
    move.b  #'m',d1
	move.w  d1,REG_VRAMRW
    rts

DrawSDIPString:
	move.w  FixWriteConfig,d1
    moveq.l #12,d6
.writename:
    nop
    move.b  (a3)+,d1
	move.w  d1,REG_VRAMRW
    subq.w  #1,d6
    bne     .writename
    rts
