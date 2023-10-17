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

    IFDEF LOADTEST
SetupDebugLoading:
    ; Setup loading test
    move.w  #SCREEN_IDLE,CurrentScreen

    jsr     ClearFix

	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

	move.l  #0,DBGTotal         ; Total 512kB loading runs
	move.l  #0,DBGPass          ; Valid loading runs
	move.l  #0,DBGWrong         ; Failed loading runs
	move.l  #0,DBGLast          ; Address of last error (difference) found

    ; Select test data file (reserved index #200)
    moveq.b #200,MCUCmdParams   ; ii 00 00 00
    MCUCMD  MCU_CMD_SELECTGAME
    bcc     .notimeout
    jsr     DispErrorTimeout    ; Timeout during file selection
    rts
.notimeout:
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    jsr     CheckACK
    bcc     .cmdok
    rts
.cmdok:

    move.w  #SCREEN_DEBUGLOAD,CurrentScreen
	rts
	
VBLProcDebugLoading:
    ; Just refresh counters
	lea     FixValueList,a0
	move.l  DBGTotal,(a0)+
	move.l  DBGPass,(a0)+
	move.l  DBGWrong,(a0)+
	move.l  DBGLast,(a0)+
    lea     FixStrDebugLoad,a0
	move.w  #FIXMAP+12+(8*32),d0
	jsr     WriteFix

    ; Erase 512kB DRAM
    moveq.l #0,d0
	lea     $180000,a0
	move.w  #$8000,d7
.erase:
    move.l  d0,(a0)+
    move.l  d0,(a0)+
    move.l  d0,(a0)+
    move.l  d0,(a0)+
    subq.w  #1,d7
    bne     .erase

	move.l  #$180000,$10FEF4    ; SectorLoadDest
	move.l  #$111204,$10FEF8	; "CDSectorBuffer" -> SectorLoadBuffer
    move.l  #2048,$10FEFC       ; SectorLoadSize
    move.l  #$00020000,MSFCounter       ; Start MSF (2 seconds = LBA 0)
    move.w  #256,CDSectorCount  ; 512kB / 2048B = 256 sectors
.loadsectors:
	jsr     LoadCDSectorFromSD
	; Copy sector to DRAM
	moveq.l #0,d0
    jsr     RunDMADirect
    ; Inc destination pointer
    move.l  $10FEF4,d0          ; SectorLoadDest
    add.l   $10FEFC,d0          ; SectorLoadSize
    move.l  d0,$10FEF4          ; SectorLoadDest
	tst.w   CDSectorCount
	bne     .loadsectors
	
	; 512kB loaded, now test data validity
	; See lfsrdatagen tool
	move.l  #$3FFFFF,d3  ; lfsr
	lea     $180000,a0
	move.l  #$80000,d7
.check:
    move.w  d3,d1
    lsr.w   #8,d1
    cmp.b   (a0)+,d1
    bne     .wrong
    move.l  d3,d1   ; FEDCBA9876543210 fedcba9876543210
    swap.l  d1      ; fedcba9876543210 FEDCBA9876543210
    lsr.w   #5,d1   ; fedcba9876543210 -----FEDCBA98765
    eor.w   d3,d1
    lsr.l   #1,d3
    lsr.w   #1,d1   ; LSB goes in carry
    bcc     .zero
    eori.l  #1<<21,d3
.zero:
    subq.l  #1,d7
    bne     .check
	addq.l  #1,DBGPass
	bra     .done
.wrong:
    move.l  a0,DBGLast
	addq.l  #1,DBGWrong
.done:
	addq.l  #1,DBGTotal
    rts
    ENDIF


    IFDEF OLD_DEBUG_STUFF
SetupDebugComm:
    ; Setup MCU comm test
    move.w  #SCREEN_COMMTEST,CurrentScreen

    jsr     ClearFix

	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

	move.l  #0,DBGTotal
	move.l  #0,DBGPass
	move.l  #0,DBGWrong
	move.l  #0,DBGTimeout
	rts

SetupDebugSDInit:
	move.w  #SCREEN_DEBUGSD,CurrentScreen

    jsr     ClearFix

	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

    ; Tell MCU to init SD and get card type
    MCUCMD  MCU_CMD_INITSD
    bcc     .notimeout
    jsr     DispErrorTimeout
    rts
.notimeout:
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    jsr     CheckACK
    bcs     .done
    ; Ok, show SD card type
    lea     FixStrSDV1,a0
	move.b  MCUReplyBuffer+1,d0
	cmp.b   #1,d0
	beq     .sdv1
    lea     FixStrSDV2,a0
.sdv1:
	move.w  #FIXMAP+8+(4*32),d0
	jsr     WriteFix
.done:
    lea     FixStrBExit,a0
	move.w  #FIXMAP+18+(4*32),d0
	jsr     WriteFix
	rts

SetupDebugISOList:
	move.w  #SCREEN_DEBUGISO,CurrentScreen

    jsr     ClearFix

	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

    ; Tell MCU to get ISO files list
    MCUCMD  MCU_CMD_GETISOS
    bcc     .notimeout
    jsr     DispErrorTimeout
    rts
.notimeout:
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    jsr     CheckACK
    bcc     .cmdok
    rts
.cmdok:
    ; Ok, get file count

    moveq.l #0,d0
    move.b  MCUReplyBuffer+1,d0
	lea     FixValueList,a0
	move.l  d0,(a0)+
    lea     FixStrFileCount,a0
	move.w  #FIXMAP+8+(4*32),d0
	jsr     WriteFix

    lea     FixStrISOLoad,a0
	move.w  #FIXMAP+24+(4*32),d0
	jsr     WriteFix
	rts

SetupROMDump:
	move.w  #SCREEN_ROMDUMP,CurrentScreen

    jsr     ClearFix

	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

    lea     FixStrROMDump,a0
	move.w  #FIXMAP+12+(10*32),d0
	jsr     WriteFix
	rts
	
VBLProcROMDump:
    move.b  BIOS_P1CHANGE,d0
	btst    #CNT_A,d0
    beq     .no_a
    ; Confirm
    ; Tell MCU to dump console system ROM
    MCUCMD  MCU_CMD_DUMPROM
    bcc     .notimeout
    jsr     DispError
    rts
.notimeout:
    ; At this point, either an error is returned or a reset is fired
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    ; Check that command was processed ok
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    beq     .cmdok
    ; Not ok, show error text and abort
    lea     FixStrCmdDumpNOK,a0
	move.w  #FIXMAP+8+(4*32),d0
	jsr     WriteFix
.cmdok:
    ; Ok
.no_a:

    move.b  BIOS_P1CHANGE,d0
    btst    #CNT_B,d0
    beq     .no_b
    ; Cancel
    jsr     SetupMenu
.no_b:
    rts


VBLProcCommTest:
	lea     FixValueList,a0
	move.l  DBGTotal,(a0)+
	move.l  DBGPass,(a0)+
	move.l  DBGWrong,(a0)+
	move.l  DBGTimeout,(a0)+
	move.l  DBGLast,(a0)+
    lea     FixStrDebug,a0
	move.w  #FIXMAP+8+(8*32),d0
	jsr     WriteFix

    move.b  BIOS_P1CURRENT,d0
	btst    #CNT_A,d0
    bne     .press_a

	move.w  #MCU_CMD_TEST,CPLDREG_DATA
    jsr     MCUWaitAck
    tst.b   d0
    bne     .timeout
    move.l  DBGTotal,d4
	move.w  d4,CPLDREG_DATA
    jsr     MCUWaitAck
    tst.b   d0
    bne     .timeout
    moveq.l #0,d4
	move.w  d4,CPLDREG_DATA
    jsr     MCUWaitAck
    tst.b   d0
    bne     .timeout
	move.w  d4,CPLDREG_DATA
    jsr     MCUWaitAck
    tst.b   d0
    bne     .timeout
	move.w  d4,CPLDREG_DATA
    jsr     MCUWaitAck
    tst.b   d0
    bne     .timeout

	move.w  d0,CPLDREG_EXEC
    jsr     MCUWaitExec
    tst.b   d0
    bne     .timeout

    move.w  CPLDREG_DATA,d1     ; Read what the MCU replied
    jsr     MCUWaitAck
    tst.b   d0
    bne     .timeout

    move.l  d1,DBGLast
    move.l  DBGTotal,d0
    cmp.b   d0,d1               ; Check if it's the same byte we sent
    bne     .wrong
    addq.l  #1,DBGPass
    bra     .done
.wrong:
    addq.l  #1,DBGWrong
    bra     .done
.timeout:
    addq.l  #1,DBGTimeout
.done:
    addq.l  #1,DBGTotal
.press_a:

    move.b  BIOS_P1CHANGE,d0
	btst    #CNT_B,d0
    beq     .no_b
    jsr     SetupMenu
.no_b:

    rts


VBLProcDebugBExit:
    move.b  BIOS_P1CHANGE,d0
	btst    #CNT_B,d0
    beq     .no_b
    jsr     SetupMenu
.no_b:
    rts

VBLProcDebugISO:
    move.b  BIOS_P1CHANGE,d0
	btst    #CNT_A,d0
    beq     .no_a
    move.b  #0,d0
    jsr     LoadISO
.no_a:

    move.b  BIOS_P1CHANGE,d0
	btst    #CNT_B,d0
    beq     .no_b
    jsr     SetupMenu
.no_b:

	btst   	#7,$10F6B9			; "GameStartState"
	beq     .idle
	IF TARGET==1
	   ERROR ":("
    ELSE
	jmp     StartGameCD
	ENDIF
.idle:

    rts
    ENDIF
    