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

; a0: Text
; a1: Procedure to call after closing (only for MessageBoxCustom call)
MessageBox:
    moveq.l #0,d0
    move.l  d0,a1
MessageBoxCustom:
    tst.b   CurrentMsgBox
    bne     .abort
    st.b    CurrentMsgBox
    movea.l a1,MsgBoxExitCall
    movea.l a0,a1
    move.w  CurrentScreen,CurrentScreenPrev    ; Save

    ; Save fix map block
    move.w  #MSGBOX_WIDTH,d0
    move.w  #MSGBOX_HEIGHT,d1
    move.w  #FIXMAP+8+(8*32),d2
    jsr     SaveFixMap

    move.w  FixWriteConfig,d5       ; Save
    move.w  #$2000,FixWriteConfig   ; Palette #2 bank 0

    ; Draw message box
    move.w  #32,REG_VRAMMOD
    move.w  #FIXMAP+8+(8*32),d2

    move.w  FixWriteConfig,d1
    move.w  #MSGBOX_WIDTH,d7
    lea     FixMapMsgBoxTop,a0
    jsr     BoxDrawRow
    move.w  #MSGBOX_HEIGHT-2,d6
.rowfill:
    move.w  #MSGBOX_WIDTH,d7
    lea     FixMapMsgBoxRow,a0
    jsr     BoxDrawRow
    subq.w  #1,d6
    bne     .rowfill
    move.w  #MSGBOX_WIDTH,d7
    lea     FixMapMsgBoxBot,a0
    jsr     BoxDrawRow

    movea.l a1,a0
	move.w  #FIXMAP+9+(9*32),d0
	jsr     WriteFix                ; Write message initially pointed by a0

    move.w  d5,FixWriteConfig       ; Restore

    move.w  #SCREEN_MSGBOX,CurrentScreen
.abort:
    rts

VBLProcMsgBox:
    ; Any button:
    ;   In menu: Close msgbox
    ;   In loading or game: Reset
    move.b  BIOS_P1CHANGE,d0
    or.b    BIOS_P2CHANGE,d0
	andi.b  #$F0,d0
    beq     .no_push
    tst.b   IsLoading
    beq     .noloading
    jmp     $C00402     ; Reset
.noloading:
    jsr     MessageBoxClose
.no_push:
    rts

MessageBoxClose:
    ; Restore fix map block
    move.w  #MSGBOX_WIDTH,d0
    move.w  #MSGBOX_HEIGHT,d1
    move.w  #FIXMAP+8+(8*32),d2
    jsr     RestoreFixMap

    clr.b   CurrentMsgBox
    move.w  CurrentScreenPrev,CurrentScreen    ; Restore
    tst.l   MsgBoxExitCall
    beq     .nocall
    move.l  MsgBoxExitCall,a0
    jmp     (a0)
.nocall:
    rts

; d1.w: Palette << 12
; d2.w: VRAM address
; d7.w: Width
; a0.l: Data pointer
BoxDrawRow:
    move.w  d2,REG_VRAMADDR
    nop
.col:
    move.w  (a0)+,d0
    or.w    d1,d0
    move.w  d0,REG_VRAMRW
    nop
    subq.w  #1,d7
    bne     .col
    addq.w  #1,d2
    rts

FixMapMsgBoxTop:
    dc.w $001
    dc.w [MSGBOX_WIDTH-2]$016
    dc.w $002
FixMapMsgBoxRow:
    dc.w $014
    dc.w [MSGBOX_WIDTH-2]$020
    dc.w $015
FixMapMsgBoxBot:
    dc.w $003
    dc.w [MSGBOX_WIDTH-2]$017
    dc.w $004

DispErrorTimeout:
    lea     FixValueList,a0
    move.b  TimeOutStage,(a0)+
    bra     DispError2
DispError:
    lea     FixValueList,a0
    move.b  #0,(a0)+
DispError2:
    tst.b   IsLoading
    beq     .noloading
    jsr     ClearFix
    ; Reload font bank and init palette #2 if error occurs during loading
    move.b  #$11,$10FEDA        ; Type
    clr.l   $10FEF4             ; Destination
    move.l  #$2000,$10FEFC      ; One fix bank
    move.l  #$C5FEB0,$10FEF8    ; Data_Fix
    jsr     $C00546             ; BIOSF_UPLOAD
    lea     IGMPalettes,a0
	lea     (2*16*2)+PALETTES,a1
    jsr     CopyPalette
.noloading:
    lea     FixValueList+1,a0
    ; Last MCU command and first param byte
    move.b  LastMCUCmd,(a0)+
    move.b  MCUCmdParams,(a0)+
    lea     MCUReplyBuffer,a1
    ; Two last MCU reply bytes
    move.b  (a1)+,(a0)+
    move.b  (a1),(a0)+
    ; Patch type (byte value at $C0AF6A)
    move.b  $C0AF6A,(a0)+
    ; Menu version
    move.b  #VERSION_MAJ,(a0)+
    move.b  #VERSION_MIN,(a0)+
    ; MCU version
    move.w  MCUVersion,(a0)+
    lea     FixStrError,a0
    jsr     MessageBox
    rts
