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

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "fatfs.h"
#include "util.h"
#include "init.h"
#include "files.h"
#include "cue_sheet.h"
#include "cdda.h"

// 44100Hz * 2 bytes * 2 channels = 176400bytes/s = 345 SD sectors/s
// 8192 words = 16384 bytes = 32 SD sectors = 16384 / 2 / 2 / 44100 = ~92ms buffer
// DMA half transfer interrupt -> Reload first half (16 SD sectors)
// DMA transfer complete interrupt -> Reload second half (16 SD sectors)
// -->
// AAAAAAAAAAAAAAAABBBBBBBBBBBBBBBB
//                 |              |
//         reload A       reload B

int16_t cdda_buffer[CDDA_BUFFER_WORDS];
uint32_t last_track;

void rewind_audio() {
	audio_pos = (audio_track_format == AUDIO_WAV) ? audio_start + WAV_DATA_START : audio_start;
}

void CDDA_Stop() {
	if ((data_mode == MODE_NULL) || (data_mode == MODE_AUDIO)) {
#ifdef STANDALONE
		CDCPrint("CDDA stop");
#endif

		// Disable DMA HT and TC interrupts before stopping it. Otherwise stopping it will trigger
		// a TC interrupt and cause a call to CDDA_Refill to be made with the data file closed.
		// (This still happens, but not very important)
		LL_DMA_DisableIT_HT(DMA2, LL_DMA_STREAM_3);	// Half transfer interrupt
		LL_DMA_DisableIT_HT(DMA2, LL_DMA_STREAM_3);	// Transfer complete interrupt

		// RM0431 page 235
		LL_DMA_DisableStream(DMA2, LL_DMA_STREAM_3);
		while(LL_DMA_IsEnabledStream(DMA2, LL_DMA_STREAM_3)) { };

		DMA2->LIFCR = DMA_LIFCR_CTCIF3 | DMA_LIFCR_CHTIF3 | DMA_LIFCR_CTEIF3 | DMA_LIFCR_CDMEIF3 | DMA_LIFCR_CFEIF3;

		LL_I2S_Disable(SPI1);
		LL_I2S_DisableDMAReq_TX(SPI1);

		HAL_I2S_DeInit(&hi2s1);

		// Set I2S data output pin back to GPIO mode otherwise it'll float and LOUD NOISE will ensue
		// PA7: I2SDO
		LL_GPIO_SetPinMode(GPIOA, LL_GPIO_PIN_7, LL_GPIO_MODE_OUTPUT);

		f_close(&fil_data);
		data_mode = MODE_NULL;
		prev_CD_LBA = -1;	// Make sure CD_LBA != prev_CD_LBA for kickstart
	}
}

void CDDA_Play(const uint8_t track, const uint8_t loop_flag) {
#ifdef STANDALONE
    char buffer_debug[256];
#endif
	CDDA_Stop();

	if ((track <= 1) || (track > 99))
		return;

	if (!OpenAudioTrack(track)) {
		cdda_pause = 0;
		cdda_loop = loop_flag;
		data_mode = MODE_AUDIO;

		if (!audio_stop)
			audio_stop = f_size(&fil_data);

#ifdef STANDALONE
		sprintf(buffer_debug, "CDDA_Play from %08lX to %08lX", audio_start, audio_stop);
		CDCPrint(buffer_debug);
#endif

		rewind_audio();
		CDDA_Refill(&cdda_buffer[0], CDDA_BUFFER_BYTES);		// Preload buffer

		// Reset I2S DO pin to normal I2S function
		// PA7: I2SDO
		LL_GPIO_SetPinMode(GPIOA, LL_GPIO_PIN_7, LL_GPIO_MODE_ALTERNATE);

		__HAL_RCC_SPI1_FORCE_RESET();	// Violent, but insures I2S bit-shifts don't happen
		LL_mDelay(1);					// TODO: Find the root cause of the issue
		__HAL_RCC_SPI1_RELEASE_RESET();

		// Setup SPI1 TX stream
		MX_I2S1_Init();

		LL_DMA_DisableStream(DMA2, LL_DMA_STREAM_3);
		DMAResetRegisters((DMA_Stream_TypeDef *)(__LL_DMA_GET_STREAM_INSTANCE(DMA2, LL_DMA_STREAM_3)));
		LL_DMA_SetChannelSelection(DMA2, LL_DMA_STREAM_3, LL_DMA_CHANNEL_0);
		// Reset the Stream3 pending flags
		DMA2->LIFCR = 0x0F400000U;

		// LL_DMA_DIRECTION_MEMORY_TO_PERIPH: From cdda_buffer to SPI1 peripheral
		// LL_DMA_MODE_CIRCULAR: Keep restarting the transfer until stopped
		// LL_DMA_PERIPH_NOINCREMENT: Always write to the same SPI1 register
		// LL_DMA_MEMORY_INCREMENT: Increment cdda_buffer pointer
		// LL_DMA_PDATAALIGN_HALFWORD: 16-bit transfers
		LL_DMA_ConfigTransfer(DMA2, LL_DMA_STREAM_3, LL_DMA_DIRECTION_MEMORY_TO_PERIPH |
					LL_DMA_PRIORITY_HIGH | LL_DMA_MODE_CIRCULAR |
					LL_DMA_PERIPH_NOINCREMENT | LL_DMA_MEMORY_INCREMENT |
					LL_DMA_PDATAALIGN_HALFWORD | LL_DMA_MDATAALIGN_HALFWORD);
		LL_DMA_ConfigAddresses(DMA2, LL_DMA_STREAM_3, (uint32_t)cdda_buffer, LL_SPI_DMA_GetRegAddr(SPI1),
					 LL_DMA_GetDataTransferDirection(DMA2, LL_DMA_STREAM_3));
		LL_DMA_SetChannelSelection(DMA2, LL_DMA_STREAM_3, LL_DMA_CHANNEL_3);
		// The entire cdda_buffer is 4096 words, 8192 bytes
		LL_DMA_SetDataLength(DMA2, LL_DMA_STREAM_3, 8192);
		// Clear flags
		DMA2->LIFCR = DMA_LIFCR_CTCIF3 | DMA_LIFCR_CHTIF3 | DMA_LIFCR_CTEIF3 | DMA_LIFCR_CDMEIF3 | DMA_LIFCR_CFEIF3;
		LL_DMA_EnableIT_HT(DMA2, LL_DMA_STREAM_3);	// Half transfer interrupt
		LL_DMA_EnableIT_TC(DMA2, LL_DMA_STREAM_3);	// Transfer complete interrupt
		LL_DMA_EnableStream(DMA2, LL_DMA_STREAM_3);
		LL_I2S_Enable(SPI1);
		LL_I2S_EnableDMAReq_TX(SPI1);
	} else {
		data_mode = MODE_NULL;
#ifdef STANDALONE
		CDCPrint("CDDA no file found");
#endif
	}
}

void CDDA_Refill(int16_t * buffer_start, uint32_t size) {
	FRESULT res = 0xFF;
	UINT br;
	uint32_t remaining = size, reached_stop = 0;

	if (!cdda_pause && (data_mode == MODE_AUDIO)) {
		res = f_lseek(&fil_data, audio_pos);
		if (res == FR_OK) {
			if (audio_stop) {
				// If we have an audio stop position, use it
				if (audio_pos + size >= audio_stop) {
					size = audio_stop - audio_pos;
					reached_stop = 1;
#ifdef STANDALONE
					DebugPrint("CDDA end of data", f_tell(&fil_data));
#endif
				}
			}
			remaining = size;
			res = f_read(&fil_data, buffer_start, size, &br);
			buffer_start += br;
			audio_pos += br;
			remaining -= br;
#ifdef STANDALONE
			if (res != FR_OK) {
				DebugPrint("CDDA f_read", res);
				//break;
			}
			if (br != size) DebugPrint("CDDA end of file", res);
#endif

			if ((br != size) || (reached_stop)) {
				// Attempted to read outside of the audio file, or reached end of data
				if (cdda_loop) {
					// Rewind and continue filling
#ifdef STANDALONE
					CDCPrint("CDDA loop");
#endif
					rewind_audio();
				} else {
					CDDA_Stop();
				}
			}
		} else {
#ifdef STANDALONE
			DebugPrint("CDDA f_lseek", res);
#endif
			CDDA_Stop();
		}
	}

	// Clear buffer if refill failed or during pause
	if ((res != FR_OK) || cdda_pause || (data_mode != MODE_AUDIO) || (remaining)) {
		for (uint32_t c = 0; c < (remaining >> 1); c++)
			*buffer_start++ = 0;
	}
}
