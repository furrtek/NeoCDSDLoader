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

#include "usb_device.h"
#include "usbd_core.h"
#include "usbd_desc.h"
#include "usbd_cdc.h"
#include "usbd_cdc_if.h"

USBD_HandleTypeDef hUsbDeviceFS;

void MX_USB_DEVICE_Init(void) {
	if (USBD_Init(&hUsbDeviceFS, &FS_Desc, DEVICE_FS) != USBD_OK)
		Error_Handler();
	if (USBD_RegisterClass(&hUsbDeviceFS, &USBD_CDC) != USBD_OK)
		Error_Handler();
	if (USBD_CDC_RegisterInterface(&hUsbDeviceFS, &USBD_Interface_fops_FS) != USBD_OK)
		Error_Handler();
	if (USBD_Start(&hUsbDeviceFS) != USBD_OK)
		Error_Handler();
}
