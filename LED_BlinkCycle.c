#include <stdint.h>

#define APB_BASE_ADDR 0x10000000
#define RAM_OFFSET    0x0000
#define GPIO_OFFSET   0x1000
#define UART_OFFSET   0x2000
#define TIMER_OFFSET  0x3000
#define FND_OFFSET    0x4000

#define RAM_BASE_ADDR   (APB_BASE_ADDR + RAM_OFFSET)
#define GPIO_BASE_ADDR  (APB_BASE_ADDR + GPIO_OFFSET)
#define UART_BASE_ADDR  (APB_BASE_ADDR + UART_OFFSET)
#define TIMER_BASE_ADDR (APB_BASE_ADDR + TIMER_OFFSET)
#define FND_BASE_ADDR   (APB_BASE_ADDR + FND_OFFSET)

#define GPIO_CR   (*(uint32_t *)(GPIO_BASE_ADDR + 0x00))
#define GPIO_ODR  (*(uint32_t *)(GPIO_BASE_ADDR + 0x04))
#define GPIO_IDR  (*(uint32_t *)(GPIO_BASE_ADDR + 0x08))

#define UART_DATA       (*(uint32_t *)(UART_BASE_ADDR + 0x00))
#define UART_STATUS     (*(uint32_t *)(UART_BASE_ADDR + 0x04))
#define UART_CONTROL    (*(uint32_t *)(UART_BASE_ADDR + 0x08))
#define UART_BAUD_RATE  (*(uint32_t *)(UART_BASE_ADDR + 0x0C))

#define TIMER_CONTROL   (*(uint32_t *)(TIMER_BASE_ADDR + 0x00))
#define TIMER_IRQ_SIG   (*(uint32_t *)(TIMER_BASE_ADDR + 0x04))
#define TIMER_PERIOD    (*(uint32_t *)(TIMER_BASE_ADDR + 0x08))
#define TIMER_VALUE     (*(uint32_t *)(TIMER_BASE_ADDR + 0x0C))

#define FND_DATA        (*(uint32_t *)(FND_BASE_ADDR + 0x00))


void delay(uint32_t t);

int main(void) {
    GPIO_CR = 0xFFFF;
    GPIO_ODR = 0x0000;
    FND_DATA = 50;
    UART_BAUD_RATE = 9600;

    uint32_t blink_period = 50000000;
    TIMER_PERIOD = blink_period;
    TIMER_CONTROL = 1;

    while (1) {

        if (UART_STATUS & (1 << 3)) {
            uint32_t ch = (UART_DATA & 0xff00) >> 8;

            if (ch == 'U' && FND_DATA < 1000) {
                blink_period += 10000000;
                FND_DATA += 10;
            }
            else if (ch == 'D' && FND_DATA > 5) {
                blink_period -= 5000000;
                FND_DATA -= 5;
            }
        }

        TIMER_PERIOD = blink_period;
        if (TIMER_IRQ_SIG) GPIO_ODR = 0xFFFF;
        else GPIO_ODR = 0x0000;

        delay(10);
    }
    return 0;
}

void delay(uint32_t t) {
    uint32_t temp = 0;
    for (uint32_t i = 0; i < t; i++) {
        temp++;
    }
}