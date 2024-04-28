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

IGMSetupLoadState:
	move.b  #4,IGMMode     ; Load State mode
    clr.b   IGMCursor
    clr.b   IGMCursorShift
    move.b  d0,REG_DIPSW

    ; Tell MCU to look for state file
    lea     MCUCmdParams,a0
    move.b  #1,(a0)+                ; Subcommand 1: List state files with matching NGH
    move.w  HEADER_NGH,d0
    move.b  d0,1(a0)
    lsr.w   #8,d0
    move.b  d0,(a0)
    MCUCMD  MCU_CMD_GETSAVES
    bcc     .notimeout
.timeout:
    jmp     DispErrorTimeout
.notimeout:
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    beq     .cmdok
.error:
    jmp     DispError
.cmdok:
    ; Ok, get file count
    tst.b   MCUReplyBuffer+1
    beq     .nofile

    ; TESTING: Close IGM but keep VBL for system ROM
    jsr     CloseIGM
    st.b    IsInIGM
    clr.b   BIOS_SYSTEM_MODE

    ;jsr     DrawIGMBox     ; Clear box

    ; DEBUG: Set up msgbox palette in case of errors
    lea     IGMPalettes,a0
	lea     (2*16*2)+PALETTES,a1
    jsr     CopyPalette
    move.b  #$0000,FixWriteConfig

	move.w  #$0600,d0           ; Stop CDDA
	jsr     CDDACommand

    ; TODO:
    ; Get region
    ; Copy data blocks one after the other

    ; Read first block (header)
    move.b  #0,MCUCmdParams    ; Use first file found
    move.w  #0,d0              ; Chunk #
    jsr     ReqChunk
	lea     CDSectorBuffer,a1        ; Retrieve chunk data
    jsr     GetCDSectorRaw

    lea     CDSectorBuffer,a0
    lea     SSBuffer,a1
    move.w  #(256/2)-1,d7
.copyheader:
    move.w  (a0)+,(a1)+
    dbra    d7,.copyheader

    ; Check NGH
    move.w  HEADER_NGH,d0
    cmp.w   SSBuffer+2,d0
    bne     .red

    move.l  SSBuffer+6,SSSP

    move.w  #0,CurDataBlock
    moveq.l #1,d5
    move.b  d0,REG_DIPSW
	move.w  #$2700,sr		   ; Disable all interrupts

.nextblock:
    moveq.l #0,d0              ; Get data block infos
    lea     SSBuffer+64,a2
    moveq.l #0,d2
    move.w  CurDataBlock,d2
    lsl.w   #3,d2              ; *8
    moveq.l #0,d4
    move.w  0(a2,d2),d4        ; Get type and bank
    
    cmp.w   #$FFFF,d4
    beq     .done

    move.l  d4,d0
    lsr.w   #8,d0
    lsl.w   #2,d0              ; *4
    lea     JT_SetLoad,a3
    move.l  0(a3,d0.w),a3      ; Get set function according to copy type code
    move.b  d4,d0              ; Bank in d0
    jsr     (a3)
    move.l  d4,d0
    lsr.w   #8,d0
    lsl.w   #2,d0              ; *4
    lea     JT_Loaders,a3
    move.l  0(a3,d0.w),a3      ; Get copy function according to copy type code

    lea     DebugStrTblCopyType,a1
    move.l  0(a1,d0),a0
    move.w  #FIXPOS(7,9),d0
	jsr     WriteFix

    moveq.l #0,d6
    move.w  2(a2,d2),d6        ; Get size
    move.l  4(a2,d2),a4        ; Get destination

    move.b  #1,REG_UPLOAD_EN

.loadblock:
    move.b  #0,MCUCmdParams    ; Use first file found
    move.w  d5,d0              ; Chunk #
    move.b  d0,REG_DIPSW
    jsr     ReqChunk
	lea     CDSectorBuffer,a1
    move.b  d0,REG_DIPSW
    jsr     GetCDSectorRaw

    move.b  d4,d0              ; Bank in d0
    move.l  a4,a1
    move.b  d0,REG_DIPSW
    jsr     (a3)

    move.l  d6,FixValueList
    lea     DebugStrLW,a0
    move.w  #(FIXMAP+10+(7*32)),d0    ;#FIXPOS(7,10),d0
	jsr     WriteFix
    move.l  a4,FixValueList
    lea     DebugStrLW,a0
    move.w  #(FIXMAP+11+(7*32)),d0    ;#FIXPOS(7,11),d0
	jsr     WriteFix

    addq.l  #1,d5              ; Next chunk
    subq.w  #1,d6
    bne     .loadblock

    move.b  #0,REG_UPLOAD_EN

    move.l  d4,d0
    lsr.w   #8,d0
    lsl.w   #2,d0              ; *4
    lea     JT_UnsetLoad,a3
    move.l  0(a3,d0.w),a3      ; Get unset function according to copy type code
    jsr     (a3)

    addq.w  #1,CurDataBlock
    bra     .nextblock

.done:
	move.w  #$2000,sr		   ; Enable all interrupts
    ;move    SSSP,sp
    rts


.red:
    move.w  #RED,BACKDROP
    move.w  #RED,PALETTES
    move.w  #RED,PALETTES+2
    move.w  #RED,PALETTES+4
    rts
.nofile:
    move.w  #YELLOW,BACKDROP
    move.w  #YELLOW,PALETTES
    move.w  #YELLOW,PALETTES+2
    move.w  #YELLOW,PALETTES+4
    rts

ReqChunk:
    move.b  d0,MCUCmdParams+2  ; LSB of block number
    lsr.w   #8,d0
    move.b  d0,MCUCmdParams+1  ; MSB of block number
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
    rts

IGMVBLProcLoadState:
    ; TODO
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
    
JT_SetLoad:
    dc.l SetPRG     ; 00: PRG words
    dc.l SetFIX     ; 01: FIX bytes
    dc.l SetSPR     ; 02: SPR words
    dc.l SetZ80     ; 03: Z80 bytes
    dc.l SetPCM     ; 04: PCM bytes
    dc.l SetNoop    ; 05: VRAM words
    dc.l SetNoop    ; 06: Palette words
    dc.l SetWRAM    ; 07: Work RAM words
    
SetWRAM:
	move.b  d0,REG_DIPSW
	rts

SetPRG:
	move.b  d0,REG_DIPSW
	;move.w  #$2700,sr		   ; Disable all interrupts
	rts
SetNoop:
    rts
SetFIX:
    move.b  #1,REG_DISBLFIX
    move.b  d0,REG_UPMAPFIX
    move.b  #5,REG_TRANSAREA
    rts
SetSPR:
    move.b  d0,REG_UPMAPSPR
    move.b  #0,REG_TRANSAREA
    move.b  d0,REG_SPRBANK
    rts
SetZ80:
    move.b  d0,REG_UPMAPZ80
    move.b  #4,REG_TRANSAREA
    rts
SetPCM:
    move.b  d0,REG_UPMAPPCM
    move.b  #1,REG_TRANSAREA
    move.b  d0,REG_PCMBANK
    rts

JT_UnsetLoad:
    dc.l UnsetPRG     ; 00: PRG words
    dc.l UnsetFIX     ; 01: FIX bytes
    dc.l UnsetSPR     ; 02: SPR words
    dc.l UnsetZ80     ; 03: Z80 bytes
    dc.l UnsetPCM     ; 04: PCM bytes
    dc.l UnsetNoop    ; 05: VRAM words
    dc.l UnsetNoop    ; 06: Palette words
    dc.l UnsetNoop    ; 07: Work RAM words
    
UnsetPRG:
	;move.w  #$2000,sr		   ; Enable all interrupts
	rts
UnsetNoop:
    rts
UnsetFIX:
    move.b  d0,REG_UPUNMAPFIX
    move.b  #0,REG_DISBLFIX
    rts
UnsetSPR:
    move.b  d0,REG_UPUNMAPSPR
    rts
UnsetZ80:
    move.b  d0,REG_UPUNMAPZ80
    rts
UnsetPCM:
    move.b  d0,REG_UPUNMAPPCM
    rts

; These are called with the bank # in d0, destination address in a4
JT_Loaders:
    dc.l LoadPRG    ; 00: PRG words
    dc.l LoadFIX    ; 01: FIX bytes
    dc.l LoadSPR    ; 02: SPR words
    dc.l LoadZ80    ; 03: Z80 bytes
    dc.l LoadPCM    ; 04: PCM bytes
    dc.l LoadVRAM   ; 05: VRAM words
    dc.l LoadPAL    ; 06: Palette words
    dc.l LoadWRAM   ; 07: Work RAM words

LoadWRAM:
    ; NO USE OF THE STACK ALLOWED STARTING HERE !

	move.w  #$2700,sr		   ; Disable all interrupts
	
    lea     $100000,a1
    move.l  #($10000/$800)-1,d6

    IF 0
.lockup:
	move.b  d0,REG_DIPSW
    move.w  #GREEN,BACKDROP
    move.w  #GREEN,PALETTES
    move.w  #GREEN,PALETTES+2
    move.w  #GREEN,PALETTES+4
    bra     .lockup
    ENDIF

.loadwramchunk:

    move.b  #$FF,d2
.wvbl:
    move.w  REG_LSPCMODE,d0
    lsr.w   #7,d0
    cmp.w   #$F8,d0
    bne     .wvbl
    ; B press
    move.b  REG_P1CNT,d0
    move.b  d2,d1
    move.b  d0,d2
    eor.b   d1,d0
    and.b   d1,d0
    andi.b  #1<<CNT_B,d0
    beq     .wvbl
.no_b:

    ; ReqChunk
    move.b  #0,MCUCmdParams    ; Use first file found
    move.w  d5,d0              ; Chunk #
    move.b  d0,REG_DIPSW
    move.b  d0,MCUCmdParams+2  ; LSB of block number
    lsr.w   #8,d0
    move.b  d0,MCUCmdParams+1  ; MSB of block number

    ;MCUCMD  MCU_CMD_LOADSAVE
    move.b  #MCU_CMD_LOADSAVE,d3

    ;MCUCommand
    ;clr.b   PollStatus         ; Stop periodic status polling until command is ack'd
    ;move.b  d3,LastMCUCmd
	move.w  d3,CPLDREG_DATA    ; Write to MCU, lower byte of CPLDREG_DATA

.lockup:
	move.b  d0,REG_DIPSW
    bra     .lockup


    ;jsr     MCUWaitAck
	moveq.l #0,d0
	; Wait for CPLDREG_STAT bit 0 (BYTE_PENDING) to be reset
	move.l  #TIMEOUT_ACK,d7
.wait:
    move.b  d0,REG_DIPSW       ; 16
    move.w  CPLDREG_STAT,d0    ; 12
    andi.w  #$0001,d0          ; 8
    beq     .done              ; 8
    subq.l  #1,d7              ; 8
    bne     .wait              ; 10 = 62, 5.167us
    move.b  #1,TimeOutStage
    bra     .timeout           ; Timeout occured
.done:
    moveq.l #32-1,d4           ; The command byte counts in the MCU's command buffer
    lea     MCUCmdParams,a0
.txparam:
    move.b  (a0)+,d0
	move.w  d0,CPLDREG_DATA    ; Write to MCU, lower byte of CPLDREG_DATA

    ;jsr     MCUWaitAck
	moveq.l #0,d0
	; Wait for CPLDREG_STAT bit 0 (BYTE_PENDING) to be reset
	move.l  #TIMEOUT_ACK,d7
.wait2:
    move.b  d0,REG_DIPSW       ; 16
    move.w  CPLDREG_STAT,d0    ; 12
    andi.w  #$0001,d0          ; 8
    beq     .done2             ; 8
    subq.l  #1,d7              ; 8
    bne     .wait2             ; 10 = 62, 5.167us
    move.b  #1,TimeOutStage
    bra     .timeout           ; Timeout occured
.done2:

    subq.b  #1,d4
    bne     .txparam

	move.w  d0,CPLDREG_EXEC

    ;jsr     MCUWaitExec
	moveq.l #0,d0
	; Wait for CPLDREG_STAT bit 1 (EXEC_PENDING) to be reset
	move.l  #TIMEOUT_EXEC,d7
.wait3:
    move.b  d0,REG_DIPSW       ; 16
    move.w  CPLDREG_STAT,d0    ; 12
    andi.w  #$0002,d0          ; 8
    beq     .done3              ; 8
    subq.l  #1,d7              ; 8
    bne     .wait3              ; 10 = 62, 5.167us
    move.b  #2,TimeOutStage
    bra     .timeout           ; Timeout occured
.done3:

    ;jsr     MCUWaitRefill
	moveq.l #0,d0
	; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
	move.l  #TIMEOUT_EXEC,d7
.wait4:
    move.b  d0,REG_DIPSW
    move.w  CPLDREG_STAT,d0    ; 12
    andi.w  #$0004,d0          ; 8
    beq     .done4              ; 8
    subq.l  #1,d7              ; 8
    bne     .wait4              ; 10 = 46
    move.b  #3,TimeOutStage
    bra     .timeout           ; Timeout occured
.done4:

    ; Read 4 words from the MCU (see doc) CHANGED
    ;jsr     MCURead4Words
    lea     MCUReplyBuffer,a0
	move.w  CPLDREG_DATA,(a0)+ ; 20 Read from MCU
	move.w  CPLDREG_DATA,(a0)+ ; Read from MCU
	move.w  CPLDREG_DATA,(a0)+ ; Read from MCU
	move.w  CPLDREG_DATA,(a0)+ ; Read from MCU

    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    beq     .cmdok
    jmp     DispError
.cmdok:

	;lea     CDSectorBuffer,a1
    move.b  d0,REG_DIPSW
    ;jsr     GetCDSectorRaw
	lea     CPLDREG_DATA,a0
	lea     CPLDREG_STAT,a2
	moveq.l #$0004,d1
	move.w  #256-1,d7 		   ; 256 * 8 = 2048 bytes
	move.b  d0,REG_DIPSW
.readsector:
	move.l  (a0),(a1)+         ; 20
	move.l  (a0),(a1)+         ; 20
.wait5:                         ; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
    move.w  (a2),d0            ; 8
    and.w   d1,d0              ; 4
    bne     .wait5              ; 10
    dbra    d7,.readsector     ; 10, total 72 for 8 bytes, 1302kB/s
	move.b  d0,REG_DIPSW

    addq.l  #1,d5              ; Next chunk
    dbra    d6,.loadwramchunk

    move.l  SSSP,FixValueList
    lea     DebugStrLW,a0
    move.w  #(FIXMAP+14+(7*32)),d0
	jsr     WriteFix

    IF 0
    move.b  #0,REG_UPLOAD_EN
    lea     MCUCmdParams,a0
    move.b  #0,(a0)                 ; Subcommand 0: Close file
    MCUCMD  MCU_CMD_STORESAVE
    bcs     .timeout
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .error
    ENDIF

    move.l  SSSP,sp
	move.w  #$2000,sr		   ; Enable all interrupts
    rts

.timeout:
    jmp     DispErrorTimeout    ; Stop everything



LoadVRAM:
    move.w  #1,REG_VRAMMOD
    move.w  a1,REG_VRAMADDR
    lea     CDSectorBuffer,a0
	move.l  #(2048/2)-1,d7     ; Block size in words
.vramcopy:
    nop
    nop
    move.w  (a0)+,REG_VRAMRW
    move.b  d0,REG_DIPSW
    nop
	dbra    d7,.vramcopy
	addi.l  #2048/2,a4
	rts

LoadPRG:
    jsr     LoadWords
    rts

LoadFIX:
    addi.l  #$E00000,a1
    jsr     LoadBytes
    rts

LoadSPR:
    addi.l  #$E00000,a1
    jsr     LoadWords
    rts

LoadZ80:
    addi.l  #$E00000,a1
    jsr     LoadBytes
    rts

LoadPCM:
    addi.l  #$E00000,a1
    jsr     LoadBytes
    rts

LoadPal:
    addi.l  #PALETTES,a1
    jsr     LoadWords
    rts
    
LoadBytes:
    lea     CDSectorBuffer,a0
	move.l  #(2048/2)-1,d7     ; Block size in words
    move.b  d0,REG_DIPSW
.copy:
    move.w  (a0)+,d0           ; AA BB    xx AA - Assemble word from 2 bytes
    move.b  d0,3(a1)
    lsr.w   #8,d0              ; xx AA
    move.b  d0,1(a1)
    lea     4(a1),a1
	dbra    d7,.copy
    addi.l  #2048*2,a4
    rts

LoadWords:
    lea     CDSectorBuffer,a0
	move.l  #(2048/2/4)-1,d7     ; Block size in words
    move.b  d0,REG_DIPSW
.copy:
    move.w  (a0)+,(a1)+
    move.w  (a0)+,(a1)+
    move.w  (a0)+,(a1)+
    move.w  (a0)+,(a1)+
	dbra    d7,.copy
    addi.l  #2048,a4
    rts


DebugStrTblCopyType:
    dc.l DebugStrPRG
    dc.l DebugStrFIX
    dc.l DebugStrSPR
    dc.l DebugStrZ80
    dc.l DebugStrPCM
    dc.l DebugStrVRAM
    dc.l DebugStrPAL
    dc.l DebugStrWRAM
DebugStrPRG:
    dc.b "PRG",0
DebugStrFIX:
    dc.b "FIX",0
DebugStrSPR:
    dc.b "SPR",0
DebugStrZ80:
    dc.b "Z80",0
DebugStrPCM:
    dc.b "PCM",0
DebugStrVRAM:
    dc.b "VRAM",0
DebugStrWRAM:
    dc.b "WRAM",0
DebugStrPAL:
    dc.b "PAL",0
DebugStrDone:
    dc.b "DONE :)",0
DebugStrLW:
    dc.b $F0,0
