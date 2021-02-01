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

#include "init.h"

void MX_GPIO_Init(void) {
	LL_GPIO_InitTypeDef GPIO_InitStruct = {0};

	LL_AHB1_GRP1_EnableClock(LL_AHB1_GRP1_PERIPH_GPIOH |
								LL_AHB1_GRP1_PERIPH_GPIOA |
								LL_AHB1_GRP1_PERIPH_GPIOB |
								LL_AHB1_GRP1_PERIPH_GPIOC |
								LL_AHB1_GRP1_PERIPH_GPIOD
								);

	LL_AHB1_GRP1_EnableClock(LL_AHB1_GRP1_PERIPH_DMA1 | LL_AHB1_GRP1_PERIPH_DMA2);

	LL_GPIO_ResetOutputPin(GPIOC, LL_GPIO_PIN_6 |		// CPLD0
									LL_GPIO_PIN_7 |		// CPLD1
									LL_GPIO_PIN_8 |		// CPLD2
									LL_GPIO_PIN_9 |		// MCUCLK
									LL_GPIO_PIN_11		// CPLD4
	);

	LL_GPIO_ResetOutputPin(GPIOA, LL_GPIO_PIN_4 | LL_GPIO_PIN_5 | // I2SWS, I2SCK
									LL_GPIO_PIN_7 |		// I2SDO
									LL_GPIO_PIN_8 |		// CPLD3
									LL_GPIO_PIN_13 |	// JTAG TDI
									LL_GPIO_PIN_15		// JTAG TCK
	);

	LL_GPIO_SetOutputPin(GPIOA, LL_GPIO_PIN_10);		// JTAG TMS

	LL_GPIO_SetOutputPin(GPIOC, LL_GPIO_PIN_3 |			// nRESET
									LL_GPIO_PIN_13 |	// LEDs off
									LL_GPIO_PIN_14 |
									LL_GPIO_PIN_15
	);

	// SD card nSS high
	LL_GPIO_SetOutputPin(GPIOC, LL_GPIO_PIN_0);

	// PA4: I2SWS
	GPIO_InitStruct.Pin = LL_GPIO_PIN_4;
	GPIO_InitStruct.Mode = LL_GPIO_MODE_OUTPUT;
	GPIO_InitStruct.Speed = LL_GPIO_SPEED_FREQ_VERY_HIGH;
	GPIO_InitStruct.OutputType = LL_GPIO_OUTPUT_PUSHPULL;
	GPIO_InitStruct.Pull = LL_GPIO_PULL_NO;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);
	// PA5: I2SCK
	GPIO_InitStruct.Pin = LL_GPIO_PIN_5;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);
	// PA7: I2SDO
	GPIO_InitStruct.Pin = LL_GPIO_PIN_7;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);
	// PC4: I2SMCK - Unused

	// PC9: MCUCLK
	GPIO_InitStruct.Pin = LL_GPIO_PIN_9;
	GPIO_InitStruct.Mode = LL_GPIO_MODE_OUTPUT;
	GPIO_InitStruct.Speed = LL_GPIO_SPEED_FREQ_HIGH;
	GPIO_InitStruct.OutputType = LL_GPIO_OUTPUT_PUSHPULL;
	GPIO_InitStruct.Pull = LL_GPIO_PULL_NO;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);
	// PC11: CPLD4
	GPIO_InitStruct.Pin = LL_GPIO_PIN_11;
	GPIO_InitStruct.Mode = LL_GPIO_MODE_INPUT;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	// PB0: MCU_Dx
	GPIO_InitStruct.Pin = LL_GPIO_PIN_0;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB1
	GPIO_InitStruct.Pin = LL_GPIO_PIN_1;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB2
	GPIO_InitStruct.Pin = LL_GPIO_PIN_2;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB3
	GPIO_InitStruct.Pin = LL_GPIO_PIN_3;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB4
	GPIO_InitStruct.Pin = LL_GPIO_PIN_4;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB5
	GPIO_InitStruct.Pin = LL_GPIO_PIN_5;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB6
	GPIO_InitStruct.Pin = LL_GPIO_PIN_6;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB7
	GPIO_InitStruct.Pin = LL_GPIO_PIN_7;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB8
	GPIO_InitStruct.Pin = LL_GPIO_PIN_8;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB9
	GPIO_InitStruct.Pin = LL_GPIO_PIN_9;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB10
	GPIO_InitStruct.Pin = LL_GPIO_PIN_10;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB11
	GPIO_InitStruct.Pin = LL_GPIO_PIN_11;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB12
	GPIO_InitStruct.Pin = LL_GPIO_PIN_12;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB13
	GPIO_InitStruct.Pin = LL_GPIO_PIN_13;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB14
	GPIO_InitStruct.Pin = LL_GPIO_PIN_14;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	// PB15
	GPIO_InitStruct.Pin = LL_GPIO_PIN_15;
	LL_GPIO_Init(GPIOB, &GPIO_InitStruct);

	// PC3: nRESET
	GPIO_InitStruct.Pin = LL_GPIO_PIN_3;
	GPIO_InitStruct.Mode = LL_GPIO_MODE_OUTPUT;
	GPIO_InitStruct.Speed = LL_GPIO_SPEED_FREQ_HIGH;
	GPIO_InitStruct.OutputType = LL_GPIO_OUTPUT_OPENDRAIN;
	GPIO_InitStruct.Pull = LL_GPIO_PULL_NO;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	// PA0: nCD
	GPIO_InitStruct.Pin = LL_GPIO_PIN_0;
	GPIO_InitStruct.Mode = LL_GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = LL_GPIO_PULL_UP;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);
	// PC0: nSS
	GPIO_InitStruct.Pin = LL_GPIO_PIN_0;
	GPIO_InitStruct.Mode = LL_GPIO_MODE_OUTPUT;
	GPIO_InitStruct.Speed = LL_GPIO_SPEED_FREQ_MEDIUM;
	GPIO_InitStruct.OutputType = LL_GPIO_OUTPUT_PUSHPULL;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	// PA8: CPLD3
	GPIO_InitStruct.Pin = LL_GPIO_PIN_8;
	GPIO_InitStruct.Pull = LL_GPIO_PULL_NO;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);
	// PC8: CPLD2
	GPIO_InitStruct.Pin = LL_GPIO_PIN_8;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	// PC6: CPLD0
	GPIO_InitStruct.Pin = LL_GPIO_PIN_6;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);
	// PC7: CPLD1
	GPIO_InitStruct.Pin = LL_GPIO_PIN_7;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	// PC13: Red LED
	GPIO_InitStruct.Pin = LL_GPIO_PIN_13;
	GPIO_InitStruct.Speed = LL_GPIO_SPEED_FREQ_LOW;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);
	// PC14: Green LED
	GPIO_InitStruct.Pin = LL_GPIO_PIN_14;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);
	// PC15: Blue LED
	GPIO_InitStruct.Pin = LL_GPIO_PIN_15;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	// PA10: JTAG TMS
	GPIO_InitStruct.Pin = LL_GPIO_PIN_10;
	GPIO_InitStruct.Mode = LL_GPIO_MODE_OUTPUT;
	GPIO_InitStruct.Speed = LL_GPIO_SPEED_FREQ_HIGH;
	GPIO_InitStruct.OutputType = LL_GPIO_OUTPUT_PUSHPULL;
	GPIO_InitStruct.Pull = LL_GPIO_PULL_NO;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);
	// PA13: JTAG TDI
	GPIO_InitStruct.Pin = LL_GPIO_PIN_13;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);
	// PA15: JTAG TCK
	GPIO_InitStruct.Pin = LL_GPIO_PIN_15;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);
	// PA14: JTAG TDO
	GPIO_InitStruct.Pin = LL_GPIO_PIN_14;
	GPIO_InitStruct.Mode = LL_GPIO_MODE_INPUT;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);
}

