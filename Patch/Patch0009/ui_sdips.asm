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

; There can be max 4 special settings + 10 normal settings = 14 lines
; These are shown like in the MVS BIOS as 2 pages, first has max 8 lines, second has max 6
; Note: BIOS_GAME_DIP is already init by the original BIOS (see ReadCDDAFlagSDIPs).

; Builds a list of the settings to facilitate display as a menu
; Each entry is 4 bytes:
; Byte, xxTTCCCC T=Type(0:normal, 1:count, 2:timer) C=Count(max+1)
; Byte, 12-char string index
; Byte, padding
; Byte, setting index in BIOS_GAME_DIP (0~13), used to map menu cursor position to setting address
InitSDIPList:
    lea     SDIPItems,a1
    moveq.l #0,d2          ; Current string index
    move.l  d2,d3          ; Entry index
    move.l  d2,d4          ; Enabled entry counter

    ; Hide Japanese-only soft DIPs options for a few games
    ; No space to load the Japanese charset for now
    lea     HideSoftDIPNGHs,a0
    move.w  HEADER_NGH,d0
.search:
    move.w  (a0)+,d1
    beq     .showsdips     ; Reached terminator
    cmp.w   d1,d0
    beq     .nosdips       ; Found NGH
    bra     .search
.showsdips:

    move.l  SDIPAddr,a0
    lea     16(a0),a0      ; Skip game name

    jsr     SDIPParseTime  ; Special setting 1
    jsr     SDIPParseTime  ; Special setting 2
    jsr     SDIPParseCount ; Special setting 3
    jsr     SDIPParseCount ; Special setting 4

    ; Simple settings
    moveq.l #10,d7
.ssloop:
    move.b  (a0)+,d0
    beq     .ssunused
    andi.b  #15,d0
    move.b  d0,(a1)+       ; Store type 0, count
    move.b  d2,(a1)+       ; Store string index
    move.w  d3,(a1)+       ; Store BIOS_GAME_DIP index
    add.b   d0,d2          ; Consumed count+1 strings
    addq.b  #1,d2
    addq.b  #1,d4          ; One more entry used
.ssunused:
    addq.b  #1,d3
    subq.b  #1,d7
    bne     .ssloop

.nosdips:
    st.b    (a1)+          ; List terminator
    move.b  d4,SDIPCount
    rts

SDIPParseTime:
    move.b  #2<<4,d1       ; Time special setting type
    cmp.w   #$FFFF,(a0)+
    beq     SDIPUnused
SDIPAddEntry:
    move.b  d1,(a1)+       ; Store type, count is implicit so unused
    move.b  d2,(a1)+       ; Store string index
    move.w  d3,(a1)+       ; Store BIOS_GAME_DIP index
    addq.b  #1,d2          ; Consumed 1 string
    addq.b  #1,d4          ; One more entry used
SDIPUnused:
    addq.b  #1,d3
    rts

SDIPParseCount:
    move.b  #1<<4,d1       ; Count special setting type
    cmp.b   #$FF,(a0)+
    beq     SDIPUnused
    bra     SDIPAddEntry


IGMSetupSDIP:
    clr.b   IGMCursor
	move.b  #2,IGMMode     ; SDIP mode

    jsr     DrawIGMBox
    jsr     InitSDIPList

    move.w  #FIXMAP+9+(6*32),d0
    tst.b   SDIPCount
    beq     .nosdips
	lea     StrSDIP,a0
	jsr     WriteFix
    jsr     DrawSDIP
    jsr     DrawSDIPCursor
    rts

.nosdips:
	lea     StrNoSDIP,a0
	jsr     WriteFix
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
    jsr     CloseIGM
.no_b:

    rts


JT_SDIPInc:
    dc.l    SDIPIncNormal
    dc.l    SDIPIncCount
    dc.l    SDIPIncTime

SDIPIncNormal:
    ; Increment value if lower than count
    move.b  IGMCursor,d1
    add.b   d1,d1
    add.b   d1,d1
    lea     SDIPItems,a0
    move.b  0(a0,d1),d1    ; Get count
    andi.b  #15,d1
    beq     .done          ; No options, just text line
    subq.b  #1,d1          ; Max = count - 1
    cmp.b   d1,d0
    bhs     .done
    addq.b  #1,d0
.done:
    rts

SDIPIncCount:
    ; Increment value if lower than 100
    cmp.b   #100,d0
    bhs     .done
    addq.b  #1,d0
.done:
    rts

SDIPIncTime:
    moveq.l #1,d1
    ; Increment seconds value
    cmp.b   #$59,d0
    bhs     .smax
    move.w  #0,ccr
    abcd.b  d1,d0
    rts
.smax:
    ; Increment minutes value
    ror.w   #8,d0
    cmp.b   #$29,d0
    bhs     .mmax
    andi.w  #$00FF,d0
    move.w  #0,ccr
    abcd.b  d1,d0
.mmax:
    rol.w   #8,d0
    rts



JT_SDIPDec:
    dc.l    SDIPDecByte
    dc.l    SDIPDecByte
    dc.l    SDIPDecTime

SDIPDecByte:
    ; Decrement byte value if non-zero
    tst.b   d0
    beq     .done
    subq.b  #1,d0
.done:
    rts

SDIPDecTime:
    moveq.l #1,d1
    ; Decrement seconds value
    tst.b   d0
    beq     .szero
    sbcd.b  d1,d0
    rts
.szero:
    ; Decrement minutes value
    ror.w   #8,d0
    tst.b   d0
    beq     .mzero
    ori.w   #$5900,d0
    sbcd.b  d1,d0
.mzero:
    rol.w   #8,d0
    rts


DrawSDIPCursor:
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
    rts


DrawSDIP:
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

    moveq.l #0,d1          ; Hex to BCD
    move.b  d0,d1
    divu.w  #10,d1
    move.w  d1,d0
    lsl.w   #4,d0
    swap.l  d1
    add.w   d1,d0

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

GetSDIPEntryType:
    lea     SDIPItems,a0
    moveq.l #0,d0
    move.b  IGMCursor,d0
    add.b   d0,d0
    add.b   d0,d0
    lea     0(a0,d0),a0
    move.b  (a0),d0
    lsr.b   #4,d0
    add.b   d0,d0
    add.b   d0,d0
    rts
    
; d0.b/w: Return SDIP's value currently pointed by IGMCursor
; Uses d1 and a2
GetSDIPValueCursor:
    jsr     GetSDIPIndexCursor
    move.b  d1,d0
; d0.b/w: Return SDIP's value indexed in BIOS_GAME_DIP by d0.b
GetSDIPValueIndex:
    lea     BIOS_GAME_DIP,a2
    cmp.b   #2,d0
    blo     .time
    move.b  2(a2,d0),d0    ; d0=2 -> +4, d0=3 -> +5, d0=4 -> +6, ...
    rts
.time:
    add.b   d0,d0
    move.w  0(a2,d0),d0
    rts

; d0.b/w: Set SDIP's value currently pointed by IGMCursor
; Uses d1 and a2
SetSDIPValue:
    jsr     GetSDIPIndexCursor
    lea     BIOS_GAME_DIP,a2
    cmp.b   #2,d1
    blo     .time
    move.b  d0,2(a2,d1)    ; d1=2 -> +4, d1=3 -> +5, d1=4 -> +6, ...
    rts
.time:
    add.b   d1,d1
    move.w  d0,0(a2,d1)
    rts

; d1.b: Return the index in BIOS_GAME_DIP of the SDIP currently pointed by IGMCursor
; Uses a2
GetSDIPIndexCursor:
    moveq.l #0,d1
    move.b  IGMCursor,d1
    add.b   d1,d1
    add.b   d1,d1
    lea     SDIPItems,a2
    move.b  3(a2,d1),d1
    rts


HideSoftDIPNGHs:
    dc.w $0027  ; minasan
    dc.w $0036  ; bakatono
    dc.w $0048  ; janshin
    dc.w $0206  ; marukodq
    dc.w $0203  ; moshougi
    dc.w $03E7  ; vliner
    dc.w $0000  ; Terminator
