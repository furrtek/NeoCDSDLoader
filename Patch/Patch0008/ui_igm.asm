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

SetupIGM:
    clr.b   IGMMode
    clr.b   IGMCursor
    clr.b   PrevIGMCursor
    clr.b   IGMCursorShift
    st.b    IsInIGM

    ; Save palettes #14 and #15 to palette buffer
    lea     (PALETTES+(2*16*14)),a0
    lea     PaletteBuffer,a1
    jsr     CopyPalette
    jsr     CopyPalette

    ; Load new palettes
    lea     IGMPalettes,a0
    lea     (PALETTES+(2*16*14)),a1
    jsr     CopyPalette
    jsr     CopyPalette

    ; Save first half of fix bank #0 to RAM buffer
    move.b  #1,REG_DISBLFIX
    move.b  #1,REG_UPLOAD_EN
    move.b  d0,REG_UPMAPFIX
    move.b  #5,REG_TRANSAREA

    lea     $E00000,a0
    lea     FixBankBuffer,a1
    move.w  #4096/2,d7
.savefix:
    move.w  (a0)+,d0
    move.b  d0,(a1)+
    move.w  (a0)+,d0
    move.b  d0,(a1)+
    subq.w  #1,d7
    bne     .savefix

    ; Load first half menu fix bank #0
    lea     FixBankZero,a0
    lea     $E00000,a1
    move.w  #4096/2,d7
.copy:
	move.b  (a0)+,d0        ; Read AA BB, store 00 BB 00 AA
	move.b  (a0)+,d1
    move.w  d1,(a1)+        ; 00 BB
	move.w  d0,(a1)+		; 00 AA
	subq.w  #1,d7
    bne     .copy

    move.b  d0,REG_UPUNMAPFIX
    move.b  #0,REG_UPLOAD_EN
    move.b  #0,REG_DISBLFIX

    ; Save fix map block
    move.w  #IGM_WIDTH,d0
    move.w  #IGM_HEIGHT,d1
    move.w  #FIXMAP+8+(5*32),d2
    jsr     SaveFixMap

    move.w  #$E000,FixWriteConfig   ; Palette #14 bank 0

    jsr     DrawIGMBox

	lea     StrIGMItems,a0
    move.w  #FIXMAP+9+(7*32),d0
	jsr     WriteFix

    move.w  #$F000,FixWriteConfig   ; Palette #15 bank 0

    ; Draw game name
	move.w  #32,REG_VRAMMOD
    lea     SoftDIPsPtrs,a0
    moveq.l #0,d0
    move.b  BIOS_COUNTRY_CODE,d0
    andi.b  #3,d0
    add.w   d0,d0
    add.w   d0,d0
    move.l  (a0,d0),a0
    move.l  (a0),a0
    move.l  a0,SDIPAddr           ; Since we're here already, store SDIPAddr for the soft DIPs editor
	move.w  FixWriteConfig,d1
    move.w  #FIXMAP+11+(7*32),REG_VRAMADDR
    moveq.l #16,d7
.writechar:
    nop
    move.b  (a0)+,d1
	move.w  d1,REG_VRAMRW
    subq.w  #1,d7
    bne     .writechar

    ; Draw country
    moveq.l #0,d0
    move.b  BIOS_COUNTRY_CODE,d0
    andi.b  #3,d0
    add.b   d0,d0
    add.b   d0,d0
    lea     CountryList,a0
    move.l  0(a0,d0),a0
    move.w  #FIXMAP+11+(28*32),d0
	jsr     WriteFix

    move.w  #$E000,FixWriteConfig   ; Palette #14 bank 0

    jsr     DrawIGMCursor

	rts
	
	
IGMVBL:
    IF TARGET==1
    jsr     $C0D6E6             ; Copied from original routine in SYSTEM_INT1, jsr to ProcessCDDACmds
    ELSEIF TARGET==2
    jsr     $C0D022             ; Copied from original routine in SYSTEM_INT1, jsr to ProcessCDDACmds
    ELSEIF TARGET==3
    jsr     $C0D0BA             ; Copied from original routine in SYSTEM_INT1, jsr to ProcessCDDACmds
    ENDIF

    tst.b   FlagSelectStart
    beq     .nof
    clr.b   FlagSelectStart
    tst.b   IsInIGM
    bne     .nof
    jsr     SetupIGM
.nof:

    tst.b   IsInIGM
    beq     .noigm

    ; Call proc for current IGM mode
    moveq.l #0,d0
    move.b  IGMMode,d0
    lsl.l   #2,d0
    lea     JT_IGMVBLProcs,a0
    move.l  0(a0,d0),a0
    jsr     (a0)

.noigm:
    rts
    
    
IGMVBLProcSelect:
    TESTCHANGE CNT_UP
    beq     .no_up
    tst.b   IGMCursor
    beq     .no_up
    subq.b  #1,IGMCursor
    jsr     DrawIGMCursor
.no_up:

	TESTCHANGE CNT_DOWN
    beq     .no_down
    cmp.b   #2,IGMCursor
    bhs     .no_down
    addq.b  #1,IGMCursor
    jsr     DrawIGMCursor
.no_down:

    TESTCHANGE CNT_A
    beq     .no_a
	lea     JT_IGMSetups,a0
	moveq.l #0,d0
	move.b  IGMCursor,d0
	lsl.w   #2,d0				; JT_IGMSetups has 4-byte entries
	move.l  0(a0,d0),a0
	jsr     (a0)
.no_a:

    ; B press and release
    move.b  BIOS_P1CURRENT,d0
    move.b  BIOS_P1PREVIOUS,d1
    eor.b   d1,d0
    and.b   d1,d0
    andi.b  #1<<CNT_B,d0
    beq     .no_b
    jsr     CloseIGM
.no_b:
    rts


DrawIGMCursor:
    move.w  #FIXMAP+13+(7*32),d2

    ; Erase previous cursor
    lea     IGMItemsY,a0
    moveq.l #0,d0
    move.b  PrevIGMCursor,d0
    add.b   d0,d0
    move.w  (a0,d0),d0
    add.w   d2,d0
    move.w  d0,REG_VRAMADDR
	move.w  FixWriteConfig,d1
    move.b  #' ',d1
    nop
    move.w  d1,REG_VRAMRW

    ; Draw new cursor
    moveq.l #0,d0
    move.b  IGMCursor,d0
    add.b   d0,d0
    move.w  (a0,d0),d0
    add.w   d2,d0
    move.w  d0,REG_VRAMADDR
    move.b  #CHAR_ARROW_RIGHT,d1
    move.b  IGMCursor,PrevIGMCursor
    nop
    move.w  d1,REG_VRAMRW
    rts
    
IGMItemsY:
    dc.w 0, 1, 3
	

CloseIGM:
    ; Restore palettes #14 and #15 from palette buffer
    lea     PaletteBuffer,a0
    lea     (PALETTES+(2*16*14)),a1
    jsr     CopyPalette
    jsr     CopyPalette

    ; Restore fix bank #0 from RAM buffer
    move.b  #1,REG_DISBLFIX
    move.b  #1,REG_UPLOAD_EN
    move.b  d0,REG_UPMAPFIX
    move.b  #5,REG_TRANSAREA

    ; Restore fix bank
    lea     FixBankBuffer,a0
    lea     $E00000,a1
    move.w  #4096/2,d7      ; Only first half of fix bank is enough
.copy:
	move.b  (a0)+,d0        ; Read AA BB, store 00 AA 00 BB
    move.w  d0,(a1)+        ; 00 AA
	move.b  (a0)+,d0
	move.w  d0,(a1)+	    ; 00 BB
	subq.w  #1,d7
    bne     .copy

    move.b  d0,REG_UPUNMAPFIX
    move.b  #0,REG_UPLOAD_EN

    ; Restore fix map block
    move.w  #IGM_WIDTH,d0
    move.w  #IGM_HEIGHT,d1
    move.w  #FIXMAP+8+(5*32),d2
    jsr     RestoreFixMap
    move.b  #0,REG_DISBLFIX

    move.b  #$02,BIOS_STATCURNT  ; Fake P1 START press to cancel pause
    move.b  #$02,BIOS_STATCHANGE

    clr.b   IsInIGM
    bset.b  #7,BIOS_SYSTEM_MODE
    rts

    
DrawIGMBox:
    move.w  #32,REG_VRAMMOD
    move.w  FixWriteConfig,d1
    move.w  #FIXMAP+8+(5*32),d2

    move.w  #IGM_WIDTH,d7
    lea     FixMapIGMTopA,a0
    jsr     BoxDrawRow

    move.w  #IGM_WIDTH,d7
    lea     FixMapIGMTopB,a0
    jsr     BoxDrawRow

    move.w  #IGM_HEIGHT-2-1,d6
.rowfill:
    move.w  #IGM_WIDTH,d7
    lea     FixMapIGMRow,a0
    jsr     BoxDrawRow
    subq.w  #1,d6
    bne     .rowfill

    move.w  #IGM_WIDTH,d7
    lea     FixMapIGMBot,a0
    jsr     BoxDrawRow
    rts
    
ClearIGM:
    move.w  #32,REG_VRAMMOD
    move.w  FixWriteConfig,d1
    move.w  #FIXMAP+10+(5*32),d2

    move.w  #IGM_HEIGHT-2-1-1,d6    ; Don't erase second-to-last line to keep instructions shown
.rowfill:
    move.w  #IGM_WIDTH,d7
    lea     FixMapIGMRow,a0
    jsr     BoxDrawRow
    subq.w  #1,d6
    bne     .rowfill
    rts
    
IGMPalettes:
    ; Normal
    dc.w  BLACK
    dc.w  WHITE
    dc.w  BLACK
    dc.w  GREEN
    dc.w  $0E90
    dc.w  BLACK
    dc.w  BLACK
    dc.w  $0B40
    dc.w  BLACK,BLACK,BLACK,BLACK,BLACK,BLACK,BLACK,BLACK

    ; Highlight
    dc.w  BLACK
    dc.w  $0CBF
    dc.w  BLACK
    dc.w  GREEN
    dc.w  $0E90
    dc.w  BLACK
    dc.w  BLACK
    dc.w  $0B40
    dc.w  BLACK,BLACK,BLACK,BLACK,BLACK,BLACK,BLACK,BLACK


FixMapIGMTopA:
    dc.w $008
    dc.w $009
    dc.w [IGM_WIDTH-3]$016
    dc.w $002
FixMapIGMTopB:
    dc.w $018
    dc.w $019
    dc.w [IGM_WIDTH-3]$020
    dc.w $015
FixMapIGMRow:
    dc.w $014
    dc.w [IGM_WIDTH-2]$020
    dc.w $015
FixMapIGMBot:
    dc.w $003
    dc.w [IGM_WIDTH-2]$017
    dc.w $004

JT_IGMSetups:
    dc.l IGMSetupCheats
    dc.l IGMSetupSDIP
    dc.l $C0055E  ; BIOSF_CDPLAYER

; This must match IGMMode values !
JT_IGMVBLProcs:
    dc.l IGMVBLProcSelect
    dc.l IGMVBLProcCheats
    dc.l IGMVBLProcSDIP

; To avoid having to load the Japanese charset, a region map is used:
; Console   Soft DIPs
; JP        US
; US        US
; EU        EU
; BR        US
SoftDIPsPtrs:
    dc.l $11A   ; US
    dc.l $11A   ; US
    dc.l $11E   ; EU
    dc.l $11A   ; US
