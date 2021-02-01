#include "leds.h"

uint8_t led_user_color = LED_RED;

void setLED(const uint8_t color) {
	// PC13, PC14, PC15
	GPIOC->ODR = (GPIOC->ODR & 0x1FFF) | ((color ^ 7) << 13);
}
