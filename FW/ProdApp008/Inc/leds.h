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

#ifndef __LEDS_H
#define __LEDS_H

#include "main.h"

#define LED_OFF 0
#define LED_RED 1
#define LED_GREEN 2
#define LED_BLUE 4
#define LED_YELLOW (LED_RED | LED_GREEN)
#define LED_CYAN (LED_GREEN | LED_BLUE)
#define LED_MAGENTA (LED_BLUE | LED_RED)
#define LED_WHITE (LED_RED | LED_GREEN | LED_BLUE)
#define LED_USER led_user_color

#define BK_RED_RED_RED			(uint32_t[]){LED_RED,	LED_RED,	LED_RED}
#define BK_RED_RED_YELLOW		(uint32_t[]){LED_RED,	LED_RED,	LED_YELLOW}
#define BK_RED_YELLOW_RED		(uint32_t[]){LED_RED,	LED_YELLOW,	LED_RED}
#define BK_RED_YELLOW_YELLOW	(uint32_t[]){LED_RED,	LED_YELLOW, LED_YELLOW}
#define BK_YELLOW_RED_RED		(uint32_t[]){LED_YELLOW,LED_RED, 	LED_RED}
#define BK_YELLOW_RED_YELLOW	(uint32_t[]){LED_YELLOW,LED_RED, 	LED_YELLOW}
#define BK_YELLOW_YELLOW_RED	(uint32_t[]){LED_YELLOW,LED_YELLOW, LED_RED}
#define BK_YELLOW_YELLOW_YELLOW	(uint32_t[]){LED_YELLOW,LED_YELLOW, LED_YELLOW}
#define BK_GREEN_GREEN_GREEN	(uint32_t[]){LED_GREEN,	LED_GREEN, 	LED_GREEN}

extern uint8_t led_color_idle;
extern uint8_t led_color_load;

void setLED(const uint8_t color);
void blink_code(const uint32_t * const colors);

#endif /* __LEDS_H */

