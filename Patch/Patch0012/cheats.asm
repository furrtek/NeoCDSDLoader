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

SystemIOCustom:
    ; Check for start+select
    ; If so: set a flag to bring up the In-Game Menu
    ; Do NOT set up the IGM in SYSTEM_IO, because the game will then be able to mess with the fix during the current frame
    ; In SYSTEM_INT1, check if the IGM flag is set. If so, set up the IGM:
    ; Save fix bank #0 somewhere and the palette in extended RAM ($110000+)
    ; Load the in-game menu fix bank in fix bank #0 and the IGM palette
    ; Let inserted code in SYSTEM_INT1 (IGMVBL) handle the UI
    
    ; If no start+select, check VBL cheats list and run them

    tst.b   IsLoading   ; Skip everything cheat-related during loading
    bne     .done

    ; This must be fast to avoid wasting the game's VBL time !
    move.b  BIOS_STATCURNT,d0
    move.b  d0,d1
    andi.b  #3,d0
    cmp.b   #3,d0
    beq     .sspress
    andi.b  #3<<2,d1
    cmp.b   #3<<2,d1
    beq     .sspress

    ; No start+select press

    ; Run VBL cheats if there are any
    lea     VBLCheatActions,a0
.runcheats:
    tst.b   (a0)
    beq     .done
    jsr     RunCheatActions
    bra     .runcheats
.done:
    rts

.sspress:
    ; Got start+select press
    clr.b   BIOS_STATCURNT  ; Do not pass the caught start+select press to the game
    clr.b   BIOS_STATCHANGE
    clr.b   $10FEDC
    clr.b   $10FEDD

    tst.b   $10F6B9		    ; Check "GameStartState" to see if game is running
    bpl     .done           ; No: Can't open IGM

    st.b    FlagSelectStart     ; Ask for IGM setup on next VBL
    move.l  $68,VBLVectorCopy
    move.l  #SYS_INT1,$68
    rts


InstallCheats:
    ; Process one-off cheats right now and prepare VBL cheats action list
    movea.l CheatDataAddr,a1
    move.b  (a1)+,d7                ; Cheats count
    moveq.l #32,d5                  ; Total iterations required for the ROR trick below to work
    lea     VBLCheatActions,a2
    move.l  CheatsBitmap,d3

.process:
    ror.l   #1,d3                   ; RORing allows easy reset of the one-off cheats
    bcc     .skipcheat
    tst.b   d7
    beq     .skipcheat              ; No more cheats to parse
    moveq.l #0,d0
    move.b  (a1)+,d0                ; Get action data offset
    lsl.w   #8,d0
    move.b  (a1)+,d0
    lea     CheatData,a0
    adda.l  d0,a0

    ; Run actions or add then to VBL list
    move.b  1(a0),d0                ; Type byte
    lsr.b   #6,d0
    andi.b  #3,d0
    subq.b  #1,d0                   ; Type is == 1 ?
    beq     .vbltype
    subq.b  #1,d0                   ; Type is == 2 ?
    bne     .skipdesc               ; Invalid type, SHOULDN'T HAPPPEN !
    jsr     RunCheatActions
    bclr.l  #31,d3                  ; Reset one-off cheat that was just RORed
    bra     .skipdesc
.vbltype:
    move.b  0(a0),d6                ; Size of action data
.vblcopy:
    move.b  (a0)+,(a2)+
    subq.b  #1,d6
    bne     .vblcopy
    bra     .skipdesc

.skipcheat:
    addq.l  #2,a1                   ; Skip action data offset
.skipdesc:
    tst.b   (a1)+                   ; Skip description text
    bne     .skipdesc

    tst.b   d7
    beq     .zero
    subq.b  #1,d7
.zero:
    subq.b  #1,d5
    bne     .process
    
    move.l  d3,CheatsBitmap

    move.b  #0,(a2)+                ; VBLCheatActions terminator
    rts


; a0: Actions list
RunCheatActions:
    movem.l d0-d7/a1-a3,-(sp)
    move.l  a0,a2
    moveq.l #0,d0
    move.b  (a0)+,d0    ; Action data size
    beq     .done       ; Should not happen
    add.l   d0,a2       ; End address
.action:
    move.b  (a0)+,d0    ; Type byte
    move.b  d0,d1
    andi.w  #3,d0       ; Get opcode
	lsl.w   #2,d0       ; JTOpCodes has 4-byte entries
    lea     JTOpCodes,a1
	move.l  0(a1,d0),a1

    lsr.b   #3,d1       ; Get data size
    andi.b  #7,d1

    move.b  (a0)+,d0    ; Get address MSB
    lsl.w   #8,d0
    move.b  (a0)+,d0    ; Get address LSB
    ori.l   #RAMSTART,d0
    movea.l d0,a3

	jsr     (a1)

	cmpa.l  a0,a2
    bne     .action     ; This may cause a crash if a0 goes over a2 (shouldn't happen if cheat data is formed correctly)
.done:
    movem.l (sp)+,d0-d7/a1-a3
    rts

JTOpCodes:
    dc.l Opcode0
    dc.l Opcode1
    dc.l Opcode2
    dc.l Opcode3

Opcode0:
    ; Write value to RAM address
    tst.b   d1
    beq     .done
    move.b  (a0)+,(a3)+
    subq.b  #1,d1
    bra     Opcode0
.done:
    rts

Opcode1:
    ; Write value to pointed RAM address + offset
    moveq.l #0,d0
    move.b  (a0)+,d0    ; Get offset MSB
    lsl.w   #8,d0
    move.b  (a0)+,d0    ; Get offset LSB
    add.l   (a3),d0
    movea.l d0,a3
    bra     Opcode0

Opcode2:
    ; Mask (clear)
    tst.b   d1
    beq     .done
    move.b  (a0)+,d0
    and.b   d0,(a3)+
    subq.b  #1,d1
    bra     Opcode2
.done:
    rts

Opcode3:
    ; Mask (clear) and set
    tst.b   d1
    beq     .done
    moveq.l #0,d2
    move.b  d1,d2       ; Data size used as constant offset in data for data and mask byte groups
.process:
    move.b  (a3),d0     ; Get data to modify
    and.b   (a0),d0     ; Mask byte
    or.b    0(a0,d2),d0 ; Set byte
    move.b  d0,(a3)+    ; Write back
    addq.l  #1,a0
    subq.b  #1,d1
    bne     .process
    adda.l  d2,a0
.done:
    rts
