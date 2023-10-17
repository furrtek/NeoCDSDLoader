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

#ifndef __STM32_ASSERT_H
#define __STM32_ASSERT_H

#ifdef  USE_FULL_ASSERT
	#define assert_param(expr) ((expr) ? (void)0U : assert_failed((uint8_t *)__FILE__, __LINE__))
	void assert_failed(uint8_t* file, uint32_t line);
#else
	#define assert_param(expr) ((void)0U)
#endif

#endif /* __STM32_ASSERT_H */
