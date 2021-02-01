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

#include "ff.h"

#define ADDR_APP (uint32_t)0x08004000	// Sectors 1~3 are for app
#define ADDR_END (uint32_t)0x08010000	// End of user flash
#define ADDR_CRC (uint32_t)0x0800FFFC	// Last dword
#define ADDR_SYSMEM (uint32_t)0x00100000	// RM0431 page 56
#define APP_SIZE (uint32_t)(ADDR_END - ADDR_APP)
#define FLASH_SIZE 65536		// RM0431 page 68

#define FILENAME_FORCED "NSDLZZZZ.WAD"

#define BK_RED_RED_RED			(uint32_t[]){LED_RED,	LED_RED,	LED_RED}
#define BK_RED_RED_YELLOW		(uint32_t[]){LED_RED,	LED_RED,	LED_YELLOW}
#define BK_RED_YELLOW_RED		(uint32_t[]){LED_RED,	LED_YELLOW,	LED_RED}
#define BK_RED_YELLOW_YELLOW	(uint32_t[]){LED_RED,	LED_YELLOW, LED_YELLOW}
#define BK_YELLOW_RED_RED		(uint32_t[]){LED_YELLOW,LED_RED, 	LED_RED}
#define BK_YELLOW_RED_YELLOW	(uint32_t[]){LED_YELLOW,LED_RED, 	LED_YELLOW}
#define BK_YELLOW_YELLOW_RED	(uint32_t[]){LED_YELLOW,LED_YELLOW, LED_RED}
#define BK_GREEN_GREEN_GREEN	(uint32_t[]){LED_GREEN,	LED_GREEN, 	LED_GREEN}

typedef void (*function_ptr_t)(void);

typedef struct __attribute__((__packed__)) {
	uint8_t magic[4];
	uint32_t entries;
	uint32_t dir_ptr;
} wad_header_t;

typedef struct __attribute__((__packed__)) {
	uint32_t start_ptr;
	uint32_t size;
	uint8_t name[8];
} wad_dir_t;

extern uint32_t card_type;

void DMAResetRegisters(DMA_Stream_TypeDef * tmp);
void Error_Handler(void);

#endif /* __MAIN_H */

