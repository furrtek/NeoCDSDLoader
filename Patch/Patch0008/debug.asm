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

    IFDEF DEBUGBUILD
WarmResetTest:
    move.b  #0,REG_ENVIDEO      ; Copied from original routine, disables video
    cmp.w   #$201,$108          ; mslug NGH = 201
    ;beq     .gotmslug
    rts
.gotmslug:
    move.b  #1,REG_DISBLSPR
    move.b  #0,REG_DISBLFIX
    move.b  #1,REG_ENVIDEO
    move.l  #NullIRQ,$68

    move.l  2(a7),PCERROR       ; Store PC from stack frame
    movem.l d0-d7/a0-a6,-(a7)   ; Store registers
    move.w  #RED,BACKDROP
    lea     FixStrWarmReset,a0
    jmp     DispExc

NullIRQ:
    movem.l d0-a6,-(sp)
    move.b  d0,REG_DIPSW
    move.w  #4,REG_IRQACK
    movem.l (sp)+,d0-a6
    rte

DrawProgressAnimation:
	; Display sector counter at 20,16
	move.w  #$3100,FixWriteConfig
	move.w  #FIXMAP+16+(20*32),d0
	move.w  $10F688,d2			; "SectorCounter"
    jsr     WriteWord
	rts
	
DebugDispFileName:
	move.w  #$3100,FixWriteConfig

    lea     FixStrClear,a0
	move.w  #FIXMAP+16+(4*32),d0
    jsr     WriteFix 			; Clear file name line

    movea.l $10F6A0,a0			; "FilenamePtr"
	move.w  #FIXMAP+16+(4*32),d0
    jsr     WriteFix 			; Display filename
    rts
    
DebugDispMSF:
    ; Display requested MSF at 6,3
	;move.l  $10F6C8,d0			; Retrieve requested MSF
	move.l  MSFCounter,d0
    lsr.l   #8,d0               ; Rightmost byte is unused
	move.l  d0,FixValueList
    lea     FixStrReqSec,a0
	move.w  #FIXMAP+3+(6*32),d0
	jsr     WriteFix
	move.b  d0,REG_DIPSW
	rts

DebugDispCDSectors:
    ; Display number of CD sectors to load at 6,5
	moveq.l #0,d0
	move.w  $10F688,d0			; Retrieve requested sector count to load
	move.l  d0,FixValueList
    lea     FixStrCDSecCnt,a0
	move.w  #FIXMAP+5+(6*32),d0
	jsr     WriteFix
	move.b  d0,REG_DIPSW
	rts
    ENDIF

RefreshDump:
	jsr     ClearFix

	move.w  #$3000,FixWriteConfig	; Palette 3, bank 0

	; Print address
	lea     FixValueList,a0
	move.l  a1,(a0)+
    lea     FixStrLongwordVal,a0
	move.w  #FIXMAP+3+(2*32),d0
	jsr     WriteFix

	movea.l a1,a2
	move.w  #32,REG_VRAMMOD
    move.w  #FIXMAP+5+(6*32),d0
	move.w  #24,d7			; 24 lines
.writeblock:
	move.w  d0,REG_VRAMADDR
	moveq.l #0,d1
	move.w  #16,d6			; 16 bytes per line (32 chars)
.writeline:
	move.b  d0,REG_DIPSW
	move.b  (a2)+,d2		; Read byte from memory
	move.b  d2,d1 			; Split in nibbles

	lsr.b   #4,d1
	jsr     Hexify
	or.w    FixWriteConfig,d1
	move.w  d1,REG_VRAMRW
	
	move.b  d2,d1
	andi.b  #$F,d1
	jsr     Hexify
	move.w  d1,REG_VRAMRW

	subq.b  #1,d6
	bne     .writeline

	addi.w  #1,d0			; Go down one line in the fix map
	subq.b  #1,d7
	bne     .writeblock
	rts

MemoryViewer:
	move.b  d0,REG_DIPSW

	lea     (2*16*3)+PALETTES,a0	; Set up palette 3 for text
	move.w  #BLACK,(a0)+
	move.w  #WHITE,(a0)+
	move.w  #BLACK,(a0)

	jsr     RefreshDump

	move.b  #1,REG_ENVIDEO
	move.b  #0,REG_DISBLSPR
	move.b  #0,REG_DISBLFIX

.loop:
	move.b  d0,REG_DIPSW

	move.b  REG_P1CNT,d0
	not.b   d0
	move.b  d0,d1
	eor.b   d0,d3
    and.b   d0,d3
    
    move.l  d1,(a7)+

    cmp.b   #$01,d3
    bne     .no_up
	subi.l  #16,a1				; UP: Address -= 16
	jsr     RefreshDump
.no_up:
    cmp.b   #$02,d3
    bne     .no_down
	addi.l  #16,a1				; DOWN: Address += 16
	jsr     RefreshDump
.no_down:
    cmp.b   #$04,d3
    bne     .no_left
	subi.l  #256,a1				; LEFT: Address -= 256
	jsr     RefreshDump
.no_left:
    cmp.b   #$08,d3
    bne     .no_right
	addi.l  #256,a1				; RIGHT: Address += 256
	jsr     RefreshDump
.no_right:

    move.l  -(a7),d1

    move.b  d1,d3
    bra     .loop
    
    IFDEF MAMEDEBUG
DebugSetupMain:
    ; Set up a fake game file list for debugging
	lea     GameDebugList,a0
	lea     FileList,a1
	move.w  #DEBUGFILECOUNT*FileEntry_LEN,d7
.debug_game_list:
	move.b  (a0)+,(a1)+
	subq.w  #1,d7
	bne     .debug_game_list
	move.w  #DEBUGFILECOUNT,TotalFileCount

	; DEBUG - Load embedded BMP data for custom bg
	lea     DebugCustomBgData,a0
    ; Check BM magic at 00
    cmp.w   #$424D,$0(a0)
    bne     .bmpfail
    ; Check 320px at 12
    cmp.l   #$40010000,$12(a0)
    bne     .bmpfail
    ; Check 224px at 16
    cmp.l   #$E0000000,$16(a0)
    bne     .bmpfail
    ; Check 4bpp at 1C
    cmp.w   #$0400,$1C(a0)
    bne     .bmpfail
    ; Check no compression 0 at 1E
    cmp.l   #0,$1E(a0)
    bne     .bmpfail
    ; Get pixel data pointer from 0A
    move.l  $A(a0),d0       ; DD CC BB AA
    rol.w   #8,d0           ; DD CC AA BB
    swap.l  d0              ; AA BB DD CC
    rol.w   #8,d0           ; AA BB CC DD
    move.l  d0,a2
    add.l   a0,a2
    ; Get size of header from 0E
    move.l  $E(a0),d0       ; DD CC BB AA
    rol.w   #8,d0           ; DD CC AA BB
    swap.l  d0              ; AA BB DD CC
    rol.w   #8,d0           ; AA BB CC DD
    addi.l  #$E,d0
    add.l   d0,a0
    ; Load palette (4 bytes RGBA per entry * 16)
    lea     (PALETTES+(2*16*16)),a1     ; Palette #16
    moveq.l #16,d7
.convertpal:
    moveq.l #0,d1
    move.b  (a0)+,d0    ; B
    lsr.b   #4,d0
    andi.w  #$000F,d0
    or.w    d0,d1
    move.b  (a0)+,d0    ; G
    lsr.b   #4,d0
    lsl.w   #4,d0
    andi.w  #$00F0,d0
    or.w    d0,d1
    move.b  (a0)+,d0    ; R
    lsr.b   #4,d0
    lsl.w   #8,d0
    andi.w  #$0F00,d0
    or.w    d0,d1
    move.w  d1,(a1)+
    move.b  (a0)+,d0    ; Skip A
    subq.w  #1,d7
    bne     .convertpal
    ; Copy color #0 to BACKDROP
    move.w  (PALETTES+(2*16*16)),BACKDROP

    move.b  #1,REG_DISBLSPR
    move.b  #1,REG_UPLOAD_EN
    move.b  d0,REG_UPMAPSPR
    move.b  #0,REG_TRANSAREA

    ; Load pixels
    lea     LUTIndexToBitplane,a0
    ; Start at bottom left pixel of bottom left tile
    ; Pen and paper required...
    lea     ($E00000+(256*128)+(128*14)-4),a4

    move.l  #14,d4
.fullheight:
    move.l  a4,a3
    subi.l  #128,a4

    move.l  #16,d5
.tileheight:
    move.l  a3,a1
    subi.l  #4,a3

    moveq.l #20,d6
.sixteenpixelsrow:

    moveq.l #0,d0
    move.l  d0,d1
    move.l  d0,d2       ; 4 bitplane * 8 bit shift register
    moveq.l #4,d7
.rowa:
    move.b  (a2)+,d1    ; Left pixel A
    move.b  d1,d0
    lsr.b   #4,d1
    lsl.b   #2,d1
    lsr.l   #1,d2
    or.l    0(a0,d1),d2
    andi.b  #$F,d0      ; Right pixel A
    lsl.b   #2,d0
    lsr.l   #1,d2
    or.l    0(a0,d0),d2
    subq.b  #1,d7
    bne     .rowa
    move.l  d2,0(a1)

    moveq.l #0,d0
    move.l  d0,d1
    move.l  d0,d2       ; 4 bitplane * 8 bit shift register
    moveq.l #4,d7
.rowb:
    move.b  (a2)+,d1    ; Left pixel B
    move.b  d1,d0
    lsr.b   #4,d1
    lsl.b   #2,d1
    lsr.l   #1,d2
    or.l    0(a0,d1),d2
    andi.b  #$F,d0      ; Right pixel B
    lsl.b   #2,d0
    lsr.l   #1,d2
    or.l    0(a0,d0),d2
    subq.b  #1,d7
    bne     .rowb
    move.l  d2,-64(a1)
    
    lea     128*14(a1),a1

    subq.w  #1,d6
    bne     .sixteenpixelsrow

    subq.w  #1,d5
    bne     .tileheight

    subq.w  #1,d4
    bne     .fullheight

    st.b    CustomBGLoaded

    move.b  d0,REG_UPUNMAPSPR
    move.b  #0,REG_UPLOAD_EN
    move.b  #0,REG_DISBLSPR

.bmpfail:
    rts
    ENDIF

	
; Required for mslug ! Otherwise a watchdog reset occurs after IPL
SYSTEM_IO_WDKICK:
    ;lea    $108000,a0
    move.b d0,REG_DIPSW

    IFDEF 0
    ; DEBUG: A+D -> Memory viewer
    move.b  BIOS_P1CURRENT,d0
	cmp.b   #$90,d0
    bne     .no_view
    movea.l #$00D190,a1
    jmp     MemoryViewer
.no_view:

    ; DEBUG: A+B -> Send $000000~$1FFFFF to MCU
    move.b  BIOS_P1CURRENT,d0
	cmp.b   #$30,d0
    bne     .no_dump
    
    movea.l #$000000,a0
	move.w  #MCU_CMD_TEST,d3
    move.l  #($200000)/4,d6
.sendloop:
    move.b  d0,REG_DIPSW

    move.b  REG_P1CNT,d0       ; C: Abort dump
	btst    #CNT_C,d0
    beq     .no_dump

	move.w  d3,CPLDREG_DATA    ; Write to MCU, lower byte of CPLDREG_DATA
    jsr     MCUWaitAck
    bcs     .timeout
    move.l  (a0)+,d4
	rol.l   #8,d4              ; BBCCDDAA
	move.w  d4,CPLDREG_DATA    ; Write to MCU, lower byte of CPLDREG_DATA
    jsr     MCUWaitAck
    bcs     .timeout
	rol.l   #8,d4              ; CCDDAABB
	move.w  d4,CPLDREG_DATA    ; Write to MCU, lower byte of CPLDREG_DATA
    jsr     MCUWaitAck
    bcs     .timeout
	rol.l   #8,d4              ; DDAABBCC
	move.w  d4,CPLDREG_DATA    ; Write to MCU, lower byte of CPLDREG_DATA
    jsr     MCUWaitAck
    bcs     .timeout
	rol.l   #8,d4              ; AABBCCDD
	move.w  d4,CPLDREG_DATA    ; Write to MCU, lower byte of CPLDREG_DATA
    jsr     MCUWaitAck
    bcs     .timeout

	move.w  d0,CPLDREG_EXEC
    jsr     MCUWaitExec
    bcs     .timeout

    subq.l  #1,d6
    bne     .sendloop

    bra     .no_dump

.timeout:
	jsr     DispErrorTimeout

.no_dump:
    ENDIF

    lea    $108000,a5
    rts

