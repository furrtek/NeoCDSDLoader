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

#ifndef __SD_H__
#define __SD_H__

#define SD_CS_LOW LL_GPIO_ResetOutputPin(GPIOC, LL_GPIO_PIN_0);
#define SD_CS_HIGH LL_GPIO_SetOutputPin(GPIOC, LL_GPIO_PIN_0);

#define SD_UNKNOWN_SD_CARD 0
#define SD_STD_CAPACITY_SD_CARD_V1_0 1
#define SD_STD_CAPACITY_SD_CARD_V2_0 2
#define SD_HIGH_CAPACITY_SD_CARD 3
#define SD_MULTIMEDIA_CARD 4

uint8_t SPI_Send(uint8_t byte);
uint32_t SD_Init();
uint8_t SD_Cmd(uint8_t command, uint32_t param);
uint8_t SD_WaitNotBusy(const uint32_t msec);

#endif /* __SD_H__ */
