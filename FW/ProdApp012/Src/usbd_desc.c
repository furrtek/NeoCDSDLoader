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

#include "usbd_core.h"
#include "usbd_desc.h"
#include "usbd_conf.h"

#define USBD_VID     1155
#define USBD_LANGID_STRING     1033
#define USBD_MANUFACTURER_STRING	"Furrtek Engineering"
#define USBD_PID_FS     22336
#define USBD_PRODUCT_STRING_FS		"Virtual Com Port"
#define USBD_CONFIGURATION_STRING_FS     "CDC Config"
#define USBD_INTERFACE_STRING_FS	"CDC Interface"

#define USB_SIZ_BOS_DESC            0x0C

static void Get_SerialNum(void);
static void IntToUnicode(uint32_t value, uint8_t * pbuf, uint8_t len);

uint8_t * USBD_FS_DeviceDescriptor(USBD_SpeedTypeDef speed, uint16_t *length);
uint8_t * USBD_FS_LangIDStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length);
uint8_t * USBD_FS_ManufacturerStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length);
uint8_t * USBD_FS_ProductStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length);
uint8_t * USBD_FS_SerialStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length);
uint8_t * USBD_FS_ConfigStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length);
uint8_t * USBD_FS_InterfaceStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length);

#ifdef USBD_SUPPORT_USER_STRING_DESC
uint8_t * USBD_FS_USRStringDesc(USBD_SpeedTypeDef speed, uint8_t idx, uint16_t *length);
#endif

USBD_DescriptorsTypeDef FS_Desc = {
	USBD_FS_DeviceDescriptor,
	USBD_FS_LangIDStrDescriptor,
	USBD_FS_ManufacturerStrDescriptor,
	USBD_FS_ProductStrDescriptor,
	USBD_FS_SerialStrDescriptor,
	USBD_FS_ConfigStrDescriptor,
	USBD_FS_InterfaceStrDescriptor
};

#if defined ( __ICCARM__ )	// IAR Compiler
  #pragma data_alignment=4
#endif

// USB standard device descriptor
__ALIGN_BEGIN uint8_t USBD_FS_DeviceDesc[USB_LEN_DEV_DESC] __ALIGN_END = {
  0x12,                       // bLength
  USB_DESC_TYPE_DEVICE,       // bDescriptorType
  0x00,                       // bcdUSB
  0x02,
  0x02,                       // bDeviceClass
  0x02,                       // bDeviceSubClass
  0x00,                       // bDeviceProtocol
  USB_MAX_EP0_SIZE,           // bMaxPacketSize
  LOBYTE(USBD_VID),           // idVendor
  HIBYTE(USBD_VID),           // idVendor
  LOBYTE(USBD_PID_FS),        // idProduct
  HIBYTE(USBD_PID_FS),        // idProduct
  0x00,                       // bcdDevice rel. 2.00
  0x02,
  USBD_IDX_MFC_STR,           // Index of manufacturer string
  USBD_IDX_PRODUCT_STR,       // Index of product string
  USBD_IDX_SERIAL_STR,        // Index of serial number string
  USBD_MAX_NUM_CONFIGURATION  // bNumConfigurations
};

#if defined ( __ICCARM__ )	// IAR Compiler
  #pragma data_alignment=4
#endif

// USB lang indentifier descriptor
__ALIGN_BEGIN uint8_t USBD_LangIDDesc[USB_LEN_LANGID_STR_DESC] __ALIGN_END = {
     USB_LEN_LANGID_STR_DESC,
     USB_DESC_TYPE_STRING,
     LOBYTE(USBD_LANGID_STRING),
     HIBYTE(USBD_LANGID_STRING)
};

#if defined ( __ICCARM__ )	// IAR Compiler
  #pragma data_alignment=4
#endif

// Internal string descriptor
__ALIGN_BEGIN uint8_t USBD_StrDesc[USBD_MAX_STR_DESC_SIZ] __ALIGN_END;

#if defined ( __ICCARM__ )	// IAR Compiler
  #pragma data_alignment=4   
#endif
__ALIGN_BEGIN uint8_t USBD_StringSerial[USB_SIZ_STRING_SERIAL] __ALIGN_END = {
	USB_SIZ_STRING_SERIAL,
	USB_DESC_TYPE_STRING,
};

uint8_t * USBD_FS_DeviceDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
	*length = sizeof(USBD_FS_DeviceDesc);
	return USBD_FS_DeviceDesc;
}

uint8_t * USBD_FS_LangIDStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
	*length = sizeof(USBD_LangIDDesc);
	return USBD_LangIDDesc;
}

uint8_t * USBD_FS_ProductStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
	if (speed == USBD_SPEED_HIGH)
		USBD_GetString((uint8_t *)USBD_PRODUCT_STRING_FS, USBD_StrDesc, length);
	else
		USBD_GetString((uint8_t *)USBD_PRODUCT_STRING_FS, USBD_StrDesc, length);

	return USBD_StrDesc;
}

uint8_t * USBD_FS_ManufacturerStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
	USBD_GetString((uint8_t *)USBD_MANUFACTURER_STRING, USBD_StrDesc, length);
	return USBD_StrDesc;
}

uint8_t * USBD_FS_SerialStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
	*length = USB_SIZ_STRING_SERIAL;
	Get_SerialNum();
	return (uint8_t *) USBD_StringSerial;
}

uint8_t * USBD_FS_ConfigStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
	if(speed == USBD_SPEED_HIGH)
		USBD_GetString((uint8_t *)USBD_CONFIGURATION_STRING_FS, USBD_StrDesc, length);
	else
		USBD_GetString((uint8_t *)USBD_CONFIGURATION_STRING_FS, USBD_StrDesc, length);

	return USBD_StrDesc;
}

uint8_t * USBD_FS_InterfaceStrDescriptor(USBD_SpeedTypeDef speed, uint16_t *length) {
	if (speed == USBD_SPEED_HIGH)
		USBD_GetString((uint8_t *)USBD_INTERFACE_STRING_FS, USBD_StrDesc, length);
	else
		USBD_GetString((uint8_t *)USBD_INTERFACE_STRING_FS, USBD_StrDesc, length);

	return USBD_StrDesc;
}

static void Get_SerialNum(void) {
	uint32_t deviceserial0, deviceserial1, deviceserial2;

	deviceserial0 = *(uint32_t *) DEVICE_ID1;
	deviceserial1 = *(uint32_t *) DEVICE_ID2;
	deviceserial2 = *(uint32_t *) DEVICE_ID3;

	deviceserial0 += deviceserial2;

	if (deviceserial0 != 0) {
		IntToUnicode(deviceserial0, &USBD_StringSerial[2], 8);
		IntToUnicode(deviceserial1, &USBD_StringSerial[18], 4);
	}
}

static void IntToUnicode(uint32_t value, uint8_t * pbuf, uint8_t len) {
	uint8_t idx = 0;

	for (idx = 0; idx < len; idx++) {
		if (((value >> 28)) < 0xA)
			pbuf[2 * idx] = (value >> 28) + '0';
		else
			pbuf[2 * idx] = (value >> 28) + 'A' - 10;

		value = value << 4;

		pbuf[2 * idx + 1] = 0;
	}
}
