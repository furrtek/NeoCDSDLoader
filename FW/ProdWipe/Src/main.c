/*
 * Copyright (C) 2020 Sean Gonsalves
 *
 * Neo CD SD Loader wiper firmware
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
#include "init.h"
#include "flash.h"
#include "cpld_comm.h"
#include "leds.h"
#ifdef STANDALONE
#include "usb_device.h"
#endif

I2S_HandleTypeDef hi2s1;

#ifdef STANDALONE
volatile FIFO RX_FIFO = {.head=0, .tail=0};		// VCP FIFO
#endif
uint32_t current_mode = MODE_RUN;

char buffer_temp[512];

int main(void) {
	// Reset of all peripherals, initializes the Flash interface and the Systick.
	HAL_Init();

	SystemClock_Config();	// The bootloader already did this

	MX_GPIO_Init();
#ifdef STANDALONE
	MX_USB_DEVICE_Init();
#else
	__HAL_RCC_USB_OTG_FS_CLK_ENABLE();
#endif

	RESET_LOW	// Keep the console in reset until everything is good to go

	__TIM2_CLK_ENABLE();
	s_TimerInstance.Instance = TIM2;
	s_TimerInstance.Init.Prescaler = 96;
	s_TimerInstance.Init.CounterMode = TIM_COUNTERMODE_UP;
	s_TimerInstance.Init.Period = 100000;
	s_TimerInstance.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	s_TimerInstance.Init.RepetitionCounter = 0;
	HAL_TIM_Base_Init(&s_TimerInstance);
	HAL_TIM_Base_Start(&s_TimerInstance);

	SetMode(MODE_MCU);

	// Blink yellow LED fast to say hello
	for (uint32_t c = 0; c < 5; c++) {
		setLED(LED_YELLOW);
		LL_mDelay(150);
		setLED(LED_OFF);
		LL_mDelay(150);
	}

	// Erase flash
	EraseFlash();
	LL_mDelay(1000);

	// Blink green LED fast to say erase ok
	for (uint32_t c = 0; c < 5; c++) {
		setLED(LED_GREEN);
		LL_mDelay(75);
		setLED(LED_OFF);
		LL_mDelay(75);
	}

	SetRunStock(1);

	// VCP and BIOS update stuff
#ifdef STANDALONE
	while (RX_FIFO.head != RX_FIFO.tail) {
		// Process one byte from the VCP RX FIFO
		uint8_t byte = RX_FIFO.data[RX_FIFO.tail];
		RX_FIFO.tail = FIFO_INCR(RX_FIFO.tail);

		if (byte == 'w') {
		}
	}
#endif
}

void Error_Handler(void) {
}
