#include <stdio.h>
#include <stdint.h>
#include "xil_printf.h"
#include "xparameters.h"

#define I2C_BASE_ADDR   0x44A10000

#define I2C_INIT    (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x00))
#define I2C_TXDATA  (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x04))
#define I2C_RXDATA  (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x08))
#define I2C_STATUS  (*(volatile uint32_t *)(I2C_BASE_ADDR + 0x0C))

#define LED 1
#define FND 2
#define MEM 3

void delay(uint32_t time);
void I2C_Initialize(int w_len, int r_len);
void I2C_Select(int device, uint16_t data);
void I2C_LED(uint16_t data);
void I2C_FND(uint16_t data);
void I2C_MEM(uint16_t data);

int main(void) {
    print("Hello, I2C (^^)\n");

    int step = 0;
    int dir = 1;
    int fnd = 0;

    while (1) {
        uint16_t led = (1u << step) | (1u << (15 - step));

        I2C_Initialize(2, 0);
        I2C_LED(led);
        delay(100000);

        if (dir == 1) {
            step++;
            if (step >= 7) dir = -1;
        } else {
            step--;
            if (step <= 0) dir = 1;
        }

        I2C_Initialize(2,0);
        I2C_FND(fnd++ % 10000);
        delay(100000);
    }

    return 0;
}

void I2C_Initialize(int w_len, int r_len) {
    I2C_INIT = (r_len << 16) | (w_len << 8) | 1;
    delay(1);
    I2C_INIT = (r_len << 16) | (w_len << 8);
}

void I2C_Select(int device, uint16_t data) {
    switch (device) {
        case LED:
            I2C_TXDATA = 0b11001000;
            while(!(I2C_STATUS & (1 << 2)));
            I2C_TXDATA = data >> 8;
            while(!(I2C_STATUS & (1 << 2)));
            I2C_TXDATA = data & 0b11111111;
            while(!(I2C_STATUS & (1 << 2)));
            break;

        case FND:
            I2C_TXDATA = 0b11001010;
            while(!(I2C_STATUS & (1 << 2)));
            I2C_TXDATA = data >> 8;
            while(!(I2C_STATUS & (1 << 2)));
            I2C_TXDATA = data & 0b11111111;
            while(!(I2C_STATUS & (1 << 2)));
            break;

        case MEM:
            I2C_TXDATA = 0b11001100;
            while(!(I2C_STATUS & (1 << 2)));
            break;

        default:
            xil_printf("Invalid device\n");
            return;
    }
}

void I2C_LED(uint16_t data) {
    I2C_Initialize(2, 0);
    I2C_Select(LED, data);
}

void I2C_FND(uint16_t data) {
    I2C_Initialize(2, 0);
    I2C_Select(FND, data);
}

void delay(uint32_t time) {
    volatile uint32_t temp = 0;
    for (uint32_t i = 0; i < time; i++) {
        temp++;
    }
}

