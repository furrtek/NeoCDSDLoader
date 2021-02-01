/*
 * Copyright (C) 2020 Sean Gonsalves
 *
 * Neo CD SD Loader bootloader V0.03
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
#include "ff.h"
#include "main.h"
#include "fatfs.h"
#include "init.h"
#include "sd.h"
#include "leds.h"

FATFS SDFatFs;
static uint32_t flash_ptr = ADDR_APP;
FIL fil_update;
uint32_t card_type = 0;
char wad_file[13];

void DMAResetRegisters(DMA_Stream_TypeDef * tmp) {
	LL_DMA_WriteReg(tmp, CR, 0U);
	LL_DMA_WriteReg(tmp, NDTR, 0U);
	LL_DMA_WriteReg(tmp, PAR, 0U);
	LL_DMA_WriteReg(tmp, M0AR, 0U);
	LL_DMA_WriteReg(tmp, M1AR, 0U);
	LL_DMA_WriteReg(tmp, FCR, 0x00000021U);
}

uint32_t find_update() {
    DIR root_dir;
    static FILINFO fno;
    uint32_t i = 0;

    // Scan root dir
	if (f_opendir(&root_dir, "/") != FR_OK)
		return 0;

	for (;;) {
		// Look for files
		FRESULT res = f_readdir(&root_dir, &fno);		// Read an item
		if (res != FR_OK || fno.fname[0] == 0) break;	// Break on error or end of directory

		if (!(fno.fattrib & AM_DIR)) {
			// Got a file

			// Get extension
			char* dot = strchr(fno.fname, '.');
			if (dot == NULL) break;

			// Compare
			if (!memcmp(dot+1, "WAD", 3)) {

				memcpy(wad_file, fno.fname, 12);
				wad_file[12] = '\0';

				i = 1;
				break;	// Stop searching at first file found
			}
		}
	}

	f_closedir(&root_dir);

	return i;
}

uint32_t flash_next(uint16_t data) {
	if ((flash_ptr > (FLASH_BASE + FLASH_SIZE - 1)) || (flash_ptr < ADDR_APP)) {
		HAL_FLASH_Lock();
		return 0;
	}

	if (HAL_FLASH_Program(FLASH_TYPEPROGRAM_BYTE, flash_ptr, data) == HAL_OK) {
		// Check programmed word
		if (*(__IO uint16_t*)flash_ptr != data) {
			HAL_FLASH_Lock();
			return 0;
		}
		flash_ptr++;
	} else {
		HAL_FLASH_Lock();
		return 0;
	}

	return 1;
}

void run_app() {
    uint32_t JumpAddress = *(__IO uint32_t*)(ADDR_APP + 4);
    function_ptr_t Jump = (function_ptr_t)JumpAddress;

    SysTick->CTRL = 0;
    SysTick->LOAD = 0;
    SysTick->VAL = 0;

    SCB->VTOR = ADDR_APP;

    __set_MSP(*(__IO uint32_t*)ADDR_APP);
    Jump();
}

void blink_code(const uint32_t * const colors) {
	// Blink 3-color code
	for (uint32_t c = 0; c < 3; c++) {
		setLED(colors[c]);
		LL_mDelay(250);
		setLED(LED_OFF);
		LL_mDelay(250);
	}
	LL_mDelay(750);
}

void blue_blinkies(const uint32_t progress) {
	if ((progress & 0x17FF) == 0x0000)
		setLED(LED_BLUE);
	else if ((progress & 0x17FF) == 0x0BFF)
		setLED(LED_OFF);
}

void do_update(char * const filename) {
    uint16_t data;
    uint32_t progress, addr, c;
    FRESULT fr;
    UINT num;
    wad_header_t header;
    wad_dir_t dir_entry;

    // Open update file
	if (f_open(&fil_update, filename, FA_READ) != FR_OK)
		while (1) { blink_code(BK_RED_RED_YELLOW); };

	// Check header
	if (f_read(&fil_update, &header, 12, &num) != FR_OK)
		while (1) { blink_code(BK_RED_YELLOW_RED); };

	if (strncmp((char*)header.magic, "IWAD", 4) || (!header.entries) || (header.entries > 32))
		while (1) { blink_code(BK_RED_YELLOW_RED); };

	// Look for MCAP lump
	f_lseek(&fil_update, header.dir_ptr);	// Go to start of directory

	for (c = 0; c < header.entries; c++) {
		f_read(&fil_update, &dir_entry, 16, &num);
		if (strstr((char*)dir_entry.name, "MCAP"))
			break;
	}
	if (c == header.entries)
		while (1) { blink_code(BK_RED_YELLOW_RED); };

	f_lseek(&fil_update, dir_entry.start_ptr);	// Go to start of MCAP lump

	__HAL_RCC_SYSCFG_CLK_ENABLE();

	HAL_FLASH_Unlock();
	__HAL_FLASH_CLEAR_FLAG(FLASH_FLAG_ALL_ERRORS);
	HAL_FLASH_Lock();

	// Erase Flash
	uint32_t PageError = 0;
	FLASH_EraseInitTypeDef pEraseInit;

	HAL_FLASH_Unlock();

	// Erase the last 3 sector (out of 4)
	pEraseInit.NbSectors = 3;
	pEraseInit.Sector = FLASH_SECTOR_1;
	pEraseInit.TypeErase = FLASH_TYPEERASE_SECTORS;
	pEraseInit.VoltageRange = FLASH_VOLTAGE_RANGE_3;
	if (HAL_FLASHEx_Erase(&pEraseInit, &PageError) != HAL_OK)
		while (1) { blink_code(BK_RED_YELLOW_YELLOW); };

	HAL_FLASH_Lock();

	// Program flash
	progress = 0;
	flash_ptr = ADDR_APP;
	HAL_FLASH_Unlock();
	do {
		data = 0xFFFF;
		fr = f_read(&fil_update, &data, 1, &num);
		if (num) {
			if (flash_next(data)) {
				progress++;
			} else {
				f_close(&fil_update);
				while (1) { blink_code(BK_YELLOW_RED_RED); };
			}
		}
		blue_blinkies(progress);
	} while((fr == FR_OK) && (flash_ptr < 0x08010000));

	// Finalize
	HAL_FLASH_Lock();
	f_close(&fil_update);
	setLED(LED_OFF);

	// Re-open file for verification
	if (f_open(&fil_update, filename, FA_READ) != FR_OK)
		while (1) { blink_code(BK_YELLOW_RED_YELLOW); };

	f_lseek(&fil_update, dir_entry.start_ptr);	// Go to start of MCAP lump

	// Verify flash
	addr = ADDR_APP;
	progress = 0;
	do {
		data = 0xFFFF;
		fr = f_read(&fil_update, &data, 1, &num);
		if (num) {
			if (*(__IO uint8_t*)addr == (__IO uint8_t)data) {
				addr++;
				progress++;
			} else {
				f_close(&fil_update);
				while (1) { blink_code(BK_YELLOW_YELLOW_RED); };
			}
		}
		blue_blinkies(progress);
	} while((fr == FR_OK) && (addr < 0x08010000));

	f_close(&fil_update);

	blink_code(BK_GREEN_GREEN_GREEN);
	//setLED(LED_OFF);
}

void run_dfu() {
	// +00000000: Stack pointer
	// +00000004: Reset vector
	uint32_t JumpAddress = *(__IO uint32_t*)(ADDR_SYSMEM + 4);
	void (*Jump)(void) = (void (*)(void))JumpAddress;

	HAL_RCC_DeInit();
	HAL_DeInit();

	SysTick->CTRL = 0;
	SysTick->LOAD = 0;
	SysTick->VAL = 0;

	__set_MSP(*(__IO uint32_t*)ADDR_SYSMEM);
	Jump();

	while(1);
}

int main(void) {
	CRC_HandleTypeDef CrcHandle;

	// Reset of all peripherals, initializes the Flash interface and the Systick.
	HAL_Init();

	SystemClock_Config();

	LL_AHB1_GRP1_EnableClock(LL_APB2_GRP1_PERIPH_SYSCFG);

	MX_GPIO_Init();
	MX_SPI2_Init();
	MX_FATFS_Init();

	LL_mDelay(200);		// Make sure SD card has its 3.3V stable. Better be safe.

	// Skip forced update check if f_mount fails
	if (f_mount(&SDFatFs, "0:", 1) == FR_OK) {
	    // See if we have a forced update file
		if (f_open(&fil_update, FILENAME_FORCED, FA_READ) == FR_OK) {
			f_close(&fil_update);
			do_update(FILENAME_FORCED);
			run_app();
		};
	}

	// Verify validity of app
	__HAL_RCC_CRC_CLK_ENABLE();
	CrcHandle.Instance = CRC;
	CrcHandle.Init.DefaultPolynomialUse = DEFAULT_POLYNOMIAL_ENABLE;
	CrcHandle.Init.DefaultInitValueUse = DEFAULT_INIT_VALUE_ENABLE;
	CrcHandle.Init.InputDataInversionMode = CRC_INPUTDATA_INVERSION_BYTE;
	CrcHandle.Init.OutputDataInversionMode = CRC_OUTPUTDATA_INVERSION_ENABLE;
	CrcHandle.InputDataFormat = CRC_INPUTDATA_FORMAT_BYTES;
	HAL_CRC_Init(&CrcHandle);

	uint32_t computed_crc = ~HAL_CRC_Calculate(&CrcHandle, (uint32_t*)ADDR_APP, APP_SIZE - 4);

	if ((*(uint32_t*)ADDR_CRC) == computed_crc) {
		// App valid, run it
		run_app();
	} else {
		// App invalid, attempt to update
		if (find_update()) {
			// Update found
			do_update(wad_file);
			run_app();
		} else {
			// No update found, we're fucked so go to DFU mode as last resort
			blink_code(BK_RED_RED_RED);
			setLED(LED_RED);	// End with solid red
			run_dfu();
		}
	}
}

void Error_Handler(void) {
}
