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
#include "util.h"
#include "cpld_comm.h"
#include "usbd_cdc_if.h"

TIM_HandleTypeDef s_TimerInstance;

void DMAResetRegisters(DMA_Stream_TypeDef * tmp) {
	LL_DMA_WriteReg(tmp, CR, 0U);	// Configuration register
	LL_DMA_WriteReg(tmp, NDTR, 0U);	// Remaining bytes register
	LL_DMA_WriteReg(tmp, PAR, 0U);	// Peripheral address register
	LL_DMA_WriteReg(tmp, M0AR, 0U);	// Memory address register
	LL_DMA_WriteReg(tmp, M1AR, 0U);	// Memory address register
	LL_DMA_WriteReg(tmp, FCR, 0x00000021U);	// FIFO control register
}

void SetMode(const uint32_t mode) {
	if (mode == MODE_RUN) {
		SetMCUBusInput();
		LL_GPIO_SetPinMode(GPIOC, LL_GPIO_PIN_7, LL_GPIO_MODE_INPUT);	// CPLD1
		LL_GPIO_SetPinMode(GPIOA, LL_GPIO_PIN_8, LL_GPIO_MODE_INPUT);	// CPLD3
		LL_GPIO_SetPinMode(GPIOC, LL_GPIO_PIN_11, LL_GPIO_MODE_INPUT);	// CPLD4
		CPLD0_LOW
		CPLD2_LOW
		RESET_FLOAT
#ifdef STANDALONE
		CDCPrint("RUN mode");
#endif
	} else if (mode == MODE_MCU) {
		RESET_LOW
		LL_GPIO_SetPinMode(GPIOC, LL_GPIO_PIN_7, LL_GPIO_MODE_OUTPUT);	// CPLD1
		LL_GPIO_SetPinMode(GPIOA, LL_GPIO_PIN_8, LL_GPIO_MODE_OUTPUT);	// CPLD3
		LL_GPIO_SetPinMode(GPIOC, LL_GPIO_PIN_11, LL_GPIO_MODE_OUTPUT);	// CPLD4
		CPLD0_HIGH
		CPLD2_LOW
		CPLD4_LOW
#ifdef STANDALONE
		CDCPrint("MCU mode");
#endif
	}
	current_mode = mode;
}

#ifdef STANDALONE
void DebugPrint(const char * const text, const uint32_t value) {
	sprintf(buffer_temp, "%s: %lu", text, value);
	CDCPrint(buffer_temp);
}

void CDCPrint(char * const str) {
	char buffer[256];
	char * local_ptr = str;
	uint32_t i = 0;

	while (*local_ptr && (i < 253))
		buffer[i++] = *local_ptr++;
	buffer[i++] = '\r';
	buffer[i++] = '\n';

	CDC_Transmit_FS((uint8_t*)buffer, i);

	LL_mDelay(5);	// Keep this or the terminal will skip lines :(
}

void CDCPuts(uint8_t c) {
	uint8_t buffer = c;
	CDC_Transmit_FS(&buffer, 1);
}
#endif

void delay_us(uint32_t delay) {
	__HAL_TIM_SET_COUNTER(&s_TimerInstance, 0);
	while (__HAL_TIM_GET_COUNTER(&s_TimerInstance) < delay) { };
}

uint32_t BCDtoHex(uint8_t bcd) {
	return ((bcd >> 4) * 10) + (bcd & 0x0F);
}
