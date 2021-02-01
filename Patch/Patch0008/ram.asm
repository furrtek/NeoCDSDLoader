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

FileEntry STRUCT
Index       ds.w 1
FileName	ds.b MAX_FILENAME
Reserved    ds.b 4
FileEntry ENDSTRUCT

    IF FileEntry_LEN <> 32
        FATAL "\aFileEntry isn't == 32 !"
    ENDIF

FILE_LIST_LEN equ (MAX_FILES+1)*FileEntry_LEN    ; +1 for space to store the end-of-list entry

    IF (FILE_LIST_LEN # 16) <> 0
        FATAL "\aFILE_LIST_LEN isn't a multiple of 16 !"
    ENDIF

FIXMAPBUFFER_SIZE equ IGM_WIDTH * IGM_HEIGHT
    IF FIXMAPBUFFER_SIZE < MSGBOX_WIDTH * MSGBOX_HEIGHT
        FATAL "\aFIXMAPBUFFER_SIZE too small !"
    ENDIF
    IF FIXMAPBUFFER_SIZE > $500
        FATAL "\aFIXMAPBUFFER_SIZE too large ! Must be under $500"
    ENDIF

	PADDING ON

; ---- Starting here, values are in work RAM, so they'll get overwritten by the game ! ----
	ORG $10D000
FileCursor		ds.b 1 	; File cursor position
FileCursorPrev	ds.b 1 	;
MenuShift		ds.b 1 	; File list starting position, for scrolling
RefreshFlags	ds.b 1 	; Bit0:Refresh file list, Bit1:Refresh letter cursor, Bit2:Refresh file cursor, Bit6:Card was removed, Bit7:Reset main menu
TotalFileCount	ds.w 1 	; Total count
LetterGameCount	ds.b 1 	; File count in selected letter category
LetterCursor	ds.b 1  ; Used as index in MenuLetterList
LetterCursorPrev	ds.b 1
LetterCursorX	ds.w 1  ; Used as 10.6 fixed point
ActiveLetters   ds.l 1  ; Bitmap of the enabled letters in the menu, bits 26~0 used, # is LSB
LetterCount     ds.b 1  ; Number of active letters, equivalent to ActiveLetters set bit count
LettersXPos     ds.w 1  ; Leftmost X position of active letters group, for centering
UITemp          ds.b 1  ; General purpose
ScrollTimer     ds.b 1  ; Scrolling speed timer
ScrollX         ds.b 1  ; Scrolling shift (in chars)

DebugDIP1       ds.b 1
DebugDIP2       ds.b 1

DBGTotal        ds.l 1
DBGPass         ds.l 1
DBGWrong        ds.l 1
DBGTimeout      ds.l 1
DBGLast         ds.l 1

CurrentScreen   ds.w 1
LastScreen      ds.w 1
FrameCounter    ds.w 1
MCUStatus       ds.b 1

CurrentScreenPrev ds.w 1
;FixMapBuffer    ds.w MSGBOX_WIDTH*MSGBOX_HEIGHT
CurrentMsgBox   ds.b 1
MsgBoxExitCall  ds.l 1

FileNameBuffer  ds.b 16+1   ; For save files
FileNameCursor  ds.b 1

SSaverTimer     ds.b 1
ssaver_vars     ds.w 4*4    ; X, Y, VX, VY - All values in 10.6

RAMEndA:
    IF RAMEndA > $110000
        FATAL "\aRAM A allocation is too large !"
    ENDIF

; ---- Starting here, values are in system RAM, so they should be kept intact when a game runs ----

	ORG $11C100
MCUReplyBuffer	ds.b 64
FixValueList	ds.l 16	; List of values (max 16) used by WriteFix codes $F0+
CDSectorCount	ds.w 1	; Length of data to load (1 CD sector = 4 SD sectors)
MSFCounter      ds.l 1
PCERROR			ds.l 1	; For error screen
FixWriteConfig	ds.w 1 	; ORed with fix tilemap data to set bank and palette
SettingCountry  ds.b 1  ; JAPAN, USA, EUROPE, BRAZIL
SettingSSaver   ds.b 1
SettingLEDIdle  ds.b 1
SettingLEDLoad  ds.b 1
SettingSFX      ds.b 1
SettingBootAnim ds.b 1
LastMCUCmd      ds.b 1
MCUCmdParams    ds.b 32
IsLoading       ds.b 1
TimeOutStage    ds.b 1
PollStatus      ds.b 1
SetMCUConfig    ds.b 1
MCUVersion      ds.w 1
CDDAPending     ds.b 1
CustomBGLoaded  ds.b 1
IsInIGM         ds.b 1
IGMCursor       ds.b 1
PrevIGMCursor   ds.b 1
IGMCursorShift  ds.b 1
IGMItems        ds.b 1
IGMMode         ds.b 1  ; Selection, Cheats or Soft DIPs
SDIPAddr        ds.l 1
SDIPCount       ds.b 1  ; Number of soft DIPs entries
    ALIGN 2
SDIPItems       ds.b (14*4)+1   ; This MUST be word-aligned
CheatsBitmap    ds.l 1  ; Each bit is an enable flag for a cheat (max. 32)
CheatDataAddr   ds.l 1
FlagSelectStart ds.b 1
VBLCheatActions ds.b 64 ; This must be large enough to contain all the action codes of all cheats for a given game
PaletteBuffer   ds.w 16*2
CustomBGBackdrop  ds.w 1
LastFileCursor    ds.b 1
LastMenuShift     ds.b 1
LastLetterCursor  ds.b 1
CursorsValid    ds.b 1  ; Non-zero when FileCursor and LetterCursor are valid, used to restore cursor to last game loaded
CardEvent       ds.b 1  ; Becomes non-zero when the card was removed or inserted

RAMEndB:
    IF RAMEndB > $11C900
        FATAL "\aRAM B allocation is too large !"
    ENDIF

	ORG $11C900
FileList	    ds.b FILE_LIST_LEN
MenuIndexList   ds.b MAX_MENU_LIST
GUBuffer        ds.b 512   ; General Use - Must be at least 256+1 bytes for LFNs

RAMEndC:
    IF RAMEndC > $11F000
        FATAL "\aRAM C allocation is too large !"
    ENDIF

	ORG $11F000
FixBankBuffer   ds.b 4096   ; Only first half of fix bank is enough

RAMEndD:
    IF RAMEndD > $120000
        FATAL "\aRAM D allocation is too large !"
    ENDIF
