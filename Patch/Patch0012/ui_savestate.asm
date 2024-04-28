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

IGMSetupSaveState:
	move.b  #3,IGMMode     ; Save State mode
    clr.b   IGMCursor
    clr.b   IGMCursorShift
    move.b  d0,REG_DIPSW
    
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

    ; Tell MCU to create save state file
    lea     MCUCmdParams,a0
    move.b  #1,(a0)                 ; Subcommand 1: Open file
    clr.b   2(a0)                   ; DEBUG: Don't check if the file exists

    ; Set filename
    lea     3(a0),a0
    move.b  #'T',(a0)+
    move.b  #'e',(a0)+
    move.b  #'s',(a0)+
    move.b  #'t',(a0)+
    move.b  #'.',(a0)+
    move.b  #'S',(a0)+
    move.b  #'T',(a0)+
    move.b  #'A',(a0)+
    move.b  #0,(a0)

    MCUCMD  MCU_CMD_STORESAVE
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

	move.w  #$0600,d0           ; Stop CDDA
	jsr     CDDACommand

	; Prepare file header block
	jsr     ClearSSBuffer

	lea     SSBuffer,a0
	move.w  #$87A0,(a0)+       ; Save state magic "STA0"
	move.w  HEADER_NGH,(a0)+   ; Game NGH
    move.b  SettingCountry,d0
    andi.w  #3,d0
	move.w  d0,(a0)+           ; Current region
	move.l  SSSP,(a0)+         ; Saved stack pointer

    lea     SSBuffer+64,a0     ; Go to data entries list
    move.w  #$0500,(a0)+       ; Slow VRAM block
    move.w  #$8000*2/$800,(a0)+; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0500,(a0)+       ; Fast VRAM block
    move.w  #$800*2/$800,(a0)+ ; Size / 2kB
    move.l  #$00008000,(a0)+   ; Destination
    move.w  #$0600,(a0)+       ; PAL A block
    move.w  #$2000/$800,(a0)+  ; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0601,(a0)+       ; PAL B block
    move.w  #$2000/$800,(a0)+  ; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0100,(a0)+       ; FIX block
    move.w  #$20000/$800,(a0)+ ; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0300,(a0)+       ; Z80 block
    move.w  #$10000/$800,(a0)+ ; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0000,(a0)+       ; PRG A block
    move.w  #$100000/$800,(a0)+; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0000,(a0)+       ; PRG B block
    move.w  #($200000-$120000)/$800,(a0)+; Size / 2kB
    move.l  #$00120000,(a0)+   ; Destination
    IF 0
    move.w  #$0200,(a0)+       ; SPR A block
    move.w  #$100000/$800,(a0)+; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0201,(a0)+       ; SPR B block
    move.w  #$100000/$800,(a0)+; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0202,(a0)+       ; SPR C block
    move.w  #$100000/$800,(a0)+; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0203,(a0)+       ; SPR D block
    move.w  #$100000/$800,(a0)+; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0400,(a0)+       ; PCM A block
    move.w  #$80000/$800,(a0)+ ; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    move.w  #$0401,(a0)+       ; PCM B block
    move.w  #$80000/$800,(a0)+ ; Size / 2kB
    move.l  #$00000000,(a0)+   ; Destination
    ENDIF
    move.w  #$0700,(a0)+       ; WRAM block
    move.w  #$10000/$800,(a0)+ ; Size / 2kB
    move.l  #$00100000,(a0)+   ; Destination
	move.w  #$FFFF,(a0)+       ; EOF code

    ; Send header
    move.w  #256/2,d0          ; Block size in words
    jsr     SSStartNewTransfer
    bcs     .abort
    jsr     SendSSBuffer
    bcs     .abort

    ; Pad to 2048 bytes
	jsr     ClearSSBuffer
	move.l  #7-1,d6
.sendpad:
    move.w  #256/2,d0          ; Block size in words
    jsr     SSStartNewTransfer
    bcs     .abort
    jsr     SendSSBuffer
    bcs     .abort
    dbra    d6,.sendpad

    ; Run dumping script
    lea     DumpScript,a1
.next:
    move.w  (a1)+,d0
    beq     .end
    cmp.b   #$01,d0
    beq     .print      ; Command xx01: Print text
    cmp.b   #$02,d0     ; Command xx02: Call copy function
    beq     .copy
    move.l  (a1)+,a2    ; Any other command: Write byte bb-- to register
    lsr.w   #8,d0
    move.b  d0,(a2)
    bra     .next
.print:
    move.l  (a1)+,a0
    move.w  #FIXPOS(7,9),d0
	jsr     WriteFix
    bra     .next
.copy:
    ; Prepare data block header
	;lea     SSBuffer,a0
	move.w  (a1)+,d1           ; Get copy type and bank from script, d1 used further down
	moveq.l #0,d7
    move.w  (a1)+,d7           ; Get size from script
	;move.l  a2,(a0)+           ; Source address (used as Destination for loading) + copy type code cc
	;move.l  d7,(a0)+           ; Size

    ; Look up dumping function according to copy type
    move.l  a1,-(sp)           ; Push script pointer
    move.b  d1,d0              ; Bank in d0
    lsr.w   #8,d1              ; Copy type >>8
    lsl.w   #2,d1              ; Copy type <<2
    lea     JT_Dumpers,a0
    move.l  0(a0,d1.w),a1      ; Get copy function according to copy type code
    move.l  #0,a0              ; Source in a0
    move.b  d0,REG_DIPSW
    jsr     (a1)
    bcs     .fail
    move.l  (sp)+,a1           ; Pop script pointer
    bra     .next
.fail:
    move.l  (sp)+,a1           ; Pop script pointer
.abort:
    ; TODO
	lea     StrDebugSSFailed,a0
    move.w  #FIXPOS(7,9),d0
	jsr     WriteFix
	rts
.end:

;.debug:
    lea     MCUCmdParams,a0
    move.b  #0,(a0)                 ; Subcommand 0: Close file
    MCUCMD  MCU_CMD_STORESAVE       ; TODO: Make MCU write header magic only once the file is completely written !
    bcs     .timeout
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    bne     .error

	lea     StrDebugSSDone,a0
    move.w  #FIXPOS(7,9),d0
	jsr     WriteFix

	rts
	
; These are called with the bank # in d0, source address in a0, and size in d7.l
JT_Dumpers:
    dc.l DumpPRG    ; 00: PRG words
    dc.l DumpFIX    ; 01: FIX bytes
    dc.l DumpSPR    ; 02: SPR words
    dc.l DumpZ80    ; 03: Z80 bytes
    dc.l DumpPCM    ; 04: PCM bytes
    dc.l DumpVRAM   ; 05: VRAM words
    dc.l DumpPAL    ; 06: Palette words
    dc.l DumpWRAM   ; 07: Work RAM words
    

DumpPRG:
    tst.b   d0
    beq     .first
    addi.l  #$120000,a0
.first:
    jmp     DumpWords

DumpFIX:
    move.b  #1,REG_DISBLFIX
    addi.l  #$E00001,a0
    move.b  d0,REG_UPMAPFIX
    move.b  #$05,REG_TRANSAREA
    jsr     DumpBytes
    move.b  d0,REG_UPUNMAPFIX
    move.b  #0,REG_DISBLFIX
    rts

DumpSPR:
    addi.l  #$E00000,a0
    move.b  d0,REG_UPMAPSPR
    move.b  #$00,REG_TRANSAREA
    move.b  d0,REG_SPRBANK
    jsr     DumpWords
    move.b  d0,REG_UPUNMAPSPR
    rts

DumpZ80:
    addi.l  #$E00001,a0
    move.b  d0,REG_UPMAPZ80
    move.b  #$04,REG_TRANSAREA
    jsr     DumpBytes
    move.b  d0,REG_UPUNMAPZ80
    rts

DumpPCM:
    addi.l  #$E00001,a0
    move.b  d0,REG_UPMAPPCM
    move.b  #$01,REG_TRANSAREA
    move.b  d0,REG_PCMBANK
    jsr     DumpBytes
    move.b  d0,REG_UPUNMAPPCM
    rts

DumpPal:
    tst.b   d0
    beq     .bank0
    move.b  d0,REG_PALBANK1
    bra     .bank1
.bank0:
    move.b  d0,REG_PALBANK0
.bank1:
    addi.l  #PALETTES,a0
    jsr     DumpWords
    move.b  d0,REG_PALBANK1     ; Assume all games use bank 0 by default
    ; DEBUG: Set up msgbox palette in case of errors
    ;lea     IGMPalettes,a0
	;lea     (2*16*2)+PALETTES,a1
    ;jsr     CopyPalette
    rts
    
DumpWRAM:
    jmp     DumpWords

DumpScript:
    dc.w $0001      ; Print
    dc.l StrDebugSSVRAM
    dc.w $0002          ; Dump
    dc.w $0500          ; VRAM dump (slow)
    dc.w $8000*2/$800   ; Size / 2kB
    dc.w $0002          ; Dump
    dc.w $0501          ; VRAM dump (fast)
    dc.w $800*2/$800    ; Size / 2kB

    dc.w $0001          ; Print
    dc.l StrDebugSSPal
    dc.w $0002          ; Dump
    dc.w $0600          ; PAL dump
    dc.w $2000/$800     ; Size / 2kB
    dc.w $0002          ; Dump
    dc.w $0601          ; PAL dump
    dc.w $2000/$800     ; Size / 2kB

    dc.w $0001      ; Print
    dc.l StrDebugSSFix
    dc.w $0002          ; Dump
    dc.w $0100          ; FIX dump
    dc.w $20000/$800    ; Size / 2kB

    dc.w $0001      ; Print
    dc.l StrDebugSSZ80
    ; TODO: Reset Z80 ?
    dc.w $0002          ; Dump
    dc.w $0300          ; Z80 dump
    dc.w $10000/$800    ; Size / 2kB

    dc.w $0001      ; Print
    dc.l StrDebugSSPRG
    dc.w $0002          ; Dump
    dc.w $0000          ; PRG dump, part 0
    dc.w $100000/$800   ; Size / 2kB
    dc.w $0002          ; Dump
    dc.w $0001          ; PRG dump, part 1
    dc.w ($200000-$120000)/$800   ; Size / 2kB

    IF 0
    dc.w $0001      ; Print
    dc.l StrDebugSSSPR
    ; TODO: Disable sprites ?
    dc.w $0002          ; Dump
    dc.w $0200          ; SPR dump, bank 0
    dc.w $100000/$800   ; Size / 2kB
    dc.w $0002          ; Dump
    dc.w $0201          ; SPR dump, bank 1
    dc.w $100000/$800   ; Size / 2kB
    dc.w $0002          ; Dump
    dc.w $0202          ; SPR dump, bank 2
    dc.w $100000/$800   ; Size / 2kB
    dc.w $0002          ; Dump
    dc.w $0203          ; SPR dump, bank 3
    dc.w $100000/$800   ; Size / 2kB

    dc.w $0001      ; Print
    dc.l StrDebugSSPCM
    dc.w $0002          ; Dump
    dc.w $0400          ; PCM dump, bank 0
    dc.w $80000/$800    ; Size / 2kB
    dc.w $0002          ; Dump
    dc.w $0401          ; PCM dump, bank 1
    dc.w $80000/$800    ; Size / 2kB
    ENDIF
    
    dc.w $0001      ; Print
    dc.l StrDebugSSWRAM
    dc.w $0002          ; Dump
    dc.w $0007          ; WRAM dump
    dc.w $10000/$800    ; Size / 2kB

    dc.w 0          ; End



DumpVRAM:
    tst.b   d0                 ; Bank 1 means copy from fast VRAM
    beq     .slow
    addi.l  #$8000,a0
.slow:
    move.w  a0,REG_VRAMADDR
	lea     CPLDREG_DATA,a1
.vramblock:
	move.l  #2048/2,d0         ; Block size in words
    jsr     SSStartNewTransfer
    bcs     SSError
    move.b  d0,REG_DIPSW
	move.l  #(2048/2)-1,d6     ; Block size in words
.vramcopy:
    move.w  REG_VRAMRW,(a1)    ; Write to MCU
    addq.w  #1,a0
    move.w  a0,REG_VRAMADDR
    nop
    jsr     SSMCUWaitAck
    bcs     SSError
	dbra    d6,.vramcopy
    jsr     DebugSSPrintCountdown
	subq.w  #1,d7
    bne     .vramblock
    andi.b  #$FE,CCR
	rts
	

DebugSSPrintCountdown:
    movem.l d0/a0,-(sp)
	move.l  d7,FixValueList
	lea     StrDebugSSCountdown,a0
    move.w  #FIXPOS(14,9),d0
	jsr     WriteFix
    movem.l (sp)+,d0/a0
    rts


DumpBytes:
    move.l  #TIMEOUT_ACK,d3
    moveq.l #$0001,d4
	lea     CPLDREG_DATA,a1
	lea     CPLDREG_STAT,a2
.block:
	move.l  #2048/2,d0         ; Block size in words
    jsr     SSStartNewTransfer
    bcs     SSError
	move.l  #(2048/2)-1,d6     ; Block size in words
.copy:
    move.b  (a0),d0            ; xx AA - Assemble word from 2 bytes
    lsl.w   #8,d0              ; AA xx
    move.b  2(a0),d0           ; AA BB
    lea     4(a0),a0           ;
    move.w  d0,(a1)            ; Write to MCU

	; Wait for CPLDREG_STAT bit 0 (BYTE_PENDING) to be reset
	move.l  d3,d1              ; 4
.waitack:
    move.b  d0,REG_DIPSW
    move.w  (a2),d2            ; 8
    and.w   d4,d2              ; 4
    beq     .done              ; 10 taken
    subq.l  #1,d1
    bne     .waitack
    move.b  #1,TimeOutStage
    bra     SSError            ; Timeout occured
.done:

	dbra    d6,.copy           ; 10, total 94 for 2 bytes = 249kB/s
    jsr     DebugSSPrintCountdown
	subq.w  #1,d7
    bne     .block
    andi.b  #$FE,CCR
    rts


DumpWords:
    move.l  #TIMEOUT_ACK,d3
    moveq.l #$0001,d4
	lea     CPLDREG_DATA,a1
	lea     CPLDREG_STAT,a2
.block:
	move.l  #2048/2,d0         ; Block size in words
    jsr     SSStartNewTransfer
    bcs     SSError
    move.b  d0,REG_DIPSW
	move.l  #(2048/2)-1,d6     ; Block size in words
.copy:
    move.w  (a0)+,(a1)         ; 12 Write to MCU

	; Wait for CPLDREG_STAT bit 0 (BYTE_PENDING) to be reset
	move.l  d3,d1              ; 4
.waitack:
    move.b  d0,REG_DIPSW
    move.w  (a2),d2            ; 8
    and.w   d4,d2              ; 4
    beq     .done              ; 10 taken
    subq.l  #1,d1
    bne     .waitack
    move.b  #1,TimeOutStage
    bra     SSError            ; Timeout occured
.done:

	dbra    d6,.copy           ; 10, total 48 for 2 bytes = 488kB/s
    jsr     DebugSSPrintCountdown
	subq.w  #1,d7
    bne     .block
    andi.b  #$FE,CCR
    rts

    
SSError:
    jsr     DispError
    ori.b   #1,CCR
    rts


; Sets carry on timeout
SSMCUWaitAck:
	; Wait for CPLDREG_STAT bit 0 (BYTE_PENDING) to be reset
	move.l  #TIMEOUT_ACK,d0    ; 12
.wait:
    move.b  d0,REG_DIPSW
    move.w  CPLDREG_STAT,d2    ; 12
    andi.w  #$0001,d2          ; 8
    beq     .done              ; 10 taken
    subq.l  #1,d0
    bne     .wait
    move.b  #1,TimeOutStage
    ori.b   #1,CCR             ; Timeout occured
    rts
.done:
    andi.b  #$FE,CCR           ; 20 Ok
    rts                        ; 16


SSStartNewTransfer:
    movem.l d6/d7/a0/a1,-(sp)
    lea     MCUCmdParams,a0
    move.b  #2,(a0)            ; Subcommand 2: Setup data transfer
    move.b  d0,2(a0)           ; Data length
    lsr.w   #8,d0
    move.b  d0,1(a0)
    MCUCMD  MCU_CMD_STORESAVE
    bcc     .notimeout
.timeout:
    ori.b   #1,CCR
    bra     .abort
.notimeout:
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    beq     .cmdok
    ori.b   #1,CCR
    bra     .abort
.cmdok:
    andi.b  #$FE,CCR
.abort:
    movem.l (sp)+,d6/d7/a0/a1
    rts


IGMVBLProcSaveState:
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

ClearSSBuffer:
	moveq.l #0,d0
	lea     SSBuffer,a0
	moveq.l #(256/4)-1,d7
    move.b  d0,REG_DIPSW
.clear:
    move.l  d0,(a0)+
	dbra    d7,.clear
	rts

SendSSBuffer:
	lea     SSBuffer,a0
	lea     CPLDREG_DATA,a1
    move.l  #(256/2)-1,d7      ; Block size in words
.loop:
    move.w  (a0)+,(a1)         ; Write to MCU
    jsr     SSMCUWaitAck
    bcs     .abort
    dbra    d7,.loop
    andi.b  #$FE,CCR           ; Ok
.abort:
    rts
