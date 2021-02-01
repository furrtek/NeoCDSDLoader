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

#ifndef __CPLD_COMM_H__
#define __CPLD_COMM_H__

void TickMCUCLK();
void SetMCUData(const uint16_t data);
uint16_t ReadCPLDData();
void WriteCPLDData(uint16_t data);
void SetMCUBusInput();
void SetMCUBusOutput();
void SetRunStock(const uint16_t v);

#endif /* __CPLD_COMM_H__ */
