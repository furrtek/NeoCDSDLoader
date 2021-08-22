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

#ifndef __CONSOLE_CMD_H__
#define __CONSOLE_CMD_H__

#include "main.h"

#define MCU_CMD_TEST		0
#define MCU_CMD_GETID 		1
#define MCU_CMD_GETSTATUS   2
#define MCU_CMD_UPDATE		3
#define MCU_CMD_RESET   	4
#define MCU_CMD_INITSD      5
#define MCU_CMD_GETGAMES    6
#define MCU_CMD_SELECTGAME  7
#define MCU_CMD_LOADSECT    8
#define MCU_CMD_CDDA    	9
#define MCU_CMD_DUMPROM    	10
#define MCU_CMD_GETSAVES    11
#define MCU_CMD_STORESAVE   12
#define MCU_CMD_LOADSAVE    13

#define CMD_OK 1
#define CMD_NOK 0

extern volatile cmd_buffer_t cmd_buffer;	// Console command buffer

void ExecCmd();

extern FATFS SDFatFs;
extern FIL fil_data;

#endif /* __CONSOLE_CMD_H__ */
