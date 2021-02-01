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

void SystemClock_Config(void) {
	LL_FLASH_SetLatency(LL_FLASH_LATENCY_3);

	if (LL_FLASH_GetLatency() != LL_FLASH_LATENCY_3)
		Error_Handler();
	LL_PWR_SetRegulVoltageScaling(LL_PWR_REGU_VOLTAGE_SCALE3);
	LL_PWR_DisableOverDriveMode();
	LL_RCC_HSE_Enable();
	// Wait for HSE to be ready
	while(LL_RCC_HSE_IsReady() != 1) { }

	LL_RCC_HSI_SetCalibTrimming(16);
	LL_RCC_HSI_Enable();
	// Wait for HSI to be ready
	while(LL_RCC_HSI_IsReady() != 1) { }

	LL_RCC_PLL_ConfigDomain_SYS(LL_RCC_PLLSOURCE_HSE, LL_RCC_PLLM_DIV_4, 96, LL_RCC_PLLP_DIV_2);	// 96MHz
	LL_RCC_PLL_ConfigDomain_48M(LL_RCC_PLLSOURCE_HSE, LL_RCC_PLLM_DIV_4, 96, LL_RCC_PLLQ_DIV_4);
	LL_RCC_PLLI2S_ConfigDomain_I2S(LL_RCC_PLLSOURCE_HSE, LL_RCC_PLLM_DIV_4, 96, LL_RCC_PLLI2SR_DIV_2);
	LL_RCC_PLL_Enable();
	// Wait for PLL to be ready
	while(LL_RCC_PLL_IsReady() != 1) { }

	LL_RCC_PLLI2S_Enable();
	// Wait for PLL to be ready
	while(LL_RCC_PLLI2S_IsReady() != 1) { }

	LL_RCC_SetAHBPrescaler(LL_RCC_SYSCLK_DIV_1);
	LL_RCC_SetAPB1Prescaler(LL_RCC_APB1_DIV_1);
	LL_RCC_SetAPB2Prescaler(LL_RCC_APB2_DIV_1);
	LL_RCC_SetSysClkSource(LL_RCC_SYS_CLKSOURCE_PLL);

	SystemCoreClockUpdate();
	HAL_InitTick(TICK_INT_PRIORITY);
}
