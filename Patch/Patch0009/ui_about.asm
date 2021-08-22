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

SetupAbout:
    ; Setup about screen
    move.w  #SCREEN_ABOUT,CurrentScreen

    jsr     ClearFixTop

	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

    ; Get MCU serial number and FW version
    clr.b   UITemp  ; Used here to signal error
    MCUCMD  MCU_CMD_GETID
    bcc     .notimeout
    st.b    UITemp
.cldata:
    ; Clear MCU data
    lea     MCUReplyBuffer+1,a0
    moveq.l #0,d0
    moveq.l #64-1-1,d7
.cldatalp:
    move.b  d0,(a0)+
    dbra    d7,.cldatalp
    bra     .done
.notimeout:
    ; Read 24 bytes from the MCU (see doc)
    move.w  #12,d3
    jsr     MCURead4WordsMult
    jsr     CheckACK
    bcs     .cldata
.done:
    lea     MCUReplyBuffer+1,a0
    lea     FixValueList,a1

	moveq.l #12-1,d7               ; Serial
.copy:
	move.b  (a0)+,(a1)+
	dbra    d7,.copy

	move.b  (a0)+,(a1)+            ; MCU version
	move.b  (a0)+,(a1)+

	move.b  2(a0),(a1)+            ; CPLD version, skip "600D"
	move.b  3(a0),(a1)

    lea     FixStrAbout,a0
	move.w  #FIXMAP+9+(5*32),d0
	jsr     WriteFix

    lea     FixStrIcon,a0
	move.w  #FIXMAP+20+(32*32),d0
	jsr     WriteFix

	tst.b   UITemp
	beq     .noerror
    jsr     DispErrorTimeout
.noerror:
	rts


VBLProcAbout:
    move.b  BIOS_P1CHANGE,d0
    or.b    BIOS_P2CHANGE,d0
    andi.b  #$F0,d0
    beq     .no_press
    move.b  #SFX_EXIT,d0
    jsr     PlaySFX
    jsr     SetupMenu
.no_press:
    rts
