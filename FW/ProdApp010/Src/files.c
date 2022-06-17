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

#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include "files.h"
#include "fatfs.h"
#include "util.h"

filetype_t last_filetype_listed = FILE_TYPE_NONE;
uint32_t last_file_count = 0;

uint32_t ASCIICompare(char * const a, char * const b) {
	uint32_t la = strlen(a);
	uint32_t lb = strlen(b);
	uint32_t l = la < lb ? la : lb;	// Take shortest

	for (uint32_t i = 0; i < l; i++) {
		char ca = tolower(a[i]);
		char cb = tolower(b[i]);
		if (ca > cb) return 1;	// a is greater than b
		if (cb > ca) return 0;	// b is greater than a
	}

	if (la > l) return 1;		// a is greater than b
	return 0;					// b is greater than a
}

uint32_t search_ext(DIR * const dir_ptr, FILINFO * fno_ptr, char * const extension) {
	for (;;) {
		// Look for files
		FRESULT res = f_readdir(dir_ptr, fno_ptr);				// Read an item
		if (res != FR_OK || fno_ptr->fname[0] == 0) return 0;	// Return on error or end of directory

		if (!(fno_ptr->fattrib & AM_DIR)) {
			// Got a file

			// Get extension
			char* dot = strchr(fno_ptr->fname, '.');
			if (dot == NULL) break;

			// Convert to lower case
			uint32_t i = 0;
			while(dot[i]) {
				dot[i] = tolower(dot[i]);
				i++;
			}

			// Compare
			if (!memcmp(dot+1, extension, 3)) {
				return 1;	// Stop searching at first file found
			}
		}
	}
	return 0;
}

int32_t listfiles(filetype_t filetype) {
    DIR root_dir, sub_dir;
    FILINFO dno, fno;
	UINT num;
    int32_t i = 0;
    uint8_t exceed_max = 0;
	uint32_t u = 1, v;

    // Returns -1 on fail, otherwise number of files found or EXCEED_CODE
    // Loads file_list and *reply_buff_ptr

	// MUST always start loading reply_buff_a
	reply_buff_ptr = &reply_buff_a;

    if ((filetype == last_filetype_listed) && (filetype == FILE_TYPE_CUE)) {
    	// Game list already in memory, don't list again
    	if (last_file_count == EXCEED_CODE) {
        	i = MAX_FILES;
	    	exceed_max = 1;
		} else {
			i = last_file_count;
		}
    } else {

	#ifdef STANDALONE
		sprintf(buffer_temp, "listfiles type %u", filetype);
		CDCPrint(buffer_temp);
	#endif

		// Scan root dir
		if (f_opendir(&root_dir, "/") != FR_OK)
			return -1;

		if (filetype == FILE_TYPE_CUE) {
			for (;;) {
				// Look for subdirs in the root
				FRESULT res = f_readdir(&root_dir, &dno);		// Read an item
				if (res != FR_OK || dno.fname[0] == 0) break;	// Break on error or end of directory

				if (dno.fattrib & AM_DIR) {
					// Got a subdir

					FRESULT res = f_opendir(&sub_dir, dno.fname);	// Scan subdir
					if (res != FR_OK) break;						// Break on error

					// This is the slowest part in getting the game list
					if (search_ext(&sub_dir, &fno, "cue")) {
						if (i == MAX_FILES) {
							// More than MAX_FILES found, flag it
							exceed_max = 1;
							f_closedir(&sub_dir);
							break;
						}
						// Store the -subdir- name
						strncpy(file_list[i], dno.fname, MAX_FILE_NAME);
						file_list[i][MAX_FILE_NAME] = '\0';
						i++;
					}

					f_closedir(&sub_dir);
				}
			}
		} else if (filetype == FILE_TYPE_SAV) {
			for (;;) {
				if (search_ext(&root_dir, &fno, "sav")) {
					if (i == MAX_FILES) {
						// More than MAX_FILES found, flag it
						exceed_max = 1;
						break;
					}
					// Store the -file- name
					strncpy(file_list[i], fno.fname, MAX_FILE_NAME);
					file_list[i][MAX_FILE_NAME] = '\0';

					i++;
				} else
					break;
			}
		} else if (filetype == FILE_TYPE_DIP) {
			for (;;) {
				if (search_ext(&root_dir, &fno, "dip")) {
					if (i == MAX_FILES) {
						// More than MAX_FILES found, flag it
						exceed_max = 1;
						break;
					}

					// Check if NGH match
#ifdef STANDALONE
					sprintf(buffer_temp, "Looking for %04X.dip", current_ngh);
					CDCPrint(buffer_temp);
#endif
					sprintf(buffer_temp, "%04X", current_ngh);
					if (!memcmp(fno.fname, buffer_temp, 4)) {
#ifdef STANDALONE
						sprintf(buffer_temp, "Found %s !", fno.fname);
						CDCPrint(buffer_temp);
#endif
						// Store the -file- name
						strncpy(file_list[i], fno.fname, MAX_FILE_NAME);
						file_list[i][MAX_FILE_NAME] = '\0';
						i++;
						break;	// Stop at first file found
					}
				} else
					break;
			}
		}

		if (i) {
			// Simple insertion sort, dumb but fast enough and doesn't use much RAM.
			char temp[MAX_FILE_NAME + 1];
			while (u < i) {
				strcpy(temp, file_list[u]);
				v = u - 1;
				while (v && ASCIICompare(file_list[v], temp)) {
					strcpy(file_list[v+1], file_list[v]);
					v--;
				}
				strcpy(file_list[v+1], temp);
				u++;
			}
		}
    }

	if (i) {
#ifdef STANDALONE
		DebugPrint("File count", i);
#endif
		// Provide console with trimmed filenames
		u = 0;
		uint8_t * buff_ptr = reply_buff_ptr->byte + 8;
		while (u < i) {
			buff_ptr[0] = u;
			for (uint32_t c = 1; c < 32; c++)
				buff_ptr[c] = 0;
#pragma GCC diagnostic ignored "-Wstringop-truncation"
			strncpy((char*)&buff_ptr[1], file_list[u], 30);
			buff_ptr += 32;

			u++;
		}
	}

	f_closedir(&root_dir);

	if (exceed_max) i = EXCEED_CODE;

	last_filetype_listed = filetype;
	last_file_count = i;

	return i;
}
