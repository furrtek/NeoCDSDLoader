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
#include "fatfs.h"
#include "cdda.h"
#include "cue_sheet.h"
#ifdef STANDALONE
#include "util.h"
#endif

char cue_sheet_path[512];

// Returns 0 on success
uint32_t ParseCueSheet(char * const file_path, const uint32_t track_number, char * const return_data) {
    FRESULT res;
    char track_type_str[16];
    char file_format_str[16];
    unsigned int current_track;
    char * line_end;
    uint32_t file_offset = 0, get_index = 0, get_stop = 0;
    unsigned int index_number, index_m = 0, index_s, index_f;
    UINT br;
    uint32_t LBA_value;
#ifdef STANDALONE
    char buffer_debug[256];
#endif

    // reply_buff_b is used here as a 1kB temporary buffer, to save up RAM

	data_mode = MODE_NULL;

	f_close(&fil_data);
	if (f_open(&fil_data, file_path, FA_READ) != FR_OK)
		return 1;

	// Get 1kB max. at once from the cue file
	while (1) {
		res = f_lseek(&fil_data, file_offset);
		if (res != FR_OK) {
			// Error or EOF
			if (get_stop) return 0;	// No problem if we already have the essential for audio track
			return 2;
		}

		res = f_read(&fil_data, reply_buff_b.byte, 1024, &br);
		if ((res != FR_OK) || (br == 0)) {
			// Error or EOF
			if (get_stop) return 0;	// No problem if we already have the essential for audio track
			return 3;
		}

		// Find line end (LF, 0x0A)
		line_end = strchr((char*)reply_buff_b.byte, 0x0A);
		if (line_end == NULL)
			line_end = (char*)reply_buff_b.byte + sizeof(reply_buff_b.byte) - 1;

		*line_end = 0;	// Chop string at line end

		char * line_ptr = (char*)reply_buff_b.byte;
		// Skip spaces at beginning of line
		while (*line_ptr == ' ')
			line_ptr++;

		if (!memcmp(line_ptr, "FILE", 4)) {
			// Found FILE line
			if (get_index) {
				if (get_stop)
					return 0;	// No need for audio_stop, just consider end of file
				else
					return 6;	// Didn't find an INDEX 01 for requested track
			}
			sscanf(line_ptr, "%*s \"%" MAX_FILE_NAME_STR "[^\"]\" %15s", return_data, file_format_str);
		} else if (!memcmp(line_ptr, "TRACK", 5)) {
			// Found TRACK line
			sscanf(line_ptr, "%*s %u %15s", &current_track, track_type_str);
			if (get_index) {
				if (get_stop) {
					if (current_track != track_number+1)
						return 0;	// Tracks aren't in order in the cue file, or last track, consider end of file
				} else
					return 6;	// Didn't find an INDEX 01 for requested track
			}
			if (current_track == track_number) {
				// Got required track, check type
				if (track_number == 1) {
					// Track 1 needs to be data
					if (!strcmp(track_type_str, "MODE1/2048"))
						data_sector_size = 2048;
					else if (!strcmp(track_type_str, "MODE1/2352"))
						data_sector_size = 2352;
					else
						return 4;	// Invalid data track type
					// TRACK valid, now expect to get INDEX line
					get_index = 1;
				} else {
					// All other tracks need to be audio
					if (!strcmp(track_type_str, "AUDIO")) {
						if (!strcmp(file_format_str, "BINARY"))
							audio_track_format = AUDIO_BIN;
						else if (!strcmp(file_format_str, "WAVE"))
							audio_track_format = AUDIO_WAV;
						else
							return 5;	// Invalid audio file format
						// TRACK valid, now expect to get INDEX lines
						audio_start = 0;
						audio_stop = 0;
						get_index = 1;
					} else
						return 4;	// Invalid audio track type
				}
			}
		} else if (!memcmp(line_ptr, "INDEX", 5) && (get_index || get_stop)) {
			// Found INDEX line
			sscanf(line_ptr, "%*s %02u %02u:%02u:%02u", &index_number, &index_m, &index_s, &index_f);
#ifdef STANDALONE
			sprintf(buffer_debug, "INDEX %02u: %02u:%02u:%02u", index_number, index_m, index_s, index_f);
			CDCPrint(buffer_debug);
#endif
			if (index_number == 1) {
				LBA_value = (index_f + (index_s * 75) + (index_m * 75 * 60)) * (audio_track_format == AUDIO_WAV ? 2048 : data_sector_size);
#ifdef STANDALONE
				sprintf(buffer_debug, "LBA_value:%08lX get_stop:%02lu", LBA_value, get_stop);
				CDCPrint(buffer_debug);
#endif
				if (get_stop) {
					audio_stop = LBA_value;	// Got stop, we're done
					return 0;
				} else {
					audio_start = LBA_value;	// Got start
					if (track_number > 1)
						get_stop = 1;	// Get stop for audio track
					else
						return 0;	// No need for stop for data track
				}
			}
		}
		file_offset += ((line_end - (char*)reply_buff_b.byte) + 1);
	}
}

// Returns 0 on success
uint32_t OpenDataTrack() {
	char file_name[MAX_FILE_NAME + 1];
	FRESULT fr = FR_OK;

	// Look for track 01, get its MODE and open it as data file
	if (!ParseCueSheet(cue_sheet_path, 1, file_name)) {
		// Generate full path
		sprintf(buffer_temp, "%s/%s", file_list[game_index], file_name);
#ifdef STANDALONE
		CDCPrint(buffer_temp);
#endif
		f_close(&fil_data);
		fr = f_open(&fil_data, buffer_temp, FA_READ);
		if (fr == FR_OK) {
			prev_CD_LBA = -1;	// Make sure CD_LBA != prev_CD_LBA for kickstart
			data_mode = MODE_DATA;
			return 0;
		}
	}

#ifdef STANDALONE
	DebugPrint("OpenDataTrack() fail", fr);
#endif
	data_mode = MODE_NULL;
	return 1;
}

// Returns 0 on success
uint32_t OpenAudioTrack(const uint32_t track_number) {
	char file_name[MAX_FILE_NAME + 1];

	// Look for AUDIO track 'track_number' and open it as data file
	if (!ParseCueSheet(cue_sheet_path, track_number, file_name)) {
		// Generate full path
		sprintf(buffer_temp, "%s/%s", file_list[game_index], file_name);
#ifdef STANDALONE
		CDCPrint(buffer_temp);
#endif
		f_close(&fil_data);
		FRESULT fr = f_open(&fil_data, buffer_temp, FA_READ);
		if (fr == FR_OK) {
			last_track = track_number;
			data_mode = MODE_AUDIO;
			return 0;
		}
	}

#ifdef STANDALONE
	CDCPrint("OpenAudioTrack() fail");
#endif
	data_mode = MODE_NULL;
	return 1;
}
