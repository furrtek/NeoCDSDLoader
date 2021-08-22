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

;SAVE_DATA1: xxaAFSNN
;x: Unused
;a: Loading animation slow/fast
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

    move.b  SettingLoadAnim,d0
    andi.b  #1,d0               ; xxxxxxxa
    add.b   d0,d0               ; xxxxxxa0
    move.b  SettingBootAnim,d1
    andi.b  #1,d1               ; xxxxxxxA
    or.b    d1,d0               ; xxxxxxaA
    add.b   d0,d0               ; xxxxxaA0
    move.b  SettingSFX,d1
    andi.b  #1,d1               ; xxxxxxxF
    or.b    d1,d0               ; xxxxxaAF
    add.b   d0,d0               ; xxxxaAF0
    move.b  SettingSSaver,d1
    andi.b  #1,d1
    or.b    d1,d0               ; xxxxaAFS
    add.b   d0,d0               ; xxxaAFS0
    add.b   d0,d0               ; xxaAFS00
    move.b  SettingCountry,d1
    andi.b  #3,d1
    or.b    d1,d0               ; xxaAFSNN
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
    move.b  d0,d1               ; xxaAFSNN
    andi.b  #3,d1
    move.b  d1,SettingCountry
    lsr.b   #2,d0               ; xxxxaAFS
    move.b  d0,d1
    andi.b  #1,d1
    move.b  d1,SettingSSaver
    lsr.b   #1,d0               ; xxxxxaAF
    move.b  d0,d1
    andi.b  #1,d1
    move.b  d1,SettingSFX
    lsr.b   #1,d0               ; xxxxxxaA
    move.b  d0,d1
    andi.b  #1,d1
    move.b  d1,SettingBootAnim
    lsr.b   #1,d0               ; xxxxxxxa
    andi.b  #1,d0
    move.b  d0,SettingLoadAnim

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
