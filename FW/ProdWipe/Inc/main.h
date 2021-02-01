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

#ifndef __MAIN_H
#define __MAIN_H

#include "stm32f7xx_hal.h"
#include "stm32f7xx_ll_rcc.h"
#include "stm32f7xx_ll_bus.h"
#include "stm32f7xx_ll_system.h"
#include "stm32f7xx_ll_exti.h"
#include "stm32f7xx_ll_cortex.h"
#include "stm32f7xx_ll_utils.h"
#include "stm32f7xx_ll_pwr.h"
#include "stm32f7xx_ll_dma.h"
#include "stm32f7xx_ll_spi.h"
#include "stm32f7xx.h"
#include "stm32f7xx_ll_gpio.h"

#define SYSMEM_ADDRESS (uint32_t)0x00100000		// RM0431 page 56

#define MODE_RUN 0
#define MODE_MCU 1

#define CPLD0_HIGH LL_GPIO_SetOutputPin(GPIOC, LL_GPIO_PIN_6);
#define CPLD0_LOW LL_GPIO_ResetOutputPin(GPIOC, LL_GPIO_PIN_6);

#define CPLD1_HIGH LL_GPIO_SetOutputPin(GPIOC, LL_GPIO_PIN_7);
#define CPLD1_LOW LL_GPIO_ResetOutputPin(GPIOC, LL_GPIO_PIN_7);

#define CPLD2_HIGH LL_GPIO_SetOutputPin(GPIOC, LL_GPIO_PIN_8);
#define CPLD2_LOW LL_GPIO_ResetOutputPin(GPIOC, LL_GPIO_PIN_8);

#define CPLD3_HIGH LL_GPIO_SetOutputPin(GPIOA, LL_GPIO_PIN_8);
#define CPLD3_LOW LL_GPIO_ResetOutputPin(GPIOA, LL_GPIO_PIN_8);

#define CPLD4_HIGH LL_GPIO_SetOutputPin(GPIOC, LL_GPIO_PIN_11);
#define CPLD4_LOW LL_GPIO_ResetOutputPin(GPIOC, LL_GPIO_PIN_11);

#define MCUCLK_HIGH LL_GPIO_SetOutputPin(GPIOC, LL_GPIO_PIN_9);
#define MCUCLK_LOW LL_GPIO_ResetOutputPin(GPIOC, LL_GPIO_PIN_9);

#define RESET_FLOAT LL_GPIO_SetOutputPin(GPIOC, LL_GPIO_PIN_3);
#define RESET_LOW LL_GPIO_ResetOutputPin(GPIOC, LL_GPIO_PIN_3);

#define FIFO_SIZE 256  // Must be 2^N

#define FIFO_INCR(x) (((x)+1)&((FIFO_SIZE)-1))

typedef struct FIFO {
	uint32_t head;
	uint32_t tail;
	uint8_t data[FIFO_SIZE];
} FIFO;

extern char buffer_temp[512];
extern volatile FIFO RX_FIFO;
extern I2S_HandleTypeDef hi2s1;
extern uint32_t current_mode;

void Error_Handler(void);
void delay_us(uint32_t delay);

#endif /* __MAIN_H */

