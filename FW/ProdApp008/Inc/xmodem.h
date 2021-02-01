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

#ifndef __XMODEM_H
#define __XMODEM_H

#include "main.h"
#include "flash.h"

typedef enum {
	STATE_IDLE,
	STATE_XMODEM_RX_START,
	STATE_XMODEM_TX_START,
	STATE_XMODEM_RX_RUN,
	STATE_XMODEM_TX_RUN,
	STATE_XMODEM_TX_WAIT,
	STATE_XMODEM_EOT
} xstate_t;

void HandleXModem(const uint8_t byte);
void XModemRX(const uint8_t byte);
void XModemTX(const uint8_t byte);
void XModemInit(const xstate_t state);

extern xstate_t xstate;
extern uint32_t xmodem_retry;
extern memtype_t memory_type;

#endif /* __XMODEM_H */
