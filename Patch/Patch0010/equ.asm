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

VERSION_MAJ     equ 0
VERSION_MIN     equ 10

SSAVER_TIMEOUT  equ 30

FixMapBuffer    equ $110804 ; "FixSaveBuffer"

; HW registers:
CPLDREG_DATA    equ $C1E000
CPLDREG_EXEC    equ $C1E100
CPLDREG_STAT    equ $C1E200

BG_CODE         equ 255
EXCEED_CODE     equ 254

CDSectorBuffer  equ $111204
CD_SECTOR_SIZE  equ 2048

SAVE_DATA1      equ MEMCARD+1         ; See doc.odt for format
SAVE_DATA2      equ MEMCARD+9         ; See doc.odt for format (3, 5, 7 locations are used by CD bios)

MAX_FILES       equ 200               ; Total max, 97 officially released games
MAX_MENU_LIST	equ	MAX_FILES         ; Max entries for currently select letter
MAX_MENU_LINES  equ 15                ; Max lines displayed at once
MAX_FILENAME    equ 25+1              ; Max length of file name, null included

TIMEOUT_ACK     equ 193534            ; 5.167us, ~1s
TIMEOUT_EXEC    equ 774200            ; 5.167us, ~4s

CHAR_BOX        equ 5
CHAR_BOX_CHECKED equ 6
CHAR_ARROW_LEFT equ 16
CHAR_ARROW_RIGHT equ 17
CHAR_ARROW_UP   equ 18
CHAR_ARROW_DOWN equ 19

MSGBOX_WIDTH    equ 24
MSGBOX_HEIGHT   equ 14

IGM_WIDTH    equ 30
IGM_HEIGHT   equ 14

MAX_CHEAT_LINES equ 8
MAX_CHEAT_DESC  equ 24      ; This must match the value in the Python converter script

MCU_CMD_TEST        equ 0
MCU_CMD_GETID       equ 1
MCU_CMD_GETSTATUS   equ 2
MCU_CMD_UPDATE      equ 3
MCU_CMD_RESET       equ 4
MCU_CMD_INITSD      equ 5
MCU_CMD_GETGAMES    equ 6
MCU_CMD_SELECTGAME  equ 7
MCU_CMD_LOADSECT    equ 8
MCU_CMD_CDDA        equ 9
MCU_CMD_DUMPROM    	equ 10
MCU_CMD_GETSAVES    equ 11
MCU_CMD_STORESAVE   equ 12
MCU_CMD_LOADSAVE    equ 13

SCREEN_IDLE     equ 0
SCREEN_MAIN     equ 1
;SCREEN_ROMDUMP  equ 2          ; Unused
;SCREEN_COMMTEST equ 3          ; Unused
;SCREEN_ID       equ 4          ; Unused
;SCREEN_DEBUGSD  equ 5          ; Unused
;SCREEN_DEBUGISO equ 6          ; Unused
SCREEN_MENU     equ 7
SCREEN_STORE_SAVE equ 8
SCREEN_LOAD_SAVE equ 9
SCREEN_SETTINGS equ 10
; ID 11 used for debug, see ui.asm
SCREEN_ABOUT    equ 12
SCREEN_SSAVER   equ 13
SCREEN_MSGBOX   equ 15

TILE_CURSOR  	equ     $58		; Tile number for the letter cursor

SPR_BG			equ		1       ; Sprite numbers
SPR_LOGO		equ		21
SPR_LETTERS		equ		32
SPR_LETTER_CUR	equ     60
SPR_ARROW_L 	equ     62
SPR_ARROW_R 	equ     63

SFX_MOVE        equ     $41
SFX_POS         equ     $42
SFX_NEG         equ     $43
SFX_VAL         equ     $44
SFX_EXIT        equ     $45

; These should all be the same for all BIOS versions
CDLoadBusy          equ $10F6B6
CDValidFlag         equ $10F656
FirstPRGSector      equ $110004
ProgressBarCodePtr  equ $11C80C
SectorCounter       equ $7688
SectorLoadCounter   equ $7DE2
BankCounter         equ $7EDB   ; BIOS_UPBANK
FirstLoadBank       equ $7EDE
SectorLoadDest      equ $7EF4   ; BIOS_UPDEST
SectorLoadBuffer    equ $7EF8   ; BIOS_UPSRC
SectorLoadSize      equ $7EFC   ; BIOS_UPSIZE

ENDIAN_CHG_L MACRO reg      ; DD CC BB AA
    rol.w   #8,reg          ; DD CC AA BB
    swap.l  reg             ; AA BB DD CC
    rol.w   #8,reg          ; AA BB CC DD
    ENDM

MCUCMD MACRO cmd
    move.b  #cmd,d3
    jsr     MCUCommand
    ENDM

TESTCHANGE MACRO btn
    move.b  BIOS_P1CHANGE,d0
    or.b    BIOS_P2CHANGE,d0
    andi.b  #(2^btn),d0
    ENDM

TESTREPEAT MACRO btn
    move.b  BIOS_P1REPEAT,d0
    or.b    BIOS_P2REPEAT,d0
    andi.b  #(2^btn),d0
    ENDM

FIXPOS FUNCTION x,y,(FIXMAP+y+(x*32))

DIIRQ MACRO
    move.b  d0,REG_DIPSW
	move.w  sr,-(a7)
	ori.w   #$0700,sr
	ENDM

ENIRQ MACRO
	move.w  #7,REG_IRQACK
	move.w  (a7)+,sr
	ENDM
