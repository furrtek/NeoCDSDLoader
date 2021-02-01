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

SetupSSaver:
    move.w  CurrentScreen,LastScreen    ; Store
    move.w  #SCREEN_IDLE,CurrentScreen

    jsr     ClearFix

    ; Clear all sprites
	move.w  #SCB3,REG_VRAMADDR
	move.w  #((496-264)<<7)+0,d1
	move.w  #384,d7
.clrspr:
	move.w  d1,REG_VRAMRW
	nop
	subq.w  #1,d7
	bne     .clrspr

    move.w  #BLACK,BACKDROP

    move.w  #4,d6                   ; Setup 4 bolts
.setspr:
    move.l  d6,-(sp)
	lea     map_ssaver_sprite,a0
	move.w  d6,d3
	lsl.w   #1,d3					; 2 sprites wide
	jsr     AutoMap
    move.l  (sp)+,d6

	move.w  d6,d0
	lsl.w   #1,d0					; 2 sprites wide
	move.w  #$0FFF,d1				; No shrink
	move.w  #2,d7					; 2 sprites wide
	jsr     SetSprZ

	move.w  d6,d0
	lsl.w   #1,d0					; 2 sprites wide
	move.w  #0,d1           		; Zero height for now
	move.w  #2,d7					; 2 sprites wide
	jsr     SetSprY

	subq.w  #1,d6
	bne     .setspr

    move.w  FrameCounter,d1         ; Shitty PRNG seed
    andi.l  #$FF,d1
	lea     ssaver_vars,a0
	lea     $C04200,a1              ; RND_DATA
	move.w  #38<<6,d0               ; Initial X
    move.w  #4,d7
.setvars:
	move.w  d0,(a0)+                ; X
	addi.w  #70<<6,d0
	move.w  #((224-32)/2)<<6,(a0)+  ; Initial Y

    moveq.l #0,d2
    move.b  0(a1,d1),d2
    ext.w   d2
    asr.w   #1,d2                   ; Slow the fuck down
    addi.w  #100,d2                 ; Minimum speed
	move.w  d2,(a0)+                ; VX

    moveq.l #0,d2
    move.b  1(a1,d1),d2
    ext.w   d2
    asr.w   #1,d2                   ; Slow the fuck down
    addi.w  #100,d2                 ; Minimum speed
	move.w  d2,(a0)+                ; VY

    addq.b  #2,d1

	subq.w  #1,d7
	bne     .setvars

    move.w  #SCREEN_SSAVER,CurrentScreen
	rts


VBLProcSSaver:
	; Refresh stuff in VRAM while we're at the beginning of the vblank
	lea     ssaver_vars,a0
    move.w  #4,d6
.setsprxy:
	move.w  d6,d0
	lsl.w   #1,d0					; 2 sprites wide
	move.w  (a0)+,d1				; X
	lsr.w   #6,d1                   ; 10.6 to int
	move.w  #2,d7					; 2 sprites wide
	jsr     SetSprX

	move.w  d6,d0
	lsl.w   #1,d0					; 2 sprites wide
	move.w  (a0)+,d1				; Y
	lsr.w   #6,d1                   ; 10.6 to int
	neg.w   d1
	addi.w  #496,d1
	lsl.w   #7,d1
	ori.w   #2,d1                   ; 2 sprites high
	move.w  #2,d7					; 2 sprites wide
	jsr     SetSprY
	
	lea     4(a0),a0                ; Skip VX and VY

	subq.w  #1,d6
	bne     .setsprxy
	
	; Animate
	lea     ssaver_vars,a0
    move.w  #4,d7
.anim:
    move.w  0(a0),d0                ; X
    move.w  2(a0),d1                ; Y

	add.w   4(a0),d0				; VX
    move.w  d0,0(a0)
	add.w   6(a0),d1				; VY
    move.w  d1,2(a0)
	
	lsr.w   #6,d0
	lsr.w   #6,d1

	cmp.w   #320-32,d0
	blo     .no_hit_right
	neg.w   4(a0)                   ; Negate VX
.no_hit_right:
	cmp.w   #0,d0
	bgt     .no_hit_left
	neg.w   4(a0)                   ; Negate VX
.no_hit_left:

	cmp.w   #224-32,d1
	blo     .no_hit_bottom
	neg.w   6(a0)                   ; Negate VY
.no_hit_bottom:
	cmp.w   #0,d1
	bgt     .no_hit_top
	neg.w   6(a0)                   ; Negate VY
.no_hit_top:

	lea     8(a0),a0                ; Next entry
	subq.w  #1,d7
	bne     .anim

    ; Screen saver disabled by any joypad activity
    move.b  BIOS_P1CHANGE,d0
    or.b    BIOS_P2CHANGE,d0
    beq     .no_exit
    ; Exiting the screen saver always brings back to the Main screen
    jsr     SetupMain
.no_exit:
	rts
