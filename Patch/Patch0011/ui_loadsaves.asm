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

SetupLoadSave:
	move.w  #$0500,FixWriteConfig	; Bank 5 has menu font

    jsr     ClearFixTop

    moveq.l #0,d0
    move.b  d0,FileCursor
    move.b  d0,MenuShift
	move.b  d0,FileCursorPrev
    move.w  d0,TotalFileCount
	move.b  #%00000101,RefreshFlags

    jsr     ClearFileList

    IFDEF MAMEDEBUG
    ; Set up a fake save file list for debugging
	lea     SaveDebugList,a0
	lea     FileList,a1
	move.w  #DEBUGSAVECOUNT*FileEntry_LEN,d7
.debug_save_list:
	move.b  (a0)+,(a1)+
	subq.w  #1,d7
	bne     .debug_save_list
	move.w  #DEBUGSAVECOUNT,TotalFileCount
	bra     .setup_interface
    ENDIF
    

    IFNDEF MAMEDEBUG
    ; Ask MCU for save files list
    move.b  #0,MCUCmdParams
    MCUCMD  MCU_CMD_GETSAVES
    bcc     .notimeout
    jsr     DispErrorTimeout
    bra     .setup_interface
.notimeout:
    ; Read 4 words from the MCU (see doc) CHANGED
    jsr     MCURead4Words
    jsr     CheckACK
    bcs     .setup_interface
    ; Ok, get file count
    moveq.l #0,d0
    move.b  MCUReplyBuffer+1,d0
    move.w  d0,TotalFileCount

    ; Retrieve file names
    move.w  TotalFileCount,d6
    tst.w   d6
    beq     .setup_interface    ; Skip if no files
    lea     FileList,a1
.listfiles:
    move.w  #16,d3              ; 1+30+1, ID.b + string + /0 CHANGED
    jsr     MCURead4WordsMult

    lea     MCUReplyBuffer,a0
    move.w  #$FF00,d0           ; "Entry used" flag
    move.b  (a0)+,d0
    move.w  d0,(a1)+            ; File index + flag

    moveq.l #MAX_FILENAME,d7
.cp:
    move.b  (a0)+,(a1)+         ; Copy file name, cap to MAX_FILENAME chars
	subq.b  #1,d7
	bne     .cp
    move.b  #0,(a1)+            ; Force last char to 0
    move.b  #0,(a1)+            ; Padding to reach 32
    move.b  #0,(a1)+
    move.b  #0,(a1)+

	subq.w  #1,d6
	bne     .listfiles

    move.b  #0,(a1)+            ; Terminate
    ENDIF

.setup_interface:
    move.w  TotalFileCount,d7
    move.b  d7,LetterGameCount  ; For DrawFileList

    ; Just fill MenuIndexList with inc indexes for DrawFileList
	lea     MenuIndexList,a0
	moveq.l #0,d0
.listlp:
    move.b  d0,(a0)+            ; Add index to list
    addq.b  #1,d0
	subq.b  #1,d7
	bne     .listlp

    lea     FixStrLoadSaveUI,a0
	move.w  #FIXMAP+9+(5*32),d0
	jsr     WriteFix

	move.w  #SCREEN_LOAD_SAVE,CurrentScreen
	rts

VBLProcLoadSave:
	; Refresh stuff in VRAM while we're at the beginning of the vblank
	btst.b  #0,RefreshFlags
	beq     .norefresh0
	jsr     DrawFileList
.norefresh0:

	btst.b  #2,RefreshFlags
	beq     .norefresh_cur
	; Erase previous cursor
	moveq.l #0,d0
	move.b  FileCursorPrev,d0
	add.w   #FIXMAP+11+(7*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	move.w  #$0520,REG_VRAMRW	; Space, palette 0, bank 5
	tst.b   LetterGameCount
	beq     .norefresh_cur      ; No files in list, don't draw cursor
	; Draw new cursor
	moveq.l #0,d0
	move.b  FileCursor,d0
	move.b  d0,FileCursorPrev
	addi.w  #FIXMAP+11+(7*32),d0
	move.w  d0,REG_VRAMADDR
	nop
	nop
	move.w  #$0511,REG_VRAMRW	; Arrow pointing right, palette 0, bank 5
	bclr.b  #2,RefreshFlags
.norefresh_cur:

    ; Prevent loading and deleting if there are no saves found
	tst.w   TotalFileCount
	beq     .nofiles
    jsr     FileListNav

	TESTCHANGE CNT_A
    beq     .no_a
    ; Ask user for confirmation
    lea     FixStrLoadConfirm,a0
    lea     ExitLoadConfirm,a1
    jmp     MessageBoxCustom
.no_a:

	TESTCHANGE CNT_C
    beq     .no_c
    ; Ask user for confirmation
    lea     FixStrDeleteConfirm,a0
    lea     DeleteConfirm,a1
    jmp     MessageBoxCustom
.no_c:
.nofiles:

	TESTCHANGE CNT_B
    beq     .no_b
    move.b  #SFX_EXIT,d0
    jsr     PlaySFX
    jsr     SetupMenu
.no_b:
	rts

ExitLoadConfirm:
	TESTCHANGE CNT_A
    beq     .no_a
	move.b  FileCursor,d0
	add.b   MenuShift,d0
    jmp     LoadSaves
.no_a:
    move.b  #SFX_NEG,d0
    jmp     PlaySFX

DeleteConfirm:
	TESTCHANGE CNT_A
    beq     .no_a
	move.b  FileCursor,d0
	add.b   MenuShift,d0
    jsr     DeleteSaves
    jsr     SetupLoadSave       ; Refresh list
    rts
.no_a:
    move.b  #SFX_NEG,d0
    jmp     PlaySFX
