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

InitLoad:
    jsr     LoadFromCD
    move.l  #CDSectorBuffer,SectorLoadBuffer(a5)
    move.l  #2048,SectorLoadSize(a5)
    rts

LoadPRGSectorsPatch:
	jsr     InitLoad
    move.l  SectorReqDest(a5),d0
    bne.s   .notfirst

    move.l  #FirstPRGSector,SectorLoadDest(a5)
    jsr     LoadPRGSectorFromSD
    clr.l   $7732(a5)
    move.l  #2048,d0                    ; Second sector

.notfirst:
    move.l  d0,SectorLoadDest(a5)

.loadPRGsectors:
    jsr     LoadPRGSectorFromSD
    jsr     UpdateLoadAnim
    tst.w   SectorCounter(a5)
    bne.s   .loadPRGsectors

	; Detect and auto-patch SSRPG's EXT_SYS.PRG
    cmp.l   #$132000,SectorReqDest(a5)
	bne     .notssrpg
	cmp.l   #$4E454F47,$132000	; Check for "NEOG" at $132000
	bne     .notssrpg
	; Pretty sure we just loaded EXT_SYS.PRG at this point: patch it
	; Thanks Justin !
	move.l  #$4E754E75,$13201A	; rts rts
	move.l  #$4E714EF9,$13201E	; nop jmp.l
	move.l  #$00C00552,$132022  ; $C00552 (BIOSF_LOADFILE)
	move.l  #$4EF900C0,$132026  ; jmp.l $C00552 (BIOSF_LOADFILE_NOANIM)
	move.w  #$0564,$13202A

.notssrpg:
    jmp     LoadPRGVectorTable


LoadSPRSectorsPatch:
	jsr     InitLoad

.loadSPRsectors:
    move.l  SectorLoadDest(a5),d0
    cmpi.l  #$100000,d0
    blo     .noteob                     ; Reached end of bank ?
    move.l  #0,SectorLoadDest(a5)       ; Go to next bank
    move.b  FirstLoadBank(a5),d0
    addq.b  #1,d0
    move.b  d0,FirstLoadBank(a5)
    move.b  d0,BankCounter(a5)
    move.b  d0,REG_SPRBANK
.noteob:
    jsr     LoadSPRSectorFromSD
    jsr     UpdateLoadAnim
    tst.w   SectorCounter(a5)
    bne.s   .loadSPRsectors             ; Loaded all sectors ?

    move.b  d0,REG_UPUNMAPSPR
    move.b  #0,REG_DISBLSPR
    rts
    
    
LoadPCMSectorsPatch:
	jsr     InitLoad
    
.loadPCMsectors:
    jsr     LoadPCMSectorFromSD
    jsr     UpdateLoadAnim
    tst.w   SectorCounter(a5)
    bne.s   .loadPCMsectors

    move.b  d0,REG_UPUNMAPPCM
    rts
    
    
UpdateLoadAnim:
    movem.l d0-a6,-(sp)
    movea.l ProgressBarCodePtr,a0
    jsr     (a0)
    tst.b   SettingLoadAnim
    beq     .fast
    move.b  LoadAnimSlowdown,d0
    addq.b  #1,d0
    move.b  d0,LoadAnimSlowdown
    andi.b  #7,d0
    bne     .skip
.fast:
    jsr     DrawProgressAnimation
.skip:
    movem.l (sp)+,d0-a6
    rts


LoadingFinished:
    move.b  d0,REG_DIPSW
    move.b  #1,$10F6C3          ; Copied from original routine
    clr.b   IsLoading           ; Added
    rts


LoadFile:
    IFDEF DEBUGBUILD
	jsr     DebugDispFileName
	ENDIF

    ; Copied from original routine
    ; TODO: Is this still needed ?
	moveq.l #0,d0
    move.b  $10F6C2,d0			; "FileTypeCode"
    lsl.b   #2,d0
    lea     JTFileLoaders,a0
    movea.l 0(a0,d0),a0
    jmp     (a0)
    

LoadPRGVectorTable:
    ; Copy everything from FirstPRGSector to the vector table at 0 except the VBL IRQ vector
    move.b  #0,REG_SWPROM
    move.l  $11006C,$10F6EE     ; VBLRoutine2,VBLVectorCopy(a5)
    movea.l #FirstPRGSector,a0
    movea.l #0,a1
    move.w  #104/2,d7
.copy1:
    move.w  (a0)+,(a1)+
    subq.w  #1,d7
    bne     .copy1
    move.l  (a0)+,d0            ; Just inc a0
    move.l  (a1)+,d0            ; Just inc a1
    move.w  #1940/2,d7
.copy2:
    move.w  (a0)+,(a1)+
    subq.w  #1,d7
    bne     .copy2
    rts


CDCheckDone:
	btst   	#7,CDValidFlag
	bne     .valid

    IFDEF DEBUGBUILD
	lea     $111204,a1			; Debug: Dump memory starting from "CDSectorBuffer" and lock up
	bra     MemoryViewer
	ENDIF

	lea     StrMsgBoxInvalidGame,a0
	jsr     MessageBox
	clr.b   CDLoadBusy
	bclr    #0,CDValidFlag
    jmp     CDCheckDoneEnd      ; Return to original code

.valid:
    ; Copied from original routine
	clr.b   CDLoadBusy
	bclr    #0,CDValidFlag
    move.b  #0,REG_ENVIDEO      ; Disable video to avoid seeing fix glitch
    jmp     CDCheckDoneEnd      ; Return to original code



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
    lea     IGMPalettes,a0
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
    move.b  d0,MCUCmdParams
    MCUCMD  MCU_CMD_SELECTGAME
    bcc     .notimeout
    jmp     DispErrorTimeout
.notimeout:
    jsr     MCURead4Words
    jsr     CheckACK
    bcs     .invalid
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

    jsr     CheckCDValid

	btst   	#7,CDValidFlag
	beq     .invalid
	move.b  #$80,$10F6B9		; "GameStartState" Kickstart loading
.invalid:
    rts
