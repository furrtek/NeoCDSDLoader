################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (9-2020-q2-update)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Src/cdda.c \
../Src/console_cmd.c \
../Src/cpld_comm.c \
../Src/cue_sheet.c \
../Src/fatfs.c \
../Src/files.c \
../Src/flash.c \
../Src/init_clocks.c \
../Src/init_gpio.c \
../Src/init_spi.c \
../Src/jtag.c \
../Src/leds.c \
../Src/main.c \
../Src/sd.c \
../Src/stm32f7xx_it.c \
../Src/syscalls.c \
../Src/sysmem.c \
../Src/system_stm32f7xx.c \
../Src/update.c \
../Src/usb_device.c \
../Src/usbd_cdc_if.c \
../Src/usbd_conf.c \
../Src/usbd_desc.c \
../Src/user_diskio.c \
../Src/util.c \
../Src/xmodem.c 

OBJS += \
./Src/cdda.o \
./Src/console_cmd.o \
./Src/cpld_comm.o \
./Src/cue_sheet.o \
./Src/fatfs.o \
./Src/files.o \
./Src/flash.o \
./Src/init_clocks.o \
./Src/init_gpio.o \
./Src/init_spi.o \
./Src/jtag.o \
./Src/leds.o \
./Src/main.o \
./Src/sd.o \
./Src/stm32f7xx_it.o \
./Src/syscalls.o \
./Src/sysmem.o \
./Src/system_stm32f7xx.o \
./Src/update.o \
./Src/usb_device.o \
./Src/usbd_cdc_if.o \
./Src/usbd_conf.o \
./Src/usbd_desc.o \
./Src/user_diskio.o \
./Src/util.o \
./Src/xmodem.o 

C_DEPS += \
./Src/cdda.d \
./Src/console_cmd.d \
./Src/cpld_comm.d \
./Src/cue_sheet.d \
./Src/fatfs.d \
./Src/files.d \
./Src/flash.d \
./Src/init_clocks.d \
./Src/init_gpio.d \
./Src/init_spi.d \
./Src/jtag.d \
./Src/leds.d \
./Src/main.d \
./Src/sd.d \
./Src/stm32f7xx_it.d \
./Src/syscalls.d \
./Src/sysmem.d \
./Src/system_stm32f7xx.d \
./Src/update.d \
./Src/usb_device.d \
./Src/usbd_cdc_if.d \
./Src/usbd_conf.d \
./Src/usbd_desc.d \
./Src/user_diskio.d \
./Src/util.d \
./Src/xmodem.d 


# Each subdirectory must supply rules for building sources it contributes
Src/cdda.o: ../Src/cdda.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/cdda.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/console_cmd.o: ../Src/console_cmd.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/console_cmd.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/cpld_comm.o: ../Src/cpld_comm.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/cpld_comm.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/cue_sheet.o: ../Src/cue_sheet.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/cue_sheet.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/fatfs.o: ../Src/fatfs.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/fatfs.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/files.o: ../Src/files.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/files.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/flash.o: ../Src/flash.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/flash.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/init_clocks.o: ../Src/init_clocks.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/init_clocks.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/init_gpio.o: ../Src/init_gpio.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/init_gpio.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/init_spi.o: ../Src/init_spi.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/init_spi.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/jtag.o: ../Src/jtag.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/jtag.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/leds.o: ../Src/leds.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/leds.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/main.o: ../Src/main.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/main.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/sd.o: ../Src/sd.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/sd.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/stm32f7xx_it.o: ../Src/stm32f7xx_it.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/stm32f7xx_it.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/syscalls.o: ../Src/syscalls.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/syscalls.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/sysmem.o: ../Src/sysmem.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/sysmem.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/system_stm32f7xx.o: ../Src/system_stm32f7xx.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/system_stm32f7xx.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/update.o: ../Src/update.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/update.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/usb_device.o: ../Src/usb_device.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/usb_device.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/usbd_cdc_if.o: ../Src/usbd_cdc_if.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/usbd_cdc_if.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/usbd_conf.o: ../Src/usbd_conf.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/usbd_conf.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/usbd_desc.o: ../Src/usbd_desc.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/usbd_desc.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/user_diskio.o: ../Src/user_diskio.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/user_diskio.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/util.o: ../Src/util.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/util.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Src/xmodem.o: ../Src/xmodem.c Src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Src/xmodem.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

