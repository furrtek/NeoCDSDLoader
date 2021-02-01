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

// Convert MS PAL palette files to NeoGeo color list

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
	unsigned char pdata[65536];
	unsigned char red, green, blue;
	unsigned short p, ngcolor;

	FILE * fin;
	FILE * fout;
	
	if (argc != 3) {
		puts("Usage: pal2db palfile binfile\n");
		return 1;
	}
	
	fin = fopen(argv[1], "rb");
	fout = fopen(argv[2], "wb");
	
	if ((fin == NULL) || (fout == NULL)) {
		puts("PAL2DB: One of the specified files can't be opened.\n");
		fclose(fin);
		fclose(fout);
		return 1;
	}
	
	fread(pdata, 1, 65536, fin);
	
	for (p = 0; p < 16; p++) {
		red = pdata[0x18 + (p << 2)] >> 3;
		green = pdata[0x18 + (p << 2) + 1] >> 3;
		blue = pdata[0x18 + (p << 2) + 2] >> 3;
		
		ngcolor = ((red >> 1) << 8) | ((green >> 1) << 4) | (blue >> 1) | ((red & 1) << 18) | ((green & 1) << 17) | ((blue & 1) << 16);
		
		// Flip bytes
		ngcolor = ((ngcolor & 0xFF) << 8) | (ngcolor >> 8);
		
		fwrite(&ngcolor, 1, 2, fout);
	}
	
	puts("PAL2DB: Done.");
	
	fclose(fin);
	fclose(fout);

	return 0;
}

