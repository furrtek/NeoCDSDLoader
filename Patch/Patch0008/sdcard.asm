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

; MAKE SURE THIS PRESERVES USED REGISTERS !
LoadCDSectorFromSD:
    movem.l d0/d1/d3/d7/a0-a2,-(sp)
	move.b  d0,REG_DIPSW

	; Needed for Double Dragon ! Loads "DDVCT.PRG" which is smaller than a CD sector
	tst.w   CDSectorCount
	beq     .exit

    ; Ask MCU for a CD sector
    move.l  MSFCounter,MCUCmdParams     ; Request MSF
    MCUCMD  MCU_CMD_LOADSECT
    bcc     .notimeout
    jsr     DispErrorTimeout
.lockup:
    bra     .lockup
.notimeout:
    jsr     MCURead4Words
    jsr     CheckACK
    bcs     .lockup

	lea     CPLDREG_DATA,a0
	move.l  #$111204,a1	       ; "CDSectorBuffer"
	lea     CPLDREG_STAT,a2
	lea     REG_DIPSW,a3
	moveq.l #$0004,d1

	move.w  #256,d7 		   ; Read whole CD sector 256*8=2048 bytes
.readsector:
	move.l  (a0),(a1)+         ; 20
	move.l  (a0),(a1)+         ; 20
	move.b  d0,(a3)            ; 8

	; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
.wait:
    move.w  (a2),d0            ; 8
    and.w   d1,d0              ; 4
    bne     .wait              ; 10

	subq.w  #1,d7              ; 4
	bne     .readsector        ; 10, total 84 for 8 bytes, 1116kB/s

	move.w  #$2000,sr		   ; Enable all interrupts

	; For original progressbar update:
	move.l  $10F690,d0
	add.l   $10F68C,d0         ; Inc value, computed from total size of data to load
	cmpi.l  #$800000,d0
	bls     .nocap
	move.l  #$800000,d0
.nocap:
	move.l  d0,$10F690

    subq.w  #1,CDSectorCount
	move.w  CDSectorCount,$10F688

	; Inc MSF
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

.exit:
    movem.l (sp)+,d0/d1/d3/d7/a0-a2
    rts


; Sets carry on error
InitSD:
    ; Tell MCU to init SD and get card type
    MCUCMD  MCU_CMD_INITSD
    bcc     .notimeout
    jsr     DispErrorTimeout
    ori.b   #1,CCR             ; Error occured
    rts
.notimeout:
    jsr     MCURead4Words
    jsr     CheckACK
    bcc     .cmdok
    ori.b   #1,CCR             ; Error occured
    rts
.cmdok:
    andi.b  #$FE,CCR           ; Ok
    rts
    
GetBMPSector:
    movem.l d1/d3/d7/a0-a3,-(sp)
    ; Ask MCU for a BMP data sector
    move.l  MSFCounter,MCUCmdParams ; Request MSF
    MCUCMD  MCU_CMD_LOADSECT
    bcc     .notimeout
    jsr     DispErrorTimeout
    bra     .err
.notimeout:
    jsr     MCURead4Words
    jsr     CheckACK
    bcs     .err

	lea     CPLDREG_DATA,a0
	move.l  #$111204,a1	       ; "CDSectorBuffer"
	lea     CPLDREG_STAT,a2
	lea     REG_DIPSW,a3
	moveq.l #$0004,d1

	move.w  #256,d7 		   ; Read whole CD sector 256*8=2048 bytes
.readsector:
	move.l  (a0),(a1)+         ; 20
	move.l  (a0),(a1)+         ; 20
	move.b  d0,(a3)            ; 8
	; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
.wait:
    move.w  (a2),d0            ; 8
    and.w   d1,d0              ; 4
    bne     .wait              ; 10
	subq.w  #1,d7              ; 4
	bne     .readsector        ; 10
    movem.l (sp)+,d1/d3/d7/a0-a3
    andi.b  #$FE,CCR           ; Ok
    rts
.err:
    movem.l (sp)+,d1/d3/d7/a0-a3
    ori.b   #1,CCR             ; Error occured
	rts
