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
#include "util.h"
#include "ff_gen_drv.h"
#include "sd.h"

static volatile DSTATUS Stat = STA_NOINIT;

DSTATUS USER_initialize (BYTE pdrv);
DSTATUS USER_status (BYTE pdrv);
DRESULT USER_read (BYTE pdrv, BYTE *buff, DWORD sector, UINT count);
#if _USE_WRITE == 1
  DRESULT USER_write (BYTE pdrv, const BYTE *buff, DWORD sector, UINT count);  
#endif
#if _USE_IOCTL == 1
  DRESULT USER_ioctl (BYTE pdrv, BYTE cmd, void *buff);
#endif

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

DSTATUS USER_initialize(BYTE pdrv) {
    Stat = 0;
    SD_Init();
    return Stat;
}

DSTATUS USER_status(BYTE pdrv) {
    Stat = 0;
    return Stat;
}

DRESULT USER_read(
	BYTE pdrv,      // Physical drive number
	BYTE *buff,     // Read data buffer
	DWORD sector,   // Sector address (LBA)
	UINT count      // Number of sectors to read (1..128)
) {
	uint32_t retries;
	uint8_t reply;

	if (card_type != SD_HIGH_CAPACITY_SD_CARD)
		sector <<= 9;

	uint32_t buff_local = (uint32_t)buff;

	if (count == 1) {
		// Read single block
		reply = SD_Cmd(17, sector);
		if (reply)
			return RES_ERROR;

		// Wait for data token
		retries = 300000;		// See SD specs 5.1.9.2 - 100ms max
		while (1) {
			reply = SPI_Send(0xFF);
			if (reply == 0xFE) break;
			if (!(retries--)) {
#ifdef STANDALONE
				DebugPrint("USER_read token", reply);
#endif
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
		if (reply)
			return RES_ERROR;

		for (uint32_t c = 0; c < count; c++) {
			// Wait for data token
			retries = 300000;		// See SD specs 5.1.9.2 - 100ms max
			while (1) {
				reply = SPI_Send(0xFF);
				if (reply == 0xFE) break;
				if (!(retries--)) {
#ifdef STANDALONE
					DebugPrint("USER_read token", reply);
#endif
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

#if 0
			// Old DMA copy code, not much faster and sometimes glitchy
			// SPI2 to memory, no interrupts needed
			LL_SPI_Disable(SPI2);

			// RX stream
			LL_DMA_DisableStream(DMA1, LL_DMA_STREAM_3);
			// Get the DMA Stream Instance
			DMAResetRegisters((DMA_Stream_TypeDef *)(__LL_DMA_GET_STREAM_INSTANCE(DMA1, LL_DMA_STREAM_3)));
			// Reset Channel register field for DMAx Stream
			LL_DMA_SetChannelSelection(DMA1, LL_DMA_STREAM_3, LL_DMA_CHANNEL_0);
			// Reset the Stream3 pending flags
			DMA1->LIFCR = 0x0F400000U;

			LL_DMA_ConfigTransfer(DMA1, LL_DMA_STREAM_3, LL_DMA_DIRECTION_PERIPH_TO_MEMORY |
						LL_DMA_PRIORITY_LOW | LL_DMA_MODE_NORMAL |
						LL_DMA_PERIPH_NOINCREMENT | LL_DMA_MEMORY_INCREMENT |
						LL_DMA_PDATAALIGN_BYTE | LL_DMA_PDATAALIGN_BYTE);
			LL_DMA_ConfigAddresses(DMA1, LL_DMA_STREAM_3, LL_SPI_DMA_GetRegAddr(SPI2), buff_local,
						 LL_DMA_GetDataTransferDirection(DMA1, LL_DMA_STREAM_3));
			LL_DMA_SetChannelSelection(DMA1, LL_DMA_STREAM_3, LL_DMA_CHANNEL_0);
			LL_DMA_SetDataLength(DMA1, LL_DMA_STREAM_3, 512);
			LL_DMA_EnableStream(DMA1, LL_DMA_STREAM_3);

			// TX stream
			// Disable the selected Stream
			LL_DMA_DisableStream(DMA1, LL_DMA_STREAM_4);
			// Get the DMA Stream Instance
			DMAResetRegisters((DMA_Stream_TypeDef *)(__LL_DMA_GET_STREAM_INSTANCE(DMA1, LL_DMA_STREAM_4)));
			// Reset Channel register field for DMAx Stream
			LL_DMA_SetChannelSelection(DMA1, LL_DMA_STREAM_4, LL_DMA_CHANNEL_0);
			// Reset the Stream4 pending flags
			DMA1->HIFCR = 0x0000003FU;

			LL_DMA_ConfigTransfer(DMA1, LL_DMA_STREAM_4, LL_DMA_DIRECTION_MEMORY_TO_PERIPH |
						LL_DMA_PRIORITY_HIGH | LL_DMA_MODE_NORMAL |
						LL_DMA_PERIPH_NOINCREMENT | LL_DMA_MEMORY_NOINCREMENT |
						LL_DMA_PDATAALIGN_BYTE | LL_DMA_PDATAALIGN_BYTE);
			LL_DMA_ConfigAddresses(DMA1, LL_DMA_STREAM_4, (uint32_t)&dummy_byte, LL_SPI_DMA_GetRegAddr(SPI2),
						 LL_DMA_GetDataTransferDirection(DMA1, LL_DMA_STREAM_4));
			LL_DMA_SetChannelSelection(DMA1, LL_DMA_STREAM_4, LL_DMA_CHANNEL_0);
			LL_DMA_SetDataLength(DMA1, LL_DMA_STREAM_4, 512);
			LL_DMA_EnableStream(DMA1, LL_DMA_STREAM_4);

			DMA1->LIFCR = DMA_LIFCR_CTCIF3 | DMA_LIFCR_CHTIF3 | DMA_LIFCR_CTEIF3 | DMA_LIFCR_CDMEIF3 | DMA_LIFCR_CFEIF3;
			DMA1->HIFCR = DMA_HIFCR_CTCIF4 | DMA_HIFCR_CHTIF4 | DMA_HIFCR_CTEIF4 | DMA_HIFCR_CDMEIF4 | DMA_HIFCR_CFEIF4;

			SPI2->CR2 |= (SPI_CR2_RXDMAEN | SPI_CR2_TXDMAEN);
			SPI2->CR1 |= SPI_CR1_SPE;

			while (!LL_DMA_IsActiveFlag_TC3(DMA1)) { };

			SPI2->CR2 &= ~(SPI_CR2_RXDMAEN | SPI_CR2_TXDMAEN);
#endif

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
#ifdef STANDALONE
				DebugPrint("USER_read CMD12", reply);
#endif
				return RES_ERROR;
			}
		}

		// Wait for FF
		retries = 300000;
		while (1) {
			reply = SPI_Send(0xFF);
			if (reply == 0xFF) break;
			if (!(retries--)) {
#ifdef STANDALONE
				DebugPrint("CMD12 busy", reply);
#endif
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

#if _USE_WRITE == 1
DRESULT USER_write (
	BYTE pdrv,          // Physical drive number
	const BYTE *buff,   // Write data buffer
	DWORD sector,       // Sector address (LBA)
	UINT count          // Number of sectors to write (1..128)
) {
	uint8_t reply;

	if (card_type != SD_HIGH_CAPACITY_SD_CARD)
		sector <<= 9;

	uint32_t buff_local = (uint32_t)buff;

	for (uint32_t c = 0; c < count; c++) {
		// Start new single-write
		reply = SD_Cmd(24, sector);
		if (reply != 0x00) {
#ifdef STANDALONE
			DebugPrint("USER_write CMD24", reply);
#endif
			return RES_ERROR;
		}

		// Send data token
		SPI_Send(0xFE);

		// Send 512 data bytes
		for (uint32_t c = 0; c < 512; c++) {
			SPI_Send(*buff++);
			while (SPI2->SR & SPI_SR_BSY);
		}

		// Dummy CRC
		SPI_Send(0xFF);
		SPI_Send(0xFF);

		if ((SPI_Send(0xFF) & 0x1F) != 0x05)
			return RES_ERROR;

		if (SD_WaitNotBusy(600))
			return RES_ERROR;

		SD_CS_HIGH
		SPI_Send(0xFF);

		if (card_type != SD_HIGH_CAPACITY_SD_CARD)
			sector += 512;
		else
			sector++;

		buff_local += 512;
	}

    return RES_OK;
}
#endif

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

	// Other chars is unsupported
	return 0;
}
#endif
