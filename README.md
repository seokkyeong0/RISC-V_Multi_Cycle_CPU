RISC-V RV32I Multicycle CPU + APB Peripherals
Project Overview

Objective:
Design a RISC-V–based multicycle CPU and integrate AMBA APB peripherals.

Key Features:

Implemented a Multicycle CPU Core (RV32I ISA)

Designed the AMBA APB bus and connected multiple peripherals (GPIO, UART, TIMER, FND)

Developed and simulated MCU applications using UART communication

Development Environment:
SystemVerilog, Vivado, C, RISC-V, Assembly

CPU Design

Architecture:
IF → ID → EX → MEM → WB (5-stage multicycle pipeline)

Highlights:

Improved timing slack compared to single-cycle CPU

Supported Load/Store Word instructions only (LB/LH temporarily excluded for logic simplicity)

Result:
Successfully verified basic RV32I instruction set operations.

AMBA APB Bus & MCU Architecture

System Structure:
ROM → CPU Core → APB Bus → Peripherals

Peripheral Address Map:

Peripheral	Address Range	Function
RAM	0x10000000 ~ 0x10000FFF	Data memory
GPIO	0x10001000 ~ 0x10001FFF	LED / Switch control
UART	0x10002000 ~ 0x10002FFF	Serial communication
TIMER	0x10003000 ~ 0x10003FFF	Timer control
FND	0x10004000 ~ 0x10004FFF	7-segment display output
Peripheral Design

GPIO: Controls 16 LEDs and switches

UART: Implemented RX/TX FIFO-based communication

TIMER: Supports periodic signal generation using interrupt-based control

FND: Four-digit 7-segment display driver

Application Examples
LED Blink Cycle Controller

Adjusts LED blinking interval based on UART input.

Used Peripherals: UART + GPIO + TIMER + FND

Prime Number Discriminator

Receives up to 4-digit numbers through UART → combines digits → performs prime number check → displays result on FND.

Used Peripherals: UART + GPIO + FND

UART Verification

Method: UVM-lite–based Loopback Test

Verification Components:

Generator: Creates and sends random 8-bit data

Driver: Generates and transmits RX patterns

Monitor: Detects TX patterns and logs output

Scoreboard: Compares transmitted and received data

Result: Correct operation confirmed through TCL console and waveform inspection.

Troubleshooting

Signal Latching:

One-cycle signals such as rx_done were too short to detect → added latching circuit

Timing Report:

Divider module caused propagation delay issues → optimized clock timing

RV32I Limitations:

Lacks MUL/DIV/MOD instructions → implemented equivalent operations in C code

Improvements & Conclusion

Gained deeper understanding of MCU operation flow

Accumulated experience in custom peripheral design

Future Enhancements:

Add more complex peripheral modules

Expand verification scope using advanced UVM environments

Personal Contribution

Designed the CPU core and APB interface

Built UART verification environment using UVM-lite

Implemented peripheral register maps and application-level C code

Diagnosed and optimized timing and signal integrity issues
