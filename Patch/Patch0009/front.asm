FrontIGMVBLInsert:
    jsr     $C0B9F6             ; Controller_0        ; Copied from original routine
    jsr     $C0D6E6             ; ProcessCDDACmds
    jsr     $C0CC8E             ; InitCDComm?
    jsr     IGMVBL
    jmp     $C0C9A4				; Return to original code


FrontCheatInsert:
    jsr     $C0D6E6             ; ProcessCDDACmds     ; Copied from original routine
    jsr     SystemIOCustom
    jmp     $C0D44A


DoCDDComm:
    ; This needs to be called when the CDD IRQ is triggered
    ; The CD drive inits the periodic data exchange

    move.b  #2,REG_CDDCTRL  ; HOCK low, bus input

    lea     CDDReadBuffer,a0
    moveq.l #9-1,d7         ; Read 9 words (#10 is an exception)
.readlp:
    jsr     WaitCDCKLow
    move.b  #3,REG_CDDCTRL  ; HOCK high, bus input
    andi.b  #15,d0
    move.b  d0,(a0)+
    jsr     WaitCDCKHigh
    move.b  #2,REG_CDDCTRL  ; HOCK low, bus input
    dbra    d7,.readlp

    jsr     WaitCDCKLow
    move.b  #3,REG_CDDCTRL  ; HOCK high, bus input
    andi.b  #15,d0
    move.b  d0,(a0)+
    jsr     WaitCDCKHigh

    lea     CDDReadBuffer,a0
    moveq.l #0,d0           ; Compute checksum
    move.l  #9-1,d7
.checksumlp:
    add.b   (a0)+,d0
    dbra    d7,.checksumlp
    addq.b  #5,d0
    not.b   d0
    andi.b  #15,d0
    cmp.b   (a0),d0
    bne     .checksumfail
    move.b  CDDReadBuffer,CDDStatus
.checksumfail:
    ; If status info checksum is wrong, don't update CDDStatus, send command anyways
    
    move.b  CDDCommand,d0
    move.b  d0,d2
    clr.b   CDDCommand
    jsr     SendCDDNibble

    moveq.l #10-2-1,d7      ; Zero parameters
.zerolp:
    moveq.l #0,d0
    jsr     SendCDDNibble
    dbra    d7,.zerolp

    move.b  d2,d0
    addi.b  #5,d0
    not.b   d0
    jsr     SendCDDNibble   ; Checksum
    rts


ToggleTray:
    ; See if CDD comm is still working with patch ! It must be
    ; if CDDCmdRDStatus1 == 5, tray is open
    ; Close: PushCDOp 1 = Send C 0 0 0 0 0 0 0 0 E
    ; Open: PushCDOp 0 = Send D 0 0 0 0 0 0 0 0 D
    move.b  #12,d0
    cmp.b   #5,CDDStatus
    beq     .closetray
    move.b  #13,d0
.closetray:
    move.b  d0,CDDCommand
    rts


SendCDDNibble:
    andi.b  #15,d0
    move.b  d0,REG_CDDOUTPUT
    move.b  #0,REG_CDDCTRL  ; HOCK low
    move.b  #2,REG_CDDCTRL  ; HOCK low
    bsr.w   WaitCDCKLow
    move.b  #1,REG_CDDCTRL  ; HOCK high
    move.b  #3,REG_CDDCTRL  ; HOCK low
    bsr.w   WaitCDCKHigh
    rts


WaitCDCKLow:
    move.l  #128,d1         ; Timeout
.poll:
    move.b  REG_CDDINPUT,d0
    btst    #4,d0
    beq     .ok
    dbra    d1,.poll
.ok:
    rts


WaitCDCKHigh:
    move.l  #128,d1         ; Timeout
.poll:
    move.b  REG_CDDINPUT,d0
    btst    #4,d0
    bne     .ok
    dbra    d1,.poll
.ok:
    rts
