/*
 * Copyright (C) 2020 Sean Gonsalves
 *
 * This file is part of Neo CD SD Loader.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

#include "xmodem.h"
#include "usbd_cdc_if.h"
#include "cpld_comm.h"
#include "util.h"

xstate_t xstate = STATE_IDLE;
uint32_t xmodem_retry = 0;
uint32_t xaddr_program = 0, xaddr_buffer = 0;
memtype_t memory_type = MEMTYPE_FLASH;

void HandleXModem(const uint8_t byte) {
	// XMODEM transfer state handling
	if (xstate == STATE_XMODEM_RX_START) {
		if (byte == 1) {	// SOH
			xstate = STATE_XMODEM_RX_RUN;
		} else
			xstate = STATE_IDLE;
	} else if ((xstate == STATE_XMODEM_EOT) && (byte == 4)) {	// EOT
		CDCPuts(6);	// ACK
		LL_mDelay(500);
		CDCPrint("Done !");
		xstate = STATE_IDLE;
	} else if (xstate == STATE_XMODEM_TX_START) {
		if (byte == 21) {	// NACK
			xstate = STATE_XMODEM_TX_RUN;
		} else
			xstate = STATE_IDLE;
	} else if (xstate == STATE_XMODEM_TX_WAIT) {
		if (byte == 6)	// ACK
			xaddr_program += 128;
		else
			xmodem_retry++;
		xstate = STATE_XMODEM_TX_RUN;
	}
}

void XModemRX(const uint8_t byte) {
	if (xmodem_retry >= 10) {
		CDCPuts(4);	// EOT
		xstate = STATE_IDLE;
		CDCPrint("XMODEM retry fail");
	}

	buffer_temp[xaddr_buffer] = byte;
	xaddr_buffer++;

	if (xaddr_buffer == 132) {	// 3+128+1
		xaddr_buffer = 0;

		// Check XMODEM packet number
		if (buffer_temp[1] == (((xaddr_program >> 7) + 1) & 0xFF)) {
			// Check XMODEM checksum
			uint32_t checksum = 0;
			for (uint32_t c = 0; c < 128; c++)
				checksum += buffer_temp[3+c];

			if ((checksum & 0xFF) == buffer_temp[3+128]) {
				xmodem_retry = 0;

				for (uint32_t c = 0; c < 64; c++) {
					uint16_t data = (buffer_temp[4+c*2]<<8) + buffer_temp[3+c*2];
					CmdFlash(FLASH_PROGRAM);	// Disable write protection
					WriteFlash((xaddr_program>>1) + c, data);	// Word program
				}
				SetMCUBusInput();

				xaddr_program += 128;
				CDCPuts(6);		// ACK
			} else {
				xmodem_retry++;
				CDCPuts(21);	// NACK
			}
		} else {
			xmodem_retry++;
			CDCPuts(21);	// NACK
		}

		if (xaddr_program == 0x80000) {	// 512kBytes
			xstate = STATE_XMODEM_EOT;
		}
	}
}

void XModemTX(const uint8_t byte) {
	if (xmodem_retry >= 10) {
		CDCPuts(4);	// EOT
		xstate = STATE_IDLE;
		CDCPrint("XMODEM retry fail");
	}
	if (xaddr_program != 0x80000) {	// 512kBytes
		buffer_temp[0] = 1;	// SOH
		buffer_temp[1] = (xaddr_program >> 7) + 1;	// Packet #
		buffer_temp[2] = 255 - buffer_temp[1];		// Inverted packet #
		uint32_t checksum = 0;
		// 128 bytes per packet = 64 words
		for (uint32_t c = 0; c < 64; c++) {
			uint16_t data = ReadMem(c + (xaddr_program >> 1), memory_type);
			buffer_temp[3+c*2] = data & 0xFF;
			buffer_temp[4+c*2] = data >> 8;
			checksum += ((data >> 8) + (data & 0xFF));
		}
		buffer_temp[128+3] = checksum;
		xmodem_retry = 0;
		CDC_Transmit_FS((uint8_t*)&buffer_temp, 3+128+1);
		LL_mDelay(2);
		xstate = STATE_XMODEM_TX_WAIT;
	} else {
		CDCPuts(4);	// EOT
		xstate = STATE_IDLE;
		LL_mDelay(500);
		CDCPrint("Done !");
	}
}

void XModemInit(const xstate_t state) {
	SetMode(MODE_MCU);
	xaddr_program = 0;
	xaddr_buffer = 0;
	xmodem_retry = 0;
	xstate = state;
}
