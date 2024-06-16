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

#include "leds.h"

uint8_t led_color_idle = LED_GREEN;
uint8_t led_color_load = LED_YELLOW;

void setLED(const uint8_t color) {
	// PC13, PC14, PC15
	GPIOC->ODR = (GPIOC->ODR & 0x1FFF) | ((color ^ 7) << 13);
}

void blink_code(const uint32_t * const colors) {
	// Blink 3-color code
	for (uint32_t c = 0; c < 3; c++) {
		setLED(colors[c]);
		LL_mDelay(250);
		setLED(LED_OFF);
		LL_mDelay(250);
	}
	LL_mDelay(750);
}
