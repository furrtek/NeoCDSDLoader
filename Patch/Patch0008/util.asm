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

ClearFix:
	move.w  #$7000,REG_VRAMADDR
	nop
	move.w  #1,REG_VRAMMOD
	move.w  #32*40,d7
.clear:
    move.w  #$00FF,REG_VRAMRW
	move.b  d0,REG_DIPSW
	subq.w  #1,d7
	bne     .clear
	rts
	
ClearFixTop:
	move.w  #$7000,d0
	move.w  #1,REG_VRAMMOD  
	move.w  #40,d6
.line:      
    move.w  d0,REG_VRAMADDR
	move.w  #32-4,d7
	nop
.col:
    move.w  #$00FF,REG_VRAMRW
	move.b  d0,REG_DIPSW
	subq.w  #1,d7
	bne     .col
	addi.w  #32,d0
	subq.w  #1,d6
	bne     .line
	rts

; Clear whole file list
ClearFileList:
	moveq.l #0,d0
	lea     FileList,a0
	move.w  #(FILE_LIST_LEN>>4),d7
.clear_file_list:
	move.l  d0,(a0)+
	move.l  d0,(a0)+
	move.l  d0,(a0)+
	move.l  d0,(a0)+
	subq.w  #1,d7
	bne     .clear_file_list
	clr.w   TotalFileCount
	rts

; Hex digit to ASCII char
Hexify:
	cmpi.b  #9,d1
	bls     .deci
    addi.b  #7,d1
.deci:
    addi.b  #$30,d1
    rts

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

SetSprX:
	addi.w  #SCB4,d0
	lsl.w   #7,d1
	move.w  d0,REG_VRAMADDR
	nop
.set_x:
	nop
	nop
	move.w  d1,REG_VRAMRW
	subq.w  #1,d7
	bne     .set_x
	rts

SaveFixMap:
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
    rts

RestoreFixMap:
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
    rts

CopyPalette:
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    rts
    
WaitVBL:
    ; Wait for vblank to hide dirty things
.waitvbl:
    move.w  REG_LSPCMODE,d0
    lsr.w   #7,d0
    cmp.w   #$F8,d0
    bne     .waitvbl
    rts
    
; Used for linear -> sprite bitplane conversion
LUTIndexToBitplane:
    ;     11003322
    dc.l $00000000
    dc.l $00800000
    dc.l $80000000
    dc.l $80800000
    dc.l $00000080
    dc.l $00800080
    dc.l $80000080
    dc.l $80800080
    dc.l $00008000
    dc.l $00808000
    dc.l $80008000
    dc.l $80808000
    dc.l $00008080
    dc.l $00808080
    dc.l $80008080
    dc.l $80808080
