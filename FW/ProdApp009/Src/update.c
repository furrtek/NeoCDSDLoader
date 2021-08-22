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
#include <string.h>
#include "update.h"
#include "jtag.h"
#include "util.h"
#include "files.h"
#include "flash.h"
#include "leds.h"

uint32_t lump_cpld_ptr, update_dir_ptr, update_entry_count;
static FIL fil_update;
char wad_filename[13];

// Returns 0 on success, error code otherwise
uint32_t find_update() {
    DIR root_dir;
    FILINFO fno;
    uint32_t error_code = 1;

    // Scan root dir
	if (f_opendir(&root_dir, "/") != FR_OK)
		return error_code;

	if (search_ext(&root_dir, &fno, "wad")) {
		memcpy(wad_filename, fno.fname, 12);
		wad_filename[12] = '\0';
		error_code = 0;
	}

	f_closedir(&root_dir);

	return error_code;
}

// Returns 0 on success, error code otherwise
uint32_t CheckUpdateFile() {
    wad_header_t header;
    wad_dir_t dir_entry;
    uint32_t c;
    UINT num;

    // Open update file
	if (f_open(&fil_update, wad_filename, FA_READ) != FR_OK)
		return 1;

	// Check header
	if (f_read(&fil_update, &header, 12, &num) != FR_OK) {
		f_close(&fil_update);
		return 2;
	}
	if (memcmp(header.magic, "IWAD", 4) || (!header.entries) || (header.entries > 32)) {
		f_close(&fil_update);
		return 3;
	}

	// Look for CPLD lump
	f_lseek(&fil_update, header.dir_ptr);	// Go to start of directory

	for (c = 0; c < header.entries; c++) {
		f_read(&fil_update, &dir_entry, 16, &num);
		if (!memcmp(dir_entry.name, "CPLD", 4))
			break;
	}
	if (c == header.entries) {
		f_close(&fil_update);
		return 4;
	}

	// TODO: Check size of lump ?

	lump_cpld_ptr = dir_entry.start_ptr;
	update_dir_ptr = header.dir_ptr;
	update_entry_count = header.entries;

	return 0;
}

// Returns 0 on success, error code otherwise
uint32_t CPLDUpdate() {
    uint32_t c;
    UINT num;

    // Update file already opened by CheckUpdateFile

#ifdef STANDALONE
	DebugPrint("IDCODE", JTAG_Code(JTAG_IDCODE));	// Should be 0x020A50DD
	DebugPrint("lump_cpld_ptr", lump_cpld_ptr);
#endif

	JTAG_Reset();

	f_lseek(&fil_update, lump_cpld_ptr);	// Go to start of CPLD lump

	JTAG_Enable();
	JTAG_Erase();
	JTAG_StartProgram();

	setLED(LED_BLUE);

	// Bitstream is always 6656 bytes = 26 blocks of 256 bytes
	for (c = 0; c < 26; c++) {
		f_read(&fil_update, buffer_temp, 256, &num);
		JTAG_Program((uint16_t*)buffer_temp, 128);		// Programming is done in words
	}

	f_lseek(&fil_update, lump_cpld_ptr);	// Go back to start of CPLD lump

	JTAG_StartRead();
	// Bitstream is always 6656 bytes = 26 blocks of 256 bytes
	for (c = 0; c < 26; c++) {
		f_read(&fil_update, buffer_temp, 256, &num);

		if (JTAG_Verify((uint16_t*)buffer_temp, 128))	// Readback is done in words
			break;
	}

	setLED(LED_OFF);

	if (c != 26) {
		JTAG_Disable();
		return 4;
	}

	JTAG_ProgramDone();
	JTAG_Disable();

	return 0;
}

// Returns checksum on success, 0 otherwise
uint16_t DumpSystemROM() {
	uint16_t sum = 0;
	FIL fil_rom;
	UINT bw;

#ifdef STANDALONE
	CDCPrint("Dumping...");
#endif

	if (f_open(&fil_rom, "ROMDUMP.BIN", FA_WRITE | FA_CREATE_ALWAYS) == FR_OK) {
		SetMode(MODE_MCU);

		uint8_t * buffer_ptr = (uint8_t*)buffer_temp;	// Init
		uint32_t w;
		for (w = 0; w < 0x40000; w++) {
			uint16_t data = ReadMem(w, MEMTYPE_CONSOLE);
			sum += data;
			*buffer_ptr++ = data >> 8;
			*buffer_ptr++ = data & 0xFF;
			if ((w & 127) == 127) {
				// End of 128-word page, write buffer to SD card
				buffer_ptr = (uint8_t*)buffer_temp;	// Reset buffer pointer
				FRESULT fr = f_write(&fil_rom, buffer_ptr, 256, &bw);
				if (bw != 256 || fr != FR_OK) {
#ifdef STANDALONE
	// DEBUG TODO
	CDCPrint("Oh no :(");
#endif
					break;
				}
			}

			// Blinkies
			if ((w & 0x3FFF) == 0)
				setLED(LED_BLUE);
			else if ((w & 0x3FFF) == 0x1FFF)
				setLED(LED_OFF);
		}

		f_close(&fil_rom);

		setLED(LED_OFF);

		if (w != 0x40000)
			sum = 0;	// Fail
	}

#ifdef STANDALONE
	CDCPrint(sum ? "OK" : "FAIL");
#endif

	return sum;
}

// Returns 0 on success, error code otherwise
uint32_t DoUpdate() {
    uint32_t c;
    wad_dir_t dir_entry;
	UINT num;
	FIL fil_romdump;
	FRESULT res;

	if (!find_update()) {
#ifdef STANDALONE
		uint32_t test = CheckUpdateFile();
		DebugPrint("CheckUpdateFile", test);
#endif

		if (CheckUpdateFile())
			return 2;	// Invalid upate

		// Starting from here, return codes are useless since the console is now in reset
		RESET_LOW

		if (CPLDUpdate())
			blink_code(BK_YELLOW_RED_RED);	// CPLD update fail

		// Dump console SP ROM to SD card
		uint16_t sprom_sum = DumpSystemROM();

		if (sprom_sum) {
			// Look in update file for patch data matching system ROM checksum
			f_lseek(&fil_update, update_dir_ptr);	// Go to start of directory

			sprintf(buffer_temp, "SPAT%04X", sprom_sum);
#ifdef STANDALONE
			CDCPrint(buffer_temp);
#endif

			for (c = 0; c < update_entry_count; c++) {
				f_read(&fil_update, &dir_entry, 16, &num);
				if (!memcmp((char*)dir_entry.name, buffer_temp, 8))
					break;
			}
			if (c != update_entry_count) {
#ifdef STANDALONE
				CDCPrint("Found, patching");
#endif
				// Open SP ROM dump
				f_open(&fil_romdump, "ROMDUMP.BIN", FA_READ | FA_WRITE);

				f_lseek(&fil_update, dir_entry.start_ptr);	// Go to start of patch data

				// Apply patch
				while (1) {
					res = f_read(&fil_update, buffer_temp, 6, &num);	// Read start address and data length
					uint32_t start_addr = *(uint32_t*)buffer_temp;
					if ((start_addr >= 0x80000) || (res != FR_OK))
						break;	// EOF

					uint16_t data_length = *(uint16_t*)(buffer_temp + 4);

#ifdef STANDALONE
					sprintf(buffer_temp, "A:%08lx L:%04x", start_addr, data_length);
					CDCPrint(buffer_temp);
#endif

					f_lseek(&fil_romdump, start_addr);

					for (c = 0; c < data_length; c++) {
						// Patch byte-by-byte - TODO: Make this faster
						f_read(&fil_update, buffer_temp, 1, &num);
						f_write(&fil_romdump, buffer_temp, 1, &num);
					}
				}

				if (res != FR_OK) {
					f_close(&fil_romdump);
					f_close(&fil_update);
					blink_code(BK_YELLOW_RED_YELLOW);	// File access error
					return 1;
				}

#ifdef STANDALONE
				CDCPrint("Flashing");
#endif

				EraseFlash();

				f_lseek(&fil_romdump, 0);
				// Flash patched file
				for (c = 0; c < 0x800; c++) {
					f_read(&fil_romdump, buffer_temp, 256, &num);
					for (uint32_t d = 0; d < 128; d++) {
						uint16_t data = (buffer_temp[d*2]<<8) + buffer_temp[d*2+1];
						CmdFlash(FLASH_PROGRAM);		// Disable write protection
						WriteFlash((c << 7) + d, data);	// Word program
					}

					// Blinkies
					if ((c & 0xFF) == 0)
						setLED(LED_BLUE);
					else if ((c & 0xFF) == 0x7F)
						setLED(LED_OFF);
				}

#ifdef STANDALONE
				CDCPrint("Done !");
#endif
				setLED(LED_OFF);

				f_close(&fil_romdump);
				f_close(&fil_update);
			} else {
				f_close(&fil_update);
				blink_code(BK_YELLOW_YELLOW_YELLOW);	// Matching patch lump not found
				return 4;
			}
		} else {
			f_close(&fil_update);
			blink_code(BK_YELLOW_RED_YELLOW);	// File access error for BIOS dumping
			return 3;
		}
	} else
		return 1;

	return 0;
}
