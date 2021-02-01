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

#define SYSMEM_ADDRESS (uint32_t)0x00100000		// RM0431 page 56

#define VERSION_MAJOR 0
#define VERSION_MINOR 8

#define MAX_FILES 200		// Must NOT go over 253. 254 and 255 are special cases, see _CODE below.
#define MAX_FILE_NAME 256
#define MAX_FILE_NAME_STR "256"

#define BG_CODE 255
#define EXCEED_CODE 254

#define CUSTOM_BG_FILENAME "bg.bmp"

#define MODE_RUN 0
#define MODE_MCU 1

#define MODE_NULL 0
#define MODE_DATA 1
#define MODE_AUDIO 2

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

typedef struct {
	uint32_t index;
	uint8_t data[64];
} cmd_buffer_t;

// bwbuffers must be at least (1024) bytes in size for the cue sheet files parsing
#define BWBUFFER_SIZE_B 6820
#define BWBUFFER_SIZE_W (BWBUFFER_SIZE_B>>1)

#if (BWBUFFER_SIZE_B < (MAX_GAMES*34+2))
#error BWBUFFER_SIZE_B must be at least (MAX_ISO_FILES * 34 + 2) bytes for the file list replies
#endif

typedef union {
	uint8_t byte[BWBUFFER_SIZE_B];
	uint16_t word[BWBUFFER_SIZE_W];
} bwbuffer_t;

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

extern char buffer_temp[512];
extern volatile FIFO RX_FIFO;
extern I2S_HandleTypeDef hi2s1;
extern volatile uint32_t flag_console_write, flag_exec, flag_refill;
extern uint32_t current_mode;
extern uint32_t card_type;
extern uint32_t audio_pos, audio_start, audio_stop, cdda_loop;
extern bwbuffer_t* reply_buff_ptr;
extern char buffer_str[];
extern char file_list[MAX_FILES][MAX_FILE_NAME + 1];
extern uint32_t game_index;
extern uint32_t cdda_pause;
extern uint32_t storing_mode, storing_count, storing_max, storing_error;
extern uint32_t reply_idx;
extern uint8_t stat_card_inserted;	// 1:Card inserted, 0:Card absent
extern uint8_t stat_card_event;		// 1:Card was removed, 0:Card didn't move
extern uint8_t stat_operation;		// 0:Normal power-on
extern uint32_t CD_LBA, prev_CD_LBA;
extern bwbuffer_t reply_buff_a, reply_buff_b;
extern uint32_t data_sector_size, audio_track_format;
extern uint32_t data_mode;

void Error_Handler(void);
void delay_us(uint32_t delay);

#endif /* __MAIN_H */

