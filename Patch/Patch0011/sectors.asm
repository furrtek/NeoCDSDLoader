; Copyright (C) 2021 Sean Gonsalves
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

IncMSF:
	; For original progressbar update:
	move.l  $10F690,d0
	add.l   $10F68C,d0         ; Inc value, computed from total size of data to load
	cmpi.l  #$800000,d0
	bls     .nocap
	move.l  #$800000,d0
.nocap:
	move.l  d0,$10F690

    subq.w  #1,CDSectorCount
	move.w  CDSectorCount,$10F688  ; SectorCounter

	; Copied from TOP-SP1-2 @ $10586
    lea     MSFCounter+2,a0     ; Start at Frames
    move.b  (a0),d0
    moveq   #1,d1
    move.w  #0,ccr
    abcd    d1,d0               ; Inc frames
    move.b  d0,(a0)
    cmpi.b  #$75,d0
    bcs.w   .incdone
    clr.b   (a0)                ; Clear Frames
    subq.l  #1,a0               ; Do Seconds
    move.b  (a0),d0
    move.w  #0,ccr
    abcd    d1,d0               ; Inc Seconds
    move.b  d0,(a0)
    cmpi.b  #$60,d0
    bcs.w   .incdone
    clr.b   (a0)                ; Clear Seconds
    subq.l  #1,a0               ; Do Minutes
    move.b  (a0),d0
    move.w  #0,ccr
    abcd    d1,d0               ; Inc Minutes
    move.b  d0,(a0)
.incdone:
    rts
    

; Ask MCU for a CD sector
; MSFCounter: Requested MSF
ReqCDSector:
    move.l  MSFCounter,MCUCmdParams
    MCUCMD  MCU_CMD_LOADSECT
    bcc     .notimeout
    jsr     DispErrorTimeout
.lockup:
    bra     .lockup
.notimeout:
    jsr     MCURead4Words
    jsr     CheckACK
    bcs     .lockup
    rts

    
; Load an entire CD sector
; a1: Destination
GetCDSectorRawFull:
	lea     CPLDREG_DATA,a0
	lea     CPLDREG_STAT,a2
	moveq.l #$0004,d1
	move.w  #256-1,d7 		   ; 256 * 8 = 2048 bytes
	move.b  d0,REG_DIPSW
	move.w  #$2700,sr		   ; Disable all interrupts
.readsector:
	move.l  (a0),(a1)+         ; 20
	move.l  (a0),(a1)+         ; 20
.wait:                         ; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
    move.w  (a2),d0            ; 8
    and.w   d1,d0              ; 4
    bne     .wait              ; 10
    dbra    d7,.readsector     ; 10, total 72 for 8 bytes, 1302kB/s
	move.b  d0,REG_DIPSW
	move.w  #$2000,sr		   ; Enable all interrupts
	rts
	

GetCDSectorRawHead:
    ; Byte-per-byte copy for first part of partial sector
    ; No need to finish reading the whole sector, the MCU won't complain
	lea     CPLDREG_DATA,a0
	lea     CPLDREG_STAT,a2
	moveq.l #$0004,d1
    move.l  SectorLoadSize(a5),d7
	move.b  d0,REG_DIPSW
	move.w  #$2700,sr		   ; Disable all interrupts
.readsector:
	move.l  (a0),d0            ; AA BB CC DD

    REPT 4
	rol.l   #8,d0
    move.b  d0,(a1)+           ; BB CC DD AA
	subq.l  #1,d7
	beq     .done
	ENDM

	move.l  (a0),d0            ; AA BB CC DD

    REPT 4
	rol.l   #8,d0
    move.b  d0,(a1)+           ; BB CC DD AA
	subq.l  #1,d7
	beq     .done
	ENDM

.wait:                         ; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
    move.w  (a2),d0
    and.w   d1,d0
    bne     .wait
    bra     .readsector
.done:

	move.b  d0,REG_DIPSW
	move.w  #$2000,sr		   ; Enable all interrupts
	rts


GetCDSectorRawTail:
    ; Byte-per-byte copy for last part of partial sector
	lea     CPLDREG_DATA,a0
	lea     CPLDREG_STAT,a2
	move.l  #2048,d1
    move.l  SectorLoadSize(a5),d7
    sub.l   d7,d1              ; How many bytes to skip at the beginning
	move.b  d0,REG_DIPSW
	move.w  #$2700,sr		   ; Disable all interrupts
.readsector:
	move.l  (a0),d0            ; AA BB CC DD

    REPT 4
	rol.l   #8,d0
	tst.w   d1
	beq     .a
	subq.w  #1,d1
	bra     .b
.a:
    move.b  d0,(a1)+
	subq.l  #1,d7
	beq     .done
.b:
	ENDM

	move.l  (a0),d0            ; AA BB CC DD

    REPT 4
	rol.l   #8,d0
	tst.w   d1
	beq     .a
	subq.w  #1,d1
	bra     .b
.a:
    move.b  d0,(a1)+
	subq.l  #1,d7
	beq     .done
.b:
	ENDM

.wait:                         ; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
    move.w  (a2),d0
    and.w   #$0004,d0
    bne     .wait
    bra     .readsector
.done:

	move.b  d0,REG_DIPSW
	move.w  #$2000,sr		   ; Enable all interrupts
	rts
	
	
GetCDSectorBytesHead:
    ; Byte-per-byte copy for first part of partial sector
    ; No need to finish reading the whole sector, the MCU won't complain
	lea     CPLDREG_DATA,a0
	lea     CPLDREG_STAT,a2
	moveq.l #$0004,d1
    move.l  SectorLoadSize(a5),d7
	move.b  d0,REG_DIPSW
	move.w  #$2700,sr		   ; Disable all interrupts
.readsector:
	move.l  (a0),d0            ; 12 AA BB CC DD
	move.l  (a0),d2            ; 12 AA BB CC DD

	move.l  d0,d3              ; 4
	swap    d3                 ; 4  CC DD AA BB
	rol.l   #8,d0              ; 24 BB CC DD AA
	move.w  d0,(a1)+           ; 8  xx AA
	subq.l  #1,d7
	beq     .done
	move.w  d3,(a1)+           ; 8  xx BB
	subq.l  #1,d7
	beq     .done
	swap    d0                 ; 4  DD AA BB CC
	move.w  d0,(a1)+           ; 8  xx CC
	subq.l  #1,d7
	beq     .done
	swap    d3                 ; 4  AA BB CC DD
	move.w  d3,(a1)+           ; 8  xx DD
	subq.l  #1,d7
	beq     .done

	move.l  d2,d3              ; 4
	swap    d3                 ; 4  CC DD AA BB
	rol.l   #8,d2              ; 24 BB CC DD AA
	move.w  d2,(a1)+           ; 8  xx AA
	subq.l  #1,d7
	beq     .done
	move.w  d3,(a1)+           ; 8  xx BB
	subq.l  #1,d7
	beq     .done
	swap    d2                 ; 4  DD AA BB CC
	move.w  d2,(a1)+           ; 8  xx CC
	subq.l  #1,d7
	beq     .done
	swap    d3                 ; 4  AA BB CC DD
	move.w  d3,(a1)+           ; 8  xx DD
	subq.l  #1,d7
	beq     .done

.wait:                         ; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
    move.w  (a2),d0
    and.w   d1,d0
    bne     .wait
    bra     .readsector
.done:

	move.b  d0,REG_DIPSW
	move.w  #$2000,sr		   ; Enable all interrupts
	rts


GetCDSectorBytesTail:
    ; Byte-per-byte copy for last part of partial sector
	lea     CPLDREG_DATA,a0
	lea     CPLDREG_STAT,a2
	move.l  #2048,d1
    move.l  SectorLoadSize(a5),d7
    sub.l   d7,d1              ; How many bytes to skip at the beginning
	move.b  d0,REG_DIPSW
	move.w  #$2700,sr		   ; Disable all interrupts
.readsector:

    REPT 2
	move.l  (a0),d0            ; 12 AA BB CC DD

	move.l  d0,d3              ; 4
	swap    d3                 ; 4  CC DD AA BB
	rol.l   #8,d0              ; 24 BB CC DD AA
	tst.w   d1
	beq     .copy1
	subq.w  #1,d1
	bra     .skip1
.copy1:
	move.w  d0,(a1)+           ; 8  xx AA
.skip1:
	tst.w   d1
	beq     .copy2
	subq.w  #1,d1
	bra     .skip2
.copy2:
	move.w  d3,(a1)+           ; 8  xx BB
.skip2:
	swap    d0                 ; 4  DD AA BB CC
	tst.w   d1
	beq     .copy3
	subq.w  #1,d1
	bra     .skip3
.copy3:
	move.w  d0,(a1)+           ; 8  xx CC
.skip3:
	swap    d3                 ; 4  AA BB CC DD
	tst.w   d1
	beq     .copy4
	subq.w  #1,d1
	bra     .skip4
.copy4:
	move.w  d3,(a1)+           ; 8  xx DD
.skip4:
    ENDM

.wait:                         ; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
    move.w  (a2),d0
    and.w   #$0004,d0
    bne     .wait
    bra     .readsector
.done:

	move.b  d0,REG_DIPSW
	move.w  #$2000,sr		   ; Enable all interrupts
	rts
	

LoadPRGSectorFromSD:
	move.b  d0,REG_DIPSW
	; Needed for Double Dragon ! Loads "DDVCT.PRG" which is smaller than a CD sector
	tst.w   CDSectorCount
	beq     .exit

    movem.l d0/d1/d3/d7/a0-a2,-(sp)
    jsr     ReqCDSector
    move.b  #1,REG_UPLOAD_EN

	movea.l SectorLoadDest(a5),a1
    cmp.l   #2048,SectorLoadSize(a5)
    beq     .full
    jsr     GetCDSectorRawHead
    bra     .done
.full:
    jsr     GetCDSectorRawFull
.done:
    move.b  #0,REG_UPLOAD_EN

    ; Update progress
    move.l  SectorLoadDest(a5),d0
    add.l   SectorLoadSize(a5),d0
    move.l  d0,SectorLoadDest(a5)
    jsr     IncMSF
    movem.l (sp)+,d0/d1/d3/d7/a0-a2

.exit:
    rts


LoadSPRSectorFromSD:
	move.b  d0,REG_DIPSW
	; Not needed ?
	tst.w   CDSectorCount
	beq     .exit

    movem.l d0/d1/d3/d7/a0-a2,-(sp)
    jsr     ReqCDSector
    move.b  #1,REG_UPLOAD_EN

    move.l  SectorLoadSize(a5),SectorLoadCounter(a5)
    move.l  SectorLoadCounter(a5),d0
    beq     .done
    ; if SectorLoadSize + SectorLoadDest > $100000, we need to cross a bank boundary
    add.l   SectorLoadDest(a5),d0
    cmp.l   #$100000,d0
    bls     .fullsector             ; If not: simply load a full sector
    move.l  #$100000,d0             ; If so:
    sub.l   SectorLoadDest(a5),d0   ; Compute size of first part of sector ($100000 - SectorLoadDest)
    move.l  d0,SectorLoadSize(a5)
    move.l  SectorLoadCounter(a5),d1
    sub.l   d0,d1                   ; Compute what will be left to load (SectorLoadSize - SectorLoadCounter)
    move.l  d1,SectorLoadCounter(a5)
    move.l  #$E00000,d0
	add.l   SectorLoadDest(a5),d0
	movea.l d0,a1
    jsr     GetCDSectorRawHead      ; Load first part of sector (will end at exactly $100000)
    jsr     ReqCDSector             ; Reload same sector for the second part
    addq.b  #1,BankCounter(a5)      ; Go to next bank
    move.b  BankCounter(a5),REG_SPRBANK
    clr.l   SectorLoadDest(a5)      ; New destination is the start of the new bank
    move.l  SectorLoadCounter(a5),SectorLoadSize(a5)
    move.l  #$E00000,a1
    jsr     GetCDSectorRawTail      ; Load second part of sector
    move.l  SectorLoadDest(a5),d0
    add.l   SectorLoadSize(a5),d0
    bra     .done

.fullsector:
    move.l  #$E00000,d0
	add.l   SectorLoadDest(a5),d0
	movea.l d0,a1
    jsr     GetCDSectorRawFull

    ; Update progress
    move.l  SectorLoadDest(a5),d0
    add.l   SectorLoadSize(a5),d0
.done:
    move.l  d0,SectorLoadDest(a5)
    jsr     IncMSF

    move.b  #0,REG_UPLOAD_EN

    movem.l (sp)+,d0/d1/d3/d7/a0-a2
.exit:
    rts



LoadPCMSectorFromSD:
	move.b  d0,REG_DIPSW

    movem.l d0/d1/d2/d3/d7/a0-a2,-(sp)
    jsr     ReqCDSector
    move.b  #1,REG_UPLOAD_EN

    move.l  SectorLoadSize(a5),SectorLoadCounter(a5)
    move.l  SectorLoadCounter(a5),d0
    beq     .done
    ; if SectorLoadSize*2 + SectorLoadDest > $100000, we need to cross a bank boundary
    add.l   d0,d0
    add.l   SectorLoadDest(a5),d0
    cmp.l   #$100000,d0
    bls     .fullsector             ; If not: simply load a full sector
    move.l  #$100000,d0             ; If so:
    sub.l   SectorLoadDest(a5),d0   ; Compute size of first part of sector ($100000 - SectorLoadDest)
    lsr.l   #1,d0
    move.l  d0,SectorLoadSize(a5)
    move.l  SectorLoadCounter(a5),d1
    sub.l   d0,d1                   ; Compute what will be left to load (SectorLoadSize - SectorLoadCounter)
    move.l  d1,SectorLoadCounter(a5)
    move.l  #$E00000,d0
	add.l   SectorLoadDest(a5),d0
	movea.l d0,a1
    jsr     GetCDSectorBytesHead    ; Load first part of sector (will end at exactly $100000)
    jsr     ReqCDSector             ; Reload same sector for the second part
    addq.b  #1,BankCounter(a5)      ; Go to next bank
    move.b  BankCounter(a5),REG_PCMBANK
    clr.l   SectorLoadDest(a5)      ; New destination is the start of the new bank
    move.l  SectorLoadCounter(a5),SectorLoadSize(a5)
    move.l  #$E00000,a1
    jsr     GetCDSectorBytesTail    ; Load second part of sector
    bra     .done

.fullsector:
    move.l  #$E00000,d0
    add.l   SectorLoadDest(a5),d0
	movea.l d0,a1

	lea     CPLDREG_DATA,a0
	lea     CPLDREG_STAT,a2
	moveq.l #$0004,d1

	move.w  #256-1,d7 		   ; Read whole CD sector 256*8=2048 bytes
	move.b  d0,REG_DIPSW
	move.w  #$2700,sr		   ; Disable all interrupts
.readsector:
    REPT 2
	move.l  (a0),d0            ; 12 AA BB CC DD
	move.l  d0,d3              ; 4
	swap    d3                 ; 4  CC DD AA BB
	rol.l   #8,d0              ; 24 BB CC DD AA
	move.w  d0,(a1)+           ; 8  xx AA
	move.w  d3,(a1)+           ; 8  xx BB
	swap    d0                 ; 4  DD AA BB CC
	move.w  d0,(a1)+           ; 8  xx CC
	swap    d3                 ; 4  AA BB CC DD
	move.w  d3,(a1)+           ; 8  xx DD
    ENDM

.wait:                         ; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
    move.w  (a2),d0            ; 8
    and.w   d1,d0              ; 4
    bne     .wait              ; 10

    dbra    d7,.readsector     ; 10, total 200 for 8 bytes, 468kB/s
	move.b  d0,REG_DIPSW
	move.w  #$2000,sr		   ; Enable all interrupts

.done:
    move.l  SectorLoadDest(a5),d0
    add.l   SectorLoadSize(a5),d0
    add.l   SectorLoadSize(a5),d0
    cmpi.l  #$100000,d0
    bcs     .loc_C0BE7E
    addq.b  #1,BankCounter(a5)
    move.b  BankCounter(a5),REG_PCMBANK
    clr.l   d0
.loc_C0BE7E:
    move.l  d0,SectorLoadDest(a5)

    jsr     IncMSF

    move.b  #0,REG_UPLOAD_EN

    movem.l (sp)+,d0/d1/d2/d3/d7/a0-a2
    rts


; MAKE SURE THIS PRESERVES USED REGISTERS !
LoadCDSectorFromSD:
	move.b  d0,REG_DIPSW
	; Not needed ?
	tst.w   CDSectorCount
	beq     .exit
    movem.l d0/d1/d3/d7/a0-a2,-(sp)
    jsr     ReqCDSector
	move.l  #CDSectorBuffer,a1
    jsr     GetCDSectorRawFull
    jsr     IncMSF
    movem.l (sp)+,d0/d1/d3/d7/a0-a2
.exit:
    rts


GetBMPSector:
    ; Ask MCU for a BMP data sector
    movem.l d1/d3/d7/a0-a3,-(sp)
    ; The following is like ReqCDSector with error handling
    move.l  MSFCounter,MCUCmdParams
    MCUCMD  MCU_CMD_LOADSECT
    bcc     .notimeout
    jsr     DispErrorTimeout
    bra     .err
.notimeout:
    jsr     MCURead4Words
    jsr     CheckACK
    bcs     .err

	move.l  #CDSectorBuffer,a1
    jsr     GetCDSectorRawFull

    movem.l (sp)+,d1/d3/d7/a0-a3
    andi.b  #$FE,CCR           ; Ok
    rts
.err:
    movem.l (sp)+,d1/d3/d7/a0-a3
    ori.b   #1,CCR             ; Error occured
	rts
