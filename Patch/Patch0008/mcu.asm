; Copyright (C) 2020 Sean Gonsalves
;
; Neo CD SD Loader system ROM patch
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

; d3.b: command #
; Parameters in MCUCmdParams
; Sets carry on timeout
MCUCommand:
    move.l  d4,-(sp)           ; Preserve d4
    move.b  d0,REG_DIPSW
    clr.b   PollStatus         ; Stop periodic status polling until command is ack'd
    move.b  d3,LastMCUCmd
	move.w  d3,CPLDREG_DATA    ; Write to MCU, lower byte of CPLDREG_DATA
    jsr     MCUWaitAck
    bcs     .timeout
    moveq.l #32-1,d4           ; The command byte counts in the MCU's command buffer
    lea     MCUCmdParams,a0
.txparam:
    move.b  (a0)+,d0
	move.w  d0,CPLDREG_DATA    ; Write to MCU, lower byte of CPLDREG_DATA
    jsr     MCUWaitAck
    bcs     .timeout
    subq.b  #1,d4
    bne     .txparam

	move.w  d0,CPLDREG_EXEC
    jsr     MCUWaitExec
    bcs     .timeout
    st.b    PollStatus
    move.l  (sp)+,d4
    andi.b  #$FE,CCR           ; Ok
    rts
.timeout:
    st.b    PollStatus
    move.l  (sp)+,d4
    ori.b   #1,CCR             ; Timeout occured
    rts

; Sets carry on timeout
MCUWaitAck:
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
    ori.b   #1,CCR             ; Timeout occured
    rts
.done:
    andi.b  #$FE,CCR           ; Ok
    rts

; Sets carry on timeout
MCUWaitExec:
	moveq.l #0,d0
	; Wait for CPLDREG_STAT bit 1 (EXEC_PENDING) to be reset
	move.l  #TIMEOUT_EXEC,d7
.wait:
    move.b  d0,REG_DIPSW       ; 16
    move.w  CPLDREG_STAT,d0    ; 12
    andi.w  #$0002,d0          ; 8
    beq     .done              ; 8
    subq.l  #1,d7              ; 8
    bne     .wait              ; 10 = 62, 5.167us
    move.b  #2,TimeOutStage
    ori.b   #1,CCR             ; Timeout occured
    rts
.done:
    jsr     MCUWaitRefill
    andi.b  #$FE,CCR           ; Ok
    rts

; Sets carry on timeout
MCUWaitRefill:
	moveq.l #0,d0
	; Wait for CPLDREG_STAT bit 2 (REFILL_PENDING) to be reset
	move.l  #TIMEOUT_EXEC,d7
.wait:
    move.b  d0,REG_DIPSW
    move.w  CPLDREG_STAT,d0    ; 12
    andi.w  #$0004,d0          ; 8
    beq     .done              ; 8
    subq.l  #1,d7              ; 8
    bne     .wait              ; 10 = 46
    move.b  #3,TimeOutStage
    ori.b   #1,CCR             ; Timeout occured
    rts
.done:
    andi.b  #$FE,CCR           ; Ok
    rts

MCURead4Words:
    move.w  #4,d3
; d3.w: word count (should be a multiple of 4)
MCURead4WordsMult:
    move.w  d3,d0
    tst.w   d0      ; Useless ?
    beq     .zero
    andi.b  #3,d0
    beq     .multipleof4
    addi.w  #4,d3
.multipleof4:
    lsr.w   #2,d3   ; Divide by 4
    lea     MCUReplyBuffer,a0
.rdloop:
	move.w  CPLDREG_DATA,(a0)+ ; 20 Read from MCU
	move.w  CPLDREG_DATA,(a0)+ ; Read from MCU
	move.w  CPLDREG_DATA,(a0)+ ; Read from MCU
	move.w  CPLDREG_DATA,(a0)+ ; Read from MCU
    jsr     MCUWaitRefill      ; Wait for FIFO to be refilled
	subq.w  #1,d3              ; 4
	bne     .rdloop            ; 10
.zero:
	rts

; Check MCU command reply flag, sets carry on error
; Uses d0
CheckACK:
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    beq     .ack
    ; Error occured, show error text and return
	jsr     DispError
    ori.b   #1,CCR
.ack:
    andi.b  #$FE,CCR           ; Ok
    rts
