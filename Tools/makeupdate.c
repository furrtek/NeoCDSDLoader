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

// Generates an update file for the Neo CD SD Loader
// furrtek 2019-2020
// Needs: MCU bin, Patch .p files, CPLD .pof file
// See other tool overlay.c for details about the .p file
// See doc.odt

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>

typedef struct __attribute__((__packed__)) {
	unsigned char record_type;
	unsigned char header_byte;
	unsigned char cpu_type;
	unsigned char granularity;
	unsigned long start_address;
	unsigned short length;
} precord_t;

typedef struct __attribute__((__packed__)) {
	unsigned char magic[4];
	unsigned long entries;
	unsigned long dir_ptr;
} wadheader_t;

typedef struct __attribute__((__packed__)) {
	unsigned long start_ptr;
	unsigned long size;
	unsigned char name[8];
} waddir_t;

static const unsigned int crc32_table[] = {
	0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f,
	0xe963a535, 0x9e6495a3,	0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
	0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91, 0x1db71064, 0x6ab020f2,
	0xf3b97148, 0x84be41de,	0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
	0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,	0x14015c4f, 0x63066cd9,
	0xfa0f3d63, 0x8d080df5,	0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
	0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,	0x35b5a8fa, 0x42b2986c,
	0xdbbbc9d6, 0xacbcf940,	0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
	0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423,
	0xcfba9599, 0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
	0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,	0x76dc4190, 0x01db7106,
	0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
	0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d,
	0x91646c97, 0xe6635c01, 0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
	0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
	0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
	0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7,
	0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
	0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa,
	0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
	0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81,
	0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
	0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683, 0xe3630b12, 0x94643b84,
	0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
	0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
	0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
	0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e,
	0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
	0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55,
	0x316e8eef, 0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
	0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe, 0xb2bd0b28,
	0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
	0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f,
	0x72076785, 0x05005713, 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
	0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
	0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
	0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69,
	0x616bffd3, 0x166ccf45, 0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
	0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc,
	0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
	0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693,
	0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
	0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d
};

unsigned char wad_entries = 0;
waddir_t wad_dir[32];
unsigned char * outdata;
unsigned char * outdata_ptr;
unsigned int mode = 0;

unsigned long CRC32(const unsigned char *buf, int len) {
	unsigned long crc = 0xFFFFFFFF;
	while (len--)
		crc = (crc >> 8) ^ crc32_table[(crc ^ *buf++) & 255];
	return crc ^ 0xFFFFFFFF;
}

int addlumpbin(char * const filename, char * const desc, char pof_flag) {
	FILE * fin;
	unsigned long crc;
	unsigned long filesize = 0;
	unsigned long c;
	
	strncpy(wad_dir[wad_entries].name, filename, 8);
	
	fin = fopen(filename, "rb");
	if (fin == NULL) {
		printf("%s can't be opened.\n", filename);
		return 1;
	} else {
	    wad_dir[wad_entries].start_ptr = outdata_ptr - outdata;
	    
	    if (!pof_flag) {
			fseek(fin, 0, SEEK_END);
		    filesize = (unsigned long)ftell(fin);
		    wad_dir[wad_entries].size = filesize + 4;
		    
			fseek(fin, 0, SEEK_SET);
			fread(outdata_ptr, 1, filesize, fin);
			
			// Pad MCU binary up to 48kB - 4 bytes (for CRC)
			memset(outdata_ptr + filesize, 0, 0xC000 - filesize - 4);
			
			filesize = 0xC000 - 4;
		} else {
			fseek(fin, 0x8D, SEEK_SET);
			fread(&filesize, 1, 2, fin);
			filesize = (filesize >> 8) + (filesize << 8);
			if (filesize & 1) {
				fclose(fin);
				printf("POF data size isn't an even number of bytes.'\n", filename);
				return 1;	
			}
		
			fseek(fin, 0x9C, SEEK_SET);
			fread(outdata_ptr, 1, filesize, fin);
			
			// Flip bits
			for (c = 0; c < filesize; c++) {
				unsigned char byte = outdata_ptr[c];
				byte = ((byte & 0xF0)>>4) | ((byte & 0x0F)<<4);	// 76543210 -> 32107654
				byte = ((byte & 0xCC)>>2) | ((byte & 0x33)<<2);	// 32107654 -> 10325476
				byte = ((byte & 0xAA)>>1) | ((byte & 0x55)<<1);	// 10325476 -> 01234567
				outdata_ptr[c] = byte;
			}
			
			// Flip bytes
			for (c = 0; c < filesize; c += 2) {
				unsigned char temp = outdata_ptr[c];
				outdata_ptr[c] = outdata_ptr[c + 1];
				outdata_ptr[c + 1] = temp;
			}
		}
		
		wad_dir[wad_entries].size = filesize + 4;
		
		crc = CRC32(outdata_ptr, filesize);
		
		if ((mode) && (!pof_flag)) {
			printf("Production test mode, MCAP CRC invalidated\n");
			crc = 0;	// Write invalid CRC on purpose to force customer to update on first run
		}
		outdata_ptr += filesize;
		
		memcpy(outdata_ptr, &crc, 4);
		outdata_ptr += 4;
		
		if (!pof_flag) {
			FILE * fout_lump = fopen("MCAP_lump.bin", "wb");
			fwrite(outdata_ptr - 4 - filesize, 1, filesize + 4, fout_lump);
			fclose(fout_lump);
		}
		
		printf("Added #%u %s lump from %s (%lu bytes, CRC32 %08lX)\n", wad_entries, desc, filename, filesize + 4, crc);
	}
	
	fclose(fin);
	
	wad_entries++;
	
	return 0;
}

int addlumppatch(char * const dirname, char * const filename) {
	unsigned short word;
	unsigned char record_type;
	unsigned char * outdata_ptr_start;	
	unsigned long datasize;
	unsigned long crc;
	precord_t precord;
	char path[1024];
	char lumpname[16];
	FILE * fin;
	
	strcpy(path, dirname);
	strcat(path, "\\");
	strcat(path, filename);
	
	strncpy(lumpname, filename, 8);
	lumpname[8] = 0;
	
	strncpy(wad_dir[wad_entries].name, lumpname, 8);
	
	fin = fopen(path, "rb");
	if (fin == NULL) {
		printf("%s can't be opened. %lu\n", path, errno);
		return 1;
	} else {
	    wad_dir[wad_entries].start_ptr = outdata_ptr - outdata;
			
		fread(&word, 1, sizeof(word), fin);
		if (word != 0x1489) {
			printf("Wrong magic word in %s.\n", path);
			fclose(fin);
			return 1;
		}
		
		outdata_ptr_start = outdata_ptr;
	
		while (fread(&precord, 1, sizeof(precord_t), fin)) {
			if (precord.record_type == 0x81) {
				// 0x81: Code record
				//printf("P - Start:%06lX Length:%04X\n", precord.start_address, precord.length);
				
				precord.start_address -= 0xC00000;
				memcpy(outdata_ptr, &precord.start_address, 4);
				outdata_ptr += 4;
				memcpy(outdata_ptr, &precord.length, 2);
				outdata_ptr += 2;
				fread(outdata_ptr, 1, precord.length, fin);
				outdata_ptr += precord.length;
			} else if (precord.record_type == 0x00) {
				// 0x00: EOF
				break;
			} else  {
				printf("Unknown record type %02X.\n", precord.record_type);
				fclose(fin);
				return 1;
			}
		}
		
		// EOF
		precord.start_address = 0xFFFFFFFF;
		memcpy(outdata_ptr, &precord.start_address, 4);
		outdata_ptr += 4;
		
		datasize = outdata_ptr - outdata_ptr_start;
	    wad_dir[wad_entries].size = datasize + 4;
		crc = CRC32(outdata_ptr_start, datasize);
		
		memcpy(outdata_ptr, &crc, 4);
		outdata_ptr += 4;
		
		printf("Added #%u %s patch lump from %s (%lu bytes, CRC32 %08lX)\n", wad_entries, lumpname, path, datasize + 4, crc);
	}
	
	fclose(fin);
	
	wad_entries++;
	
	return 0;
}

int main(int argc, char *argv[]) {
	wadheader_t wad_header = { {'I', 'W', 'A', 'D'}, 0, sizeof(wadheader_t) };
	unsigned int c;
	FILE * fout;

	if ((sizeof(unsigned char) != 1) ||
		(sizeof(unsigned short) != 2) ||
		(sizeof(unsigned long) != 4)) {
		puts("Type incompatibility error.\n");
		return 1;
	}
	
	if (argc != 6) {
		puts("Usage: makeupdate mcufile poffile pfilesdir outfile mode\n");
		return 1;
	}
	
	mode = atoi(argv[5]);
	
	// Allocate memory for WAD file
	outdata = (unsigned char *)malloc(0x100000);	// Max 1MB should be enough
	if (outdata == NULL) {
		puts("Malloc failed.\n");
		return 1;
	}
	outdata_ptr = outdata;
	
	// Handle MCU update file
	if (addlumpbin(argv[1], "MCU app", 0)) {
		free(outdata);
		return 1;
	}
	if (mode != 2) {
		// Handle CPLD update file
		if (addlumpbin(argv[2], "CPLD bitstream", 1)) {
			free(outdata);
			return 1;
		}
	
		// Handle Patch update files
	    DIR *dir;
	    struct dirent *dirp;
	    dir = opendir(argv[3]);
	    //chdir(argv[3]);
	    while ((dirp = readdir(dir)) != NULL){
	        if (strstr(dirp->d_name, ".p") != NULL) {
	            //printf("%s %s\n", "FILE", dirp->d_name);
	            addlumppatch(argv[3], dirp->d_name);
	        }
	    }
	    //chdir("..");
	    closedir(dir);
	}
	
	fout = fopen(argv[4], "wb");
	
	wad_header.entries = wad_entries;	// Update header with number of directory entries
	fwrite(&wad_header, 1, sizeof(wad_header), fout);	// Write header
	// Adjust data start pointers according to directory size
	unsigned int dir_size = sizeof(waddir_t) * wad_entries;
	for (c = 0; c < wad_entries; c++) {
		wad_dir[c].start_ptr += (sizeof(wadheader_t) + dir_size);
	}
	fwrite(&wad_dir, 1, dir_size, fout);	// Write directory
	fwrite(outdata, 1, outdata_ptr - outdata, fout);	// Write lump data
	
	printf("Generated %s OK.\n", argv[4]);
	
	free(outdata);

	return 0;
}

