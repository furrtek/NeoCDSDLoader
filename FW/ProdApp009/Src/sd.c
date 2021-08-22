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

#include "main.h"
#include "util.h"
#include "sd.h"

static const uint8_t crc7_syndrome_table[256] = {
	0x00, 0x09, 0x12, 0x1b, 0x24, 0x2d, 0x36, 0x3f,
	0x48, 0x41, 0x5a, 0x53, 0x6c, 0x65, 0x7e, 0x77,
	0x19, 0x10, 0x0b, 0x02, 0x3d, 0x34, 0x2f, 0x26,
	0x51, 0x58, 0x43, 0x4a, 0x75, 0x7c, 0x67, 0x6e,
	0x32, 0x3b, 0x20, 0x29, 0x16, 0x1f, 0x04, 0x0d,
	0x7a, 0x73, 0x68, 0x61, 0x5e, 0x57, 0x4c, 0x45,
	0x2b, 0x22, 0x39, 0x30, 0x0f, 0x06, 0x1d, 0x14,
	0x63, 0x6a, 0x71, 0x78, 0x47, 0x4e, 0x55, 0x5c,
	0x64, 0x6d, 0x76, 0x7f, 0x40, 0x49, 0x52, 0x5b,
	0x2c, 0x25, 0x3e, 0x37, 0x08, 0x01, 0x1a, 0x13,
	0x7d, 0x74, 0x6f, 0x66, 0x59, 0x50, 0x4b, 0x42,
	0x35, 0x3c, 0x27, 0x2e, 0x11, 0x18, 0x03, 0x0a,
	0x56, 0x5f, 0x44, 0x4d, 0x72, 0x7b, 0x60, 0x69,
	0x1e, 0x17, 0x0c, 0x05, 0x3a, 0x33, 0x28, 0x21,
	0x4f, 0x46, 0x5d, 0x54, 0x6b, 0x62, 0x79, 0x70,
	0x07, 0x0e, 0x15, 0x1c, 0x23, 0x2a, 0x31, 0x38,
	0x41, 0x48, 0x53, 0x5a, 0x65, 0x6c, 0x77, 0x7e,
	0x09, 0x00, 0x1b, 0x12, 0x2d, 0x24, 0x3f, 0x36,
	0x58, 0x51, 0x4a, 0x43, 0x7c, 0x75, 0x6e, 0x67,
	0x10, 0x19, 0x02, 0x0b, 0x34, 0x3d, 0x26, 0x2f,
	0x73, 0x7a, 0x61, 0x68, 0x57, 0x5e, 0x45, 0x4c,
	0x3b, 0x32, 0x29, 0x20, 0x1f, 0x16, 0x0d, 0x04,
	0x6a, 0x63, 0x78, 0x71, 0x4e, 0x47, 0x5c, 0x55,
	0x22, 0x2b, 0x30, 0x39, 0x06, 0x0f, 0x14, 0x1d,
	0x25, 0x2c, 0x37, 0x3e, 0x01, 0x08, 0x13, 0x1a,
	0x6d, 0x64, 0x7f, 0x76, 0x49, 0x40, 0x5b, 0x52,
	0x3c, 0x35, 0x2e, 0x27, 0x18, 0x11, 0x0a, 0x03,
	0x74, 0x7d, 0x66, 0x6f, 0x50, 0x59, 0x42, 0x4b,
	0x17, 0x1e, 0x05, 0x0c, 0x33, 0x3a, 0x21, 0x28,
	0x5f, 0x56, 0x4d, 0x44, 0x7b, 0x72, 0x69, 0x60,
	0x0e, 0x07, 0x1c, 0x15, 0x2a, 0x23, 0x38, 0x31,
	0x46, 0x4f, 0x54, 0x5d, 0x62, 0x6b, 0x70, 0x79
};

uint8_t SPI_Send(uint8_t byte) {
    while (!LL_SPI_IsActiveFlag_TXE(SPI2)) {};
    LL_SPI_TransmitData8(SPI2, byte);
    while (!LL_SPI_IsActiveFlag_RXNE(SPI2)) {};
    return (uint8_t)LL_SPI_ReceiveData8(SPI2);
}

// Returns 1 on timeout, 0 otherwise
uint8_t SD_WaitNotBusy(const uint32_t msec) {
	SPI_Send(0xFF);
	for (uint32_t busy_timeout = 0; busy_timeout < msec; busy_timeout++) {
		if (SPI_Send(0xFF) == 0xFF)
			return 0;
		LL_mDelay(1);
	}
	return 1;
}

// Returns -1 on error, first byte of reply otherwise
uint8_t SD_Cmd(uint8_t command, uint32_t param) {
	uint8_t crc = 0;
	uint8_t buffer[5];
	uint8_t reply;
	uint32_t busy_timeout;

	SPI_Send(0xFF);
	SD_CS_LOW

	if (command != 12) {
		// Wait for FF
		SPI_Send(0xFF);
		for (uint32_t busy_timeout = 300; busy_timeout > 0; busy_timeout--) {
			if (SPI_Send(0xFF) == 0xFF)
				break;
			if (!busy_timeout)
				return -1;
			LL_mDelay(1);
		}
	}

	buffer[0] = command | 0x40;		// Command code
	buffer[1] = param >> 24;
	buffer[2] = param >> 16;
	buffer[3] = param >> 8;
	buffer[4] = param;

	for (uint32_t c = 0; c < 5; c++) {
		SPI_Send(buffer[c]);
		crc = crc7_syndrome_table[(crc << 1) ^ buffer[c]];
	}

	SPI_Send((crc << 1) | 1);

	if (command == 12)
		SPI_Send(0xFF);

	for (busy_timeout = 20; busy_timeout > 0; busy_timeout--) {
		reply = SPI_Send(0xFF);
		if (!(reply & 0x80))
			break;
	}
	if (!busy_timeout) {
		SD_CS_HIGH
		SPI_Send(0xFF);
		return -1;
	}

	if (command == 12) {
		// Wait for ready
		uint32_t retries = 20000;
		while (1) {
			if (SPI_Send(0xFF) == 0xFF) break;
			if (!(retries--)) return -1;	// Failed
		}
	}

	if ((command == 17) || (command == 18) || (command == 24)) {
		return reply;
	}

	SD_CS_HIGH
	SPI_Send(0xFF);
	return reply;
}

// Returns 0 on success, error code otherwise
uint32_t SD_Init() {
	uint32_t retries, c;

	// Low speed
	// SYSCLK=96MHz -> 375kHz
	LL_SPI_SetBaudRatePrescaler(SPI2, LL_SPI_BAUDRATEPRESCALER_DIV256);

	// DOUT high, CS high, and a bunch of CLKs
	SD_CS_HIGH
	for (c = 0; c < 100; c++)
		SPI_Send(0xFF);

	SD_CS_LOW

	// Send CMD0, expect 0x01 reply, 2s timeout
	retries = 1000;
	while (1) {
		if (SD_Cmd(0, 0x00000000) == 0x01) break;	// Idle state ok
		if (!(retries--)) return 1;		// Failed
		LL_mDelay(2);
	}
	SPI_Send(0xFF);		// SD PLSS v6.00 page 76
#ifdef STANDALONE
	CDCPrint("CMD0 ok");
#endif

	// Send CMD8 param 000001AA
	// If $01 reply: card is SDV2, must then reply 000001AA back
	// If no reply: card is SDV1 or MMC
	if (SD_Cmd(8, 0x000001AA) & 4) {	// Illegal command bit
		card_type = SD_STD_CAPACITY_SD_CARD_V1_0;
	} else {
		SPI_Send(0xFF);		// Should be 00
		SPI_Send(0xFF);		// Should be 00
		SPI_Send(0xFF);		// Should be 01
		SPI_Send(0xFF);		// Should be AA
		card_type = SD_STD_CAPACITY_SD_CARD_V2_0;
	}
	SPI_Send(0xFF);		// SD PLSS v6.00 page 76
#ifdef STANDALONE
	DebugPrint("CMD8 ok, card_type", card_type);
#endif

	retries = 2000;	// This CAN be long, see SD specs 3.4.1, thanks ikari_01 !
	while (1) {
		// Send CMD55
		uint32_t r = SD_Cmd(55, 0x00000000);
		SPI_Send(0xFF);		// SD PLSS v6.00 page 76
#ifdef STANDALONE
		DebugPrint("CMD55", r);
#endif

		// Send ACMD41
		r = SD_Cmd(41, card_type == SD_STD_CAPACITY_SD_CARD_V2_0 ? 0x40000000 : 0);
		// Expect $00 reply, 10 max retries
#ifdef STANDALONE
		DebugPrint("ACMD41", r);
#endif
		if (r == 0x00) break;	// Init ok
		if (!(retries--)) return 2;		// Failed
		LL_mDelay(1);
	}
	SPI_Send(0xFF);		// Ignore R3 response to ACMD41
	SPI_Send(0xFF);
	SPI_Send(0xFF);
	SPI_Send(0xFF);
	SPI_Send(0xFF);		// SD PLSS v6.00 page 76

	if (card_type == SD_STD_CAPACITY_SD_CARD_V2_0) {
		// Read OCR register
		uint32_t r = SD_Cmd(58, 0x00000000);	// CMD58
		uint32_t r3 = 0;
		if (r == 0x00) {
			// Get R3 response
			r3  = SPI_Send(0xFF) << 24;
			r3 |= SPI_Send(0xFF) << 16;
			r3 |= SPI_Send(0xFF) << 8;
			r3 |= SPI_Send(0xFF);
		} else {
			return 3; // Bad CMD58 response
		}
		if (r3 & (1<<30))
			card_type = SD_HIGH_CAPACITY_SD_CARD; // SDHC or SDXC
		SPI_Send(0xFF);		// SD PLSS v6.00 page 76
	}

	// For SDv2, SDv1, MMC must set block size. For SDHC/SDXC it is fixed to 512.
	if ((card_type == SD_STD_CAPACITY_SD_CARD_V1_0) ||
			(card_type == SD_STD_CAPACITY_SD_CARD_V2_0) ||
			(card_type == SD_MULTIMEDIA_CARD)) {
		// CMD16: block size = 512 bytes
		if (SD_Cmd(16, 0x00000200) != 0x00)
			return 5; // Set block size failed
	}

	// Full speed !
	// SYSCLK=96MHz -> 24MHz
	LL_SPI_SetBaudRatePrescaler(SPI2, LL_SPI_BAUDRATEPRESCALER_DIV4);

	SPI_Send(0xFF);
	SD_CS_HIGH

#ifdef STANDALONE
	DebugPrint("SD init success, card_type", card_type);
#endif

	return 0;	// Success
}
