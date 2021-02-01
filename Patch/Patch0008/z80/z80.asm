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

; Smol sound driver

.MEMORYMAP
DEFAULTSLOT 0
SLOTSIZE $1000
SLOT 0 $0000
.ENDME
.ROMBANKMAP
BANKSTOTAL 1
BANKSIZE $1000
BANKS 1
.ENDRO

.define STACK	     	$FFFC
.define	FIFO_BUFFER	    $F800	; 32 bytes, must be 256 bytes aligned
.define RAM_ADDR     	$F840

.ENUM RAM_ADDR
NeedReset	DB
ToProcess	DB                  ; Command to process
ChannelCache 	DS 6          	; 6 bytes to store sample index for each voice
ChannelWaiting  DS 6	        ; Sample waiting in channel
CurrentSample   DB
NextPCMChn 	DB
GetPointer	DB
PutPointer	DB
.ENDE

.bank 0 slot 0
.org $0000
	di
	jp   EntryPoint
	
.org $8
    push  af
    pop   af
    push  af
    pop   af
    push  af
    pop   af
    ret

sendDEPortA:
	push af
	ld   a,d
	out  (4),a
	rst  8
	ld   a,e
	out  (5),a
	rst  8
	pop  af
	ret

sendDEPortB:
	push af
	ld   a, d
	out  (6),a
	rst  8
	ld   a, e
	out  (7),a
	rst  8
	pop af
	ret

; IRQ: YM2610 timer tick
.org $38
	reti

; NMI: Received command
.org $66
	push  af
	push  bc
	push  de
	push  hl
	
	xor   a
	out   ($18),a
	out   ($0C),a

	in    a,(0)			; Read byte from 68k
	ld    b,a
	cp    1				; BIOS/system command
	jp    z,Command01_Handler
	cp    3
	jp    z,Command03_Handler

	ld    hl,FIFO_BUFFER
	ld    a,(PutPointer)
	ld    l,a
	ld    (hl),b
	inc   a
	and   $1F
	ld    (PutPointer),a

	ld    a,b
	out   ($0C),a			; Send ACK
	ld    a,$80
	out   ($00),a
	out   ($08),a

	pop   hl
	pop   de
	pop   bc
	pop   af
	retn


.org $0100
.db "Smol sound driver"

EntryPoint:
	di
	xor   a
	out   ($0C),a			; Reply = 0 (init in progress)
	ld    b,$40             ; Wait (useless ?)
-:
	nop
	djnz  -
	xor   a
	out   ($0C),a			; Reply = 0 (init in progress)

	ld    sp,STACK
	im    1

	xor   a
    ld    ($F800),a			; Clear RAM
    ld    hl,$F800
    ld    de,$F801
    ld    bc,$800-1
    ldir

	xor   a
	ld    (NextPCMChn), a
	ld    (GetPointer),a
	ld    (PutPointer),a
	
	; ROM bank setup
	ld      a,1eh
	in      a,(08h)         ; $1E*$800=$F000
	ld      a,0eh
	in      a,(09h)         ; $E*$1000=$E000
	ld      a,06h
	in      a,(0ah)         ; 6*$2000=$C000
	ld      a,02h
	in      a,(0bh)		    ; 2*$4000=$8000
	
	out     (08h),a		    ; Enable NMIs

ym2160Reset:
	ld	de,$2801            ; FM channels off
	call	sendDEPortA
	ld	de,$2802
	call	sendDEPortA
	ld	de,$2805
	call	sendDEPortA
	ld	de,$2806
	call	sendDEPortA

	ld	de,$0800            ; SSG channels off
	call	sendDEPortA
	ld	de,$0900
	call	sendDEPortA
	ld	de,$0a00
	call	sendDEPortA

	ld	de,$00BF
	call	sendDEPortB     ; ADPCM-A channels off

	ld	de,$1001
	call	sendDEPortA     ; ADPCM-B channel reset
	ld	de,$1c00
	call	sendDEPortA
	ld	de,$1000
	call	sendDEPortA
	ld	de,$2730            ; Reset timers
	call	sendDEPortA

	ei

	ld      a,(NeedReset)	; Goes in a loop in RAM waiting for interrupt
	jr      z,+
	
	out     (08h),a		    ; Enable NMIs
	ei
	ld      hl,$FFFD
	ld      (hl),$C3	    ; JP opcode
	ld      ($FFFE),hl	    ; $FFFD
	ld      a,1
	out     ($0C),a		    ; Tell 68k we're ready for bankswitch
	jp      $FFFD           ; Jump to RAM
+:

	ld      a,3
	out     ($0C),a		    ; Ready to accept commands !
	
	ld    	de,$013F
	call	sendDEPortB 	; ADPCM-A max volume
	ld	    de,$1B00
	call	sendDEPortA	    ; ADPCM-B silent


MainLoop:
	ld    a,(PutPointer)
	ld    b,a
	ld    a,(GetPointer)
	and   $1F               ; Useless ?
	cp    b
	jr    z,MainLoop		; FIFO is empty

	ld    c,a
	; New command, pop it out
	ld    hl,FIFO_BUFFER
	ld    l,a
	ld    a,(hl)			; Read command
	ld    (ToProcess),a
	
	call  PlaySound

    out   (18h),a		    ; Disable NMIs

	ld    a,(GetPointer)
	inc   a
	and   $1F
	ld    (GetPointer),a

    out   (08h),a		    ; Enable NMIs

	jr    MainLoop
	
PlaySound:
	ld    a,(ToProcess)
	and   $7F
	ld    (CurrentSample),a

	push  af
	ld    h,0
	ld    l,a
	ld    d,h
	ld    e,l
	add   hl,hl		; *5
	add   hl,hl
	add   hl,de
	ld    de,SampleInfos
	add   hl,de
	push  hl
	pop   ix		; IX=HL
	pop   af
	
	ld	  a,(ix + 4)
	ret   z            ; Zero flag means unused sound code

; Play ADPCM-A sample
; Search for a channel playing the same sample
	ld	  hl,ChannelCache
	ld	  b,0
-:
	ld	  a,(CurrentSample)
    ld	  e,(hl)
	cp	  e				; Match, restart channel
	jp 	  z,VoiceFound
	inc	  hl
	inc   b
	ld	  a,b
	cp	  6
	jp	  nz,-

	; No channel available, use the next one
	ld	  a,(NextPCMChn)
	ld	  b,a
	inc	  a
	cp	  6
	jr	  nz,noWarp
	xor	  a
noWarp:
	ld	  (NextPCMChn),a

VoiceFound:
	; Store sample number in cache
	ld	  hl,ChannelCache
	ld	  d,0
	ld	  e,b
	add	  hl,de
	ld	  a,(CurrentSample)
	ld	  (hl),a

	ld	  a,b
	add	  a,8
	ld    d,a
	ld	  e,$DF             ; Max channel volume + L + R
	call  sendDEPortB

	ld	  a,b
	add	  a,$10
	ld	  d,a
	ld	  e,(ix + 1)
	call  sendDEPortB		; Start LSB
	add	  a,8
	ld	  d,a
	ld	  e,(ix + 0)
	call  sendDEPortB		; Start MSB
	add	  a,8
	ld	  d,a
	ld	  e,(ix + 3)
	call  sendDEPortB		; End LSB
	add	  a,8
	ld	  d,a
	ld	  e,(ix + 2)
	call  sendDEPortB		; End MSB

	ld	  a,b
	ld	  l,a
	ld	  h,0
	ld	  de,KeyOn
	add	  hl,de               	; KeyOn + Channel
	ld	  e,(hl)
	ld	  d,0
	call  sendDEPortB        	; Dump=0 means note on

	ret

KeyOn:
	.db $01,$02,$04,$08,$10,$20

Command01_Handler:
	di
	xor   a
	out   ($0C),a		; Tell 68k to wait
	out   ($00),a       ; Clear receive buffer
	inc   a
	ld    (NeedReset),a	; Sit-in-RAM flag
	ld    sp,$FFFC
	ld    hl,ym2160Reset
	push  hl
	retn

Command03_Handler:
	xor   a
	out   ($0C),a
	out   ($00),a
	ld    sp,$FFFC
	ld    hl,EntryPoint
	push  hl
	retn

; Format: Start Start End End Flags
SampleInfos:
	.include "sample_table.inc"
