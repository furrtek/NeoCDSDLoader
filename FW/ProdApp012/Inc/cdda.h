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

#ifndef __CDDA_H__
#define __CDDA_H__

#define CDDA_BUFFER_WORDS 8192
#define CDDA_BUFFER_BYTES (CDDA_BUFFER_WORDS*2)
#define CDDA_BUFFER_HALF (CDDA_BUFFER_BYTES/2)

#define GOERTZEL_PI 3.14159265358979323846
#define GOERTZEL_FS 44100.0
#define GOERTZEL_BUFF_SIZE 2048
#define GOERTZEL_SCALING (GOERTZEL_BUFF_SIZE / 2)

#define WAV_DATA_START 44

#define AUDIO_WAV 0
#define AUDIO_BIN 1

void CDDA_Play(const uint8_t track, const uint8_t loop_flag);
void CDDA_Stop();
void CDDA_Refill(int16_t* buffer_start, uint32_t size);

extern FIL fil_data;
extern int16_t cdda_buffer[];
extern uint32_t last_track;

#endif /* __CDDA_H__ */
