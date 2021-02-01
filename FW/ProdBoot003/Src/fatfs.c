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

#include "fatfs.h"

uint8_t retUSER;    // Return value for USER
char USERPath[4];   // USER logical drive path
FATFS USERFatFS;    // File system object for USER logical drive
FIL USERFile;       // File object for USER

void MX_FATFS_Init(void) {
	retUSER = FATFS_LinkDriver(&USER_Driver, USERPath);
}

DWORD get_fattime(void) {
	return 0;
}
