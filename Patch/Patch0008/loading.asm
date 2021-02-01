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

LoadingFinished:
    move.b  d0,REG_DIPSW
    move.b  #1,$10F6C3          ; Copied from original routine
    clr.b   IsLoading
    rts

LoadFile:
    IFDEF DEBUGBUILD
	jsr     DebugDispFileName
	ENDIF

    ; Copied from original routine
	moveq.l #0,d0
    move.b  $10F6C2,d0			; "FileTypeCode"
    lsl.b   #2,d0
    IF TARGET==1
    lea     $C0FD94,a0			; "JTFileLoaders"
    ELSEIF TARGET==2
    lea     $C0F60A,a0			; "JTFileLoaders"
    ELSEIF TARGET==3
    lea     $C0F752,a0			; "JTFileLoaders"
    ENDIF
    movea.l 0(a0,d0),a0
    jmp     (a0)
    
LoadPRGVectorTable:
    ; Copy everything from FirstPRGSector to the vector table at 0 except the VBL IRQ vector
    move.b  #0,REG_SWPROM
    move.l  $11006C,$10F6EE     ; VBLRoutine2,VBLVectorCopy(a5)
    movea.l #$110004,a0         ; "FirstPRGSector"
    movea.l #0,a1
    move.w  #104/2,d7
.copy1:
    move.w  (a0)+,(a1)+
    subq.w  #1,d7
    bne     .copy1
    move.l  (a0)+,d0            ; Discard, just inc a0
    move.l  (a1)+,d0            ; Just inc a1
    move.w  #1940/2,d7
.copy2:
    move.w  (a0)+,(a1)+
    subq.w  #1,d7
    bne     .copy2
    rts


CDCheckDone:
	btst   	#7,$10F656			; "CDValidFlag"
	bne     .valid

    IFDEF DEBUGBUILD
	lea     $111204,a1			; Debug: Dump memory starting from "CDSectorBuffer" and lock up
	bra     MemoryViewer
	ENDIF

	lea     StrMsgBoxInvalidGame,a0
	jsr     MessageBox
	clr.b   $10F6B6				; "CDLoadBusy"
	bclr    #0,$7656(a5)		; "CDValidFlag"
	IF TARGET==1
    jmp     $C0F55C				; Return to original code
	ELSEIF TARGET==2
	jmp     $C0EE4E				; Return to original code
	ELSEIF TARGET==3
	jmp     $C0EF90				; Return to original code
	ENDIF

.valid:
    ; Copied from original routine
	clr.b   $10F6B6				; "CDLoadBusy"
	bclr    #0,$7656(a5)		; "CDValidFlag"
    move.b  #0,REG_ENVIDEO      ; Disable video to avoid seeing fix glitch
	IF TARGET==1
    jmp     $C0F55C				; Return to original code
	ELSEIF TARGET==2
	jmp     $C0EE4E				; Return to original code
	ELSEIF TARGET==3
	jmp     $C0EF90				; Return to original code
	ENDIF


LoadFromCD:
    ; LoadFromCD jump patch
    movem.l d0/a0,-(sp)

    ; Copied from original routine
    move.b  #1,$76B6(a5)
    clr.b   $76B7(a5)
    ;Ignore PushCDOp
	move.w  #4,$7684(a5)
	move.b  #64,$76BA(a5)
	move.b  #64,$76BB(a5)
	clr.w   $76BC(a5)

	move.b  d0,REG_DIPSW
	st.b    IsLoading

    IFDEF DEBUGBUILD
    movem.l a1,-(sp)
    ; Set up palettes for debug text
    lea     IGMPalette,a0
    lea     PALETTES,a1
    jsr     CopyPalette

	jsr     DebugDispMSF
    movem.l (sp)+,a1
	ENDIF

    move.l  $10F6C8,d0          ; Requested MSF
    move.l  d0,MSFCounter

	move.w  $10F688,d0			; Retrieve requested sector count to load
	move.w  d0,CDSectorCount	; Make our own copy, just in case

    IFDEF DEBUGBUILD
	jsr		DebugDispCDSectors
	move.b  #1,REG_ENVIDEO
	move.b  #0,REG_DISBLSPR
	move.b  #0,REG_DISBLFIX
	ENDIF

    movem.l (sp)+,d0/a0
	rts

LoadGame:
    ; Select file with index in d0.b and start loading
    move.b  d0,MCUCmdParams     ; ii 00 00 00
    MCUCMD  MCU_CMD_SELECTGAME
    bcc     .notimeout
    jmp     DispErrorTimeout
.notimeout:
    jsr     MCURead4Words
    jsr     CheckACK
    bcc     .cmdok
    rts
.cmdok:
    ; Ok, start loading
	st.b    IsLoading

    move.b  SettingCountry,d0
	andi.b  #3,d0               ; Sanitize
	move.b  d0,BIOS_COUNTRY_CODE

    moveq.l #0,d0
	move.l  d0,CheatsBitmap
	move.b  d0,FlagSelectStart
	move.b  d0,VBLCheatActions
	move.b  d0,IsInIGM   
    move.b  d0,CustomBGLoaded
	move.b  FileCursor,LastFileCursor
	move.b  MenuShift,LastMenuShift
	move.b  LetterCursor,LastLetterCursor
    st.b    CursorsValid

	IF TARGET==1
	jsr     $C0F29A
    ELSEIF TARGET==2
    jsr     $C0EB96				; CheckCDValid
	ELSEIF TARGET==3
	jsr     $C0ECD2
	ENDIF
	btst   	#7,$10F656			; "CDValidFlag"
	beq     .invalid
	move.b  #$80,$10F6B9		; "GameStartState" Kickstart loading
.invalid:
    rts
