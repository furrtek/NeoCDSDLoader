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

#include "usbd_cdc_if.h"

// CDC RX and TX buffer sizes
#define APP_RX_DATA_SIZE  2048
#define APP_TX_DATA_SIZE  2048

uint8_t UserRxBufferFS[APP_RX_DATA_SIZE];
uint8_t UserTxBufferFS[APP_TX_DATA_SIZE];

extern USBD_HandleTypeDef hUsbDeviceFS;

static int8_t CDC_Init_FS(void);
static int8_t CDC_DeInit_FS(void);
static int8_t CDC_Control_FS(uint8_t cmd, uint8_t* pbuf, uint16_t length);
static int8_t CDC_Receive_FS(uint8_t* pbuf, uint32_t *Len);

USBD_CDC_ItfTypeDef USBD_Interface_fops_FS = {
	CDC_Init_FS,
	CDC_DeInit_FS,
	CDC_Control_FS,
	CDC_Receive_FS
};

static int8_t CDC_Init_FS(void) {
	// Assign buffers
	USBD_CDC_SetTxBuffer(&hUsbDeviceFS, UserTxBufferFS, 0);
	USBD_CDC_SetRxBuffer(&hUsbDeviceFS, UserRxBufferFS);
	return (USBD_OK);
}

static int8_t CDC_DeInit_FS(void) {
	return (USBD_OK);
}

static int8_t CDC_Control_FS(
	uint8_t cmd,	// Command code
	uint8_t* pbuf,	// Command data buffer
	uint16_t length	// Size of data (bytes)
) {
	// Not a real serial port, so ignore all
	switch(cmd) {
		case CDC_SEND_ENCAPSULATED_COMMAND:
		case CDC_GET_ENCAPSULATED_RESPONSE:
		case CDC_SET_COMM_FEATURE:
		case CDC_GET_COMM_FEATURE:
		case CDC_CLEAR_COMM_FEATURE:
		case CDC_SET_LINE_CODING:
		case CDC_GET_LINE_CODING:
		case CDC_SET_CONTROL_LINE_STATE:
		case CDC_SEND_BREAK:
		default:
		break;
	}

	return (USBD_OK);
}

static int8_t CDC_Receive_FS(uint8_t* Buf, uint32_t *Len) {
	uint32_t len = *Len;

	USBD_CDC_SetRxBuffer(&hUsbDeviceFS, &Buf[0]);
	USBD_CDC_ReceivePacket(&hUsbDeviceFS);

	// Add received data to FIFO
	while (len--) {
		if (FIFO_INCR(RX_FIFO.head) == RX_FIFO.tail) {
			return USBD_FAIL;	// Overrun
		} else {
			RX_FIFO.data[RX_FIFO.head] = *Buf++;
			RX_FIFO.head = FIFO_INCR(RX_FIFO.head);
		}
	}

	return (USBD_OK);
}

uint8_t CDC_Transmit_FS(uint8_t* Buf, uint16_t Len) {
	uint8_t result = USBD_OK;

	USBD_CDC_HandleTypeDef *hcdc = (USBD_CDC_HandleTypeDef*)hUsbDeviceFS.pClassData;
	if (hcdc->TxState != 0)
		return USBD_BUSY;

	USBD_CDC_SetTxBuffer(&hUsbDeviceFS, Buf, Len);
	result = USBD_CDC_TransmitPacket(&hUsbDeviceFS);

	return result;
}
