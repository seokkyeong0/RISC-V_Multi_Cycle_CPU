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
void send_uart(uint8_t data);
int mul(int a, int b);
int mod(int a, int b);
int is_prime(int n);

int main(void) {
    GPIO_CR = 0xFFFF;
    GPIO_ODR = 0x0000;
    FND_DATA = 0;
    UART_BAUD_RATE = 9600;

    uint32_t buf[5] = { 0,0,0,0 };
    uint32_t idx = 0;

    while (1) {

        while (UART_STATUS & (1 << 3));
        uint32_t ch = (UART_DATA & 0xff00) >> 8;

        if (ch >= '0' && ch <= '9') {
            if (idx < 4) {
                send_uart(ch);
                buf[idx] = ch - 48;
                idx += 1;
            }
        }
        else if (ch == '\r' || ch == '\n') {
            if (idx > 0) {
                int value = 0;

                for (int i = 0; i < idx; i++) {
                    value = mul(value, 10) + buf[i];
                }

                FND_DATA = value;

                if (is_prime(value)) {
                    GPIO_ODR = 0xFFFF;
                    send_uart(' ');
                    send_uart('I');
                    send_uart('S');
                    send_uart(' ');
                    send_uart('P');
                    send_uart('R');
                    send_uart('I');
                    send_uart('M');
                    send_uart('E');
                    send_uart('\n');
                }
                else {
                    GPIO_ODR = 0x0000;
                    send_uart(' ');
                    send_uart('I');
                    send_uart('S');
                    send_uart(' ');
                    send_uart('N');
                    send_uart('O');
                    send_uart('T');
                    send_uart(' ');
                    send_uart('P');
                    send_uart('R');
                    send_uart('I');
                    send_uart('M');
                    send_uart('E');
                    send_uart('\n');
                }
            }

            idx = 0;
            for (int i = 0; i < 4; i++) buf[i] = 0;
        }

        delay(1000);
    }

    return 0;
}

void delay(uint32_t t) {
    uint32_t temp = 0;
    for (uint32_t i = 0; i < t; i++) {
        temp++;
    }
}

void send_uart(uint8_t data) {
    UART_DATA = data;
    UART_CONTROL = 1;
    delay(10);
    UART_CONTROL = 0;
    while (UART_STATUS & 1);
}

int mul(int a, int b) {
    int result = a;
    if (b == 0) return 0;
    else if (b == 1) return a;

    for (int i = 0; i < b - 1; i++) {
        result += a;
    }
    return result;
}

int mod(int a, int b) {
    while (a >= b) a -= b;
    return a;
}

int is_prime(int n) {
    if (n < 2) return 0;
    for (int i = 2; i < n; i++) {
        if (mod(n, i) == 0)
            return 0;
    }
    return 1;
}