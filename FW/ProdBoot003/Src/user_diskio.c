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

#include <string.h>
#include <stdio.h>
#include "main.h"
#include "ff_gen_drv.h"
#include "sd.h"

static volatile DSTATUS Stat = STA_NOINIT;

DSTATUS USER_initialize (BYTE pdrv);
DSTATUS USER_status (BYTE pdrv);
DRESULT USER_read (BYTE pdrv, BYTE *buff, DWORD sector, UINT count);
#if _USE_WRITE == 1
  DRESULT USER_write (BYTE pdrv, const BYTE *buff, DWORD sector, UINT count);  
#endif /* _USE_WRITE == 1 */
#if _USE_IOCTL == 1
  DRESULT USER_ioctl (BYTE pdrv, BYTE cmd, void *buff);
#endif /* _USE_IOCTL == 1 */

Diskio_drvTypeDef USER_Driver = {
	USER_initialize,
	USER_status,
	USER_read,
	#if  _USE_WRITE
		USER_write,
	#endif
	#if  _USE_IOCTL == 1
		USER_ioctl,
	#endif
};

DSTATUS USER_initialize (BYTE pdrv) {
    Stat = 0;
    SD_Init();
    return Stat;
}

DSTATUS USER_status (BYTE pdrv) {
    Stat = 0;
    return Stat;
}

DRESULT USER_read (
	BYTE pdrv,      // Physical drive number to identify the drive
	BYTE *buff,     // Data buffer to store read data
	DWORD sector,   // Sector address in LBA
	UINT count      // Number of sectors to read
) {
	uint32_t retries;
	uint8_t reply;

	if (card_type != SD_HIGH_CAPACITY_SD_CARD)
		sector <<= 9;

	uint32_t buff_local = (uint32_t)buff;

	if (count == 1) {
		// Read single block
		reply = SD_Cmd(17, sector);
		if (reply != 0x00) {
			return RES_ERROR;
		}

		// Wait for data token
		retries = 300000;		// See SD specs 5.1.9.2 - 100ms max
		while (1) {
			reply = SPI_Send(0xFF);
			if (reply == 0xFE) break;
			if (!(retries--)) {
				return RES_ERROR;
			}
			asm("nop");
			asm("nop");
			asm("nop");
			asm("nop");
		}

		// Software copy
		for (uint32_t c = 0; c < 512; c++) {
			LL_SPI_TransmitData8(SPI2, 0xFF);
			while (SPI2->SR & SPI_SR_BSY);
			((uint8_t*)buff_local)[c] = LL_SPI_ReceiveData8(SPI2);
		}

		// Discard CRC
		SPI_Send(0xFF);
		SPI_Send(0xFF);
	} else {
		// Read multiple blocks
		reply = SD_Cmd(18, sector);
		if (reply != 0x00) {
			return RES_ERROR;
		}

		for (uint32_t c = 0; c < count; c++) {
			// Wait for data token
			retries = 300000;		// See SD specs 5.1.9.2 - 100ms max
			while (1) {
				reply = SPI_Send(0xFF);
				if (reply == 0xFE) break;
				if (!(retries--)) {
					return RES_ERROR;
				}
				asm("nop");
				asm("nop");
				asm("nop");
				asm("nop");
			}

			for (uint32_t c = 0; c < 512; c++) {
				LL_SPI_TransmitData8(SPI2, 0xFF);
				while (SPI2->SR & SPI_SR_BSY);
				((uint8_t*)buff_local)[c] = LL_SPI_ReceiveData8(SPI2);
			}

			// Discard CRC
			SPI_Send(0xFF);
			SPI_Send(0xFF);

			buff_local += 512;
		}

		retries = 10;
		while (1) {
			reply = SD_Cmd(12, 0);
			if (reply == 0x00) break;
			if (!(retries--)) {
				return RES_ERROR;
			}
		}

		// Wait for FF
		retries = 300000;
		while (1) {
			reply = SPI_Send(0xFF);
			if (reply == 0xFF) break;
			if (!(retries--)) {
				return RES_ERROR;
			}
			asm("nop");
			asm("nop");
			asm("nop");
			asm("nop");
		}
	}

	SD_CS_HIGH
	SPI_Send(0xFF);		// See SD specs 5.1.8

	return RES_OK;
}

#if _USE_IOCTL == 1
DRESULT USER_ioctl (
	BYTE pdrv,      // Physical drive nmuber
	BYTE cmd,       // Control code
	void *buff      // Buffer to send/receive control data
) {
    return RES_OK;
}
#endif

#if _USE_LFN == 1
WCHAR ff_convert (WCHAR wch, UINT dir) {
	// Normal ASCII char ?
	if (wch < 0x80)
		return wch;

	// Other chars are unsupported
	return 0;
}

WCHAR ff_wtoupper (WCHAR wch) {
	// Normal ASCII char ?
	if (wch < 0x80) {
		if (wch >= 'a' && wch <= 'z')
			wch &= ~0x20;
		return wch;
	}

	// Other chars are unsupported
	return 0;
}
#endif
