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

void MX_I2S1_Init(void) {
	uint32_t i2sdiv;

	LL_APB2_GRP1_EnableClock(LL_APB2_GRP1_PERIPH_SPI1);

	CLEAR_BIT(SPI1->I2SCFGR, (SPI_I2SCFGR_CHLEN | SPI_I2SCFGR_DATLEN | SPI_I2SCFGR_CKPOL | \
		SPI_I2SCFGR_I2SSTD | SPI_I2SCFGR_PCMSYNC | SPI_I2SCFGR_I2SCFG | \
		SPI_I2SCFGR_I2SE | SPI_I2SCFGR_I2SMOD));

	SPI1->I2SPR = 0x0002U;

	// Compute the i2sdiv prescaler
    i2sdiv = 17;
	SPI1->I2SPR = (uint32_t)((uint32_t)i2sdiv | (uint32_t)(I2S_MCLKOUTPUT_DISABLE));

	MODIFY_REG(SPI1->I2SCFGR, (SPI_I2SCFGR_CHLEN | SPI_I2SCFGR_DATLEN | \
		SPI_I2SCFGR_CKPOL | SPI_I2SCFGR_I2SSTD | \
		SPI_I2SCFGR_PCMSYNC | SPI_I2SCFGR_I2SCFG | \
		SPI_I2SCFGR_I2SE  | SPI_I2SCFGR_I2SMOD), \
		(SPI_I2SCFGR_I2SMOD | I2S_MODE_MASTER_TX | \
		I2S_STANDARD_LSB | I2S_DATAFORMAT_16B_EXTENDED | \
		I2S_CPOL_LOW));
}

void MX_SPI2_Init(void) {
	LL_GPIO_InitTypeDef GPIO_InitStruct = {0};

	LL_APB1_GRP1_EnableClock(LL_APB1_GRP1_PERIPH_SPI2);

	// SPI2 GPIO Configuration
	// PC1: SPI2_MOSI
	// PC2: SPI2_MISO
	// PA9: SPI2_SCK
	GPIO_InitStruct.Pin = LL_GPIO_PIN_1;
	GPIO_InitStruct.Mode = LL_GPIO_MODE_ALTERNATE;
	GPIO_InitStruct.Speed = LL_GPIO_SPEED_FREQ_MEDIUM;
	GPIO_InitStruct.OutputType = LL_GPIO_OUTPUT_PUSHPULL;
	GPIO_InitStruct.Pull = LL_GPIO_PULL_UP;
	GPIO_InitStruct.Alternate = LL_GPIO_AF_5;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	GPIO_InitStruct.Pin = LL_GPIO_PIN_9;
	LL_GPIO_Init(GPIOA, &GPIO_InitStruct);

	GPIO_InitStruct.Pin = LL_GPIO_PIN_2;
	LL_GPIO_Init(GPIOC, &GPIO_InitStruct);

	MODIFY_REG(SPI2->CR1,
		(SPI_CR1_CPHA | SPI_CR1_CPOL | \
		SPI_CR1_BR      | SPI_CR1_LSBFIRST | SPI_CR1_SSI    | \
		SPI_CR1_SSM     | SPI_CR1_RXONLY   | SPI_CR1_CRCL   | \
		SPI_CR1_CRCNEXT | SPI_CR1_CRCEN    | SPI_CR1_BIDIOE | \
		SPI_CR1_BIDIMODE),
		LL_SPI_FULL_DUPLEX | LL_SPI_MODE_MASTER |
		LL_SPI_POLARITY_LOW | LL_SPI_PHASE_1EDGE |
		LL_SPI_NSS_SOFT | LL_SPI_BAUDRATEPRESCALER_DIV256 |
		LL_SPI_MSB_FIRST | LL_SPI_CRCCALCULATION_DISABLE);

	MODIFY_REG(SPI2->CR2,
		SPI_CR2_DS | SPI_CR2_SSOE,
		LL_SPI_DATAWIDTH_8BIT | (LL_SPI_NSS_SOFT >> 16U));

	CLEAR_BIT(SPI2->I2SCFGR, SPI_I2SCFGR_I2SMOD);

	LL_SPI_SetRxFIFOThreshold(SPI2, LL_SPI_RX_FIFO_TH_QUARTER);

	SET_BIT(SPI2->CR1, SPI_CR1_SPE);
}
