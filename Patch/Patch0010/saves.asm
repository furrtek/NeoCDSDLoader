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

SetupSavesMenu:
    ; Set BIOS_COUNTRY_CODE to software setting
    move.b  SettingCountry,d0
	andi.b  #3,d0                   ; Sanitize
	move.b  d0,BIOS_COUNTRY_CODE
    ; Run the original "memory card" menu
    jmp     MemCardMenu


; d0: If non-zero, force save even if file exists
StoreSaves:
    ; Tell MCU to create file
    lea     MCUCmdParams,a0
    move.b  #1,(a0)                 ; Subcommand 1: Open file
    clr.b   2(a0)
    tst.b   d0
    bne     .nocheck
    addq.b  #1,2(a0)                ; Check if the file exists first
.nocheck:

    ; Copy filename to MCUCmdParams and append extension
    lea     FileNameBuffer,a1
    lea     3(a0),a0
    moveq.l #17,d7
.cp:
    move.b  (a1)+,d0
    beq     .nullchar
    move.b  d0,(a0)+
    subq.b  #1,d7
    bne     .cp
.nullchar:
    move.b  #'.',(a0)+
    move.b  #'S',(a0)+
    move.b  #'A',(a0)+
    move.b  #'V',(a0)+
    move.b  #0,(a0)

    MCUCMD  MCU_CMD_STORESAVE
    bcc     .notimeout
.storefailtimeout:
    jmp     DispErrorTimeout
.notimeout:
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    beq     .cmdok
    ; Does file already exist ?
    cmp.b   #3,MCUReplyBuffer+1
    bne     .error
    ; Yes: warn user
    move.b  #SFX_NEG,d0
    jsr     PlaySFX
    lea     FixStrFileExists,a0
    lea     ExitFileExists,a1
    jmp     MessageBoxCustom
.error:
    jmp     DispError
.cmdok:

    ; Ok, send data one word at a time
    lea     MCUCmdParams,a0
    move.b  #2,(a0)+                ; Subcommand 2: Setup data transfer
    move.b  #((8192+2)/2)>>8,(a0)+  ; Entire save data is 8kB + 2 checksum bytes (in words)
    move.b  #((8192+2)/2)&255,(a0)
    MCUCMD  MCU_CMD_STORESAVE
    bcs     .storefailtimeout
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .error

    lea     MEMCARD+1,a0       ; Save data is on odd bytes
    move.l  #8192/2,d4         ; Block size in words, entire save data is 8kB
    moveq.l #0,d6              ; Checksum accumulator
    moveq.l #0,d1              ; Make sure upper bits are cleared
.loop:
    move.b  0(a0),d1           ; Assemble word from 2 bytes
    add.w   d1,d6
    move.b  d1,d0
    lsl.w   #8,d0
    move.b  2(a0),d1
    add.w   d1,d6
    move.b  d1,d0
    move.w  d0,CPLDREG_DATA    ; Write to MCU
    jsr     MCUWaitAck
    bcs     .storefailtimeout
    addq.l  #4,a0
    subq.w  #1,d4
    bne     .loop

    move.w  d6,CPLDREG_DATA    ; Send checksum
    jsr     MCUWaitAck
    bcs     .storefailtimeout

    move.b  #0,MCUCmdParams    ; Subcommand 0: Close file
    MCUCMD  MCU_CMD_STORESAVE
    bcs     .storefailtimeout
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .error

    move.b  #SFX_POS,d0
    jsr     PlaySFX
    lea     FixStrSaveStored,a0
    jmp     MessageBox

ExitFileExists:
    TESTCHANGE CNT_A
    beq     .no_a
    st.b    d0                 ; Force save
    jsr     StoreSaves
.no_a:
    rts


; d0.b: Save file index
LoadSaves:
    move.b  d0,MCUCmdParams
    ; First, load to compute checksum without storing in MEMCARD area
    ; CHANGED ! Direct copy to MEMCARD now because low RAM
    lea     MEMCARD+1,a1       ; Data in MEMCARD is on odd bytes
    moveq.l #0,d4              ; Chunk counter
    moveq.l #0,d6              ; Checksum accumulator
.loadchunk:
    ; Ask MCU for 2kB of the save file data
    move.b  #0,MCUCmdParams+1  ; MSB of block number
    move.b  d4,MCUCmdParams+2  ; LSB of block number
    MCUCMD  MCU_CMD_LOADSAVE   ; d4 should come out the same
    bcc     .notimeout
    jmp     DispErrorTimeout
.notimeout:
    ; Read 4 words from the MCU (see doc) CHANGED
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    beq     .cmdok
    jmp     DispError
.cmdok:
    ; Ok, retrieve chunk data
	lea     CPLDREG_DATA,a0

	cmp.b   #4,d4              ; 4 chunks of 2kB = whole 8kB save file
    beq     .checkcsum
	addq.b  #1,d4

    ; Read data and update checksum
	move.w  #2048/2,d7 		   ; Load chunk in words
	move.w  #$00FF,d2
.readdata:
	move.w  (a0),d0            ; Get two bytes at once
	move.w  d0,d1
	move.b  d0,2(a1)           ; Store LSB
    lsr.w   #8,d0
	move.b  d0,(a1)            ; Store MSB
    addq.l  #4,a1
    add.w   d0,d6              ; High
    and.w   d2,d1
    add.w   d1,d6              ; Low
	subq.w  #1,d7
	bne     .readdata
	bra     .loadchunk
.checkcsum:

    ; Get checksum and compare
	move.w  (a0),d0
	cmp.w   d6,d0
	beq     .csum_ok
	; Checksum mismatch
    move.b  #SFX_NEG,d0
    jsr     PlaySFX
    lea     FixStrSaveChkError,a0
    jmp     MessageBox
.csum_ok:

    move.b  #SFX_POS,d0
    jsr     PlaySFX
    lea     FixStrSaveLoaded,a0
    jmp     MessageBox


; d0.b: Save file index
DeleteSaves:
    lea     MCUCmdParams,a0
    move.b  #3,(a0)+                ; Subcommand 3: Delete file
    move.b  d0,(a0)
    MCUCMD  MCU_CMD_STORESAVE
    bcc     .notimeout
    jmp     DispErrorTimeout
.notimeout:
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    beq     .cmdok
    jmp     DispError
.cmdok:

    move.b  #SFX_POS,d0
    jsr     PlaySFX
    rts
