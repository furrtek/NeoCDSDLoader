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

;SAVE_DATA1: xxxAFSNN
;x: Unused
;A: Default boot animation on/off
;F: Sound effects on/off
;S: Screen saver on/off
;NN: Nationality

;SAVE_DATA2: xxbgrBGR
;bgr: LED idle color
;BGR: LED loading color

SaveSettings:
    moveq.l #0,d0
    move.b  d0,REG_CRDNORMAL
    move.b  d0,REG_CRDBANK

    move.b  SettingBootAnim,d0
    andi.b  #1,d0               ; xxxxxxxA
    add.b   d0,d0               ; xxxxxxA0
    move.b  SettingSFX,d1
    andi.b  #1,d1
    or.b    d1,d0               ; xxxxxxAF
    add.b   d0,d0               ; xxxxxAF0
    move.b  SettingSSaver,d1
    andi.b  #1,d1
    or.b    d1,d0               ; xxxxxAFS
    add.b   d0,d0               ; xxxxAFS0
    add.b   d0,d0               ; xxxAFS00
    move.b  SettingCountry,d1
    andi.b  #3,d1
    or.b    d1,d0               ; xxxAFSNN
    move.b  d0,SAVE_DATA1

    move.b  SettingLEDIdle,d0
    andi.b  #7,d0
    lsl.b   #3,d0
    move.b  SettingLEDLoad,d1
    andi.b  #7,d1
    or.b    d1,d0
    move.b  d0,SAVE_DATA2
    rts

LoadSettings:
    moveq.l #0,d0
    move.b  d0,REG_CRDNORMAL
    move.b  d0,REG_CRDBANK

    move.b  SAVE_DATA1,d0
    move.b  d0,d1               ; xxxAFSNN
    andi.b  #3,d1
    move.b  d1,SettingCountry
    lsr.b   #2,d0               ; xxxxxAFS
    move.b  d0,d1
    andi.b  #1,d1
    move.b  d1,SettingSSaver
    lsr.b   #1,d0               ; xxxxxxAF
    move.b  d0,d1
    andi.b  #1,d1
    move.b  d1,SettingSFX
    lsr.b   #1,d0               ; xxxxxxxA
    move.b  d0,d1
    andi.b  #1,d1
    move.b  d1,SettingBootAnim

    move.b  SAVE_DATA2,d0
    move.b  d0,d1
    andi.b  #7,d1
    ; Can't be 7
    cmp.b   #7,d1
    bne     .ok1
    move.b  #0,d1
.ok1:
    move.b  d1,SettingLEDLoad
    lsr.b   #3,d0
    andi.b  #7,d0
    ; Can't be 7
    cmp.b   #7,d0
    bne     .ok2
    move.b  #0,d0
.ok2:
    move.b  d0,SettingLEDIdle
    rts
