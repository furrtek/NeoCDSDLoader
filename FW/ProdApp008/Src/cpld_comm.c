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
#include "init.h"
#include "util.h"
#include "flash.h"
#include "cpld_comm.h"
#include "jtag.h"

void TickMCUCLK() {
	MCUCLK_HIGH
	delay_us(1);
	MCUCLK_LOW
	delay_us(1);
}

void SetMCUData(const uint16_t data) {
	GPIOB->ODR = data;
}

uint16_t ReadCPLDData() {
	uint16_t data;

	SetMCUBusInput();
	CPLD2_HIGH						// Enter read mode
	delay_us(3);					// Was 2, increased to 3 in hope to solve CDDA command erroneously
	data = GPIOB->IDR;				// executed during CD sector loading - TODO: Not needed anymore ?
	delay_us(1);
	CPLD2_LOW						// Exit read mode

	return data;
}

void WriteCPLDData(uint16_t data) {
	CPLD2_LOW						// Make sure CPLD is in input mode. Shouldn't be needed
	SetMCUBusOutput();

	// TODO: Can this be done faster ?
	GPIOB->ODR = data;
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	MCUCLK_HIGH
	asm("nop");		// ~60ns
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	MCUCLK_LOW
	asm("nop");		// ~60ns
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");

	SetMCUBusInput();				// Shouldn't be needed
}

void SetMCUBusInput() {
	GPIOB->MODER = 0x00000000;		// 00 = Input mode
}

void SetMCUBusOutput() {
	GPIOB->MODER = 0x55555555;		// 01 = General purpose output mode
}

void SetRunStock(const uint16_t v) {
	SetMode(MODE_MCU);

#ifdef STANDALONE
	// Check bios flash validity
	DebugPrint("Menu magic", ReadMem(0x7FFFE >> 1, MEMTYPE_FLASH));
	// Check bios flash version
	DebugPrint("Menu version", ReadMem(0x19000 >> 1, MEMTYPE_FLASH));
	// Check CPLD version
	DebugPrint("CPLD USERCODE", JTAG_Code(JTAG_USERCODE));
#endif

	if (v)
		I2SOutputDisable();
	else
		I2SOutputEnable();

	SetMCUBusOutput();
	SetMCUData(v);					// Set RUN_STOCK
	CPLD3_HIGH
	TickMCUCLK();					// Reset CPLD state
	CPLD3_LOW
	SetMCUBusInput();				// Useless ?
	SetMode(MODE_RUN);
}
