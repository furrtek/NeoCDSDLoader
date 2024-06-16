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

; Soft DIPs format:
; There can be max 4 special settings + 10 normal settings = 14 lines
; These are shown in the MVS BIOS as 2 pages, first has max 8 lines, second has max 6
; Note: BIOS_GAME_DIP is already init by the original BIOS (see ReadCDDAFlagSDIPs).

; Ask to save contents of BIOS_GAME_DIP to the SD card
StoreSDIPs:
    ; Tell MCU to create file
    lea     MCUCmdParams,a0
    move.b  #1,(a0)                 ; Subcommand 1: Open file
    clr.b   2(a0)                   ; Force overwrite if file exists

    lea     3(a0),a0				; Move to filename string parameter
    ; Set filename to ASCII of game's NGH and append extension
    move.w  HEADER_NGH,d0
    moveq.l #4-1,d7
.convhex:
    rol.w   #4,d0
    move.b  d0,d1
    andi.b  #15,d1
    jsr     Hexify
    move.b  d1,(a0)+
    dbra    d7,.convhex
    move.b  #'.',(a0)+
    move.b  #'D',(a0)+
    move.b  #'I',(a0)+
    move.b  #'P',(a0)+
    move.b  #0,(a0)

    MCUCMD  MCU_CMD_STORESAVE
    bcs     .fail
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .fail

    ; Ok, send data one word at a time
    lea     MCUCmdParams,a0
    move.b  #2,(a0)+                ; Subcommand 2: Setup data transfer
    move.b  #(16/2)>>8,(a0)+  		; Entire BIOS_GAME_DIP data is 16 bytes
    move.b  #(16/2)&255,(a0)
    MCUCMD  MCU_CMD_STORESAVE
    bcs     .fail
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .fail

    lea     BIOS_GAME_DIP,a0   ; Already word-aligned
    move.l  #16/2,d4           ; Data size in words
.loop:
    move.w  (a0)+,CPLDREG_DATA ; Write to MCU
    jsr     MCUWaitAck
    bcs     .fail
    subq.b  #1,d4
    bne     .loop

    move.b  #0,MCUCmdParams    ; Subcommand 0: Close file
    MCUCMD  MCU_CMD_STORESAVE
    bcs     .fail
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .fail

	rts

.fail:
    ; Silently ignore errors in IGM, too much of a mess to handle and there shouldn't be any !

	rts
	

; Must be called just after IPL before passing control to game so we get HEADER_NGH set correctly
LoadSDIPs:
    ; Ask MCU for SDIP files list
    lea     MCUCmdParams,a0
    move.b  #1,(a0)+           ; Subcommand 1: List SDIP files with matching NGH
    move.w  HEADER_NGH,d0
    move.b  d0,1(a0)
    lsr.w   #8,d0
    move.b  d0,(a0)

    MCUCMD  MCU_CMD_GETSAVES
    bcs     .fail
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .fail
    ; Ok, get file count
    tst.b   MCUReplyBuffer+1
    beq     .fail		       ; No SDIP file found

	; Read file if found
    clr.b   MCUCmdParams	   ; There should be only one (or no) file in list

    ; Ask MCU for data
    move.b  #0,MCUCmdParams+1  ; MSB of block number
    move.b  #0,MCUCmdParams+2  ; LSB of block number
    MCUCMD  MCU_CMD_LOADSAVE   ; d4 should come out the same
    bcs     .fail
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .fail

    ; Ok, retrieve data
	lea     CPLDREG_DATA,a0
    lea     BIOS_GAME_DIP,a1   ; Already word-aligned
    move.l  #16/2,d4           ; Data size in words
.readdata:
	move.w  (a0),(a1)+
	subq.b  #1,d4
	bne     .readdata

	rts

.fail:
    ; Silently ignore errors in IGM, too much of a mess to handle and there shouldn't be any !

	rts


; Builds a list of the settings to facilitate display as a menu
; Each entry is 4 bytes:
; Byte, xxTTCCCC T=Type(0:normal, 1:count, 2:timer) C=Count(max-1)
; Byte, 12-char string index
; Byte, padding
; Byte, setting index (not address !) in BIOS_GAME_DIP (0~13), used to map menu cursor position to setting address
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
    lea     16(a0),a0      ; Skip game name string

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
    cmp.w   #$FFFF,(a0)+
    beq     SDIPUnused
    move.b  #2<<4,d1       ; Time special setting type
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
    cmp.b   #$FF,(a0)+
    beq     SDIPUnused
    move.b  #1<<4,d1       ; Count special setting type
    bra     SDIPAddEntry


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
    andi.w  #$00FF,d0	; Reset seconds
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
    ori.w   #$5900,d0	; Set seconds to 59
    sbcd.b  d1,d0
.mzero:
    rol.w   #8,d0
    rts

; Also multiply result by 4 to index jumptable
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
    move.b  2(a2,d0),d0    ; Skip over the two time (word) values: d1=2 -> +4, d1=3 -> +5...
    rts
.time:
    add.b   d0,d0
    move.w  0(a2,d0),d0    ; Read a time (word) value at d1=0 -> +0 or d1=1 -> +2
    rts

; d0.b/w: Set SDIP's value currently pointed by IGMCursor
; Uses d1 and a2
SetSDIPValue:
    jsr     GetSDIPIndexCursor
    lea     BIOS_GAME_DIP,a2
    cmp.b   #2,d1
    blo     .time
    move.b  d0,2(a2,d1)    ; Skip over the two time (word) values: d1=2 -> +4, d1=3 -> +5...
    rts
.time:
    add.b   d1,d1
    move.w  d0,0(a2,d1)    ; Write a time (word) value at d1=0 -> +0 or d1=1 -> +2
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

; List of games to ignore because they have Japanese-only soft DIPs strings
HideSoftDIPNGHs:
    dc.w $0027  ; minasan
    dc.w $0036  ; bakatono
    dc.w $0048  ; janshin
    dc.w $0206  ; marukodq
    dc.w $0203  ; moshougi
    dc.w $03E7  ; vliner
    dc.w $0000  ; EOL
