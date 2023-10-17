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
#include "cpld_comm.h"
#include "stm32f7xx_it.h"

extern PCD_HandleTypeDef hpcd_USB_OTG_FS;

void NMI_Handler(void) { }

void HardFault_Handler(void) {
	while (1) {	}
}

void MemManage_Handler(void) {
	while (1) {	}
}

void BusFault_Handler(void) {
	while (1) {	}
}

void UsageFault_Handler(void) {
	while (1) {	}
}

void SVC_Handler(void) { }

void DebugMon_Handler(void) { }

void PendSV_Handler(void) { }

void SysTick_Handler(void) {
	HAL_IncTick();
}

extern uint32_t reply_idx;
extern bwbuffer_t* reply_buff_ptr;

#ifdef STANDALONE
void OTG_FS_IRQHandler(void) {
	HAL_PCD_IRQHandler(&hpcd_USB_OTG_FS);
}
#endif

void EXTI9_5_IRQHandler(void) {
	if (LL_EXTI_IsActiveFlag_0_31(LL_EXTI_LINE_7) != RESET) {
		// Interrupt on CPLD1 (PC7, EXTI7)
		LL_EXTI_ClearFlag_0_31(LL_EXTI_LINE_7);
		if (current_mode == MODE_RUN) {
			// CPLD4
			if (LL_GPIO_IsInputPinSet(GPIOC, LL_GPIO_PIN_11)) {
				flag_console_write = 1;
			} else {
				// This must be done in this interrupt handler because the main loop may be caught
				// up doing the SD-to-MCU transfers, and wouldn't reply in time.

				// This delay only works for readout by pairs of move.l's (ax),(ay)+, see doc.
				// Min 567ns, max 2230ns
				/*for (uint32_t c = 0; c < 15; c++) {
					asm("nop");		// ~50ns
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
				}*/

				// Reload CPLD FIFO with 4 words
				for (uint32_t c = 0; c < 4; c++) {
					uint16_t data = reply_buff_ptr->word[reply_idx++];

					// Endian conversion is done in CPLD
					GPIOB->ODR = data;
					asm("nop");		// ~50ns
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					/*asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");*/

					MCUCLK_HIGH
					asm("nop");		// ~50ns
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					/*asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");*/

					MCUCLK_LOW
					asm("nop");		// ~50ns
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");
					/*asm("nop");
					asm("nop");
					asm("nop");
					asm("nop");*/

					if (reply_idx >= BWBUFFER_SIZE_W) reply_idx = 0;	// Avoid buffer overflow, just in case
				}
			}
		}
	}
	if (LL_EXTI_IsActiveFlag_0_31(LL_EXTI_LINE_8) != RESET) {
		// Interrupt on CPLD3 (PA8, EXTI8)
		LL_EXTI_ClearFlag_0_31(LL_EXTI_LINE_8);
		flag_exec = 1;
	}
}

void DMA2_Stream3_IRQHandler(void) {
	if (LL_DMA_IsActiveFlag_HT3(DMA2)) {
		// Half transfer done, need to refill first half of buffer
		flag_refill = 1;
		LL_DMA_ClearFlag_HT3(DMA2);
	} else if (LL_DMA_IsActiveFlag_TC3(DMA2)) {
		// Transfer complete, need to refill second half of buffer
		flag_refill = 2;
		LL_DMA_ClearFlag_TC3(DMA2);
	}
}
