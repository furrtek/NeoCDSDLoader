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

#ifndef __FLASH_H__
#define __FLASH_H__

#define FLASH_ID_ENTRY 0x90
#define FLASH_ID_EXIT 0xF0
#define FLASH_ERASE 0x80
#define FLASH_CHIP 0x10
#define FLASH_PROGRAM 0xA0

typedef enum {
	MEMTYPE_FLASH,
	MEMTYPE_CONSOLE
} memtype_t;

void SetFlashAddress(const uint32_t addr);
void CmdFlash(const uint32_t cmd);
void WriteFlash(const uint32_t addr, const uint16_t data);
uint16_t ReadMem(const uint32_t addr, const memtype_t type);
uint32_t EraseFlash();

#endif /* __FLASH_H__ */
