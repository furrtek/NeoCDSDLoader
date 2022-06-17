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
#include "console_cmd.h"
#include "util.h"
#include "sd.h"
#include "cpld_comm.h"
#include "jtag.h"
#include "update.h"
#include "files.h"
#include "cdda.h"
#include "leds.h"
#include "cue_sheet.h"
#ifdef STANDALONE
#include "usbd_cdc_if.h"
#include "usb_device.h"
#endif

volatile cmd_buffer_t cmd_buffer = { .index = 0, .data = { 0 } };	// Console command buffer

void LoadReplyFIFO() {
	// Fill entire CPLD FIFO
	WriteCPLDData(reply_buff_ptr->word[0]);	// Total 1648ns ~= 20 68kclk
	WriteCPLDData(reply_buff_ptr->word[1]);
	WriteCPLDData(reply_buff_ptr->word[2]);
	WriteCPLDData(reply_buff_ptr->word[3]);
	reply_idx = 4;
	SetMCUBusOutput();	// Useless ?
}

void SetStatus(const uint8_t cmd, const uint8_t flag, const uint8_t value) {
	reply_buff_ptr = &reply_buff_a;
	reply_buff_ptr->byte[0] = flag ? (cmd | 0xF0) : (cmd & 0x0F);
    reply_buff_ptr->byte[1] = value;
}

void load_CD_sector(const uint32_t LBA, uint8_t* buffer) {
	UINT num;

	buffer[0] = MCU_CMD_LOADSECT;	// NOK by default

	if (data_mode != MODE_DATA) {
		if (OpenDataTrack()) {
#ifdef STANDALONE
			CDCPrint("OpenDataTrack() fail");
#endif
			buffer[1] = 3;
			return;
		}
#ifdef STANDALONE
		else
			CDCPrint("OpenDataTrack() OK");
#endif
	}

	setLED(led_color_load);

	// 2352-byte sectors: Skip sync pattern, address and mode (16 bytes)
	FRESULT res = f_lseek(&fil_data, LBA + ((data_sector_size == 2048) ? 0 : 16));
	if (res == FR_OK) {
		if (f_read(&fil_data, &buffer[8], 2048, &num) == FR_OK) {
			buffer[0] |= 0xF0;	// OK
		} else {
#ifdef STANDALONE
			CDCPrint("load_CD_sector f_read");
#endif
			buffer[1] = 1;
		}
	} else {
#ifdef STANDALONE
		DebugPrint("load_CD_sector f_lseek", res);
#endif
		buffer[1] = 2;
	}

	setLED(led_color_idle);
}

void ExecCmd() {
	uint32_t error_code;

	cmd_buffer.index = 0;	// Reset command buffer
	reply_idx = 0;			// Reset reply readback index
	storing_mode = 0;		// This should not be needed !

	uint8_t cmd = cmd_buffer.data[0];

#ifdef STANDALONE
	if ((cmd != MCU_CMD_GETSTATUS) && (cmd != MCU_CMD_LOADSECT) && (cmd != MCU_CMD_TEST) && (cmd != MCU_CMD_LOADSAVE)) {
#if 1
		if (cmd != MCU_CMD_STORESAVE) {
#endif
		sprintf(buffer_temp, "Exec cmd %02X - %02X %02X %02X %02X", cmd, cmd_buffer.data[1], cmd_buffer.data[2], cmd_buffer.data[3], cmd_buffer.data[4]);
		CDCPrint(buffer_temp);
#if 1
		}
#endif
	}
#endif

	// Make sure CD_LBA != prev_CD_LBA if commands were issued between loading of adjacent sectors
	// This also guarantees that the first sector of a new selected game gets buffered before being sent
	if (cmd != MCU_CMD_LOADSECT)
		prev_CD_LBA = -1;

	if (cmd == MCU_CMD_TEST) {
		// Comm test, echo back param[0]
#ifdef STANDALONE
		CDC_Transmit_FS((uint8_t*)cmd_buffer.data, 4);
		LL_mDelay(5);	// Keep this or the terminal will skip lines :(
#endif
		SetStatus(cmd, CMD_OK, cmd_buffer.data[1]);
	} else if (cmd == MCU_CMD_GETID) {
		// Get MCU serial, MCU app version and CPLD's USERCODE
		uint32_t code_part = 0;
		uint8_t * buff_ptr = reply_buff_ptr->byte + 1;

		for (uint32_t c = 0; c < 12; c++) {
			if ((c & 3) == 0) {
				code_part = *(uint32_t*)(UID_BASE + c);	// Load new longword
#ifdef STANDALONE
				sprintf(buffer_temp, "%lu: %08lX", c, code_part);
				CDCPrint(buffer_temp);
#endif
			}
			*buff_ptr++ = (code_part >> 24) & 0xFF;
			code_part <<= 8;	// Next byte
		}

		*buff_ptr++ = VERSION_MAJOR;
		*buff_ptr++ = VERSION_MINOR;

		code_part = JTAG_Code(JTAG_USERCODE);
#ifdef STANDALONE
				sprintf(buffer_temp, "CPLD: %08lX", code_part);
				CDCPrint(buffer_temp);
#endif
		for (uint32_t c = 0; c < 4; c++) {
			*buff_ptr++ = (code_part >> 24) & 0xFF;
			code_part <<= 8;	// Next byte
		}

		SetStatus(cmd, CMD_OK, reply_buff_ptr->byte[1]);	// Stupid, rewrite byte[1] to avoid adding special handling in SetStatus
	} else if (cmd == MCU_CMD_UPDATE) {
		error_code = DoUpdate();
		SetStatus(cmd, CMD_NOK, error_code);
		// Let user see error code if it isn't critical
		// Do SetRunStock(0) if the update succeeded
		// Do SetRunStock(1) if the update failed (firmware or CPLD may be corrupt)
		if (!error_code)
			SetRunLoader();
		else if (error_code > 2)
			SetRunStock(0, 0);
#ifdef STANDALONE
		DebugPrint("Update req", error_code);
#endif
	} else if (cmd == MCU_CMD_RESET) {
		if (cmd_buffer.data[1]) {
			uint8_t patch_data = cmd_buffer.data[2];
			uint32_t patch_addr = ((uint32_t)cmd_buffer.data[3] << 16) + ((uint32_t)cmd_buffer.data[4] << 8) + cmd_buffer.data[5];
#ifdef STANDALONE
		sprintf(buffer_temp, "SetRunStock patch addr:%08lX: data:%02X", patch_addr, patch_data);
		CDCPrint(buffer_temp);
#endif
			SetRunStock(patch_data, patch_addr);
		} else {
			SetRunLoader();
		}
	} else if (cmd == MCU_CMD_INITSD) {
		error_code = SD_Init();
		if (!error_code) {
			error_code = f_mount(&SDFatFs, "0:", 1);
			if (error_code == FR_OK)
				SetStatus(cmd, CMD_OK, card_type);
			else
				SetStatus(cmd, CMD_NOK, error_code + 32);
		} else
			SetStatus(cmd, CMD_NOK, error_code);
#ifdef STANDALONE
		DebugPrint("SD_Init", error_code);
#endif
	} else if (cmd == MCU_CMD_GETGAMES) {
		if (!cmd_buffer.data[1]) {
			// Get games list
			int32_t i = listfiles(FILE_TYPE_CUE);
			SetStatus(cmd, i >= 0 ? CMD_OK : CMD_NOK, i);
		} else {
			// Get full file name
			// param[1] must be less or equal than game count !
			for (uint32_t c = 0; c < MAX_FILE_NAME; c++)
				reply_buff_ptr->byte[c + 8] = 0;
			strncpy((char*)&reply_buff_ptr->byte[8], file_list[cmd_buffer.data[2]], MAX_FILE_NAME);
#ifdef STANDALONE
			sprintf(buffer_temp, "LFN get %02u: %.256s", cmd_buffer.data[2], (char*)&reply_buff_ptr->byte[8]);
			CDCPrint(buffer_temp);
#endif
			SetStatus(cmd, CMD_OK, 0);
		}
	} else if (cmd == MCU_CMD_SELECTGAME) {
		DIR sub_dir;
		FILINFO fno;

		data_mode = MODE_NULL;
		game_index = cmd_buffer.data[1];

#if 0
		DebugPrint("Load game", game_index);

		if (game_index == 200) {
			f_close(&fil_data);
			FRESULT fr = f_open(&fil_data, "testdata.bin", FA_READ);
			if (fr != FR_OK)
				DebugPrint("testdata f_open()", fr);
			data_mode = MODE_DATA;
			data_sector_size = 2048;

			error_code = 0;
		} else {
#endif

		if (game_index == BG_CODE) {
			// Game index BG_CODE is used as a special case to read the custom background file
			f_close(&fil_data);
			if (f_open(&fil_data, CUSTOM_BG_FILENAME, FA_READ) == FR_OK) {
#ifdef STANDALONE
				CDCPrint("Found custom bg file");
#endif
				prev_CD_LBA = -1;	// Make sure CD_LBA != prev_CD_LBA for kickstart
				data_mode = MODE_DATA;
				data_sector_size = 2048;
				error_code = 0;
			} else
				error_code = 1;		// File doesn't exist or access problem
		} else {
			// Normal game selection
			if (f_opendir(&sub_dir, file_list[game_index]) == FR_OK) {
				if (search_ext(&sub_dir, &fno, "cue")) {
					sprintf(cue_sheet_path, "%s/%s", file_list[game_index], fno.fname);
					// Get data track sector size in expectation of MCU_CMD_LOADSECT
					OpenDataTrack();
					error_code = 0;
				} else
					error_code = 2;	// search_ext failed

				f_closedir(&sub_dir);
			} else
				error_code = 3;	// f_opendir failed
		}
#if 0
	}
#endif
		SetStatus(cmd, error_code ? CMD_NOK : CMD_OK, error_code);
	} else if (cmd == MCU_CMD_LOADSECT) {
		// Get CD sector

		CDDA_Stop();

		// MSF - 2 seconds -> LBA
		CD_LBA = BCDtoHex(cmd_buffer.data[1]) * 75 * 60;
		CD_LBA += BCDtoHex(cmd_buffer.data[2]) * 75;
		CD_LBA += BCDtoHex(cmd_buffer.data[3]);
		CD_LBA -= (2 * 75);
		CD_LBA *= data_sector_size;

		if (CD_LBA == prev_CD_LBA + data_sector_size) {
			// The requested sector is consecutive to the previous one, it should be
			// already buffered.
			// Flip the buffers, tell the BIOS that we're already ready and start loading
			// the next one in anticipation.

#if 0
			sprintf(buffer_temp, "Cons M:%02X S:%02X F:%02X LBA:%08lX S:%u", cmd_buffer.data[1], cmd_buffer.data[2], cmd_buffer.data[3], CD_LBA, data_sector_size);
			CDCPrint(buffer_temp);
#endif

			reply_buff_ptr = (reply_buff_ptr == &reply_buff_a) ? &reply_buff_b : &reply_buff_a;

			LoadReplyFIFO();

			// BIOS reading A, load B
			// BIOS reading B, load A
			load_CD_sector(CD_LBA + data_sector_size, (reply_buff_ptr == &reply_buff_a) ? &reply_buff_b.byte[0] : &reply_buff_a.byte[0]);
		} else {
			// The requested sector is not consecutive to the previous one, both buffers
			// must be loaded.
			// Reset the flip flag, load one sector, tell the BIOS that we're ready and start
			// loading the next one in prevision.

#if 0
			sprintf(buffer_temp, "Rand M:%02X S:%02X F:%02X LBA:%08lX S:%u", cmd_buffer.data[1], cmd_buffer.data[2], cmd_buffer.data[3], CD_LBA, data_sector_size);
			CDCPrint(buffer_temp);
#endif

			reply_buff_ptr = &reply_buff_a;

			reply_buff_ptr->byte[0] = cmd & 0x0F;	// NOK is default reply
			load_CD_sector(CD_LBA, &reply_buff_a.byte[0]);

			LoadReplyFIFO();

			load_CD_sector(CD_LBA + data_sector_size, &reply_buff_b.byte[0]);
		}

		flag_exec = 0;	// Prevent fall-through code from doing its thing
		prev_CD_LBA = CD_LBA;
	} else if (cmd == MCU_CMD_CDDA) {
		// CDDA command
		uint8_t cmd = cmd_buffer.data[1];
		uint8_t track = BCDtoHex(cmd_buffer.data[2]);

		// The console doesn't like waiting while the cue file is being parsed,
		// so provide answer right now and then keep working...
		SetStatus(cmd, CMD_OK, 0);
		flag_exec = 0;
		LoadReplyFIFO();

#ifdef STANDALONE
		DebugPrint("CDDA cmd", cmd);
		DebugPrint("Track", track);
#endif

		if ((cmd & 3) == 0) {
			CDDA_Play(track, 1);	// Play, loop
		} else if ((cmd & 3) == 1) {
			CDDA_Play(track, 0);	// Play, no loop
		} else if ((cmd & 3) == 2) {
			cdda_pause = 1;			// Pause
		} else if ((cmd & 3) == 3) {
			cdda_pause = 0;			// Resume
		}
	} else if (cmd == MCU_CMD_DUMPROM) {

		// Dump console system ROM to SD card
		// TODO: Repurpose ? Not used anymore
		if (DumpSystemROM())
			SetMode(MODE_RUN);				// Success, let console restart
		else
			SetStatus(cmd, CMD_NOK, 1);		// Fail, provide error code

	} else if (cmd == MCU_CMD_GETSAVES) {
		// Get save RAM or soft DIPs file list
		int i;

		if (cmd_buffer.data[1] == 0) {
#ifdef STANDALONE
			CDCPrint("listfiles SAV");
#endif
			i = listfiles(FILE_TYPE_SAV);
		} else {
			current_ngh = (cmd_buffer.data[2] << 8) + cmd_buffer.data[3];
#ifdef STANDALONE
			sprintf(buffer_temp, "listfiles DIP NGH %04X", current_ngh);
			CDCPrint(buffer_temp);
#endif
			i = listfiles(FILE_TYPE_DIP);
		}

		SetStatus(cmd, i >= 0 ? CMD_OK : CMD_NOK, i);
	} else if (cmd == MCU_CMD_STORESAVE) {
		// Store save RAM (or anything really) data to SD card
		// Change: File extension is provided by console

		error_code = 0;
		storing_mode = 0;	// This should not be needed !

		if (storing_error) {
			// There has been a storing error since file was opened
			error_code = 5;	// NOK, error code
			storing_error = 0;
		} else {
			// 0: Close file
			// 1: Open file
			// 2: Setup transfer
			// 3: Delete file
			uint8_t subcmd = cmd_buffer.data[1];

			if (subcmd == 0) {
				// Just close file and answer back OK
				f_close(&fil_data);
			} else if (subcmd == 1) {
				// Open file for writing

				// Make sure that future sector loading will re-open the data track
				data_mode = MODE_NULL;
				prev_CD_LBA = -1;	// Make sure CD_LBA != prev_CD_LBA for kickstart

				CDDA_Stop();
				f_close(&fil_data);

				// Check that filename is not empty
				if (!cmd_buffer.data[4]) {
					error_code = 1;	// NOK, error code
				} else {
#ifdef STANDALONE
					sprintf(buffer_temp, "Open file: %s", (char*)&cmd_buffer.data[4]);
					CDCPrint(buffer_temp);
#endif
					// If param[2] is 1, return an error if the file already exists
					FRESULT fr = f_open(&fil_data, (char*)&cmd_buffer.data[4], FA_WRITE | (cmd_buffer.data[3] == 1 ? FA_CREATE_NEW : FA_CREATE_ALWAYS));
					if (fr == FR_OK) {
						storing_error = 0;
					} else {
						if ((cmd_buffer.data[3] == 1) && (fr == FR_EXIST))
							error_code = 3;	// NOK error code, menu code checks this
						else
							error_code = 2;	// NOK error code
					}
				}
			} else if (subcmd == 2) {
				// Setup transfer, max 65536 words
				storing_word_max = (cmd_buffer.data[2] << 8) + cmd_buffer.data[3];
				if (storing_word_max) {
					storing_word_count = 0;
					buffer_write_count = 0;
					storing_mode = 1;
#ifdef STANDALONE
					DebugPrint("Transfer size", storing_word_max);
#endif
				} else
					error_code = 4;	// NOK error code
			} else if (subcmd == 3) {
				// Delete file
#ifdef STANDALONE
				DebugPrint("Delete file", cmd_buffer.data[2]);
#endif
				if (f_unlink(file_list[cmd_buffer.data[2]]) != FR_OK)
					error_code = 6;	// f_unlink failed
			}
		}

		SetStatus(cmd, error_code ? CMD_NOK : CMD_OK, error_code);
	} else if (cmd == MCU_CMD_LOADSAVE) {
		// Load RAM data from SD card
		// This is similar to the CD sector loading code, but simpler
		UINT br;
		error_code = 0;	// OK

		f_close(&fil_data);

		uint32_t LBA = ((cmd_buffer.data[2] << 8) + cmd_buffer.data[3]) << 11;	// *2048
#ifdef STANDALONE
		DebugPrint("File load chunk", LBA);
#endif

		if (cmd_buffer.data[1] >= MAX_FILES)
			error_code = 5;	// Invalid save file index

		if (f_open(&fil_data, file_list[cmd_buffer.data[1]], FA_READ) == FR_OK) {
			// Don't use the double-buffer method for this, total transfer is short
			if (f_lseek(&fil_data, LBA) == FR_OK) {
				if (f_read(&fil_data, &reply_buff_a.byte[8], 2048, &br) == FR_OK) {
					if (br <= 0)
						error_code = 2;	// f_read returned no data
				} else
					error_code = 3;	// f_read failed
			} else
				error_code = 4;	// f_lseek failed
		} else
			error_code = 1;	// f_open failed

		// Make sure that future sector loading will re-open the data track
		data_mode = MODE_NULL;
		prev_CD_LBA = -1;	// Make sure CD_LBA != prev_CD_LBA for kickstart

		SetStatus(cmd, error_code ? CMD_NOK : CMD_OK, error_code);
	} else if (cmd == MCU_CMD_GETSTATUS) {
		// Get status byte, set RGB LED colors if requested

		uint8_t param = cmd_buffer.data[1];
		if (param & 0x80) {
#ifdef STANDALONE
		DebugPrint("Set LEDs", param);
#endif
			led_color_idle = (param >> 3) & 7;
			led_color_load = param & 7;
			setLED(led_color_idle);
		}

		SetStatus(cmd, CMD_OK, (stat_card_inserted << 7) | (stat_card_event << 6));

		// Reading status clears the card event bit
		stat_card_event = 0;
	} else {
		// Invalid command
		SetStatus(cmd, CMD_NOK, 0);
#ifdef STANDALONE
		DebugPrint("Invalid cmd", cmd);
#endif
	}

	if (flag_exec) {
		flag_exec = 0;
		LoadReplyFIFO();
	}

	cmd_buffer.data[0] = 0;		// Prevents storing_mode lock
}
