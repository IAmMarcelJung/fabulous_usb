// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdbool.h>

#include "demo_system.h"
#include "gpio.h"
#include "timer.h"

int main(void) {
    // install_exception_handler(UART_IRQ_NUM, &test_uart_irq_handler);

    // This indicates how often the timer gets updated.
    timer_init();
    timer_enable(5000000);

    uint64_t last_elapsed_time = get_elapsed_time();

    // Reset green LEDs to having just one on
    set_outputs(GPIO_OUT, 0x10);

    while (1) {
        uint64_t cur_time = get_elapsed_time();

        if (cur_time != last_elapsed_time) {
            last_elapsed_time = cur_time;

            static bool led_on = false;
            led_on = !led_on; // Toggle the LED state

            set_outputs(GPIO_OUT,
                        led_on ? GPIO_LED_MASK : 0x00); // Blink all LEDs
        }

        asm volatile("wfi");
    }
}
