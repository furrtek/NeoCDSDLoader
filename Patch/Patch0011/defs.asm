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

; Hard DIPs:
DIPSW_SETTINGS  equ 0   ; Settings mode
DIPSW_CHUTES    equ 1   ; Number of coin chutes
DIPSW_CTRL      equ 2   ; Mahjong controller enable
DIPSW_ID0       equ 3   ; Multiplayer ID
DIPSW_ID1       equ 4   ; Multiplayer ID
DIPSW_MULTI     equ 5   ; Multiplayer enable
DIPSW_FREEPLAY  equ 6   ; Freeplay enable
DIPSW_FREEZE    equ 7   ; Freeze frame

; Header values
HEADER_NGH        equ $108      ; Game's NGH
HEADER_SDIPS_JP   equ $116      ; JP soft DIPs layout
HEADER_SDIPS_US   equ $11A      ; US soft DIPs layout
HEADER_SDIPS_EU   equ $11E      ; EU soft DIPs layout

; VRAM zones:
SCB1            equ $0000   ; Sprite tilemaps
FIXMAP          equ $7000   ; Fix tilemap
SCB2            equ $8000   ; Sprite shrink values
SCB3            equ $8200   ; Sprite Y positions, heights and flags
SCB4            equ $8400   ; Sprite X positions

; Basic colors:
BLACK           equ $8000
MIDRED          equ $4700
RED             equ $4F00
MIDGREEN        equ $2070
GREEN           equ $20F0
MIDBLUE         equ $1007
BLUE            equ $100F
MIDYELLOW       equ $6770
YELLOW          equ $6FF0
MIDMAGENTA      equ $5707
MAGENTA         equ $5F0F
MIDCYAN         equ $3077
CYAN            equ $30FF
ORANGE          equ $6F70
MIDGREY         equ $7777
WHITE           equ $7FFF

; Memory zones:
RAMSTART        equ $100000   ; 68k work RAM
PALETTES        equ $400000   ; Palette RAM
BACKDROP        equ PALETTES+(16*2*256)-2
MEMCARD         equ $800000   ; Memory card
SYSROM          equ $C00000   ; System ROM

; Registers:
REG_P1CNT       equ $300000
REG_DIPSW       equ $300001   ; Dipswitches/Watchdog
REG_SOUND       equ $320000   ; Z80 I/O
REG_STATUS_A    equ $320001
REG_P2CNT       equ $340000
REG_STATUS_B    equ $380000
REG_POUTPUT     equ $380001   ; Joypad port outputs
REG_CRDBANK     equ $380011
REG_SLOT        equ $380021   ; Slot select

REG_NOSHADOW    equ $3A0001   ; Video output normal/dark
REG_SHADOW      equ $3A0011
REG_SWPROM      equ $3A0013
REG_CRDNORMAL   equ $3A0019
REG_BRDFIX      equ $3A000B   ; Use embedded fix tileset
REG_CRTFIX      equ $3A001B   ; Use game fix tileset
REG_PALBANK1    equ $3A000F   ; Use palette bank 1
REG_PALBANK0    equ $3A001F   ; Use palette bank 0 (default)

REG_VRAMADDR    equ $3C0000
REG_VRAMRW      equ $3C0002
REG_VRAMMOD     equ $3C0004
REG_LSPCMODE    equ $3C0006
REG_TIMERHIGH   equ $3C0008
REG_TIMERLOW    equ $3C000A
REG_IRQACK      equ $3C000C
REG_TIMERSTOP   equ $3C000E

REG_TRANSAREA   equ $FF0105
REG_DISBLSPR	equ $FF0111
REG_DISBLFIX	equ $FF0115
REG_ENVIDEO		equ $FF0119
REG_CDCONFIG    equ $FF011C
REG_UPMAPSPR    equ $FF0121
REG_UPMAPPCM    equ $FF0123
REG_UPMAPZ80    equ $FF0127
REG_UPMAPFIX    equ $FF0129
REG_UPUNMAPSPR  equ $FF0141
REG_UPUNMAPPCM  equ $FF0143
REG_UPUNMAPZ80  equ $FF0147
REG_UPUNMAPFIX  equ $FF0149
REG_CDDINPUT    equ $FF0161
REG_CDDOUTPUT   equ $FF0163
REG_CDDCTRL     equ $FF0165
REG_UPLOAD_EN   equ $FF016F
REG_CDRST       equ $FF0181
REG_Z80RST      equ $FF0183
REG_SPRBANK     equ $FF01A1
REG_PCMBANK     equ $FF01A3

; System ROM calls:
SYS_INT1          equ $C00438
SYS_RETURN        equ $C00444
SYS_IO            equ $C0044A
SYS_CREDIT_CHECK  equ $C00450
SYS_CREDIT_DOWN   equ $C00456
SYS_READ_CALENDAR equ $C0045C   ; MVS only
SYS_CARD          equ $C00468
SYS_CARD_ERROR    equ $C0046E
SYS_HOWTOPLAY     equ $C00474   ; MVS only
SYS_FIX_CLEAR     equ $C004C2
SYS_LSP_1ST       equ $C004C8   ; Clear sprites
SYS_MESS_OUT      equ $C004CE
SYS_CDPLAYER      equ $C0055E

; RAM locations:
BIOS_SYSTEM_MODE  equ $10FD80
BIOS_MVS_FLAG     equ $10FD82
BIOS_COUNTRY_CODE equ $10FD83
BIOS_GAME_DIP     equ $10FD84   ; Start of soft DIPs settings (up to $10FD93)

; Set by SYS_IO:
BIOS_P1STATUS   equ $10FD94
BIOS_P1PREVIOUS equ $10FD95
BIOS_P1CURRENT  equ $10FD96
BIOS_P1CHANGE   equ $10FD97
BIOS_P1REPEAT   equ $10FD98
BIOS_P1TIMER    equ $10FD99

BIOS_P2STATUS   equ $10FD9A
BIOS_P2PREVIOUS equ $10FD9B
BIOS_P2CURRENT  equ $10FD9C
BIOS_P2CHANGE   equ $10FD9D
BIOS_P2REPEAT   equ $10FD9E
BIOS_P2TIMER    equ $10FD99

BIOS_STATCURNT    equ $10FDAC
BIOS_STATCHANGE   equ $10FDAD
BIOS_USER_REQUEST equ $10FDAE
BIOS_USER_MODE    equ $10FDAF
BIOS_START_FLAG   equ $10FDB4
BIOS_MESS_POINT   equ $10FDBE
BIOS_MESS_BUSY    equ $10FDC2

; Memory card:
BIOS_CRDF       equ $10FDC4   ; Byte: function to perform when calling BIOSF_CRDACCESS
BIOS_CRDRESULT  equ $10FDC6   ; Byte: 00 on success, else 80+ and encodes the error
BIOS_CRDPTR     equ $10FDC8   ; Longword: pointer to read from/write to
BIOS_CRDSIZE    equ $10FDCC   ; Word: how much data to read/write from/to card
BIOS_CRDNGH     equ $10FDCE   ; Word: usually game NGH. Unique identifier for the game that owns the save file
BIOS_CRDFILE    equ $10FDD0   ; Word: each NGH has up to 16 save files associated with

; Calendar, MVS only (in BCD):
BIOS_YEAR       equ $10FDD2   ; Last 2 digits of year
BIOS_MONTH      equ $10FDD3
BIOS_DAY        equ $10FDD4
BIOS_WEEKDAY    equ $10FDD5   ; Sunday = 0, Monday = 1 ... Saturday = 6
BIOS_HOUR       equ $10FDD6   ; 24 hour time
BIOS_MINUTE     equ $10FDD7
BIOS_SECOND     equ $10FDD8

BIOS_SELECT_TIMER equ $10FDDA ; Byte: game start countdown
BIOS_DEVMODE      equ $10FE80 ; Byte: non-zero for developer mode

; Upload system ROM call:
BIOS_UPDEST     equ $10FEF4   ; Longword
BIOS_UPSRC      equ $10FEF8   ; Longword
BIOS_UPSIZE     equ $10FEFC   ; Longword
BIOS_UPZONE     equ $10FEDA   ; Byte: zone (0=PRG, 1=FIX, 2=SPR, 3=Z80, 4=PCM, 5=PAT)
BIOS_UPBANK     equ $10FEDB   ; Byte: bank

SOUND_STOP      equ $D00046

; Inputs:
CNT_UP	        equ 0
CNT_DOWN		equ 1
CNT_LEFT		equ 2
CNT_RIGHT		equ 3
CNT_A	        equ 4
CNT_B	        equ 5
CNT_C	        equ 6
CNT_D	        equ 7
CNT_START1      equ 0
CNT_SELECT1     equ 1
CNT_START2      equ 2
CNT_SELECT2     equ 3
