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

SetupSettings:
	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

    jsr     ClearFixTop

    lea     FixStrSettings,a0
	move.w  #FIXMAP+8+(10*32),d0
	jsr     WriteFix

    move.b  SettingCountry,UITemp   ; Used to detect change to Brazil region
	move.b  #0,FileCursor
	move.b  #0,FileCursorPrev
	move.b  #0,LetterCursor         ; Used here as debug DIP bit cursor

	move.w  #$3500,FixWriteConfig	; Bank 5 has menu font, highlight palette

	; RefreshFlags bits use in ui_settings:
	; 0: Redraw debug DIPs
	; 1: Redraw country
	; 2: Redraw item cursor
	; 3: Redraw dev mode setting
	; 4: Redraw screen saver setting
	; 5: Redraw LED color setting
	; 6: Redraw SFX setting
	; 7: Redraw boot and load anim setting
	move.b  #%11111111,RefreshFlags

	move.w  #SCREEN_SETTINGS,CurrentScreen
	rts

FixStrClearDIPs:
    dc.b "        ",0

FixStrEnabled:
    dc.b "ENABLED ",0
FixStrDisabled:
    dc.b "DISABLED",0

FixStrNew:
    dc.b "NEW",0
FixStrOld:
    dc.b "OLD",0

FixStrFast:
    dc.b "FAST",0
FixStrSlow:
    dc.b "SLOW",0

VBLProcSettings:
	; Refresh stuff in VRAM while we're at the beginning of the vblank

	btst.b  #0,RefreshFlags
	beq     .norefresh_DIPs
    ; Refresh DIPs
	bclr.b  #0,RefreshFlags

    ; Clear bit arrow
    lea     FixStrClearDIPs,a0
	move.w  #FIXMAP+12+(24*32),d0
	jsr     WriteFix

    ; Draw bit arrow
    moveq.l #0,d0
    move.b  LetterCursor,d0
    andi.b  #7,d0
    lsl.w   #5,d0
	addi.w  #FIXMAP+12+(24*32),d0
	move.w  d0,REG_VRAMADDR
    move.w  FixWriteConfig,d1
    move.b  #CHAR_ARROW_DOWN,d1
	move.w  d1,REG_VRAMRW

    ; Draw bits
    move.w  #32,REG_VRAMMOD
	move.w  #FIXMAP+13+(24*32),REG_VRAMADDR
	move.b  DebugDIP1,d0
	jsr     .drawbitvalues
	move.w  #FIXMAP+14+(24*32),REG_VRAMADDR
	move.b  DebugDIP2,d0
.drawbitvalues:
	moveq.l #8-1,d7
.bit
	move.b  #'0',d1
	lsl.b   #1,d0
	bcc     .zero
	move.b  #'1',d1
.zero:
	move.w  d1,REG_VRAMRW
	dbra    d7,.bit
.norefresh_DIPs:

	btst.b  #1,RefreshFlags
	beq     .norefresh_country
    ; Refresh country
	jsr     SaveSettings
    moveq.l #0,d0
	move.b  SettingCountry,d0
	andi.b  #3,d0
	move.b  d0,SettingCountry
    lea     CountryList,a0
    lsl.w   #2,d0
    move.l  0(a0,d0),a0
	move.w  #FIXMAP+10+(20*32),d0
	jsr     WriteFix
	bclr.b  #1,RefreshFlags
.norefresh_country:

	btst.b  #2,RefreshFlags
	beq     .norefresh_cur
	; Erase previous cursor
	moveq.l #0,d0
	move.b  FileCursorPrev,d0
    jsr     GetNavYPos
	add.w   #FIXMAP+10+(9*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	move.w  #$0520,REG_VRAMRW	; Space, palette 0, bank 5
	; Draw new cursor
	move.b  FileCursor,d0
	andi.w  #$00FF,d0
	;move.b  d0,d1
    jsr     GetNavYPos
	addi.w  #FIXMAP+10+(9*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	move.w  #$05<<8+CHAR_ARROW_RIGHT,REG_VRAMRW	; Palette 0, bank 5
	;move.b  d1,FileCursorPrev
	move.b  FileCursor,FileCursorPrev
	bclr.b  #2,RefreshFlags
.norefresh_cur:

	btst.b  #3,RefreshFlags
	beq     .norefresh_devmode
	; Refresh developer mode setting
	lea     FixStrDisabled,a0
	tst.b   BIOS_DEVMODE
	beq     .disableda
	lea     FixStrEnabled,a0
.disableda:
	move.w  #FIXMAP+15+(24*32),d0
	jsr     WriteFix
	bclr.b  #3,RefreshFlags
.norefresh_devmode:

	btst.b  #4,RefreshFlags
	beq     .norefresh_ssaver
	; Refresh screen saver setting
	jsr     SaveSettings
	lea     FixStrDisabled,a0
	move.b  SettingSSaver,d0
	andi.b  #1,d0
	beq     .disabledb
	lea     FixStrEnabled,a0
.disabledb:
	move.w  #FIXMAP+19+(24*32),d0
	jsr     WriteFix
	bclr.b  #4,RefreshFlags
.norefresh_ssaver:

	btst.b  #5,RefreshFlags
	beq     .norefresh_led
	; Refresh LED color settings
	jsr     SaveSettings
	st.b    SetMCUConfig       ; Send setting to MCU to give a preview

	moveq.l #0,d0
	move.b  SettingLEDIdle,d0
    lea     ColorList,a0
    lsl.w   #2,d0
    move.l  0(a0,d0),a0
	move.w  #FIXMAP+17+(24*32),d0
	jsr     WriteFix

	moveq.l #0,d0
	move.b  SettingLEDLoad,d0
    lea     ColorList,a0
    lsl.w   #2,d0
    move.l  0(a0,d0),a0
	move.w  #FIXMAP+18+(24*32),d0
	jsr     WriteFix

	bclr.b  #5,RefreshFlags
.norefresh_led:

	btst.b  #6,RefreshFlags
	beq     .norefresh_sfx
	; Refresh sound effects setting
	jsr     SaveSettings
	lea     FixStrDisabled,a0
	move.b  SettingSFX,d0
	andi.b  #1,d0
	beq     .disabledc
	lea     FixStrEnabled,a0
.disabledc:
	move.w  #FIXMAP+20+(25*32),d0
	jsr     WriteFix
	bclr.b  #6,RefreshFlags
.norefresh_sfx:

	btst.b  #7,RefreshFlags
	beq     .norefresh_anim
	; Refresh boot anim setting
	jsr     SaveSettings
	lea     FixStrNew,a0
	move.b  SettingBootAnim,d0
	andi.b  #1,d0
	beq     .new
	lea     FixStrOld,a0
.new:
	move.w  #FIXMAP+21+(29*32),d0
	jsr     WriteFix
	; Refresh loading anim setting
	lea     FixStrFast,a0
	move.b  SettingLoadAnim,d0
	andi.b  #1,d0
	beq     .fast
	lea     FixStrSlow,a0
.fast:
	move.w  #FIXMAP+22+(29*32),d0
	jsr     WriteFix
	bclr.b  #7,RefreshFlags
.norefresh_anim:

    ; The B button MUST be handled before L/R to make sure the settings values were
    ; sanitized by the update procedures above before saving them and exiting !
	TESTCHANGE CNT_B
    beq     no_b
    ; Show warning about Brazil region if needed, or just exit
    cmp.b   #3,UITemp
    beq     ExitSettings        ; Brazil was already selected, no need to warn user
    cmp.b   #3,SettingCountry
    bne     ExitSettings        ; Brazil isn't currently selected, no need to warn user
    lea     FixStrBrazilWarning,a0
    lea     ExitSettings,a1
    jmp     MessageBoxCustom
ExitSettings:
    move.b  #SFX_EXIT,d0
    jsr     PlaySFX
    jmp     SetupMenu
no_b:

	; Handle input to move item cursor
	TESTREPEAT CNT_UP
    beq     .no_up
    tst.b   FileCursor
    beq     .no_up
    ; Move cursor
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    subq.b  #1,FileCursor
	bset.b  #2,RefreshFlags
    bra     .no_up
.no_up:

	TESTREPEAT CNT_DOWN
    beq     .no_down
    move.b  FileCursor,d0
    addq.b  #1,d0
    cmp.b   #11,d0              ; Last item
    beq     .no_down
    ; Move cursor
    move.b  d0,FileCursor
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
	bset.b  #2,RefreshFlags
.no_down:

	TESTCHANGE CNT_LEFT
    beq     .no_left
    ; Call Left proc
    moveq.l #0,d0
    jsr     CallNavProc
.no_left:

	TESTCHANGE CNT_RIGHT
    beq     .no_right
    ; Call Right proc
    moveq.l #1,d0
    jsr     CallNavProc
.no_right:

	TESTCHANGE CNT_A
    beq     .no_a
    ; Call A proc
    moveq.l #2,d0
    jsr     CallNavProc
.no_a:

	rts

CountryList:
    dc.l FixStrJAPAN
    dc.l FixStrUSA
    dc.l FixStrEUROPE
    dc.l FixStrBRAZIL

ColorList:
    dc.l FixStrRED
    dc.l FixStrGREEN
    dc.l FixStrYELLOW
    dc.l FixStrBLUE
    dc.l FixStrMAGENTA
    dc.l FixStrCYAN
    dc.l FixStrWHITE

    
; Navigation table
; Cursor Y position (word), parameter for procs (word), Left proc (ptr), Right proc (ptr), A proc (ptr)
SettingsNavTable:
    dc.w 0, 0
    dc.l NavProcCountryL, NavProcCountryR, NavProcNull
    dc.w 1, 0
    dc.l NavProcNull, NavProcNull, NavProcRstCountry
    dc.w 3, 0
    dc.l NavProcDDIPL, NavProcDDIPR, NavProcDDIPA
    dc.w 4, 1
    dc.l NavProcDDIPL, NavProcDDIPR, NavProcDDIPA
    dc.w 5, 0
    dc.l NavProcDevModeLR, NavProcDevModeLR, NavProcNull
    dc.w 7, 0
    dc.l NavProcLEDL, NavProcLEDR, NavProcNull
    dc.w 8, 1
    dc.l NavProcLEDL, NavProcLEDR, NavProcNull
    dc.w 9, 0
    dc.l NavProcSSaverLR, NavProcSSaverLR, NavProcNull
    dc.w 10, 0
    dc.l NavProcSFXLR, NavProcSFXLR, NavProcNull
    dc.w 11, 0
    dc.l NavProcAnimLR, NavProcAnimLR, NavProcNull
    dc.w 12, 0
    dc.l NavProcLoadLR, NavProcLoadLR, NavProcNull

; d0:Proc event: 0=Left, 1=Right, 2=A
CallNavProc:
    moveq.l #0,d1
    move.b  FileCursor,d1
    lsl.w   #4,d1   ; A SettingsNavTable entry is 16 bytes
    addq.w  #1,d0   ; Skip first 2 words
    lsl.w   #2,d0   ; Addressing longs
    add.w   d1,d0
    lea     SettingsNavTable,a0
    move.l  0(a0,d0),a1     ; Get Proc pointer
    move.w  2(a0,d1),d0     ; Get Proc parameter word
    jmp     (a1)
    
; d0:Entry number
GetNavYPos:
    lsl.w   #4,d0   ; A SettingsNavTable entry is 16 bytes
    lea     SettingsNavTable,a0
    move.w  0(a0,d0),d0
    rts

NavProcNull:
    rts

NavProcCountryL:
    ; Previous country
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    subq.b  #1,SettingCountry
	bset.b  #1,RefreshFlags
	rts

NavProcCountryR:
    ; Next country
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    addq.b  #1,SettingCountry
	bset.b  #1,RefreshFlags
	rts

NavProcRstCountry:
    ; Reset country
    move.b  #SFX_VAL,d0
    jsr     PlaySFX
    jsr     ResetCountry
	bset.b  #1,RefreshFlags
	rts

NavProcSSaverLR:
    ; Toggle screen saver on/off
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    eori.b  #1,SettingSSaver
	bset.b  #4,RefreshFlags
	rts

NavProcSFXLR:
    ; Toggle sound effects on/off
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    eori.b  #1,SettingSFX
	bset.b  #6,RefreshFlags
	rts

NavProcDDIPL:
    ; Previous debug DIP bit
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    subq.b  #1,LetterCursor
	bset.b  #0,RefreshFlags
	rts

NavProcDDIPR:
    ; Next debug DIP bit
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    addq.b  #1,LetterCursor
	bset.b  #0,RefreshFlags
	rts

NavProcDDIPA:
    ; Toggle debug DIP bit
    lea     DebugDIP1,a0
    tst.b   d0
    beq     .dip1
    lea     DebugDIP2,a0
.dip1:
    moveq.l #0,d0
    move.b  LetterCursor,d0
    andi.b  #7,d0
    moveq.l #$80,d1
    lsr.b   d0,d1
    eor.b   d1,(a0)
	bset.b  #0,RefreshFlags
	rts

NavProcDevModeLR:
    ; Toggle developer mode on/off
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    tst.b   BIOS_DEVMODE   ; BIOS_DEVMODE is not guaranteed to be always equal to 00 or FF
    beq     .nodevmode     ; Toggle and fix value if needed at the same time
    move.b  #$FF,BIOS_DEVMODE
.nodevmode:
    eori.b  #$FF,BIOS_DEVMODE
	bset.b  #3,RefreshFlags
	rts

NavProcLEDL:
    ; Previous color
    lea     SettingLEDIdle,a0
    tst.b   d0
    beq     .ledidle
    lea     SettingLEDLoad,a0
.ledidle:
    move.b  (a0),d0
    tst.b   d0
    bne     .subok
    move.b  #6+1,d0
.subok:
    subq.b  #1,d0
    move.b  d0,(a0)
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
	bset.b  #5,RefreshFlags
	rts

NavProcLEDR:
    ; Next color
    lea     SettingLEDIdle,a0
    tst.b   d0
    beq     .ledidle
    lea     SettingLEDLoad,a0
.ledidle:
    move.b  (a0),d0
    cmp.b   #6,d0
    bne     .addok
    move.b  #0-1,d0
.addok:
    addq.b  #1,d0
    move.b  d0,(a0)
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
	bset.b  #5,RefreshFlags
	rts

NavProcAnimLR:
    ; Choose between old or new boot animation
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    eori.b  #1,SettingBootAnim
	bset.b  #7,RefreshFlags
	rts

NavProcLoadLR:
    ; Choose between slowed down or normal loading animations
    move.b  #SFX_MOVE,d0
    jsr     PlaySFX
    eori.b  #1,SettingLoadAnim
	bset.b  #7,RefreshFlags
	rts
