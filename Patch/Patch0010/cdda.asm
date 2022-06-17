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

StopCDDA:
    move.b  #0,REG_ENVIDEO      ; Copied from original routine
	move.w  #$0600,d0           ; Stop CDDA
	jmp     CDDACommand


; d0.w: command, track
CDDACommand:
    IFNDEF MAMEDEBUG
    btst.l  #9,d0
    bne     .ok              ; Command is pause or resume: ok
    tst.b   d0
    bne     .ok              ; Command is play with track # > 0: ok
    rts                      ; Command is null or invalid
.ok:
    ; If command bit 2 is set, the system ROM steals the VBL IRQ until the command is processed
    ;tst.b   $107             ; From original code. Bit 7 of byte at $107 prevents the use of blocking CDDA commands
    ;bmi     .direct
    ;st.b    CDDAPending
    ;move.w  #1,$FF0004
    ;move.l  #SYS_INT1,$68    ; Replace VBL handler by SYS_INT1 while the command is being procesed
    ;move.w  #$731,$FF0004
;.direct:
    ;clr.b   $10F6D9          ; CDDAReadyFlag

    move.w  d0,MCUCmdParams
    MCUCMD  MCU_CMD_CDDA
    bcc     .notimeout
    jmp     DispErrorTimeout
.notimeout:
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    jsr     CheckACK
    ; Aaaand do absolutely nothing with them (ignore errors)
    ENDIF
    rts


ProcessZ80CDDA:
    move.b  1(a0),d0
    lsl.w   #8,d0
    move.b  3(a0),d0
    clr.b   1(a0)
    clr.b   3(a0)
    move.w  d0,-(sp)
    jsr     CDDACommand
    move.w  (sp)+,d0
    jmp     ReadCDDAFromZ80End


BIOSF_CDDACMD:
    movem.l d0-d7/a0-a1,-(sp)
    jsr     CDDACommand
    movem.l (sp)+,d0-d7/a0-a1
    rts
