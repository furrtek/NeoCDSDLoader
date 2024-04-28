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

; Clear whole fix layer
ClearFix:
	move.w  #$7000,REG_VRAMADDR
	move.w  #1,REG_VRAMMOD
	move.w  #(32*40)-1,d7
.clear:
	move.b  d0,REG_DIPSW
	nop
    move.w  #$00FF,REG_VRAMRW
	dbra    d7,.clear
	rts


; Clear top 28*40 fix rectangle
ClearFixTop:
	move.w  #$7000,d0
	move.w  #1,REG_VRAMMOD  
	moveq.l #40-1,d6
.line:
    move.w  d0,REG_VRAMADDR
	moveq.l #(32-4)-1,d7
.col:
	move.b  d0,REG_DIPSW
	nop
    move.w  #$00FF,REG_VRAMRW
	dbra    d7,.col
	addi.w  #32,d0
	dbra    d6,.line
	rts


; Clear whole file list
ClearFileList:
	moveq.l #0,d0
	lea     FileList,a0
	move.w  #(FILE_LIST_LEN>>4)-1,d7
.lp:
	move.l  d0,(a0)+
	move.l  d0,(a0)+
	move.l  d0,(a0)+
	move.l  d0,(a0)+
	dbra    d7,.lp
	clr.w   TotalFileCount
	rts


; Hex digit to ASCII char
; d1.b: Hex nibble in / ASCII out
Hexify:
	cmpi.b  #9,d1
	bls     .deci
    addi.b  #7,d1
.deci:
    addi.b  #'0',d1
    rts

; d0.b: Hex byte in / BCD out
HexToBCD:
	moveq.l #0,d1
	move.b  d0,d1
	divu.w  #10,d1
	move.w  d1,d0
	lsl.w   #4,d0
	swap.l  d1
	add.w   d1,d0
	rts


; a0.l: Pointer to map data
AutoMap:
    move.b  (a0)+,d1 				; Width
    addq.b  #1,d1
    move.b  (a0)+,d2 				; Height
    addq.b  #1,d2
    lsl.w   #6,d3					; *64
.map_sprites:
	move.w  d3,REG_VRAMADDR
	move.w  d2,d4					; Restore height
.map_tiles:
	move.w  (a0)+,d5
	move.w  d5,d6
    andi.w  #$0FFF,d6				; Keep tile #
	move.w  d6,REG_VRAMRW
	andi.w  #$F000,d5				; Keep palette # (4 bits)
	lsr.w   #4,d5
    move.w  d5,REG_VRAMRW
	subq.b  #1,d4
	bne     .map_tiles
	addi.w  #2*32,d3				; Next sprite
	subq.b  #1,d1
	bne     .map_sprites
	rts


; d0.w: First sprite #
; d1.w: Scaling value
; d7.w: Sprite count
SetSprZ:
	addi.w  #SCB2,d0
	move.w  d0,REG_VRAMADDR
	nop
.set_z:
	nop
	nop
	move.w  d1,REG_VRAMRW
	subq.w  #1,d7
	bne     .set_z
	rts


; d0.w: First sprite #
; d1.w: SCB3 value
; d7.w: Sprite count
SetSprY:
	addi.w  #SCB3,d0
	move.w  d0,REG_VRAMADDR
	nop
.set_y:
	nop
	nop
	move.w  d1,REG_VRAMRW
	ori.w   #64,d1					; Set chain bit
	subq.w  #1,d7
	bne     .set_y
	rts


; d0.w: First sprite #
; d1.w: X position
; d7.w: Sprite count
SetSprX:
	addi.w  #SCB4,d0
	move.w  d0,REG_VRAMADDR
	lsl.w   #7,d1
.set_x:
	nop
	nop
	move.w  d1,REG_VRAMRW
	subq.w  #1,d7
	bne     .set_x
	rts


; d0.w: Width
; d1.w: Height
; d2.w: VRAM start address
SaveFixMap:
    DIIRQ
    lea     FixMapBuffer,a0
.row:
    move.w  d2,d3
    move.w  d0,d7
.col:
    move.w  d3,REG_VRAMADDR
    addi.w  #32,d3
    nop
    move.w  REG_VRAMRW,(a0)+
    subq.w  #1,d7
    bne     .col
    addq.w  #1,d2
    subq.w  #1,d1
    bne     .row
	ENIRQ
    rts


; d0.w: Width
; d1.w: Height
; d2.w: VRAM start address
RestoreFixMap:
    DIIRQ
    move.b  d0,REG_DIPSW
	move.w  sr,-(a7)
	ori.w   #$0700,sr
    lea     FixMapBuffer,a0
.row:
    move.w  d2,d3
    move.w  d0,d7
.col:
    move.w  d3,REG_VRAMADDR
    addi.w  #32,d3
    nop
    move.w  (a0)+,REG_VRAMRW
    subq.w  #1,d7
    bne     .col
    addq.w  #1,d2
    subq.w  #1,d1
    bne     .row
	move.w  (a7)+,sr
	ENIRQ
    rts


CopyPalette:
    REPT 8
    move.l  (a0)+,(a1)+
    ENDM
    rts
    

WaitVBL:
    move.w  REG_LSPCMODE,d0
    lsr.w   #7,d0
    cmp.w   #$F8,d0
    bne     WaitVBL
    rts

; Sets carry on error
InitSD:
    ; Tell MCU to init SD and get card type
    move.b  #10,RetryCounter
.retry:
    MCUCMD  MCU_CMD_INITSD
    bcc     .notimeout
    jsr     DispErrorTimeout
    bra     .error
.notimeout:
    jsr     MCURead4Words
    jsr     CheckACK
    bcc     .initok
    jsr     WaitVBL            ; Let at least one frame go by
    jsr     WaitVBL
    subq.b  #1,RetryCounter
    bne     .retry
.error:
    ori.b   #1,CCR             ; Error occured
    rts
.initok:
    andi.b  #$FE,CCR           ; Ok
    rts
    