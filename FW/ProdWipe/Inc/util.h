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

#ifndef __UTIL_H__
#define __UTIL_H__

#include "main.h"

extern TIM_HandleTypeDef s_TimerInstance;

void DMAResetRegisters(DMA_Stream_TypeDef * tmp);
void DebugPrint(const char * const text, const uint32_t value);
void SetMode(uint32_t mode);
void CDCPuts(uint8_t c);
void CDCPrint(char* str);
void delay_us(uint32_t delay);
uint32_t BCDtoHex(uint8_t bcd);

#endif /* __UTIL_H__ */
