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

DoUpdate:
    MCUCMD  MCU_CMD_UPDATE
    bcc     .notimeout
    jmp     DispErrorTimeout
.notimeout:
    ; Console may be reset here
    ; Read 4 words from the MCU (see doc)
    jsr     MCURead4Words
    move.b  MCUReplyBuffer,d0
    andi.b  #$F0,d0
    cmp.b   #$F0,d0
    beq     .ok
    cmp.b   #1,MCUReplyBuffer+1 ; File not found error code
    bne     .ok
    lea     StrMsgBoxNoUpdate,a0
    jsr     MessageBox
.ok:
    rts
