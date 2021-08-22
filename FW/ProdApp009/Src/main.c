/*
 * Copyright (C) 2020 Sean Gonsalves
 *
 * Neo CD SD Loader application firmware V0.09
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
#include "fatfs.h"
#include "util.h"
#include "init.h"
#include "flash.h"
#include "sd.h"
#include "cpld_comm.h"
#include "update.h"
#include "console_cmd.h"
#include "jtag.h"
#include "cdda.h"
#include "leds.h"
#include "files.h"
#ifdef STANDALONE
#include "usb_device.h"
#include "xmodem.h"
#endif

I2S_HandleTypeDef hi2s1;

#ifdef STANDALONE
volatile FIFO RX_FIFO = { .head = 0, .tail = 0 };	// VCP FIFO
#endif
volatile uint32_t flag_console_write = 0, flag_exec = 0, flag_refill = 0;
uint32_t current_mode = MODE_RUN;
FATFS SDFatFs;
uint32_t card_type = 0;

char file_list[MAX_FILES][MAX_FILE_NAME + 1];	// + /0

char buffer_temp[512];
uint16_t buffer_write[BUFFER_WRITE_SIZE];
FIL fil_data;
uint32_t reply_idx = 0;
bwbuffer_t reply_buff_a, reply_buff_b;
bwbuffer_t* reply_buff_ptr = &reply_buff_a;
uint32_t game_index = 0;
uint32_t audio_pos = 0, audio_start = 0, audio_stop = 0, cdda_loop = 0, cdda_pause;
uint32_t storing_mode = 0, storing_word_count = 0, buffer_write_count, storing_word_max = 0, storing_error = 0;
uint8_t stat_card_inserted = 0;	// 1:Card inserted, 0:Card absent
uint8_t stat_card_event = 0;	// 1:Card presence changed, 0:Card didn't move
uint32_t CD_LBA, prev_CD_LBA = -1;
uint32_t data_sector_size, audio_track_format;
uint32_t data_mode = MODE_NULL;
uint16_t current_ngh;

void store_write_buffer() {
	UINT num;

	setLED(led_color_load);

	FRESULT fr = f_write(&fil_data, buffer_write, buffer_write_count<<1, &num);
	if (num != (buffer_write_count<<1) || fr != FR_OK)
		storing_error = 1;
	buffer_write_count = 0;

	setLED(led_color_idle);
}

int main(void) {
	uint8_t prev_stat_card_inserted;

	// Reset of all peripherals, initializes the Flash interface and the Systick.
	HAL_Init();

	SystemClock_Config();	// The bootloader already did this

	MX_GPIO_Init();
	MX_I2S1_Init();
	MX_SPI2_Init();
	MX_FATFS_Init();
#ifdef STANDALONE
	MX_USB_DEVICE_Init();
#else
	__HAL_RCC_USB_OTG_FS_CLK_ENABLE();
#endif

	RESET_LOW	// Keep the console in reset until everything is good to go

	// Setup TIM2 for delay_us
	__TIM2_CLK_ENABLE();
	s_TimerInstance.Instance = TIM2;
	s_TimerInstance.Init.Prescaler = 96;
	s_TimerInstance.Init.CounterMode = TIM_COUNTERMODE_UP;
	s_TimerInstance.Init.Period = 100000;
	s_TimerInstance.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	s_TimerInstance.Init.RepetitionCounter = 0;
	HAL_TIM_Base_Init(&s_TimerInstance);
	HAL_TIM_Base_Start(&s_TimerInstance);

	// Interrupt on CPLD1 (PC7)
	LL_AHB1_GRP1_EnableClock(LL_APB2_GRP1_PERIPH_SYSCFG);
	LL_SYSCFG_SetEXTISource(LL_SYSCFG_EXTI_PORTC, LL_SYSCFG_EXTI_LINE7);

	LL_EXTI_InitTypeDef EXTI7_init;
	EXTI7_init.Line_0_31 = LL_EXTI_LINE_7;
	EXTI7_init.LineCommand = ENABLE;
	EXTI7_init.Mode = LL_EXTI_MODE_IT;
	EXTI7_init.Trigger = LL_EXTI_TRIGGER_RISING;
	LL_EXTI_Init(&EXTI7_init);

	// Interrupt on CPLD3 (PA8)
	LL_SYSCFG_SetEXTISource(LL_SYSCFG_EXTI_PORTA, LL_SYSCFG_EXTI_LINE8);

	LL_EXTI_InitTypeDef EXTI8_init;
	EXTI8_init.Line_0_31 = LL_EXTI_LINE_8;
	EXTI8_init.LineCommand = ENABLE;
	EXTI8_init.Mode = LL_EXTI_MODE_IT;
	EXTI8_init.Trigger = LL_EXTI_TRIGGER_RISING;
	LL_EXTI_Init(&EXTI8_init);

	NVIC_SetPriority(EXTI9_5_IRQn, 0);
	NVIC_EnableIRQ(EXTI9_5_IRQn);

	// Interrupt on DMA2 Stream 3 for CDDA buffer refill
	NVIC_SetPriority(DMA2_Stream3_IRQn, 0);
	NVIC_EnableIRQ(DMA2_Stream3_IRQn);

	CDDA_Stop();
	SetMode(MODE_MCU);

	// Blink green LED fast to say hello
	for (uint32_t c = 0; c < 3; c++) {
		setLED(LED_GREEN);
		LL_mDelay(75);
		setLED(LED_OFF);
		LL_mDelay(75);
	}

#ifndef STANDALONE
	// Check bios flash validity
	// Check bios flash version
	// Check CPLD version
	if ((ReadMem(0x7FFFE >> 1, MEMTYPE_FLASH) != 0x600D) ||	// Require flash to end with 0x600D
	(ReadMem(0x19000 >> 1, MEMTYPE_FLASH) != 0x0009) ||		// Require menu version to be 00.09
	(JTAG_Code(JTAG_USERCODE) != 0x600D0003)) {				// Require CPLD version to be 00.03
		// Sum Ting Wong, an update is required
		SD_Init();
		f_mount(&SDFatFs, "0:", 1);

		// Try updating
		if (DoUpdate()) {
			// Update failed :(
			SetRunStock(0, 0);	// Let console run with stock bios, no patching, and disable SD loader
			RESET_FLOAT
			for (;;) {};
		}
	}
	// Run loader flash
	SetRunLoader();
#else
	SetRunLoader();
#endif

	prev_stat_card_inserted = (GPIOA->IDR & 1) ^ 1;

	while (1) {
		// Detect SD card insertion or removal
		stat_card_inserted = (GPIOA->IDR & 1) ^ 1;
		if (prev_stat_card_inserted != stat_card_inserted) {
			last_filetype_listed = FILE_TYPE_NONE;	// Make last file list invalid
			if (!prev_stat_card_inserted && stat_card_inserted) {
				stat_card_event = 1;
#ifdef STANDALONE
				CDCPrint("SD card inserted");
#endif
			} else {
				stat_card_event = 1;
#ifdef STANDALONE
				CDCPrint("SD card removed");
#endif
			}
		}
		prev_stat_card_inserted = stat_card_inserted;

		if (current_mode == MODE_RUN) {
			// Console is running

			if (flag_refill) {
				CDDA_Refill((flag_refill == 1) ? &cdda_buffer[0] : &cdda_buffer[4096], CDDA_BUFFER_HALF);
				flag_refill = 0;
			}

			if (flag_console_write) {
				// CPLD signaled that the console wrote a new word or byte

				uint16_t word = ReadCPLDData();

				if (storing_mode) {
					// Console-to-mcu data transfer mode, used for save RAM and state transfers
					// During this time, each transferred byte is ack'd to avoid cmd_fifo overruns
					// This mode is disabled when the transfer is finished or when a new command is received

					if (storing_word_count < storing_word_max) {
						// Store in BUFFER_WRITE_SIZE-byte buffer before doing f_write()
						buffer_write[buffer_write_count++] = word;
						storing_word_count++;
						if (buffer_write_count == BUFFER_WRITE_SIZE) {
							store_write_buffer();
#if 0
							DebugPrint("store_write_buffer", storing_word_count);
#endif
						}
					}

					if (storing_word_count == storing_word_max) {
						// Proper exit from storing_mode
						storing_mode = 0;
						// Write partially-filled buffer if needed
						if (buffer_write_count)
							store_write_buffer();
					}
				} else {
					// Normal command mode
					if (cmd_buffer.index < sizeof(cmd_buffer.data)) {
						cmd_buffer.data[cmd_buffer.index] = (uint8_t)(word >> 8);
						cmd_buffer.index++;
					}
				}

				flag_console_write = 0;
				TickMCUCLK();	// Ack byte received
			}

			if (flag_exec) {
				// CPLD signaled the console wants the last loaded command to be run
				ExecCmd();
			}
		}

		// VCP and BIOS update stuff
#ifdef STANDALONE
		// Try starting XMODEM RX transfer every 500ms
		if (xstate == STATE_XMODEM_RX_START) {
			LL_mDelay(500);
			CDCPuts(21);	// NACK
		}
		while (RX_FIFO.head != RX_FIFO.tail) {
			// Process one byte from the VCP RX FIFO
			uint8_t byte = RX_FIFO.data[RX_FIFO.tail];
			RX_FIFO.tail = FIFO_INCR(RX_FIFO.tail);

			HandleXModem(byte);

			if (xstate == STATE_IDLE) {
				if (byte == 'w') {
					RX_FIFO.tail = RX_FIFO.head;
					// Erase and re-program flash

					SetMode(MODE_MCU);
					CDCPrint("Flash erase");
					EraseFlash();
					CDCPrint("Now send XMODEM 128 checksum");

					XModemInit(STATE_XMODEM_RX_START);
				} else if (byte == 'r') {
					RX_FIFO.tail = RX_FIFO.head;
					// Readback system ROM flash

					SetMode(MODE_MCU);
					CDCPrint("Flash dump");

					memory_type = MEMTYPE_FLASH;
					XModemInit(STATE_XMODEM_TX_START);
				} else if (byte == 'd') {
					RX_FIFO.tail = RX_FIFO.head;
					// Dump console system ROM

					SetMode(MODE_MCU);
					CDCPrint("Console system ROM dump");

					memory_type = MEMTYPE_CONSOLE;
					XModemInit(STATE_XMODEM_TX_START);
				} else if (byte == 'g') {
					// Go ! RUN MODE
					RX_FIFO.tail = RX_FIFO.head;
					SetRunLoader();
				}
			} else if (xstate == STATE_XMODEM_RX_RUN) {
				XModemRX(byte);
			} else if (xstate == STATE_XMODEM_TX_RUN) {
				XModemTX(byte);
			}
		}
#endif
	}
}

void Error_Handler(void) {
}
