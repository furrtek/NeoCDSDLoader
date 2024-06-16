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

;$00: End of string
;$01: Move from origin X, Y
;$A0: Restore palette to the one in FixWriteConfig
;$AF: Escape next char
;$Bx: Print button picto, x must be A, B, C or D
;$Cx: Change palette to x
;$Ex: Print stored byte in FixValueList at index x
;$Fx: Print stored longword in FixValueList at index x
WriteFix:
	move.b  d0,REG_DIPSW
    movem.l d1-d7/a1,-(sp)
	move.w  FixWriteConfig,d1
	move.w  #32,REG_VRAMMOD
    nop
    nop
    nop
    move.w  d0,REG_VRAMADDR
.write:
    move.b  (a0)+,d1
    tst.b   d1
    beq     .strend
    cmp.b   #1,d1
	beq     .reloc
    cmp.b   #$AF,d1
	bne     .noescape
    move.b  (a0)+,d1
	move.w  d1,REG_VRAMRW
    bra     .write
.noescape:
    cmpi.b  #$A0,d1
    bhs     .special
	move.w  d1,REG_VRAMRW
    bra     .write
.special:
    cmpi.b  #$F0,d1
    bhs     .valuelong
    cmpi.b  #$E0,d1
    bhs     .valuebyte
    cmpi.b  #$C0,d1
    bhs     .changepal
    cmpi.b  #$B0,d1
    bhs     .picto
    cmpi.b  #$A0,d1
    beq     .restorepal
	;Invalid char
    bra     .write
.strend:
    movem.l (sp)+,d1-d7/a1
	rts

.restorepal:
	move.w  FixWriteConfig,d1
    bra     .write

.changepal:
    move.w  d1,d2
    andi.w  #$000F,d2
    ror.w   #4,d2
    andi.w  #$0FFF,d1
    or.w    d2,d1
    bra     .write

.picto:
    move.w  #$1500,d3       ; Palette #1 bank 5
    move.w  d1,d2
    andi.w  #$0F,d2
    add.b   d2,d2
    lea     ButtonPictoLUT,a1
    move.b  0(a1,d2),d3
	move.w  d3,REG_VRAMRW
	nop
	nop
    move.b  1(a1,d2),d3
	move.w  d3,REG_VRAMRW
    bra     .write


.reloc:
    moveq.l #0,d3
    move.b  (a0)+,d3
    lsl.w   #5,d3
    add.w   d0,d3
    add.b   (a0)+,d3
    move.w  d3,REG_VRAMADDR
    bra     .write

.valuelong:
    moveq.l #0,d3
    move.b  d1,d3
    andi.b  #15,d3
    lsl.w   #2,d3
    lea     FixValueList,a1
    move.l  (a1,d3),d3
	move.w  d1,d2
    moveq.l #8,d7
.writelong:
	rol.l   #4,d3
	move.b  d3,d2
	andi.b  #$F,d2
	cmpi.b  #9,d2
	bls     .deci
    addi.b  #7,d2
.deci:
    addi.b  #$30,d2
	move.w  d2,REG_VRAMRW
	subq.b  #1,d7
	bne     .writelong
    bra     .write
    
.valuebyte:
    moveq.l #0,d3
    move.b  d1,d3
    andi.b  #15,d3
    lea     FixValueList,a1
    move.b  (a1,d3),d3
	move.w  d1,d2
    moveq.l #2,d7
.writebyte:
	rol.b   #4,d3
	move.b  d3,d2
	andi.b  #$F,d2
	cmpi.b  #9,d2
	bls     .deci2
    addi.b  #7,d2
.deci2:
    addi.b  #$30,d2
	move.w  d2,REG_VRAMRW
	subq.b  #1,d7
	bne     .writebyte
    bra     .write
    
    IFDEF DEBUGBUILD
WriteWord:
	move.w  #32,REG_VRAMMOD
	move.w  FixWriteConfig,d1
    nop
    move.w  d0,REG_VRAMADDR
    moveq.l #4,d7
.writeword:
	rol.w   #4,d2
	moveq.l #0,d3
	move.b  d2,d3
	andi.b  #$F,d3
	cmpi.b  #9,d3
	bls     .deci
    addq.b  #7,d3
.deci:
    addi.b  #$30,d3
    or.w    d1,d3
	move.w  d3,REG_VRAMRW
	subq.b  #1,d7
	bne     .writeword
	rts
	ENDIF

ButtonPictoLUT:
    dc.b $00,$00
    dc.b $00,$00
    dc.b $00,$00
    dc.b $00,$00
    dc.b $00,$00
    dc.b $00,$00
    dc.b $00,$00
    dc.b $00,$00
    dc.b $00,$00
    dc.b $00,$00
    dc.b $8C,$8D    ; A button
    dc.b $8E,$8F    ; B button
    dc.b $9C,$9D    ; C button
    dc.b $9E,$9F    ; D button
    dc.b $00,$00
    dc.b $00,$00

; a0.l: Data pointer
; a2.l: Dictionary pointer
; d0.w: VRAM address
WriteFixDict:
	move.b  d0,REG_DIPSW
	move.w  #32,REG_VRAMMOD
    movem.l d0-d2/a1,-(sp)
    moveq.l #0,d2
	move.w  FixWriteConfig,d1
    move.w  d0,REG_VRAMADDR
.write:
    move.b  (a0)+,d1
    tst.b   d1
    beq     .strend
    bpl     .char
    ; Alias
    moveq.l #0,d0
    move.b  d1,d0
    subi.b  #128,d0
    lsl.w   #4,d0
    lea     0(a2,d0),a1
.awrite:
    move.b  (a1)+,d1
    tst.b   d1
    beq     .write
	move.w  d1,REG_VRAMRW
	addq.b  #1,d2
    bra     .awrite
.char:
	move.w  d1,REG_VRAMRW
	addq.b  #1,d2
    bra     .write
.strend:
    ; Pad to MAX_CHEAT_DESC if needed
    move.b  #' ',d1
.pad:
    cmp.b   #MAX_CHEAT_DESC,d2
    beq     .done
	move.w  d1,REG_VRAMRW
	addq.b  #1,d2
	bra     .pad
.done:
    movem.l (sp)+,d0-d2/a1
    rts


; d0.b: Byte to write
; Uses d1
WriteByte:
    jsr     .writebyte
.writebyte:
	move.w  FixWriteConfig,d1
	rol.b   #4,d0
	move.b  d0,d1
	andi.b  #$F,d1
	cmpi.b  #9,d1
	bls     .deci
    addi.b  #7,d1
.deci:
    addi.b  #$30,d1
	move.w  d1,REG_VRAMRW
	rts
