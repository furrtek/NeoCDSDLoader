################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (9-2020-q2-update)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Middlewares/Third_Party/FatFs/src/diskio.c \
../Middlewares/Third_Party/FatFs/src/ff.c \
../Middlewares/Third_Party/FatFs/src/ff_gen_drv.c 

OBJS += \
./Middlewares/Third_Party/FatFs/src/diskio.o \
./Middlewares/Third_Party/FatFs/src/ff.o \
./Middlewares/Third_Party/FatFs/src/ff_gen_drv.o 

C_DEPS += \
./Middlewares/Third_Party/FatFs/src/diskio.d \
./Middlewares/Third_Party/FatFs/src/ff.d \
./Middlewares/Third_Party/FatFs/src/ff_gen_drv.d 


# Each subdirectory must supply rules for building sources it contributes
Middlewares/Third_Party/FatFs/src/diskio.o: ../Middlewares/Third_Party/FatFs/src/diskio.c Middlewares/Third_Party/FatFs/src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Middlewares/Third_Party/FatFs/src/diskio.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Middlewares/Third_Party/FatFs/src/ff.o: ../Middlewares/Third_Party/FatFs/src/ff.c Middlewares/Third_Party/FatFs/src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Middlewares/Third_Party/FatFs/src/ff.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"
Middlewares/Third_Party/FatFs/src/ff_gen_drv.o: ../Middlewares/Third_Party/FatFs/src/ff_gen_drv.c Middlewares/Third_Party/FatFs/src/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m7 -std=gnu11 -DSTM32F730xx -DUSE_HAL_DRIVER -DUSE_FULL_LL_DRIVER -c -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc/Legacy" -I"D:/neogeo/SDLoader/trunk/FW/ProdApp001/Drivers/STM32F7xx_HAL_Driver/Inc" -I../Inc -I../Drivers/CMSIS/Include -I../Drivers/CMSIS/Device/ST/STM32F7xx/Include -I../Middlewares/ST/STM32_USB_Device_Library/Class/CDC/Inc -I../Middlewares/ST/STM32_USB_Device_Library/Core/Inc -I../Middlewares/Third_Party/FatFs/src -O3 -ffunction-sections -fdata-sections -Wall -Wmissing-include-dirs -Wswitch-default -fstack-usage -MMD -MP -MF"Middlewares/Third_Party/FatFs/src/ff_gen_drv.d" -MT"$@" --specs=nano.specs -mfpu=fpv5-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

