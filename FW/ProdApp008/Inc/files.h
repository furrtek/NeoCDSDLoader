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

#ifndef __FILES_H
#define __FILES_H

#include "main.h"

typedef enum {
	FILE_TYPE_NONE,
	FILE_TYPE_CUE,
	FILE_TYPE_SAV
} filetype_t;

extern filetype_t last_filetype_listed;

uint32_t ASCIICompare(char * const a, char * const b);
uint32_t search_ext(DIR * const dir_ptr, FILINFO * fno_ptr, char * const extension);
int32_t listfiles(filetype_t filetype);

#endif /* __FILES_H */
