# 🧠 RISC-V RV32I Multicycle CPU + APB Peripherals

## 📌 Project Overview
**Objective:**  
Design a RISC-V–based multicycle CPU and integrate AMBA APB peripherals.

**Key Features:**
- Multicycle CPU Core implementation (RV32I ISA)
- AMBA APB bus design with multiple peripherals (GPIO, UART, TIMER, FND)
- MCU applications simulated using UART communication

**Development Environment:**  
SystemVerilog, Vivado, C, RISC-V, Assembly

---

## ⚙️ CPU Design

**Architecture:**  
- `IF → ID → EX → MEM → WB` (5-stage multicycle pipeline)
- To achieve this, DFFs are inserted into the datapath and the control unit is also implemented in FSM form.

**Highlights:**
- Improved timing slack compared to single-cycle CPU
- Supports Load/Store Word instructions only (LB/LH temporarily excluded for simplicity)

**Result:**  
Successfully verified basic RV32I instruction set operations.

---

## 🔗 AMBA APB Bus & MCU Architecture

**System Structure:**  
**Peripheral Address Map:**

| Peripheral | Address Range           | Function                     |
|------------|------------------------|-------------------------------|
| RAM        | 0x10000000 ~ 0x10000FFF | Data memory                  |
| GPIO       | 0x10001000 ~ 0x10001FFF | LED / Switch control         |
| UART       | 0x10002000 ~ 0x10002FFF | Serial communication         |
| TIMER      | 0x10003000 ~ 0x10003FFF | Timer control                |
| FND        | 0x10004000 ~ 0x10004FFF | 7-segment display output     |

---

## 🧩 Peripheral Design

- **GPIO:** Controls 16 LEDs and switches  
- **UART:** RX/TX FIFO-based serial communication  
- **TIMER:** Periodic signal generation with interrupt control  
- **FND:** Four-digit 7-segment display driver  

---

## 💻 Application Examples

### 1️⃣ LED Blink Cycle Controller
- Adjusts LED blinking interval based on UART input  
- **Peripherals used:** UART, GPIO, TIMER, FND  

### 2️⃣ Prime Number Discriminator
- Receives up to 4-digit numbers via UART → combines digits → checks primality → displays result on FND  
- **Peripherals used:** UART, GPIO, FND  

---

## 🧪 UART Verification

**Method:** UVM-lite–based Loopback Test  

**Verification Components:**
- **Generator:** Creates and sends random 8-bit data  
- **Driver:** Generates and transmits RX patterns  
- **Monitor:** Detects TX patterns and logs output  
- **Scoreboard:** Compares transmitted and received data  

**Result:** Correct operation confirmed via TCL console and waveform inspection.

---

## ⚠️ Troubleshooting

- **Signal Latching:**  
  Short one-cycle signals (e.g., `rx_done`) required latching circuits for reliable detection
- **Timing Report:**  
  Divider module caused propagation delays → optimized clock timing
- **RV32I Limitations:**  
  MUL/DIV/MOD instructions missing → implemented equivalent operations in C code

---

## 🚀 Improvements & Conclusion

**Achievements:**
- Gained deep understanding of MCU operation flow
- Experience in custom peripheral design

**Future Enhancements:**
- Add more complex peripheral modules
- Expand verification scope using advanced UVM environments

---

## 🙋‍♂️ Personal Contribution

- Designed the CPU core and APB interface  
- Built UART verification environment using UVM-lite  
- Implemented peripheral register maps and application-level C code  
- Diagnosed and optimized timing and signal integrity issues

