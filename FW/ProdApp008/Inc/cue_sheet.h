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

#ifndef __CUE_SHEET_H__
#define __CUE_SHEET_H__

extern FIL fil_data;
extern char cue_sheet_path[512];

uint32_t ParseCueSheet(char * const file_path, const uint32_t track_number, char * const return_data);
uint32_t OpenDataTrack();
uint32_t OpenAudioTrack(const uint32_t track_number);

#endif /* __CUE_SHEET_H__ */
