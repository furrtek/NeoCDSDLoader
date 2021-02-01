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

ErrBus:
    move.l  10(a7),PCERROR      ; Store PC from stack frame
    movem.l d0-d7/a0-a6,-(a7)   ; Store registers
    move.w  #GREEN,BACKDROP
    lea     FixStrErrBus,a0
    jmp     DispExc

ErrAddr:
    move.l  10(a7),PCERROR      ; Store PC from stack frame, 2(a7) is the address value that caused the error
    movem.l d0-d7/a0-a6,-(a7)   ; Store registers
    move.w  #BLUE,BACKDROP
    lea     FixStrErrAddr,a0
    jmp     DispExc
    
ErrIllegal:
    move.l  2(a7),PCERROR       ; Store PC from stack frame
    movem.l d0-d7/a0-a6,-(a7)   ; Store registers
    move.w  #YELLOW,BACKDROP
    lea     FixStrErrIllegal,a0
    jmp     DispExc

ErrGeneric:
    move.l  2(a7),PCERROR       ; Store PC from stack frame
    movem.l d0-d7/a0-a6,-(a7)   ; Store registers
    move.w  #MAGENTA,BACKDROP
    lea     FixStrErrGeneric,a0
    jmp     DispExc

ErrUninit:
    move.l  2(a7),PCERROR       ; Store PC from stack frame
    movem.l d0-d7/a0-a6,-(a7)   ; Store registers
    move.w  #CYAN,BACKDROP
    lea     FixStrErrUninit,a0
    jmp     DispExc
    

DispExc:
	ori.w   #$0700,sr

	; Load 8x8 charset
    move.b  #$11,BIOS_UPZONE
    clr.l   BIOS_UPDEST
    move.l  #$2000,BIOS_UPSIZE
    move.l  #$C5FEB0,BIOS_UPSRC
    jsr     $C00546             ; BIOSF_UPLOAD

	move.w  #$3000,FixWriteConfig

	move.w  #FIXMAP+5+(4*32),d0
	jsr     WriteFix

	lea     (2*16*3)+PALETTES,a0	; Set up palette 3 for text
	move.w  #BLACK,(a0)+
	move.w  #WHITE,(a0)+
	move.w  #BLACK,(a0)

	;subi.l  #60,a7				; Rewind stack pointer
    lea     FixValueList,a0
    move.b  #8,d7
.loadDRegs:
	move.l  (a7)+,(a0)+
	subq.b  #1,d7
	bne     .loadDRegs
    lea     FixStrDRegsDump,a0
	move.w  #FIXMAP+6+(4*32),d0
	jsr     WriteFix

    lea     FixValueList,a0
    move.b  #7,d7
.loadARegs:
	move.l  (a7)+,(a0)+
	subq.b  #1,d7
	bne     .loadARegs
	move.l  PCERROR,(a0)
    lea     FixStrARegsDump,a0
	move.w  #FIXMAP+6+(16*32),d0
	jsr     WriteFix

    lea     FixValueList,a0
    move.l  $68,(a0)+
    move.b  $C0AF6A,(a0)    ; Used to check patch version
    lea     FixStrVBL,a0
	move.w  #FIXMAP+15+(4*32),d0
	jsr     WriteFix

    lea     FixValueList,a0
    move.l  a7,a1
	move.l  a1,(a0)+
    move.b  #40,d7
.loadstackvalues:
	move.b  (a1)+,(a0)+
	subq.b  #1,d7
	bne     .loadstackvalues
    lea     FixStrStackDump,a0
	move.w  #FIXMAP+17+(4*32),d0
	jsr     WriteFix

    lea     FixValueList,a0
    move.l  PCERROR,d0
    subq.l  #8,d0
    movea.l d0,a1
    move.b  #16,d7
.loadatpcvalues:
	move.b  (a1)+,(a0)+
	subq.b  #1,d7
	bne     .loadatpcvalues
    lea     FixStrAtPCDump,a0
	move.w  #FIXMAP+24+(4*32),d0
	jsr     WriteFix

	move.b  #1,REG_ENVIDEO
	move.b  #0,REG_DISBLSPR
	move.b  #0,REG_DISBLFIX

	jmp     Lockup

;ErrSD:
;	move.w  #$0000,FixWriteConfig
;
;	lea     PALETTES,a0			; Set up palettes for text
;	move.w  #BLACK,(a0)+
;	move.w  #WHITE,(a0)+
;	move.w  #BLACK,(a0)
;
;	move.b  d0,REG_DIPSW
;
;	jsr     ClearFix
;
;	; Print error message
;    lea     ErrFixStrList,a0
;	add.w   d0,d0
;	add.w   d0,d0
;	adda.l  d0,a0
;	movea.l (a0),a0
;	move.w  #FIXMAP+4+(4*32),d0
;	jsr     WriteFix
;
;    ; Display requested MSF
;	move.l  $10F6C8,d0			; Retrieve requested MSF
;	lsr.l   #8,d0               ; Rightmost byte is unused
;	move.l  d0,FixValueList
;    lea     FixStrReqSec,a0
;	move.w  #FIXMAP+14+(4*32),d0
;	jsr     WriteFix
;
;	jsr     DebugDispFileName
;
;	move.b  #1,REG_ENVIDEO
;	move.b  #0,REG_DISBLSPR
;	move.b  #0,REG_DISBLFIX
;
;	jmp     Lockup
;

Lockup:
	move.b  d0,REG_DIPSW
    move.b  BIOS_P1CURRENT,d0
    cmp.b   #$F0,d0				; A+B+C+D
    bne     Lockup
	jmp     $C00402				; Reset
