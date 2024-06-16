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

SplashInit:
	lea    $100000,a6           ; Copied from original routine
    tst.b  SettingBootAnim
    beq    .newanim
	move.l #600,$101B2E			; Copied from original routine
	lea    SpriteInitData,a1    ; Copied from original routine
	rts
.newanim:
	move.l #360,$101B2E			; Reduce splash duration (10s -> 6s)
	lea    NewSpriteInitData,a1
    rts
    
SplashStartCurve:
    tst.b   SettingBootAnim
    beq     .newanim
    move.l  #$8C0000,$20(a6)    ; Copied from original routine
    rts
.newanim:
	move.l  #$920000,$20(a6)    ; Loop start X position
    rts
    
SplashLetterCurve:
    tst.b   SettingBootAnim
    beq     .newanim
    move.l  #$60000,d0          ; Copied from original routine
    rts
.newanim:
	move.l  #$50000,d0			; Loop curve width (oval)
    rts
    
SplashMapSprite:
    moveq.l #0,d0               ; Copied from original routine
    move.b  2(a6),d0            ; SpriteMapIndex
    bne     .nspr0
    tst.b   SettingBootAnim
    bne     .nspr0
    lea     map_splash_sdcard,a2
    rts
.nspr0:
    add.b   d0,d0               ; Copied from original routine
    add.b   d0,d0               ; Copied from original routine
    move.l  (a1,d0),a2          ; Copied from original routine
    rts
    
InstallPalettes:
    lea     CDPPalData,a0       ; Copied from original routine, CDPPalData

    lea     PALETTES,a1         ; Copied from original routine
    move.w  #128-1,d7           ; Copied from original routine, load 16 palettes
.ldpal:
    move.l  (a0)+,(a1)+
    dbf     d7,.ldpal
    tst.b   SettingBootAnim
    beq     .newanim
    rts
.newanim:
    lea     pal_sd_card,a0      ; Replace CD palette (7)
    lea     (PALETTES+(2*16*7)),a1
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    move.l  (a0)+,(a1)+
    rts

; Original data:
;    dc.w $0000, $0700, $0000, $0000, $0058, $0038, $0008, $0018, $0008, $0018
;    dc.w $8001, $0000, $0000, $0000, $0050, $0038, $0008, $0018, $0008, $0018
;    dc.w $0002, $0120, $0000, $0001, $0150, $00B8, $0098, $00B8, $0033, $00B8
;    dc.w $0003, $0120, $0000, $0005, $0150, $00B8, $00A0, $00B8, $004F, $00B8
;    dc.w $0004, $0120, $0000, $0009, $0150, $00B8, $00A0, $00B8, $0067, $00B8
;    dc.w $0005, $0120, $0000, $000D, $0150, $00B8, $00A0, $00B8, $0081, $00B8
;    dc.w $0006, $0120, $0000, $000F, $0150, $00B8, $00A0, $00B8, $0089, $00B8
;    dc.w $0003, $0120, $0000, $0013, $0150, $00B8, $00A0, $00B8, $00A2, $00B8
;    dc.w $0004, $0120, $0000, $0017, $0150, $00B8, $00A0, $00B8, $00BA, $00B8
;    dc.w $0007, $0120, $0000, $001B, $0150, $00B8, $00A0, $00B8, $00D8, $00B8
;    dc.w $0008, $0120, $0000, $001F, $0150, $00B8, $00A0, $00B8, $00F0, $00B8
;    dc.w $FFFF

NewSpriteInitData:
    dc.w $0000, $0700, $0000, $0000, 96,    $0038, $0008, $0018, $0008, $0018
    dc.w $8001, $0000, $0000, $0000, 88,    $0038, $0008, $0018, $0008, $0018
    dc.w $0002, $0120, $0000, $0001, $0150, $00B8, $0098, $00B8, $48,   $00B8
    dc.w $0003, $0120, $0000, $0005, $0150, $00B8, $00A0, $00B8, $48+28, $00B8
    dc.w $0004, $0120, $0000, $0009, $0150, $00B8, $00A0, $00B8, $48+54, $00B8
    dc.w $0005, $0120, $0000, $000D, $0150, $00B8, $00A0, $00B8, $48+83, $00B8
    dc.w $0006, $0120, $0000, $000F, $0150, $00B8, $00A0, $00B8, $48+94, $00B8
    dc.w $0003, $0120, $0000, $0013, $0150, $00B8, $00A0, $00B8, $48+121, $00B8
    dc.w $0004, $0120, $0000, $0017, $0150, $00B8, $00A0, $00B8, $48+147, $00B8
    dc.w $FFFF, $0120, $0000, $001B, $0150, $00B8, $00A0, $00B8, $00D8, $00B8
    dc.w $0008, $0120, $0000, $001F, $0150, $00B8, $00A0, $00B8, $00F4, $00B8
    dc.w $FFFF
