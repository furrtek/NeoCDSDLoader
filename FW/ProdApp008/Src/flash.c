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

#include "main.h"
#include "flash.h"
#include "cpld_comm.h"

// The flash chip requires the unlock sequence for EACH word to be programmed
// The flash address needs to be set up completely for EACH word
// Write loop 7.3ms total for 128 bytes = 57us/byte = 17.1kB/s

void SetFlashAddress(const uint32_t addr) {
	SetMCUData(0);					// Make sure to set RUN_STOCK = 0
	CPLD3_HIGH
	TickMCUCLK();					// Reset CPLD address load state
	CPLD3_LOW

	SetMCUData(addr & 0xFFFF);
	TickMCUCLK();					// Set address 16 lower bits
	SetMCUData(addr >> 16);
	TickMCUCLK();					// Set address 2 higher bits
}

void CmdFlash(const uint32_t cmd) {
	CPLD2_LOW						// Make sure CPLD is all inputs
	SetMCUBusOutput();
	WriteFlash(0x05555, 0xAA);
	WriteFlash(0x02AAA, 0x55);
	WriteFlash(0x05555, cmd);
}

void WriteFlash(const uint32_t addr, const uint16_t data) {
	// The MCU_D port must already be set to output here
	SetFlashAddress(addr);
	SetMCUData(data);

	CPLD1_HIGH						// Write !
	delay_us(2);
	CPLD1_LOW
	delay_us(2);
}

uint16_t ReadMem(const uint32_t addr, const memtype_t type) {
	uint16_t data;

	SetMCUBusOutput();
	SetFlashAddress(addr);

	SetMCUBusInput();

	if (type == MEMTYPE_FLASH)
		CPLD4_LOW		// Select flash
	else
		CPLD4_HIGH		// Select console system ROM
	CPLD2_HIGH			// Read enable

	delay_us(2);
	data = GPIOB->IDR;	// Get word

	CPLD2_LOW			// Read disable

	return data;
}

// Returns 0 on success
uint32_t EraseFlash() {
	CmdFlash(FLASH_ERASE);
	CmdFlash(FLASH_CHIP);

	// Read from 0x00000 to get DQ7
	uint32_t timeout = 20;
	while (!(ReadMem(0x00000, MEMTYPE_FLASH) & 0b10000000) && (--timeout)) {
		LL_mDelay(10);
	}

	return timeout ? 0 : 1;
}
