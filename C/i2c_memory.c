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
void I2C_LED(uint16_t data);
void I2C_FND(uint16_t data);
void I2C_MEM_Write(uint8_t addr, uint8_t data);
void I2C_MEM_Random_Read(uint8_t addr);
void I2C_MEM_Page_Write(uint8_t addr, uint64_t data, int write_len);
void I2C_MEM_Current_Address_Read();
void I2C_MEM_Sequence_Read(uint8_t addr, int read_len);
void I2C_MEM_Current_Data();

int address = 0;

int main(void) {
    print("Hello, I2C (^^)\n");

    // 1 Write, 1 Read
    I2C_MEM_Write(3, 0xaa);
    I2C_MEM_Random_Read(3);

    // Page Write (2~8)
    I2C_MEM_Page_Write(  2, 0x2010, 2);
    I2C_MEM_Page_Write(  8, 0x302010, 3);
    I2C_MEM_Page_Write( 16, 0x40302010, 4);
    I2C_MEM_Page_Write( 32, 0x5040302010, 5);
    I2C_MEM_Page_Write( 48, 0x605040302010, 6);
    I2C_MEM_Page_Write( 64, 0x70605040302010, 7);
    I2C_MEM_Page_Write( 80, 0x8070605040302010, 8);

    // Current Address Read
    I2C_MEM_Write(48, 0x11); // Setting Current Address
    I2C_MEM_Current_Address_Read();
    I2C_MEM_Current_Address_Read();
    I2C_MEM_Current_Address_Read();
    I2C_MEM_Current_Address_Read();
    I2C_MEM_Current_Address_Read();
    I2C_MEM_Current_Address_Read();


    // Sequential Read (2~8)
    I2C_MEM_Sequence_Read(2, 2);
    I2C_MEM_Sequence_Read(8, 3);
    I2C_MEM_Sequence_Read(16, 4);
    I2C_MEM_Sequence_Read(32, 5);
    I2C_MEM_Sequence_Read(48, 6);
    I2C_MEM_Sequence_Read(64, 7);
    I2C_MEM_Sequence_Read(80, 8);

    // Print All EEPROM Data
    I2C_MEM_Current_Data();

    return 0;
}

void I2C_Initialize(int w_len, int r_len) {
    I2C_INIT = (r_len << 16) | (w_len << 8) | 1;
    delay(1);
    I2C_INIT = (r_len << 16) | (w_len << 8);
}

void I2C_LED(uint16_t data) {
    I2C_Initialize(2, 0);
    I2C_TXDATA = 0b11001000;
    while(!(I2C_STATUS & (1 << 2)));
    I2C_TXDATA = data >> 8;
    while(!(I2C_STATUS & (1 << 2)));
    I2C_TXDATA = data & 0b11111111;
    while(!(I2C_STATUS & (1 << 2)));
    delay(1000);
}

void I2C_FND(uint16_t data) {
    I2C_Initialize(2, 0);
    I2C_TXDATA = 0b11001010;
    while(!(I2C_STATUS & (1 << 2)));
    I2C_TXDATA = data >> 8;
    while(!(I2C_STATUS & (1 << 2)));
    I2C_TXDATA = data & 0b11111111;
    while(!(I2C_STATUS & (1 << 2)));
    delay(1000);
}

void I2C_MEM_Write(uint8_t addr, uint8_t data) {
	xil_printf("Write Start !!\n");
	I2C_Initialize(2, 0);
    I2C_TXDATA = 0b11001100;
    while(!(I2C_STATUS & (1 << 2)));
    I2C_TXDATA = addr;
    while(!(I2C_STATUS & (1 << 2)));
    I2C_TXDATA = data;
    while(!(I2C_STATUS & (1 << 2)));
    xil_printf("MEM[%d] : Write Data = %x !!\n", addr, data);
    print("Write Done !!\n\n");
    address = addr;
    delay(100);
}

void I2C_MEM_Random_Read(uint8_t addr) {
	xil_printf("Random Read Start\n");
	I2C_Initialize(1, 1);
    I2C_TXDATA = 0b11001100;
    while(!(I2C_STATUS & (1 << 2)));
    I2C_TXDATA = addr;
    while(!(I2C_STATUS & (1 << 2)));
    I2C_TXDATA = 0b11001101;
    while(!(I2C_STATUS & 1));
    xil_printf("MEM[%d] : Received Data = %x\n", addr, I2C_RXDATA);
    print("Random Read Done !!\n\n");
    address = addr;
    delay(100);
}

void I2C_MEM_Page_Write(uint8_t addr, uint64_t data, int write_len) {
	xil_printf("Page Write Start : %d\n", write_len);
	uint8_t buf[8] = {data, data >> 8, data >> 16, data >> 24,
			          data >> 32, data >> 40, data >> 48, data >> 56};
	I2C_Initialize(write_len + 1, 0);
	I2C_TXDATA = 0b11001100;
	while(!(I2C_STATUS & (1 << 2)));
	I2C_TXDATA = addr;
	while(!(I2C_STATUS & (1 << 2)));
	for(int i = 0; i < write_len; i++){
		I2C_TXDATA = buf[i];
		while(!(I2C_STATUS & (1 << 2)));
	}
	for(int i = 0; i < write_len; i++){
		xil_printf("MEM[%d] : Write Data = %x !!\n", addr++, buf[i]);
	}
	xil_printf("Page Write Done !!\n\n");
	address = addr;
	delay(100);
}

void I2C_MEM_Current_Address_Read() {
	xil_printf("Current Address Read Start\n");
	I2C_Initialize(0, 1);
	I2C_TXDATA = 0b11001101;
	while(!(I2C_STATUS & 1));
	xil_printf("MEM[%d] : Received Data = %x\n", ++address, I2C_RXDATA);
	xil_printf("Current Address Read Done !!\n\n");
	delay(100);
}

void I2C_MEM_Sequence_Read(uint8_t addr, int read_len) {
	uint8_t buf[8] = {0};
	xil_printf("Sequence Read Start : %d\n", read_len);
	I2C_Initialize(1, read_len);
	I2C_TXDATA = 0b11001100;
	while(!(I2C_STATUS & (1 << 2)));
	I2C_TXDATA = addr;
	while(!(I2C_STATUS & (1 << 2)));
	I2C_TXDATA = 0b11001101;
	for(int i = 0; i < read_len; i++){
		while(!(I2C_STATUS & 1));
		buf[i] = I2C_RXDATA;
	}
	for(int i = 0; i < read_len; i++){
		xil_printf("MEM[%d] : Received Data = %x\n", addr++, buf[i]);
	}
	xil_printf("Sequence Read Done !!\n\n");
	address = addr;
	delay(100);
}

void I2C_MEM_Current_Data(){
	int r_addr = 0;
	xil_printf("############################################################\n");
	xil_printf("########         Seok Kyeong Hyun's EEPROM SIMULATION         ########\n");
	xil_printf("############################################################\n");
	for(int i = 0; i < 16; i++){
		xil_printf("|");
		for(int i = 0; i < 16; i++){
			I2C_Initialize(1, 1);
		    I2C_TXDATA = 0b11001100;
		    while(!(I2C_STATUS & (1 << 2)));
		    I2C_TXDATA = r_addr++;
		    while(!(I2C_STATUS & (1 << 2)));
		    I2C_TXDATA = 0b11001101;
		    while(!(I2C_STATUS & 1));
		    xil_printf("%3x |", I2C_RXDATA);
		    delay(100);
		}
		xil_printf("\n");
	}
	xil_printf("############################################################\n");
	xil_printf("############################################################\n");
	xil_printf("############################################################\n");
}

void delay(uint32_t time) {
    volatile uint32_t temp = 0;
    for (uint32_t i = 0; i < time; i++) {
        temp++;
    }
}